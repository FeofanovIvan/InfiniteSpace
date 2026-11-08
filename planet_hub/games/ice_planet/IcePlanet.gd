extends Control
## MIKA · Ice Planet (SMC phase beings)
## Self-contained learning game. Drag the planet to change average heat;
## increase rotation to reduce the contrast between warm and cool hemispheres.
## Simplified classroom model, not orbital/atmospheric physics.

const DESIGN := Vector2(1280.0, 720.0)
const LANGUAGE_CODES := ["ru", "en", "pt", "es", "de", "fr"]
const HOLD_TO_WIN := 3.0
const ORBIT_X_MIN := 389.0
const ORBIT_X_MAX := 842.0
const PLANET_Y := 361.0
const STAR_POS := Vector2(172.0, 342.0)
const PLANET_RADIUS := 80.0
const DISTANCE_BAR := Rect2(83.0, 619.0, 507.0, 12.0)
const ROTATION_BAR := Rect2(711.0, 619.0, 464.0, 12.0)
const STAR_ICON = preload("res://planet_hub/games/ice_planet/star_core.png")

var _strings: Dictionary = {}
var _missions: Array = []
var _service: Node
var _interface_lang := "en"
var _learning_lang := "en"
var _scale := 1.0
var _origin := Vector2.ZERO
var _elapsed := 0.0
var _distance := 0.88
var _spin := 0.12
var _planet_angle := 0.0
var _score := 0
var _mission_index := 0
var _stable_seconds := 0.0
var _mission_complete := false
var _game_complete := false
var _drag_mode := ""
var _drag_start := Vector2.ZERO
var _distance_at_press := 0.0
var _spin_at_press := 0.0
var _hint_seconds := 0.0
var _hint_key := ""
var _mean_temp := 0.0
var _warm_temp := 0.0
var _cool_temp := 0.0
var _status := "cold"

var _title: Label
var _subtitle: Label
var _mission_label: Label
var _round_label: Label
var _score_label: Label
var _panel_title: Label
var _state_label: Label
var _average_label: Label
var _warm_label: Label
var _cool_label: Label
var _stable_label: Label
var _phase_label: Label
var _guide_label: Label
var _distance_label: Label
var _rotation_label: Label
var _distance_near_label: Label
var _distance_far_label: Label
var _rotation_slow_label: Label
var _rotation_fast_label: Label
var _instruction_label: Label
var _tip_label: Label
var _model_note: Label
var _hint_button: Button
var _restart_button: Button
var _next_button: Button
var _language_picker: OptionButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_load_data()
	_create_ui()
	_bind_language()
	_layout()
	get_viewport().size_changed.connect(_layout)
	_restart_game()


func _load_data() -> void:
	var loaded_strings = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/ice_planet/data/strings.json"))
	if typeof(loaded_strings) == TYPE_DICTIONARY:
		_strings = loaded_strings
	var loaded_missions = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/ice_planet/data/missions.json"))
	if typeof(loaded_missions) == TYPE_ARRAY:
		_missions = loaded_missions


