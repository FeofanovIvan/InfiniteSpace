extends Control
## MIKA native Encyclopedia. No independent menu or language control.
## Data belongs to the imported catalog; UI belongs to Infinity Space.
signal closed

const DATA_PATH: String = "res://mika_encyclopedia_v18/data/catalog.json"
const TRANSLATION_PATH: String = "res://mika_encyclopedia_v18/data/article_localizations.json"
const NATIVE_IMAGES_PATH: String = "res://mika_encyclopedia_v18/data/native_asset_links.json"
const CROSSROADS_PATH: String = "res://mika_encyclopedia_v18/data/crossroads_encyclopedia_v96_6_languages.json"
const L: Script = preload("res://mika_encyclopedia_v18/scripts/localized_text.gd")
const STYLE: Script = preload("res://mika_encyclopedia_v18/scripts/kosmo_style.gd")
const SECTION_ORDER: Array[String] = ["planets", "stations", "races", "characters", "science", "terms"]
const SECTIONS_TINT: Dictionary = {
    "planets": Color("#64dff3"), "stations": Color("#a4c0ff"),
    "races": Color("#88f0c5"), "characters": Color("#ffd3ab"),
    "science": Color("#ffe297"), "terms": Color("#dabafa")
}
const BATCH_SIZE: int = 10

var _catalog: Dictionary = {}
var _localizations: Dictionary = {}
var _science: Dictionary = {}
var _native_images: Dictionary = {}
var _science_by_id: Dictionary = {}
var _locale: String = "ru"
var _section: String = ""
var _query: String = ""
var _matches: Array[Dictionary] = []
var _cursor: int = 0
var _safe_root: Control
var _heading: Label
var _subtitle: Label
var _back_button: Button
var _search: LineEdit
var _scroll: ScrollContainer
var _list: VBoxContainer
var _category_grid: GridContainer
var _responsive_images: Array[TextureRect] = []
var _search_timer: Timer
var _loading_more: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_STOP
    L.load_saved()
    _catalog = _read_json(DATA_PATH)
    _localizations = _read_json(TRANSLATION_PATH).get("articles", {})
    _science = _read_json(CROSSROADS_PATH)
    _native_images = _read_json(NATIVE_IMAGES_PATH)
    for raw_topic in _science.get("topics", []):
        if raw_topic is Dictionary:
            var topic: Dictionary = raw_topic
            _science_by_id[str(topic.get("id", ""))] = topic
    _locale = _get_app_locale()
    _construct_native_page()
    _search_timer = Timer.new()
    _search_timer.one_shot = true
    _search_timer.wait_time = 0.16
    _search_timer.process_mode = Node.PROCESS_MODE_ALWAYS
    _search_timer.timeout.connect(_refresh_content)
    add_child(_search_timer)
    resized.connect(_fit_safe_area)
    get_viewport().size_changed.connect(_fit_safe_area)
    _fit_safe_area()
    _open_categories()
    hide()

func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("MIKA Encyclopedia missing: " + path)
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if parsed is Dictionary:
        return parsed
    return {}

func _get_app_locale() -> String:
    var language_service: Node = get_node_or_null("/root/MobileLocale")
    if language_service == null:
        return "ru"
    var code: String = str(language_service.get("language"))
    return code if L.LOCALES.has(code) else "ru"

func set_language(_ignored: String) -> void:
    # The main game owns language selection, never this page.
    _locale = _get_app_locale()
    _apply_locale()
    _refresh_content()

func _tr(key: String) -> String:
    return L.text(key)

func _field(item: Dictionary, field: String) -> String:
    if _section == "science":
        var source_id: String = str(item.get("source_topic_id", ""))
        if _science_by_id.has(source_id):
            var topic: Dictionary = _science_by_id[source_id]
            if field == "title":
                var titles: Dictionary = topic.get("title", {})
                return str(titles.get(_locale, titles.get("ru", item.get(field, ""))))
            if field == "description":
                var answers: Dictionary = topic.get("answers", {})
                var localized_answers: Array = answers.get(_locale, answers.get("ru", []))
                if not localized_answers.is_empty():
                    return str(localized_answers[0])
    var key: String = _section + "/" + str(item.get("id", ""))
    var locales: Dictionary = _localizations.get(key, {})
    var fields: Dictionary = locales.get(_locale, {})
    return str(fields.get(field, item.get(field, "")))

