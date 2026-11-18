extends "res://learning/src/features/grocery/grocery_game.gd"
## Background only. Same Product Count image, no changes to product positions.
const MIKA_PRODUCT_COUNT_BG: Texture2D = preload("res://learning/assets/product_count/background.webp")
var _mika_product_backdrop: TextureRect

func _build_scene() -> void:
    super._build_scene()
    _mika_product_backdrop = TextureRect.new()
    _mika_product_backdrop.name = "MIKA_ProductCountBackground"
    _mika_product_backdrop.texture = MIKA_PRODUCT_COUNT_BG
    _mika_product_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _mika_product_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _mika_product_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background_layer.add_child(_mika_product_backdrop)
    background_layer.move_child(_mika_product_backdrop, 0)
    wall.visible = false
    floor.visible = false
    _mika_product_backdrop.position = Vector2.ZERO
    _mika_product_backdrop.size = get_viewport_rect().size

func _layout_for_viewport() -> void:
    super._layout_for_viewport()
    if is_instance_valid(_mika_product_backdrop):
        _mika_product_backdrop.position = Vector2.ZERO
        _mika_product_backdrop.size = get_viewport_rect().size
