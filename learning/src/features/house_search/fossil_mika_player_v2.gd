extends "res://learning/src/features/house_search/house_search_player.gd"
## Only Fossil Hunt instantiates this subclass; the original player is untouched.
var fossil_mirror_left := false

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    _set_side_mirror()

func face(direction: Vector2) -> void:
    super.face(direction)
    _set_side_mirror()

func play_walk(direction: Vector2) -> void:
    super.play_walk(direction)
    _set_side_mirror()

func _set_side_mirror() -> void:
    if animated_sprite != null:
        animated_sprite.flip_h = fossil_mirror_left and animated_sprite.animation == &"walk_left"
