extends Control
## MIKA Encyclopedia v5.6 — viewport-adaptive layout, transparent title and real native images.
## Reuses the live space background and simulator Back glyph.
## No fixed content max width; content follows viewport and MobileLocale safe rect. JSON untouched.

signal closed

const ROOT: String = "res://addons/mika_ency_reader/"
const CATALOG_FILE: String = ROOT + "data/catalog.json"
const UI_FILE: String = ROOT + "data/ui_localizations.json"
const TRANSLATIONS_FILE: String = ROOT + "data/article_localizations.json"
const LIVE_SPACE = preload("res://simulator_ui/scripts/real_space_background.gd")
const BACK_GLYPH = preload("res://simulator_ui/back_arrow_glyph.gd")
const SEARCH_GLYPH = preload("res://addons/mika_ency_reader/search_glyph.gd")

const SECTIONS: Array[String] = ["planets", "stations", "races", "characters", "science", "terms"]
const SECTION_ICONS: Dictionary = {
	"planets": "res://assets/destinations/earth.png",
	"stations": "res://assets/story/callisto_shipyard.png",
	"races": "res://planet_hub/characters/12_phase_liquid.png",
	"characters": "res://planet_hub/characters/05_human_amara_cole.png",
	"science": "res://planet_hub/assets/v68_neon/crystal_reference.png",
	"terms": "res://planet_hub/assets/simulator_helmet.png"
}
const MW_ICONS: Dictionary = {
	"mw_p01": "earth", "mw_p02": "mars", "mw_p03": "jupiter", "mw_p04": "saturn",
	"mw_p05": "uranus", "mw_p06": "neptune", "mw_p07": "venus", "mw_p08": "mercury"
}
# Source illustrations of all 6 unique stations in the main game.
const STATION_ART: Dictionary = {
	"station_01": "res://assets/story/callisto_shipyard.png",
	"station_02": "res://assets/story/tarantula_lab_ship.png",
	"station_03": "res://assets/story/living_archive_lotus.png",
	"station_04": "res://assets/story/titan_skull_ngc6822.png",
	"station_05": "res://assets/story/inverted_pyramid_m31.png",
	"station_06": "res://assets/story/last_gate_m33.png"
}
const NAVY: Color = Color("#061c38")
const NAVY_HOVER: Color = Color("#103e63")
const CYAN: Color = Color("#26dfff")
const BRIGHT_CYAN: Color = Color("#a6eeff")
const TEXT: Color = Color("#f3fbff")
const MUTED: Color = Color("#9ec2db")
const LABELS: Dictionary = {
	"ru": {"system": "Система", "race": "Жители", "world_type": "Тип мира", "nature": "Природа", "building": "Сооружение", "science_fact": "Интересный факт", "station_type": "Тип станции", "location": "Расположение", "appearance": "Снаружи", "interior": "Внутри", "form": "Форма жизни", "anatomy": "Строение", "perception": "Восприятие", "movement": "Движение", "communication": "Общение", "environment": "Среда обитания", "science_link": "Наука и фантастика", "role": "Кто это", "work": "Чем занимается", "knowledge": "Что знает", "where_in_game": "Где в игре", "fun_fact": "Интересный факт", "status": "Тип", "principle": "Как работает", "details": "Подробнее", "related": "Связанные темы"},
	"en": {"system": "System", "race": "Inhabitants", "world_type": "World type", "nature": "Nature", "building": "Buildings", "science_fact": "Fun fact", "station_type": "Station type", "location": "Location", "appearance": "Outside", "interior": "Inside", "form": "Life form", "anatomy": "Anatomy", "perception": "Perception", "movement": "Movement", "communication": "Communication", "environment": "Environment", "science_link": "Science and fiction", "role": "Who is this?", "work": "Activity", "knowledge": "Knowledge", "where_in_game": "In the game", "fun_fact": "Fun fact", "status": "Type", "principle": "How it works", "details": "More details", "related": "Related topics"},
	"fr": {"system": "Système", "race": "Habitants", "world_type": "Type de monde", "nature": "Nature", "building": "Bâtiments", "science_fact": "Le savais-tu ?", "station_type": "Type de station", "location": "Lieu", "appearance": "Extérieur", "interior": "Intérieur", "form": "Forme de vie", "anatomy": "Anatomie", "perception": "Perception", "movement": "Mouvement", "communication": "Communication", "environment": "Habitat", "science_link": "Science et fiction", "role": "Qui est-ce ?", "work": "Activité", "knowledge": "Savoir", "where_in_game": "Dans le jeu", "fun_fact": "Le savais-tu ?", "status": "Type", "principle": "Fonctionnement", "details": "Détails", "related": "Liens"},
	"de": {"system": "System", "race": "Bewohner", "world_type": "Welttyp", "nature": "Natur", "building": "Bauwerke", "science_fact": "Schon gewusst?", "station_type": "Stationstyp", "location": "Ort", "appearance": "Außen", "interior": "Innen", "form": "Lebensform", "anatomy": "Anatomie", "perception": "Wahrnehmung", "movement": "Bewegung", "communication": "Kommunikation", "environment": "Umgebung", "science_link": "Wissenschaft und Fiktion", "role": "Wer ist das?", "work": "Tätigkeit", "knowledge": "Wissen", "where_in_game": "Im Spiel", "fun_fact": "Schon gewusst?", "status": "Typ", "principle": "Funktionsweise", "details": "Details", "related": "Verwandt"},
	"es": {"system": "Sistema", "race": "Habitantes", "world_type": "Tipo de mundo", "nature": "Naturaleza", "building": "Construcciones", "science_fact": "Dato curioso", "station_type": "Tipo de estación", "location": "Lugar", "appearance": "Exterior", "interior": "Interior", "form": "Forma de vida", "anatomy": "Anatomía", "perception": "Percepción", "movement": "Movimiento", "communication": "Comunicación", "environment": "Entorno", "science_link": "Ciencia y ficción", "role": "¿Quién es?", "work": "Actividad", "knowledge": "Conocimientos", "where_in_game": "En el juego", "fun_fact": "Dato curioso", "status": "Tipo", "principle": "Funcionamiento", "details": "Detalles", "related": "Relacionado"},
	"pt_BR": {"system": "Sistema", "race": "Habitantes", "world_type": "Tipo de mundo", "nature": "Natureza", "building": "Construções", "science_fact": "Curiosidade", "station_type": "Tipo de estação", "location": "Local", "appearance": "Exterior", "interior": "Interior", "form": "Forma de vida", "anatomy": "Anatomia", "perception": "Percepção", "movement": "Movimento", "communication": "Comunicação", "environment": "Ambiente", "science_link": "Ciência e ficção", "role": "Quem é?", "work": "Atividade", "knowledge": "Conhecimentos", "where_in_game": "No jogo", "fun_fact": "Curiosidade", "status": "Tipo", "principle": "Como funciona", "details": "Detalhes", "related": "Relacionado"}
}

