extends Control
## MIKA Eco Sorting v3 — non-destructive toolbar/score adapter.
## This Control is added to the existing Eco Sort V2 scene. Its original
## middle block, three bins, items, scripts and scoring remain unchanged.

const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")

const WORDS: Dictionary = {
    "ru": {"title":"ЭКОСОРТИРОВКА", "sub":"Переработка · Органика · Мусор", "score":"Очки"},
    "en": {"title":"ECO SORTING", "sub":"Recycling · Compost · Trash", "score":"Score"},
    "pt": {"title":"SEPARAÇÃO ECOLÓGICA", "sub":"Reciclagem · Orgânicos · Lixo", "score":"Pontos"},
    "es": {"title":"CLASIFICACIÓN ECOLÓGICA", "sub":"Reciclaje · Orgánicos · Basura", "score":"Puntos"},
    "fr": {"title":"TRI ÉCOLOGIQUE", "sub":"Recyclage · Compost · Déchets", "score":"Points"},
    "de": {"title":"MÜLLTRENNUNG", "sub":"Recycling · Bioabfall · Restmüll", "score":"Punkte"}
}

var _host: Node
var _cover: ColorRect
var _panel: Panel
var _title: Label
var _subtitle: Label
var _back: Button
var _counter: Control
var _locale: String = "en"
var _last_score: int = -2147483648
var _host_back: Control
var _score_timer: Timer
var _middle: Control
var _middle_initial_pos: Vector2
var _middle_initial_size: Vector2
var _middle_initial_scale: Vector2

func _ready() -> void:
    _host = get_parent()
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    z_index = 100
    if _host is Control:
        set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        size = (_host as Control).size
        (_host as Control).resized.connect(_layout)
    else:
        position = Vector2.ZERO
        size = get_viewport_rect().size
    get_viewport().size_changed.connect(_layout)

    _cover = ColorRect.new()
    _cover.name = "EcoOriginalHeaderCover"
    _cover.color = Color("#07162d")
    _cover.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_cover)

    _panel = Panel.new()
    _panel.name = "EcoNativeTitlePanel"
    _panel.mouse_filter = Control.MOUSE_FILTER_STOP
    TOOLBAR.apply_title_style(_panel)
    add_child(_panel)
    _title = _make_label(_panel, Color("#f5fff9"))
    _subtitle = _make_label(_panel, Color("#b7e7ee"))

    _back = Button.new()
    _back.name = "EcoNativeBack"
    _style_button(_back)
    _back.pressed.connect(_exit_to_cards)
    add_child(_back)
    var arrow: Control = GLYPH.new() as Control
    arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(arrow)
    arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _counter = HUD.new() as Control
    _counter.name = "EcoNativeScoreCounter"
    _counter.size = Vector2(1680.0, 158.0)
    add_child(_counter)
    for key in ["sim_button", "flight_button"]:
        var action: Button = _counter.get(key) as Button
        if action != null:
            action.disabled = true
            action.hide()
    _counter.set("crystal_count", 0)

    _score_timer = Timer.new()
    _score_timer.wait_time = 0.18
    _score_timer.one_shot = false
    _score_timer.timeout.connect(_update_score)
    add_child(_score_timer)
    _score_timer.start()

    _read_locale()
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        mobile.connect("language_changed", _on_language_changed)
    _translate()
    _layout()
    # Scene children receive _ready before their parent root. Do this after
    # the original EcoSort.gd has built the existing board and toolbar.
    call_deferred("_after_original_ready")

func _after_original_ready() -> void:
    _find_host_back()
    _locate_middle()
    _layout()

func _make_label(parent: Control, shade: Color) -> Label:
    var label: Label = Label.new()
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.clip_text = true
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_color_override("font_color", shade)
    parent.add_child(label)
    return label

func _style_button(button: Button) -> void:
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_stylebox_override("normal", KIT.button_style(false))
    button.add_theme_stylebox_override("hover", KIT.button_style(true))
    button.add_theme_stylebox_override("pressed", KIT.button_style(true))
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.add_theme_color_override("font_color", Color("#f7fdff"))

func _read_locale() -> void:
    _locale = "en"
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null:
        _locale = str(mobile.get("language")).to_lower().get_slice("_", 0).get_slice("-", 0)
    elif get_node_or_null("/root/LanguageService") != null:
        var service: Node = get_node_or_null("/root/LanguageService")
        _locale = str(service.get("learning_locale")).to_lower().get_slice("_", 0).get_slice("-", 0)
    if not WORDS.has(_locale):
        _locale = "en"

func _on_language_changed(_language: String) -> void:
    _read_locale()
    _translate()
    _layout()

func _translate() -> void:
    var data: Dictionary = WORDS.get(_locale, WORDS["en"])
    _title.text = str(data["title"])
    _subtitle.text = str(data["sub"])
    _back.tooltip_text = str(data["title"])
    _counter.tooltip_text = str(data["score"])

