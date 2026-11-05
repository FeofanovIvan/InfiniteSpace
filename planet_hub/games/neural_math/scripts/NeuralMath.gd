extends Control
## MIKA | Neural Math (Triangulum) | 3 graduated levels | 6 languages
## 2026 V2 teaching edition: gradual scaffolding, 3-stage hints, audio questions, review, six languages.

const BOARD_SCRIPT = preload("res://planet_hub/games/neural_math/scripts/NeuralBoard.gd")
const CORE = preload("res://planet_hub/games/neural_math/assets/star_core.png")
const CORRECT_SFX = preload("res://planet_hub/games/neural_math/audio/ui/correct.wav")
const WRONG_SFX = preload("res://planet_hub/games/neural_math/audio/ui/wrong.wav")
const LANGS := ["ru", "en", "pt", "es", "de", "fr"]
const NAMES := ["Русский", "English", "Português", "Español", "Deutsch", "Français"]
const BG := Color("#061320")
const PANEL := Color("#0d2137")
const PANEL2 := Color("#122b46")
const BORDER := Color("#335f7e")
const CYAN := Color("#82ddff")
const WHITE := Color("#edf7ff")
const MUTED := Color("#a2bfd6")
const MINT := Color("#7ff2c8")
const GOLD := Color("#ffe094")

var problems: Array = []
var words: Dictionary = {}
var hints: Dictionary = {}
var interface_locale := "en"
var learning_locale := "en"
var service: Node = null

var level := 0
var question_index := 0
var level_progress := [0,0,0]
var completed_levels := [false,false,false]
var scored_questions: Dictionary = {}
var score := 0
var best_score := 0
var answer_text := ""
var hint_step := 0
var solved := false
var mistakes := 0
var finish_all := false
# Deferred review: missed questions are revisited without extra points after the main eight.
var review_indices: Array[int] = []
var review_mode := false
var review_index := 0
var fx_clock := 0.0
var success_timer := 0.0

var title_label: Label
var subtitle_label: Label
var score_label: Label
var best_label: Label
var progress_label: Label
var prompt_label: Label
var stage_note: Label
var question_note: Label
var level_buttons: Array[Button] = []
var language_select: OptionButton
var board
var input_label: Label
var answer_label: Label
var feedback_label: Label
var hint_heading: Label
var hint_step_label: Label
var hint_caption: Label
var hint_hint_label: Label
var hint_bars: Array[Panel] = []
var hint_button: Button
var listen_button: Button
var hear_problem_button: Button
var next_button: Button
var check_button: Button
var restart_button: Button
var digit_buttons: Array[Button] = []
var speaker: AudioStreamPlayer
var sfx: AudioStreamPlayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_load_data()
	_load_locale()
	_build_ui()
	_apply_locale()
	_select_level(0)

func _load_data() -> void:
	var p = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/neural_math/data/problems.json"))
	var u = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/neural_math/data/ui.json"))
	var h = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/neural_math/data/hints.json"))
	if p is Array: problems = p
	if u is Dictionary: words = u
	if h is Dictionary: hints = h

func _load_locale() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://mika_neural_math.cfg") == OK:
		learning_locale = str(cfg.get_value("settings", "learning_locale", "en"))
	if not LANGS.has(learning_locale): learning_locale = "en"
	interface_locale = learning_locale
	service = get_node_or_null("/root/LanguageService")
	if service == null or (service.get("interface_locale") == null and service.get("learning_locale") == null):
		service = get_node_or_null("/root/MobileLocale")
	if service != null:
		_sync_service_locale()
		if service.has_signal("language_changed"):
			service.connect("language_changed", Callable(self, "_on_service_language_changed"))
	_load_best()

func _sync_service_locale() -> void:
	if service == null: return
	var ui_code: String = str(service.get("language")) if service.name == "MobileLocale" else str(service.get("interface_locale"))
	var game_code: String = str(service.get("language")) if service.name == "MobileLocale" else str(service.get("learning_locale"))
	ui_code = "pt" if ui_code == "pt_BR" else ui_code
	game_code = "pt" if game_code == "pt_BR" else game_code
	if LANGS.has(ui_code): interface_locale = ui_code
	if LANGS.has(game_code): learning_locale = game_code

