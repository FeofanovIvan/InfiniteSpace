extends Control
class_name MikaStoryPageTwoPanels
## The second PDF is stored as one compressed JPG page, not a video.
## Story beats advance by player input; no new cutscene timings are introduced.

signal sequence_completed

const PAGE_TEXTURE: Texture2D = preload("res://mika_motion_comic/assets/pages/ch01_p02_story.jpg")
const PAGE_SHADER: Shader = preload("res://mika_motion_comic/shaders/single_page_comic.gdshader")
const PAGE_SIZE: Vector2 = Vector2(2481.0, 3508.0)

# Page-relative camera positions for the five panels of 1-2.pdf.
# Values: focus x, focus y, visible page height. Each frame uses the same
# existing shader as chapter one's timed page; only the cue is event-driven.
const CAMERA: Dictionary = {
	"wormhole": Vector3(0.500, 0.161, 0.350),
	"earth_view": Vector3(0.245, 0.462, 0.208),
	"simulator": Vector3(0.754, 0.462, 0.208),
	"earth_descent": Vector3(0.250, 0.801, 0.233),
	"earth_arrival": Vector3(0.756, 0.801, 0.233),
}

var _artwork: ColorRect
var _material: ShaderMaterial
var _sequence: Array[String] = []
var _index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	visible = false
	_artwork = ColorRect.new()
	_artwork.name = "PageTwoSingleCompressedSheet"
	_artwork.color = Color.WHITE
	_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_artwork)
	_material = ShaderMaterial.new()
	_material.shader = PAGE_SHADER
	_material.set_shader_parameter("artwork", PAGE_TEXTURE)
	_material.set_shader_parameter("page_aspect", PAGE_SIZE.x / PAGE_SIZE.y)
	_artwork.material = _material
	resized.connect(_update_camera)
	_update_camera()


func begin_sequence(panels: Array) -> void:
	_sequence.clear()
	for panel_value in panels:
		var panel_id: String = str(panel_value)
		if not CAMERA.has(panel_id):
			push_error("Unknown page-two story panel: " + panel_id)
			continue
		_sequence.append(panel_id)
	_index = 0
	visible = not _sequence.is_empty()
	_update_camera()
	if _sequence.is_empty():
		sequence_completed.emit()


func end_sequence() -> void:
	visible = false
	_sequence.clear()
	_index = 0


func current_panel_id() -> String:
	if not visible or _sequence.is_empty():
		return ""
	return _sequence[_index]


func advance_panel() -> void:
	if not visible or _sequence.is_empty():
		return
	if _index + 1 < _sequence.size():
		_index += 1
		_update_camera()
		return
	end_sequence()
	sequence_completed.emit()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		advance_panel()
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_panel()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey):
		return
	if event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		advance_panel()
		get_viewport().set_input_as_handled()


func _update_camera() -> void:
	if _material == null:
		return
	if size.x > 1.0 and size.y > 1.0:
		_material.set_shader_parameter("viewport_aspect", size.x / size.y)
	if _sequence.is_empty():
		return
	var camera: Vector3 = CAMERA[_sequence[_index]]
	_material.set_shader_parameter("focus", Vector2(camera.x, camera.y))
	_material.set_shader_parameter("crop_height", camera.z)
