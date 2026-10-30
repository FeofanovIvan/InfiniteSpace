#!/usr/bin/env python3
"""V35 regression: exactly one standalone repair shipyard in the outer MW.
Static integrity/geometry audit only, not a Godot renderer check.
"""
from pathlib import Path
import json, math, re

ROOT = Path(__file__).resolve().parents[1]
solar = (ROOT/'scripts/SolarSystem.gd').read_text(encoding='utf-8')
atlas = (ROOT/'scripts/AtlasSystem.gd').read_text(encoding='utf-8')
nav = (ROOT/'scripts/NavigationMenu.gd').read_text(encoding='utf-8')
mini = (ROOT/'scripts/MiniMap.gd').read_text(encoding='utf-8')
main = (ROOT/'scripts/Main.gd').read_text(encoding='utf-8')
pc = (ROOT/'scripts/NpcTraffic.gd').read_text(encoding='utf-8')
catalog = json.loads((ROOT/'atlas/world_atlas.json').read_text(encoding='utf-8'))

assert 'EarthOrbitalStation_MIKO' not in solar
assert 'StationScene.instantiate()' not in solar
assert '_station_phase' not in solar
assert '_station.position' not in solar
assert '"Earth": preload("res://station_overlays/scenes/OrbitalStation_01.tscn")' in solar
print('PASS old free-flying Earth station removed; one existing Earth ring preserved')

coords = re.search(r'const REMOTE_SHIPYARD_WORLD: Vector2 = Vector2\((-?[0-9.]+),\s*(-?[0-9.]+)\)', solar)
assert coords, 'Remote shipyard coordinates missing'
x, y = map(float, coords.groups())
station_radius = math.hypot(x,y)
assert 'return REMOTE_SHIPYARD_WORLD' in solar
assert '"velocity": Vector2.ZERO' in solar
assert '"EarthStation", "kind": "station", "world": station_world_position()' in solar
assert '"name": "EarthStation"' in solar
assert '"EarthStation"' in pc, 'NPC routing no longer finds its compatible port'
print(f'PASS only one world-space NPC/target location ({x:.0f}, {y:.0f}), radius={station_radius:.1f}')

# When orbit and moons are maximally aligned, the shipyard still remains
# beyond the outermost Neptune moon plus the visible station half-diameter.
station_image = ROOT/'assets/story/callisto_shipyard.png'
assert station_image.is_file()
assert station_image.stat().st_size > 100000
shipyard_visual_radius = 1254.0 * 0.255 * 0.5
neptune_moon_envelope = 1950.0 + (140.0 + 2.0*46.0 + 72.0) + 29.0
clearance = station_radius - neptune_moon_envelope - shipyard_visual_radius
assert clearance > 200.0, f'Station overlaps Neptune/moon envelope: clearance {clearance}'
print(f'PASS shipyard has >200-unit clearance from all Neptune moon orbits (min {clearance:.0f})')

assert 'var _repair_shipyard_world: Vector2 = Vector2.ZERO' in atlas
assert '_repair_shipyard_world = _original.station_world_position()' in atlas
assert atlas.count('Node2D.new()') >= 1
assert atlas.count('"OuterRepairShipyard_OneStandaloneStation"') == 1
assert 'REPAIR_SHIPYARD_TEXTURE' in atlas and 'REPAIR_SHIPYARD_SCALE' in atlas
assert '_repair_shipyard.rotation = wrapf(' in atlas
assert '"st_mw"' in atlas and 'get_target_state("EarthStation")' in atlas
assert 'CALLISTO_SHIPYARD_OFFSET' not in atlas
assert '"CallistoShipyard"' not in atlas
print('PASS one large rotating station, not orbiting Callisto; st_mw and NPC point to same target')

assert '"Neptune", "st_mw"]' in nav
assert '"st_mw": preload("res://assets/story/callisto_shipyard.png")' in nav
assert ('"st_mw": return "Дальняя ремонтная верфь"' in nav or 'MobileLocale.t("shipyard")' in nav)
assert 'REPAIR_SHIPYARD_PREVIEW' in mini
assert 'draw_texture_rect(REPAIR_SHIPYARD_PREVIEW' in mini
assert 'station_world.length() + 140.0' in mini
print('PASS selection button and mini-map show new shipyard asset; old station not in player destinations')

assert 'if region_id == "mw":' in main and 'return 3220.0' in main
assert station_radius+210.0 < 3220.0
assert 'const OUTER_JUMP_RADIUS: float = 2500.0' in (ROOT/'scripts/HyperjumpMotion.gd').read_text()
assert 'var movement: Dictionary = _constrain_free_flight_displacement(requested_displacement)' in main
print('PASS shipyard accessible by manual flight and autopilot; free flight still finite')

mw = next(x for x in catalog['systems'] if x['id']=='mw')
location = mw['station']['placement']
assert mw['station']['id'] == 'st_mw'
assert location['mode'] == 'fixed_outer_solar_system'
assert location['x'] == x and location['y'] == y
assert 'Дальняя ремонтная верфь' == mw['station']['name_ru']
assert len(mw['planets']) == 8
assert sum(len(x.get('moons', [])) for x in mw['planets']) == 20
print('PASS world atlas accurately records relocation while keeping all 8 MW planets and 20 moons')

print('check_v35: OK — static geometry/source validation; Godot F5 still required')
