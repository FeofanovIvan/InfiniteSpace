@tool
extends Control
## Bottom sci-fi HUD is drawn in Godot; icons are separate PNG textures.
## Its buttons work and emit simulator_pressed / flight_pressed.

signal simulator_pressed
signal flight_pressed

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
    count_label = _new_label("CrystalCount", str(crystal_count), self, 38)
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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
    if sim_button == null:
        return
    var s: float = size.y / 142.0
    var w: float = size.x
    var bw: float = minf(430*s, w*0.29)
    var button_h: float = 107*s
    sim_button.position = Vector2(20*s, 20*s)
    sim_button.size = Vector2(bw,button_h)
    flight_button.position = Vector2(w-20*s-bw,20*s)
    flight_button.size = Vector2(bw,button_h)
    sim_icon.position = Vector2(35*s,11*s)
    sim_icon.size = Vector2(95*s,86*s)
    flight_icon.position = Vector2(48*s,22*s)
    flight_icon.size = Vector2(124*s,69*s)
    sim_label.position = Vector2(170*s,0)
    sim_label.size = Vector2(maxf(0,bw-185*s),button_h)
    flight_label.position = Vector2(205*s,0)
    flight_label.size = Vector2(maxf(0,bw-216*s),button_h)
    for lbl in [sim_label,flight_label]:
        lbl.add_theme_font_size_override("font_size", maxi(16,int(29*s)))
    count_label.position = Vector2(w/2.0+6*s, 26*s)
    count_label.size = Vector2(144*s,90*s)
    count_label.add_theme_font_size_override("font_size", maxi(20,int(39*s)))
    queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w <= 10 or h <= 10:
        return
    var s: float = h/142.0
    # Steel-blue spine connecting both enlarged ends.
    _fill(PackedVector2Array([
        Vector2(0,13*s), Vector2(w,13*s),Vector2(w,h),Vector2(0,h)]),Color(0.014,0.046,0.085,0.98))
    draw_rect(Rect2(0,16*s,w,8*s),Color(0.03,0.19,0.32,0.9))
    draw_line(Vector2(0,16*s),Vector2(w,16*s),Color(0.29,0.64,0.8,0.85),2.0*s,true)
    draw_line(Vector2(0, 35*s),Vector2(w,35*s),Color(0.07,0.23,0.43,0.9),3*s,true)
    draw_line(Vector2(0, h-13*s),Vector2(w,h-13*s),Color(0.13,0.34,0.51,0.9),3*s,true)
    # Metallic segmented rails near center.
    for i in range(9):
        var xx: float = w*0.30 + (w*0.40)*float(i)/8.0
        draw_line(Vector2(xx,23*s),Vector2(xx,31*s),Color(0.2,0.48,0.68,0.25),2*s)

    var bw: float = minf(430*s,w*0.29)
    var lr: Rect2 = Rect2(20*s,20*s,bw,107*s)
    var rr: Rect2 = Rect2(w-20*s-bw,20*s,bw,107*s)
    _button_plate(lr, Color("36c8ff"), _over_sim, s)
    _button_plate(rr, Color("ffae35"), _over_flight, s)

    # Center counter housing, a bright reusable crystal drawn entirely with polygons.
    var center_width: float = minf(390*s,maxf(200*s,w*0.27))
    var center_rect: Rect2 = Rect2(w/2.0-center_width/2.0,32*s,center_width,84*s)
    var plate: PackedVector2Array = _octagonal(center_rect,24*s)
    _fill(plate,Color(0.012,0.095,0.17,0.96))
    _outline(plate,Color(0.06,0.56,0.88,0.35),8*s)
    _outline(plate,Color(0.2,0.68,1.0,0.83),2*s)
    draw_line(Vector2(center_rect.position.x+44*s,center_rect.position.y+5*s),Vector2(center_rect.end.x-44*s,center_rect.position.y+5*s),Color(0.31,0.77,1,0.75),2*s,true)
    _crystal(Vector2(w/2.0-80*s,75*s),s)

func _button_plate(rect: Rect2, neon: Color, hovered: bool, s: float) -> void:
    var outer: PackedVector2Array = _octagonal(rect,27*s)
    _outline(outer,Color(neon.r,neon.g,neon.b,0.13),17*s)
    _fill(outer,Color(0.006,0.075,0.145,0.99))
    var inner: PackedVector2Array = _octagonal(rect.grow(-7*s),22*s)
    var alpha: float = 0.35 if hovered else 0.17
    _fill(inner,Color(neon.r*0.2,neon.g*0.3,neon.b*0.38,0.68+alpha))
    _outline(outer,Color(neon.r,neon.g,neon.b,0.95),3.5*s)
    _outline(inner,Color(neon.r,neon.g,neon.b,0.40),1.4*s)
    draw_line(Vector2(rect.position.x+47*s,rect.position.y+5*s),Vector2(rect.end.x-47*s,rect.position.y+5*s),Color(neon.r,neon.g,neon.b,0.9),3*s,true)
    draw_line(Vector2(rect.position.x+54*s,rect.end.y-4*s),Vector2(rect.end.x-54*s,rect.end.y-4*s),Color(neon.r,neon.g,neon.b,0.75),2*s,true)

func _crystal(c: Vector2, s: float) -> void:
    var top: Vector2 = c+Vector2(0,-33*s)
    var left: Vector2 = c+Vector2(-22*s,-4*s)
    var right: Vector2 = c+Vector2(22*s,-4*s)
    var bottom: Vector2 = c+Vector2(0,35*s)
    var middle: Vector2 = c+Vector2(0,15*s)
    var top_mid: Vector2 = c+Vector2(0,-11*s)
    _fill(PackedVector2Array([top,left,middle,top_mid]),Color("13a5fa"))
    _fill(PackedVector2Array([top,top_mid,middle,right]),Color("9df5ff"))
    _fill(PackedVector2Array([left,bottom,middle]),Color("0070e5"))
    _fill(PackedVector2Array([middle,bottom,right]),Color("15b7ff"))
    _outline(PackedVector2Array([top,right,bottom,left]),Color("a1f6ff"),2*s)
    draw_line(top, middle,Color("e4ffff"),1*s,true)

func _octagonal(rect: Rect2, c: float) -> PackedVector2Array:
    return PackedVector2Array([
        rect.position+Vector2(c,0),Vector2(rect.end.x-c,rect.position.y),
        Vector2(rect.end.x,rect.position.y+c),Vector2(rect.end.x,rect.end.y-c),
        rect.end-Vector2(c,0),Vector2(rect.position.x+c,rect.end.y),
        Vector2(rect.position.x,rect.end.y-c),rect.position+Vector2(0,c)])

func _fill(p: PackedVector2Array, color: Color) -> void:
    draw_colored_polygon(p,color)

func _outline(p: PackedVector2Array, color: Color, width: float) -> void:
    var closed: PackedVector2Array = p.duplicate()
    closed.append(p[0])
    draw_polyline(closed,color,width,true)
