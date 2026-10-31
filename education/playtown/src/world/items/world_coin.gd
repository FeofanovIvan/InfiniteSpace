extends Sprite2D
signal coin_collected
@onready var area: Area2D = $Area2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_collect: AudioStreamPlayer2D = $SFX_Collect if has_node("SFX_Collect") else null
func _ready() -> void:
	add_to_group("coins")
	if anim:
		anim.play("spin")
	area.body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	coin_collected.emit()
	_play_collect_effect()
	queue_free()
func _play_collect_effect() -> void:
	if sfx_collect:
		sfx_collect.play()
