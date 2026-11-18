extends Node
## Shared, action-synchronous praise/encouragement for planetary mini-games.
## Never schedule a timer, never queue voice, and never respond to idle time.

const LANGUAGES: Array[String] = ["ru", "en", "pt", "es", "fr", "de"]
const VOICE_ROOT: String = "res://learning/audio/voice/"
const MIN_GAP_MS: int = 8000
const INTRO_GRACE_MS: int = 3500

var _player: AudioStreamPlayer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _cache: Dictionary = {}
var _started_ms: int = 0
var _last_voice_ms: int = -1000000
var _last_praise: int = -1
var _last_retry: int = -1


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    _started_ms = Time.get_ticks_msec()
    _player = AudioStreamPlayer.new()
    _player.name = "PlanetaryActionFeedback"
    _player.process_mode = Node.PROCESS_MODE_ALWAYS
    _player.bus = _choose_bus()
    _player.volume_db = -5.0
    add_child(_player)


func _choose_bus() -> String:
    for name: String in ["VOICE", "Voice", "SFX"]:
        if AudioServer.get_bus_index(name) >= 0:
            return name
    return "Master"


func prime_locale(locale: String) -> void:
    # Decode short MP3 clips before the first player interaction, not on a tap.
    var lang: String = _normalize(locale)
    for kind: String in ["praise", "retry"]:
        var count: int = 5 if kind == "praise" else 3
        for index in range(1, count + 1):
            var path: String = _path(lang, kind, index)
            if _cache.has(path):
                continue
            if ResourceLoader.exists(path):
                var clip: AudioStream = load(path) as AudioStream
                if clip != null:
                    _cache[path] = clip


func praise(locale: String) -> bool:
    return _play_now("praise", locale)


func encourage(locale: String) -> bool:
    return _play_now("retry", locale)


func stop_feedback() -> void:
    if _player != null:
        _player.stop()


func is_playing() -> bool:
    return _player != null and _player.playing


func _normalize(locale: String) -> String:
    var lang: String = locale.to_lower().get_slice("_", 0).get_slice("-", 0)
    return lang if LANGUAGES.has(lang) else "en"


func _path(lang: String, kind: String, index: int) -> String:
    return "%s%s/feedback/%s_%02d.mp3" % [VOICE_ROOT, lang, kind, index]


func _instruction_is_speaking() -> bool:
    var mika: Node = get_node_or_null("/root/MikaVoice")
    if mika != null:
        if not bool(mika.get("enabled")):
            return true  # Respect the game's spoken-voice mute preference.
        if mika.has_method("is_reading") and bool(mika.call("is_reading")):
            return true
    if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return DisplayServer.tts_is_speaking()
    return false


func _play_now(kind: String, locale: String) -> bool:
    if not is_inside_tree() or _player == null or _player.playing:
        return false
    var now_ms: int = Time.get_ticks_msec()
    if now_ms - _started_ms < INTRO_GRACE_MS or now_ms - _last_voice_ms < MIN_GAP_MS:
        return false
    if _instruction_is_speaking():
        return false
    var lang: String = _normalize(locale)
    var count: int = 5 if kind == "praise" else 3
    var last_index: int = _last_praise if kind == "praise" else _last_retry
    var chosen: int = _rng.randi_range(1, count)
    if chosen == last_index:
        chosen = chosen % count + 1
    var path: String = _path(lang, kind, chosen)
    if not _cache.has(path):
        prime_locale(lang)
    var clip: AudioStream = _cache.get(path) as AudioStream
    if clip == null:
        return false
    _player.stream = clip
    _player.play()
    _last_voice_ms = now_ms
    if kind == "praise":
        _last_praise = chosen
    else:
        _last_retry = chosen
    return true
