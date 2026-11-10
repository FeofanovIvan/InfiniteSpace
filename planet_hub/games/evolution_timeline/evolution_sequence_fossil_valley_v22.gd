extends "res://planet_hub/games/evolution_timeline/evolution_sequence_desert_voice_v21.gd"
## MIKA Evolution v2.2 — approved Dinosaur Planet Fossil Valley user artwork.
## Only the background texture and rounded crop mask are changed. All evolution
## rules, draggable animals, card sizes, per-game score, TTS and chimes are inherited.

const FOSSIL_VALLEY_PNG: String = "res://planet_hub/games/evolution_timeline/assets/dinosaur_planet_fossil_valley_v22.png"
const ROUND_MASK: Shader = preload("res://planet_hub/games/evolution_timeline/shaders/evolution_rounded_background_v22.gdshader")
const STAGE_FRAME_WIDTH: float = 3.0
const STAGE_CORNER_RADIUS: float = 28.0

var _fossil_valley_mask: ShaderMaterial

func _build_interface() -> void:
    super._build_interface()
    if _desert_background == null:
        push_error("Evolution v2.2: stage background from v2.1 was not created")
        return
    var source: Texture2D = load(FOSSIL_VALLEY_PNG) as Texture2D
    if source == null:
        push_error("Evolution v2.2: missing approved background: " + FOSSIL_VALLEY_PNG)
        return
    _desert_background.name = "FossilValleyRoundedOnlyInsideEvolutionStage"
    _desert_background.texture = source
    _desert_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _desert_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _desert_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _desert_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    # Clip in local PIXEL coordinates: rounded corners stay 25px inside the
    # stage's 28px radius / 3px border at any supported landscape aspect ratio.
    _fossil_valley_mask = ShaderMaterial.new()
    _fossil_valley_mask.shader = ROUND_MASK
    _desert_background.material = _fossil_valley_mask
    _update_fossil_valley_crop()

func _layout() -> void:
    super._layout()
    _update_fossil_valley_crop()

func _update_fossil_valley_crop() -> void:
    if _desert_background == null or _stage == null:
        return
    var inner_rect_size: Vector2 = Vector2(
        maxf(1.0, _stage.size.x - 2.0 * STAGE_FRAME_WIDTH),
        maxf(1.0, _stage.size.y - 2.0 * STAGE_FRAME_WIDTH)
    )
    _desert_background.position = Vector2.ONE * STAGE_FRAME_WIDTH
    _desert_background.size = inner_rect_size
    if _fossil_valley_mask != null:
        _fossil_valley_mask.set_shader_parameter("panel_size", inner_rect_size)
        _fossil_valley_mask.set_shader_parameter("corner_radius", STAGE_CORNER_RADIUS - STAGE_FRAME_WIDTH)
