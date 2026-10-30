extends Node2D
## v45: Five *native* translucent spacecraft classes belong to SMC ONLY.
## No cross-system transfers until inter-system mechanics are designed.
const WorldAddress = preload("res://scripts/WorldPosition.gd")
const INNER_LIGHT: Shader = preload("res://shaders/alien_inner_light.gdshader")
const ShipMotionFX = preload("res://scripts/ShipMotionFX.gd")
const HOME_SYSTEM: String = "smc"
const ALIEN_ART: Array[Texture2D] = [
    preload("res://assets/story/alien_ship_01.png"),
    preload("res://assets/story/alien_ship_02.png"),
    preload("res://assets/story/alien_ship_03.png"),
    preload("res://assets/story/alien_ship_04.png"),
    preload("res://assets/story/alien_ship_05.png")
]
# In original v44 assets: 01 = peach/ivory vessel; 02 = azure blade;
# 03 = golden cloud barge; 04 = red/blue dual-wing; 05 = pearl flower.
# Role-specific movement, turn rates, station dwell and inner light palettes.
const SHIP_CLASSES: Array[Dictionary] = [
    {"role": "liner", "label": "Passenger Liner", "speed": 75.0, "turn": 1.45, "size": 0.105, "dwell": 3.2, "light": Color(1.0, 0.83, 0.48), "glow": 0.60},
    {"role": "scout", "label": "Deep-Space Scout", "speed": 163.0, "turn": 3.40, "size": 0.090, "dwell": 0.5, "light": Color(0.35, 0.88, 1.0), "glow": 0.90},
    {"role": "cargo", "label": "Cloud Cargo Carrier", "speed": 53.0, "turn": 0.84, "size": 0.115, "dwell": 4.0, "light": Color(1.0, 0.65, 0.25), "glow": 0.76},
    {"role": "guard", "label": "Twin-Wing Guardian", "speed": 127.0, "turn": 2.85, "size": 0.097, "dwell": 0.8, "light": Color(0.42, 0.72, 1.0), "glow": 0.84},
    {"role": "diplomat", "label": "Pearl Diplomatic Vessel", "speed": 91.0, "turn": 1.65, "size": 0.105, "dwell": 2.5, "light": Color(0.49, 1.0, 0.83), "glow": 0.66}
]
const LOCAL_SHIP_COUNT: int = 7
var _atlas: Node
var _region: String = "mw"
var _ships: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _view: Vector2 = Vector2(1280.0, 720.0)
var _camera_world: Vector2 = Vector2.ZERO
var _time: float = 0.0

func configure(atlas: Node) -> void:
    _atlas = atlas

func set_region(region_id: String) -> void:
    _region = region_id
    for item in _ships:
        var old_image: Sprite2D = item["image"]
        old_image.visible = false
        old_image.queue_free()
    _ships.clear()
    _time = 0.0
    if _region != HOME_SYSTEM:
        visible = false
        set_physics_process(false)
        return
    visible = true
    set_physics_process(true)
    _rng.seed = ("MIKO_SMC_native_fleet_v45").hash()
    var ports: Array[Dictionary] = _available_ports()
    if ports.size() < 2:
        set_physics_process(false)
        return
    # All five shapes are present from the first visit. Two extra vessels
    # use the same native types, never imported ships from other galaxies.
    for i in range(LOCAL_SHIP_COUNT):
        _spawn_native_ship(i % ALIEN_ART.size(), i, ports)
    _update_images()

func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
    _camera_world = Vector2(sector) * WorldAddress.SECTOR_SIZE + local_position + camera_offset
    _update_images()

func resize_view(view: Vector2) -> void:
    _view = view
    _update_images()

func _available_ports() -> Array[Dictionary]:
    var ports: Array[Dictionary] = []
    if _atlas == null:
        return ports
    for body in _atlas.get_navigation_bodies():
        var name: String = str(body.get("name", ""))
        if name == "Sun" or str(body.get("kind", "")) == "moon":
            continue
        ports.append(body)
    return ports