func _label(text_value: String, px: int, tint: Color = Color("#effaff")) -> Label:
    var label: Label = Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", px)
    label.add_theme_color_override("font_color", tint)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _panel_style(soft: bool = false) -> StyleBoxFlat:
    var bg: Color = Color("#071c35") if not soft else Color("#122b4e")
    return STYLE.box(bg, 18, Color("#417a9d"), 1, 14)

func _construct_native_page() -> void:
    var background: ColorRect = ColorRect.new()
    background.name = "MikaEncyclopediaBackground"
    background.color = Color("#061329")
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _safe_root = Control.new()
    _safe_root.name = "MikaScreenSafeArea"
    _safe_root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(_safe_root)

    var outer: VBoxContainer = VBoxContainer.new()
    outer.name = "MikaEncyclopediaLayout"
    outer.add_theme_constant_override("separation", 12)
    _safe_root.add_child(outer)
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var heading_panel: PanelContainer = PanelContainer.new()
    heading_panel.name = "MikaEncyclopediaHeader"
    heading_panel.add_theme_stylebox_override("panel", _panel_style(true))
    outer.add_child(heading_panel)
    var header: HBoxContainer = HBoxContainer.new()
    header.add_theme_constant_override("separation", 14)
    heading_panel.add_child(header)

    _back_button = Button.new()
    _back_button.name = "MikaNavigationBack"
    _back_button.text = _tr("back")
    _back_button.custom_minimum_size = Vector2(112, 52)
    _back_button.focus_mode = Control.FOCUS_ALL
    STYLE.apply_navigation(_back_button, false)
    _back_button.pressed.connect(_go_back)
    header.add_child(_back_button)

    var headings: VBoxContainer = VBoxContainer.new()
    headings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    headings.add_theme_constant_override("separation", 1)
    header.add_child(headings)
    _heading = _label(_tr("book_title"), 28)
    headings.add_child(_heading)
    _subtitle = _label(_tr("book_subtitle"), 14, Color("#b5d6e9"))
    headings.add_child(_subtitle)

    _search = LineEdit.new()
    _search.name = "MikaEncyclopediaSearch"
    _search.placeholder_text = _tr("search_default")
    _search.custom_minimum_size.y = 46
    _search.add_theme_font_size_override("font_size", 18)
    _search.add_theme_color_override("font_color", Color("#effaff"))
    _search.add_theme_stylebox_override("normal", STYLE.box(Color("#0e2a4a"), 13, Color("#4f91b7"), 1, 12))
    _search.add_theme_stylebox_override("focus", STYLE.box(Color("#0e2a4a"), 13, Color("#7feaff"), 2, 12))
    _search.text_changed.connect(_search_changed)
    outer.add_child(_search)

    _scroll = ScrollContainer.new()
    _scroll.name = "MikaEncyclopediaTouchScroll"
    _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    _scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _scroll.follow_focus = true
    outer.add_child(_scroll)

    _list = VBoxContainer.new()
    _list.name = "MikaEncyclopediaArticles"
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list.add_theme_constant_override("separation", 12)
    _scroll.add_child(_list)
    _scroll.get_v_scroll_bar().value_changed.connect(_scroll_position_changed)

func _fit_safe_area() -> void:
    if _safe_root == null:
        return
    var view: Vector2 = get_viewport_rect().size
    var safe: Rect2 = Rect2(Vector2(16.0, 16.0), view - Vector2(32.0, 32.0))
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_method("safe_rect"):
        var queried: Variant = mobile.call("safe_rect", view)
        if queried is Rect2:
            safe = queried
    var pad: float = 7.0
    _safe_root.position = safe.position + Vector2.ONE * pad
    _safe_root.size = safe.size - Vector2.ONE * (2.0 * pad)
    _back_button.custom_minimum_size.x = 88 if view.x < 760 else 112
    _back_button.add_theme_font_size_override("font_size", 16 if view.x < 760 else 18)
    if _category_grid != null:
        _category_grid.columns = 1 if _safe_root.size.x < 570 else 2 if _safe_root.size.x < 910 else 3
    var image_width: float = 92.0 if _safe_root.size.x < 750 else 150.0
    for image: TextureRect in _responsive_images:
        if is_instance_valid(image):
            image.custom_minimum_size.x = image_width

func _apply_locale() -> void:
    if _heading == null:
        return
    _heading.text = _tr("book_title")
    _subtitle.text = _tr("book_subtitle") if _section.is_empty() else _tr("category_" + _section)
    _back_button.text = _tr("back")
    _search.placeholder_text = _tr("search_default") if _section.is_empty() else _tr("search_article")

