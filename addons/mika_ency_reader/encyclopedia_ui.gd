extends Control
## MIKA / InfiniteSpace integrated encyclopedia 5.2.
## Redesign pass: native-style top bar + vertical scrolling section list.

signal closed

const BASE: String = "res://addons/mika_ency_reader/"
const CATALOG_PATH: String = BASE + "data/catalog.json"
const LOCALES_PATH: String = BASE + "data/article_localizations.json"
const UI_PATH: String = BASE + "data/ui_localizations.json"
const SECTION_IDS: Array[String] = ["planets", "stations", "races", "characters", "science", "terms"]
const ACCENTS: Dictionary = {
	"planets": Color("#74dcff"),
	"stations": Color("#b5a3ff"),
	"races": Color("#74ecb6"),
	"characters": Color("#ffc987"),
	"science": Color("#ff98bc"),
	"terms": Color("#ffe28a")
}
const SECTION_IMAGE_PATHS: Dictionary = {
	"planets": BASE + "assets/worlds/mw_p01.jpg",
	"stations": BASE + "assets/stations/station_02.jpg",
	"races": BASE + "assets/races/human_group.jpg",
	"characters": BASE + "assets/races/mika.png",
	"science": BASE + "assets/technology/crystal_variants.jpg",
	"terms": BASE + "assets/technology/translator_tablet.jpg"
}
const BACK_NORMAL: String = BASE + "assets/ui/mika_back_normal.png"
const BACK_HOVER: String = BASE + "assets/ui/mika_back_hover.png"
const BACK_PRESSED: String = BASE + "assets/ui/mika_back_pressed.png"
const TEXT_PRIMARY: Color = Color("#f5fbff")
const TEXT_MUTED: Color = Color("#9fbcd6")
const SURFACE: Color = Color(0.04, 0.12, 0.24, 0.88)
const SURFACE_LIGHT: Color = Color(0.07, 0.18, 0.33, 0.92)
const SURFACE_DEEP: Color = Color(0.03, 0.10, 0.20, 0.94)
const EDGE: Color = Color("#2d6687")

