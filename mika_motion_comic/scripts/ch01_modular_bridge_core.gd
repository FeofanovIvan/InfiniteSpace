extends Node
## MIKA CH01 pages 2-4: one spoken line = one MP3. Godot 4.7.1.
## Strict pipeline: camera movement -> visible render acknowledgements ->
## optional SFX while moving -> completed visual frame -> single independent voice clip.
## No global MP3 clock and no independently scheduled child _process.
## CH01_CAMERA_VOICE_INSTRUMENTED_V22: safe render gate plus event trace.

const RU_SEQUENCE = preload("res://mika_motion_comic/scripts/ch01_ru_camera_sequence.gd")
var _ru_sequence = RU_SEQUENCE.new()

const LANGS: Array[String] = ["ru", "en", "pt_BR", "es", "fr", "de"]
const HOLD_FRAME: float = 1000000.0
const PAGE_RATIO: float = 2480.0 / 3508.0

var _owner: Control
var _voice: AudioStreamPlayer
var _sfx: AudioStreamPlayer
signal sync_event(event_name: String, line_id: String, details: String)
var _camera_commits: int = 0
var _debug_label: Label = null
var _last_phase_reported: String = ""
var _render_seen: bool = false
var _visible_hold_s: float = 0.0
var _transition_has_motion: bool = false
var _locale: String = ""
var _texture: Texture2D
var _data: Dictionary = {}
var _all_lines: Array = []
var _panel: String = ""
var _previous_panel: String = ""
var _line_index: int = -1
var _active: bool = false
var _panel_done: bool = false
var _phase: String = "off"  # transition / framing / voice / awaiting_panel / error / off
var _move_elapsed: float = 0.0
var _move_duration: float = 0.0
var _cue_remaining: float = 0.0
var _camera_from: Vector3 = Vector3(0.5, 0.5, 0.25)
var _camera_target: Vector3 = Vector3(0.5, 0.5, 0.25)
var _camera_now: Vector3 = Vector3(0.5, 0.5, 0.25)
var _transition_style: String = "cut"

func _page_number() -> int:
    return 0  # Override in the three tiny page adapters.

func _ready() -> void:
    _ru_sequence.event_recorded.connect(_ru_on_event)

    process_mode = Node.PROCESS_MODE_ALWAYS
    # The parent story player calls tick_before_camera, then updates the
    # shader, then calls camera_committed. Child _process must not race it.
    set_process(false)
    _voice = AudioStreamPlayer.new()
    _voice.name = "CH01_ModularVoice_P%02d" % _page_number()
    _voice.process_mode = Node.PROCESS_MODE_ALWAYS
    _voice.bus = "Master"
    add_child(_voice)
    _voice.finished.connect(_on_clip_finished)
    RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
    _sfx = AudioStreamPlayer.new()
    _sfx.name = "CH01_CameraTransitionEffect_P%02d" % _page_number()
    _sfx.process_mode = Node.PROCESS_MODE_ALWAYS
    _sfx.bus = "Master"
    add_child(_sfx)
    _sfx.finished.connect(_on_sfx_finished)
    _emit_sync("BRIDGE_READY", "Audio and camera are controlled from one state machine")
    var locale_service: Node = get_node_or_null("/root/MobileLocale")
    if locale_service != null and locale_service.has_signal("language_changed"):
        locale_service.connect("language_changed", Callable(self, "_on_language_changed"))

func attach_player(owner: Control) -> void:
    _owner = owner
    _load_locale()
    # Visible evidence that the actual running comic uses this code.
    # Only debug builds show the small status text; releases remain clean.
    if OS.has_feature("debug"):
        _debug_label = Label.new()
        _debug_label.name = "CH01_V22_Debug_P%02d" % _page_number()
        _debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _debug_label.add_theme_font_size_override("font_size", 16)
        _debug_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
        _debug_label.add_theme_color_override("font_shadow_color", Color.BLACK)
        _debug_label.add_theme_constant_override("shadow_offset_x", 2)
        _debug_label.add_theme_constant_override("shadow_offset_y", 2)
        _debug_label.position = Vector2(16, 92)
        _debug_label.z_index = 100
        _debug_label.visible = false
        _owner.add_child(_debug_label)

