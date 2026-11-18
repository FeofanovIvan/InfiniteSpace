extends Control
## MIKA / LMC / sentient mycelium — Mushroom Race v1.
## Self-contained: all 2D art is drawn in Godot; shared navy/cyan styling from Eco Sorting v2.
## A child grows a fungal colony by correctly allocating finite water, organic matter and minerals.

const DESIGN := Vector2(1280.0, 720.0)
const RESOURCE_KEYS := ["water", "food", "minerals"]
const RESOURCE_COLORS := [Color("66d2ff"), Color("91e9a3"), Color("edc888")]
const RESOURCE_RECTS := [Rect2(184, 583, 265, 91), Rect2(481, 583, 265, 91), Rect2(778, 583, 265, 91)]
const PATH_POINTS := [
	Vector2(155, 348), Vector2(269, 321), Vector2(391, 355),
	Vector2(513, 309), Vector2(633, 353), Vector2(755, 315),
	Vector2(878, 356), Vector2(1000, 308), Vector2(1121, 343)
]
const LAN_CODES := ["ru", "en", "pt", "es", "de", "fr"]
const STAR_ICON = preload("res://planet_hub/games/mycelium_race/star_core.png")
const PLAY_PANEL := Rect2(24, 141, 1232, 388)
const CHALLENGE_RECT := Rect2(406, 154, 468, 72)
const DRAG_TARGET_RADIUS := 104.0
const RACE_SECONDS := 135.0

var _texts: Dictionary = {}
var _lang := "en"
var _service: Node
var _scale := 1.0
var _origin := Vector2.ZERO
var _clock := 0.0
var _race_clock := 0.0
var _rival_progress := 0.0
var _race_mode := 0
var _step := 0
var _score := 0
var _mistakes := 0
var _streak := 0
var _boost_uses := 0
var _requirements: Array[String] = []
var _supplies := {"water": 4, "food": 4, "minerals": 3}
var _hint_enabled := false
var _bonus_selected := false
var _feedback_text := ""
var _feedback_color := Color("a8d9e9")
var _playing := false
var _finished := false
var _won := false
var _busy := false
var _growth_t := 0.0
var _pending_key := ""
var _pending_bonus := false
var _pressed_resource := -1
var _press_point := Vector2.ZERO
var _dragging := false
var _drag_point := Vector2.ZERO
var _hover_resource := -1
var _sparkles: Array[Dictionary] = []

var _title: Label
var _subtitle: Label
var _score_lbl: Label
var _step_lbl: Label
var _time_lbl: Label
var _need_title: Label
var _need_value: Label
var _feedback: Label
var _instruction: Label
var _supplies_lbl: Label
var _supply_titles: Array[Label] = []
var _supply_counts: Array[Label] = []
var _language: OptionButton
var _mode: OptionButton
var _restart: Button
var _hint: Button
var _bonus: Button
var _again: Button
var _overlay_title: Label
var _overlay_detail: Label
var _rival_lbl: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var json = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/mycelium_race/data/strings.json"))
	if typeof(json) == TYPE_DICTIONARY:
		_texts = json
	_create_controls()
	_detect_language()
	_layout()
	get_viewport().size_changed.connect(_layout)
	_new_game()

