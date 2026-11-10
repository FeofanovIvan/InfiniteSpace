extends Control
## MIKA / SMC / Phase beings — molecule builder.
## One self-contained Control scene. Chemistry data and six translations are external JSON.
## Works with mouse and touchscreen; integrates with /root/LanguageService when present.

const DESIGN := Vector2(1280.0, 720.0)
const LANGUAGES := ["ru", "en", "pt", "es", "de", "fr"]
const ELEMENTS := ["H", "O", "C", "N"]
const ATOM_COLORS := {
	"H": Color("e5f4fa"),
	"O": Color("ff788e"),
	"C": Color("344c70"),
	"N": Color("6db8ff")
}
const ATOM_EDGES := {
	"H": Color("ffffff"),
	"O": Color("ffc1cc"),
	"C": Color("b7d8fa"),
	"N": Color("c5ecff")
}
const MOLECULE_ORIGIN := Vector2(635, 359)
const LEFT_PANEL := Rect2(30, 145, 257, 404)
const BOARD_PANEL := Rect2(302, 145, 652, 404)
const RIGHT_PANEL := Rect2(969, 145, 281, 404)
const BOTTOM_PANEL := Rect2(28, 566, 1224, 133)
const PALETTE_RECTS := [
	Rect2(166, 590, 213, 84),
	Rect2(410, 590, 213, 84),
	Rect2(654, 590, 213, 84),
	Rect2(898, 590, 213, 84)
]
const STAR_ICON = preload("res://planet_hub/games/molecule_builder/star_core.png")
## MIKA_MOLECULE_NATIVE_V3_INTEGRATED
## MIKA_MOLECULE_NATIVE_V3_3_EXPANDED
## MIKA_MOLECULE_NUMBERED_ATOMS_V3_4
## MIKA_MOLECULE_ATOM_LETTERS_V3_4_2
## MIKA_MOLECULE_AUTO_NEXT_V3_4_3
## MIKA_MOLECULE_VOICE_V3_4_5
## MIKA_MOLECULE_VICTORY_GREY_DOTS_V3_4_6
# MIKA Molecule Builder v3.4.5 — native, language-aware voice narration.
# No fake/pre-rendered robotic voice assets. Uses installed system voices,
# preferring neural/natural/premium/enhanced variants when present.
const MOLECULE_VOICE_LINES: Dictionary = {
	"ru": {"intro": "Давай соберём молекулу! Возьми атом снизу и поставь на место с номером. Начнём с молекулы: ", "next": "Следующая молекула: ", "hint": "Подсказка. Нужен атом: ", "wrong": "Попробуй другой атом.", "win": "Отлично! Молекула готова!"},
	"en": {"intro": "Let's build a molecule! Choose an atom below and drag it to a numbered spot. Our first molecule is ", "next": "Next molecule: ", "hint": "Here's a hint. You need ", "wrong": "Try a different atom.", "win": "Great job! Molecule complete!"},
	"pt": {"intro": "Vamos montar uma molécula! Escolha um átomo abaixo e arraste-o até um lugar numerado. Nossa primeira molécula é ", "next": "Próxima molécula: ", "hint": "Uma dica. Você precisa de ", "wrong": "Tente outro átomo.", "win": "Muito bem! Molécula completa!"},
	"es": {"intro": "¡Vamos a construir una molécula! Elige un átomo de abajo y arrástralo hasta un lugar numerado. La primera molécula es ", "next": "Siguiente molécula: ", "hint": "Una pista. Necesitas ", "wrong": "Prueba con otro átomo.", "win": "¡Muy bien! ¡Molécula completa!"},
	"fr": {"intro": "Construisons une molécule ! Choisis un atome en bas et glisse-le vers un emplacement numéroté. Notre première molécule est ", "next": "Molécule suivante : ", "hint": "Un indice. Il te faut de l'élément ", "wrong": "Essaie un autre atome.", "win": "Bravo ! Molécule terminée !"},
	"de": {"intro": "Wir bauen ein Molekül! Wähle unten ein Atom und ziehe es auf einen nummerierten Platz. Unser erstes Molekül ist ", "next": "Nächstes Molekül: ", "hint": "Ein Tipp. Du brauchst das Element ", "wrong": "Versuche ein anderes Atom.", "win": "Prima! Das Molekül ist fertig!"}
}
const MOLECULE_VOICE_REGIONS: Dictionary = {
	"ru": "ru_ru", "en": "en_us", "pt": "pt_br", "es": "es_es", "fr": "fr_fr", "de": "de_de"
}
const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const SFX_GOOD: AudioStream = preload("res://planet_hub/games/molecule_builder/audio/atom_good_v3.ogg")
const SFX_WRONG: AudioStream = preload("res://planet_hub/games/molecule_builder/audio/atom_wrong_v3.ogg")
const SFX_COMPLETE: AudioStream = preload("res://planet_hub/games/molecule_builder/audio/molecule_complete_v3.ogg")
const SFX_HINT: AudioStream = preload("res://planet_hub/games/molecule_builder/audio/molecule_hint_v3.ogg")
const SFX_NAV: AudioStream = preload("res://planet_hub/games/molecule_builder/audio/molecule_nav_v3.ogg")
const AMBIENT: AudioStream = preload("res://planet_hub/games/molecule_builder/audio/ambient_molecule_v3.ogg")
const STAGE_START_Y := 136.0
const STAGE_HEIGHT := 584.0
const MUSIC_TITLES: Dictionary = {
	"ru": "Музыка: вкл./выкл.", "en": "Music on/off",
	"pt": "Ligar/desligar música", "es": "Activar/desactivar música",
	"de": "Musik ein/aus", "fr": "Activer/désactiver la musique"
}
const CRYSTAL_GOOD: Dictionary = {
	"ru": "Отлично! +1 кристалл", "en": "Great! +1 crystal",
	"pt": "Muito bem! +1 cristal", "es": "¡Muy bien! +1 cristal",
	"de": "Super! +1 Kristall", "fr": "Bravo ! +1 cristal"
}

