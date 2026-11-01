@tool
extends Control
## v66: mirror-wing pastel controls and very dark rounded crystal counter.
## Only the *icons* are raster resources; there is no panel background image.
signal simulator_pressed
signal flight_pressed

const CRYSTAL_ART: Texture2D = preload("res://asteroid_assets/fragments/04_blue/crystal_wedge.png")
const SIM_ICON: Texture2D = preload("res://planet_hub/assets/simulator_helmet.png")
const LAUNCH_ICON: Texture2D = preload("res://planet_hub/assets/launch_ship.png")

@export var crystal_count: int = 0:
    set(value):
        crystal_count = maxi(0, value)
        if count_label != null:
            count_label.text = str(crystal_count)
        queue_redraw()

var sim_button: Button
var flight_button: Button
var sim_icon: TextureRect
var flight_icon: TextureRect
var crystal_icon: TextureRect
var sim_label: Label
var flight_label: Label
var count_label: Label
var _over_sim: bool = false
var _over_flight: bool = false
var _press_sim: bool = false
var _press_flight: bool = false
var _left_rect: Rect2 = Rect2()
var _right_rect: Rect2 = Rect2()
var _center_rect: Rect2 = Rect2()
var _scale: float = 1.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    sim_button = _new_button("SimulatorButton")
    flight_button = _new_button("LaunchButton")
    sim_icon = _icon("SimulatorHelmet", SIM_ICON, sim_button)
    flight_icon = _icon("LaunchShip", LAUNCH_ICON, flight_button)
    sim_label = _label("SimulatorText", sim_button)
    flight_label = _label("LaunchText", flight_button)
    crystal_icon = _icon("CollectedCrystal_OriginalGameAsset", CRYSTAL_ART, self)
    count_label = _label("CrystalCount", self)
    count_label.text = str(crystal_count)
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count_label.add_theme_color_override("font_color", Color.WHITE)
    count_label.add_theme_color_override("font_outline_color", Color("06152b"))
    count_label.add_theme_constant_override("outline_size", 4)
    sim_button.pressed.connect(func(): simulator_pressed.emit())
    flight_button.pressed.connect(func(): flight_pressed.emit())
    sim_button.mouse_entered.connect(_set_highlight.bind(true, true))
    sim_button.mouse_exited.connect(_set_highlight.bind(true, false))
    flight_button.mouse_entered.connect(_set_highlight.bind(false, true))
    flight_button.mouse_exited.connect(_set_highlight.bind(false, false))
    sim_button.button_down.connect(_set_pressed.bind(true, true))
    sim_button.button_up.connect(_set_pressed.bind(true, false))
    flight_button.button_down.connect(_set_pressed.bind(false, true))
    flight_button.button_up.connect(_set_pressed.bind(false, false))
    resized.connect(_layout_items)
    if not Engine.is_editor_hint():
        MobileLocale.language_changed.connect(_on_language_changed)
    _on_language_changed("ru" if Engine.is_editor_hint() else MobileLocale.language)
    _layout_items()

func _set_highlight(is_sim: bool, highlighted: bool) -> void:
    if is_sim:
        _over_sim = highlighted
    else:
        _over_flight = highlighted
    queue_redraw()

func _set_pressed(is_sim: bool, pressed: bool) -> void:
    if is_sim:
        _press_sim = pressed
    else:
        _press_flight = pressed
    queue_redraw()

func _new_button(node_name: String) -> Button:
    var button := Button.new()
    button.name = node_name
    button.flat = true
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    for state in ["normal", "hover", "pressed", "disabled", "focus"]:
        button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
    add_child(button)
    return button

func _icon(node_name: String, texture: Texture2D, parent: Control) -> TextureRect:
    var icon := TextureRect.new()
    icon.name = node_name
    icon.texture = texture
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(icon)
    return icon

func _label(node_name: String, parent: Control) -> Label:
    var label := Label.new()
    label.name = node_name
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.clip_text = true
    label.add_theme_color_override("font_color", Color("f2faff"))
    label.add_theme_color_override("font_outline_color", Color("07142d"))
    label.add_theme_constant_override("outline_size", 2)
    parent.add_child(label)
    return label

func _on_language_changed(_locale: String) -> void:
    if sim_label == null:
        return
    sim_label.text = "Симулятор" if Engine.is_editor_hint() else MobileLocale.t("planet_simulator")
    flight_label.text = "Вылет" if Engine.is_editor_hint() else MobileLocale.t("planet_depart")
    sim_button.tooltip_text = sim_label.text
    flight_button.tooltip_text = flight_label.text
    _layout_items()