func _on_service_language_changed(_lang: String) -> void:
	_sync_service_locale()
	_load_best()
	level_progress = [0,0,0]
	completed_levels = [false,false,false]
	review_mode = false
	review_indices.clear()
	review_index = 0
	scored_questions.clear()
	score = 0
	level = 0
	question_index = 0
	_apply_locale()
	_show_question()

func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://mika_neural_math.cfg") == OK:
		best_score = int(cfg.get_value("records", learning_locale, 0))
	else:
		best_score = 0

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://mika_neural_math.cfg")
	cfg.set_value("settings", "learning_locale", learning_locale)
	cfg.set_value("records", learning_locale, best_score)
	cfg.save("user://mika_neural_math.cfg")

func t(key: String) -> String:
	return str(words.get(interface_locale, {}).get(key, key))

func _label(text_value: String, font_size: int, color: Color, pos: Vector2, box_size: Vector2 = Vector2.ZERO, wrap_text: bool = false) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = pos
	if box_size != Vector2.ZERO: l.size = box_size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if wrap_text: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)
	return l

func _style(fill: Color, stroke: Color = BORDER, radius: int = 16, border_size: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = stroke
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_size)
	return sb

func _button(text_value: String, pos: Vector2, box_size: Vector2, font_size: int = 17, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.position = pos
	b.size = box_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color("#10273b") if primary else WHITE)
	b.add_theme_color_override("font_hover_color", WHITE)
	b.add_theme_color_override("font_disabled_color", Color("#6b8ba3"))
	b.add_theme_stylebox_override("normal", _style(CYAN if primary else PANEL2, CYAN if primary else BORDER, 15))
	b.add_theme_stylebox_override("hover", _style(Color("#3282a2") if primary else Color("#1c4666"), CYAN, 15))
	b.add_theme_stylebox_override("pressed", _style(Color("#2f668c"), GOLD, 15))
	b.add_theme_stylebox_override("disabled", _style(Color("#142537"), Color("#273e53"), 15))
	add_child(b)
	return b

func _build_ui() -> void:
	title_label = _label("", 30, WHITE, Vector2(35, 14), Vector2(800,42))
	subtitle_label = _label("", 14, CYAN, Vector2(37, 51), Vector2(680,26))
	score_label = _label("", 21, GOLD, Vector2(935, 13), Vector2(190,32))
	best_label = _label("", 15, MUTED, Vector2(936, 49), Vector2(155,24))
	language_select = OptionButton.new()
	language_select.position = Vector2(1095, 44)
	language_select.size = Vector2(148, 38)
	language_select.focus_mode = Control.FOCUS_NONE
	language_select.add_theme_font_size_override("font_size", 14)
	language_select.add_theme_color_override("font_color", WHITE)
	language_select.add_theme_stylebox_override("normal", _style(PANEL2, BORDER, 12))
	for n in NAMES: language_select.add_item(n)
	language_select.item_selected.connect(_on_language_selected)
	add_child(language_select)
	if service != null: language_select.visible = false
	
	for i in range(3):
		var btn := _button("", Vector2(34.0 + i * 284.0, 91.0), Vector2(275,43), 14)
		btn.pressed.connect(_on_level_pressed.bind(i))
		level_buttons.append(btn)
	
	restart_button = _button("", Vector2(889,91), Vector2(354,43), 14)
	restart_button.pressed.connect(_restart_game)
	
	progress_label = _label("", 14, MINT, Vector2(56,154), Vector2(300,22))
	stage_note = _label("", 14, MUTED, Vector2(358,154), Vector2(490,24))
	board = Control.new()
	board.set_script(BOARD_SCRIPT)
	board.position = Vector2(47,184)
	board.size = Vector2(808,337)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)
	
	input_label = _label("", 14, CYAN, Vector2(53,557), Vector2(700,22))
	answer_label = _label("?", 32, WHITE, Vector2(52,597), Vector2(115,62))
	answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	answer_label.add_theme_stylebox_override("normal", _style(Color("#17314b"), CYAN, 16))
	answer_label.add_theme_font_size_override("font_size", 32)
	
	for n in range(10):
		var digit: Button = _button(str(n), Vector2(181.0 + n * 46.0, 600), Vector2(41,53), 22)
		digit.pressed.connect(_append_digit.bind(n))
		digit_buttons.append(digit)
	var back_button := _button("⌫", Vector2(643,600), Vector2(57,53), 21)
	back_button.pressed.connect(_backspace)
	check_button = _button("", Vector2(709,600), Vector2(146,53), 16, true)
	check_button.pressed.connect(_check_answer)
	feedback_label = _label("", 15, MINT, Vector2(54,665), Vector2(790,25))
	
	hint_heading = _label("", 21, CYAN, Vector2(907,167), Vector2(306,32))
	hint_step_label = _label("", 16, GOLD, Vector2(907,213), Vector2(305,26))
	for i in range(3):
		var segment := Panel.new()
		segment.position = Vector2(906 + i * 108, 252)
		segment.size = Vector2(100,10)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(segment)
		hint_bars.append(segment)
	hint_caption = _label("", 16, WHITE, Vector2(906,280), Vector2(309,57), true)
	hint_hint_label = _label("", 16, MUTED, Vector2(905,348), Vector2(309,163), true)
	hint_button = _button("", Vector2(902, 519), Vector2(321,47), 17, true)
	hint_button.pressed.connect(_next_hint)
	listen_button = _button("", Vector2(902, 574), Vector2(321,44), 16)
	listen_button.pressed.connect(_replay_audio)
	hear_problem_button = _button("", Vector2(902, 628), Vector2(321,44), 15)
	hear_problem_button.pressed.connect(_play_problem_audio)
	
	# Audio player is separate from the visual animation so hints can be replayed.
	speaker = AudioStreamPlayer.new()
	speaker.volume_db = -1.0
	add_child(speaker)
	sfx = AudioStreamPlayer.new()
	sfx.volume_db = -9.0
	add_child(sfx)
	
	# Next appears only after a correct answer.
	next_button = _button("", Vector2(709,600), Vector2(146,53), 16, true)
	next_button.pressed.connect(_next_question)
	next_button.visible = false

