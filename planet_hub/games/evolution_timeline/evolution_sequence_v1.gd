extends Control
## MIKA · Evolution sequences v1.0 · a single missing item in each 5-stage story.
## Five editable chains × five assets. The player chooses 1 answer from 5.
## Existing Evolution source/data are preserved for safe rollback.

const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const UI_KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const BACK: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const ITEM_ROOT := "res://planet_hub/games/evolution_timeline/assets/"
const CHAINS := 5
const STEPS := 5
const CYAN := Color("65e7ff")
const LIGHT := Color("e7f8ff")
const MINT := Color("8eeacb")
const BASE := Color("071a30")

const WORDS := {
    "ru": {"title":"ЭВОЛЮЦИЯ: КТО СЛЕДУЮЩИЙ?", "chain":"Цепочка", "pick":"Выбери недостающий предмет", "correct":"Отлично!", "wrong":"Попробуй другой предмет"},
    "en": {"title":"EVOLUTION: WHAT COMES NEXT?", "chain":"Sequence", "pick":"Choose the missing object", "correct":"Great job!", "wrong":"Try another object"},
    "pt": {"title":"EVOLUÇÃO: QUAL VEM DEPOIS?", "chain":"Sequência", "pick":"Escolha o objeto que falta", "correct":"Muito bem!", "wrong":"Tente outro objeto"},
    "es": {"title":"EVOLUCIÓN: ¿QUÉ SIGUE?", "chain":"Secuencia", "pick":"Elige el objeto que falta", "correct":"¡Muy bien!", "wrong":"Prueba otro objeto"},
    "de": {"title":"EVOLUTION: WAS KOMMT DANACH?", "chain":"Reihe", "pick":"Wähle das fehlende Objekt", "correct":"Super!", "wrong":"Versuche ein anderes Objekt"},
    "fr": {"title":"ÉVOLUTION : QUELLE SUITE ?", "chain":"Suite", "pick":"Choisis l'objet manquant", "correct":"Bravo !", "wrong":"Essaie un autre objet"},
}

class SequenceCanvas:
    extends Control
    var game: Control
    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
    func _draw() -> void:
        if game != null:
            game.call("_draw_board", self)

var _language := "en"
var _header: Panel
var _header_title: Label
var _header_subtitle: Label
var _back: Button
var _counter: Control
var _stage: Panel
var _canvas: SequenceCanvas
var _external_back: Array[Button] = []
var _hidden_back_visibility: Dictionary = {}
var _assets: Dictionary = {}
var _chain_order: Array[int] = []
var _chain_position := 0
var _missing_index := 0
var _choices: Array[Vector2i] = []
var _answer_choice := -1
var _selected := -1
var _dragging := false
var _drag_delta := Vector2.ZERO
var _drag_id := -100
var _completed := false
var _auto_seconds := 0.0
var _error_seconds := 0.0
var _score := 0
var _smoke_mode := false
var _slot_rects: Array[Rect2] = []
var _choice_rects: Array[Rect2] = []
var _layout_ready := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    _set_language()
    _build_interface()
    _cache_art()
    _hide_parent_back()
    resized.connect(_layout)
    get_viewport().size_changed.connect(_layout)
    _layout()
    _new_set()
    _start_chain()

func _set_language() -> void:
    var service: Node = get_node_or_null("/root/LanguageService")
    if service != null:
        var value := str(service.get("learning_locale")).to_lower().substr(0, 2)
        if WORDS.has(value):
            _language = value
        if service.has_signal("language_changed") and not service.is_connected("language_changed", Callable(self, "_on_language_changed")):
            service.connect("language_changed", Callable(self, "_on_language_changed"))

func _on_language_changed(_unused: String) -> void:
    _set_language()
    if _header_title != null:
        _header_title.text = _word("title")
    if _canvas != null:
        _canvas.queue_redraw()
    _layout()

func _word(key: String) -> String:
    var words: Dictionary = WORDS.get(_language, WORDS["en"])
    return str(words.get(key, key))

