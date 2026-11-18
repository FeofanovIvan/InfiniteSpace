extends Node2D
## Actual lit 3D SphereMesh inside a tiny transparent SubViewport.
## The ball is a Sprite2D showing the live 3D render; gameplay position stays 2D.
## No flattened circles or sprite swaps; its cyan circuitry rotates in real 3D.
const CIRCUIT_TEXTURE: Texture2D = preload("res://bubble/ball_play/assets/ball_circuit.png")
var _sphere: MeshInstance3D
var _display: Sprite2D
var _clock: float = 0.0

func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.name = "Transparent160pxThreeDimensionalBall"
	viewport.size = Vector2i(160,160)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	_sphere = MeshInstance3D.new()
	_sphere.name = "LitCircuitSphereMesh"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	_sphere.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.46,0.88,1.0)
	material.albedo_texture = CIRCUIT_TEXTURE
	material.metallic = 0.44
	material.roughness = 0.27
	material.emission_enabled = true
	material.emission = Color(0.09,0.53,0.83)
	material.emission_energy_multiplier = 0.44
	_sphere.material_override = material
	root.add_child(_sphere)
	var light := DirectionalLight3D.new()
	light.name = "SoftTopLeftLight"
	light.rotation_degrees = Vector3(-35,-28,0)
	light.light_energy = 1.8
	root.add_child(light)
	var fill := OmniLight3D.new()
	fill.name = "BlueRimFill"
	fill.position = Vector3(-2.5,-1.5,2.3)
	fill.light_color = Color(0.36,0.90,1.0)
	fill.light_energy = 1.1
	root.add_child(fill)
	var camera := Camera3D.new()
	camera.position = Vector3(0,0,3.6)
	camera.fov = 42.0
	root.add_child(camera)
	camera.current = true
	_display = Sprite2D.new()
	_display.name = "Live3DTexture"
	_display.texture = viewport.get_texture()
	_display.scale = Vector2.ONE * 0.35
	add_child(_display)

func _process(delta: float) -> void:
	_clock += delta
	if is_instance_valid(_sphere):
		_sphere.rotation = Vector3(0.24+sin(_clock*0.62)*0.12,_clock*0.75,0.11)
	if is_instance_valid(_display):
		_display.scale = Vector2.ONE * 0.35 # Depth scaling comes ONLY from the shared parent factor.
