extends Node
## Local, pause-safe feedback for the living fungal route puzzle.
## Speech is loaded from the existing six-language feedback library; no voice copies.

const DOT: AudioStream = preload("res://learning/audio/sfx/connect_point.ogg")
const GROW: AudioStream = preload("res://planet_hub/games/fungal_paths/audio/mycelium_grow.wav")
const UNDO: AudioStream = preload("res://planet_hub/games/fungal_paths/audio/route_undo.wav")
const DEPART: AudioStream = preload("res://planet_hub/games/fungal_paths/audio/bubble_depart.wav")
const JUNCTION: AudioStream = preload("res://planet_hub/games/fungal_paths/audio/junction_glow.wav")
const LOST: AudioStream = preload("res://planet_hub/games/fungal_paths/audio/lost_wobble.wav")

const LANGUAGES: Array[String] = ["ru", "en", "pt", "es", "fr", "de"]
const DOT_PITCHES: Array[float] = [0.89, 1.00, 1.12, 1.25, 1.33, 1.12, 1.00]

var _tap: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _motion: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()
var _last_point_ms: int = -1000
var _last_junction_ms: int = -1000
var _voice_generation: int = 0
var _last_praise: int = -1
var _last_retry: int = -1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    _tap = _player("SFX")
    _ambient = _player("SFX")
    _motion = _player("SFX")
    _voice = _player("VOICE")
    _voice.volume_db = -3.5

func _player(bus_name: String) -> AudioStreamPlayer:
    var p := AudioStreamPlayer.new()
    p.process_mode = Node.PROCESS_MODE_ALWAYS
    p.bus = bus_name
    add_child(p)
    return p

func _effect(player: AudioStreamPlayer, stream: AudioStream, volume: float, pitch: float = 1.0) -> void:
    if player == null or stream == null:
        return
    player.stop()
    player.stream = stream
    player.volume_db = volume
    player.pitch_scale = pitch
    player.play()

func point_added(route_size: int) -> void:
    var now := Time.get_ticks_msec()
    if now - _last_point_ms < 95:
        return
    _last_point_ms = now
    var index: int = maxi(route_size - 3, 0)
    _effect(_tap, DOT, -11.0, DOT_PITCHES[index % DOT_PITCHES.size()])
    # Growth is a separate, soft accent every third confirmed junction.
    if index > 0 and index % 3 == 0:
        _effect(_ambient, GROW, -17.0, _rng.randf_range(0.94, 1.06))

func point_removed() -> void:
    _effect(_tap, UNDO, -11.5)

func round_restarted() -> void:
    _cancel_feedback()
    _tap.stop()
    _ambient.stop()
    _motion.stop()
    _effect(_tap, UNDO, -16.0, 0.82)

func route_started() -> void:
    _cancel_feedback()
    _effect(_motion, DEPART, -11.5)

func junction_reached(step_number: int) -> void:
    var now := Time.get_ticks_msec()
    if now - _last_junction_ms < 180:
        return
    _last_junction_ms = now
    _effect(_tap, JUNCTION, -17.0, DOT_PITCHES[step_number % DOT_PITCHES.size()])

func bubble_lost(locale: String) -> void:
    _tap.stop()
    _ambient.stop()
    _effect(_motion, LOST, -12.5)
    _schedule_feedback("retry", locale, 0.75)

func bubble_won(locale: String) -> void:
    _tap.stop()
    _ambient.stop()
    _motion.stop()
    # The existing, shorter victory cue stays owned by the main scene.
    _schedule_feedback("praise", locale, 1.05)

func _cancel_feedback() -> void:
    _voice_generation += 1
    if _voice != null:
        _voice.stop()

func _schedule_feedback(kind: String, locale: String, delay: float) -> void:
    _cancel_feedback()
    var request_id: int = _voice_generation
    _delayed_feedback(kind, locale, delay, request_id)

func _delayed_feedback(kind: String, locale: String, delay: float, request_id: int) -> void:
    await get_tree().create_timer(delay, true).timeout
    if not is_inside_tree() or request_id != _voice_generation:
        return
    var lang: String = locale.to_lower().get_slice("_", 0)
    if not LANGUAGES.has(lang):
        lang = "en"
    var count: int = 5 if kind == "praise" else 3
    var previous: int = _last_praise if kind == "praise" else _last_retry
    var index: int = _rng.randi_range(1, count)
    if count > 1 and index == previous:
        index = index % count + 1
    var path: String = "res://learning/audio/voice/%s/feedback/%s_%02d.mp3" % [lang, kind, index]
    if not ResourceLoader.exists(path):
        return
    var stream: AudioStream = load(path) as AudioStream
    if stream == null:
        return
    if kind == "praise":
        _last_praise = index
    else:
        _last_retry = index
    _voice.stop()
    _voice.stream = stream
    _voice.play()

func _exit_tree() -> void:
    _voice_generation += 1
