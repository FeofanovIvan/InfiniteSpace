extends Node2D
signal player_near_mom(near: bool)
@export var game_select_scene_path: String = "res://education/playtown/scenes/screens/game_select_home.tscn"
@onready var talk_area: Area2D = $TalkArea
@onready var talk_sign: Sprite2D = $TalkSign
@onready var talk_sound: AudioStreamPlayer = $TalkSound
func _ready() -> void:
	talk_sound.bus = "VOICE"
	talk_sign.visible = false
	talk_area.body_entered.connect(_on_talk_area_body_entered)
	talk_area.body_exited.connect(_on_talk_area_body_exited)
	talk_area.input_pickable = true
	talk_area.input_event.connect(_on_talk_area_input_event)
func _on_talk_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_show_talk_sign()
		emit_signal("player_near_mom", true)
func _on_talk_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_hide_talk_sign()
		emit_signal("player_near_mom", false)
func _on_talk_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var is_press := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_press = true
	elif event is InputEventScreenTouch and event.pressed:
		is_press = true
	if is_press:
		go_to_game()
func go_to_game() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var stand_point: Vector2 = $TalkArea/CollisionShape2D.global_position
		player.global_position = stand_point
		GameState.remember_main_player_position(stand_point)
	var nav_panel := get_node_or_null("/root/Main/CanvasLayer/TopUI/NavPanel")
	if nav_panel and nav_panel.has_method("set_active_target"):
		nav_panel.set_active_target("Мама")
	SFX.transition_from_world(game_select_scene_path)
func _show_talk_sign() -> void:
	talk_sign.visible = true
	if talk_sound:
		talk_sound.play()
func _hide_talk_sign() -> void:
	talk_sign.visible = false
