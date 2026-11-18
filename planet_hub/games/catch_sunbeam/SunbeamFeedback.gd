extends Node
## Catch Sunbeam: multilingual feedback, triggered by player actions only.
## No timers or pending voice queues: feedback cannot arrive after its event.

const SUPPORTED_LANGUAGES: Array[String] = ["ru", "en", "pt", "es", "fr", "de"]
const COOLDOWN_MS: int = 8000
const FIRST_VOICE_DELAY_MS: int = 4500

var _voice: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()
var _started_ms: int = 0
var _last_spoken_ms: int = -1000000
var _last_praise: int = -1
var _last_retry: int = -1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    _started_ms = Time.get_ticks_msec()
    _voice = AudioStreamPlayer.new()
    _voice.name = "SunbeamLocalizedEncouragement"
    _voice.process_mode = Node.PROCESS_MODE_ALWAYS
    _voice.bus = "VOICE"
    _voice.volume_db = -3.5
    add_child(_voice)

func praise(locale: String) -> void:
    _play_feedback("praise", locale)

func encourage(locale: String) -> void:
    _play_feedback("retry", locale)

func stop_feedback() -> void:
    if _voice != null:
        _voice.stop()

func _play_feedback(kind: String, locale: String) -> void:
    if not is_inside_tree() or _voice == null or _voice.playing:
        return
    var now: int = Time.get_ticks_msec()
    if now - _started_ms < FIRST_VOICE_DELAY_MS or now - _last_spoken_ms < COOLDOWN_MS:
        return
    var lang: String = locale.to_lower().get_slice("_", 0)
    if not SUPPORTED_LANGUAGES.has(lang):
        lang = "en"
    var variants: int = 5 if kind == "praise" else 3
    var previous: int = _last_praise if kind == "praise" else _last_retry
    var chosen: int = _rng.randi_range(1, variants)
    if chosen == previous:
        chosen = chosen % variants + 1
    var path: String = "res://learning/audio/voice/%s/feedback/%s_%02d.mp3" % [lang, kind, chosen]
    if not ResourceLoader.exists(path):
        return
    var stream: AudioStream = load(path) as AudioStream
    if stream == null:
        return
    if kind == "praise":
        _last_praise = chosen
    else:
        _last_retry = chosen
    _voice.stream = stream
    _last_spoken_ms = Time.get_ticks_msec()
    _voice.play()
