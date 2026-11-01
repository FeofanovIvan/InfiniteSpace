@tool
extends Control
## v63: fully procedural, language-aware sci-fi planetary bottom HUD.
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
    if sim_button == null or size.x < 160 or size.y < 38:
        return
    var w: float = size.x
    var h: float = size.y
    var s: float = h / 158.0
    _scale = s
    var center_width: float = minf(360.0 * s, w * 0.35)
    var gap: float = 15.0 * s
    var button_width: float = minf(450.0 * s, (w - center_width - 2.0 * gap - 16.0 * s) * 0.5)
    button_width = maxf(50.0, button_width)
    var button_height: float = 104.0 * s
    var y: float = 23.0 * s
    # Keep the dynamic resource center aligned; place action buttons at edges.
    var side_margin: float = 8.0 * s
    _left_rect = Rect2(side_margin, y, button_width, button_height)
    _right_rect = Rect2(w - side_margin - button_width, y, button_width, button_height)
    _center_rect = Rect2(w * 0.5 - center_width * 0.5, 21.0 * s, center_width, 108.0 * s)
    sim_button.position = _left_rect.position
    sim_button.size = _left_rect.size
    flight_button.position = _right_rect.position
    flight_button.size = _right_rect.size
    var icon_w: float = minf(85.0 * s, button_width * 0.30)
    var icon_h: float = 80.0 * s
    sim_icon.position = Vector2(18.0 * s, (button_height - icon_h) * 0.5)
    sim_icon.size = Vector2(icon_w, icon_h)
    flight_icon.position = Vector2(18.0 * s, (button_height - icon_h) * 0.5)
    flight_icon.size = Vector2(icon_w, icon_h)
    var text_start: float = 24.0 * s + icon_w
    var text_width: float = maxf(2.0, button_width - text_start - 14.0 * s)
    sim_label.position = Vector2(text_start, 0)
    sim_label.size = Vector2(text_width, button_height)
    flight_label.position = Vector2(text_start, 0)
    flight_label.size = Vector2(text_width, button_height)
    for lbl in [sim_label, flight_label]:
        var font_size: int = maxi(12, int(28.0 * s))
        var needed: float = maxf(1.0, float(lbl.text.length()))
        # German/French/Portuguese labels remain legible without clipping.
        if needed > 10.0:
            font_size = maxi(10, int(float(font_size) * 10.0 / needed))
        lbl.add_theme_font_size_override("font_size", font_size)
    var cx: float = _center_rect.position.x
    var cy: float = _center_rect.position.y
    var icon_size: float = minf(_center_rect.size.y * 0.76, _center_rect.size.x * 0.33)
    crystal_icon.position = Vector2(cx + 13.0 * s, cy + (_center_rect.size.y - icon_size) * 0.5)
    crystal_icon.size = Vector2(icon_size, icon_size)
    count_label.position = Vector2(cx + icon_size + 12.0 * s, cy + 4.0 * s)
    count_label.size = Vector2(maxf(5.0, _center_rect.size.x - icon_size - 30.0 * s), _center_rect.size.y - 8.0 * s)
    count_label.add_theme_font_size_override("font_size", maxi(20, int(53.0 * s)))
    queue_redraw()

