extends Control
## MIKA • Electric Impulses • Andromeda • Godot 4.7.1
## Five memory levels, six languages, mouse/touch/keyboard, original audio cues.
## All scenery is drawn in CanvasItem. The only reused game asset is star_core.png.

const DESIGN := Vector2(1280.0, 720.0)
const LOCALES := ["ru", "en", "pt", "es", "de", "fr"]
const LEVEL_LENGTHS := [2, 3, 4, 5, 6]
const LEVEL_NODES := [
	[0, 2, 4, 6],
	[0, 1, 2, 4, 5, 6],
	[0, 1, 2, 4, 5, 6],
	[0, 1, 2, 3, 4, 5, 6, 7],
	[0, 1, 2, 3, 4, 5, 6, 7]
]
const NODE_POSITIONS := [
	Vector2(640, 210),
	Vector2(824, 242),
	Vector2(922, 364),
	Vector2(824, 492),
	Vector2(640, 526),
	Vector2(456, 492),
	Vector2(358, 364),
	Vector2(456, 242)
]
const NODE_COLORS := [
	Color("68d8ff"), Color("b8a1ff"), Color("ffce78"), Color("71f5c5"),
	Color("ff93bf"), Color("8fb3ff"), Color("bff078"), Color("ffa37a")
]
const INK := Color("071425")
const PANEL := Color("101e33")
const BORDER := Color("315678")
const TEXT := Color("ecf8ff")
const MUTED := Color("9dbad3")
const CYAN := Color("6edbff")
const AQUA := Color("8affe0")
const GOLD := Color("ffd67b")
const CORE_TEXTURE := preload("res://planet_hub/games/electric_impulses/assets/star_core.png")

const RESET_RECT := Rect2(1145, 24, 108, 62)
const SOUND_RECT := Rect2(1058, 24, 80, 62)
const REPLAY_RECT := Rect2(980, 133, 248, 53)
const NEXT_RECT := Rect2(476, 421, 328, 63)

var _strings: Dictionary = {}
var _ui_lang := "en"
var _language_service: Node = null
var _sound_on := true
var _audio_player: AudioStreamPlayer
var _sounds: Array = []
var _rng := RandomNumberGenerator.new()
var _stars: Array[Vector2] = []

var _level := 0
var _score := 0
var _best := 0
var _phase := "intro"  # intro, demo, input, wrong, level_done, finished
var _phase_timer := 0.0
var _demo_clock := 0.0
var _clock := 0.0
var _lit_node := -1
var _tap_node := -1
var _tap_timer := 0.0
var _input_step := 0
var _credited_steps := 0
var _sequence: Array[int] = []
var _available_nodes: Array[int] = []
var _view_scale := 1.0
var _view_offset := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	_generate_stars()
	_load_strings()
	_setup_audio()
	_read_settings_and_project_locale()
	get_viewport().size_changed.connect(_on_viewport_resized)
	_start_new_game()


func _load_strings() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/electric_impulses/data/strings.json"))
	if parsed is Dictionary:
		_strings = parsed


func _setup_audio() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.volume_db = -12.0
	add_child(_audio_player)
	for i in range(1, 9):
		_sounds.append(load("res://planet_hub/games/electric_impulses/audio/impulse_%02d.wav" % i))


func _read_settings_and_project_locale() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://mika_electric_impulses.cfg") == OK:
		_best = int(cfg.get_value("results", "best", 0))
		_sound_on = bool(cfg.get_value("options", "sound", true))
		_ui_lang = str(cfg.get_value("options", "language", "en"))
	if not LOCALES.has(_ui_lang):
		_ui_lang = "en"
	_language_service = get_node_or_null("/root/LanguageService")
	if _language_service == null:
		_language_service = get_node_or_null("/root/MobileLocale")
	if _language_service != null:
		_sync_main_language()
		if _language_service.has_signal("language_changed"):
			_language_service.connect("language_changed", Callable(self, "_on_language_changed"))


func _on_language_changed(_locale: String) -> void:
	_sync_main_language()
	queue_redraw()


func _sync_main_language() -> void:
	if _language_service == null:
		return
	var value: String = str(_language_service.get("language")) if _language_service.name == "MobileLocale" else str(_language_service.get("interface_locale"))
	value = "pt" if value == "pt_BR" else value
	if LOCALES.has(value):
		_ui_lang = value
	else:
		_ui_lang = "en"


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("results", "best", _best)
	cfg.set_value("options", "sound", _sound_on)
	cfg.set_value("options", "language", _ui_lang)
	cfg.save("user://mika_electric_impulses.cfg")


