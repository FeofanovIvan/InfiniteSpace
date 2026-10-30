#!/usr/bin/env python3
from pathlib import Path
p=Path(__file__).resolve().parent.parent/'scripts'/'OtherSystem.gd'
s=p.read_text(encoding='utf-8')
assert 'var _crossroads_storm_flash_index: int = -1' in s
assert 'Color(0.84, 0.22, 0.48)' in s and 'Color(0.76, 0.34, 1.0)' in s
assert 'set_storm_state", "surge" if sin(_time * 0.34) > 0.18 else "communicating"' in s
assert 'var flash_index: int = int(floor(_time / 1.35))' in s
start = s.find('if str(_region.get("id", "")) == "crossroads":')
end = s.find('\n\t\treturn', start)
block = s[start:end]
assert 'draw_arc(center' not in block
assert 'for shard in range(24):' in s
assert 'for bolt in range(8):' in s
assert 'for burst in range(9):' in s
print('v50 STATIC PASS')
