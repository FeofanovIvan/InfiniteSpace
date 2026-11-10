#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parent.parent
other=(root/'scripts/OtherSystem.gd').read_text()
traffic=(root/'scripts/ForeignTraffic.gd').read_text()
npc=(root/'scripts/NpcTraffic.gd').read_text()
assert 'LastGateFX.new()' in other
assert 'LastGate_RealNebula_' in other
assert 'station_region_id == "m33"' in other
assert 'const HOME_SYSTEM: String = "smc"' in traffic
assert 'ShipMotionFX.new()' in traffic
assert 'nose of all five top-down SMC PNGs' in traffic
assert 'Face the actual outward departure path first' in npc
assert 'Lock the jump vector to the visible nose' in npc
for name in ['scripts/LastGateFX.gd','scripts/ShipMotionFX.gd']:
 assert (root/name).is_file(),name
assert not any(s.startswith(' ') for s in other.splitlines() if s.strip())
print('check_v46: PASS — static only (Godot runtime not executed)')
