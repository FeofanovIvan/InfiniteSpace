extends Control
const MIKA_VOICE_TABLET_UI: Script = preload("res://addons/mika_voice/MikaTabletVoiceUI.gd")
# v96: original visual tablet with new v93.2 intent engine; Try prompt moved left.
const DialogueEngine = preload("res://planet_hub/scripts/dialogue_engine.gd")
## v76: global locale on first build, touch chat scroll and brighter key guidance.
## v75: framed chat, space-pattern wallpaper, draggable prompt and global locale.
## v60: full-height chat in the RIGHT HALF of the screen.
## Upper half is message history; lower half is a genuine six-layout, on-screen
## keyboard. Free input is always allowed; bright keys suggest sample answers.
const CHAT_PATTERN: Texture2D = preload("res://planet_hub/assets/chat_space_pattern.png")
signal message_sent(phrase: String)
signal progress_changed(character_count: int)
signal suggestions_changed(options: Array)

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
const INPUT_PLACEHOLDERS: Dictionary = {
	"ru": "Напиши сообщение…",
	"en": "Type a message…",
	"fr": "Écris un message…",
	"de": "Schreibe eine Nachricht…",
	"es": "Escribe un mensaje…",
	"pt_BR": "Escreva uma mensagem…"
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
const V107_SYMBOL_ROWS: Array[String] = ["?!.,:;—", "¿¡()/@#+%&", "«»“”’'-_=+"]
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
var _message_input: LineEdit
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
var _v96_engine: RefCounted
var _v96_place_id: String = ""
var _v96_suggestions: Array[String] = []
var _v96_selected_index: int = 0
var _chat_drag_touch_id: int = -1
var _chat_mouse_dragging: bool = false
var _hint_dragging: bool = false
var _hint_y_ratio: float = 0.337

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	var loc: Node = get_node_or_null("/root/MobileLocale")
	_locale = str(loc.get("language")) if loc != null else "ru"
	if not LANGUAGES.has(_locale):
		_locale = "en"
	# The game-wide Settings screen owns language selection.
	if loc != null and loc.has_signal("language_changed"):
		loc.connect("language_changed", Callable(self, "_on_global_locale_changed"))
	var db: Node = get_node_or_null("/root/ChildProfileStore")
	if db != null:
		_profile = db.get("profile")
		_questions = db.call("get_questions")
	if _profile.is_empty():
		_profile = {"name":"Алися", "age":3, "favorite_color":"голубой"}
	_v96_engine = DialogueEngine.new()
	_ready_ui = true
	# v75 built the keyboard while _locale was still the Russian default.
	# Rebuild once after reading MobileLocale so English is English on entry.
	_rebuild_keyboard()
	resized.connect(_relayout)
	reset_exercise()
	_relayout()
	var mika_voice_runtime_ui: Node = MIKA_VOICE_TABLET_UI.new() as Node
	if mika_voice_runtime_ui != null:
		mika_voice_runtime_ui.name = "MikaVoiceUI"
		add_child(mika_voice_runtime_ui)

func _build_ui() -> void:
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.name = "ChatHistory"
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_chat_scroll.clip_contents = true
	_chat_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_chat_scroll.scroll_deadzone = 4
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
	_message_input = LineEdit.new()
	_message_input.name = "FreeTextEntry"
	_message_input.placeholder_text = "Напиши сообщение…"
	_message_input.max_length = 160
	_message_input.virtual_keyboard_enabled = false
	_message_input.add_theme_font_size_override("font_size", 21)
	_message_input.add_theme_color_override("font_color", Color("eaf8ff"))
	_message_input.text_changed.connect(_on_text_changed)
	_message_input.text_submitted.connect(func(_v: String): _on_send())
	var field_style := StyleBoxFlat.new()
	field_style.bg_color = Color("10243b")
	field_style.border_color = Color("4599cb")
	field_style.set_border_width_all(1)
	field_style.set_corner_radius_all(12)
	field_style.set_content_margin_all(12)
	_message_input.add_theme_stylebox_override("normal", field_style)
	_message_input.add_theme_stylebox_override("focus", field_style)
	add_child(_message_input)
	_send_button = _make_key("SendMessage", "➤")
	_send_button.add_theme_color_override("font_color", Color.WHITE)
	_send_button.pressed.connect(_on_send)
	add_child(_send_button)
	_hint = Label.new()
	_hint.name = "SuggestedAnswer"
	_hint.add_theme_color_override("font_color", Color("52f3ee"))
	_hint.add_theme_color_override("font_outline_color", Color("041834"))
	_hint.add_theme_constant_override("outline_size", 2)
	_hint.add_theme_font_size_override("font_size", 29)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.clip_text = true
	_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	_hint.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_hint.gui_input.connect(_on_hint_drag)
	_hint.visible = false
	add_child(_hint)
	_keyboard = Control.new()
	_keyboard.name = "SixLanguageKeyboard"
	_keyboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_keyboard)
	# No language-switch buttons here: MobileLocale updates this keyboard.
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
	var rows: Array = V107_SYMBOL_ROWS if _keyboard_mode == "symbols" else (NUMBER_ROWS if _keyboard_mode == "numbers" else KEYBOARD_ROWS[_locale])
	for i in range(3):
		var sequence: String = str(rows[i])
		for j in range(sequence.length()):
			var character: String = sequence.substr(j, 1)
			var display: String = character.to_upper() if _shift else character
			var b: Button = _make_key("Key_%d_%d" % [i,j], display)
			b.pressed.connect(_on_key.bind(display))
			_row_containers[i].add_child(b)
			_keyboard_buttons.append(b)
	var controls: Array[String] = ["123" if _keyboard_mode != "numbers" else str(_labels().get("letters", "ABC")), "?!" if _keyboard_mode != "symbols" else str(_labels().get("letters", "ABC")), "⇧", ",", " ", ".", "⌫"]
	for c in controls:
		var b: Button = _make_key("Control_" + str(c.unicode_at(0)), c)
		b.pressed.connect(_on_key.bind(c))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if c == " ":
			b.size_flags_stretch_ratio = 4.0
			b.text = str(PHRASES.get(_locale, PHRASES["ru"]).get("space"))
			b.add_theme_font_size_override("font_size", 17)
			b.add_theme_color_override("font_color", Color("f5fdff"))
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