func _text(key: String) -> String:
	var dictionary: Dictionary = _strings.get(_ui_lang, _strings.get("en", {}))
	return str(dictionary.get(key, key))


func _generate_stars() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 802461
	for i in range(96):
		_stars.append(Vector2(random.randf_range(22, 1257), random.randf_range(117, 584)))


func _start_new_game() -> void:
	_score = 0
	_level = 0
	_start_level()


func _start_level() -> void:
	_phase = "intro"
	_phase_timer = 1.15
	_input_step = 0
	_credited_steps = 0
	_demo_clock = 0.0
	_lit_node = -1
	_tap_node = -1
	_sequence.clear()
	_available_nodes.clear()
	for node_id in LEVEL_NODES[_level]:
		_available_nodes.append(node_id)
	for i in range(LEVEL_LENGTHS[_level]):
		var candidate: int = _available_nodes[_rng.randi_range(0, _available_nodes.size() - 1)]
		while _sequence.size() > 0 and candidate == _sequence[_sequence.size() - 1]:
			candidate = _available_nodes[_rng.randi_range(0, _available_nodes.size() - 1)]
		_sequence.append(candidate)
	queue_redraw()


func _start_demo() -> void:
	_phase = "demo"
	_demo_clock = 0.0
	_lit_node = -1
	_input_step = 0
	_tap_node = -1
	queue_redraw()


func _play_node_tone(node_id: int) -> void:
	if not _sound_on or node_id < 0 or node_id >= _sounds.size():
		return
	var stream: AudioStream = _sounds[node_id]
	if stream != null:
		_audio_player.stop()
		_audio_player.stream = stream
		_audio_player.play()


func _process(delta: float) -> void:
	_clock += delta
	if _tap_timer > 0.0:
		_tap_timer = max(0.0, _tap_timer - delta)
		if _tap_timer <= 0.0:
			_tap_node = -1
	match _phase:
		"intro", "wrong":
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_start_demo()
		"demo":
			_demo_clock += delta
			var on_time: float = 0.78 - 0.04 * float(_level)
			var slot_time: float = on_time + 0.25
			var slot := int(_demo_clock / slot_time)
			if slot >= _sequence.size():
				_lit_node = -1
				_phase = "input"
			else:
				var within := fmod(_demo_clock, slot_time)
				var new_lit: int = int(_sequence[slot]) if within < on_time else -1
				if new_lit != _lit_node:
					_lit_node = new_lit
					if _lit_node >= 0:
						_play_node_tone(_lit_node)
	queue_redraw()


func _tap_node_now(node_id: int) -> void:
	if _phase != "input" or not _available_nodes.has(node_id):
		return
	_tap_node = node_id
	_tap_timer = 0.30
	_play_node_tone(node_id)
	if node_id == _sequence[_input_step]:
		_input_step += 1
		if _input_step > _credited_steps:
			_credited_steps = _input_step
			_score += 10
		if _input_step == _sequence.size():
			_score += 20
			if _score > _best:
				_best = _score
			_save_settings()
			if _level == LEVEL_LENGTHS.size() - 1:
				_phase = "finished"
			else:
				_phase = "level_done"
	else:
		_input_step = 0
		_phase = "wrong"
		_phase_timer = 1.15
	queue_redraw()


func _on_viewport_resized() -> void:
	queue_redraw()


func _view_point(pointer: Vector2) -> Vector2:
	var zoom: float = min(size.x / DESIGN.x, size.y / DESIGN.y)
	if zoom <= 0.0:
		return Vector2(-999, -999)
	var origin := (size - DESIGN * zoom) * 0.5
	return (pointer - origin) / zoom


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_click(_view_point(event.position))
			accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(_view_point(event.position))
			accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_start_new_game()
		elif event.keycode == KEY_M:
			_sound_on = not _sound_on
			_save_settings()
		elif event.keycode == KEY_SPACE:
			if _phase == "input":
				_start_demo()
			elif _phase == "level_done" or _phase == "finished":
				_go_next()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
			var slot: int = event.keycode - KEY_1
			if slot < _available_nodes.size():
				_tap_node_now(_available_nodes[slot])
		get_viewport().set_input_as_handled()


func _handle_click(p: Vector2) -> void:
	if RESET_RECT.has_point(p):
		_start_new_game()
		return
	if SOUND_RECT.has_point(p):
		_sound_on = not _sound_on
		_save_settings()
		return
	if _language_service == null:
		for i in range(LOCALES.size()):
			if Rect2(894 + i * 57, 647, 53, 33).has_point(p):
				_ui_lang = LOCALES[i]
				_save_settings()
				return
	if _phase == "level_done" or _phase == "finished":
		if NEXT_RECT.has_point(p):
			_go_next()
		return
	if _phase == "input" and REPLAY_RECT.has_point(p):
		_start_demo()
		return
	if _phase != "input":
		return
	for node_id in _available_nodes:
		if p.distance_to(NODE_POSITIONS[node_id]) <= 49.0:
			_tap_node_now(node_id)
			return


