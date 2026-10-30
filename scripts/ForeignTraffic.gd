extends Node2D
## v51: Native LMC, SMC and M33 share one anchored landing/takeoff flight controller.
## Native sprites have +X or -X noses encoded per class; ships never move sideways.
const WorldAddress = preload("res://scripts/WorldPosition.gd")
const INNER_LIGHT: Shader = preload("res://shaders/alien_inner_light.gdshader")
const ShipMotionFX = preload("res://scripts/ShipMotionFX.gd")
const HyperjumpMotion = preload("res://scripts/HyperjumpMotion.gd")
const NpcJumpVisual = preload("res://scripts/NpcJumpVisual.gd")
const NATIVE_SYSTEMS: Array[String] = ["lmc", "smc", "m33"]
const ALIEN_ART: Array[Texture2D] = [
    preload("res://assets/story/alien_ship_01.png"),
    preload("res://assets/story/alien_ship_02.png"),
    preload("res://assets/story/alien_ship_03.png"),
    preload("res://assets/story/alien_ship_04.png"),
    preload("res://assets/story/alien_ship_05.png")
]
const SHIP_CLASSES: Array[Dictionary] = [
    {"role":"liner", "label":"Passenger Liner", "speed":75.0, "turn":1.45, "size":0.105, "dwell":3.2, "light":Color(1.0,0.83,0.48), "glow":0.60},
    {"role":"scout", "label":"Deep-Space Scout", "speed":163.0, "turn":3.40, "size":0.090, "dwell":0.5, "light":Color(0.35,0.88,1.0), "glow":0.90},
    {"role":"cargo", "label":"Cloud Cargo Carrier", "speed":53.0, "turn":0.84, "size":0.115, "dwell":4.0, "light":Color(1.0,0.65,0.25), "glow":0.76},
    {"role":"guard", "label":"Twin-Wing Guardian", "speed":127.0, "turn":2.85, "size":0.097, "dwell":0.8, "light":Color(0.42,0.72,1.0), "glow":0.84},
    {"role":"diplomat", "label":"Pearl Diplomatic Vessel", "speed":91.0, "turn":1.65, "size":0.105, "dwell":2.5, "light":Color(0.49,1.0,0.83), "glow":0.66}
]
const M33_ART: Array[Texture2D] = [
    preload("res://assets/story/m33_civilian_01.png"),
    preload("res://assets/story/m33_merchant_02.png"),
    preload("res://assets/story/m33_courier_03.png"),
    preload("res://assets/story/m33_patrol_04.png"),
    preload("res://assets/story/m33_cargo_05.png")
]
# Defined by position on original 1536x1024 sheet. nose_axis: 0 = right, PI = left.
const M33_CLASSES: Array[Dictionary] = [
    {"role":"civilian", "label":"Common Civilian Shuttle", "speed":92.0, "turn":1.65, "size":0.135, "dwell":2.0, "light":Color(1.0,0.84,0.62), "glow":0.56, "nose_axis":PI},
    {"role":"merchant", "label":"Merchant Trading Vessel", "speed":78.0, "turn":1.30, "size":0.148, "dwell":3.4, "light":Color(1.0,0.79,0.45), "glow":0.60, "nose_axis":0.0},
    {"role":"courier", "label":"Fast Diplomatic Courier", "speed":142.0, "turn":2.45, "size":0.128, "dwell":1.3, "light":Color(1.0,0.92,0.70), "glow":0.72, "nose_axis":0.0},
    {"role":"patrol", "label":"Local Patrol Craft", "speed":118.0, "turn":2.9, "size":0.205, "dwell":1.0, "light":Color(0.94,0.82,1.0), "glow":0.66, "nose_axis":0.0},
    {"role":"cargo", "label":"Heavy Freight Carrier", "speed":58.0, "turn":0.92, "size":0.093, "dwell":4.5, "light":Color(1.0,0.70,0.42), "glow":0.52, "nose_axis":PI}
]
# Five ORIGINAL alpha-cut-out sprites from Alien Biomechanical Starship Showcase.png.
# Nose directions are defined per sprite: 0.0 right, PI left.
const LMC_ART: Array[Texture2D] = [
    preload("res://assets/story/lmc_merchant_01.png"),
    preload("res://assets/story/lmc_shuttle_02.png"),
    preload("res://assets/story/lmc_freighter_03.png"),
    preload("res://assets/story/lmc_explorer_04.png"),
    preload("res://assets/story/lmc_escort_05.png")
]
const LMC_CLASSES: Array[Dictionary] = [
    {"role":"merchant", "label":"Biomechanical Merchant", "speed":79.0, "turn":1.25, "size":0.136, "dwell":3.5, "light":Color(1.0,0.59,0.26), "glow":0.48, "nose_axis":PI},
    {"role":"shuttle", "label":"Civilian Biopod Shuttle", "speed":108.0, "turn":1.9, "size":0.160, "dwell":2.1, "light":Color(1.0,0.73,0.34), "glow":0.50, "nose_axis":0.0},
    {"role":"freighter", "label":"Long-range Organic Freighter", "speed":54.0, "turn":0.85, "size":0.097, "dwell":4.8, "light":Color(1.0,0.53,0.17), "glow":0.42, "nose_axis":PI},
    {"role":"explorer", "label":"Biomechanical Explorer", "speed":146.0, "turn":2.9, "size":0.123, "dwell":1.2, "light":Color(1.0,0.76,0.46), "glow":0.61, "nose_axis":0.0},
    {"role":"escort", "label":"Living Escort / Patrol", "speed":123.0, "turn":2.45, "size":0.127, "dwell":1.4, "light":Color(1.0,0.68,0.38), "glow":0.62, "nose_axis":PI}
]
const LOCAL_SHIP_COUNT: int = 7
const APPROACH_RADIUS: float = 250.0
const APPROACH_SECONDS: float = 1.65
const HOVER_SECONDS: float = 0.65
const LANDING_SECONDS: float = 1.20
const TAKEOFF_SECONDS: float = 1.05
const DEPART_SECONDS: float = 1.15
const DEPART_RADIUS: float = 235.0
const CHARGE_SECONDS: float = 0.50
const DASH_SECONDS: float = 0.40
const REENTRY_SECONDS: float = 3.0