func _on_global_locale_changed(lang: String) -> void:
	if not LANGUAGES.has(lang):
		return
	_locale = lang
	_keyboard_mode = "letters"
	_shift = false
	if _keyboard != null:
		_rebuild_keyboard()
	if _hint != null:
		_refresh_hint()
	if _ready_ui and not _v96_place_id.is_empty():
		reset_exercise()

func _input(event: InputEvent) -> void:
	# Mobile-first chat history dragging; desktop drag is supported for testing.
	if not visible or not _ready_ui or not is_instance_valid(_chat_scroll):
		_chat_drag_touch_id = -1
		_chat_mouse_dragging = false
		return
	if event is InputEventScreenTouch:
		if event.pressed and _chat_scroll.get_global_rect().has_point(event.position):
			_chat_drag_touch_id = event.index
		elif not event.pressed and event.index == _chat_drag_touch_id:
			_chat_drag_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _chat_drag_touch_id:
		_chat_scroll.scroll_vertical = maxi(0, _chat_scroll.scroll_vertical - roundi(event.relative.y))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_chat_mouse_dragging = event.pressed and _chat_scroll.get_global_rect().has_point(event.position)
	elif event is InputEventMouseMotion and _chat_mouse_dragging:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_chat_scroll.scroll_vertical = maxi(0, _chat_scroll.scroll_vertical - roundi(event.relative.y))
		else:
			_chat_mouse_dragging = false

func _on_hint_drag(event: InputEvent) -> void:
	# Constrain dragging to the teaching strip between bubbles and input.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_hint_dragging = event.pressed
	elif event is InputEventMouseMotion and _hint_dragging and size.y > 0.0:
		_hint_y_ratio = clampf(_hint_y_ratio + event.relative.y / size.y, 0.31, 0.375)
		_relayout()

