extends "res://simulator_ui/where_is_it/independent/where_is_it_ui_audio_viewportsafe_v5.gd"
## MIKA Where Is It v5: viewport-safe native shared toolbar and crystal HUD.
## Full-width responsive layout; camera-safe 3D marker projection.
## The original 3D world, word placement, rounds, SFX and localizations stay intact.

const SHARED_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const NATIVE_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")

var _shared_title_panel: Panel = null
var _shared_hud: Control = null
var _shared_body: Panel = null
var _shared_tray: Panel = null
var _shared_ready: bool = false
var _shared_projection_requested: bool = false


func _build_stage() -> void:
    super._build_stage()
    # No approximate look-alike. Hide the old handcrafted top rectangle and
    # the three panels introduced by v1; preserve all functional controls.
    for child in stage.get_children():
        if child is Panel and child != _crystal_panel and child.position.y < 120.0:
            child.visible = false
    _crystal_panel.visible = false
    if _native_main_panel != null:
        _native_main_panel.visible = false
    if _native_left_panel != null:
        _native_left_panel.visible = false
    if _native_right_panel != null:
        _native_right_panel.visible = false
    lang_picker.visible = false
    round_label.visible = false
    score_label.visible = false
    instructions.visible = false
    front_hint.visible = false
    helper.visible = false
    next_button.visible = false
    var legacy_restart: Control = stage.get_node_or_null("RestartAll") as Control
    if legacy_restart != null:
        legacy_restart.visible = false

    _shared_body = _panel(Rect2(0, 0, 10, 10), Color("102C51"), Color("48CEF6"), 24)
    _shared_body.name = "WhereIsIt_OneSharedSimulatorBody"
    stage.move_child(_shared_body, viewport_box.get_index())

    _shared_title_panel = Panel.new()
    _shared_title_panel.name = "WhereIsIt_ActualSharedTitlePlaque"
    _shared_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    SHARED_TOOLBAR.apply_title_style(_shared_title_panel)
    stage.add_child(_shared_title_panel)
    heading.reparent(_shared_title_panel, false)
    subtitle.reparent(_shared_title_panel, false)
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    heading.clip_text = true
    subtitle.clip_text = true
    for element in [heading, subtitle]:
        element.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # Use the real PlanetHub counter already approved for Trace/Write Number.
    _shared_hud = NATIVE_HUD.new() as Control
    _shared_hud.name = "WhereIsIt_OriginalPlanetHubCounter"
    _shared_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _shared_hud.size = Vector2(1680.0, 158.0)
    stage.add_child(_shared_hud)
    for node_name in ["SimulatorButton", "LaunchButton"]:
        var n: Control = _shared_hud.get_node_or_null(node_name) as Control
        if n != null:
            n.hide()
    _shared_hud.set("crystal_count", _session_crystals)

    # The original back glyph stays; use the same simulator host style when available.
    var host: Node = _shared_simulator_host()
    if host != null and host.has_method("_style_back_button"):
        # The original game already added an arrow; the native host will
        # add its own, so remove the older glyph to avoid two arrows.
        for glyph in _back_button.get_children():
            _back_button.remove_child(glyph)
            glyph.free()
        host.call("_style_back_button", _back_button)
    if chip_strip.get_child_count() > 0:
        _shared_tray = chip_strip.get_child(0) as Panel
    _shared_ready = true


func _shared_simulator_host() -> Node:
    var p: Node = get_parent()
    for _i in range(20):
        if p == null:
            break
        if p.has_method("_return_to_cards"):
            return p
        p = p.get_parent()
    return null


func _shared_safe_area(view_size: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view_size)
    var win: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if win.x <= 0 or win.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
        return Rect2(Vector2.ZERO, view_size)
    var factor: Vector2 = view_size / win
    return Rect2(Vector2(safe.position) * factor, Vector2(safe.size) * factor)


func _fit_stage() -> void:
    if stage == null or not _shared_ready:
        return
    _layout_for_viewport(get_viewport_rect().size)