var _atlas: Node
var _region: String = "mw"
var _ships: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _view: Vector2 = Vector2(1280.0, 720.0)
var _camera_world: Vector2 = Vector2.ZERO
var _time: float = 0.0

func configure(atlas: Node) -> void:
    _atlas = atlas

func _class_library() -> Array[Dictionary]:
    match _region:
        "lmc":
            return LMC_CLASSES
        "m33":
            return M33_CLASSES
        _:
            return SHIP_CLASSES

func _texture_library() -> Array[Texture2D]:
    match _region:
        "lmc":
            return LMC_ART
        "m33":
            return M33_ART
        _:
            return ALIEN_ART

func set_region(region_id: String) -> void:
    _region = region_id
    for item in _ships:
        var image: Sprite2D = item["image"]
        image.queue_free()
    _ships.clear()
    _time = 0.0
    visible = NATIVE_SYSTEMS.has(_region)
    set_physics_process(visible)
    if not visible:
        return
    _rng.seed = 409517 if _region == "smc" else (117309 if _region == "m33" else 552871)
    var ports: Array[Dictionary] = _available_ports()
    if ports.size() < 2:
        set_physics_process(false)
        return
    var art_count: int = _texture_library().size()
    for i in range(LOCAL_SHIP_COUNT):
        _spawn_ship(i % art_count, i, ports)
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
        if not bool(body.get("inhabited", false)) and str(body.get("kind", "")) != "station":
            continue
        ports.append(body)
    return ports

func _port_world(ports: Array[Dictionary], index: int) -> Vector2:
    return Vector2(ports[posmod(index, ports.size())]["world"])

