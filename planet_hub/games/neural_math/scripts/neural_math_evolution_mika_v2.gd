extends "res://planet_hub/games/neural_math/scripts/neural_math_evolution_mika_v1.gd"
## MIKA | Neural Math v2 | free random arithmetic, multiplication/division,
## simple fractions; five Evolution-style draggable/tappable answer cards.
## v2 fixed: native Button minimum sizing no longer spills past its mode panel.
## The original audio, lessons and hint logic remain unreferenced.

const SPACE_SKY = preload("res://simulator_ui/scripts/real_space_background.gd")
const MODE_NAMES := {
	"ru": ["СЛОЖЕНИЕ / ВЫЧИТАНИЕ", "УМНОЖЕНИЕ / ДЕЛЕНИЕ", "ДРОБИ"],
	"en": ["ADD / SUBTRACT", "MULTIPLY / DIVIDE", "FRACTIONS"],
	"pt": ["SOMAR / SUBTRAIR", "MULTIPLICAR / DIVIDIR", "FRAÇÕES"],
	"es": ["SUMAR / RESTAR", "MULTIPLICAR / DIVIDIR", "FRACCIONES"],
	"de": ["PLUS / MINUS", "MAL / GETEILT", "BRÜCHE"],
	"fr": ["ADDITION / SOUSTRACTION", "MULTIPLICATION / DIVISION", "FRACTIONS"]
}
const MODE_CAPTIONS := {
	"ru": "РЕЖИМ ИГРЫ", "en": "CHOOSE A MODE", "pt": "ESCOLHA O MODO",
	"es": "ELIGE UN MODO", "de": "SPIELMODUS", "fr": "CHOISIS UN MODE"
}
const SYMBOLS = ["+", "−", "×", "÷", "≠"]
const FRACTION_DENOMINATORS = [4, 5, 6, 8, 10]

var _mode: int = 0
var _denominator: int = 1
var _modes_rect: Rect2 = Rect2()
var _mode_buttons: Array[Button] = []
var _sky: Control
var _recent: Array[String] = []
var _last_problem_signature: String = ""


func _ready() -> void:
	super._ready()
	_sky = SPACE_SKY.new() as Control
	_sky.name = "NeuralMathOriginalFlightSpace"
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky.z_index = -20
	add_child(_sky)
	_sky.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_layout()


func _build_header() -> void:
	super._build_header()
	_restart.hide()
	_restart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(3):
		var button := Button.new()
		button.name = "NeuralMathMode_%d" % i
		button.focus_mode = Control.FOCUS_NONE
		# Long translated labels must not impose native minimum width.
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size = Vector2.ZERO
		button.z_index = 18
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_color_override("font_color", TEXT)
		button.add_theme_color_override("font_hover_color", TEXT)
		button.add_theme_color_override("font_pressed_color", TEXT)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_choose_mode.bind(i))
		add_child(button)
		_mode_buttons.append(button)
	_update_labels()


func _update_labels() -> void:
	super._update_labels()
	if _restart != null:
		_restart.hide()
	if _mode_buttons.size() == 3:
		var names: Array = MODE_NAMES.get(_locale, MODE_NAMES["en"])
		for i in range(3):
			_mode_buttons[i].text = str(names[i])
			_style_mode_button(i)
	queue_redraw()


func _style_mode_button(i: int) -> void:
	if i < 0 or i >= _mode_buttons.size():
		return
	var button: Button = _mode_buttons[i]
	var selected: bool = _mode == i
	button.add_theme_stylebox_override("normal", _style(Color(0.08,0.27,0.39,0.94) if selected else Color(0.025,0.10,0.19,0.89), MINT if selected else Color("4c87a9"), 13, 3 if selected else 2))
	button.add_theme_stylebox_override("hover", _style(Color("245071"), CYAN, 13, 2))
	button.add_theme_stylebox_override("pressed", _style(Color("21647c"), MINT, 13, 3))


func _choose_mode(mode: int) -> void:
	if mode < 0 or mode > 2:
		return
	_mode = mode
	_transition_time = 0.0
	_correct_lock = false
	_selected = -1
	_active_pointer = -1
	_dragging = false
	_feedback_time = 0.0
	_feedback = ""
	_recent.clear()
	for i in range(_mode_buttons.size()):
		_style_mode_button(i)
	_new_round()


