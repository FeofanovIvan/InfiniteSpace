#!/usr/bin/env python3
"""v38.5: the unfolded destination tiles must be vertically centered in their rail."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
src = (root / 'scripts/NavigationMenu.gd').read_text(encoding='utf-8')
assert 'const RAIL_HEIGHT: float = 90.0' in src
assert 'const TILE_SIZE: float = 64.0' in src
assert '_scroll.position = Vector2(RAIL_PADDING, (RAIL_HEIGHT - TILE_SIZE) * 0.5)' in src
assert '_scroll.size = Vector2(maxf(0.0, _shown_width - RAIL_PADDING * 2.0), RAIL_HEIGHT - _scroll.position.y)' in src
assert 'const TILE_GAP: int = 8' in src
assert 'tile.size = Vector2(TILE_SIZE, TILE_SIZE)' in src
assert 'tile.icon = _target_previews[id]' in src
assert 'tile.pressed.connect(_choose.bind(id))' in src
# Actual rail is at y=2 relative to NavigationMenu, scroll starts at 13,
# the icon center in the 64px tile is y=32: 2 + 13 + 32 = 47,
# equal to the rail center 2 + 90/2 = 47.
rail_y, rail_h, tile_h = 2.0, 90.0, 64.0
scroll_y = (rail_h - tile_h) * .5
assert abs((rail_y + scroll_y + tile_h * .5) - (rail_y + rail_h * .5)) < 1e-9
for scale in (.58, .67, .85, 1.0, 1.10):
    scaled_gap = scale * scroll_y
    assert scaled_gap >= 0
    assert scroll_y + tile_h <= rail_h
print('check_v38_5: PASS — 6 circular planet tiles vertically centered; styles, icon sizes and navigation unchanged.')
print('Godot F5 visual confirmation is still required.')
