extends "res://planet_hub/games/evolution_timeline/evolution_sequence_v2.gd"
## MIKA Evolution v2.1: the uninhabited planet Duna's existing landscape
## behind the 5×5 sequence; MikaVoice and gentle non-verbal success/error sounds.
## All evolution data, scoring, cards, sizes and transitions come from v2 unchanged.

const DUNA_BACKGROUND: String = "res://planet_hub/backgrounds/shared_uninhabited/11.png"
const SUCCESS_SOUND: String = "res://planet_hub/games/evolution_timeline/audio/evolution_right_v21.wav"
const ERROR_SOUND: String = "res://planet_hub/games/evolution_timeline/audio/evolution_wrong_v21.wav"

var _desert_background: TextureRect
var _success_audio: AudioStreamPlayer
var _error_audio: AudioStreamPlayer
var _last_wrong_voice_ms: int = -100000

func _ready() -> void:
    super._ready()
    # Defer system TTS until the scene, navigation and autoloads are ready.
    call_deferred("_speak_instruction")

func _build_interface() -> void:
    super._build_interface()
    # The background belongs ONLY to the large stage below the shared toolbar.
    # The 3px frame remains; the previous opaque navy paint is transparent.
    var old_style: StyleBoxFlat = _stage.get_theme_stylebox("panel") as StyleBoxFlat
    if old_style != null:
        var clear_style: StyleBoxFlat = old_style.duplicate() as StyleBoxFlat
        clear_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
        _stage.add_theme_stylebox_override("panel", clear_style)
    _desert_background = TextureRect.new()
    _desert_background.name = "DunaDesertOnlyInsideMainStage"
    _desert_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _desert_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _desert_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _desert_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    if ResourceLoader.exists(DUNA_BACKGROUND, "Texture2D"):
        _desert_background.texture = load(DUNA_BACKGROUND) as Texture2D
    else:
        push_warning("Evolution: Duna stage background is missing: " + DUNA_BACKGROUND)
    _stage.add_child(_desert_background)
    _stage.move_child(_desert_background, 0)
    # AudioStreamPlayers never capture input or modify the game rules.
    _success_audio = AudioStreamPlayer.new()
    _success_audio.name = "EvolutionCorrectChime"
    _success_audio.volume_db = -10.0
    if ResourceLoader.exists(SUCCESS_SOUND):
        _success_audio.stream = load(SUCCESS_SOUND) as AudioStream
    add_child(_success_audio)
    _error_audio = AudioStreamPlayer.new()
    _error_audio.name = "EvolutionIncorrectHint"
    _error_audio.volume_db = -15.0
    if ResourceLoader.exists(ERROR_SOUND):
        _error_audio.stream = load(ERROR_SOUND) as AudioStream
    add_child(_error_audio)

func _layout() -> void:
    super._layout()
    if _desert_background != null and _stage != null:
        # Keep the image behind the border, never over the shared title bar.
        _desert_background.position = Vector2(3.0, 3.0)
        _desert_background.size = Vector2(maxf(1.0, _stage.size.x - 6.0),
                maxf(1.0, _stage.size.y - 6.0))

func _on_language_changed(new_language: String) -> void:
    super._on_language_changed(new_language)
    call_deferred("_speak_instruction")

func _speak_instruction() -> void:
    _speak_evolution_text("instruction")

func _speak_evolution_text(key: String) -> void:
    if _smoke_mode or not is_inside_tree():
        return
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null and voice.has_method("speak_text"):
        voice.call("speak_text", _word(key), _language, "tablet", "evolution_timeline")

func _award() -> void:
    super._award()
    if not _smoke_mode:
        if _success_audio != null and _success_audio.stream != null:
            _success_audio.play()
        _speak_evolution_text("correct")

func _choose(choice: int) -> void:
    var was_valid: bool = not _completed and choice >= 0 and choice < _choices.size()
    var wrong: bool = was_valid and choice != _answer_choice
    super._choose(choice)
    if wrong and not _smoke_mode:
        if _error_audio != null and _error_audio.stream != null:
            _error_audio.play()
        var now: int = Time.get_ticks_msec()
        if now - _last_wrong_voice_ms > 2600:
            _last_wrong_voice_ms = now
            _speak_evolution_text("wrong")
