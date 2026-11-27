extends "res://mika_motion_comic/scripts/ch01_modular_bridge_core.gd"
## CH06 P03: reuse the shared camera-first / independent MP3 sequencer.
## Whole-page camera, no panel masking, no parallel timing clock.
## Silent visuals use the same camera-render gate, not fake audio resources.
var _silent_remaining: float = 0.0

func _play_line() -> void:
    if str(_line().get("audio_kind", "")) != "silent":
        super._play_line()
        return
    var hold: float = maxf(0.12, float(_line().get("camera_visible_lead_s", 0.12)))
    if not _active or _phase != "framing" or not _render_seen or _camera_commits < 3 or _visible_hold_s < hold or not _camera_is_committed():
        return
    _silent_remaining = maxf(0.1, float(_line().get("visual_hold_s", 2.2)))
    _phase = "visual_hold"

func tick_before_camera(delta: float) -> void:
    if _active and _phase == "visual_hold":
        _silent_remaining -= maxf(0.0, delta)
        if _silent_remaining <= 0.0:
            _phase = "awaiting_panel"
            _panel_done = true
        return
    super.tick_before_camera(delta)

func _page_number() -> int:
    return 63

func _load_locale() -> void:
    var wanted: String = _effective_locale()
    if wanted == _locale and not _all_lines.is_empty() and _texture != null:
        return
    _locale = wanted
    _texture = null
    _data = {}
    _all_lines.clear()
    var path: String = "res://mika_motion_comic/ch06_timeline/%s/ch06_p03.json" % wanted
    if FileAccess.file_exists(path):
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if parsed is Dictionary and str(parsed.get("page_id", "")) == "CH06_P03":
            _data = parsed
            _all_lines = parsed.get("lines", [])
    var pic: String = str(_data.get("image_path", ""))
    if not pic.is_empty() and ResourceLoader.exists(pic):
        _texture = ResourceLoader.load(pic) as Texture2D
    if _texture == null and not pic.is_empty() and FileAccess.file_exists(pic):
        var image: Image = Image.new()
        if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(pic)) == OK:
            _texture = ImageTexture.create_from_image(image)
    if _all_lines.is_empty() or _texture == null:
        push_error("CH06 P03: missing locale resources: " + wanted)
        _all_lines.clear()

func _p63_page_fit(cam: Vector3, view: Vector2) -> Vector3:
    var aspect: float = maxf(0.01, view.x / maxf(1.0, view.y))
    var h: float = clampf(cam.z, 0.001, minf(1.0, PAGE_RATIO / aspect))
    var w: float = h * aspect / PAGE_RATIO
    return Vector3(clampf(cam.x, w * 0.5, 1.0 - w * 0.5), clampf(cam.y, h * 0.5, 1.0 - h * 0.5), h)

func _camera_for_line(line: Dictionary) -> Vector3:
    var view: Vector2 = _owner.size if _owner != null else Vector2(1280, 720)
    var cam: Vector3 = _vec(line.get("camera_target", []))
    var bounds: Rect2 = _rect(line.get("visual_bounds", (_data.get("panel_bounds", {}) as Dictionary).get(str(line.get("panel_id", "")), [0.0, 0.0, 1.0, 1.0])))
    var aspect: float = maxf(0.01, view.x / maxf(1.0, view.y))
    if str(line.get("shot_type", "")) == "wide":
        cam.z = maxf(cam.z, bounds.size.x * PAGE_RATIO / aspect)
    elif str(line.get("shot_type", "")) == "scene":
        cam.z = minf(bounds.size.y, bounds.size.x * PAGE_RATIO / aspect) * 1.18
    return _p63_page_fit(cam, view)

func camera_state(panel: String, _elapsed: float, view: Vector2, _continuous: bool, _from_camera: Vector3) -> Vector3:
    if not is_active_for(panel):
        return Vector3(0.5, 0.5, 0.25)
    # Clamp to the WHOLE page only. Adjacent panels are deliberately allowed.
    return _p63_page_fit(_camera_now, view)

func _on_language_changed(_new_code: String) -> void:
    var was_active: bool = _active
    var saved_panel: String = _panel
    var saved_line: String = str(_line().get("line_id", ""))
    stop_sequence()
    _locale = ""
    if not was_active or _owner == null:
        release_texture()
        return
    _load_locale()
    _panel = saved_panel
    _line_index = _find_line_for_panel(saved_panel)
    for i in range(_all_lines.size()):
        if str((_all_lines[i] as Dictionary).get("line_id", "")) == saved_line:
            _line_index = i
            break
    _active = _line_index >= 0 and _texture != null
    if _active:
        _camera_now = _camera_for_line(_line())
        _start_line(false)
        _owner.call("_update_camera")
