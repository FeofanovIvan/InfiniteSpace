extends Area2D
var player_inside: bool = false
var _bodies_inside: Dictionary = {}
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.is_in_group("pet"):
		_bodies_inside[body] = true
		player_inside = true
func _on_body_exited(body: Node) -> void:
	if _bodies_inside.has(body):
		_bodies_inside.erase(body)
	player_inside = _bodies_inside.size() > 0
