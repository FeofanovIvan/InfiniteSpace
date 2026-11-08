extends Control
## MIKA • Barnard Galaxy • Evolution: Who Came First?
## A compact self-contained timeline game. The illustrations are drawn as vector shapes.

const DESIGN := Vector2(1280.0, 720.0)
const LANGUAGES := ["ru", "en", "pt", "es", "de", "fr"]
const SLOT_X := [107.0, 369.0, 631.0, 893.0]
const SLOT_W := 240.0
const TARGET_Y := 217.0
const TARGET_H := 169.0
const CARD_Y := 497.0
const CARD_H := 153.0
const HINT_RECT := Rect2(853.0, 25.0, 115.0, 46.0)
const RESTART_RECT := Rect2(979.0, 25.0, 120.0, 46.0)
const LANGUAGE_RECT := Rect2(1110.0, 25.0, 144.0, 46.0)
const NEXT_RECT := Rect2(1054.0, 424.0, 170.0, 49.0)
const AGAIN_RECT := Rect2(500.0, 531.0, 280.0, 56.0)
const C_WHITE := Color("edfaff")
const C_MUTED := Color("a0c3dc")
const C_BG := Color("081626")
const C_BLUE := Color("79d0fa")
const C_MINT := Color("83e6bd")

var _font: Font
var _star_texture: Texture2D
var _locales: Dictionary = {}
var _levels: Array = []
var _locale := "en"
var _language_service: Node = null
var _level_index := 0
var _score := 0
var _placed: Array = [false, false, false, false]
var _deck: Array = [0, 1, 2, 3]
var _selected_card := -1
var _dragging := false
var _drag_pointer := Vector2.ZERO
var _drag_started := Vector2.ZERO
var _hint_slot := -1
var _hint_card := -1
var _wrong_slot := -1
var _wrong_timer := 0.0
var _correct_slot := -1
var _correct_timer := 0.0
var _feedback := ""
var _feedback_timer := 0.0
var _completed := false
var _all_done := false
var _elapsed := 0.0
var _drawing_scale := 1.0
var _drawing_offset := Vector2.ZERO
var _stars: Array[Vector2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	_star_texture = load("res://planet_hub/games/evolution_timeline/star_core.png") as Texture2D
	_load_data()
	_build_stars()
	_detect_language()
	_update_scale()
	get_viewport().size_changed.connect(_update_scale)
	_start_story(0, true)

func _load_data() -> void:
	var levels_json = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/evolution_timeline/data/levels.json"))
	var strings_json = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/evolution_timeline/data/strings.json"))
	if typeof(levels_json) == TYPE_ARRAY:
		_levels = levels_json
	if typeof(strings_json) == TYPE_DICTIONARY:
		_locales = strings_json

func _build_stars() -> void:
	var generator := RandomNumberGenerator.new()
	generator.seed = 24681
	for i in range(95):
		_stars.append(Vector2(generator.randf_range(0.0, 1280.0), generator.randf_range(0.0, 720.0)))

func _detect_language() -> void:
	_language_service = get_node_or_null("/root/LanguageService")
	var chosen := "en"
	if _language_service != null:
		var learning_value = _language_service.get("learning_locale")
		chosen = String(learning_value)
		if not LANGUAGES.has(chosen):
			chosen = String(_language_service.get("interface_locale"))
		if _language_service.has_signal("language_changed"):
			_language_service.connect("language_changed", Callable(self, "_external_language_changed"))
	else:
		var cfg := ConfigFile.new()
		if cfg.load("user://mika_evolution.cfg") == OK:
			chosen = String(cfg.get_value("settings", "language", "en"))
	_apply_language(chosen)

func _external_language_changed(_ignored: String) -> void:
	if _language_service == null:
		return
	_apply_language(String(_language_service.get("learning_locale")))

func _apply_language(code: String) -> void:
	_locale = code if LANGUAGES.has(code) else "en"
	queue_redraw()

func _cycle_language() -> void:
	var index := LANGUAGES.find(_locale)
	var next_code := String(LANGUAGES[(index + 1) % LANGUAGES.size()])
	if _language_service != null and _language_service.has_method("set_learning_locale"):
		_language_service.call("set_learning_locale", next_code)
	else:
		var cfg := ConfigFile.new()
		cfg.set_value("settings", "language", next_code)
		cfg.save("user://mika_evolution.cfg")
	_apply_language(next_code)

func _t(key: String) -> String:
	var lang: Dictionary = _locales.get(_locale, _locales.get("en", {}))
	return String(lang.get(key, key))

func _nested(section: String, key: String) -> String:
	var lang: Dictionary = _locales.get(_locale, _locales.get("en", {}))
	var group: Dictionary = lang.get(section, {})
	return String(group.get(key, key))

func _current_level() -> Dictionary:
	if _levels.is_empty():
		return {}
	return _levels[_level_index]

func _stages() -> Array:
	return _current_level().get("stages", [])

func _start_story(index: int, new_game: bool = false) -> void:
	if _levels.is_empty():
		return
	if new_game:
		_score = 0
	_level_index = clampi(index, 0, _levels.size() - 1)
	_deck = [0, 1, 2, 3]
	_deck.shuffle()
	_placed = [false, false, false, false]
	_selected_card = -1
	_dragging = false
	_hint_slot = -1
	_hint_card = -1
	_wrong_slot = -1
	_correct_slot = -1
	_wrong_timer = 0.0
	_correct_timer = 0.0
	_feedback_timer = 0.0
	_feedback = ""
	_completed = false
	_all_done = false
	queue_redraw()

func _update_scale() -> void:
	var screen_size := get_viewport_rect().size
	_drawing_scale = min(screen_size.x / DESIGN.x, screen_size.y / DESIGN.y)
	_drawing_scale = maxf(_drawing_scale, 0.01)
	_drawing_offset = (screen_size - DESIGN * _drawing_scale) / 2.0
	queue_redraw()

func _to_local_point(screen_point: Vector2) -> Vector2:
	return (screen_point - _drawing_offset) / _drawing_scale

func _target_rect(i: int) -> Rect2:
	return Rect2(SLOT_X[i], TARGET_Y, SLOT_W, TARGET_H)

func _card_rect(i: int) -> Rect2:
	return Rect2(SLOT_X[i], CARD_Y, SLOT_W, CARD_H)

func _hit_target(where: Vector2) -> int:
	for i in range(4):
		if _target_rect(i).has_point(where):
			return i
	return -1

func _hit_card(where: Vector2) -> int:
	for i in range(4):
		if _card_rect(i).has_point(where) and not bool(_placed[int(_deck[i])]):
			return i
	return -1

func _try_place(slot_index: int) -> void:
	if _selected_card < 0 or _completed or _all_done or bool(_placed[slot_index]):
		return
	var stage_index := int(_deck[_selected_card])
	if stage_index == slot_index:
		_placed[slot_index] = true
		_score += 10
		_correct_slot = slot_index
		_correct_timer = 1.05
		_hint_card = -1
		_hint_slot = -1
		_selected_card = -1
		_feedback = _t("correct")
		_feedback_timer = 1.15
		if _level_complete():
			_completed = true
			_score += 20
			_feedback = _t("completed")
			_feedback_timer = 15.0
			if _level_index >= _levels.size() - 1:
				_all_done = true
	else:
		_wrong_slot = slot_index
		_wrong_timer = 0.8
		_feedback = _t("wrong")
		_feedback_timer = 1.6
	queue_redraw()

func _level_complete() -> bool:
	for value in _placed:
		if not bool(value):
			return false
	return true

func _show_hint() -> void:
	if _completed or _all_done:
		return
	for i in range(4):
		if not bool(_placed[i]):
			_hint_slot = i
			for card in range(4):
				if int(_deck[card]) == i:
					_hint_card = card
					break
			break
	_feedback = _t("hint_message")
	_feedback_timer = 2.8
	queue_redraw()

func _handle_press(where: Vector2) -> void:
	if _all_done:
		if AGAIN_RECT.has_point(where):
			_start_story(0, true)
		return
	if LANGUAGE_RECT.has_point(where):
		_cycle_language()
		return
	if RESTART_RECT.has_point(where):
		_start_story(0, true)
		return
	if HINT_RECT.has_point(where):
		_show_hint()
		return
	if _completed and NEXT_RECT.has_point(where):
		_start_story(_level_index + 1)
		return
	var slot := _hit_target(where)
	if slot >= 0 and _selected_card >= 0:
		_try_place(slot)
		return
	var card := _hit_card(where)
	if card >= 0 and not _completed:
		_selected_card = card
		_dragging = true
		_drag_pointer = where
		_drag_started = where
		_feedback = _t("select")
		_feedback_timer = 2.0
		queue_redraw()

func _handle_move(where: Vector2) -> void:
	if not _dragging:
		return
	_drag_pointer = where
	queue_redraw()

func _handle_release(where: Vector2) -> void:
	if not _dragging:
		return
	_dragging = false
	var slot := _hit_target(where)
	if slot >= 0:
		_try_place(slot)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		var where := _to_local_point(button.position)
		if button.pressed:
			_handle_press(where)
		else:
			_handle_release(where)
	elif event is InputEventMouseMotion:
		if _dragging:
			_handle_move(_to_local_point((event as InputEventMouseMotion).position))
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_handle_press(_to_local_point(touch.position))
		else:
			_handle_release(_to_local_point(touch.position))
	elif event is InputEventScreenDrag:
		_handle_move(_to_local_point((event as InputEventScreenDrag).position))

func _process(delta: float) -> void:
	_elapsed += delta
	_wrong_timer = maxf(0.0, _wrong_timer - delta)
	_correct_timer = maxf(0.0, _correct_timer - delta)
	_feedback_timer = maxf(0.0, _feedback_timer - delta)
	queue_redraw()

func _draw() -> void:
	if _font == null or _levels.is_empty():
		return
	draw_set_transform(_drawing_offset, 0.0, Vector2(_drawing_scale, _drawing_scale))
	_draw_background()
	_draw_header()
	_draw_timeline()
	_draw_deck()
	_draw_footer()
	if _dragging and _selected_card >= 0 and _drag_pointer.distance_to(_drag_started) > 6.0:
		_draw_floating_card()
	if _all_done:
		_draw_winner()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _panel(rect: Rect2, fill: Color, border: Color, radius: int = 20, border_width: int = 2) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	draw_style_box(box, rect)

func _print(text: String, pos: Vector2, size_px: int = 20, color: Color = C_WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(_font, pos, text, align, width, size_px, color)

func _fit(text: String, center: Vector2, max_width: float, max_size: int, color: Color = C_WHITE) -> void:
	var sz := max_size
	while sz > 12 and _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, sz).x > max_width:
		sz -= 1
	_print(text, center, sz, color, HORIZONTAL_ALIGNMENT_CENTER, max_width)

func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN), C_BG)
	for i in range(8):
		draw_circle(Vector2(218, 166), 258.0 - i * 23.0, Color(0.12, 0.35, 0.58, 0.012))
		draw_circle(Vector2(1134, 621), 280.0 - i * 23.0, Color(0.12, 0.45, 0.34, 0.013))
	if _star_texture != null:
		draw_texture_rect(_star_texture, Rect2(70, 388, 27, 27), false, Color(1.0, 1.0, 1.0, 0.42))
		draw_texture_rect(_star_texture, Rect2(1188, 411, 24, 24), false, Color(1.0, 1.0, 1.0, 0.37))
	for i in range(_stars.size()):
		var pulse := 0.65 + 0.35 * sin(_elapsed * 0.6 + float(i))
		draw_circle(_stars[i], 0.75 + float(i % 3) * 0.33, Color(0.72, 0.91, 1.0, 0.13 + 0.2 * pulse))
	# decorative museum scanner lines
	for i in range(7):
		draw_arc(Vector2(1225, 215), 85.0 + i * 28.0, 1.68, 3.25, 40, Color(0.22, 0.56, 0.67, 0.09), 1.0, true)

