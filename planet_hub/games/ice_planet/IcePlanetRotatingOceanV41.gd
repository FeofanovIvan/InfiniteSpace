extends Control
## Ice Planet v4.1: shader-free, genuinely rotating spherical ocean.
## The ocean has a stable procedural surface map in spherical longitude/latitude.
## Turning moves that map across the visible hemisphere; opposite steering
## reverses it. Unlike the old animated stripe offset, recognisable patterns
## pass behind the globe's silhouette and reappear after a full revolution.
## Never uses an opaque ColorRect or relies on mobile shader compilation.

const LAT_CELLS: int = 20
const LON_CELLS: int = 42

var ocean_yaw: float = 0.0
var ocean_pitch: float = 0.0
var hot_factor: float = 0.0
var ice_factor: float = 0.0
var flare_factor: float = 0.0
var elapsed: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = false

func update_world(yaw: float, pitch: float, heat: float, freeze: float, flare: float, time_value: float) -> void:
    ocean_yaw = yaw
    ocean_pitch = pitch
    hot_factor = clampf(heat, 0.0, 1.0)
    ice_factor = clampf(freeze, 0.0, 1.0)
    flare_factor = clampf(flare, 0.0, 1.0)
    elapsed = time_value
    queue_redraw()

# Fixed texture in geographic coordinates; no TIME-dependent longitude here.
# The planet's rotation is the only way these ocean features move sideways.
func _water_color(view_lon: float, lat: float) -> Color:
    var geographic_lon: float = view_lon - ocean_yaw
    var s1: float = sin(geographic_lon * 4.8 + 1.25 * sin(lat * 5.2) + 0.7 * cos(geographic_lon * 2.1 - lat * 4.0))
    var s2: float = cos(geographic_lon * 8.5 - lat * 5.1 + 1.4 * sin(geographic_lon * 2.2 + lat * 2.9))
    var gyre: float = cos(geographic_lon * 2.4 + lat * 6.3) * sin(lat * 5.2 - geographic_lon * 3.3)
    var aqua: float = clampf(0.48 + s1 * 0.28 + s2 * 0.13 + gyre * 0.12, 0.0, 1.0)
    var water: Color = Color("083166").lerp(Color("079ac2"), aqua)
    var foam: float = smoothstep(0.57, 0.91, s1 * 0.65 + s2 * 0.35)
    water = water.lerp(Color("9cf2f0"), foam * 0.62)
    # Sphere lighting: stronger shading near the limb, without hiding the map.
    var limb: float = pow(maxf(cos(view_lon) * cos(lat), 0.0), 0.58)
    water = water.darkened((1.0 - limb) * 0.38)
    var screen_x: float = cos(lat) * sin(view_lon)
    var red: float = hot_factor * clampf((0.32 - screen_x) / 1.20, 0.0, 1.0)
    var frost: float = ice_factor * clampf((0.34 + screen_x) / 1.20, 0.0, 1.0)
    if red > 0.001:
        water = water.lerp(Color("e74c3a"), red * 0.88)
    if frost > 0.001:
        water = water.lerp(Color("e1f5ff"), frost * 0.91)
    return water

func _surface_point(center: Vector2, radius: float, view_lon: float, lat: float) -> Vector2:
    return center + Vector2(cos(lat) * sin(view_lon), sin(lat)) * radius

