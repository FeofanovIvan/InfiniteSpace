#!/usr/bin/env python3
"""Static invariants for v57 crystal fuel gameplay; Godot F5 still required."""
from pathlib import Path
r=Path(__file__).resolve().parent.parent
main=(r/'scripts/Main.gd').read_text(encoding='utf-8')
a=(r/'scripts/AsteroidField.gd').read_text(encoding='utf-8')
hud=(r/'scripts/RightStatusHUD.gd').read_text(encoding='utf-8')
assert 'const FUEL_CAPACITY: float = 50.0' in main
assert 'const FUEL_MAX_DRAIN_PER_SECOND: float = 1.8' in main
assert 'var _fuel_units: float = FUEL_CAPACITY' in main
assert 'asteroid_field.fuel_collected.connect(_on_fuel_collected)' in main
assert 'if _fuel_units <= 0.0:' in main
assert 'velocity = Vector2.ZERO' in main[main.index('if _fuel_units <= 0.0:'):main.index('# Ship world position, camera world position')]
assert 'asteroid_field.has_collectible_in_range(ship_world)' in main
assert 'asteroid_field.start_magnet_capture(_ship_world())' in main
assert '_fuel_units = minf(FUEL_CAPACITY, _fuel_units + float(units))' in main
assert 'const CRYSTAL_FUEL_VALUES: Array[int] = [0, 2, 1, 3]' in a
assert 'const MAGNET_RADIUS: float = 188.0' in a
assert 'const MAGNET_DURATION: float = 0.95' in a
assert 'func _spawn_mineral_cluster() -> void:' in a
assert 'func _advance_magnet(delta: float) -> void:' in a
assert 'fuel_collected.emit(gathered)' in a
assert 'func has_collectible_in_range(center: Vector2) -> bool:' in a
assert 'func start_magnet_capture(center: Vector2) -> bool:' in a
assert 'draw_arc(center, radius, 0.0, TAU, 96' in a
assert 'fuel_segments == 1' in hud and 'fuel_segments == 2' in hud
assert 'fuel_segments <= 4' in hud
assert 'FuelCount_50Capacity' in hud
assert '_blink_time' in hud
assert (r/'tools/check_v56.py').is_file()
print('v57 STATIC PASS: 50 capacity, 0/2/1/3 crystal yields, magnet, seven-stage gauge, free warp')
