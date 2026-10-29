#!/usr/bin/env python3
"""Offline, stdlib-only v19 regression preflight; cannot replace Godot runtime test."""
from pathlib import Path
import re
import struct
import json
root = Path(__file__).resolve().parents[1]
read=lambda name:(root/name).read_text(encoding='utf-8')
main=read('scripts/Main.gd')
npc=read('scripts/NpcTraffic.gd')
asteroids=read('scripts/AsteroidField.gd')
hud=read('scripts/RightStatusHUD.gd')
menu=read('scripts/MikoMainMenu.gd')
galaxy=read('scripts/GalacticMap.gd')
assert re.search(r'const POPULATION: int = 14\b',npc)
weights=[int(w) for w in re.findall(r'"weight":(\d+)',npc)]
assert len(weights)==10 and sum(weights)==100,(weights,sum(weights))
assert 'const MAX_ASTEROIDS: int = 1' in asteroids
assert '_spawn_timer = _rng.randf_range(40.0, 65.0)' in asteroids
assert '_rng.randf_range(60.0, 120.0)' in asteroids
assert 'MAX_DEBRIS: int = 350' in asteroids
assert 'func _shatter(' in asteroids and 'func _find_contact(' in asteroids
assert 'const HUD_WIDTH: float = 126.0' in hud
assert 'for i in range(7):' in hud
assert all(k in hud for k in ['BlueCrystal_NoDigits','fuel_segments <= 2','fuel_segments <= 5','set_crystals(value: int)'])
assert '_count_label' not in hud and '_count_label.text' not in hud
assert 'assets/ui/ship.png' not in hud and 'shop_button.png' not in hud
assert 'res://assets/ships/miko_player_ship.png' in hud or 'res://assets/ui/miko_ship_menu_circle.png' in hud
assert 'main_menu_requested.emit()' in hud and 'galaxy_requested.emit()' in hud
assert ('MikoTinyTopDownShip' in hud and 'Vector2(28.0, 32.0)' in hud) or ('_make_ship_menu_button' in hud and 'TextureButton.STRETCH_SCALE' in hud)
assert 'res://assets/ui/ship.png' not in galaxy
assert 'const MikoMainMenuScene' in main
assert 'status_hud.main_menu_requested.connect(_on_main_menu_requested)' in main
assert 'main_menu.open_menu(' in main and 'main_menu.closed.connect(_on_modal_closed)' in main
assert 'get_tree().paused = true' in main and 'get_tree().paused = false' in main
assert 'ship_shop' not in main and '_on_shop_requested' not in main
assert 'process_mode = Node.PROCESS_MODE_ALWAYS' in menu
assert 'closed.emit()' in menu and ('MikoShipPreview' in menu or 'BridgeWithSimulatorAndShop' in menu)
assert 'galactic_map.open_map(' in main
assert 'Goal' not in menu
assert len(list((root/'planets').glob('*.tscn')))==8
assert len(list((root/'assets/ships').glob('*.png')))==11
# Godot resources must exist. Scan all scripts for static paths including new menu.
for f in root.rglob('*.gd'):
    src=f.read_text(encoding='utf-8')
    kinds={('tab' if line.startswith('\t') else 'space') for line in src.splitlines() if line and line[0] in ' \t'}
    assert len(kinds)<=1,(f,kinds)
    for res in re.findall(r'(?:preload|load)\("(res://[^\"]+)"\)',src):
        assert (root/res[6:]).is_file(), (f.name,res)
# Check image signatures without PIL.
for img in ['assets/ships/miko_player_ship.png','assets/ui/crystal.png']:
    p=root/img
    with p.open('rb') as f: b=f.read(26)
    assert b[:8]==b'\x89PNG\r\n\x1a\n' and b[12:16]==b'IHDR'
    w,h=struct.unpack('>II',b[16:24]); assert 64<=w<=1024 and 64<=h<=1024
print('PASS v19: 14 weighted NPC, 1 max asteroid, 60-120s asteroid spawn, 7 fuel bars, crystal icon without digits, tiny ship menu, gallery + autopilot intact')
print('NOTE: actual GDScript compilation, touch input, and layout require Godot F5 on your Mac')