func _build_interface() -> void:
    _header = Panel.new()
    _header.name = "EvolutionNativeToolbar"
    _header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_header)
    add_child(_header)
    _header_title = Label.new()
    _header_title.text = _word("title")
    _header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _header_title.clip_text = true
    _header_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header_title.add_theme_color_override("font_color", LIGHT)
    _header.add_child(_header_title)
    _header_subtitle = Label.new()
    _header_subtitle.text = ""
    _header_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header.add_child(_header_subtitle)

    _back = Button.new()
    _back.name = "EvolutionToolbarBack"
    _back.focus_mode = Control.FOCUS_NONE
    _back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _back.add_theme_stylebox_override("normal", UI_KIT.button_style())
    _back.add_theme_stylebox_override("hover", UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("pressed", UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _back.pressed.connect(_go_back)
    add_child(_back)
    var arrow: Control = BACK.new() as Control
    arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(arrow)
    arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _counter = HUD.new() as Control
    _counter.name = "EvolutionNativeCrystals"
    _counter.size = Vector2(1680, 158)
    add_child(_counter)
    for key in ["sim_button", "flight_button"]:
        var child: Button = _counter.get(key) as Button
        if child != null:
            child.disabled = true
            child.hide()

    _stage = Panel.new()
    _stage.name = "EvolutionLargeStage"
    _stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _stage.clip_contents = true
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.014, 0.072, 0.148, 0.91)
    skin.border_color = CYAN
    skin.set_border_width_all(3)
    skin.set_corner_radius_all(28)
    skin.anti_aliasing = true
    _stage.add_theme_stylebox_override("panel", skin)
    add_child(_stage)
    _canvas = SequenceCanvas.new()
    _canvas.game = self
    _canvas.name = "SequenceFiveSlotsAndFiveChoices"
    _stage.add_child(_canvas)
    _canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var game_state: Node = get_node_or_null("/root/GameState")
    if game_state != null and game_state.has_method("get_coin_balance"):
        _counter.set("crystal_count", int(game_state.call("get_coin_balance")))

func _cache_art() -> void:
    # Art is intentionally optional: missing PNGs are clearly numbered placeholders.
    # Replacing PNGs never requires changing gameplay code.
    for chain in range(CHAINS):
        for step in range(STEPS):
            var id := Vector2i(chain, step)
            var path := _asset_path(id)
            if ResourceLoader.exists(path, "Texture2D"):
                var texture: Texture2D = load(path) as Texture2D
                if texture != null:
                    _assets[id] = texture

func _asset_path(id: Vector2i) -> String:
    return "%schain_%02d_item_%02d.png" % [ITEM_ROOT, id.x + 1, id.y + 1]

func _hide_parent_back() -> void:
    # Simulator and PlanetHub both place their own back on top of the SubViewport.
    # Hide only a currently visible game-level button while this scene is running.
    for node in get_tree().root.find_children("*", "Button", true, false):
        if node.name in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var parent_back := node as Button
            if parent_back != null and parent_back.visible:
                _external_back.append(parent_back)
                _hidden_back_visibility[parent_back] = true
                parent_back.hide()

func _exit_tree() -> void:
    for button in _external_back:
        if is_instance_valid(button) and bool(_hidden_back_visibility.get(button, false)):
            button.show()

func _go_back() -> void:
    for button in _external_back:
        if is_instance_valid(button):
            button.emit_signal("pressed")
            return
    var portal: Node = get_node_or_null("/root/PlayTownPortal")
    if portal != null and bool(portal.get("active")) and portal.has_method("handle_scene_transition"):
        portal.call("handle_scene_transition", "")
        return
    for node in get_tree().root.find_children("*", "Control", true, false):
        if node.has_method("_v1051_return_to_cards"):
            node.call("_v1051_return_to_cards")
            return
        if node.has_method("_return_to_cards"):
            node.call("_return_to_cards")
            return

func _safe_rect() -> Rect2:
    var view: Vector2 = size
    if view.x < 1 or view.y < 1:
        view = get_viewport_rect().size
    if OS.get_name() not in ["Android", "iOS"]:
        return Rect2(Vector2.ZERO, view)
    var window: Vector2 = Vector2(DisplayServer.window_get_size())
    var area: Rect2i = DisplayServer.get_display_safe_area()
    if window.x <= 50 or window.y <= 50 or area.size.x <= 50:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(area.position) * (view / window), Vector2(area.size) * (view / window))