func _on_language_selected(index: int) -> void:
	if service != null: return
	if index < 0 or index >= LANGS.size(): return
	interface_locale = LANGS[index]
	learning_locale = LANGS[index]
	_load_best()
	_save_settings()
	level_progress = [0,0,0]
	completed_levels = [false,false,false]
	review_mode = false
	review_indices.clear()
	review_index = 0
	scored_questions.clear()
	score = 0
	level = 0
	question_index = 0
	_apply_locale()
	_show_question()

func _apply_locale() -> void:
	if words.is_empty(): return
	title_label.text = t("title")
	subtitle_label.text = t("subtitle")
	restart_button.text = t("new_game")
	for i in range(level_buttons.size()):
		level_buttons[i].text = str(words[interface_locale]["stages"][i])
	input_label.text = t("answer")
	check_button.text = t("check")
	next_button.text = t("next")
	hint_heading.text = t("voice_label")
	hint_button.text = t("hint")
	listen_button.text = t("listen")
	hear_problem_button.text = t("listen_problem")
	hint_caption.text = t("help_tip")
	if service == null:
		var idx := LANGS.find(learning_locale)
		if idx >= 0: language_select.select(idx)
	_refresh_top()

func _refresh_top() -> void:
	score_label.text = "%s: %d" % [t("score"),score]
	best_label.text = "%s: %d" % [t("best"),best_score]
	if review_mode:
		progress_label.text = "%s %d / %d" % [t("review"), review_index + 1, review_indices.size()]
		stage_note.text = t("replay")
	else:
		progress_label.text = "%s %d / 8" % [t("progress"), question_index + 1]
		if question_index < 2:
			stage_note.text = t("guided")
		elif question_index < 5:
			stage_note.text = t("practice")
		else:
			stage_note.text = t("independent")
	for i in range(level_buttons.size()):
		var b: Button = level_buttons[i]
		b.disabled = i > 0 and not bool(completed_levels[i-1])
		if i == level:
			b.add_theme_stylebox_override("normal", _style(Color("#205c79"), CYAN, 15))
		else:
			b.add_theme_stylebox_override("normal", _style(PANEL2, BORDER, 15))

func _on_level_pressed(idx: int) -> void:
	if idx > 0 and not bool(completed_levels[idx-1]):
		feedback_label.text = t("stage_locked")
		return
	_select_level(idx)