func _on_key(c: String) -> void:
	match c:
		"123":
			_keyboard_mode = "numbers"
			_rebuild_keyboard()
			return
		"?!":
			_keyboard_mode = "letters" if _keyboard_mode == "symbols" else "symbols"
			_rebuild_keyboard()
			return
		"АБВ", "ABC":
			_keyboard_mode = "letters"
			_rebuild_keyboard()
			return
		"⇧":
			_shift = not _shift
			_rebuild_keyboard()
			return
		"⌫":
			var pos: int = _message_input.caret_column
			if pos > 0:
				_message_input.text = _message_input.text.substr(0, pos - 1) + _message_input.text.substr(pos)
				_message_input.caret_column = pos - 1
		" ":
			_insert_at_cursor(" ")
		_:
			_insert_at_cursor(c)
	_refresh_hint()

func _insert_at_cursor(character: String) -> void:
	var pos: int = _message_input.caret_column
	_message_input.text = _message_input.text.substr(0, pos) + character + _message_input.text.substr(pos)
	_message_input.caret_column = pos + character.length()
	var mika_voice_service: Node = get_node_or_null("/root/MikaVoice")
	if mika_voice_service != null and character.length() == 1:
		mika_voice_service.call("speak_key", character, _locale)

func _on_text_changed(_content: String) -> void:
	_refresh_hint()

func _labels() -> Dictionary:
	return PHRASES.get(_locale, PHRASES["en"])

func configure_for_world(world_id: String) -> void:
	_v96_place_id = world_id
	var loc: Node = get_node_or_null("/root/MobileLocale")
	if loc != null:
		var preferred: String = str(loc.get("language"))
		if LANGUAGES.has(preferred) and preferred != _locale:
			_locale = preferred
			_keyboard_mode = "letters"
			_shift = false
			_rebuild_keyboard()
	if _ready_ui:
		reset_exercise()


func get_suggestions() -> Array[String]:
	return _v96_suggestions.duplicate()


func get_language() -> String:
	return _locale


func select_suggestion(index: int) -> void:
	if index < 0 or index >= _v96_suggestions.size():
		return
	_v96_selected_index = index
	_refresh_hint()


func _v96_set_choices(options: Array) -> void:
	_v96_suggestions.clear()
	for phrase in options:
		_v96_suggestions.append(str(phrase))
	_v96_selected_index = 0
	suggestions_changed.emit(_v96_suggestions.duplicate())
	_refresh_hint()


func _sample_answer() -> String:
	if _v96_engine == null:
		return ""
	return str(_v96_engine.call("get_hint", _v96_selected_index))


func _refresh_hint() -> void:
	if _hint == null:
		return
	var target: String = _sample_answer()
	_hint.text = (str(_labels().get("hint")) + " " + target) if not target.is_empty() else str(_labels().get("free"))
	_message_input.placeholder_text = str(INPUT_PLACEHOLDERS.get(_locale, INPUT_PLACEHOLDERS["en"]))
	var entered: String = _message_input.text.to_lower()
	var hint_word: String = target.to_lower()
	var next_letter: String = hint_word.substr(entered.length(), 1) if hint_word.begins_with(entered) and entered.length() < hint_word.length() else ""
	for button in _keyboard_buttons:
		var old: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
		if old == null:
			continue
		var highlighted: bool = button.text.to_lower() == next_letter and not next_letter.is_empty()
		old.bg_color = Color("e4a335") if highlighted else Color("244564")
		old.border_color = Color("fff4ad") if highlighted else Color("3a6f99")
		old.set_border_width_all(2 if highlighted else 1)
		button.add_theme_stylebox_override("normal", old)
	progress_changed.emit(entered.length())
	_v107_refresh_send_button()
	_v1073_update_guidance()

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
	if not _ready_ui:
		return
	_typing_seconds = 0.0
	_pending_text = ""
	_message_input.text = ""
	_typing_indicator.text = ""
	_send_button.disabled = false
	for node in _chat_messages.get_children():
		_chat_messages.remove_child(node)
		node.queue_free()
	if _v96_engine == null:
		_v96_engine = DialogueEngine.new()
	if _v96_place_id.is_empty():
		_v96_set_choices([])
		return
	var store: Node = get_node_or_null("/root/ChildProfileStore")
	var starting: Dictionary = _v96_engine.call("begin", _v96_place_id, _locale, store)
	_v96_set_choices(starting.get("choices", []))
	if bool(starting.get("available", false)):
		_queue_npc(str(starting.get("npc", "")))
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
	var text: String = _message_input.text.strip_edges()
	if text.is_empty() or _typing_seconds > 0.0 or _v96_place_id.is_empty():
		return
	_add_message(text, true)
	message_sent.emit(text)
	_message_input.text = ""
	var outcome: Dictionary = _v96_engine.call("accept", text)
	if not bool(outcome.get("accepted", false)):
		_add_message(str(outcome.get("npc", NOT_UNDERSTOOD.get(_locale, NOT_UNDERSTOOD["en"]))), false)
		_refresh_hint()
		return
	_v96_set_choices(outcome.get("choices", []))
	_queue_npc(str(outcome.get("npc", "")))
	_refresh_hint()


