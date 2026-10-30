#!/usr/bin/env python3
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
traffic=(root/'scripts/ForeignTraffic.gd').read_text()
assert 'const HOME_SYSTEM: String = "m33"' in traffic
assert 'if _region != HOME_SYSTEM:' in traffic
assert 'LOCAL_SHIP_COUNT: int = 7' in traffic
assert 'VisitingEarthFreighter' not in traffic
assert 'EARTH_VISITORS' not in traffic
assert 'FOREIGN_VESSELS' not in traffic
assert 'var next_port:' in traffic
assert (root/'shaders/alien_inner_light.gdshader').exists()
shader=(root/'shaders/alien_inner_light.gdshader').read_text()
assert 'hull.a * 0.95' in shader
assert 'light_pos' in shader
other=(root/'scripts/OtherSystem.gd').read_text()
assert '_build_titan_asteroid_ring()' in other
assert '_add_titan_nebula()' in other
assert 'PYRAMID_TEXTURE' in other and 'TITAN_SKULL_TEXTURE' in other
assert 'TITAN_ASTEROID_TEXTURES' in other
main=(root/'scripts/Main.gd').read_text()
assert 'foreign_traffic.set_region(region_id)' in main
assert 'M33_NativeFleet_FiveShipDesigns' in main
assert 'UPPER_RIGHT_UI_GROWTH' in main
assert 'FOREIGN_VESSELS' not in traffic
for i in range(1,6):
 assert (root/'assets/story'/f'alien_ship_{i:02}.png').exists()
assert (root/'assets/story/titan_skull_ngc6822.png').exists()
assert (root/'assets/story/inverted_pyramid_m31.png').exists()
obj=json.loads((root/'atlas/world_atlas.json').read_text())
for region in obj['systems']:
 if region['id']=='ngc6822':
  assert 'titan_skull_ngc6822.png' in region['station']['visual_asset']
 if region['id']=='m31':
  assert 'inverted_pyramid_m31.png' in region['station']['visual_asset']
print('check_v44: PASS — one native M33 fleet, no intersystem ships, Titan/pyramid assets, existing UI.')
