extends "res://learning/src/features/draw_this/draw_this_game.gd"
## MIKA / Draw It native responsive toolbar v1.
## This subclasses the working v100.2 drawing game: no tool, audio, drawing,
## preview, colour selection or free-draw logic is rewritten.

const MIKA_SHARED_DRAW_TOOLBAR := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_DRAW_HUB := preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_DRAW_BACK_GLYPH := preload("res://simulator_ui/back_arrow_glyph.gd")
const DRAW_REWARD_SOUND: AudioStream = preload("res://learning/audio/sfx/coin.ogg")
const SECONDS_PER_CRYSTAL: float = 5.0
const DRAW_MOTION_WINDOW: float = 0.18

const TITLE_TEXT := {
    "en": ["DRAW IT", "Draw, trace and colour"],
    "ru": ["НАРИСУЙ", "Рисуй, обводи и раскрашивай"],
    "pt_BR": ["DESENHE", "Desenhe, contorne e pinte"],
    "es": ["DIBUJA", "Dibuja, repasa y colorea"],
    "fr": ["DESSINE", "Dessine, trace et colorie"],
    "de": ["ZEICHNE", "Zeichne, spure nach und male aus"]
}

var _mika_toolbar_layer: CanvasLayer
var _mika_toolbar_root: Control
var _mika_back: Button
var _mika_counter: Control
var _mika_title_panel: Panel
var _mika_title: Label
var _mika_subtitle: Label
var _mika_toolbar_ready: bool = false
var _mika_active_seconds: float = 0.0
var _mika_recent_draw_motion: float = 0.0
var _mika_earned: int = 0
var _mika_rewards_settled: bool = false
var _mika_timer_sfx: AudioStreamPlayer
var _mika_progress: ProgressBar
var _mika_last_timer_tenth: int = -1

func _ready() -> void:
    # The simulator is normally paused while children play; the reward clock
    # must continue advancing *only during real drawing input*.
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process(true)
    _mika_active_seconds = 0.0
    _mika_earned = 0
    _mika_rewards_settled = false
    # Original construction includes all functioning buttons, textures,
    # voice players and the drawing surface.
    super._ready()

    # The original Draw It back control lives in the sidebar. Hide and disable
    # it; don't free it, so future source-game changes won't dereference a
    # deleted node.
    if exit_button != null:
        exit_button.hide()
        exit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
        exit_button.focus_mode = Control.FOCUS_NONE

    _mika_toolbar_layer = CanvasLayer.new()
    _mika_toolbar_layer.name = "MikaDrawItSharedToolbar"
    _mika_toolbar_layer.layer = 2
    add_child(_mika_toolbar_layer)
    _mika_toolbar_root = Control.new()
    _mika_toolbar_root.name = "SharedToolbarLayout"
    _mika_toolbar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_toolbar_root.size = get_viewport_rect().size
    _mika_toolbar_layer.add_child(_mika_toolbar_root)

    _mika_back = _create_back_button()
    _mika_toolbar_root.add_child(_mika_back)
    _mika_counter = MIKA_DRAW_HUB.new() as Control
    _mika_counter.name = "OriginalPlanetHubCrystalCounter"
    _mika_counter.size = Vector2(1680.0, 158.0)
    _mika_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_toolbar_root.add_child(_mika_counter)
    # The actual Hub component draws all the native crystal artwork. We keep
    # its original scale, hide its unrelated flight and simulator buttons.
    var sim_button: Control = _mika_counter.get_node_or_null("SimulatorButton") as Control
    var launch_button: Control = _mika_counter.get_node_or_null("LaunchButton") as Control
    if sim_button != null:
        sim_button.hide()
    if launch_button != null:
        launch_button.hide()
    _mika_counter.set("crystal_count", 0)

    # Keep a compact, non-interactive completion indicator under the title.
    # The original visual height is still determined by the real HUD counter.
    _mika_progress = ProgressBar.new()
    _mika_progress.name = "FiveSecondsOfActualDrawingProgress"
    _mika_progress.min_value = 0.0
    _mika_progress.max_value = SECONDS_PER_CRYSTAL
    _mika_progress.value = 0.0
    _mika_progress.show_percentage = false
    _mika_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_progress.add_theme_stylebox_override("background", _timer_skin(Color("#102645")))
    _mika_progress.add_theme_stylebox_override("fill", _timer_skin(Color("#54e4ff")))
    _mika_toolbar_root.add_child(_mika_progress)

    _mika_timer_sfx = AudioStreamPlayer.new()
    _mika_timer_sfx.name = "ExistingPlayTownCrystalAwardSfx"
    _mika_timer_sfx.stream = DRAW_REWARD_SOUND
    _mika_timer_sfx.bus = "SFX"
    _mika_timer_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_mika_timer_sfx)
    # The inherited canvas is already connected to its original drawing
    # handler; listen second, without changing stroke/eraser mechanics.
    canvas.gui_input.connect(_on_mika_canvas_input)

    _mika_title_panel = Panel.new()
    _mika_title_panel.name = "SharedDrawItTitle"
    _mika_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    MIKA_SHARED_DRAW_TOOLBAR.apply_title_style(_mika_title_panel)
    _mika_toolbar_root.add_child(_mika_title_panel)
    _mika_title = _create_label(Color("#f4fbff"))
    _mika_subtitle = _create_label(Color("#aeeaff"))
    _mika_title_panel.add_child(_mika_title)
    _mika_title_panel.add_child(_mika_subtitle)
    _mika_progress.reparent(_mika_title_panel)
    _apply_title_language()
    if not MobileLocale.language_changed.is_connected(_on_draw_language_changed):
        MobileLocale.language_changed.connect(_on_draw_language_changed)

    _mika_toolbar_ready = true
    _refresh_mika_timer()
    _layout()

