extends Node2D
## One handcrafted-but-procedurally-rendered Milky Way region, fixed in world
## coordinates (no timed respawns and no parallax drift of the landmark).
## The cloud image is generated once outside the game; GPU only draws a sprite.

const MILKY_WAY_TEXTURE: Texture2D = preload("res://assets/cosmic/milky_way_2048.png")
const GALAXY_CENTER: Vector2 = Vector2(6900.0, -3100.0)
const GALAXY_WORLD_SIZE: Vector2 = Vector2(8000.0, 4000.0)
const BLACK_HOLE_WORLD: Vector2 = Vector2(6500.0, -2950.0)

var _galaxy: Sprite2D
var _view_size: Vector2 = Vector2(1280.0, 720.0)
var _camera_world: Vector2 = Vector2.ZERO


func _ready() -> void:
    _galaxy = Sprite2D.new()
    _galaxy.name = "MilkyWay_GasDust_Anchored"
    _galaxy.texture = MILKY_WAY_TEXTURE
    _galaxy.centered = true
    _galaxy.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    _galaxy.scale = GALAXY_WORLD_SIZE / MILKY_WAY_TEXTURE.get_size()
    add_child(_galaxy)
    _update_position()


func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
    # Same absolute world address used by the planets, ship and mini-map.
    _camera_world = Vector2(sector) * 512.0 + local_position + camera_offset
    _update_position()


func resize_sky(view_size: Vector2) -> void:
    _view_size = view_size
    _update_position()


func _update_position() -> void:
    if not is_instance_valid(_galaxy):
        return
    _galaxy.position = GALAXY_CENTER - _camera_world + _view_size * 0.5
    # Cull based on the WORLD-SIZED bounds; avoid drawing a very large sprite
    # while the player is staying close to the Solar System.
    var half: Vector2 = GALAXY_WORLD_SIZE * 0.5
    var half_view: Vector2 = _view_size * 0.5
    var delta: Vector2 = GALAXY_CENTER - _camera_world
    _galaxy.visible = absf(delta.x) < half.x + half_view.x and absf(delta.y) < half.y + half_view.y
