extends "res://mika_motion_comic/scripts/ch01_modular_bridge_core.gd"
## CH01 P06: existing shared sequencer, page-specific camera composition.
func _page_number() -> int:
    return 6

func _camera_for_line(line: Dictionary) -> Vector3:
    return _p06_fit(_vec(line.get("camera_target", [])), str(line.get("panel_id", "")), _owner.size if _owner != null else Vector2(1280, 720))

func _p06_fit(cam: Vector3, panel: String, view: Vector2) -> Vector3:
    var bounds: Rect2 = _rect((_data.get("panel_bounds", {}) as Dictionary).get(panel, [0.0, 0.0, 1.0, 1.0]))
    var aspect: float = clampf(view.x / maxf(1.0, view.y), 0.4, 3.25)
    var h: float = minf(cam.z, minf(bounds.size.y, bounds.size.x * PAGE_RATIO / aspect) * 0.985)
    var w: float = h * aspect / PAGE_RATIO
    return Vector3(clampf(cam.x, bounds.position.x + w * 0.5, bounds.end.x - w * 0.5), clampf(cam.y, bounds.position.y + h * 0.5, bounds.end.y - h * 0.5), h)

func camera_state(panel: String, _elapsed: float, view: Vector2, _continuous: bool, _from_camera: Vector3) -> Vector3:
    if not is_active_for(panel):
        return Vector3(0.5, 0.5, 0.25)
    return _p06_fit(_camera_now, panel, view)

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
        _owner.set("_page_six_texture", _texture)
        _camera_now = _camera_for_line(_line())
        _start_line(false)
        _owner.call("_update_camera")
