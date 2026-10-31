extends Control
## v60: character LEFT HALF, full-height translator RIGHT HALF.
## No duplicate title, no inset tiny tablet; one native fullscreen chat scene.
signal return_requested
@export var planet_background: String = "":
	set(value):
		planet_background = value
		_load_background()
@onready var character: Control = $RepresentativeCharacter
@onready var hint: Control = $PhraseHint
@onready var tablet: Control = $TranslatorTablet
var _background: Texture2D
var _back_button: Button
var _setup: bool = false
var _current_planet_id: String = ""

func configure_for_planet(planet_id: String, planet_name: String, background_path: String, portrait_path: String) -> void:
	_current_planet_id = planet_id
	planet_background = background_path
	if character != null:
		character.set("portrait_path", portrait_path)
	if tablet != null and tablet.has_method("reset_exercise"):
		tablet.call("reset_exercise")
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_background()
	_back_button = Button.new()
	_back_button.name = "BackToPlanet"
	_back_button.text = "←"
	_back_button.tooltip_text = "Вернуться на планету"
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.add_theme_font_size_override("font_size", 25)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("102c47")
	style.border_color = Color("65c9f5")
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	_back_button.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("23537d")
	_back_button.add_theme_stylebox_override("hover", hover)
	_back_button.add_theme_stylebox_override("pressed", hover)
	_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(_back_button)
	_back_button.pressed.connect(_go_back)
	# The hint is integrated inside the tablet above the on-screen keyboard.
	hint.visible = false
	_setup = true
	resized.connect(_layout_ui)
	_layout_ui()

func _load_background() -> void:
	_background = null
	if not planet_background.is_empty() and ResourceLoader.exists(planet_background):
		_background = load(planet_background) as Texture2D
	queue_redraw()

func _layout_ui() -> void:
	if not _setup or size.x < 200 or size.y < 140:
		return
	var w: float = size.x
	var h: float = size.y
	var split: float = w * 0.50
	character.position = Vector2(8, h * 0.025)
	character.size = Vector2(split - 16, h * 0.965)
	tablet.position = Vector2(split, 0)
	tablet.size = Vector2(w - split, h)
	_back_button.position = Vector2(maxf(10, w * 0.009), maxf(10, h * 0.018))
	_back_button.size = Vector2(clampf(w * 0.05, 45, 68), clampf(h * 0.09, 42, 64))
	_back_button.raise()
	queue_redraw()

func _go_back() -> void:
	if not Engine.is_editor_hint():
		return_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_go_back()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 5 or h < 5:
		return
	if _background != null:
		var ts: Vector2 = _background.get_size()
		var factor: float = maxf(w / ts.x, h / ts.y)
		var crop: Vector2 = Vector2(w, h) / factor
		draw_texture_rect_region(_background, Rect2(Vector2.ZERO, size), Rect2((ts - crop) * 0.5, crop))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("06192d"))
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = 2412
		for i in range(150):
			var p: Vector2 = Vector2(random.randf_range(0, w * 0.5), random.randf_range(0, h))
			draw_circle(p, random.randf_range(0.3, 1.2), Color(0.66, 0.85, 1.0, random.randf_range(0.15, 0.50)))
	draw_rect(Rect2(0, 0, w * 0.5, h), Color(0.0, 0.02, 0.05, 0.18))