const FIELD_LABELS: Dictionary = {
	"ru": {"nature": "Природа", "world_type": "Тип мира", "system": "Галактика", "race": "Жители", "building": "Сооружения", "science_fact": "Интересный факт", "appearance": "Как выглядит", "interior": "Внутри", "form": "Форма жизни", "communication": "Общение", "movement": "Движение", "environment": "Среда обитания", "science_link": "Наука и фантастика", "role": "Кто это", "work": "Чем занимается", "knowledge": "Что знает", "location": "Где живёт", "fun_fact": "Знаешь ли ты?", "where_in_game": "В игре", "principle": "Как работает", "details": "Подробнее", "status": "О чём это", "more": "Открой следующую страницу", "empty": "Изображение появится позже", "back_to_settings": "В настройки", "choose": "Выбери раздел", "all": "Все статьи", "section": "Раздел", "page": "Страница", "previous": "Назад", "next": "Далее"},
	"en": {"nature": "Nature", "world_type": "World type", "system": "Galaxy", "race": "Inhabitants", "building": "Buildings", "science_fact": "Fun fact", "appearance": "Appearance", "interior": "Inside", "form": "Life form", "communication": "Communication", "movement": "Movement", "environment": "Habitat", "science_link": "Science & fiction", "role": "Who is this?", "work": "What they do", "knowledge": "What they know", "location": "Location", "fun_fact": "Did you know?", "where_in_game": "In the game", "principle": "How it works", "details": "More details", "status": "Type", "more": "Discover the next page", "empty": "Illustration coming later", "back_to_settings": "Settings", "choose": "Choose a section", "all": "All articles", "section": "Section", "page": "Page", "previous": "Previous", "next": "Next"},
	"fr": {"nature": "Nature", "world_type": "Type de monde", "system": "Galaxie", "race": "Habitants", "building": "Bâtiments", "science_fact": "Le savais-tu ?", "appearance": "Apparence", "interior": "À l'intérieur", "form": "Forme de vie", "communication": "Communication", "movement": "Mouvement", "environment": "Habitat", "science_link": "Science et fiction", "role": "Qui est-ce ?", "work": "Activité", "knowledge": "Savoir", "location": "Lieu", "fun_fact": "Le savais-tu ?", "where_in_game": "Dans le jeu", "principle": "Fonctionnement", "details": "En détail", "status": "Type", "more": "Découvre la suite", "empty": "Image à venir", "back_to_settings": "Paramètres", "choose": "Choisis une rubrique", "all": "Tous les articles", "section": "Rubrique", "page": "Page", "previous": "Précédent", "next": "Suivant"},
	"de": {"nature": "Natur", "world_type": "Welttyp", "system": "Galaxie", "race": "Bewohner", "building": "Bauwerke", "science_fact": "Schon gewusst?", "appearance": "Aussehen", "interior": "Im Inneren", "form": "Lebensform", "communication": "Kommunikation", "movement": "Bewegung", "environment": "Lebensraum", "science_link": "Wissenschaft und Fiktion", "role": "Wer ist das?", "work": "Aufgabe", "knowledge": "Wissen", "location": "Ort", "fun_fact": "Schon gewusst?", "where_in_game": "Im Spiel", "principle": "So funktioniert es", "details": "Mehr dazu", "status": "Typ", "more": "Weiter entdecken", "empty": "Bild folgt", "back_to_settings": "Einstellungen", "choose": "Wähle einen Bereich", "all": "Alle Artikel", "section": "Bereich", "page": "Seite", "previous": "Zurück", "next": "Weiter"},
	"es": {"nature": "Naturaleza", "world_type": "Tipo de mundo", "system": "Galaxia", "race": "Habitantes", "building": "Edificios", "science_fact": "¿Sabías que...?", "appearance": "Aspecto", "interior": "Interior", "form": "Forma de vida", "communication": "Comunicación", "movement": "Movimiento", "environment": "Hábitat", "science_link": "Ciencia y ficción", "role": "¿Quién es?", "work": "Qué hace", "knowledge": "Qué sabe", "location": "Lugar", "fun_fact": "¿Sabías que...?", "where_in_game": "En el juego", "principle": "Cómo funciona", "details": "Detalles", "status": "Tipo", "more": "Descubre más", "empty": "Imagen próximamente", "back_to_settings": "Ajustes", "choose": "Elige una sección", "all": "Todos los artículos", "section": "Sección", "page": "Página", "previous": "Anterior", "next": "Siguiente"},
	"pt_BR": {"nature": "Natureza", "world_type": "Tipo de mundo", "system": "Galáxia", "race": "Habitantes", "building": "Construções", "science_fact": "Você sabia?", "appearance": "Aparência", "interior": "Interior", "form": "Forma de vida", "communication": "Comunicação", "movement": "Movimento", "environment": "Habitat", "science_link": "Ciência e ficção", "role": "Quem é?", "work": "O que faz", "knowledge": "O que sabe", "location": "Local", "fun_fact": "Você sabia?", "where_in_game": "No jogo", "principle": "Como funciona", "details": "Detalhes", "status": "Tipo", "more": "Descubra mais", "empty": "Imagem em breve", "back_to_settings": "Configurações", "choose": "Escolha uma seção", "all": "Todos os artigos", "section": "Seção", "page": "Página", "previous": "Anterior", "next": "Próximo"}
}

var _catalog: Dictionary = {}
var _locale_texts: Dictionary = {}
var _localized_articles: Dictionary = {}
var _locale: String = "ru"
var _mode: String = "home"
var _section: String = "planets"
var _article_idx: int = 0
var _search_open: bool = false
var _search_query: String = ""

var _shell: VBoxContainer
var _header_title: Label
var _back_button: Control
var _search_button: Button
var _body_scroll: ScrollContainer
var _body: VBoxContainer
var _last_compact: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_catalog = _json(CATALOG_PATH)
	_locale_texts = _json(UI_PATH).get("translations", {})
	_localized_articles = _json(LOCALES_PATH).get("articles", {})
	_locale = _detect_locale()
	_build_shell()
	_last_compact = _compact()
	_render()
	resized.connect(_on_size_changed)

func set_locale(code: String) -> void:
	var next: String = _normalize_locale(code)
	if next.is_empty():
		next = "ru"
	if _locale != next:
		_locale = next
		_render()