func _relayout() -> void:
	if not _ready_ui or size.x < 100 or size.y < 100:
		return
	var w: float = size.x
	var h: float = size.y
	# All content sits inside the tablet rim; the frame is never a screen divider.
	var padding: float = clampf(w * 0.047, 17.0, 36.0)
	var content_w: float = w - 2.0 * padding
	_chat_scroll.position = Vector2(padding, h * 0.086)
	_chat_scroll.size = Vector2(content_w, h * 0.296)
	_chat_messages.custom_minimum_size.x = _chat_scroll.size.x - 6.0
	_typing_indicator.position = Vector2(padding + 8.0, h * 0.385)
	_typing_indicator.size = Vector2(content_w - 16.0, h * 0.037)
	# Large draggable learning prompt stays in view between conversation and input.
	_hint.position = Vector2(padding + 4.0, h * _hint_y_ratio)
	_hint.size = Vector2(content_w - 8.0, h * 0.079)
	_hint.add_theme_font_size_override("font_size", clampi(roundi(h * 0.041), 20, 35))
	var input_y: float = h * 0.455
	var send_w: float = clampf(content_w * 0.11, 48.0, 85.0)
	_message_input.position = Vector2(padding, input_y)
	_message_input.size = Vector2(content_w - send_w - 10.0, h * 0.075)
	_send_button.position = Vector2(padding + content_w - send_w, input_y)
	_send_button.size = Vector2(send_w, _message_input.size.y)
	_keyboard.position = Vector2(padding, h * 0.581)
	_keyboard.size = Vector2(content_w, h * 0.359)
	# The keyboard has no local language tabs. The four rows use the full space.
	var row_gap: float = maxf(4.0, h * 0.006)
	var row_h: float = (_keyboard.size.y - 3.0 * row_gap) * 0.25
	for i in range(_row_containers.size()):
		var row: HBoxContainer = _row_containers[i]
		row.position = Vector2(0.0, i * (row_h + row_gap))
		row.size = Vector2(_keyboard.size.x, row_h)
		for key in row.get_children():
			if key is Button:
				key.custom_minimum_size.x = 0.0
				key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				key.add_theme_font_size_override("font_size", maxi(13, roundi(row_h * 0.47)))
	queue_redraw()
	_v107_adjust_entry_send_layout()

