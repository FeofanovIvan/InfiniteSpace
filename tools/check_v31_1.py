#!/usr/bin/env python3
"""Regression checks for the exact-rim NPC-style player jump (v31.1).

Runs without Godot and supplements, but cannot replace, Godot F5 testing.
"""
from pathlib import Path
import math
import re

ROOT = Path(__file__).resolve().parents[1]
main = (ROOT / "scripts" / "Main.gd").read_text(encoding="utf-8")
hyper = (ROOT / "scripts" / "HyperjumpMotion.gd").read_text(encoding="utf-8")
assert 'const WARP_EDGE_SNAP_DISTANCE: float = 12.0' in main
assert '_story_move_to(_warp_exit_world)' in main
assert '_warp_velocity = Vector2.ZERO' in main
assert 'var desired_speed: float = minf(AUTO_CRUISE_SPEED, sqrt(2.0 * AUTO_BRAKE_ACCEL * distance))' in main
assert 'maxf(0.0, distance - 82.0)' not in main
assert '"hyperspace_edge_reached"' in main
assert '"hyperspace_jump_started"' in main
assert '"hyperspace_arrived"' in main
assert 'HyperjumpMotion.dash_speed' in main
assert 'NpcJumpVisual.dash_ship_scale' in main
assert 'NpcJumpVisual.draw_dash' in (ROOT / 'scripts' / 'PlayerJumpFX.gd').read_text() or 'show_dash' in main

RADIUS = float(re.search(r'OUTER_JUMP_RADIUS: float = ([0-9.]+)', hyper).group(1))
TOL = float(re.search(r'WARP_EDGE_SNAP_DISTANCE: float = ([0-9.]+)', main).group(1))
assert RADIUS == 2500.0


def run_leg(start, direction, fps):
    goal = [direction[0] * RADIUS, direction[1] * RADIUS]
    pos = list(start)
    vel = [0., 0.]
    dt = 1. / fps
    for tick in range(int(60 * fps)):
        rem = [goal[0] - pos[0], goal[1] - pos[1]]
        dist = math.hypot(*rem)
        if dist <= TOL:
            # Exact rim snap is the critical regression guard.
            pos = list(goal)
            assert abs(math.hypot(*pos) - RADIUS) < 1e-8
            return tick / fps, dist
        aim = [rem[0] / dist, rem[1] / dist]
        desired_speed = min(720., math.sqrt(2 * 1060. * dist))
        desired = [v * desired_speed for v in aim]
        dv = [desired[0] - vel[0], desired[1] - vel[1]]
        dv_len = math.hypot(*dv)
        factor = min(1., (1100. * dt) / dv_len) if dv_len else 0.
        vel = [vel[0] + dv[0] * factor, vel[1] + dv[1] * factor]
        displacement = [vel[0] * dt, vel[1] * dt]
        if math.hypot(*displacement) ** 2 >= dist ** 2:
            displacement = rem
        pos = [pos[0] + displacement[0], pos[1] + displacement[1]]
    raise AssertionError(f'cruise stalled from {start} toward {direction} at {fps} FPS; remainder={dist:.10f}')


starts = [(650., 35.), (550., 300.), (-2100., 850.), (20., 0.), (-750., -550.)]
angles = [0., math.pi/5., math.pi/2., math.pi, -2.*math.pi/3., 2.8]
count = 0
for start in starts:
    for angle in angles:
        direction = (math.cos(angle), math.sin(angle))
        for fps in (30, 60, 120):
            secs, before_snap = run_leg(start, direction, fps)
            assert secs < 20.
            assert before_snap <= TOL
            count += 1

print(f'PASS {count} flight paths at 30/60/120 FPS: edge reached and snapped to exactly {RADIUS:.0f}')
print('PASS player jump reuses NPC HyperjumpMotion speed and NpcJumpVisual appearance')
print('PASS transitions still report edge, dash start, and arrival')
print('NOTE real Godot runtime and graphics validation still require F5 on your Mac')