func _layout() -> void:
	super._layout()
	if _title_panel == null or _mode_buttons.size() != 3:
		return
	if _sky != null:
		_sky.position = Vector2.ZERO
		_sky.size = _view
	var w: float = _stage.size.x
	var h: float = _stage.size.y
	var padding: float = clampf(w * 0.021, 8.0, 27.0)
	var mode_width: float = clampf(w * 0.235, 128.0, 300.0)
	var mode_height: float = minf(h * 0.58, 240.0)
	_modes_rect = Rect2(Vector2(_stage.end.x - padding - mode_width, _stage.position.y + padding), Vector2(mode_width, mode_height))
	var button_gap: float = clampf(h * 0.016, 3.0, 12.0)
	var button_top: float = _modes_rect.position.y + clampf(h * 0.095, 15.0, 36.0)
	var remaining: float = maxf(72.0, _modes_rect.end.y - button_top - padding * 0.36)
	var button_height: float = (remaining - button_gap * 2.0) / 3.0
	for i in range(3):
		var button: Button = _mode_buttons[i]
		var button_width: float = maxf(24.0, mode_width - 14.0)
		var title_units: float = maxf(1.0, float(button.text.length()) * 0.55)
		var text_fit: float = (button_width - 14.0) / title_units
		# Important: set font BEFORE Button.size. Otherwise Godot's previous
		# text-driven minimum width can retain a larger geometry at 1024x768.
		button.add_theme_font_size_override("font_size", maxi(9, roundi(minf(16.0, minf(button_height * 0.38, text_fit)))))
		button.position = Vector2(_modes_rect.position.x + 7.0, button_top + i * (button_height + button_gap))
		button.size = Vector2(button_width, button_height)

	# Equation occupies the left side. The choice cards span the full bottom row.
	var exp_left: float = _stage.position.x + padding
	var exp_right: float = _modes_rect.position.x - padding
	var area_width: float = maxf(120.0, exp_right - exp_left)
	var equation_height: float = clampf(h * 0.285, 48.0, 136.0)
	var mid_y: float = _stage.position.y + h * 0.438
	var widths: Array[float] = [0.237,0.112,0.237,0.112,0.237]
	var gap: float = minf(area_width * 0.012, 14.0)
	var total_factor: float = 0.0
	for value in widths:
		total_factor += value
	var factor: float = (area_width * 0.96 - gap * 4.0) / total_factor
	var x: float = exp_left + (area_width - (total_factor * factor + 4.0 * gap)) * 0.5
	_expression_rects.clear()
	for factor_piece in widths:
		var segment: float = factor_piece * factor
		_expression_rects.append(Rect2(Vector2(x, mid_y - equation_height * 0.5), Vector2(segment, equation_height)))
		x += segment + gap
	_target_rect = _expression_rects[_missing_index]

	var choices_width: float = w * 0.88
	var choice_gap: float = clampf(w * 0.014, 5.0, 20.0)
	var choice_width: float = (choices_width - choice_gap * 4.0) / 5.0
	var choice_h: float = clampf(h * 0.203, 44.0, 106.0)
	var choice_y: float = _stage.end.y - choice_h - clampf(h * 0.048, 9.0, 34.0)
	var choice_x: float = _stage.get_center().x - choices_width * 0.5
	_choice_rects.clear()
	for i in range(5):
		_choice_rects.append(Rect2(Vector2(choice_x + i * (choice_width + choice_gap), choice_y), Vector2(choice_width, choice_h)))
	queue_redraw()


func _candidate() -> Dictionary:
	var a: int = 0
	var b: int = 0
	var c: int = 0
	var denominator: int = 1
	var op: String = "+"
	if _mode == 0:
		op = "+" if _rng.randi_range(0, 1) == 0 else "−"
		if op == "+":
			a = _rng.randi_range(1, 12)
			b = _rng.randi_range(1, 12)
			c = a + b
		else:
			a = _rng.randi_range(3, 20)
			b = _rng.randi_range(1, a - 1)
			c = a - b
	elif _mode == 1:
		op = "×" if _rng.randi_range(0, 1) == 0 else "÷"
		if op == "×":
			a = _rng.randi_range(2, 6)
			b = _rng.randi_range(2, 6)
			c = a * b
		else:
			b = _rng.randi_range(2, 6)
			c = _rng.randi_range(1, 6)
			a = b * c
	else:
		denominator = FRACTION_DENOMINATORS[_rng.randi_range(0, FRACTION_DENOMINATORS.size() - 1)]
		op = "+" if _rng.randi_range(0, 1) == 0 else "−"
		if op == "+":
			a = _rng.randi_range(1, denominator - 1)
			b = _rng.randi_range(1, denominator - a)
			c = a + b
		else:
			a = _rng.randi_range(2, denominator)
			b = _rng.randi_range(1, a - 1)
			c = a - b
	var missing: int = 1 if _rng.randf() < 0.27 else [0, 2, 4][_rng.randi_range(0, 2)]
	return {"a": a, "b": b, "c": c, "den": denominator, "op": op, "missing": missing}


