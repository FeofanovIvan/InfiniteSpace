extends Control
## MIKA · Evolution illustrated 5 × 5 v2.0 · 25 real transparent PNGs.
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
    "ru": {"title":"ЭВОЛЮЦИЯ: КТО СЛЕДУЮЩИЙ?", "instruction":"Перетащи пропущенное животное на место в цепочке эволюции.", "correct":"Отлично!", "wrong":"Попробуй другое животное"},
    "en": {"title":"EVOLUTION: WHAT COMES NEXT?", "instruction":"Drag the missing animal into the evolution chain.", "correct":"Great job!", "wrong":"Try another animal"},
    "pt": {"title":"EVOLUÇÃO: QUAL VEM DEPOIS?", "instruction":"Arraste o animal que falta para a sequência evolutiva.", "correct":"Muito bem!", "wrong":"Tente outro animal"},
    "es": {"title":"EVOLUCIÓN: ¿QUÉ SIGUE?", "instruction":"Arrastra el animal que falta a la cadena evolutiva.", "correct":"¡Muy bien!", "wrong":"Prueba otro animal"},
    "de": {"title":"EVOLUTION: WER KOMMT ALS NÄCHSTES?", "instruction":"Ziehe das fehlende Tier an seinen Platz in der Evolutionsreihe.", "correct":"Super!", "wrong":"Versuche ein anderes Tier"},
    "fr": {"title":"ÉVOLUTION : QUI VIENT ENSUITE ?", "instruction":"Glisse l’animal manquant à sa place dans la chaîne évolutive.", "correct":"Bravo !", "wrong":"Essaie un autre animal"},
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
        _header_subtitle.text = _word("instruction")
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
    _header_subtitle.text = _word("instruction")
    _header_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _header_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _header_subtitle.clip_text = true
    _header_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header_subtitle.add_theme_color_override("font_color", Color("b7eaff"))
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
    # The header always shows THIS game's score, not the global crystal wallet.
    _counter.set("crystal_count", _score)

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
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
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
    # Two text lines inside ONE shared toolbar: title + translated instruction.
    _header_title.position = Vector2(7.0, _header.size.y * 0.04)
    _header_title.size = Vector2(maxf(20.0, _header.size.x - 14.0), _header.size.y * 0.55)
    _header_subtitle.position = Vector2(7.0, _header.size.y * 0.57)
    _header_subtitle.size = Vector2(maxf(20.0, _header.size.x - 14.0), _header.size.y * 0.38)
    _header_subtitle.show()
    var font: Font = ThemeDB.fallback_font
    var title_size := maxi(11, roundi(_header.size.y * 0.33))
    while title_size > 10 and font.get_string_size(_header_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_size).x > _header_title.size.x - 8.0:
        title_size -= 1
    _header_title.add_theme_font_size_override("font_size", title_size)
    var instruction_size := maxi(9, roundi(_header.size.y * 0.18))
    while instruction_size > 8 and font.get_string_size(_header_subtitle.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, instruction_size).x > _header_subtitle.size.x - 8.0:
        instruction_size -= 1
    _header_subtitle.add_theme_font_size_override("font_size", instruction_size)

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
    if w < 160.0 or h < 120.0:
        _layout_ready = false
        return
    var pad_x: float = clampf(w * 0.035, 8.0, 46.0)
    var arrow_gap: float = clampf(w * 0.026, 11.0, 35.0)
    # Main evolution creatures are LARGE and unframed; the answer cards are smaller.
    var main_side: float = minf((w - 2.0 * pad_x - 4.0 * arrow_gap) / 5.0, h * 0.37)
    var option_side: float = minf(main_side * 0.63, h * 0.24)
    main_side = maxf(24.0, main_side)
    option_side = maxf(20.0, option_side)
    var main_total: float = main_side * 5.0 + arrow_gap * 4.0
    var main_x: float = (w - main_total) * 0.5
    var main_y: float = clampf(h * 0.25 - main_side * 0.1, 12.0, h * 0.29)
    var bottom_pad: float = clampf(h * 0.050, 9.0, 30.0)
    var option_y: float = h - option_side - bottom_pad
    # Keep the choice row visually separate on compact landscape screens.
    if option_y < main_y + main_side + 12.0:
        var available: float = h - bottom_pad - main_y - 12.0
        main_side = minf(main_side, available / 1.65)
        option_side = minf(option_side, main_side * 0.63)
        main_total = main_side * 5.0 + arrow_gap * 4.0
        main_x = (w - main_total) * 0.5
        option_y = h - option_side - bottom_pad
    for i in range(STEPS):
        _slot_rects.append(Rect2(main_x + float(i) * (main_side + arrow_gap), main_y, main_side, main_side))
    var option_gap: float = clampf(option_side * 0.23, 7.0, 34.0)
    var choice_total: float = 5.0 * option_side + 4.0 * option_gap
    if choice_total > w - 2.0 * pad_x:
        option_gap = maxf(4.0, (w - 2.0 * pad_x - 5.0 * option_side) / 4.0)
        choice_total = 5.0 * option_side + 4.0 * option_gap
    var option_x: float = (w - choice_total) * 0.5
    for i in range(STEPS):
        _choice_rects.append(Rect2(option_x + float(i) * (option_side + option_gap), option_y, option_side, option_side))
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
    # Exactly one decoy from EACH other chain. The correct animal is the
    # only candidate belonging to the displayed sequence.
    for chain in range(CHAINS):
        if chain != chain_id:
            _choices.append(Vector2i(chain, randi_range(0, STEPS - 1)))
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
    # Per-game score starts at zero every launch. Global wallet is separate.
    if _counter != null:
        _counter.set("crystal_count", _score)
    var game_state: Node = get_node_or_null("/root/GameState")
    if not _smoke_mode and game_state != null and game_state.has_method("add_coins"):
        game_state.call("add_coins", 1)

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
    var w: float = canvas.size.x
    var h: float = canvas.size.y
    var creature_side: float = _slot_rects[0].size.x
    var current_chain: int = _chain_order[_chain_position]
    for i in range(STEPS):
        var slot: Rect2 = _slot_rects[i]
        var empty: bool = i == _missing_index and not _completed
        if empty:
            _draw_missing_slot(canvas, slot)
        else:
            var completed_missing: bool = i == _missing_index and _completed
            if completed_missing:
                canvas.draw_circle(slot.get_center(), creature_side * 0.48, Color(0.18, 0.86, 0.67, 0.13))
                canvas.draw_arc(slot.get_center(), creature_side * 0.46, 0.0, TAU, 46, MINT, 2.5, true)
            _draw_animal(canvas, slot, Vector2i(current_chain, i), 0.985)
        if i < STEPS - 1:
            _draw_arrow(canvas, Vector2(slot.end.x + 4.0, slot.get_center().y),
                Vector2(_slot_rects[i + 1].position.x - 4.0, slot.get_center().y))
    # Five smaller, clearly distinct cards. Nothing extra in the game field.
    for i in range(STEPS):
        _draw_choice_card(canvas, _choice_rects[i], _choices[i], i == _selected and not _completed)
    if _dragging and _selected >= 0 and _selected < _choices.size():
        var ghost_side: float = _choice_rects[0].size.x * 1.12
        var rect := Rect2(_drag_delta - Vector2.ONE * ghost_side * 0.5, Vector2.ONE * ghost_side)
        _draw_choice_card(canvas, rect, _choices[_selected], true)
    if _completed or _error_seconds > 0.0:
        var feedback: String = _word("correct") if _completed else _word("wrong")
        var feedback_color: Color = MINT if _completed else Color("ff9da9")
        var y: float = minf(h - 5.0, _choice_rects[0].end.y + clampf(h * 0.048, 14.0, 24.0))
        canvas.draw_string(font, Vector2(0.0, y), feedback, HORIZONTAL_ALIGNMENT_CENTER, w,
            clampi(roundi(creature_side * 0.11), 11, 20), feedback_color)

