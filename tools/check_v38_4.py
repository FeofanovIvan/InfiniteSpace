#!/usr/bin/env python3
from pathlib import Path
import struct
r=Path(__file__).resolve().parents[1]
s=(r/'scripts/RightStatusHUD.gd').read_text()
fragment=r/'asteroid_assets/fragments/04_blue/crystal_wedge.png'
assert fragment.is_file()
data=fragment.read_bytes()
assert data[:8]==b"\x89PNG\r\n\x1a\n"
assert struct.unpack('>II',data[16:24])==(320,320)
assert 'preload("res://asteroid_assets/fragments/04_blue/crystal_wedge.png")' in s
assert 'preload("res://assets/ui/crystal.png")' not in s
assert 'panel.clip_contents = true' in s
assert '_crystal_icon = Sprite2D.new()' in s
assert '_crystal_icon.position = Vector2(100.0, 17.0)' in s
assert '_crystal_icon.scale = Vector2.ONE * 0.075' in s
assert 'panel.add_child(_crystal_icon)' in s
assert 'for i in range(7):' in s and 'seg.position = Vector2(10.0 + float(i) * 10.0, 11.0)' in s
assert 'if fuel_segments <= 2:' in s and 'elif fuel_segments <= 5:' in s
assert 'Color("4bde80")' in s and 'Color("ffd459")' in s and 'Color("fa585b")' in s
assert 'Vector2(HUD_WIDTH, 34.0)' in s
# 320x320 sprite scaled to 24px, entirely within the fuel strip x=0..126 y=0..34.
assert 100-320*.075/2 >= 78+8
assert 100+320*.075/2 < 126
assert 17-320*.075/2 >= 0
assert 17+320*.075/2 < 34
print('v38.4: PASS — exact blue asteroid fragment, small and inside 7-segment fuel bar; colour thresholds unchanged.')
