extends Control
class_name MikaMotionComicIntro
## v42: nine expanded artworks registered to the original 16:9 camera; 71 seconds; silent.
## Virtual cinema pixels extend beyond the 16:9 artwork without cropping the center.
## Original image camera, comic masks, dialogue timings and final shake are kept.
## Can be instanced inside any existing Godot 4 Control scene.
## Signals: finished. API: play(), pause(), resume(), restart(), seek(seconds), stop().

signal finished

@export var show_lettering: bool = true
@export_file("*.json") var editable_cues_path: String = "res://mika_motion_comic/cues.json"

@export var autoplay: bool = true
@export var loop_playback: bool = false
@export_range(0.1, 3.0, 0.05) var playback_speed: float = 1.0

const DURATION: float = 71.0
const BAKED_CAPTION_CUES = [
    {"id": "01_world", "start": 0.65, "end": 5.35, "style": "title", "text": "AERELIA", "secondary": "A WORLD ABOVE THE CLOUDS", "x": 70, "y": 498},
    {"id": "02_peace", "start": 5.9, "end": 9.75, "style": "caption", "text": "A PLACE WHERE LIFE", "secondary": "FLOATED IN THE SKY.", "x": 55, "y": 555},
    {"id": "03_mika", "start": 9.9, "end": 12.9, "style": "balloon", "text": "WHAT'S HAPPENING?", "x": 55, "y": 78, "w": 575},
    {"id": "04_alert", "start": 13.55, "end": 19.85, "style": "radio", "text": "EMERGENCY TRANSMISSION", "secondary": "A CHRONOSTORM IS COMING!", "x": 63, "y": 490, "w": 820},
    {"id": "05_space", "start": 21.15, "end": 25.75, "style": "caption", "text": "IT BENDS SPACE...", "x": 63, "y": 52},
    {"id": "06_time", "start": 26.45, "end": 30.45, "style": "caption", "text": "...AND FRACTURES TIME!", "x": 63, "y": 52},
    {"id": "07_danger", "start": 30.65, "end": 35.3, "style": "urgent", "text": "OUR WORLD IS", "secondary": "BREAKING APART!", "x": 65, "y": 516},
    {"id": "08_question", "start": 37.2, "end": 41.05, "style": "balloon", "text": "WHAT CAN WE DO?", "x": 62, "y": 50, "w": 550},
    {"id": "09_answer", "start": 41.25, "end": 46.65, "style": "balloon", "text": "FIND THE CROSSROADS", "secondary": "OF WORLDS!", "x": 620, "y": 485, "w": 602},
    {"id": "10_depart", "start": 48.55, "end": 52.4, "style": "balloon", "text": "I'LL FIND IT!", "x": 67, "y": 69, "w": 478},
    {"id": "11_quest", "start": 52.6, "end": 55.2, "style": "caption", "text": "INTO THE UNKNOWN...", "x": 66, "y": 560},
    {"id": "12_follow", "start": 57.05, "end": 61.55, "style": "caption", "text": "BUT THE STORM", "secondary": "WAS FASTER.", "x": 65, "y": 52},
    {"id": "13_caught", "start": 62.8, "end": 67.3, "style": "balloon", "text": "NO! IT FOUND ME!", "x": 720, "y": 477, "w": 512},
    {"id": "14_scream", "start": 67.8, "end": 70.6, "style": "scream", "text": "AAAAAAH!", "x": 750, "y": 450},
]

const OLD_BEATS: Array[float] = [0.000,3.400,6.950,7.650,10.500,11.350,12.550,16.550,17.350,20.450,21.200,24.200,24.950,27.800,30.600,33.200]
const NEW_BEATS: Array[float] = [0.000,5.600,12.000,13.200,20.600,22.000,26.200,35.600,36.800,47.200,48.400,55.400,56.600,62.000,67.600,71.000]

const BASE_SIZE: Vector2 = Vector2(1280.0, 720.0)
const COMIC_SHADER: Shader = preload("res://mika_motion_comic/shaders/comic_layer.gdshader")
@export var use_expanded_artwork: bool = true