func _timer_skin(tint: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = tint
    style.set_corner_radius_all(5)
    style.anti_aliasing = true
    return style


func _on_mika_canvas_input(event: InputEvent) -> void:
    if canvas == null or not is_instance_valid(canvas):
        return
    if event is InputEventMouseButton or event is InputEventScreenTouch:
        if not canvas.pointer_active:
            _mika_recent_draw_motion = 0.0
        return
    if canvas.eraser_enabled or not canvas.pointer_active:
        return
    var moved: bool = false
    var point: Vector2 = Vector2.ZERO
    if event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        point = motion.position
        moved = (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and motion.relative.length_squared() > 0.25
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        point = drag.position
        moved = drag.relative.length_squared() > 0.25
    # Count only movement in the actual drawable paper region. The exercise
    # preview, the drawing tools, held-still fingers, and the eraser earn zero.
    if moved and canvas._is_drawable_point(point):
        _mika_recent_draw_motion = DRAW_MOTION_WINDOW


func _process(delta: float) -> void:
    if not _mika_toolbar_ready or canvas == null or not is_instance_valid(canvas):
        return
    var active: bool = canvas.pointer_active and not canvas.eraser_enabled
    if active and _mika_recent_draw_motion > 0.0:
        var credited_time: float = minf(delta, _mika_recent_draw_motion)
        _mika_active_seconds += credited_time
        while _mika_active_seconds >= SECONDS_PER_CRYSTAL:
            _mika_active_seconds -= SECONDS_PER_CRYSTAL
            _mika_earned += 1
            if is_instance_valid(_mika_timer_sfx):
                _mika_timer_sfx.play()
            _mika_counter.set("crystal_count", _mika_earned)
    _mika_recent_draw_motion = maxf(0.0, _mika_recent_draw_motion - delta) if active else 0.0
    _refresh_mika_timer()


func _refresh_mika_timer() -> void:
    if _mika_progress != null:
        _mika_progress.value = _mika_active_seconds
    var tenth: int = floori(_mika_active_seconds * 10.0)
    if tenth == _mika_last_timer_tenth or _mika_subtitle == null:
        return
    _mika_last_timer_tenth = tenth
    _apply_title_language()


func _settle_mika_drawing_rewards() -> void:
    if _mika_rewards_settled:
        return
    _mika_rewards_settled = true
    if _mika_earned <= 0:
        return
    var host: Node = _find_simulator_host()
    if host == null or not host.has_signal("crystals_earned"):
        return
    # Main.gd receives this signal and caps the actual tank at FUEL_CAPACITY.
    host.emit_signal("crystals_earned", _mika_earned)
    # Refresh the simulator's own balance before returning to its game cards.
    var parent: Node = host.get_parent()
    for _i in range(8):
        if parent == null:
            break
        var fuel: Variant = parent.get("_fuel_units")
        if fuel is int or fuel is float:
            if host.has_method("set_stats"):
                host.call("set_stats", maxi(0, floori(float(fuel) + 0.001)), 0, 0.0)
            break
        parent = parent.get_parent()


func _exit_tree() -> void:
    # Also handles the outer simulator closing the game without our back key.
    _settle_mika_drawing_rewards()
    super._exit_tree()

func _create_label(color: Color) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", Color("#061832"))
    label.add_theme_constant_override("outline_size", 2)
    return label

func _find_simulator_host() -> Node:
    var node: Node = get_parent()
    for i in range(20):
        if node == null:
            break
        if node.has_method("_return_to_cards"):
            return node
        node = node.get_parent()
    return null

func _create_back_button() -> Button:
    var b := Button.new()
    b.name = "SimulatorNativeDrawBack"
    b.text = ""
    b.focus_mode = Control.FOCUS_NONE
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    var host: Node = _find_simulator_host()
    if host != null and host.has_method("_style_back_button"):
        host.call("_style_back_button", b)
    else:
        var normal := StyleBoxFlat.new()
        normal.bg_color = Color("#061c38")
        normal.border_color = Color("#26dfff")
        normal.set_border_width_all(2)
        normal.set_corner_radius_all(18)
        normal.shadow_color = Color(0.04, 0.64, 1.0, 0.47)
        normal.shadow_size = 6
        b.add_theme_stylebox_override("normal", normal)
        var hover := normal.duplicate() as StyleBoxFlat
        hover.bg_color = Color("#113a60")
        b.add_theme_stylebox_override("hover", hover)
        b.add_theme_stylebox_override("pressed", hover)
        b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        var glyph: Control = MIKA_DRAW_BACK_GLYPH.new()
        glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(glyph)
        glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    b.pressed.connect(_exit_game)
    return b

func _on_draw_language_changed(_code: String) -> void:
    _apply_title_language()
    if _mika_toolbar_ready:
        _layout()

func _apply_title_language() -> void:
    var code: String = str(MobileLocale.language)
    if not TITLE_TEXT.has(code):
        code = "en"
    var pair: Array = TITLE_TEXT[code]
    _mika_title.text = str(pair[0])
    _mika_subtitle.text = "%s  ·  %.1f / 5 s" % [str(pair[1]), _mika_active_seconds]

func _layout() -> void:
    if not _mika_toolbar_ready or outer_panel == null or sidebar == null or canvas_panel == null:
        # The original _ready() invokes this method before the new toolbar
        # exists. Preserve the original one-time layout during construction.
        if outer_panel != null and canvas_panel != null and sidebar != null:
            super._layout()
        return

    var view: Vector2 = get_viewport_rect().size
    if view.x <= 110.0 or view.y <= 140.0:
        return
    background.position = Vector2.ZERO
    background.size = view
    _mika_toolbar_root.size = view

    var insets: Vector4 = _safe_area_insets(view)
    var safe := Rect2(Vector2(insets.x, insets.y), view - Vector2(insets.x + insets.z, insets.y + insets.w))
    var header_end: float = MIKA_SHARED_DRAW_TOOLBAR.relayout(view, safe, _mika_back, _mika_counter, _mika_title_panel, _mika_title, _mika_subtitle)
    if _mika_progress != null:
        var title_rect: Rect2 = Rect2(_mika_title_panel.position, _mika_title_panel.size)
        _mika_progress.position = Vector2(title_rect.size.x * 0.065, title_rect.size.y * 0.91)
        _mika_progress.size = Vector2(title_rect.size.x * 0.87, maxf(2.0, title_rect.size.y * 0.035))
    var sw: float = safe.size.x
    var sh: float = safe.size.y
    var edge: float = sw * 0.018
    var top_gap: float = sh * 0.018
    var bottom_edge: float = sh * 0.018
    var body_y: float = header_end + top_gap
    var body_bottom: float = safe.end.y - bottom_edge
    var body_w: float = sw - edge * 2.0
    var body_h: float = body_bottom - body_y
    if body_w <= 60.0 or body_h <= 90.0:
        return

    outer_panel.position = Vector2(safe.position.x + edge, body_y)
    outer_panel.size = Vector2(body_w, body_h)

    var inner: float = minf(body_w, body_h) * 0.020
    var gap: float = body_w * 0.014
    var content_w: float = body_w - inner * 2.0
    var content_h: float = body_h - inner * 2.0
    var portrait: bool = sw < sh * 0.78
    var panel_rect: Rect2

    if portrait:
        # Portrait: five task icons in one row, tools in a separate bottom row
        # and maximum remaining white canvas area in the middle.
        var category_h: float = content_h * 0.14
        var tools_h: float = content_h * 0.125
        sidebar.position = Vector2(inner, inner)
        sidebar.size = Vector2(content_w, category_h)
        panel_rect = Rect2(Vector2(inner, inner + category_h + gap), Vector2(content_w, content_h - category_h - tools_h - gap * 2.0))
        var tools_rect := Rect2(Vector2(inner, panel_rect.end.y + gap), Vector2(content_w, tools_h))
        _layout_exercise_buttons(true)
        _layout_tool_buttons(tools_rect, true)
    else:
        # Landscape: task sidebar, free-drawing paper, separate right-side
        # tool rail. All widths/gaps are proportional to usable safe bounds.
        var category_w: float = content_w * 0.135
        var tools_w: float = content_w * 0.092
        sidebar.position = Vector2(inner, inner)
        sidebar.size = Vector2(category_w, content_h)
        panel_rect = Rect2(Vector2(inner + category_w + gap, inner), Vector2(content_w - category_w - tools_w - gap * 2.0, content_h))
        var tools_rect := Rect2(Vector2(panel_rect.end.x + gap, inner), Vector2(tools_w, content_h))
        _layout_exercise_buttons(false)
        _layout_tool_buttons(tools_rect, false)

    canvas_panel.position = panel_rect.position
    canvas_panel.size = Vector2(maxf(12.0, panel_rect.size.x), maxf(12.0, panel_rect.size.y))
    var inset: float = minf(canvas_panel.size.x, canvas_panel.size.y) * 0.012
    canvas.position = Vector2.ONE * inset
    canvas.size = canvas_panel.size - Vector2.ONE * inset * 2.0
    _layout_palette()

func _layout_exercise_buttons(horizontal: bool) -> void:
    if exit_button != null:
        exit_button.hide()
    var n: int = exercise_buttons.size()
    if n <= 0:
        return
    if horizontal:
        var padding: float = sidebar.size.y * 0.10
        var gap: float = sidebar.size.x * 0.016
        var side: float = minf(sidebar.size.y - padding * 2.0, (sidebar.size.x - padding * 2.0 - gap * float(n - 1)) / float(n))
        var content_width: float = side * float(n) + gap * float(n - 1)
        var start_x: float = (sidebar.size.x - content_width) * 0.5
        for i in range(n):
            var b: Button = exercise_buttons[i]
            b.size = Vector2.ONE * side
            b.position = Vector2(start_x + float(i) * (side + gap), (sidebar.size.y - side) * 0.5)
    else:
        var padding: float = sidebar.size.x * 0.085
        var gap: float = sidebar.size.y * 0.020
        var side: float = minf(sidebar.size.x - padding * 2.0, (sidebar.size.y - padding * 2.0 - gap * float(n - 1)) / float(n))
        var content_height: float = side * float(n) + gap * float(n - 1)
        var start_y: float = (sidebar.size.y - content_height) * 0.5
        for i in range(n):
            var b: Button = exercise_buttons[i]
            b.size = Vector2.ONE * side
            b.position = Vector2((sidebar.size.x - side) * 0.5, start_y + float(i) * (side + gap))

func _layout_tool_buttons(rect: Rect2, horizontal: bool) -> void:
    var buttons: Array[Button] = [clear_button, eraser_button, color_button]
    var icons: Array[Control] = [clear_icon, eraser_icon, palette_icon]
    var n: int = buttons.size()
    var gap: float = (rect.size.x if horizontal else rect.size.y) * 0.060
    var side: float
    if horizontal:
        side = minf(rect.size.y * 0.86, (rect.size.x - gap * float(n - 1)) / float(n))
    else:
        side = minf(rect.size.x * 0.87, (rect.size.y - gap * float(n - 1)) / float(n))
    var total: float = side * float(n) + gap * float(n - 1)
    var origin: Vector2 = rect.position
    if horizontal:
        origin.x += (rect.size.x - total) * 0.5
        origin.y += (rect.size.y - side) * 0.5
    else:
        origin.x += (rect.size.x - side) * 0.5
        origin.y += (rect.size.y - total) * 0.5
    for i in range(n):
        var b: Button = buttons[i]
        var icon_node: Control = icons[i]
        b.size = Vector2.ONE * side
        b.position = origin + (Vector2(float(i) * (side + gap), 0.0) if horizontal else Vector2(0.0, float(i) * (side + gap)))
        icon_node.position = Vector2.ONE * side * 0.085
        icon_node.size = Vector2.ONE * side * 0.83

func _layout_palette() -> void:
    # Opens above the canvas; compact wrap-less pencil strip scales down to
    # fit even portrait phones, never outside the main glass container.
    var board: Rect2 = Rect2(canvas_panel.position, canvas_panel.size)
    var count: int = pencil_buttons.size()
    if count == 0:
        return
    var pad: float = minf(board.size.x, board.size.y) * 0.014
    var available_w: float = board.size.x * 0.94
    var gap: float = available_w * 0.016
    var pencil_w: float = (available_w - pad * 2.0 - gap * float(count - 1)) / float(count)
    var pencil_h: float = minf(board.size.y * 0.17, pencil_w * 1.65)
    var total_w: float = pencil_w * float(count) + gap * float(count - 1) + pad * 2.0
    palette_panel.size = Vector2(total_w, pencil_h + pad * 2.0)
    palette_panel.position = board.position + Vector2((board.size.x - total_w) * 0.5, board.size.y - palette_panel.size.y - pad)
    for i in range(count):
        pencil_buttons[i].size = Vector2(pencil_w, pencil_h)
        pencil_buttons[i].position = Vector2(pad + float(i) * (pencil_w + gap), pad)

func _exit_game() -> void:
    _settle_mika_drawing_rewards()
    # Return to the *simulator cards*, not PlayTown's old school-game screen.
    var host: Node = _find_simulator_host()
    if host != null:
        host.call("_return_to_cards")
    else:
        super._exit_game()