func _landing_offset(ports: Array[Dictionary], index: int) -> float:
    return 0.0 if str(ports[posmod(index, ports.size())].get("kind", "")) == "station" else 22.0

func _smooth(value: float) -> float:
    var t: float = clampf(value, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

func _anchor(item: Dictionary, ports: Array[Dictionary]) -> Vector2:
    return _port_world(ports, int(item["port_index"])) + Vector2(item["anchor_dir"]) * _landing_offset(ports, int(item["port_index"]))

func _spawn_ship(art_id: int, index: int, ports: Array[Dictionary]) -> void:
    var info: Dictionary = _class_library()[art_id]
    var image: Sprite2D = Sprite2D.new()
    image.name = "%s_%s_%02d" % [_region.to_upper(), str(info["role"]), index]
    image.texture = _texture_library()[art_id]
    image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    image.z_index = 1
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = INNER_LIGHT
    material.set_shader_parameter("light_phase", float(index) * 1.37)
    material.set_shader_parameter("brightness", float(info["glow"]))
    material.set_shader_parameter("light_tint", info["light"])
    material.set_shader_parameter("motion_rate", 0.8 + float(index % 4) * 0.13)
    image.material = material
    add_child(image)
    var wake: Node2D = ShipMotionFX.new()
    wake.name = "Wake_%02d" % index
    wake.z_index = -1
    wake.scale.x = -1.0 if is_equal_approx(float(info.get("nose_axis", 0.0)), PI) else 1.0
    image.add_child(wake)
    # Two ships begin docked, two begin inbound; all roles remain visible across the fleet.
    var target: int = (index * 3 + 2) % ports.size()
    var outward: Vector2 = Vector2.from_angle(float(index) * 1.9 + 0.7)
    var origin: Vector2 = _port_world(ports, target) + outward * (310.0 + 32.0 * float(index % 3))
    var nose_axis: float = float(info.get("nose_axis", 0.0))
    var heading: float = (-outward).angle()
    image.rotation = heading - nose_axis
    var item: Dictionary = {
        "image":image, "wake":wake, "light_color":info["light"],
        "role":info["role"], "label":info["label"], "class_id":art_id, "nose_axis":nose_axis,
        "world":origin, "velocity":Vector2.ZERO,
        "target_index":target, "port_index":target,
        "speed":float(info["speed"]) * _rng.randf_range(0.94, 1.06),
        "turn":float(info["turn"]), "dwell":float(info["dwell"]),
        "timer":0.0, "mode":"cruise", "anchor_dir":outward,
        "approach_offset":outward * 310.0, "stops_left":(1 if index == 1 else 2 + index % 3),
        "outbound":false, "exit_world":Vector2.ZERO, "jump_direction":Vector2.RIGHT,
        "phase":float(index) * 1.91
    }
    if index < 2:
        item["mode"] = "docked"
        item["timer"] = 0.7 + float(index) * 2.0
        item["world"] = _anchor(item, ports)
    elif index < 4:
        item["mode"] = "approach"
        item["approach_offset"] = outward * (310.0 + 32.0 * float(index % 3))
    else:
        # Remaining vessels sail toward other ports using their nose +X.
        item["target_index"] = (target + 1 + index % 2) % ports.size()
        image.rotation = (_port_world(ports, int(item["target_index"])) - origin).angle() - nose_axis
    _ships.append(item)

func _choose_next_port(item: Dictionary, ports: Array[Dictionary]) -> int:
    var n: int = ports.size()
    var current: int = int(item["port_index"]) % n
    match str(item["role"]):
        "liner", "civilian", "shuttle":
            return (current + 1) % n
        "cargo", "merchant", "freighter":
            return (current + 2) % n
        "scout", "courier", "explorer":
            var furthest: int = (current + 1) % n
            var largest: float = -1.0
            for i in range(n):
                if i == current:
                    continue
                var value: float = Vector2(item["world"]).distance_squared_to(_port_world(ports, i))
                if value > largest:
                    largest = value
                    furthest = i
            return furthest
        "guard", "patrol", "escort":
            return (current + (1 if current % 2 == 0 else n - 1)) % n
        "diplomat":
            return n - 1 if current != n - 1 else _rng.randi_range(0, n - 2)
        _:
            return (current + 1) % n

func _begin_approach(item: Dictionary, ports: Array[Dictionary]) -> void:
    var target_index: int = int(item["target_index"])
    var offset: Vector2 = Vector2(item["world"]) - _port_world(ports, target_index)
    var outward: Vector2 = offset.normalized() if offset.length_squared() > 0.01 else Vector2.RIGHT
    item["mode"] = "approach"
    item["port_index"] = target_index
    item["anchor_dir"] = outward
    item["approach_offset"] = offset
    item["timer"] = 0.0
    item["velocity"] = Vector2.ZERO

func _jump_destination(from_world: Vector2) -> Vector2:
    var heading: Vector2 = from_world.normalized() if from_world.length_squared() > 1.0 else Vector2.RIGHT
    var radius: float = maxf(3350.0, from_world.length() + 1050.0)
    return heading * radius

func _start_takeoff(item: Dictionary, ports: Array[Dictionary]) -> void:
    item["stops_left"] = int(item["stops_left"]) - 1
    item["outbound"] = int(item["stops_left"]) <= 0
    var port: int = int(item["port_index"])
    if bool(item["outbound"]):
        item["exit_world"] = _jump_destination(_port_world(ports, port))
    else:
        item["target_index"] = _choose_next_port(item, ports)
    item["world"] = _anchor(item, ports)
    item["mode"] = "takeoff"
    item["timer"] = 0.0
    item["velocity"] = Vector2.ZERO
    # During lift-off, nose always faces outward from the port.
    (item["image"] as Sprite2D).rotation = Vector2(item["anchor_dir"]).angle() - float(item["nose_axis"])

func _turn_nose(image: Sprite2D, desired: Vector2, speed: float, delta: float, nose_axis: float = 0.0) -> float:
    if desired.length_squared() < 0.001:
        return 0.0
    var desired_angle: float = desired.angle() - nose_axis
    image.rotation = lerp_angle(image.rotation, desired_angle, minf(1.0, maxf(0.0, speed) * delta))
    return absf(wrapf(desired_angle - image.rotation, -PI, PI))

func _process_ship(item: Dictionary, ports: Array[Dictionary], delta: float) -> void:
    var mode: String = str(item["mode"])
    var image: Sprite2D = item["image"]
    var world: Vector2 = item["world"]
    var velocity: Vector2 = item["velocity"]
    var elapsed: float = float(item["timer"]) + delta
    var nose_axis: float = float(item["nose_axis"])
    var port: int = int(item["port_index"])
    if mode == "docked":
        item["world"] = _anchor(item, ports)
        item["timer"] = float(item["timer"]) - delta
        if float(item["timer"]) <= 0.0:
            _start_takeoff(item, ports)
        return
    if mode == "waiting":
        item["timer"] = float(item["timer"]) - delta
        if float(item["timer"]) <= 0.0:
            # Respawn docked rather than appearing midflight: visible nose-first takeoff.
            item["port_index"] = _rng.randi_range(0, ports.size() - 1)
            item["anchor_dir"] = Vector2.from_angle(_rng.randf_range(-PI, PI))
            item["stops_left"] = _rng.randi_range(2, 4)
            item["outbound"] = false
            item["mode"] = "docked"
            item["timer"] = 0.55
            item["world"] = _anchor(item, ports)
            image.rotation = Vector2(item["anchor_dir"]).angle() - nose_axis
            item["velocity"] = Vector2.ZERO
        return
    if mode in ["approach", "hover", "landing", "takeoff", "depart"]:
        var anchor: Vector2 = _anchor(item, ports)
        var port_world: Vector2 = _port_world(ports, port)
        item["timer"] = elapsed
        item["velocity"] = Vector2.ZERO
        match mode:
            "approach":
                var progress: float = _smooth(elapsed / APPROACH_SECONDS)
                var next_world: Vector2 = port_world + Vector2(item["approach_offset"]).lerp(Vector2(item["anchor_dir"]) * _landing_offset(ports, port), progress)
                var direction: Vector2 = next_world - world
                if direction.length_squared() > 0.001:
                    _turn_nose(image, direction, 6.0, delta, nose_axis)
                item["world"] = next_world
                if elapsed >= APPROACH_SECONDS:
                    item["mode"] = "hover"
                    item["timer"] = 0.0
            "hover":
                item["world"] = anchor
                if elapsed >= HOVER_SECONDS:
                    item["mode"] = "landing"
                    item["timer"] = 0.0
            "landing":
                item["world"] = anchor
                if elapsed >= LANDING_SECONDS:
                    item["mode"] = "docked"
                    item["timer"] = 1.5 + float(item["dwell"])
            "takeoff":
                item["world"] = anchor
                image.rotation = Vector2(item["anchor_dir"]).angle() - nose_axis
                if elapsed >= TAKEOFF_SECONDS:
                    item["mode"] = "depart"
                    item["timer"] = 0.0
            "depart":
                var outward: Vector2 = Vector2(item["anchor_dir"])
                image.rotation = outward.angle() - nose_axis
                var distance: float = lerpf(_landing_offset(ports, port), DEPART_RADIUS, _smooth(elapsed / DEPART_SECONDS))
                item["world"] = port_world + outward * distance
                if elapsed >= DEPART_SECONDS:
                    item["mode"] = "cruise"
                    item["timer"] = 0.0
                    item["velocity"] = outward * float(item["speed"]) * 0.55
        return
    if mode == "align_jump":
        # No positional motion during alignment; the ship must point its nose at the exit.
        var to_exit: Vector2 = Vector2(item["exit_world"]) - world
        var error: float = _turn_nose(image, to_exit, 6.0, delta, nose_axis)
        item["velocity"] = Vector2.ZERO
        item["timer"] = elapsed
        if error < 0.025:
            item["jump_direction"] = Vector2.from_angle(image.rotation + nose_axis)
            item["mode"] = "charge"
            item["timer"] = 0.0
        return
    if mode == "charge":
        item["timer"] = elapsed
        item["velocity"] = Vector2.ZERO
        image.rotation = Vector2(item["jump_direction"]).angle() - nose_axis
        if elapsed >= CHARGE_SECONDS:
            item["mode"] = "dash"
            item["timer"] = 0.0
        return
    if mode == "dash":
        var t: float = clampf(elapsed / DASH_SECONDS, 0.0, 1.0)
        var forward: Vector2 = Vector2(item["jump_direction"])
        image.rotation = forward.angle() - nose_axis
        item["world"] = world + forward * HyperjumpMotion.dash_speed(t) * delta
        item["velocity"] = forward * HyperjumpMotion.dash_speed(t)
        item["timer"] = elapsed
        if t >= 1.0:
            item["mode"] = "waiting"
            item["timer"] = REENTRY_SECONDS + _rng.randf_range(0.0, 1.2)
            item["velocity"] = Vector2.ZERO
        return
    # Cruise uses the true sprite nose for both +X and -X native textures.
    var target: Vector2 = Vector2(item["exit_world"]) if bool(item["outbound"]) else _port_world(ports, int(item["target_index"]))
    var towards: Vector2 = target - world
    var arrive_radius: float = 88.0 if bool(item["outbound"]) else APPROACH_RADIUS
    if towards.length() <= arrive_radius:
        if bool(item["outbound"]):
            item["mode"] = "align_jump"
            item["timer"] = 0.0
            item["velocity"] = Vector2.ZERO
        else:
            _begin_approach(item, ports)
        return
    var error_angle: float = _turn_nose(image, towards, float(item["turn"]), delta, nose_axis)
    var forward: Vector2 = Vector2.from_angle(image.rotation + nose_axis)
    var alignment: float = maxf(0.0, cos(error_angle))
    var desired_speed: float = float(item["speed"]) * alignment
    var speed_now: float = move_toward(velocity.length(), desired_speed, 150.0 * delta)
    item["velocity"] = forward * speed_now
    item["world"] = world + forward * speed_now * delta
    item["timer"] = elapsed

func _physics_process(delta: float) -> void:
    if not NATIVE_SYSTEMS.has(_region):
        return
    _time += delta
    var ports: Array[Dictionary] = _available_ports()
    if ports.size() < 2:
        return
    for i in range(_ships.size()):
        var item: Dictionary = _ships[i]
        _process_ship(item, ports, delta)
        _ships[i] = item
    _update_images()
    queue_redraw()

func _draw() -> void:
    if not NATIVE_SYSTEMS.has(_region):
        return
    for item in _ships:
        var mode: String = str(item["mode"])
        if mode not in ["charge", "dash", "hover", "landing", "takeoff"]:
            continue
        var screen: Vector2 = Vector2(item["world"]) - _camera_world + _view * 0.5
        if screen.x < -300.0 or screen.y < -300.0 or screen.x > _view.x + 300.0 or screen.y > _view.y + 300.0:
            continue
        var glow: Color = item["light_color"]
        if mode == "charge":
            NpcJumpVisual.draw_charge(self, screen, clampf(float(item["timer"]) / CHARGE_SECONDS, 0.0, 1.0), glow)
        elif mode == "dash":
            # FX rotation uses nose_axis; Solar FX code expects local -Y.
            NpcJumpVisual.draw_dash(self, screen, (item["image"] as Sprite2D).rotation + float(item["nose_axis"]) + PI * 0.5, clampf(float(item["timer"]) / DASH_SECONDS, 0.0, 1.0), glow)
        else:
            var lift: float = 1.0 if mode == "hover" else 0.65
            draw_arc(screen, 18.0 + 4.0 * sin(_time * 2.2), 0.0, TAU, 30, Color(glow, 0.20 * lift), 1.5, true)

func _update_images() -> void:
    for item in _ships:
        var image: Sprite2D = item["image"]
        var mode: String = str(item["mode"])
        var screen: Vector2 = Vector2(item["world"]) - _camera_world + _view * 0.5
        image.position = screen
        var data: Dictionary = _class_library()[int(item["class_id"])]
        var base_scale: float = float(data["size"])
        var factor: float = 1.0
        if mode == "approach":
            factor = 1.0 - 0.18 * _smooth(float(item["timer"]) / APPROACH_SECONDS)
        elif mode == "hover":
            factor = 0.82
        elif mode == "landing":
            factor = 0.82 * (1.0 - _smooth(float(item["timer"]) / LANDING_SECONDS))
        elif mode == "takeoff":
            factor = 0.82 * _smooth(float(item["timer"]) / TAKEOFF_SECONDS)
        elif mode == "depart":
            factor = 0.82 + 0.18 * _smooth(float(item["timer"]) / DEPART_SECONDS)
        elif mode == "dash":
            factor = 1.0 + 0.45 * _smooth(float(item["timer"]) / DASH_SECONDS)
        image.scale = Vector2.ONE * base_scale * maxf(0.0, factor)
        image.modulate.a = 1.0 if mode != "dash" else 1.0 - 0.72 * _smooth(float(item["timer"]) / DASH_SECONDS)
        var moving: float = Vector2(item["velocity"]).length() / maxf(1.0, float(item["speed"]))
        if mode in ["approach", "hover", "landing", "docked", "takeoff", "waiting", "align_jump", "charge"]:
            moving = 0.0
        var wake: Node2D = item["wake"]
        wake.call("update_motion", _time, clampf(moving, 0.0, 1.0), item["light_color"])
        image.visible = NATIVE_SYSTEMS.has(_region) and mode not in ["docked", "waiting"] and screen.x > -330.0 and screen.y > -330.0 and screen.x < _view.x + 330.0 and screen.y < _view.y + 330.0
