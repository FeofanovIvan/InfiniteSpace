@tool
extends Control
## Free-standing hint module. Updates after every correctly entered character.

@export var target_phrase: String = "Привет":
    set(value):
        target_phrase = value
        _update_text()

var progress: int = 0:
    set(value):
        progress = value
        _update_text()

var _header: Label
var _task: Label
var _progress: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header = _label("HintHeader","✦  ПОДСКАЗКА",22,Color("7bddff"))
    _task = _label("HintText","",34,Color("ffe197"))
    _progress = _label("HintProgress","",17,Color("b1d8ef"))
    resized.connect(_relayout)
    _relayout()
    _update_text()

func _label(node_name: String, value: String, font_size: int, tint: Color) -> Label:
    var label: Label = Label.new()
    label.name = node_name
    label.text = value
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",tint)
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)
    return label

func _update_text() -> void:
    if _task == null:
        return
    _task.text = "Напиши: " + target_phrase
    _progress.text = ("Готово! Можно отправлять" if progress >= target_phrase.length() else "Введено: %d / %d" % [progress, target_phrase.length()])

func _relayout() -> void:
    if _header == null:
        return
    var s: float = minf(size.x/400.0,size.y/186.0)
    _header.position = Vector2(33*s,21*s)
    _header.size = Vector2(size.x-65*s,38*s)
    _header.add_theme_font_size_override("font_size",maxi(13,int(21*s)))
    _task.position = Vector2(33*s,70*s)
    _task.size = Vector2(size.x-65*s,54*s)
    _task.add_theme_font_size_override("font_size",maxi(19,int(32*s)))
    _progress.position = Vector2(34*s,137*s)
    _progress.size = Vector2(size.x-65*s,34*s)
    _progress.add_theme_font_size_override("font_size",maxi(12,int(16*s)))
    queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 5.0 or h < 5.0:
        return
    var s: float = minf(w/400.0,h/186.0)
    var p: PackedVector2Array = PackedVector2Array([
        Vector2(22*s,4*s),Vector2(w-23*s,4*s),Vector2(w-4*s,23*s),
        Vector2(w-4*s,h-24*s),Vector2(w-24*s,h-4*s),Vector2(22*s,h-4*s),
        Vector2(4*s,h-23*s),Vector2(4*s,22*s)])
    draw_colored_polygon(p,Color(0.01,0.07,0.14,0.96))
    var outline: PackedVector2Array = p.duplicate()
    outline.append(p[0])
    draw_polyline(outline,Color(0.03,0.55,1.0,0.25),8*s,true)
    draw_polyline(outline,Color(0.32,0.84,1.0,0.96),2.4*s,true)
    draw_line(Vector2(34*s,65*s),Vector2(w-34*s,65*s),Color(0.17,0.53,0.8,0.45),1*s,true)
    draw_line(Vector2(40*s,h-11*s),Vector2(w-40*s,h-11*s),Color(0.26,0.76,1.0,0.5),2*s,true)
