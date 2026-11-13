extends Node2D
class_name MikaBubbleBrain
## Unified Bubble API: procedural body + layered FaceRig + interactive dental care.
## Every action is displayed through one current visual; previous visual fades out.
## Animation transitions and position changes are centralized here.

signal action_started(action_id: String)
signal action_finished(action_id: String)
signal face_expression_changed(expression_id: String)
signal brush_progress_changed(ratio: float)
signal brush_ready()

const IDLE_SCENE: PackedScene = preload("res://bubble/scenes/bubble_idle.tscn")
const MOVE_SCENE: PackedScene = preload("res://bubble/scenes/bubble_movement.tscn")
const TURN_SCENE: PackedScene = preload("res://bubble/scenes/bubble_turn.tscn")
const GESTURE_SCENE: PackedScene = preload("res://bubble/scenes/bubble_gesture.tscn")
const PLASTIC_SCENE: PackedScene = preload("res://bubble/scenes/bubble_plastic.tscn")
const CARE_SCENE: PackedScene = preload("res://bubble/scenes/bubble_care.tscn")
const FACE_SCENE: PackedScene = preload("res://bubble/scenes/bubble_face.tscn")
const BRUSH_COMPLETE_THRESHOLD: float = 0.92

const ACTIONS: Array[String] = [
    "idle", "walk_forward", "walk_backward", "strafe_left", "strafe_right", "accelerate", "brake",
    "turn_45_left", "turn_45_right", "turn_90_left", "turn_90_right", "turn_180_left", "turn_180_right", "turn_move_left", "turn_move_right",
    "wave", "jump", "roll", "float", "spin", "look",
    "detach", "rejoin", "stretch", "contract", "gas", "sleep",
    "eat", "drink", "brush_teeth", "bath"
]

@export var auto_return_idle: bool = true
@export var external_motion_control: bool = false
# When true, caller moves Bubble directly while the gait still animates.
@export_range(0.5, 2.0, 0.05) var playback_rate: float = 1.0
@export_range(0.1, 0.9, 0.05) var blend_seconds: float = 0.30
@export_range(0.5, 1.75, 0.05) var expressiveness: float = 1.0
@export_range(0.5, 1.75, 0.05) var spring_responsiveness: float = 1.0

var current_action: String = "idle"
var current_group: String = "idle"
var elapsed: float = 0.0
var action_duration: float = -1.0
var finished: bool = false
var paused: bool = false
var _actor
var _outgoing: Node2D
var _blend_time: float = 0.0
var _action_start_pos: Vector2
var _action_end_pos: Vector2
var _step_after_finish: float = 0.0
var _face_rig: MikaBubbleFace = null
var _expression_override: String = ""
var _jaw_override: float = -1.0
var _brushing_ready: bool = false
var _brushing_completed: bool = false
var _brushing_finish_delay: float = 0.0
var _last_face_id: String = ""
# Room micro-reactions do not replace the character or interrupt locomotion.
var _room_emotion_id: String = ""
var _room_emotion_left: float = 0.0
var _room_emotion_clock: float = 0.0
var _room_emotion_cycle: int = 0
var _surface_heading: float = 0.0
var _room_sleeping: bool = false
var _render_quality_low: bool = false
var _perf_warmup: float = 2.5
var _perf_elapsed: float = 0.0
var _perf_frames: int = 0
var _slow_windows: int = 0
var _fast_windows: int = 0
# MIKA_BUBBLE_SEAMLESS_SLEEP_V8_4_7

