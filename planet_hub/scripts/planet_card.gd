@tool
extends Control
## Sci-fi card with a native-drawn frame, optional image, and editable text.
## Add your own illustration to assets/representative.png or assets/mission.png.

@export var card_title: String = "Представитель планеты":
    set(value):
        card_title = value
        _refresh()
@export var card_subtitle: String = "Имя: здесь будет имя":
    set(value):
        card_subtitle = value
        _refresh()
@export_multiline var card_description: String = "Здесь будет описание персонажа.":
    set(value):
        card_description = value
        _refresh()
@export var image_path: String = "":
    set(value):
        image_path = value
        _refresh()
@export var accent: Color = Color("20a8ff"):
    set(value):
        accent = value
        queue_redraw()

var artwork: TextureRect
var image_hint: Label
var title_label: Label
var subtitle_label: Label
var description_label: Label
var _loaded_image_path: String = ""

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = false
    artwork = TextureRect.new()
    artwork.name = "Artwork_ReplaceableImage"
    artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
    artwork.clip_contents = true
    add_child(artwork, false, Node.INTERNAL_MODE_BACK)

    image_hint = Label.new()
    image_hint.name = "ImagePlaceholder"
    image_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    image_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    image_hint.add_theme_color_override("font_color", Color(0.64, 0.83, 0.98, 0.74))
    image_hint.add_theme_font_size_override("font_size", 18)
    image_hint.text = "ИЗОБРАЖЕНИЕ\nдобавить позже"
    image_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(image_hint)

    title_label = _new_label("CardTitle", 28, Color("e7f8ff"))
    subtitle_label = _new_label("CardSubtitle", 18, Color("74ceff"))
    description_label = _new_label("CardDescription", 17, Color("d8e7f4"))
    description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

    resized.connect(_layout_content)
    _refresh()
    _layout_content()
    queue_redraw()