func _draw_button(rect: Rect2, text: String, accent: Color, active: bool = false) -> void:
	_panel(rect, Color("102640") if not active else Color("27516a"), accent, 15, 2)
	_fit(text, rect.get_center() + Vector2(0, 7), rect.size.x - 15.0, 17, C_WHITE)

func _draw_header() -> void:
	_panel(Rect2(24, 12, 1232, 97), Color("0d2037"), Color("2b4b68"), 25)
	_print(_t("title"), Vector2(48, 53), 26, C_WHITE)
	_print(_t("subtitle"), Vector2(49, 83), 16, C_MUTED)
	_draw_button(HINT_RECT, _t("hint"), Color("84dbb5"))
	_draw_button(RESTART_RECT, _t("restart"), Color("76bde4"))
	_draw_button(LANGUAGE_RECT, _t("language"), Color("d1b3ff"))
	var level: Dictionary = _current_level()
	_panel(Rect2(35, 119, 1210, 68), Color("0e243c"), Color("365572"), 18)
	var accent := Color(String(level.get("accent", "#83e6bd")))
	_print("%02d  /  %02d" % [_level_index + 1, _levels.size()], Vector2(58, 148), 17, accent)
	_fit(_nested("story_titles", String(level.get("id", ""))), Vector2(640, 151), 635, 23, C_WHITE)
	_print("%s: %d" % [_t("score"), _score], Vector2(1054, 149), 19, Color("ffdfa0"))
	_print(_t("instruction"), Vector2(639, 176), 15, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER, 890)

