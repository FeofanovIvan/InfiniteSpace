extends Control
## Seven-location hyperspace chart for the prototype.
## Small rotating suns are used as the main selectable nodes.
signal closed
signal travel_requested(region_id: String, travel_direction: Vector2)

const CATALOG_PATH: String = "res://atlas/world_atlas.json"
const CLOSE_ICON: Texture2D = preload("res://assets/ui/close.png")
const SUN_TEXTURES: Array[Texture2D] = [
	preload("res://assets/atlas/suns/sun_0.png"),
	preload("res://assets/atlas/suns/sun_1.png"),
	preload("res://assets/atlas/suns/sun_2.png"),
	preload("res://assets/atlas/suns/sun_3.png"),
	preload("res://assets/atlas/suns/sun_4.png"),
	preload("res://assets/atlas/suns/sun_5.png"),
	preload("res://assets/atlas/suns/sun_6.png")
]
const GALAXY_ART: Array[Texture2D] = [
	preload("res://assets/ui/galaxy_1.png"),
	preload("res://assets/ui/galaxy_2.png"),
	preload("res://assets/ui/galaxy_3.png"),
	preload("res://assets/ui/galaxy_4.png"),
	preload("res://assets/ui/galaxy_5.png"),
	preload("res://assets/ui/galaxy_6.png")
]
const POSITIONS: Array[Vector2] = [
	Vector2(0.15, 0.34), Vector2(0.35, 0.20), Vector2(0.67, 0.18),
	Vector2(0.84, 0.49), Vector2(0.70, 0.76), Vector2(0.35, 0.78),
	Vector2(0.49, 0.47)
]
const EDGES: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3),
	Vector2i(3, 4), Vector2i(4, 5), Vector2i(5, 6)
]
const SIZE_FACTORS: Array[float] = [0.82, 0.72, 0.76, 0.86, 0.80, 0.74, 0.94]

var _systems: Array = []
var _current: String = "mw"
var _buttons: Array[TextureButton] = []
var _halos: Array[TextureRect] = []
var _labels: Array[Label] = []
var _positions: Array[Vector2] = []
var _stars: Array[Vector2] = []
var _node_size: float = 74.0
var _close: Button
var _title: Label
var _footer: Label
var _scale_factor: float = 1.0
var _time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(true)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if parsed is Dictionary:
		_systems = parsed.get("systems", [])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20391372
	for i in range(360):
		_stars.append(Vector2(rng.randf(), rng.randf()))
	for i in range(mini(7, _systems.size())):
		var halo: TextureRect = TextureRect.new()
		halo.texture = GALAXY_ART[i] if i < 6 else SUN_TEXTURES[6]
		halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		halo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		halo.modulate.a = 0.46 if i < 6 else 0.24
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(halo)
		_halos.append(halo)
		var button: TextureButton = TextureButton.new()
		button.name = "Destination_" + str(_systems[i]["id"])
		button.texture_normal = SUN_TEXTURES[i]
		button.texture_hover = SUN_TEXTURES[i]
		button.texture_pressed = SUN_TEXTURES[i]
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.tooltip_text = str(_systems[i]["name_en"])
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_travel_to.bind(i))
		add_child(button)
		_buttons.append(button)
		var label: Label = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = str(_systems[i]["name_en"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.04, 0.12, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(label)
		_labels.append(label)
	_title = Label.new()
	_title.text = "HYPERSPACE MAP"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color(0.72, 0.90, 1.0))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_footer = Label.new()
	_footer.text = "CHOOSE A STAR · ALL DESTINATIONS OPEN FOR TESTING"
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_theme_font_size_override("font_size", 13)
	_footer.add_theme_color_override("font_color", Color(0.50, 0.79, 0.94))
	_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_footer)
	_close = Button.new()
	_close.icon = CLOSE_ICON
	_close.expand_icon = true
	_close.focus_mode = Control.FOCUS_NONE
	_close.tooltip_text = "Back to flight"
	_close.pressed.connect(hide_map)
	add_child(_close)
	resized.connect(_reflow)
	_reflow()

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	for i in range(_buttons.size()):
		if i < _buttons.size() - 1:
			_buttons[i].rotation = _time * (0.16 + float(i) * 0.03)
			_halos[i].rotation = -_time * (0.05 + float(i) * 0.012)
		else:
			_buttons[i].rotation = 0.0
			_halos[i].rotation = 0.0

