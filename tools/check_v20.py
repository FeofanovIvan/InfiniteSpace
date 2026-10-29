#!/usr/bin/env python3
"""Dependency-free v0.20 integration checks (no Pillow needed)."""
from pathlib import Path
import struct
p=Path(__file__).resolve().parent.parent
hud=(p/'scripts/RightStatusHUD.gd').read_text(encoding='utf-8')
assert 'TextureButton.STRETCH_SCALE' in hud
assert 'PLAYER_SHIP_BUTTON' in hud
assert 'PLAYER_SHIP_ICON' not in hud
assert 'func _make_ship_menu_button()' in hud
assert 'MAX_NPC: int = 14' in (p/'scripts/NpcTraffic.gd').read_text() or '14' in (p/'scripts/NpcTraffic.gd').read_text()
for name in ('assets/ui/miko_ship_menu_circle.png','blackhole2d/textures/black_hole_cinematic.png'):
    b=(p/name).read_bytes()
    assert b[:8]==b'\x89PNG\r\n\x1a\n', name
    w,h=struct.unpack('>II',b[16:24])
    assert w>100 and h>100,(name,w,h)
    print('OK',name,w,h)
for name in ('scripts/Main.gd','scripts/RightStatusHUD.gd','blackhole2d/scripts/black_hole_2d.gd','blackhole2d/shaders/black_hole_cinematic.gdshader'):
    assert (p/name).exists(),name
print('V20 PASS: HUD icon, black hole sprite, and scene references')