func _layout_items() -> void:
    if sim_button == null or size.x < 160.0 or size.y < 38.0:
        return
    var w: float = size.x
    var h: float = size.y
    var s: float = h / 158.0
    _scale = s

    # The source screen is landscape; protect the centered crystal counter first.
    # Buttons remain hard-anchored to left and right edges at every aspect ratio.
    var center_width: float = minf(354.0 * s, w * 0.38)
    var side_margin: float = 7.0 * s
    var gap: float = 13.0 * s
    var available_side: float = maxf(0.0, (w - center_width) * 0.5 - gap - side_margin)
    var button_width: float = minf(464.0 * s, available_side)
    var button_height: float = 104.0 * s
    var y: float = 22.0 * s
    _left_rect = Rect2(side_margin, y, button_width, button_height)
    _right_rect = Rect2(w - side_margin - button_width, y, button_width, button_height)
    _center_rect = Rect2((w - center_width) * 0.5, 20.0 * s, center_width, 109.0 * s)
    sim_button.position = _left_rect.position
    sim_button.size = _left_rect.size
    flight_button.position = _right_rect.position
    flight_button.size = _right_rect.size

    # Wider outer ends carry the icon and label, pointed ends face the counter.
    # Text color is dark so it is readable on the pastel button surfaces.
    var icon_width: float = minf(78.0 * s, button_width * 0.25)
    var icon_height: float = minf(79.0 * s, button_height * 0.79)
    var icon_y: float = (button_height - icon_height) * 0.5
    var left_margin: float = 18.0 * s
    sim_icon.position = Vector2(left_margin, icon_y)
    sim_icon.size = Vector2(icon_width, icon_height)
    var sim_text_start: float = left_margin + icon_width + 5.0 * s
    sim_label.position = Vector2(sim_text_start, 0.0)
    sim_label.size = Vector2(maxf(2.0, button_width * 0.72 - sim_text_start), button_height)

    flight_icon.position = Vector2(button_width - left_margin - icon_width, icon_y)
    flight_icon.size = Vector2(icon_width, icon_height)
    flight_label.position = Vector2(button_width * 0.27, 0.0)
    flight_label.size = Vector2(maxf(2.0, button_width * 0.73 - icon_width - left_margin - 5.0 * s), button_height)
    for lbl in [sim_label, flight_label]:
        lbl.add_theme_color_override("font_color", Color("092a42"))
        lbl.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.26))
        lbl.add_theme_constant_override("outline_size", maxi(0, int(1.0 * s)))
        var font_size: int = maxi(11, int(27.0 * s))
        var needed: float = maxf(8.0, float(lbl.text.length()))
        if needed > 10.0:
            font_size = maxi(10, int(float(font_size) * 10.0 / needed))
        lbl.add_theme_font_size_override("font_size", font_size)

    # Existing shard icon and live crystal balance; never bake into artwork.
    var icon_size: float = minf(_center_rect.size.y * 0.72, _center_rect.size.x * 0.31)
    var cx: float = _center_rect.position.x
    var cy: float = _center_rect.position.y
    crystal_icon.position = Vector2(cx + 15.0*s, cy + (_center_rect.size.y - icon_size)*0.5)
    crystal_icon.size = Vector2(icon_size, icon_size)
    count_label.position = Vector2(cx + icon_size + 17.0*s, cy + 4.0*s)
    count_label.size = Vector2(maxf(1.0, _center_rect.size.x - icon_size - 32.0*s), _center_rect.size.y - 8.0*s)
    count_label.add_theme_font_size_override("font_size", maxi(20, int(54.0*s)))
    count_label.add_theme_color_override("font_color", Color.WHITE)
    queue_redraw()

func _draw() -> void:
    if size.x < 160.0 or size.y < 38.0:
        return
    var s: float = _scale
    var w: float = size.x
    var h: float = size.y
    # Low-profile grounding rail. Avoid another massive, boxy sprite background.
    draw_rect(Rect2(0.0, 60.0*s, w, h - 60.0*s), Color(0.014, 0.053, 0.105, 0.76))
    draw_line(Vector2(0.0, 62.0*s), Vector2(w, 62.0*s), Color(0.18, 0.60, 0.78, 0.18), 2.0*s, true)
    draw_line(Vector2(0.0, h - 9.0*s), Vector2(w, h - 9.0*s), Color(0.20, 0.74, 1.0, 0.24), 2.0*s, true)

    # Left and right are inverse rounded triangular wings, not rectangles.
    _draw_wing(_left_rect, true, _over_sim, _press_sim)
    _draw_wing(_right_rect, false, _over_flight, _press_flight)
    _draw_counter()

