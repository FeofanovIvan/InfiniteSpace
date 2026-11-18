extends "res://learning/src/features/matching_pairs/matching_door.gd"
## MIKA Matching Pairs v3.1: aperture from 8 user-marked polygon vertices.
## Source: 1=(221,239); 2=(279,176); 3=(1030,180); 4=(1092,244); 5=(1092,1033); 6=(1038,1079); 7=(274,1080); 8=(222,1032)
## The aperture mask is a 600x606 alpha PNG generated from the points above;
## it is NOT a rectangular Control.clip_contents window.
## CanvasItem.CLIP_CHILDREN_ONLY clips both moving leaves to the same fixed
## octagonal alpha silhouette at every point of the 0.46-second animation.

const FRAME_ART: Texture2D = preload("res://learning/assets/matching_pairs/mika_door_frame_octagon_v3_1.png")
const LEFT_LEAF_ART: Texture2D = preload("res://learning/assets/matching_pairs/mika_door_left_leaf_octagon_v3_1.png")
const RIGHT_LEAF_ART: Texture2D = preload("res://learning/assets/matching_pairs/mika_door_right_leaf_octagon_v3_1.png")
const OCTAGON_ALPHA: Texture2D = preload("res://learning/assets/matching_pairs/mika_door_aperture_mask_octagon_v3_1.png")
const IMAGE_SIZE: Vector2 = Vector2(600.0, 606.0)
const LEAF_X_LEFT: float = 51.0
const LEAF_X_SEAM: float = 300.0
const LEAF_X_RIGHT: float = 550.0
const LEAF_Y_TOP: float = 61.0
const LEAF_Y_BOTTOM: float = 579.0
const SLIDE_SECONDS: float = 0.46

var _mask: TextureRect = null
var _left_leaf: TextureRect = null
var _right_leaf: TextureRect = null
var _frame: TextureRect = null
var _open_progress: float = 0.0
var _slide_tween: Tween = null


func _ready() -> void:
    super._ready()
    # TextureRect's own alpha defines the fixed octagonal stencil; its pixels
    # are only used for CLIPPING children and are not separately drawn.
    _mask = TextureRect.new()
    _mask.name = "ShuttleAperture_ExactUserEightPointAlphaMask"
    _mask.texture = OCTAGON_ALPHA
    _mask.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _mask.stretch_mode = TextureRect.STRETCH_SCALE
    _mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
    add_child(_mask)

    _left_leaf = _create_leaf("Shuttle_LeftLeaf", LEFT_LEAF_ART)
    _right_leaf = _create_leaf("Shuttle_RightLeaf", RIGHT_LEAF_ART)

    _frame = TextureRect.new()
    _frame.name = "Shuttle_StaticFrame_ExactEightCorners"
    _frame.texture = FRAME_ART
    _frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _frame.stretch_mode = TextureRect.STRETCH_SCALE
    _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_frame)
    _on_resized()


func _create_leaf(node_name: String, texture: Texture2D) -> TextureRect:
    var leaf: TextureRect = TextureRect.new()
    leaf.name = node_name
    leaf.texture = texture
    leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    leaf.stretch_mode = TextureRect.STRETCH_SCALE
    leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mask.add_child(leaf)
    return leaf


func _on_resized() -> void:
    super._on_resized()
    if _mask == null or _left_leaf == null or _right_leaf == null or _frame == null:
        return
    if size.x <= 0.0 or size.y <= 0.0:
        return
    var scale_to_door: Vector2 = size / IMAGE_SIZE
    _mask.position = Vector2.ZERO
    _mask.size = size
    _left_leaf.size = Vector2((LEAF_X_SEAM - LEAF_X_LEFT) * scale_to_door.x,
        (LEAF_Y_BOTTOM - LEAF_Y_TOP) * scale_to_door.y)
    _right_leaf.size = Vector2((LEAF_X_RIGHT - LEAF_X_SEAM) * scale_to_door.x,
        (LEAF_Y_BOTTOM - LEAF_Y_TOP) * scale_to_door.y)
    _frame.position = Vector2.ZERO
    _frame.size = size
    _apply_open_progress(_open_progress)


func _apply_open_progress(value: float) -> void:
    _open_progress = clampf(value, 0.0, 1.0)
    if _left_leaf == null or _right_leaf == null:
        return
    var scale_to_door: Vector2 = size / IMAGE_SIZE
    # Sideways slides disappear INSIDE the stationary octagonal stencil.
    var left_shift: float = _left_leaf.size.x * _open_progress
    var right_shift: float = _right_leaf.size.x * _open_progress
    _left_leaf.position = Vector2(LEAF_X_LEFT * scale_to_door.x - left_shift,
        LEAF_Y_TOP * scale_to_door.y)
    _right_leaf.position = Vector2(LEAF_X_SEAM * scale_to_door.x + right_shift,
        LEAF_Y_TOP * scale_to_door.y)


func set_revealed(value: bool, animated: bool = true) -> void:
    if revealed == value or matched:
        return
    if _slide_tween != null and _slide_tween.is_valid():
        _slide_tween.kill()
    revealed = value
    queue_redraw()
    var target: float = 1.0 if value else 0.0
    if not animated or not is_inside_tree():
        _apply_open_progress(target)
        return
    _slide_tween = create_tween()
    _slide_tween.tween_method(Callable(self, "_apply_open_progress"),
        _open_progress, target, SLIDE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    await _slide_tween.finished


func _draw() -> void:
    if size.x <= 0.0 or size.y <= 0.0:
        return
    # The white recess has identical eight-point alpha. NEVER use draw_rect().
    draw_texture_rect(OCTAGON_ALPHA, Rect2(Vector2.ZERO, size), false)
    if revealed:
        # MatchingDoor's existing shapes and colors remain unchanged.
        draw_set_transform(Vector2(-size.x * 0.07, 0.0))
        _draw_symbol()
        draw_set_transform(Vector2.ZERO)