# Use coordinates of the APPROVED original images for all authored focus/zoom.
# Expanded scene images are a NEW visual row, registered only through metadata.
const IMAGE_FILES_ORIGINAL: Dictionary = {
    "city": "res://mika_motion_comic/assets/city.png",
    "mica": "res://mika_motion_comic/assets/mica_balcony.png",
    "news": "res://mika_motion_comic/assets/news.png",
    "talk": "res://mika_motion_comic/assets/conversation.png",
    "red": "res://mika_motion_comic/assets/disaster_red.png",
    "magenta": "res://mika_motion_comic/assets/disaster_magenta.png",
    "ship_front": "res://mika_motion_comic/assets/ship_front.png",
    "ship_rear": "res://mika_motion_comic/assets/ship_rear.png",
    "cockpit": "res://mika_motion_comic/assets/cockpit.png",
}
const IMAGE_FILES_EXPANDED: Dictionary = {
    "city": "res://mika_motion_comic/assets/overscan/city_overscan.png",
    "mica": "res://mika_motion_comic/assets/overscan/mica_overscan.png",
    "news": "res://mika_motion_comic/assets/overscan/news_overscan.png",
    "talk": "res://mika_motion_comic/assets/overscan/talk_overscan.png",
    "red": "res://mika_motion_comic/assets/overscan/red_overscan.png",
    "magenta": "res://mika_motion_comic/assets/overscan/magenta_overscan.png",
    "ship_front": "res://mika_motion_comic/assets/overscan/ship_front_overscan.png",
    "ship_rear": "res://mika_motion_comic/assets/overscan/ship_rear_overscan.png",
    "cockpit": "res://mika_motion_comic/assets/overscan/cockpit_overscan.png",
}
# Affine registration is estimated (SIFT); known content changes remain in the PNGs.
const COMPOSITION_ALIGNMENTS: Dictionary = {
    "city": {"source": Vector2(1372, 1146), "linear": Vector4(0.74532000, 0.00082000, -0.00082000, 0.74532000), "origin": Vector2(243.06910000, 117.91354000)},
    "mica": {"source": Vector2(1122, 1402), "linear": Vector4(0.59319000, 0.00196000, -0.00196000, 0.59319000), "origin": Vector2(150.72984000, 497.31648000)},
    "news": {"source": Vector2(1372, 1147), "linear": Vector4(0.78477000, 0.00082000, -0.00082000, 0.78477000), "origin": Vector2(234.00754000, 57.36714000)},
    "talk": {"source": Vector2(1536, 1024), "linear": Vector4(0.66617000, -0.00694000, 0.00694000, 0.66617000), "origin": Vector2(268.05682000, 176.88933000)},
    "red": {"source": Vector2(1372, 1147), "linear": Vector4(0.72143000, -0.00306000, 0.00306000, 0.72143000), "origin": Vector2(139.13664000, 96.94213000)},
    "magenta": {"source": Vector2(1371, 1147), "linear": Vector4(0.80308000, -0.00261000, 0.00261000, 0.80308000), "origin": Vector2(126.27197000, 60.50362000)},
    "ship_front": {"source": Vector2(1536, 1024), "linear": Vector4(0.78007000, -0.00249000, 0.00249000, 0.78007000), "origin": Vector2(188.57894000, 83.95730000)},
    "ship_rear": {"source": Vector2(1536, 1024), "linear": Vector4(0.75522000, -0.04459000, 0.04459000, 0.75522000), "origin": Vector2(217.29300000, 74.42986000)},
    "cockpit": {"source": Vector2(1536, 1024), "linear": Vector4(0.61516000, -0.00952000, 0.00952000, 0.61516000), "origin": Vector2(302.65328000, 208.17871000)},
}

@onready var viewport_frame: Control = $ViewportFrame
@onready var picture: Control = $ViewportFrame/Picture
@onready var layers: Array[ColorRect] = [
    $ViewportFrame/Picture/Base,
    $ViewportFrame/Picture/Panel,
    $ViewportFrame/Picture/Transition,
]
@onready var fade_rect: ColorRect = $ViewportFrame/Picture/Fade
@onready var lettering: MikaComicLettering = $AdaptiveLettering

var elapsed: float = 0.0
var playing: bool = false
var textures: Dictionary = {}
var materials: Array[ShaderMaterial] = []
var caption_cues: Array = BAKED_CAPTION_CUES

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    lettering.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _load_caption_cues()
    viewport_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var selected_files: Dictionary = IMAGE_FILES_EXPANDED if use_expanded_artwork else IMAGE_FILES_ORIGINAL
    for key in selected_files:
        textures[key] = load(str(selected_files[key])) as Texture2D
        if textures[key] == null:
            push_error("MIKA intro missing artwork: " + str(selected_files[key]))
    for layer in layers:
        layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var mat := ShaderMaterial.new()
        mat.shader = COMIC_SHADER
        layer.material = mat
        materials.append(mat)
    fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(_fit_view)
    _fit_view()
    _render_time(elapsed)
    if autoplay:
        play()