func _normalize_locale(code: String) -> String:
	var value: String = code.strip_edges().to_lower().replace("-", "_")
	if value.begins_with("pt"):
		return "pt_BR"
	for lang in ["ru", "en", "fr", "de", "es"]:
		if value.begins_with(lang):
			return lang
	return ""

func _detect_locale() -> String:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load("user://mika_discovery.cfg") == OK:
		var saved: String = _normalize_locale(str(cfg.get_value("settings", "language", "")))
		if not saved.is_empty():
			return saved
	var server: String = _normalize_locale(TranslationServer.get_locale())
	return server if not server.is_empty() else "ru"

func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("MIKA Encyclopedia missing resource: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("MIKA Encyclopedia invalid JSON: " + path)
	return {}

func _ui(key: String) -> String:
	var t: Dictionary = _locale_texts.get(_locale, _locale_texts.get("ru", {}))
	var fallback: Dictionary = _locale_texts.get("ru", {})
	return str(t.get(key, fallback.get(key, key)))

func _word(key: String) -> String:
	return str(FIELD_LABELS.get(_locale, FIELD_LABELS["ru"]).get(key, key))

func _section_name(section: String) -> String:
	return _ui("category_" + section)

func _entries(section: String) -> Array:
	return _catalog.get("sections", {}).get(section, [])

func _entry_text(section: String, data: Dictionary, key: String) -> String:
	var identifier: String = str(data.get("id", ""))
	if _locale != "ru":
		var localized: Dictionary = _localized_articles.get(section + "/" + identifier, {}).get(_locale, {})
		var translated: String = str(localized.get(key, "")).strip_edges()
		if not translated.is_empty():
			return translated
	return str(data.get(key, "")).strip_edges()

func _entry_title(section: String, data: Dictionary) -> String:
	return _entry_text(section, data, "title")

func _resolve_asset_path(path: String) -> String:
	if path.begins_with("res://assets/"):
		return BASE + path.trim_prefix("res://assets/")
	return path

func _load_image(path: String) -> Texture2D:
	var resolved: String = _resolve_asset_path(path)
	if resolved.is_empty() or not ResourceLoader.exists(resolved):
		return null
	return load(resolved) as Texture2D

func _image_for(section: String, entry: Dictionary) -> Texture2D:
	for key in ["image", "portrait_target", "source_portrait", "fallback_illustration"]:
		var path: String = str(entry.get(key, ""))
		var found: Texture2D = _load_image(path)
		if found != null:
			return found
	return _load_image(str(SECTION_IMAGE_PATHS.get(section, "")))

func _box(color: Color, stroke: Color, radius: int = 20, width: int = 2, margin: int = 12) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = stroke
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = float(margin)
	box.content_margin_right = float(margin)
	box.content_margin_top = float(margin)
	box.content_margin_bottom = float(margin)
	return box

func _style_button(button: Button, tint: Color = Color("#73daff"), font_px: int = 20) -> void:
	button.add_theme_stylebox_override("normal", _box(SURFACE, tint.darkened(0.55), 18, 2))
	button.add_theme_stylebox_override("hover", _box(SURFACE_LIGHT, tint, 18, 2))
	button.add_theme_stylebox_override("pressed", _box(Color("#173452"), tint.lightened(0.15), 18, 2))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, tint.lightened(0.15), 18, 2))
	button.add_theme_stylebox_override("disabled", _box(Color("#0f2033"), Color("#29465f"), 18, 1))
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", Color("#5e7b94"))
	button.add_theme_font_size_override("font_size", font_px)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP

func _style_line_edit(line: LineEdit) -> void:
	line.add_theme_stylebox_override("normal", _box(Color("#0f2139"), EDGE, 16, 2, 12))
	line.add_theme_stylebox_override("focus", _box(Color("#152a45"), Color("#79ddff"), 16, 2, 12))
	line.add_theme_color_override("font_color", TEXT_PRIMARY)
	line.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	line.add_theme_font_size_override("font_size", 18 if not _compact() else 16)
	line.clear_button_enabled = true

