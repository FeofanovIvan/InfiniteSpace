extends Control
class_name MikaMotionComicIntro
## Real-time (not an MP4) motion-comic player. 16:9, 71.0 s, silent.
## Can be instanced inside any existing Godot 4 Control scene.
## Signals: finished. API: play(), pause(), resume(), restart(), seek(seconds), stop().

signal finished

@export var show_lettering: bool = true

@export var autoplay: bool = true
@export var loop_playback: bool = false
@export_range(0.1, 3.0, 0.05) var playback_speed: float = 1.0

const DURATION: float = 71.0
const CAPTION_CUES = [
    {"start": 0.650, "end": 5.350, "image": "res://mika_motion_comic/captions/01_world.png"},
    {"start": 5.900, "end": 9.750, "image": "res://mika_motion_comic/captions/02_peace.png"},
    {"start": 9.900, "end": 12.900, "image": "res://mika_motion_comic/captions/03_mika.png"},
    {"start": 13.550, "end": 19.850, "image": "res://mika_motion_comic/captions/04_alert.png"},
    {"start": 21.150, "end": 25.750, "image": "res://mika_motion_comic/captions/05_space.png"},
    {"start": 26.450, "end": 30.450, "image": "res://mika_motion_comic/captions/06_time.png"},
    {"start": 30.650, "end": 35.300, "image": "res://mika_motion_comic/captions/07_danger.png"},
    {"start": 37.200, "end": 41.050, "image": "res://mika_motion_comic/captions/08_question.png"},
    {"start": 41.250, "end": 46.650, "image": "res://mika_motion_comic/captions/09_answer.png"},
    {"start": 48.550, "end": 52.400, "image": "res://mika_motion_comic/captions/10_depart.png"},
    {"start": 52.600, "end": 55.200, "image": "res://mika_motion_comic/captions/11_quest.png"},
    {"start": 57.050, "end": 61.550, "image": "res://mika_motion_comic/captions/12_follow.png"},
    {"start": 62.800, "end": 67.300, "image": "res://mika_motion_comic/captions/13_caught.png"},
    {"start": 67.800, "end": 70.600, "image": "res://mika_motion_comic/captions/14_scream.png"},
]

const OLD_BEATS: Array[float] = [0.000,3.400,6.950,7.650,10.500,11.350,12.550,16.550,17.350,20.450,21.200,24.200,24.950,27.800,30.600,33.200]
const NEW_BEATS: Array[float] = [0.000,5.600,12.000,13.200,20.600,22.000,26.200,35.600,36.800,47.200,48.400,55.400,56.600,62.000,67.600,71.000]

const BASE_SIZE: Vector2 = Vector2(1280.0, 720.0)
const COMIC_SHADER: Shader = preload("res://mika_motion_comic/shaders/comic_layer.gdshader")
const IMAGE_FILES: Dictionary = {
    "city": "res://mika_motion_comic/assets/city.png",
    "mica": "res://mika_motion_comic/assets/mica_balcony.png",
    "news": "res://mika_motion_comic/assets/news.png",
    "magenta": "res://mika_motion_comic/assets/disaster_magenta.png",
    "red": "res://mika_motion_comic/assets/disaster_red.png",
    "talk": "res://mika_motion_comic/assets/conversation.png",
    "ship_front": "res://mika_motion_comic/assets/ship_front.png",
    "ship_rear": "res://mika_motion_comic/assets/ship_rear.png",
    "cockpit": "res://mika_motion_comic/assets/cockpit.png",
}

@onready var viewport_frame: Control = $ViewportFrame
@onready var picture: Control = $ViewportFrame/Picture
@onready var layers: Array[ColorRect] = [
    $ViewportFrame/Picture/Base,
    $ViewportFrame/Picture/Panel,
    $ViewportFrame/Picture/Transition,
]
@onready var fade_rect: ColorRect = $ViewportFrame/Picture/Fade
@onready var caption_layer: TextureRect = $ViewportFrame/CaptionLayer

var elapsed: float = 0.0
var playing: bool = false
var textures: Dictionary = {}
var materials: Array[ShaderMaterial] = []
var caption_textures: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    viewport_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for key in IMAGE_FILES:
        textures[key] = load(IMAGE_FILES[key]) as Texture2D
    for layer in layers:
        layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var mat := ShaderMaterial.new()
        mat.shader = COMIC_SHADER
        layer.material = mat
        materials.append(mat)
    fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    caption_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for cue in CAPTION_CUES:
        caption_textures[cue["image"]] = load(cue["image"]) as Texture2D
    resized.connect(_fit_view)
    _fit_view()
    _render_time(elapsed)
    if autoplay:
        play()

func _fit_view() -> void:
    # Fit a 16:9 picture into a host control of ANY aspect ratio, without warping.
    var scale_factor: float = min(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
    if scale_factor <= 0.0:
        return
    viewport_frame.size = BASE_SIZE * scale_factor
    viewport_frame.position = (size - viewport_frame.size) * 0.5
    picture.position = Vector2.ZERO
    picture.size = viewport_frame.size
    caption_layer.size = viewport_frame.size

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
    caption_layer.visible = false
    if not show_lettering:
        return
    for cue in CAPTION_CUES:
        var start_time: float = cue["start"]
        var end_time: float = cue["end"]
        if t < start_time or t >= end_time:
            continue
        var fade_in: float = minf(0.24, (end_time - start_time) * 0.18)
        var fade_out: float = minf(0.25, (end_time - start_time) * 0.18)
        var a: float = clampf(minf(minf((t - start_time) / maxf(0.01, fade_in),
                (end_time - t) / maxf(0.01, fade_out)), 1.0), 0.0, 1.0)
        a = a * a * (3.0 - 2.0 * a)
        caption_layer.texture = caption_textures[cue["image"]]
        caption_layer.modulate = Color(1.0, 1.0, 1.0, a)
        caption_layer.position = Vector2((1.0 - a) * 18.0 * (viewport_frame.size.x / BASE_SIZE.x), 0.0)
        caption_layer.visible = true
        break
