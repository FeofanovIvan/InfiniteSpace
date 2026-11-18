extends Control
## MIKA / Barnard's Galaxy / Dinosaur Eggs.
## Standalone Godot 4.7.1 scene; visually consistent with Eco Sort V2.
## 3 levels: matching shell color, fictional species mark, then both.

const DESIGN := Vector2(1280.0, 720.0)
const LANGS := ["ru", "en", "pt", "es", "de", "fr"]
const PALETTE := [
	Color("fa6c83"), Color("69baff"), Color("69dfa5"), Color("ffdb70"),
	Color("b699ff"), Color("ff95ce"), Color("ffab70"), Color("6ee5df")
]
const EGG_CENTER := Vector2(640.0, 338.0)
const STAGE_KEYS := ["stage_color", "stage_species", "stage_both"]
const PROMPT_KEYS := ["prompt_color", "prompt_species", "prompt_both"]
const EGGS_PER_NEST := 2
const STAGE_LENGTH := 4 * EGGS_PER_NEST
const STAR := preload("res://planet_hub/games/dinosaur_eggs/star_core.png")

var _strings: Dictionary = {}
var _locale := "en"
var _service: Node = null
var _scale_factor := 1.0
var _offset := Vector2.ZERO
var _t := 0.0
var _stage := 0
var _egg_idx := 0
var _total_score := 0
var _total_correct := 0
var _targets: Array[Dictionary] = []
var _queue: Array[Dictionary] = []
var _filled := [0, 0, 0, 0]
var _state := "playing"  # playing, flying, stage_done, all_done
var _dragging := false
var _drag_at := EGG_CENTER
var _drag_start := EGG_CENTER
var _drag_moved := false
var _selected := false
var _hover_nest := -1
var _hint_nest := -1
var _hint_timer := 0.0
var _feedback := ""
var _feedback_timer := 0.0
var _shake_timer := 0.0
var _fly_t := 0.0
var _fly_to := Vector2.ZERO
var _fly_egg: Dictionary = {}
var _flight_nest := -1
var _confetti: Array[Dictionary] = []

var _lang_button: OptionButton
var _restart_button: Button
var _hint_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_read_strings()
	_create_controls()
	_link_language()
	_layout_controls()
	get_viewport().size_changed.connect(_layout_controls)
	_new_game()

func _read_strings() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/dinosaur_eggs/data/strings.json"))
	if parsed is Dictionary:
		_strings = parsed

func _link_language() -> void:
	_service = get_node_or_null("/root/LanguageService")
	var chosen := "en"
	if _service != null:
		chosen = String(_service.get("learning_locale"))
		if not LANGS.has(chosen):
			chosen = String(_service.get("interface_locale"))
		if _service.has_signal("language_changed"):
			_service.connect("language_changed", Callable(self, "_on_service_language"))
	else:
		var cfg := ConfigFile.new()
		if cfg.load("user://mika_dino_eggs.cfg") == OK:
			chosen = String(cfg.get_value("settings", "language", "en"))
	_set_locale(chosen)

func _on_service_language(_value: String) -> void:
	if _service == null:
		return
	_set_locale(String(_service.get("learning_locale")))

func _set_locale(code: String) -> void:
	_locale = code if LANGS.has(code) else "en"
	if _lang_button != null:
		_lang_button.select(LANGS.find(_locale))
	if _restart_button != null:
		_restart_button.text = _tr("restart")
	if _hint_button != null:
		_hint_button.text = _tr("hint")
	queue_redraw()

func _on_lang_selected(idx: int) -> void:
	if idx < 0 or idx >= LANGS.size():
		return
	var selected := String(LANGS[idx])
	if _service != null and _service.has_method("set_learning_locale"):
		_service.call("set_learning_locale", selected)
	else:
		var cfg := ConfigFile.new()
		cfg.set_value("settings", "language", selected)
		cfg.save("user://mika_dino_eggs.cfg")
	_set_locale(selected)