func open_glossary() -> void:
    _locale = _get_app_locale()
    show()
    _search.text = ""
    _query = ""
    _open_categories()
    _fit_safe_area()
    if _search.has_focus():
        _search.release_focus()

func _clear_list() -> void:
    _responsive_images.clear()
    for child: Node in _list.get_children():
        _list.remove_child(child)
        child.queue_free()
    _category_grid = null

func _open_categories() -> void:
    _section = ""
    _query = ""
    _clear_list()
    _apply_locale()
    _search.visible = false
    var intro: Label = _label(_tr("book_tagline"), 19, Color("#b9e0ee"))
    _list.add_child(intro)
    _category_grid = GridContainer.new()
    _category_grid.columns = 3
    _category_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _category_grid.add_theme_constant_override("h_separation", 12)
    _category_grid.add_theme_constant_override("v_separation", 12)
    _list.add_child(_category_grid)
    var sections: Dictionary = _catalog.get("sections", {})
    for section: String in SECTION_ORDER:
        var entries: Array = sections.get(section, [])
        _add_category_tile(section, entries.size())
    _fit_safe_area()
    _scroll.scroll_vertical = 0

func _add_category_tile(section: String, quantity: int) -> void:
    var tile: PanelContainer = PanelContainer.new()
    tile.name = "Category_" + section
    tile.custom_minimum_size.y = 164
    tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tile.add_theme_stylebox_override("panel", STYLE.box(Color("#0b2846"), 17, SECTIONS_TINT.get(section, STYLE.CYAN), 1, 12))
    _category_grid.add_child(tile)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 6)
    tile.add_child(column)
    var artwork: String = str(STYLE.TILE_IMAGES.get(section, ""))
    var portrait: TextureRect = _picture(artwork, 94.0)
    if portrait != null:
        portrait.custom_minimum_size.y = 94
        portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        column.add_child(portrait)
    var title: Label = _label(_tr("category_" + section), 19, SECTIONS_TINT.get(section, STYLE.CYAN))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(title)
    var count: Label = _label(str(quantity), 15, Color("#c6d6e8"))
    count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(count)
    var hit_area: Button = Button.new()
    hit_area.name = "Open_" + section
    hit_area.flat = true
    hit_area.tooltip_text = _tr("category_" + section)
    hit_area.focus_mode = Control.FOCUS_ALL
    hit_area.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
    hit_area.add_theme_stylebox_override("hover", STYLE.box(Color(0.2, 0.5, 0.7, 0.12), 17, SECTIONS_TINT.get(section, STYLE.CYAN), 1, 2))
    hit_area.add_theme_stylebox_override("focus", STYLE.box(Color.TRANSPARENT, 17, SECTIONS_TINT.get(section, STYLE.CYAN), 2, 2))
    tile.add_child(hit_area)
    hit_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hit_area.pressed.connect(_open_section.bind(section))

func _picture(path: String, width_px: float) -> TextureRect:
    if path.is_empty() or not ResourceLoader.exists(path):
        return null
    var texture: Texture2D = load(path) as Texture2D
    if texture == null:
        return null
    var rect: TextureRect = TextureRect.new()
    rect.texture = texture
    rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    rect.clip_contents = true
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    rect.custom_minimum_size = Vector2(width_px, 100.0)
    return rect

func _open_section(section: String) -> void:
    _section = section
    _search.visible = true
    _search.text = ""
    _query = ""
    _apply_locale()
    _refresh_content()

func _search_changed(value: String) -> void:
    _query = value.strip_edges().to_lower()
    _search_timer.start()

func _refresh_content() -> void:
    if _section.is_empty():
        _open_categories()
        return
    _clear_list()
    _matches.clear()
    _cursor = 0
    var all_sections: Dictionary = _catalog.get("sections", {})
    var entries: Array = all_sections.get(_section, [])
    for raw_item in entries:
        if not raw_item is Dictionary:
            continue
        var item: Dictionary = raw_item
        var searchable: String = _field(item, "title") + " " + _field(item, "description") + " " + _field(item, "system") + " " + _field(item, "race")
        if _query.is_empty() or searchable.to_lower().contains(_query):
            _matches.append(item)
    var summary: Label = _label(_tr("category_" + _section) + " · " + str(_matches.size()), 20, SECTIONS_TINT.get(_section, STYLE.CYAN))
    _list.add_child(summary)
    if _matches.is_empty():
        _list.add_child(_label(_tr("empty"), 17, Color("#aac5df")))
        return
    _append_batch()
    _scroll.scroll_vertical = 0