var _translations: Dictionary = {}
var _molecules: Array = []
var _queue: Array = []
var _model: Dictionary = {}
var _placed: Array = []
var _interface_lang := "en"
var _learning_lang := "en"
var _service: Node
var _scale := 1.0
var _origin := Vector2.ZERO
var _time := 0.0
var _round := 0
var _score := 0
var _errors := 0
var _completed := false
var _finished := false
var _auto_next_seconds: float = -1.0
var _molecule_voice_ids: Dictionary = {}
var _molecule_voice_intro: bool = true
var _molecule_voice_started: bool = false
var _molecule_voice_warned: bool = false
var _molecule_voice_duck_sec: float = 0.0
var _hint_slot := -1
var _hint_remaining := 0.0
var _selected_element := ""
var _drag_element := ""
var _drag_point := Vector2.ZERO
var _drag_start := Vector2.ZERO
var _hover_slot := -1
var _drag_from_touch := false
var _feedback_message := ""
var _feedback_color := Color("bde9ff")
var _feedback_timer := 0.0
var _glow_effects: Array[Dictionary] = []

var _title: Label
var _subtitle: Label
var _score_label: Label
var _round_label: Label
var _mission_label: Label
var _name_label: Label
var _formula_label: Label
var _instruction_label: Label
var _count_label: Label
var _board_title: Label
var _feedback_label: Label
var _right_title: Label
var _right_tip: Label
var _counts: Array[Label] = []
var _element_labels: Array[Label] = []
var _language_picker: OptionButton
var _restart_button: Button
var _hint_button: Button
var _next_button: Button
var _previous_button: Button
var _forward_button: Button
var _native_back: Button
var _native_hud: Control
var _native_title_panel: Panel
var _native_title: Label
var _native_subtitle: Label
var _host_back: Control
var _sfx: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _music_enabled := true
var _session_crystals := 0
var _last_start_id := ""
var _progress_by_id: Dictionary = {}
var _solved_by_id: Dictionary = {}
var _orientations: Dictionary = {}
var _rotation_angle := 0.0
var _mirror_x := false
var _stage_extra_x: float = 0.0
var _logical_stage_width: float = 1280.0
var _dynamic_palette: Array[Rect2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	randomize()
	_read_data()
	_make_controls()
	_make_native_header()
	_setup_audio()
	_connect_language()
	_find_host_back()
	_layout()
	get_viewport().size_changed.connect(_layout)
	resized.connect(_layout)
	_new_game()
	call_deferred("_layout")

func _read_data() -> void:
	var parsed_strings = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/molecule_builder/data/strings.json"))
	var parsed_molecules = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/games/molecule_builder/data/molecules.json"))
	if typeof(parsed_strings) == TYPE_DICTIONARY:
		_translations = parsed_strings
	if typeof(parsed_molecules) == TYPE_ARRAY:
		_molecules = parsed_molecules

func _make_controls() -> void:
	_title = _label(32, Color("f3fbff"), HORIZONTAL_ALIGNMENT_LEFT)
	_subtitle = _label(15, Color("a3c9e2"), HORIZONTAL_ALIGNMENT_LEFT)
	_score_label = _label(21, Color("f7fbff"), HORIZONTAL_ALIGNMENT_LEFT)
	_round_label = _label(18, Color("c4e6ff"), HORIZONTAL_ALIGNMENT_LEFT)
	_mission_label = _label(15, Color("a6d5eb"), HORIZONTAL_ALIGNMENT_CENTER)
	_name_label = _label(24, Color("f4fffc"), HORIZONTAL_ALIGNMENT_CENTER)
	_formula_label = _label(48, Color("fff0bf"), HORIZONTAL_ALIGNMENT_CENTER)
	_count_label = _label(17, Color("c7e8f6"), HORIZONTAL_ALIGNMENT_CENTER)
	_instruction_label = _label(16, Color("b9d9ef"), HORIZONTAL_ALIGNMENT_CENTER)
	_board_title = _label(18, Color("c5ecff"), HORIZONTAL_ALIGNMENT_CENTER)
	_feedback_label = _label(18, Color("b7f5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_right_title = _label(17, Color("cdf2ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_right_tip = _label(15, Color("9bc0d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_right_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for _i in range(4):
		_element_labels.append(_label(17, Color("e5f9ff"), HORIZONTAL_ALIGNMENT_LEFT))
		_counts.append(_label(20, Color("f3fbff"), HORIZONTAL_ALIGNMENT_RIGHT))

	_language_picker = OptionButton.new()
	_language_picker.focus_mode = Control.FOCUS_NONE
	for code in LANGUAGES:
		_language_picker.add_item(str(_translations.get(code, {}).get("lang", code)))
	_language_picker.item_selected.connect(_choose_language)
	_skin_button(_language_picker, Color("153554"), Color("5eacdb"))
	add_child(_language_picker)

	_restart_button = _button("", Callable(self, "_new_game"))
	_hint_button = _button("", Callable(self, "_show_hint"))
	_next_button = _button("", Callable(self, "_advance"))
	_next_button.visible = false
	_skin_button(_next_button, Color("1e5b64"), Color("87f4d4"))
	_previous_button = _button("←", Callable(self, "_previous_molecule"))
	_forward_button = _button("→", Callable(self, "_next_molecule"))
	# Music remains ambient, but there is no on-screen music toggle.
	for old in [_title, _subtitle, _round_label, _score_label, _language_picker, _right_tip, _next_button]:
		old.hide()
	for action in [_hint_button, _restart_button, _previous_button, _forward_button]:
		_skin_button(action, Color("0c3558"), Color("57d5ee"))

func _label(font_size: int, color: Color, horizontal: HorizontalAlignment) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.horizontal_alignment = horizontal
	node.clip_text = true
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func _skin_button(button: BaseButton, bg: Color, edge: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.17)
	hover.border_color = Color.WHITE
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.17)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("eafaff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	_skin_button(button, Color("173a59"), Color("6eb3da"))
	button.pressed.connect(callback)
	add_child(button)
	return button

func _put(control: Control, rect: Rect2) -> void:
	control.position = _origin + rect.position * _scale
	control.size = rect.size
	control.scale = Vector2.ONE * _scale

func _layout() -> void:
	var viewport_size: Vector2 = size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	if _native_title_panel == null or viewport_size.x < 220.0 or viewport_size.y < 170.0:
		return
	var safe: Rect2 = _safe_area(viewport_size)
	var header_bottom: float = TOOLBAR.relayout(viewport_size, safe,
			_native_back, _native_hud, _native_title_panel, _native_title, _native_subtitle)
	var margin: float = clampf(safe.size.x * 0.012, 5.0, 22.0)
	var stage_top: float = header_bottom + clampf(safe.size.y * 0.011, 4.0, 12.0)
	var width_available: float = maxf(180.0, safe.size.x - margin * 2.0)
	var height_available: float = maxf(90.0, safe.end.y - stage_top - margin)
	# Uniform scale: atoms stay circular. Extra width expands the central panel,
	# and the bottom palette, instead of shrinking all four blocks to a 1280 canvas.
	_scale = maxf(0.12, minf(width_available / DESIGN.x, height_available / STAGE_HEIGHT))
	_logical_stage_width = maxf(DESIGN.x, width_available / _scale)
	_stage_extra_x = _logical_stage_width - DESIGN.x
	_origin = Vector2(safe.position.x + margin,
			stage_top + (height_available - STAGE_HEIGHT * _scale) * 0.5 - STAGE_START_Y * _scale)
	_dynamic_palette.clear()
	var palette_start: float = 57.0
	var palette_end: float = _logical_stage_width - 57.0
	var palette_gap: float = 14.0
	var cell_w: float = (palette_end - palette_start - palette_gap * 3.0) * 0.25
	for i in range(ELEMENTS.size()):
		_dynamic_palette.append(Rect2(palette_start + float(i) * (cell_w + palette_gap), 590.0, cell_w, 84.0))
	_put(_mission_label, Rect2(49, 178, 218, 29))
	_put(_name_label, Rect2(49, 224, 220, 43))
	_put(_formula_label, Rect2(53, 274, 211, 74))
	_put(_count_label, Rect2(48, 382, 221, 39))
	_put(_board_title, Rect2(355 + _stage_extra_x * 0.5, 166, 548, 30))
	_put(_instruction_label, Rect2(314 + _stage_extra_x * 0.5, 198, 630, 23))
	_instruction_label.hide()  # Instruction lives in the top toolbar, not twice.
	_put(_feedback_label, Rect2(338 + _stage_extra_x * 0.5, 513, 582, 27))
	var right_x: float = 969.0 + _stage_extra_x
	_put(_right_title, Rect2(right_x + 17.0, 170, 247, 35))
	for i in range(ELEMENTS.size()):
		_element_labels[i].hide()
		_counts[i].hide()
	_put(_hint_button, Rect2(right_x + 19.0, 405.0, 243, 35))
	_put(_restart_button, Rect2(right_x + 19.0, 445.0, 243, 35))
	_put(_previous_button, Rect2(right_x + 19.0, 486.0, 114, 41))
	_put(_forward_button, Rect2(right_x + 148.0, 486.0, 114, 41))
	for action in [_hint_button, _restart_button, _previous_button, _forward_button]:
		action.add_theme_font_size_override("font_size", 17 if action == _hint_button or action == _restart_button else 23)
	# The six-language subtitle can be long, especially in Portuguese/German.
	var header_w: float = maxf(60.0, _native_title_panel.size.x - 22.0)
	var count: float = float(maxi(_native_subtitle.text.length(), 1))
	var cap: int = maxi(9, floori(header_w / (count * 0.56)))
	_native_subtitle.add_theme_font_size_override("font_size", mini(cap, maxi(10, roundi(17.0 * _scale))))
	queue_redraw()

func _connect_language() -> void:
	_service = get_node_or_null("/root/LanguageService")
	if _service != null:
		_language_picker.hide()
		if _service.has_signal("language_changed"):
			_service.connect("language_changed", Callable(self, "_external_language_changed"))
		_reload_service_languages()
	else:
		var cfg := ConfigFile.new()
		var code := "en"
		if cfg.load("user://mika_molecule_builder.cfg") == OK:
			code = str(cfg.get_value("settings", "language", "en"))
		_apply_languages(code, code)

func _reload_service_languages() -> void:
	if _service == null:
		return
	var interface_code := str(_service.get("interface_locale"))
	var learning_code := str(_service.get("learning_locale"))
	_apply_languages(interface_code, learning_code)

func _external_language_changed(_unused: String) -> void:
	_reload_service_languages()

func _choose_language(index: int) -> void:
	if index < 0 or index >= LANGUAGES.size():
		return
	var code: String = LANGUAGES[index]
	if _service != null and _service.has_method("set_learning_locale"):
		_service.call("set_learning_locale", code)
	else:
		var cfg := ConfigFile.new()
		cfg.set_value("settings", "language", code)
		cfg.save("user://mika_molecule_builder.cfg")
	_apply_languages(code, code)

func _apply_languages(interface_code: String, learning_code: String) -> void:
	_interface_lang = interface_code if LANGUAGES.has(interface_code) else "en"
	_learning_lang = learning_code if LANGUAGES.has(learning_code) else _interface_lang
	if _language_picker != null:
		_language_picker.select(LANGUAGES.find(_learning_lang))
	_update_labels()
	if not _model.is_empty():
		call_deferred("_voice_announce_current")

func _tr(key: String) -> String:
	var translations: Dictionary = _translations.get(_interface_lang, _translations.get("en", {}))
	return str(translations.get(key, key))

func _element_name(element: String) -> String:
	var translations: Dictionary = _translations.get(_learning_lang, _translations.get("en", {}))
	return str(translations.get("atom_" + element.to_lower(), element))

func _molecule_name() -> String:
	var names: Dictionary = _model.get("names", {})
	return str(names.get(_learning_lang, names.get("en", "")))

func _new_game() -> void:
	if _molecules.is_empty():
		return
	_queue = _molecules.duplicate()
	_queue.shuffle()
	# No fixed first molecule, and avoid immediately repeating the last opening.
	if _queue.size() > 1 and str(_queue[0].get("id", "")) == _last_start_id:
		var j: int = randi_range(1, _queue.size() - 1)
		var first: Variant = _queue[0]
		_queue[0] = _queue[j]
		_queue[j] = first
	_last_start_id = str(_queue[0].get("id", ""))
	_progress_by_id.clear()
	_solved_by_id.clear()
	_orientations.clear()
	_round = 0
	_score = 0
	_errors = 0
	_session_crystals = 0
	_finished = false
	_molecule_voice_intro = true
	if _native_hud != null:
		_native_hud.set("crystal_count", _session_crystals)
	_play_sfx(SFX_NAV)
	_go_to_round()

func _go_to_round() -> void:
	if _queue.is_empty():
		return
	_round = posmod(_round, _queue.size())
	_model = _queue[_round]
	_auto_next_seconds = -1.0
	var molecule_id: String = str(_model.get("id", ""))
	if not _orientations.has(molecule_id):
		_orientations[molecule_id] = {"angle": float(randi_range(0, 3)) * PI * 0.5,
				"mirror": bool(randi_range(0, 1) == 1)}
	var orientation: Dictionary = _orientations[molecule_id]
	_rotation_angle = float(orientation.get("angle", 0.0))
	_mirror_x = bool(orientation.get("mirror", false))
	_placed.clear()
	for _i in range(_model.get("atoms", []).size()):
		_placed.append(false)
	_completed = false
	if _progress_by_id.has(molecule_id):
		var saved: Dictionary = _progress_by_id[molecule_id]
		var restored: Array = saved.get("placed", [])
		if restored.size() == _placed.size():
			_placed = restored.duplicate()
			_completed = _placed.count(true) == _placed.size()
	_finished = _solved_by_id.size() == _queue.size()
	_hint_slot = -1
	_hint_remaining = 0.0
	_selected_element = ""
	_drag_element = ""
	_hover_slot = -1
	_glow_effects.clear()
	_next_button.hide()
	_feedback_message = _tr("complete") if _completed else _tr("started")
	_feedback_color = Color("bfe7ff")
	_feedback_timer = 0.0
	_update_labels()
	call_deferred("_voice_announce_current")
	queue_redraw()

func _advance() -> void:
	if _finished:
		_new_game()
		return
	if not _completed:
		return
	_round += 1
	_go_to_round()

func _show_hint() -> void:
	if _completed:
		return
	for i in range(_placed.size()):
		if not _placed[i]:
			_hint_slot = i
			_hint_remaining = 5.0
			_play_sfx(SFX_HINT)
			var required := str(_model.get("atoms", [])[i].get("type", "H"))
			_feedback_message = _tr("hint_message") % _element_name(required)
			_voice_read_hint(required)
			_feedback_color = Color("ffe6a3")
			_feedback_timer = 5.0
			_update_labels()
			return

func _required_count(element: String) -> int:
	var quantity := 0
	for atom in _model.get("atoms", []):
		if str(atom.get("type", "")) == element:
			quantity += 1
	return quantity

func _placed_count(element: String) -> int:
	var count := 0
	var atoms: Array = _model.get("atoms", [])
	for i in range(_placed.size()):
		if _placed[i] and str(atoms[i].get("type", "")) == element:
			count += 1
	return count

func _update_labels() -> void:
	if _title == null:
		return
	_title.text = _tr("title")
	_subtitle.text = _tr("subtitle")
	_score_label.text = "%s  %d" % [_tr("score"), _score]
	_mission_label.text = _tr("mission")
	_name_label.text = _molecule_name()
	_formula_label.text = str(_model.get("formula", ""))
	_board_title.text = _tr("collect")
	_instruction_label.text = _tr("instruction")
	_count_label.text = "%s   %d / %d" % [_tr("remaining"), _placed.count(true), _placed.size()]
	_right_title.text = _tr("needed")
	_right_tip.text = _tr("tap")
	_hint_button.text = _tr("hint")
	_restart_button.text = _tr("new")
	_next_button.text = _tr("again") if _finished else _tr("next")
	_next_button.hide()
	if _native_title != null:
		_native_title.text = _tr("title")
		_native_subtitle.text = _tr("instruction")
	if _native_hud != null:
		_native_hud.set("crystal_count", _session_crystals)
	_previous_button.tooltip_text = "◀"
	_forward_button.tooltip_text = _tr("next")
	_feedback_label.text = _feedback_message
	_feedback_label.add_theme_color_override("font_color", _feedback_color)
	var visible_row := 0
	for i in range(ELEMENTS.size()):
		var element: String = ELEMENTS[i]
		var required := _required_count(element)
		if required > 0:
			_put(_element_labels[i], Rect2(992, 221 + visible_row * 47, 165, 37))
			_put(_counts[i], Rect2(1160, 221 + visible_row * 47, 68, 37))
			visible_row += 1
		_element_labels[i].visible = false
		_counts[i].visible = false
		_element_labels[i].text = "%s  %s" % [element, _element_name(element)]
		_counts[i].text = "%d/%d" % [_placed_count(element), required]
		var label_color: Color = Color("baf9d5") if _placed_count(element) == required else Color("e9f8ff")
		_counts[i].add_theme_color_override("font_color", label_color)

func _to_design(screen_point: Vector2) -> Vector2:
	return (screen_point - _origin) / maxf(_scale, 0.01)

func _palette_at(point: Vector2) -> String:
	for i in range(_dynamic_palette.size()):
		if _dynamic_palette[i].has_point(point):
			return ELEMENTS[i]
	return ""

func _slot_point(index: int) -> Vector2:
	var atoms: Array = _model.get("atoms", [])
	var item: Dictionary = atoms[index]
	var offset := Vector2(float(item.get("x", 0)), float(item.get("y", 0))) * 0.72
	if _mirror_x:
		offset.x = -offset.x
	return _molecule_center() + offset.rotated(_rotation_angle)

func _closest_slot(point: Vector2) -> int:
	var nearest: int = -1
	var distance: float = _atom_visual_radius() + 18.0
	for i in range(_placed.size()):
		if _placed[i]:
			continue
		var delta: float = point.distance_to(_slot_point(i))
		if delta < distance:
			nearest = i
			distance = delta
	return nearest

func _begin_interaction(point: Vector2, is_touch: bool) -> void:
	if _completed:
		return
	var hit_element := _palette_at(point)
	if not hit_element.is_empty():
		_drag_element = hit_element
		_voice_read_element(hit_element)
		_drag_start = point
		_drag_point = point
		_drag_from_touch = is_touch
		_hover_slot = -1
		queue_redraw()
	elif not _selected_element.is_empty():
		_try_placement(_selected_element, point)
		queue_redraw()

func _move_interaction(point: Vector2, is_touch: bool) -> void:
	if _drag_element.is_empty() or _drag_from_touch != is_touch:
		return
	_drag_point = point
	_hover_slot = _closest_slot(point)
	queue_redraw()

func _end_interaction(point: Vector2, is_touch: bool) -> void:
	if _drag_element.is_empty() or _drag_from_touch != is_touch:
		return
	var element: String = _drag_element
	_drag_element = ""
	_hover_slot = -1
	if point.distance_to(_drag_start) <= 23.0 and not _palette_at(point).is_empty():
		_selected_element = element
	else:
		_try_placement(element, point)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = _to_design(event.position)
		if event.pressed:
			_begin_interaction(point, false)
		else:
			_end_interaction(point, false)
	elif event is InputEventMouseMotion:
		_move_interaction(_to_design(event.position), false)
	elif event is InputEventScreenTouch and event.index == 0:
		var touch_point: Vector2 = _to_design(event.position)
		if event.pressed:
			_begin_interaction(touch_point, true)
		else:
			_end_interaction(touch_point, true)
	elif event is InputEventScreenDrag and event.index == 0:
		_move_interaction(_to_design(event.position), true)

func _try_placement(element: String, point: Vector2) -> void:
	if _completed:
		return
	var slot := _closest_slot(point)
	if slot < 0:
		return
	var atoms: Array = _model.get("atoms", [])
	if str(atoms[slot].get("type", "")) != element:
		_errors += 1
		_play_sfx(SFX_WRONG)
		_feedback_message = _tr("wrong")
		_voice_speak(_voice_phrase(_learning_lang, "wrong"))
		_feedback_color = Color("ffabba")
		_feedback_timer = 2.6
		_update_labels()
		_burst(_slot_point(slot), Color("ff9aa5"), 7)
		return
	_placed[slot] = true
	_session_crystals += 1
	if _native_hud != null:
		_native_hud.set("crystal_count", _session_crystals)
	_play_sfx(SFX_GOOD)
	_selected_element = ""
	_score += 10
	_hint_remaining = 0.0
	_hint_slot = -1
	_feedback_message = str(CRYSTAL_GOOD.get(_interface_lang, CRYSTAL_GOOD["en"]))
	_feedback_color = Color("99ffd0")
	_feedback_timer = 3.0
	_burst(_slot_point(slot), ATOM_EDGES[element], 16)
	if _placed.count(true) == _placed.size():
		_completed = true
		_score += 30
		_solved_by_id[str(_model.get("id", ""))] = true
		_finished = _solved_by_id.size() == _queue.size()
		_play_sfx(SFX_COMPLETE)
		_voice_speak(_voice_phrase(_learning_lang, "win") + " " + _molecule_name() + ".")
		_auto_next_seconds = 2.6  # Voice-aware victory hold
		_feedback_message = _tr("finish") if _finished else _tr("complete")
		_feedback_color = Color("ffecae")
		_feedback_timer = 0.0
		_next_button.hide()
		for i in range(_placed.size()):
			_burst(_slot_point(i), Color("83ffee"), 8)
	_save_progress()
	_update_labels()
	queue_redraw()

func _burst(center: Vector2, tone: Color, count: int) -> void:
	for i in range(count):
		var angle := randf() * TAU
		var speed := randf_range(28.0, 100.0)
		_glow_effects.append({
			"point": center,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.4, 1.1),
			"max_life": 1.1,
			"color": tone
		})

func _process(delta: float) -> void:
	_time += delta
	_voice_duck_music(delta)
	if _auto_next_seconds >= 0.0:
		if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH) and DisplayServer.tts_is_speaking():
			_auto_next_seconds = 1.65  # Start hold after speech finishes
		else:
			_auto_next_seconds -= delta
			if _auto_next_seconds <= 0.0:
				_auto_next_seconds = -1.0
				_auto_advance_after_win()
	if _hint_remaining > 0.0:
		_hint_remaining = maxf(0.0, _hint_remaining - delta)
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0 and not _completed:
			_feedback_message = ""
			_feedback_label.text = ""
	for i in range(_glow_effects.size() - 1, -1, -1):
		var item: Dictionary = _glow_effects[i]
		item["life"] = float(item.get("life", 0.0)) - delta
		item["point"] = item.get("point", Vector2.ZERO) + item.get("velocity", Vector2.ZERO) * delta
		if float(item["life"]) <= 0.0:
			_glow_effects.remove_at(i)
		else:
			_glow_effects[i] = item
	queue_redraw()

func _draw() -> void:
	_draw_space_background()
	draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
	_draw_panels()
	_draw_molecule()
	_draw_palette()
	_draw_particles()
	if not _drag_element.is_empty():
		_draw_atom(_drag_point, _drag_element, 34.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _round_rect(rect: Rect2, background: Color, border: Color, radius: int = 18, border_size: int = 2) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border_size)
	draw_style_box(box, rect)

func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN), Color("07111f"), true)
	# Stable dots: deterministic, so random locations do not flicker between frames.
	for i in range(94):
		var x := fmod(float(i * 173 + 49), DESIGN.x)
		var y := fmod(float(i * 89 + 17), DESIGN.y)
		draw_circle(Vector2(x, y), float((i % 3) + 1) * 0.57, Color(0.65, 0.86, 1.0, 0.17))
	for radius in range(5, 0, -1):
		draw_circle(Vector2(194, 362), float(radius) * 73.0, Color(0.13, 0.42, 0.64, 0.013))
		draw_circle(Vector2(1050, 344), float(radius) * 70.0, Color(0.26, 0.24, 0.58, 0.012))
	draw_texture_rect(STAR_ICON, Rect2(724, 24, 37, 37), false, Color(0.82, 0.97, 1.0, 0.84))
	_draw_linework()

func _draw_linework() -> void:
	for i in range(9):
		var x := 300.0 + float(i) * 82.0
		draw_line(Vector2(x, 147), Vector2(x, 548), Color(0.30, 0.57, 0.67, 0.045), 1.0)
	for i in range(6):
		var y := 168.0 + float(i) * 75.0
		draw_line(Vector2(302, y), Vector2(953, y), Color(0.30, 0.57, 0.67, 0.045), 1.0)

func _draw_panels() -> void:
	var right := Rect2(RIGHT_PANEL.position + Vector2(_stage_extra_x, 0.0), RIGHT_PANEL.size)
	var central := Rect2(BOARD_PANEL.position, BOARD_PANEL.size + Vector2(_stage_extra_x, 0.0))
	var lower := Rect2(BOTTOM_PANEL.position, BOTTOM_PANEL.size + Vector2(_stage_extra_x, 0.0))
	# Four matching cyan-rimmed panels. Glow stays BEHIND the opaque main fill.
	for rect in [LEFT_PANEL, central, right, lower]:
		_round_rect(rect.grow(4.0), Color(0.01, 0.12, 0.26, 0.15), Color(0.12, 0.72, 0.96, 0.26), 26, 3)
		_round_rect(rect, Color("091c33"), Color("51dbf4"), 22, 3)
	_round_rect(Rect2(52, 278, 212, 83), Color("163352"), Color("66cced"), 20, 2)
	_draw_progress()
	var center: Vector2 = _molecule_center()
	for i in range(3):
		var radius: float = 119.0 + float(i) * 65.0
		var wave: float = 0.04 * sin(_time * 0.6 + float(i))
		draw_arc(center, radius, 0.0, TAU, 100, Color(0.31, 0.77, 0.89, 0.09 + wave), 1.2)
	_draw_required_atom_dots()

func _draw_progress() -> void:
	# Per-molecule assembly progress only; no numbered levels or stage dots.
	var total: int = maxi(1, _placed.size())
	var done: int = _placed.count(true)
	var outer := Rect2(66, 433, 185, 16)
	_round_rect(outer, Color("10243b"), Color("4182a5"), 8)
	if done > 0:
		var amount: float = (float(done) / float(total)) * 179.0
		_round_rect(Rect2(69, 436, amount, 10), Color("75f3c6"), Color.TRANSPARENT, 6, 0)

func _draw_molecule() -> void:
	if _model.is_empty():
		return
	var atoms: Array = _model.get("atoms", [])
	for bond in _model.get("bonds", []):
		var a := int(bond.get("a", 0))
		var b := int(bond.get("b", 0))
		var order := int(bond.get("order", 1))
		var done: Variant = _placed[a] and _placed[b]
		var begin := _slot_point(a)
		var end := _slot_point(b)
		var along := (end - begin).normalized()
		var perp := Vector2(-along.y, along.x)
		var light := Color("91ffdb") if done else Color("5b8eaa")
		var opacity := 0.96 if done else 0.28
		var thickness := 7.0 if done else 4.0
		for k in range(order):
			var shift := perp * (float(k) - float(order - 1) * 0.5) * 12.0
			draw_line(begin + shift, end + shift, Color(light.r, light.g, light.b, opacity * 0.18), 17.0)
			draw_line(begin + shift, end + shift, Color(light.r, light.g, light.b, opacity), thickness)

	for i in range(atoms.size()):
		var center := _slot_point(i)
		var element := str(atoms[i].get("type", ""))
		if _placed[i]:
			_draw_atom(center, element, _atom_visual_radius(), true)
		else:
			var highlighted := _hover_slot == i or (_hint_slot == i and _hint_remaining > 0.0)
			var halo := Color("f5da88") if highlighted else Color("68b3d9")
			draw_circle(center, _atom_visual_radius() + 6.0, Color(halo.r, halo.g, halo.b, 0.09))
			draw_circle(center, _atom_visual_radius() - 1.0, Color("0a243f"))
			draw_arc(center, _atom_visual_radius() + 1.0, 0.0, TAU, 50, Color(halo.r, halo.g, halo.b, 0.94 if highlighted else 0.72), 3.0)
			draw_arc(center, _atom_visual_radius() + 9.0, _time, _time + 2.0, 36, Color(halo.r, halo.g, halo.b, 0.31), 2.0)
			# Number on the board equals the numbered colored dot in the list.
			# Hint still highlights the exact matching position.
			var text_value: String = str(i + 1)
			var number_font: int = 27 if i < 9 else 22
			_draw_center_text(center, text_value, number_font, Color("fff0bb") if highlighted else Color("b8dff5"))

	if _completed:
		var banner := Rect2(420 + _stage_extra_x * 0.5, 476, 430, 34)
		_round_rect(banner, Color("1f504e"), Color("6cebc3"), 16)
		_draw_drawn_text(Vector2(436 + _stage_extra_x * 0.5, 499), _tr("finish") if _finished else _tr("complete"), 16, Color("edfff7"), 401.0)

func _draw_palette() -> void:
	if _completed:
		for i in range(5):
			var x: float = (_logical_stage_width - 850.0) * 0.5 + float(i) * 181.0
			draw_circle(Vector2(x, 635), 12.0, Color(0.49, 0.89, 0.78, 0.15))
			draw_texture_rect(STAR_ICON, Rect2(x - 16, 619, 32, 32), false, Color("a9f3e1", 0.58))
		return
	for i in range(ELEMENTS.size()):
		var element: String = ELEMENTS[i]
		if i >= _dynamic_palette.size():
			continue
		var rect: Rect2 = _dynamic_palette[i]
		var selected: bool = _selected_element == element or _drag_element == element
		var fill: Color = Color("1b4a70") if selected else Color("142e4b")
		var edge: Color = ATOM_EDGES[element] if selected else Color("4ca8c9")
		_round_rect(rect, fill, edge, 17, 3 if selected else 2)
		_draw_atom(rect.position + Vector2(47, 42), element, 28.0, true)
		_draw_drawn_text(rect.position + Vector2(85, 36), _element_name(element), 16, Color("ecf9ff"), rect.size.x - 91.0)
		_draw_drawn_text(rect.position + Vector2(85, 61), element, 16, Color("9ad5f6"), rect.size.x - 91.0)

func _draw_atom(center: Vector2, element: String, radius: float, with_glow: bool) -> void:
	var fill: Color = ATOM_COLORS.get(element, Color("deeaf6"))
	var edge: Color = ATOM_EDGES.get(element, Color.WHITE)
	if with_glow:
		draw_circle(center, radius + 9.0, Color(edge.r, edge.g, edge.b, 0.085))
		draw_circle(center, radius + 4.0, Color(edge.r, edge.g, edge.b, 0.12))
	draw_circle(center + Vector2(2.0, 5.0), radius, Color(0, 0, 0, 0.24))
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 46, edge, 2.6)
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.32), radius * 0.28, Color(1, 1, 1, 0.19))
	_draw_center_text(center, element, 27 if radius >= 33 else 21, Color("112b3f") if element == "H" else Color.WHITE)

