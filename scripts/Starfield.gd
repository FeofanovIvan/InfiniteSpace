extends Node2D
## A deterministic, very large, cyclic star map.
## No star Node2D per star: a sector is one batched MultiMeshInstance2D.
## The spacecraft does NOT move in world coordinates. We scroll this field instead.

const CHUNK_SIZE: int = 512
const WORLD_SECTORS: int = 16384
const WORLD_SPAN: float = float(CHUNK_SIZE * WORLD_SECTORS)
const STAR_IMAGE: Texture2D = preload("res://assets/star_core.png")

# Three VERY distant populations. No planets, nearby dust, galaxies or nebulae.
# Tweak SPEED_RATIOS to adjust the feeling of depth.
const SPEED_RATIOS: Array[float] = [0.12, 0.38, 0.82]
const STAR_COUNTS: Array[int] = [205, 78, 20]
const POPULATION_OPACITY: Array[float] = [0.62, 0.82, 0.97]

var _offset_x: Array[float] = [0.0, 0.0, 0.0]
var _offset_y: Array[float] = [0.0, 0.0, 0.0]
var _layers: Array = []
var _slots: Array = []
var _keys: Array = []
var _columns: int = 0
var _rows: int = 0
var _star_quad: QuadMesh
var _screen_size: Vector2 = Vector2(1280, 720)
var _camera_look: Vector2 = Vector2.ZERO


func _ready() -> void:
	_star_quad = QuadMesh.new()
	_star_quad.size = Vector2(32.0, 32.0)
	for layer_index in range(SPEED_RATIOS.size()):
		var layer_root := Node2D.new()
		layer_root.name = "DistantStars_%d" % (layer_index + 1)
		add_child(layer_root)
		_layers.append(layer_root)
		_slots.append([])
		_keys.append([])
	resize_field(get_viewport_rect().size)


func resize_field(view_size: Vector2) -> void:
	_screen_size = view_size
	var new_columns: int = int(ceil(_screen_size.x / float(CHUNK_SIZE))) + 2
	var new_rows: int = int(ceil(_screen_size.y / float(CHUNK_SIZE))) + 2
	if new_columns == _columns and new_rows == _rows:
		return
	_columns = new_columns
	_rows = new_rows
	for layer_index in range(_layers.size()):
		var root: Node2D = _layers[layer_index]
		for child in root.get_children():
			child.queue_free()
		var fresh_slots: Array = []
		var fresh_keys: Array = []
		for _slot_index in range(_columns * _rows):
			var cell := MultiMeshInstance2D.new()
			cell.texture = STAR_IMAGE
			root.add_child(cell)
			fresh_slots.append(cell)
			fresh_keys.append(Vector2i(-1, -1))
		_slots[layer_index] = fresh_slots
		_keys[layer_index] = fresh_keys
	_update_all_positions()


func advance(screen_flight_displacement: Vector2) -> void:
	if screen_flight_displacement.length_squared() < 0.000001:
		return
	for index in range(SPEED_RATIOS.size()):
		var factor: float = SPEED_RATIOS[index]
		_offset_x[index] = fposmod(_offset_x[index] + screen_flight_displacement.x * factor, WORLD_SPAN)
		_offset_y[index] = fposmod(_offset_y[index] + screen_flight_displacement.y * factor, WORLD_SPAN)
	_update_all_positions()


func set_camera_look(camera_offset: Vector2) -> void:
	# Camera is at ship_address + camera_offset. Wrap before sector lookup
	# so camera exploration remains stable even after very long drags.
	if _camera_look == camera_offset:
		return
	_camera_look = camera_offset
	_update_all_positions()


func reset_field() -> void:
	for index in range(SPEED_RATIOS.size()):
		_offset_x[index] = 0.0
		_offset_y[index] = 0.0
	_update_all_positions()


func _update_all_positions() -> void:
	for layer_index in range(_layers.size()):
		var ratio: float = SPEED_RATIOS[layer_index]
		var ox: float = fposmod(_offset_x[layer_index] + _camera_look.x * ratio, WORLD_SPAN)
		var oy: float = fposmod(_offset_y[layer_index] + _camera_look.y * ratio, WORLD_SPAN)
		var chunk_x: int = int(floor(ox / float(CHUNK_SIZE)))
		var chunk_y: int = int(floor(oy / float(CHUNK_SIZE)))
		var fragment_x: float = fposmod(ox, float(CHUNK_SIZE))
		var fragment_y: float = fposmod(oy, float(CHUNK_SIZE))
		var layer_nodes: Array = _slots[layer_index]
		var layer_keys: Array = _keys[layer_index]
		for yy in range(_rows):
			for xx in range(_columns):
				var slot_index: int = yy * _columns + xx
				var cell: MultiMeshInstance2D = layer_nodes[slot_index]
				cell.position = Vector2(float(xx * CHUNK_SIZE) - fragment_x, float(yy * CHUNK_SIZE) - fragment_y)
				var sector := Vector2i(posmod(chunk_x + xx, WORLD_SECTORS), posmod(chunk_y + yy, WORLD_SECTORS))
				if layer_keys[slot_index] != sector:
					cell.multimesh = _create_sector(layer_index, sector)
					layer_keys[slot_index] = sector


func _create_sector(layer_index: int, sector: Vector2i) -> MultiMesh:
	var random := RandomNumberGenerator.new()
	# Seed is reproducible, using only bounded integers, so there are no huge coordinates.
	random.seed = int(sector.x) * 73856093 + int(sector.y) * 19349663 + (layer_index + 1) * 83492791 + 1072589
	var count: int = STAR_COUNTS[layer_index]
	var group := MultiMesh.new()
	group.transform_format = MultiMesh.TRANSFORM_2D
	group.use_colors = true
	group.mesh = _star_quad
	group.instance_count = count

	for index in range(count):
		var x: float = random.randf_range(0.0, float(CHUNK_SIZE))
		var y: float = random.randf_range(0.0, float(CHUNK_SIZE))
		var category: float = random.randf()
		var radius_scale: float
		var brightness: float
		if category < 0.79:
			radius_scale = random.randf_range(0.19, 0.31)
			brightness = random.randf_range(0.30, 0.68)
		elif category < 0.978:
			radius_scale = random.randf_range(0.32, 0.52)
			brightness = random.randf_range(0.63, 0.96)
		else:
			radius_scale = random.randf_range(0.49, 0.70)
			brightness = random.randf_range(0.74, 0.90)
		# Small cool white stars dominate, with a realistic minority of warm stars.
		var palette_roll: float = random.randf()
		var tint: Color
		if palette_roll < 0.54:
			tint = Color(0.84, 0.92, 1.0)
		elif palette_roll < 0.75:
			tint = Color(0.63, 0.79, 1.0)
		elif palette_roll < 0.91:
			tint = Color(1.0, 0.96, 0.81)
		elif palette_roll < 0.976:
			tint = Color(1.0, 0.77, 0.53)
		else:
			tint = Color(1.0, 0.59, 0.58)
		var transform := Transform2D.IDENTITY
		transform.x = Vector2(radius_scale, 0.0)
		transform.y = Vector2(0.0, radius_scale)
		transform.origin = Vector2(x, y)
		group.set_instance_transform_2d(index, transform)
		group.set_instance_color(index, Color(tint.r, tint.g, tint.b, brightness * POPULATION_OPACITY[layer_index]))
	return group
