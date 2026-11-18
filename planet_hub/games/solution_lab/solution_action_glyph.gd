extends Control
## Vector arrows for the two action buttons; no font-dependent unicode symbols.
var restart: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func _draw() -> void:
    var center: Vector2 = size * 0.5
    var s: float = minf(size.x,size.y)
    if s <= 4.0:
        return
    var light := Color("#e7fcff")
    var glow := Color(0.19,0.87,1.0,0.39)
    if restart:
        var radius: float = s*0.29
        draw_arc(center,radius,-PI*0.68,PI*1.07,36,glow,s*0.18,true)
        draw_arc(center,radius,-PI*0.68,PI*1.07,36,light,s*0.075,true)
        var tip := center + Vector2(cos(-PI*0.68),sin(-PI*0.68))*radius
        var a := tip + Vector2(-s*0.02,-s*0.26)
        var b := tip + Vector2(s*0.19,-s*0.04)
        draw_line(a,tip,light,s*0.075,true)
        draw_line(b,tip,light,s*0.075,true)
    else:
        var tail := Vector2(size.x*0.14,center.y)
        var tip := Vector2(size.x*0.87,center.y)
        var up := Vector2(size.x*0.61, size.y*0.25)
        var down := Vector2(size.x*0.61, size.y*0.75)
        for tint_width in [0.16,0.07]:
            var tint: Color = glow if tint_width > 0.1 else light
            draw_line(tail,tip,tint,s*tint_width,true)
            draw_line(up,tip,tint,s*tint_width,true)
            draw_line(down,tip,tint,s*tint_width,true)