func _draw_center_text(center: Vector2, value: String, font_size: int, color: Color) -> void:
	var width := 100.0
	var origin := center + Vector2(-width * 0.5, float(font_size) * 0.34)
	draw_string(ThemeDB.fallback_font, origin, value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _draw_drawn_text(position: Vector2, value: String, font_size: int, color: Color, width: float) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _draw_particles() -> void:
	for effect in _glow_effects:
		var color: Color = effect.get("color", Color.WHITE)
		var ratio := clampf(float(effect.get("life", 0.0)) / maxf(float(effect.get("max_life", 1.0)), 0.01), 0.0, 1.0)
		var point: Vector2 = effect.get("point", Vector2.ZERO)
		draw_circle(point, 2.0 + ratio * 2.3, Color(color.r, color.g, color.b, ratio * 0.84))

# v3 native UI: same established HUD/arrow/title resources as Fungal Paths.
func _make_native_header() -> void:
	_native_title_panel = Panel.new()
	_native_title_panel.name = "MoleculeNativeTitlePanel"
	_native_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TOOLBAR.apply_title_style(_native_title_panel)
	add_child(_native_title_panel)
	_native_title = _label_in(_native_title_panel, Color("f3ffff"))
	_native_subtitle = _label_in(_native_title_panel, Color("b5dce9"))
	_native_back = Button.new()
	_native_back.name = "MoleculeNativeBack"
	_native_back.focus_mode = Control.FOCUS_NONE
	_native_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_native_back.add_theme_stylebox_override("normal", KIT.button_style(false))
	_native_back.add_theme_stylebox_override("hover", KIT.button_style(true))
	_native_back.add_theme_stylebox_override("pressed", KIT.button_style(true))
	_native_back.pressed.connect(_exit_to_cards)
	add_child(_native_back)
	var glyph: Control = GLYPH.new() as Control
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_native_back.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_native_hud = HUD.new() as Control
	_native_hud.name = "MoleculeNativeCrystalCounter"
	_native_hud.size = Vector2(1680.0, 158.0)
	_native_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_native_hud)
	for key in ["sim_button", "flight_button"]:
		var action: Button = _native_hud.get(key) as Button
		if action != null:
			action.disabled = true
			action.hide()
	_native_hud.set("crystal_count", 0)

