extends RefCounted
## Shared RU P01-P04 sequencer. No audio duration or absolute timeline drives camera.
## Caller writes current to the actual shader, then calls commit; post_draw acknowledges it.
signal event_recorded(event_name: String, detail: String)

const DIALOGUE_SECONDS: float = 0.25
const PANEL_SECONDS: float = 0.40
const PAGE_ENTRY_SECONDS: float = 0.60
const FRAME_SETTLE_SECONDS: float = 0.10
const EPSILON: float = 0.0005
const PAGE_ASPECT: float = 2480.0 / 3508.0
const LOG_PATH: String = "user://ch01_camera_voice_v30_ru.log"

var phase: String = "off"
var current: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
var origin: Vector3 = Vector3.ZERO
var move_duration: float = 0.0
var move_elapsed: float = 0.0
var settle_required: float = FRAME_SETTLE_SECONDS
var settle_elapsed: float = 0.0
var committed: bool = false
var drawn: bool = false
var line_id: String = ""
var owner_path: String = ""

static func fit_page(shot: Vector3, view: Vector2) -> Vector3:
    var aspect: float = maxf(0.001, view.x / maxf(view.y, 1.0))
    var h: float = clampf(shot.z, 0.001, minf(1.0, PAGE_ASPECT / aspect))
    var w: float = h * aspect / PAGE_ASPECT
    return Vector3(clampf(shot.x, w * 0.5, 1.0 - w * 0.5), clampf(shot.y, h * 0.5, 1.0 - h * 0.5), h)

func reset() -> void:
    phase = "off"
    committed = false
    drawn = false
    settle_elapsed = 0.0

func record(event_name: String, detail: String = "") -> void:
    var message: String = "[CH01_RU_V30] %d %s %s %s %s" % [Time.get_ticks_msec(), line_id, event_name, owner_path, detail]
    print(message)
    var mode: int = FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE
    var file: FileAccess = FileAccess.open(LOG_PATH, mode)
    if file != null:
        file.seek_end()
        file.store_line(message)
        file.close()
    event_recorded.emit(event_name, detail)

func begin(id: String, node_path: String, from_shot: Vector3, to_shot: Vector3, animate: bool, same_panel: bool, style: String, page_entry: bool) -> void:
    reset()
    line_id = id
    owner_path = node_path
    origin = from_shot
    target = to_shot
    current = origin
    move_elapsed = 0.0
    move_duration = 0.0
    settle_required = FRAME_SETTLE_SECONDS
    var changed: bool = origin.distance_to(target) > EPSILON
    # Within a dialogue always pan if the camera target changes. Between drawings,
    # retain an authored hard cut rather than pan through unrelated comic gutters.
    if animate and changed:
        if same_panel or style == "pan" or style == "dissolve":
            move_duration = DIALOGUE_SECONDS if same_panel else PANEL_SECONDS
        else:
            settle_required += PANEL_SECONDS
    if page_entry:
        settle_required += PAGE_ENTRY_SECONDS
    phase = "moving" if move_duration > 0.0 else "framing"
    record("CAMERA_START", "from=%s to=%s move=%.2f settle=%.2f" % [origin, target, move_duration, settle_required])
    if phase == "framing":
        current = target
        record("CAMERA_END", "static/cut target=" + str(target))

func step(delta: float) -> void:
    if phase != "moving":
        return
    move_elapsed = minf(move_duration, move_elapsed + maxf(delta, 0.0))
    var t: float = move_elapsed / move_duration
    current = origin.lerp(target, t * t * (3.0 - 2.0 * t))
    if move_elapsed >= move_duration:
        current = target
        phase = "framing"
        record("CAMERA_END", "target=" + str(target))

func matches(actual: Vector3) -> bool:
    return actual.distance_to(target) <= EPSILON

func commit(actual: Vector3, visible: bool, delta: float) -> void:
    if phase != "framing":
        return
    if not visible or not matches(actual):
        committed = false
        drawn = false
        settle_elapsed = 0.0
        return
    committed = true
    if drawn:
        settle_elapsed += maxf(delta, 0.0)

func post_draw(actual: Vector3, visible: bool) -> void:
    if phase == "framing" and committed and visible and matches(actual):
        if not drawn:
            drawn = true
            record("FRAME_CONFIRMED", "shader=" + str(actual))

func can_start(actual: Vector3, visible: bool) -> bool:
    return phase == "framing" and committed and drawn and settle_elapsed >= settle_required and visible and matches(actual)

func voice_started() -> void:
    phase = "voice"
    record("VOICE_START", "camera=" + str(target))

func voice_finished() -> void:
    if phase == "voice":
        record("VOICE_END", "AudioStreamPlayer.finished")
        phase = "done"

func fail(reason: String) -> void:
    if phase != "error":
        phase = "error"
        record("ERROR", reason)
        push_error("CH01 RU V30 " + line_id + ": " + reason)
