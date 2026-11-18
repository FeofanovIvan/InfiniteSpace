extends Control
## MIKA • Andromeda • Magnetic Collector • Godot 4.7.1
## All scenery, magnetic crane, items, joysticks and FX are drawn in CanvasItem.
## Two independent touch controls + mouse + keyboard. No external plugins.

const DESIGN = Vector2(1280.0, 720.0)
const LOCALES = ["ru", "en", "pt", "es", "de", "fr"]
const LEVEL_TOTAL = 3
const MAGNET_SPEED_X = 280.0
const MAGNET_SPEED_Y = 215.0
const FLOOR_Y = 509.0
const GRAB_RADIUS = 84.0
const LEFT_PAD = Vector2(172.0, 641.0)
const RIGHT_PAD = Vector2(1100.0, 641.0)
const PAD_RADIUS = 60.0
const BAY_RECT = Rect2(87.0, 365.0, 236.0, 180.0)

const METALS = ["gear", "bolt", "ball", "bar", "washer", "screw"]
const NON_METALS = ["rock", "wood", "glass"]
const STAR_CORE = preload("res://planet_hub/games/magnetic_collector/assets/star_core.png")

const INK = Color("081427")
const PANEL = Color("101f38")
const LINE = Color("35658a")
const BLUE = Color("69ceff")
const TEAL = Color("75f0dc")
const GREEN = Color("8df5b3")
const GOLD = Color("ffc77c")
const LIGHT = Color("e9f7ff")
const MUTED = Color("91b8d3")

var _strings: Dictionary = {}
var _ui_lang := "en"
var _study_lang := "en"
var _language_service: Node = null

var _scale_factor := 1.0
var _origin := Vector2.ZERO
var _clock := 0.0
var _level_index := 0
var _score := 0
var _collected := 0
var _level_goal := 4
var _objects: Array[Dictionary] = []
var _carrying := -1
var _level_complete := false
var _paused := false
var _magnet_pos := Vector2(690.0, 330.0)
var _left_axis := 0.0
var _right_axis := 0.0
var _left_pointer := -1
var _right_pointer := -1
var _mouse_down := false
var _hint_timer := 0.0
var _hint_index := -1
var _feedback_key := "ready"
var _feedback_timer := 0.0
var _flash := 0.0
var _particles: Array[Dictionary] = []

var _title: Label
var _subtitle: Label
var _score_label: Label
var _level_label: Label
var _feedback: Label
var _instruction_label: Label
var _bay_label: Label
var _bay_hint: Label
var _left_help: Label
var _right_help: Label
var _footer: Label
var _progress_label: Label
var _language_picker: OptionButton
var _restart_button: Button
var _grab_button: Button
var _hint_button: Button
var _pause_button: Button
var _overlay: Panel
var _overlay_heading: Label
var _overlay_message: Label
var _next_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	randomize()
	_load_strings()
	_make_ui()
	_sync_language()
	_layout_ui()
	get_viewport().size_changed.connect(_layout_ui)
	_new_game()


func _load_strings() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/magnetic_collector/data/strings.json"))
	if parsed is Dictionary:
		_strings = parsed


func _sync_language() -> void:
	_language_service = get_node_or_null("/root/LanguageService")
	if _language_service != null:
		var study := str(_language_service.get("learning_locale"))
		var interface := str(_language_service.get("interface_locale"))
		_ui_lang = interface if LOCALES.has(interface) else "en"
		_study_lang = study if LOCALES.has(study) else "en"
		if _language_service.has_signal("language_changed"):
			_language_service.connect("language_changed", Callable(self, "_on_main_language_changed"))
	else:
		var cfg := ConfigFile.new()
		if cfg.load("user://mika_magnetic_collector.cfg") == OK:
			_ui_lang = str(cfg.get_value("settings", "language", "en"))
		if not LOCALES.has(_ui_lang):
			_ui_lang = "en"
		_study_lang = _ui_lang
	_apply_translation()


func _on_main_language_changed(_locale: String) -> void:
	if _language_service == null:
		return
	var interface := str(_language_service.get("interface_locale"))
	var study := str(_language_service.get("learning_locale"))
	_ui_lang = interface if LOCALES.has(interface) else "en"
	_study_lang = study if LOCALES.has(study) else "en"
	_apply_translation()


