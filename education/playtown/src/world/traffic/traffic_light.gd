extends Sprite2D
@export var red_texture: Texture2D
@export var green_texture: Texture2D
func _ready() -> void:
	scale = Vector2(0.15, 0.15)
	texture = red_texture
func set_pedestrian_go(go: bool) -> void:
	texture = green_texture if go else red_texture
