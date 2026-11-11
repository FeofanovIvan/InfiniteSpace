extends "res://learning/src/features/draw_this/mika_draw_this_native_toolbar_v1.gd"
## MIKA Draw It v1.1 — compact lesson list and original on-canvas tools.
## The existing seven pencil textures and colour-selection behavior are intact.
## Only geometry changes. The parent handles the native header and 5s rewards.

func _layout() -> void:
    # Inherited Draw It constructs the controls before constructing its toolbar.
    # During that short period, use the original game's layout unchanged.
    if not _mika_toolbar_ready:
        super._layout()
        return
    if outer_panel == null or sidebar == null or canvas_panel == null or canvas == null:
        return

    var view: Vector2 = get_viewport_rect().size
    if view.x <= 110.0 or view.y <= 140.0:
        return
    background.position = Vector2.ZERO
    background.size = view
    _mika_toolbar_root.size = view

    # Keep exactly the same native back/title/crystal toolbar as v1.
    var insets: Vector4 = _safe_area_insets(view)
    var safe := Rect2(Vector2(insets.x, insets.y), view - Vector2(insets.x + insets.z, insets.y + insets.w))
    var header_bottom: float = MIKA_SHARED_DRAW_TOOLBAR.relayout(view, safe, _mika_back, _mika_counter, _mika_title_panel, _mika_title, _mika_subtitle)
    if _mika_progress != null:
        var title_size: Vector2 = _mika_title_panel.size
        _mika_progress.position = Vector2(title_size.x * 0.065, title_size.y * 0.91)
        _mika_progress.size = Vector2(title_size.x * 0.87, title_size.y * 0.035)

    # All spacing is a proportion of the available safe viewport.
    var edge_x: float = safe.size.x * 0.018
    var gap_y: float = safe.size.y * 0.018
    var bottom: float = safe.end.y - gap_y
    var body_size := Vector2(safe.size.x - edge_x * 2.0, bottom - header_bottom - gap_y)
    if body_size.x <= 45.0 or body_size.y <= 65.0:
        return
    outer_panel.position = Vector2(safe.position.x + edge_x, header_bottom + gap_y)
    outer_panel.size = body_size

    var pad: float = minf(body_size.x, body_size.y) * 0.022
    var available: Vector2 = body_size - Vector2.ONE * pad * 2.0
    var between: float = available.x * 0.016
    var count: int = exercise_buttons.size()
    if count <= 0:
        return
    var portrait: bool = safe.size.x < safe.size.y * 0.79
    var button_side: float
    var button_gap: float
    var button_padding: float
    var paper: Rect2

    if portrait:
        # Tight HORIZONTAL list of the five original exercise icons.
        button_gap = available.x * 0.012
        button_side = minf(available.x * 0.165, (available.x - button_gap * float(count - 1)) / (float(count) * 1.18))
        button_side = minf(button_side, available.y * 0.115)
        button_padding = button_side * 0.09
        var strip_w: float = button_side * float(count) + button_gap * float(count - 1) + button_padding * 2.0
        var strip_h: float = button_side + button_padding * 2.0
        sidebar.position = Vector2(pad + (available.x - strip_w) * 0.5, pad)
        sidebar.size = Vector2(strip_w, strip_h)
        for i in range(count):
            var exercise_button: Button = exercise_buttons[i]
            exercise_button.position = Vector2(button_padding + float(i) * (button_side + button_gap), button_padding)
            exercise_button.size = Vector2.ONE * button_side
        var paper_top: float = pad + strip_h + available.y * 0.020
        paper = Rect2(Vector2(pad, paper_top), Vector2(available.x, body_size.y - pad - paper_top))
    else:
        # Tight VERTICAL list, just a thin border around the buttons, instead
        # of the previous wide/mostly empty sidebar.
        button_gap = available.y * 0.014
        button_side = minf(available.x * 0.092, (available.y * 0.95 - button_gap * float(count - 1)) / (float(count) * 1.10))
        button_padding = button_side * 0.085
        var strip_w: float = button_side + button_padding * 2.0
        var strip_h: float = button_side * float(count) + button_gap * float(count - 1) + button_padding * 2.0
        sidebar.position = Vector2(pad, pad + (available.y - strip_h) * 0.5)
        sidebar.size = Vector2(strip_w, strip_h)
        for i in range(count):
            var exercise_button: Button = exercise_buttons[i]
            exercise_button.position = Vector2(button_padding, button_padding + float(i) * (button_side + button_gap))
            exercise_button.size = Vector2.ONE * button_side
        var paper_left: float = pad + strip_w + between
        paper = Rect2(Vector2(paper_left, pad), Vector2(body_size.x - pad - paper_left, available.y))

    if exit_button != null:
        exit_button.hide()
        exit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas_panel.position = paper.position
    canvas_panel.size = paper.size
    var canvas_inset: float = minf(paper.size.x, paper.size.y) * 0.012
    canvas.position = Vector2.ONE * canvas_inset
    canvas.size = paper.size - Vector2.ONE * canvas_inset * 2.0

    # Three original tools: palette, eraser and clear. Their original button
    # nodes and icons remain inside the drawing tablet at bottom-right.
    var short_side: float = minf(paper.size.x, paper.size.y)
    var tool_size: float = minf(paper.size.y * 0.13, paper.size.x * 0.11)
    var tool_margin: float = short_side * 0.022
    var tool_gap: float = tool_size * 0.12
    var tools: Array[Button] = [color_button, eraser_button, clear_button]
    var icons: Array[Control] = [palette_icon, eraser_icon, clear_icon]
    var bottom_right: Vector2 = paper.position + paper.size - Vector2.ONE * (tool_size + tool_margin)
    for i in range(tools.size()):
        var button: Button = tools[i]
        var icon_node: Control = icons[i]
        button.position = bottom_right - Vector2(0.0, float(i) * (tool_size + tool_gap))
        button.size = Vector2.ONE * tool_size
        icon_node.position = Vector2.ONE * tool_size * 0.09
        icon_node.size = Vector2.ONE * tool_size * 0.82

    _layout_palette()