func _layout() -> void:
    if _back == null:
        return
    var viewport_size: Vector2 = size if size.x > 50 and size.y > 50 else get_viewport_rect().size
    var safe: Rect2 = _safe_rect()
    var toolbar_bottom: float = TOOLBAR.relayout(viewport_size, safe, _back, _counter, _header, _header_title, _header_subtitle)
    _header_title.position = Vector2(6.0, 0.0)
    _header_title.size = Vector2(maxf(1.0, _header.size.x - 12.0), _header.size.y)
    _header_subtitle.hide()
    var margin: float = clampf(safe.size.x * 0.018, 6.0, 27.0)
    var gap: float = clampf(safe.size.y * 0.018, 6.0, 17.0)
    _stage.position = Vector2(safe.position.x + margin, toolbar_bottom + gap)
    _stage.size = Vector2(maxf(220.0, safe.size.x - 2.0 * margin), maxf(145.0, safe.end.y - toolbar_bottom - gap - margin))
    _canvas.position = Vector2.ZERO
    _canvas.size = _stage.size
    _compute_rects()
    _canvas.queue_redraw()

func _compute_rects() -> void:
    _slot_rects.clear()
    _choice_rects.clear()
    var w: float = _canvas.size.x
    var h: float = _canvas.size.y
    if w < 160 or h < 120:
        _layout_ready = false
        return
    var margin_x := clampf(w * 0.033, 10.0, 45.0)
    var arrow_space := clampf(w * 0.030, 18.0, 43.0)
    var width_available := w - margin_x * 2.0 - arrow_space * 4.0
    var card_w := minf(width_available / 5.0, h * 0.39)
    card_w = maxf(25.0, card_w)
    var row_gap := clampf(h * 0.085, 12.0, 50.0)
    var row_total := card_w * 2.0 + row_gap
    if row_total > h - 30.0:
        card_w = maxf(25.0, (h - row_gap - 30.0) * 0.5)
    var chain_width := 5.0 * card_w + 4.0 * arrow_space
    var chain_left := (w - chain_width) * 0.5
    var first_y := maxf(12.0, (h - (2.0 * card_w + row_gap)) * 0.47)
    var second_y := first_y + card_w + row_gap
    for index in range(STEPS):
        _slot_rects.append(Rect2(chain_left + float(index) * (card_w + arrow_space), first_y, card_w, card_w))
    var available_for_choices := maxf(0.0, w - 2.0 * margin_x - 5.0 * card_w)
    var choice_gap := available_for_choices / 4.0
    var start_x := (w - 5.0 * card_w - 4.0 * choice_gap) * 0.5
    for index in range(STEPS):
        _choice_rects.append(Rect2(start_x + float(index) * (card_w + choice_gap), second_y, card_w, card_w))
    _layout_ready = true

func _new_set() -> void:
    _chain_order = [0, 1, 2, 3, 4]
    _chain_order.shuffle()
    _chain_position = 0

func _start_chain() -> void:
    _completed = false
    _auto_seconds = 0.0
    _error_seconds = 0.0
    _selected = -1
    _dragging = false
    _missing_index = randi_range(0, STEPS - 1)
    var chain_id: int = _chain_order[_chain_position]
    var right: Vector2i = Vector2i(chain_id, _missing_index)
    _choices.clear()
    _choices.append(right)
    # Four different wrong candidates from the OTHER sequences.
    var pool: Array[Vector2i] = []
    for chain in range(CHAINS):
        if chain == chain_id:
            continue
        for step in range(STEPS):
            pool.append(Vector2i(chain, step))
    pool.shuffle()
    for j in range(4):
        _choices.append(pool[j])
    _choices.shuffle()
    _answer_choice = _choices.find(right)
    _canvas.queue_redraw()

func _advance() -> void:
    _chain_position += 1
    if _chain_position >= CHAINS:
        _new_set()
    _start_chain()