func _unique_operator(problem: Dictionary) -> bool:
	var a: float = float(problem["a"]) / float(problem["den"])
	var b: float = float(problem["b"]) / float(problem["den"])
	var c: float = float(problem["c"]) / float(problem["den"])
	var matching: int = 0
	for symbol in ["+", "−", "×", "÷"]:
		var result: float = 0.0
		match symbol:
			"+": result = a + b
			"−": result = a - b
			"×": result = a * b
			"÷": result = a / b
		if absf(result - c) < 0.0001:
			matching += 1
	return matching == 1


func _numeric_choices(correct: int) -> Array[String]:
	var low: int = 0
	var high: int = _denominator if _mode == 2 else maxi(42, correct + 8)
	var numbers: Array[int] = [correct]
	var tries: int = 0
	while numbers.size() < 5 and tries < 200:
		tries += 1
		var offset: int = _rng.randi_range(-6, 6)
		var guess: int = clampi(correct + offset, low, high)
		if not numbers.has(guess):
			numbers.append(guess)
	var fallback: int = low
	while numbers.size() < 5:
		if not numbers.has(fallback):
			numbers.append(fallback)
		fallback += 1
	numbers.shuffle()
	var choices: Array[String] = []
	for number in numbers:
		choices.append(str(number))
	return choices


func _new_round() -> void:
	_selected = -1
	_active_pointer = -1
	_dragging = false
	_correct_lock = false
	_feedback_time = 0.0
	_feedback = ""
	var candidate: Dictionary = {}
	var signature: String = ""
	var accepted: bool = false
	for attempt in range(140):
		candidate = _candidate()
		if int(candidate["missing"]) == 1 and not _unique_operator(candidate):
			continue
		signature = "%d:%s:%s:%s:%s:%s:%s" % [_mode, candidate["a"],candidate["b"],candidate["c"],candidate["den"],candidate["op"],candidate["missing"]]
		if _recent.has(signature):
			continue
		accepted = true
		break
	if not accepted:
		# Guaranteed valid fallback, only if randomness exhausted 140 attempts.
		match _mode:
			0: candidate = {"a": 7, "b": 5, "c": 12, "den": 1, "op": "+", "missing": 0}
			1: candidate = {"a": 15, "b": 3, "c": 5, "den": 1, "op": "÷", "missing": 2}
			2: candidate = {"a": 1, "b": 2, "c": 3, "den": 5, "op": "+", "missing": 0}
		signature = "%d:%s:%s:%s:%s:%s:%s" % [_mode, candidate["a"],candidate["b"],candidate["c"],candidate["den"],candidate["op"],candidate["missing"]]
	_last_problem_signature = signature
	_recent.append(signature)
	if _recent.size() > 16:
		_recent.remove_at(0)
	_missing_index = int(candidate["missing"])
	_denominator = int(candidate["den"])
	var a: int = int(candidate["a"])
	var b: int = int(candidate["b"])
	var c: int = int(candidate["c"])
	var op: String = str(candidate["op"])
	_equation.assign([str(a), op, str(b), "=", str(c)])
	if _missing_index == 1:
		_correct_answer = op
		_options.assign(SYMBOLS)
		_options.shuffle()
	else:
		_correct_answer = _equation[_missing_index]
		_options = _numeric_choices(int(_correct_answer))
	_layout()
	queue_redraw()


func _handle_press(pointer: int, point: Vector2) -> void:
	# Native GUI buttons handle touches in the right-hand mode panel.
	if _modes_rect.has_point(point):
		return
	super._handle_press(pointer, point)


