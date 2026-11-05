#!/usr/bin/env python3
"""v41 static regression: engine nozzle placement, local rotation, nebula only for living archive."""
from pathlib import Path
import math
R = Path(__file__).resolve().parents[1]
other = (R/'scripts/OtherSystem.gd').read_text(encoding='utf-8')
jet = (R/'scripts/TarantulaThrusters.gd').read_text(encoding='utf-8')
shader = (R/'shaders/far_plasma.gdshader').read_text(encoding='utf-8')
assert 'const TarantulaThrusters = preload(' in other
assert 'ThreeBlueThrusters_AttachedToTarantula' in other
assert '_station_sprite.add_child(_tarantula_thrusters)' in other
assert 'if station_region_id == "smc":\n\t\t\t_add_archive_nebula()' in other
# v44 gives Titan a dedicated shader and pyramid its own asset; m33 retains the old placeholder.
assert 'elif ["ngc6822", "m31", "m33"].has(station_region_id):' in other or 'elif ["m33"].has(station_region_id):' in other
assert 'LivingArchive_NebulaCloud_%d' in other
assert 'ARCHIVE_NEBULA_SHADER: Shader = preload("res://shaders/far_plasma.gdshader")' in other
assert 'shader_mat.shader = ARCHIVE_NEBULA_SHADER' in other
assert '_station_sprite.rotation = _time * 0.022' in other
assert '_station_sprite.rotation = -_time * 0.015' in other
assert '_tarantula_thrusters.call("update_time", _time)' in other
assert '_station_sprite.texture = TARANTULA_TEXTURE' in other and '_station_sprite.texture = ARCHIVE_TEXTURE' in other
assert 'Vector2(-742.0, -158.0)' in jet
assert 'Vector2(-742.0,  -31.0)' in jet
assert 'Vector2(-742.0,  103.0)' in jet
assert 'NOZZLES.size()' in jet
assert '0.23 * sin(_time * 1.47 + phase)' in jet
assert 'draw_colored_polygon(outer' in jet and 'draw_colored_polygon(inner' in jet
assert 'draw_circle(Vector2.ZERO' not in jet
assert 'edge = smoothstep' in shader and 'float density' in shader
# The emitter source positions must be in the rear (left) section of the 1536x1024 image;
# the station is scaled .24 and source/jet are children of the same rotating sprite.
size = (1536, 1024)
nozzles=[(-742.0,-158.0),(-742.0,-31.0),(-742.0,103.0)]
for x,y in nozzles:
    sx = x + size[0]*0.5
    sy = y + size[1]*0.5
    assert 0<=sx<=48, (sx,sy)
    assert 300<sy<650, (sx,sy)
    assert -300 < x * 0.24 < 0
assert len(set(y for _,y in nozzles)) == 3
print('check_v41: PASS — three nozzle-anchored animated blue jets, independent pressure, ship spin, living archive shader gas, no LMC halo.')
print('NOTE: Godot F5 and runtime particle rendering require device/editor testing.')
