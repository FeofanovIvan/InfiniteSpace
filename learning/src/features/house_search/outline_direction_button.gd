extends Button

@export var arrow_direction: Vector2 = Vector2.UP

# Exact button colors and StyleBoxFlat settings from ice_cream_game_v5_4.gd.
func _ready() -> void:
    focus_mode = Control.FOCUS_NONE
    flat = false
    text = _arrow_text()
    add_theme_font_size_override("font_size", 43)
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        add_theme_color_override(state, Color("#ffffff"))
    add_theme_stylebox_override("normal", _control_style(Color("#59bce6")))
    add_theme_stylebox_override("hover", _control_style(Color("#83d8f7")))
    add_theme_stylebox_override("pressed", _control_style(Color("#238dbf")))
    add_theme_stylebox_override("disabled", _control_style(Color("#9fbfcf")))
    add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _arrow_text() -> String:
    if arrow_direction == Vector2.UP:
        return "↑"
    if arrow_direction == Vector2.DOWN:
        return "↓"
    if arrow_direction == Vector2.LEFT:
        return "←"
    return "→"


func _control_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color("#dff7ff")
    style.set_border_width_all(2)
    style.set_corner_radius_all(16)
    style.shadow_color = Color(0.05, 0.25, 0.39, 0.28)
    style.shadow_size = 6
    style.shadow_offset = Vector2(0, 4)
    return style
