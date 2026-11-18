#!/usr/bin/env python3
"""Static v60.1.1 check: Godot F5 is needed for runtime validation."""
import sys, re
from pathlib import Path

def check(root: Path) -> None:
    p = root / 'planet_hub/scripts/representative_dialog.gd'
    source=p.read_text(encoding='utf-8')
    assert '_back_button.move_to_front()' in source, 'missing Godot 4 button z-order method'
    assert '_back_button.raise()' not in source, 'deprecated Godot 3 raise() remains'
    assert '_planet_name: String' in source, 'unused parameter not prefixed'
    assert 'tablet.position = Vector2(split, 0)' in source, 'full-height right tablet must remain'
    assert 'tablet.size = Vector2(w - split, h)' in source, 'full-height tablet sizing changed'
    for other in (root/'planet_hub/scripts').glob('*.gd'):
        assert not re.search(r'\.raise\s*\(', other.read_text(encoding='utf-8')), f'legacy raise() in {other}'
    assert (root/'tools/check_v60_1.py').exists(), 'v60.1 base missing'
    print('v60.1.1 STATIC PASS: Godot4 move_to_front, warning, preserved layout')

if __name__ == '__main__':
    check(Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path.cwd())