const FIELDS: Dictionary = {
	"planets": ["system", "world_type", "nature", "race", "building", "science_fact"],
	"stations": ["station_type", "location", "race", "appearance", "interior", "science_fact"],
	"races": ["system", "form", "anatomy", "perception", "movement", "communication", "environment", "science_link"],
	"characters": ["location", "role", "work", "knowledge"],
	"science": ["status", "where_in_game", "fun_fact"],
	"terms": ["status", "principle", "where_in_game", "details", "fun_fact", "related"]
}

var _catalog: Dictionary = {}
var _ui_data: Dictionary = {}
var _article_languages: Dictionary = {}
var _locale: String = "ru"
var _mode: String = "home"
var _section: String = "planets"
var _article_id: String = ""
var _query: String = ""
var _search_visible: bool = false

var _main_margin: MarginContainer
var _header: HBoxContainer
var _title: Label
var _subtitle: Label
var _search_button: Button
var _search_input: LineEdit
var _scroll: ScrollContainer
var _cards: VBoxContainer
var _last_compact_layout: bool = false

# Gesture state: a drag scrolls; a short release opens a card, never both.
var _drag_target: String = ""
var _drag_origin: Vector2 = Vector2.ZERO
var _drag_distance: float = 0.0
var _dragged: bool = false
var _touch_id: int = -1
var _pointer_type: String = ""
var _ignore_mouse_until: int = 0
var _last_open_ms: int = -1000

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_catalog = _read_json(CATALOG_FILE)
	_ui_data = _read_json(UI_FILE).get("translations", {})
	_article_languages = _read_json(TRANSLATIONS_FILE).get("articles", {})
	_locale = _detect_locale()
	_build()
	_last_compact_layout = _is_compact()
	_show_page(true)
	resized.connect(_on_viewport_resized)
	if has_node("/root/MobileLocale"):
		var mobile: Node = get_node("/root/MobileLocale")
		if mobile.has_signal("language_changed"):
			mobile.language_changed.connect(set_locale)
	call_deferred("_layout")

