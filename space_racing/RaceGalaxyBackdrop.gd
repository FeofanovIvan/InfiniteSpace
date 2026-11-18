extends Node2D
## Static, texture-based orbital bodies for station-racing previews outside MW.
## Real planet art is taken from the existing InfiniteSpace atlas; no shaders or orbit animation.
const Generator = preload("res://space_racing/RaceRouteGenerator.gd")
var system_id: String = "lmc"
var _camera: Vector2 = Vector2.ZERO
var _screen: Vector2 = Vector2(1280.0, 720.0)
var _planet_textures: Array[Texture2D] = []

func _ready() -> void:
    _planet_textures.clear()
    for i in range(1, 9):
        var path: String = "res://assets/atlas/planets/%s_p%02d.png" % [system_id, i]
        var art: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
        _planet_textures.append(art)
    queue_redraw()

func resize_view(view: Vector2) -> void:
    _screen = view
    queue_redraw()

func set_camera_address(sector: Vector2i, local: Vector2, _offset: Vector2) -> void:
    _camera = Vector2(sector) * 512.0 + local
    queue_redraw()

func get_navigation_bodies() -> Array[Dictionary]:
    return Generator.bodies()

func _draw() -> void:
    var bodies: Array[Dictionary] = Generator.bodies()
    for i in range(bodies.size()):
        var body: Dictionary = bodies[i]
        var center: Vector2 = _screen * 0.5 + Vector2(body["world"]) - _camera
        var radius: float = float(body["radius"]) * 0.78
        if center.x < -radius or center.x > _screen.x + radius or center.y < -radius or center.y > _screen.y + radius:
            continue
        if i == 0:
            draw_circle(center, radius + 15.0, Color(0.98, 0.77, 0.36, 0.12))
            draw_circle(center, radius, Color("e9b96a"))
            draw_circle(center - Vector2(17, 17), radius * 0.70, Color("ffe1a0"))
            continue
        var art: Texture2D = _planet_textures[i - 1] if i - 1 < _planet_textures.size() else null
        if art != null:
            draw_texture_rect(art, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false)
        else:
            draw_circle(center, radius, Color("6ba4d1"))
