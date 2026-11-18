@tool
extends Control
## Decorative entry arrow for an EXISTING PlanetHub card. No new card/menu.
## The parent card remains the only interactive element.
@export var representative_mode: bool = false

func _ready() -> void:
    name = "MikaEntryArrow"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var card: Control = get_parent() as Control
    if card != null:
        card.resized.connect(_fit)
    _fit()

func _fit() -> void:
    var card: Control = get_parent() as Control
    if card == null or card.size.x <= 10.0 or card.size.y <= 10.0:
        return
    var s: float = minf(card.size.x / 430.0, card.size.y / 540.0)
    var plaque_y: float = card.size.y * 0.685
    var side: float = 42.0 * s
    position = Vector2(card.size.x - (39.0 + 42.0) * s, plaque_y + 15.0 * s)
    size = Vector2(side, side)
    var caption: Label = card.get_node_or_null("CardTitle") as Label
    if caption != null:
        # Card title is left-aligned, arrow right-aligned, symmetrical side margins.
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        caption.size.x = maxf(75.0 * s, position.x - caption.position.x - 10.0 * s)
    if representative_mode:
        var subtitle: Label = card.get_node_or_null("CardSubtitle") as Label
        if subtitle != null:
            subtitle.visible = false
        var description: Label = card.get_node_or_null("CardDescription") as Label
        if description != null:
            description.position.y = plaque_y + 70.0 * s
            description.size.y = maxf(20.0 * s, card.size.y - description.position.y - 25.0 * s)
    queue_redraw()

func _draw() -> void:
    var c: Vector2 = size * 0.5
    var radius: float = minf(size.x, size.y) * 0.43
    draw_circle(c, radius, Color(0.05, 0.24, 0.37, 0.64))
    draw_arc(c, radius, 0.0, TAU, 28, Color("7cdcf5"), maxf(1.3, size.x * 0.048), true)
    var tri: PackedVector2Array = PackedVector2Array([
        c + Vector2(-5.0, -9.0) * (size.x / 42.0),
        c + Vector2(9.5, 0.0) * (size.x / 42.0),
        c + Vector2(-5.0, 9.0) * (size.x / 42.0)
    ])
    draw_colored_polygon(tri, Color("d0faff"))
