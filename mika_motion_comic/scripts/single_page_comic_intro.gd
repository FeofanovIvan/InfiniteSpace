extends Control
class_name MikaSinglePageComicIntro
## MIKA CH01 P01: every line owns its audio, picture and camera transition.
## One audio clip finishes -> move camera in silence -> start next audio.
## Existing ComicPrologue.begin/restart/stop/finished API remains unchanged.

signal finished

@export var show_lettering: bool = false
@export_file("*.json") var editable_cues_path: String = "res://mika_motion_comic/cues.json"
@export var autoplay: bool = true
@export var loop_playback: bool = false
@export_range(0.1, 3.0, 0.05) var playback_speed: float = 1.0

const RU_SEQUENCE = preload("res://mika_motion_comic/scripts/ch01_ru_camera_sequence.gd")
var _ru_sequence = RU_SEQUENCE.new()

const PAGE_SHADER: Shader = preload("res://mika_motion_comic/shaders/ch01_p01_localized.gdshader")
const PAGE_ASPECT: float = 2480.0 / 3508.0
const LANGUAGE_CODES: Array[String] = ["ru", "en", "pt_BR", "es", "fr", "de"]

@onready var page: ColorRect = $Page
@onready var fade: ColorRect = $Fade
@onready var lettering: Control = $AdaptiveLettering

var elapsed: float = 0.0
var playing: bool = false
var page_material: ShaderMaterial
var _locale: String = ""
var _lines: Array = []
var _line_index: int = 0
var _voice: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _camera_commits: int = 0
var _render_seen: bool = false
var _visible_hold_s: float = 0.0
var _transition_has_motion: bool = false
var _phase: String = "off"
var _camera_now: Vector3 = Vector3(0.5, 0.5, 0.22)
var _camera_from: Vector3 = Vector3(0.5, 0.5, 0.22)
var _camera_to: Vector3 = Vector3(0.5, 0.5, 0.22)
var _transition_style: String = "cut"
var _move_duration: float = 0.0
var _move_elapsed: float = 0.0
var _cue_remaining: float = 0.0
var _seconds_before_line: float = 0.0
var _page_texture: Texture2D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    for item in [page, fade, lettering]:
        item.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lettering.hide()
    show_lettering = false  # The new localized WebP already contains the bubbles.
    page_material = ShaderMaterial.new()
    page_material.shader = PAGE_SHADER
    page_material.set_shader_parameter("page_aspect", PAGE_ASPECT)
    page.material = page_material
    _voice = AudioStreamPlayer.new()
    _voice.name = "CH01_P01_IndividualVoiceClips"
    _voice.process_mode = Node.PROCESS_MODE_ALWAYS
    _voice.finished.connect(_on_clip_finished)
    RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
    add_child(_voice)
    _sfx = AudioStreamPlayer.new()
    _sfx.name = "CH01_P01_CameraTransitionEffect"
    _sfx.process_mode = Node.PROCESS_MODE_ALWAYS
    _sfx.finished.connect(_on_sfx_finished)
    add_child(_sfx)
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        mobile.connect("language_changed", Callable(self, "_on_language_changed"))
    _load_locale()
    resized.connect(_fit_view)
    _fit_view()
    if autoplay:
        play()

func _effective_locale() -> String:
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    var code: String = str(mobile.get("language")) if mobile != null else "en"
    if code.begins_with("pt"):
        code = "pt_BR"
    return code if LANGUAGE_CODES.has(code) else "en"

func _load_locale() -> void:
    _locale = _effective_locale()
    var path: String = "res://mika_motion_comic/ch01_timeline/%s/ch01_p01.json" % _locale
    if not FileAccess.file_exists(path):
        push_error("CH01 P01: missing modular manifest: " + path)
        return
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (data is Dictionary) or not (data.get("lines", []) is Array) or data["lines"].size() != 10:
        push_error("CH01 P01: invalid voice manifest: " + path)
        return
    _lines = data["lines"]
    var pic_path: String = str(data.get("image_path", ""))
    _page_texture = null
    if ResourceLoader.exists(pic_path):
        _page_texture = load(pic_path) as Texture2D
    if _page_texture == null and FileAccess.file_exists(pic_path):
        var bitmap: Image = Image.new()
        if bitmap.load_webp_from_buffer(FileAccess.get_file_as_bytes(pic_path)) == OK:
            _page_texture = ImageTexture.create_from_image(bitmap)
    if _page_texture != null:
        page_material.set_shader_parameter("artwork", _page_texture)
    else:
        push_error("CH01 P01: localized WebP not found: " + pic_path)