func set_locale(code: String) -> void:
	var normalized: String = _normalize_locale(code)
	if normalized.is_empty():
		normalized = "ru"
	if normalized != _locale:
		_locale = normalized
		_show_page(false)

func _normalize_locale(code: String) -> String:
	var val: String = code.to_lower().strip_edges().replace("-", "_")
	if val.begins_with("pt"):
		return "pt_BR"
	for lang in ["ru", "en", "fr", "de", "es"]:
		if val.begins_with(lang):
			return lang
	return ""

func _detect_locale() -> String:
	if has_node("/root/MobileLocale"):
		var mobile: Node = get_node("/root/MobileLocale")
		var lang: String = _normalize_locale(str(mobile.get("language")))
		if not lang.is_empty():
			return lang
	var fallback: String = _normalize_locale(TranslationServer.get_locale())
	return fallback if not fallback.is_empty() else "ru"

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("MIKA Encyclopedia: missing " + path)
		return {}
	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if result is Dictionary:
		return result
	push_error("MIKA Encyclopedia: invalid JSON " + path)
	return {}

func _ui(key: String) -> String:
	var local: Dictionary = _ui_data.get(_locale, _ui_data.get("ru", {}))
	var fallback: Dictionary = _ui_data.get("ru", {})
	return str(local.get(key, fallback.get(key, key)))

func _label_name(key: String) -> String:
	return str(LABELS.get(_locale, LABELS["ru"]).get(key, key))

func _section_title(section: String) -> String:
	return _ui("category_" + section)

func _entries(section: String) -> Array:
	return _catalog.get("sections", {}).get(section, [])

func _text_of(section: String, item: Dictionary, field: String) -> String:
	if _locale != "ru":
		var identifier: String = section + "/" + str(item.get("id", ""))
		var localized: Dictionary = _article_languages.get(identifier, {}).get(_locale, {})
		var translated: String = str(localized.get(field, "")).strip_edges()
		if not translated.is_empty():
			return translated
	return str(item.get(field, "")).strip_edges()

func _texture_if_exists(path: String) -> Texture2D:
	if not path.is_empty() and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _planet_texture(identifier: String) -> Texture2D:
	# Every world gets its own source image; no shared Earth fallback.
	if MW_ICONS.has(identifier):
		return _texture_if_exists("res://assets/destinations/" + str(MW_ICONS[identifier]) + ".png")
	var asset: Texture2D = _texture_if_exists("res://assets/atlas/planets/" + identifier + ".png")
	if asset != null:
		return asset
	return _texture_if_exists("res://assets/atlas/previews/ngc6822/" + identifier + ".png")

func _article_texture(section: String, item: Dictionary) -> Texture2D:
	if section == "planets":
		return _planet_texture(str(item.get("id", "")))
	if section == "stations":
		var station_texture: Texture2D = _texture_if_exists(str(STATION_ART.get(str(item.get("id", "")), "")))
		if station_texture != null:
			return station_texture
	# The source portrait points to the native Planet Hub characters.
	var keys: Array[String] = ["image", "portrait_target", "source_portrait", "fallback_illustration"]
	if section == "characters":
		keys = ["source_portrait", "portrait_target", "image", "fallback_illustration"]
	for key in keys:
		var path: String = str(item.get(key, ""))
		var texture: Texture2D = _texture_if_exists(path)
		if texture != null:
			return texture
		if path.begins_with("res://assets/"):
			texture = _texture_if_exists(ROOT + path.trim_prefix("res://assets/"))
			if texture != null:
				return texture
	return null

func _rounded(bg: Color, edge: Color, radius: int, border: int, shadow: float = 0.18) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.04, 0.64, 1.0, shadow)
	style.shadow_size = 5
	style.anti_aliasing = true
	return style