func _go_next() -> void:
	if _phase == "finished":
		_start_new_game()
	elif _phase == "level_done":
		_level += 1
		_start_level()


func _draw() -> void:
	_draw_outer_background()
	_view_scale = min(size.x / DESIGN.x, size.y / DESIGN.y)
	_view_offset = (size - DESIGN * _view_scale) * 0.5
	draw_set_transform(_view_offset, 0.0, Vector2(_view_scale, _view_scale))
	_draw_screen()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_outer_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK, true)


func _round_box(r: Rect2, fill: Color, border: Color = Color.TRANSPARENT, radius: int = 20, thickness: int = 1) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.border_color = border
	if border.a > 0.01:
		style.set_border_width_all(thickness)
	draw_style_box(style, r)


func _font_size(text_value: String, preferred: int, max_width: float) -> int:
	var font := ThemeDB.fallback_font
	var fs := preferred
	while fs > 11 and font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_width:
		fs -= 1
	return fs


func _label(text_value: String, pos: Vector2, font_size: int, color: Color, max_width: float = 9999.0) -> void:
	var fs := _font_size(text_value, font_size, max_width)
	draw_string(ThemeDB.fallback_font, pos, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _center_label(text_value: String, center_x: float, baseline: float, font_size: int, color: Color, max_width: float = 9999.0) -> void:
	var fs := _font_size(text_value, font_size, max_width)
	var len_x: float = ThemeDB.fallback_font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_label(text_value, Vector2(center_x - len_x * 0.5, baseline), fs, color)


func _draw_button(rect: Rect2, title: String, color: Color = CYAN, enabled: bool = true) -> void:
	var fill := Color("173552") if enabled else Color("18273b")
	_round_box(rect, fill, color if enabled else BORDER, 17, 2)
	_draw_corner_glow(rect, color)
	_center_label(title, rect.get_center().x, rect.position.y + rect.size.y * 0.61, 18, TEXT if enabled else MUTED, rect.size.x - 16)


func _draw_corner_glow(rect: Rect2, color: Color) -> void:
	draw_line(rect.position + Vector2(17, 2), rect.position + Vector2(rect.size.x - 17, 2), Color(color.r, color.g, color.b, 0.33), 1.2)


func _draw_screen() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN), INK, true)
	_draw_header()
	_draw_game_field()
	_draw_footer()
	if _phase == "level_done" or _phase == "finished":
		_draw_overlay()


func _draw_header() -> void:
	_round_box(Rect2(24, 15, 1232, 87), Color("0e213b"), Color("365c80"), 24, 2)
	_label(_text("title"), Vector2(45, 46), 28, TEXT, 680)
	_label(_text("subtitle"), Vector2(46, 77), 15, MUTED, 682)
	_draw_stat(Rect2(757, 25, 130, 59), _text("score"), str(_score), CYAN)
	_draw_stat(Rect2(895, 25, 154, 59), _text("level"), "%d / %d" % [_level + 1, LEVEL_LENGTHS.size()], AQUA)
	_draw_button(SOUND_RECT, _text("on") if _sound_on else _text("off"), GOLD)
	_draw_button(RESET_RECT, _text("restart"), CYAN)


func _draw_stat(rect: Rect2, caption: String, value: String, color: Color) -> void:
	_round_box(rect, Color("142e47"), Color("325c7f"), 16, 1)
	_center_label(caption, rect.get_center().x, rect.position.y + 20, 13, MUTED, rect.size.x - 13)
	_center_label(value, rect.get_center().x, rect.position.y + 47, 24, color, rect.size.x - 16)


func _draw_game_field() -> void:
	_round_box(Rect2(25, 116, 1230, 472), PANEL, BORDER, 29, 2)
	_draw_space()
	_draw_circuit()
	_draw_central_core()
	for node_id in _available_nodes:
		_draw_node(node_id)
	var prompt := _text("repeat") if _phase == "input" else _text("watch")
	if _phase == "intro":
		prompt = _text("ready")
	elif _phase == "wrong":
		prompt = _text("mistake")
	elif _phase == "level_done":
		prompt = _text("success")
	elif _phase == "finished":
		prompt = _text("completed")
	_label(prompt, Vector2(54, 166), 20, GOLD if _phase == "demo" else AQUA, 760)
	if _phase == "input":
		_draw_button(REPLAY_RECT, _text("replay"), CYAN)
	else:
		_round_box(REPLAY_RECT, Color("122941"), Color("2b506d"), 16, 1)
		_center_label(_text("demo") if _phase == "demo" else _text("steps") + ": " + str(_sequence.size()), REPLAY_RECT.get_center().x, 166, 16, MUTED, 226)
	_draw_sequence_meter()


