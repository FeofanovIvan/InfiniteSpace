extends TextureButton
@export var pet_home_scene_path: String = "res://education/playtown/scenes/features/pet/pet_home.tscn"
func _ready() -> void:
	_refresh_visibility()
	AccessService.preview_pet_access_changed.connect(_on_preview_pet_access_changed)
	pressed.connect(_on_pressed)
func _on_preview_pet_access_changed(_available: bool) -> void:
	_refresh_visibility()
func _refresh_visibility() -> void:
	visible = GameState.has_pet_access()
func _on_pressed() -> void:
	SFX.transition_from_world(pet_home_scene_path)