func _award() -> void:
    _completed = true
    _selected = -1
    _dragging = false
    _auto_seconds = 1.0
    _score += 1
    var game_state: Node = get_node_or_null("/root/GameState")
    if not _smoke_mode and game_state != null and game_state.has_method("add_coins"):
        game_state.call("add_coins", 1)
        if game_state.has_method("get_coin_balance"):
            _counter.set("crystal_count", int(game_state.call("get_coin_balance")))
    _canvas.queue_redraw()

func _choose(choice: int) -> void:
    if _completed or choice < 0 or choice >= _choices.size():
        return
    if choice == _answer_choice:
        _award()
    else:
        _error_seconds = 0.68
        _canvas.queue_redraw()

func _local_stage(screen_point: Vector2) -> Vector2:
    return _canvas.get_global_transform_with_canvas().affine_inverse() * screen_point

func _hit_choice(point: Vector2) -> int:
    for i in range(_choice_rects.size()):
        if _choice_rects[i].grow(5).has_point(point):
            return i
    return -1

func _hit_missing(point: Vector2) -> bool:
    return _missing_index < _slot_rects.size() and _slot_rects[_missing_index].grow(12).has_point(point)

func _press(point: Vector2, pointer: int) -> bool:
    if _completed or not _layout_ready or _dragging:
        return false
    var choice := _hit_choice(point)
    if choice >= 0:
        _selected = choice
        _dragging = true
        _drag_id = pointer
        _drag_delta = point
        _canvas.queue_redraw()
        return true
    if _selected >= 0 and _hit_missing(point):
        _choose(_selected)
        return true
    return false

func _move(point: Vector2, pointer: int) -> bool:
    if _dragging and _drag_id == pointer:
        _drag_delta = point
        _canvas.queue_redraw()
        return true
    return false

func _release(point: Vector2, pointer: int) -> bool:
    if not _dragging or _drag_id != pointer:
        return false
    _dragging = false
    _drag_id = -100
    if _hit_missing(point):
        _choose(_selected)
    _canvas.queue_redraw()
    return true

func _input(event: InputEvent) -> void:
    var handled := false
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        handled = _press(_local_stage(t.position), t.index) if t.pressed else _release(_local_stage(t.position), t.index)
    elif event is InputEventScreenDrag:
        var t := event as InputEventScreenDrag
        handled = _move(_local_stage(t.position), t.index)
    elif event is InputEventMouseButton:
        var b := event as InputEventMouseButton
        if b.button_index == MOUSE_BUTTON_LEFT:
            handled = _press(_local_stage(b.position), -1) if b.pressed else _release(_local_stage(b.position), -1)
    elif event is InputEventMouseMotion:
        handled = _move(_local_stage((event as InputEventMouseMotion).position), -1)
    if handled:
        get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _go_back()
        get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
    if _auto_seconds > 0.0:
        _auto_seconds -= delta
        if _auto_seconds <= 0.0:
            _advance()
    if _error_seconds > 0.0:
        _error_seconds = maxf(0.0, _error_seconds - delta)
        _canvas.queue_redraw()

func _draw_board(canvas: Control) -> void:
    if not _layout_ready:
        return
    var font: Font = ThemeDB.fallback_font
    var h: float = canvas.size.y
    var width: float = canvas.size.x
    var step_h: float = _slot_rects[0].size.y
    var header_text := "%s  %d / %d" % [_word("chain"), _chain_position + 1, CHAINS]
    canvas.draw_string(font, Vector2(width * 0.5 - 200.0, maxf(20.0, _slot_rects[0].position.y - 13.0)), header_text,
        HORIZONTAL_ALIGNMENT_CENTER, 400.0, clampi(roundi(step_h * 0.12), 12, 20), Color(0.68, 0.87, 1.0, 0.85))
    for i in range(STEPS):
        var slot: Rect2 = _slot_rects[i]
        var is_blank: bool = i == _missing_index
        var green: bool = _completed and is_blank
        _draw_card(canvas, slot, Vector2i(_chain_order[_chain_position], i),
            is_blank and not green, not is_blank or green, green, false)
        if i < STEPS - 1:
            _draw_arrow(canvas, Vector2(slot.end.x + 6.0, slot.get_center().y),
                Vector2(_slot_rects[i + 1].position.x - 6.0, slot.get_center().y))
    for i in range(STEPS):
        var selected: bool = i == _selected and not _completed
        _draw_card(canvas, _choice_rects[i], _choices[i], false, true, false, selected)
    if _dragging and _selected >= 0 and _selected < _choices.size():
        var ghost_side := step_h * 0.83
        var ghost := Rect2(_drag_delta - Vector2.ONE * ghost_side * 0.5, Vector2.ONE * ghost_side)
        _draw_card(canvas, ghost, _choices[_selected], false, true, false, true)
    var caption := _word("correct") if _completed else (_word("wrong") if _error_seconds > 0.0 else "")
    if not caption.is_empty():
        var text_color := MINT if _completed else Color("ff9c9c")
        var y: float = minf(h - 10.0, _choice_rects[0].end.y + 24.0)
        canvas.draw_string(font, Vector2(0.0, y), caption, HORIZONTAL_ALIGNMENT_CENTER, width,
            clampi(roundi(step_h * 0.115), 12, 20), text_color)

