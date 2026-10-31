extends Control
## v60: full-height chat in the RIGHT HALF of the screen.
## Upper half is message history; lower half is a genuine six-layout, on-screen
## keyboard. Free input is always allowed; bright keys suggest sample answers.
signal message_sent(phrase: String)
signal progress_changed(character_count: int)

const LANGUAGES: Array[String] = ["ru", "en", "fr", "de", "es", "pt_BR"]
const LANGUAGE_NAMES: Dictionary = {"ru":"РУС", "en":"ENG", "fr":"FRA", "de":"DEU", "es":"ESP", "pt_BR":"POR"}
const GREETINGS: Dictionary = {"ru":"Привет!", "en":"Hello!", "fr":"Bonjour !", "de":"Hallo!", "es":"¡Hola!", "pt_BR":"Olá!"}
# v60: localized response to a wrong answer. An incorrect answer must not
# advance the current exercise or silently accept arbitrary text.
const NOT_UNDERSTOOD: Dictionary = {
	"ru": "Я тебя не понимаю. Повтори.",
	"en": "I don't understand you. Please try again.",
	"fr": "Je ne te comprends pas. Répète, s'il te plaît.",
	"de": "Ich verstehe dich nicht. Wiederhole bitte.",
	"es": "No te entiendo. Repítelo, por favor.",
	"pt_BR": "Não entendo você. Repita, por favor."
}
const COLOR_SAMPLES: Dictionary = {"ru":"голубой", "en":"light blue", "fr":"bleu clair", "de":"hellblau", "es":"azul claro", "pt_BR":"azul-claro"}
const KEYBOARD_ROWS: Dictionary = {
	"ru": ["йцукенгшщзх", "фывапролджэ", "ячсмитьбюё"],
	"en": ["qwertyuiop", "asdfghjkl", "zxcvbnm"],
	"fr": ["azertyuiop", "qsdfghjklm", "wxcvbnéèàù"],
	"de": ["qwertzuiopü", "asdfghjklöä", "yxcvbnmß"],
	"es": ["qwertyuiop", "asdfghjklñ", "zxcvbnmáéíóú"],
	"pt_BR": ["qwertyuiop", "asdfghjklç", "zxcvbnmáéíóú"]
}
const NUMBER_ROWS: Array[String] = ["1234567890", "-/:;()$&@\"", ".,?!'+=%#*", ""]
const PHRASES: Dictionary = {
	"ru": {"send":"➤", "reset":"Заново", "space":"пробел", "letters":"АБВ", "numbers":"123", "hint":"Подсказка:", "typing":"печатает…", "you":"Ты", "done":"Спасибо! Теперь мы знакомы.", "ask":"Расскажи мне о себе!", "free":"Можешь написать любой ответ"},
	"en": {"send":"➤", "reset":"Restart", "space":"space", "letters":"ABC", "numbers":"123", "hint":"Try:", "typing":"typing…", "you":"You", "done":"Thank you! Nice to meet you.", "ask":"Tell me about yourself!", "free":"You may write any answer"},
	"fr": {"send":"➤", "reset":"Recommencer", "space":"espace", "letters":"ABC", "numbers":"123", "hint":"Essaie :", "typing":"écrit…", "you":"Toi", "done":"Merci ! Enchanté.", "ask":"Parle-moi de toi !", "free":"Tu peux écrire ce que tu veux"},
	"de": {"send":"➤", "reset":"Neu", "space":"Leer", "letters":"ABC", "numbers":"123", "hint":"Tipp:", "typing":"schreibt…", "you":"Du", "done":"Danke! Schön, dich kennenzulernen.", "ask":"Erzähl mir von dir!", "free":"Du kannst frei antworten"},
	"es": {"send":"➤", "reset":"Reiniciar", "space":"espacio", "letters":"ABC", "numbers":"123", "hint":"Pista:", "typing":"escribiendo…", "you":"Tú", "done":"¡Gracias! Encantado.", "ask":"¡Cuéntame sobre ti!", "free":"Puedes escribir libremente"},
	"pt_BR": {"send":"➤", "reset":"Reiniciar", "space":"espaço", "letters":"ABC", "numbers":"123", "hint":"Dica:", "typing":"digitando…", "you":"Você", "done":"Obrigado! Prazer em conhecer você.", "ask":"Conte um pouco sobre você!", "free":"Pode escrever livremente"}
}