func _pack() -> Dictionary:
	return _strings.get(_locale, _strings.get("en", {}))

func _tr(key: String) -> String:
	return String(_pack().get(key, key))

func _color_name(index: int) -> String:
	var names: Array = _pack().get("colors", [])
	return String(names[index]) if index < names.size() else "COLOR"

func _species_name(index: int) -> String:
	var names: Array = _pack().get("species", [])
	return String(names[index]) if index < names.size() else "TYPE"

func _create_controls() -> void:
	_lang_button = OptionButton.new()
	_lang_button.focus_mode = Control.FOCUS_NONE
	_lang_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for code in LANGS:
		_lang_button.add_item(String(_strings.get(code, {}).get("name", code)))
	_lang_button.item_selected.connect(_on_lang_selected)
	_style_button(_lang_button, Color("102945"), Color("6099c1"))
	add_child(_lang_button)
	_restart_button = Button.new()
	_restart_button.focus_mode = Control.FOCUS_NONE
	_restart_button.pressed.connect(_new_game)
	_style_button(_restart_button, Color("153454"), Color("699ecd"))
	add_child(_restart_button)
	_hint_button = Button.new()
	_hint_button.focus_mode = Control.FOCUS_NONE
	_hint_button.pressed.connect(_show_hint)
	_style_button(_hint_button, Color("183e40"), Color("7adac1"))
	add_child(_hint_button)