func _select_level(idx: int) -> void:
	if idx < 0 or idx > 2: return
	speaker.stop()
	review_mode = false
	review_indices.clear()
	review_index = 0
	level = idx
	question_index = min(int(level_progress[level]), 7)
	finish_all = false
	_show_question()

func _current() -> Dictionary:
	var idx: int = review_indices[review_index] if review_mode and review_indices.size() > 0 else clampi(question_index,0,7)
	return problems[level * 8 + idx]

func _show_question() -> void:
	if problems.size() < 24: return
	speaker.stop()
	solved = (not review_mode) and int(level_progress[level]) > question_index
	answer_text = ""
	hint_step = 0
	mistakes = 0
	success_timer = 0.0
	board.set_exercise(_current(),0,solved)
	feedback_label.text = t("intro") if not solved else t("correct")
	_hint_text()
	_update_input()
	_refresh_top()
	check_button.visible = not solved
	next_button.visible = solved
	hint_button.disabled = solved
	listen_button.disabled = solved

func _update_input() -> void:
	answer_label.text = answer_text if not answer_text.is_empty() else "?"

func _append_digit(n: int) -> void:
	if solved: return
	if answer_text.length() >= 2: return
	if answer_text == "0": answer_text = ""
	answer_text += str(n)
	_update_input()

func _backspace() -> void:
	if solved: return
	if answer_text.length() > 0: answer_text = answer_text.substr(0,answer_text.length()-1)
	_update_input()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null: return
	if not key.pressed or key.echo: return
	if key.unicode >= 48 and key.unicode <= 57:
		_append_digit(int(key.unicode)-48)
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_BACKSPACE:
		_backspace()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		if solved: _next_question()
		else: _check_answer()
		get_viewport().set_input_as_handled()

func _check_answer() -> void:
	if solved: return
	if answer_text.is_empty():
		feedback_label.text = t("enter")
		return
	var q := _current()
	if int(answer_text) == int(q["answer"]):
		solved = true
		if not review_mode and not scored_questions.has(str(q["id"])):
			scored_questions[str(q["id"])] = true
			score += 10
			if question_index == 7: score += 20
		if not review_mode:
			level_progress[level] = max(int(level_progress[level]), question_index + 1)
		best_score = max(score,best_score)
		_save_settings()
		feedback_label.text = t("correct") if review_mode or question_index < 7 else t("finished")
		board.set_exercise(q,hint_step,true)
		_play_effect(CORRECT_SFX)
		success_timer = 1.0
		check_button.visible = false
		next_button.visible = true
		hint_button.disabled = true
		listen_button.disabled = true
	else:
		mistakes += 1
		if not review_mode and not review_indices.has(question_index):
			review_indices.append(question_index)
		var fix_key := "fix_frac" if level == 2 else ("fix_add" if str(q["op"]) == "+" else ("fix_sub" if str(q["op"]) == "-" else ("fix_mul" if str(q["op"]) == "×" else "fix_div")))
		feedback_label.text = t("wrong") + " " + t(fix_key) if mistakes == 1 else t("offer_hint")
		if mistakes >= 2 and hint_step < 1:
			hint_step = 1
			_hint_text()
		_play_effect(WRONG_SFX)
		answer_text = ""
		_update_input()
	_refresh_top()

func _next_question() -> void:
	if not solved: return
	if review_mode:
		if review_index + 1 < review_indices.size():
			review_index += 1
			_show_question()
		else:
			_complete_level()
	elif question_index < 7:
		question_index += 1
		_show_question()
	elif not review_indices.is_empty():
		review_mode = true
		review_index = 0
		_show_question()
	else:
		_complete_level()

func _complete_level() -> void:
	completed_levels[level] = true
	if level < 2:
		_select_level(level + 1)
	else:
		finish_all = true
		feedback_label.text = t("complete")
		next_button.visible = false
		check_button.visible = false
		hint_button.disabled = true
		listen_button.disabled = true

func _restart_game() -> void:
	speaker.stop()
	level_progress = [0,0,0]
	completed_levels = [false,false,false]
	review_mode = false
	review_indices.clear()
	review_index = 0
	scored_questions.clear()
	score = 0
	finish_all = false
	_select_level(0)

