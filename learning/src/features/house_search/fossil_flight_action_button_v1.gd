extends "res://scripts/ActionButton.gd"
## Fossil Hunt: use the exact main-flight action circle and hand,
## replacing only its inner glyph with the existing stairs interaction.
var _door_mode: bool = false
var _stairs_up: bool = true

func set_door_mode(enabled: bool) -> void:
	if _door_mode != enabled:
		_door_mode = enabled
		queue_redraw()

func set_stairs_up(enabled: bool) -> void:
	if _stairs_up != enabled:
		_stairs_up = enabled
		queue_redraw()

func _draw() -> void:
	super._draw()
	if not _door_mode or not interaction_available:
		return
	var c: Vector2 = size * 0.5
	# Paint over the flight-hand glyph, not its outer native circular frame.
	draw_circle(c, 47.0, Color(0.04, 0.17, 0.28, 0.96))
	draw_arc(c, 47.0, 0.0, TAU, 64, Color(0.38, 0.80, 1.0, 0.72), 2.0, true)
	var white: Color = Color(0.84, 0.98, 1.0, 0.97)
	var left: float = c.x - 33.0
	var bottom: float = c.y + 20.0
	var step: float = 15.0
	var stairs := PackedVector2Array([
		Vector2(left, bottom), Vector2(left + step, bottom),
		Vector2(left + step, bottom - step), Vector2(left + step * 2.0, bottom - step),
		Vector2(left + step * 2.0, bottom - step * 2.0),
		Vector2(left + step * 2.7, bottom - step * 2.0)
	])
	draw_polyline(stairs, white, 4.5, true)
	var axis_x: float = c.x + 27.0
	var tip: Vector2 = Vector2(axis_x, c.y - 28.0 if _stairs_up else c.y + 28.0)
	var tail: Vector2 = Vector2(axis_x, c.y + 20.0 if _stairs_up else c.y - 20.0)
	draw_line(tail, tip, white, 4.0, true)
	var wing: float = 9.0
	var y: float = tip.y + wing if _stairs_up else tip.y - wing
	draw_line(tip, Vector2(axis_x - wing, y), white, 4.0, true)
	draw_line(tip, Vector2(axis_x + wing, y), white, 4.0, true)
