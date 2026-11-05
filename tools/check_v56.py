#!/usr/bin/env python3
"""Static release and relationship checks; does not replace the Godot F5 test."""
from pathlib import Path
import re
root = Path(__file__).resolve().parent.parent
f = (root/'scripts/ForeignTraffic.gd').read_text(encoding='utf8')
assert (root/'tools/check_v55.py').is_file()
assert 'const MAX_ACTIVE_TRADE_TRIPS: int = 2' in f
assert 'const TRADE_LAUNCH_INTERVAL: float = 65.0' in f
assert 'const TRADE_ROLES: Array[String] = ["cargo", "freighter", "merchant", "liner", "shuttle"]' in f
assert '"mw": ["lmc", "ngc6822"]' in f
assert '"lmc": ["smc", "mw"]' in f
assert '"smc": ["lmc"]' in f
assert '"ngc6822": ["mw"]' in f
assert '"m31": ["m33"]' in f
assert '"m33": ["m31"]' in f
assert '"crossroads"' not in f[f.index('const TRADE_NEIGHBORS:'):f.index('const TRADE_ROLES:')]
for name in [
    '_reserve_trade', '_queue_transfer', '_save_departing_visitors',
    '_spawn_trade_arrivals', '_prune_offscreen_transfers', '_start_warp_arrival',
    '_spawn_ambient_trader', '_class_library_for', '_texture_library_for',
]:
    assert 'func '+name+'(' in f,name
assert '_save_departing_visitors()\n    _prune_offscreen_transfers()' in f
assert 'visible = NATIVE_SYSTEMS.has(_region) or _region == "mw"' in f
assert 'var next_system: String = str(item.get("transfer_to", ""))' in f
assert 'item["mode"] = "offworld"' in f
assert 'item["mode"] = "warp_in"' in f
assert 'item["world"] = entry_a.lerp(entry_b, entry_t)' in f
assert 'image.rotation = entry_direction.angle() - nose_axis' in f
assert 'var data: Dictionary = _class_library_for(str(item["home_system"]))' in f
assert 'if mode == "dash":\n            image.modulate.a' in f
assert 'MAX_ACTIVE_TRADE_TRIPS' in f[f.index('func _reserve_trade'):f.index('func _queue_transfer')]
assert not re.search(r'(?m)^\s*(?:extends|func)\s+.*\x00',f)
print('v56 STATIC PASS: neighboring trade, max 2 ships, destination manifest and nose-first arrival')