func open_map(view: Vector2, from_region: String = "mw") -> void:
	_current = from_region
	size = view
	visible = true
	_reflow()

func hide_map() -> void:
	visible = false
	closed.emit()

func _travel_to(i: int) -> void:
	if i < 0 or i >= _systems.size():
		return
	var id: String = str(_systems[i]["id"])
	if id == _current:
		hide_map()
		return
	var from_pos: Vector2 = POSITIONS[0]
	for j in range(_systems.size()):
		if str(_systems[j]["id"]) == _current:
			from_pos = POSITIONS[j]
			break
	var direction: Vector2 = (POSITIONS[i] - from_pos).normalized()
	if direction.length_squared() < 0.1:
		direction = Vector2.RIGHT
	visible = false
	travel_requested.emit(id, direction)

func _reflow() -> void:
	if _buttons.is_empty():
		return
	var view: Vector2 = size
	_scale_factor = clampf(minf(view.x / 900.0, view.y / 540.0), 0.50, 1.18)
	_node_size = 74.0 * _scale_factor
	_positions.clear()
	for i in range(_buttons.size()):
		var pos: Vector2 = Vector2(view.x * POSITIONS[i].x, view.y * POSITIONS[i].y)
		_positions.append(pos)
		var size_main: Vector2 = Vector2.ONE * (_node_size * SIZE_FACTORS[i])
		_buttons[i].position = pos - size_main * 0.5
		_buttons[i].size = size_main
		_buttons[i].pivot_offset = size_main * 0.5
		_halos[i].size = size_main * 1.85
		_halos[i].position = pos - _halos[i].size * 0.5
		_halos[i].pivot_offset = _halos[i].size * 0.5
		_labels[i].position = pos + Vector2(-118.0 * _scale_factor, size_main.y * 0.56)
		_labels[i].size = Vector2(236.0 * _scale_factor, 25.0)
		_labels[i].add_theme_font_size_override("font_size", maxi(11, int(15.0 * _scale_factor)))
		var selected: bool = str(_systems[i]["id"]) == _current
		_buttons[i].modulate = Color(1.0, 1.0, 1.0, 1.0) if selected else Color(0.92, 0.96, 1.0, 0.92)
		_labels[i].add_theme_color_override("font_color", Color(1.0, 0.88, 0.52) if selected else Color(0.82, 0.92, 1.0))
	_title.position = Vector2(0.0, maxf(2.0, view.y * 0.035))
	_title.size = Vector2(view.x, 32.0)
	_footer.position = Vector2(0.0, view.y - 34.0)
	_footer.size = Vector2(view.x, 30.0)
	_close.size = Vector2.ONE * (50.0 * _scale_factor)
	_close.position = Vector2(view.x - 58.0 * _scale_factor, 6.0 * _scale_factor)
	queue_redraw()

func _draw() -> void:
	var view: Vector2 = size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.004, 0.014, 0.038, 0.98))
	for i in range(_stars.size()):
		var pos: Vector2 = _stars[i] * view
		var alpha: float = 0.18 + float(i % 6) * 0.08
		draw_circle(pos, (0.6 + float(i % 3) * 0.3) * _scale_factor, Color(0.62, 0.79, 1.0, alpha))
	for edge in EDGES:
		var first: Vector2 = _positions[edge.x]
		var last: Vector2 = _positions[edge.y]
		var difference: Vector2 = (last - first).normalized()
		var a: Vector2 = first + difference * _node_size * 0.32
		var b: Vector2 = last - difference * _node_size * 0.32
		draw_line(a, b, Color(0.20, 0.59, 0.96, 0.12), 8.0 * _scale_factor, true)
		draw_line(a, b, Color(0.34, 0.78, 1.0, 0.58), 1.6 * _scale_factor, true)
	for i in range(_positions.size()):
		if str(_systems[i]["id"]) == _current:
			draw_arc(_positions[i], _node_size * 0.44, 0.0, TAU, 70, Color(1.0, 0.82, 0.38), 2.2, true)
		if i == 6:
			draw_arc(_positions[i], _node_size * 0.40, PI * 0.20, PI * 1.8, 45, Color(0.64, 0.94, 1.0), 2.0, true)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide_map()
		get_viewport().set_input_as_handled()
