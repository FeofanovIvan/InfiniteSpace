#!/usr/bin/env python3
from pathlib import Path
import json
p=Path(__file__).resolve().parent.parent
j=json.loads((p/'atlas/world_atlas.json').read_text())
counts={}
for s in j['systems']:
    inhabited=[x for x in s.get('planets',[]) if x.get('inhabited') is True]
    assert all(x.get('landing')=='landing' for x in inhabited),s['id']
    counts[s['id']]=len(inhabited)+(1 if (s.get('station') or {}).get('accessible',False) else 0)
assert counts['mw'] != 6 and counts['m33'] >= 2
nav=(p/'scripts/NavigationMenu.gd').read_text()
assert 'if not bool(data.get("inhabited", false)):' in nav
assert 'set_available_width(_available_width)' in nav
traffic=(p/'scripts/ForeignTraffic.gd').read_text()
assert 'NATIVE_SYSTEMS.has(_region)' in traffic
assert 'M33_CLASSES' in traffic and 'M33_ART' in traffic
assert 'bool(body.get("inhabited", false))' in traffic
assert 'nose_axis' in traffic
main=(p/'scripts/Main.gd').read_text()
assert 'if not bool(planet.get("inhabited", false)):' in main
assert 'station_distance' in main
npc=(p/'scripts/NpcTraffic.gd').read_text()
assert 'var accessible_ports: Dictionary = {}' in npc
assert 'if accessible_ports.has(str(body.get("name", ""))):' in npc
for nm in ['civilian_01','merchant_02','courier_03','patrol_04','cargo_05']:
    b=(p/('assets/story/m33_'+nm+'.png')).read_bytes()
    assert b[:8] == b'\x89PNG\r\n\x1a\n'
    assert b[25] == 6
print('v48 STATIC PASS',counts)