func _draw() -> void:
    if size.x < 160.0 or size.y < 38.0:
        return
    var w: float = size.x
    var h: float = size.y
    var s: float = _scale
    # Main alloy rail: deep-blue body, faceted upper seam and restrained glow.
    draw_rect(Rect2(0, 18.0*s, w, h - 18.0*s), Color("07172c"))
    draw_rect(Rect2(0, 23.0*s, w, h - 33.0*s), Color("0d2946"))
    draw_rect(Rect2(0, 41.0*s, w, h - 49.0*s), Color("091d37"))
    draw_line(Vector2(0, 19.0*s), Vector2(w, 19.0*s), Color(0.22, 0.79, 1.0, 0.16), 10.0*s, true)
    draw_line(Vector2(0, 19.0*s), Vector2(w, 19.0*s), Color("43c6ff"), 2.0*s, true)
    draw_line(Vector2(0, h - 11.0*s), Vector2(w, h - 11.0*s), Color("1f5a81"), 3.0*s, true)
    # Subtle repeating ribs give the bar an engineered, not flat, appearance.
    for i in range(1, 24):
        var xx: float = w * float(i) / 24.0
        draw_line(Vector2(xx, 24.0*s), Vector2(xx + 11.0*s, 32.0*s), Color(0.14, 0.44, 0.67, 0.16), 1.0*s, true)
    _draw_button_plate(_left_rect, Color("39bfff"), _over_sim, _press_sim)
    _draw_button_plate(_right_rect, Color("ffa633"), _over_flight, _press_flight)
    _draw_counter()

func _draw_button_plate(r: Rect2, accent: Color, hovering: bool, pressed: bool) -> void:
    var s: float = _scale
    var poly: PackedVector2Array = _facets(r, 23.0*s)
    var inner: PackedVector2Array = _facets(r.grow(-6.0*s), 20.0*s)
    _outline(poly, Color(accent.r, accent.g, accent.b, 0.17), 13.0*s)
    draw_colored_polygon(poly, Color("041326"))
    draw_colored_polygon(inner, Color("113d60") if hovering else Color("0b2b49"))
    if pressed:
        draw_colored_polygon(inner, Color(accent.r * 0.3, accent.g * 0.34, accent.b * 0.3, 0.43))
    _outline(poly, Color(accent.r, accent.g, accent.b, 0.96), 3.2*s)
    _outline(inner, Color(accent.r, accent.g, accent.b, 0.33), 1.2*s)
    var y: float = r.position.y + 8.0*s
    draw_line(Vector2(r.position.x + 52.0*s, y), Vector2(r.end.x - 52.0*s, y), Color(accent.r, accent.g, accent.b, 0.76), 2.3*s, true)
    draw_line(Vector2(r.position.x + 53.0*s, r.end.y - 7.0*s), Vector2(r.end.x - 53.0*s, r.end.y - 7.0*s), Color(accent.r, accent.g, accent.b, 0.35), 1.6*s, true)

func _draw_counter() -> void:
    var r: Rect2 = _center_rect
    var s: float = _scale
    var poly: PackedVector2Array = _facets(r, 26.0*s)
    var inner: PackedVector2Array = _facets(r.grow(-7.0*s), 22.0*s)
    _outline(poly, Color(0.06, 0.68, 1.0, 0.20), 14.0*s)
    draw_colored_polygon(poly, Color("051528"))
    draw_colored_polygon(inner, Color("0a3152"))
    _outline(poly, Color("35c9ff"), 2.5*s)
    _outline(inner, Color(0.18, 0.68, 0.98, 0.5), 1.3*s)
    draw_line(Vector2(r.position.x + 42.0*s, r.position.y + 5.0*s), Vector2(r.end.x - 42.0*s, r.position.y + 5.0*s), Color(0.32, 0.86, 1.0, 0.8), 2.0*s, true)

func _facets(r: Rect2, c: float) -> PackedVector2Array:
    c = minf(c, minf(r.size.x, r.size.y) * 0.30)
    return PackedVector2Array([
        r.position + Vector2(c, 0), Vector2(r.end.x - c, r.position.y),
        Vector2(r.end.x, r.position.y + c), Vector2(r.end.x, r.end.y - c),
        r.end - Vector2(c, 0), Vector2(r.position.x + c, r.end.y),
        Vector2(r.position.x, r.end.y - c), r.position + Vector2(0, c)
    ])

func _outline(p: PackedVector2Array, color: Color, width: float) -> void:
    var points: PackedVector2Array = p.duplicate()
    points.append(p[0])
    draw_polyline(points, color, width, true)