func _draw_wing(r: Rect2, points_right: bool, hovering: bool, pressed: bool) -> void:
    var s: float = _scale
    if r.size.x <= 4.0 or r.size.y <= 4.0:
        return
    var base: Color = Color("cbeaf4") if points_right else Color("edddc8")
    var highlight: Color = Color("ecf9fd") if points_right else Color("f9efdf")
    var pushed: Color = Color("a8d2e2") if points_right else Color("dbc6ab")
    var fill: Color = pushed if pressed else (highlight if hovering else base)
    var halo: PackedVector2Array = _wing_points(r.grow(4.0*s), points_right)
    var outer: PackedVector2Array = _wing_points(r, points_right)
    var inner: PackedVector2Array = _wing_points(r.grow(-5.5*s), points_right)
    # Multi-layer glow, cyan-beveled rim and smooth pastel colored face.
    _stroke(halo, Color(0.18, 0.76, 1.0, 0.13), 10.0*s)
    draw_colored_polygon(outer, Color("063153"))
    draw_colored_polygon(inner, fill)
    _stroke(outer, Color("5bd2ff"), 2.6*s)
    _stroke(inner, Color(1.0, 1.0, 1.0, 0.48), 1.2*s)
    # Gentle reflection on the long, straight upper edge.
    var inner_start: float = r.position.x + (24.0*s if points_right else r.size.x*0.32)
    var inner_end: float = r.end.x - (r.size.x*0.32 if points_right else 24.0*s)
    if inner_end > inner_start:
        draw_line(Vector2(inner_start, r.position.y + 11.0*s), Vector2(inner_end, r.position.y + 11.0*s), Color(1.0, 1.0, 1.0, 0.42), 2.0*s, true)

func _draw_counter() -> void:
    var s: float = _scale
    var r: Rect2 = _center_rect
    if r.size.x <= 4.0 or r.size.y <= 4.0:
        return
    # Rounded rectangle, deliberately almost-black saturated midnight blue.
    var shadow := StyleBoxFlat.new()
    shadow.bg_color = Color(0.01, 0.11, 0.21, 0.88)
    shadow.border_color = Color(0.10, 0.59, 0.91, 0.25)
    shadow.set_border_width_all(maxi(1, roundi(9.0*s)))
    shadow.set_corner_radius_all(maxi(5, roundi(31.0*s)))
    draw_style_box(shadow, r.grow(6.0*s))

    var plate := StyleBoxFlat.new()
    plate.bg_color = Color("03142b")
    plate.border_color = Color("61cbed")
    plate.set_border_width_all(maxi(1, roundi(2.6*s)))
    plate.set_corner_radius_all(maxi(4, roundi(26.0*s)))
    draw_style_box(plate, r)

    var inner := StyleBoxFlat.new()
    inner.bg_color = Color("061d39")
    inner.border_color = Color(0.31, 0.66, 0.91, 0.37)
    inner.set_border_width_all(maxi(1, roundi(1.0*s)))
    inner.set_corner_radius_all(maxi(4, roundi(20.0*s)))
    draw_style_box(inner, r.grow(-7.0*s))

    var edge: float = minf(r.size.x * 0.12, 35.0*s)
    draw_line(Vector2(r.position.x+edge, r.position.y+7.0*s), Vector2(r.end.x-edge, r.position.y+7.0*s), Color(0.69, 0.91, 1.0, 0.20), 1.4*s, true)

func _wing_points(r: Rect2, points_right: bool) -> PackedVector2Array:
    # Normalized Bézier-like rounded corners, rounded triangular inner tip.
    # Both wings share the same geometry, mirrored horizontally.
    var p: PackedVector2Array = PackedVector2Array()
    _add_point(p, r, Vector2(0.085, 0.035), points_right)
    _add_point(p, r, Vector2(0.690, 0.035), points_right)
    _add_curve(p, r, Vector2(0.690, 0.035), Vector2(0.765, 0.035), Vector2(0.814, 0.155), points_right)
    _add_point(p, r, Vector2(0.974, 0.414), points_right)
    _add_curve(p, r, Vector2(0.974, 0.414), Vector2(1.035, 0.50), Vector2(0.974, 0.586), points_right)
    _add_point(p, r, Vector2(0.814, 0.845), points_right)
    _add_curve(p, r, Vector2(0.814, 0.845), Vector2(0.765, 0.965), Vector2(0.690, 0.965), points_right)
    _add_point(p, r, Vector2(0.085, 0.965), points_right)
    _add_curve(p, r, Vector2(0.085, 0.965), Vector2(0.010, 0.965), Vector2(0.010, 0.86), points_right)
    _add_point(p, r, Vector2(0.010, 0.14), points_right)
    _add_curve(p, r, Vector2(0.010, 0.14), Vector2(0.010, 0.035), Vector2(0.085, 0.035), points_right)
    return p

func _add_point(points: PackedVector2Array, r: Rect2, uv: Vector2, points_right: bool) -> void:
    var x: float = uv.x if points_right else 1.0 - uv.x
    points.append(r.position + Vector2(x*r.size.x, uv.y*r.size.y))

func _add_curve(points: PackedVector2Array, r: Rect2, begin: Vector2, control: Vector2, end: Vector2, points_right: bool) -> void:
    for i in range(1, 9):
        var t: float = float(i)/8.0
        var u: float = 1.0-t
        var uv: Vector2 = begin*(u*u) + control*(2.0*u*t) + end*(t*t)
        _add_point(points, r, uv, points_right)

func _stroke(points: PackedVector2Array, color: Color, width: float) -> void:
    if points.size() < 3:
        return
    var loop: PackedVector2Array = points.duplicate()
    loop.append(points[0])
    draw_polyline(loop, color, width, true)
