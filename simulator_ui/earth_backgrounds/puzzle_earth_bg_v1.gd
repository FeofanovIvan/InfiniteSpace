extends "res://education/playtown/src/features/puzzle/puzzle_game.gd"
## Background only. Original SafeCityKids puzzle board, tray, score and Exit are intact.
const MIKA_EARTH_SCENE_BG: Texture2D = preload("res://planet_hub/backgrounds/mw_p01.png")
var _mika_earth_backdrop: TextureRect

func _build_ui() -> void:
    super._build_ui()
    _mika_earth_backdrop = TextureRect.new()
    _mika_earth_backdrop.name = "MIKA_EarthHubBackground"
    _mika_earth_backdrop.texture = MIKA_EARTH_SCENE_BG
    _mika_earth_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _mika_earth_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _mika_earth_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_earth_backdrop.z_index = -8
    add_child(_mika_earth_backdrop)
    _mika_earth_backdrop.position = Vector2.ZERO
    _mika_earth_backdrop.size = get_viewport_rect().size

func _layout() -> void:
    super._layout()
    if is_instance_valid(_mika_earth_backdrop):
        _mika_earth_backdrop.position = Vector2.ZERO
        _mika_earth_backdrop.size = get_viewport_rect().size