func _style_button(button: BaseButton, bg: Color, outline: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = outline
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", normal)
	var over := normal.duplicate() as StyleBoxFlat
	over.bg_color = bg.lightened(0.13)
	over.border_color = Color("c7ecff")
	button.add_theme_stylebox_override("hover", over)
	var press := normal.duplicate() as StyleBoxFlat
	press.bg_color = bg.darkened(0.20)
	button.add_theme_stylebox_override("pressed", press)
	button.add_theme_color_override("font_color", Color("ecf8ff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)

func _layout_controls() -> void:
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	_scale_factor = minf(viewport_size.x / DESIGN.x, viewport_size.y / DESIGN.y)
	_offset = (viewport_size - DESIGN * _scale_factor) * 0.5
	_place(_lang_button, Rect2(1086, 18, 165, 40))
	_place(_restart_button, Rect2(1086, 66, 165, 39))
	_place(_hint_button, Rect2(933, 66, 143, 39))
	queue_redraw()

func _place(control: Control, rect: Rect2) -> void:
	control.scale = Vector2.ONE * _scale_factor
	control.position = _offset + rect.position * _scale_factor
	control.size = rect.size

func _new_game() -> void:
	_total_score = 0
	_total_correct = 0
	_stage = 0
	_begin_stage()

func _begin_stage() -> void:
	_state = "playing"
	_egg_idx = 0
	_filled = [0, 0, 0, 0]
	_selected = false
	_dragging = false
	_hover_nest = -1
	_hint_nest = -1
	_hint_timer = 0.0
	_feedback = ""
	_feedback_timer = 0.0
	var color_ids := [0, 1, 2, 3, 4, 5, 6, 7]
	color_ids.shuffle()
	var species_ids := [0, 1, 2, 3]
	species_ids.shuffle()
	_targets.clear()
	_queue.clear()
	for i in range(4):
		var target: Dictionary = {"color": color_ids[i], "species": species_ids[i]}
		_targets.append(target)
		for n in range(EGGS_PER_NEST):
			var egg := target.duplicate()
			if _stage == 0:
				egg["species"] = randi_range(0, 3)
			elif _stage == 1:
				egg["color"] = randi_range(0, 7)
			_queue.append(egg)
	_queue.shuffle()
	queue_redraw()

func _show_hint() -> void:
	if _state != "playing" or _egg_idx >= _queue.size():
		return
	_hint_nest = _correct_nest(_queue[_egg_idx])
	_hint_timer = 3.0
	_feedback = _tr("hint_msg")
	_feedback_timer = 2.5
	queue_redraw()

func _correct_nest(egg: Dictionary) -> int:
	for i in range(_targets.size()):
		var target: Dictionary = _targets[i]
		var color_matches := int(target["color"]) == int(egg["color"])
		var species_matches := int(target["species"]) == int(egg["species"])
		if (_stage == 0 and color_matches) or (_stage == 1 and species_matches) or (_stage == 2 and color_matches and species_matches):
			return i
	return -1

func _try_nest(index: int) -> void:
	if _state != "playing" or index < 0 or index >= 4 or _egg_idx >= _queue.size():
		return
	var egg: Dictionary = _queue[_egg_idx]
	if _correct_nest(egg) == index:
		_total_score += 10
		_total_correct += 1
		_filled[index] += 1
		_fly_to = _nest_rect(index).get_center() + Vector2(0, 24)
		_fly_egg = egg.duplicate()
		_flight_nest = index
		_fly_t = 0.0
		_state = "flying"
		_feedback = _tr("correct")
		_feedback_timer = 1.0
		_spawn_sparks(_fly_to, PALETTE[int(_targets[index]["color"])])
	else:
		_feedback = _tr("wrong_color") if _stage == 0 else (_tr("wrong_species") if _stage == 1 else _tr("wrong_both"))
		_feedback_timer = 2.0
		_shake_timer = 0.50
	_dragging = false
	_selected = false
	_hover_nest = -1
	queue_redraw()

func _advance_egg() -> void:
	_egg_idx += 1
	_state = "playing"
	_hint_nest = -1
	_hint_timer = 0.0
	if _egg_idx >= STAGE_LENGTH:
		_total_score += 20
		_state = "all_done" if _stage == 2 else "stage_done"
		_feedback = ""
	queue_redraw()

func _next_stage() -> void:
	if _state == "stage_done":
		_stage += 1
		_begin_stage()
	elif _state == "all_done":
		_new_game()

func _process(delta: float) -> void:
	_t += delta
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(0.0, _feedback_timer - delta)
	if _hint_timer > 0.0:
		_hint_timer = maxf(0.0, _hint_timer - delta)
	if _shake_timer > 0.0:
		_shake_timer = maxf(0.0, _shake_timer - delta)
	if _state == "flying":
		_fly_t += delta / 0.62
		if _fly_t >= 1.0:
			_advance_egg()
	for sparkle in _confetti:
		sparkle["life"] = float(sparkle["life"]) - delta
	for index in range(_confetti.size() - 1, -1, -1):
		if float(_confetti[index]["life"]) <= 0.0:
			_confetti.remove_at(index)
	queue_redraw()

func _spawn_sparks(center: Vector2, tint: Color) -> void:
	for i in range(16):
		var a := TAU * float(i) / 16.0
		_confetti.append({"pos": center, "vel": Vector2(cos(a), sin(a)) * randf_range(48.0, 146.0), "life": randf_range(0.55, 1.2), "max": 1.2, "color": tint})

func _nest_rect(index: int) -> Rect2:
	return Rect2(30.0 + float(index) * 312.0, 507.0, 284.0, 173.0)

func _at_screen(point: Vector2) -> Vector2:
	return (point - _offset) / maxf(0.01, _scale_factor)

func _egg_hit(point: Vector2) -> bool:
	var delta := point - EGG_CENTER
	return (delta.x * delta.x / 95.0 / 95.0 + delta.y * delta.y / 130.0 / 130.0) < 1.15

func _nest_at(point: Vector2) -> int:
	for i in range(4):
		if _nest_rect(i).has_point(point):
			return i
	return -1

func _input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	var down := false
	var up := false
	var moving := false
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		point = _at_screen(event.position)
		down = event.pressed
		up = not event.pressed
	elif event is InputEventMouseMotion:
		point = _at_screen(event.position)
		moving = true
	elif event is InputEventScreenTouch:
		point = _at_screen(event.position)
		down = event.pressed
		up = not event.pressed
	elif event is InputEventScreenDrag:
		point = _at_screen(event.position)
		moving = true
	elif event is InputEventKey:
		if not event.pressed or event.echo or _state != "playing":
			return
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			_try_nest(event.keycode - KEY_1)
		return
	else:
		return

	if down and _state in ["stage_done", "all_done"]:
		if Rect2(474, 438, 332, 63).has_point(point):
			_next_stage()
		return
	if _state != "playing":
		return
	if down:
		if _egg_hit(point):
			_dragging = true
			_selected = true
			_drag_moved = false
			_drag_start = point
			_drag_at = point
			accept_event()
			return
		var nest := _nest_at(point)
		if nest >= 0:
			_try_nest(nest)
			accept_event()
	elif moving:
		if _dragging:
			_drag_at = point
			_drag_moved = _drag_moved or point.distance_to(_drag_start) > 12.0
			_hover_nest = _nest_at(point)
			accept_event()
	elif up and _dragging:
		_dragging = false
		var hover := _nest_at(point)
		_hover_nest = -1
		if hover >= 0:
			_try_nest(hover)
		else:
			_selected = true
		accept_event()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(_offset, 0.0, Vector2(_scale_factor, _scale_factor))
	_draw_backdrop()
	_draw_header()
	_draw_center()
	_draw_nests()
	if _state == "flying":
		var flight := minf(_fly_t, 1.0)
		var eased_flight := 1.0 - pow(1.0 - flight, 3.0)
		var p_flight := EGG_CENTER.lerp(_fly_to, eased_flight)
		p_flight.y -= sin(PI * flight) * 125.0
		_draw_egg(p_flight, 1.0 - flight * 0.61, int(_fly_egg["color"]), int(_fly_egg["species"]), _stage)
	if _dragging and _drag_moved and _state == "playing" and _egg_idx < _queue.size():
		var held: Dictionary = _queue[_egg_idx]
		_draw_egg(_drag_at, 1.02, int(held["color"]), int(held["species"]), _stage)
	_draw_footer()
	_draw_sparks()
	if _state in ["stage_done", "all_done"]:
		_draw_completion()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _ca(hex: String, alpha: float) -> Color:
	var col := Color(hex)
	col.a = alpha
	return col

func _panel(rect: Rect2, bg: Color, border: Color, corner := 18, border_width := 2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner)
	draw_style_box(sb, rect)

func _text(value: String, pos: Vector2, size_px: int, color: Color, max_width := -1.0, centered := false) -> void:
	var align := HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	draw_string(ThemeDB.fallback_font, pos, value, align, max_width, size_px, color)

func _draw_backdrop() -> void:
	for i in range(32):
		var v := float(i) / 32.0
		var col := Color("081322").lerp(Color("14324e"), v * 0.70)
		draw_rect(Rect2(0, i * 23, 1280, 25), col)
	for i in range(74):
		var px := fmod(37.0 + float(i) * 137.41, 1268.0)
		var py := fmod(45.0 + float(i) * 71.27, 702.0)
		draw_circle(Vector2(px, py), 0.8 + float(i % 3) * 0.55, Color(0.73, 0.89, 1.0, 0.16))
	# Faint fossil ribs etched behind panels.
	for i in range(8):
		var x := 52.0 + i * 33.0
		draw_arc(Vector2(x, 408.0), 36.0 + i * 6.0, 3.65, 5.78, 28, _ca("4a94b3", 0.11), 3.0, true)
	for i in range(12):
		draw_circle(Vector2(1118 + sin(float(i) * 1.3) * 88, 245 + i * 15), 2.8, _ca("63bcce", 0.13))
	# Bioluminescent floor lines.
	for j in range(7):
		var y := 486.0 + float(j) * 30.0
		draw_line(Vector2(0, y), Vector2(1280, y + sin(float(j)) * 9.0), _ca("2e7397", 0.10), 2.0)

func _draw_header() -> void:
	_panel(Rect2(19, 13, 1242, 108), _ca("10223c", 0.96), Color("37688b"), 22)
	draw_texture_rect(STAR, Rect2(34, 25, 40, 40), false, Color(0.65, 0.94, 1.0, 0.85))
	_text(_tr("title"), Vector2(84, 53), 29, Color("f1faff"), 720.0)
	_text(_tr("region"), Vector2(87, 80), 13, Color("86b7d0"), 790.0)
	_text("%s %d / 3" % [_tr("level"), _stage + 1], Vector2(668, 36), 19, Color("e4f8ff"), 245.0)
	_text("%s  %d" % [_tr("score"), _total_score], Vector2(668, 65), 24, Color("ffe9ab"), 245.0)
	# Eight progress dots for current stage.
	for i in range(STAGE_LENGTH):
		var c := Color("72e6ba") if i < _egg_idx else Color("3b617d")
		if _state == "flying" and i == _egg_idx:
			c = Color("f8d77d")
		draw_circle(Vector2(691 + i * 23, 99), 6, c)
		draw_arc(Vector2(691 + i * 23, 99), 7, 0.0, TAU, 18, _ca("94b4c9", 0.45), 1.2)

func _draw_center() -> void:
	_panel(Rect2(26, 144, 1228, 348), _ca("0d2038", 0.86), Color("365c7c"), 25)
	_panel(Rect2(276, 164, 728, 308), _ca("132c46", 0.92), Color("3d7192"), 24)
	# Decorative inner rings and central pedestal.
	var pulse := 0.5 + 0.5 * sin(_t * 2.1)
	for i in range(4):
		draw_arc(EGG_CENTER + Vector2(0, 10), 117.0 + i * 13.0, 0.10, PI - 0.10, 42, Color(0.42, 0.88, 0.85, 0.12 + pulse * 0.04), 2.0)
	_ellipse(Rect2(518, 443, 244, 24), Color(0.04, 0.11, 0.2, 0.78))
	_ellipse(Rect2(557, 444, 166, 13), Color(0.18, 0.81, 0.76, 0.26))
	_text(_tr(STAGE_KEYS[_stage]), Vector2(304, 204), 22, Color("b8ffdf"), 670.0, true)
	_text(_tr(PROMPT_KEYS[_stage]), Vector2(320, 238), 18, Color("d4ecf8"), 640.0, true)
	if _state == "playing":
		var current: Dictionary = _queue[_egg_idx]
		var egg_at := EGG_CENTER + Vector2(0, sin(_t * 1.9) * 5)
		if _shake_timer > 0.0:
			egg_at.x += sin(_t * 45.0) * 8.0
		if _dragging and _drag_moved:
			_draw_egg(egg_at, 0.72, int(current["color"]), int(current["species"]), _stage)
		elif _selected:
			draw_arc(egg_at, 116, 0.0, TAU, 56, _ca("a6eaff", 0.62 + pulse * 0.20), 3.0, true)
			_draw_egg(egg_at, 1.08, int(current["color"]), int(current["species"]), _stage)
		else:
			_draw_egg(egg_at, 1.08, int(current["color"]), int(current["species"]), _stage)
	elif _state == "flying":
		_draw_egg(EGG_CENTER, 0.64, int(_fly_egg["color"]), int(_fly_egg["species"]), _stage)
	else:
		_draw_hatchling(EGG_CENTER + Vector2(0, 10), 1.8, _stage % 4, Color("8ae5bf"))
	# Left instruction card.
	_panel(Rect2(43, 214, 209, 213), _ca("102a43", 0.92), Color("396b85"), 18)
	_text(_tr("hatchery"), Vector2(55, 247), 18, Color("99dff3"), 184.0, true)
	_draw_small_egg(Vector2(147, 309), Color("a4dced"), 0.84)
	_text("%d / %d" % [min(_egg_idx + 1, STAGE_LENGTH), STAGE_LENGTH], Vector2(58, 392), 24, Color("edfbff"), 177.0, true)
	# Right instructions and good feedback.
	_panel(Rect2(1028, 214, 207, 213), _ca("102a43", 0.92), Color("396b85"), 18)
	_text(_tr("no_timer"), Vector2(1037, 251), 13, Color("9ac6dc"), 190.0, true)
	for i in range(3):
		var on := i <= _stage
		draw_circle(Vector2(1090 + i * 41, 303), 13, Color("67e7b4") if on else Color("38576b"))
		_text(str(i + 1), Vector2(1077 + i * 41, 309), 16, Color("092035") if on else Color("b7d6e3"), 27.0, true)
	_text(_tr("tip"), Vector2(1035, 372), 14, Color("e0f0fa"), 195.0, true)
	if _feedback_timer > 0.0:
		var good := _state == "flying" or _feedback == _tr("hint_msg")
		_text(_feedback, Vector2(307, 457), 17, Color("96ffbc") if good else Color("ffbfa8"), 665.0, true)
	elif _state == "playing":
		_text(_tr("drag_egg"), Vector2(500, 456), 16, Color("8cbaca"), 280.0, true)

func _draw_nests() -> void:
	for i in range(4):
		var r := _nest_rect(i)
		var target: Dictionary = _targets[i]
		var shell_color: Color = PALETTE[int(target["color"])]
		var hovering := _hover_nest == i or (_hint_timer > 0.0 and _hint_nest == i)
		var border := Color("8ef6ce") if hovering else Color("477493")
		_panel(r, _ca("122841", 0.97), border, 21, 3 if hovering else 2)
		if hovering:
			_panel(Rect2(r.position + Vector2(7, 7), r.size - Vector2(14, 14)), _ca("51eab9", 0.06), _ca("70f1c0", 0.22), 18, 1)
		# The shell color is only relevant for levels 1 and 3.
		_draw_egg(r.position + Vector2(73, 76), 0.43, int(target["color"]), int(target["species"]), _stage)
		# Nest made from layered woven branches.
		var cx := r.position.x + 76
		var cy := r.position.y + 123
		_ellipse(Rect2(cx - 65, cy - 9, 130, 38), Color("233f3e"))
		for j in range(5):
			var spread := float(j) - 2.0
			draw_arc(Vector2(cx + spread * 4, cy - spread * 2), 51 + j * 3, 0.15, PI - 0.15, 20, _ca("65b6a7", 0.23 + float(j) * 0.07), 4.0)
		# Nest label is different for the color / type / combined stage.
		var name := _color_name(int(target["color"])) if _stage == 0 else _species_name(int(target["species"]))
		if _stage == 2:
			name = "%s +" % _color_name(int(target["color"]))
		_text(name, r.position + Vector2(151, 70), 17, Color("ecf9ff"), 122.0, true)
		if _stage == 2:
			_text(_species_name(int(target["species"])), r.position + Vector2(151, 93), 15, Color("bce5ed"), 122.0, true)
		_text("%d / %d" % [_filled[i], EGGS_PER_NEST], r.position + Vector2(151, 123), 22, Color("d3ecf6"), 121.0, true)
		for j in range(EGGS_PER_NEST):
			draw_circle(r.position + Vector2(179 + 26 * j, 148), 8, shell_color if j < _filled[i] else Color("365770"))
			draw_arc(r.position + Vector2(179 + 26 * j, 148), 9.0, 0.0, TAU, 18, _ca("aad9e8", 0.50), 1.0)
		if _filled[i] >= EGGS_PER_NEST:
			draw_circle(r.position + Vector2(250, 24), 11, Color("66e9ab"))
			_text("✓", r.position + Vector2(237, 31), 20, Color("15304a"), 25.0, true)

func _draw_footer() -> void:
	_text(_tr("drag"), Vector2(58, 707), 14, Color("96bbd5"), 950.0)
	_text(_tr("fictional"), Vector2(830, 707), 12, Color("749bb0"), 399.0, true)

func _draw_sparks() -> void:
	for sparkle in _confetti:
		var life := float(sparkle["life"])
		var p: Vector2 = sparkle["pos"] + (1.2 - life) * (sparkle["vel"] as Vector2)
		var col: Color = sparkle["color"]
		draw_circle(p, maxf(1.0, life * 2.7), Color(col.r, col.g, col.b, clampf(life, 0, 1)))

func _draw_completion() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN), Color(0.03, 0.07, 0.14, 0.78))
	_panel(Rect2(300, 180, 680, 356), Color("102a43"), Color("76d2cb"), 28, 3)
	for i in range(7):
		draw_circle(Vector2(330 + i * 95, 202 + sin(_t + i) * 4), 4, _ca("81e9c0", 0.53))
	_draw_hatchling(Vector2(640, 289), 1.55, _stage % 4, Color("89ecb6"))
	_text(_tr("complete") if _state == "all_done" else _tr("stage_done"), Vector2(360, 355), 32, Color("effff6"), 560.0, true)
	_text(_tr("final_msg") if _state == "all_done" else _tr("great"), Vector2(370, 396), 19, Color("b9e1ef"), 540.0, true)
	_text("%s: %d" % [_tr("score"), _total_score], Vector2(430, 430), 21, Color("ffdf90"), 420.0, true)
	_panel(Rect2(474, 445, 332, 62), Color("69dcc0"), Color("d5fff3"), 19, 2)
	_text(_tr("again") if _state == "all_done" else _tr("next"), Vector2(481, 482), 24, Color("0a3041"), 317.0, true)

func _ellipse(rect: Rect2, fill: Color) -> void:
	var points := PackedVector2Array()
	for i in range(33):
		var theta := TAU * float(i) / 32.0
		points.append(rect.get_center() + Vector2(cos(theta) * rect.size.x * 0.5, sin(theta) * rect.size.y * 0.5))
	draw_colored_polygon(points, fill)

func _draw_egg(center: Vector2, scale: float, color_idx: int, species_idx: int, stage: int) -> void:
	var base: Color = PALETTE[color_idx] if stage != 1 else Color("b7d0da")
	var pts := PackedVector2Array()
	for j in range(49):
		var a := TAU * float(j) / 48.0
		pts.append(center + Vector2(sin(a) * (63.0 - 12.0 * cos(a)), -88.0 * cos(a)) * scale)
	draw_colored_polygon(pts, base.darkened(0.20))
	var inner := PackedVector2Array()
	for j in range(49):
		var a := TAU * float(j) / 48.0
		inner.append(center + Vector2(sin(a) * (59.0 - 11.0 * cos(a)), -83.0 * cos(a)) * scale)
	draw_colored_polygon(inner, base)
	draw_polyline(pts, _ca("effbff", 0.83), 2.4 * scale, true)
	# Glossy left-side highlights.
	_ellipse(Rect2(center.x - 37 * scale, center.y - 57 * scale, 24 * scale, 77 * scale), Color(1, 1, 1, 0.20))
	draw_circle(center + Vector2(32, 26) * scale, 7 * scale, base.darkened(0.18))
	draw_circle(center + Vector2(-30, 31) * scale, 4 * scale, base.darkened(0.22))
	if stage != 0:
		_draw_species_icon(center + Vector2(0, 5) * scale, species_idx, 0.66 * scale, Color("123d52"))
	else:
		for k in range(5):
			var x := sin(float(k) * 2.12) * 29.0
			var y := cos(float(k) * 1.41) * 35.0
			draw_circle(center + Vector2(x, y) * scale, (6.0 + k % 3) * scale, base.darkened(0.21))

func _draw_small_egg(center: Vector2, tint: Color, sc: float) -> void:
	_ellipse(Rect2(center.x - 37 * sc, center.y + 40 * sc, 75 * sc, 13 * sc), Color(0, 0, 0, 0.28))
	_draw_egg(center, sc, 7, 0, 0)

func _draw_species_icon(center: Vector2, idx: int, scale: float, tint: Color) -> void:
	# Four fictional, recognizable silhouettes; no claim about real species' eggs.
	if idx == 0:  # long neck
		draw_line(center + Vector2(-18, 25) * scale, center + Vector2(10, -28) * scale, tint, 12.0 * scale, true)
		draw_circle(center + Vector2(13, -31) * scale, 12 * scale, tint)
		_ellipse(Rect2(center.x - 30 * scale, center.y + 8 * scale, 45 * scale, 25 * scale), tint)
		draw_circle(center + Vector2(19, -32) * scale, 2.1 * scale, Color("c4f4f0"))
	elif idx == 1:  # two horns
		draw_circle(center + Vector2(0, 8) * scale, 25 * scale, tint)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-23, -6) * scale, center + Vector2(-27, -41) * scale, center + Vector2(-8, -12) * scale]), tint)
		draw_colored_polygon(PackedVector2Array([center + Vector2(23, -6) * scale, center + Vector2(27, -41) * scale, center + Vector2(8, -12) * scale]), tint)
		draw_circle(center + Vector2(-9, 6) * scale, 3 * scale, Color("cef9f3"))
		draw_circle(center + Vector2(9, 6) * scale, 3 * scale, Color("cef9f3"))
	elif idx == 2:  # plate back
		_ellipse(Rect2(center.x - 34 * scale, center.y - 2 * scale, 68 * scale, 32 * scale), tint)
		for j in range(4):
			var px := -24.0 + float(j) * 16.0
			draw_colored_polygon(PackedVector2Array([center + Vector2(px - 6, 0) * scale, center + Vector2(px, -29 - 4 * (j % 2)) * scale, center + Vector2(px + 8, 0) * scale]), tint)
		draw_line(center + Vector2(-26, 22) * scale, center + Vector2(-24, 36) * scale, tint, 7 * scale)
		draw_line(center + Vector2(24, 22) * scale, center + Vector2(22, 36) * scale, tint, 7 * scale)
	else:  # crest head
		draw_circle(center + Vector2(0, 7) * scale, 24 * scale, tint)
		for j in range(4):
			var px := -17.0 + float(j) * 12.0
			draw_line(center + Vector2(px, -9) * scale, center + Vector2(px + 6, -38 - 5 * (j % 2)) * scale, tint, 7 * scale, true)
		draw_circle(center + Vector2(-8, 8) * scale, 2.5 * scale, Color("c7f7eb"))
		draw_circle(center + Vector2(8, 8) * scale, 2.5 * scale, Color("c7f7eb"))