# Action intent is a separate layer, not an asset per motion.
const FACE_BY_ACTION: Dictionary = {
    "idle": "calm", "walk_forward": "calm", "walk_backward": "calm",
    "strafe_left": "calm", "strafe_right": "calm",
    "accelerate": "calm", "brake": "calm",
    "turn_45_left": "calm", "turn_45_right": "calm",
    "turn_90_left": "calm", "turn_90_right": "calm",
    "turn_180_left": "calm", "turn_180_right": "calm",
    "turn_move_left": "calm", "turn_move_right": "calm",
    "wave": "happy", "jump": "excited", "roll": "playful",
    "float": "content", "spin": "excited", "look": "curious",
    "detach": "surprised", "rejoin": "happy", "stretch": "content",
    "contract": "uncomfortable", "gas": "strained", "sleep": "sleeping",
    "eat": "content", "drink": "calm", "brush_teeth": "calm", "bath": "content"
}

func _ready() -> void:
    play_action("idle")

func group_for(id: String) -> String:
    if id == "idle": return "idle"
    if id in ["walk_forward", "walk_backward", "strafe_left", "strafe_right", "accelerate", "brake"]: return "movement"
    if id.begins_with("turn_"): return "turn"
    if id in ["wave", "jump", "roll", "float", "spin", "look"]: return "gesture"
    if id in ["detach", "rejoin", "stretch", "contract", "gas", "sleep"]: return "plastic"
    return "care"

func _scene_for(group: String) -> PackedScene:
    match group:
        "movement", "idle": return MOVE_SCENE
        "turn": return TURN_SCENE
        "gesture": return GESTURE_SCENE
        "plastic": return PLASTIC_SCENE
        "care": return CARE_SCENE
    return MOVE_SCENE

func _attach_face() -> void:
    _face_rig = null
    var socket: Node2D = _actor.get_node_or_null("Body/Face") as Node2D
    if socket == null:
        push_warning("Bubble action renderer has no Body/Face socket")
        return
    # Keep the Face socket (and all body motion) but hide legacy, opaque eyes and mouth.
    for old_part in socket.get_children():
        if old_part is CanvasItem:
            (old_part as CanvasItem).visible = false
    var rig: MikaBubbleFace = FACE_SCENE.instantiate() as MikaBubbleFace
    rig.name = "ProceduralFaceRig"
    rig.show_preview_body = false
    rig.automatic_blink = true
    rig.scale = Vector2.ONE * 0.79
    socket.add_child(rig)
    _face_rig = rig
    _last_face_id = ""
    _face_rig.brushing_progress_changed.connect(_on_brush_progress)
    _face_rig.set_surface_heading(_surface_heading)

func _on_brush_progress(progress_ratio: float) -> void:
    brush_progress_changed.emit(progress_ratio)

func get_current_expression() -> String:
    if is_instance_valid(_face_rig):
        return _face_rig.current_expression
    return "calm"

func get_face() -> MikaBubbleFace:
    return _face_rig if is_instance_valid(_face_rig) else null

func set_expression(id: String) -> void:
    # Manual facial expression overrides the default for ordinary motions.
    if not is_instance_valid(_face_rig) or not _face_rig.presets.has(id):
        push_warning("Unknown facial expression: " + id)
        return
    _expression_override = id
    _apply_expression(id)

func clear_expression_override() -> void:
    _expression_override = ""
    _update_face(get_progress(), 1.0)

func set_mouth_open(amount: float) -> void:
    # Negative resets automatic mouth choreography.
    _jaw_override = clampf(amount, 0.0, 1.0) if amount >= 0.0 else -1.0

func is_brushing_ready() -> bool:
    return current_action == "brush_teeth" and _brushing_ready and not _brushing_completed

func get_brushing_progress() -> float:
    return _face_rig.get_brushing_progress() if is_instance_valid(_face_rig) else 0.0

func brush_teeth_at(point: Vector2, radius: float = 14.0) -> float:
    if not is_brushing_ready() or not is_instance_valid(_face_rig):
        return get_brushing_progress()
    var result: float = _face_rig.brush_at(point, radius)
    if result >= BRUSH_COMPLETE_THRESHOLD and not _brushing_completed:
        _brushing_completed = true
        _brushing_ready = false
        _brushing_finish_delay = 0.0
    return result

