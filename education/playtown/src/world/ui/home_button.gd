extends TextureButton
@export var select_scene_path: String = "res://education/playtown/scenes/screens/character_select.tscn"
func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	SFX.transition_from_world(select_scene_path)
