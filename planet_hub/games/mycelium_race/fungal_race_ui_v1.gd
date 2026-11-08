extends "res://planet_hub/games/mycelium_race/MyceliumRace.gd"
## MIKA Fungal Race — UI refresh v1.
## Extends the untouched original gameplay. Native toolbar, responsive field and
## three nutrient cards replace the old fixed design / logos / selectors.

const SHARED_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD_NATIVE = preload("res://planet_hub/scripts/bottom_hud.gd")
const BACK_GLYPH = preload("res://simulator_ui/back_arrow_glyph.gd")
const UI_KIT = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const SPACE_BG = preload("res://simulator_ui/scripts/real_space_background.gd")
const VICTORY_SFX = preload("res://education/playtown/audio/sfx/correct.ogg")

var _race_space: Control
var _race_back: Button
var _race_counter: Control
var _race_title_panel: Panel
var _race_title: Label
var _race_subtitle: Label
var _race_audio: AudioStreamPlayer
var _race_stage: Rect2 = Rect2(30.0, 150.0, 1220.0, 395.0)
var _race_cards: Array[Rect2] = []
var _race_stage_origin: Vector2 = Vector2.ZERO
var _race_stage_scale: Vector2 = Vector2.ONE
var _race_outer_back: Control
var _race_last_window: Vector2 = Vector2.ZERO

func _ready() -> void:
    # The visible version is a race. Keep all original feeding/score/growth rules.
    _race_mode = 1
    process_mode = Node.PROCESS_MODE_ALWAYS
    super._ready()
    _race_find_host_back()
    _layout()
    call_deferred("_layout")

func _create_controls() -> void:
    super._create_controls()
    for legacy in [_title, _subtitle, _instruction, _supplies_lbl, _rival_lbl, _language, _mode, _hint, _bonus]:
        if legacy != null:
            legacy.hide()
    _race_space = SPACE_BG.new() as Control
    _race_space.name = "FungalRaceSharedSpace"
    _race_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _race_space.z_index = -20
    add_child(_race_space)
    _race_title_panel = Panel.new()
    _race_title_panel.name = "FungalRaceNativeTitlePanel"
    _race_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    SHARED_TOOLBAR.apply_title_style(_race_title_panel)
    add_child(_race_title_panel)
    _race_title = _header_label()
    _race_title_panel.add_child(_race_title)
    _race_subtitle = _header_label()
    _race_title_panel.add_child(_race_subtitle)
    _race_back = Button.new()
    _race_back.name = "FungalRaceNativeBack"
    _race_back.focus_mode = Control.FOCUS_NONE
    _race_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _race_back.add_theme_stylebox_override("normal", UI_KIT.button_style())
    _race_back.add_theme_stylebox_override("hover", UI_KIT.button_style(true))
    _race_back.add_theme_stylebox_override("pressed", UI_KIT.button_style(true))
    _race_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _race_back.pressed.connect(_race_exit)
    add_child(_race_back)
    var glyph: Control = BACK_GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _race_back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _race_counter = HUD_NATIVE.new() as Control
    _race_counter.name = "FungalRaceNativeCrystalCounter"
    _race_counter.size = Vector2(1680.0, 158.0)
    add_child(_race_counter)
    # Only the genuine center capsule. Its other buttons are never duplicated.
    var simulator: Button = _race_counter.get("sim_button") as Button
    var flight: Button = _race_counter.get("flight_button") as Button
    if simulator != null:
        simulator.disabled = true
        simulator.hide()
    if flight != null:
        flight.disabled = true
        flight.hide()
    _race_counter.set("crystal_count", _score)
    _restart.name = "FungalRaceRestart"
    _restart.text = "↻"
    _restart.tooltip_text = "Restart"
    _race_audio = AudioStreamPlayer.new()
    _race_audio.bus = "SFX"
    add_child(_race_audio)

func _header_label() -> Label:
    var node := Label.new()
    node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    node.clip_text = true
    return node