func _emit_sync(event_name: String, details: String = "") -> void:
    var ident: String = str(_line().get("line_id", "none"))
    var text_line: String = "[CH01_SYNC_V22] %d P%02d %s %s %s" % [Time.get_ticks_msec(), _page_number(), _locale, ident, event_name]
    if not details.is_empty():
        text_line += " " + details
    print(text_line)
    var log_path: String = "user://ch01_camera_voice_v22.log"
    var open_mode: int = FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE
    var log_file: FileAccess = FileAccess.open(log_path, open_mode)
    if log_file != null:
        log_file.seek_end()
        log_file.store_line(text_line)
        log_file.close()
    sync_event.emit(event_name, ident, details)
    if _debug_label != null:
        _debug_label.text = "CAMERA-FIRST v2.2 | P%02d %s | %s | %s" % [_page_number(), _locale, ident, event_name]
        _debug_label.visible = _active and _owner != null and _owner.visible

func _camera_is_committed() -> bool:
    if _owner == null or not _owner.visible:
        return false
    var material: ShaderMaterial = _owner.get("_material") as ShaderMaterial
    if material == null:
        return false
    var drawn: Vector2 = material.get_shader_parameter("focus") as Vector2
    var crop: float = float(material.get_shader_parameter("crop_height"))
    var target: Vector3 = camera_state(_panel, 0.0, _owner.size, false, Vector3.ZERO)
    return drawn.distance_to(Vector2(target.x, target.y)) < 0.0015 and absf(crop - target.z) < 0.0015

func _play_move_effect(line: Dictionary) -> void:
    var path: String = str(line.get("transition_sfx_path", ""))
    var stream: AudioStream = _ch01_export_audio(path)
    if stream == null:
        return
    _sfx.stream = stream
    _sfx.volume_db = float(line.get("transition_sfx_volume_db", -26.0))
    _sfx.play()
    _emit_sync("SFX_MOVE_START", "Move-only effect; voice remains stopped")

func _effective_locale() -> String:
    var service: Node = get_node_or_null("/root/MobileLocale")
    var value: String = str(service.get("language")) if service != null else "en"
    if value.begins_with("pt"):
        value = "pt_BR"
    return value if LANGS.has(value) else "en"

func _load_locale() -> void:
    var wanted: String = _effective_locale()
    if wanted == _locale and not _all_lines.is_empty() and _texture != null:
        return
    _locale = wanted
    _texture = null
    _data = {}
    _all_lines.clear()
    var path: String = "res://mika_motion_comic/ch01_timeline/%s/ch01_p%02d.json" % [wanted, _page_number()]
    if FileAccess.file_exists(path):
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if parsed is Dictionary and str(parsed.get("page_id", "")) == "CH01_P%02d" % _page_number():
            _data = parsed
            _all_lines = parsed.get("lines", [])
    var pic: String = str(_data.get("image_path", ""))
    if not pic.is_empty() and FileAccess.file_exists(pic):
        var image: Image = Image.new()
        if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(pic)) == OK:
            _texture = ImageTexture.create_from_image(image)
    if _texture == null and not pic.is_empty() and ResourceLoader.exists(pic):
        _texture = load(pic) as Texture2D
    if _all_lines.is_empty() or _texture == null:
        push_error("CH01 P%02d: missing locale clip manifest or page image: %s" % [_page_number(), wanted])

func selected_texture() -> Texture2D:
    _load_locale()
    return _texture

func release_texture() -> void:
    _texture = null

func _find_line_for_panel(panel: String) -> int:
    for i in range(_all_lines.size()):
        if str((_all_lines[i] as Dictionary).get("panel_id", "")) == panel:
            return i
    return -1

func _line() -> Dictionary:
    if _line_index >= 0 and _line_index < _all_lines.size():
        return _all_lines[_line_index] as Dictionary
    return {}

static func _vec(raw: Variant) -> Vector3:
    if raw is Array and raw.size() == 3:
        return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
    return Vector3(0.5, 0.5, 0.25)


