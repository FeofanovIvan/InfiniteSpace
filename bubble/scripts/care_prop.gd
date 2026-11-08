extends Node2D
## Temporary generated props, shared by standalone care lab and unified actor.
@export var front_layer: bool = false

func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
    var pts := PackedVector2Array()
    for i in range(40):
        var a: float = float(i) * TAU / 40.0
        pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
    draw_colored_polygon(pts, color)

func _draw() -> void:
    var c: Node = get_parent()
    var mode: String = str(c.get("action"))
    var phase: float = float(c.get("elapsed"))
    var u: float = float(c.get("progress"))
    var act: float = clampf((u - 0.02) * 9.0, 0.0, 1.0) * (1.0 - clampf((u - 0.92) * 12.0, 0.0, 1.0))
    if mode == "eat" or mode == "drink":
        var cx: float = 153.0
        if not front_layer:
            _ellipse(Vector2(cx, 199), 87, 27, Color(0.015, 0.02, 0.055, 0.28))
            _ellipse(Vector2(cx, 181), 77, 30, Color("667fa5"))
            _ellipse(Vector2(cx, 172), 69, 23, Color("101d43"))
            if mode == "eat":
                for k in range(10):
                    var x: float = cx + sin(float(k) * 4.0) * 48.0
                    var y: float = 169.0 + cos(float(k) * 3.7) * 10.0
                    draw_circle(Vector2(x,y), 7.5, Color("c89b65"))
                    draw_circle(Vector2(x-2.0,y-2.0), 2.0, Color("ffdf9b"))
            else:
                _ellipse(Vector2(cx, 171), 61, 17, Color(0.28, 0.84, 1.0, 0.83))
                if act > 0.15:
                    for i in range(3):
                        var radius: float = 12.0 + fposmod(phase * 32.0 + i * 13.0, 42.0)
                        draw_arc(Vector2(cx+7.0, 170.0), radius, -2.8, -0.3, 30, Color(0.85, 1.0, 1.0, 0.35 * act), 1.8, true)
        else:
            _ellipse(Vector2(cx, 186), 79, 15, Color("92b3d8"))
            _ellipse(Vector2(cx, 181), 70, 9, Color("c4d8ef"))
    elif mode == "bath":
        if not front_layer:
            _ellipse(Vector2(0, 183), 231, 88, Color("253958"))
            draw_rect(Rect2(-226, 126, 452, 112), Color("5b85b4"))
            _ellipse(Vector2(0, 130), 224, 43, Color("a2c1e0"))
            _ellipse(Vector2(0, 130), 208, 31, Color("4aacc8"))
        else:
            draw_rect(Rect2(-225, 174, 450, 69), Color("688fb9"))
            _ellipse(Vector2(0, 176), 225, 28, Color("b4d4ec"))
            _ellipse(Vector2(0, 184), 210, 20, Color("789fcc"))
            for i in range(28):
                var n: float = float(i)
                var px: float = -192.0 + fposmod(n * 57.0, 389.0)
                var py: float = 151.0 + sin(n * 2.61 + phase * 1.08) * 10.0
                var size: float = 7.0 + fposmod(n * 3.3, 11.0)
                draw_circle(Vector2(px,py), size, Color(0.90, 0.97, 1.0, 0.56))
                draw_arc(Vector2(px,py), size*0.8, -2.7, -0.8, 14, Color(1,1,1,0.7), 1.1)
    elif mode == "brush_teeth" and front_layer:
        var oscillate: float = sin(phase * TAU * 2.6) * 11.0 * act
        # Toothbrush moves; existing face PNGs stay as-is.
        var brush_head: Vector2 = Vector2(32.0 + oscillate, 56.0 + oscillate * 0.35)
        draw_line(brush_head + Vector2(16, 5), brush_head + Vector2(72, 95), Color("6caaca"), 12.0, true)
        draw_line(brush_head + Vector2(16, 5), brush_head + Vector2(72, 95), Color("a7eaf8"), 7.0, true)
        draw_rect(Rect2(brush_head.x - 6.0, brush_head.y - 12.0, 32.0, 20.0), Color("f5f6ff"))
        for k in range(5):
            draw_line(brush_head + Vector2(-4.0+k*5.0,-12.0), brush_head + Vector2(-4.0+k*5.0,-23.0), Color("85d3e7"),2.0)
