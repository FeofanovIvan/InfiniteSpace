extends Control
## Self-contained F6 preview wrapper for individual turn scenes.
@onready var background: Node2D = $Background
@onready var bubble: MikaBubbleTurn = $Bubble

func _ready() -> void:
    get_viewport().size_changed.connect(_layout)
    _layout()
    var title := Label.new()
    title.text = "БАББЛ / " + bubble.initial_action + " / Godot 4.7.1"
    title.position = Vector2(24, 20)
    title.add_theme_font_size_override("font_size", 25)
    add_child(title)
    var info := Label.new()
    info.text = "Сцена повторяет выбранный поворот автоматически. F5 — общий тестовый экран."
    info.position = Vector2(25, 58)
    info.add_theme_color_override("font_color", Color("acd7e9"))
    add_child(info)

func _layout() -> void:
    var sz: Vector2 = get_viewport_rect().size
    bubble.position = Vector2(sz.x * 0.54, sz.y * 0.52)
    bubble.scale = Vector2.ONE * clampf(minf(sz.x / 1600.0, sz.y / 900.0), 0.45, 0.87)
    background.queue_redraw()