func _camera_for_line(line: Dictionary) -> Vector3:
    # Scene-first direction: the authored frame is primary.
    # Bubble visibility is still respected, but only as a secondary assist.
    var desired: Vector3 = _vec(line.get("camera_target", []))
    var raw: Variant = line.get("bubble_box_normalized", null)
    if not (raw is Array and raw.size() == 4) or _owner == null:
        return desired
    var bubble: Rect2 = _rect(raw)
    var page_bounds: Dictionary = _data.get("panel_bounds", {})
    var bounds: Rect2 = _rect(page_bounds.get(str(line.get("panel_id", "")), [0,0,1,1]))
    return _scene_first_camera(desired, bubble, bounds)

func _camera_rect(cam: Vector3, aspect: float) -> Rect2:
    var width: float = cam.z * aspect / PAGE_RATIO
    return Rect2(cam.x - width * 0.5, cam.y - cam.z * 0.5, width, cam.z)

func _panel_limited_camera(cam: Vector3, bounds: Rect2, aspect: float) -> Vector3:
    var limited: Vector3 = cam
    var max_h: float = minf(bounds.size.y * 0.985, bounds.size.x * PAGE_RATIO / aspect * 0.985)
    limited.z = clampf(limited.z, 0.02, max_h)
    var width: float = limited.z * aspect / PAGE_RATIO
    limited.x = clampf(limited.x, bounds.position.x + width * 0.5, bounds.end.x - width * 0.5)
    limited.y = clampf(limited.y, bounds.position.y + limited.z * 0.5, bounds.end.y - limited.z * 0.5)
    return limited

func _scene_first_camera(desired: Vector3, bubble: Rect2, bounds: Rect2) -> Vector3:
    var aspect: float = clampf(_owner.size.x / maxf(1.0, _owner.size.y), 0.4, 3.25)
    var result: Vector3 = _panel_limited_camera(desired, bounds, aspect)
    var bubble_pad: float = 0.006
    var bubble_safe: Rect2 = Rect2(
        bubble.position - Vector2.ONE * bubble_pad,
        bubble.size + Vector2.ONE * bubble_pad * 2.0
    )
    var view: Rect2 = _camera_rect(result, aspect)
    if view.encloses(bubble_safe):
        return result
    var max_zoom_h: float = minf(bounds.size.y * 0.985, bounds.size.x * PAGE_RATIO / aspect * 0.985)
    var merged: Rect2 = view.merge(bubble_safe)
    var needed_h: float = maxf(merged.size.y, merged.size.x * PAGE_RATIO / aspect)
    var allowed_h: float = minf(max_zoom_h, result.z * 1.14)
    if needed_h > result.z:
        result.z = minf(allowed_h, maxf(result.z, needed_h))
        result = _panel_limited_camera(result, bounds, aspect)
        view = _camera_rect(result, aspect)
    var shift: Vector2 = Vector2.ZERO
    if bubble_safe.position.x < view.position.x:
        shift.x = bubble_safe.position.x - view.position.x
    elif bubble_safe.end.x > view.end.x:
        shift.x = bubble_safe.end.x - view.end.x
    if bubble_safe.position.y < view.position.y:
        shift.y = bubble_safe.position.y - view.position.y
    elif bubble_safe.end.y > view.end.y:
        shift.y = bubble_safe.end.y - view.end.y
    var max_shift: Vector2 = Vector2(view.size.x * 0.12, view.size.y * 0.16)
    shift.x = clampf(shift.x, -max_shift.x, max_shift.x)
    shift.y = clampf(shift.y, -max_shift.y, max_shift.y)
    result.x += shift.x
    result.y += shift.y
    return _panel_limited_camera(result, bounds, aspect)

func begin_sequence(ids: Array) -> void:
    stop_sequence()
    if ids.is_empty():
        return
    var prefix: String = "p%02d_" % _page_number()
    if _page_number() == 2:
        if not ["wormhole", "earth_view", "simulator", "earth_approach", "earth_spaceport"].has(str(ids[0])):
            return
    elif not str(ids[0]).begins_with(prefix):
        return
    _load_locale()
    _active = not _all_lines.is_empty()
    if not _active:
        return
    _panel = str(ids[0])
    _previous_panel = ""
    _line_index = _find_line_for_panel(_panel)
    if _line_index < 0:
        _active = false
        push_error("CH01: unknown panel in modular manifest: " + _panel)
        return
    _camera_now = _camera_for_line(_line())
    _emit_sync("SEQUENCE_START", "panel=" + _panel)
    _start_line(false)