func _make_text(value: String, font_size: int, tint: Color = TEXT) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _nav_button(glyph_script: Script) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(66, 66)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _rounded(NAVY, CYAN, 18, 2, 0.24))
	button.add_theme_stylebox_override("hover", _rounded(NAVY_HOVER, BRIGHT_CYAN, 18, 2, 0.38))
	button.add_theme_stylebox_override("pressed", _rounded(Color("#174b70"), BRIGHT_CYAN, 18, 2, 0.18))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var glyph: Control = glyph_script.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return button

func _build() -> void:
	var sky: Control = LIVE_SPACE.new()
	add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tint: ColorRect = ColorRect.new()
	tint.color = Color(0.01, 0.03, 0.08, 0.13)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_main_margin = MarginContainer.new()
	add_child(_main_margin)
	_main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var main: VBoxContainer = VBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	_main_margin.add_child(main)

	# No pixel coordinates: three columns stay aligned before and after first layout.
	_header = HBoxContainer.new()
	_header.custom_minimum_size.y = 98
	_header.add_theme_constant_override("separation", 18)
	main.add_child(_header)

	var back: Button = _nav_button(BACK_GLYPH)
	back.tooltip_text = _ui("back")
	back.pressed.connect(_go_back)
	_header.add_child(back)

	var title_panel: PanelContainer = PanelContainer.new()
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Transparent title container: no visible capsule or decorative outline.
	title_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_header.add_child(title_panel)
	var title_padding: MarginContainer = MarginContainer.new()
	title_padding.add_theme_constant_override("margin_top", 6)
	title_padding.add_theme_constant_override("margin_bottom", 6)
	title_padding.add_theme_constant_override("margin_left", 8)
	title_padding.add_theme_constant_override("margin_right", 8)
	title_panel.add_child(title_padding)
	var title_stack: VBoxContainer = VBoxContainer.new()
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 2)
	title_padding.add_child(title_stack)
	_title = _make_text("", 32, TEXT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.clip_text = true
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.add_theme_color_override("font_outline_color", Color("#07172d"))
	_title.add_theme_constant_override("outline_size", 2)
	title_stack.add_child(_title)
	_subtitle = _make_text("", 16, CYAN)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.clip_text = true
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_stack.add_child(_subtitle)

	_search_button = _nav_button(SEARCH_GLYPH)
	_search_button.tooltip_text = _ui("search_default")
	_search_button.pressed.connect(_toggle_search)
	_header.add_child(_search_button)

	# Exactly ONE search field. It is created once and never during rendering.
	_search_input = LineEdit.new()
	_search_input.visible = false
	_search_input.clear_button_enabled = true
	_search_input.custom_minimum_size.y = 54
	_search_input.add_theme_stylebox_override("normal", _rounded(NAVY, Color("#2679a6"), 18, 2))
	_search_input.add_theme_stylebox_override("focus", _rounded(NAVY_HOVER, CYAN, 18, 2))
	_search_input.add_theme_color_override("font_color", TEXT)
	_search_input.add_theme_color_override("font_placeholder_color", MUTED)
	_search_input.add_theme_font_size_override("font_size", 19)
	_search_input.text_changed.connect(_on_search_changed)
	main.add_child(_search_input)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.follow_focus = false
	_scroll.clip_contents = true
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll.gui_input.connect(_on_scroll_blank_input)
	main.add_child(_scroll)
	# Invisible bar: only swipe, mouse wheel, trackpad or mouse-drag can scroll.
	_scroll.get_v_scroll_bar().modulate = Color(1.0, 1.0, 1.0, 0.0)
	_scroll.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE

	_cards = VBoxContainer.new()
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 13)
	_scroll.add_child(_cards)

func _safe_view_rect() -> Rect2:
	# The *actual viewport* defines the available canvas. The encyclopedia
	# is fullscreen, but still works during the first layout before size settles.
	var view: Vector2 = get_viewport_rect().size
	if view.x < 1.0 or view.y < 1.0:
		view = size
	var viewport_rect: Rect2 = Rect2(Vector2.ZERO, view)
	var safe: Rect2 = viewport_rect
	if has_node("/root/MobileLocale"):
		var mobile: Node = get_node("/root/MobileLocale")
		if mobile.has_method("safe_rect"):
			var result: Variant = mobile.call("safe_rect", view)
			if result is Rect2:
				safe = result
	# Defensive fallback: never lay out outside the current viewport.
	safe = safe.intersection(viewport_rect)
	if safe.size.x < 1.0 or safe.size.y < 1.0:
		return viewport_rect
	return safe

