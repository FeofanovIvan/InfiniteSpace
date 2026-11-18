extends Control
## MIKA / Big Magellanic Cloud / Sentient Mycelium — Eco Sorting v2. Unified MIKA visual language.
## Self-contained, no imported artwork, six-language UI, touch and mouse controls.

const DESIGN := Vector2(1280.0, 720.0)
const CATEGORY_KEYS := ["recycle", "organic", "residual"]
const CATEGORY_COLORS := [Color("6ecfff"), Color("80e9a9"), Color("ffbe79")]
const BIN_RECTS := [Rect2(30, 487, 389, 175), Rect2(446, 487, 389, 175), Rect2(862, 487, 389, 175)]
const ART_CENTER := Vector2(640, 289)
const ART_PICK_AREA := Rect2(443, 194, 394, 215)
const LANGUAGE_CODES := ["ru", "en", "pt", "es", "de", "fr"]

var _translations: Dictionary = {}
var _items: Array = []
var _queue: Array = []
var _locale_code := "en"
var _scale_factor := 1.0
var _offset := Vector2.ZERO
var _current := 0
var _score := 0
var _streak := 0
var _bad_guesses := 0
var _hint_cat := -1
var _hover_bin := -1
var _dragging := false
var _drag_point := Vector2.ZERO
var _flying := false
var _fly_t := 0.0
var _fly_start := Vector2.ZERO
var _fly_end := Vector2.ZERO
var _finished := false
var _animation_tick := 0.0
var _category_counts := [0, 0, 0]
var _sparkles: Array[Dictionary] = []
var _success_bin := -1
var _success_flash := 0.0

var _title: Label
var _subtitle: Label
var _prompt: Label
var _instructions: Label
var _item_label: Label
var _score_label: Label
var _round_label: Label
var _streak_label: Label
var _feedback: Label
var _footer: Label
var _bin_titles: Array = []
var _bin_descriptions: Array = []
var _language_selector: OptionButton
var _restart_button: Button
var _hint_button: Button
var _replay_button: Button
var _overlay_title: Label
var _overlay_detail: Label
var _linked_language_service: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_load_json()
	_create_controls()
	_detect_locale()
	_layout_controls()
	get_viewport().size_changed.connect(_layout_controls)
	_new_game()

func _load_json() -> void:
	var strings_text := FileAccess.get_file_as_string("res://planet_hub/games/eco_sort/data/strings.json")
	var items_text := FileAccess.get_file_as_string("res://planet_hub/games/eco_sort/data/items.json")
	var strings_json = JSON.parse_string(strings_text)
	var items_json = JSON.parse_string(items_text)
	if typeof(strings_json) == TYPE_DICTIONARY:
		_translations = strings_json
	if typeof(items_json) == TYPE_ARRAY:
		_items = items_json

func _detect_locale() -> void:
	_linked_language_service = get_node_or_null("/root/LanguageService")
	var selected := "en"
	if _linked_language_service != null:
		selected = String(_linked_language_service.get("learning_locale"))
		if not LANGUAGE_CODES.has(selected):
			selected = String(_linked_language_service.get("interface_locale"))
		if _linked_language_service.has_signal("language_changed"):
			_linked_language_service.connect("language_changed", Callable(self, "_on_external_language_changed"))
	else:
		var config := ConfigFile.new()
		if config.load("user://mika_eco_sort.cfg") == OK:
			selected = String(config.get_value("settings", "language", "en"))
	_apply_locale(selected)

func _on_external_language_changed(_value: String) -> void:
	if _linked_language_service == null:
		return
	var lang := String(_linked_language_service.get("learning_locale"))
	_apply_locale(lang)

func _apply_locale(code: String) -> void:
	_locale_code = code if LANGUAGE_CODES.has(code) else "en"
	if _language_selector != null:
		var idx := LANGUAGE_CODES.find(_locale_code)
		if idx >= 0:
			_language_selector.select(idx)
	_refresh_text()

func _set_language(index: int) -> void:
	if index < 0 or index >= LANGUAGE_CODES.size():
		return
	var code := String(LANGUAGE_CODES[index])
	if _linked_language_service != null:
		if _linked_language_service.has_method("set_learning_locale"):
			_linked_language_service.call("set_learning_locale", code)
	else:
		var config := ConfigFile.new()
		config.set_value("settings", "language", code)
		config.save("user://mika_eco_sort.cfg")
	_apply_locale(code)

func _t(key: String) -> String:
	var pack: Dictionary = _translations.get(_locale_code, _translations.get("en", {}))
	return String(pack.get(key, key))

func _item_name(item: Dictionary) -> String:
	var names: Dictionary = item.get("names", {})
	return String(names.get(_locale_code, names.get("en", String(item.get("id", "")))))

