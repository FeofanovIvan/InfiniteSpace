extends Control
## Draws the lightweight SVG stage beneath Mika.
## Initially it is a muted sketch; after a correct answer, it is revealed left-to-right.

var stage_texture: Texture2D = null
var reveal: float = 0.0:
	set(value):
		reveal = clampf(value, 0.0, 1.0)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_stage(path: String) -> void:
	stage_texture = load(path) as Texture2D
	reveal = 0.0
	queue_redraw()

func _draw() -> void:
	if stage_texture == null:
		return
	var artwork := Rect2(Vector2.ZERO, size)
	# A subdued line illustration is visible before the child completes the task.
	draw_texture_rect(stage_texture, artwork, false, Color(0.47, 0.75, 0.94, 0.20))
	# 'Drawing' animation: bright SVG is progressively unmasked.
	if reveal > 0.005:
		var width_now := maxf(0.01, size.x * reveal)
		var source_width := maxf(0.01, float(stage_texture.get_width()) * reveal)
		draw_texture_rect_region(stage_texture, Rect2(0.0, 0.0, width_now, size.y), Rect2(0.0, 0.0, source_width, float(stage_texture.get_height())), Color(1, 1, 1, 0.95))
