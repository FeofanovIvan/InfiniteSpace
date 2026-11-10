extends TextureButton

const ICON := preload("res://education/playtown/assets/ui/language/language_button.svg")
const LANGUAGE_SCENE := "res://education/playtown/scenes/screens/language_select.tscn"
const WORLD_SCENE := "res://education/playtown/scenes/world/city_world.tscn"


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	texture_normal = ICON
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = size * 0.5
	pressed.connect(_open_language_select)
	button_down.connect(_press_down)
	button_up.connect(_press_up)
	mouse_exited.connect(_press_up)


func _open_language_select() -> void:
	LanguageService.request_language_picker(WORLD_SCENE)
	SFX.transition_from_world(LANGUAGE_SCENE)


func _press_down() -> void:
	scale = Vector2(0.94, 0.94)


func _press_up() -> void:
	scale = Vector2.ONE