func _draw_missing_slot(canvas: Control, rect: Rect2) -> void:
    var skin := StyleBoxFlat.new()
    skin.anti_aliasing = true
    skin.bg_color = Color(0.07, 0.29, 0.42, 0.24)
    skin.border_color = CYAN
    skin.set_border_width_all(3)
    skin.set_corner_radius_all(clampi(roundi(rect.size.x * 0.13), 10, 30))
    canvas.draw_style_box(skin, rect)
    var font: Font = ThemeDB.fallback_font
    canvas.draw_string(font, Vector2(rect.position.x, rect.get_center().y + rect.size.y * 0.16), "?",
        HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, clampi(roundi(rect.size.x * 0.56), 20, 102), LIGHT)

func _draw_animal(canvas: Control, rect: Rect2, id: Vector2i, padding: float = 0.94) -> void:
    var texture: Texture2D = _assets.get(id) as Texture2D
    if texture == null:
        _draw_placeholder(canvas, rect, id)
        return
    var image_area: Rect2 = rect.grow(-(rect.size.x * (1.0 - padding) * 0.5))
    var dims: Vector2 = texture.get_size()
    var scale_factor: float = minf(image_area.size.x / maxf(1.0, dims.x), image_area.size.y / maxf(1.0, dims.y))
    var fitted: Vector2 = dims * scale_factor
    var dest: Rect2 = Rect2(image_area.get_center() - fitted * 0.5, fitted)
    canvas.draw_texture_rect(texture, dest, false)

func _draw_choice_card(canvas: Control, rect: Rect2, id: Vector2i, selected: bool) -> void:
    var skin := StyleBoxFlat.new()
    skin.anti_aliasing = true
    skin.bg_color = Color(0.065, 0.17, 0.30, 0.96)
    skin.border_color = Color("ffdfa0") if selected else Color("71d9f8")
    skin.set_border_width_all(3 if selected else 2)
    skin.set_corner_radius_all(clampi(roundi(rect.size.x * 0.13), 8, 22))
    skin.shadow_color = Color(0.09, 0.69, 0.91, 0.22)
    skin.shadow_size = 5
    canvas.draw_style_box(skin, rect)
    _draw_animal(canvas, rect.grow(-maxf(3.0, rect.size.x * 0.075)), id, 1.0)

func _draw_placeholder(canvas: Control, rect: Rect2, id: Vector2i) -> void:
    var center := rect.get_center()
    canvas.draw_circle(center, rect.size.x * 0.23, Color(0.10 + id.x * 0.036, 0.32, 0.55 + id.y * 0.06, 0.73))
    var font: Font = ThemeDB.fallback_font
    canvas.draw_string(font, Vector2(rect.position.x, center.y + rect.size.y * 0.08), "%02d" % (id.y + 1),
        HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, clampi(roundi(rect.size.x * 0.30), 12, 48), LIGHT)

func _draw_arrow(canvas: Control, start: Vector2, end: Vector2) -> void:
    var length: float = end.x - start.x
    if length <= 4.0:
        return
    var ink := Color("85e3fa")
    var tip: float = minf(10.0, length * 0.34)
    canvas.draw_line(start, Vector2(end.x - tip * 0.8, start.y), ink, 3.0, true)
    canvas.draw_colored_polygon(PackedVector2Array([
        end, Vector2(end.x - tip, end.y - 6.0), Vector2(end.x - tip, end.y + 6.0)
    ]), ink)