static func _vector(raw: Variant) -> Vector3:
    if raw is Array and raw.size() == 3:
        return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
    return Vector3(0.5, 0.5, 0.22)

func _line() -> Dictionary:
    return _lines[_line_index] as Dictionary if _line_index >= 0 and _line_index < _lines.size() else {}

func _begin_line(animate: bool) -> void:
    if _locale == "ru":
        _ru_begin_line(animate)
        return

    if _line().is_empty():
        _finish_current()
        return
    if _voice != null:
        _voice.stop()
        _voice.stream = null
    if _sfx != null:
        _sfx.stop()
        _sfx.stream = null
    var line: Dictionary = _line()
    _camera_from = _camera_now
    _camera_to = _vector(line.get("camera_target", []))
    _transition_style = str(line.get("transition_style", "cut"))
    _move_duration = clampf(float(line.get("transition_before_s", 0.3)), 0.0, 2.0) if animate else 0.0
    _move_elapsed = 0.0
    if _transition_style not in ["pan", "dissolve"] or _move_duration <= 0.02:
        _camera_now = _camera_to
        _move_duration = 0.0
    _transition_has_motion = _move_duration > 0.015
    _phase = "transition" if _transition_has_motion else "framing"
    _camera_commits = 0
    _render_seen = false
    _visible_hold_s = 0.0
    _render()

func _process(delta: float) -> void:
    if not playing:
        return
    var advance: float = delta * playback_speed
    elapsed += advance
    if _locale == "ru":
        _ru_tick(delta)
        return
    if _phase == "transition":
        _move_elapsed = minf(_move_duration, _move_elapsed + advance)
        var t: float = clampf(_move_elapsed / maxf(_move_duration, 0.001), 0.0, 1.0)
        t = t * t * (3.0 - 2.0 * t)
        _camera_now = _camera_from.lerp(_camera_to, t)
        if _move_elapsed >= _move_duration:
            _camera_now = _camera_to
            _phase = "framing"
            _camera_commits = 0
            _render_seen = false
            _visible_hold_s = 0.0
    # Render camera BEFORE contemplating any sound for this frame.
    _render()
    if _phase == "framing":
        var actual: Vector2 = page_material.get_shader_parameter("focus_a") as Vector2
        var crop: float = float(page_material.get_shader_parameter("crop_height_a"))
        if actual.distance_to(Vector2(_camera_to.x, _camera_to.y)) > 0.0015 or absf(crop - _camera_to.z) > 0.0015:
            _camera_commits = 0
            _render_seen = false
            _visible_hold_s = 0.0
        else:
            _camera_commits += 1
            _visible_hold_s += advance
            if _render_seen and _camera_commits >= 3 and _visible_hold_s >= 0.12:
                _play_transition_effect_or_voice()

func _on_frame_post_draw() -> void:
    if _locale == "ru":
        if playing:
            _ru_sequence.post_draw(_ru_actual_shot(), _ru_visible())
        return

    if playing and _phase == "framing" and _camera_commits > 0 and visible:
        _render_seen = true

func _play_transition_effect_or_voice() -> void:
    var line: Dictionary = _line()
    var path: String = str(line.get("transition_sfx_path", ""))
    if _transition_has_motion and not path.is_empty():
        var stream: AudioStream = _ch01_export_audio(path)
        if stream != null:
            _sfx.stream = stream
            _sfx.volume_db = float(line.get("transition_sfx_volume_db", -26.0))
            _phase = "sfx"
            _sfx.play()
            return
    _play_voice()

func _on_sfx_finished() -> void:
    if not playing or _phase != "sfx":
        return
    _sfx.stop()
    _sfx.stream = null
    _play_voice()

