extends "res://education/playtown/src/features/counting/mika_count_pick_native_v1_2.gd"
## MIKA Pick Up a Number v1.3: real recordings first, system TTS fallback.
## Preserves v1.2 layout, score, mechanics and all original number artwork.

const NUMBER_TTS: Script = preload("res://education/playtown/src/features/counting/mika_count_number_tts_v1_3.gd")
var _mika_number_speech: RefCounted = NUMBER_TTS.new()

func _ready() -> void:
    super._ready()
    set_meta("mika_pick_number_version", "v1.3-native-tts-11-to-20")
    print("[MIKA PICK NUMBER v1.3] ACTIVE — MP3 first, native TTS 11..20; language: ", str(LanguageService.learning_locale))

func _play_number_voice(n: int) -> void:
    if n <= 10:
        super._play_number_voice(n)
        return
    if n > MIKA_MAX_PICK_NUMBER:
        return
    var locale: String = str(LanguageService.learning_locale)
    if locale == "pt_BR":
        locale = "pt"
    if locale not in ["ru", "en", "pt", "es", "fr", "de"]:
        return
    var path: String = "res://education/playtown/audio/voice/%s/numbers/number_%02d.mp3" % [locale, n]
    if ResourceLoader.exists(path):
        var stream: AudioStream = load(path) as AudioStream
        if stream != null and is_instance_valid(voice_player):
            _mika_number_speech.call("stop")
            voice_player.stop()
            voice_player.stream = stream
            voice_player.play()
            return
    # No MP3 yet: pronounce the HIDDEN localized text (60 entries in JSON).
    # Never call LanguageService.get_number_voice(11..20) — it clamps to 10.
    if is_instance_valid(voice_player):
        voice_player.stop()
    _mika_number_speech.call("speak_number", n, locale)

func _on_option_pressed(btn: Button, value: int) -> void:
    # Pronounce ANY selected answer. Correct selections are voiced by the
    # original success handler, so don't play them twice here.
    if not round_over and not btn.disabled and value != current_number:
        _play_number_voice(value)
    super._on_option_pressed(btn, value)

func _exit_tree() -> void:
    _mika_number_speech.call("stop")
    super._exit_tree()