func _label_in(parent: Control, color: Color) -> Label:
	var node := Label.new()
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.clip_text = true
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func _safe_area(viewport_size: Vector2) -> Rect2:
	if OS.get_name() not in ["Android", "iOS"]:
		return Rect2(Vector2.ZERO, viewport_size)
	var screen: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if screen.x <= 0.0 or screen.y <= 0.0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Rect2(Vector2.ZERO, viewport_size)
	return Rect2(Vector2(safe.position) * (viewport_size / screen),
			Vector2(safe.size) * (viewport_size / screen))

func _draw_space_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050c1b"), true)
	# Stable, faint stars behind the panels, never a semitransparent overlay.
	for i in range(130):
		var p := Vector2(fmod(float(i * 137 + 31), maxf(size.x, 1.0)),
				fmod(float(i * 79 + 53), maxf(size.y, 1.0)))
		draw_circle(p, 0.65 + float(i % 3) * 0.24, Color(0.54, 0.78, 1.0, 0.19))

func _save_progress() -> void:
	if _model.is_empty():
		return
	_progress_by_id[str(_model.get("id", ""))] = {"placed": _placed.duplicate()}

func _change_molecule(step: int) -> void:
	if _queue.size() < 2:
		return
	_save_progress()
	_round = posmod(_round + step, _queue.size())
	_play_sfx(SFX_NAV)
	_go_to_round()

