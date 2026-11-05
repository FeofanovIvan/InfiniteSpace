extends Control
## Actual vector comic lettering L01–L12. Text remains a Label (not baked image).
## configure() uses style IDs and explicit dimensions; no external font downloads needed.
signal text_does_not_fit(id: String, text_value: String)
const Registry = preload("res://mika_comic_kit/scripts/comic_registry.gd")

var element_id: String = "L02"
var content: String = "Hello!"
var subtitle: String = ""
var target_point: Vector2 = Vector2(-1000.0, -1000.0)
var ui_scale: float = 1.0
var min_font_size: int = 18
var text_ok: bool = true
var home_position: Vector2 = Vector2.ZERO
var _label: Label
var _fill: Color
var _ink: Color
var _outline: Color
var _font: Font
var _font_px: int

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = false
    _label = Label.new()
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _label.clip_text = false
    add_child(_label)
    _apply()

func configure(id: String, value: String, secondary: String = "", box_size: Vector2 = Vector2(440, 174), speaker_anchor: Vector2 = Vector2(-1000, -1000), scale_factor: float = 1.0) -> void:
    element_id = id
    content = value
    subtitle = secondary
    target_point = speaker_anchor
    ui_scale = maxf(0.25, scale_factor)
    custom_minimum_size = Vector2.ZERO
    size = box_size
    if is_node_ready():
        _apply()

func _apply() -> void:
    var preset: Dictionary = Registry.lettering(element_id)
    _fill = Registry.color_id(str(preset.get("fill_color_id", "C02")))
    _ink = Registry.color_id(str(preset.get("text_color_id", "C01")))
    _outline = Registry.color_id(str(preset.get("outline_color_id", "C01")))
    var fid: String = str(preset.get("font_id", "F01"))
    _font = Registry.font_resource(fid)
    var displayed: String = content
    if not subtitle.is_empty():
        displayed += "\n" + subtitle
    _label.text = displayed
    var padding: float = maxf(12.0, 25.0 * ui_scale)
    if element_id == "L08":
        padding = maxf(24.0, 44.0 * ui_scale)
    if element_id == "L09":
        padding = 8.0
    _label.position = Vector2(padding, padding * 0.75)
    _label.size = Vector2(maxf(1.0, size.x - padding * 2.0), maxf(1.0, size.y - padding * 1.5))
    _label.custom_maximum_size = Vector2(_label.size.x,0.0)
    _label.add_theme_color_override("font_color", _ink)
    _label.add_theme_color_override("font_outline_color", Registry.color_id("C12") if element_id == "L09" else Color(0, 0, 0, 0))
    _label.add_theme_constant_override("outline_size", 4 if element_id == "L09" else 0)
    _label.add_theme_font_override("font", _font)
    _font_px = maxi(min_font_size, int(float(Registry.font_size(fid)) * ui_scale))
    _fit_label()
    queue_redraw()

func _fit_label() -> void:
    text_ok = false
    var width: float = _label.size.x
    var height: float = _label.size.y
    var desired_min: int = maxi(14, int(float(min_font_size) * ui_scale))
    for font_px in range(_font_px, desired_min - 1, -1):
        if _estimated_fits(_label.text, font_px, width, height):
            _font_px = font_px
            text_ok = true
            break
    if not text_ok:
        # Never silently clip or let letters escape the graphic; caller can split the cue.
        _font_px = desired_min
        text_does_not_fit.emit(element_id, _label.text)
    _label.add_theme_font_size_override("font_size", _font_px)
    _label.visible = text_ok

func _estimated_fits(value: String, font_px: int, width: float, height: float) -> bool:
    if _font == null:
        return false
    var all_lines: int = 0
    for paragraph in value.split("\n"):
        var running: String = ""
        var line_count: int = 1
        for word in paragraph.split(" ", false):
            var candidate: String = word if running.is_empty() else running + " " + word
            if _font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x <= width:
                running = candidate
            else:
                if _font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > width:
                    return false
                line_count += 1
                running = word
        all_lines += line_count
    return float(all_lines) * _font.get_height(font_px) * 1.10 <= height

func set_home(pos: Vector2) -> void:
    home_position = pos
    position = pos
    pivot_offset = size * 0.5

func seek_entrance(progress: float) -> void:
    # Reproducible motion, no Tween state; legal to scrub the timeline to any timestamp.
    var q: float = clampf(progress,0.0,1.0)
    var eased: float = q*q*(3.0-2.0*q)
    var preset: Dictionary = Registry.lettering(element_id)
    var animation: String = str(preset.get("entry_animation","fade"))
    position = home_position
    scale = Vector2.ONE
    modulate.a = eased
    match animation:
        "fade_slide", "slide", "title_reveal":
            position = home_position + Vector2(0.0, 34.0 * (1.0-eased) * ui_scale)
        "pop", "punch", "impact_once":
            var magnitude: float = 0.16 if animation == "pop" else 0.23
            var value: float = 1.0-magnitude*(1.0-eased)
            if animation == "impact_once":
                value += 0.04 * sin(q*PI) * (1.0-eased)
            scale = Vector2.ONE*value
        "quick_reveal":
            modulate.a = clampf(q*2.0,0.0,1.0)
        "snap":
            modulate.a = 1.0 if q>0.12 else 0.0
        _:
            pass