func _apply_expression(id: String) -> void:
    if not is_instance_valid(_face_rig) or _last_face_id == id:
        return
    _face_rig.set_expression(id)
    _last_face_id = id
    face_expression_changed.emit(id)

func _update_face(p: float, delta: float) -> void:
    if not is_instance_valid(_face_rig):
        return
    var expression_id: String = str(FACE_BY_ACTION.get(current_action, "calm"))
    var opening: float = 0.0
    var eye_target: Vector2 = Vector2.ZERO
    var phase: float = clampf(p, 0.0, 1.0)
    match current_action:
        "gas":
            # Tight cheeks + tense eyes -> startled -> embarrassed -> relieved.
            if phase < 0.37:
                expression_id = "strained"
            elif phase < 0.57:
                expression_id = "surprised"
                opening = 0.32
            elif phase < 0.78:
                expression_id = "embarrassed"
                eye_target = Vector2(-0.9, 0.35)
            else:
                expression_id = "relieved"
        "eat":
            eye_target = Vector2(0.6, 0.7)
            if phase > 0.2 and phase < 0.83:
                opening = 0.28 + 0.19 * (0.5 + 0.5 * sin(elapsed * TAU * 1.4))
            if phase >= 0.83:
                expression_id = "happy"
        "drink":
            eye_target = Vector2(0.5, 0.7)
            if phase > 0.18 and phase < 0.85:
                opening = 0.12 + 0.10 * (0.5 + 0.5 * sin(elapsed * TAU * 2.4))
            if phase >= 0.85:
                expression_id = "content"
        "brush_teeth":
            if _brushing_completed:
                expression_id = "happy"
                opening = 0.0
            else:
                expression_id = "calm"
                opening = clampf(elapsed / 1.2, 0.0, 1.0)
        "bath":
            expression_id = "content"
            eye_target = Vector2(0.0, -0.2)
        "look":
            eye_target = Vector2(sin(elapsed * 1.7) * 0.9, sin(elapsed * 0.9) * 0.28)
        "wave":
            eye_target = Vector2(0.5, -0.25)
        "sleep":
            expression_id = "sleeping"
        "idle":
            # Resting is not a frozen expression: small attentive eye motion.
            eye_target = Vector2(0.20 * sin(elapsed * 0.47), 0.09 * sin(elapsed * 0.31))
    if _room_emotion_left > 0.0 and current_group in ["idle", "movement"]:
        expression_id = _room_emotion_id
    if _expression_override != "" and current_action not in ["gas", "brush_teeth"]:
        expression_id = _expression_override
    if _jaw_override >= 0.0 and current_action not in ["gas", "brush_teeth"]:
        opening = _jaw_override
    if _room_sleeping and current_group in ["idle", "movement"]:
        expression_id = "sleeping"
        opening = 0.0
    _apply_expression(expression_id)
    var jaw_speed: float = 6.0 if current_action == "brush_teeth" else 9.0
    var lerp_factor: float = 1.0 if delta >= 0.9 else 1.0 - exp(-jaw_speed * delta)
    _face_rig.set_jaw_open(lerpf(_face_rig.jaw_open, opening, lerp_factor))
    # Separate gaze remains available while the main body deforms and moves.
    if _expression_override == "" or current_action in ["gas", "brush_teeth"]:
        _face_rig.set_gaze(eye_target)
    _face_rig.scale = _face_rig.scale.lerp(Vector2.ONE * (1.10 if current_action == "brush_teeth" else 0.79), lerp_factor)
    # Always reapply after the expression and jaw have rewritten child nodes.
    _face_rig.set_surface_heading(_surface_heading)

func set_room_emotion(id: String, seconds: float = 3.0) -> void:
    # Same existing FaceRig and expression preset catalog.
    if is_instance_valid(_face_rig) and _face_rig.presets.has(id):
        _room_emotion_id = id
        _room_emotion_left = maxf(seconds, 0.0)
        _apply_expression(id)

func set_room_turn_activity(amount: float) -> void:
    if is_instance_valid(_actor) and _actor is MikaBubbleMovement:
        _actor.set_turn_activity(amount)