func _new_label(name_string: String, font_px: int, text_color: Color) -> Label:
    var label: Label = Label.new()
    label.name = name_string
    label.add_theme_font_size_override("font_size", font_px)
    label.add_theme_color_override("font_color", text_color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.clip_text = true
    add_child(label)
    return label

func _refresh() -> void:
    if artwork == null:
        queue_redraw()
        return
    title_label.text = card_title
    subtitle_label.text = card_subtitle
    description_label.text = card_description
    if image_path != _loaded_image_path:
        _loaded_image_path = image_path
        artwork.texture = null
        if not image_path.is_empty() and ResourceLoader.exists(image_path):
            artwork.texture = load(image_path) as Texture2D
    image_hint.visible = artwork.texture == null
    queue_redraw()

func _layout_content() -> void:
    if artwork == null:
        return
    var w: float = size.x
    var h: float = size.y
    var s: float = minf(w / 430.0, h / 540.0)
    var pad: float = 22.0 * s
    var plaque_y: float = h * 0.685
    artwork.position = Vector2(pad, pad)
    artwork.size = Vector2(w - 2.0 * pad, plaque_y - pad)
    image_hint.position = Vector2(pad, plaque_y-115.0*s)
    image_hint.size = Vector2(w-2.0*pad, 75.0*s)

    title_label.add_theme_font_size_override("font_size", maxi(16, int(26.0 * s)))
    title_label.position = Vector2(39.0 * s, plaque_y + 16.0 * s)
    title_label.size = Vector2(w - 64.0 * s, 42.0 * s)

    subtitle_label.add_theme_font_size_override("font_size", maxi(12, int(17.0 * s)))
    subtitle_label.position = Vector2(41.0 * s, plaque_y + 64.0 * s)
    subtitle_label.size = Vector2(w - 76.0 * s, 25.0 * s)

    description_label.add_theme_font_size_override("font_size", maxi(12, int(17.0 * s)))
    description_label.position = Vector2(41.0 * s, plaque_y + 94.0 * s)
    description_label.size = Vector2(w - 72.0 * s, maxf(0.0, h - plaque_y - 108.0 * s))
    image_hint.add_theme_font_size_override("font_size", maxi(12, int(17.0 * s)))
    queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w <= 3 or h <= 3:
        return
    var s: float = minf(w / 430.0, h / 540.0)
    var poly: PackedVector2Array = _corners(Rect2(4*s, 4*s, w-8*s, h-8*s), 24*s)
    draw_colored_polygon(poly, Color(0.006, 0.028, 0.075, 0.91))
    _stroke(poly, Color(0.04, 0.6, 1.0, 0.12), 12.0*s)
    _stroke(poly, Color(0.01, 0.42, 0.95, 0.36), 7.0*s)
    _stroke(poly, Color(0.25, 0.81, 1.0, 0.97), 2.8*s)

    var plaque_y: float = h*0.685
    var plaque: PackedVector2Array = PackedVector2Array([
        Vector2(8*s, plaque_y), Vector2(w-8*s, plaque_y),
        Vector2(w-8*s, h-32*s), Vector2(w-32*s, h-8*s),
        Vector2(29*s, h-8*s), Vector2(8*s, h-29*s)])
    draw_colored_polygon(plaque, Color(0.006, 0.055, 0.13, 0.98))
    draw_rect(Rect2(19*s, plaque_y-4*s, w-38*s, 4*s), Color(0.08, 0.57, 0.99, 0.9))
    draw_line(Vector2(40*s, plaque_y+60*s), Vector2(w-40*s, plaque_y+60*s), Color(0.22,0.51,0.75,0.38),1.2*s)

    # Non-image area: deliberately empty technical grid; textures can be inserted later.
    if not is_instance_valid(artwork) or artwork.texture == null:
        var top: float = 24.0*s
        var bottom: float = plaque_y-8.0*s
        var left: float = 25.0*s
        var right: float = w-25.0*s
        draw_rect(Rect2(left, top, right-left, bottom-top), Color(0.07, 0.16, 0.25, 0.38), true)
        for i in range(1, 8):
            var xx: float = lerpf(left, right, float(i)/8.0)
            draw_line(Vector2(xx, top), Vector2(xx, bottom), Color(0.35,0.67,0.9,0.12), 1*s)
        for j in range(1, 7):
            var yy: float = lerpf(top, bottom, float(j)/7.0)
            draw_line(Vector2(left, yy), Vector2(right, yy), Color(0.35,0.67,0.9,0.12), 1*s)
        draw_rect(Rect2(left, top, right-left, bottom-top), Color(0.15,0.58,0.9,0.55), false, 1.2*s)
        var cx: float = w/2.0
        var cy: float = (top + bottom)/2.0 - 31*s
        draw_rect(Rect2(cx-38*s,cy-28*s,76*s,56*s),Color(0.5,0.78,0.96,0.55),false,2*s)
        draw_circle(Vector2(cx+19*s,cy-11*s),6*s,Color(0.5,0.78,0.96,0.5))
        draw_polyline(PackedVector2Array([Vector2(cx-30*s,cy+19*s), Vector2(cx-8*s,cy-4*s),Vector2(cx+4*s,cy+9*s),Vector2(cx+17*s,cy-3*s),Vector2(cx+30*s,cy+19*s)]),Color(0.5,0.78,0.96,0.58),2*s,true)

    # Thin segmented frame highlights.
    draw_line(Vector2(36*s,8*s),Vector2(111*s,8*s),accent,3*s,true)
    draw_line(Vector2(w-113*s,8*s),Vector2(w-36*s,8*s),accent,3*s,true)
    draw_line(Vector2(9*s, h-110*s),Vector2(9*s,h-53*s),accent,3*s,true)
    draw_line(Vector2(w-9*s,h-110*s),Vector2(w-9*s,h-53*s),accent,3*s,true)

func _corners(r: Rect2, c: float) -> PackedVector2Array:
    return PackedVector2Array([
        Vector2(r.position.x+c, r.position.y),
        Vector2(r.end.x-c, r.position.y),
        Vector2(r.end.x, r.position.y+c),
        Vector2(r.end.x, r.end.y-c),
        Vector2(r.end.x-c, r.end.y),
        Vector2(r.position.x+c, r.end.y),
        Vector2(r.position.x, r.end.y-c),
        Vector2(r.position.x, r.position.y+c)])

func _stroke(points: PackedVector2Array, color: Color, width: float) -> void:
    var closed: PackedVector2Array = points.duplicate()
    closed.append(points[0])
    draw_polyline(closed, color, width, true)