func _on_language_selected(index: int) -> void:
	if index < 0 or index >= LOCALES.size():
		return
	var code: String = LOCALES[index]
	if _language_service != null and _language_service.has_method("set_learning_locale"):
		_language_service.call("set_learning_locale", code)
		_study_lang = code
	else:
		_ui_lang = code
		_study_lang = code
		var cfg := ConfigFile.new()
		cfg.set_value("settings", "language", code)
		cfg.save("user://mika_magnetic_collector.cfg")
	_apply_translation()


func _t(key: String, study: bool = false) -> String:
	var lang: String = _study_lang if study else _ui_lang
	var pack: Dictionary = _strings.get(lang, _strings.get("en", {}))
	return str(pack.get(key, key))


func _make_label(font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = align
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func _make_button(callback: Callable, tint: Color, font_size: int = 17) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	_style_button(button, Color("183554"), tint)
	button.pressed.connect(callback)
	add_child(button)
	return button


func _style_button(button: BaseButton, bg: Color, edge: Color) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = bg
	base.border_color = edge
	base.set_border_width_all(2)
	base.set_corner_radius_all(18)
	base.content_margin_left = 10
	base.content_margin_right = 10
	base.content_margin_top = 7
	base.content_margin_bottom = 7
	var over := base.duplicate() as StyleBoxFlat
	over.bg_color = bg.lightened(0.17)
	over.border_color = Color("e0f9ff")
	var down := base.duplicate() as StyleBoxFlat
	down.bg_color = bg.darkened(0.2)
	button.add_theme_stylebox_override("normal", base)
	button.add_theme_stylebox_override("hover", over)
	button.add_theme_stylebox_override("pressed", down)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)