func _create_controls() -> void:
	_title = _label(32, Color("f0faff"), HORIZONTAL_ALIGNMENT_LEFT)
	_subtitle = _label(16, Color("a6cced"), HORIZONTAL_ALIGNMENT_LEFT)
	_prompt = _label(27, Color("f3faff"), HORIZONTAL_ALIGNMENT_CENTER)
	_instructions = _label(16, Color("a4c5dd"), HORIZONTAL_ALIGNMENT_CENTER)
	_item_label = _label(24, Color("fff4d5"), HORIZONTAL_ALIGNMENT_CENTER)
	_score_label = _label(21, Color("eaf8ff"), HORIZONTAL_ALIGNMENT_LEFT)
	_round_label = _label(18, Color("c6e9ff"), HORIZONTAL_ALIGNMENT_LEFT)
	_streak_label = _label(18, Color("ffe2ac"), HORIZONTAL_ALIGNMENT_LEFT)
	_feedback = _label(20, Color("ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	_footer = _label(13, Color("86aac9"), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(3):
		_bin_titles.append(_label(23, Color("f2fcff"), HORIZONTAL_ALIGNMENT_CENTER))
		_bin_descriptions.append(_label(14, Color("cde6e6"), HORIZONTAL_ALIGNMENT_CENTER))
	_language_selector = OptionButton.new()
	_language_selector.focus_mode = Control.FOCUS_NONE
	_language_selector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for code in LANGUAGE_CODES:
		var name := String(_translations.get(code, {}).get("lang", code))
		_language_selector.add_item(name)
	_language_selector.item_selected.connect(_set_language)
	_style_button(_language_selector, Color("14345a"), Color("5caadd"))
	add_child(_language_selector)
	_restart_button = _button("", Callable(self, "_new_game"))
	_hint_button = _button("", Callable(self, "_show_hint"))
	_replay_button = _button("", Callable(self, "_new_game"))
	_overlay_title = _label(41, Color("f4ffe1"), HORIZONTAL_ALIGNMENT_CENTER)
	_overlay_detail = _label(25, Color("b3ffca"), HORIZONTAL_ALIGNMENT_CENTER)

func _label(font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = value
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(callback)
	_style_button(b, Color("14385d"), Color("68b7f2"))
	add_child(b)
	return b

func _style_button(button: BaseButton, background: Color, outline: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = background
	normal.border_color = outline
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(17)
	normal.content_margin_left = 13
	normal.content_margin_right = 13
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = background.lightened(0.16)
	hover.border_color = Color("d2edff")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = background.darkened(0.20)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("f0f8ff"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))

func _put(node: Control, rectangle: Rect2) -> void:
	node.scale = Vector2.ONE * _scale_factor
	node.position = _offset + rectangle.position * _scale_factor
	node.size = rectangle.size

func _layout_controls() -> void:
	var viewport_size: Vector2 = size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	_scale_factor = minf(viewport_size.x / DESIGN.x, viewport_size.y / DESIGN.y)
	_offset = (viewport_size - DESIGN * _scale_factor) * 0.5
	_put(_title, Rect2(43, 14, 740, 51))
	_put(_subtitle, Rect2(45, 63, 744, 25))
	_put(_score_label, Rect2(855, 16, 187, 31))
	_put(_round_label, Rect2(855, 45, 187, 27))
	_put(_streak_label, Rect2(855, 72, 187, 25))
	_put(_language_selector, Rect2(1068, 17, 175, 42))
	_put(_restart_button, Rect2(1068, 67, 175, 37))
	_put(_prompt, Rect2(347, 137, 586, 40))
	_put(_instructions, Rect2(339, 178, 602, 29))
	_put(_item_label, Rect2(356, 391, 568, 41))
	_put(_feedback, Rect2(253, 432, 774, 34))
	_put(_footer, Rect2(300, 678, 730, 28))
	_put(_hint_button, Rect2(33, 675, 174, 36))
	_put(_replay_button, Rect2(526, 423, 228, 56))
	_put(_overlay_title, Rect2(195, 258, 890, 75))
	_put(_overlay_detail, Rect2(258, 345, 764, 51))
	for i in range(3):
		var rect: Rect2 = BIN_RECTS[i]
		_put(_bin_titles[i], Rect2(rect.position.x + 111, rect.position.y + 37, rect.size.x - 133, 42))
		_put(_bin_descriptions[i], Rect2(rect.position.x + 115, rect.position.y + 94, rect.size.x - 128, 67))
	queue_redraw()

func _refresh_text() -> void:
	if _title == null:
		return
	_title.text = _t("title")
	_subtitle.text = _t("subtitle")
	_prompt.text = _t("prompt")
	_instructions.text = _t("instructions")
	_restart_button.text = _t("restart")
	_hint_button.text = _t("hint")
	_replay_button.text = _t("again")
	_overlay_title.text = _t("done")
	_overlay_detail.text = _t("done_detail")
	for i in range(3):
		_bin_titles[i].text = _t(CATEGORY_KEYS[i])
		_bin_descriptions[i].text = _t(["rec_desc", "org_desc", "res_desc"][i])
	_footer.text = "MIKA  ·  MYCELIUM LAB  ·  ECO SORT  ·  v2"
	_update_status()

func _update_status() -> void:
	if _score_label == null:
		return
	_score_label.text = "%s   %02d" % [_t("score"), _score]
	_round_label.text = "%s   %02d / %02d" % [_t("round"), mini(_current + 1, _queue.size()), _queue.size()]
	_streak_label.text = "%s   %02d" % [_t("streak"), _streak]
	if _current < _queue.size():
		_item_label.text = _item_name(_queue[_current])
	else:
		_item_label.text = ""
	_replay_button.visible = _finished
	_overlay_title.visible = _finished
	_overlay_detail.visible = _finished
	_hint_button.visible = not _finished
	_restart_button.disabled = _flying
	queue_redraw()

func _new_game() -> void:
	_queue = _items.duplicate(true)
	_queue.shuffle()
	_current = 0
	_score = 0
	_streak = 0
	_bad_guesses = 0
	_hint_cat = -1
	_hover_bin = -1
	_dragging = false
	_flying = false
	_finished = false
	_feedback.text = ""
	_category_counts = [0, 0, 0]
	_sparkles.clear()
	_success_bin = -1
	_success_flash = 0.0
	_update_status()

func _current_category_index() -> int:
	if _current < 0 or _current >= _queue.size():
		return -1
	return CATEGORY_KEYS.find(String(_queue[_current].get("category", "")))

func _show_hint() -> void:
	if _finished or _flying:
		return
	_hint_cat = _current_category_index()
	_feedback.text = _t("hint_text")
	_feedback.add_theme_color_override("font_color", Color("ffe795"))
	queue_redraw()

func _submit_answer(index: int, start_point: Vector2 = ART_CENTER) -> void:
	if _finished or _flying or index < 0 or index >= 3:
		return
	if index != _current_category_index():
		_bad_guesses += 1
		_streak = 0
		_feedback.text = _t("wrong")
		_feedback.add_theme_color_override("font_color", Color("ffc4b4"))
		if _bad_guesses >= 2:
			_hint_cat = _current_category_index()
		_update_status()
		return
	_feedback.text = _t("good")
	_feedback.add_theme_color_override("font_color", Color("b4ffd3"))
	_hint_cat = -1
	_hover_bin = index
	_flying = true
	_fly_t = 0.0
	_fly_start = start_point
	_fly_end = BIN_RECTS[index].get_center() + Vector2(0.0, 10.0)
	var tween := create_tween()
	tween.tween_property(self, "_fly_t", 1.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_finish_flight"))
	queue_redraw()

func _finish_flight() -> void:
	_score += 1
	_streak += 1
	if _hover_bin >= 0 and _hover_bin < 3:
		_category_counts[_hover_bin] += 1
		_success_bin = _hover_bin
		_success_flash = 1.0
		_spawn_sparkles(_fly_end, _hover_bin)
	_flying = false
	_current += 1
	_bad_guesses = 0
	_hover_bin = -1
	if _current >= _queue.size():
		_finished = true
		_feedback.text = ""
		_overlay_detail.text = "%s: %d %s %d" % [_t("complete"), _score, _t("of"), _queue.size()]
		_update_status()
	else:
		_update_status()
		get_tree().create_timer(0.52).timeout.connect(Callable(self, "_clear_positive_feedback"))

func _clear_positive_feedback() -> void:
	if not _flying and not _finished:
		_feedback.text = ""

func _hit_bin(point: Vector2) -> int:
	for i in range(3):
		if BIN_RECTS[i].has_point(point):
			return i
	return -1

func _to_design(point: Vector2) -> Vector2:
	return (point - _offset) / maxf(0.001, _scale_factor)

func _input(event: InputEvent) -> void:
	if _finished or _flying:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p := _to_design(event.position)
		if event.pressed:
			if ART_PICK_AREA.has_point(p):
				_dragging = true
				_drag_point = p
				get_viewport().set_input_as_handled()
			elif _hit_bin(p) >= 0:
				_submit_answer(_hit_bin(p))
				get_viewport().set_input_as_handled()
		else:
			if _dragging:
				_dragging = false
				var idx := _hit_bin(p)
				if idx >= 0:
					_submit_answer(idx, p)
				_hover_bin = -1
				queue_redraw()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		_drag_point = _to_design(event.position)
		_hover_bin = _hit_bin(_drag_point)
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var p2 := _to_design(event.position)
		if event.pressed:
			if ART_PICK_AREA.has_point(p2):
				_dragging = true
				_drag_point = p2
				get_viewport().set_input_as_handled()
			elif _hit_bin(p2) >= 0:
				_submit_answer(_hit_bin(p2))
				get_viewport().set_input_as_handled()
		else:
			if _dragging:
				_dragging = false
				var idx2 := _hit_bin(p2)
				if idx2 >= 0:
					_submit_answer(idx2, p2)
				_hover_bin = -1
				queue_redraw()
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _dragging:
		_drag_point = _to_design(event.position)
		_hover_bin = _hit_bin(_drag_point)
		queue_redraw()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_animation_tick += delta
	_success_flash = maxf(0.0, _success_flash - delta * 2.4)
	for j in range(_sparkles.size() - 1, -1, -1):
		var sp: Dictionary = _sparkles[j]
		sp["life"] = float(sp["life"]) - delta
		if float(sp["life"]) <= 0.0:
			_sparkles.remove_at(j)
		else:
			sp["pos"] = Vector2(sp["pos"]) + Vector2(sp["vel"]) * delta
			sp["vel"] = Vector2(sp["vel"]) * (1.0 - delta * 0.8)
			_sparkles[j] = sp
	if _dragging or _flying or not _sparkles.is_empty() or _success_flash > 0.0 or fmod(_animation_tick, 0.04) < delta:
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("040b19"), true)
	draw_set_transform(_offset, 0.0, Vector2(_scale_factor, _scale_factor))
	_draw_background()
	_draw_main_panel()
	_draw_hud()
	for i in range(3):
		_draw_bin(i)
	if _current < _queue.size() and not _finished:
		var key := String(_queue[_current].get("id", ""))
		if _dragging:
			# Keep the original stage visible while dragging only the object.
			_draw_drop_shadow(ART_CENTER, 1.0)
			_draw_art(key, _drag_point, 1.05, 0.97)
		elif _flying:
			var p := _fly_start.lerp(_fly_end, _fly_t)
			_draw_art(key, p, 1.0 - _fly_t * 0.52, 1.0 - _fly_t * 0.22)
		else:
			_draw_art(key, ART_CENTER + Vector2(0, sin(_animation_tick * 2.7) * 5), 1.0, 1.0)
	for sp in _sparkles:
		var color: Color = sp["color"]
		var alpha := clampf(float(sp["life"]) / 0.75, 0.0, 1.0)
		draw_circle(sp["pos"], 3.5 * alpha + 1.2, Color(color.r, color.g, color.b, alpha))
	if _finished:
		_draw_win_overlay()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_background() -> void:
	# Shared MIKA palette: deep space navy, cyan interface glow; biological greens only as accents.
	var top := Color("060f23")
	var bottom := Color("0b1930")
	for j in range(36):
		var y := float(j) * 20.0
		draw_rect(Rect2(0, y, 1280, 21), top.lerp(bottom, float(j) / 35.0), true)
	for field in range(4):
		var c: Vector2 = [Vector2(140, 255), Vector2(1158, 240), Vector2(110, 614), Vector2(1162, 600)][field]
		var tint := Color("225a9a") if field % 2 == 0 else Color("2b705e")
		for ring in range(4, 0, -1):
			draw_circle(c, 44.0 + ring * 29.0, Color(tint.r, tint.g, tint.b, 0.022))
	# Tiny slow twinkles (no bright stars directly behind the active item).
	for i in range(72):
		var x := 19.0 + fmod(float(i * 197 + 59), 1244.0)
		var y := 128.0 + fmod(float(i * 103 + 17), 535.0)
		var a := 0.20 + 0.09 * sin(_animation_tick * (0.5 + float(i % 4) * 0.14) + float(i))
		draw_circle(Vector2(x, y), 1.0 + float(i % 3) * 0.43, Color(0.70, 0.89, 1.0, a))
	# Mycelium threads at the edges, visually related to Big Magellanic Cloud.
	for side in range(2):
		var bx := 18.0 if side == 0 else 1262.0
		var direction := 1.0 if side == 0 else -1.0
		for i in range(7):
			var y := 158.0 + float(i) * 70.0
			var a := Vector2(bx, y)
			var b := a + Vector2(direction * (52.0 + float(i % 3) * 15.0), 19.0)
			var d := b + Vector2(direction * 21.0, 18.0)
			draw_line(a, b, Color(0.35, 0.83, 0.65, 0.16), 2.0, true)
			draw_line(b, d, Color(0.35, 0.83, 0.65, 0.12), 2.0, true)
			draw_circle(b, 2.7, Color(0.46, 0.99, 0.76, 0.24))

func _draw_hud() -> void:
	# Persistent navy top strip, matching the ship simulator and Color Sort.
	_round_box(Rect2(24, 10, 1232, 104), Color("0a1d36"), Color("315b83"), 23, 2)
	draw_line(Vector2(44, 101), Vector2(818, 101), Color("6ab8ec", 0.24), 2.0, true)
	_round_box(Rect2(834, 17, 211, 89), Color("102e4f"), Color("4382ba"), 16, 2)
	# Main progress bar: shows percentage of objects already sorted.
	_round_box(Rect2(246, 474, 788, 10), Color("0a2039"), Color("234867"), 6, 1)
	var count := maxi(1, _queue.size())
	var progress := clampf(float(_current) / float(count), 0.0, 1.0)
	if progress > 0.0:
		_round_box(Rect2(248, 476, 784.0 * progress, 6), Color("62ddb9"), Color("62ddb9"), 4, 0)
	# Mark each fifth completed step with a small softly glowing dot.
	for i in range(1, 15):
		var x := 246.0 + 788.0 * float(i) / 15.0
		var done := i <= _current
		draw_circle(Vector2(x, 479), 2.8, Color("e7fff1") if done else Color("3e5d79"))

func _spawn_sparkles(origin: Vector2, category: int) -> void:
	var random := RandomNumberGenerator.new()
	random.randomize()
	for i in range(16):
		var angle := TAU * float(i) / 16.0 + random.randf_range(-0.12, 0.12)
		var speed := random.randf_range(65.0, 156.0)
		_sparkles.append({
			"pos": origin,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": random.randf_range(0.47, 0.78),
			"color": CATEGORY_COLORS[category]
		})

func _draw_main_panel() -> void:
	# Single prominent central interactive card; no clutter on the subject silhouette.
	_round_box(Rect2(198, 117, 884, 354), Color("0e2543"), Color("4f9acb"), 28, 2)
	_round_box(Rect2(214, 129, 852, 318), Color("0a1d35"), Color("234b70"), 23, 1)
	# Background accent at both ends of the sample card.
	for k in range(4):
		var y := 210.0 + float(k) * 39.0
		draw_line(Vector2(245, y), Vector2(294, y), Color("4388bb", 0.18), 2.0, true)
		draw_line(Vector2(986, y), Vector2(1035, y), Color("4388bb", 0.18), 2.0, true)
	# Object stage: generous empty center and circular holographic light.
	for radius in [124.0, 109.0, 93.0]:
		draw_arc(Vector2(640, 303), radius, 0, TAU, 64, Color(0.37, 0.77, 1.0, 0.055), 2.0, true)
	var pulsing := 0.5 + 0.5 * sin(_animation_tick * 1.45)
	_round_box(Rect2(507, 371, 266, 18), Color("081f3c"), Color("5dadd1"), 9, 2)
	_draw_oval(Vector2(640, 373), 112.0, 20.0, Color(0.35, 0.85, 0.83, 0.10 + pulsing * 0.04))
	draw_line(Vector2(563, 366), Vector2(717, 366), Color(0.55, 0.98, 0.90, 0.12), 3.0, true)
	# Quiet biological flourishes near the frame, not behind the item.
	for i in range(4):
		var x := 266.0 if i < 2 else 1015.0
		var y := 251.0 + float(i % 2) * 97.0
		_draw_small_leaf(Vector2(x, y), 0.92 if i < 2 else -0.92)

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(32):
		var a := TAU * float(i) / 32.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)

func _draw_small_leaf(pos: Vector2, direction: float) -> void:
	var tip := pos + Vector2(22.0 * direction, -28.0)
	_draw_poly(pos, [Vector2(0, 0), Vector2(12 * direction, -25), Vector2(22 * direction, -28), Vector2(22 * direction, -9)], 1.0, Color(0.35, 0.80, 0.61, 0.48))
	draw_line(pos, tip, Color(0.53, 0.98, 0.72, 0.38), 2.0, true)

func _draw_bin(i: int) -> void:
	var r: Rect2 = BIN_RECTS[i]
	var accent: Color = CATEGORY_COLORS[i]
	var active: bool = _hover_bin == i or _hint_cat == i or (_success_bin == i and _success_flash > 0.0)
	var pulsing := 0.5 + 0.5 * sin(_animation_tick * 5.5)
	# Rounded soft shadow is the same tactile card language as Color Sort.
	_round_box(Rect2(r.position + Vector2(0, 7), r.size).grow(3), Color(0.01, 0.03, 0.08, 0.35), Color(0, 0, 0, 0), 29, 0)
	_round_box(r.grow(3), Color(accent.r, accent.g, accent.b, 0.035 if not active else 0.10 + pulsing * 0.07), Color(accent.r, accent.g, accent.b, 0.15 if not active else 0.45), 29, 2)
	var fill := Color("102842").lerp(accent.darkened(0.77), 0.12 if not active else 0.34)
	_round_box(r, fill, accent.darkened(0.28) if not active else accent, 26, 3 if active else 2)
	# Raised colored rim on the basket card.
	_round_box(Rect2(r.position.x + 14, r.position.y + 13, r.size.x - 28, 17), Color("07182e"), Color(accent.r, accent.g, accent.b, 0.6), 9, 2)
	for k in range(6):
		var x := r.position.x + 37.0 + float(k) * 58.0
		draw_line(Vector2(x, r.position.y + 21), Vector2(x + 23, r.position.y + 21), Color(accent.r, accent.g, accent.b, 0.18), 2.0, true)
	# Icon lives on its own circular glowing button, never on top of text.
	var c := r.position + Vector2(59, 97)
	for radius in [55.0, 51.0]:
		draw_circle(c, radius, Color(accent.r, accent.g, accent.b, 0.035))
	draw_circle(c, 44.0, Color("071b30"))
	draw_arc(c, 45.0, 0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.55), 2.0, true)
	match i:
		0: _draw_recycle(c, accent)
		1: _draw_compost(c, accent)
		2: _draw_residual(c, accent)
	# Five visible sockets: one small LED per correct item of this category.
	for j in range(5):
		var p := r.position + Vector2(145.0 + float(j) * 41.0, 137)
		var filled: bool = j < int(_category_counts[i])
		draw_circle(p, 9, Color("061527"))
		draw_circle(p, 6.0, accent if filled else Color("2d4e64"))
		if filled:
			draw_arc(p, 9.8, 0, TAU, 20, Color(accent.r, accent.g, accent.b, 0.35), 2.0, true)

func _draw_recycle(c: Vector2, color: Color) -> void:
	for i in range(3):
		var angle := float(i) * TAU / 3.0 - 1.8
		var a := c + Vector2(cos(angle), sin(angle)) * 31.0
		var b := c + Vector2(cos(angle + 1.1), sin(angle + 1.1)) * 31.0
		draw_line(a, b, color, 8.0, true)
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([b + dir * 3.0, b - dir * 12.0 + side * 9.0, b - dir * 12.0 - side * 9.0]), color)