func set_room_sleep_pose(enabled: bool) -> void:
    # Preserve the current liquid renderer and FaceRig; only change its pose goal.
    _room_sleeping = enabled
    if enabled:
        _room_emotion_left = 0.0
        _expression_override = ""
    if is_instance_valid(_actor) and _actor is MikaBubbleMovement:
        _actor.set_room_sleep_pose(enabled)

func set_room_heading(heading_rad: float) -> void:
    # Body yaw and face projection share one heading, even during the idle turn.
    _surface_heading = heading_rad
    if is_instance_valid(_actor) and _actor is MikaBubbleMovement:
        _actor.set_facing_heading(heading_rad)
    if is_instance_valid(_face_rig):
        _face_rig.set_surface_heading(heading_rad)

func set_room_locomotion(mode_id: String, speed_ratio: float, traveled: float, steer_delta: float = 0.0) -> void:
    # Critical: movement never instantiates a new body/face or resets springs.
    # Only care / gesture / plastic actions switch renderer as before.
    if not external_motion_control:
        return
    var valid: bool = mode_id in ["idle", "walk_forward", "walk_backward", "strafe_left", "strafe_right"]
    if not valid:
        return
    if not is_instance_valid(_actor) or not (_actor is MikaBubbleMovement):
        play_action("idle")
    var previous: String = current_action
    current_action = "idle" if speed_ratio <= 0.025 else mode_id
    current_group = "idle" if current_action == "idle" else "movement"
    action_duration = -1.0
    finished = false
    # Changing walk direction must NOT clear a temporary expression or
    # create a new rig. Face and liquid orbit continue as one animation.
    if previous != current_action:
        _expression_override = ""
        _jaw_override = -1.0
        action_started.emit(current_action)
    _actor.set_locomotion_input(mode_id, speed_ratio, traveled, steer_delta)

func play_action(id: String) -> void:
    if id not in ACTIONS:
        push_warning("Unknown Bubble action: " + id)
        return
    if id == "idle" and is_instance_valid(_actor) and _actor is MikaBubbleMovement:
        current_action = "idle"
        current_group = "idle"
        finished = false
        elapsed = 0.0
        action_duration = -1.0
        _actor.set_locomotion_input("idle", 0.0, 0.0, 0.0)
        _expression_override = ""
        _jaw_override = -1.0
        _update_face(0.0, 0.06)
        return
    # Dispose any older fading renderer before bringing a new one in.
    if is_instance_valid(_outgoing):
        _outgoing.queue_free()
        _outgoing = null
    _outgoing = _actor if is_instance_valid(_actor) else null
    _actor = _scene_for(group_for(id)).instantiate()
    _actor.name = "ActiveVisual"
    add_child(_actor)
    _apply_render_quality(_actor)
    _attach_face()
    current_action = id
    current_group = group_for(id)
    elapsed = 0.0
    finished = false
    _step_after_finish = 0.0
    _brushing_ready = false
    _room_emotion_left = 0.0
    _brushing_completed = false
    _brushing_finish_delay = 0.0
    _jaw_override = -1.0
    action_duration = -1.0
    _blend_time = 0.0
    _actor.modulate = Color(1.0, 1.0, 1.0, 0.0 if is_instance_valid(_outgoing) else 1.0)

    match current_group:
        "idle":
            # One liquid renderer serves both standing and walking.
            _actor.playback_rate = playback_rate
            _actor.gait_amplitude = expressiveness
            _actor.spring_responsiveness = spring_responsiveness
            _actor.set_locomotion_input("idle", 0.0, 0.0, 0.0)
        "movement":
            _actor.playback_rate = playback_rate
            _actor.gait_amplitude = expressiveness
            _actor.spring_responsiveness = spring_responsiveness
            _actor.restart_motion(id)
            action_duration = 4.2 if id == "brake" else 4.6
        "turn":
            _actor.standalone_autoplay = false
            _actor.playback_rate = playback_rate
            _actor.pose_amplitude = expressiveness
            _actor.spring_responsiveness = spring_responsiveness
            _actor.start_turn(id)
            action_duration = _actor.duration
        "gesture":
            _actor.standalone_autoplay = false
            _actor.playback_rate = playback_rate
            _actor.pose_amplitude = expressiveness
            _actor.spring_responsiveness = spring_responsiveness
            _actor.start_gesture(id)
            action_duration = _actor.duration
        "plastic":
            _actor.standalone_autoplay = false
            _actor.playback_rate = playback_rate
            _actor.pose_amplitude = expressiveness
            _actor.spring_responsiveness = spring_responsiveness
            _actor.start_action(id)
            action_duration = _actor.duration
        "care":
            _actor.standalone_autoplay = false
            _actor.playback_rate = playback_rate
            _actor.pose_amplitude = expressiveness
            _actor.spring_responsiveness = spring_responsiveness
            _actor.start_care(id)
            action_duration = _actor.duration
    _action_start_pos = position
    _action_end_pos = position + _travel_delta(id)
    _actor.set_process(not paused)
    _update_face(0.0, 1.0)
    action_started.emit(id)

