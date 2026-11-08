extends "res://scripts/MikoMainMenu.gd"
## MIKA Simulator 5x2 temporary catalog: native HUD, original cards and runners.
## Ten approved cards fill the first two rows; additional testing cards scroll below.
## No edits to original card art, game paths or crystal accounting.

const COLUMN_COUNT: int = 5
const CARD_ASPECT: float = 430.0 / 540.0

var _grid_ready: bool = false
var _grid_columns: Array[VBoxContainer] = []
var _grid_cards: Array[TextureButton] = []

func _ready() -> void:
    # Keep the whole native header, original card factory and game launching.
    super._ready()
    _install_grid()
    _gallery.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    _gallery.scroll_horizontal = 0
    _gallery.scroll_vertical = 0
    _grid_ready = true
    _v81_refresh_game_titles()
    _reflow()

func _install_grid() -> void:
    var originals: Array[TextureButton] = []
    for item in _strip.get_children():
        if item is TextureButton:
            originals.append(item as TextureButton)
    if originals.size() < 10:
        push_warning("MIKA 5x2: fewer than 10 simulator cards are available")
    # HBox containing FIVE vertical stacks maintains the exact source order:
    # row 1 = items 0..4, row 2 = 5..9, rows 3+ = test games.
    _strip.alignment = BoxContainer.ALIGNMENT_CENTER
    for column_index in range(COLUMN_COUNT):
        var column := VBoxContainer.new()
        column.name = "SimulatorFiveColumn_%02d" % (column_index + 1)
        column.alignment = BoxContainer.ALIGNMENT_BEGIN
        column.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _strip.add_child(column)
        _grid_columns.append(column)
    for card_index in range(originals.size()):
        var button: TextureButton = originals[card_index]
        button.reparent(_grid_columns[card_index % COLUMN_COUNT], false)
        _grid_cards.append(button)

func _v81_refresh_game_titles(_locale: String = "") -> void:
    if not _grid_ready:
        super._v81_refresh_game_titles(_locale)
        return
    for button in _grid_cards:
        var id: String = str(button.get_meta("game_id", ""))
        if not id.is_empty():
            var caption: String = _v81_game_title(id)
            button.tooltip_text = caption
            var frame: Control = button.get_node_or_null("PlanetHubGameFrame") as Control
            if frame != null:
                frame.set("card_title", caption)
            continue
        # Also preserve six-language names of the temporary planetary cards.
        var prefix: String = "TemporaryPlanetCard_"
        if str(button.name).begins_with(prefix):
            var planet_id: String = str(button.name).trim_prefix(prefix)
            var data: Dictionary = _v1151p24_by_id.get(planet_id, {})
            if not data.is_empty():
                var label: Label = button.get_node_or_null("PlanetGameTitle") as Label
                var caption: String = _v1151p24_title(data.get("title", {}), planet_id)
                var available: bool = not _v1151p24_find_scene(data).is_empty()
                button.tooltip_text = caption if available else caption + " — сцена пока отсутствует"
                if label != null:
                    label.text = caption

func _card_under_point(screen_point: Vector2) -> TextureButton:
    if not _grid_ready:
        return super._card_under_point(screen_point)
    # The invisible gesture shield remains above all cards. It distinguishes
    # a click from a vertical swipe just as the native horizontal menu did.
    for card in _grid_cards:
        if card.visible and card.get_global_rect().has_point(screen_point):
            return card
    return null

