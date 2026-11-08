extends Node2D
## Fits the exact original 1672x941 art + ShowerFX together without stretching.

const ART_SIZE := Vector2(1672.0, 941.0)
@onready var stage: Node2D = $Stage

func _ready() -> void:
    get_viewport().size_changed.connect(_fit_to_viewport)
    _fit_to_viewport()

func _fit_to_viewport() -> void:
    var available: Vector2 = get_viewport().get_visible_rect().size
    var factor: float = minf(available.x / ART_SIZE.x, available.y / ART_SIZE.y)
    stage.scale = Vector2.ONE * factor
    stage.position = (available - ART_SIZE * factor) * 0.5
