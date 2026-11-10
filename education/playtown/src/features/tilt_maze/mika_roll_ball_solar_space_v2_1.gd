extends "res://education/playtown/src/features/tilt_maze/mika_roll_ball_magnetic_universe_v2.gd"
## Roll the Ball v2.1 — visual-only solar space, based on the approved magnetic v2.
## No overrides for physics, touch, sensors, maze generation, scores or navigation.

const CLEAR_SPACE_BOARD: Script = preload("res://education/playtown/src/features/tilt_maze/mika_magnetic_maze_clear_space_v2_1.gd")
const SPACE_SKY: Script = preload("res://education/playtown/src/features/tilt_maze/mika_roll_cosmic_sky_v2_1.gd")
const REAL_SUN: Script = preload("res://education/playtown/src/features/tilt_maze/mika_roll_real_sun_v2_1.gd")

var _mika_space_sky: Control
var _mika_real_sun: Control


func _build_ui() -> void:
    super._build_ui()
    # Keep the full approved magnet-rail art and collision script inheritance.
    var previous_board: Node2D = board
    var previous_index: int = previous_board.get_index()
    var open_board: Node2D = CLEAR_SPACE_BOARD.new() as Node2D
    open_board.name = "MagneticRailsWithoutOpaqueFloor"
    add_child(open_board)
    move_child(open_board, previous_index)
    previous_board.hide()
    previous_board.queue_free()
    board = open_board

    # The existing backdrop is the bottommost colour, not a panel floor.
    background.color = Color("#020511")
    _mika_space_sky = SPACE_SKY.new() as Control
    _mika_space_sky.name = "GenuineFlightStarsAndOuterNebulae"
    _mika_space_sky.z_index = -9
    _mika_space_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_mika_space_sky)

    _mika_real_sun = REAL_SUN.new() as Control
    _mika_real_sun.name = "TrueSolarSunBehindMagneticLabyrinth"
    _mika_real_sun.z_index = -2
    _mika_real_sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_mika_real_sun)

    # Keep the original rounded neon frame, but remove the opaque stage fill.
    var skin: StyleBoxFlat = _mika_stage.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
    skin.bg_color = Color(0.0, 0.0, 0.0, 0.0)
    _mika_stage.add_theme_stylebox_override("panel", skin)


func _mika_layout_for_size(view: Vector2) -> void:
    super._mika_layout_for_size(view)
    if _mika_space_sky == null or _mika_real_sun == null:
        return
    _mika_space_sky.call("configure", view, board_rect)
    # The Sun fits entirely into the cleared goal. Its corona extends beyond
    # the core, without hiding any ring passage or interfering with the ball.
    var corona_size: float = maxf(1.0, board_rect.size.x * 0.215)
    _mika_real_sun.size = Vector2.ONE * corona_size
    _mika_real_sun.position = board_rect.get_center() - Vector2.ONE * corona_size * 0.5
