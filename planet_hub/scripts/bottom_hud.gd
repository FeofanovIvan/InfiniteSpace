@tool
extends Control
## v68: neon capsule HUD styled after the approved planetary landing reference.
## Buttons, six-language labels, and crystal count stay live Godot controls.

signal simulator_pressed
signal flight_pressed

const CRYSTAL_ART: Texture2D = preload("res://planet_hub/assets/v68_neon/crystal_reference.png")
const SIM_PANEL: Texture2D = preload("res://planet_hub/assets/v68_neon/simulator_panel.png")
const LAUNCH_PANEL: Texture2D = preload("res://planet_hub/assets/v68_neon/launch_panel.png")
const COUNTER_PANEL: Texture2D = preload("res://planet_hub/assets/v68_neon/crystals_panel.png")
const SIM_BADGE: Texture2D = preload("res://planet_hub/assets/v68_neon/simulator_badge.png")
const LAUNCH_BADGE: Texture2D = preload("res://planet_hub/assets/v68_neon/launch_badge.png")

@export var crystal_count: int = 0:
    set(value):
        crystal_count = maxi(0, value)
        if count_label != null:
            count_label.text = str(crystal_count)
            if sim_button != null:
                _layout_items()
        queue_redraw()

var sim_button: Button
var flight_button: Button
var sim_panel: NinePatchRect
var flight_panel: NinePatchRect
var center_panel: NinePatchRect
var sim_icon: TextureRect
var flight_icon: TextureRect
var crystal_icon: TextureRect
var sim_label: Label
var flight_label: Label
var count_label: Label
var counter_divider_glow: ColorRect
var counter_divider: ColorRect

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    sim_button = _new_button("SimulatorButton")
    flight_button = _new_button("LaunchButton")
    sim_panel = _new_panel("CyanBlueNeonCapsule", SIM_PANEL, sim_button)
    flight_panel = _new_panel("AmberOrangeNeonCapsule", LAUNCH_PANEL, flight_button)
    center_panel = _new_panel("MidnightBlueCrystalCounter", COUNTER_PANEL, self)
    sim_icon = _new_icon("SimulatorHelmetBadge", SIM_BADGE, sim_button)
    flight_icon = _new_icon("LaunchShipBadge", LAUNCH_BADGE, flight_button)
    sim_label = _new_label("SimulatorText", sim_button)
    flight_label = _new_label("LaunchText", flight_button)
    crystal_icon = _new_icon("CollectedCrystal_ReferenceArt", CRYSTAL_ART, self)
    counter_divider_glow = _new_separator("CounterDividerGlow", Color(0.11, 0.76, 1.0, 0.34))
    counter_divider = _new_separator("CounterDivider", Color(0.57, 0.92, 1.0, 0.94))
    count_label = _new_label("LiveCrystalCount", self)
    count_label.text = str(crystal_count)
    count_label.add_theme_color_override("font_color", Color.WHITE)
    count_label.add_theme_color_override("font_outline_color", Color("071a37"))
    count_label.add_theme_constant_override("outline_size", 2)
    sim_button.mouse_entered.connect(_on_button_highlight.bind(true, true))
    sim_button.mouse_exited.connect(_on_button_highlight.bind(true, false))
    flight_button.mouse_entered.connect(_on_button_highlight.bind(false, true))
    flight_button.mouse_exited.connect(_on_button_highlight.bind(false, false))
    sim_button.button_down.connect(_on_button_press.bind(true, true))
    sim_button.button_up.connect(_on_button_press.bind(true, false))
    flight_button.button_down.connect(_on_button_press.bind(false, true))
    flight_button.button_up.connect(_on_button_press.bind(false, false))
    sim_button.pressed.connect(func(): simulator_pressed.emit())
    flight_button.pressed.connect(func(): flight_pressed.emit())
    resized.connect(_layout_items)
    if not Engine.is_editor_hint():
        MobileLocale.language_changed.connect(_on_language_changed)
    _on_language_changed("ru" if Engine.is_editor_hint() else MobileLocale.language)
    _layout_items()

func _on_button_highlight(is_sim: bool, hovering: bool) -> void:
    var panel: NinePatchRect = sim_panel if is_sim else flight_panel
    panel.self_modulate = Color(1.0, 1.12, 1.18) if hovering else Color.WHITE

func _on_button_press(is_sim: bool, pressed: bool) -> void:
    var panel: NinePatchRect = sim_panel if is_sim else flight_panel
    panel.self_modulate = Color(0.76, 0.85, 0.93) if pressed else Color.WHITE

func _new_button(node_name: String) -> Button:
    var button := Button.new()
    button.name = node_name
    button.flat = true
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    for state in ["normal", "hover", "pressed", "disabled", "focus"]:
        button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
    add_child(button)
    return button