func _create_controls() -> void:
	_title = _label(31, Color("effaff"), HORIZONTAL_ALIGNMENT_LEFT)
	_subtitle = _label(15, Color("98c6e5"), HORIZONTAL_ALIGNMENT_LEFT)
	_score_lbl = _label(20, Color("effaff"), HORIZONTAL_ALIGNMENT_LEFT)
	_step_lbl = _label(17, Color("b8e4ff"), HORIZONTAL_ALIGNMENT_LEFT)
	_time_lbl = _label(17, Color("b6ffe4"), HORIZONTAL_ALIGNMENT_LEFT)
	_need_title = _label(15, Color("a6d5ed"), HORIZONTAL_ALIGNMENT_CENTER)
	_need_value = _label(27, Color("fff4bc"), HORIZONTAL_ALIGNMENT_CENTER)
	_feedback = _label(19, Color("b7f9df"), HORIZONTAL_ALIGNMENT_CENTER)
	_instruction = _label(16, Color("c3dff0"), HORIZONTAL_ALIGNMENT_CENTER)
	_supplies_lbl = _label(17, Color("a7c9e8"), HORIZONTAL_ALIGNMENT_CENTER)
	_rival_lbl = _label(14, Color("eac2eb"), HORIZONTAL_ALIGNMENT_LEFT)
	for _i in range(3):
		_supply_titles.append(_label(15, Color("f0faff"), HORIZONTAL_ALIGNMENT_LEFT))
		_supply_counts.append(_label(23, Color("effaff"), HORIZONTAL_ALIGNMENT_CENTER))

	_language = OptionButton.new()
	_language.focus_mode = Control.FOCUS_NONE
	for code in LAN_CODES:
		_language.add_item(str(_texts.get(code, {}).get("lang", code)))
	_language.item_selected.connect(_change_language)
	_skin_button(_language, Color("132f50"), Color("549ac6"))
	add_child(_language)

	_mode = OptionButton.new()
	_mode.focus_mode = Control.FOCUS_NONE
	_mode.item_selected.connect(_change_mode)
	_skin_button(_mode, Color("163654"), Color("56af9d"))
	add_child(_mode)

	_restart = _button("", Callable(self, "_new_game"))
	_hint = _button("", Callable(self, "_show_hint"))
	_bonus = _button("", Callable(self, "_toggle_bonus"))
	_again = _button("", Callable(self, "_new_game"))
	_overlay_title = _label(34, Color("f0fff4"), HORIZONTAL_ALIGNMENT_CENTER)
	_overlay_detail = _label(19, Color("c5efed"), HORIZONTAL_ALIGNMENT_CENTER)

