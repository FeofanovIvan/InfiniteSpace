extends Node2D
## Small, shader-free animated gas/dust accents for the five distinct story POIs.
## All effects are procedural; the original art textures are never edited.
## This is an illustrative gravity-inspired drift, not an N-body simulation.

var _region_id: String = "lmc"
var _seconds: float = 0.0
var _tone: Color = Color(0.40, 0.72, 1.0, 0.35)
var _outer_radius: float = 200.0

func configure(region_id: String) -> void:
	_region_id = region_id
	match region_id:
		"lmc":
			_tone = Color(0.36, 0.70, 1.0, 0.31)
			_outer_radius = 220.0
		"smc":
			_tone = Color(0.48, 0.58, 1.0, 0.36)
			_outer_radius = 254.0
		"ngc6822":
			_tone = Color(1.0, 0.65, 0.32, 0.29)
			_outer_radius = 180.0
		"m31":
			_tone = Color(0.72, 0.58, 1.0, 0.30)
			_outer_radius = 200.0
		"m33":
			_tone = Color(0.38, 0.92, 0.98, 0.32)
			_outer_radius = 198.0
	queue_redraw()

func update_time(seconds: float) -> void:
	_seconds = seconds
	queue_redraw()

func _draw() -> void:
	# Small transparent halos keep the visual effects subordinate to the asset.
	var beat: float = 0.5 + 0.5 * sin(_seconds * 0.54)
	var core: Color = Color(_tone.r, _tone.g, _tone.b, 0.025 + 0.020 * beat)
	draw_circle(Vector2.ZERO, _outer_radius * (0.86 + 0.03 * beat), core)
	# Counter-rotating diffuse gas arcs provide visible movement but avoid
	# artificial straight lines or a second prominent object.
	for stream in range(3):
		var direction: float = -1.0 if (stream % 2) == 0 else 1.0
		var start: float = 0.85 * float(stream) + direction * _seconds * (0.025 + 0.005 * stream)
		var span: float = 0.68 + 0.11 * sin(_seconds * 0.26 + float(stream))
		var radius: float = _outer_radius * (0.73 + 0.09 * stream)
		var alpha: float = 0.11 + 0.035 * beat
		draw_arc(Vector2.ZERO, radius, start, start + span, 35,
			Color(_tone.r, _tone.g, _tone.b, alpha), 4.5 + float(stream), true)
	# A limited number of tiny particles spirals outward on curved paths.
	# Particle motion reverses in alternating streams to suggest eddies.
	for index in range(24):
		var group: int = index % 3
		var turn: float = 1.0 if (group % 2) == 0 else -1.0
		var seed: float = float(index) * 2.39996323
		var motion: float = fposmod(_seconds * (0.025 + float(group) * 0.012) + float(index) * 0.139, 1.0)
		var radius: float = _outer_radius * (0.66 + 0.32 * motion)
		var angle: float = seed + turn * _seconds * 0.009 + motion * 1.4
		var point: Vector2 = Vector2(cos(angle), sin(angle) * 0.79) * radius
		var alpha: float = _tone.a * (1.0 - motion) * 0.37
		draw_circle(point, 1.2 + 1.6 * (1.0 - motion), Color(_tone.r, _tone.g, _tone.b, alpha))
	# Individual character: the living archive breathes, the laboratory vessel
	# has very faint exhaust puffs, and the other landmarks show thin swirls.
	if _region_id == "lmc":
		for i in range(5):
			var t: float = fposmod(_seconds * 0.12 + float(i) * 0.21, 1.0)
			var plume_at: Vector2 = Vector2(-124.0 - 86.0 * t, 19.0 * sin(float(i) + _seconds * 0.37))
			draw_circle(plume_at, 7.0 + 12.0 * t, Color(0.30, 0.74, 1.0, 0.058 * (1.0 - t)))
	elif _region_id == "smc":
		var breathe: float = 0.86 + 0.10 * sin(_seconds * 0.67)
		draw_arc(Vector2.ZERO, _outer_radius * breathe, _seconds * 0.012,
			_seconds * 0.012 + PI * 1.3, 72, Color(0.62, 0.48, 1.0, 0.075), 5.0, true)
