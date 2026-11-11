extends "res://learning/src/features/counting/count_trace_game.gd"
## MIKA Write a Number — responsive native simulator UI.
## Inherits original traced strokes, product catalogue, prompts and animations.

const MIKA_TRACE_SPACE := preload("res://simulator_ui/scripts/real_space_background.gd")
const MIKA_TRACE_NEBULA := preload("res://simulator_ui/scripts/mika_minigame_nebula_layer.gd")
const MIKA_TRACE_TOOLBAR := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_TRACE_HUB := preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_TRACE_BACK := preload("res://simulator_ui/back_arrow_glyph.gd")

const MIKA_TRACE_TEXT := {
	"ru": ["НАПИШИ ЧИСЛО", "Посчитай предметы и обведи цифру"],
	"en": ["WRITE A NUMBER", "Count the objects and trace the number"],
	"pt_BR": ["ESCREVA O NÚMERO", "Conte os objetos e trace o número"],
	"es": ["ESCRIBE EL NÚMERO", "Cuenta los objetos y repasa el número"],
	"fr": ["ÉCRIS LE NOMBRE", "Compte les objets et trace le nombre"],
	"de": ["SCHREIBE DIE ZAHL", "Zähle die Dinge und zeichne die Zahl nach"]
}

# Coordinates of the untouched original number-tracing content.
# One transform scales the objects, equals sign, digit and path tolerances together.
const MIKA_TRACE_STAGE_BOUNDS := Rect2(230.0, 157.0, 1090.0, 557.0)

var _mika_trace_space: Control
var _mika_trace_nebula: Control
var _mika_trace_body: Panel
var _mika_trace_stage: Node2D
var _mika_trace_product_sheet: Panel
var _mika_trace_digit_sheet: Panel
var _mika_trace_top: Control
var _mika_trace_back: Button
var _mika_trace_hub: Control
var _mika_trace_plaque: Panel
var _mika_trace_title: Label
var _mika_trace_subtitle: Label
var _mika_trace_prev: Button
var _mika_trace_next: Button
var _mika_trace_earned: int = 0
var _mika_trace_awarded: Dictionary = {}
var _mika_trace_settled: bool = false
var _mika_trace_ready: bool = false
var _mika_trace_host_back: BaseButton
var _mika_trace_pointer_type: String = ""
var _mika_trace_pointer_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The original coins are a different currency. Earn exactly one ship crystal
	# per unique completed number this visit; settle once on exit.
	coins_per_number = 0
	_mika_trace_earned = 0
	_mika_trace_awarded.clear()
	_mika_trace_settled = false
	super._ready()
	_mika_trace_stage = Node2D.new()
	_mika_trace_stage.name = "AdaptiveNumberDrawingStage"
	add_child(_mika_trace_stage)
	# Keep the original, unscaled paths in stage-local coordinates.
	product_root.reparent(_mika_trace_stage, false)
	letter_root.reparent(_mika_trace_stage, false)
	_mika_trace_add_sheets()
	_mika_trace_ready = true
	_mika_trace_set_language()
	var host: Node = _mika_trace_find_host()
	if host != null:
		_mika_trace_host_back = host.get_node_or_null("EmbeddedGameRunner/ReturnToEducationalCards") as BaseButton
		if is_instance_valid(_mika_trace_host_back):
			_mika_trace_host_back.hide()
	get_viewport().size_changed.connect(_mika_trace_layout)
	if not MobileLocale.language_changed.is_connected(_mika_trace_locale_changed):
		MobileLocale.language_changed.connect(_mika_trace_locale_changed)
	_mika_trace_layout()
	_mika_trace_update_score()

func _mika_trace_style(fill: Color, border: Color, radius: int, thick: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(thick)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.12, 0.57, 0.90, 0.24)
	style.shadow_size = 8
	style.shadow_offset = Vector2.ZERO
	return style

func _build_background() -> void:
	_mika_trace_space = MIKA_TRACE_SPACE.new() as Control
	_mika_trace_space.name = "WriteNumberRealSpace"
	_mika_trace_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_trace_space.z_index = -30
	add_child(_mika_trace_space)
	_mika_trace_nebula = MIKA_TRACE_NEBULA.new() as Control
	_mika_trace_nebula.name = "WriteNumberVioletNebula"
	_mika_trace_nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_trace_space.add_child(_mika_trace_nebula)
	_mika_trace_body = Panel.new()
	_mika_trace_body.name = "WriteNumberGameBodyBackgroundOnly"
	_mika_trace_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_trace_body.z_index = -10
	_mika_trace_body.add_theme_stylebox_override("panel", _mika_trace_style(Color(0.075, 0.165, 0.33, 0.90), Color("#55dfff"), 26))
	add_child(_mika_trace_body)