func _label(font_size: int, color: Color, align_mode: HorizontalAlignment) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = align_mode
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.clip_text = true
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func _skin_button(node: BaseButton, bg: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.20)
	hover.border_color = Color("d4f7ff")
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.16)
	node.add_theme_stylebox_override("normal", style)
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", pressed)
	node.add_theme_color_override("font_color", Color("ebfaff"))
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_font_size_override("font_size", 15)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _button(value: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = value
	node.focus_mode = Control.FOCUS_NONE
	_skin_button(node, Color("153659"), Color("62afd9"))
	node.pressed.connect(callback)
	add_child(node)
	return node

func _rect(node: Control, rect: Rect2) -> void:
	node.scale = Vector2.ONE * _scale
	node.position = _origin + rect.position * _scale
	node.size = rect.size

func _layout() -> void:
	var view_size: Vector2 = size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		view_size = get_viewport_rect().size
	_scale = minf(view_size.x / DESIGN.x, view_size.y / DESIGN.y)
	_origin = (view_size - DESIGN * _scale) * 0.5
	_rect(_title, Rect2(45, 16, 680, 49))
	_rect(_subtitle, Rect2(47, 65, 726, 27))
	_rect(_score_lbl, Rect2(807, 23, 194, 28))
	_rect(_step_lbl, Rect2(807, 53, 194, 26))
	_rect(_time_lbl, Rect2(807, 80, 194, 26))
	_rect(_language, Rect2(1035, 18, 206, 39))
	_rect(_mode, Rect2(1035, 66, 206, 39))
	_rect(_need_title, Rect2(427, 156, 426, 28))
	_rect(_need_value, Rect2(425, 183, 430, 37))
	_rect(_instruction, Rect2(217, 538, 845, 28))
	_rect(_feedback, Rect2(217, 493, 845, 29))
	_rect(_supplies_lbl, Rect2(37, 604, 135, 34))
	_rect(_rival_lbl, Rect2(97, 471, 258, 23))
	for i in range(3):
		var r: Rect2 = RESOURCE_RECTS[i]
		_rect(_supply_titles[i], Rect2(r.position.x + 78, r.position.y + 13, r.size.x - 91, 40))
		_rect(_supply_counts[i], Rect2(r.end.x - 53, r.position.y + 40, 38, 33))
	_rect(_hint, Rect2(1065, 580, 176, 38))
	_rect(_bonus, Rect2(1065, 628, 176, 38))
	_rect(_restart, Rect2(1037, 110, 204, 32))
	_rect(_again, Rect2(518, 436, 244, 57))
	_rect(_overlay_title, Rect2(182, 272, 916, 54))
	_rect(_overlay_detail, Rect2(210, 347, 860, 49))
	queue_redraw()

func _detect_language() -> void:
	_service = get_node_or_null("/root/LanguageService")
	var code := "en"
	if _service != null:
		code = str(_service.get("learning_locale"))
		if not LAN_CODES.has(code):
			code = str(_service.get("interface_locale"))
		if _service.has_signal("language_changed"):
			_service.connect("language_changed", Callable(self, "_external_language_changed"))
		_language.visible = false
	else:
		var cfg := ConfigFile.new()
		if cfg.load("user://mika_mycelium_race.cfg") == OK:
			code = str(cfg.get_value("settings", "language", "en"))
	_apply_language(code)

func _external_language_changed(_code: String) -> void:
	if _service != null:
		_apply_language(str(_service.get("learning_locale")))

func _change_language(index: int) -> void:
	if index < 0 or index >= LAN_CODES.size():
		return
	var code := str(LAN_CODES[index])
	if _service != null and _service.has_method("set_learning_locale"):
		_service.call("set_learning_locale", code)
	else:
		var cfg := ConfigFile.new()
		cfg.set_value("settings", "language", code)
		cfg.save("user://mika_mycelium_race.cfg")
	_apply_language(code)

func _apply_language(code: String) -> void:
	_lang = code if LAN_CODES.has(code) else "en"
	_language.select(LAN_CODES.find(_lang))
	_refresh_text()

func _tr(key: String) -> String:
	var packet: Dictionary = _texts.get(_lang, _texts.get("en", {}))
	return str(packet.get(key, key))

func _refresh_text() -> void:
	_title.text = _tr("title")
	_subtitle.text = _tr("subtitle")
	_instruction.text = _tr("instruction")
	_need_title.text = _tr("need")
	_supplies_lbl.text = _tr("resource")
	_rival_lbl.text = _tr("rival")
	_hint.text = _tr("hint")
	_restart.text = _tr("restart")
	_again.text = _tr("again")
	_mode.clear()
	_mode.add_item(_tr("calm"))
	_mode.add_item(_tr("race"))
	_mode.select(_race_mode)
	for i in range(3):
		_supply_titles[i].text = _tr(RESOURCE_KEYS[i])
	_update_ui()

func _change_mode(index: int) -> void:
	_race_mode = index
	_new_game()

func _new_game() -> void:
	_requirements = ["water", "water", "water", "food", "food", "food", "minerals", "minerals"]
	_requirements.shuffle()
	_supplies = {"water": 4, "food": 4, "minerals": 3}
	_step = 0
	_score = 0
	_mistakes = 0
	_streak = 0
	_boost_uses = 0
	_hint_enabled = false
	_bonus_selected = false
	_feedback_text = _tr("status_ready")
	_feedback_color = Color("b9dfef")
	_playing = false
	_finished = false
	_won = false
	_busy = false
	_growth_t = 0.0
	_pending_key = ""
	_pending_bonus = false
	_race_clock = 0.0
	_rival_progress = 0.0
	_pressed_resource = -1
	_dragging = false
	_hover_resource = -1
	_sparkles.clear()
	_update_ui()

func _current_need() -> String:
	if _step >= 0 and _step < _requirements.size():
		return _requirements[_step]
	return ""

func _remaining_needs(key: String) -> int:
	var count := 0
	for idx in range(_step, _requirements.size()):
		if _requirements[idx] == key:
			count += 1
	return count

func _can_boost() -> bool:
	var needed := _current_need()
	return not needed.is_empty() and int(_supplies.get(needed, 0)) > _remaining_needs(needed)

func _toggle_bonus() -> void:
	if _finished or _busy:
		return
	if not _can_boost():
		_feedback_text = _tr("bonus_unavailable")
		_feedback_color = Color("ffcaaa")
		_bonus_selected = false
	else:
		_bonus_selected = not _bonus_selected
	_update_ui()

func _show_hint() -> void:
	if _finished or _busy:
		return
	_hint_enabled = true
	_feedback_text = _tr("hint_text")
	_feedback_color = Color("fff2b2")
	_update_ui()

func _attempt_feed(index: int) -> void:
	if _finished or _busy or index < 0 or index >= 3:
		return
	var key := str(RESOURCE_KEYS[index])
	_playing = true
	if key != _current_need():
		_mistakes += 1
		_streak = 0
		_feedback_text = _tr("wrong")
		_feedback_color = Color("ffc6b4")
		if _mistakes >= 2:
			_hint_enabled = true
		_update_ui()
		return
	if int(_supplies.get(key, 0)) <= 0:
		_feedback_text = _tr("bonus_unavailable")
		_feedback_color = Color("ffcaaa")
		_update_ui()
		return
	_pending_key = key
	_pending_bonus = _bonus_selected and _can_boost()
	_busy = true
	_growth_t = 0.0
	_hint_enabled = false
	_bonus_selected = false
	_feedback_text = _tr("good")
	_feedback_color = Color("aeffd5")
	var tween := create_tween()
	tween.tween_property(self, "_growth_t", 1.0, 0.58 if not _pending_bonus else 0.33).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_complete_growth"))
	_update_ui()

func _complete_growth() -> void:
	if not _busy or _finished:
		return
	var used := 2 if _pending_bonus else 1
	_supplies[_pending_key] = int(_supplies[_pending_key]) - used
	_step += 1
	_streak += 1
	_score += 10
	if _pending_bonus:
		_boost_uses += 1
		_score += 5
	if _streak % 3 == 0:
		_score += 5
	_spawn_sparkles(PATH_POINTS[_step], RESOURCE_KEYS.find(_pending_key))
	_pending_key = ""
	_pending_bonus = false
	_growth_t = 0.0
	_busy = false
	_mistakes = 0
	if _step >= _requirements.size():
		_finish(true)
	else:
		_update_ui()

func _finish(success: bool) -> void:
	_finished = true
	_won = success
	_busy = false
	_playing = false
	_dragging = false
	_pressed_resource = -1
	_feedback_text = ""
	_update_ui()

func _update_ui() -> void:
	if _score_lbl == null:
		return
	_score_lbl.text = "%s  %03d" % [_tr("score"), _score]
	_step_lbl.text = "%s  %d / %d" % [_tr("stage"), _step, _requirements.size()]
	if _race_mode == 1:
		_time_lbl.text = "%s  %d s" % [_tr("time"), ceili(maxf(0.0, RACE_SECONDS - _race_clock))]
	else:
		_time_lbl.text = _tr("calm")
	_need_value.text = _tr(_current_need()) if not _current_need().is_empty() else "★"
	_feedback.text = _feedback_text
	_feedback.add_theme_color_override("font_color", _feedback_color)
	for i in range(3):
		_supply_counts[i].text = "%d" % int(_supplies.get(RESOURCE_KEYS[i], 0))
	_bonus.text = _tr("bonus_on") if _bonus_selected else _tr("bonus_off")
	_bonus.disabled = _finished or _busy or not _can_boost()
	_hint.disabled = _finished or _busy
	_restart.disabled = _busy
	_mode.disabled = _busy
	_again.visible = _finished
	_overlay_title.visible = _finished
	_overlay_detail.visible = _finished
	_overlay_title.text = _tr("win") if _won else _tr("lose")
	_overlay_detail.text = _tr("win_desc") if _won else _tr("lose_desc")
	queue_redraw()

func _resource_at(point: Vector2) -> int:
	for i in range(RESOURCE_RECTS.size()):
		if RESOURCE_RECTS[i].has_point(point):
			return i
	return -1

func _to_design(pos: Vector2) -> Vector2:
	return (pos - _origin) / maxf(_scale, 0.001)

func _input(event: InputEvent) -> void:
	if _finished or _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point := _to_design(event.position)
		if event.pressed:
			var idx := _resource_at(point)
			if idx >= 0:
				_pressed_resource = idx
				_press_point = point
				_drag_point = point
				_dragging = false
				get_viewport().set_input_as_handled()
		else:
			if _pressed_resource >= 0:
				var chosen := _pressed_resource
				var was_dragged := _dragging
				_pressed_resource = -1
				_dragging = false
				_hover_resource = -1
				if not was_dragged or point.distance_to(PATH_POINTS[mini(_step + 1, PATH_POINTS.size() - 1)]) < DRAG_TARGET_RADIUS:
					_attempt_feed(chosen)
				queue_redraw()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if _pressed_resource >= 0:
			_drag_point = _to_design(event.position)
			if _drag_point.distance_to(_press_point) > 14.0:
				_dragging = true
			queue_redraw()
			get_viewport().set_input_as_handled()
		else:
			var next_hover := _resource_at(_to_design(event.position))
			if next_hover != _hover_resource:
				_hover_resource = next_hover
				queue_redraw()

func _process(delta: float) -> void:
	_clock += delta
	if _race_mode == 1 and _playing and not _finished:
		_race_clock += delta
		_rival_progress = clampf(_race_clock / RACE_SECONDS * float(_requirements.size()), 0.0, float(_requirements.size()))
		if _rival_progress >= float(_requirements.size()) and _step < _requirements.size():
			_finish(false)
		elif int(_clock * 2.0) != int((_clock - delta) * 2.0):
			_update_ui()
	elif _race_mode == 0:
		_rival_progress = minf(float(_step) * 0.52, 5.5)
	for i in range(_sparkles.size() - 1, -1, -1):
		var s: Dictionary = _sparkles[i]
		s["life"] = float(s["life"]) - delta
		if float(s["life"]) < 0.0:
			_sparkles.remove_at(i)
		else:
			s["point"] = Vector2(s["point"]) + Vector2(s["velocity"]) * delta
			s["velocity"] = Vector2(s["velocity"]) * (1.0 - 0.85 * delta)
			_sparkles[i] = s
	queue_redraw()

func _spawn_sparkles(at: Vector2, color_index: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var color: Color = RESOURCE_COLORS[maxi(0, color_index)]
	for i in range(18):
		var a := TAU * float(i) / 18.0 + rng.randf_range(-0.2, 0.2)
		_sparkles.append({
			"point": at,
			"velocity": Vector2(cos(a), sin(a)) * rng.randf_range(55.0, 135.0),
			"life": rng.randf_range(0.42, 0.93),
			"color": color
		})

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("060e20"), true)
	draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
	_draw_background()
	_draw_hud()
	_draw_stage()
	_draw_resources()
	for particle in _sparkles:
		var life := clampf(float(particle["life"]), 0.0, 1.0)
		var color: Color = particle["color"]
		draw_circle(particle["point"], 1.0 + life * 4.0, Color(color.r, color.g, color.b, life * 0.7))
	if _dragging and _pressed_resource >= 0:
		var color: Color = RESOURCE_COLORS[_pressed_resource]
		draw_circle(_drag_point + Vector2(0, 5), 33, Color(0, 0, 0, 0.28))
		draw_circle(_drag_point, 31, Color(color.r, color.g, color.b, 0.32))
		_draw_nutrient_icon(_pressed_resource, _drag_point, 0.77)
	if _finished:
		_draw_end_panel()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _box(rect: Rect2, bg: Color, border: Color, corner: int = 20, width: int = 2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(corner)
	style.set_border_width_all(width)
	draw_style_box(style, rect)

func _draw_background() -> void:
	for i in range(36):
		var fade := float(i) / 35.0
		draw_rect(Rect2(0, float(i) * 20.0, 1280, 21), Color("061024").lerp(Color("0d2138"), fade))
	for i in range(86):
		var p := Vector2(14.0 + fmod(float(i * 197 + 29), 1250.0), 123.0 + fmod(float(i * 103 + 7), 575.0))
		var opacity := 0.19 + 0.09 * sin(_clock * 0.8 + float(i))
		draw_circle(p, 1.0 + float(i % 3) * 0.45, Color(0.69, 0.87, 1, opacity))
	for side in range(2):
		var edge := 20.0 if side == 0 else 1260.0
		var direction := 1.0 if side == 0 else -1.0
		for j in range(8):
			var p := Vector2(edge, 180 + j * 65)
			var branch := p + Vector2(direction * (24 + j % 3 * 17), 16)
			var end := branch + Vector2(direction * 23, -10)
			draw_line(p, branch, Color(0.29, 0.73, 0.57, 0.14), 2, true)
			draw_line(branch, end, Color(0.34, 0.90, 0.65, 0.13), 2, true)
			draw_circle(end, 2.7, Color(0.42, 1, 0.73, 0.19))

func _draw_hud() -> void:
	_box(Rect2(24, 10, 1232, 110), Color("0c213a"), Color("335e83"), 23, 2)
	_box(Rect2(790, 18, 229, 94), Color("112e4e"), Color("3c739e"), 14, 2)
	draw_line(Vector2(46, 99), Vector2(768, 99), Color(0.39, 0.77, 1.0, 0.21), 2, true)
	draw_texture_rect(STAR_ICON, Rect2(764, 21, 21, 21), false, Color(0.79, 0.99, 0.87, 0.74))
	# Header progress LEDs
	for i in range(8):
		var c := Vector2(320 + i * 51.0, 111)
		draw_circle(c, 4.8, Color("7cecbf") if i < _step else Color("315577"))

func _draw_stage() -> void:
	_box(Rect2(PLAY_PANEL.position + Vector2(0, 6), PLAY_PANEL.size), Color(0.0, 0.0, 0.0, 0.20), Color(0,0,0,0), 27, 0)
	_box(PLAY_PANEL, Color("0d213d"), Color("406f98"), 27, 2)
	_box(CHALLENGE_RECT, Color("102d4d"), Color("4b93ba"), 21, 2)
	# faint living-green background clusters, never covering prompts
	for index in range(5):
		var p := Vector2(128 + 230 * index, 407 + 23 * (index % 2))
		for ring in range(4, 0, -1):
			draw_circle(p, 18 + 23 * ring, Color(0.18, 0.62, 0.48, 0.012))
	# The finish is a bioluminescent gate, unlike an ordinary mechanical goal.
	_draw_finish_gate(Vector2(1153, 340))
	# Future trail, including ghost stations
	for i in range(PATH_POINTS.size() - 1):
		var a: Vector2 = PATH_POINTS[i]
		var b: Vector2 = PATH_POINTS[i + 1]
		var d := (b - a).normalized()
		var total := a.distance_to(b)
		for k in range(int(total / 17.0)):
			var p := a + d * float(k * 17)
			draw_circle(p, 2.2, Color(0.28, 0.56, 0.56, 0.22))
		_draw_ghost_node(b)
	# Ally growth path: bright green organic veins, clear but not over-rendered
	for i in range(_step):
		_draw_grown_segment(PATH_POINTS[i], PATH_POINTS[i + 1], 1.0, i)
	if _busy and _step < _requirements.size():
		_draw_grown_segment(PATH_POINTS[_step], PATH_POINTS[_step + 1], _growth_t, _step)
	var head_idx := mini(_step, PATH_POINTS.size() - 1)
	var head: Vector2 = PATH_POINTS[head_idx]
	if _busy and _step + 1 < PATH_POINTS.size():
		head = PATH_POINTS[_step].lerp(PATH_POINTS[_step + 1], _growth_t)
	_draw_colony_head(head, Color("8affbb"), 1.0)
	# Next sprout: target to drop a nutrient onto
	if _step < _requirements.size() and not _busy:
		var target: Vector2 = PATH_POINTS[_step + 1]
		var pulse := 0.5 + 0.5 * sin(_clock * 4.8)
		for ring in range(3, 0, -1):
			draw_circle(target, 16.0 + ring * 12.0, Color(0.45, 1, 0.67, 0.027 + pulse * 0.019))
		draw_arc(target, 21.0 + pulse * 5.0, 0, TAU, 48, Color(0.60, 1, 0.76, 0.55), 2, true)
		_draw_sprout(target, 1.0 + pulse * 0.1)
		var required_index := RESOURCE_KEYS.find(_current_need())
		_draw_nutrient_icon(required_index, target + Vector2(0, -62), 0.41)
	# Other colony stays in its own lower lane: soft mauve filaments, no faces/eyes.
	var rival_start := Vector2(155, 457)
	var rival_end := Vector2(1121, 457)
	draw_line(rival_start, rival_end, Color(0.73, 0.37, 0.71, 0.16), 7, true)
	var rival_head := rival_start.lerp(rival_end, _rival_progress / float(_requirements.size()))
	draw_line(rival_start, rival_head, Color("ad76c8"), 9, true)
	draw_line(rival_start, rival_head, Color(0.81, 0.60, 0.91, 0.40), 3, true)
	for i in range(int(_rival_progress)):
		var t := float(i + 1) / float(_requirements.size())
		var p := rival_start.lerp(rival_end, t)
		_draw_rival_branch(p)
	_draw_colony_head(rival_head, Color("d3a0ef"), 0.74)

func _draw_finish_gate(c: Vector2) -> void:
	for i in range(5):
		var r := 24.0 + float(i) * 7.0
		draw_arc(c, r, -PI * 0.62, PI * 0.62, 60, Color(0.55, 0.88, 1.0, 0.24 - 0.03 * float(i)), 3.0, true)
	for j in range(6):
		var a := TAU * float(j) / 6.0 + _clock * 0.22
		draw_circle(c + Vector2(cos(a), sin(a)) * 26, 3.0, Color(0.57, 0.90, 1, 0.43))

func _draw_ghost_node(c: Vector2) -> void:
	draw_circle(c, 12.0, Color("203b49"))
	draw_arc(c, 13.0, 0, TAU, 24, Color(0.38, 0.67, 0.59, 0.24), 2, true)

func _draw_grown_segment(start: Vector2, finish: Vector2, amount: float, index: int) -> void:
	var end := start.lerp(finish, amount)
	draw_line(start, end, Color(0.20, 0.99, 0.64, 0.12), 19, true)
	draw_line(start, end, Color("338c75"), 11, true)
	draw_line(start, end, Color("77eaba"), 5, true)
	var vec := (finish - start).normalized()
	var side := Vector2(-vec.y, vec.x)
	for j in range(3):
		var part := 0.23 + float(j) * 0.26
		if amount < part:
			continue
		var from := start.lerp(finish, part)
		var direction := -1.0 if (index + j) % 2 == 0 else 1.0
		var to := from + side * (19.0 + j % 2 * 10.0) * direction + vec * 10.0
		draw_line(from, to, Color("69cba7"), 3.0, true)
		draw_circle(to, 3.3, Color("abffd2"))

func _draw_sprout(at: Vector2, s: float) -> void:
	draw_line(at + Vector2(0, 13) * s, at + Vector2(0, -10) * s, Color("9dffc3"), 4, true)
	_poly(at, [Vector2(0, -4), Vector2(-26, -24), Vector2(-14, 2)], s, Color("78e69b"))
	_poly(at, [Vector2(0, -4), Vector2(26, -27), Vector2(13, 4)], s, Color("adffc8"))

func _draw_rival_branch(p: Vector2) -> void:
	draw_line(p, p + Vector2(11, -19), Color("bf86df"), 3.0, true)
	draw_circle(p + Vector2(11, -19), 4.0, Color("dba4f7"))

func _draw_colony_head(at: Vector2, tint: Color, scale_size: float) -> void:
	var pulse := 1.0 + 0.06 * sin(_clock * 4.4)
	draw_circle(at, 29.0 * scale_size * pulse, Color(tint.r, tint.g, tint.b, 0.09))
	draw_circle(at, 17.0 * scale_size, Color("143b42"))
	draw_circle(at, 12.8 * scale_size, tint)
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + _clock * 0.28
		var offset := Vector2(cos(angle), sin(angle)) * 20.0 * scale_size
		draw_circle(at + offset, 2.0 * scale_size, Color(tint.r, tint.g, tint.b, 0.65))

func _draw_resources() -> void:
	_box(Rect2(23, 571, 1234, 118), Color("0c2039"), Color("386e91"), 26, 2)
	for i in range(3):
		var r: Rect2 = RESOURCE_RECTS[i]
		var c: Color = RESOURCE_COLORS[i]
		var active: bool = i == _hover_resource or (_hint_enabled and RESOURCE_KEYS[i] == _current_need())
		var dim := int(_supplies.get(RESOURCE_KEYS[i], 0)) <= 0
		var fill := Color("102b46") if not active else Color("19435a")
		if dim:
			fill = Color("142432")
		_box(Rect2(r.position + Vector2(0, 4), r.size), Color(0,0,0,0.22), Color.TRANSPARENT, 21, 0)
		_box(r, fill, c if active else Color(c.r, c.g, c.b, 0.56), 20, 3 if active else 2)
		draw_circle(r.position + Vector2(43, 45), 31, Color(c.r, c.g, c.b, 0.12))
		_draw_nutrient_icon(i, r.position + Vector2(43, 45), 0.70)
		for j in range(4):
			var on := j < int(_supplies.get(RESOURCE_KEYS[i], 0))
			draw_circle(r.position + Vector2(89 + j * 29, 68), 4.8, c if on else Color("294b61"))
		if active:
			_box(r.grow(4), Color.TRANSPARENT, Color(c.r, c.g, c.b, 0.26), 24, 2)
	# Little root structure behind labels: quiet and consistent across series.
	for k in range(5):
		var x := 39 + k * 23.0
		draw_line(Vector2(x, 669), Vector2(x + 13, 657 - k % 2 * 7), Color(0.36, 0.89, 0.67, 0.17), 2, true)

func _draw_nutrient_icon(index: int, c: Vector2, zoom: float) -> void:
	if index == 0:
		_poly(c, [Vector2(0, -34), Vector2(-22, 2), Vector2(-18, 24), Vector2(0, 33), Vector2(18, 24), Vector2(22, 2)], zoom, Color("69d7ff"))
		draw_circle(c + Vector2(-7,-2) * zoom, 6 * zoom, Color(0.92,0.99,1,0.45))
	elif index == 1:
		for j in range(4):
			var a := TAU * float(j) / 4.0
			var off := Vector2(cos(a), sin(a)) * 16.0 * zoom
			draw_circle(c + off, 15.0 * zoom, Color("8af2a6"))
		for j in range(3):
			var a := TAU * float(j) / 3.0 + 0.15
			var off := Vector2(cos(a), sin(a)) * 18.0 * zoom
			draw_circle(c + off, 5.5 * zoom, Color("346953"))
	else:
		_poly(c, [Vector2(0,-37),Vector2(24,-8),Vector2(18,21),Vector2(0,36),Vector2(-22,15),Vector2(-22,-11)], zoom, Color("f9d993"))
		_poly(c, [Vector2(0,-37),Vector2(24,-8),Vector2(0,7),Vector2(-22,-11)], zoom, Color("ffebbf"))
		_poly(c, [Vector2(0,7),Vector2(24,-8),Vector2(18,21),Vector2(0,36)], zoom, Color("c99058"))

func _poly(c: Vector2, points: Array, zoom: float, color: Color) -> void:
	var p := PackedVector2Array()
	for vertex in points:
		p.append(c + vertex * zoom)
	draw_colored_polygon(p, color)

func _draw_end_panel() -> void:
	draw_rect(Rect2(0, 140, 1280, 392), Color(0.01, 0.04, 0.08, 0.72))
	_box(Rect2(161, 204, 958, 312), Color("0d2c46"), Color("81e6c0") if _won else Color("d9afd6"), 34, 3)
	_box(Rect2(178, 218, 924, 281), Color("0b2138"), Color("376d81"), 28, 2)
	for i in range(33):
		var p := Vector2(193 + fmod(float(i * 79), 887), 238 + fmod(float(i * 37), 250))
		draw_circle(p, 2.0 + float(i % 3), Color(0.54, 0.97, 0.76, 0.21))
	for k in range(3):
		var p := Vector2(600 + float(k) * 39, 254)
		draw_texture_rect(STAR_ICON, Rect2(p, Vector2(29, 29)), false, Color("d8ffe9") if _won else Color("446e80"))