func _load_caption_cues() -> void:
    # Edit the text and cue timings in cues.json; code changes are not needed.
    # A built-in fallback keeps the intro functional if JSON is not exported.
    if not FileAccess.file_exists(editable_cues_path):
        return
    var json_text: String = FileAccess.get_file_as_string(editable_cues_path)
    var data: Variant = JSON.parse_string(json_text)
    if data is Array and not data.is_empty():
        caption_cues = data

func _fit_view() -> void:
    # NO CROPPING: all original 1280x720 cinema coordinates fit inside the
    # device. The shader extends the source image past the margins, rather
    # than zooming away important artwork or distorting the virtual picture.
    if size.x < 1.0 or size.y < 1.0:
        return
    var fit_scale: float = minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
    viewport_frame.position = Vector2.ZERO
    viewport_frame.size = size
    picture.position = Vector2.ZERO
    picture.size = size
    for material in materials:
        material.set_shader_parameter("viewport_size", size)
        material.set_shader_parameter("contain_scale", fit_scale)
    lettering.position = Vector2.ZERO
    lettering.size = size
    _render_lettering(elapsed)

func play() -> void:
    if elapsed >= DURATION:
        elapsed = 0.0
    playing = true
    set_process(true)
    _render_time(elapsed)

func pause() -> void:
    playing = false

func resume() -> void:
    play()

func restart() -> void:
    elapsed = 0.0
    play()

func stop() -> void:
    playing = false
    elapsed = 0.0
    _render_time(elapsed)

func seek(seconds: float) -> void:
    elapsed = clampf(seconds, 0.0, DURATION)
    _render_time(elapsed)

func get_duration() -> float:
    return DURATION

func get_playhead() -> float:
    return elapsed

func _process(delta: float) -> void:
    if not playing:
        return
    elapsed = minf(elapsed + delta * playback_speed, DURATION)
    _render_time(elapsed)
    if elapsed >= DURATION:
        if loop_playback:
            elapsed = 0.0
        else:
            playing = false
            finished.emit()

static func _ease(value: float) -> float:
    var x: float = clampf(value, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)

static func _phase(t: float, start: float, ending: float) -> float:
    return _ease((t - start) / (ending - start))

static func _blend(a: float, b: float, amount: float) -> float:
    return lerpf(a, b, amount)

func _layer(slot: int, image_key: String, magnification: float, fx: float, fy: float,
        mask: int = 0, seam: float = 0.0, slope_value: float = 0.0,
        right_panel_start: float = 0.0, shake: Vector2 = Vector2.ZERO) -> void:
    var layer: ColorRect = layers[slot]
    var mat: ShaderMaterial = materials[slot]
    layer.visible = true
    mat.set_shader_parameter("artwork", textures[image_key])
    var mapping: Dictionary = COMPOSITION_ALIGNMENTS[image_key]
    mat.set_shader_parameter("source_resolution", mapping["source"])
    mat.set_shader_parameter("composition_affine", mapping["linear"] if use_expanded_artwork else Vector4(1.0, 0.0, 0.0, 1.0))
    mat.set_shader_parameter("composition_origin", mapping["origin"] if use_expanded_artwork else Vector2.ZERO)
    mat.set_shader_parameter("zoom", magnification)
    mat.set_shader_parameter("focus", Vector2(fx, fy))
    mat.set_shader_parameter("mask_mode", mask)
    mat.set_shader_parameter("seam_px", seam)
    mat.set_shader_parameter("slope", slope_value)
    mat.set_shader_parameter("panel_start_x", right_panel_start)
    mat.set_shader_parameter("shake_px", shake)

func _city(t: float, slot: int = 0, shake: Vector2 = Vector2.ZERO) -> void:
    var v: float = _phase(t, 0.0, 7.1)
    _layer(slot, "city", _blend(1.075, 1.195, v),
            _blend(0.54, 0.46, v), _blend(0.49, 0.52, v),
            0, 0.0, 0.0, 0.0, shake)

