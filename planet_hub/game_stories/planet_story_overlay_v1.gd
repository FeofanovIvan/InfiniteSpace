extends CanvasLayer
## MIKA planet stories v1. One non-invasive overlay for exactly 24 planet games.
## Added as a CHILD of the active game instance by BOTH planet-game launchers.
## Keeps gameplay scripts, the first ten simulator games, and existing toolbars intact.
## Earth v2: four individually placed story buttons beside original exits;
## hide duplicate PlanetHub runner back only for these four Earth games.

const STORIES_PATH: String = "res://planet_hub/game_stories/planet_game_stories_v1.json"
const EARTH_GAMES := ["mw__puzzles", "mw__animal_habitat", "mw__shopping_list", "mw__product_count"]
const NATIVE_EXIT_SOURCE := "res://education/playtown/src/ui/game_exit_button.gd"
const NATIVE_SCORE_SOURCE := "res://education/playtown/src/ui/game_score_panel.gd"
const GAME_CATALOGS := [
    "res://planet_hub/data/planet_game_cards_v204.json",
    "res://planet_hub/data/planet_game_cards_v104.json",
]
const LANG_CODES := ["ru", "en", "pt_BR", "es", "de", "fr"]
const LABELS: Dictionary = {
    "ru": ["История", "История игры", "Закрыть", "История этой игры пока не написана."],
    "en": ["Story", "Game story", "Close", "The story for this game has not been written yet."],
    "pt_BR": ["História", "História do jogo", "Fechar", "A história deste jogo ainda não foi escrita."],
    "es": ["Historia", "Historia del juego", "Cerrar", "La historia de este juego todavía no está escrita."],
    "de": ["Geschichte", "Spielgeschichte", "Schließen", "Die Geschichte für dieses Spiel ist noch nicht geschrieben."],
    "fr": ["Histoire", "Histoire du jeu", "Fermer", "L’histoire de ce jeu n’est pas encore écrite."],
}

var game_id: String = ""
var _stories: Dictionary = {}
var _catalog_titles: Dictionary = {}
var _ui: Control
var _button: Button
var _shield: ColorRect
var _modal: Panel
var _heading: Label
var _close: Button
var _scroller: ScrollContainer
var _story_text: RichTextLabel
var _last_locale: String = ""
var _last_view: Vector2 = Vector2.ZERO
var _tick: float = 0.0
var _planet_runner_back: Control
var _planet_runner_back_previous_visible: bool = true


func _ready() -> void:
    layer = 120
    process_mode = Node.PROCESS_MODE_ALWAYS
    _read_registry()
    if not _stories.has(game_id):
        # A game outside the 24-item registry never receives a button.
        visible = false
        return
    _read_titles()
    _make_ui()
    _hide_duplicate_planet_back()
    _update_language()
    _layout()
    if not get_viewport().size_changed.is_connected(_layout):
        get_viewport().size_changed.connect(_layout)


func _read_registry() -> void:
    if not FileAccess.file_exists(STORIES_PATH):
        push_warning("Planet game stories: registry missing: " + STORIES_PATH)
        return
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORIES_PATH))
    if value is Dictionary:
        var records: Variant = (value as Dictionary).get("games", {})
        if records is Dictionary:
            _stories = records


func _read_titles() -> void:
    for path in GAME_CATALOGS:
        if not FileAccess.file_exists(path):
            continue
        var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (value is Dictionary):
            continue
        var entries: Variant = (value as Dictionary).get("games", {})
        if not (entries is Dictionary):
            continue
        var game: Variant = (entries as Dictionary).get(game_id, {})
        if game is Dictionary:
            var titles: Variant = (game as Dictionary).get("title", {})
            if titles is Dictionary and not (titles as Dictionary).is_empty():
                _catalog_titles = titles
                return


func _locale() -> String:
    var lang: String = "en"
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null:
        var candidate: Variant = mobile.get("language")
        if candidate != null:
            lang = str(candidate)
    else:
        var service: Node = get_node_or_null("/root/LanguageService")
        if service != null:
            var candidate: Variant = service.get("interface_locale")
            if candidate != null:
                lang = str(candidate)
    if lang == "pt" or lang == "pt-BR":
        lang = "pt_BR"
    if lang.begins_with("en_"):
        lang = "en"
    if LANG_CODES.has(lang):
        return lang
    return "en"


func _tr(index: int) -> String:
    var phrases: Array = LABELS.get(_locale(), LABELS["en"])
    return str(phrases[index])


