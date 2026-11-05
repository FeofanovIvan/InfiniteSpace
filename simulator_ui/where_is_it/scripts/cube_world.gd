extends Node3D
## A real Godot 3D cube. No imported meshes/textures/images.
## The camera orbits the stationary box so LEFT/RIGHT and FRONT/BACK
## keep stable meanings in world coordinates.

const ANCHORS = {
	"on": Vector3(0.0, 1.60, 0.0),
	"under": Vector3(0.0, -1.90, 0.0),
	"in": Vector3(0.0, 0.00, 0.0),
	"left": Vector3(-2.30, 0.0, 0.0),
	"right": Vector3(2.30, 0.0, 0.0),
	"above": Vector3(0.0, 2.70, 0.0),
	"front": Vector3(0.0, -0.65, 2.50),
	"behind": Vector3(0.0, 0.70, -2.50),
	"outside": Vector3(2.15, 1.65, 2.15)
}
const PALETTE = {
	"on": Color("71d5ff"),
	"under": Color("ffb86f"),
	"in": Color("8fffc0"),
	"left": Color("be9cff"),
	"right": Color("ff8dcc"),
	"above": Color("ffe18a"),
	"front": Color("ffd06e"),
	"behind": Color("80b5ff"),
	"outside": Color("a7f2ff")
}

var camera: Camera3D
var orbit_yaw := deg_to_rad(24.0)
var orbit_pitch := deg_to_rad(18.0)
var orbit_distance := 11.6
var figures := {}

func _ready() -> void:
	_create_world()
	set_view(orbit_yaw, orbit_pitch)

func set_view(yaw: float, pitch: float) -> void:
	orbit_yaw = yaw
	orbit_pitch = clampf(pitch, deg_to_rad(-16.0), deg_to_rad(62.0))
	var target := Vector3(0, 0.05, 0)
	var cp := cos(orbit_pitch)
	camera.position = target + Vector3(sin(orbit_yaw) * cp, sin(orbit_pitch), cos(orbit_yaw) * cp) * orbit_distance
	camera.look_at(target, Vector3.UP)

func rotate_view(delta_yaw: float, delta_pitch: float) -> void:
	set_view(orbit_yaw + delta_yaw, orbit_pitch + delta_pitch)

func reset_view() -> void:
	set_view(deg_to_rad(24.0), deg_to_rad(18.0))

func project_key(key: String) -> Vector2:
	return camera.unproject_position(ANCHORS[key])

func is_anchor_behind_camera(key: String) -> bool:
	return camera.is_position_behind(ANCHORS[key])

func clear_figures() -> void:
	for figure in figures.values():
		figure.queue_free()
	figures.clear()

func reveal(key: String) -> void:
	if figures.has(key):
		return
	var figure := Node3D.new()
	figure.name = "PlacedMikaMarker_" + key
	figure.position = ANCHORS[key]
	add_child(figure)
	figures[key] = figure
	var col: Color = PALETTE[key]
	_add_sphere(figure, Vector3(0, 0.14, 0), 0.17, Color("f7eedb"))
	_add_capsule(figure, Vector3(0, -0.15, 0), 0.27, col)
	_add_sphere(figure, Vector3(0, 0.19, 0.13), 0.038, Color("071628"))
	_add_sphere(figure, Vector3(0.08, 0.19, 0.13), 0.038, Color("071628"))
	_add_box(figure, Vector3(-0.13, -0.29, 0), Vector3(0.07, 0.27, 0.10), col.darkened(0.1))
	_add_box(figure, Vector3(0.13, -0.29, 0), Vector3(0.07, 0.27, 0.10), col.darkened(0.1))
	var pulse := create_tween()
	figure.scale = Vector3(0.06, 0.06, 0.06)
	pulse.tween_property(figure, "scale", Vector3.ONE * 1.12, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(figure, "scale", Vector3.ONE, 0.15)

func _material(col: Color, emissive := false, alpha := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.38
	mat.metallic = 0.12
	if alpha:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		mat.emission_enabled = true
		mat.emission = Color(col.r, col.g, col.b)
		mat.emission_energy_multiplier = 0.65
	return mat

func _add_box(parent: Node3D, pos: Vector3, dims: Vector3, col: Color, emissive := false, alpha := false) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dims
	piece.mesh = mesh
	piece.position = pos
	piece.material_override = _material(col, emissive, alpha)
	parent.add_child(piece)
	return piece

func _add_sphere(parent: Node3D, pos: Vector3, radius: float, col: Color, emissive := false) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	piece.mesh = mesh
	piece.position = pos
	piece.material_override = _material(col, emissive)
	parent.add_child(piece)
	return piece

func _add_capsule(parent: Node3D, pos: Vector3, height: float, col: Color) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.14
	mesh.height = maxf(height, 0.29)
	piece.mesh = mesh
	piece.position = pos
	piece.material_override = _material(col)
	parent.add_child(piece)
	return piece

func _create_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("08172b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b4d9ff")
	env.ambient_light_energy = 0.75
	environment.environment = env
	add_child(environment)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 49.0
	camera.near = 0.05
	camera.far = 90.0
	add_child(camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, 18, -12)
	light.light_color = Color("d3ecff")
	light.light_energy = 1.5
	add_child(light)
	var side_light := OmniLight3D.new()
	side_light.position = Vector3(-3.0, 4.0, 4.0)
	side_light.light_color = Color("7cdaff")
	side_light.light_energy = 1.0
	add_child(side_light)

	# Transparent 3D cube; interior remains visible.
	_add_box(self, Vector3.ZERO, Vector3(2.5, 2.5, 2.5), Color(0.33, 0.75, 1.0, 0.10), false, true)
	var edge_color := Color("83d6ff")
	for x in [-1.25, 1.25]:
		for y in [-1.25, 1.25]:
			_add_box(self, Vector3(x, y, 0), Vector3(0.046, 0.046, 2.5), edge_color, true)
	for x in [-1.25, 1.25]:
		for z in [-1.25, 1.25]:
			_add_box(self, Vector3(x, 0, z), Vector3(0.046, 2.5, 0.046), edge_color, true)
	for y in [-1.25, 1.25]:
		for z in [-1.25, 1.25]:
			_add_box(self, Vector3(0, y, z), Vector3(2.5, 0.046, 0.046), edge_color, true)
	
	# Bright gold triangular marker on the stable FRONT (+Z) face.
	var face_sign := MeshInstance3D.new()
	var tri := PrismMesh.new()
	tri.size = Vector3(0.58, 0.45, 0.08)
	face_sign.mesh = tri
	face_sign.position = Vector3(0, 0.57, 1.30)
	face_sign.rotation_degrees = Vector3(0, 0, 180)
	face_sign.material_override = _material(Color("ffd980"), true)
	add_child(face_sign)

	# Soft perspective grid and a halo beneath the cube.
	for gx in range(-4, 5):
		_add_box(self, Vector3(float(gx), -2.58, 0), Vector3(0.014, 0.014, 9.0), Color("153657"), true)
	for gz in range(-4, 5):
		_add_box(self, Vector3(0, -2.58, float(gz)), Vector3(9.0, 0.014, 0.014), Color("153657"), true)
	_add_sphere(self, Vector3(0, -2.58, 0), 0.07, Color("98dcff"), true)