func _layout_for_viewport(view_size: Vector2) -> void:
    if stage == null or not _shared_ready or view_size.x < 190.0 or view_size.y < 190.0:
        return
    var safe: Rect2 = _shared_safe_area(view_size)
    var canvas_size: Vector2 = safe.size
    # No fixed 1280x720 scene or proportional scaling of the whole screen.
    # Each control is positioned in the actual available display pixels.
    # Inset only on phones where the OS reports a physical unsafe area.
    stage.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
    stage.scale = Vector2.ONE
    stage.position = safe.position
    stage.size = canvas_size
    if _real_space != null:
        _real_space.position = Vector2.ZERO
        _real_space.size = view_size

    var available: Rect2 = Rect2(Vector2.ZERO, canvas_size)
    var top_end: float = SHARED_TOOLBAR.relayout(canvas_size, available, _back_button,
            _shared_hud, _shared_title_panel, heading, subtitle)
    var landscape: bool = canvas_size.x >= canvas_size.y * 0.92
    var margin: float = clampf(canvas_size.x * 0.018, 12.0, 28.0)
    var gap: float = clampf(canvas_size.y * 0.015, 8.0, 17.0)
    var tray_h: float = clampf(canvas_size.y * (0.18 if landscape else 0.115), 100.0, 174.0)
    var tray_y: float = canvas_size.y - margin - tray_h
    var game_y: float = top_end + gap
    var body_h: float = maxf(155.0, tray_y - game_y - gap)
    var body: Rect2 = Rect2(Vector2(margin, game_y),
            Vector2(canvas_size.x - 2.0 * margin, body_h))
    _shared_body.position = body.position
    _shared_body.size = body.size

    chip_strip.position = Vector2(margin, tray_y)
    chip_strip.size = Vector2(body.size.x, tray_h)
    if _shared_tray != null:
        _shared_tray.position = Vector2.ZERO
        _shared_tray.size = chip_strip.size
    _shared_layout_chips()

    if landscape:
        var rail_w: float = clampf(body.size.x * 0.115, 105.0, 155.0)
        var inside: float = clampf(body.size.x * 0.013, 10.0, 20.0)
        viewport_box.position = body.position + Vector2(rail_w + inside, 12.0)
        viewport_box.size = Vector2(maxf(170.0, body.size.x - 2.0 * (rail_w + inside)),
                maxf(120.0, body.size.y - 50.0))
        _shared_layout_left(body.position.x + rail_w * 0.5,
                body.position.y + body.size.y * 0.50, rail_w)
        _shared_layout_right(body.end.x - rail_w * 0.5,
                body.position.y + body.size.y * 0.50, rail_w)
    else:
        # Portrait: two separated rows prevent controls from overlapping.
        var control_cx: float = body.position.x + body.size.x * 0.5
        var row_width: float = minf(body.size.x * 0.75, 245.0)
        _shared_layout_left(control_cx, body.position.y + 36.0, row_width, true)
        _shared_layout_right(control_cx, body.position.y + 100.0, row_width, true)
        viewport_box.position = body.position + Vector2(15.0, 170.0)
        viewport_box.size = Vector2(maxf(180.0, body.size.x - 30.0),
                maxf(190.0, body.size.y - 208.0))
    # A larger 3D viewport without distorting cube geometry.
    # SubViewportContainer.stretch drives the child viewport size. Avoid
    # projecting markers in the SAME frame as a synthetic screen resize.
    if not viewport_box.stretch:
        view.size = Vector2i(maxi(1, roundi(viewport_box.size.x)),
                             maxi(1, roundi(viewport_box.size.y)))
    if feedback != null:
        feedback.position = Vector2(body.position.x + 12.0, body.end.y - 37.0)
        feedback.size = Vector2(body.size.x - 24.0, 30.0)
        feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        feedback.add_theme_font_size_override("font_size", 17)
        feedback.clip_text = true
    # Projection depends on the Camera3D's updated viewport transform.
    # During a headless resolution sweep, running unproject_position()
    # immediately after resizing produces transient engine errors.
    _shared_request_projection()


func _shared_request_projection() -> void:
    if _shared_projection_requested or not is_inside_tree():
        return
    _shared_projection_requested = true
    call_deferred("_shared_project_after_resize")


func _shared_project_after_resize() -> void:
    if not is_inside_tree():
        _shared_projection_requested = false
        return
    await get_tree().process_frame
    _shared_projection_requested = false
    if not is_inside_tree() or viewport_box == null or view == null:
        return
    if viewport_box.size.x < 4.0 or viewport_box.size.y < 4.0:
        return
    # The underlying 3D world is unchanged. The markers are reprojected
    # after Godot applies the SubViewportContainer's stretch geometry.
    _update_slot_positions()


