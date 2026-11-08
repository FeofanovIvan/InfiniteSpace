extends "res://education/playtown/src/features/animal_habitat/animal_habitat_game.gd"
## Background only; individual animal habitats, drag/drop and original HUD intact.
const MIKA_EARTH_SCENE_BG: Texture2D = preload("res://planet_hub/backgrounds/mw_p01.png")

func _build_ui() -> void:
    super._build_ui()
    background.texture = MIKA_EARTH_SCENE_BG