func _layout_palette() -> void:
    # The ORIGINAL seven pencil textures, in the original horizontal popover,
    # with adaptive sizing to keep the strip on the screen on small phones.
    if palette_panel == null or pencil_buttons.is_empty() or color_button == null:
        return
    var board: Rect2 = Rect2(canvas_panel.position, canvas_panel.size)
    var count: int = pencil_buttons.size()
    var button_side: float = color_button.size.x
    var pad: float = button_side * 0.12
    var gap: float = button_side * 0.09
    var natural_pencil_h: float = button_side * 1.08
    var natural_pencil_w: float = natural_pencil_h * 0.58
    var natural_w: float = natural_pencil_w * float(count) + pad * float(count + 1)
    var room_to_left: float = color_button.position.x - (board.position.x + board.size.x * 0.015) - gap
    var popover_w: float
    var popover_y: float
    var popover_x: float
    if room_to_left >= natural_w * 0.75:
        # On wide displays the pencil strip opens LEFT of the palette icon,
        # just as it did in the original Draw It.
        popover_w = minf(natural_w, room_to_left)
        popover_x = color_button.position.x - popover_w - gap
        popover_y = color_button.position.y + button_side - (natural_pencil_h + pad * 2.0)
    else:
        # On narrow displays keep the same pencil strip, but open ABOVE the
        # tool buttons so no pencil gets clipped outside the tablet.
        popover_w = board.size.x * 0.92
        popover_x = board.position.x + (board.size.x - popover_w) * 0.5
        popover_y = clear_button.position.y - (natural_pencil_h + pad * 2.0) - gap
    var pencil_w: float = (popover_w - pad * float(count + 1)) / float(count)
    var pencil_h: float = minf(natural_pencil_h, pencil_w * 1.72)
    var popover_h: float = pencil_h + pad * 2.0
    popover_y = clampf(popover_y, board.position.y + board.size.y * 0.02, board.end.y - popover_h - board.size.y * 0.02)
    palette_panel.position = Vector2(popover_x, popover_y)
    palette_panel.size = Vector2(popover_w, popover_h)
    for i in range(count):
        var pencil: TextureButton = pencil_buttons[i]
        pencil.position = Vector2(pad + float(i) * (pencil_w + pad), pad)
        pencil.size = Vector2(pencil_w, pencil_h)
