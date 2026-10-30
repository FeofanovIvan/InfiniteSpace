#!/usr/bin/env python3
"""v40: Solar System-sized free-flight radius in all five systems, 5 unique remote objects.
No real Godot execution; mathematical/static regression and packaging check.
"""
from pathlib import Path
import re, math
R = Path(__file__).resolve().parents[1]
main = (R/'scripts/Main.gd').read_text()
other = (R/'scripts/OtherSystem.gd').read_text()
fx = (R/'scripts/StoryStationFX.gd').read_text()
assert 'if region_id == "mw":' in main
assert 'return 3220.0' in main
assert 'if ["lmc", "smc", "ngc6822", "m31", "m33"].has(region_id):' in main
assert main.count('return 3220.0') == 2, 'MW and all five external regions must match exactly'
assert 'if region_id == "crossroads":' in main and 'return 980.0' in main
assert 'return {"world": Vector2.ZERO, "visual": requested}' in main
assert 'return {"world": clipped, "visual": requested}' in main
assert 'if _autopilot_active:' in main
# Hyperjump boundary must not be silently widened; player and NPC use shared logic.
assert '2500.0' in (R/'scripts/HyperjumpMotion.gd').read_text()
assert 'const STORY_STATION_ANCHORS: Dictionary' in other
expected = {
  'lmc': (2350,-1690), 'smc': (1490,2410), 'ngc6822':(-580,-2810),
  'm31':(-2490,-1350), 'm33':(2880,460)
}
assert len(set(expected.values()))==5
# The five sectors are physically different, far from original MW shipyard.
base_shipyard=(-2150, 1850)
for id,(x,y) in expected.items():
    token=f'"{id}": Vector2({x:.1f}, {y:.1f})'
    assert token in other, (id,token)
    radius=math.hypot(x,y)
    assert 2800<radius<3000, (id, radius)
    assert math.hypot(x-base_shipyard[0], y-base_shipyard[1]) > 1000
    # Allow drift and gas fields while keeping visible POI accessible.
    assert radius + 46 + 254 < 3220, (id, radius)
# All POIs use the same analytic drift for rendered sprite + nav, with derivative for tracking.
assert 'return anchor + Vector2(cos(phase), sin(phase) * 0.73) * amplitude' in other
assert 'return Vector2(-sin(phase), cos(phase) * 0.73) * amplitude * omega' in other
assert '"world": _station_world(), "velocity": _station_velocity()' in other
assert '_planets[2]' not in other
assert 'StoryStationFX.new()' in other and '_story_fx.call("update_time", _time)' in other
assert 'ARCHIVE_HAZE_TEXTURE' in other or 'ARCHIVE_NEBULA_SHADER' in other
assert 'draw_arc(' in fx and 'draw_circle(' in fx and 'fposmod(' in fx
assert 'GENERIC_STORY_STATION_PREVIEW' in (R/'scripts/MiniMap.gd').read_text() or 'TARANTULA_STATION_PREVIEW' in (R/'scripts/MiniMap.gd').read_text()
assert (R/'assets/story/tarantula_lab_ship.png').exists()
assert (R/'assets/story/living_archive_lotus.png').exists()
print('check_v40: PASS — MW/LMC/SMC/NGC6822/M31/M33 all 3220; 5 unique remote placements, accessible drifting objects, gas FX, NPC/warp unchanged.')
print('NOTE: Godot F5/editor parse and device rendering not run here.')