func _previous_molecule() -> void:
	_change_molecule(-1)

func _next_molecule() -> void:
	_change_molecule(1)

func _setup_audio() -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.name = "MoleculeEffects"
	_sfx.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	_sfx.volume_db = -11.0
	add_child(_sfx)
	_ambient = AudioStreamPlayer.new()
	_ambient.name = "MoleculeQuietMusic"
	_ambient.stream = AMBIENT
	_ambient.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	_ambient.volume_db = -26.0
	_ambient.finished.connect(_on_ambient_finished)
	add_child(_ambient)
	if _music_enabled:
		_ambient.play()

func _on_ambient_finished() -> void:
	if _music_enabled and is_instance_valid(_ambient):
		_ambient.play()



func _play_sfx(stream: AudioStream) -> void:
	if _sfx != null and stream != null:
		_sfx.stream = stream
		_sfx.play()

func _find_host_back() -> void:
	var ancestor: Node = get_parent()
	while ancestor != null:
		for identifier in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
			var button: Control = ancestor.get_node_or_null(identifier) as Control
			if button != null:
				_host_back = button
				_host_back.hide()
				return
		ancestor = ancestor.get_parent()

func _exit_to_cards() -> void:
	if is_instance_valid(_host_back):
		_host_back.show()
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null and bool(portal.get("active")):
		portal.call("handle_scene_transition", "res://")
		return
	get_tree().change_scene_to_file("res://education/playtown/scenes/screens/game_select_playground.tscn")