func _new_panel(node_name: String, texture: Texture2D, parent: Control) -> NinePatchRect:
    var panel := NinePatchRect.new()
    panel.name = node_name
    panel.texture = texture
    panel.patch_margin_left = 66
    panel.patch_margin_right = 66
    panel.patch_margin_top = 44
    panel.patch_margin_bottom = 44
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(panel)
    return panel

func _new_icon(node_name: String, art: Texture2D, parent: Control) -> TextureRect:
    var icon := TextureRect.new()
    icon.name = node_name
    icon.texture = art
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(icon)
    return icon

func _new_label(node_name: String, parent: Control) -> Label:
    var label := Label.new()
    label.name = node_name
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.clip_text = true
    label.add_theme_color_override("font_color", Color.WHITE)
    label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.18, 0.8))
    label.add_theme_constant_override("outline_size", 3)
    parent.add_child(label)
    return label

func _new_separator(node_name: String, tint: Color) -> ColorRect:
    var rect := ColorRect.new()
    rect.name = node_name
    rect.color = tint
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(rect)
    return rect

func _on_language_changed(locale: String) -> void:
    if sim_label == null:
        return
    var ru: bool = Engine.is_editor_hint() or locale == "ru"
    sim_label.text = "Симулятор" if ru else MobileLocale.t("planet_simulator")
    # The reference says Запуск; keep existing translation for other languages.
    flight_label.text = "Запуск" if ru else MobileLocale.t("planet_depart")
    sim_button.tooltip_text = sim_label.text
    flight_button.tooltip_text = flight_label.text
    _layout_items()

func _layout_items() -> void:
    if sim_button == null or size.x < 200.0 or size.y < 38.0:
        return
    var w: float = size.x
    var s: float = minf(size.y / 158.0, w / 1680.0)
    var wing_w: float = 594.0 * s
    var center_w: float = 394.0 * s
    var center_x: float = (w - center_w) * 0.5
    var right_x: float = w - wing_w

    sim_button.position = Vector2.ZERO
    sim_button.size = Vector2(wing_w, size.y)
    flight_button.position = Vector2(right_x, 0.0)
    flight_button.size = Vector2(wing_w, size.y)

    sim_panel.position = Vector2(70.0 * s, 5.0 * s)
    sim_panel.size = Vector2(wing_w - 77.0 * s, 148.0 * s)
    flight_panel.position = Vector2(7.0 * s, 5.0 * s)
    flight_panel.size = Vector2(wing_w - 77.0 * s, 148.0 * s)
    center_panel.position = Vector2(center_x, 0.0)
    center_panel.size = Vector2(center_w, 158.0 * s)

    # The badge texture is a transparent cutout of the reference, including its glowing ring.
    sim_icon.position = Vector2(1.0 * s, 4.0 * s)
    sim_icon.size = Vector2(150.0 * s, 150.0 * s)
    flight_icon.position = Vector2(wing_w - 151.0 * s, 4.0 * s)
    flight_icon.size = Vector2(150.0 * s, 150.0 * s)

    sim_label.position = Vector2(151.0 * s, 27.0 * s)
    sim_label.size = Vector2(wing_w - 169.0 * s, 105.0 * s)
    flight_label.position = Vector2(18.0 * s, 27.0 * s)
    flight_label.size = Vector2(wing_w - 169.0 * s, 105.0 * s)
    for label in [sim_label, flight_label]:
        var chars: int = maxi(label.text.length(), 1)
        var base_px: float = 39.0 * s
        if chars > 11:
            base_px *= 11.0 / float(chars)
        label.add_theme_font_size_override("font_size", maxi(10, roundi(base_px)))
        label.add_theme_constant_override("outline_size", maxi(1, roundi(2.0 * s)))

    crystal_icon.position = Vector2(center_x + 43.0 * s, 31.0 * s)
    crystal_icon.size = Vector2(109.0 * s, 94.0 * s)
    counter_divider_glow.position = Vector2(center_x + 180.0 * s, 48.0 * s)
    counter_divider_glow.size = Vector2(5.0 * s, 65.0 * s)
    counter_divider.position = Vector2(center_x + 182.0 * s, 49.0 * s)
    counter_divider.size = Vector2(maxf(1.0, 1.6 * s), 63.0 * s)
    count_label.position = Vector2(center_x + 196.0 * s, 26.0 * s)
    count_label.size = Vector2(183.0 * s, 109.0 * s)
    var digit_count: int = maxi(str(crystal_count).length(), 2)
    var counter_px: float = 54.0 * s if digit_count <= 3 else 54.0 * s * 3.0 / float(digit_count)
    count_label.add_theme_font_size_override("font_size", maxi(11, roundi(counter_px)))
