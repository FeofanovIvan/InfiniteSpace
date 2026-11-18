extends Control
class_name MikaComicLettering
## Editable, locale-aware vector comic lettering. No pre-rendered caption images.
## Safe-area anchored balloons for landscape viewport ratios.
## Original YouTube scene anchors, but the text itself is never cropped.

const INK = Color("241335")
const CREAM = Color("fff4df")
const ROSE = Color("ffb2ce")
const VIOLET = Color("6d38b9")
const RED = Color("fb4f6b")

@export var optional_comic_font: Font

var _active_cue: Dictionary = {}
var _view_rect: Rect2 = Rect2()
var _fade: float = 1.0
var _panel_size: Vector2 = Vector2.ZERO
var _headline: Label
var _subline: Label
var _fit_font: Font
var _shape_style: String = "caption"
var _tail_side: int = 1
var _tail_anchor: Vector2 = Vector2.ZERO
var _has_tail_anchor: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fit_font = optional_comic_font if optional_comic_font != null else ThemeDB.fallback_font
    _headline = Label.new()
    _headline.name = "Headline_EN"
    _headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _headline.clip_text = false
    _headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    add_child(_headline)
    _subline = Label.new()
    _subline.name = "Secondary_EN"
    _subline.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _subline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _subline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(_subline)
    if optional_comic_font != null:
        _headline.add_theme_font_override("font", optional_comic_font)
        _subline.add_theme_font_override("font", optional_comic_font)
    visible = false

func update_cue(cue: Dictionary, picture_rect: Rect2, portrait_mode: bool, opacity: float) -> void:
    if cue.is_empty():
        visible = false
        return
    var needs_layout: bool = (not visible or str(_active_cue.get("id", "")) != str(cue.get("id", ""))
        or _view_rect != picture_rect)
    visible = true
    modulate = Color(1, 1, 1, opacity)
    if not needs_layout:
        return
    _active_cue = cue
    _view_rect = picture_rect
    _fade = opacity
    modulate = Color(1, 1, 1, opacity)
    _shape_style = str(cue.get("style", "caption"))

    var root_size: Vector2 = (get_parent() as Control).size
    var panel_width: float = 0.0
    var font_main: int = 30
    var font_small: int = 24
    var panel_height: float = 100.0
    var origin: Vector2 = Vector2.ZERO
    var text1: String = str(cue.get("text", ""))
    var text2: String = str(cue.get("secondary", ""))
    # Start from our 1280x720 YouTube layout, then shift the entire bubble
    # inside the real, visible phone/tablet/laptop screen (not picture_rect).
    var scale_factor: float = picture_rect.size.x / 1280.0
    var safe: Rect2 = Rect2(Vector2.ZERO, root_size)
    if has_node("/root/MobileLocale"):
        safe = get_node("/root/MobileLocale").safe_rect(root_size)
    var safe_margin: float = maxf(10.0, minf(root_size.x, root_size.y) * 0.025)
    var safe_width: float = maxf(80.0, safe.size.x - 2.0 * safe_margin)
    var safe_height: float = maxf(70.0, safe.size.y - 2.0 * safe_margin)
    var virtual_width: float = float(cue.get("w", 0.0))
    var desired_width: float = maxf(virtual_width, 260.0)
    if virtual_width <= 0.0:
        desired_width = clampf(float(text1.length()) * 26.0 + 100.0, 340.0, 840.0)
    if not text2.is_empty():
        desired_width = maxf(desired_width, clampf(float(text2.length()) * 23.0 + 100.0, 390.0, 860.0))
    panel_width = minf(desired_width * scale_factor, safe_width)
    font_main = int(clampf(36.0 * scale_factor, 12.0, safe_height * 0.074))
    font_small = int(clampf(28.0 * scale_factor, 11.0, safe_height * 0.060))
    if _shape_style == "title":
        font_main = int(clampf(62.0 * scale_factor, 14.0, safe_height * 0.11))
    elif _shape_style == "scream":
        font_main = int(clampf(65.0 * scale_factor, 14.0, safe_height * 0.12))
    panel_height = (142.0 if not text2.is_empty() else 91.0) * scale_factor
    if _shape_style in ["title", "scream"]:
        panel_height = 150.0 * scale_factor
    panel_height = minf(panel_height, safe_height * 0.38)
    origin = picture_rect.position + Vector2(
        float(cue.get("x", 65.0)) * scale_factor,
        float(cue.get("y", 70.0)) * scale_factor)
    origin.x = clampf(origin.x, safe.position.x + safe_margin,
        maxf(safe.position.x + safe_margin, safe.end.x - safe_margin - panel_width))
    origin.y = clampf(origin.y, safe.position.y + safe_margin,
        maxf(safe.position.y + safe_margin, safe.end.y - safe_margin - panel_height))

    _panel_size = Vector2(panel_width, panel_height)
    var cue_tail: Variant = cue.get("tail", [])
    _has_tail_anchor = cue_tail is Array and cue_tail.size() == 2
    if _has_tail_anchor:
        var world_anchor: Vector2 = picture_rect.position + Vector2(float(cue_tail[0]), float(cue_tail[1])) * scale_factor
        world_anchor.x = clampf(world_anchor.x, safe.position.x + 4.0, safe.end.x - 4.0)
        world_anchor.y = clampf(world_anchor.y, safe.position.y + 4.0, safe.end.y - 4.0)
        _tail_anchor = world_anchor - origin
    position = origin
    size = _panel_size
    var pad: float = clampf(panel_width * 0.054, 14.0, 34.0)
    var text_room: float = maxf(60.0, panel_width - pad * 2.0)
    font_main = _fit_text_size(text1, font_main, text_room)
    font_small = _fit_text_size(text2, font_small, text_room)

    _headline.text = text1
    _headline.position = Vector2(pad, 5.0)
    _headline.size = Vector2(text_room, panel_height * (0.59 if not text2.is_empty() else 0.85))
    _headline.add_theme_font_size_override("font_size", font_main)
    _headline.add_theme_color_override("font_color", _text_color())
    _headline.add_theme_color_override("font_outline_color", INK)
    _headline.add_theme_constant_override("outline_size", 2 if _shape_style != "radio" else 0)
    _headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if _shape_style in ["balloon", "scream"] else HORIZONTAL_ALIGNMENT_LEFT

    _subline.text = text2
    _subline.visible = not text2.is_empty()
    _subline.position = Vector2(pad, panel_height * 0.55)
    _subline.size = Vector2(text_room, panel_height * 0.38)
    _subline.add_theme_font_size_override("font_size", font_small)
    _subline.add_theme_color_override("font_color", _text_color())
    _subline.add_theme_color_override("font_outline_color", INK)
    _subline.add_theme_constant_override("outline_size", 1 if _shape_style != "radio" else 0)
    _subline.horizontal_alignment = _headline.horizontal_alignment

    # The dialog 'tails' point downward for speech. Avoid covering faces by
    # keeping them inside the card's own small decorative extension.
    _tail_side = -1 if origin.x > root_size.x * 0.5 else 1
    queue_redraw()