func _is_compact() -> bool:
	return _safe_view_rect().size.x < 720.0

func _on_viewport_resized() -> void:
	_layout()
	# Recreate cards only if we switch between phone / larger screen layouts.
	# Never recreate on every pixel change: that would reset touch scrolling.
	var compact: bool = _is_compact()
	if compact != _last_compact_layout:
		_last_compact_layout = compact
		_render_cards()

func _layout() -> void:
	if not is_instance_valid(_main_margin):
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 1.0 or view.y < 1.0:
		view = size
	var safe: Rect2 = _safe_view_rect()

	# The user's layout rule: percentages of available SAFE screen space,
	# not a centered fixed-width rectangle (no max_width anywhere).
	# 3.2% on both sides, 2% top/bottom; small touchscreens keep >= 8 px.
	var horizontal_inset: float = maxf(8.0, safe.size.x * 0.032)
	var vertical_inset: float = maxf(8.0, safe.size.y * 0.020)
	_main_margin.add_theme_constant_override("margin_left", roundi(safe.position.x + horizontal_inset))
	_main_margin.add_theme_constant_override("margin_right", roundi(view.x - safe.end.x + horizontal_inset))
	_main_margin.add_theme_constant_override("margin_top", roundi(safe.position.y + vertical_inset))
	_main_margin.add_theme_constant_override("margin_bottom", roundi(view.y - safe.end.y + vertical_inset))

	# Scale the header inside the available safe rectangle, preserving a
	# symmetrical Back / Title / Search row on portrait and landscape screens.
	var button_side: int = roundi(clampf(minf(safe.size.x * 0.13, safe.size.y * 0.105), 44.0, 76.0))
	var header_height: int = roundi(clampf(safe.size.y * 0.118, 68.0, 114.0))
	_header.custom_minimum_size.y = maxi(header_height, button_side + 10)
	_header.add_theme_constant_override("separation", maxi(7, roundi(safe.size.x * 0.010)))
	for button in [_header.get_child(0), _search_button]:
		(button as Button).custom_minimum_size = Vector2(button_side, button_side)
	var title_px: int = roundi(clampf(minf(safe.size.x * 0.040, safe.size.y * 0.054), 19.0, 39.0))
	var subtitle_px: int = roundi(clampf(safe.size.x * 0.019, 12.0, 17.0))
	_title.add_theme_font_size_override("font_size", title_px)
	_subtitle.add_theme_font_size_override("font_size", subtitle_px)
	_search_input.custom_minimum_size.y = roundi(clampf(safe.size.y * 0.071, 44.0, 60.0))
	_search_input.add_theme_font_size_override("font_size", roundi(clampf(safe.size.x * 0.022, 15.0, 21.0)))

	# Gaps follow the viewport as well. ScrollContainer retains the rest of
	# VBoxContainer height automatically; no manual scroll viewport clipping.
	var main: VBoxContainer = _main_margin.get_child(0) as VBoxContainer
	if main != null:
		main.add_theme_constant_override("separation", maxi(9, roundi(safe.size.y * 0.016)))
	_cards.add_theme_constant_override("separation", maxi(9, roundi(safe.size.y * 0.015)))

func _show_page(reset_scroll: bool) -> void:
	if not is_instance_valid(_cards):
		return
	_search_input.placeholder_text = _ui("search_default")
	_search_button.tooltip_text = _ui("search_default")
	if _mode == "home":
		_title.text = _ui("book_title")
		_subtitle.text = _ui("book_subtitle")
	elif _mode == "list":
		_title.text = _section_title(_section)
		_subtitle.text = _ui("book_subtitle")
	else:
		var found: Dictionary = _find_article(_section, _article_id)
		_title.text = _text_of(_section, found, "title") if not found.is_empty() else _section_title(_section)
		_subtitle.text = _section_title(_section)
	_render_cards()
	_layout()
	if reset_scroll:
		_scroll.set_deferred("scroll_vertical", 0)

