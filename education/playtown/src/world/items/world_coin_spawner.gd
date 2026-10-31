extends Node
signal coins_spawned
signal bonus_collected(item_id: String)

const PetBonusCollectible := preload("res://education/playtown/src/world/items/pet_bonus_collectible.gd")
const QUESTION_TEXTURE := preload("res://education/playtown/assets/bonus_wheel/question.webp")

@export var coin_scene: PackedScene
@export var pickups_to_spawn := 10
@export var questions_to_spawn := 2
@onready var spawn_points := $"../SpawnPoints".get_children()

func _ready():
	call_deferred("_spawn_unique_coins")

func _spawn_unique_coins():
	var object_count := mini(pickups_to_spawn, spawn_points.size())
	var selected := _select_spread_points(object_count)
	selected.shuffle()
	var question_count := mini(mini(questions_to_spawn, GameState.get_session_pet_bonus_remaining()), selected.size())
	for index in selected.size():
		if index < question_count:
			_spawn_question_at(selected[index])
		else:
			_spawn_coin_at(selected[index])
	await get_tree().process_frame
	emit_signal("coins_spawned")

func _select_spread_points(amount: int) -> Array:
	var available := spawn_points.duplicate()
	var selected: Array = []
	if available.is_empty() or amount <= 0:
		return selected
	selected.append(available.pop_at(randi_range(0, available.size() - 1)))
	while selected.size() < amount and not available.is_empty():
		var best_index := 0
		var best_distance := -1.0
		for index in available.size():
			var point := available[index] as Marker2D
			var nearest := INF
			for chosen in selected:
				nearest = minf(nearest, point.global_position.distance_squared_to((chosen as Marker2D).global_position))
			if nearest > best_distance:
				best_distance = nearest
				best_index = index
		selected.append(available.pop_at(best_index))
	return selected

func _spawn_coin_at(point: Marker2D) -> void:
	var coin = coin_scene.instantiate()
	if coin is Node2D:
		coin.global_position = point.global_position
	else:
		coin.position = point.global_position
	get_parent().call_deferred("add_child", coin)

func _spawn_question_at(point: Marker2D) -> void:
	var collectible := PetBonusCollectible.new()
	collectible.configure("wheel", QUESTION_TEXTURE)
	collectible.collected.connect(_on_bonus_collected)
	collectible.global_position = point.global_position
	get_parent().call_deferred("add_child", collectible)

func _on_bonus_collected(item_id: String) -> void:
	bonus_collected.emit(item_id)