func _append_batch() -> void:
    if _loading_more:
        return
    _loading_more = true
    var until: int = mini(_cursor + BATCH_SIZE, _matches.size())
    while _cursor < until:
        _add_article_row(_matches[_cursor])
        _cursor += 1
    _loading_more = false

func _scroll_position_changed(value: float) -> void:
    if _scroll == null or _cursor >= _matches.size() or _section.is_empty():
        return
    var bar: VScrollBar = _scroll.get_v_scroll_bar()
    if value + bar.page >= bar.max_value - 160.0:
        call_deferred("_append_batch")

func _image_path(item: Dictionary) -> String:
    # Prefer the actual approved game portrait. Never substitute unrelated
    # pictures, and never duplicate existing app assets.
    var paths: Array[String] = []
    var portrait: String = str(item.get("source_portrait", ""))
    if not portrait.is_empty():
        paths.append(portrait)
    var scene_art: String = str(item.get("image", ""))
    if not scene_art.is_empty():
        paths.append(scene_art)
    var linked: String = str(_native_images.get(_section + "/" + str(item.get("id", "")), ""))
    if not linked.is_empty():
        paths.append(linked)
    for path: String in paths:
        if ResourceLoader.exists(path):
            return path
    # A race-group silhouette is an explicit fallback in the source data.
    var fallback: String = str(item.get("fallback_illustration", ""))
    if not fallback.is_empty() and ResourceLoader.exists(fallback):
        return fallback
    return ""

func _add_article_row(item: Dictionary) -> void:
    var card: PanelContainer = PanelContainer.new()
    card.add_theme_stylebox_override("panel", _panel_style(true))
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list.add_child(card)
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    card.add_child(row)
    var image_path: String = _image_path(item)
    var pic: TextureRect = _picture(image_path, 150.0)
    if pic != null:
        pic.custom_minimum_size.y = 132
        row.add_child(pic)
        _responsive_images.append(pic)
    else:
        var emblem: Label = _label("✦", 28, SECTIONS_TINT.get(_section, STYLE.CYAN))
        emblem.custom_minimum_size.x = 46
        emblem.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        row.add_child(emblem)
    var body: VBoxContainer = VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 8)
    row.add_child(body)
    body.add_child(_label(_field(item, "title"), 23, SECTIONS_TINT.get(_section, STYLE.CYAN)))
    var meta: String = _field(item, "system")
    if not meta.is_empty():
        body.add_child(_label(meta, 15, Color("#9fc7df")))
    var description: String = _field(item, "description")
    if not description.is_empty():
        body.add_child(_label(description, 18, Color("#f1f8ff")))
    if _section == "science":
        var source_id: String = str(item.get("source_topic_id", ""))
        if _science_by_id.has(source_id):
            var topic: Dictionary = _science_by_id[source_id]
            var questions: Dictionary = topic.get("questions", {})
            var answers: Dictionary = topic.get("answers", {})
            var localized_q: Array = questions.get(_locale, questions.get("ru", []))
            var localized_a: Array = answers.get(_locale, answers.get("ru", []))
            for i: int in range(mini(localized_q.size(), localized_a.size())):
                if i == 0:
                    continue # First answer is already shown as the description.
                body.add_child(_label(str(localized_q[i]), 17, Color("#86e9f3")))
                body.add_child(_label(str(localized_a[i]), 17, Color("#d7eaf6")))
    else:
        var extras: Array[String] = ["world_type", "nature", "building", "science_fact", "race", "appearance", "interior", "role", "work", "knowledge", "where_in_game", "fun_fact", "principle", "details"]
        for key: String in extras:
            var val: String = _field(item, key)
            if val.is_empty() or val == description:
                continue
            var prefix: String = _tr(key)
            if prefix == key:
                prefix = ""
            body.add_child(_label((prefix + ": " if not prefix.is_empty() else "") + val, 16, Color("#bdd5e6")))

func _go_back() -> void:
    if _section.is_empty():
        hide()
        closed.emit()
        return
    _search.release_focus()
    _open_categories()

func _unhandled_key_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed("ui_cancel"):
        _go_back()
        get_viewport().set_input_as_handled()
