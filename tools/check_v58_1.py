#!/usr/bin/env python3
from pathlib import Path
import hashlib
r=Path(__file__).resolve().parent.parent
b=(r/'assets/story/tarantula_lab_ship.png').read_bytes()
assert hashlib.sha256(b).hexdigest()=="b639efa725a849c06576a4eb783d4f9f686fb642df91c48dd470288757aaca1c", 'New Tarantula PNG mismatch'
assert b[:8]==bytes.fromhex('89504e470d0a1a0a'), 'PNG signature'
other=(r/'scripts/OtherSystem.gd').read_text(encoding='utf-8')
assert '_station_sprite.scale = Vector2.ONE * 0.294' in other
assert '_station_sprite.rotation = _time * 0.022' in other
assert '_tarantula_thrusters = TarantulaThrusters.new()' not in other
assert 'const TARANTULA_TEXTURE: Texture2D = preload("res://assets/story/tarantula_lab_ship.png")' in other
assert (r/'tools/check_v58.py').is_file()
print('v58.1 STATION PASS: original radial art, no displaced old exhaust, positioning unchanged')
