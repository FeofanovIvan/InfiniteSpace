extends Control
## Preview a specific gesture scene via F6. Restart its gesture after a short hold.
@onready var bg: Node2D = $Background
@onready var bubble: MikaBubbleGesture = $Bubble

func _ready() -> void:
    get_viewport().size_changed.connect(_relayout)
    _relayout()
    var heading := Label.new()
    heading.text = "БАББЛ / " + bubble.initial_action + " / Godot 4.7.1"
    heading.position = Vector2(30, 25)
    heading.add_theme_font_size_override("font_size", 27)
    heading.add_theme_color_override("font_color", Color("b4e8fb"))
    add_child(heading)
    var message := Label.new()
    message.text = "Отдельная сцена жеста: воспроизведение повторяется автоматически. F5 — главный экран."
    message.position = Vector2(30, 67)
    message.add_theme_font_size_override("font_size", 15)
    add_child(message)

func _process(_delta: float) -> void:
    bubble.position = Vector2(get_viewport_rect().size.x * 0.55, get_viewport_rect().size.y * 0.50) + bubble.motion_offset * bubble.scale.x

func _relayout() -> void:
    var sz: Vector2 = get_viewport_rect().size
    bubble.scale = Vector2.ONE * clampf(minf(sz.x / 1600.0, sz.y / 900.0) * 0.86, 0.45, 0.86)
    bg.queue_redraw()
