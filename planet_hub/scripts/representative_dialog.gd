extends Control
const LivingWorldScene = preload("res://living_world_storm_2d/living_world_storm_2d.tscn")
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
var _living_layer: Control
var _living_world: Node2D

func configure_for_planet(planet_id: String, _planet_name: String, background_path: String, portrait_path: String) -> void:
	_current_planet_id = planet_id
	planet_background = background_path
	if character != null:
		character.visible = planet_id != "crossroads_core"
		character.set("portrait_path", portrait_path)
	if _living_layer != null:
		_living_layer.visible = planet_id == "crossroads_core"
		_living_layer.process_mode = Node.PROCESS_MODE_ALWAYS if planet_id == "crossroads_core" else Node.PROCESS_MODE_DISABLED
		if planet_id == "crossroads_core":
			_ensure_living_world()
			_layout_ui()
	if tablet != null and tablet.has_method("configure_for_world"):
		tablet.call("configure_for_world", planet_id)
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
	# Living World uses its existing animated liquid planet, not a human silhouette.
	_living_layer = Control.new()
	_living_layer.name = "LivingWorldEncyclopediaVisual"
	_living_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_living_layer.clip_contents = true
	add_child(_living_layer)
	move_child(_living_layer, character.get_index() + 1)
	_living_layer.visible = _current_planet_id == "crossroads_core"
	_living_layer.process_mode = Node.PROCESS_MODE_DISABLED
	if tablet != null and tablet.has_signal("message_sent"):
		tablet.connect("message_sent", Callable(self, "_on_living_world_message"))
	# The hint is integrated inside the tablet above the on-screen keyboard.
	hint.visible = false
	_setup = true
	resized.connect(_layout_ui)
	_layout_ui()

func _ensure_living_world() -> void:
	if _living_world != null or _living_layer == null:
		return
	_living_world = LivingWorldScene.instantiate() as Node2D
	if _living_world != null:
		_living_world.name = "AnimatedLivingWorldSpeaker"
		_living_layer.add_child(_living_world)
		_living_world.call("set_mood", "curious")
		_living_world.call("set_storm_state", "communicating")
		_living_world.call("set_storm_enabled", true)

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
	if _living_layer != null:
		_living_layer.position = Vector2.ZERO
		_living_layer.size = Vector2(split, h)
	if _living_world != null:
		_living_world.position = Vector2(split * 0.5, h * 0.50)
		_living_world.call("update_diameter", clampf(minf(split * 0.48, h * 0.36), 145.0, 350.0))
	_back_button.position = Vector2(maxf(10, w * 0.009), maxf(10, h * 0.018))
	_back_button.size = Vector2(clampf(w * 0.05, 45, 68), clampf(h * 0.09, 42, 64))
	_back_button.move_to_front()
	queue_redraw()

func _on_living_world_message(_text: String) -> void:
	if _current_planet_id != "crossroads_core" or _living_world == null:
		return
	_living_world.call("set_mood", "curious")
	_living_world.call("react_to_voice", 0.85)
	_living_world.call("trigger_storm", Vector2.UP, 0.58)

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
