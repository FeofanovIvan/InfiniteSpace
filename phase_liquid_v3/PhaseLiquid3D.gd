extends Control
## One connected living liquid 3D mesh displayed in a 2D UI via SubViewport.
## 3D shape is animated by a shader; no disconnected spheres or separate appendage meshes.
## Intended for InfiniteSpace GL Compatibility (Godot 4.7.1).

@export_range(0.1, 2.5, 0.01) var flow_speed: float = 0.85:
    set(value):
        flow_speed = value
        _parameter("flow_speed", value)
@export_range(0.0, 1.0, 0.01) var spiral_strength: float = 0.82:
    set(value):
        spiral_strength = value
        _parameter("spiral_strength", value)
@export_range(0.0, 1.3, 0.01) var lobe_strength: float = 0.92:
    set(value):
        lobe_strength = value
        _parameter("lobe_strength", value)
@export_range(0.5, 1.5, 0.01) var gravity_weight: float = 1.0:
    set(value):
        gravity_weight = value
        _parameter("gravity_weight", value)
@export_range(0.0, 2.0, 0.01) var glow_strength: float = 0.9:
    set(value):
        glow_strength = value
        _parameter("glow_strength", value)
@export_range(0.55, 0.98, 0.01) var glass_opacity: float = 0.84:
    set(value):
        glass_opacity = value
        _parameter("glass_opacity", value)
@export_range(0.0, 6.28, 0.01) var color_shift: float = 0.0:
    set(value):
        color_shift = value
        _parameter("color_shift", value)

const SHADER_PATH: String = "res://phase_liquid_v3/phase_morph_3d.gdshader"
@export var high_quality: bool = false  # false for mobiles; true for desktop demo

var _viewport: SubViewport
var _model: MeshInstance3D
var _material: ShaderMaterial
var _texture: TextureRect
var _clock: float = 0.0
var _mode: String = "idle"
var _talk_level: float = 0.0
var _voice_level: float = -1.0
var _duration: float = -1.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    _make_renderer()
    set_process(true)

func _make_renderer() -> void:
    _viewport = SubViewport.new()
    _viewport.name = "LiquidTo2D_Transparent3D"
    _viewport.size = Vector2i(440, 600) if high_quality else Vector2i(320, 440)
    _viewport.transparent_bg = true
    _viewport.own_world_3d = true
    _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _viewport.msaa_3d = Viewport.MSAA_2X
    add_child(_viewport)

    var root := Node3D.new()
    root.name = "PhaseLiquidWorld"
    _viewport.add_child(root)

    var environment_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.0, 0.0, 0.0)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.43, 0.58, 0.82)
    environment.ambient_light_energy = 0.65
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
    environment_node.environment = environment
    root.add_child(environment_node)

    _model = MeshInstance3D.new()
    _model.name = "OneContinuousPhaseOrganism"
    _model.mesh = _make_connected_mesh()
    _model.custom_aabb = AABB(Vector3(-4.0, -0.5, -4.0), Vector3(8.0, 6.5, 8.0))
    _model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _material = ShaderMaterial.new()
    _material.shader = load(SHADER_PATH) as Shader
    _model.material_override = _material
    root.add_child(_model)

    _light(root, Vector3(-4.2, 6.5, 5.2), Color(0.65, 0.94, 1.0), 2.0)
    _light(root, Vector3(4.0, 3.8, 2.4), Color(0.93, 0.52, 1.0), 1.45)
    _light(root, Vector3(-2.0, 3.0, -5.0), Color(0.20, 0.81, 0.98), 1.2)

    var camera := Camera3D.new()
    camera.name = "3D_Camera_for_2D_dialogue"
    root.add_child(camera)
    camera.position = Vector3(2.45, 3.0, 9.0)
    camera.look_at(Vector3(0.0, 2.4, 0.0), Vector3.UP)
    camera.fov = 33.0
    camera.current = true

    _texture = TextureRect.new()
    _texture.name = "TransparentLiquidPortrait"
    _texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_texture)
    _texture.texture = _viewport.get_texture()

    _parameter("flow_speed", flow_speed)
    _parameter("spiral_strength", spiral_strength)
    _parameter("lobe_strength", lobe_strength)
    _parameter("gravity_weight", gravity_weight)
    _parameter("glow_strength", glow_strength)
    _parameter("glass_opacity", glass_opacity)
    _parameter("color_shift", color_shift)
    _parameter("speech_level", 0.0)
    _parameter("morph_clock", 0.0)