func _draw_timeline() -> void:
	var level: Dictionary = _current_level()
	var stages: Array = _stages()
	var accent := Color(String(level.get("accent", "#83e6bd")))
	# spine line and small endpoints
	draw_line(Vector2(100, 202), Vector2(1176, 202), Color("458da2"), 3.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(1179, 202), Vector2(1166, 196), Vector2(1166, 208)]), C_BLUE)
	_print(_t("oldest"), Vector2(108, 199), 12, C_MINT)
	_print(_t("newest"), Vector2(1170, 199), 12, C_MINT, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in range(4):
		var rect := _target_rect(i)
		var placed := bool(_placed[i])
		var hinting := _hint_slot == i and not placed
		var is_wrong := _wrong_slot == i and _wrong_timer > 0.0
		var is_success := _correct_slot == i and _correct_timer > 0.0
		var border := Color("416880")
		if hinting:
			border = Color("e5dc8e")
		elif is_wrong:
			border = Color("fa8b99")
		elif placed:
			border = accent
		if is_success:
			border = Color("e8ffaa")
		_panel(rect, Color("112b3d") if placed else Color("0c2035"), border, 20, 3)
		draw_circle(Vector2(rect.position.x + 25, rect.position.y + 23), 15.0, accent if placed else Color("264e66"))
		_print(str(i + 1), Vector2(rect.position.x + 25, rect.position.y + 29), 17, Color("081626") if placed else C_MUTED, HORIZONTAL_ALIGNMENT_CENTER, 24)
		if placed and i < stages.size():
			var stage: Dictionary = stages[i]
			_draw_art(String(stage.get("icon", "amniote")), Vector2(rect.get_center().x, rect.position.y + 80), 0.68, accent)
			_fit(_nested("names", String(stage.get("id", ""))), Vector2(rect.get_center().x, rect.position.y + 145), rect.size.x - 18.0, 17, C_WHITE)
			_draw_date(stage, Vector2(rect.get_center().x, rect.position.y + 164), 13, C_MUTED)
		else:
			var shade := Color("d7f6ff") if hinting else Color("5f91b3")
			_print("?", rect.get_center() + Vector2(0, 22), 70, shade, HORIZONTAL_ALIGNMENT_CENTER, 100)
			if hinting:
				draw_arc(rect.get_center(), 63, 0, TAU * 0.95, 42, Color(1.0, 0.97, 0.72, 0.25 + 0.20 * sin(_elapsed * 4.0)), 2.2, true)
	if _completed:
		_fit(_nested("facts", String(level.get("id", ""))), Vector2(600, 449), 895, 20, Color("bff7d3"))
		if not _all_done:
			_draw_button(NEXT_RECT, _t("next"), Color("9df8c8"), true)
	elif _feedback_timer > 0.0:
		_fit(_feedback, Vector2(640, 453), 1100, 19, Color("ffdeaa") if _wrong_timer > 0.0 else Color("a8ecd4"))
	else:
		_fit(_t("select"), Vector2(640, 453), 1060, 17, Color("8eacc7"))

func _draw_date(stage: Dictionary, center: Vector2, font_size: int, color: Color) -> void:
	var age := int(stage.get("age_mya", 0))
	var label := _t("today") if age <= 0 else "~%d Ma" % age
	_print(label, center, font_size, color, HORIZONTAL_ALIGNMENT_CENTER, 145)

func _draw_deck() -> void:
	_panel(Rect2(28, 472, 1224, 192), Color("10253d"), Color("375d77"), 23)
	var level: Dictionary = _current_level()
	var stages: Array = _stages()
	var accent := Color(String(level.get("accent", "#83e6bd")))
	for i in range(4):
		var stage_index := int(_deck[i])
		var placed := bool(_placed[stage_index])
		var rect := _card_rect(i)
		var selected := _selected_card == i and not placed
		var hinting := _hint_card == i and not placed
		var col := Color("325672")
		if selected:
			col = Color("ffdc9a")
		elif hinting:
			col = Color("d2f7a0")
		elif placed:
			col = Color("315b51")
		_panel(rect, Color("162f48") if not placed else Color("102b2f"), col, 20, 3 if selected or hinting else 2)
		if stage_index < stages.size():
			var stage: Dictionary = stages[stage_index]
			if placed:
				_draw_art(String(stage.get("icon", "amniote")), Vector2(rect.get_center().x, rect.position.y + 67), 0.65, Color("587f82"))
				_print("✓", Vector2(rect.get_center().x, rect.position.y + 99), 30, Color("b9efcb"), HORIZONTAL_ALIGNMENT_CENTER, 55)
			else:
				_draw_art(String(stage.get("icon", "amniote")), Vector2(rect.get_center().x, rect.position.y + 63), 0.68, accent)
				_fit(_nested("names", String(stage.get("id", ""))), Vector2(rect.get_center().x, rect.position.y + 128), rect.size.x - 18.0, 18, C_WHITE)
				_draw_date(stage, Vector2(rect.get_center().x, rect.position.y + 147), 13, C_MUTED)

func _draw_footer() -> void:
	_panel(Rect2(28, 672, 1224, 35), Color("0e2337"), Color("1d4058"), 14, 1)
	_fit(_t("fact_note"), Vector2(639, 694), 1174, 14, Color("83a8bd"))

func _draw_floating_card() -> void:
	var stages: Array = _stages()
	var stage_index := int(_deck[_selected_card])
	if stage_index >= stages.size():
		return
	var stage: Dictionary = stages[stage_index]
	var center := _drag_pointer + Vector2(0, -32)
	var rect := Rect2(center - Vector2(96, 71), Vector2(192, 140))
	_panel(rect, Color("25435b", 0.96), Color("f5e29e"), 16, 3)
	_draw_art(String(stage.get("icon", "amniote")), center + Vector2(0, -14), 0.58, Color("b4e9d2"))
	_fit(_nested("names", String(stage.get("id", ""))), center + Vector2(0, 59), 176, 15, C_WHITE)

func _draw_winner() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN), Color(0.02, 0.06, 0.12, 0.81))
	_panel(Rect2(300, 180, 680, 435), Color("123148"), Color("86dcb2"), 30, 4)
	for i in range(3):
		draw_arc(Vector2(640, 308), 80.0 + 10.0 * i, 0, TAU * 0.99, 64, Color("b9f8cb", 0.4 - 0.1 * i), 2.0, true)
	_draw_art("sauropod", Vector2(640, 305), 1.05, Color("b6e29f"))
	_fit(_t("all_complete"), Vector2(640, 429), 630, 32, C_WHITE)
	_fit(_t("all_message"), Vector2(640, 471), 630, 19, C_MUTED)
	_fit("%s: %d / 240" % [_t("score"), _score], Vector2(640, 503), 530, 22, Color("ffe09b"))
	_draw_button(AGAIN_RECT, _t("again"), Color("96f5bd"), true)

