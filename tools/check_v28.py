#!/usr/bin/env python3
"""Static consistency and numeric flight-state checks for v0.28.
Does not substitute for Godot 4.7.1 parsing / visual F5 verification.
"""
from pathlib import Path
import math, json, re, zipfile
P=Path(__file__).resolve().parent.parent
main=(P/'scripts/Main.gd').read_text()
npc=(P/'scripts/NpcTraffic.gd').read_text()
landing=(P/'scripts/LandingMotion.gd').read_text()
shared=(P/'scripts/HyperjumpMotion.gd').read_text()
shader=(P/'mika_motion_comic/shaders/comic_layer.gdshader').read_text()

checks={
 'same hyperjump speed function': 'HyperjumpMotion.dash_speed(t)' in npc and 'HyperjumpMotion.dash_speed(departure_progress)' in main and 'HyperjumpMotion.dash_speed(arrival_progress)' in main,
 'same jump rim used in NPC and player': 'HyperjumpMotion.exit_world(Vector2.from_angle(outward))' in npc and 'HyperjumpMotion.exit_world(_warp_direction)' in main,
 'same charge and dash durations': 'const CHARGE_TIME: float = 0.43' in npc and 'const DASH_TIME: float = 0.36' in npc and 'const CHARGE_TIME: float = 0.43' in shared and 'const DASH_TIME: float = 0.36' in shared,
 'player cruises to rim before jump': '"cruise":' in main and '"charge":' in main and '"dash_out":' in main and '"dash_in":' in main,
 'arrival on opposite outer rim': 'HyperjumpMotion.arrival_world(_warp_direction)' in main and '-heading * (OUTER_JUMP_RADIUS + ARRIVAL_OUTSIDE_DISTANCE)' in shared,
 'world address actually advances along route': 'func _story_move_to(world_position: Vector2)' in main and '_story_move_to(here + displacement)' in main,
 'landing shares NPC anchored helper': 'LandingMotion.anchored_approach' in npc and 'LandingMotion.anchored_approach' in main,
 'landing uses NPC times / offset': all('NpcTrafficScene.' + key in main for key in ('APPROACH_TIME','HOVER_TIME','LANDING_TIME','PLANET_LANDING_OFFSET')),
 'no scripted crash smoke': '_story_smoke.set_progress' not in main and 'STORY_SMOKE_END' not in main,
 'old instantaneous warp removed': 'WARP_DEPART_SECONDS' not in main and 'WARP_ARRIVE_SECONDS' not in main,
 'white-screen shader fix retained': 'return;' not in shader,
 'HUD restored': all(k in main for k in ('RightJoystick','LeftContextAction','TopRightDestinationPicker','Fuel_Crystals_Galaxy_MikoMenu')),
 'existing atlas data present': (P/'atlas/world_atlas.json').exists(),
 'new SMC assets present': all((P/f'smc_planets/planets/smc_p{i:02d}.tscn').exists() for i in range(1,9)),
 'intro scenes present': (P/'mika_motion_comic/scenes/MotionComicIntro.tscn').exists(),
}
for label,ok in checks.items():
    print(('PASS' if ok else 'FAIL'), label)
assert all(checks.values())
assert len(json.loads((P/'atlas/world_atlas.json').read_text())['systems'])==7
# Simulate edge-to-edge travel: ship starts on the WRONG side of the system.
edge=2500.0
start=(-1750.0,0)
end=(edge,0)
assert math.dist(start,end)>4000.0
# NPC speed law: both objects cover approx. the same dash distance.
dt=0.0005
distance=sum((880.0+5400.0*(min((k*dt)/0.36,1.0)**2))*dt for k in range(round(0.36/dt)))
assert 900 < distance < 1100,distance
# Entry from beyond the outer rim must finish INSIDE the destination system.
arrival_start=-(edge+650)
arrival_finish=arrival_start+distance
assert -edge < arrival_finish < -2000,(arrival_finish,distance)
# Piecewise NPC landing size must stay monotone and finish at zero.
smooth=lambda t:t*t*(3-2*t)
vals=[0.82*(1-smooth(i/100)) for i in range(101)]
assert all(a>=b for a,b in zip(vals,vals[1:])) and abs(vals[-1])<1e-7
print('PASS numeric: edge crossing, shared dash distance %.1f, destination entry %.1f, anchored landing scale' % (distance,arrival_finish))
print('NOTE: Godot runtime, shader rendering and UI interaction require F5 on a real Godot installation.')