func _draw_compost(c: Vector2, color: Color) -> void:
	_draw_poly(c, [Vector2(-6, 34), Vector2(-28, 10), Vector2(-17, -28), Vector2(25, -43), Vector2(31, -6), Vector2(12, 27)], 1.0, color)
	draw_line(c + Vector2(-12, 22), c + Vector2(20, -27), Color("183d3a"), 4.0, true)
	draw_line(c + Vector2(-5, 13), c + Vector2(-19, -7), Color("183d3a"), 3.0, true)

func _draw_residual(c: Vector2, color: Color) -> void:
	_round_box(Rect2(c.x - 28, c.y - 28, 56, 64), color, color, 9, 1)
	_round_box(Rect2(c.x - 38, c.y - 36, 76, 12), color, color, 5, 1)
	for d in [-15, 0, 15]:
		draw_line(c + Vector2(d, -13), c + Vector2(d, 19), Color("4e3a32"), 4.0, true)

func _draw_drop_shadow(c: Vector2, factor: float) -> void:
	draw_circle(c, 65 * factor, Color(0.50, 0.84, 0.76, 0.08))

func _draw_win_overlay() -> void:
	# Final state uses same panel geometry as other MIKA games.
	draw_rect(Rect2(0, 114, 1280, 552), Color(0.02, 0.04, 0.10, 0.58), true)
	_round_box(Rect2(170, 179, 940, 360), Color("112e4c"), Color("74ccef"), 32, 4)
	_round_box(Rect2(186, 196, 908, 326), Color("091d35"), Color("367ca7"), 26, 2)
	for j in range(32):
		var x := 205.0 + fmod(float(j * 79), 857.0)
		var y := 216.0 + fmod(float(j * 61), 285.0)
		var color: Color = CATEGORY_COLORS[j % 3]
		draw_circle(Vector2(x, y), 2.0 + float(j % 4), Color(color.r, color.g, color.b, 0.29))
	_draw_compost(Vector2(639, 226), Color("80e9a9"))

