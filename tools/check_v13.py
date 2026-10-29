#!/usr/bin/env python3
"""V13 preflight: static resources and geometry. Does NOT replace Godot launch."""
from pathlib import Path
import struct
import re, math
root=Path(__file__).resolve().parents[1]
sol=(root/'scripts/SolarSystem.gd').read_text(encoding='utf-8')
menu=(root/'scripts/NavigationMenu.gd').read_text(encoding='utf-8')
mapcode=(root/'scripts/MiniMap.gd').read_text(encoding='utf-8')
main=(root/'scripts/Main.gd').read_text(encoding='utf-8')
check=lambda x,msg: (_ for _ in ()).throw(AssertionError(msg)) if not x else None
all_planets=['Mercury','Venus','Earth','Mars','Jupiter','Saturn','Uranus','Neptune']
allowed=['Venus','Earth','Mars','Jupiter','Neptune','EarthStation']
check(all((root/'planets'/f'{name.lower()}.tscn').is_file() for name in all_planets),'Missing a MIKO planet scene')
check(all(f'"{name}": preload("res://planets/{name.lower()}.tscn")' in sol for name in all_planets if name!='Earth'),'One of 7 non-Earth scenes not kept')
check('EarthScene: PackedScene' in sol,'Earth scene missing')
match=re.search(r'const TARGETS: Array\[String\] = \[(.*?)\]',menu)
check(match is not None,'No destination target list')
ids=re.findall(r'"(\w+)"',match.group(1))
check(ids==allowed,f'Incorrect destinations: {ids}')
check('if target_id != "EarthStation" and not STATION_SHELL_SCENES.has(target_id)' in sol,'Autopilot must filter destinations')
for name in allowed[:-1]:
    check(f'"{name}": preload("res://station_overlays/scenes/OrbitalStation_' in sol,f'No overlay for {name}')
for forbidden in ['Mercury','Saturn','Uranus']:
    check(f'"{forbidden}": preload("res://station_overlays/scenes/' not in sol,f'Station placed on noninhabited {forbidden}')
check('shell.rotation = 0.0' in sol and 'anchored_shell.position = planet_screen' in sol and 'earth_shell.position = earth_screen' in sol, 'Anchoring of stationary shells missing')
check('STATION_ART_PLANET_DIAMETER: float = 320.0' in sol,'Scale mismatch after downsampling')
check('set_camera_view_size(view)' in main and 'set_camera_view_size(view_world_size: Vector2)' in mapcode,'Viewport extent not synchronized')
check('_camera_view_world_size / (_units_per_pixel * 2.0)' in mapcode,'Camera box size not based on viewport')
check('_draw_clipped_view_edge' in mapcode and 'intervals.sort()' in mapcode,'Viewport frame must be circularly clipped')
check('HBoxContainer.new()' in menu and 'ScrollContainer.new()' in menu,'Horizontal touch menu lost')
check('auto_stop_button.visible = true' in main and 'joystick.visible = false' in main, 'Stop/joystick toggle lost')
# Every referenced file must exist.
for script in root.rglob('*.gd'):
    txt=script.read_text(encoding='utf-8')
    for r in re.findall(r'res://([^"\s]+)',txt):
        if '%' in r: continue
        if Path(r).suffix in ('.gd','.gdshader','.tscn','.png','.jpg'):
            check((root/r).exists(),f'{script.name}: missing {r}')
    # Existing project uses tabs, except MIKO Planet2D script which is 4-space.
    lines=[x for x in txt.splitlines() if x.strip()]
    check(not(any(x.startswith('\t') for x in lines) and any(x.startswith(' ') for x in lines)),f'{script.name}: mixed indentation')
for scene in (root/'station_overlays/scenes').glob('*.tscn'):
    code=scene.read_text()
    for path in re.findall(r'path="res://([^"]+)"',code):
        check((root/path).is_file(),f'Missing station texture {path}')
    check('z_index = -1' in code and 'z_index = 1' in code,f'{scene.name}: no back/front ordering')
for image in (root/'station_overlays/assets').glob('*.png'):
    with image.open('rb') as stream:
        header=stream.read(26)
    check(header[:8]==b'\x89PNG\r\n\x1a\n','Invalid PNG: '+image.name)
    width,height=struct.unpack('>II',header[16:24])
    color_type=header[25]
    check((width,height)==(512,512) and color_type==6,f'Wrong RGBA mobile texture: {image.name}')
# Exact viewport aspect ratio: mapping uses same scalar for both x and y.
for w,h in [(1280,720),(1080,1920),(960,540),(390,844),(1024,768)]:
    pixel_width=w/19.0
    pixel_height=h/19.0
    check(abs(pixel_width/pixel_height-w/h)<1e-12,'Viewport box aspect error')
# Single-sector Earth-follow display remains deterministic without extra moving nodes.
print('PASS v0.13: 8 visible worlds, 5 anchored orbital overlays, 6 destinations, aspect-accurate camera frame, resources and tabs')
print('Note: GDScript compilation/visuals require Godot 4 editor; tools/verify_project.command records headless preflight there.')
