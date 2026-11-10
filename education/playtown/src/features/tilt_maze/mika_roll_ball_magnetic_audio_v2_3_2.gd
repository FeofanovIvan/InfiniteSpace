extends "res://education/playtown/src/features/tilt_maze/mika_roll_ball_rounded_solar_space_v2_2.gd"
## MIKA Roll the Ball v2.3.2 — original physics, robust event-driven magnetic SFX.
## VISUALS, physics, wall geometry, mobile sensors, scoring and UI are inherited.
## No per-frame looping audio and no additional ambient soundtrack.

const MAGNETIC_HELLO: AudioStream = preload("res://education/playtown/audio/sfx/roll_ball_magnetic_v2_3/magnetic_hello.wav")
const MAGNETIC_WALL_SOFT: AudioStream = preload("res://education/playtown/audio/sfx/roll_ball_magnetic_v2_3/magnetic_wall_soft.wav")
const MAGNETIC_WALL_BRIGHT: AudioStream = preload("res://education/playtown/audio/sfx/roll_ball_magnetic_v2_3/magnetic_wall_bright.wav")
const MAGNETIC_APPROACH: AudioStream = preload("res://education/playtown/audio/sfx/roll_ball_magnetic_v2_3/magnetic_approach.wav")
const MAGNETIC_CENTER: Vector2 = Vector2(500.0, 500.0)
const MAGNETIC_APPROACH_RADII: Array[float] = [355.0, 265.0, 165.0]

var _mika_audio_ready: bool = false
var _mika_entry_player: AudioStreamPlayer
var _mika_impact_player: AudioStreamPlayer
var _mika_approach_player: AudioStreamPlayer
var _mika_silent_time: float = 1.0
var _mika_approach_flags: Array[bool] = [false, false, false]
var _mika_contacts_heard: int = 0
var _mika_welcome_attempts: int = 0
var _mika_approaches_heard: int = 0
var _mika_audio_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _build_ui() -> void:
    super._build_ui()
    # All sound emitters are siblings of the game's existing SFX player.
    _mika_entry_player = _mika_new_player("MagneticGameWelcome", MAGNETIC_HELLO, -16.0)
    _mika_impact_player = _mika_new_player("MagneticWallTap", MAGNETIC_WALL_SOFT, -18.0)
    _mika_approach_player = _mika_new_player("MagneticCoreApproach", MAGNETIC_APPROACH, -17.0)
    _mika_audio_rng.seed = 13772
    _mika_audio_ready = true


func _mika_new_player(label: String, sound: AudioStream, volume: float) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.name = label
    # AudioServer can expose Master alone in some imported/mobile projects.
    # A non-existent SFX bus must never prevent a real sound from playing.
    player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
    player.stream = sound
    player.volume_db = volume
    add_child(player)
    return player


func _reset_game() -> void:
    super._reset_game()
    _mika_approach_flags = [false, false, false]
    _mika_silent_time = 1.0
    if _mika_audio_ready and _mika_entry_player != null:
        _mika_welcome_attempts += 1
        _mika_entry_player.play() # Once per attempt, never every frame.


func _move_ball(delta: float) -> void:
    # Preserve original physics precisely by letting the parent's _move_ball()
    # run first. That routine splits displacement into several substeps and
    # may bounce against the SAME wall multiple times within a single call.
    # Consequently the velocity can reverse an even number of times; a test
    # based on sign change alone misses legitimate impacts. Energy loss is a
    # reliable observable: the parent only changes velocity inside _move_ball()
    # by multiplying a colliding component by -BOUNCE (= -0.24).
    # Detect that loss without modifying wall geometry, collision response,
    # ball coordinates, mobile input or gameplay.
    var before_speed: Vector2 = ball_velocity
    var before_radius: float = ball_position.distance_to(MAGNETIC_CENTER)
    super._move_ball(delta)
    _mika_silent_time += maxf(0.0, delta)
    if not _mika_audio_ready:
        return
    var impact_x: bool = absf(before_speed.x) >= 40.0 and absf(ball_velocity.x) < absf(before_speed.x) * 0.60
    var impact_y: bool = absf(before_speed.y) >= 40.0 and absf(ball_velocity.y) < absf(before_speed.y) * 0.60
    if (impact_x or impact_y) and _mika_silent_time >= 0.105:
        var impact_speed: float = maxf(absf(before_speed.x) if impact_x else 0.0,
                absf(before_speed.y) if impact_y else 0.0)
        _mika_play_impact(impact_speed)
    var current_radius: float = ball_position.distance_to(MAGNETIC_CENTER)
    for i in range(MAGNETIC_APPROACH_RADII.size()):
        if not _mika_approach_flags[i] and before_radius > MAGNETIC_APPROACH_RADII[i] and current_radius <= MAGNETIC_APPROACH_RADII[i]:
            _mika_approach_flags[i] = true
            _mika_approaches_heard += 1
            _mika_approach_player.pitch_scale = 0.92 + 0.12 * float(i)
            _mika_approach_player.play()
            break


func _mika_play_impact(speed: float) -> void:
    _mika_silent_time = 0.0
    var intensity: float = clampf((speed - 40.0) / 620.0, 0.0, 1.0)
    _mika_impact_player.stream = MAGNETIC_WALL_BRIGHT if speed > 295.0 else MAGNETIC_WALL_SOFT
    _mika_impact_player.volume_db = lerpf(-23.0, -12.5, intensity)
    _mika_impact_player.pitch_scale = _mika_audio_rng.randf_range(0.93, 1.09)
    _mika_contacts_heard += 1
    _mika_impact_player.play()
