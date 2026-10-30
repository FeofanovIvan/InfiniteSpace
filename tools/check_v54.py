#!/usr/bin/env python3
from pathlib import Path
import hashlib, json
root=Path(__file__).resolve().parent.parent
assert (root/'tools/check_v53.py').is_file()
s=(root/'scripts/ForeignTraffic.gd').read_text()
o=(root/'scripts/OtherSystem.gd').read_text()
assert 'const NATIVE_SYSTEMS: Array[String] = ["lmc", "smc", "ngc6822", "m33"]' in s
assert 'NGC6822_ART' in s and 'return NGC6822_ART' in s
assert '"glow":0.52, "nose_axis":PI * 0.5' in s
assert 'var cloud_count: int = 16' in o
assert 'var cloud_count: int = 36' in o
assert '_crossroads_world.z_index = 3' in o
assert 'cloud.z_index = 1' in o
assert 'root.z_index = 3' in o and '_story_station_root.z_index = 3' in o
assert '_add_system_background_nebulae(str(region.get("id", "")))' in o
assert 'func _system_nebula_palette(region_id: String)' in o
for region in ['mw','lmc','smc','ngc6822','m31','m33']:
    assert f'"{region}":' in o[o.index('func _system_nebula_palette'):o.index('func _add_system_background_nebulae')]
prov=json.loads((root/'assets/story/ngc6822_crop_provenance.json').read_text())
assert len(prov['ships']) == 5
for item in prov['ships']:
    f=root/'assets/story'/item['name']
    assert f.is_file()
    assert hashlib.sha256(f.read_bytes()).hexdigest()==item['sha256']
print('v54 STATIC PASS')