func _fit_text_size(msg: String, initial_size: int, max_width: float) -> int:
    if msg.is_empty():
        return initial_size
    var f: int = initial_size
    while f > 11 and _fit_font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x > max_width:
        f -= 1
    return f

func _text_color() -> Color:
    if _shape_style == "radio":
        return Color("ffeaf5")
    if _shape_style == "scream":
        return Color("fff0ff")
    return INK

func _poly(points: PackedVector2Array, fill: Color, stroke: Color = INK, line_width: float = 3.0) -> void:
    draw_colored_polygon(points, fill)
    var closed_points := PackedVector2Array(points)
    closed_points.append(points[0])
    draw_polyline(closed_points, stroke, line_width, true)

func _draw() -> void:
    if _active_cue.is_empty():
        return
    var w: float = _panel_size.x
    var h: float = _panel_size.y
    var lw: float = clampf(w / 170.0, 2.0, 5.0)
    var inset: float = maxf(5.0, lw * 2.0)
    var path := PackedVector2Array([
        Vector2(inset + 12.0, inset), Vector2(w - inset - 13.0, inset),
        Vector2(w - inset, inset + 14.0), Vector2(w - inset, h - inset - 13.0),
        Vector2(w - inset - 13.0, h - inset), Vector2(inset + 13.0, h - inset),
        Vector2(inset, h - inset - 13.0), Vector2(inset, inset + 13.0)])
    # Offset shadow makes a physical comic sticker instead of a flat UI panel.
    draw_set_transform(Vector2(6, 6))
    draw_colored_polygon(path, Color(0.13, 0.04, 0.22, 0.36))
    draw_set_transform(Vector2.ZERO)

    if _shape_style == "scream":
        var center := Vector2(w / 2.0, h / 2.0)
        var burst := PackedVector2Array()
        var points_count: int = 24
        for i in range(points_count):
            var angle: float = float(i) * TAU / float(points_count)
            var radius: float = 0.49 if i % 2 == 0 else 0.34
            burst.append(center + Vector2(cos(angle) * w * radius, sin(angle) * h * radius))
        _poly(burst, RED, INK, lw + 1.0)
        return

    var fill := CREAM
    if _shape_style == "radio":
        fill = Color("35224f")
    elif _shape_style == "urgent":
        fill = Color("ffd4df")
    elif _shape_style == "title":
        fill = Color("ffebad")
    elif _shape_style == "balloon":
        fill = Color("fffcf6")
    _poly(path, fill, INK, lw)

    # Branded strips and details are vector graphics — no external plugin.
    if _shape_style in ["title", "caption", "urgent"]:
        var accent := ROSE if _shape_style != "urgent" else RED
        draw_rect(Rect2(inset + 3.0, inset + 12.0, maxf(4.0, lw * 1.7), h - inset * 2.0 - 23.0), accent, true)
        draw_line(Vector2(w - 45.0, inset + 10.0), Vector2(w - 20.0, inset + 10.0), VIOLET, lw)
    elif _shape_style == "radio":
        draw_line(Vector2(inset + 14.0, h - inset - 11.0), Vector2(w - inset - 14.0, h - inset - 11.0), RED, lw + 1.0)
        draw_circle(Vector2(w - inset - 17.0, inset + 16.0), 5.0, RED)
    elif _shape_style == "balloon":
        # Short tail anchored to the card, no long triangle over character eyes.
        var tail_x: float = w * (0.75 if _tail_side == 1 else 0.25)
        var tip: Vector2 = Vector2(tail_x + float(_tail_side) * 14.0, h + minf(20.0, h * 0.25))
        if _has_tail_anchor:
            tip = _tail_anchor
        var tail := PackedVector2Array([
            Vector2(tail_x - 8.0, h - inset),
            Vector2(tail_x + 8.0, h - inset),
            tip])
        _poly(tail, fill, INK, lw)