func _draw_card(canvas: Control, rect: Rect2, id: Vector2i, hidden: bool, visible_object: bool, success: bool, selected: bool) -> void:
    var style := StyleBoxFlat.new()
    style.anti_aliasing = true
    style.bg_color = Color("103050") if not hidden else Color("061f36")
    style.border_color = MINT if success else (Color("fbe3a3") if selected else (CYAN if hidden else Color("467a9f")))
    style.set_border_width_all(3 if hidden or selected or success else 2)
    style.set_corner_radius_all(clampi(roundi(rect.size.x * 0.11), 10, 25))
    style.shadow_color = Color(0.04, 0.55, 0.8, 0.20)
    style.shadow_size = 3
    canvas.draw_style_box(style, rect)
    var center := rect.get_center()
    var font: Font = ThemeDB.fallback_font
    if hidden:
        canvas.draw_string(font, Vector2(rect.position.x, center.y + rect.size.y * 0.14), "?",
            HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, clampi(roundi(rect.size.y * 0.55), 20, 72), LIGHT)
    elif visible_object:
        var texture: Texture2D = _assets.get(id) as Texture2D
        if texture != null:
            var inset := maxf(4.0, rect.size.x * 0.055)
            var area := rect.grow(-inset)
            var dims: Vector2 = texture.get_size()
            var factor: float = minf(area.size.x / maxf(1.0, dims.x), area.size.y / maxf(1.0, dims.y))
            var fit := dims * factor
            canvas.draw_texture_rect(texture, Rect2(area.get_center() - fit * 0.5, fit), false)
        else:
            # Deliberate placeholder only: user will supply the 25 real illustrations.
            canvas.draw_arc(center, rect.size.x * 0.32, 0.0, TAU, 48, Color("4e9dbb", 0.55), 2.0, true)
            canvas.draw_circle(center, rect.size.x * 0.20, Color(0.13 + id.x * 0.045, 0.36, 0.48 + id.y * 0.055, 0.78))
            canvas.draw_string(font, Vector2(rect.position.x, center.y + rect.size.y * 0.08), "%02d" % (id.y + 1),
                HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, clampi(roundi(rect.size.y * 0.31), 12, 44), LIGHT)
    if success:
        canvas.draw_circle(rect.position + Vector2(rect.size.x * 0.87, rect.size.y * 0.13), rect.size.x * 0.088, MINT)

func _draw_arrow(canvas: Control, from: Vector2, to: Vector2) -> void:
    var center_y: float = from.y
    var end_x: float = to.x
    var length: float = end_x - from.x
    if length <= 4.0:
        return
    var ink := Color("8cdeef")
    canvas.draw_line(from, Vector2(end_x - minf(9.0, length * 0.31), center_y), ink, 3.0, true)
    var tip := PackedVector2Array([Vector2(end_x, center_y), Vector2(end_x - minf(10.0, length * 0.34), center_y - 7.0), Vector2(end_x - minf(10.0, length * 0.34), center_y + 7.0)])
    canvas.draw_colored_polygon(tip, ink)