func _round_box(rect: Rect2, fill: Color, stroke: Color, radius: int, width: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = stroke
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	draw_style_box(sb, rect)

func _draw_poly(center: Vector2, points: Array, zoom: float, color: Color) -> void:
	var actual := PackedVector2Array()
	for p in points:
		actual.append(center + p * zoom)
	draw_colored_polygon(actual, color)

func _draw_art(id: String, center: Vector2, scale_amount: float, opacity: float) -> void:
	var s := scale_amount
	var op := opacity
	draw_circle(center, 88.0 * s, Color(0.45, 1.0, 0.81, 0.07 * op))
	match id:
		"plastic_bottle":
			_art_box(center, Rect2(-31,-76,62,145), Color("76d9ed",0.82 * op), 18,s)
			_art_box(center, Rect2(-21,-91,42,23), Color("2b78a0",op), 5,s)
			_art_box(center, Rect2(-33,-37,66,51), Color("e9f9ff",0.81 * op), 9,s)
			_art_line(center, Vector2(-18,-58), Vector2(-18,49),Color("ffffff",0.65 * op),4,s)
			_art_line(center, Vector2(-10,-6), Vector2(16,-6),Color("61b4d9",op),4,s)
		"glass_jar":
			_art_box(center, Rect2(-60,-55,120,128), Color("94e6ea",0.70 * op), 23,s)
			_art_box(center, Rect2(-68,-70,136,25), Color("62b3c8",op), 7,s)
			_art_box(center, Rect2(-43,-24,86,70), Color("cdeeee",0.50 * op), 10,s)
			_art_line(center,Vector2(-35,-28),Vector2(-35,42),Color("ffffff",0.53 * op),5,s)
		"aluminum_can":
			_art_box(center, Rect2(-52,-67,104,137), Color("e0e8ee",op), 20,s)
			_art_box(center, Rect2(-53,-69,106,20), Color("b0becb",op), 10,s)
			_art_box(center, Rect2(-48,46,96,23), Color("b4c8d9",op), 9,s)
			_art_box(center, Rect2(-51,-22,102,57), Color("59c7f2",op), 6,s)
			_art_line(center,Vector2(-21,-5),Vector2(25,15),Color("ffffff",0.85 * op),8,s)
		"cardboard_box":
			_draw_poly(center,[Vector2(-72,-27),Vector2(6,-61),Vector2(78,-31),Vector2(1,1)],s,Color("e2b875",op))
			_draw_poly(center,[Vector2(-72,-27),Vector2(1,1),Vector2(1,75),Vector2(-72,39)],s,Color("c99351",op))
			_draw_poly(center,[Vector2(1,1),Vector2(78,-31),Vector2(78,41),Vector2(1,75)],s,Color("d6a45f",op))
			_art_line(center,Vector2(1,1),Vector2(1,75),Color("a66d3b",op),3,s)
			_art_line(center,Vector2(-32,-43),Vector2(39,-16),Color("bd8952",op),4,s)
		"newspaper":
			_art_box(center,Rect2(-76,-66,152,130),Color("eaf3e8",op),8,s)
			_art_box(center,Rect2(-64,-53,128,26),Color("82bfca",op),3,s)
			_art_box(center,Rect2(-62,-13,56,53),Color("aadcb5",op),3,s)
			for j in range(4):
				_art_line(center,Vector2(11,-10+j*14),Vector2(61,-10+j*14),Color("81999c",op),3,s)
			for j in range(2):
				_art_line(center,Vector2(-58,51+j*9),Vector2(61,51+j*9),Color("9db0b2",op),3,s)
		"banana_peel":
			_draw_poly(center,[Vector2(0,-51),Vector2(-18,-15),Vector2(-60,10),Vector2(-49,66),Vector2(-20,39),Vector2(0,1),Vector2(19,45),Vector2(54,58),Vector2(40,0),Vector2(10,-23)],s,Color("ffe16b",op))
			_draw_poly(center,[Vector2(-6,-31),Vector2(-10,7),Vector2(-23,34),Vector2(0,17),Vector2(8,-29)],s,Color("ffc247",op))
			_art_box(center,Rect2(-7,-62,14,18),Color("5d9760",op),3,s)
		"apple_core":
			draw_circle(center+Vector2(-4,-40)*s,36*s,Color("ed6970",op))
			draw_circle(center+Vector2(-4,40)*s,32*s,Color("ed6970",op))
			_draw_poly(center,[Vector2(-22,-30),Vector2(21,-30),Vector2(17,30),Vector2(-21,30)],s,Color("ffe5bb",op))
			_art_line(center,Vector2(0,-76),Vector2(4,-90),Color("5d9a61",op),7,s)
			_draw_poly(center+Vector2(11,-75)*s,[Vector2(0,0),Vector2(38,-15),Vector2(27,12)],s,Color("7fe6a2",op))
			for y in [-9,10]:
				draw_circle(center+Vector2(0,y)*s,3.7*s,Color("916345",op))
		"dry_leaf":
			_draw_poly(center,[Vector2(-8,74),Vector2(-50,20),Vector2(-35,-33),Vector2(17,-86),Vector2(57,-29),Vector2(43,24),Vector2(-8,74)],s,Color("d9a55b",op))
			_art_line(center,Vector2(-15,83),Vector2(19,-68),Color("865c41",op),5,s)
			for y in [-25,3,31]:
				_art_line(center,Vector2(1,y),Vector2(29,y-19),Color("a87948",op),3,s)
		"vegetable_peels":
			_draw_poly(center,[Vector2(-62,-55),Vector2(-24,-49),Vector2(-12,55),Vector2(-44,75),Vector2(-31,-18)],s,Color("f4a157",op))
			_draw_poly(center,[Vector2(-12,-43),Vector2(20,-69),Vector2(55,50),Vector2(19,68),Vector2(11,-18)],s,Color("ffbd72",op))
			_draw_poly(center,[Vector2(36,-31),Vector2(66,-22),Vector2(40,69),Vector2(13,55)],s,Color("e88542",op))
			_art_line(center,Vector2(-50,-63),Vector2(-31,-76),Color("79bd82",op),4,s)
		"eggshell":
			_draw_poly(center,[Vector2(-64,13),Vector2(-70,-17),Vector2(-43,-56),Vector2(0,-69),Vector2(44,-48),Vector2(61,-8),Vector2(48,8),Vector2(25,-2),Vector2(4,12),Vector2(-16,-7),Vector2(-39,12)],s,Color("fff2dc",op))
			_draw_poly(center,[Vector2(-62,26),Vector2(-34,11),Vector2(-13,28),Vector2(11,8),Vector2(36,24),Vector2(60,9),Vector2(51,63),Vector2(-49,63)],s,Color("f9dfbf",op))
		"used_tissue":
			_draw_poly(center,[Vector2(-68,44),Vector2(-51,-38),Vector2(-12,-51),Vector2(16,-26),Vector2(48,-54),Vector2(73,37),Vector2(29,66),Vector2(-18,47)],s,Color("e9eaf0",op))
			_art_line(center,Vector2(-35,-20),Vector2(-10,30),Color("b5c5d1",op),4,s)
			_art_line(center,Vector2(25,-22),Vector2(28,46),Color("cad7e1",op),3,s)
		"sponge":
			_art_box(center,Rect2(-75,-43,150,100),Color("f2c762",op),23,s)
			for i in range(10):
				var px := -52.0 + float((i*53)%112)
				var py := -22.0 + float((i*29)%54)
				draw_circle(center + Vector2(px,py)*s, (4+i%4)*s,Color("b18b52",0.35*op))
			_art_box(center,Rect2(-75,35,150,27),Color("72c1b3",op),12,s)
		"broken_mug":
			_art_box(center,Rect2(-64,-51,103,114),Color("e2b3cc",op),12,s)
			draw_arc(center+Vector2(52,-5)*s,36*s,-PI*0.5,PI*0.52,25,Color("e2b3cc",op),14*s,true)
			_draw_poly(center,[Vector2(-64,-52),Vector2(-30,-72),Vector2(-2,-52),Vector2(22,-77),Vector2(39,-52)],s,Color("9c728c",op))
			_art_line(center,Vector2(-10,-44),Vector2(4,-17),Color("ab7f96",op),4,s)
			_art_line(center,Vector2(4,-17),Vector2(-14,10),Color("ab7f96",op),4,s)
		"used_bandage":
			_art_box(center,Rect2(-79,-24,158,48),Color("f0c49a",op),15,s)
			_art_box(center,Rect2(-25,-35,50,70),Color("ffe1bc",op),8,s)
			for d in [-58,-44,44,58]:
				draw_circle(center+Vector2(d,0)*s,4*s,Color("bf8c74",op))
		"sticker":
			_draw_poly(center,[Vector2(-55,-66),Vector2(43,-65),Vector2(65,37),Vector2(12,67),Vector2(-63,44)],s,Color("f59bc5",op))
			_draw_poly(center,[Vector2(42,34),Vector2(65,37),Vector2(12,67)],s,Color("ffe3f2",op))
			_draw_poly(center,[Vector2(-13,-43),Vector2(0,-13),Vector2(31,-12),Vector2(7,9),Vector2(18,40),Vector2(-13,23),Vector2(-41,40),Vector2(-33,7),Vector2(-55,-13),Vector2(-25,-15)],s,Color("fff5bb",op))
		_: draw_circle(center,42*s,Color("a6f78a",op))

func _art_box(center: Vector2, rect: Rect2, color: Color, radius: int, s: float) -> void:
	_round_box(Rect2(center+rect.position*s,rect.size*s),color,color,maxi(3,int(radius*s)),1)

func _art_line(center: Vector2, a: Vector2, b: Vector2, color: Color, thickness: float, s: float) -> void:
	draw_line(center+a*s,center+b*s,color,thickness*s,true)
