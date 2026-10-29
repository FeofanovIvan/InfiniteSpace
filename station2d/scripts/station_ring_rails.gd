extends Node2D
## Vector-only modular ring rails. Draws near and far arcs on separate CanvasItems.
@export var draw_front: bool = false
var ring_phase: float = 0.0
var module_count: int = 12
var tilt_rad: float = deg_to_rad(-23.0)
var orbit_radius_x: float = 195.0
var orbit_radius_y: float = 94.0

func orbit_point(angle: float, rx: float, ry: float) -> Vector2:
    var c: float = cos(tilt_rad)
    var s: float = sin(tilt_rad)
    var p: Vector2 = Vector2(cos(angle) * rx, sin(angle) * ry)
    return Vector2(p.x * c - p.y * s, p.x * s + p.y * c)

func _draw() -> void:
    var count: int = 144
    var beam_color: Color = Color("82a9bb") if draw_front else Color("39566c")
    var edge_color: Color = Color("d9edf2") if draw_front else Color("67899c")
    for rail in range(2):
        var rx: float = orbit_radius_x + (9.0 if rail == 0 else -9.0)
        var ry: float = orbit_radius_y + (4.0 if rail == 0 else -4.0)
        for i in range(count):
            var a: float = TAU * float(i) / float(count) + ring_phase
            var b: float = TAU * float(i+1) / float(count) + ring_phase
            var middle: float = (a+b)*0.5
            if (sin(middle) >= 0.0) != draw_front:
                continue
            var p1: Vector2 = orbit_point(a,rx,ry)
            var p2: Vector2 = orbit_point(b,rx,ry)
            draw_line(p1,p2,Color("162d40"),7.0,true)
            draw_line(p1,p2,beam_color,4.0,true)
            if rail == 0:
                draw_line(p1,p2,edge_color,1.3,true)
    # Structural crossbracing between two rails, not particles around the object.
    for i in range(module_count*4):
        var theta: float = TAU*float(i)/float(module_count*4)+ring_phase
        if (sin(theta)>=0.0) != draw_front:
            continue
        var o: Vector2 = orbit_point(theta,orbit_radius_x+9,orbit_radius_y+4)
        var inn: Vector2 = orbit_point(theta,orbit_radius_x-9,orbit_radius_y-4)
        draw_line(o,inn,Color("a5d9e5") if draw_front else Color("5d849b"),3.0,true)
    # A few long central supports behind sphere or passing in front on the near side.
    for j in range(8):
        var theta: float = TAU*float(j)/8.0+ring_phase
        if (sin(theta)>=0.0) != draw_front:
            continue
        var outer: Vector2 = orbit_point(theta,orbit_radius_x-9,orbit_radius_y-4)
        var inner: Vector2 = orbit_point(theta,82.0,39.0)
        draw_line(inner,outer,Color("142b3e"),10.0,true)
        draw_line(inner,outer,beam_color,6.0,true)
        draw_line(inner,outer,edge_color,1.4,true)