func _exit_tree() -> void:
	if _molecule_voice_started and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()
	if is_instance_valid(_host_back):
		_host_back.show()

# MIKA v3.3: atom-sequence preview, not a fixed six-level progress indicator.
func _molecule_center() -> Vector2:
	return MOLECULE_ORIGIN + Vector2(_stage_extra_x * 0.5, 0.0)

func _atom_visual_radius() -> float:
	var count: int = _model.get("atoms", []).size()
	return 38.0 if count <= 5 else (32.0 if count <= 7 else 27.0)

func _draw_required_atom_dots() -> void:
	if _model.is_empty():
		return
	var atoms: Array = _model.get("atoms", [])
	var right_x: float = RIGHT_PANEL.position.x + _stage_extra_x
	var per_row: int = 5
	var separation: float = 47.0
	var radius: float = 14.0
	for i in range(atoms.size()):
		var element: String = str(atoms[i].get("type", "H"))
		var column: int = i % per_row
		var row: int = int(floor(float(i) / float(per_row)))
		var center := Vector2(right_x + 47.0 + float(column) * separation,
							  232.0 + float(row) * 63.0)
		var placed: bool = i < _placed.size() and _placed[i]
		var next_needed: bool = not placed and i == _placed.find(false)
		var fill: Color = _preview_atom_fill(i, element)
		var rim: Color = Color("a5aeb8") if placed else (Color("b6fff7") if next_needed else ATOM_EDGES.get(element, Color.WHITE))
		draw_circle(center, radius + 4.0, Color(rim.r, rim.g, rim.b, 0.15))
		draw_circle(center, radius, fill)
		draw_arc(center, radius, 0.0, TAU, 36, rim, 2.0)
		if placed:
			draw_arc(center, radius + 3.0, 0.0, TAU, 36, Color("c4cbd4"), 2.0)
		elif next_needed:
			draw_arc(center, radius + 3.0, 0.0, TAU, 36, Color("b3fff7"), 2.0)
		# Atoms Needed: letter on each colored dot; order supplies the index.
		draw_string(ThemeDB.fallback_font, center + Vector2(-13.0, 5.2), element,
				HORIZONTAL_ALIGNMENT_CENTER, 26.0, 15,
				Color("eff3f8") if placed else (Color("152b3b") if element == "H" else Color.WHITE))