var _chat_scroll: ScrollContainer
var _chat_messages: VBoxContainer
var _input: LineEdit
var _send_button: Button
var _hint: Label
var _typing_indicator: Label
var _locale_buttons: Array[Button] = []
var _key_rows: Array[HBoxContainer] = []
var _keyboard_buttons: Array[Button] = []
var _row_containers: Array[HBoxContainer] = []
var _keyboard: Control
var _keyboard_mode: String = "letters"
var _shift: bool = false
var _locale: String = "ru"
var _turn: int = 0
var _pending_text: String = ""
var _typing_seconds: float = 0.0
var _profile: Dictionary = {}
var _questions: Array = []
var _ready_ui: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	var loc: Node = get_node_or_null("/root/MobileLocale")
	_locale = str(loc.get("language")) if loc != null else "ru"
	if not LANGUAGES.has(_locale):
		_locale = "en"
	var db: Node = get_node_or_null("/root/ChildProfileStore")
	if db != null:
		_profile = db.get("profile")
		_questions = db.call("get_questions")
	if _profile.is_empty():
		_profile = {"name":"Алися", "age":3, "favorite_color":"голубой"}
	_ready_ui = true
	resized.connect(_relayout)
	reset_exercise()
	_relayout()

func _build_ui() -> void:
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.name = "ChatHistory"
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_chat_scroll.clip_contents = true
	_chat_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_chat_scroll)
	_chat_messages = VBoxContainer.new()
	_chat_messages.name = "Messages"
	_chat_messages.add_theme_constant_override("separation", 10)
	_chat_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_scroll.add_child(_chat_messages)
	_typing_indicator = Label.new()
	_typing_indicator.name = "RepresentativeTyping"
	_typing_indicator.add_theme_color_override("font_color", Color("8ed4f9"))
	_typing_indicator.add_theme_font_size_override("font_size", 17)
	_typing_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_typing_indicator)
	_input = LineEdit.new()
	_input.name = "FreeTextEntry"
	_input.placeholder_text = "Напиши сообщение…"
	_input.max_length = 160
	_input.virtual_keyboard_enabled = false
	_input.add_theme_font_size_override("font_size", 21)
	_input.add_theme_color_override("font_color", Color("eaf8ff"))
	_input.text_changed.connect(_on_text_changed)
	_input.text_submitted.connect(func(_v: String): _on_send())
	var field_style := StyleBoxFlat.new()
	field_style.bg_color = Color("10243b")
	field_style.border_color = Color("4599cb")
	field_style.set_border_width_all(1)
	field_style.set_corner_radius_all(12)
	field_style.set_content_margin_all(12)
	_input.add_theme_stylebox_override("normal", field_style)
	_input.add_theme_stylebox_override("focus", field_style)
	add_child(_input)
	_send_button = _make_key("SendMessage", "➤")
	_send_button.add_theme_color_override("font_color", Color.WHITE)
	_send_button.pressed.connect(_on_send)
	add_child(_send_button)
	_hint = Label.new()
	_hint.name = "SuggestedAnswer"
	_hint.add_theme_color_override("font_color", Color("f7d894"))
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.clip_text = true
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_keyboard = Control.new()
	_keyboard.name = "SixLanguageKeyboard"
	_keyboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_keyboard)
	for lang in LANGUAGES:
		var lang_button: Button = _make_key("Language_" + lang, str(LANGUAGE_NAMES[lang]))
		lang_button.pressed.connect(_change_language.bind(lang))
		_keyboard.add_child(lang_button)
		_locale_buttons.append(lang_button)
	for i in range(4):
		var row := HBoxContainer.new()
		row.name = "KeysRow_%d" % i
		row.add_theme_constant_override("separation", 4)
		_keyboard.add_child(row)
		_row_containers.append(row)
	_rebuild_keyboard()