func _draw_space() -> void:
	for g in range(12, 0, -1):
		var shade := Color(0.13, 0.27, 0.43, 0.005 + float(13-g)*0.0013)
		draw_circle(Vector2(395, 418), 55 + g * 8, shade)
	for g in range(11, 0, -1):
		draw_circle(Vector2(980, 324), 40 + g * 8, Color(0.24, 0.16, 0.45, 0.008))
	for i in range(_stars.size()):
		var star: Vector2 = _stars[i]
		var alpha := 0.17 + 0.16 * (1.0 + sin(_clock * 0.6 + float(i) * 1.2)) * 0.5
		draw_circle(star, 0.8 + float(i % 3) * 0.4, Color(0.77, 0.91, 1.0, alpha))


func _draw_circuit() -> void:
	var center := Vector2(640, 364)
	# Concentric rings reference the black metallic architecture of Andromeda.
	for ring_radius in [105.0, 115.0, 128.0]:
		draw_arc(center, ring_radius, 0.0, TAU, 90, Color(0.28, 0.66, 0.85, 0.10), 1.6)
	for i in range(16):
		var angle := float(i) * TAU / 16.0 + _clock * 0.08
		var radius := 124.0
		var p1 := center + Vector2(cos(angle), sin(angle)) * radius
		var p2 := center + Vector2(cos(angle), sin(angle)) * (radius + 10.0)
		draw_line(p1, p2, Color(0.52, 0.87, 1.0, 0.3), 2.0)
	for node_id in _available_nodes:
		var node_pos: Vector2 = NODE_POSITIONS[node_id]
		var lit := _lit_node == node_id or (_tap_node == node_id and _tap_timer > 0.0)
		var node_color: Color = NODE_COLORS[node_id]
		var dim := Color(0.18, 0.46, 0.60, 0.36)
		draw_line(center, node_pos, Color(node_color.r, node_color.g, node_color.b, 0.24) if lit else dim, 10.0)
		draw_line(center, node_pos, Color(node_color.r, node_color.g, node_color.b, 0.93) if lit else Color("426b89", 0.70), 2.4)
		if lit:
			var q := 0.3 + 0.55 * sin(_clock * 11.0)
			var pt := center.lerp(node_pos, q)
			draw_circle(pt, 11.0, Color(node_color.r, node_color.g, node_color.b, 0.16))
			draw_circle(pt, 4.5, node_color)
	# Industrial frame accents at left and right edge.
	for side in [0, 1]:
		var x := 90.0 if side == 0 else 1185.0
		var side_sign := 1.0 if side == 0 else -1.0
		for j in range(3):
			var y := 250.0 + float(j) * 104.0
			draw_line(Vector2(x, y), Vector2(x + side_sign * 34, y), Color(0.32, 0.57, 0.72, 0.26), 2.0)
			draw_circle(Vector2(x + side_sign * 34, y), 4.0, Color(0.38, 0.77, 0.93, 0.32))


func _draw_central_core() -> void:
	var center := Vector2(640, 364)
	var lit := _lit_node >= 0 or _tap_timer > 0.0
	var color: Color = NODE_COLORS[_lit_node] if _lit_node >= 0 else CYAN
	for radius in [100.0, 91.0, 82.0]:
		draw_circle(center, radius, Color(color.r, color.g, color.b, 0.018 if not lit else 0.065))
	draw_circle(center, 78.0, Color("081a2c"))
	draw_arc(center, 77.0, 0.0, TAU, 90, Color("5dacc9", 0.60), 2.0)
	draw_arc(center, 70.0, _clock * 0.36, _clock * 0.36 + PI * 1.2, 64, Color("8feaff", 0.63), 4.0)
	draw_circle(center, 49.0, Color("193851"))
	draw_texture_rect(CORE_TEXTURE, Rect2(617, 341, 46, 46), false, Color(0.70, 0.93, 1.0, 0.95))
	_center_label("MIKA", center.x, 413.0, 15, Color("9fddf6"), 94)


