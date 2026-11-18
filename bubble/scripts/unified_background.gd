extends Node2D
## Stylized space-workroom stage, without any baked character sprites.
func _draw() -> void:
    var size: Vector2 = get_viewport_rect().size
    for i in range(42):
        var t: float = float(i)/41.0
        draw_rect(Rect2(0, size.y*t, size.x, size.y/41.0+2), Color("06142b").lerp(Color("23436b"), t))
    var rng := RandomNumberGenerator.new()
    rng.seed = 4712026
    for i in range(145):
        var pt := Vector2(rng.randf_range(0,size.x),rng.randf_range(0,size.y*0.72))
        draw_circle(pt,rng.randf_range(0.5,1.8),Color(0.75,0.92,1.0,rng.randf_range(0.15,0.65)))
    var floor_y: float = size.y * 0.74
    draw_rect(Rect2(0,floor_y,size.x,size.y-floor_y),Color(0.045,0.082,0.165,1))
    draw_line(Vector2(0,floor_y),Vector2(size.x,floor_y),Color("477caa"),2.0)
    for j in range(8):
        var x: float = float(j) * size.x/7.0
        draw_line(Vector2(x,floor_y),Vector2(x - 70,size.y),Color(0.32,0.61,0.78,0.14),1.0)