func _auto_advance_after_win() -> void:
	# Navigation and New Game cancel their pending timers in _go_to_round().
	if not _completed or _queue.is_empty():
		return
	# After all twenty distinct tasks, start another shuffled set.
	if _solved_by_id.size() >= _queue.size():
		_new_game()
		return
	# Skip finished models when advancing automatically; arrows stay manual.
	for step in range(1, _queue.size() + 1):
		var next_index: int = posmod(_round + step, _queue.size())
		var next_id: String = str(_queue[next_index].get("id", ""))
		if not _solved_by_id.has(next_id):
			_save_progress()
			_round = next_index
			_play_sfx(SFX_NAV)
			_go_to_round()
			return

func _voice_phrase(locale: String, key: String) -> String:
	var text_map: Dictionary = MOLECULE_VOICE_LINES.get(locale, MOLECULE_VOICE_LINES["en"])
	return str(text_map.get(key, ""))

func _voice_available(locale: String) -> String:
	if _molecule_voice_ids.has(locale):
		return str(_molecule_voice_ids[locale])
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return ""
	var voices: Array[Dictionary] = DisplayServer.tts_get_voices()
	var preferred_language: String = str(MOLECULE_VOICE_REGIONS.get(locale, locale))
	var best_id: String = ""
	var best_score: int = -10000
	for entry in voices:
		var code: String = str(entry.get("language", "")).to_lower().replace("-", "_")
		if not code.begins_with(locale + "_") and code != locale:
			continue
		var voice_id: String = str(entry.get("id", ""))
		if voice_id.is_empty():
			continue
		var name: String = str(entry.get("name", ""))
		var quality: String = (name + " " + voice_id).to_lower()
		var score: int = 0
		if code == preferred_language:
			score += 55
		if quality.contains("neural") or quality.contains("natural"):
			score += 220
		if quality.contains("premium"):
			score += 180
		if quality.contains("enhanced"):
			score += 140
		if quality.contains("siri"):
			score += 75
		if quality.contains("compact") or quality.contains("novelty") or quality.contains("robot"):
			score -= 170
		if score > best_score:
			best_score = score
			best_id = voice_id
	_molecule_voice_ids[locale] = best_id
	return best_id

