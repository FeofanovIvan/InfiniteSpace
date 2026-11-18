extends "res://learning/src/features/tilt_maze/mika_roll_ball_sensors_v1_1.gd"
## MIKA Roll the Ball v2 — CHILD-FRIENDLY MAGNETIC UNIVERSE.
## Only visual nodes are replaced. Original physics, tilt input, scoring and
## the already approved responsive MIKA top toolbar are inherited unmodified.

const MAGNETIC_BOARD: Script = preload("res://learning/src/features/tilt_maze/mika_magnetic_maze_board_v2.gd")
const MAGNETIC_BALL: Script = preload("res://learning/src/features/tilt_maze/mika_magnetic_planet_ball_v2.gd")
var _mika_magnetic_planet: Node2D


func _build_ui() -> void:
    super._build_ui()
    # A drop-in visual board subclass of the *exact same physical maze*.
    var old_board: Node2D = board
    var slot: int = old_board.get_index()
    var replacement: Node2D = MAGNETIC_BOARD.new() as Node2D
    replacement.name = "MagneticUniverseRingMaze"
    add_child(replacement)
    move_child(replacement, slot)
    old_board.hide()
    old_board.queue_free()
    board = replacement

    # Hide only the OLD red ball polygons; the Node2D with its physics position
    # and scaling remains the same original ball_root.
    for old_visual in [shadow_shape, ball_shape, highlight_shape]:
        if old_visual != null:
            old_visual.hide()
    _mika_magnetic_planet = MAGNETIC_BALL.new() as Node2D
    _mika_magnetic_planet.name = "FriendlyLiquidMagneticMiniPlanet"
    ball_root.add_child(_mika_magnetic_planet)
    # No other node/layout/physics code changes. No background asset yet.


func _update_ball_visual() -> void:
    # Original ball_position, board_rect and ball_root positioning are UNCHANGED.
    super._update_ball_visual()
    # The stylized planet has a slightly enlarged drawable silhouette while
    # collisions still use the original unchanged ball_radius parameter.
    if ball_root != null and board_rect.size.x > 0.0:
        ball_root.scale = Vector2.ONE * (board_rect.size.x * 0.025)
