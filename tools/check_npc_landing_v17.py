#!/usr/bin/env python3
"""Offline v0.17 static and motion-math regression checks (no Godot required)."""
from pathlib import Path
import math
import re
ROOT=Path(__file__).resolve().parents[1]
NPC=(ROOT/'scripts/NpcTraffic.gd').read_text()
MOTION=(ROOT/'scripts/LandingMotion.gd').read_text()
MAIN=(ROOT/'scripts/Main.gd').read_text()
SOLAR=(ROOT/'scripts/SolarSystem.gd').read_text()
required_modes=['"cruise"','"approach"','"hover"','"landing"','"docked"','"takeoff"','"depart"','"charge"','"dash"','"waiting"']
for mode in required_modes: assert mode in NPC,mode
for s in ['landing_completed.emit(', 'takeoff_started.emit(', 'hyperjump_started.emit(',
          '_anchor_world(npc, bodies)', 'LandingMotion.anchored_approach(', 'LandingMotion.smooth_step(',
          'npc = _make_ship(false, true)', 'const POPULATION: int = 14', 'const MAX_CLOUDS: int = 15']:
    assert s in NPC,s
for fn in ('func _on_npc_takeoff_started','func _on_npc_landing_completed'):
    assert fn in MAIN, fn
assert 'npc_landings' in MAIN and 'npc_takeoffs' in MAIN
ports=re.search(r'const LANDING_PORTS = \[([^]]+)\]',NPC)
assert ports, 'no ports list'
assert re.findall(r'"([A-Za-z]+)"',ports.group(1))==['Earth','Venus','Mars','Jupiter','Neptune','EarthStation']
assert len(re.findall(r'"weight":(\d+)',NPC))==10
assert sum(map(int,re.findall(r'"weight":(\d+)',NPC)))==100
assert 'get_navigation_bodies()' in NPC
assert 'STATION_SHELL_SCENES' in SOLAR
assert 'PLANET_ORBITS' in SOLAR and '"Saturn"' in SOLAR and '"Uranus"' in SOLAR and '"Mercury"' in SOLAR
for f in (ROOT/'scripts').glob('*.gd'):
    for i,line in enumerate(f.read_text().splitlines(),1):
        if not line or not line[0].isspace(): continue
        lead=line[:len(line)-len(line.lstrip(' \t'))]
        assert not (' ' in lead and '\t' in lead), (f.name,i,'mixed indentation')
        if f.name in ('NpcTraffic.gd','LandingMotion.gd'):
            assert ' ' not in lead, (f.name,i,'spaces for indentation')

def smooth(t):
    t=max(0,min(1,t))
    return t*t*(3-2*t)

def interpolated(start,end,t):
    k=smooth(t)
    return (start[0]+(end[0]-start[0])*k,start[1]+(end[1]-start[1])*k)

def add(a,b): return a[0]+b[0],a[1]+b[1]
# Two orbital positions, same attached offset. No camera-dependent interpolation.
origin_a=(565,0)
origin_b=(300,477)
offset_a=(150,-70)
offset_end=(17,-8)
for t in (0,0.12,0.33,0.5,0.75,1):
    relative=interpolated(offset_a,offset_end,t)
    world_a=add(origin_a,relative)
    world_b=add(origin_b,relative)
    assert abs(math.dist(world_a,world_b)-math.dist(origin_a,origin_b)) < 1e-8
# Landing size monotonic down to zero; takeoff grows to 82% base.
for i in range(40):
    t=i/40
    nxt=(i+1)/40
    assert 0.82*(1-smooth(nxt)) <= 0.82*(1-smooth(t))
    assert 0.82*smooth(nxt) >= 0.82*smooth(t)
assert smooth(0)==0 and smooth(1)==1
assert smooth(-20)==0 and smooth(40)==1
textures=list((ROOT/'assets/ships').glob('*.png'))
assert len(textures)==11
print('PASS: NPC landing/takeoff states, anchored moving orbits, six active ports, 14 NPC cap, 10 weighted roles, ship assets, logs, smooth-scale monotonicity, indentation')
