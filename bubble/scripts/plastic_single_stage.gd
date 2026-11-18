extends Control
## F6 on any scene in scenes/actions/ launches only that action.
@onready var bg: Node2D = $Background
@onready var bubble: MikaBubblePlastic = $Bubble

func _ready() -> void:
    get_viewport().size_changed.connect(_relayout)
    _relayout()
    var h := Label.new()
    h.text = "БАББЛ  /  " + bubble.initial_action + "  /  Godot 4.7.1"
    h.position = Vector2(30.0, 25.0)
    h.add_theme_font_size_override("font_size", 28)
    h.add_theme_color_override("font_color", Color("b4e8fb"))
    add_child(h)
    var sub := Label.new()
    sub.text = "Отдельная сцена действия • анимация повторяется автоматически • F5 — общий экран"
    sub.position = Vector2(30.0, 69.0)
    sub.add_theme_font_size_override("font_size", 15)
    add_child(sub)

func _relayout() -> void:
    var s: Vector2 = get_viewport_rect().size
    bubble.position = Vector2(s.x * 0.60, s.y * 0.53)
    bubble.scale = Vector2.ONE * clampf(minf(s.x / 1600.0, s.y / 900.0) * 0.83, 0.45, 0.83)
    bg.queue_redraw()