func _voice_speak(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	var code: String = _learning_lang if MOLECULE_VOICE_LINES.has(_learning_lang) else "en"
	var voice_id: String = _voice_available(code)
	if voice_id.is_empty():
		if not _molecule_voice_warned:
			_molecule_voice_warned = true
			push_warning("Molecule Builder: no installed TTS voice for " + code + ". Install a macOS Enhanced/Premium voice for natural narration.")
		return
	_molecule_voice_started = true
	_molecule_voice_duck_sec = 0.85
	if is_instance_valid(_ambient):
		_ambient.volume_db = -39.0
	DisplayServer.tts_speak(text, voice_id, 85, 1.0, 0.94, 0, true)

func _voice_announce_current() -> void:
	if _model.is_empty():
		return
	var phrase: String = _voice_phrase(_learning_lang, "intro" if _molecule_voice_intro else "next")
	_molecule_voice_intro = false
	_voice_speak(phrase + _molecule_name() + ".")

func _voice_read_element(element: String) -> void:
	if ELEMENTS.has(element):
		_voice_speak(_element_name(element))

func _voice_read_hint(required: String) -> void:
	_voice_speak(_voice_phrase(_learning_lang, "hint") + _element_name(required))

func _voice_duck_music(delta: float) -> void:
	if not is_instance_valid(_ambient):
		return
	if _molecule_voice_duck_sec > 0.0:
		_molecule_voice_duck_sec = maxf(0.0, _molecule_voice_duck_sec - delta)
	var speaking: bool = false
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		speaking = DisplayServer.tts_is_speaking()
	_ambient.volume_db = -39.0 if speaking or _molecule_voice_duck_sec > 0.0 else -26.0

func _preview_atom_fill(index: int, element: String) -> Color:
	if index >= 0 and index < _placed.size() and _placed[index]:
		return Color("737e8a")
	return ATOM_COLORS.get(element, Color.WHITE)