func _refresh_text() -> void:
    super._refresh_text()
    if _race_title != null:
        _race_title.text = _tr("title")
        _race_subtitle.text = _tr("subtitle")
    if _restart != null:
        _restart.text = "↻"
        _restart.tooltip_text = _tr("restart")
    _layout()

func _update_ui() -> void:
    super._update_ui()
    if _race_counter != null:
        # Local round score only. Do not alter GameState or the player's wallet.
        _race_counter.set("crystal_count", _score)

func _finish(success: bool) -> void:
    var already_finished: bool = _finished
    super._finish(success)
    if success and not already_finished and _race_audio != null:
        _race_audio.stream = VICTORY_SFX
        _race_audio.play()

func _race_safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view)
    var screen: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if screen.x < 50.0 or screen.y < 50.0 or safe.size.x < 50:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(safe.position) * (view / screen), Vector2(safe.size) * (view / screen))

func _layout() -> void:
    if _race_back == null or size.x < 200.0 or size.y < 165.0:
        return
    _race_space.position = Vector2.ZERO
    _race_space.size = size
    var safe: Rect2 = _race_safe_area(size)
    var header_bottom: float = SHARED_TOOLBAR.relayout(size, safe, _race_back, _race_counter, _race_title_panel, _race_title, _race_subtitle)
    var margin: float = clampf(safe.size.x * 0.015, 6.0, 22.0)
    var gap: float = clampf(safe.size.y * 0.013, 5.0, 14.0)
    var content_top: float = header_bottom + gap
    var content_h: float = maxf(110.0, safe.end.y - content_top - margin)
    var nutrient_h: float = clampf(content_h * 0.23, 66.0, 148.0)
    nutrient_h = minf(nutrient_h, content_h * 0.39)
    var stage_h: float = maxf(75.0, content_h - nutrient_h - gap)
    var content_w: float = maxf(150.0, safe.size.x - margin * 2.0)
    _race_stage = Rect2(Vector2(safe.position.x + margin, content_top), Vector2(content_w, stage_h))
    _race_stage_scale = Vector2(_race_stage.size.x / PLAY_PANEL.size.x, _race_stage.size.y / PLAY_PANEL.size.y)
    _race_stage_origin = _race_stage.position - PLAY_PANEL.position * _race_stage_scale
    _race_cards.clear()
    var card_gap: float = clampf(content_w * 0.012, 5.0, 17.0)
    var card_w: float = (content_w - card_gap * 2.0) / 3.0
    var resource_y: float = _race_stage.end.y + gap
    for i in range(3):
        var card: Rect2 = Rect2(safe.position.x + margin + float(i) * (card_w + card_gap), resource_y, card_w, nutrient_h)
        _race_cards.append(card)
        var icon_width: float = minf(card.size.y * 0.88, card.size.x * 0.30)
        var label_x: float = icon_width + 8.0
        var title_rect: Rect2 = Rect2(card.position + Vector2(label_x, 7.0), Vector2(maxf(20.0, card.size.x - label_x - 37.0), card.size.y * 0.48))
        var count_rect: Rect2 = Rect2(card.end.x - minf(38.0, card_w * 0.17), card.position.y + card.size.y * 0.48, minf(33.0, card_w * 0.16), card.size.y * 0.40)
        _race_place_label(_supply_titles[i], title_rect, maxi(10, roundi(card.size.y * 0.19)))
        _race_place_label(_supply_counts[i], count_rect, maxi(13, roundi(card.size.y * 0.23)))
        _supply_titles[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        _supply_counts[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var metric_font: int = maxi(11, roundi(minf(_race_stage_scale.x, _race_stage_scale.y) * 16.0))
    _race_place_design(_score_lbl, Rect2(70, 157, 265, 32), metric_font)
    _race_place_design(_step_lbl, Rect2(70, 190, 275, 30), metric_font)
    _race_place_design(_time_lbl, Rect2(936, 158, 270, 33), metric_font)
    _race_place_design(_need_title, Rect2(428, 158, 426, 26), maxi(10, metric_font))
    _race_place_design(_need_value, Rect2(421, 184, 440, 42), maxi(15, roundi(metric_font * 1.55)))
    _race_place_design(_feedback, Rect2(397, 479, 487, 28), metric_font)
    _race_place_design(_again, Rect2(508, 421, 266, 57), maxi(13, metric_font))
    _race_place_design(_overlay_title, Rect2(185, 270, 910, 51), maxi(17, roundi(metric_font * 1.8)))
    _race_place_design(_overlay_detail, Rect2(204, 337, 875, 52), maxi(12, metric_font))
    var restart_h: float = clampf(stage_h * 0.115, 27.0, 49.0)
    var restart_w: float = clampf(content_w * 0.10, 70.0, 124.0)
    _restart.scale = Vector2.ONE
    _restart.size = Vector2(restart_w, restart_h)
    _restart.position = _race_stage.end - Vector2(restart_w + 12.0, restart_h + 11.0)
    _restart.add_theme_font_size_override("font_size", maxi(18, roundi(restart_h * 0.64)))
    queue_redraw()

func _race_place_label(node: Control, area: Rect2, font_size: int) -> void:
    node.scale = Vector2.ONE
    node.position = area.position
    node.size = area.size
    if node is Label:
        (node as Label).add_theme_font_size_override("font_size", font_size)
    elif node is Button:
        (node as Button).add_theme_font_size_override("font_size", font_size)

func _race_place_design(node: Control, logical: Rect2, font_size: int) -> void:
    node.scale = _race_stage_scale
    node.position = _race_stage_origin + logical.position * _race_stage_scale
    node.size = logical.size
    if node is Label:
        (node as Label).add_theme_font_size_override("font_size", font_size)
    elif node is Button:
        (node as Button).add_theme_font_size_override("font_size", font_size)

func _resource_at(point: Vector2) -> int:
    for i in range(_race_cards.size()):
        if _race_cards[i].has_point(point):
            return i
    return -1

func _race_design_to_screen(logical: Vector2) -> Vector2:
    return _race_stage_origin + logical * _race_stage_scale

func _input(event: InputEvent) -> void:
    if _finished or _busy:
        return
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event
        if mouse_event.button_index == MOUSE_BUTTON_LEFT:
            if mouse_event.pressed:
                _race_press(mouse_event.position)
            else:
                _race_release(mouse_event.position)
    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _race_press(touch.position)
        else:
            _race_release(touch.position)
    elif event is InputEventMouseMotion:
        if _pressed_resource >= 0:
            _race_move(event.position)
        else:
            _hover_resource = _resource_at(event.position)
    elif event is InputEventScreenDrag:
        if _pressed_resource >= 0:
            _race_move(event.position)

func _race_press(point: Vector2) -> void:
    var which: int = _resource_at(point)
    if which < 0:
        return
    _pressed_resource = which
    _press_point = point
    _drag_point = point
    _dragging = false
    get_viewport().set_input_as_handled()
    queue_redraw()

func _race_move(point: Vector2) -> void:
    _drag_point = point
    if point.distance_to(_press_point) > 13.0:
        _dragging = true
    queue_redraw()
    get_viewport().set_input_as_handled()

func _race_release(point: Vector2) -> void:
    if _pressed_resource < 0:
        return
    var index: int = _pressed_resource
    var was_dragged: bool = _dragging
    _pressed_resource = -1
    _dragging = false
    _hover_resource = -1
    var goal: Vector2 = _race_design_to_screen(PATH_POINTS[mini(_step + 1, PATH_POINTS.size() - 1)])
    var radius: float = maxf(35.0, 104.0 * minf(_race_stage_scale.x, _race_stage_scale.y))
    if not was_dragged or point.distance_to(goal) < radius:
        _attempt_feed(index)
    queue_redraw()
    get_viewport().set_input_as_handled()

func _draw() -> void:
    if _race_cards.size() != 3 or _race_stage.size.x <= 0.0:
        return
    # The original path, resource requirements and moving rival are unchanged.
    # Only drawing of the old HUD, star logo and resource frame is replaced.
    draw_set_transform(_race_stage_origin, 0.0, _race_stage_scale)
    _draw_stage()
    for sparkle in _sparkles:
        var life: float = clampf(float(sparkle["life"]), 0.0, 1.0)
        var tint: Color = sparkle["color"]
        draw_circle(sparkle["point"], 1.0 + life * 4.0, Color(tint.r, tint.g, tint.b, life * 0.7))
    if _finished:
        _draw_end_panel()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    var frame := StyleBoxFlat.new()
    frame.bg_color = Color.TRANSPARENT
    frame.border_color = Color("65e7ff")
    frame.set_border_width_all(3)
    frame.set_corner_radius_all(25)
    frame.anti_aliasing = true
    draw_style_box(frame, _race_stage)
    for i in range(3):
        var card: Rect2 = _race_cards[i]
        var c: Color = RESOURCE_COLORS[i]
        var hover: bool = _hover_resource == i or (_hint_enabled and _current_need() == RESOURCE_KEYS[i])
        var empty: bool = int(_supplies.get(RESOURCE_KEYS[i], 0)) <= 0
        var skin := StyleBoxFlat.new()
        skin.bg_color = Color("142534") if empty else (Color("1c4a5c") if hover else Color("0c213b"))
        skin.border_color = c if hover else Color(c.r, c.g, c.b, 0.65)
        skin.set_border_width_all(3 if hover else 2)
        skin.set_corner_radius_all(20)
        skin.anti_aliasing = true
        draw_style_box(skin, card)
        var icon_c: Vector2 = Vector2(card.position.x + minf(card.size.y * 0.43, card.size.x * 0.15), card.get_center().y)
        draw_circle(icon_c, minf(card.size.y * 0.30, card.size.x * 0.13), Color(c.r, c.g, c.b, 0.13))
        _draw_nutrient_icon(i, icon_c, minf(card.size.y / 135.0, card.size.x / 260.0))
        for j in range(4):
            var on: bool = j < int(_supplies.get(RESOURCE_KEYS[i], 0))
            var led_x: float = card.position.x + minf(card.size.y * 0.76, card.size.x * 0.26) + float(j) * clampf(card.size.x * 0.085, 9.0, 25.0)
            draw_circle(Vector2(led_x, card.end.y - clampf(card.size.y * 0.20, 10.0, 23.0)), clampf(card.size.y * 0.045, 2.6, 5.4), c if on else Color("29495d"))
    if _dragging and _pressed_resource >= 0:
        var color: Color = RESOURCE_COLORS[_pressed_resource]
        draw_circle(_drag_point, 33.0, Color(color.r, color.g, color.b, 0.23))
        _draw_nutrient_icon(_pressed_resource, _drag_point, 0.76)

func _draw_end_panel() -> void:
    # Explicitly excludes the previous STAR_ICON logo and full-screen dimming.
    _box(Rect2(175, 241, 929, 267), Color("0c2640"), Color("65e7ff"), 29, 3)
    _box(Rect2(189, 254, 900, 239), Color("0c1e34"), Color("315f76"), 22, 2)

func _race_find_host_back() -> void:
    var parent_node: Node = get_parent()
    for i in range(16):
        if parent_node == null:
            break
        for name in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var original: Control = parent_node.get_node_or_null(name) as Control
            if original != null:
                _race_outer_back = original
                original.hide()
                return
        parent_node = parent_node.get_parent()

func _exit_tree() -> void:
    if is_instance_valid(_race_outer_back):
        _race_outer_back.show()

func _race_exit() -> void:
    var portal: Node = get_node_or_null("/root/PlayTownPortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "")
        return
    var parent_node: Node = get_parent()
    for i in range(16):
        if parent_node == null:
            break
        if parent_node.has_method("_v1051_return_to_cards"):
            parent_node.call("_v1051_return_to_cards")
            return
        if parent_node.has_method("_return_to_cards"):
            parent_node.call("_return_to_cards")
            return
        parent_node = parent_node.get_parent()
    var fallback: String = "res://education/playtown/scenes/screens/game_select_school.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _race_exit()
        get_viewport().set_input_as_handled()