func _start_line(animate: bool) -> void:
    if _locale == "ru":
        _ru_begin_line(animate)
        return

    if not _active or _line().is_empty():
        return
    _voice.stop()
    _voice.stream = null
    _sfx.stop()
    _sfx.stream = null
    var line: Dictionary = _line()
    _panel_done = false
    _camera_from = _camera_now
    _camera_target = _camera_for_line(line)
    _transition_style = str(line.get("transition_style", "cut"))
    _move_elapsed = 0.0
    _move_duration = clampf(float(line.get("transition_before_s", 0.40)), 0.0, 2.0) if animate else 0.0
    if _transition_style != "pan" or not animate:
        _camera_now = _camera_target
        _move_duration = 0.0
    _transition_has_motion = _move_duration > 0.015
    _phase = "transition" if _transition_has_motion else "framing"
    _camera_commits = 0
    _render_seen = false
    _visible_hold_s = 0.0
    _emit_sync("CAMERA_START", "panel=%s duration=%.3f from=%s to=%s" % [_panel, _move_duration, _camera_from, _camera_target])
    if _transition_has_motion:
        _play_move_effect(line)

func tick_before_camera(delta: float) -> void:
    if _locale == "ru":
        if _active:
            _ru_sequence.step(delta)
            _camera_now = _ru_sequence.current
            if _ru_sequence.phase == "voice" and not _ru_visible_shot_matches():
                _voice.stop()
                _ru_sequence.fail("camera or artwork changed during voice")
        return

    # Called explicitly from story_page_two_panels._process BEFORE _update_camera.
    if not _active or _phase != "transition":
        return
    _move_elapsed = minf(_move_elapsed + delta, _move_duration)
    var t: float = clampf(_move_elapsed / maxf(_move_duration, 0.001), 0.0, 1.0)
    t = t * t * (3.0 - 2.0 * t)
    _camera_now = _camera_from.lerp(_camera_target, t)
    if _move_elapsed >= _move_duration:
        _camera_now = _camera_target
        _phase = "framing"
        _camera_commits = 0
        _render_seen = false
        _visible_hold_s = 0.0
        if _sfx.playing:
            _sfx.stop()
        _emit_sync("CAMERA_END", "target=%s" % [_camera_target])

func _on_frame_post_draw() -> void:
    if _locale == "ru":
        if _active:
            _ru_sequence.post_draw(_ru_actual_shot(), _ru_visible())
        return

    # GPU-level acknowledgement that at least one frame used the new shot.
    if _active and _phase == "framing" and _camera_commits > 0 and _owner != null and _owner.visible:
        _render_seen = true

func camera_committed(delta: float) -> void:
    if _locale == "ru":
        if _active:
            _ru_sequence.commit(_ru_actual_shot(), _ru_visible(), delta)
            if _ru_sequence.can_start(_ru_actual_shot(), _ru_visible()):
                _ru_play_line()
        return

    # Called AFTER the parent has written the camera to its shader.
    # Requiring multiple presentation frames guarantees that the image
    # has moved BEFORE speech can start. One frame is not sufficient.
    if not _active or _phase != "framing" or _owner == null:
        return
    var material: ShaderMaterial = _owner.get("_material") as ShaderMaterial
    if material == null:
        return
    var actual: Vector2 = material.get_shader_parameter("focus") as Vector2
    var actual_crop: float = float(material.get_shader_parameter("crop_height"))
    var required: Vector3 = camera_state(_panel, 0.0, _owner.size, false, Vector3.ZERO)
    if actual.distance_to(Vector2(required.x, required.y)) > 0.0015 or absf(actual_crop - required.z) > 0.0015:
        _camera_commits = 0
        _render_seen = false
        _visible_hold_s = 0.0
        return
    _camera_commits += 1
    if _camera_commits == 1 and not _transition_has_motion:
        _emit_sync("CAMERA_END", "static or cut shot committed")
    _visible_hold_s += maxf(delta, 0.0)
    var line: Dictionary = _line()
    var hold: float = maxf(0.12, float(line.get("camera_visible_lead_s", 0.12)))
    if _render_seen and _camera_commits >= 3 and _visible_hold_s >= hold:
        _emit_sync("FRAME_CONFIRMED", "commits=%d hold=%.3fs" % [_camera_commits, _visible_hold_s])
        _play_line()