func _game_title() -> String:
    return str(_catalog_titles.get(_locale(), _catalog_titles.get("ru", _catalog_titles.get("en", game_id))))


func _story_value() -> String:
    var row: Variant = _stories.get(game_id, {})
    if not (row is Dictionary):
        return _tr(3)
    var texts: Dictionary = row as Dictionary
    var preferred: String = str(texts.get(_locale(), "")).strip_edges()
    if not preferred.is_empty():
        return preferred
    # When the selected language is not yet translated, fall back to the draft.
    for lang in ["ru", "en"]:
        var fallback: String = str(texts.get(lang, "")).strip_edges()
        if not fallback.is_empty():
            return fallback
    return _tr(3)


func _make_ui() -> void:
    _ui = Control.new()
    _ui.name = "PlanetStoryTransparentOverlay"
    _ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_ui)
    _ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _button = Button.new()
    _button.name = "PlanetStoryToolbarInfoButton"
    _button.text = "i"
    _button.focus_mode = Control.FOCUS_NONE
    _button.mouse_filter = Control.MOUSE_FILTER_STOP
    _button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _button.add_theme_color_override("font_color", Color("EFFBFF"))
    _button.add_theme_color_override("font_hover_color", Color.WHITE)
    _button.add_theme_color_override("font_pressed_color", Color.WHITE)
    _button.add_theme_stylebox_override("normal", _style(Color("103451"), Color("74E3FF"), 15, 2))
    _button.add_theme_stylebox_override("hover", _style(Color("20526E"), Color("AFF7FF"), 15, 2))
    _button.add_theme_stylebox_override("pressed", _style(Color("286480"), Color("FFFFFF"), 15, 2))
    _button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _button.pressed.connect(_open_story)
    _ui.add_child(_button)

    _shield = ColorRect.new()
    _shield.name = "PlanetStoryModalBackdrop"
    _shield.color = Color(0.015, 0.026, 0.058, 0.74)
    _shield.mouse_filter = Control.MOUSE_FILTER_STOP
    _shield.visible = false
    _shield.gui_input.connect(_on_shield_input)
    _ui.add_child(_shield)
    _shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _modal = Panel.new()
    _modal.name = "PlanetStoryRoundedScrollWindow"
    _modal.mouse_filter = Control.MOUSE_FILTER_STOP
    _modal.visible = false
    _modal.add_theme_stylebox_override("panel", _style(Color("091C36", 0.985), Color("77E2FF"), 25, 3))
    _ui.add_child(_modal)

    _heading = Label.new()
    _heading.name = "PlanetStoryTitle"
    _heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _heading.clip_text = true
    _heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _heading.add_theme_color_override("font_color", Color("E8FAFF"))
    _modal.add_child(_heading)

    _close = Button.new()
    _close.name = "PlanetStoryClose"
    _close.text = "×"
    _close.focus_mode = Control.FOCUS_NONE
    _close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _close.add_theme_color_override("font_color", Color("E8FAFF"))
    _close.add_theme_stylebox_override("normal", _style(Color("18344F"), Color("64CDEC"), 13, 2))
    _close.add_theme_stylebox_override("hover", _style(Color("2C5C78"), Color("B0F5FF"), 13, 2))
    _close.add_theme_stylebox_override("pressed", _style(Color("24536E"), Color.WHITE, 13, 2))
    _close.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _close.pressed.connect(_close_story)
    _modal.add_child(_close)

    var line: ColorRect = ColorRect.new()
    line.name = "PlanetStoryDivider"
    line.color = Color("4ABAD6", 0.44)
    line.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _modal.add_child(line)

    _scroller = ScrollContainer.new()
    _scroller.name = "PlanetStoryScrollableText"
    _scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    _scroller.mouse_filter = Control.MOUSE_FILTER_STOP
    _modal.add_child(_scroller)

    _story_text = RichTextLabel.new()
    _story_text.name = "PlanetStoryBody"
    _story_text.bbcode_enabled = false
    _story_text.fit_content = true
    _story_text.scroll_active = false  # Scrolling belongs to the ScrollContainer.
    _story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _story_text.mouse_filter = Control.MOUSE_FILTER_PASS
    _story_text.add_theme_color_override("default_color", Color("D9F1FF"))
    _story_text.add_theme_constant_override("line_separation", 7)
    _scroller.add_child(_story_text)