func _light(parent: Node3D, position_3d: Vector3, tint: Color, energy: float) -> void:
    var light := OmniLight3D.new()
    light.position = position_3d
    light.light_color = tint
    light.light_energy = energy
    light.omni_range = 16.0
    light.shadow_enabled = false
    parent.add_child(light)

func _make_connected_mesh() -> ArrayMesh:
    # One vertex topology, not metaball children. GPU bulges remain fused.
    var segments: int = 128 if high_quality else 80
    var height_rings: int = 89 if high_quality else 61
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var uvs := PackedVector2Array()
    var indices := PackedInt32Array()

    # One bottom pole, then rings, then one top pole. Thus watertight.
    vertices.append(Vector3(0.0, 0.0, 0.0))
    normals.append(Vector3.DOWN)
    uvs.append(Vector2(0.0, 0.0))
    for i in range(1, height_rings - 1):
        var h: float = float(i) / float(height_rings - 1)
        for j in range(segments):
            var a: float = TAU * float(j) / float(segments)
            vertices.append(Vector3(cos(a), 5.1 * h, sin(a)))
            normals.append(Vector3(cos(a), 0.0, sin(a)))
            uvs.append(Vector2(float(j) / float(segments), h))
    var top_index: int = vertices.size()
    vertices.append(Vector3(0.0, 5.1, 0.0))
    normals.append(Vector3.UP)
    uvs.append(Vector2(0.0, 1.0))

    for j in range(segments):
        var nxt: int = (j + 1) % segments
        indices.append_array(PackedInt32Array([0, 1 + j, 1 + nxt]))
    for i in range(height_rings - 3):
        for j in range(segments):
            var nxt: int = (j + 1) % segments
            var a: int = 1 + i * segments + j
            var b: int = 1 + (i + 1) * segments + j
            var c: int = 1 + i * segments + nxt
            var d: int = 1 + (i + 1) * segments + nxt
            indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
    for j in range(segments):
        var nxt: int = (j + 1) % segments
        var a: int = 1 + (height_rings - 3) * segments + j
        var c: int = 1 + (height_rings - 3) * segments + nxt
        indices.append_array(PackedInt32Array([a, top_index, c]))

    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func _process(delta: float) -> void:
    _clock += delta
    if _duration >= 0.0:
        _duration -= delta
        if _duration <= 0.0:
            set_speech_state("idle")
            _duration = -1.0

    var target: float = 0.0
    match _mode:
        "talk_soft":
            target = 0.41 + 0.09 * sin(_clock * 4.1)
        "talk_active":
            target = 0.75 + 0.19 * sin(_clock * 5.3)
        "emotion_peak":
            target = 0.96
        _:
            target = 0.07
    if _voice_level >= 0.0:
        target = maxf(target, _voice_level)
    _talk_level = move_toward(_talk_level, clampf(target, 0.0, 1.0), delta * 1.35)
    _parameter("speech_level", _talk_level)
    _parameter("morph_clock", _clock)
    if _model != null:
        _model.rotation.y = sin(_clock * 0.17) * 0.11
        _model.rotation.z = sin(_clock * 0.28) * 0.013

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        speak_for(2.0, 0.85)
    elif event is InputEventScreenTouch and event.pressed:
        speak_for(2.0, 0.85)

func set_speech_state(state: String) -> void:
    if state in ["idle", "talk_soft", "talk_active", "emotion_peak"]:
        _mode = state
        _duration = -1.0

func speak_for(seconds: float = 2.0, intensity: float = 0.8) -> void:
    _mode = "emotion_peak" if intensity >= 0.90 else ("talk_active" if intensity >= 0.60 else "talk_soft")
    _duration = maxf(0.1, seconds)

func set_voice_energy(value: float) -> void:
    # Call this with normalized 0..1 voice activity, or -1 to use auto rhythm.
    _voice_level = -1.0 if value < 0.0 else clampf(value, 0.0, 1.0)

func stop_talking() -> void:
    set_speech_state("idle")
    _voice_level = -1.0

func set_flow(value: float) -> void:
    flow_speed = value

func set_spiral(value: float) -> void:
    spiral_strength = value

func set_lobes(value: float) -> void:
    lobe_strength = value

func set_glow(value: float) -> void:
    glow_strength = value

func set_gravity(value: float) -> void:
    gravity_weight = value

func set_opacity(value: float) -> void:
    glass_opacity = value

func _parameter(key: String, value: float) -> void:
    if _material != null:
        _material.set_shader_parameter(key, value)