func _on_sfx_finished() -> void:
    # Effects accompany motion only. Never unlock voice from an SFX callback.
    _sfx.stop()
    _sfx.stream = null

func _play_line() -> void:
    if not _active or _line().is_empty():
        return
    # Fail closed: a voice cannot begin without the completed camera + render gate.
    var hold: float = maxf(0.12, float(_line().get("camera_visible_lead_s", 0.12)))
    if _phase != "framing" or not _render_seen or _camera_commits < 3 or _visible_hold_s < hold or not _camera_is_committed():
        _emit_sync("VOICE_BLOCKED", "phase=%s commits=%d frame_seen=%s hold=%.3f" % [_phase, _camera_commits, _render_seen, _visible_hold_s])
        return
    var path: String = str(_line().get("audio_path", ""))
    _phase = "voice"
    var stream: AudioStream = _ch01_export_audio(path)
    if stream == null:
        push_error("CH01: missing or unreadable individual voice clip: " + path)
        _phase = "error"
        return
    _voice.stop()
    _voice.stream = stream
    _emit_sync("VOICE_START", "camera=%s path=%s" % [_camera_now, path])
    _voice.play()

func _on_clip_finished() -> void:
    if _locale == "ru":
        if not _active or _ru_sequence.phase != "voice":
            return
        _ru_sequence.voice_finished()
        _voice.stream = null
        var next_index: int = _line_index + 1
        if next_index < _all_lines.size() and str((_all_lines[next_index] as Dictionary).get("panel_id", "")) == _panel:
            _line_index = next_index
            _ru_begin_line(true)
        else:
            _panel_done = true
            _phase = "awaiting_panel"
        return

    if not _active or _phase != "voice":
        return
    _emit_sync("VOICE_END", "clip naturally finished")
    _voice.stop()
    _voice.stream = null
    var upcoming: int = _line_index + 1
    if upcoming < _all_lines.size() and str((_all_lines[upcoming] as Dictionary).get("panel_id", "")) == _panel:
        _line_index = upcoming
        _start_line(true)
    else:
        _phase = "awaiting_panel"
        _panel_done = true

func panel_advanced(previous_id: String, next_id: String, _manual: bool) -> void:
    if not _active:
        return
    _emit_sync("PANEL_ADVANCE", "%s => %s" % [previous_id, next_id])
    _previous_panel = previous_id
    _panel = next_id
    _voice.stop()
    _voice.stream = null
    _line_index = _find_line_for_panel(next_id)
    if _line_index < 0:
        stop_sequence()
        return
    _start_line(true)

func stop_sequence() -> void:
    _ru_sequence.reset()

    _active = false
    _panel_done = false
    _phase = "off"
    if _debug_label != null:
        _debug_label.visible = false
    _panel = ""
    _line_index = -1
    if _voice != null:
        _voice.stop()
        _voice.stream = null
    if _sfx != null:
        _sfx.stop()
        _sfx.stream = null

func frame_duration(panel: String, fallback: float) -> float:
    if _active and panel == _panel:
        return 0.0 if _panel_done else HOLD_FRAME
    return fallback

func visual_duration(_panel_id: String, fallback: float) -> float:
    return fallback

func sync_elapsed(panel: String, fallback: float) -> float:
    # No global audio timeline! Keep old process clock for non-CH01 pages.
    return 0.0 if _active and panel == _panel else fallback

func is_active_for(panel: String) -> bool:
    return _active and panel == _panel

static func _rect(raw: Variant) -> Rect2:
    if raw is Array and raw.size() == 4:
        return Rect2(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]))
    return Rect2(0.0, 0.0, 1.0, 1.0)

func camera_state(panel: String, _elapsed: float, view: Vector2, _continuous: bool, _from_camera: Vector3) -> Vector3:
    if not is_active_for(panel):
        return Vector3(0.5, 0.5, 0.25)
    var current: Vector3 = _camera_now
    var bounds: Rect2 = _rect((_data.get("panel_bounds", {}) as Dictionary).get(panel, [0.0, 0.0, 1.0, 1.0]))
    if _phase == "transition" and _previous_panel != "" and _previous_panel != panel and _transition_style == "pan":
        var previous: Rect2 = _rect((_data.get("panel_bounds", {}) as Dictionary).get(_previous_panel, [0,0,1,1]))
        bounds = bounds.merge(previous)
    var aspect: float = maxf(0.3, view.x / maxf(1.0, view.y))
    return _panel_limited_camera(current, bounds, aspect)