func _style(fill: Color, edge: Color, radius: int, thickness: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = edge
    style.set_corner_radius_all(radius)
    style.set_border_width_all(thickness)
    style.anti_aliasing = true
    return style


func _on_shield_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if (event as InputEventMouseButton).pressed:
            _close_story()
            _shield.accept_event()
    elif event is InputEventScreenTouch:
        if (event as InputEventScreenTouch).pressed:
            _close_story()
            _shield.accept_event()


func _open_story() -> void:
    _update_language()
    _shield.visible = true
    _modal.visible = true
    _button.release_focus()
    _layout()
    if _scroller != null:
        _scroller.scroll_vertical = 0


func _close_story() -> void:
    _modal.visible = false
    _shield.visible = false


func _input(event: InputEvent) -> void:
    if _modal == null or not _modal.visible:
        return
    if event is InputEventKey:
        var key: InputEventKey = event as InputEventKey
        if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
            _close_story()
            get_viewport().set_input_as_handled()


func _update_language() -> void:
    if _button == null:
        return
    var loc: String = _locale()
    _last_locale = loc
    _button.tooltip_text = _tr(0)
    _heading.text = _tr(1) + " · " + _game_title()
    _story_text.text = _story_value()


func _safe_rect(view: Vector2) -> Rect2:
    var fallback: float = maxf(10.0, view.x * 0.025)
    var rect: Rect2 = Rect2(Vector2(fallback, maxf(7.0, view.y * 0.018)),
        view - Vector2(fallback * 2.0, maxf(14.0, view.y * 0.036)))
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_method("safe_rect"):
        var candidate: Variant = mobile.call("safe_rect", view)
        if candidate is Rect2:
            var provided: Rect2 = candidate
            if provided.size.x > 180.0 and provided.size.y > 150.0:
                rect = provided
    return rect



# The Planet Hub runner adds its own Back at the top-left, even though these
# original PlayTown Earth games have a native GameExitButton. Hide ONLY that
# duplicate. The existing GameExitButton keeps the original portal bridge.
# Restore the runner's button when leaving, so all other planet games work.
func _hide_duplicate_planet_back() -> void:
    if not EARTH_GAMES.has(game_id):
        return
    var ancestor: Node = get_parent()
    for _i in range(9):
        if ancestor == null:
            break
        if ancestor.name == "ExistingPlanetGameRunner":
            var duplicate: Control = ancestor.get_node_or_null("ReturnToExistingPlanetCards") as Control
            if duplicate != null:
                _planet_runner_back = duplicate
                _planet_runner_back_previous_visible = duplicate.visible
                duplicate.visible = false
            return
        ancestor = ancestor.get_parent()


func _exit_tree() -> void:
    if is_instance_valid(_planet_runner_back):
        _planet_runner_back.visible = _planet_runner_back_previous_visible
    _planet_runner_back = null


# Read the actual GameExitButton (not a guessed percentage of the screen).
# Native buttons in these four games may be children of a CanvasLayer or a
# Control; get_global_transform_with_canvas returns SubViewport coordinates.
func _earth_native_rect(source_path: String) -> Rect2:
    var game_root: Node = get_parent()
    if game_root == null:
        return Rect2()
    var stack: Array[Node] = [game_root]
    var inspected: int = 0
    while not stack.is_empty() and inspected < 500:
        var node: Node = stack.pop_back()
        inspected += 1
        if node == self:
            continue
        for child in node.get_children():
            stack.append(child)
        if not (node is Control):
            continue
        var ctl: Control = node as Control
        if not ctl.visible or ctl.size.x < 15.0 or ctl.size.y < 15.0:
            continue
        var script: Script = ctl.get_script() as Script
        if script == null or script.resource_path != source_path:
            continue
        var transform: Transform2D = ctl.get_global_transform_with_canvas()
        var a: Vector2 = transform * Vector2.ZERO
        var b: Vector2 = transform * ctl.size
        return Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)),
            Vector2(absf(b.x - a.x), absf(b.y - a.y)))
    return Rect2()


func _earth_fallback_exit_rect(view: Vector2) -> Rect2:
    # Used only during first-frame layout, before an embedded PlayTown game
    # has computed the sizes of its own controls.
    var s: float = clampf(minf(view.x / 1280.0, view.y / 720.0), 0.57, 1.55)
    match game_id:
        "mw__puzzles":
            return Rect2(40.0 * s, view.y - 120.0 * s, 100.0 * s, 100.0 * s)
        "mw__animal_habitat":
            return Rect2(view.x * 0.31, view.y - 106.0 * s - 18.0, 106.0 * s, 106.0 * s)
        "mw__shopping_list":
            return Rect2(18.0 * s, 18.0 * s, 106.0 * s, 106.0 * s)
        "mw__product_count":
            return Rect2(view.x - 30.0 * s - 76.0 * s, 30.0 * s, 76.0 * s, 76.0 * s)
    return Rect2()


