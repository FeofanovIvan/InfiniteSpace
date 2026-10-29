extends RefCounted
## The single visual source for NPC and player hyperspace jumps.
## This is the exact renderer previously embedded in NpcTraffic.gd.
## Its caller supplies the craft's already-rendered screen position.

static func draw_charge(canvas: CanvasItem, screen: Vector2, t: float, trail_color: Color) -> void:
	var charge_alpha: float = clampf(t, 0.0, 1.0)
	canvas.draw_arc(screen, 27.0 - charge_alpha * 6.0, -1.7, 4.0, 28, Color(trail_color, 0.45 * charge_alpha), 2.0, true)

static func draw_dash(canvas: CanvasItem, screen: Vector2, angle: float, t: float, trail_color: Color) -> void:
	var progress: float = clampf(t, 0.0, 1.0)
	var direction: Vector2 = Vector2.from_angle(angle - PI * 0.5)
	canvas.draw_line(screen, screen - direction * (100.0 + 420.0 * progress), Color(trail_color, 0.58 * (1.0 - progress)), 3.0 + 4.0 * progress, true)
	canvas.draw_circle(screen, 9.0 + 30.0 * progress, Color(trail_color, 0.28 * (1.0 - progress)))

static func dash_ship_scale(t: float) -> float:
	return 1.0 + clampf(t, 0.0, 1.0) * 0.46

static func draw_jump_cloud(canvas: CanvasItem, screen: Vector2, lifetime: float, color: Color, phase: float) -> void:
	var progress: float = 1.0 - lifetime
	for i in range(4):
		var spread: float = 12.0 + float(i) * 9.0 + progress * 55.0
		var col: Color = color
		col.a = lifetime * (0.13 - float(i) * 0.019)
		canvas.draw_circle(screen + Vector2.from_angle(float(i) * 1.7 + phase) * (10.0 + progress * 15.0), spread, col)
	canvas.draw_arc(screen, 14.0 + progress * 60.0, 0.0, TAU, 48, Color(color, lifetime * 0.39), 1.5, true)
