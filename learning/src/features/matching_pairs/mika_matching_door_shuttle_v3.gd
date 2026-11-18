extends "res://learning/src/features/matching_pairs/matching_door.gd"
## MIKA Matching Pairs v3: true two-leaf shuttle-door opening.
## The fixed frame is a separate transparent image. Only the interior is clipped.
## Touch selection, symbol comparison, matched animation and sound logic remain
## inherited from MatchingDoor / matching_pairs_game.gd.

const FRAME_ART: Texture2D = preload("res://learning/assets/matching_pairs/mika_door_frame_v3.png")
const LEFT_LEAF_ART: Texture2D = preload("res://learning/assets/matching_pairs/mika_door_left_leaf_v3.png")
const RIGHT_LEAF_ART: Texture2D = preload("res://learning/assets/matching_pairs/mika_door_right_leaf_v3.png")

# Native image canvas: 600 x 606; inner aperture: x=49..533, y=61..563.
# Both shutters are 242 x 502 so they meet exactly at the original seam.
const IMAGE_SIZE: Vector2 = Vector2(600.0, 606.0)
const APERTURE: Rect2 = Rect2(49.0, 61.0, 484.0, 502.0)
const LEAF_HALF: float = 242.0
const SLIDE_SECONDS: float = 0.46

var _aperture_clip: Control = null
var _left_leaf: TextureRect = null
var _right_leaf: TextureRect = null
var _fixed_frame: TextureRect = null
var _open_progress: float = 0.0
var _slide_tween: Tween = null


func _ready() -> void:
    super._ready()
    _aperture_clip = Control.new()
    _aperture_clip.name = "ShuttleDoor_Aperture_ClipsMovingLeaves"
    _aperture_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _aperture_clip.clip_contents = true
    add_child(_aperture_clip)

    _left_leaf = _make_leaf("ShuttleDoor_LeftLeaf", LEFT_LEAF_ART)
    _right_leaf = _make_leaf("ShuttleDoor_RightLeaf", RIGHT_LEAF_ART)

    # Overlay contains ONLY the stationary jambs and frame, not the leaves.
    # Its middle is transparent, so the opening stays unobstructed.
    _fixed_frame = TextureRect.new()
    _fixed_frame.name = "ShuttleDoor_StationaryFrame"
    _fixed_frame.texture = FRAME_ART
    _fixed_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _fixed_frame.stretch_mode = TextureRect.STRETCH_SCALE
    _fixed_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_fixed_frame)
    _on_resized()


func _make_leaf(node_name: String, art: Texture2D) -> TextureRect:
    var leaf := TextureRect.new()
    leaf.name = node_name
    leaf.texture = art
    leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    leaf.stretch_mode = TextureRect.STRETCH_SCALE
    leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _aperture_clip.add_child(leaf)
    return leaf


func _on_resized() -> void:
    super._on_resized()
    if _aperture_clip == null or _left_leaf == null or _right_leaf == null:
        return
    if size.x <= 0.0 or size.y <= 0.0:
        return
    var scale_to_door: Vector2 = size / IMAGE_SIZE
    _aperture_clip.position = APERTURE.position * scale_to_door
    _aperture_clip.size = APERTURE.size * scale_to_door
    var left_w: float = LEAF_HALF * scale_to_door.x
    var right_w: float = (APERTURE.size.x - LEAF_HALF) * scale_to_door.x
    _left_leaf.size = Vector2(left_w, _aperture_clip.size.y)
    _right_leaf.size = Vector2(right_w, _aperture_clip.size.y)
    _fixed_frame.position = Vector2.ZERO
    _fixed_frame.size = size
    _apply_open_progress(_open_progress)


func _apply_open_progress(value: float) -> void:
    _open_progress = clampf(value, 0.0, 1.0)
    if _left_leaf == null or _right_leaf == null:
        return
    # The moving leaf images are ALWAYS children of the clipping aperture.
    # At t=1 they have completely disappeared behind its left/right edges.
    var left_w: float = _left_leaf.size.x
    var right_w: float = _right_leaf.size.x
    _left_leaf.position = Vector2(-left_w * _open_progress, 0.0)
    _right_leaf.position = Vector2(left_w + right_w * _open_progress, 0.0)


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
    var scale_to_door: Vector2 = size / IMAGE_SIZE
    # Pure-white inner recess is ALWAYS behind the two movable shutters.
    # The matching symbol is drawn on the white interior, not on the shutters.
    draw_rect(Rect2(APERTURE.position * scale_to_door,
        APERTURE.size * scale_to_door), Color.WHITE, true)
    if revealed:
        # Base matching symbol is at 57% width; translate it to true centre.
        draw_set_transform(Vector2(-size.x * 0.07, 0.0))
        _draw_symbol()
        draw_set_transform(Vector2.ZERO)