func _draw_fraction_card(rect: Rect2, numerator: String, denominator: int, tint: Color) -> void:
	var number_h: float = rect.size.y * 0.43
	var top: Rect2 = Rect2(rect.position + Vector2(3.0, rect.size.y * 0.025), Vector2(rect.size.x - 6.0, number_h))
	var bottom: Rect2 = Rect2(rect.position + Vector2(3.0, rect.size.y * 0.55), Vector2(rect.size.x - 6.0, number_h))
	_print_center(numerator, top, minf(rect.size.y * 0.42, 42.0), tint)
	var line_y: float = rect.position.y + rect.size.y * 0.50
	draw_line(Vector2(rect.position.x + rect.size.x * 0.19, line_y), Vector2(rect.end.x - rect.size.x * 0.19, line_y), CYAN, maxf(2.0, rect.size.y * 0.026), true)
	_print_center(str(denominator), bottom, minf(rect.size.y * 0.42, 42.0), TEXT)


func _draw() -> void:
	if _expression_rects.size() != 5 or _options.size() != 5:
		return
	# SPACE_SKY supplies exactly the native real-space background. No blue film.
	_box(_stage, Color(0,0,0,0), CYAN, 26, 3)
	_box(_modes_rect, Color(0.01, 0.055, 0.12, 0.56), Color("507a94"), 20, 2)
	var caption: Rect2 = Rect2(_modes_rect.position.x + 8.0, _modes_rect.position.y + 5.0, _modes_rect.size.x - 16.0, clampf(_stage.size.y * 0.077, 16.0, 29.0))
	_print_center(str(MODE_CAPTIONS.get(_locale, MODE_CAPTIONS["en"])), caption, 18.0, MUTED)

	var prompt_rect := Rect2(_stage.position.x + 15.0, _stage.position.y + _stage.size.y * 0.12, maxf(80.0, _modes_rect.position.x - _stage.position.x - 30.0), clampf(_stage.size.y * 0.068, 16.0, 34.0))
	_print_center(_t("tap"), prompt_rect, minf(19.0, _stage.size.y * 0.055), MUTED)

	for i in range(5):
		var rect: Rect2 = _expression_rects[i]
		var unknown: bool = i == _missing_index
		var edge: Color = MINT if _correct_lock and unknown else (GOLD if unknown else BORDER)
		var fill: Color = Color(0.08,0.20,0.30,0.93) if unknown else Color(0.035,0.095,0.17,0.85)
		_box(rect, fill, edge, 17, 3 if unknown else 2)
		var val: String = _correct_answer if _correct_lock and unknown else ("?" if unknown else _equation[i])
		var tint: Color = MINT if _correct_lock and unknown else (GOLD if unknown else TEXT)
		if _mode == 2 and i in [0, 2, 4]:
			_draw_fraction_card(rect, val, _denominator, tint)
		else:
			_print_center(val, rect, minf(63.0, rect.size.y * 0.77), tint)

	var choose_rect := Rect2(_stage.position.x + 16.0, _choice_rects[0].position.y - clampf(_stage.size.y * 0.105, 21.0, 56.0), _stage.size.x - 32.0, clampf(_stage.size.y * 0.064, 19.0, 32.0))
	_print_center(_feedback if _feedback_time > 0.0 else _t("choose"), choose_rect, 23.0, _feedback_color if _feedback_time > 0.0 else MUTED)
	for i in range(5):
		var rect: Rect2 = _choice_rects[i]
		var selected: bool = i == _selected
		var correct: bool = _correct_lock and _options[i] == _correct_answer
		var accent: Color = MINT if correct else (GOLD if selected else Color("4c87a9"))
		_box(rect, Color(0.03,0.105,0.19,0.94) if not selected else Color(0.15,0.31,0.41,0.97), accent, 19, 3 if selected else 2)
		_print_center(_options[i], rect, minf(50.0, rect.size.y * 0.70), TEXT)
	if _dragging and _selected >= 0 and not _correct_lock:
		var card_w: float = _choice_rects[_selected].size.x
		var card_h: float = _choice_rects[_selected].size.y
		var ghost: Rect2 = Rect2(_pointer_at - Vector2(card_w,card_h) * 0.5, Vector2(card_w,card_h))
		_box(ghost, Color(0.07,0.18,0.30,0.95), GOLD, 17, 3)
		_print_center(_options[_selected], ghost, minf(50.0,card_h * 0.7), TEXT)