func _make_key(node_name: String, key_label: String) -> Button:
	var b: Button = Button.new()
	b.name = node_name
	b.text = key_label
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color("e8f5ff"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("244564")
	style.border_color = Color("3a6f99")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	b.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("37688c")
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func _rebuild_keyboard() -> void:
	for row in _row_containers:
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
	_keyboard_buttons.clear()
	var rows: Array = NUMBER_ROWS if _keyboard_mode == "numbers" else KEYBOARD_ROWS[_locale]
	for i in range(3):
		var sequence: String = str(rows[i])
		for j in range(sequence.length()):
			var character: String = sequence.substr(j, 1)
			var display: String = character.to_upper() if _shift else character
			var b: Button = _make_key("Key_%d_%d" % [i,j], display)
			b.pressed.connect(_on_key.bind(display))
			_row_containers[i].add_child(b)
			_keyboard_buttons.append(b)
	var controls: Array[String] = ["123" if _keyboard_mode == "letters" else str(_labels().get("letters", "ABC")), "⇧", ",", " ", ".", "⌫"]
	for c in controls:
		var b: Button = _make_key("Control_" + str(c.unicode_at(0)), c)
		b.pressed.connect(_on_key.bind(c))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if c == " ":
			b.size_flags_stretch_ratio = 4.0
			b.text = str(PHRASES.get(_locale, PHRASES["ru"]).get("space"))
		_row_containers[3].add_child(b)
		_keyboard_buttons.append(b)
	_relayout()
	_refresh_hint()

func _change_language(lang: String) -> void:
	_locale = lang
	_keyboard_mode = "letters"
	_shift = false
	_rebuild_keyboard()
	_refresh_hint()

func _on_key(c: String) -> void:
	match c:
		"123", "АБВ", "ABC":
			_keyboard_mode = "numbers" if _keyboard_mode == "letters" else "letters"
			_rebuild_keyboard()
			return
		"⇧":
			_shift = not _shift
			_rebuild_keyboard()
			return
		"⌫":
			var pos: int = _input.caret_column
			if pos > 0:
				_input.text = _input.text.substr(0, pos - 1) + _input.text.substr(pos)
				_input.caret_column = pos - 1
		" ":
			_insert_at_cursor(" ")
		_:
			_insert_at_cursor(c)
	_refresh_hint()

func _insert_at_cursor(character: String) -> void:
	var pos: int = _input.caret_column
	_input.text = _input.text.substr(0, pos) + character + _input.text.substr(pos)
	_input.caret_column = pos + character.length()

func _on_text_changed(_content: String) -> void:
	_refresh_hint()

func _labels() -> Dictionary:
	return PHRASES.get(_locale, PHRASES["en"])

func _sample_answer() -> String:
	match _turn:
		0:
			return str(GREETINGS.get(_locale, GREETINGS["en"])).trim_suffix("!").trim_prefix("¡")
		1:
			var store: Node = get_node_or_null("/root/ChildProfileStore")
			if store != null and store.has_method("get_display_name"):
				return str(store.call("get_display_name", _locale))
			return str(_profile.get("name_cyrillic" if _locale == "ru" else "name_latin", "Алися" if _locale == "ru" else "Alisya"))
		2:
			return str(_profile.get("age", 3))
		3:
			return str(COLOR_SAMPLES.get(_locale, "голубой"))
	return ""

func _refresh_hint() -> void:
	if _hint == null:
		return
	var target: String = _sample_answer()
	_hint.text = (str(_labels().get("hint")) + " " + target) if not target.is_empty() else str(_labels().get("free"))
	var entered: String = _input.text.to_lower()
	var hint_word: String = target.to_lower()
	var next_letter: String = hint_word.substr(entered.length(), 1) if hint_word.begins_with(entered) and entered.length() < hint_word.length() else ""
	for button in _keyboard_buttons:
		var old: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
		if old == null:
			continue
		old.bg_color = Color("ab7327") if button.text.to_lower() == next_letter and not next_letter.is_empty() else Color("244564")
		button.add_theme_stylebox_override("normal", old)
	progress_changed.emit(entered.length())

func _add_message(text: String, from_child: bool) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if from_child:
		row.add_child(spacer)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("175b8e") if from_child else Color("243b55")
	style.set_corner_radius_all(13)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.custom_minimum_size.x = maxf(130.0, size.x * 0.65)
	panel.add_child(label)
	row.add_child(panel)
	if not from_child:
		row.add_child(spacer)
	_chat_messages.add_child(row)
	_chat_scroll.call_deferred("set", "scroll_vertical", 999999)

func reset_exercise() -> void:
	_turn = 0
	_typing_seconds = 0.0
	_pending_text = ""
	_input.text = ""
	for node in _chat_messages.get_children():
		_chat_messages.remove_child(node)
		node.queue_free()
	_queue_npc(str(GREETINGS.get(_locale, GREETINGS["en"])))
	_refresh_hint()

func _queue_npc(message: String) -> void:
	_pending_text = message
	_typing_seconds = 0.9 + minf(float(message.length()) * 0.025, 1.1)
	_typing_indicator.text = "● ● ●   " + str(_labels().get("typing"))
	_send_button.disabled = true

func _process(delta: float) -> void:
	if _typing_seconds <= 0.0:
		return
	_typing_seconds -= delta
	if _typing_seconds <= 0.0:
		_add_message(_pending_text, false)
		_pending_text = ""
		_typing_indicator.text = ""
		_send_button.disabled = false

# Only a known answer to the current prompt advances the scripted exercise.
# Normalization tolerates case, punctuation and repeated spaces. Children may
# still type ANY text; unrecognized answers receive a friendly immediate reply.
func _normalize_answer(value: String) -> String:
	var normalized: String = value.to_lower().strip_edges()
	for mark in ["!", "?", ".", ",", ";", ":", "¡", "¿", "…", "«", "»", "'"]:
		normalized = normalized.replace(mark, "")
	while normalized.contains("  "):
		normalized = normalized.replace("  ", " ")
	return normalized.strip_edges()


func _answer_matches_expected(answer: String) -> bool:
	# Conversation can become free-form after the initial four prompts.
	if _turn >= 4:
		return true
	var typed: String = _normalize_answer(answer)
	var expected: String = _normalize_answer(_sample_answer())
	if typed.is_empty():
		return false
	if typed == expected:
		return true
	match _turn:
		0:
			# Greetings in any of the six languages are meaningful.
			for greeting in GREETINGS.values():
				if typed == _normalize_answer(str(greeting)):
					return true
		1:
			# The same name may be typed in Cyrillic or Latin in ANY locale.
			# Proper names are transliterated, not translated into six names.
			var names: Array[String] = [
				str(_profile.get("name_cyrillic", "Алися")),
				str(_profile.get("name_latin", "Alisya"))
			]
			for candidate in names:
				var normalized_candidate: String = _normalize_answer(candidate)
				if typed == normalized_candidate:
					return true
				for prefix in ["меня зовут ", "my name is ", "je m'appelle ", "ich heiße ", "me llamo ", "meu nome é "]:
					if typed == _normalize_answer(prefix + normalized_candidate):
						return true
		2:
			# Accept a bare number or a simple age phrase, but not another age.
			for form in ["мне %s", "%s года", "%s лет", "i am %s", "%s years old", "tengo %s años", "tenho %s anos", "j'ai %s ans", "ich bin %s"]:
				if typed == _normalize_answer(form % expected):
					return true
		3:
			# The saved child's preferred colour is also a valid answer.
			return typed == _normalize_answer(str(_profile.get("favorite_color", "голубой")))
	return false


func _on_send() -> void:
	var text: String = _input.text.strip_edges()
	if text.is_empty() or _typing_seconds > 0.0:
		return
	_add_message(text, true)
	message_sent.emit(text)
	_input.text = ""
	if not _answer_matches_expected(text):
		# Reply immediately; do not proceed to the next question.
		_add_message(str(NOT_UNDERSTOOD.get(_locale, NOT_UNDERSTOOD["ru"])), false)
		_refresh_hint()
		return
	_turn += 1
	if _turn >= 4:
		_queue_npc(str(_labels().get("done")))
	else:
		var field: Dictionary = _questions[_turn - 1] if _turn - 1 < _questions.size() else {}
		_queue_npc(str(field.get(_locale, field.get("ru", str(_labels().get("ask"))))))
	_refresh_hint()

func _relayout() -> void:
	if not _ready_ui or size.x < 100 or size.y < 100:
		return
	var w: float = size.x
	var h: float = size.y
	var padding: float = maxf(7.0, h * 0.017)
	_chat_scroll.position = Vector2(padding, padding)
	_chat_scroll.size = Vector2(w - padding * 2.0, h * 0.475 - padding)
	_chat_messages.custom_minimum_size.x = _chat_scroll.size.x - 6
	_typing_indicator.position = Vector2(padding + 10, h * 0.445)
	_typing_indicator.size = Vector2(w - padding * 2, h * 0.04)
	var input_y: float = h * 0.495
	_input.position = Vector2(padding, input_y)
	_input.size = Vector2(w - padding * 3 - maxf(54.0, w * 0.105), h * 0.067)
	_send_button.position = Vector2(_input.position.x + _input.size.x + padding, input_y)
	_send_button.size = Vector2(w - (_input.position.x + _input.size.x + padding) - padding, _input.size.y)
	_hint.position = Vector2(padding + 3, h * 0.565)
	_hint.size = Vector2(w - 2 * padding, h * 0.037)
	_keyboard.position = Vector2(padding, h * 0.607)
	_keyboard.size = Vector2(w - 2 * padding, h * 0.385)
	var locale_width: float = (_keyboard.size.x - 5.0 * 4.0) / 6.0
	var locale_height: float = _keyboard.size.y * 0.12
	for i in range(_locale_buttons.size()):
		var button: Button = _locale_buttons[i]
		button.position = Vector2(i * (locale_width + 4), 0)
		button.size = Vector2(locale_width, locale_height)
		button.add_theme_font_size_override("font_size", maxi(10, roundi(locale_height * 0.44)))
		var style: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
		style.bg_color = Color("187da9") if LANGUAGES[i] == _locale else Color("244564")
		button.add_theme_stylebox_override("normal", style)
	var rows_top: float = locale_height + 5
	var row_gap: float = maxf(3.0, h * 0.004)
	var row_h: float = (_keyboard.size.y - rows_top - 3.0 * row_gap) * 0.25
	for i in range(_row_containers.size()):
		var row: HBoxContainer = _row_containers[i]
		row.position = Vector2.ZERO + Vector2(0, rows_top + i * (row_h + row_gap))
		row.size = Vector2(_keyboard.size.x, row_h)
		for key in row.get_children():
			if key is Button:
				key.custom_minimum_size.x = 0.0
				key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				key.add_theme_font_size_override("font_size", maxi(13, roundi(row_h * 0.47)))
	queue_redraw()

func _draw() -> void:
	var panel: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(panel, Color("0a1e34"))
	draw_line(Vector2(0, 0), Vector2(0, size.y), Color("60bfe9"), 3, true)
	draw_line(Vector2(10, size.y * 0.485), Vector2(size.x - 10, size.y * 0.485), Color("326f98"), 2, true)
