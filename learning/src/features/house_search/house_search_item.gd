class_name HouseSearchItem
extends Sprite2D

var item_data: Dictionary
var floor_number := 1
var interaction_distance := 105.0


func configure(data: Dictionary, item_floor: int, item_position: Vector2, target_height: float) -> void:
	item_data = data
	floor_number = item_floor
	position = item_position
	texture = data.get("texture") as Texture2D
	if texture:
		var image_size := texture.get_size()
		var visible_rect := _visible_pixel_rect(texture)
		var factor := target_height / maxf(1.0, visible_rect.size.y)
		scale = Vector2.ONE * factor
		# The node position is the surface contact point. Offset the visual so
		# the bottom-center of its non-transparent pixels lands on that point.
		offset = Vector2(
			image_size.x * 0.5 - (visible_rect.position.x + visible_rect.size.x * 0.5),
			image_size.y * 0.5 - (visible_rect.position.y + visible_rect.size.y)
		)


func _visible_pixel_rect(source_texture: Texture2D) -> Rect2:
	var image := source_texture.get_image()
	if image == null or image.is_empty():
		return Rect2(Vector2.ZERO, source_texture.get_size())
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Rect2(Vector2.ZERO, source_texture.get_size())
	return Rect2(used)


func can_use(player_x: float, active_floor: int) -> bool:
	return visible and floor_number == active_floor and absf(position.x - player_x) <= interaction_distance