func _reflow() -> void:
    # Called by the parent during super._ready() before columns exist.
    super._reflow()
    if not _grid_ready or size.x < 120.0 or size.y < 140.0:
        return
    var view: Vector2 = size
    var hud_unit: float = minf(view.y / 864.0, view.x / 1680.0)
    var left: float = clampf(view.x * 0.016, 7.0, 35.0)
    var top: float = 20.0 * hud_unit + 158.0 * hud_unit * 0.80 + clampf(view.y * 0.013, 7.0, 18.0)
    var bottom: float = view.y - clampf(view.y * 0.012, 7.0, 20.0)
    var available_width: float = maxf(100.0, view.x - 2.0 * left)
    var available_height: float = maxf(96.0, bottom - top)
    var gap_x: float = clampf(view.x * 0.010, 4.0, 20.0)
    var gap_y: float = clampf(view.y * 0.014, 5.0, 16.0)
    var width_limit: float = (available_width - gap_x * 4.0) / 5.0
    var height_limit: float = maxf(44.0, (available_height - gap_y) * 0.5)
    var card_width: float = maxf(34.0, minf(width_limit, height_limit * CARD_ASPECT))
    var card_height: float = card_width / CARD_ASPECT

    _gallery.position = Vector2(left, top)
    _gallery.size = Vector2(available_width, available_height)
    _gesture_layer.position = _gallery.position
    _gesture_layer.size = _gallery.size
    _strip.add_theme_constant_override("separation", roundi(gap_x))
    _strip.custom_minimum_size = Vector2(available_width, 0.0)
    for column in _grid_columns:
        column.add_theme_constant_override("separation", roundi(gap_y))
    for card in _grid_cards:
        card.custom_minimum_size = Vector2(card_width, card_height)
        var planet_label: Label = card.get_node_or_null("PlanetGameTitle") as Label
        if planet_label != null:
            planet_label.add_theme_font_size_override("font_size", maxi(9, roundi(card_width * 0.062)))
    # No horizontal scrolling. 5 real cards per row across every aspect ratio.
    _gallery.scroll_horizontal = 0
    call_deferred("_keep_gallery_scroll_in_range")

func _keep_gallery_scroll_in_range() -> void:
    if not _grid_ready or not is_instance_valid(_gallery):
        return
    var limit: int = maxi(0, roundi(_strip.size.y - _gallery.size.y))
    _gallery.scroll_vertical = clampi(_gallery.scroll_vertical, 0, limit)

func _gesture_move(screen_point: Vector2) -> void:
    if _pointer_kind == "":
        return
    var delta_y: float = screen_point.y - _pointer_last.y
    if screen_point.distance_to(_pointer_origin) > DRAG_THRESHOLD:
        _pointer_moved = true
    if _pointer_moved:
        var limit: int = maxi(0, roundi(_strip.size.y - _gallery.size.y))
        _gallery.scroll_vertical = clampi(roundi(float(_gallery.scroll_vertical) - delta_y), 0, limit)
        _fling_speed = clampf(-delta_y / maxf(get_process_delta_time(), 0.016), -MAX_FLING_SPEED, MAX_FLING_SPEED)
    _pointer_last = screen_point

func _input(event: InputEvent) -> void:
    if not visible or _playing or not _gesture_layer.visible:
        return
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _gesture_begin("touch", touch.index, touch.position)
        elif _pointer_kind == "touch" and _pointer_index == touch.index:
            _gesture_end(touch.position)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        if _pointer_kind == "touch" and _pointer_index == drag.index:
            _gesture_move(drag.position)
    elif event is InputEventMouseButton:
        var button: InputEventMouseButton = event
        if button.button_index == MOUSE_BUTTON_LEFT:
            if button.pressed:
                _gesture_begin("mouse", 0, button.position)
            elif _pointer_kind == "mouse":
                _gesture_end(button.position)
        elif button.pressed and _pointer_kind == "" and _gesture_layer.get_global_rect().has_point(button.position):
            if button.button_index == MOUSE_BUTTON_WHEEL_UP:
                _scroll_by(-maxf(48.0, size.y * 0.11))
            elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                _scroll_by(maxf(48.0, size.y * 0.11))
    elif event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event
        if _pointer_kind == "mouse" and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
            _gesture_move(motion.position)
    elif event is InputEventPanGesture:
        var pan: InputEventPanGesture = event
        if _pointer_kind == "" and _gesture_layer.get_global_rect().has_point(pan.position):
            var wheel_value: float = pan.delta.y if absf(pan.delta.y) >= absf(pan.delta.x) else pan.delta.x
            _scroll_by(wheel_value * 45.0)

func _scroll_by(amount: float) -> void:
    var limit: int = maxi(0, roundi(_strip.size.y - _gallery.size.y))
    _gallery.scroll_vertical = clampi(roundi(float(_gallery.scroll_vertical) + amount), 0, limit)
    _fling_speed = 0.0

func _process(delta: float) -> void:
    if not visible or _playing or _pointer_kind != "" or absf(_fling_speed) < 8.0:
        return
    var limit: int = maxi(0, roundi(_strip.size.y - _gallery.size.y))
    var next_scroll: int = clampi(roundi(float(_gallery.scroll_vertical) + _fling_speed * delta), 0, limit)
    if next_scroll == _gallery.scroll_vertical:
        _fling_speed = 0.0
    else:
        _gallery.scroll_vertical = next_scroll
        _fling_speed *= exp(-6.0 * delta)