func _on_language_changed(_new_code: String) -> void:
    _ru_sequence.reset()

    var saved_panel: String = _panel
    var was_active: bool = _active
    if _voice != null:
        _voice.stop()
    if _sfx != null:
        _sfx.stop()
    _locale = ""
    _load_locale()
    if was_active and _owner != null:
        # Switching locale restarts only the current frame, not the whole story.
        _panel = saved_panel
        _line_index = _find_line_for_panel(saved_panel)
        _active = _line_index >= 0
        if _active:
            _camera_now = _camera_for_line(_line())
            _start_line(false)
            _owner.set("_page_%s_texture" % ("two" if _page_number() == 2 else "three" if _page_number() == 3 else "four"), _texture)
            _owner.call("_update_camera")


# RU V3.0: no legacy camera clock, no SFX, no automatic fallback.
func _ru_on_event(event_name: String, detail: String) -> void:
    sync_event.emit(event_name, _ru_sequence.line_id, detail)
    if is_instance_valid(_debug_label):
        _debug_label.text = "CAMERA-FIRST RU v3.0 | %s | %s" % [_ru_sequence.line_id, event_name]
        _debug_label.visible = _active and is_instance_valid(_owner) and _owner.is_visible_in_tree()

func is_ru_sequence(panel: String) -> bool:
    return _locale == "ru" and is_active_for(panel)

func ru_panel_done() -> bool:
    return _panel_done and _ru_sequence.phase == "done"

func _ru_material() -> ShaderMaterial:
    return _owner.get("_material") as ShaderMaterial if is_instance_valid(_owner) else null

func _ru_actual_shot() -> Vector3:
    var mat: ShaderMaterial = _ru_material()
    if mat == null:
        return Vector3(-1.0, -1.0, -1.0)
    var f: Vector2 = mat.get_shader_parameter("focus") as Vector2
    return Vector3(f.x, f.y, float(mat.get_shader_parameter("crop_height")))

func _ru_visible() -> bool:
    var mat: ShaderMaterial = _ru_material()
    return is_instance_valid(_owner) and _owner.is_visible_in_tree() and mat != null and _texture != null and mat.get_shader_parameter("artwork") == _texture

func _ru_visible_shot_matches() -> bool:
    return _ru_visible() and _ru_sequence.matches(_ru_actual_shot())

func _ru_begin_line(animate: bool) -> void:
    if not _active or _line().is_empty() or not is_instance_valid(_owner):
        return
    _voice.stop()
    _voice.stream = null
    _sfx.stop()
    _sfx.stream = null
    _panel_done = false
    var line: Dictionary = _line()
    var same_panel: bool = animate and _line_index > 0 and str((_all_lines[_line_index - 1] as Dictionary).get("panel_id", "")) == _panel
    var view: Vector2 = _owner.size if _owner.size.x > 1.0 and _owner.size.y > 1.0 else _owner.get_viewport_rect().size
    var target: Vector3 = RU_SEQUENCE.fit_page(_camera_for_line(line), view)
    var origin: Vector3 = _ru_sequence.current if animate else target
    _ru_sequence.begin(str(line.get("line_id", "")), str(_owner.get_path()), origin, target, animate, same_panel, str(line.get("transition_style", "cut")), not animate and _line_index == 0)
    _camera_now = _ru_sequence.current
    _phase = "ru_sequence"

func _ru_play_line() -> void:
    if not _ru_sequence.can_start(_ru_actual_shot(), _ru_visible()):
        return
    var path: String = str(_line().get("audio_path", ""))
    var clip: AudioStreamMP3 = AudioStreamMP3.load_from_buffer(FileAccess.get_file_as_bytes(path)) if FileAccess.file_exists(path) else null
    if clip == null:
        _ru_sequence.fail("missing or invalid clip: " + path)
        return
    _voice.stream = clip
    _ru_sequence.voice_started()
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