func _play_voice() -> void:
    var path: String = str(_line().get("audio_path", ""))
    var stream: AudioStream = _ch01_export_audio(path)
    if stream == null:
        push_error("CH01 P01: missing or unreadable clip: " + path)
        _phase = "error"
        return
    _voice.stream = stream
    _voice.pitch_scale = playback_speed
    _phase = "voice"
    _voice.play()

func _on_clip_finished() -> void:
    if _locale == "ru":
        if not playing or _ru_sequence.phase != "voice":
            return
        _ru_sequence.voice_finished()
        _voice.stream = null
        if _line_index + 1 < _lines.size():
            _line_index += 1
            _ru_begin_line(true)
        else:
            _finish_current()
        return

    if not playing or _phase != "voice":
        return
    _voice.stop()
    _voice.stream = null
    if _line_index + 1 < _lines.size():
        _line_index += 1
        _begin_line(true)
    else:
        _finish_current()

func _finish_current() -> void:
    if not playing:
        return
    if loop_playback:
        restart()
    else:
        playing = false
        _phase = "off"
        _voice.stop()
        if _sfx != null:
            _sfx.stop()
        finished.emit()

func play() -> void:
    if _lines.is_empty():
        _load_locale()
    if _lines.is_empty():
        return
    if playing:
        return
    playing = true
    if _phase == "voice" and _voice != null and _voice.playing:
        _voice.stream_paused = false
    elif _phase == "sfx" and _sfx != null and _sfx.playing:
        _sfx.stream_paused = false
    elif _phase == "off":
        _line_index = 0
        _seconds_before_line = 0.0
        _camera_now = _vector(_lines[0].get("camera_target", []))
        _begin_line(false)
    _render()

func pause() -> void:
    playing = false
    if _voice != null and _voice.playing:
        _voice.stream_paused = true
    if _sfx != null and _sfx.playing:
        _sfx.stream_paused = true

func resume() -> void:
    play()

func restart() -> void:
    stop()
    play()

func stop() -> void:
    _ru_sequence.reset()

    playing = false
    _phase = "off"
    _line_index = 0
    elapsed = 0.0
    if _voice != null:
        _voice.stop()
        _voice.stream = null
    if _sfx != null:
        _sfx.stop()
        _sfx.stream = null
    if not _lines.is_empty():
        _camera_now = _vector(_lines[0].get("camera_target", []))
    _render()

func seek(seconds: float) -> void:
    # Explicit debug seek: jump to the *start of a line* so it stays synchronized.
    var offset: float = maxf(0.0, seconds)
    if _lines.is_empty():
        return
    if _voice != null:
        _voice.stop()
    _line_index = 0
    for i in range(_lines.size()):
        var length: float = float((_lines[i] as Dictionary).get("audio_duration_s", 1.0))
        if offset <= length or i == _lines.size() - 1:
            _line_index = i
            break
        offset -= length + float((_lines[i] as Dictionary).get("transition_before_s", 0.3))
    elapsed = seconds
    _camera_now = _vector(_line().get("camera_target", []))
    if playing or _locale == "ru":
        _begin_line(false)
    _render()

func get_duration() -> float:
    var total: float = 0.0
    for i in range(_lines.size()):
        var row: Dictionary = _lines[i] as Dictionary
        total += float(row.get("audio_duration_s", 0.0)) + (float(row.get("transition_before_s", 0.0)) if i > 0 else 0.0) + 0.10
    return total

func get_playhead() -> float:
    return elapsed

func get_camera_state() -> Vector3:
    return _camera_now

func _on_language_changed(code: String) -> void:
    if code != _locale:
        _ru_sequence.reset()

    if code == _locale:
        return
    var active: bool = playing
    var current: int = _line_index
    if _voice != null:
        _voice.stop()
    _load_locale()
    _line_index = mini(current, _lines.size() - 1)
    playing = active
    if not active and _locale == "ru":
        _phase = "off"
    if active and not _lines.is_empty():
        _camera_now = _vector(_line().get("camera_target", []))
        _begin_line(false)
    _render()

func _fit_view() -> void:
    if page_material == null:
        return
    if size.y > 1.0:
        page_material.set_shader_parameter("viewport_aspect", size.x / size.y)
    _render()