func _label(text: String, px: int, color: Color = TEXT_PRIMARY) -> Label:
	var result: Label = Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", px)
	result.add_theme_color_override("font_color", color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _compact() -> bool:
	return size.x < 840.0

func _build_shell() -> void:
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0.01, 0.04, 0.09, 0.24)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_shell = VBoxContainer.new()
	_shell.add_theme_constant_override("separation", 0)
	add_child(_shell)
	_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var header: PanelContainer = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 88 if _compact() else 98)
	header.add_theme_stylebox_override("panel", _box(SURFACE_DEEP, Color("#1d4e70"), 0, 0, 0))
	_shell.add_child(header)

	var header_margin: MarginContainer = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 14)
	header_margin.add_theme_constant_override("margin_top", 10)
	header_margin.add_theme_constant_override("margin_right", 14)
	header_margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(header_margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	header_margin.add_child(row)

	_back_button = _make_back_button()
	row.add_child(_back_button)

	var title_wrap: CenterContainer = CenterContainer.new()
	title_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_wrap)

	_header_title = _label("", 28 if not _compact() else 22)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_title.clip_text = true
	title_wrap.add_child(_header_title)

	_search_button = Button.new()
	_search_button.text = "⌕"
	_search_button.tooltip_text = _ui("search_default")
	_search_button.custom_minimum_size = Vector2(56 if _compact() else 64, 56 if _compact() else 64)
	_style_button(_search_button, Color("#7bdfff"), 28 if not _compact() else 24)
	_search_button.pressed.connect(_toggle_search)
	row.add_child(_search_button)

	var body_margin: MarginContainer = MarginContainer.new()
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 16 if _compact() else 22)
	body_margin.add_theme_constant_override("margin_top", 16)
	body_margin.add_theme_constant_override("margin_right", 16 if _compact() else 22)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	_shell.add_child(body_margin)

	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_body_scroll.follow_focus = true
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_child(_body_scroll)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 14)
	_body_scroll.add_child(_body)

func _make_back_button() -> Control:
	var normal: Texture2D = _load_image(BACK_NORMAL)
	if normal != null:
		var tex: TextureButton = TextureButton.new()
		tex.texture_normal = normal
		tex.texture_hover = _load_image(BACK_HOVER)
		tex.texture_pressed = _load_image(BACK_PRESSED)
		tex.ignore_texture_size = true
		tex.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(56 if _compact() else 64, 56 if _compact() else 64)
		tex.tooltip_text = _word("back_to_settings")
		tex.focus_mode = Control.FOCUS_ALL
		tex.pressed.connect(_go_back)
		return tex
	var fallback: Button = Button.new()
	fallback.text = "‹"
	fallback.custom_minimum_size = Vector2(56 if _compact() else 64, 56 if _compact() else 64)
	_style_button(fallback, Color("#7bdfff"), 34)
	fallback.tooltip_text = _word("back_to_settings")
	fallback.pressed.connect(_go_back)
	return fallback

func _on_size_changed() -> void:
	var compact: bool = _compact()
	if compact != _last_compact:
		_last_compact = compact
	call_deferred("_render")

func _clear_body() -> void:
	for node in _body.get_children():
		_body.remove_child(node)
		node.queue_free()
	_body_scroll.scroll_vertical = 0

func _render() -> void:
	if not is_instance_valid(_body) or not is_inside_tree():
		return
	if is_instance_valid(_search_button):
		_search_button.visible = _mode != "detail"
		_search_button.tooltip_text = _ui("search_default")
	_clear_body()
	if _mode == "home":
		_render_home()
	elif _mode == "list":
		_render_list()
	else:
		_render_article()

func _render_search_field(placeholder: String) -> void:
	if not _search_open and _search_query.strip_edges().is_empty():
		return
	var search_card: PanelContainer = PanelContainer.new()
	search_card.add_theme_stylebox_override("panel", _box(Color(0.04, 0.11, 0.22, 0.72), EDGE, 18, 2, 10))
	_body.add_child(search_card)
	var line: LineEdit = LineEdit.new()
	line.placeholder_text = placeholder
	line.text = _search_query
	_style_line_edit(line)
	line.text_changed.connect(_on_search_changed)
	search_card.add_child(line)
	call_deferred("_focus_line", line)

func _focus_line(line: LineEdit) -> void:
	if is_instance_valid(line) and _search_open:
		line.grab_focus()
		line.caret_column = line.text.length()

