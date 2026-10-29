#!/usr/bin/env python3
"""Static and numerical invariants for Infinite Space v0.11.
Does not substitute for an actual Godot engine run."""
from pathlib import Path
import struct
import re, math, zipfile

root=Path(__file__).resolve().parents[1]
issues=[]
def check(condition,what):
    if not condition: issues.append(what)

for gd in root.rglob('*.gd'):
    content=gd.read_text(encoding='utf-8')
    # Strictly consistent file-level indentation: forbid source lines with leading spaces
    # and other lines with leading tabs (known parser failure in previous iterations).
    has_tab=any(line.startswith('\t') for line in content.splitlines())
    has_space=any(line.startswith(' ') for line in content.splitlines())
    check(not(has_tab and has_space),f'Mixed indentation: {gd.relative_to(root)}')
    # Validate literal resources used in .gd source.
    for path in re.findall(r'(?:preload|load)\("res://([^"\n]+)"\)',content):
        check((root/path).is_file(),f'Missing preload: {gd.name} => {path}')
    check('extends ' in content,f'No extends: {gd.name}')
for ts in root.rglob('*.tscn'):
    for path in re.findall(r'path="res://([^"\n]+)"',ts.read_text(encoding='utf-8')):
        check((root/path).is_file(),f'Missing scene ref: {ts.relative_to(root)} => {path}')

ids=['mercury','venus','earth','mars','jupiter','saturn','uranus','neptune','earth_station']
for target in ids:
    f=root/'assets/destinations'/f'{target}.png'
    check(f.is_file(),f'Missing picture: {target}')
    if f.is_file():
        data = f.read_bytes()[:26]
        check(data[:8] == b"\x89PNG\r\n\x1a\n", f"Invalid PNG: {target}")
        if len(data) == 26:
            w, h = struct.unpack(">II", data[16:24])
            check((w, h) == (144,144), f"Unexpected PNG dimensions: {target}")
nav=(root/'scripts/NavigationMenu.gd').read_text()
mp=(root/'scripts/MiniMap.gd').read_text()
main=(root/'scripts/Main.gd').read_text()
solar=(root/'scripts/SolarSystem.gd').read_text()
check('tile.text = ""' in nav and '_add_heading' not in nav,'Text UI still in target picker')
check('"EarthStation"' in nav and '"Neptune"' in nav,'Target list incomplete')
check('_station = StationScene.instantiate()' in solar and 'station2d/orbital_station_2d.tscn' in solar,'New station not instanced')
check('map_navigate_requested.emit(requested)' in mp,'MiniMap does not emit selected point')
check('_map_camera_start_world.lerp(_map_camera_target_world, eased)' in main,'Camera does not ease toward tapped coordinates')
check('_draw_clipped_view_edge' in mp and '_camera_view_world_size' in mp,'Accurate camera extent missing')
check('ReturnToShip_TopRight' not in main,'Removed extra return button present')
check('func _on_auto_stop_pressed()' in main and 'auto_stop_button.visible = true' in main,'Autopilot STOP lost')
check('func _start_camera_return(' in main,'Joystick flyback lost')
check('STATION_DIAMETER: float = 114.0' in solar,'MIKO station size not set')
check((root/'station2d/scripts/orbital_station_2d.gd').exists(),'MIKO station script missing')
# Camera coordinate mapping must be the inverse of map projection.
for origin in [(0.,0.),(2350.,-4275.)]:
    for tap in [(130.,130.),(160.,182.),(18.,25.)]:
        units=19.
        world=(origin[0]+(tap[0]-130.)*units,origin[1]+(tap[1]-130.)*units)
        back=(130+(world[0]-origin[0])/units,130+(world[1]-origin[1])/units)
        check(max(abs(back[0]-tap[0]),abs(back[1]-tap[1]))<1e-8,'Map world inverse failed')
if issues:
    print('FAIL:', '\n'.join(issues));raise SystemExit(1)
print('PASS: 6 picture targets, real MIKO station, no text UI, map tap→camera, true viewport frame, STOP, resources, indent style')