func _shared_layout_left(cx: float, cy: float, width: float, row: bool = false) -> void:
    var button_w: float = clampf(width * (0.36 if row else 0.42), 45.0, 76.0)
    var button_h: float = clampf(button_w * 0.84, 38.0, 62.0)
    prev_view_button.size = Vector2(button_w, button_h)
    next_view_button.size = Vector2(button_w, button_h)
    reset_view_button.size = Vector2(button_w * (1.5 if row else 1.75), button_h * 0.82)
    if row:
        prev_view_button.position = Vector2(cx - button_w * 1.60, cy - button_h * 0.5)
        next_view_button.position = Vector2(cx - button_w * 0.45, cy - button_h * 0.5)
        reset_view_button.position = Vector2(cx + button_w * 0.65, cy - button_h * 0.40)
    else:
        prev_view_button.position = Vector2(cx - button_w - 3.0, cy - 57.0)
        next_view_button.position = Vector2(cx + 3.0, cy - 57.0)
        reset_view_button.position = Vector2(cx - reset_view_button.size.x * 0.5, cy + 18.0)


func _shared_layout_right(cx: float, cy: float, width: float, row: bool = false) -> void:
    var b: float = clampf(width * (0.48 if row else 0.48), 45.0, 80.0)
    _native_undo_button.size = Vector2(b * (0.96 if row else 1.22), b * 0.75)
    _native_round_prev.size = Vector2(b * 0.70, b * 0.75)
    _native_round_next.size = Vector2(b * 0.70, b * 0.75)
    if row:
        _native_undo_button.position = Vector2(cx - b * 1.50, cy - b * 0.375)
        _native_round_prev.position = Vector2(cx - b * 0.35, cy - b * 0.375)
        _native_round_next.position = Vector2(cx + b * 0.42, cy - b * 0.375)
        _native_round_number.position = Vector2(cx - b * 0.55, cy + b * 0.43)
    else:
        _native_undo_button.position = Vector2(cx - _native_undo_button.size.x * 0.5, cy - 70.0)
        _native_round_prev.position = Vector2(cx - b * 0.77, cy + 14.0)
        _native_round_next.position = Vector2(cx + b * 0.08, cy + 14.0)
        _native_round_number.position = Vector2(cx - 45.0, cy + 72.0)
    _native_round_number.size = Vector2(90.0, 27.0)


func _shared_layout_chips() -> void:
    if chip_strip == null or chips.is_empty():
        return
    var items: Array = chips.keys()
    var count: int = items.size()
    var gap: float = 13.0
    var left_pad: float = 16.0
    var width: float = maxf(55.0, minf(230.0,
        (chip_strip.size.x - left_pad * 2.0 - gap * float(count - 1)) / float(maxi(count, 1))))
    var total: float = float(count) * width + float(count - 1) * gap
    var x: float = (chip_strip.size.x - total) * 0.5
    var height: float = minf(72.0, chip_strip.size.y - 20.0)
    for i in range(count):
        var b: Button = chips[items[i]] as Button
        if b != null:
            b.position = Vector2(x + float(i) * (width + gap),
                (chip_strip.size.y - height) * 0.5)
            b.size = Vector2(width, height)


func _spawn_chips() -> void:
    super._spawn_chips()
    if _shared_ready:
        _shared_layout_chips()


func _update_score() -> void:
    super._update_score()
    if _shared_hud != null:
        _shared_hud.set("crystal_count", _session_crystals)


func _exit_to_simulator() -> void:
    var host: Node = _shared_simulator_host()
    if host != null:
        host.call("_return_to_cards")
        return
    super._exit_to_simulator()


func _update_slot_positions() -> void:
    # The base game invokes this in _begin_round(), including on the same
    # frame that the 3D subviewport has just been resized. Postpone that one
    # projection until Camera3D has a valid, updated viewport transform.
    if _shared_projection_requested or cube_world == null or viewport_box == null or view == null:
        return
    if viewport_box.size.x < 4.0 or viewport_box.size.y < 4.0:
        return
    super._update_slot_positions()


func _process(_delta: float) -> void:
    # Preserve the original continuous anchor updates when the camera is
    # stable. Do not query Camera3D mid-SubViewport resize.
    if _shared_projection_requested or cube_world == null or viewport_box == null:
        return
    if active_keys.is_empty() or viewport_box.size.x < 4.0 or viewport_box.size.y < 4.0:
        return
    _update_slot_positions()