func _draw_hatchling(center: Vector2, scale: float, kind: int, tint: Color) -> void:
	_ellipse(Rect2(center.x - 57 * scale, center.y + 23 * scale, 114 * scale, 19 * scale), Color(0.0, 0.06, 0.09, 0.25))
	# Cracked eggshell cup.
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-39, 8) * scale, center + Vector2(-27, 0) * scale,
		center + Vector2(-12, 11) * scale, center + Vector2(2, 0) * scale,
		center + Vector2(16, 10) * scale, center + Vector2(29, 1) * scale,
		center + Vector2(40, 8) * scale, center + Vector2(30, 38) * scale,
		center + Vector2(-30, 38) * scale
	]), Color("b8e4e4"))
	_ellipse(Rect2(center.x - 22 * scale, center.y - 44 * scale, 44 * scale, 57 * scale), tint.darkened(0.08))
	draw_circle(center + Vector2(0, -52) * scale, 25 * scale, tint)
	_draw_species_icon(center + Vector2(0, -52) * scale, kind, 0.33 * scale, Color("245f60"))
	draw_circle(center + Vector2(-9, -51) * scale, 3.5 * scale, Color("17394c"))
	draw_circle(center + Vector2(10, -51) * scale, 3.5 * scale, Color("17394c"))
	draw_circle(center + Vector2(-8, -53) * scale, 1.1 * scale, Color.WHITE)
	draw_circle(center + Vector2(11, -53) * scale, 1.1 * scale, Color.WHITE)