func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view)
    var screen: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if screen.x < 50.0 or screen.y < 50.0 or safe.size.x < 50:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(safe.position) * (view / screen), Vector2(safe.size) * (view / screen))

func _layout() -> void:
    if _host == null or _cover == null:
        return
    if _host is Control:
        size = (_host as Control).size
    else:
        size = get_viewport_rect().size
    if size.x < 210.0 or size.y < 180.0:
        return
    var safe: Rect2 = _safe_area(size)
    var header_end: float = TOOLBAR.relayout(size, safe, _back, _counter, _panel, _title, _subtitle)
    # Opaque cover hides the OLD top toolbar without touching the middle board.
    # Its z-layer is above the original controls, so old back buttons do not fire.
    _cover.position = Vector2(0.0, 0.0)
    _cover.size = Vector2(size.x, header_end + 3.0)
    _layout_middle(safe, header_end)

func _locate_middle() -> void:
    # Only recognize an explicitly named existing *middle container*.
    # Do not rearrange anonymous controls, bins, items or gameplay scripts.
    var aliases: Array[String] = ["centerblock", "middleblock", "middlepanel", "centerpanel", "gameboard", "sortingboard", "sortingarea", "playarea"]
    for child in _host.get_children():
        if child == self or not (child is Control):
            continue
        var key: String = str(child.name).to_lower().replace("_", "").replace("-", "")
        if key in aliases:
            _middle = child as Control
            break
    if _middle != null:
        _middle_initial_pos = _middle.position
        _middle_initial_size = _middle.size
        _middle_initial_scale = _middle.scale

func _layout_middle(safe: Rect2, header_end: float) -> void:
    if not is_instance_valid(_middle) or _middle_initial_size.x < 100.0 or _middle_initial_size.y < 90.0:
        return
    # Preserve the existing three-bin board and every child. Only fit the
    # original middle container uniformly in the free safe area.
    var margin: float = clampf(safe.size.x * 0.015, 6.0, 24.0)
    var gap: float = clampf(safe.size.y * 0.012, 5.0, 13.0)
    var target: Rect2 = Rect2(
        Vector2(safe.position.x + margin, header_end + gap),
        Vector2(maxf(100.0, safe.size.x - margin * 2.0), maxf(80.0, safe.end.y - (header_end + gap) - margin))
    )
    var scale_factor: float = minf(target.size.x / _middle_initial_size.x, target.size.y / _middle_initial_size.y)
    _middle.scale = _middle_initial_scale * scale_factor
    var drawn_size: Vector2 = _middle_initial_size * _middle.scale
    _middle.position = target.position + (target.size - drawn_size) * 0.5

func _update_score() -> void:
    var value: Variant = _read_score()
    if value == null:
        return
    var current: int = maxi(0, int(value))
    if current != _last_score:
        _last_score = current
        _counter.set("crystal_count", current)

func _read_score() -> Variant:
    if _host == null:
        return null
    var keys: Array[String] = ["_score", "score", "_points", "points", "_correct", "correct_count", "_correct_count", "_game_score", "game_score", "_total_score", "total_score", "_sorted_count", "sorted_count"]
    for item in _host.get_property_list():
        var name: String = str(item.get("name", ""))
        if name in keys:
            var score: Variant = _host.get(name)
            if score is int or score is float:
                return score
    # Fallback for games that store the score only in a Label.
    # Keep it read-only, so old EcoSort scoring still controls the game.
    var queue: Array[Node] = [_host]
    var visited: int = 0
    while not queue.is_empty() and visited < 180:
        var node: Node = queue.pop_front()
        visited += 1
        if node == self:
            continue
        if node is Label:
            var key: String = str(node.name).to_lower()
            if key.contains("score") or key.contains("points") or key.contains("очк"):
                var label_text: String = (node as Label).text
                var number: String = ""
                for c in label_text:
                    if c >= "0" and c <= "9":
                        number += c
                    elif not number.is_empty():
                        break
                if not number.is_empty():
                    return int(number)
        for child in node.get_children():
            queue.append(child)
    return null

func _find_host_back() -> void:
    var ancestor: Node = get_parent().get_parent()
    for _i in range(16):
        if ancestor == null:
            break
        for key in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var found: Control = ancestor.get_node_or_null(key) as Control
            if found != null:
                _host_back = found
                _host_back.hide()
                return
        ancestor = ancestor.get_parent()

func _exit_tree() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()

func _exit_to_cards() -> void:
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "")
        return
    var ancestor: Node = get_parent()
    for _i in range(16):
        if ancestor == null:
            break
        if ancestor.has_method("_v1051_return_to_cards"):
            ancestor.call("_v1051_return_to_cards")
            return
        if ancestor.has_method("_return_to_cards"):
            ancestor.call("_return_to_cards")
            return
        ancestor = ancestor.get_parent()
    var fallback: String = "res://scenes/main.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _exit_to_cards()
        get_viewport().set_input_as_handled()