# --- Small vector silhouettes. These are stylized teaching icons, not realistic reconstructions. ---
func _ellipse(center: Vector2, rx: float, ry: float, color: Color, sides: int = 30) -> void:
	var points := PackedVector2Array()
	for i in range(sides):
		var angle := float(i) * TAU / float(sides)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)

func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _head(center: Vector2, rx: float, ry: float, color: Color, eye: bool = true) -> void:
	_ellipse(center, rx, ry, color)
	if eye:
		draw_circle(center + Vector2(rx * 0.35, -ry * 0.18), 2.6, Color("0a2130"))

func _draw_art(kind: String, pos: Vector2, scale_value: float, base: Color) -> void:
	# All coordinates below are relative to this icon's centre.
	draw_set_transform(_drawing_offset + pos * _drawing_scale, 0, Vector2(_drawing_scale * scale_value, _drawing_scale * scale_value))
	var dark := base.darkened(0.32)
	var light := base.lightened(0.32)
	match kind:
		"amniote":
			_poly([Vector2(-39, 8), Vector2(-100, 18), Vector2(-54, -4)], dark)
			_ellipse(Vector2(-6, 0), 50, 22, base)
			for x in [-39.0, 26.0]:
				draw_line(Vector2(x, 13), Vector2(x - 10, 36), dark, 11, true)
			_head(Vector2(45, -4), 24, 14, base)
		"archosaur":
			_poly([Vector2(-50, 5), Vector2(-100, 17), Vector2(-55, -9)], dark)
			_ellipse(Vector2(-14, 5), 60, 18, base)
			_head(Vector2(53, 0), 32, 12, base)
			draw_line(Vector2(44, 11), Vector2(78, 13), dark, 3, true)
			for x in [-43.0, 29.0]:
				draw_line(Vector2(x, 14), Vector2(x + 2, 33), dark, 10, true)
		"dinosaur", "featherdino":
			_poly([Vector2(-25, 5), Vector2(-98, 27), Vector2(-55, -16)], dark)
			_ellipse(Vector2(-8, 3), 44, 26, base)
			draw_line(Vector2(23, -9), Vector2(44, -42), base, 21, true)
			_head(Vector2(51, -42), 24, 14, base)
			for x in [-23.0, 9.0]:
				draw_line(Vector2(x, 22), Vector2(x + 3, 49), dark, 12, true)
			draw_line(Vector2(33, 6), Vector2(45, 22), dark, 6, true)
			if kind == "featherdino":
				for i in range(5):
					draw_line(Vector2(-50 + i * 11, -11), Vector2(-63 + i * 12, -30 - (i % 2) * 7), light, 7.5, true)
				for i in range(4):
					draw_line(Vector2(-84 + i * 8, 17), Vector2(-99 + i * 10, 2), light, 6.0, true)
		"sauropod":
			_poly([Vector2(-43, 14), Vector2(-99, -10), Vector2(-61, -5)], dark)
			_ellipse(Vector2(-24, 8), 55, 30, base)
			draw_line(Vector2(13, -5), Vector2(31, -51), base, 25, true)
			_head(Vector2(43, -59), 21, 13, base)
			for x in [-62.0, -13.0, 2.0]:
				draw_line(Vector2(x, 28), Vector2(x - 6, 51), dark, 13, true)
		"archaeopteryx", "bird":
			_ellipse(Vector2(2, 4), 25, 17, base)
			_poly([Vector2(-16, 6), Vector2(-91, 35), Vector2(-40, 13)], dark)
			_poly([Vector2(-4, 4), Vector2(-64, -44), Vector2(-28, 1)], light)
			_poly([Vector2(8, 3), Vector2(45, -54), Vector2(33, 12)], base)
			draw_line(Vector2(16, -4), Vector2(37, -25), dark, 10, true)
			_head(Vector2(41, -27), 16, 14, base)
			_poly([Vector2(55, -25), Vector2(75, -21), Vector2(55, -17)], Color("ffdc9b"))
			if kind == "archaeopteryx":
				for k in range(4):
					draw_line(Vector2(-32 - k * 11, 13), Vector2(-56 - k * 8, 38), light, 5, true)
			else:
				draw_line(Vector2(1, 18), Vector2(-12, 31), dark, 3, true)
		"pakicetus", "ambulocetus":
			_poly([Vector2(-47, 1), Vector2(-91, -15), Vector2(-53, -9)], dark)
			_ellipse(Vector2(-12, 3), 55, 23, base)
			_head(Vector2(46, -8), 28, 17, base)
			for x in [-48.0, -18.0, 18.0, 39.0]:
				draw_line(Vector2(x, 17), Vector2(x - 7, 47), dark, 9 if kind == "pakicetus" else 14, true)
			if kind == "ambulocetus":
				_poly([Vector2(60, 0), Vector2(91, 10), Vector2(60, 14)], dark)
		"basilosaurus", "whale":
			_ellipse(Vector2(0, 0), 71 if kind == "basilosaurus" else 62, 20 if kind == "basilosaurus" else 30, base)
			_poly([Vector2(-55, -1), Vector2(-93, -31), Vector2(-89, 0), Vector2(-93, 30)], dark)
			_poly([Vector2(-8, 10), Vector2(7, 50), Vector2(35, 10)], light)
			if kind == "whale":
				draw_circle(Vector2(54, -10), 3.0, Color("081827"))
				_ellipse(Vector2(10, -27), 20, 7, light)
			else:
				for x in [-12.0, 27.0]:
					draw_line(Vector2(x, 14), Vector2(x + 12, 34), dark, 6, true)
		"microbes":
			for i in range(6):
				var a := float(i) * TAU / 6.0
				var place := Vector2(cos(a) * 43, sin(a) * 27)
				draw_circle(place, 13.0 + float(i % 3) * 3.0, base if i % 2 == 0 else light)
				draw_circle(place + Vector2(2, -2), 4.0, dark)
		"cell":
			draw_circle(Vector2.ZERO, 54.0, base)
			draw_arc(Vector2.ZERO, 54.0, 0, TAU * 0.98, 42, light, 5.0, true)
			draw_circle(Vector2(-11, -4), 21.0, dark)
			draw_circle(Vector2(-8, -9), 9.0, light)
			for i in range(5):
				var a := float(i) * TAU / 5.0
				_ellipse(Vector2(22 * cos(a), 32 * sin(a)), 11, 6, light)
		"jellyfish":
			_ellipse(Vector2(0, -8), 53, 37, base)
			_poly([Vector2(-53, -8), Vector2(53, -8), Vector2(47, 0), Vector2(-47, 0)], dark)
			for i in range(7):
				var x := -39.0 + float(i) * 13.0
				draw_line(Vector2(x, -1), Vector2(x + sin(float(i) * 2.0) * 8.0, 46.0), light, 3.5, true)
		"fern":
			draw_line(Vector2(0, 52), Vector2(0, -61), dark, 8.0, true)
			for i in range(6):
				var y := 26.0 - float(i) * 17.0
				var length := 42.0 * (1.0 - float(i) * 0.09)
				_poly([Vector2(0, y + 4), Vector2(-length, y - 14), Vector2(-8, y - 10)], base)
				_poly([Vector2(0, y + 4), Vector2(length, y - 14), Vector2(8, y - 10)], light)
		_:
			draw_circle(Vector2.ZERO, 39, base)
	draw_set_transform(_drawing_offset, 0, Vector2(_drawing_scale, _drawing_scale))