func _make_label(font_size: int, tint: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = alignment
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _button(callback: Callable) -> Button:
	var control := Button.new()
	control.focus_mode = Control.FOCUS_NONE
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_skin_button(control, Color("173956"), Color("5bafdb"))
	control.pressed.connect(callback)
	add_child(control)
	return control


func _skin_button(control: BaseButton, base: Color, stroke: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = base
	style.border_color = stroke
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = base.lightened(0.16)
	hover.border_color = Color("c8f5ff")
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = base.darkened(0.15)
	control.add_theme_stylebox_override("normal", style)
	control.add_theme_stylebox_override("hover", hover)
	control.add_theme_stylebox_override("pressed", pressed)
	control.add_theme_font_size_override("font_size", 15)
	control.add_theme_color_override("font_color", Color("f1faff"))
	control.add_theme_color_override("font_hover_color", Color.WHITE)


func _create_ui() -> void:
	_title = _make_label(32, Color("f2fbff"))
	_subtitle = _make_label(15, Color("9ec8e6"))
	_mission_label = _make_label(21, Color("ffe8ab"), HORIZONTAL_ALIGNMENT_CENTER)
	_round_label = _make_label(17, Color("c1e6fc"))
	_score_label = _make_label(18, Color("f6fbff"))
	_panel_title = _make_label(18, Color("bfeaff"), HORIZONTAL_ALIGNMENT_CENTER)
	_state_label = _make_label(20, Color("ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	_average_label = _make_label(19, Color("e6f7ff"))
	_warm_label = _make_label(17, Color("ffd9ac"))
	_cool_label = _make_label(17, Color("b8e7ff"))
	_stable_label = _make_label(16, Color("baf6d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_phase_label = _make_label(18, Color("d0f5ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_guide_label = _make_label(14, Color("a1c9e0"), HORIZONTAL_ALIGNMENT_CENTER)
	_distance_label = _make_label(18, Color("d3efff"))
	_rotation_label = _make_label(18, Color("d3efff"))
	_distance_near_label = _make_label(13, Color("ffc38b"))
	_distance_far_label = _make_label(13, Color("a5d5ff"), HORIZONTAL_ALIGNMENT_RIGHT)
	_rotation_slow_label = _make_label(13, Color("acc6e3"))
	_rotation_fast_label = _make_label(13, Color("98f0d4"), HORIZONTAL_ALIGNMENT_RIGHT)
	_instruction_label = _make_label(16, Color("f0eece"), HORIZONTAL_ALIGNMENT_CENTER)
	_tip_label = _make_label(15, Color("bde9ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_model_note = _make_label(11, Color("7798af"), HORIZONTAL_ALIGNMENT_CENTER)

	_hint_button = _button(Callable(self, "_show_hint"))
	_restart_button = _button(Callable(self, "_restart_game"))
	_next_button = _button(Callable(self, "_next_world"))
	_skin_button(_next_button, Color("1c675f"), Color("81efc2"))
	_next_button.visible = false

	_language_picker = OptionButton.new()
	_language_picker.focus_mode = Control.FOCUS_NONE
	for code in LANGUAGE_CODES:
		_language_picker.add_item(str(_strings.get(code, {}).get("language", code)))
	_language_picker.item_selected.connect(_on_language_selected)
	_skin_button(_language_picker, Color("173956"), Color("5bafdb"))
	add_child(_language_picker)


func _put(control: Control, rect: Rect2) -> void:
	control.position = _origin + rect.position * _scale
	control.size = rect.size
	control.scale = Vector2.ONE * _scale


func _layout() -> void:
	var viewport_size := size
	if viewport_size.x < 1.0 or viewport_size.y < 1.0:
		viewport_size = get_viewport_rect().size
	_scale = minf(viewport_size.x / DESIGN.x, viewport_size.y / DESIGN.y)
	_origin = (viewport_size - DESIGN * _scale) * 0.5
	_put(_title, Rect2(40, 17, 660, 44))
	_put(_subtitle, Rect2(41, 61, 733, 28))
	_put(_round_label, Rect2(787, 18, 241, 29))
	_put(_score_label, Rect2(787, 54, 240, 29))
	_put(_language_picker, Rect2(1058, 16, 188, 42))
	_put(_hint_button, Rect2(932, 98, 141, 40))
	_put(_restart_button, Rect2(1081, 98, 164, 40))

	_put(_mission_label, Rect2(370, 169, 443, 33))
	_put(_phase_label, Rect2(430, 451, 355, 27))
	_put(_guide_label, Rect2(305, 486, 620, 24))
	_put(_panel_title, Rect2(980, 170, 260, 31))
	_put(_state_label, Rect2(982, 214, 256, 39))
	_put(_average_label, Rect2(992, 263, 237, 32))
	_put(_warm_label, Rect2(992, 305, 237, 30))
	_put(_cool_label, Rect2(992, 343, 237, 30))
	_put(_stable_label, Rect2(987, 412, 245, 25))
	_put(_next_button, Rect2(996, 454, 233, 52))

	_put(_distance_label, Rect2(59, 552, 548, 29))
	_put(_rotation_label, Rect2(685, 552, 510, 29))
	_put(_distance_near_label, Rect2(81, 638, 175, 23))
	_put(_distance_far_label, Rect2(416, 638, 178, 23))
	_put(_rotation_slow_label, Rect2(709, 638, 175, 23))
	_put(_rotation_fast_label, Rect2(1004, 638, 176, 23))
	_put(_instruction_label, Rect2(278, 91, 651, 38))
	_put(_tip_label, Rect2(354, 664, 584, 22))
	_put(_model_note, Rect2(70, 704, 1140, 15))
	queue_redraw()


func _bind_language() -> void:
	_service = get_node_or_null("/root/LanguageService")
	if _service != null:
		_language_picker.visible = false
		if _service.has_signal("language_changed"):
			_service.connect("language_changed", Callable(self, "_on_external_language_changed"))
		_read_service_language()
	else:
		var cfg := ConfigFile.new()
		var saved := "en"
		if cfg.load("user://mika_ice_planet.cfg") == OK:
			saved = str(cfg.get_value("settings", "language", "en"))
		_set_languages(saved, saved)


func _read_service_language() -> void:
	if _service != null:
		_set_languages(str(_service.get("interface_locale")), str(_service.get("learning_locale")))


func _on_external_language_changed(_locale: String) -> void:
	_read_service_language()


func _on_language_selected(index: int) -> void:
	if index >= 0 and index < LANGUAGE_CODES.size():
		var lang: String = LANGUAGE_CODES[index]
		if _service == null:
			var cfg := ConfigFile.new()
			cfg.set_value("settings", "language", lang)
			cfg.save("user://mika_ice_planet.cfg")
		_set_languages(lang, lang)


func _set_languages(ui_language: String, study_language: String) -> void:
	_interface_lang = ui_language if LANGUAGE_CODES.has(ui_language) else "en"
	_learning_lang = study_language if LANGUAGE_CODES.has(study_language) else _interface_lang
	if _language_picker != null:
		_language_picker.select(LANGUAGE_CODES.find(_learning_lang))
	_update_labels()


func _tr(key: String) -> String:
	var locale: Dictionary = _strings.get(_interface_lang, _strings.get("en", {}))
	return str(locale.get(key, key))


func _learn(key: String) -> String:
	var locale: Dictionary = _strings.get(_learning_lang, _strings.get("en", {}))
	return str(locale.get(key, key))


func _restart_game() -> void:
	_score = 0
	_mission_index = 0
	_game_complete = false
	_open_world()


func _open_world() -> void:
	if _missions.is_empty():
		return
	if _mission_index >= _missions.size():
		_game_complete = true
		_mission_complete = true
		_next_button.visible = true
		_update_labels()
		return
	var data: Dictionary = _missions[_mission_index]
	_distance = clampf(float(data.get("start_distance", 0.8)), 0.0, 1.0)
	_spin = clampf(float(data.get("start_spin", 0.2)), 0.0, 1.0)
	_stable_seconds = 0.0
	_mission_complete = false
	_game_complete = false
	_hint_seconds = 0.0
	_hint_key = ""
	_drag_mode = ""
	_next_button.visible = false
	_update_temperatures()
	_update_labels()
	queue_redraw()


func _next_world() -> void:
	if _game_complete:
		_restart_game()
	elif _mission_complete:
		_mission_index += 1
		_open_world()


func _update_temperatures() -> void:
	# Teaching model: a wider orbit cools the globe; faster rotation evens out
	# day and night. Values are illustrative, not real exoplanet calculations.
	_mean_temp = lerpf(124.0, -49.0, _distance)
	var contrast := lerpf(40.0, 9.0, _spin)
	_warm_temp = _mean_temp + contrast
	_cool_temp = _mean_temp - contrast
	if _warm_temp >= 100.0:
		_status = "hot"
	elif _cool_temp <= 2.0:
		_status = "cold"
	elif _spin < 0.55:
		_status = "spin"
	else:
		_status = "good"


func _process(delta: float) -> void:
	_elapsed += delta
	_planet_angle = wrapf(_planet_angle + delta * lerpf(0.23, 2.2, _spin), 0.0, TAU)
	if _hint_seconds > 0.0:
		_hint_seconds -= delta
		if _hint_seconds <= 0.0:
			_hint_key = ""
	if not _mission_complete and not _game_complete:
		_update_temperatures()
		if _status == "good":
			_stable_seconds += delta
			if _stable_seconds >= HOLD_TO_WIN:
				_stable_seconds = HOLD_TO_WIN
				_mission_complete = true
				_score += 100
				if _mission_index == _missions.size() - 1:
					_game_complete = true
				_next_button.visible = true
		else:
			_stable_seconds = maxf(0.0, _stable_seconds - delta * 2.5)
	_update_labels()
	queue_redraw()


func _show_hint() -> void:
	if _mission_complete or _game_complete:
		return
	_update_temperatures()
	_hint_key = "hint_" + _status
	_hint_seconds = 5.0
	_update_labels()


func _status_key() -> String:
	if _game_complete:
		return "status_finish"
	if _mission_complete:
		return "status_complete"
	return "status_" + _status


func _tip_key() -> String:
	if _game_complete:
		return "tip_finish"
	if _mission_complete:
		return "tip_complete"
	return "tip_" + _status


func _phase_key() -> String:
	if _mean_temp < -5.0:
		return "phase_ice"
	if _mean_temp < 12.0 or _cool_temp < 2.0:
		return "phase_mix"
	if _mean_temp > 105.0:
		return "phase_steam"
	if _mean_temp > 80.0:
		return "phase_hot"
	return "phase_water"


func _mission_id() -> String:
	if _missions.is_empty():
		return "melt"
	return str(_missions[mini(_mission_index, _missions.size() - 1)].get("id", "melt"))


func _update_labels() -> void:
	if _title == null:
		return
	_title.text = _tr("title")
	_subtitle.text = _tr("subtitle")
	_round_label.text = "%s  %d / %d" % [_tr("round"), mini(_mission_index + 1, _missions.size()), _missions.size()]
	_score_label.text = "%s  %d / %d" % [_tr("score"), _score, _missions.size() * 100]
	_hint_button.text = _tr("hint")
	_restart_button.text = _tr("restart")
	_next_button.text = _tr("again") if _game_complete else _tr("next")
	_mission_label.text = _learn("mission_" + _mission_id())
	_panel_title.text = _tr("conditions")
	_state_label.text = _tr(_status_key())
	var state_color := Color("b6f4d5") if (_status == "good" or _mission_complete) else Color("ffdcaa")
	_state_label.add_theme_color_override("font_color", state_color)
	_average_label.text = "%s  %+d°C" % [_tr("surface"), roundi(_mean_temp)]
	_warm_label.text = "%s  %+d°C" % [_tr("day"), roundi(_warm_temp)]
	_cool_label.text = "%s  %+d°C" % [_tr("night"), roundi(_cool_temp)]
	_stable_label.text = "%s   %.1f / %.0f s" % [_tr("hold"), _stable_seconds, HOLD_TO_WIN]
	_phase_label.text = _tr(_phase_key())
	_guide_label.text = _tr("drag_guide")
	_distance_label.text = _tr("distance")
	_rotation_label.text = _tr("rotate_title")
	_distance_near_label.text = _tr("distance_left")
	_distance_far_label.text = _tr("distance_right")
	_rotation_slow_label.text = _tr("spin_left")
	_rotation_fast_label.text = _tr("spin_right")
	_instruction_label.text = _learn("instruction")
	_tip_label.text = _tr(_hint_key) if _hint_seconds > 0.0 else _tr(_tip_key())
	_model_note.text = _tr("info")


func _planet_center() -> Vector2:
	return Vector2(lerpf(ORBIT_X_MIN, ORBIT_X_MAX, _distance), PLANET_Y)


func _from_viewport(pixel: Vector2) -> Vector2:
	return (pixel - _origin) / maxf(_scale, 0.001)


func _input(event: InputEvent) -> void:
	if _mission_complete or _game_complete:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(_from_viewport(event.position))
			else:
				_drag_mode = ""
	elif event is InputEventMouseMotion and not _drag_mode.is_empty():
		_drag_to(_from_viewport(event.position))
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(_from_viewport(event.position))
		else:
			_drag_mode = ""
	elif event is InputEventScreenDrag and not _drag_mode.is_empty():
		_drag_to(_from_viewport(event.position))


func _start_drag(point: Vector2) -> void:
	_drag_mode = ""
	_drag_start = point
	_distance_at_press = _distance
	_spin_at_press = _spin
	if Rect2(69, 597, 535, 48).has_point(point):
		_drag_mode = "distance"
		_drag_to(point)
	elif Rect2(688, 597, 506, 48).has_point(point):
		_drag_mode = "spin"
		_drag_to(point)
	elif point.distance_to(_planet_center()) < PLANET_RADIUS + 20.0:
		_drag_mode = "planet"
	elif Rect2(370, 328, 500, 60).has_point(point):
		_drag_mode = "distance_orbit"
		_drag_to(point)


func _drag_to(point: Vector2) -> void:
	match _drag_mode:
		"distance", "distance_orbit":
			var min_x := DISTANCE_BAR.position.x if _drag_mode == "distance" else ORBIT_X_MIN
			var max_x := (DISTANCE_BAR.position.x + DISTANCE_BAR.size.x) if _drag_mode == "distance" else ORBIT_X_MAX
			_distance = clampf((point.x - min_x) / (max_x - min_x), 0.0, 1.0)
		"spin":
			_spin = clampf((point.x - ROTATION_BAR.position.x) / ROTATION_BAR.size.x, 0.0, 1.0)
		"planet":
			var movement := point - _drag_start
			if absf(movement.x) >= absf(movement.y):
				_distance = clampf(_distance_at_press + movement.x / (ORBIT_X_MAX - ORBIT_X_MIN), 0.0, 1.0)
			else:
				_spin = clampf(_spin_at_press - movement.y / 255.0, 0.0, 1.0)
	_update_temperatures()
	_update_labels()
	queue_redraw()


func _draw() -> void:
	draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
	_draw_background()
	_draw_panels()
	_draw_orbit()
	_draw_sun()
	_draw_planet()
	_draw_monitor()
	_draw_sliders()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _panel(rect: Rect2, fill_color: Color, edge_color: Color, radius: int = 22, width: int = 2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = edge_color
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN), Color("07111f"), true)
	for i in range(145):
		var x := fmod(float(i * 181 + 37), DESIGN.x)
		var y := fmod(float(i * 73 + 19), DESIGN.y)
		var alpha := 0.22 + 0.20 * sin(float(i) * 2.87 + _elapsed * 0.34)
		draw_circle(Vector2(x, y), 0.65 + float(i % 3) * 0.45, Color(0.72, 0.88, 1.0, alpha), true)
	draw_circle(Vector2(109, 290), 238, Color(0.12, 0.30, 0.49, 0.14), true)
	draw_circle(Vector2(1023, 125), 268, Color(0.16, 0.30, 0.54, 0.10), true)
	# Thin crosshair motifs of the phase beings.
	for i in range(3):
		var a := Vector2(1174 + i * 21, 95 + i * 11)
		draw_arc(a, 17.0 + i * 8.0, -2.3, 0.9, 38, Color(0.32, 0.71, 0.95, 0.24), 1.5, true)
	draw_texture_rect(STAR_ICON, Rect2(1230, 675, 28, 28), false, Color(0.74, 0.91, 1.0, 0.60))


func _draw_panels() -> void:
	_panel(Rect2(27, 149, 929, 374), Color("0d2039"), Color("366a90"), 23, 2)
	_panel(Rect2(971, 149, 281, 374), Color("10253e"), Color("37658b"), 23, 2)
	_panel(Rect2(29, 537, 1222, 161), Color("0e2039"), Color("3b7297"), 22, 2)
	_panel(Rect2(274, 93, 654, 40), Color("142d47"), Color("4e7c9b"), 15, 1)
	draw_line(Vector2(955, 174), Vector2(955, 493), Color("447ca1", 0.42), 1.5, true)
	# Dividing line between the two interactive controls.
	draw_line(Vector2(638, 558), Vector2(638, 668), Color("34658e", 0.8), 2.0, true)


func _draw_orbit() -> void:
	# Stylised orbital-distance guide, not a physical path/orbit diagram.
	var base := Vector2(ORBIT_X_MIN, PLANET_Y + 1.0)
	var end := Vector2(ORBIT_X_MAX, PLANET_Y + 1.0)
	draw_line(base, end, Color("2b526e"), 6.0, true)
	for i in range(13):
		var t := float(i) / 12.0
		var x := lerpf(ORBIT_X_MIN, ORBIT_X_MAX, t)
		draw_line(Vector2(x, PLANET_Y - 6.0), Vector2(x, PLANET_Y + 7.0), Color("5f9bbd", 0.48), 1.8, true)
	var ideal_a := lerpf(ORBIT_X_MIN, ORBIT_X_MAX, 0.43)
	var ideal_b := lerpf(ORBIT_X_MIN, ORBIT_X_MAX, 0.66)
	draw_line(Vector2(ideal_a, PLANET_Y + 2.0), Vector2(ideal_b, PLANET_Y + 2.0), Color("4de7b1", 0.36), 8.0, true)
	for j in range(4):
		var px := 325 + j * 168
		draw_arc(Vector2(px, 361), 40.0 + j * 12.0, -2.45, -1.8, 22, Color(0.36, 0.68, 0.9, 0.09), 1.0, true)


func _draw_sun() -> void:
	var pulse := 1.0 + sin(_elapsed * 1.9) * 0.025
	for i in range(5, 0, -1):
		draw_circle(STAR_POS, (78.0 + float(i) * 19.0) * pulse, Color(1.0, 0.53, 0.20, 0.018 + float(i) * 0.009), true)
	for i in range(18):
		var a := float(i) * TAU / 18.0 + _elapsed * 0.065
		var ray_start := STAR_POS + Vector2.from_angle(a) * 84.0
		var ray_end := STAR_POS + Vector2.from_angle(a) * (101.0 + float(i % 4) * 9.0)
		draw_line(ray_start, ray_end, Color(1.0, 0.72, 0.34, 0.31), 3.0, true)
	draw_circle(STAR_POS, 78.0, Color("e7833f"), true)
	draw_circle(STAR_POS + Vector2(-11, -9), 66.0, Color("ffb659"), true)
	draw_circle(STAR_POS + Vector2(-18, -17), 52.0, Color("ffe2a0"), true)
	draw_circle(STAR_POS + Vector2(-22, -22), 35.0, Color("fff1c4"), true)
	draw_arc(STAR_POS, 81, -2.1, 1.4, 70, Color(1.0, 0.91, 0.60, 0.7), 3.0, true)


func _draw_planet() -> void:
	var p := _planet_center()
	var ice_ratio := clampf((15.0 - _cool_temp) / 56.0, 0.0, 1.0)
	var vapour_ratio := clampf((_warm_temp - 78.0) / 56.0, 0.0, 1.0)
	var ocean_ratio := clampf(1.0 - maxf(ice_ratio, vapour_ratio), 0.0, 1.0)
	# Outer atmospheric glow and a 3D-like shaded disc.
	for j in range(4, 0, -1):
		draw_circle(p, PLANET_RADIUS + 13.0 + 7.0 * float(j), Color(0.22, 0.63, 0.98, 0.010 + ocean_ratio * 0.008), true)
	draw_circle(p, PLANET_RADIUS + 3.0, Color("58baff"), true)
	draw_circle(p, PLANET_RADIUS, Color("173a65"), true)
	var ground := Color("2b83cf").lerp(Color("b6e4ed"), ice_ratio * 0.80).lerp(Color("c06a6b"), vapour_ratio * 0.80)
	draw_circle(p + Vector2(-6, -5), PLANET_RADIUS - 4.0, ground, true)
	# Fine lines across the sphere rotate, showing actual visual axial spin.
	for line_index in range(5):
		var points := PackedVector2Array()
		for step in range(29):
			var phase := float(step) / 28.0
			var x := lerpf(-60.0, 60.0, phase)
			var y := (float(line_index) - 2.0) * 23.0 + sin(phase * 7.0 + _planet_angle * 1.65 + line_index) * 8.0
			if Vector2(x, y).length() < 65.0:
				points.append(p + Vector2(x, y))
		if points.size() > 1:
			draw_polyline(points, Color(0.77, 0.97, 1.0, 0.19 + ocean_ratio * 0.25), 2.2, true)
	# Ice patches that shrink as the globe warms up.
	if ice_ratio > 0.01:
		for i in range(7):
			var angle := float(i) * 2.399 + _planet_angle * (0.38 + _spin * 0.40)
			var radial := 18.0 + float(i % 3) * 13.0
			var spot := p + Vector2(cos(angle), sin(angle)) * radial
			draw_circle(spot, 5.0 + ice_ratio * float(13 + i % 3 * 3), Color(0.91, 0.99, 1.0, 0.21 + ice_ratio * 0.65), true)
	# Liquid waves, with pale blue specular highlights.
	if ocean_ratio > 0.08:
		for i in range(3):
			var wave_y := -28.0 + i * 25.0
			draw_arc(p + Vector2(-8, wave_y), 28.0, 0.12, PI - 0.12, 21, Color(0.68, 0.98, 1.0, 0.16 + ocean_ratio * 0.24), 3.0, true)
	# Hot-world vapour streams escape around the top side.
	if vapour_ratio > 0.05:
		for k in range(8):
			var phase := _elapsed * 0.7 + float(k) * 1.17
			var smoke_pos := p + Vector2(cos(phase) * (88.0 + 15.0 * vapour_ratio), sin(phase) * (74.0 + 20.0 * vapour_ratio))
			draw_circle(smoke_pos, 3.0 + vapour_ratio * 7.0, Color(1.0, 0.78, 0.70, 0.28 * vapour_ratio), true)
	# Night side crescent: visually separates star-lit and cool sides.
	draw_arc(p, PLANET_RADIUS - 3.0, -PI * 0.52, PI * 0.50, 60, Color(0.04, 0.13, 0.30, 0.68), 14.0, true)
	draw_arc(p, PLANET_RADIUS + 2.0, -PI * 0.72, PI * 0.72, 64, Color(0.70, 0.94, 1.0, 0.85), 2.7, true)
	# Rotation ring and its bright moving marker.
	draw_arc(p, 104.0, -0.38, PI * 1.43, 90, Color(0.28, 0.65, 0.86, 0.24), 2.0, true)
	var marker := p + Vector2.from_angle(_planet_angle * 0.75 - 0.5) * 104.0
	draw_circle(marker, 5.6, Color("7debc9"), true)
	if _stable_seconds > 0.0:
		var ratio := clampf(_stable_seconds / HOLD_TO_WIN, 0.0, 1.0)
		draw_arc(p, 111.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 96, Color("61f1b7"), 6.0, true)
	if _mission_complete:
		for i in range(12):
			var a := _elapsed * 0.3 + float(i) * TAU / 12.0
			var radius := 124.0 + 4.0 * sin(_elapsed * 1.8 + i)
			draw_circle(p + Vector2.from_angle(a) * radius, 3.0, Color(0.65, 1.0, 0.80, 0.68), true)


func _draw_monitor() -> void:
	# Heat marker: cold (blue) — water zone (green) — hot (orange).
	var left := 990.0
	var width := 239.0
	_panel(Rect2(left, 384, width, 13), Color("152e45"), Color("39617e"), 7, 1)
	draw_rect(Rect2(left + 4, 388, width * 0.38, 5), Color("68bdff"), true)
	draw_rect(Rect2(left + 4 + width * 0.38, 388, width * 0.31, 5), Color("62e5af"), true)
	draw_rect(Rect2(left + 4 + width * 0.69, 388, width * 0.29 - 8.0, 5), Color("ffb16c"), true)
	var heat_t := clampf((_mean_temp + 49.0) / 173.0, 0.0, 1.0)
	var indicator_x := left + 7.0 + heat_t * (width - 14.0)
	draw_circle(Vector2(indicator_x, 391.0), 8.0, Color("d6f8ff"), true)
	draw_circle(Vector2(indicator_x, 391.0), 4.0, Color("1a3852"), true)
	var fraction := clampf(_stable_seconds / HOLD_TO_WIN, 0.0, 1.0)
	_panel(Rect2(986, 443, 248, 5), Color("233b50"), Color("233b50"), 2, 0)
	if fraction > 0.0:
		draw_rect(Rect2(988, 444, 244 * fraction, 3), Color("78f0bf"), true)


func _draw_slider(track: Rect2, value: float, accent: Color) -> void:
	var rail := Rect2(track.position.x, track.position.y, track.size.x, 10)
	_panel(rail, Color("132c45"), Color("3f6e93"), 6, 1)
	if value > 0.001:
		_panel(Rect2(rail.position.x + 3, rail.position.y + 2, (rail.size.x - 6) * value, 6), Color(accent.r, accent.g, accent.b, 0.56), Color(accent.r, accent.g, accent.b, 0.56), 3, 0)
	var x := rail.position.x + rail.size.x * value
	var knob := Vector2(x, rail.position.y + 5.0)
	draw_circle(knob, 22.0, Color(accent.r, accent.g, accent.b, 0.12), true)
	draw_circle(knob, 15.0, accent, true)
	draw_circle(knob + Vector2(-4, -5), 5.0, Color(1, 1, 1, 0.64), true)
	draw_arc(knob, 15.4, 0, TAU, 32, Color("d8f7ff"), 2.0, true)


func _draw_sliders() -> void:
	_draw_slider(DISTANCE_BAR, _distance, Color("83d3ff"))
	_draw_slider(ROTATION_BAR, _spin, Color("78eeb6"))
	# Small decorative sun / circular rotation glyphs.
	draw_circle(Vector2(73, 564), 6.0, Color("ffd08b"), true)
	draw_arc(Vector2(697, 566), 8.0, -2.5, 1.8, 24, Color("80e4bf"), 2.2, true)
