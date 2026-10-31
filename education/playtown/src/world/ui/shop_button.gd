extends TextureButton
@export var shop_scene_path: String = "res://education/playtown/scenes/features/pet/pet_shop.tscn"
const NAV_PANEL_PATH := "/root/Main/CanvasLayer/TopUI/NavPanel"
func _ready() -> void:
	pressed.connect(_on_pressed)
func _on_pressed() -> void:
	var nav_panel := get_node_or_null(NAV_PANEL_PATH)
	if nav_panel and nav_panel.has_method("set_active_target"):
		nav_panel.set_active_target("Магазин")
	SFX.transition_from_world(shop_scene_path)