func _render() -> void:
    if page_material == null:
        return
    var a: Vector3 = _camera_now
    if _locale == "ru" and _ru_sequence.phase != "off":
        a = _ru_sequence.current
    var b: Vector3 = a
    var dissolve: float = 0.0
    if _locale != "ru" and _phase == "transition" and _transition_style == "dissolve":
        a = _camera_from
        b = _camera_to
        dissolve = clampf(_move_elapsed / maxf(_move_duration, 0.001), 0.0, 1.0)
    page_material.set_shader_parameter("focus_a", Vector2(a.x, a.y))
    page_material.set_shader_parameter("crop_height_a", a.z)
    page_material.set_shader_parameter("focus_b", Vector2(b.x, b.y))
    page_material.set_shader_parameter("crop_height_b", b.z)
    page_material.set_shader_parameter("dissolve", dissolve)
    fade.color = Color(0.015, 0.006, 0.025, 0.0)
    lettering.hide()


func _ru_visible() -> bool:
    return is_visible_in_tree() and page.is_visible_in_tree() and page_material != null and _page_texture != null and page_material.get_shader_parameter("artwork") == _page_texture

func _ru_actual_shot() -> Vector3:
    if page_material == null:
        return Vector3(-1.0, -1.0, -1.0)
    var f: Vector2 = page_material.get_shader_parameter("focus_a") as Vector2
    return Vector3(f.x, f.y, float(page_material.get_shader_parameter("crop_height_a")))

func _ru_begin_line(animate: bool) -> void:
    if _line().is_empty():
        _finish_current()
        return
    _voice.stop()
    _voice.stream = null
    _voice.stream_paused = false
    _sfx.stop()
    _sfx.stream = null
    var line: Dictionary = _line()
    var same_panel: bool = animate and _line_index > 0 and str((_lines[_line_index - 1] as Dictionary).get("panel_id", "")) == str(line.get("panel_id", ""))
    var view: Vector2 = size if size.x > 1.0 and size.y > 1.0 else get_viewport_rect().size
    var target: Vector3 = RU_SEQUENCE.fit_page(_vector(line.get("camera_target", [])), view)
    var origin: Vector3 = _ru_sequence.current if animate else target
    _ru_sequence.begin(str(line.get("line_id", "")), str(get_path()), origin, target, animate, same_panel, str(line.get("transition_style", "cut")), false)
    _camera_now = _ru_sequence.current
    _phase = "ru_sequence"
    _render()

func _ru_tick(delta: float) -> void:
    if _ru_sequence.phase == "voice" and (not _ru_visible() or not _ru_sequence.matches(_ru_actual_shot())):
        _voice.stop()
        _ru_sequence.fail("camera or artwork changed during voice")
        _phase = "error"
        return
    _ru_sequence.step(delta)
    _camera_now = _ru_sequence.current
    _render()
    _ru_sequence.commit(_ru_actual_shot(), _ru_visible(), delta)
    if not _ru_sequence.can_start(_ru_actual_shot(), _ru_visible()):
        return
    var path: String = str(_line().get("audio_path", ""))
    var clip: AudioStreamMP3 = AudioStreamMP3.load_from_buffer(FileAccess.get_file_as_bytes(path)) if FileAccess.file_exists(path) else null
    if clip == null:
        _ru_sequence.fail("missing or invalid clip: " + path)
        _phase = "error"
        return
    _voice.stream = clip
    _voice.pitch_scale = playback_speed
    _voice.stream_paused = false
    _ru_sequence.voice_started()
    _phase = "voice"
    _voice.play()

# CH01_EXPORT_AUDIO_RESOURCE_V1: imported audio in PCK, raw fallback for loose files.
func _ch01_export_audio(path: String) -> AudioStream:
    if path.is_empty():
        return null
    if ResourceLoader.exists(path):
        var imported: AudioStream = ResourceLoader.load(path) as AudioStream
        if imported != null:
            return imported
    if FileAccess.file_exists(path):
        var encoded: PackedByteArray = FileAccess.get_file_as_bytes(path)
        if not encoded.is_empty():
            return AudioStreamMP3.load_from_buffer(encoded)
    return null