func _hint_text() -> void:
	for i in range(hint_bars.size()):
		hint_bars[i].add_theme_stylebox_override("panel", _style(MINT if i < hint_step else Color("#19374d"), MINT if i < hint_step else BORDER, 5, 1))
	if hint_step == 0:
		hint_step_label.text = t("hint0")
		hint_hint_label.text = t("number_note") if level < 2 else t("fraction_note")
	else:
		hint_step_label.text = "%s %d / 3" % [t("step"),hint_step]
		var localized: Array = hints.get(learning_locale, {}).get(str(_current()["id"]), [])
		hint_hint_label.text = str(localized[hint_step-1]) if localized.size() >= hint_step else ""
	listen_button.disabled = hint_step <= 0 or solved
	# A concrete picture is shown automatically only for two guided examples.
	# Later questions invite the child to request their own scaffold.
	var visible_step: int = 2 if not review_mode and question_index < 2 and not solved else hint_step
	board.set_exercise(_current(),maxi(hint_step,visible_step),solved)

func _next_hint() -> void:
	if solved: return
	if hint_step < 3: hint_step += 1
	_hint_text()
	_replay_audio()

func _play_problem_audio() -> void:
	if speaker == null: return
	var path: String = "res://planet_hub/games/neural_math/audio/problems/%s/%s.ogg" % [learning_locale,str(_current()["id"])]
	if ResourceLoader.exists(path):
		speaker.stop()
		speaker.stream = load(path)
		speaker.play()

func _replay_audio() -> void:
	if hint_step < 1: return
	var q := _current()
	var path: String = "res://planet_hub/games/neural_math/audio/hints/%s/%s_%d.ogg" % [learning_locale,str(q["id"]),hint_step]
	if ResourceLoader.exists(path):
		speaker.stop()
		speaker.stream = load(path)
		speaker.play()

func _play_effect(sound: AudioStream) -> void:
	if sound == null: return
	sfx.stop()
	sfx.stream = sound
	sfx.play()

func _process(delta: float) -> void:
	fx_clock += delta
	if success_timer > 0.0: success_timer = maxf(success_timer - delta, 0.0)
	queue_redraw()

func _panel(rect: Rect2, fill: Color, stroke: Color = BORDER, radius: int = 22) -> void:
	draw_style_box(_style(fill,stroke,radius),rect)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size), BG)
	# A tiny luminous geometry map gives the distinct Triangulum / neuron feeling.
	for i in range(125):
		var p := Vector2(float((i * 83 + 28) % 1280),float((i * 137 + 31) % 720))
		draw_circle(p,1.0 + float(i % 3) * 0.38,Color(0.75,0.90,1.0,0.18))
	for i in range(11):
		var pos := Vector2(120.0 + i*105.0, 650.0 + 9 * sin(float(i)*1.7))
		var npos := Vector2(120.0 + ((i+3)%11)*105.0, 615.0 + 7 * sin(float(i)*2.1))
		draw_line(pos,npos,Color(0.21,0.52,0.64,0.12),2)
		draw_circle(pos,4,Color(0.48,0.85,0.96,0.32))
	# Shared Mika interface
	_panel(Rect2(29,143,842,393), PANEL, Color("#375e7a"),26)
	_panel(Rect2(884,143,364,539), PANEL, Color("#375e7a"),26)
	_panel(Rect2(29,548,842,134), PANEL, Color("#375e7a"),26)
	draw_texture_rect(CORE,Rect2(854,4,74,74),false,Color(0.55,0.81,1.0,0.48))
	# Soft radial portal nodes in hint panel (background only)
	var hc := Vector2(1062,479)
	for i in range(6):
		var a := TAU * float(i) / 6.0 + fx_clock * 0.16
		var pt := hc + Vector2.from_angle(a) * 30
		draw_line(hc,pt,Color(0.39,0.76,0.91,0.20),2)
		draw_circle(pt,3.1,Color(0.56,0.88,1,0.35))
	if success_timer > 0.0:
		for i in range(18):
			var angle := TAU * float(i)/18.0
			var distance := 12.0 + (1.0-success_timer)*260.0
			var pt := Vector2(455,330) + Vector2.from_angle(angle)*distance
			draw_circle(pt,4.0*success_timer,MINT if i%2==0 else GOLD)