func _render_home() -> void:
	_header_title.text = _ui("book_title")
	if is_instance_valid(_back_button):
		_back_button.tooltip_text = _word("back_to_settings")
	_render_search_field(_ui("search_default"))

	var sections: Array[String] = []
	for section in SECTION_IDS:
		if _home_section_visible(section):
			sections.append(section)

	for section in sections:
		var entries: Array = _entries(section)
		var card: Button = _make_list_button(ACCENTS[section], 106 if _compact() else 118)
		card.pressed.connect(_choose_section.bind(section))
		_body.add_child(card)

		var row: HBoxContainer = HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 16)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(row)

		row.add_child(_thumb(_load_image(str(SECTION_IMAGE_PATHS[section])), 88 if _compact() else 94, true))

		var texts: VBoxContainer = VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 4)
		texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(texts)

		texts.add_child(_label(_section_name(section), 22 if not _compact() else 18, TEXT_PRIMARY))
		var teaser_key: String = "teaser_" + section
		texts.add_child(_label(_ui(teaser_key), 14 if not _compact() else 13, TEXT_MUTED))

		var meta: HBoxContainer = HBoxContainer.new()
		meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		meta.add_theme_constant_override("separation", 8)
		texts.add_child(meta)
		meta.add_child(_pill(str(entries.size()), ACCENTS[section]))
		meta.add_child(_label(_word("all"), 13, TEXT_MUTED))

		row.add_child(_arrow_label(ACCENTS[section]))

	if sections.is_empty():
		_body.add_child(_empty_hint())

func _home_section_visible(section: String) -> bool:
	var query: String = _search_query.strip_edges().to_lower()
	if query.is_empty():
		return true
	var text: String = (_section_name(section) + " " + _ui("teaser_" + section)).to_lower()
	return text.find(query) != -1

func _choose_section(section: String) -> void:
	_section = section
	_mode = "list"
	_search_query = ""
	_search_open = false
	_render()

func _render_list() -> void:
	_header_title.text = _section_name(_section)
	if is_instance_valid(_back_button):
		_back_button.tooltip_text = _ui("back")
	_render_search_field(_ui("search_article"))

	var entries: Array = _filtered_entries(_section)
	for i in range(entries.size()):
		var wrapped: Dictionary = entries[i]
		var entry: Dictionary = wrapped["entry"]
		var idx: int = int(wrapped["index"])
		var card: Button = _make_list_button(ACCENTS[_section], 118 if _compact() else 126)
		card.pressed.connect(_open_article.bind(idx))
		_body.add_child(card)

		var row: HBoxContainer = HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 16)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(row)

		row.add_child(_thumb(_image_for(_section, entry), 88 if _compact() else 94, _section == "planets"))

		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 5)
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(info)

		info.add_child(_label(_entry_title(_section, entry), 21 if not _compact() else 17, TEXT_PRIMARY))
		var short: String = _entry_text(_section, entry, "description")
		var snippet: Label = _label(short, 14 if not _compact() else 13, TEXT_MUTED)
		snippet.max_lines_visible = 2
		snippet.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info.add_child(snippet)

		row.add_child(_arrow_label(ACCENTS[_section]))

	if entries.is_empty():
		_body.add_child(_empty_hint())

func _filtered_entries(section: String) -> Array:
	var query: String = _search_query.strip_edges().to_lower()
	var out: Array = []
	var source: Array = _entries(section)
	for i in range(source.size()):
		var entry: Dictionary = source[i]
		if query.is_empty():
			out.append({"index": i, "entry": entry})
			continue
		var text: String = (_entry_title(section, entry) + " " + _entry_text(section, entry, "description")).to_lower()
		if text.find(query) != -1:
			out.append({"index": i, "entry": entry})
	return out

func _open_article(index: int) -> void:
	_article_idx = index
	_mode = "detail"
	_search_open = false
	_search_query = ""
	_render()