func _travel_delta(id: String) -> Vector2:
    match id:
        "walk_forward": return Vector2(315, 0)
        "walk_backward": return Vector2(-280, 0)
        "strafe_left": return Vector2(-255, 0)
        "strafe_right": return Vector2(255, 0)
        "accelerate": return Vector2(350, 0)
        "brake": return Vector2(270, 0)
        "turn_move_left": return Vector2(-220, 0)
        "turn_move_right": return Vector2(220, 0)
    return Vector2.ZERO

func _process(delta: float) -> void:
    if paused or not is_instance_valid(_actor):
        return
    _sample_mobile_performance(delta)
    var dt: float = minf(delta, 0.04)
    if is_instance_valid(_outgoing):
        _blend_time += dt
        var blend: float = clampf(_blend_time / blend_seconds, 0.0, 1.0)
        var smooth_blend: float = blend * blend * (3.0 - 2.0 * blend)
        _actor.modulate = Color(1.0, 1.0, 1.0, smooth_blend)
        _outgoing.modulate = Color(1.0, 1.0, 1.0, 1.0 - smooth_blend)
        if blend >= 1.0:
            _outgoing.queue_free()
            _outgoing = null

    if finished:
        _update_face(get_progress(), dt)
        if auto_return_idle and current_action != "idle":
            _step_after_finish += dt
            if _step_after_finish >= 0.75:
                play_action("idle")
        return

    elapsed += dt * playback_rate
    if external_motion_control and current_group in ["idle", "movement"]:
        _room_emotion_left = maxf(0.0, _room_emotion_left - dt)
        _room_emotion_clock += dt
        # Brief micro-expressions when standing or walking; no automatic
        # surprise/O-mouth. Wider emotions can be selected by the HUD.
        if _room_emotion_left <= 0.0 and _room_emotion_clock > 7.0:
            _room_emotion_clock = 0.0
            _room_emotion_cycle += 1
            var safe_set: Array[String] = ["calm", "happy", "content", "proud", "playful", "thoughtful", "delighted"]
            var next_id: String = safe_set[_room_emotion_cycle % safe_set.size()]
            set_room_emotion(next_id, 1.5 if current_action != "idle" else 2.1)
    # Interactive tooth cleaning is a hold state: 31 actions, but this one
    # waits for the child to clean the plaque instead of timing out.
    if current_action == "brush_teeth":
        if not _brushing_completed:
            if not _brushing_ready:
                _actor.advance(dt)
                if elapsed >= 1.45:
                    _brushing_ready = true
                    brush_ready.emit()
            _update_face(0.45, dt)
        else:
            _brushing_finish_delay += dt
            _update_face(1.0, dt)
            if _brushing_finish_delay >= 1.25:
                _finish_action()
        return
    _update_face(get_progress(), dt)
    if current_group == "idle":
        return
    if current_group == "movement":
        if external_motion_control:
            # The room feeds real displacement; never terminate mid-walk.
            return
        var p: float = clampf(elapsed / action_duration, 0.0, 1.0)
        _actor.update_drive(p, p < 1.0)
        var travel_p: float = p
        if current_action == "accelerate":
            travel_p = pow(p, 2.25)
        elif current_action == "brake":
            var v: float = minf(p / 0.57, 1.0)
            travel_p = 1.0 - pow(1.0 - v, 3.0)
        if not external_motion_control:
            position = _action_start_pos.lerp(_action_end_pos, travel_p)
        if p >= 1.0:
            _update_face(1.0, dt)
            _finish_action()
        return

    # For all one-shot animation implementations the controller drives their time.
    if not _actor.has_finished:
        _actor.advance(dt)
    if current_group == "turn" and current_action.begins_with("turn_move_"):
        var progress_fraction: float = _actor.get_movement_fraction()
        if not external_motion_control:
            position = _action_start_pos.lerp(_action_end_pos, progress_fraction)
    elif current_group == "gesture":
        # The old gesture implementation emits extra root translation for a roll.
        _actor.position = _actor.motion_offset
    if _actor.has_finished:
        _update_face(1.0, dt)
        _finish_action()

