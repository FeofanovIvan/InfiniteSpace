from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
script = (ROOT / 'scripts' / 'OtherSystem.gd').read_text(encoding='utf-8')

def ok(msg):
    print('PASS', msg)

assert 'const M31_SCENES' in script, 'M31 scene library missing'
ok('M31 scene library wired into OtherSystem')
assert 'const M33_SCENES' in script, 'M33 scene library missing'
ok('M33 scene library wired into OtherSystem')
assert 'const STATION_SHELL_VARIANTS' in script, 'station shell library missing'
ok('orbital ring station variants available in OtherSystem')
assert ('func _build_planet_station_cluster' in script or 'func _build_planet_orbital_ring' in script), 'orbital station builder missing'
ok('station builder exists')
assert 'func _planet_supports_civil_station' in script, 'inhabited-planet selector missing'
ok('inhabited world selector exists')
assert ('shells_to_spawn: int = 2 + int(rng.randi() % 2)' in script or 'const SYSTEM_RING_COUNTS' in script), 'station count specification missing'
ok('ring station count configuration exists')
assert '"m31":' in script and 'return M31_SCENES' in script, 'M31 not returned by region library'
assert '"m33":' in script and 'return M33_SCENES' in script, 'M33 not returned by region library'
ok('region library returns M31 and M33 scene sets')

for folder in ['m31_planets', 'm33_planets']:
    root = ROOT / folder
    assert root.is_dir(), f'{folder} directory missing'
    planet_files = sorted((root / 'planets').glob('*.tscn'))
    assert len(planet_files) == 8, f'{folder}: expected 8 planet scenes, got {len(planet_files)}'
    assert (root / 'catalog.json').is_file(), f'{folder}: catalog missing'
    ok(f'{folder} integrated with 8 planet scenes and catalog')

atlas = json.loads((ROOT / 'atlas' / 'world_atlas.json').read_text(encoding='utf-8'))
systems = {system['id']: system for system in atlas['systems']}
for region_id in ['m31', 'm33', 'lmc', 'smc', 'ngc6822']:
    assert region_id in systems, f'{region_id} missing from atlas'
    story_worlds = [p for p in systems[region_id].get('planets', []) if p.get('story', False)]
    assert len(story_worlds) >= 3, f'{region_id}: expected at least 3 inhabited/story worlds'
    ok(f'{region_id} atlas data contains inhabited worlds for ring stations')

print('check_v32: OK')
