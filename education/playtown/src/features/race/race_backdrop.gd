extends Control
const SKY := Color("#64c8e0")
const GRASS := Color("#74aa30")
const ROAD := Color("#979fa4")
const ROAD_LIGHT := Color("#eef2f3")
const ROAD_EDGE := Color("#5a9d2c")
var stripe_phase := 0.0
var road_paused := false
var road_speed_multiplier := 1.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()
func _process(delta: float) -> void:
	if road_paused:
		return
	stripe_phase = fmod(stripe_phase + delta * 0.28 * road_speed_multiplier, 1.0)
	queue_redraw()
func set_road_paused(value: bool) -> void:
	road_paused = value
func set_road_speed_multiplier(value: float) -> void:
	road_speed_multiplier = clampf(value, 0.0, 1.0)
func _draw() -> void:
	var view := size
	if view.x <= 1.0 or view.y <= 1.0:
		return
	var horizon := view.y * 0.475
	draw_rect(Rect2(Vector2.ZERO, Vector2(view.x, horizon)), SKY)
	draw_rect(Rect2(Vector2(0.0, horizon), Vector2(view.x, view.y - horizon)), GRASS)
	var road_top_left := Vector2(view.x * 0.43, horizon)
	var road_top_right := Vector2(view.x * 0.57, horizon)
	var road_bottom_right := Vector2(view.x * 0.845, view.y)
	var road_bottom_left := Vector2(view.x * 0.155, view.y)
	draw_colored_polygon(
		PackedVector2Array([road_top_left, road_top_right, road_bottom_right, road_bottom_left]),
		ROAD
	)
	var edge := view.x * 0.018
	draw_colored_polygon(PackedVector2Array([
		road_top_left - Vector2(edge, 0.0),
		road_top_left,
		road_bottom_left,
		road_bottom_left - Vector2(edge * 1.8, 0.0)
	]), ROAD_EDGE)
	draw_colored_polygon(PackedVector2Array([
		road_top_right,
		road_top_right + Vector2(edge, 0.0),
		road_bottom_right + Vector2(edge * 1.8, 0.0),
		road_bottom_right
	]), ROAD_EDGE)
	for index in range(4):
		var t := fmod(float(index) / 4.0 + stripe_phase, 1.0)
		var next_t := minf(1.0, t + 0.06 + t * 0.05)
		var y1 := lerpf(horizon + 16.0, view.y, t)
		var y2 := lerpf(horizon + 16.0, view.y, next_t)
		var width1 := lerpf(view.x * 0.003, view.x * 0.017, pow(t, 1.35))
		var width2 := lerpf(view.x * 0.003, view.x * 0.017, pow(next_t, 1.35))
		draw_colored_polygon(PackedVector2Array([
			Vector2(view.x * 0.5 - width1, y1),
			Vector2(view.x * 0.5 + width1, y1),
			Vector2(view.x * 0.5 + width2, y2),
			Vector2(view.x * 0.5 - width2, y2)
		]), ROAD_LIGHT)
