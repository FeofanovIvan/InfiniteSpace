#!/usr/bin/env python3
"""Static integrity checks for v34 Callisto shipyard + orbit spacing patch.

This does NOT run the Godot renderer. It only verifies source/assets exist and
key source changes are present.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
atlas = (ROOT / 'scripts' / 'AtlasSystem.gd').read_text(encoding='utf-8')
other = (ROOT / 'scripts' / 'OtherSystem.gd').read_text(encoding='utf-8')
solar = (ROOT / 'scripts' / 'SolarSystem.gd').read_text(encoding='utf-8')
main = (ROOT / 'scripts' / 'Main.gd').read_text(encoding='utf-8')
asset = ROOT / 'assets' / 'story' / 'callisto_shipyard.png'
assert asset.is_file(), 'Missing new Callisto shipyard asset'
assert asset.stat().st_size > 100000, 'Callisto shipyard asset looks too small'

if 'REPAIR_SHIPYARD_TEXTURE' in atlas:
    # v35 supersedes v34's small Callisto satellite-offset design.
    for phrase in [
        'REPAIR_SHIPYARD_TEXTURE',
        'REPAIR_SHIPYARD_SCALE',
        'REPAIR_SHIPYARD_SPIN_SPEED',
        'shipyard_sprite: Sprite2D = Sprite2D.new()',
        'shipyard_sprite.texture = REPAIR_SHIPYARD_TEXTURE',
        '_repair_shipyard.rotation = wrapf(',
        '_repair_shipyard_world = _original.station_world_position()',
    ]:
        assert phrase in atlas, f'AtlasSystem missing v35 shipyard: {phrase}'
    print('PASS v35 large standalone repair shipyard sprite rotates')
else:
    atlas_required = [
        'CALLISTO_SHIPYARD_TEXTURE',
        'CALLISTO_SHIPYARD_SCALE',
        'CALLISTO_SHIPYARD_SPIN_SPEED',
        'CALLISTO_SHIPYARD_OFFSET',
        'shipyard_sprite: Sprite2D = Sprite2D.new()',
        'shipyard_sprite.texture = CALLISTO_SHIPYARD_TEXTURE',
        '_callisto_shipyard.rotation = wrapf(',
        '_callisto_world = position + CALLISTO_SHIPYARD_OFFSET',
    ]
    for phrase in atlas_required:
        assert phrase in atlas, f'AtlasSystem missing: {phrase}'
    print('PASS v34 Callisto shipyard sprite is wired and rotates')

assert 'VISUAL_INNER_ORBIT' in other and 'VISUAL_ORBIT_SCALE' in other, 'OtherSystem orbit spacing constants missing'
assert 'func _display_orbit_radius' in other, 'OtherSystem display orbit function missing'
assert re.search(r'_planets\.append\(\{"data": source, .*"index": i\}\)', other), 'Planet index not stored'
assert 'RING_MOON_CLEARANCE_FACTOR' in other and 'RING_MOON_CLEARANCE_BONUS' in other, 'Moon/ring clearance constants missing'
assert 'ring_assignments.has(i)' in other and 'moon_node.z_index = 6' in other, 'Moon ring clearance patch missing'
assert 'bodies.append({"name": str(data["name_en"]), "world": body["world"], "color": p_color, "orbit": _display_orbit_radius' in other
print('PASS external-system orbit spacing enlarged and minimap uses enlarged radii')
print('PASS moons around ringed planets receive extra clearance')

assert 'const MOON_ORBIT_RADIUS: float = 136.0' in solar, 'SolarSystem Earth moon orbit radius not widened'
print('PASS Earth moon orbit widened for shell clearance')

main_required = [
    'SYSTEM_ROAM_EXTRA_RADIUS',
    'SYSTEM_ROAM_SOFT_MARGIN',
    'func _current_system_roam_radius() -> float:',
    'func _clip_displacement_to_circle(start: Vector2, delta: Vector2, radius: float) -> Vector2:',
    'func _constrain_free_flight_displacement(requested: Vector2) -> Dictionary:',
    'var movement: Dictionary = _constrain_free_flight_displacement(requested_displacement)',
    'visual_star_displacement',
]
for phrase in main_required:
    assert phrase in main, f'Main.gd missing: {phrase}'
print('PASS free-flight roaming is now bounded while the starfield can keep moving visually')
print('check_v34: OK — static checks only, open in Godot for visual verification')
