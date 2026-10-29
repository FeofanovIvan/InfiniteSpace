#!/usr/bin/env python3
"""Static integrity checks for v0.9 UI/autopilot integration."""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[1]
scripts = ROOT / "scripts"
main = (scripts / "Main.gd").read_text()
solar = (scripts / "SolarSystem.gd").read_text()
menu = (scripts / "NavigationMenu.gd").read_text()
stop = (scripts / "AutoStopButton.gd").read_text()
assert main.count("_autopilot_active = true") == 1
assert main.count("_autopilot_active = false") == 1
assert 'auto_stop_button.visible = true' in main
assert 'joystick.visible = false' in main
assert 'auto_stop_button.visible = false' in main
assert 'joystick.visible = true' in main
assert 'velocity = Vector2.ZERO' in main
assert 'get_target_state(_autopilot_target)' in main
assert 'EarthStation' in solar and 'station_world_position' in solar
assert menu.count('preload("res://assets/destinations/') == 6
assert 'signal stop_requested()' in stop
assert 'if not is_visible_in_tree()' in (scripts / 'Joystick.gd').read_text()
for path in ROOT.rglob('*.gd'):
    code = path.read_text()
    for rel in re.findall(r'res://([^"\s]+)', code):
        if '%' in rel: continue
        if Path(rel).suffix in ('.gd', '.gdshader', '.png', '.jpg', '.tscn'):
            assert (ROOT / rel).is_file(), f"Missing: {rel} referenced by {path.name}"
print('PASS: six destinations, station, stop/joystick switch, preload links')
print('NOTE: Run tools/verify_project.command in Godot for actual GDScript parse validation.')