func _draw() -> void:
	if size.x < 70.0 or size.y < 70.0:
		return
	var w: float = size.x
	var h: float = size.y
	var frame: Rect2 = Rect2(Vector2(9.0, 9.0), Vector2(w - 18.0, h - 18.0))
	# Double rim, rounded corners and illuminated hardware details.
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color("051733")
	outer.border_color = Color("16caff")
	outer.set_border_width_all(3)
	outer.set_corner_radius_all(29)
	outer.shadow_color = Color(0.0, 0.62, 1.0, 0.68)
	outer.shadow_size = 7
	draw_style_box(outer, frame)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color("051934")
	inner.border_color = Color("17599a")
	inner.set_border_width_all(2)
	inner.set_corner_radius_all(24)
	draw_style_box(inner, frame.grow(-6.0))
	# Decorative astronomy SVG supplied by the user, rasterized as transparent PNG.
	var wallpaper: Rect2 = Rect2(Vector2(w * 0.055, h * 0.062), Vector2(w * 0.89, h * 0.36))
	draw_texture_rect(CHAT_PATTERN, wallpaper, false, Color(1.0, 1.0, 1.0, 0.40))
	# Teaching prompt backdrop is separated from chat bubbles.
	if _hint != null and _hint.visible:
		var hr: Rect2 = Rect2(_hint.position - Vector2(3.0, 3.0), _hint.size + Vector2(6.0, 6.0))
		var prompt := StyleBoxFlat.new()
		prompt.bg_color = Color(0.005, 0.18, 0.35, 0.90)
		prompt.border_color = Color("36ddff")
		prompt.set_border_width_all(2)
		prompt.set_corner_radius_all(22)
		prompt.shadow_color = Color(0.0, 0.64, 0.95, 0.52)
		prompt.shadow_size = 5
		draw_style_box(prompt, hr)
	# Keyboard well stays within the frame and has its own material.
	var well: Rect2 = Rect2(Vector2(w * 0.028, h * 0.561), Vector2(w * 0.944, h * 0.409))
	var well_style := StyleBoxFlat.new()
	well_style.bg_color = Color(0.012, 0.08, 0.18, 0.50)
	well_style.border_color = Color(0.13, 0.50, 0.82, 0.34)
	well_style.set_border_width_all(1)
	well_style.set_corner_radius_all(17)
	draw_style_box(well_style, well)
	for px in [0.16, 0.50, 0.84]:
		draw_line(Vector2(w * px, 12), Vector2(w * px + 18, 12), Color("57f2ff"), 3.0, true)

# v107-keyboard-accessibility: show SEND after meaningful typing.
# Different locale labels come from the chosen tablet language, not a second selector.
# v107.2-button-type-fix: read actual UI nodes, never treat a Callable as a Button.
func _v107_find_send_button() -> Button:
	var node: Node = find_child("SendMessage", true, false)
	if node is Button:
		return node as Button
	for child in find_children("*", "Button", true, false):
		if child is Button:
			var button: Button = child as Button
			if button.name == "SendButton" or button.name == "Send" or button.text.contains("➤"):
				return button
	return null

func _v107_find_entry() -> LineEdit:
	var node: Node = find_child("FreeTextEntry", true, false)
	if node is LineEdit:
		return node as LineEdit
	for child in find_children("*", "LineEdit", true, false):
		if child is LineEdit:
			return child as LineEdit
	return null

func _v107_refresh_send_button() -> void:
	var send_button: Button = _v107_find_send_button()
	var text_entry: LineEdit = _v107_find_entry()
	if send_button == null or text_entry == null:
		return
	var labels: Dictionary = {
		"ru": "Отправить ➤", "en": "Send ➤", "fr": "Envoyer ➤",
		"de": "Senden ➤", "es": "Enviar ➤", "pt_BR": "Enviar ➤"
	}
	send_button.text = str(labels.get(_locale, labels["en"]))
	send_button.visible = not text_entry.text.strip_edges().is_empty()
	send_button.add_theme_font_size_override("font_size", 16)

# Keep the locally configured layout; widen only a real side-by-side Send button.
func _v107_adjust_entry_send_layout() -> void:
	var send_button: Button = _v107_find_send_button()
	var text_entry: LineEdit = _v107_find_entry()
	if send_button == null or text_entry == null:
		return
	if absf(send_button.position.y - text_entry.position.y) > maxf(15.0, text_entry.size.y * 0.25):
		return
	var input_left: float = text_entry.position.x
	var right_edge: float = minf(size.x - 6.0, send_button.position.x + send_button.size.x)
	var available: float = right_edge - input_left
	if available < 185.0:
		return
	var gap: float = maxf(6.0, size.x * 0.012)
	var send_width: float = minf(clampf(size.x * 0.24, 94.0, 162.0), available * 0.42)
	send_button.position.x = right_edge - send_width
	send_button.size.x = send_width
	text_entry.size.x = maxf(55.0, send_button.position.x - input_left - gap)

