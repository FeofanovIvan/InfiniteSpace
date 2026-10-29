#!/usr/bin/env python3
from pathlib import Path
import re
base=Path(__file__).resolve().parents[1]
npc=(base/'scripts/NpcTraffic.gd').read_text()
main=(base/'scripts/Main.gd').read_text()
ship=(base/'scripts/Ship.gd').read_text()
files=list((base/'assets/ships').glob('*.png'))
assert len(files)==11,(len(files),files)
assert npc.count('"weight":')==10
weights=list(map(int,re.findall(r'"weight":(\d+)',npc)))
assert sum(weights)==100,weights
assert 'const POPULATION: int = 14' in npc
for token in ('hyperjump_started','OUTER_JUMP_RADIUS','"charge"','"dash"','"waiting"','_draw_thruster','_draw_jump_cloud'):
 assert token in npc,token
for token in ('NpcTrafficScene','npc_traffic.set_camera_address','_on_npc_hyperjump_started'):
 assert token in main,token
assert 'miko_player_ship.png' in ship
for path in [base/'scripts/Main.gd',base/'scripts/NpcTraffic.gd',base/'scripts/Ship.gd']:
    # indentation must not mix tabs and spaces; content of nested functions only
    for i,line in enumerate(path.read_text().splitlines(),1):
        if line and line[0] in ' \t':
            lead=line[:len(line)-len(line.lstrip(' \t'))]
            assert not (' ' in lead and '\t' in lead),(path.name,i)
print('PASS: all 10 roles, 100% weights, 14 capped NPCs, 11 sprites, player texture, travel+hyperjump hooks, consistent indentation')