func _draw() -> void:
    if size.x < 10.0 or size.y < 10.0:
        return
    var center: Vector2 = size * 0.5
    var radius: float = minf(size.x, size.y) * 0.415
    draw_circle(center, radius + 5.0, Color("6dd2ff", 0.34))
    draw_circle(center, radius + 2.0, Color("91edff"))
    draw_circle(center, radius, Color("092f5c"))

    # A shaded globe tessellated in the SCREEN hemisphere. Its colour at each
    # vertex samples a fixed ocean texture at (view longitude - rotation).
    # The front-facing map changes visibly as the joystick turns the planet.
    for row in range(LAT_CELLS):
        var lat_a: float = -PI * 0.5 + float(row) * PI / float(LAT_CELLS)
        var lat_b: float = -PI * 0.5 + float(row + 1) * PI / float(LAT_CELLS)
        for col in range(LON_CELLS):
            var lon_a: float = -PI * 0.5 + float(col) * PI / float(LON_CELLS)
            var lon_b: float = -PI * 0.5 + float(col + 1) * PI / float(LON_CELLS)
            var corners := PackedVector2Array([
                _surface_point(center, radius, lon_a, lat_a),
                _surface_point(center, radius, lon_b, lat_a),
                _surface_point(center, radius, lon_b, lat_b),
                _surface_point(center, radius, lon_a, lat_b),
            ])
            var shades := PackedColorArray([
                _water_color(lon_a, lat_a), _water_color(lon_b, lat_a),
                _water_color(lon_b, lat_b), _water_color(lon_a, lat_b)
            ])
            draw_polygon(corners, shades)

    # Distinct persistent luminous gyres. Their projected x coordinates and
    # apparent widths actually rotate in either direction, disappearing on
    # the far side instead of sliding back and forth like a flat overlay.
    for k in range(9):
        var fixed_lon: float = -PI + float(k) * TAU / 9.0 + 0.22 * sin(float(k) * 2.7)
        var visible_lon: float = wrapf(fixed_lon + ocean_yaw, -PI, PI)
        if absf(visible_lon) > PI * 0.49:
            continue
        var latitude: float = 0.65 * sin(float(k) * 2.18)
        var facing: float = cos(visible_lon) * cos(latitude)
        var at: Vector2 = _surface_point(center, radius, visible_lon, latitude)
        var spot_radius: float = radius * (0.050 + 0.018 * float(k % 3)) * maxf(0.15, facing)
        draw_circle(at, spot_radius * 2.3, Color(0.10, 0.77, 0.98, 0.16 * facing))
        draw_circle(at, spot_radius, Color(0.65, 0.98, 0.99, 0.35 + 0.39 * facing))
        draw_circle(at + Vector2(-spot_radius * 0.24, -spot_radius * 0.22), spot_radius * 0.34, Color("defaff", 0.54))

    # These weather reactions are screen-oriented (facing the Sun), while the
    # water underneath continues spinning independently in 3D projection.
    if hot_factor > 0.035:
        for i in range(18):
            var t: float = fposmod(float(i) * 0.173 + elapsed * (0.24 + float(i % 3) * 0.05), 1.0)
            var x: float = -radius * (0.15 + 0.70 * fposmod(float(i) * 0.419, 1.0))
            var y: float = radius * (0.77 - 1.48 * t)
            var place: Vector2 = center + Vector2(x, y)
            if place.distance_to(center) < radius - 5.0:
                draw_arc(place, 2.0 + float(i % 3) * 2.0, 0.0, TAU, 20, Color(1.0, 0.90, 0.65, hot_factor * (1.0 - t) * 0.79), 1.5, true)
    if ice_factor > 0.035:
        for i in range(12):
            var x: float = radius * (0.10 + 0.67 * fposmod(float(i) * 0.397, 1.0))
            var y: float = radius * (-0.73 + 1.46 * fposmod(float(i) * 0.479, 1.0))
            var place: Vector2 = center + Vector2(x, y)
            if place.distance_to(center) < radius * 0.88:
                var length: float = 5.0 + ice_factor * 9.0
                draw_line(place + Vector2(-length, 0), place + Vector2(length, 0), Color(0.97, 1.0, 1.0, 0.76 * ice_factor), 1.7, true)
                draw_line(place + Vector2(0, -length), place + Vector2(0, length), Color(0.96, 1.0, 1.0, 0.73 * ice_factor), 1.7, true)

    # Translucent terminator and atmospheric highlight, still fully circular.
    draw_arc(center, radius - 1.0, -PI * 0.52, PI * 0.49, 72, Color(0.01, 0.06, 0.20, 0.44), radius * 0.13, true)
    draw_arc(center, radius + 0.8, -PI * 0.90, PI * 0.10, 72, Color(0.79, 0.96, 1.0, 0.73), 2.8, true)
    draw_arc(center, radius + 4.0, -PI * 0.74, PI * 0.74, 72, Color(0.23 + flare_factor * 0.24, 0.80, 1.0, 0.44), 2.5, true)
