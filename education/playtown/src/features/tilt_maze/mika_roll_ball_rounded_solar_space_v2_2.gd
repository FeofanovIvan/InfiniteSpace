extends "res://education/playtown/src/features/tilt_maze/mika_roll_ball_solar_space_v2_1.gd"
## MIKA Roll the Ball v2.2 — background ONLY inside approved rounded stage.
## Reparent the exact EXISTING Sun, nebula and true flight starfield into a
## rounded alpha stencil. The maze, physics, sensor input and HUD are inherited.

const ROUNDED_SPACE_MASK: Script = preload("res://education/playtown/src/features/tilt_maze/mika_roll_rounded_space_mask_v2_2.gd")

var _mika_rounded_space: Control
var _mika_inner_void: ColorRect

func _build_ui() -> void:
    super._build_ui()
    # Outside the main stage there must be NO starfield / nebula / Sun.
    # This is the original neutral UI surround, not an opaque wash over space.
    background.color = Color("#061225")

    # The outer panel remains a cyan neon outline only, with 0% blue fill.
    var original_skin: StyleBoxFlat = _mika_stage.get_theme_stylebox("panel") as StyleBoxFlat
    if original_skin != null:
        var transparent_skin: StyleBoxFlat = original_skin.duplicate() as StyleBoxFlat
        transparent_skin.bg_color = Color(0.0, 0.0, 0.0, 0.0)
        _mika_stage.add_theme_stylebox_override("panel", transparent_skin)

    # Disable the panel's rectangular clipping: the child stencil replaces it
    # with genuinely rounded clipping, including on ultrawide mobile screens.
    _mika_stage.clip_contents = false
    _mika_rounded_space = ROUNDED_SPACE_MASK.new() as Control
    _mika_rounded_space.name = "RoundedStageOnly_SpaceBackdrop_Mask"
    _mika_rounded_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_stage.add_child(_mika_rounded_space)

    _mika_inner_void = ColorRect.new()
    _mika_inner_void.name = "UnobstructedOuterSpace_NoBlueFilm"
    _mika_inner_void.color = Color("#020511")
    _mika_inner_void.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_rounded_space.add_child(_mika_inner_void)

    # No copies, no image substitutions: reuse the actual v2.1 sky and Sun.
    # Reparent removes them from the full-screen root so nothing can escape
    # behind the title bar or outside the large central playfield.
    _mika_space_sky.reparent(_mika_rounded_space, false)
    _mika_space_sky.z_index = 0
    _mika_real_sun.reparent(_mika_rounded_space, false)
    _mika_real_sun.z_index = 1

func _mika_layout_for_size(view: Vector2) -> void:
    # First run all original layout/physics calculations unchanged.
    super._mika_layout_for_size(view)
    if _mika_rounded_space == null or _mika_inner_void == null:
        return

    var panel_size: Vector2 = _mika_stage.size
    var border_inset: float = 3.0
    _mika_rounded_space.position = Vector2.ONE * border_inset
    _mika_rounded_space.size = Vector2(
        maxf(1.0, panel_size.x - 2.0 * border_inset),
        maxf(1.0, panel_size.y - 2.0 * border_inset)
    )
    _mika_inner_void.position = Vector2.ZERO
    _mika_inner_void.size = _mika_rounded_space.size

    # The sky's uniforms and starfield now use LOCAL coordinates of the mask.
    var masked_origin: Vector2 = _mika_stage.position + _mika_rounded_space.position
    var maze_local: Rect2 = Rect2(board_rect.position - masked_origin, board_rect.size)
    _mika_space_sky.call("configure", _mika_rounded_space.size, maze_local)

    # Keep the actual sun exactly at the centre of the existing maze.
    var sun_size: float = maxf(1.0, board_rect.size.x * 0.215)
    _mika_real_sun.size = Vector2.ONE * sun_size
    _mika_real_sun.position = maze_local.get_center() - Vector2.ONE * sun_size * 0.5
