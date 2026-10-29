extends Node2D
## Lightweight schematic planet. Pure CanvasItem drawing, no external assets.
## A changing longitude shifts surface stripes while the globe stays round.

var body_radius: float = 25.0
var base_color: Color = Color(0.55, 0.72, 0.92)
var band_color: Color = Color(0.7, 0.8, 1.0)
var has_rings: bool = false
var rotation_seconds: float = 42.0
var _phase: float = 0.0
var _redraw_accumulator: float = 0.0


func configure(diameter: float, color: Color, bands: Color, rings: bool, spin_seconds: float, initial_phase: float) -> void:
	body_radius = diameter * 0.5
	base_color = color
	band_color = bands
	has_rings = rings
	rotation_seconds = maxf(5.0, spin_seconds)
	_phase = initial_phase
	queue_redraw()


func _process(delta: float) -> void:
	# 20 Hz appearance update is enough for distant objects and mobile hardware.
	_phase = wrapf(_phase + TAU * delta / rotation_seconds, 0.0, TAU)
	_redraw_accumulator += delta
	if _redraw_accumulator >= 0.05:
		_redraw_accumulator = fmod(_redraw_accumulator, 0.05)
		if visible:
			queue_redraw()


func _draw() -> void:
	var r: float = body_radius
	if has_rings:
		_draw_ring(false)
	# Slightly shaded disc; markings remain constrained inside the disc.
	draw_circle(Vector2.ZERO, r + 2.0, Color(base_color.r, base_color.g, base_color.b, 0.09))
	draw_circle(Vector2.ZERO, r, base_color.darkened(0.29))
	draw_circle(Vector2(-r * 0.08, -r * 0.09), r * 0.90, base_color)
	# Latitude bands appear to drift with the rotation, rather than rotating a flat disc.
	for j in range(5):
		var latitude: float = (float(j) - 2.0) / 3.3
		var y: float = latitude * r * 0.88
		var half_width: float = sqrt(maxf(0.0, r * r - y * y)) * 0.93
		var band_wobble: float = sin(_phase + float(j) * 1.75) * r * 0.07
		var shade: Color = band_color.lightened(0.07 * sin(_phase * 0.5 + float(j)))
		shade.a = 0.22 + 0.13 * (1.0 + sin(_phase + float(j))) * 0.5
		var band_thickness: float = maxf(1.6, r * (0.09 if j % 2 == 0 else 0.05))
		draw_line(Vector2(-half_width, y + band_wobble), Vector2(half_width, y - band_wobble), shade, band_thickness, true)
	# Soft glint and dim limb give the flat schematic object some depth.
	draw_circle(Vector2(-r * 0.33, -r * 0.36), maxf(1.3, r * 0.10), Color(1.0, 1.0, 1.0, 0.11))
	draw_arc(Vector2.ZERO, r - 0.6, PI * 0.17, PI * 1.1, 24, Color(0.015, 0.03, 0.06, 0.38), maxf(1.8, r * 0.13), true)
	if has_rings:
		_draw_ring(true)


func _draw_ring(foreground: bool) -> void:
	# Saturn/Uranus: a thin tilted ring, split into back and front arcs.
	var r: float = body_radius
	var ring_color: Color = Color(0.84, 0.75, 0.57, 0.65) if has_rings else Color.TRANSPARENT
	var start_angle: float = 0.0 if foreground else PI
	var end_angle: float = PI if foreground else TAU
	for ring in range(2):
		var pts := PackedVector2Array()
		for i in range(40):
			var a: float = lerpf(start_angle, end_angle, float(i) / 39.0)
			var rx: float = r * (1.42 + 0.16 * float(ring))
			var ry: float = r * (0.35 + 0.075 * float(ring))
			var p: Vector2 = Vector2(cos(a) * rx, sin(a) * ry).rotated(-0.17)
			pts.append(p)
		draw_polyline(pts, ring_color, maxf(1.1, r * 0.033), true)