# Pure layout function used by the Earth-specific smoke test.
# Product Count has its score/progress directly LEFT of the exit; putting the
# new story button to the left of the score is the only non-overlapping slot.
func _earth_button_position(safe: Rect2, side: float, exit_rect: Rect2,
        score_rect: Rect2) -> Vector2:
    var gap: float = clampf(side * 0.28, 7.0, 15.0)
    var x: float = exit_rect.end.x + gap
    var y: float = exit_rect.position.y + (exit_rect.size.y - side) * 0.5
    match game_id:
        "mw__puzzles":
            # Bottom left; immediately to the right of the native Exit.
            pass
        "mw__animal_habitat":
            # Bottom center; between Exit and the original crystal counter.
            if score_rect.size.x > 0.0 and x + side + gap > score_rect.position.x:
                x = exit_rect.position.x
                y = exit_rect.position.y - side - gap
        "mw__shopping_list":
            # Upper left; the original shopping-list card begins lower down.
            pass
        "mw__product_count":
            # Upper right, to the left of the score rather than overlapping it.
            if score_rect.size.x > 0.0:
                x = score_rect.position.x - gap - side
            else:
                x = exit_rect.position.x - gap - side
        _:
            return Vector2(safe.position.x, safe.position.y)
    x = clampf(x, safe.position.x + 2.0, safe.end.x - side - 2.0)
    y = clampf(y, safe.position.y + 2.0, safe.end.y - side - 2.0)
    return Vector2(x, y)

func _title_panel_rect(view: Vector2) -> Rect2:
    var game_root: Node = get_parent()
    if game_root == null or game_root is Window:
        return Rect2()
    var best: Rect2 = Rect2()
    var best_score: int = -1
    var pending: Array[Node] = [game_root]
    var inspected: int = 0
    while not pending.is_empty() and inspected < 320:
        var node: Node = pending.pop_back()
        inspected += 1
        if node == self or node == _ui:
            continue
        for child in node.get_children():
            pending.append(child)
        if not (node is Control):
            continue
        var ctl: Control = node as Control
        if not ctl.is_visible_in_tree():
            continue
        var name: String = str(ctl.name).to_lower()
        if name.contains("crystal") or name.contains("score") or name.contains("bottom") or name.contains("answer"):
            continue
        var candidate: bool = name.contains("title") or name.contains("header") or name.contains("toolbar") or name.contains("caption")
        if not candidate:
            continue
        var world: Transform2D = ctl.get_global_transform_with_canvas()
        var scale_xy: Vector2 = world.get_scale()
        var rect: Rect2 = Rect2(world.origin, ctl.size * scale_xy)
        if rect.position.y < -10.0 or rect.position.y > view.y * 0.24:
            continue
        if rect.size.x < 155.0 or rect.size.x > view.x * 0.93:
            continue
        if rect.size.y < 31.0 or rect.size.y > view.y * 0.23:
            continue
        if rect.end.x > view.x + 4.0:
            continue
        var score: int = 0
        if node is Panel:
            score += 5
        if name.contains("title"):
            score += 7
        if name.contains("toolbar"):
            score += 3
        if name.contains("header"):
            score += 2
        if rect.size.x > view.x * 0.25:
            score += 2
        if score > best_score:
            best_score = score
            best = rect
    return best


