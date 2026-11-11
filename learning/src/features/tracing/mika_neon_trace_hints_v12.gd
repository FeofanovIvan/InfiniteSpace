extends "res://learning/src/features/tracing/letter_trace_checkpoints.gd"
## Brighter, high-contrast guide. Tracing checkpoints and path math unchanged.

func _draw() -> void:
    if game == null or game.letter_done or game.stroke_samples.is_empty():
        return
    var dot_every: int = maxi(1, int(DOT_SPACING_PX / game.sample_step))
    for s in range(game.strokes.size()):
        if s < game.cur_stroke:
            continue
        if dot_end_stroke >= 0 and s >= dot_end_stroke:
            continue
        var samples: Array = game.stroke_samples[s]
        var from_idx: int = game.sample_idx if s == game.cur_stroke else 0
        var i: int = from_idx + dot_every
        while i < samples.size():
            draw_circle(samples[i], 11.5, Color(0.02, 0.78, 1.0, 0.15))
            draw_circle(samples[i], 5.8, Color(0.73, 0.95, 1.0, 0.98))
            i += dot_every
    if game.cur_stroke >= game.stroke_samples.size():
        return
    var cur_samples: Array = game.stroke_samples[game.cur_stroke]
    if cur_samples.is_empty():
        return
    var idx: int = game.sample_idx
    var pos: Vector2 = cur_samples[idx]
    var ahead: Vector2 = cur_samples[mini(idx + 4, cur_samples.size() - 1)]
    var direction: Vector2 = (ahead - pos).normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.RIGHT
    var pulse: float = 1.0 + 0.10 * sin(_time * 5.0)
    var radius: float = 25.0 * pulse
    draw_circle(pos, radius + 11.0, Color(0.03, 0.85, 1.0, 0.14))
    draw_circle(pos, radius + 5.0, Color(0.73, 0.96, 1.0, 0.92))
    draw_circle(pos, radius, Color(0.02, 0.70, 0.91, 0.96))
    var tip: Vector2 = pos + direction * radius * 0.69
    var back: Vector2 = pos - direction * radius * 0.36
    var side: Vector2 = direction.orthogonal() * radius * 0.38
    draw_line(back, tip, Color.WHITE, 5.0, true)
    draw_colored_polygon(PackedVector2Array([
        tip + direction * radius * 0.24,
        tip + side - direction * radius * 0.10,
        tip - side - direction * radius * 0.10
    ]), Color.WHITE)
