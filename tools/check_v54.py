#!/usr/bin/env python3
from pathlib import Path
import hashlib, json
root = Path(__file__).resolve().parent.parent
# v53 baseline must still be present.
assert (root / 'tools/check_v53.py').is_file(), 'check_v53.py missing'
foreign = (root / 'scripts/ForeignTraffic.gd').read_text(encoding='utf-8')
other = (root / 'scripts/OtherSystem.gd').read_text(encoding='utf-8')
assert ('const NATIVE_SYSTEMS: Array[String] = ["lmc", "smc", "ngc6822", "m33"]' in foreign or 'const NATIVE_SYSTEMS: Array[String] = ["lmc", "smc", "ngc6822", "m31", "m33"]' in foreign)
for name in [
    'ngc6822_cargo_01.png','ngc6822_interceptor_02.png','ngc6822_patrol_03.png','ngc6822_liner_04.png','ngc6822_merchant_05.png'
]:
    assert name in foreign, f'missing preload for {name}'
assert 'return NGC6822_CLASSES' in foreign and 'return NGC6822_ART' in foreign
assert '"scout", "courier", "explorer", "interceptor":' in foreign
assert ('_region == "ngc6822"' in foreign or '"ngc6822":' in foreign)
assert 'var _system_nebulae: Array[ColorRect] = []' in other
assert 'var _system_nebula_data: Array[Dictionary] = []' in other
assert '_add_system_background_nebulae(str(region.get("id", "")))' in other
assert 'root.z_index = 3' in other
assert '_story_station_root.z_index = 3' in other
assert '_star_orb.z_index = 2' in other
assert 'func _system_nebula_palette(region_id: String) -> Array[Color]:' in other
assert 'var cloud_count: int = 16' in other
assert 'var cloud_count: int = 36' in other, 'v53 Crossroads density must not regress'
assert '_crossroads_world.z_index = 3' in other, 'living world must be in front of Crossroads gas'
assert 'var _system_nebula_data: Array[Dictionary]' in other
assert '"mw":' in other[other.index('func _system_nebula_palette'):], 'Solar system must also get background clouds'
assert '"glow":0.52, "nose_axis":PI * 0.5' in foreign, 'cargo nose must face down'
assert 'cloud.z_index = 1' in other
assert '_system_nebulae.append(cloud)' in other and '_system_nebula_data.append(info)' in other
assert 'for i in range(_system_nebulae.size()):' in other
prov = json.loads((root / 'assets/story/ngc6822_crop_provenance.json').read_text(encoding='utf-8'))
assert len(prov['ships']) == 5
for ship in prov['ships']:
    p = root / 'assets/story' / ship['name']
    assert p.is_file(), f'missing crop {ship["name"]}'
    assert hashlib.sha256(p.read_bytes()).hexdigest() == ship['sha256'], ship['name']
print('v54 STATIC PASS: Barnard fleet crops + all-system nebula background hooks')
