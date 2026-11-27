extends Node
## Second ending only. Native panel IDs and cameras are resolved by the installer.
var _owner: Control
var _audio: AudioStreamPlayer
var _paper: ColorRect
var _picture: TextureRect
var _meta: Dictionary = {}
var _data: Dictionary = {}
var _locale: String = ""
var _panel: String = ""
var _texture: Texture2D
var _elapsed: float = 0.0
var _started: bool = false
var _final: bool = false
var _active: bool = false
var _shot: Vector3 = Vector3(0.5, 0.5, 0.25)
var _target: Vector3 = Vector3(0.5, 0.5, 0.25)
const CONFIG = "res://mika_motion_comic/ch08_timeline/ch08_finale_panels.json"

func _json(path: String) -> Dictionary:
    if FileAccess.file_exists(path):
        var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if d is Dictionary:
            return d
    return {}

func attach_player(player: Control) -> void:
    _owner = player
    _meta = _json(CONFIG)
    _audio = AudioStreamPlayer.new()
    _audio.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_audio)

func handles(panel: String) -> bool:
    return not panel.is_empty() and (panel in _meta.get("panels", []) or panel == str(_meta.get("final_panel", "")))

func _language() -> String:
    var other: Node = _owner.get("_ch07_p03_bridge") as Node
    var lang: String = TranslationServer.get_locale()
    if other != null and other.has_method("_effective_locale"):
        lang = str(other.call("_effective_locale"))
    lang = lang.replace("-", "_")
    if lang.begins_with("pt"):
        return "pt_BR"
    var base: String = lang.split("_")[0]
    return base if base in ["ru", "en", "es", "fr", "de"] else "en"

func _load() -> void:
    _locale = _language()
    _data = _json("res://mika_motion_comic/ch08_timeline/%s/ch08_finale.json" % _locale)

func _page() -> Dictionary:
    return _data.get("pages", {}).get("CH08_FINAL" if _final else "CH08_P02", {})

func _show_page() -> void:
    var path: String = str(_page().get("image_path", ""))
    _texture = null
    if ResourceLoader.exists(path):
        _texture = ResourceLoader.load(path) as Texture2D
    if _texture == null:
        push_error("Missing finale texture: " + path)
        return
    if _final:
        if _paper == null:
            var art: Control = _owner.get("_artwork") as Control
            if art == null:
                push_error("Finale artwork control unavailable")
                return
            _paper = ColorRect.new()
            _paper.color = Color.WHITE
            _paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
            art.add_child(_paper)
            _paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            _picture = TextureRect.new()
            _picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
            _picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            _picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            _paper.add_child(_picture)
            _picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _picture.texture = _texture
        _paper.show()
    elif _paper != null:
        _paper.hide()

func _enter(panel: String, final: bool, smooth: bool) -> void:
    _audio.stop()
    _panel = panel
    _final = final
    _active = true
    _elapsed = 0.0
    _started = false
    if _locale != _language() or _data.is_empty():
        _load()
    var c: Array = _data.get("camera", {}).get(panel, {}).get("camera", [0.5, 0.5, 0.25])
    _target = Vector3(float(c[0]), float(c[1]), float(c[2]))
    if not smooth:
        _shot = _target
    _show_page()

func begin_sequence(sequence: Array) -> void:
    stop_sequence()
    if sequence.is_empty():
        return
    var panel: String = str(sequence[0])
    if handles(panel):
        _enter(panel, panel == str(_meta.get("final_panel", "")), false)

func panel_advanced(_previous: String, next: String, _manual: bool) -> void:
    if handles(next):
        _enter(next, next == str(_meta.get("final_panel", "")), true)
    else:
        stop_sequence()

func is_active_for(panel: String) -> bool:
    return _active and panel == _panel and _texture != null

func selected_texture() -> Texture2D:
    return _texture

func tick_before_camera(delta: float) -> void:
    if not _active:
        return
    if _locale != _language():
        _enter(_panel, _final, false)
    _elapsed += delta
    _shot = _shot.lerp(_target, clampf(delta * 5.0, 0.0, 1.0))

func _speaks() -> bool:
    return _final or _panel == str(_data.get("storm_panel", ""))

func camera_committed(_delta: float) -> void:
    if _started or not _speaks() or _elapsed < 0.7:
        return
    _started = true
    var path: String = str(_page().get("audio_path", ""))
    var stream: AudioStream = ResourceLoader.load(path) as AudioStream if ResourceLoader.exists(path) else null
    if stream != null:
        _audio.stream = stream
        _audio.play()
    else:
        push_error("Missing finale MP3: " + path)

func camera_state(_panel_id: String, _t: float, view: Vector2, _continuous: bool, _from: Vector3) -> Vector3:
    var ratio: float = 2480.0 / 3508.0
    var aspect: float = maxf(0.01, view.x / maxf(1.0, view.y))
    var h: float = clampf(_shot.z, 0.001, minf(1.0, ratio / aspect))
    var w: float = h * aspect / ratio
    return Vector3(clampf(_shot.x, w * 0.5, 1.0 - w * 0.5), clampf(_shot.y, h * 0.5, 1.0 - h * 0.5), h)

func frame_duration(_id: String, _fallback: float) -> float:
    if _final:
        return 1.0 # Stay on the blank page until player input.
    var done: bool = _elapsed >= 2.4
    if _speaks():
        done = _started and not _audio.playing and _elapsed >= float(_page().get("duration", 0.0)) + 1.0
    if not done:
        return 1.0
    var panels: Array = _meta.get("panels", [])
    if str(_meta.get("final_panel", "")).is_empty() and not panels.is_empty() and _panel == str(panels.back()):
        _enter(_panel, true, false)
        return 1.0
    return 0.0

func intercept_advance() -> bool:
    if not _active:
        return false
    if _final:
        return not _started or _audio.playing
    var panels: Array = _meta.get("panels", [])
    if str(_meta.get("final_panel", "")).is_empty() and not panels.is_empty() and _panel == str(panels.back()):
        _enter(_panel, true, false)
        return true
    return false

func stop_sequence() -> void:
    if _audio != null:
        _audio.stop()
    _active = false
    _panel = ""
    _final = false
    if _paper != null:
        _paper.hide()

func release_texture() -> void:
    _texture = null
    if _picture != null:
        _picture.texture = null
