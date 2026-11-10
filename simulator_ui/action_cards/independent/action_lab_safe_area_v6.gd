extends "res://simulator_ui/action_cards/independent/action_lab_whole_card_drag_v5.gd"
## Action Lab / Safe Zones v6. Layout + native title/counter only.
## The original v5 game logic, 20 actions, sounds, voice, drag, and crystal
## rewards remain completely unchanged.

const SHARED_HEADER = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const SHARED_KIT = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const CRYSTAL_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")

var _v6_counter_clip: Control
var _v6_counter: Control
var _v6_header_guide: Control
var _v6_safe: Rect2
var _v6_last_crystals: int = -1


func _build_interface() -> void:
    super._build_interface()
    if canvas == null or _branch_title == null:
        return

    # The common title helper positions title/subtitle RELATIVE TO the plaque,
    # unlike v5 (where labels were siblings in the full-width canvas).
    game_header.reparent(_branch_title, false)
    status_label.reparent(_branch_title, false)
    SHARED_HEADER.apply_title_style(_branch_title)
    game_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # Reuse the actual PlanetHub neon crystal artwork, not a stretched
    # manually reconstructed Action Lab counter. Crop out the unused HUD wings.
    _crystal_panel.hide()
    _v6_counter_clip = Control.new()
    _v6_counter_clip.name = "ActionLabNativeCrystalCounterClip_v6"
    _v6_counter_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _v6_counter_clip.clip_contents = true
    canvas.add_child(_v6_counter_clip)
    _v6_counter = CRYSTAL_HUD.new() as Control
    _v6_counter.name = "ActionLabNativePlanetCrystalCounter_v6"
    _v6_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _v6_counter_clip.add_child(_v6_counter)
    # Only the counter artwork is used: never allow the cropped Simulator and
    # Launch wings to intercept gameplay input beyond the visible clip.
    for button_name in ["sim_button", "flight_button"]:
        var inactive: Button = _v6_counter.get(button_name) as Button
        if inactive != null:
            inactive.disabled = true
            inactive.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _v6_header_guide = Control.new()
    _v6_header_guide.name = "HeaderGeometryGuideNotRendered_v6"
    _v6_header_guide.visible = false
    _v6_header_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(_v6_header_guide)
    _v6_last_crystals = -1
    _v6_sync_counter()
    _fit_to_viewport()


func _v6_safe_rect(view: Vector2) -> Rect2:
    # Keep a visible symmetric safety gutter in ordinary landscape screens.
    var left: float = clampf(view.x * 0.036, 16.0, 75.0)
    var right: float = left
    var top: float = clampf(view.y * 0.028, 12.0, 38.0)
    var bottom: float = maxf(top, clampf(view.y * 0.044, 18.0, 60.0))
    # On phones, physical cutouts and gesture bars override smaller gutters.
    if DisplayServer.get_name() in ["Android", "iOS"]:
        var pixels: Vector2i = DisplayServer.screen_get_size()
        var usable: Rect2i = DisplayServer.get_display_safe_area()
        if pixels.x > 0 and pixels.y > 0 and usable.size.x > 0 and usable.size.y > 0:
            left = maxf(left, float(maxi(0, usable.position.x)) / float(pixels.x) * view.x)
            right = maxf(right, float(maxi(0, pixels.x - usable.end.x)) / float(pixels.x) * view.x)
            top = maxf(top, float(maxi(0, usable.position.y)) / float(pixels.y) * view.y)
            bottom = maxf(bottom, float(maxi(0, pixels.y - usable.end.y)) / float(pixels.y) * view.y)
    left = minf(left, view.x * 0.16)
    right = minf(right, view.x * 0.16)
    top = minf(top, view.y * 0.12)
    bottom = minf(bottom, view.y * 0.12)
    return Rect2(Vector2(left, top),
        Vector2(maxf(1.0, view.x - left - right), maxf(1.0, view.y - top - bottom)))


func _v6_sync_counter() -> void:
    if _v6_counter != null and _v6_last_crystals != session_crystals:
        _v6_last_crystals = session_crystals
        _v6_counter.set("crystal_count", session_crystals)


