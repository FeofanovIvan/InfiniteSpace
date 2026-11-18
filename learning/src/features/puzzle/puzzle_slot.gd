extends Control
var correct_id: int = -1
var filled: bool = false
var pic: TextureRect
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic = TextureRect.new()
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pic)
func fill(tex: Texture2D) -> void:
	if filled:
		return
	filled = true
	pic.texture = tex
	pivot_offset = size * 0.5
	scale = Vector2(1.18, 1.18)
	modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