func _draw_node(node_id: int) -> void:
	var p: Vector2 = NODE_POSITIONS[node_id]
	var col: Color = NODE_COLORS[node_id]
	var lit := _lit_node == node_id or (_tap_node == node_id and _tap_timer > 0.0)
	var number := _available_nodes.find(node_id) + 1
	if lit:
		draw_circle(p, 54.0 + sin(_clock*13.0)*3.0, Color(col.r, col.g, col.b, 0.11))
		draw_circle(p, 47.0, Color(col.r, col.g, col.b, 0.19))
	draw_circle(p, 43.0, Color("142d43"))
	draw_circle(p, 35.0, Color(col.r, col.g, col.b, 0.93 if lit else 0.19))
	draw_arc(p, 43.0, 0.0, TAU, 64, Color(col.r, col.g, col.b, 0.96 if lit else 0.70), 3.0)
	draw_arc(p, 31.0, 0.6, 5.8, 42, Color(1.0, 1.0, 1.0, 0.40 if lit else 0.16), 2.0)
	for j in range(4):
		var angle := PI * 0.25 + float(j) * PI * 0.5
		var vec := Vector2(cos(angle), sin(angle))
		draw_line(p+vec*45.0, p+vec*50.0, col, 2.0)
	_center_label(str(number), p.x, p.y + 11, 29, INK if lit else TEXT, 54)


func _draw_sequence_meter() -> void:
	var count := _sequence.size()
	var x := 94.0
	for i in range(count):
		var filled := _phase == "input" and i < _input_step or (_phase == "level_done" or _phase == "finished")
		var active := _phase == "demo" and int(_demo_clock / (1.03 - 0.04 * _level)) == i
		var col := AQUA if filled else (GOLD if active else Color("355b78"))
		_round_box(Rect2(x, 557, 30, 8), col, Color.TRANSPARENT, 4)
		x += 39


func _draw_footer() -> void:
	_round_box(Rect2(25, 601, 1230, 103), Color("0d1d33"), BORDER, 27, 2)
	var status := _text("ready")
	if _phase == "demo":
		status = _text("demo")
	elif _phase == "input":
		status = _text("tap")
	elif _phase == "wrong":
		status = _text("mistake")
	elif _phase == "level_done":
		status = _text("success")
	elif _phase == "finished":
		status = _text("completed")
	_label(status, Vector2(51, 635), 19, AQUA if _phase != "wrong" else GOLD, 810)
	_label(_text("tip"), Vector2(52, 673), 14, MUTED, 790)
	_draw_level_dots()
	if _language_service == null:
		_label(_text("lang") + ":", Vector2(794, 633), 13, MUTED, 120)
		for i in range(LOCALES.size()):
			var locale: String = LOCALES[i]
			var is_current := locale == _ui_lang
			var b := Rect2(894 + i * 57, 647, 53, 33)
			_round_box(b, Color("1c4a65") if is_current else Color("142f49"), CYAN if is_current else BORDER, 10, 1)
			_center_label(locale.to_upper(), b.get_center().x, b.position.y + 22, 14, TEXT if is_current else MUTED, 45)
	else:
		_label(_text("control"), Vector2(930, 675), 13, MUTED, 285)


func _draw_level_dots() -> void:
	for i in range(LEVEL_LENGTHS.size()):
		var p := Vector2(696 + i*25, 666)
		var col := GOLD if i < _level else (AQUA if i == _level else Color("345b75"))
		draw_circle(p, 6.2, col)


func _draw_overlay() -> void:
	_round_box(Rect2(26, 117, 1228, 471), Color(0.035, 0.075, 0.15, 0.76), Color.TRANSPARENT, 26)
	_round_box(Rect2(410, 206, 460, 290), Color("112a46"), Color("6bd4e9"), 30, 3)
	for i in range(8):
		var angle := float(i) * TAU / 8.0 + _clock * 0.12
		var p := Vector2(640, 262) + Vector2(cos(angle), sin(angle)) * 45.0
		draw_circle(p, 3.8, AQUA if i % 2 == 0 else GOLD)
	draw_circle(Vector2(640, 262), 26, Color("246782"))
	draw_arc(Vector2(640, 262), 26.0, 0, TAU, 48, AQUA, 2.5)
	_center_label("✓", 640.0, 275.0, 38, TEXT, 60)
	var title := _text("success") if _phase == "level_done" else _text("completed")
	_center_label(title, 640.0, 338.0, 24, TEXT, 418)
	_center_label(_text("earned") + " " + str(_score) + " " + _text("points"), 640.0, 375.0, 20, GOLD, 408)
	_draw_button(NEXT_RECT, _text("next") if _phase == "level_done" else _text("again"), AQUA)
