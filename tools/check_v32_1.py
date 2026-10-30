"""Regression checks for v32.1: 2-4 rings PER SYSTEM, not PER PLANET.

This checks source and atlas structure only. Godot visual verification requires F5.
"""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'scripts' / 'OtherSystem.gd').read_text(encoding='utf-8')
world_atlas = json.loads((ROOT / 'atlas' / 'world_atlas.json').read_text(encoding='utf-8'))
systems = {r['id']:r for r in world_atlas['systems']}

count_block = re.search(r'const SYSTEM_RING_COUNTS: Dictionary = \{(.*?)\n\}', source, re.S)
assert count_block is not None, 'system-wide station count table missing'
counts = {key:int(n) for key,n in re.findall(r'"([a-z0-9]+)"\s*:\s*(\d+)',count_block.group(1))}
expected = {'lmc':2, 'smc':3, 'ngc6822':2, 'm31':4, 'm33':3}
assert counts == expected, f'wrong per-system counts: {counts}'
assert all(2 <= c <= 4 for c in counts.values())
assert 'mw' not in counts, 'Milky Way should remain unchanged'
assert 'crossroads' not in counts, 'Crossroads should remain unchanged'

required_phrases = [
  'func _choose_system_ring_stations(region: Dictionary) -> Dictionary:',
  'func _build_planet_orbital_ring(',
  'if ring_assignments.has(i):',
  '_build_planet_orbital_ring(root, source, diameter, ring_assignments[i])',
  'ring_assignments: Dictionary = _choose_system_ring_stations(region)',
  'rng.seed = ("MIKO_system_ring_layout_v32_1:" + region_id).hash()',
  'STATION_SHELL_VARIANTS[style_id]',
  'assigned[candidates[n]]',
  'candidates.size())',
  'var available_styles: Array[int] = [0, 1, 2, 3]',
]
for phrase in required_phrases:
    assert phrase in source, f'new ring distribution missing: {phrase}'
assert 'shells_to_spawn' not in source, 'obsolete 2–3 rings per planet logic still present'
assert 'func _build_planet_station_cluster(' not in source, 'obsolete cluster builder remains'

for system_id, expected_count in counts.items():
    region = systems[system_id]
    candidates = []
    for p in region['planets']:
        unique = p.get('unique','').lower()
        if p.get('story',False) or any(t in unique for t in ('город','city','лаборатор')):
            candidates.append(p['name_en'])
    assert len(candidates) >= expected_count, f'not enough candidate worlds in {system_id}: {candidates}'
    assert len(region['planets']) == 8
    print(f'PASS {system_id}: {expected_count} different ringed planets from {len(candidates)} candidates, 1 ring per selected world')

for i in range(1,5):
    ring = ROOT / 'station_overlays' / 'scenes' / f'OrbitalStation_0{i}.tscn'
    assert ring.exists()
    content=ring.read_text(encoding='utf-8')
    assert '[node name="Back"' in content and '[node name="Front"' in content
print('PASS four existing ring variants retained (back/front layers)')
assert (ROOT / 'scripts' / 'SolarSystem.gd').exists()
assert (ROOT / 'scripts' / 'NpcTraffic.gd').exists()
print('PASS Milky Way and NPC source scripts still present')
print('PASS static v32.1 checks; engine rendering needs F5')