func _mika_trace_add_sheets() -> void:
	# Opaque panels are actual backgrounds BEHIND content, never overlays.
	_mika_trace_product_sheet = Panel.new()
	_mika_trace_product_sheet.name = "WhiteObjectsSheetBelowArt"
	_mika_trace_product_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_trace_product_sheet.z_index = -1
	_mika_trace_product_sheet.position = Vector2(250.0, 177.0)
	_mika_trace_product_sheet.size = Vector2(585.0, 526.0)
	_mika_trace_product_sheet.add_theme_stylebox_override("panel", _mika_trace_style(Color(1.0, 1.0, 1.0, 1.0), Color("#96ddf5"), 22, 2))
	_mika_trace_stage.add_child(_mika_trace_product_sheet)
	_mika_trace_digit_sheet = Panel.new()
	_mika_trace_digit_sheet.name = "WhiteNumberSheetBelowInk"
	_mika_trace_digit_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_trace_digit_sheet.z_index = -1
	_mika_trace_digit_sheet.position = Vector2(989.0, 265.0)
	_mika_trace_digit_sheet.size = Vector2(298.0, 344.0)
	_mika_trace_digit_sheet.add_theme_stylebox_override("panel", _mika_trace_style(Color(1.0, 1.0, 1.0, 1.0), Color("#96ddf5"), 22, 2))
	_mika_trace_stage.add_child(_mika_trace_digit_sheet)

func _mika_trace_label(tint: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_outline_color", Color("#071b38"))
	label.add_theme_constant_override("outline_size", 2)
	return label

func _mika_trace_nav_button(symbol: String) -> Button:
	var btn := Button.new()
	btn.text = symbol
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_color_override("font_color", Color("#e9fbff"))
	btn.add_theme_stylebox_override("normal", _mika_trace_style(Color("#0d2f55"), Color("#55dfff"), 15))
	btn.add_theme_stylebox_override("hover", _mika_trace_style(Color("#24527b"), Color("#a0f5ff"), 15))
	btn.add_theme_stylebox_override("pressed", _mika_trace_style(Color("#24527b"), Color("#a0f5ff"), 15))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "WriteNumberNativeHUD"
	hud.layer = 2
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	_mika_trace_top = Control.new()
	_mika_trace_top.name = "WriteNumberToolbarRoot"
	_mika_trace_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_mika_trace_top)
	_mika_trace_back = Button.new()
	_mika_trace_back.name = "OriginalSimulatorBack"
	_mika_trace_back.text = ""
	_mika_trace_back.focus_mode = Control.FOCUS_NONE
	_mika_trace_back.mouse_filter = Control.MOUSE_FILTER_STOP
	_mika_trace_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var host: Node = _mika_trace_find_host()
	if host != null and host.has_method("_style_back_button"):
		host.call("_style_back_button", _mika_trace_back)
	else:
		_mika_trace_back.add_theme_stylebox_override("normal", _mika_trace_style(Color("#09264a"), Color("#49dfff"), 17))
		_mika_trace_back.add_theme_stylebox_override("hover", _mika_trace_style(Color("#19436e"), Color("#9af5ff"), 17))
		_mika_trace_back.add_theme_stylebox_override("pressed", _mika_trace_style(Color("#19436e"), Color("#9af5ff"), 17))
		_mika_trace_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var back_glyph: Control = MIKA_TRACE_BACK.new() as Control
		back_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mika_trace_back.add_child(back_glyph)
		back_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mika_trace_back.pressed.connect(_on_exit_pressed)
	_mika_trace_top.add_child(_mika_trace_back)

	_mika_trace_hub = MIKA_TRACE_HUB.new() as Control
	_mika_trace_hub.name = "OriginalPlanetHubCrystalCounter"
	_mika_trace_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_trace_hub.size = Vector2(1680.0, 158.0)
	_mika_trace_top.add_child(_mika_trace_hub)
	var sim: Control = _mika_trace_hub.get_node_or_null("SimulatorButton") as Control
	var flight: Control = _mika_trace_hub.get_node_or_null("LaunchButton") as Control
	if sim != null:
		sim.hide()
	if flight != null:
		flight.hide()
	_mika_trace_hub.set("crystal_count", 0)

	_mika_trace_plaque = Panel.new()
	_mika_trace_plaque.name = "SharedTitleToolbarPlaque"
	_mika_trace_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MIKA_TRACE_TOOLBAR.apply_title_style(_mika_trace_plaque)
	_mika_trace_top.add_child(_mika_trace_plaque)
	_mika_trace_title = _mika_trace_label(Color("#f3fdff"))
	_mika_trace_subtitle = _mika_trace_label(Color("#a9e5ff"))
	_mika_trace_plaque.add_child(_mika_trace_title)
	_mika_trace_plaque.add_child(_mika_trace_subtitle)

	_mika_trace_prev = _mika_trace_nav_button("❮")
	_mika_trace_prev.name = "PreviousNumber"
	_mika_trace_prev.pressed.connect(_on_prev_pressed)
	_mika_trace_top.add_child(_mika_trace_prev)
	_mika_trace_next = _mika_trace_nav_button("❯")
	_mika_trace_next.name = "NextNumber"
	_mika_trace_next.pressed.connect(_on_next_pressed)
	_mika_trace_top.add_child(_mika_trace_next)

	# The parent expects this variable for a GameState signal, even though
	# PlayTown's total is intentionally not shown inside this simulator game.
	score_label = Label.new()
	score_label.name = "HiddenLegacyPlayTownTotal"
	score_label.visible = false
	_mika_trace_top.add_child(score_label)

