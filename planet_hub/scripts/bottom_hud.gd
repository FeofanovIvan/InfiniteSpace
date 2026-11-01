@tool
extends Control
## Bottom sci-fi HUD is drawn in Godot; icons are separate PNG textures.
## Its buttons work and emit simulator_pressed / flight_pressed.

signal simulator_pressed
signal flight_pressed

# Full-resolution user-supplied artwork. Draw at original aspect ratio and
# center-anchor it: wide transparent edges may extend beyond the viewport.
const PANEL_ART: Texture2D = preload("res://planet_hub/assets/planet_bottom_panel.png")
# The very same blue crystal resource used by RightStatusHUD/asteroid shards.
const CRYSTAL_ART: Texture2D = preload("res://asteroid_assets/fragments/04_blue/crystal_wedge.png")
const ART_STRIP_BOTTOM: float = 392.0
const ART_STRIP_TOP: float = 290.0

@export var crystal_count: int = 509:
    set(value):
        crystal_count = value
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

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    sim_button = _new_button("SimulatorButton")
    flight_button = _new_button("LaunchButton")
    sim_icon = _new_icon("SimulatorHelmet", "res://planet_hub/assets/simulator_helmet.png", sim_button)
    flight_icon = _new_icon("LaunchShip", "res://planet_hub/assets/launch_ship.png", flight_button)
    sim_label = _new_label("SimulatorText", "Симулятор", sim_button, 29)
    flight_label = _new_label("LaunchText", "Вылет", flight_button, 30)
    # Keep the counter as LIVE Godot nodes; the source PNG is decorative only.
    crystal_icon = _new_icon("CollectedCrystal_OriginalGameAsset", "res://asteroid_assets/fragments/04_blue/crystal_wedge.png", self)
    crystal_icon.texture = CRYSTAL_ART
    count_label = _new_label("CrystalCount", str(crystal_count), self, 58)
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count_label.add_theme_color_override("font_color", Color.WHITE)
    count_label.add_theme_color_override("font_outline_color", Color(0.015, 0.065, 0.14, 0.98))
    count_label.add_theme_constant_override("outline_size", 3)

    sim_button.pressed.connect(func(): simulator_pressed.emit())
    flight_button.pressed.connect(func(): flight_pressed.emit())
    sim_button.mouse_entered.connect(func(): _set_hover(true, true))
    sim_button.mouse_exited.connect(func(): _set_hover(true, false))
    flight_button.mouse_entered.connect(func(): _set_hover(false, true))
    flight_button.mouse_exited.connect(func(): _set_hover(false, false))
    resized.connect(_layout_items)
    _layout_items()
    queue_redraw()

func _new_button(node_name: String) -> Button:
    var b: Button = Button.new()
    b.name = node_name
    b.flat = true
    b.focus_mode = Control.FOCUS_ALL
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    for key in ["normal", "hover", "pressed", "disabled", "focus"]:
        b.add_theme_stylebox_override(key, StyleBoxEmpty.new())
    add_child(b)
    return b

func _new_icon(node_name: String, path: String, parent_node: Control) -> TextureRect:
    var icon: TextureRect = TextureRect.new()
    icon.name = node_name
    if ResourceLoader.exists(path):
        icon.texture = load(path) as Texture2D
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent_node.add_child(icon)
    return icon

func _new_label(node_name: String, label_text: String, parent_node: Control, font_px: int) -> Label:
    var l: Label = Label.new()
    l.name = node_name
    l.text = label_text
    l.add_theme_color_override("font_color", Color("f3f9ff"))
    l.add_theme_font_size_override("font_size", font_px)
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent_node.add_child(l)
    return l

func _set_hover(is_sim: bool, enabled: bool) -> void:
    if is_sim:
        _over_sim = enabled
    else:
        _over_flight = enabled
    queue_redraw()

func _layout_items() -> void:
    if sim_button == null or crystal_icon == null or count_label == null:
        return
    var w: float = size.x
    var h: float = size.y
    if w < 180.0 or h < 45.0:
        return
    # Height governs scale: NEVER squash panel art to fit screen width.
    var s: float = h / 158.0
    var art_scale: float = h / (ART_STRIP_BOTTOM - ART_STRIP_TOP)
    # Reserve the real, centered bezel for the crystal and large white number.
    var center_guard: float = 360.0 * art_scale
    var side_gap: float = 12.0 * s
    var side_width: float = maxf(0.0, (w - center_guard) * 0.5 - side_gap)
    var margin: float = 10.0 * s
    sim_button.position = Vector2(margin, 6.0 * s)
    sim_button.size = Vector2(maxf(1.0, side_width - margin), maxf(1.0, h - 10.0 * s))
    flight_button.position = Vector2(w - side_width, 6.0 * s)
    flight_button.size = Vector2(maxf(1.0, side_width - margin), maxf(1.0, h - 10.0 * s))

    var icon_width: float = minf(76.0 * s, sim_button.size.x * 0.32)
    sim_icon.position = Vector2(8.0 * s, 14.0 * s)
    sim_icon.size = Vector2(icon_width, 97.0 * s)
    sim_label.position = Vector2(20.0 * s + icon_width, 0.0)
    sim_label.size = Vector2(maxf(0.0, sim_button.size.x - 24.0 * s - icon_width), sim_button.size.y)
    var ship_width: float = minf(105.0 * s, flight_button.size.x * 0.38)
    flight_icon.position = Vector2(9.0 * s, 17.0 * s)
    flight_icon.size = Vector2(ship_width, 83.0 * s)
    flight_label.position = Vector2(18.0 * s + ship_width, 0)
    flight_label.size = Vector2(maxf(0.0, flight_button.size.x - 22.0 * s - ship_width), flight_button.size.y)
    for lbl in [sim_label, flight_label]:
        lbl.add_theme_font_size_override("font_size", maxi(14, int(29.0 * s)))

    # Locate content IN the cavity of the original image, not in a fake housing.
    # Actual reference: cavity centered at asset x=1024, around y=337.
    var cavity_center_y: float = h - (ART_STRIP_BOTTOM - 341.0) * art_scale
    var icon_size: float = 75.0 * s
    crystal_icon.position = Vector2(w * 0.5 - 169.0 * s, cavity_center_y - icon_size * 0.50)
    crystal_icon.size = Vector2(icon_size, icon_size)
    count_label.position = Vector2(w * 0.5 - 40.0 * s, cavity_center_y - 53.0 * s)
    count_label.size = Vector2(220.0 * s, 106.0 * s)
    count_label.add_theme_font_size_override("font_size", maxi(25, int(60.0 * s)))
    queue_redraw()

func _draw() -> void:
    if size.x < 5.0 or size.y < 5.0:
        return
    # The source art has a tall transparent margin. Align the *visible*
    # horizontal band to the bottom of the HUD, with no horizontal stretching.
    var factor: float = size.y / (ART_STRIP_BOTTOM - ART_STRIP_TOP)
    var art_size: Vector2 = PANEL_ART.get_size() * factor
    var target: Rect2 = Rect2(
        Vector2((size.x - art_size.x) * 0.5, size.y - ART_STRIP_BOTTOM * factor),
        art_size
    )
    draw_texture_rect(PANEL_ART, target, false)