func _clear_cards() -> void:
	for old in _cards.get_children():
		_cards.remove_child(old)
		old.queue_free()

func _render_cards() -> void:
	_clear_cards()
	if _mode == "home":
		_render_home()
	elif _mode == "list":
		_render_section()
	else:
		_render_article()

func _make_card(height: int, name: String, route: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = name
	card.custom_minimum_size = Vector2(0, height)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not route.is_empty() else Control.CURSOR_ARROW
	card.add_theme_stylebox_override("panel", _rounded(Color(0.006, 0.055, 0.13, 0.92), Color("#2c9bc2"), 24, 2, 0.19))
	if not route.is_empty():
		card.gui_input.connect(_card_input.bind(card, route))
		card.mouse_entered.connect(_card_hover.bind(card, true))
		card.mouse_exited.connect(_card_hover.bind(card, false))
	return card

func _card_hover(card: PanelContainer, hovered: bool) -> void:
	if is_instance_valid(card):
		var bg: Color = Color(0.018, 0.11, 0.22, 0.98) if hovered else Color(0.006, 0.055, 0.13, 0.92)
		var edge: Color = BRIGHT_CYAN if hovered else Color("#2c9bc2")
		card.add_theme_stylebox_override("panel", _rounded(bg, edge, 24, 2, 0.24 if hovered else 0.19))

func _card_padding(card: PanelContainer, pad: int) -> HBoxContainer:
	var margins: MarginContainer = MarginContainer.new()
	margins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margins.add_theme_constant_override("margin_left", pad)
	margins.add_theme_constant_override("margin_right", pad)
	margins.add_theme_constant_override("margin_top", 12)
	margins.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margins)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	margins.add_child(row)
	return row

func _icon(texture: Texture2D, side: int, transparent: bool = false) -> Control:
	var icon_frame: PanelContainer = PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(side, side)
	icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if transparent:
		# Planet and station artwork should float inside the outer row, unframed.
		icon_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		icon_frame.add_theme_stylebox_override("panel", _rounded(Color(0.035, 0.11, 0.21, 0.88), Color("#2474a0"), 17, 1, 0.0))
	var inner: MarginContainer = MarginContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inset: int = 1 if transparent else 5
	for margin in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_theme_constant_override(margin, inset)
	icon_frame.add_child(inner)
	if texture != null:
		var img: TextureRect = TextureRect.new()
		img.texture = texture
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(img)
	return icon_frame

func _card_lines(row: HBoxContainer, title_text: String, subtitle_text: String, count_text: String = "") -> void:
	var col: VBoxContainer = VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var compact: bool = _is_compact()
	var title_label: Label = _make_text(title_text, 21 if compact else 28)
	title_label.clip_text = true
	col.add_child(title_label)
	if not subtitle_text.is_empty():
		var short: Label = _make_text(subtitle_text, 14 if compact else 17, MUTED)
		short.max_lines_visible = 2
		short.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(short)
	if not count_text.is_empty():
		col.add_child(_make_text(count_text, 13 if compact else 15, CYAN))
	var arrow: Label = _make_text("›", 31 if compact else 38, BRIGHT_CYAN)
	arrow.custom_minimum_size.x = 27 if compact else 40
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(arrow)

func _section_matches(section: String, needle: String) -> bool:
	if needle.is_empty():
		return true
	var head: String = (_section_title(section) + " " + _ui("teaser_" + section)).to_lower()
	if head.contains(needle):
		return true
	for item in _entries(section):
		if item is Dictionary:
			var article: Dictionary = item
			if (_text_of(section, article, "title") + " " + _text_of(section, article, "description")).to_lower().contains(needle):
				return true
	return false

func _render_home() -> void:
	var needle: String = _query.strip_edges().to_lower()
	var compact: bool = _is_compact()
	for section in SECTIONS:
		if not _section_matches(section, needle):
			continue
		var card: PanelContainer = _make_card(108 if compact else 124, "Section_" + section, "section:" + section)
		_cards.add_child(card)
		var row: HBoxContainer = _card_padding(card, 18 if compact else 24)
		row.add_child(_icon(_texture_if_exists(str(SECTION_ICONS[section])), 70 if compact else 86, section == "planets" or section == "stations"))
		var count: String = _ui("discoveries").replace("{count}", str(_entries(section).size()))
		_card_lines(row, _section_title(section), _ui("teaser_" + section), count)
	if _cards.get_child_count() == 0:
		_render_empty()

