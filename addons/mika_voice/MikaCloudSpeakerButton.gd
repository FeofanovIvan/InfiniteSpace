extends "res://addons/mika_voice/SpeakerButton.gd"
## A circular blue/orange speaker beside each of the three original speech choices.
## Playback only. No recording, no voice recognition, no choice selection.
var _choice_selected: bool = false


func set_selected(value: bool) -> void:
    if _choice_selected == value:
        return
    _choice_selected = value
    _install_style()
    queue_redraw()


func _install_style() -> void:
    var blue: Color = Color("218fc5")
    var orange: Color = Color("d98b31")
    var normal: StyleBoxFlat = StyleBoxFlat.new()
    normal.bg_color = orange if _choice_selected else blue
    normal.border_color = Color("ffe9c8") if _choice_selected else Color("cceffd")
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(64)
    normal.anti_aliasing = true
    var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("f0a950") if _choice_selected else Color("4bb1de")
    var pressed_style: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
    pressed_style.bg_color = Color("c67923") if _choice_selected else Color("136b9c")
    add_theme_stylebox_override("normal", normal)
    add_theme_stylebox_override("hover", hover)
    add_theme_stylebox_override("pressed", pressed_style)
    add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _draw() -> void:
    # Vector speaker icon fitted to the size of the circular button.
    var scale_factor: float = minf(size.x, size.y) / 46.0
    var center: Vector2 = size * 0.5
    var paint: Color = Color("fff8e8") if _choice_selected else Color("f3fcff")
    var polygon: PackedVector2Array = PackedVector2Array([
        center + Vector2(-12.0, -5.0) * scale_factor,
        center + Vector2(-7.0, -5.0) * scale_factor,
        center + Vector2(-2.0, -10.0) * scale_factor,
        center + Vector2(-2.0, 10.0) * scale_factor,
        center + Vector2(-7.0, 5.0) * scale_factor,
        center + Vector2(-12.0, 5.0) * scale_factor
    ])
    draw_colored_polygon(polygon, paint)
    draw_arc(center + Vector2(-1.0, 0.0) * scale_factor, 11.0 * scale_factor,
        -0.68, 0.68, 14, paint, 2.0 * scale_factor, true)
    draw_arc(center + Vector2(-1.0, 0.0) * scale_factor, 16.0 * scale_factor,
        -0.65, 0.65, 14, paint, 1.7 * scale_factor, true)