func _mica(t: float, slot: int = 1, shake: Vector2 = Vector2.ZERO) -> void:
    var v: float = _phase(t, 3.4, 7.0)
    _layer(slot, "mica", _blend(1.0, 1.075, v), 0.5, _blend(0.56, 0.46, v),
            1, _blend(1370.0, 1280.0 * 0.495, _phase(t, 3.4, 4.95)),
            0.12, 480.0, shake)

func _news(t: float, slot: int = 0, mask: int = 0, seam: float = 0.0,
        slope_value: float = 0.0, shake: Vector2 = Vector2.ZERO) -> void:
    var v: float = _phase(t, 6.95, 10.6)
    _layer(slot, "news", _blend(1.02, 1.135, v), 0.5,
            _blend(0.48, 0.53, v), mask, seam, slope_value, 0.0, shake)

func _disaster_first(t: float, slot: int = 0, mask: int = 0,
        seam: float = 0.0, slope_value: float = 0.0, shake: Vector2 = Vector2.ZERO) -> void:
    # STORY ORDER: clearer red scene FIRST, magenta collapsing scene SECOND.
    var v: float = _phase(t, 10.5, 16.8)
    _layer(slot, "red", _blend(1.04, 1.17, v), _blend(0.55, 0.49, v),
            0.48, mask, seam, slope_value, 0.0, shake)

func _disaster_duo(t: float, shake: Vector2 = Vector2.ZERO) -> void:
    var v: float = _phase(t, 12.55, 16.55)
    _layer(0, "red", _blend(1.12, 1.22, v),
            _blend(0.52, 0.59, v), 0.50, 0, 0.0, 0.0, 0.0, shake)
    # The more chaotic damaged city scene enters from the right.
    _layer(1, "magenta", _blend(1.03, 1.15, v),
            _blend(0.44, 0.54, v), _blend(0.52, 0.45, v),
            1, _blend(1360.0, 1280.0 * 0.52, _phase(t, 12.55, 13.35)),
            -0.12, 555.0, shake)

func _talk(t: float, slot: int = 0, mask: int = 0,
        seam: float = 0.0, slope_value: float = 0.0, shake: Vector2 = Vector2.ZERO) -> void:
    var v: float = _phase(t, 16.55, 20.5)
    _layer(slot, "talk", _blend(1.025, 1.115, v),
            _blend(0.48, 0.50, v), 0.53, mask, seam, slope_value, 0.0, shake)

func _ship_front(t: float, slot: int = 0, mask: int = 0,
        seam: float = 0.0, slope_value: float = 0.0, shake: Vector2 = Vector2.ZERO) -> void:
    var v: float = _phase(t, 20.45, 24.35)
    _layer(slot, "ship_front", _blend(1.035, 1.16, v),
            _blend(0.44, 0.36, v), _blend(0.52, 0.47, v),
            mask, seam, slope_value, 0.0, shake)

func _ship_rear(t: float, slot: int = 0, mask: int = 0,
        seam: float = 0.0, slope_value: float = 0.0, shake: Vector2 = Vector2.ZERO) -> void:
    var v: float = _phase(t, 24.2, 31.6)
    _layer(slot, "ship_rear", _blend(1.03, 1.25, v),
            0.51, _blend(0.51, 0.44, v),
            mask, seam, slope_value, 0.0, shake)

func _cockpit(t: float, slot: int = 1, mask: int = 1,
        seam: float = 0.0, slope_value: float = -0.15,
        right_panel_start: float = 510.0, shake: Vector2 = Vector2.ZERO) -> void:
    var v: float = _phase(t, 27.8, 30.75)
    _layer(slot, "cockpit", _blend(1.02, 1.10, v),
            _blend(0.44, 0.48, v), 0.46, mask, seam,
            slope_value, right_panel_start, shake)

func _shake(t: float, strength: float) -> Vector2:
    if strength <= 0.0:
        return Vector2.ZERO
    return Vector2(
        strength * (0.68 * sin(t * 29.7) + 0.32 * sin(t * 47.8)),
        strength * (0.65 * sin(t * 38.1) + 0.35 * sin(t * 65.2))
    )

func _picture_seconds(t: float) -> float:
    for i in range(NEW_BEATS.size() - 1):
        if t < NEW_BEATS[i + 1]:
            var fraction: float = (t - NEW_BEATS[i]) / (NEW_BEATS[i + 1] - NEW_BEATS[i])
            return lerpf(OLD_BEATS[i], OLD_BEATS[i + 1], fraction)
    return OLD_BEATS[OLD_BEATS.size() - 1]

