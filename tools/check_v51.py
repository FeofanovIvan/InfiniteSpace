#!/usr/bin/env python3
from pathlib import Path
import json
import struct
p=Path(__file__).resolve().parent.parent
s=(p/'scripts/ForeignTraffic.gd').read_text()
assert 'const NATIVE_SYSTEMS: Array[String] = ["lmc", "smc", "m33"]' in s
assert 'LMC_ART' in s and 'LMC_CLASSES' in s and 'func _texture_library()' in s
assert '"freighter"' in s and '"merchant"' in s and '"explorer"' in s and '"escort"' in s
assert 'var forward: Vector2 = Vector2.from_angle(image.rotation + nose_axis)' in s
assert 'if not bool(body.get("inhabited", false))' in s
assert '"landing"' in s and '"takeoff"' in s and '"dash"' in s
for name in ['merchant_01','shuttle_02','freighter_03','explorer_04','escort_05']:
    file=p/('assets/story/lmc_'+name+'.png')
    assert file.is_file(),file
    b=file.read_bytes()
    assert b[:8]==bytes.fromhex('89504e470d0a1a0a') and b[12:16]==b'IHDR'
    assert b[25]==6, f'{name}: expected RGBA PNG'
    w,h=struct.unpack('>II',b[16:24])
    assert w>300 and h>250,(name,w,h)
print('v51 STATIC PASS - five original LMC sprites and native traffic routes')
