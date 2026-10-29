#!/usr/bin/env python3
"""Static checks for v14. Godot actual parser and rendering must be tested on Mac."""
from pathlib import Path
import re, zipfile, struct
root=Path(__file__).resolve().parents[1]
main=(root/'scripts/Main.gd').read_text()
mini=(root/'scripts/MiniMap.gd').read_text()
region=(root/'scripts/CosmicRegion.gd').read_text()
assert 'DEBUG_SHOW_BLACK_HOLE_ON_MAP: bool = true' in main
assert 'set_debug_landmark(CosmicRegionScene.BLACK_HOLE_WORLD, DEBUG_SHOW_BLACK_HOLE_ON_MAP)' in main
assert 'BLACK_HOLE_WORLD: Vector2 = Vector2(6500.0, -2950.0)' in region
assert 'GALAXY_CENTER: Vector2 = Vector2(6900.0, -3100.0)' in region
assert 'set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2)' in region
assert '_update_black_hole_position()' in main
assert 'black_hole = BlackHoleScene.instantiate() as Node2D' in main
assert 'set_debug_landmark(world_position: Vector2, enabled: bool)' in mini
assert 'map_navigate_requested.emit(_debug_landmark_world)' in mini
assert '_draw_camera_marker()' in mini
assert (root/'assets/cosmic/milky_way_2048.png').exists()
assert (root/'blackhole2d/black_hole_2d.tscn').exists()
assert (root/'blackhole2d/shaders/black_hole_2d.gdshader').exists()
assert (root/'blackhole2d/textures/white_quad.png').exists()
with (root/'assets/cosmic/milky_way_2048.png').open('rb') as f:
    header=f.read(26)
assert header[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',header[16:24])==(2048,1024)
for path in root.rglob('*.gd'):
    text=path.read_text()
    lines=[line for line in text.splitlines() if line.strip()]
    assert not (any(l.startswith(' ') for l in lines) and any(l.startswith('\t') for l in lines)),f'Mixed indentation: {path}'
    for res in re.findall(r'res://([^"\s]+)', text):
        if Path(res).suffix in ('.tscn','.gd','.gdshader','.png','.jpg'):
            assert (root/res).is_file(),f'{path.name}: missing res://{res}'
menu=(root/'scripts/NavigationMenu.gd').read_text()
assert 'EarthStation' in menu and 'Neptune' in menu
assert len(list((root/'planets').glob('*.tscn')))==8
print('PASS v0.14 static: black hole module, anchored Milky Way, debug marker, 8 planets, camera frame, art assets')
print('NOTE: Godot parser, mobile rendering and on-screen visual tests require running Godot on your Mac.')
