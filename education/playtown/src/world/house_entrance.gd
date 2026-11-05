extends Node2D

signal player_near_house(near: bool)

@export var target_scene_path := "res://education/playtown/scenes/features/house_search/house_search_game.tscn"
@onready var talk_area: Area2D = $TalkArea
@onready var talk_sign: Sprite2D = $TalkSign


func _ready() -> void:
	talk_sign.visible = false
	talk_area.body_entered.connect(_on_body_entered)
	talk_area.body_exited.connect(_on_body_exited)
	talk_area.input_pickable = true
	talk_area.input_event.connect(_on_input_event)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		talk_sign.visible = true
		player_near_house.emit(true)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		talk_sign.visible = false
		player_near_house.emit(false)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed):
		enter_house()


func enter_house() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		GameState.remember_main_player_position(player.global_position)
	SFX.transition_from_world(target_scene_path)

