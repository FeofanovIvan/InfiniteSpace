extends "res://planet_hub/games/ice_planet/IcePlanetLivingOceanV3.gd"
## Ice Planet v3.1: remove the white shader quad; render the living ocean
## as a real circle, restore v2 segmented safety gauge, lock left stick to X.
## Retains v3 gameplay, six languages, host toolbar and animated sun.

const HORIZONTAL_FLIGHT_STICK: Script = preload("res://planet_hub/games/ice_planet/IcePlanetHorizontalStickV31.gd")
const LIQUID_SPHERE: Script = preload("res://planet_hub/games/ice_planet/IcePlanetLiquidSphereV31.gd")
var _ocean_sphere: Control
var _ocean_pitch: float = 0.0
var _ocean_extra_yaw: float = 0.0

func _activate_ocean_shader() -> void:
    # V3 used an opaque WHITE ColorRect and a shader. On unsupported/failed
    # shader compilation that ColorRect was rendered as a plain white square.
    # Replace it with transparent script-driven CanvasItem drawing.
    if _earth_body != null:
        _earth_body.material = null
        _earth_body.color = Color(0, 0, 0, 0)
        _earth_body.hide()
    _earth_material = null

func _create_flight_controls() -> void:
    _flight_left = HORIZONTAL_FLIGHT_STICK.new() as Control
    _flight_left.name = "LeftFlightStick_HorizontalOnly_Arrows"
    _flight_left.z_index = 50
    add_child(_flight_left)
    _flight_left.connect("direction_changed", Callable(self, "_on_left_stick"))

    _flight_right = FLIGHT_STICK.new() as Control
    _flight_right.name = "RightFlightStick_Full360Rotation"
    _flight_right.z_index = 50
    add_child(_flight_right)
    _flight_right.connect("direction_changed", Callable(self, "_on_right_stick"))

func _ready() -> void:
    super._ready()
    # Even if the prior scene created the old surface, never reveal it again.
    if _earth_body != null:
        _earth_body.material = null
        _earth_body.color = Color(0, 0, 0, 0)
        _earth_body.hide()
    _earth_material = null
    _ocean_sphere = LIQUID_SPHERE.new() as Control
    _ocean_sphere.name = "VisibleLivingOcean_NoShader_NoWhiteQuad"
    _ocean_sphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _ocean_sphere.z_index = 4
    add_child(_ocean_sphere)
    _reposition_ocean()
    _update_ocean()
    call_deferred("_layout")

func _layout() -> void:
    super._layout()
    _reposition_ocean()

func _position_bodies() -> void:
    super._position_bodies()
    if _earth_body != null:
        _earth_body.hide()
    _reposition_ocean()

func _reposition_ocean() -> void:
    if _ocean_sphere == null or _stage_rect.size.x <= 0.0:
        return
    var half_extent: float = _world_radius * 1.20
    _put(_ocean_sphere, Rect2(_earth_center - Vector2.ONE * half_extent, Vector2.ONE * half_extent * 2.0))

func _process(delta: float) -> void:
    # More pronounced movement: left/right joystick reliably moves the visible
    # globe, even while the sun is oscillating. Up/down never changes orbit.
    if not _mission_complete and not _game_complete:
        _distance = clampf(_distance + _left_vector.x * 0.42 * delta, 0.0, 1.0)
    super._process(delta)
    # X turns longitude clockwise/counterclockwise; Y tilts the liquid's
    # circulating bands up/down. Diagonals operate both axes simultaneously.
    _ocean_extra_yaw = wrapf(_ocean_extra_yaw + _right_vector.x * 0.68 * delta, -TAU, TAU)
    _ocean_pitch = wrapf(_ocean_pitch + _right_vector.y * 2.75 * delta, -TAU, TAU)
    _update_ocean()

func _update_ocean() -> void:
    if _ocean_sphere == null:
        return
    var hot: float = smoothstep(40.0, 102.0, _warm_temp)
    var frozen: float = 1.0 - smoothstep(-28.0, 27.0, _cool_temp)
    _ocean_sphere.call("update_world", _planet_angle + _ocean_extra_yaw, _ocean_pitch, hot, frozen, _flare_amount(), _liquid_fx_time)

func _draw_temperature_gauge() -> void:
    # Restore the liked v2 heat / habitable zone / ice segmented gauge.
    # Only the marker's input is corrected to the actual moving Sun distance.
    _panel(Rect2(361, 517, 558, 71), Color("071b30", 0.83), Color("3e95b8", 0.62), 20, 2)
    var total: float = SAFETY_BAR.size.x
    var segments: int = 88
    for part in range(segments):
        var t: float = float(part) / float(segments)
        var tint: Color = Color("fa6d40") if t < 0.27 else Color("73e2ab") if t < 0.59 else Color("6bbaf7")
        var place: Rect2 = Rect2(SAFETY_BAR.position + Vector2(t * total, 0.0), Vector2(total / float(segments) + 1.0, SAFETY_BAR.size.y))
        draw_rect(place, tint.darkened(0.15) if part % 2 == 0 else tint, true)
    draw_rect(Rect2(SAFETY_BAR.position.x + total * 0.27, SAFETY_BAR.position.y - 6.0, total * 0.32, SAFETY_BAR.size.y + 12.0), Color("baffdc", 0.13), false, 3.0)
    var marker: Vector2 = Vector2(SAFETY_BAR.position.x + clampf(_actual_distance, 0.0, 1.0) * total, SAFETY_BAR.get_center().y)
    draw_line(marker - Vector2(0, 16), marker + Vector2(0, 19), Color("f5ffff"), 5.0, true)
    draw_circle(marker - Vector2(0, 21), 8.0, Color("e6ffff"))
    draw_string(ThemeDB.fallback_font, Vector2(388, 576), _readable("heat"), HORIZONTAL_ALIGNMENT_LEFT, 100, 15, Color("ffc9a5"))
    draw_string(ThemeDB.fallback_font, Vector2(554, 576), _readable("safe"), HORIZONTAL_ALIGNMENT_CENTER, 170, 15, Color("caffdc"))
    draw_string(ThemeDB.fallback_font, Vector2(812, 576), _readable("ice"), HORIZONTAL_ALIGNMENT_RIGHT, 70, 15, Color("b8e6ff"))