func _mika_trace_find_host() -> Node:
	var p: Node = get_parent()
	for _i in range(20):
		if p == null:
			break
		if p.has_method("_return_to_cards") and p.has_signal("crystals_earned"):
			return p
		p = p.get_parent()
	return null

func _mika_trace_set_language() -> void:
	if _mika_trace_title == null:
		return
	var locale: String = str(MobileLocale.language)
	if not MIKA_TRACE_TEXT.has(locale):
		locale = "en"
	_mika_trace_title.text = str(MIKA_TRACE_TEXT[locale][0])
	_mika_trace_subtitle.text = str(MIKA_TRACE_TEXT[locale][1])

func _mika_trace_locale_changed(_locale: String) -> void:
	_mika_trace_set_language()
	if _mika_trace_ready:
		_mika_trace_layout()

func _mika_trace_safe_area(view: Vector2) -> Rect2:
	if OS.get_name() not in ["iOS", "Android"]:
		return Rect2(Vector2.ZERO, view)
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Rect2(Vector2.ZERO, view)
	var ratio: Vector2 = view / window_size
	return Rect2(Vector2(safe.position) * ratio, Vector2(safe.size) * ratio)

func _mika_trace_layout() -> void:
	if not _mika_trace_ready or _mika_trace_stage == null:
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 120.0 or view.y < 140.0:
		return
	var safe: Rect2 = _mika_trace_safe_area(view)
	_mika_trace_space.position = Vector2.ZERO
	_mika_trace_space.size = view
	_mika_trace_nebula.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mika_trace_nebula.size = view
	_mika_trace_top.size = view
	var head_bottom: float = MIKA_TRACE_TOOLBAR.relayout(view, safe, _mika_trace_back, _mika_trace_hub, _mika_trace_plaque, _mika_trace_title, _mika_trace_subtitle)
	var pad_x: float = safe.size.x * 0.019
	var gap_y: float = safe.size.y * 0.025
	var body: Rect2 = Rect2(
		Vector2(safe.position.x + pad_x, head_bottom + gap_y),
		Vector2(safe.size.x - pad_x * 2.0, safe.end.y - head_bottom - gap_y * 2.0)
	)
	if body.size.x <= 90.0 or body.size.y <= 65.0:
		return
	_mika_trace_body.position = body.position
	_mika_trace_body.size = body.size
	var inset_x: float = body.size.x * 0.017
	var inset_y: float = body.size.y * 0.022
	var nav_w: float = body.size.x * 0.056
	var stage_area: Rect2 = Rect2(
		body.position + Vector2(inset_x + nav_w, inset_y),
		body.size - Vector2((inset_x + nav_w) * 2.0, inset_y * 2.0)
	)
	var factor: float = minf(stage_area.size.x / MIKA_TRACE_STAGE_BOUNDS.size.x, stage_area.size.y / MIKA_TRACE_STAGE_BOUNDS.size.y)
	var fitted_size: Vector2 = MIKA_TRACE_STAGE_BOUNDS.size * factor
	_mika_trace_stage.scale = Vector2.ONE * factor
	_mika_trace_stage.position = stage_area.position + (stage_area.size - fitted_size) * 0.5 - MIKA_TRACE_STAGE_BOUNDS.position * factor
	var btn_side: float = minf(nav_w * 0.78, body.size.y * 0.15)
	var btn_y: float = body.position.y + (body.size.y - btn_side) * 0.5
	_mika_trace_prev.position = Vector2(body.position.x + inset_x + (nav_w - btn_side) * 0.5, btn_y)
	_mika_trace_prev.size = Vector2.ONE * btn_side
	_mika_trace_next.position = Vector2(body.end.x - inset_x - nav_w + (nav_w - btn_side) * 0.5, btn_y)
	_mika_trace_next.size = Vector2.ONE * btn_side
	for button in [_mika_trace_prev, _mika_trace_next]:
		button.add_theme_font_size_override("font_size", maxi(12, roundi(btn_side * 0.60)))

