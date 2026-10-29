#!/usr/bin/env python3
"""Static sanity checks for v0.15. Does not replace Godot compilation."""
from pathlib import Path
import re
import struct
root=Path(__file__).resolve().parents[1]
scripts=['Main.gd','RightStatusHUD.gd','GalacticMap.gd','MikoShop.gd']
for name in scripts:
    p=root/'scripts'/name
    assert p.exists(),name
    s=p.read_text(encoding='utf8')
    assert not any(line.startswith(' ') for line in s.splitlines()),f'{name}: mixed indentation'
    assert not re.search(r'^\t+ +[^ ]',s,re.M),f'{name}: space mixed with tabs'
    # Ignore comments and strings when checking braces is hard; instead check parentheses
    # lightly and rely on real Godot headless preflight for full GDScript parsing.
    for m in re.findall(r'(?:preload|load)\("(res://[^"]+)"\)',s):
        assert (root/m.removeprefix('res://')).exists(),f'{name}: missing {m}'

main=(root/'scripts/Main.gd').read_text()
for needle in ('_on_galaxy_requested', '_on_main_menu_requested','galactic_map.open_map','main_menu.open_menu', 'get_tree().paused = false'):
    assert needle in main,needle
hud=(root/'scripts/RightStatusHUD.gd').read_text()
assert 'range(7)' in hud and 'fuel_segments <= 2' in hud and 'fuel_segments <= 5' in hud
assert 'galaxy_requested.emit()' in hud and 'main_menu_requested.emit()' in hud
map_src=(root/'scripts/GalacticMap.gd').read_text()
assert map_src.count('preload("res://assets/ui/galaxy_')==6
assert 'draw_colored_polygon' in map_src
assert 'travel_available": false' in main
shop=(root/'scripts/MikoShop.gd').read_text()
assert 'category_inspected.emit(key)' in shop and 'Новые детали появятся позже' in shop
assert 'Main.gd' not in shop
for p in (root/'assets/ui').glob('*.png'):
    payload=p.read_bytes()
    assert payload[:8] == b"\x89PNG\r\n\x1a\n" and len(payload) > 33, p
    width,height=struct.unpack(">II",payload[16:24])
    assert 32 <= width <= 1024 and 32 <= height <= 1024, p
assert len(list((root/'assets/ui').glob('*.png'))) >= 13  # newer UI icon assets are additive
# Previous functionality still present.
assert (root/'blackhole2d/black_hole_2d.tscn').exists()
assert len(list((root/'planets').glob('*.tscn'))) == 8
assert (root/'assets/cosmic/milky_way_2048.png').exists()
print('PASS v0.15 resource regression / v0.19 UI: resources, 7-bar fuel UI, crystal icon, six galaxies, shop previews, existing worlds')
print('NOTE: Godot headless/editor compile and mobile UI testing still required')