func _render_article() -> void:
	var entries: Array = _entries(_section)
	if entries.is_empty():
		_mode = "list"
		_render()
		return
	_article_idx = clampi(_article_idx, 0, entries.size() - 1)
	var entry: Dictionary = entries[_article_idx]
	_header_title.text = _entry_title(_section, entry)
	if is_instance_valid(_back_button):
		_back_button.tooltip_text = _ui("back")

	var hero: PanelContainer = PanelContainer.new()
	hero.add_theme_stylebox_override("panel", _box(SURFACE, ACCENTS[_section].darkened(0.45), 22, 2, 14))
	_body.add_child(hero)

	var wrap: BoxContainer = VBoxContainer.new() if _compact() else HBoxContainer.new()
	wrap.add_theme_constant_override("separation", 18)
	hero.add_child(wrap)

	wrap.add_child(_thumb(_image_for(_section, entry), 210 if _compact() else 250, _section == "planets", true))

	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 10)
	wrap.add_child(text_col)

	var desc: String = _entry_text(_section, entry, "description")
	if not desc.is_empty():
		text_col.add_child(_label(desc, 18 if not _compact() else 16, TEXT_PRIMARY))

	for field in _field_keys(_section):
		var value: String = _entry_text(_section, entry, field)
		if value.is_empty() or value == desc:
			continue
		text_col.add_child(_field_block(_word(field), value, ACCENTS[_section]))

func _field_keys(section: String) -> Array[String]:
	match section:
		"planets":
			return ["system", "world_type", "nature", "building", "science_fact"]
		"stations":
			return ["system", "race", "appearance", "interior", "science_fact"]
		"races":
			return ["form", "communication", "environment", "science_link"]
		"characters":
			return ["location", "role", "work", "knowledge"]
		"science":
			return ["fun_fact", "where_in_game"]
		"terms":
			return ["principle", "details", "fun_fact", "where_in_game"]
	return []

func _field_block(title: String, value: String, tint: Color) -> Control:
	var block: PanelContainer = PanelContainer.new()
	block.add_theme_stylebox_override("panel", _box(Color(0.05, 0.12, 0.23, 0.74), tint.darkened(0.35), 18, 1, 10))
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	block.add_child(v)
	v.add_child(_label(title.to_upper(), 12, tint))
	v.add_child(_label(value, 16 if not _compact() else 15, TEXT_PRIMARY))
	return block

func _make_list_button(tint: Color, min_h: float) -> Button:
	var card: Button = Button.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, min_h)
	_style_button(card, tint, 18)
	card.text = ""
	return card

func _thumb(texture: Texture2D, size_px: int, contain: bool = false, allow_large: bool = false) -> Control:
	var frame: PanelContainer = PanelContainer.new()
	frame.custom_minimum_size = Vector2(size_px, size_px if not allow_large else max(size_px, int(size_px * 0.86)))
	frame.add_theme_stylebox_override("panel", _box(Color(0.02, 0.06, 0.13, 0.52), Color("#24567b"), 18, 1, 4))
	var pic: TextureRect = TextureRect.new()
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if contain else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.texture = texture
	frame.add_child(pic)
	if texture == null:
		var empty: Label = _label(_word("empty"), 14, TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		frame.add_child(empty)
	return frame

func _pill(text: String, tint: Color) -> Control:
	var badge: PanelContainer = PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _box(tint.darkened(0.70), tint, 14, 1, 6))
	var label: Label = _label(text, 13, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(label)
	return badge

func _arrow_label(tint: Color) -> Label:
	var arrow: Label = _label("›", 34 if not _compact() else 30, tint)
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return arrow

func _empty_hint() -> Control:
	var box: PanelContainer = PanelContainer.new()
	box.add_theme_stylebox_override("panel", _box(Color(0.04, 0.11, 0.22, 0.70), EDGE, 18, 2, 14))
	box.custom_minimum_size = Vector2(0, 90)
	box.add_child(_label(_ui("empty"), 18 if not _compact() else 16, TEXT_MUTED))
	return box

func _toggle_search() -> void:
	_search_open = not _search_open
	if not _search_open:
		_search_query = ""
	_render()

func _on_search_changed(value: String) -> void:
	_search_query = value
	if not _search_open and not value.is_empty():
		_search_open = true
	_render()

func _go_back() -> void:
	_search_open = false
	_search_query = ""
	if _mode == "detail":
		_mode = "list"
		_render()
	elif _mode == "list":
		_mode = "home"
		_render()
	else:
		closed.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()