func _spawn_native_ship(art_id: int, index: int, ports: Array[Dictionary]) -> void:
    var ship_class: Dictionary = SHIP_CLASSES[art_id]
    var image: Sprite2D = Sprite2D.new()
    image.name = "SMC_%s_%02d" % [str(ship_class["role"]), index]
    image.texture = ALIEN_ART[art_id]
    image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    image.scale = Vector2.ONE * float(ship_class["size"])
    image.z_index = 1
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = INNER_LIGHT
    material.set_shader_parameter("light_phase", float(index) * 1.37)
    material.set_shader_parameter("brightness", float(ship_class["glow"]))
    material.set_shader_parameter("light_tint", ship_class["light"])
    material.set_shader_parameter("motion_rate", 0.80 + float(index % 4) * 0.13)
    image.material = material
    add_child(image)
    var wake: Node2D = ShipMotionFX.new()
    wake.name = "Wake_%s_%02d" % [str(ship_class["role"]), index]
    wake.z_index = -1
    image.add_child(wake)
    var origin: Vector2 = Vector2(ports[index % ports.size()]["world"])
    origin += Vector2.from_angle(float(index) * 2.4) * (165.0 + 18.0 * float(index % 3))
    image.rotation = (Vector2(ports[(index * 3 + 2) % ports.size()]["world"]) - origin).angle()
    _ships.append({
        "image": image,
        "wake": wake,
        "light_color": ship_class["light"],
        "role": ship_class["role"],
        "label": ship_class["label"],
        "world": origin,
        "velocity": Vector2.ZERO,
        "target_index": (index * 3 + 2) % ports.size(),
        "speed": float(ship_class["speed"]) * _rng.randf_range(0.93, 1.07),
        "turn": float(ship_class["turn"]),
        "dwell": float(ship_class["dwell"]),
        "pause": 0.0,
        "phase": float(index) * 1.91
    })

func _choose_next_port(item: Dictionary, ports: Array[Dictionary]) -> int:
    var n: int = ports.size()
    var current: int = int(item["target_index"]) % n
    match str(item["role"]):
        "liner":
            return (current + 1) % n  # Regular scheduled passenger route
        "cargo":
            return (current + 2) % n  # Longer hops and unloading pauses
        "scout":
            var furthest: int = (current + 1) % n
            var distance_max: float = -1.0
            for i in range(n):
                if i == current:
                    continue
                var distance: float = Vector2(item["world"]).distance_squared_to(Vector2(ports[i]["world"]))
                if distance > distance_max:
                    furthest = i
                    distance_max = distance
            return furthest  # Scouts seek distant sectors
        "guard":
            return (current + 1 if current % 2 == 0 else current + n - 1) % n
        "diplomat":
            return n - 1 if current != n - 1 else _rng.randi_range(0, n - 2)
        _:
            return (current + 1) % n

func _physics_process(delta: float) -> void:
    if _region != HOME_SYSTEM:
        return
    _time += delta
    var ports: Array[Dictionary] = _available_ports()
    if ports.size() < 2:
        return
    for idx in range(_ships.size()):
        var item: Dictionary = _ships[idx]
        var world: Vector2 = item["world"]
        var velocity: Vector2 = item["velocity"]
        if float(item["pause"]) > 0.0:
            item["pause"] = maxf(0.0, float(item["pause"]) - delta)
            velocity = velocity.move_toward(Vector2.ZERO, delta * 170.0)
            item["velocity"] = velocity
            item["world"] = world + velocity * delta
        else:
            var target_index: int = int(item["target_index"]) % ports.size()
            var target: Vector2 = Vector2(ports[target_index]["world"])
            if world.distance_to(target) < 130.0:
                item["target_index"] = _choose_next_port(item, ports)
                item["pause"] = float(item["dwell"])
                item["velocity"] = velocity.move_toward(Vector2.ZERO, delta * 170.0)
            else:
                # +X is the nose of all five top-down SMC PNGs.
                # Steering controls heading; velocity follows that heading,
                # never skidding sideways in hyperspace or on approach.
                var image: Sprite2D = item["image"]
                var desired_heading: float = (target - world).angle()
                image.rotation = lerp_angle(image.rotation, desired_heading, minf(1.0, delta * float(item["turn"])))
                var forward: Vector2 = Vector2.from_angle(image.rotation)
                var alignment: float = maxf(0.13, forward.dot((target - world).normalized()))
                var speed_goal: float = float(item["speed"]) * alignment
                var speed_now: float = move_toward(velocity.length(), speed_goal, delta * 135.0)
                var next_velocity: Vector2 = forward * speed_now
                item["velocity"] = next_velocity
                item["world"] = world + next_velocity * delta
        _ships[idx] = item
    _update_images()

func _update_images() -> void:
    for item in _ships:
        var image: Sprite2D = item["image"]
        var screen: Vector2 = Vector2(item["world"]) - _camera_world + _view * 0.5
        image.position = screen
        var speed_ratio: float = Vector2(item["velocity"]).length() / maxf(1.0, float(item["speed"]))
        var wake: Node2D = item["wake"]
        wake.call("update_motion", _time, speed_ratio, item["light_color"])
        # Cull only offscreen rendering; every ship keeps cruising in world space.
        image.visible = _region == HOME_SYSTEM and screen.x > -240.0 and screen.y > -240.0 and screen.x < _view.x + 240.0 and screen.y < _view.y + 240.0
