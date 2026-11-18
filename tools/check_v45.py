#!/usr/bin/env python3
"""v45 static checks for native SMC fleet + final Triangulum gateway."""
from pathlib import Path
import json, sys
root=Path(__file__).resolve().parent.parent
traffic=(root/'scripts/ForeignTraffic.gd').read_text()
shader=(root/'shaders/alien_inner_light.gdshader').read_text()
other=(root/'scripts/OtherSystem.gd').read_text()
main=(root/'scripts/Main.gd').read_text()
nav=(root/'scripts/NavigationMenu.gd').read_text()
assert 'const HOME_SYSTEM: String = "smc"' in traffic
assert 'LOCAL_SHIP_COUNT: int = 7' in traffic
assert 'set_physics_process(false)' in traffic and '_available_ports()' in traffic
assert traffic.count('"role": "') == 5
for role in ('liner','scout','cargo','guard','diplomat'):
 assert f'"role": "{role}"' in traffic
assert '_choose_next_port' in traffic and 'light_tint' in traffic
assert 'M33_NativeFleet_FiveShipDesigns' not in main
assert 'SMC_NativeFleet_FiveShipClasses' in main
assert 'foreign_traffic.set_region(region_id)' in main
assert 'light_pos' in shader and 'inside' in shader and 'hull.a * 0.96' in shader
assert 'LAST_GATE_TEXTURE' in other and '_add_archive_nebula' in other
assert '_build_titan_asteroid_ring()' in other and 'TARANTULA_TEXTURE' in other
assert 'station_asset' in nav and 'station_art' not in nav
assert not any(line.startswith(' ') for line in other.splitlines() if line.strip())
for i in range(1, 6):
 p=root/'assets/story'/f'alien_ship_{i:02}.png'
 assert p.is_file(),str(p)
assert (root/'assets/story/last_gate_m33.png').read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
atlas=json.loads((root/'atlas/world_atlas.json').read_text())
ids=[s['id'] for s in atlas['systems']]
assert ids[-2:]==['m33','crossroads']
assert next(s for s in atlas['systems'] if s['id']=='m33')['station']['visual_asset']=='res://assets/story/last_gate_m33.png'
assert next(s for s in atlas['systems'] if s['id']=='smc')['station']['visual_asset']=='res://assets/story/living_archive_lotus.png'
print('check_v45: PASS — five SMC native classes; moving interior light; single M33 final gateway; previous content preserved.')
