#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,math,struct
r=Path(__file__).resolve().parent.parent
assert (r/'tools/check_v54.py').is_file(),'v54 missing'
s=(r/'scripts/ForeignTraffic.gd').read_text(encoding='utf8')
assert 'const NATIVE_SYSTEMS: Array[String] = ["lmc", "smc", "ngc6822", "m31", "m33"]' in s
assert 'const M31_ART: Array[Texture2D]' in s and 'const M31_CLASSES: Array[Dictionary]' in s
assert 'return M31_ART' in s and 'return M31_CLASSES' in s
assert '"m31":\n            _rng.seed = 731198' in s
assert 'wake.rotation = float(info.get("nose_axis", 0.0))' in s
assert '"nose_axis":-PI*0.5' in s and '"nose_axis":0.0' in s
assert '"guard", "patrol", "escort", "guardian":' in s
assert '"scout", "courier", "explorer", "interceptor":' in s
assert 'if not bool(body.get("inhabited", false))' in s
for mode in ['"approach"','"hover"','"landing"','"docked"','"takeoff"','"depart"','"align_jump"','"charge"','"dash"']:
    assert mode in s,mode
provenance=json.loads((r/'assets/story/m31_crop_provenance.json').read_text(encoding='utf8'))
assert len(provenance['ships'])==5
for record in provenance['ships']:
    path=r/'assets/story'/record['file']
    assert path.is_file(),path
    assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256'],path
    raw=path.read_bytes()
    assert raw[:8]==bytes.fromhex('89504e470d0a1a0a')
    assert raw[25]==6, 'PNG must preserve RGBA alpha channel'
    assert struct.unpack('>II',raw[16:24])==tuple(record['cutout_dimensions'])
assert math.isclose(provenance['ships'][0]['nose_axis'],-math.pi/2)
assert math.isclose(provenance['ships'][2]['nose_axis'],-math.pi/2)
print('v55 STATIC PASS: 5 original M31 RGBA ships, NPC routes and nose orientations')