func _layout() -> void:
    if _ui == null or _button == null:
        return
    var view: Vector2 = get_viewport().get_visible_rect().size
    if view.x < 220.0 or view.y < 170.0:
        return
    _ui.position = Vector2.ZERO
    _ui.size = view
    _shield.position = Vector2.ZERO
    _shield.size = view
    var safe: Rect2 = _safe_rect(view)
    var s: float = clampf(minf(view.x / 1280.0, view.y / 720.0), 0.57, 1.55)
    var btn_side: float = clampf(47.0 * s, 30.0, 68.0)
    if EARTH_GAMES.has(game_id):
        # The four Earth PlayTown games do NOT have the MIKA title toolbar.
        # Locate the real on-screen Exit button in this particular game.
        var exit_rect: Rect2 = _earth_native_rect(NATIVE_EXIT_SOURCE)
        if exit_rect.size.x < 15.0:
            exit_rect = _earth_fallback_exit_rect(view)
        var score_rect: Rect2 = _earth_native_rect(NATIVE_SCORE_SOURCE)
        btn_side = clampf(minf(btn_side, exit_rect.size.y * 0.56), 28.0, 62.0)
        _button.position = _earth_button_position(safe, btn_side, exit_rect, score_rect)
    else:
        var title_rect: Rect2 = _title_panel_rect(view)
        if title_rect.size.x > 180.0:
            var inpad: float = clampf(10.0 * s, 6.0, 18.0)
            btn_side = minf(btn_side, title_rect.size.y - 2.0 * inpad)
            _button.position = Vector2(title_rect.end.x - btn_side - inpad,
                title_rect.position.y + (title_rect.size.y - btn_side) * 0.5)
        else:
            # Native 3-part MIKA toolbar: back on the left, main caption in the
            # middle, original crystal capsule on the right. Stay INSIDE caption.
            var native_scale: float = minf(view.x / 1680.0, view.y / 864.0)
            var gap: float = clampf(safe.size.x * 0.015, 5.0, 22.0)
            var margin: float = clampf(safe.size.x * 0.018, 5.0, 28.0)
            var counter_width: float = 394.0 * 0.8 * native_scale
            var header_height: float = 158.0 * 0.8 * native_scale
            var header_y: float = safe.position.y + clampf(safe.size.y * 0.022, 5.0, 22.0)
            var title_right: float = safe.end.x - margin - counter_width - gap
            btn_side = minf(btn_side, header_height * 0.62)
            _button.position = Vector2(title_right - btn_side - maxf(5.0, 7.0 * s),
                header_y + (header_height - btn_side) * 0.5)
        _button.position.x = clampf(_button.position.x, safe.position.x + 20.0, safe.end.x - btn_side - 10.0)
        _button.position.y = clampf(_button.position.y, safe.position.y + 1.0, safe.position.y + safe.size.y * 0.22)
    _button.size = Vector2.ONE * btn_side
    _button.add_theme_font_size_override("font_size", maxi(18, roundi(btn_side * 0.60)))

    var box_w: float = minf(740.0 * s, safe.size.x * 0.73)
    var box_h: float = minf(500.0 * s, safe.size.y * 0.72)
    box_w = maxf(245.0, minf(box_w, safe.size.x - 18.0))
    box_h = maxf(150.0, minf(box_h, safe.size.y - 14.0))
    _modal.position = safe.position + (safe.size - Vector2(box_w, box_h)) * 0.5
    _modal.size = Vector2(box_w, box_h)
    var p: float = clampf(22.0 * s, 12.0, 30.0)
    var close_side: float = clampf(47.0 * s, 30.0, 55.0)
    _close.size = Vector2.ONE * close_side
    _close.position = Vector2(box_w - p - close_side, p * 0.60)
    _close.add_theme_font_size_override("font_size", maxi(19, roundi(close_side * 0.72)))
    _heading.position = Vector2(p, p * 0.55)
    _heading.size = Vector2(box_w - p * 2.0 - close_side - 9.0, close_side)
    _heading.add_theme_font_size_override("font_size", maxi(14, roundi(25.0 * s)))
    var divider: ColorRect = _modal.get_node("PlanetStoryDivider") as ColorRect
    var divider_y: float = _close.position.y + close_side + 10.0 * s
    divider.position = Vector2(p, divider_y)
    divider.size = Vector2(box_w - p * 2.0, maxf(1.0, 1.5 * s))
    var text_y: float = divider_y + 12.0 * s
    _scroller.position = Vector2(p, text_y)
    _scroller.size = Vector2(box_w - p * 2.0, maxf(38.0, box_h - text_y - p))
    _story_text.custom_minimum_size = Vector2(maxf(85.0, _scroller.size.x - 14.0), 0.0)
    _story_text.add_theme_font_size_override("normal_font_size", maxi(15, roundi(21.0 * s)))
    _last_view = view


func _process(delta: float) -> void:
    if _ui == null:
        return
    _tick += delta
    if _tick < 0.32:
        return
    _tick = 0.0
    if _last_locale != _locale():
        _update_language()
        _layout()
    elif _last_view != get_viewport().get_visible_rect().size:
        _layout()
    else:
        # Toolbars can finish their own layout one frame after _ready.
        _layout()
