extends TextureButton

const ICON := preload("res://education/playtown/assets/ui/subscription/subscription_icon.png")
var active := false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	texture_normal = ICON
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Subscription"
	pivot_offset = size * 0.5
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_exited.connect(_on_mouse_exited)

func set_active(value: bool) -> void:
	active = value
	modulate = Color(0.86, 1.0, 0.88) if active else Color.WHITE

func _on_button_down() -> void:
	scale = Vector2(0.94, 0.94)

func _on_button_up() -> void:
	scale = Vector2.ONE

func _on_mouse_exited() -> void:
	if not button_pressed:
		scale = Vector2.ONE
