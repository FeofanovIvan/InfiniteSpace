extends Node2D
## Gas is connected to BubbleBrain's 'gas' action, not a looping decoration.
var enabled: bool = false
var progress: float = 0.0
var origin: Vector2 = Vector2.ZERO

func set_state(active: bool, action_progress: float, at: Vector2) -> void:
    enabled = active
    progress = action_progress
    origin = at
    queue_redraw()

func _draw() -> void:
    if not enabled or progress < 0.38 or progress >= 0.97:
        return
    var phase: float = clampf((progress-.38)/.58,0.0,1.0)
    for i in range(28):
        var t: float = phase - float(i%9)*0.044
        if t < 0.0 or t > .75: continue
        var u: float = t/.75
        var px: float = origin.x+40.0+u*190.0 + 16.0*sin(float(i)*1.9+u*6.0)
        var py: float = origin.y+18.0-75.0*u + 45.0*sin(float(i)*2.7)
        var a: float = 0.45*(1.0-u) * clampf(u*8.0,0.0,1.0)
        var rad: float = 11.0+20.0*u+float(i%4)*3.0
        draw_circle(Vector2(px,py),rad*1.36,Color(.19,.84,.64,a*.26))
        draw_circle(Vector2(px,py),rad,Color(.45,.95,.75,a*.34))
        draw_arc(Vector2(px,py),rad*.82,-2.7,-.7,14,Color(.9,1,.95,a*.76),2.0,true)