func _filtered_entries(section: String) -> Array:
	var items: Array = []
	var needle: String = _query.strip_edges().to_lower()
	for candidate in _entries(section):
		if not (candidate is Dictionary):
			continue
		var item: Dictionary = candidate
		if needle.is_empty() or (_text_of(section, item, "title") + " " + _text_of(section, item, "description") + " " + _text_of(section, item, "system")).to_lower().contains(needle):
			items.append(item)
	return items

func _render_section() -> void:
	var compact: bool = _is_compact()
	for item in _filtered_entries(_section):
		var identifier: String = str(item.get("id", ""))
		var card: PanelContainer = _make_card(96 if compact else 114, "Article_" + identifier, "article:" + identifier)
		_cards.add_child(card)
		var row: HBoxContainer = _card_padding(card, 18 if compact else 24)
		var tex: Texture2D = _article_texture(_section, item)
		row.add_child(_icon(tex, 66 if compact else 86, _section == "planets" or _section == "stations"))
		var secondary: String = _text_of(_section, item, "system")
		if secondary.is_empty():
			secondary = _text_of(_section, item, "role")
		if secondary.is_empty():
			secondary = _text_of(_section, item, "description")
		_card_lines(row, _text_of(_section, item, "title"), secondary)
	if _cards.get_child_count() == 0:
		_render_empty()

func _find_article(section: String, identifier: String) -> Dictionary:
	for raw in _entries(section):
		if raw is Dictionary and str(raw.get("id", "")) == identifier:
			return raw
	return {}

func _render_article() -> void:
	var article: Dictionary = _find_article(_section, _article_id)
	if article.is_empty():
		_render_empty()
		return
	var visual: Texture2D = _article_texture(_section, article)
	if visual != null:
		var floating_art: bool = _section == "planets" or _section == "stations"
		var visual_frame: PanelContainer = PanelContainer.new()
		visual_frame.name = "ArticleImage"
		visual_frame.custom_minimum_size = Vector2(0, 260 if _is_compact() else 350)
		visual_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if floating_art:
			# No extra framed box behind the planet or the station picture.
			visual_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		else:
			visual_frame.add_theme_stylebox_override("panel", _rounded(Color(0.006, 0.055, 0.13, 0.92), Color("#2c9bc2"), 24, 2, 0.19))
		_cards.add_child(visual_frame)
		var art_margin: MarginContainer = MarginContainer.new()
		art_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
			art_margin.add_theme_constant_override(m, 6 if floating_art else 18)
		visual_frame.add_child(art_margin)
		var art: TextureRect = TextureRect.new()
		art.texture = visual
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_margin.add_child(art)
	var description: String = _text_of(_section, article, "description")
	if not description.is_empty():
		_add_reading_block("", description)
	var keys: Array = FIELDS.get(_section, [])
	for field in keys:
		var field_name: String = str(field)
		var body: String = _text_of(_section, article, field_name)
		if not body.is_empty() and body != description:
			_add_reading_block(_label_name(field_name), body)

func _add_reading_block(heading: String, body: String) -> void:
	var card: PanelContainer = _make_card(0, "ReadingBlock", "")
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards.add_child(card)
	var margin: MarginContainer = MarginContainer.new()
	for name in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(name, 23)
	for name in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(name, 19)
	card.add_child(margin)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 9)
	margin.add_child(col)
	if not heading.is_empty():
		col.add_child(_make_text(heading.to_upper(), 14, CYAN))
	col.add_child(_make_text(body, 17 if _is_compact() else 20))

func _render_empty() -> void:
	_add_reading_block("", _ui("empty"))

func _toggle_search() -> void:
	_search_visible = not _search_visible
	_search_input.visible = _search_visible
	if not _search_visible:
		_query = ""
		_search_input.clear()
		_render_cards()
	else:
		_search_input.call_deferred("grab_focus")
	# VBoxContainer immediately relayouts; there are no header coordinates to recalc.

