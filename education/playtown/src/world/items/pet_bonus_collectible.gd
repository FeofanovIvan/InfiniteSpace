extends Area2D

signal collected(item_id: String)

var item_id := ""
var icon: Sprite2D
var collecting := false


func configure(value: String, texture: Texture2D) -> void:
	item_id = value
	icon = Sprite2D.new()
	icon.texture = texture
	var longest_side := maxf(float(texture.get_width()), float(texture.get_height()))
	icon.scale = Vector2.ONE * (118.0 / longest_side)
	add_child(icon)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 62.0
	shape_node.shape = shape
	add_child(shape_node)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	z_index = 12
	body_entered.connect(_on_body_entered)
	var start_y := icon.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(icon, "position:y", start_y - 12.0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(icon, "position:y", start_y, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node) -> void:
	if collecting or not body.is_in_group("player"):
		return
	if not GameState.collect_session_pet_bonus(item_id):
		return
	collecting = true
	set_deferred("monitoring", false)
	collected.emit(item_id)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(icon, "position:y", icon.position.y - 70.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", icon.scale * 1.28, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "modulate:a", 0.0, 0.42)
	tween.chain().tween_callback(queue_free)