# The original only supports InputEventScreenTouch/Drag. Trace in the local
# coordinates of the transformed numeral, not the old hard-coded viewport.
func _unhandled_input(event: InputEvent) -> void:
	if letter_done or stroke_samples.is_empty() or cur_stroke >= stroke_samples.size():
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			if _mika_trace_pointer_type != "":
				return
			_mika_trace_pointer_type = "touch"
			_mika_trace_pointer_index = touch.index
			_start_trace(letter_root.to_local(touch.position))
		elif _mika_trace_pointer_type == "touch" and _mika_trace_pointer_index == touch.index:
			tracing = false
			_mika_trace_pointer_type = ""
			_mika_trace_pointer_index = -1
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if _mika_trace_pointer_type == "touch" and _mika_trace_pointer_index == drag.index:
			_move_trace(letter_root.to_local(drag.position))
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				if _mika_trace_pointer_type != "":
					return
				_mika_trace_pointer_type = "mouse"
				_mika_trace_pointer_index = 0
				_start_trace(letter_root.to_local(mouse.position))
			elif _mika_trace_pointer_type == "mouse":
				tracing = false
				_mika_trace_pointer_type = ""
				_mika_trace_pointer_index = -1
	elif event is InputEventMouseMotion:
		var move: InputEventMouseMotion = event
		if _mika_trace_pointer_type == "mouse" and (move.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_move_trace(letter_root.to_local(move.position))

func _load_round() -> void:
	_mika_trace_pointer_type = ""
	_mika_trace_pointer_index = -1
	super._load_round()

func _update_score() -> void:
	_mika_trace_update_score()

func _mika_trace_update_score() -> void:
	if _mika_trace_hub != null:
		_mika_trace_hub.set("crystal_count", _mika_trace_earned)

func _finish_number() -> void:
	if letter_done:
		return
	var completed: int = _current_number()
	# Original success animation, number voice, praise and progress saved.
	# Original PlayTown coins are suppressed via coins_per_number = 0.
	super._finish_number()
	if not _mika_trace_awarded.has(completed):
		_mika_trace_awarded[completed] = true
		_mika_trace_earned += 1
		_mika_trace_update_score()

func _mika_trace_settle_rewards() -> void:
	if _mika_trace_settled:
		return
	_mika_trace_settled = true
	if _mika_trace_earned <= 0:
		return
	var host: Node = _mika_trace_find_host()
	if host != null:
		host.emit_signal("crystals_earned", _mika_trace_earned)
		var p: Node = host.get_parent()
		for _i in range(9):
			if p == null:
				break
			var fuel: Variant = p.get("_fuel_units")
			if fuel is float or fuel is int:
				if host.has_method("set_stats"):
					host.call("set_stats", maxi(0, floori(float(fuel) + 0.001)), 0, 0.0)
				break
			p = p.get_parent()

func _on_exit_pressed() -> void:
	_mika_trace_settle_rewards()
	var host: Node = _mika_trace_find_host()
	if host != null:
		host.call("_return_to_cards")
	else:
		SFX.transition_to_scene(exit_scene_path)

func _exit_tree() -> void:
	_mika_trace_settle_rewards()
	if is_instance_valid(_mika_trace_host_back):
		_mika_trace_host_back.show()
	if MobileLocale.language_changed.is_connected(_mika_trace_locale_changed):
		MobileLocale.language_changed.disconnect(_mika_trace_locale_changed)