func _rounded_points(rect: Rect2, r: float) -> PackedVector2Array:
    var p: PackedVector2Array = PackedVector2Array()
    var centers: Array[Vector2] = [Vector2(rect.end.x-r, rect.position.y+r), Vector2(rect.end.x-r, rect.end.y-r), Vector2(rect.position.x+r, rect.end.y-r), Vector2(rect.position.x+r, rect.position.y+r)]
    for corner in range(4):
        for j in range(9):
            var a: float = (-0.5 + float(corner) * 0.5) * PI + (float(j) / 8.0) * PI * 0.5
            p.append(centers[corner] + Vector2(cos(a), sin(a)) * r)
    return p

func _paint_polygon(p: PackedVector2Array, fill: Color, ink: Color, stroke: float = 3.0) -> void:
    draw_colored_polygon(p, fill)
    var closed: PackedVector2Array = p.duplicate()
    closed.append(p[0])
    draw_polyline(closed, ink, stroke, true)

func _ellipse_points(center: Vector2, radius: Vector2, count: int = 60) -> PackedVector2Array:
    var p := PackedVector2Array()
    for i in range(count):
        var a := TAU * float(i) / float(count)
        p.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
    return p

func _burst_points(center: Vector2, radius: Vector2) -> PackedVector2Array:
    var p := PackedVector2Array()
    for i in range(36):
        var a: float = -PI * 0.5 + TAU * float(i) / 36.0
        var f: float = 1.0 if i % 2 == 0 else 0.78
        p.append(center + Vector2(cos(a)*radius.x*f, sin(a)*radius.y*f))
    return p

func _tail() -> void:
    if target_point.x < -100.0:
        return
    var origin: Vector2 = Vector2(size.x*0.5, size.y*0.83)
    var to_target: Vector2 = target_point - origin
    if to_target.length() < 20.0:
        return
    var ortho: Vector2 = to_target.normalized().orthogonal() * minf(24.0, 12.0 * ui_scale)
    var tip: Vector2 = target_point
    # Tail is behind the panel because it is drawn first.
    var points := PackedVector2Array([origin-ortho, origin+ortho, tip])
    draw_colored_polygon(points, _fill)
    draw_line(origin-ortho, tip, _outline, 3.0, true)
    draw_line(origin+ortho, tip, _outline, 3.0, true)

func _draw() -> void:
    var r := Rect2(Vector2(3,3), size-Vector2(6,6))
    var inset := 4.0 * ui_scale
    match element_id:
        "L01":
            _paint_polygon(_rounded_points(r, 18.0), _fill, _outline)
            draw_rect(Rect2(12,12,6,size.y-24),Registry.color_id("C03"))
        "L02":
            _tail()
            _paint_polygon(_ellipse_points(size*0.5, Vector2(size.x*0.49,size.y*0.47)), _fill, _outline)
        "L03":
            _paint_polygon(PackedVector2Array([Vector2(27,3),Vector2(size.x-27,3),Vector2(size.x-3,27),Vector2(size.x-3,size.y-3),Vector2(3,size.y-3),Vector2(3,27)]),_fill,_outline)
            draw_line(Vector2(32,10),Vector2(size.x-32,10),Registry.color_id("C04"),3)
        "L04":
            var pts := PackedVector2Array([Vector2(22,3),Vector2(size.x-22,3),Vector2(size.x-3,22),Vector2(size.x-3,size.y-20),Vector2(size.x-22,size.y-3),Vector2(22,size.y-3),Vector2(3,size.y-20),Vector2(3,22)])
            _paint_polygon(pts,_fill,_outline,4.0)
            draw_rect(Rect2(13,13,size.x-26,size.y-26),_outline,false,2.0)
        "L05":
            _tail()
            _paint_polygon(_rounded_points(r,12.0),_fill,_outline,2.0)
            var cyan: Color = Registry.color_id("C09")
            for x in [12.0,size.x-12.0]:
                for y in [12.0,size.y-12.0]:
                    var dx: float = 1.0 if x < size.x*0.5 else -1.0
                    var dy: float = 1.0 if y < size.y*0.5 else -1.0
                    draw_line(Vector2(x,y),Vector2(x+dx*30,y),cyan,4.0)
                    draw_line(Vector2(x,y),Vector2(x,y+dy*24),cyan,4.0)
        "L06":
            _tail()
            var ep := _ellipse_points(size*0.5,Vector2(size.x*0.49,size.y*0.47))
            draw_colored_polygon(ep,_fill)
            for i in range(0,ep.size(),4):
                var nxt: int = (i+2) % ep.size()
                draw_line(ep[i],ep[nxt],_outline,2.5,true)
        "L07":
            _paint_polygon(_rounded_points(r,16),_fill,_outline)
            draw_circle(Vector2(20,20),6,Registry.color_id("C03"))
        "L08":
            _tail()
            _paint_polygon(_burst_points(size*0.5, size*0.48),_fill,_outline,4.5)
        "L09":
            pass  # SFX typography without a container
        "L10":
            draw_colored_polygon(_rounded_points(r,22),_fill)
            draw_rect(Rect2(16,size.y-11,size.x-32,5),Registry.color_id("C03"))
        "L11":
            _paint_polygon(_rounded_points(r,12),_fill,_outline)
            draw_rect(Rect2(size.x-9,10,4,size.y-20),Registry.color_id("C09"))
        "L12":
            _paint_polygon(_rounded_points(r,20),_fill,_outline)
            draw_line(Vector2(12,size.y-10),Vector2(2,size.y+8),_outline,3.0)
        _:
            _paint_polygon(_rounded_points(r,18),_fill,_outline)
