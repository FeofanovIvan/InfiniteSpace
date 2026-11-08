extends Control
## InfiniteSpace v91: actual live sky used by spaceflight, shared by simulator
## and Puzzle. Reuses the original procedural Godot sky, not a bitmap imitation.
## Lightweight standalone copy: no planets, ship, asteroids, gameplay or HUD.

const FlightStarfield = preload("res://scripts/Starfield.gd")
const FlightFarPlasma = preload("res://scripts/FarPlasma.gd")
const FlightDistantEvents = preload("res://scripts/DistantEvents.gd")

var _stars: Node2D
var _plasma_near: Node2D
var _plasma_far: Node2D
var _meteors: Node2D
var _flight_drift: float = 0.0


func _ready() -> void:
    # The game world is paused while the simulator is shown. The sky must not stop.
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = true

    var void_color := ColorRect.new()
    void_color.name = "FlightVoidColor"
    # Exact clear color of the project from project.godot.
    void_color.color = Color(0.0015, 0.003, 0.009, 1.0)
    void_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(void_color)
    void_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    # Original clouds from spaceflight, twice at different camera addresses.
    # This only increases the visible concentration of the SAME shader nebulae.
    _plasma_near = FlightFarPlasma.new() as Node2D
    _plasma_near.name = "RealSpaceFlightNebulaePrimary"
    add_child(_plasma_near)
    _plasma_far = FlightFarPlasma.new() as Node2D
    _plasma_far.name = "RealSpaceFlightNebulaeAdditional"
    add_child(_plasma_far)

    _stars = FlightStarfield.new() as Node2D
    _stars.name = "RealSpaceFlightStarfield"
    add_child(_stars)

    _meteors = FlightDistantEvents.new() as Node2D
    _meteors.name = "RealSpaceFlightMeteorsAndTwinkles"
    add_child(_meteors)
    resized.connect(_resize_sky)
    _resize_sky()


func _resize_sky() -> void:
    if _stars == null or not is_instance_valid(_stars) or size.x < 8.0 or size.y < 8.0:
        return
    _plasma_near.call("resize_sky", size)
    _plasma_far.call("resize_sky", size)
    _stars.call("resize_field", size)
    _meteors.call("resize_sky", size)
    _set_sky_camera()


func _set_sky_camera() -> void:
    # Static nebula cloud shapes with the same gently breathing original shader.
    # Slight virtual camera drift makes the real distant star parallax noticeable.
    # The second position is independently seeded for more of the same clouds.
    _plasma_near.call("set_camera_address", Vector2i.ZERO, Vector2.ZERO,
        Vector2(0.0, 0.0) + Vector2(_flight_drift * 0.12, 0.0))
    _plasma_far.call("set_camera_address", Vector2i(13, 9), Vector2.ZERO,
        Vector2(_flight_drift * 0.08, 0.0))


func _process(delta: float) -> void:
    if not visible or size.x < 8.0 or size.y < 8.0:
        return
    # Same original star-size, star-color, multi-depth parallax and movement.
    _stars.call("advance", Vector2(22.0 * delta, 3.0 * delta))
    _flight_drift += 10.0 * delta
    # Rescans are suppressed internally by FarPlasma unless moved far enough.
    _set_sky_camera()
    # The original DistantEvents.gd supplies time-driven meteor movement itself.