func _finish_action() -> void:
    if finished: return
    finished = true
    action_finished.emit(current_action)

func get_progress() -> float:
    return 0.0 if action_duration <= 0.0 else clampf(elapsed / action_duration, 0.0, 1.0)

func set_paused(value: bool) -> void:
    paused = value
    if is_instance_valid(_actor):
        _actor.set_process(not value)
    if is_instance_valid(_face_rig):
        _face_rig.set_process(not value)
    if is_instance_valid(_outgoing):
        _outgoing.set_process(not value)

func set_render_quality_low(value: bool) -> void:
    if _render_quality_low == value:
        return
    _render_quality_low = value
    _apply_render_quality(_actor)
    _apply_render_quality(_outgoing)

func is_render_quality_low() -> bool:
    return _render_quality_low

func _apply_render_quality(target: Node) -> void:
    if not is_instance_valid(target):
        return
    var surface: ColorRect = target.get_node_or_null("Body/Surface") as ColorRect
    if surface != null and surface.material is ShaderMaterial:
        (surface.material as ShaderMaterial).set_shader_parameter("detail_level", 0.0 if _render_quality_low else 1.0)

func _sample_mobile_performance(delta: float) -> void:
    if not OS.has_feature("mobile"):
        return
    if _perf_warmup > 0.0:
        _perf_warmup -= delta
        return
    _perf_elapsed += delta
    _perf_frames += 1
    if _perf_elapsed < 1.25:
        return
    var measured_fps: float = float(_perf_frames) / maxf(_perf_elapsed, 0.001)
    _perf_elapsed = 0.0
    _perf_frames = 0
    if not _render_quality_low:
        _slow_windows = _slow_windows + 1 if measured_fps < 52.0 else 0
        if _slow_windows >= 2:
            set_render_quality_low(true)
            _slow_windows = 0
    else:
        _fast_windows = _fast_windows + 1 if measured_fps > 56.0 else 0
        if _fast_windows >= 6:
            set_render_quality_low(false)
            _fast_windows = 0

func set_playback_rate(value: float) -> void:
    playback_rate = value
    if not is_instance_valid(_actor): return
    _actor.playback_rate = value

func set_plasticity(value: float) -> void:
    spring_responsiveness = value
    if is_instance_valid(_actor):
        _actor.set("spring_responsiveness", value)

func set_amplitude(value: float) -> void:
    expressiveness = value
    if not is_instance_valid(_actor): return
    match current_group:
        "idle": _actor.gait_amplitude = value
        "movement": _actor.gait_amplitude = value
        _: _actor.pose_amplitude = value
