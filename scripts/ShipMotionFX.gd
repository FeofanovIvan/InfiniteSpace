extends Node2D
## Small lightweight slipstream behind transparent SMC ships (art nose is +X).
var _clock: float = 0.0
var _power: float = 0.0
var _tint: Color = Color(0.55, 0.86, 1.0)

func update_motion(clock: float, power: float, tint: Color) -> void:
	_clock = clock
	_power = clampf(power, 0.0, 1.0)
	_tint = tint
	queue_redraw()

func _draw() -> void:
	if _power < 0.15:
		return
	var pulse: float = 0.88 + 0.12 * sin(_clock * 12.0)
	for lane in range(4):
		var y: float = (float(lane) - 1.5) * 165.0
		var start: Vector2 = Vector2(-475.0, y)
		var length_px: float = (125.0 + float(lane % 2) * 60.0) * _power * pulse
		var finish: Vector2 = start + Vector2(-length_px, y * 0.08)
		draw_line(start, finish, Color(_tint, 0.12 * _power), 13.0, true)
		draw_line(start, finish, Color(0.86, 0.95, 1.0, 0.17 * _power), 2.4, true)
	# A few dots recede behind the ship like suspended particles.
	for dot_index in range(5):
		var along: float = fposmod(_clock * (190.0 + dot_index * 19.0) + float(dot_index) * 89.0, 270.0)
		var dot: Vector2 = Vector2(-480.0 - along, (float(dot_index) - 2.0) * 100.0)
		draw_circle(dot, 2.0 + float(dot_index % 2), Color(_tint, 0.24 * _power * (1.0 - along / 300.0)))