# v107.3-next-action-guidance: guide the child to letters, Space, 123, ?!, or Send.
# Uses the selected cloud's _sample_answer(); never autofills the child's input.
func _v1073_set_guided_style(button: Button, active: bool) -> void:
	if button == null:
		return
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color("e58a22") if active else Color("244564")
	normal.border_color = Color("ffe0a1") if active else Color("3a6f99")
	normal.set_border_width_all(2 if active else 1)
	normal.set_corner_radius_all(7)
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("f6a03c") if active else Color("37688c")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color.WHITE if active else Color("e8f5ff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func _v1073_next_action(next_character: String) -> String:
	if next_character == " " or next_character == "\t":
		return "space"
	if next_character == "," or next_character == ".":
		return "punctuation_shortcut"
	if next_character.is_valid_int():
		return "character" if _keyboard_mode == "numbers" else "numbers"
	var locale_letters: Array = KEYBOARD_ROWS.get(_locale, KEYBOARD_ROWS["en"])
	for row in locale_letters:
		if str(row).to_lower().contains(next_character.to_lower()):
			return "character" if _keyboard_mode == "letters" else "letters"
	for row in V107_SYMBOL_ROWS:
		if str(row).contains(next_character):
			return "character" if _keyboard_mode == "symbols" else "symbols"
	for row in NUMBER_ROWS:
		if str(row).contains(next_character):
			return "character" if _keyboard_mode == "numbers" else "numbers"
	return "unknown"


func _v1073_update_guidance() -> void:
	var text_entry: LineEdit = _v107_find_entry()
	var send_button: Button = _v107_find_send_button()
	if text_entry == null or send_button == null:
		return
	var target: String = _sample_answer()
	var entered: String = text_entry.text
	var target_lower: String = target.to_lower()
	var entered_lower: String = entered.to_lower()
	var next_character: String = ""
	var show_send_hint: bool = false
	if target.is_empty():
		# Free input after the scripted hint sequence.
		show_send_hint = not entered.strip_edges().is_empty()
	elif target_lower.begins_with(entered_lower):
		if entered.length() < target.length():
			next_character = target.substr(entered.length(), 1)
		else:
			show_send_hint = not entered.strip_edges().is_empty()
	else:
		# Semantically valid alternatives may differ from the selected suggestion.
		# Do not force an alternative through the chosen phrase's remaining letters.
		show_send_hint = not entered.strip_edges().is_empty()
	var action: String = _v1073_next_action(next_character) if not next_character.is_empty() else ""
	var letter_control: String = str(_labels().get("letters", "ABC"))
	for key_button in _keyboard_buttons:
		if not is_instance_valid(key_button):
			continue
		var key: Button = key_button as Button
		if key == null:
			continue
		var highlight: bool = false
		var key_name: String = str(key.name)
		match action:
			"space":
				highlight = key_name == "Control_32"
			"numbers":
				highlight = key_name == "Control_49" and key.text == "123"
			"symbols":
				highlight = key_name == "Control_63" and key.text == "?!"
			"letters":
				highlight = key.text == letter_control and key_name.begins_with("Control_")
			"punctuation_shortcut":
				highlight = key_name.begins_with("Control_") and key.text == next_character
			"character":
				highlight = key_name.begins_with("Key_") and key.text.to_lower() == next_character.to_lower()
		_v1073_set_guided_style(key, highlight)
	# The Send button is shown by v107.2 after nonempty input; highlight it
	# only when the selected phrase is complete or a free-form alternative is typed.
	_v1073_set_guided_style(send_button, show_send_hint and send_button.visible and not send_button.disabled)
# v108-existing-card-voice