func _fit_to_viewport() -> void:
    # Preserve the original square, image options, and drag animation methods;
    # then move every visible element into the REAL safe rectangle.
    super._fit_to_viewport()
    if _v6_counter_clip == null or _v6_counter == null or _v6_header_guide == null:
        return
    if canvas == null or stage_panel == null or target_panel == null:
        return
    var view: Vector2 = size
    if view.x < 100.0 or view.y < 100.0:
        view = get_viewport_rect().size
    if view.x < 100.0 or view.y < 100.0:
        return
    canvas.scale = Vector2.ONE
    canvas.position = Vector2.ZERO
    canvas.size = view
    _sky.position = Vector2.ZERO
    _sky.size = view
    _v6_safe = _v6_safe_rect(view)

    # EXACT shared simulator heading proportions: 158px source height,
    # 60%-size square back button, 80%-size real crystal counter.
    var header_bottom: float = SHARED_HEADER.relayout(view, _v6_safe,
        _back_button, _v6_header_guide, _branch_title, game_header, status_label)
    var counter_scale: float = _v6_header_guide.scale.x
    var counter_left: float = _v6_header_guide.position.x + 643.0 * counter_scale
    _v6_counter_clip.position = Vector2(counter_left, _v6_header_guide.position.y)
    _v6_counter_clip.size = Vector2(394.0 * counter_scale, 158.0 * counter_scale)
    _v6_counter.position = Vector2(-643.0 * counter_scale, 0.0)
    _v6_counter.scale = Vector2.ONE * counter_scale
    _v6_counter.size = Vector2(1680.0, 158.0)
    _v6_sync_counter()

    _back_button.add_theme_stylebox_override("normal", SHARED_KIT.button_style())
    _back_button.add_theme_stylebox_override("hover", SHARED_KIT.button_style(true))
    _back_button.add_theme_stylebox_override("pressed",
        _style(Color("174366"), Color("65e7ff"), 18, 2))

    # A single safe width for the central board and all five bottom choices.
    var unit: float = minf(view.x / 1280.0, view.y / 720.0)
    var side_margin: float = clampf(_v6_safe.size.x * 0.012, 6.0, 22.0)
    var x: float = _v6_safe.position.x + side_margin
    var width: float = maxf(1.0, _v6_safe.size.x - 2.0 * side_margin)
    var gap: float = maxf(5.0, 10.0 * unit)
    var available_bottom: float = _v6_safe.end.y - maxf(6.0, 8.0 * unit)
    var row_h: float = clampf(_v6_safe.size.y * 0.225, 84.0 * unit, 160.0 * unit)
    var row_top: float = available_bottom - row_h
    var inner: float = maxf(7.0, 16.0 * unit)
    var tile_gap: float = maxf(5.0, 9.0 * unit)
    var tile_w: float = maxf(20.0, (width - inner * 2.0 - tile_gap * 4.0) / 5.0)
    var tile_h: float = minf(row_h * 0.94, tile_w * 1.08)
    var cards_y: float = row_top + (row_h - tile_h) * 0.5
    for i in range(OPTIONS_COUNT):
        var tile: Panel = option_panels[i]
        tile.position = Vector2(x + inner + float(i) * (tile_w + tile_gap), cards_y)
        tile.size = Vector2(tile_w, tile_h)
        option_images[i].position = Vector2(maxf(2.0, 5.0 * unit), maxf(2.0, 4.0 * unit))
        option_images[i].size = Vector2(maxf(1.0, tile_w - maxf(4.0, 10.0 * unit)),
            maxf(1.0, tile_h - maxf(4.0, 8.0 * unit)))

    var main_y: float = header_bottom + gap
    var main_h: float = maxf(50.0, cards_y - main_y - gap)
    stage_panel.position = Vector2(x, main_y)
    stage_panel.size = Vector2(width, main_h)

    # Same 1:1 question as v5; recompute its winning sprite and click area.
    var edge: float = maxf(6.0, 9.0 * unit)
    var caption: float = clampf(main_h * 0.14, 28.0 * unit, 54.0 * unit)
    var between: float = maxf(4.0, 9.0 * unit)
    var available_h: float = maxf(15.0, main_h - edge * 2.0 - caption - between)
    var side: float = maxf(10.0, minf(minf(available_h, width - edge * 2.0), 470.0 * unit))
    var square_x: float = (width - side) * 0.5
    var square_y: float = edge + maxf(0.0, (available_h - side) * 0.18)
    target_panel.position = Vector2(square_x, square_y)
    target_panel.size = Vector2(side, side)
    _branch_stable_frame_rect = Rect2(target_panel.position, target_panel.size)
    _branch_frame_inset = maxf(3.0, 4.0 * unit)
    _branch_frame_ready = true
    _branch_keep_question_frame_stable()
    var inset: float = maxf(4.0, side * 0.035)
    question_label.position = Vector2(inset * 0.4, inset * 0.2)
    question_label.size = Vector2(side - inset * 0.8, side - inset * 0.4)
    question_label.add_theme_font_size_override("font_size", maxi(25, roundi(side * 0.72)))

    var word_y: float = square_y + side + between
    var speaker_size: float = minf(47.0 * unit, caption)
    var name_w: float = minf(width * 0.5, 470.0 * unit)
    var word_gap: float = 9.0 * unit
    var word_group: float = name_w + word_gap + speaker_size
    var word_x: float = (width - word_group) * 0.5
    prompt_word.position = Vector2(word_x, word_y)
    prompt_word.size = Vector2(name_w, caption)
    prompt_word.add_theme_font_size_override("font_size",
        maxi(12, roundi((22.0 if prompt_word.text.length() > 13 else 30.0) * unit)))
    if _v125_speaker != null:
        _v125_speaker.position = Vector2(word_x + name_w + word_gap,
            word_y + (caption - speaker_size) * 0.5)
        _v125_speaker.size = Vector2(speaker_size, speaker_size)
        _v125_speaker.queue_redraw()

    var win_side: float = side * 0.90
    win_sprite.position = Vector2(square_x + (side - win_side) * 0.5,
        square_y + (side - win_side) * 0.5)
    win_sprite.size = Vector2(win_side, win_side)
    win_sprite.pivot_offset = win_sprite.size * 0.5
    next_button.visible = false
    ghost.size = Vector2(maxf(45.0, tile_w * 0.86), maxf(52.0, tile_h * 1.08))
    _branch_refresh_drag_card_geometry()
    _branch_keep_question_frame_stable()


func _process(delta: float) -> void:
    super._process(delta)
    _v6_sync_counter()