func _make_ui() -> void:
	_title = _make_label(29, LIGHT)
	_subtitle = _make_label(15, MUTED)
	_score_label = _make_label(21, Color("fff1c7"))
	_level_label = _make_label(18, Color("a9e5fa"))
	_feedback = _make_label(21, Color("d5f7ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_instruction_label = _make_label(18, Color("a3c9df"), HORIZONTAL_ALIGNMENT_CENTER)
	_bay_label = _make_label(19, TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	_bay_hint = _make_label(14, Color("bbefdc"), HORIZONTAL_ALIGNMENT_CENTER)
	_left_help = _make_label(14, Color("d1eafa"), HORIZONTAL_ALIGNMENT_CENTER)
	_right_help = _make_label(14, Color("d1eafa"), HORIZONTAL_ALIGNMENT_CENTER)
	_footer = _make_label(13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_progress_label = _make_label(16, Color("f0f9ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_language_picker = OptionButton.new()
	_language_picker.focus_mode = Control.FOCUS_NONE
	_language_picker.add_theme_font_size_override("font_size", 16)
	_style_button(_language_picker, Color("142e4d"), LINE)
	for code in LOCALES:
		var pack: Dictionary = _strings.get(code, {})
		_language_picker.add_item(str(pack.get("lang", code)))
	_language_picker.item_selected.connect(_on_language_selected)
	add_child(_language_picker)
	_restart_button = _make_button(Callable(self, "_new_game"), BLUE, 15)
	_grab_button = _make_button(Callable(self, "_toggle_magnet"), TEAL, 19)
	_style_button(_grab_button, Color("125865"), TEAL)
	_hint_button = _make_button(Callable(self, "_show_hint"), GOLD, 16)
	_pause_button = _make_button(Callable(self, "_toggle_pause"), BLUE, 16)
	_overlay = Panel.new()
	var modal := StyleBoxFlat.new()
	modal.bg_color = Color("101f39")
	modal.border_color = Color("8ce6e0")
	modal.set_border_width_all(3)
	modal.set_corner_radius_all(26)
	modal.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	modal.shadow_size = 22
	modal.shadow_offset = Vector2(0, 9)
	_overlay.add_theme_stylebox_override("panel", modal)
	add_child(_overlay)
	_overlay_heading = _make_label(36, LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	_overlay_heading.reparent(_overlay)
	_overlay_message = _make_label(20, Color("b6eadb"), HORIZONTAL_ALIGNMENT_CENTER)
	_overlay_message.reparent(_overlay)
	_next_button = _make_button(Callable(self, "_advance_level"), GREEN, 21)
	_next_button.reparent(_overlay)
	_overlay.visible = false


func _place(control: Control, rect: Rect2) -> void:
	control.scale = Vector2.ONE * _scale_factor
	control.position = _origin + rect.position * _scale_factor
	control.size = rect.size


func _layout_ui() -> void:
	var real_size := size
	if real_size.x < 1.0 or real_size.y < 1.0:
		real_size = get_viewport_rect().size
	_scale_factor = minf(real_size.x / DESIGN.x, real_size.y / DESIGN.y)
	_origin = (real_size - DESIGN * _scale_factor) * 0.5
	_place(_title, Rect2(52, 24, 682, 43))
	_place(_subtitle, Rect2(54, 69, 693, 27))
	_place(_score_label, Rect2(807, 28, 216, 32))
	_place(_level_label, Rect2(807, 65, 222, 25))
	_place(_language_picker, Rect2(1040, 21, 196, 44))
	_place(_restart_button, Rect2(1040, 71, 196, 31))
	_place(_feedback, Rect2(337, 514, 865, 39))
	_place(_instruction_label, Rect2(338, 155, 847, 28))
	_place(_bay_label, Rect2(97, 365, 220, 35))
	_place(_bay_hint, Rect2(94, 402, 226, 25))
	_place(_progress_label, Rect2(94, 489, 230, 25))
	_place(_left_help, Rect2(42, 693, 265, 19))
	_place(_right_help, Rect2(967, 693, 266, 19))
	_place(_footer, Rect2(318, 690, 640, 22))
	_place(_grab_button, Rect2(526, 601, 228, 67))
	_place(_hint_button, Rect2(348, 613, 154, 46))
	_place(_pause_button, Rect2(780, 613, 154, 46))
	_place(_overlay, Rect2(357, 215, 566, 275))
	_overlay_heading.position = Vector2(23, 40)
	_overlay_heading.size = Vector2(520, 75)
	_overlay_message.position = Vector2(36, 115)
	_overlay_message.size = Vector2(494, 57)
	_next_button.position = Vector2(160, 187)
	_next_button.size = Vector2(246, 55)
	queue_redraw()


func _apply_translation() -> void:
	if _title == null:
		return
	_title.text = _t("title")
	_subtitle.text = _t("subtitle")
	_instruction_label.text = _t("level_%d" % (_level_index + 1), true)
	_bay_label.text = _t("bay")
	_bay_hint.text = _t("bay_hint")
	_left_help.text = _t("left")
	_right_help.text = _t("right")
	_footer.text = _t("key_help")
	_restart_button.text = _t("restart")
	_hint_button.text = _t("hint")
	_pause_button.text = _t("resume") if _paused else _t("pause")
	_grab_button.text = _t("release") if _carrying >= 0 else _t("grab")
	_language_picker.select(LOCALES.find(_study_lang))
	_refresh_ui()


func _refresh_ui() -> void:
	if _score_label == null:
		return
	_score_label.text = "%s: %d" % [_t("score"), _score]
	_level_label.text = "%s %d / %d" % [_t("level"), _level_index + 1, LEVEL_TOTAL]
	_instruction_label.text = _t("level_%d" % (_level_index + 1), true)
	_progress_label.text = "%s: %d / %d" % [_t("target"), _collected, _level_goal]
	_grab_button.text = _t("release") if _carrying >= 0 else _t("grab")
	_grab_button.disabled = _paused or _level_complete
	_hint_button.disabled = _paused or _level_complete
	_pause_button.text = _t("resume") if _paused else _t("pause")
	_feedback.text = _t(_feedback_key)
	_overlay.visible = _paused or _level_complete
	_next_button.visible = _level_complete and not _paused
	if _paused:
		_overlay_heading.text = _t("pause")
		_overlay_message.text = _t("pause_detail")
	elif _level_complete:
		var is_final := _level_index >= LEVEL_TOTAL - 1
		_overlay_heading.text = _t("game_complete") if is_final else _t("level_complete")
		_overlay_message.text = _t("game_complete_detail") if is_final else _t("level_complete_detail")
		_next_button.text = _t("play_again") if is_final else _t("next")
	queue_redraw()


func _new_game() -> void:
	_score = 0
	_level_index = 0
	_start_level()


func _start_level() -> void:
	_collected = 0
	_level_goal = 4 + _level_index
	_level_complete = false
	_paused = false
	_carrying = -1
	_magnet_pos = Vector2(730, 324)
	_left_axis = 0.0
	_right_axis = 0.0
	_left_pointer = -1
	_right_pointer = -1
	_hint_timer = 0.0
	_hint_index = -1
	_objects.clear()
	_particles.clear()
	var types := METALS.duplicate()
	types.shuffle()
	var materials: Array[String] = []
	for i in range(_level_goal):
		materials.append(types[i])
	var nonmetal_count := 0
	if _level_index == 1:
		nonmetal_count = 2
	elif _level_index == 2:
		nonmetal_count = 3
	var decoys := NON_METALS.duplicate()
	decoys.shuffle()
	for j in range(nonmetal_count):
		materials.append(decoys[j])
	materials.shuffle()
	var slots := [424.0, 514.0, 604.0, 694.0, 784.0, 874.0, 964.0, 1054.0, 1144.0]
	for j in range(materials.size()):
		var kind: String = materials[j]
		var px := float(slots[j]) + randf_range(-9.0, 9.0)
		_objects.append({"kind": kind, "magnetic": METALS.has(kind), "pos": Vector2(px, FLOOR_Y - randf_range(0.0, 8.0)), "delivered": false})
	_set_feedback("ready", 0.0)
	_refresh_ui()


func _advance_level() -> void:
	if not _level_complete:
		return
	if _level_index >= LEVEL_TOTAL - 1:
		_new_game()
	else:
		_level_index += 1
		_start_level()


func _toggle_pause() -> void:
	if _level_complete:
		return
	_paused = not _paused
	if _paused:
		_left_axis = 0.0
		_right_axis = 0.0
	_refresh_ui()


func _show_hint() -> void:
	if _paused or _level_complete:
		return
	_hint_timer = 4.5
	_hint_index = -1
	if _carrying >= 0:
		_set_feedback("hint_bay", 4.0)
	else:
		var best_distance := INF
		for i in range(_objects.size()):
			var thing: Dictionary = _objects[i]
			if not bool(thing["magnetic"]) or bool(thing["delivered"]):
				continue
			var dist := (thing["pos"] as Vector2).distance_squared_to(_magnet_pos)
			if dist < best_distance:
				best_distance = dist
				_hint_index = i
		_set_feedback("hint_find", 4.0)


func _set_feedback(key: String, seconds: float) -> void:
	_feedback_key = key
	_feedback_timer = seconds
	if _feedback != null:
		_feedback.text = _t(key)


func _toggle_magnet() -> void:
	if _paused or _level_complete:
		return
	if _carrying >= 0:
		_release_item()
	else:
		_grab_item()
	_refresh_ui()


func _grab_item() -> void:
	var tip := _magnet_pos + Vector2(0, 47)
	var selected := -1
	var best_dist := GRAB_RADIUS
	for i in range(_objects.size()):
		var item: Dictionary = _objects[i]
		if bool(item["delivered"]):
			continue
		var dist := tip.distance_to(item["pos"] as Vector2)
		if dist < best_dist:
			best_dist = dist
			selected = i
	if selected < 0:
		_set_feedback("not_close", 3.0)
		_spawn_sparks(tip, BLUE, 7)
		return
	var target: Dictionary = _objects[selected]
	if not bool(target["magnetic"]):
		_set_feedback("not_magnetic", 3.5)
		_spawn_sparks(target["pos"], GOLD, 9)
		return
	_carrying = selected
	_hint_timer = 0.0
	_flash = 0.65
	_set_feedback("pickup", 4.0)
	_spawn_sparks(tip + Vector2(0, 40), TEAL, 15)


func _release_item() -> void:
	if _carrying < 0:
		return
	var current: Dictionary = _objects[_carrying]
	if _magnet_pos.x <= 335.0:
		current["delivered"] = true
		_objects[_carrying] = current
		_carrying = -1
		_collected += 1
		_score += 10
		_flash = 0.8
		_spawn_sparks(Vector2(220.0, 474.0), GREEN, 25)
		_set_feedback("delivered", 3.0)
		if _collected == _level_goal:
			_score += 20
			_level_complete = true
			_spawn_sparks(Vector2(639, 301), GREEN, 36)
	else:
		current["pos"] = Vector2(clampf(_magnet_pos.x, 401.0, 1164.0), FLOOR_Y)
		_objects[_carrying] = current
		_carrying = -1
		_set_feedback("not_at_bay", 4.0)
		_spawn_sparks(current["pos"], GOLD, 9)


func _spawn_sparks(center: Vector2, tone: Color, count: int) -> void:
	for i in range(count):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(35.0, 140.0)
		_particles.append({"pos": center, "vel": Vector2(cos(ang), sin(ang)) * spd, "life": randf_range(0.35, 0.95), "color": tone})


func _process(delta: float) -> void:
	_clock += delta
	_flash = maxf(0.0, _flash - delta)
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0 and not _paused and not _level_complete:
			_set_feedback("ready", 0.0)
	_hint_timer = maxf(0.0, _hint_timer - delta)
	for i in range(_particles.size() - 1, -1, -1):
		var fx: Dictionary = _particles[i]
		fx["life"] = float(fx["life"]) - delta
		fx["pos"] = (fx["pos"] as Vector2) + (fx["vel"] as Vector2) * delta
		fx["vel"] = (fx["vel"] as Vector2) * 0.974
		if float(fx["life"]) <= 0.0:
			_particles.remove_at(i)
		else:
			_particles[i] = fx
	if not _paused and not _level_complete:
		var hx := _left_axis
		var vy := _right_axis
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			hx -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			hx += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			vy -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			vy += 1.0
		_magnet_pos.x = clampf(_magnet_pos.x + clampf(hx, -1.0, 1.0) * MAGNET_SPEED_X * delta, 218.0, 1170.0)
		_magnet_pos.y = clampf(_magnet_pos.y + clampf(vy, -1.0, 1.0) * MAGNET_SPEED_Y * delta, 255.0, 438.0)
	queue_redraw()


func _screen_to_design(pos: Vector2) -> Vector2:
	return (pos - _origin) / maxf(_scale_factor, 0.01)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_toggle_magnet()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H:
			_show_hint()
		elif event.keycode == KEY_P:
			_toggle_pause()
		elif event.keycode == KEY_R:
			_new_game()
	if event is InputEventScreenTouch:
		var touch_pos := _screen_to_design(event.position)
		if event.pressed:
			_pointer_down(event.index, touch_pos)
		else:
			_pointer_up(event.index)
	elif event is InputEventScreenDrag:
		_pointer_move(event.index, _screen_to_design(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_down = event.pressed
		if event.pressed:
			_pointer_down(1000, _screen_to_design(event.position))
		else:
			_pointer_up(1000)
	elif event is InputEventMouseMotion and _mouse_down:
		_pointer_move(1000, _screen_to_design(event.position))


func _pointer_down(pointer: int, point: Vector2) -> void:
	if _paused or _level_complete:
		return
	if point.distance_to(LEFT_PAD) <= PAD_RADIUS + 28.0 and _left_pointer < 0:
		_left_pointer = pointer
		_left_axis = clampf((point.x - LEFT_PAD.x) / 43.0, -1.0, 1.0)
	elif point.distance_to(RIGHT_PAD) <= PAD_RADIUS + 28.0 and _right_pointer < 0:
		_right_pointer = pointer
		_right_axis = clampf((point.y - RIGHT_PAD.y) / 43.0, -1.0, 1.0)


func _pointer_move(pointer: int, point: Vector2) -> void:
	if pointer == _left_pointer:
		_left_axis = clampf((point.x - LEFT_PAD.x) / 43.0, -1.0, 1.0)
	if pointer == _right_pointer:
		_right_axis = clampf((point.y - RIGHT_PAD.y) / 43.0, -1.0, 1.0)


func _pointer_up(pointer: int) -> void:
	if pointer == _left_pointer:
		_left_pointer = -1
		_left_axis = 0.0
	if pointer == _right_pointer:
		_right_pointer = -1
		_right_axis = 0.0


func _panel(rect: Rect2, fill: Color, outline: Color, radius: int = 17, border: int = 1) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = outline
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	draw_style_box(sb, rect)


func _draw() -> void:
	draw_set_transform(_origin, 0.0, Vector2.ONE * _scale_factor)
	_draw_background()
	_draw_factory()
	_draw_bay()
	_draw_ground_items()
	_draw_magnet()
	_draw_joysticks()
	_draw_sparks()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN), INK)
	# Subtle nebula haze, keeping the center free of visual clutter.
	for i in range(10):
		draw_circle(Vector2(1138, 120), 220.0 - float(i) * 15.0, Color(0.13, 0.24, 0.53, 0.008))
	for i in range(9):
		draw_circle(Vector2(132, 429), 190.0 - float(i) * 14.0, Color(0.10, 0.55, 0.54, 0.009))
	for i in range(86):
		var p := Vector2(fmod(float(97 * i + 41), 1280.0), fmod(float(61 * i + 17), 710.0))
		draw_circle(p, 0.65 + float(i % 3) * 0.33, Color(0.60, 0.83, 1.0, 0.10 + 0.07 * float(i % 3)))
	draw_texture_rect(STAR_CORE, Rect2(1200, 142, 26, 26), false, Color(0.5, 0.83, 1.0, 0.4))
	_panel(Rect2(28, 16, 1224, 94), Color("0d2139"), LINE, 24, 2)
	_panel(Rect2(29, 127, 1222, 444), PANEL, Color("345b7b"), 24, 2)
	_panel(Rect2(29, 582, 1222, 129), Color("0d2139"), LINE, 26, 2)
	# Thin rails of geometric magnetic architecture.
	for i in range(12):
		var x := 49.0 + 104.0 * float(i)
		draw_line(Vector2(x, 568), Vector2(x + 23.0, 568), Color(0.31, 0.64, 0.81, 0.22), 2.0)
	# Divider above the gameplay board.
	draw_line(Vector2(45, 189), Vector2(1230, 189), Color("2e536e"), 1.5)


func _draw_factory() -> void:
	# Distant magnetic factory geometry (low contrast).
	for i in range(7):
		var p := Vector2(377 + i * 128, 367 + 17 * (i % 3))
		draw_arc(p, 90, 0.8, 2.35, 20, Color(0.13, 0.44, 0.63, 0.13), 2.0, true)
	# Rail shadows.
	draw_line(Vector2(345, 231), Vector2(1184, 231), Color(0.0, 0.0, 0.0, 0.45), 14.0)
	_panel(Rect2(340, 200, 848, 22), Color("365677"), Color("84adcf"), 7, 2)
	draw_line(Vector2(355, 207), Vector2(1174, 207), Color("a6cadf"), 2)
	for i in range(17):
		var x := 356.0 + 49.0 * float(i)
		draw_line(Vector2(x, 210), Vector2(x + 21, 210), Color("133b5f"), 5)
	# Supporting footlights across the floor.
	draw_rect(Rect2(333, 535, 861, 9), Color("233e56"))
	for i in range(15):
		var x := 350.0 + 57 * float(i)
		draw_line(Vector2(x, 540), Vector2(x + 28, 540), Color(0.28, 0.86, 0.88, 0.65), 3)
	# Target glow guide on left, x=~220.
	if _carrying >= 0:
		for i in range(3):
			draw_arc(Vector2(221, 465), 114 + 10 * i, -PI * .25, PI * 1.25, 45, Color(0.4, 0.96, 0.76, .24 - .06 * float(i)), 2)


func _draw_bay() -> void:
	var glow := 0.20 + 0.12 * (0.5 + 0.5 * sin(_clock * 2.7))
	_panel(BAY_RECT, Color("0a3943"), TEAL if _carrying >= 0 else Color("4aa9b4"), 22, 2)
	_panel(Rect2(108, 437, 194, 53), Color("071d2a"), Color("3c7d84"), 13, 2)
	draw_ellipse_patch(Vector2(205, 458), 83, 19, Color(0.35, 0.98, 0.76, glow))
	for i in range(5):
		var xx := 136.0 + float(i) * 35.0
		draw_line(Vector2(xx, 450), Vector2(xx + 12, 450), GREEN if i < _collected else Color("246f78"), 4.0)
	# Collector socket that doubles as easy visual guidance.
	draw_line(Vector2(146, 476), Vector2(264, 476), Color("76e9bd"), 4)
	draw_line(Vector2(158, 477), Vector2(180, 488), Color("4ba9a2"), 3)
	draw_line(Vector2(252, 477), Vector2(229, 488), Color("4ba9a2"), 3)
	if _flash > 0.0 and _collected > 0:
		draw_circle(Vector2(215, 458), 76 * _flash, Color(0.4, 1.0, 0.72, _flash * 0.11))


func draw_ellipse_patch(pos: Vector2, rx: float, ry: float, tone: Color) -> void:
	var points := PackedVector2Array()
	for i in range(37):
		var ang := TAU * float(i) / 36.0
		points.append(pos + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(points, tone)


func _draw_ground_items() -> void:
	for idx in range(_objects.size()):
		var item: Dictionary = _objects[idx]
		if bool(item["delivered"]) or idx == _carrying:
			continue
		var p: Vector2 = item["pos"]
		draw_ellipse_patch(p + Vector2(0, 27), 34, 8, Color(0.0, 0.0, 0.0, 0.36))
		if _hint_timer > 0.0 and idx == _hint_index:
			draw_arc(p, 46 + 2.0 * sin(_clock * 6.0), 0, TAU, 48, GOLD, 3, true)
		_draw_item(str(item["kind"]), p, 1.0)


func _draw_item(kind: String, pos: Vector2, factor: float) -> void:
	# All item types are illustrative, not imported sprites.
	# The game deliberately chooses ferromagnetic iron/steel vs rock/wood/glass.
	if factor != 1.0:
		draw_set_transform(_origin + pos * _scale_factor, 0.0, Vector2.ONE * (_scale_factor * factor))
		pos = Vector2.ZERO
	match kind:
		"gear":
			for j in range(10):
				var angle := TAU * float(j) / 10.0
				var edge := pos + Vector2(cos(angle), sin(angle)) * 28
				draw_rect(Rect2(edge - Vector2(5, 5), Vector2(10, 10)), Color("85b7ce"))
			draw_circle(pos, 28, Color("6f9fb9"))
			draw_circle(pos, 21, Color("aacfe1"))
			draw_circle(pos, 10, Color("18344e"))
			draw_arc(pos, 20, 0, TAU, 32, Color("d6f0fb"), 2)
		"bolt":
			_panel(Rect2(pos.x - 13, pos.y - 21, 24, 48), Color("699db9"), Color("b8d6e7"), 4, 2)
			var hp := PackedVector2Array([pos + Vector2(-25, -17), pos + Vector2(-13, -29), pos + Vector2(9, -29), pos + Vector2(22, -17), pos + Vector2(9, -5), pos + Vector2(-13, -5)])
			draw_colored_polygon(hp, Color("9ac9d8"))
			draw_line(pos + Vector2(-9, 6), pos + Vector2(9, 6), Color("c5e2ee"), 2.3)
			draw_line(pos + Vector2(-9, 15), pos + Vector2(9, 15), Color("c5e2ee"), 2.3)
		"ball":
			draw_circle(pos, 29, Color("7c9ebc"))
			draw_circle(pos - Vector2(9, 9), 12, Color("c5e7f6"))
			draw_arc(pos, 28, -0.2, 2.1, 32, Color("e9f9ff"), 2.2)
		"bar":
			_panel(Rect2(pos.x - 34, pos.y - 15, 68, 28), Color("719ab4"), Color("c9e0f0"), 7, 2)
			draw_line(pos + Vector2(-20, -7), pos + Vector2(21, -7), Color("a5cde1"), 4)
		"washer":
			draw_circle(pos, 30, Color("849cbb"))
			draw_circle(pos, 16, Color("12273c"))
			draw_arc(pos, 28, 0, TAU, 48, Color("c9e3f1"), 2)
		"screw":
			_panel(Rect2(pos.x - 11, pos.y - 21, 22, 48), Color("6b96ac"), Color("cbe9f2"), 4, 1)
			draw_circle(pos + Vector2(0, -20), 18, Color("b4d7e7"))
			draw_line(pos + Vector2(-10, -20), pos + Vector2(10, -20), Color("2a5a76"), 3)
			for j in range(4):
				draw_line(pos + Vector2(-10, j * 9 - 8), pos + Vector2(10, j * 9 - 2), Color("d6ebf4"), 2)
		"rock":
			var shape := PackedVector2Array([pos + Vector2(-30, 19), pos + Vector2(-23, -20), pos + Vector2(-3, -28), pos + Vector2(25, -12), pos + Vector2(31, 17), pos + Vector2(6, 27)])
			draw_colored_polygon(shape, Color("7e7a88"))
			draw_line(pos + Vector2(-23, -20), pos + Vector2(1, 0), Color("b1a6ac"), 2)
		"wood":
			_panel(Rect2(pos.x - 32, pos.y - 19, 64, 39), Color("b48757"), Color("e9bc7e"), 6, 2)
			for j in range(3):
				draw_line(pos + Vector2(-24, -10 + 11 * j), pos + Vector2(24, -10 + 11 * j), Color("805b47"), 2)
		"glass":
			var bottle := PackedVector2Array([pos + Vector2(-11, -30), pos + Vector2(11, -30), pos + Vector2(11, -17), pos + Vector2(22, -7), pos + Vector2(23, 27), pos + Vector2(-23, 27), pos + Vector2(-22, -7), pos + Vector2(-11, -17)])
			draw_colored_polygon(bottle, Color(0.33, 0.84, 0.86, 0.45))
			var outline := bottle.duplicate()
			outline.append(bottle[0])
			draw_polyline(outline, Color("a5f0f5"), 2)
			draw_line(pos + Vector2(-10, -18), pos + Vector2(-10, 16), Color("d5fffa"), 2)
	if factor != 1.0:
		draw_set_transform(_origin, 0.0, Vector2.ONE * _scale_factor)


func _draw_magnet() -> void:
	var x := _magnet_pos.x
	var y := _magnet_pos.y
	# Crane trolley and telescoping cable.
	_panel(Rect2(x - 42, 192, 84, 43), Color("36628c"), Color("b0d2e8"), 10, 2)
	for dx in [-26.0, 26.0]:
		draw_circle(Vector2(x + dx, 212), 9, Color("0c243e"))
		draw_circle(Vector2(x + dx, 212), 4, Color("85c8e9"))
	draw_line(Vector2(x - 7, 235), Vector2(x - 7, y - 33), Color("527a91"), 6)
	draw_line(Vector2(x + 7, 235), Vector2(x + 7, y - 33), Color("7fa6bd"), 3)
	# Cooling core, copper coil and magnetic poles.
	for n in range(4):
		draw_circle(_magnet_pos, 79 - float(n) * 13, Color(0.20, 0.78, 0.92, (0.03 - 0.005 * float(n)) if _carrying < 0 else 0.08))
	_panel(Rect2(x - 42, y - 39, 84, 50), Color("2c5778"), Color("a2d2ed"), 11, 3)
	for n in range(6):
		var xx := x - 31 + n * 12
		draw_line(Vector2(xx, y - 28), Vector2(xx, y - 3), Color("ffba6f"), 4.5)
	_panel(Rect2(x - 43, y - 3, 22, 47), Color("7da5c1"), Color("dbf2fa"), 6, 2)
	_panel(Rect2(x + 21, y - 3, 22, 47), Color("7da5c1"), Color("dbf2fa"), 6, 2)
	draw_line(Vector2(x - 27, y + 40), Vector2(x + 27, y + 40), TEAL, 4.0)
	if _carrying >= 0:
		var object_center := Vector2(x, y + 74)
		draw_line(Vector2(x, y + 42), object_center, Color(0.39, 0.93, 1.0, 0.7), 2)
		draw_arc(object_center, 43, 0, TAU, 40, Color(0.34, 0.99, 0.86, .44), 2)
		_draw_item(str(_objects[_carrying]["kind"]), object_center, 0.84)
	else:
		draw_arc(Vector2(x, y + 49), 42, 0, TAU, 30, Color(0.38, 0.83, 1.0, 0.18 + 0.13 * sin(_clock * 4.0)), 2)


func _draw_joysticks() -> void:
	for entry in [{"p": LEFT_PAD, "axis": _left_axis, "horizontal": true}, {"p": RIGHT_PAD, "axis": _right_axis, "horizontal": false}]:
		var p: Vector2 = entry["p"]
		var active := absf(float(entry["axis"])) > 0.03
		draw_circle(p, 60, Color("07192e"))
		draw_arc(p, 59, 0, TAU, 64, TEAL if active else Color("437da2"), 3.0)
		draw_circle(p, 39, Color("173e5f"))
		var move_offset := Vector2(float(entry["axis"]) * 31, 0) if bool(entry["horizontal"]) else Vector2(0, float(entry["axis"]) * 31)
		draw_circle(p + move_offset, 19, Color("8ee6f5"))
		draw_circle(p + move_offset - Vector2(5, 6), 7, Color("e5fdff"))
		if bool(entry["horizontal"]):
			draw_line(p + Vector2(-44, 0), p + Vector2(-28, 0), Color("9ad6ed"), 2)
			draw_line(p + Vector2(44, 0), p + Vector2(28, 0), Color("9ad6ed"), 2)
		else:
			draw_line(p + Vector2(0, -44), p + Vector2(0, -28), Color("9ad6ed"), 2)
			draw_line(p + Vector2(0, 44), p + Vector2(0, 28), Color("9ad6ed"), 2)


func _draw_sparks() -> void:
	for fx in _particles:
		var tone: Color = fx["color"]
		tone.a = clampf(float(fx["life"]), 0.0, 1.0)
		draw_circle(fx["pos"], 2.0 + float(fx["life"]) * 2.0, tone)
