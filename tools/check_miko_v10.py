#!/usr/bin/env python3
"""Offline checks for integration of MIKO Solar System V3 into Infinite Space."""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
scripts = root / 'scripts'
solar = (scripts / 'SolarSystem.gd').read_text(encoding='utf-8')
menu = (scripts / 'NavigationMenu.gd').read_text(encoding='utf-8')
main = (scripts / 'Main.gd').read_text(encoding='utf-8')
joystick = (scripts / 'Joystick.gd').read_text(encoding='utf-8')
assert 'PlanetPrototype.gd' not in solar
assert 'PLANET_SCENES' in solar
assert 'get_target_state' in solar and 'EarthStation' in solar
assert 'auto_stop_button.visible = true' in main and 'joystick.visible = false' in main
assert 'auto_stop_button.visible = false' in main and 'joystick.visible = true' in main
assert menu.count('preload("res://assets/destinations/') == 6
catalog = json.loads((root / 'planet2d/configs/solar_system.json').read_text(encoding='utf-8'))
ids = catalog['order']
assert len(ids) == 8 and len(set(ids)) == 8
for planet in ids:
    scene = (root / 'planets' / f'{planet}.tscn')
    assert scene.is_file(), scene
    text = scene.read_text(encoding='utf-8')
    assert f'planet_id = "{planet}"' in text or planet == 'earth', scene
    for component in ('RingBack', 'Globe', 'RingFront'):
        assert f'name="{component}"' in text, (scene, component)
    assert (root / 'planet2d/textures' / f'{planet}_surface.jpg').is_file(), planet
    assert f'res://planets/{planet}.tscn' in solar, planet
for p in (root / 'planet2d/textures').glob('*.png'):
    assert p.stat().st_size > 50, p
assert 'rings' in catalog['planets']['saturn'] and catalog['planets']['saturn']['rings']
assert (root / 'planet2d/shaders/planet_globe.gdshader').is_file()
assert (root / 'planet2d/textures/saturn_ring_front.png').is_file()
assert (root / 'planet2d/textures/saturn_ring_back.png').is_file()
# Catch mixed indentation (original v0.9 error): a GDScript file may use tabs OR spaces but not both.
for f in root.rglob('*.gd'):
    styles = set()
    for line_number, line in enumerate(f.read_text(encoding='utf-8').splitlines(), 1):
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        indent = line[:len(line)-len(line.lstrip(' \t'))]
        if ' ' in indent and '\t' in indent:
            raise AssertionError(f'mixed line indent {f}:{line_number}')
        if '\t' in indent:
            styles.add('tab')
        if ' ' in indent:
            styles.add('space')
    assert len(styles) <= 1, f'mixed indentation style {f}: {styles}'
assert '\n\t_touch_id = -1\n\t_mouse_down = false\n' in joystick
assert '\n\tif not is_visible_in_tree():\n\t\treturn\n' in joystick
# Resolution of every literal resource link in scripts, shader source and scene files.
missing = []
for p in list(root.rglob('*.gd')) + list(root.rglob('*.tscn')) + list(root.rglob('*.gdshader')):
    for ref in re.findall(r'res://([^"\'\s]+)', p.read_text(encoding='utf-8')):
        if Path(ref).suffix in {'.tscn', '.gd', '.gdshader', '.json', '.png', '.jpg'} and not (root / ref).exists():
            missing.append((p.name, ref))
assert not missing, missing
print('PASS: eight MIKO V3 planet scenes, textures, shaders and Saturn rings')
print('PASS: joystick tabs, consistent script indentation, linked resources')
print('PASS: six navigation destinations and original autopilot/stop toggle')
print('NOTE: Godot editor preflight and Android frame-rate test must run on your Mac.')