func _on_search_changed(value: String) -> void:
	_query = value
	if _mode == "article":
		_mode = "list"
		_show_page(true)
	else:
		# Never reset the LineEdit or instantiate another search field on typing.
		_render_cards()
		_scroll.set_deferred("scroll_vertical", 0)

func _go_back() -> void:
	_drag_target = ""
	if _mode == "article":
		_mode = "list"
		_show_page(true)
	elif _mode == "list":
		_mode = "home"
		_query = ""
		_search_input.clear()
		_show_page(true)
	else:
		closed.emit()

func _navigate_to(route: String) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_open_ms < 220:
		return
	_last_open_ms = now
	if route.begins_with("section:"):
		_section = route.trim_prefix("section:")
		_article_id = ""
		_mode = "list"
		# Opening a section without a search shows its entire native list.
		_query = ""
		_search_input.clear()
		_search_visible = false
		_search_input.visible = false
	elif route.begins_with("article:"):
		_article_id = route.trim_prefix("article:")
		_mode = "article"
		_query = ""
		_search_input.clear()
		_search_visible = false
		_search_input.visible = false
	_show_page(true)

func _start_drag(route: String, origin: Vector2, kind: String, touch: int = -1) -> void:
	_drag_target = route
	_drag_origin = origin
	_drag_distance = 0.0
	_dragged = false
	_pointer_type = kind
	_touch_id = touch

func _move_drag(delta: Vector2) -> void:
	_drag_distance += delta.length()
	if _drag_distance > 10.0:
		_dragged = true
	if _dragged:
		_scroll.scroll_vertical -= roundi(delta.y)

func _finish_drag(route: String, within: bool) -> void:
	var open: bool = not _dragged and within and route == _drag_target and not route.is_empty()
	_drag_target = ""
	_touch_id = -1
	_pointer_type = ""
	_dragged = false
	if open:
		_navigate_to(route)

func _card_input(event: InputEvent, card: PanelContainer, route: String) -> void:
	if event is InputEventMouseButton:
		var m: InputEventMouseButton = event
		if m.button_index == MOUSE_BUTTON_WHEEL_DOWN or m.button_index == MOUSE_BUTTON_WHEEL_UP:
			var unit: int = 75
			_scroll.scroll_vertical += unit if m.button_index == MOUSE_BUTTON_WHEEL_DOWN else -unit
			card.accept_event()
			return
		if Time.get_ticks_msec() < _ignore_mouse_until:
			return
		if m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed:
				_start_drag(route, m.position, "mouse")
			elif _pointer_type == "mouse":
				_finish_drag(route, Rect2(Vector2.ZERO, card.size).has_point(m.position))
			card.accept_event()
	elif event is InputEventMouseMotion:
		var move: InputEventMouseMotion = event
		if _pointer_type == "mouse" and _drag_target == route and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_move_drag(move.relative)
			card.accept_event()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		_ignore_mouse_until = Time.get_ticks_msec() + 300
		if touch.pressed:
			_start_drag(route, touch.position, "touch", touch.index)
		elif _pointer_type == "touch" and _touch_id == touch.index:
			_finish_drag(route, Rect2(Vector2.ZERO, card.size).has_point(touch.position))
		card.accept_event()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if _pointer_type == "touch" and _touch_id == drag.index and _drag_target == route:
			_move_drag(drag.relative)
			card.accept_event()
	elif event is InputEventPanGesture:
		var pan: InputEventPanGesture = event
		_scroll.scroll_vertical += roundi(pan.delta.y * 65.0)
		card.accept_event()

func _on_scroll_blank_input(event: InputEvent) -> void:
	# Same drag and wheel behavior when a gesture begins in the gap between cards.
	if event is InputEventMouseButton:
		var m: InputEventMouseButton = event
		if m.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll.scroll_vertical += 75
		elif m.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll.scroll_vertical -= 75
		elif m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed:
				_start_drag("", m.position, "mouse")
			elif _pointer_type == "mouse":
				_finish_drag("", false)
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if _pointer_type == "mouse" and _drag_target.is_empty() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_move_drag(motion.relative)
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_start_drag("", touch.position, "touch", touch.index)
		elif _pointer_type == "touch" and _touch_id == touch.index:
			_finish_drag("", false)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if _pointer_type == "touch" and _touch_id == drag.index and _drag_target.is_empty():
			_move_drag(drag.relative)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()
