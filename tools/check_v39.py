#!/usr/bin/env python3
"""V39 focused static assertions: correct story art, remote placements, navigation."""
from pathlib import Path
import json, math
import struct
P=Path(__file__).resolve().parents[1]
other=(P/'scripts/OtherSystem.gd').read_text()
nav=(P/'scripts/NavigationMenu.gd').read_text()
mini=(P/'scripts/MiniMap.gd').read_text()
main=(P/'scripts/Main.gd').read_text()
a=json.loads((P/'atlas/world_atlas.json').read_text())
regions={s['id']:s for s in a['systems']}
for reg, station, art in [('lmc','st_lmc','tarantula_lab_ship.png'), ('smc','st_smc','living_archive_lotus.png')]:
    assert regions[reg]['station']['id']==station
    assert regions[reg]['station']['visual_asset']=='res://assets/story/'+art
    assert (P/'assets/story'/art).is_file()
    assert station in mini
assert ('TARANTULA_ANCHOR' in other and 'ARCHIVE_ANCHOR' in other) or 'STORY_STATION_ANCHORS' in other
assert ('ARCHIVE_HAZE_TEXTURE' in other and 'LivingArchive_AtmosphericMist' in other) or ('ARCHIVE_NEBULA_SHADER' in other and 'LivingArchive_NebulaCloud_' in other)
assert 'TARANTULA_TEXTURE' in other and 'ARCHIVE_TEXTURE' in other
assert '"velocity": _station_velocity()' in other
assert '"kind": "station"' in other
assert 'load(station_asset) as Texture2D' in nav
assert 'return 3400.0' in main or 'return 3220.0' in main
# Far enough from the sun/planet orbits for clear separation, but reachable in free flight.
# Actual station coordinates, world boundary and destination velocities are verified by check_v40.py.
for filename in ('living_archive_lotus.png','tarantula_lab_ship.png','living_archive_haze.png'):
    raw=(P/'assets/story'/filename).read_bytes()
    assert raw.startswith(b'\x89PNG\r\n\x1a\n')
    assert raw[25]==6, f'{filename} must be RGBA PNG'
assert (P/'assets/story/living_archive_lotus.png').stat().st_size > 100_000
print('check_v39: PASS — separate deep-space LMC/SMC story objects, navigation, haze, visible alpha, reachable radius')
print('Godot parser/F5 and real mobile rendering NOT verified in this container.')
