extends Control
class_name MikaSinglePageComicIntro
## A lightweight motion-comic player driven by one complete comic page.
## The original nine-image player remains available as MotionComicIntro.tscn.

signal finished

@export var show_lettering: bool = true
@export_file("*.json") var editable_cues_path: String = "res://mika_motion_comic/cues.json"
@export var autoplay: bool = true
@export var loop_playback: bool = false
@export_range(0.1, 3.0, 0.05) var playback_speed: float = 1.0

const DURATION: float = 71.0
const BASE_SIZE := Vector2(1280.0, 720.0)
const PAGE_SIZE := Vector2(2480.0, 3508.0)
const PAGE_TEXTURE: Texture2D = preload("res://mika_motion_comic/assets/pages/ch01_p01_full.jpg")
const PAGE_SHADER: Shader = preload("res://mika_motion_comic/shaders/single_page_comic.gdshader")

# Each entry is [time, page focus x, page focus y, visible page height].
# Paired keys create a calm drift while short gaps create panel transitions.
const CAMERA_KEYS: Array[Vector4] = [
	Vector4(0.0, 0.31, 0.155, 0.245),
	Vector4(8.9, 0.36, 0.165, 0.225),
	Vector4(9.7, 0.79, 0.155, 0.215),
	Vector4(12.9, 0.77, 0.165, 0.205),
	Vector4(13.7, 0.245, 0.405, 0.225),
	Vector4(20.0, 0.285, 0.42, 0.205),
	Vector4(20.9, 0.59, 0.405, 0.205),
	Vector4(25.8, 0.62, 0.42, 0.19),
	Vector4(26.6, 0.845, 0.41, 0.195),
	Vector4(35.3, 0.82, 0.43, 0.185),
	Vector4(36.4, 0.255, 0.615, 0.205),
	Vector4(46.7, 0.29, 0.625, 0.19),
	Vector4(47.6, 0.73, 0.615, 0.215),
	Vector4(55.5, 0.68, 0.625, 0.195),
	Vector4(56.5, 0.295, 0.845, 0.245),
	Vector4(62.0, 0.36, 0.855, 0.225),
	Vector4(62.9, 0.79, 0.845, 0.225),
	Vector4(71.0, 0.77, 0.855, 0.205),
]

@onready var page: ColorRect = $Page
@onready var fade: ColorRect = $Fade
@onready var lettering: MikaComicLettering = $AdaptiveLettering

var elapsed: float = 0.0
var playing: bool = false
var caption_cues: Array = []
var page_material: ShaderMaterial

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lettering.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_material = ShaderMaterial.new()
	page_material.shader = PAGE_SHADER
	page_material.set_shader_parameter("artwork", PAGE_TEXTURE)
	page_material.set_shader_parameter("page_aspect", PAGE_SIZE.x / PAGE_SIZE.y)
	page.material = page_material
	_load_caption_cues()
	resized.connect(_fit_view)
	_fit_view()
	_render_time(elapsed)
	if autoplay:
		play()

func _load_caption_cues() -> void:
	if not FileAccess.file_exists(editable_cues_path):
		push_warning("Single-page prologue has no caption cue file: " + editable_cues_path)
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(editable_cues_path))
	if data is Array:
		caption_cues = data

func _fit_view() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	page_material.set_shader_parameter("viewport_aspect", size.x / size.y)
	_render_time(elapsed)

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

func get_camera_state() -> Vector3:
	var state := _camera_at(elapsed)
	return Vector3(state.x, state.y, state.z)

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

static func _smooth(value: float) -> float:
	var x := clampf(value, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func _camera_at(time: float) -> Vector3:
	for index in range(CAMERA_KEYS.size() - 1):
		var current := CAMERA_KEYS[index]
		var following := CAMERA_KEYS[index + 1]
		if time <= following.x:
			var amount := _smooth(inverse_lerp(current.x, following.x, time))
			return Vector3(
				lerpf(current.y, following.y, amount),
				lerpf(current.z, following.z, amount),
				lerpf(current.w, following.w, amount))
	var last := CAMERA_KEYS[CAMERA_KEYS.size() - 1]
	return Vector3(last.y, last.z, last.w)

func _render_time(time: float) -> void:
	if not is_instance_valid(page_material):
		return
	var camera := _camera_at(time)
	page_material.set_shader_parameter("focus", Vector2(camera.x, camera.y))
	page_material.set_shader_parameter("crop_height", camera.z)
	var edge_fade := minf(clampf(time / 0.55, 0.0, 1.0), clampf((DURATION - time) / 0.55, 0.0, 1.0))
	fade.color = Color(0.015, 0.006, 0.025, 1.0 - _smooth(edge_fade))
	_render_lettering(time)

func _render_lettering(time: float) -> void:
	if not show_lettering:
		lettering.visible = false
		return
	for cue_value in caption_cues:
		var cue: Dictionary = cue_value
		var start_time := float(cue.get("start", 0.0))
		var end_time := float(cue.get("end", 0.0))
		if time < start_time or time >= end_time:
			continue
		var fade_in := minf(0.28, (end_time - start_time) * 0.18)
		var fade_out := minf(0.32, (end_time - start_time) * 0.18)
		var alpha := clampf(minf((time - start_time) / maxf(fade_in, 0.01), (end_time - time) / maxf(fade_out, 0.01)), 0.0, 1.0)
		var fit_scale := minf(size.x / BASE_SIZE.x, size.y / BASE_SIZE.y)
		var fit_size := BASE_SIZE * fit_scale
		var fit_rect := Rect2((size - fit_size) * 0.5, fit_size)
		var visible_cue: Dictionary = cue.duplicate()
		if has_node("/root/MobileLocale"):
			var localized: Dictionary = get_node("/root/MobileLocale").caption_for(str(cue.get("id", "")))
			for key in ["text", "secondary"]:
				if localized.has(key):
					visible_cue[key] = localized[key]
		lettering.update_cue(visible_cue, fit_rect, false, _smooth(alpha))
		return
	lettering.visible = false
