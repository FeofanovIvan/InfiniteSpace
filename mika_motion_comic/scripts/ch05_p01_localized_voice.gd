extends "res://mika_motion_comic/scripts/ch01_modular_bridge_core.gd"
## CH05 P01: existing shared sequencer, page-specific camera composition.
func _page_number() -> int:
    return 51

func _load_locale() -> void:
    var wanted: String = _effective_locale()
    if wanted == _locale and not _all_lines.is_empty() and _texture != null:
        return
    _locale = wanted
    _texture = null
    _data = {}
    _all_lines.clear()
    var path: String = "res://mika_motion_comic/ch05_timeline/%s/ch05_p01.json" % wanted
    if FileAccess.file_exists(path):
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if parsed is Dictionary and str(parsed.get("page_id", "")) == "CH05_P01":
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
        push_error("CH05 P01: missing locale clip manifest or page image: %s" % wanted)

func _camera_for_line(line: Dictionary) -> Vector3:
    return _p51_fit(_vec(line.get("camera_target", [])), str(line.get("panel_id", "")), _owner.size if _owner != null else Vector2(1280, 720))

func _p51_fit(cam: Vector3, panel: String, view: Vector2) -> Vector3:
    var bounds: Rect2 = _rect((_data.get("panel_bounds", {}) as Dictionary).get(panel, [0.0, 0.0, 1.0, 1.0]))
    var aspect: float = clampf(view.x / maxf(1.0, view.y), 0.4, 3.25)
    var h: float = minf(cam.z, minf(bounds.size.y, bounds.size.x * PAGE_RATIO / aspect) * 0.985)
    var w: float = h * aspect / PAGE_RATIO
    return Vector3(clampf(cam.x, bounds.position.x + w * 0.5, bounds.end.x - w * 0.5), clampf(cam.y, bounds.position.y + h * 0.5, bounds.end.y - h * 0.5), h)

func camera_state(panel: String, _elapsed: float, view: Vector2, _continuous: bool, _from_camera: Vector3) -> Vector3:
    if not is_active_for(panel):
        return Vector3(0.5, 0.5, 0.25)
    return _p51_fit(_camera_now, panel, view)

func _on_language_changed(_new_code: String) -> void:
    var was_active: bool = _active
    var saved_panel: String = _panel
    var saved_line: String = str(_line().get("line_id", ""))
    stop_sequence()
    _locale = ""
    _load_locale()
    if not was_active or _owner == null:
        return
    _panel = saved_panel
    _line_index = _find_line_for_panel(saved_panel)
    for i in range(_all_lines.size()):
        if str((_all_lines[i] as Dictionary).get("line_id", "")) == saved_line:
            _line_index = i
            break
    _active = _line_index >= 0 and _texture != null
    if _active:
        _owner.set("_ch05_page_one_texture", _texture)
        _camera_now = _camera_for_line(_line())
        _start_line(false)
        _owner.call("_update_camera")

# The existing real flight shows the red planet as a separate, unvoiced picture.
func begin_sequence(ids: Array) -> void:
    if not ids.is_empty() and str(ids[0]) == "p51_gravity_world":
        stop_sequence()
        return
    super.begin_sequence(ids)