func _render_time(t: float) -> void:
    _render_picture(_picture_seconds(t))
    _render_lettering(t)

func _render_picture(t: float) -> void:
    for layer in layers:
        layer.visible = false
    fade_rect.color = Color(0.0, 0.0, 0.0, _phase(t, 32.85, 33.2))

    if t < 3.4:
        _city(t)
    elif t < 6.95:
        _city(t)
        _mica(t)
    elif t < 7.65:
        _city(t)
        _mica(t)
        _news(t, 2, 3, _blend(870.0, -110.0, _phase(t, 6.95, 7.65)), -0.07)
    elif t < 10.5:
        _news(t)
    elif t < 11.35:
        _news(t)
        _disaster_first(t, 1, 2, _blend(-100.0, 1390.0, _phase(t, 10.5, 11.35)), -0.13)
    elif t < 12.55:
        _disaster_first(t)
    elif t < 16.55:
        _disaster_duo(t)
    elif t < 17.35:
        _disaster_duo(t)
        _talk(t, 2, 1, _blend(1395.0, -110.0, _phase(t, 16.55, 17.35)), 0.16)
    elif t < 20.45:
        _talk(t)
    elif t < 21.2:
        _talk(t)
        _ship_front(t, 1, 3, _blend(870.0, -120.0, _phase(t, 20.45, 21.2)), 0.14)
    elif t < 24.2:
        _ship_front(t)
    elif t < 24.95:
        _ship_front(t)
        _ship_rear(t, 1, 2, _blend(-100.0, 1430.0, _phase(t, 24.2, 24.95)), 0.20)
    elif t < 27.8:
        var shake := _shake(t, _blend(0.0, 2.0, _phase(t, 26.2, 27.8)))
        _ship_rear(t, 0, 0, 0.0, 0.0, shake)
    elif t < 30.6:
        var shake := _shake(t, _blend(1.0, 5.2, _phase(t, 27.8, 30.6)))
        _ship_rear(t, 0, 0, 0.0, 0.0, shake)
        _cockpit(t, 1, 1, _blend(1380.0, 1280.0 * 0.48, _phase(t, 27.8, 28.8)), -0.15, 510.0, shake)
    else:
        var shake := _shake(t, _blend(5.2, 1.0, _phase(t, 30.6, 33.1)))
        if t < 31.35:
            _ship_rear(t, 0, 0, 0.0, 0.0, shake)
            _cockpit(t, 1, 1, 1280.0 * 0.48, -0.15, 510.0, shake)
            var push: float = _phase(t, 30.6, 33.2)
            _layer(2, "cockpit", _blend(1.10, 1.23, push),
                    _blend(0.42, 0.39, push), 0.47, 1,
                    _blend(1280.0 * 0.48, -110.0, _phase(t, 30.6, 31.35)),
                    -0.15, 0.0, shake)
        else:
            var push: float = _phase(t, 30.6, 33.2)
            _layer(0, "cockpit", _blend(1.10, 1.23, push),
                    _blend(0.42, 0.39, push), 0.47, 0, 0.0, 0.0, 0.0, shake)


func _render_lettering(t: float) -> void:
    if not show_lettering:
        lettering.visible = false
        return
    for cue in caption_cues:
        var start_time: float = float(cue["start"])
        var end_time: float = float(cue["end"])
        if t < start_time or t >= end_time:
            continue
        var fade_in: float = minf(0.28, (end_time - start_time) * 0.18)
        var fade_out: float = minf(0.32, (end_time - start_time) * 0.18)
        var alpha: float = clampf(minf((t - start_time) / maxf(fade_in, 0.01),
                              (end_time - t) / maxf(fade_out, 0.01)), 0.0, 1.0)
        alpha = _ease(alpha)
        var screen_fit_scale: float = minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
        var fit_size: Vector2 = BASE_SIZE * screen_fit_scale
        var fit_rect: Rect2 = Rect2((size - fit_size) * 0.5, fit_size)
        var visible_cue: Dictionary = cue.duplicate()
        if has_node("/root/MobileLocale"):
            var localized: Dictionary = get_node("/root/MobileLocale").caption_for(str(cue.get("id", "")))
            for key in ["text", "secondary"]:
                if localized.has(key):
                    visible_cue[key] = localized[key]
        lettering.update_cue(visible_cue, fit_rect, false, alpha)
        return
    lettering.visible = false
