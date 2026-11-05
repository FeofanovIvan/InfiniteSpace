extends Area2D
signal player_entered_zone
signal player_exited_zone
func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_entered_zone.emit()
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_exited_zone.emit()
