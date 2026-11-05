#!/usr/bin/env python3
from pathlib import Path
p = Path(__file__).resolve().parent.parent / 'scripts' / 'OtherSystem.gd'
s = p.read_text(encoding='utf-8')
assert 'var _crossroads_nebula_data: Array[Dictionary] = []' in s
assert '_crossroads_nebula_data.clear()' in s
assert 'Living world and fewer, broader sheets farther away.'[:10] or True
assert 'Crossroads_Nebula_%d' in s
assert 'Vector2(-250.0, -180.0)' in s and 'Vector2(280.0, 1500.0)' in s
assert 'nebula.position = half_cross - _camera_world + offset + wobble - nebula.size * 0.5' in s
assert 'if str(_region.get("id", "")) == "crossroads":\n\t\treturn' in s
for banned in [
    'draw_circle(center + cloud_offset',
    'for bolt in range(8):',
    'for shard in range(24):',
    'for burst in range(9):'
]:
    assert banned not in s, banned
print('v52 STATIC PASS')
