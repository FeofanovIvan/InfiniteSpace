extends Node

signal bonus_collected(item_id: String)

const PetBonusCollectible := preload("res://education/playtown/src/world/items/pet_bonus_collectible.gd")
const QUESTION_TEXTURE := "res://education/playtown/assets/bonus_wheel/question.webp"

@onready var coin_spawner: Node = get_parent().get_node("CoinSpawner")
@onready var spawn_points: Node2D = get_parent().get_node("SpawnPoints")


func _ready() -> void:
	if GameState.is_session_pet_bonus_collected():
		return
	if coin_spawner.has_signal("coins_spawned"):
		coin_spawner.coins_spawned.connect(_spawn_bonus, CONNECT_ONE_SHOT)
	else:
		call_deferred("_spawn_bonus")


func _spawn_bonus() -> void:
	if GameState.is_session_pet_bonus_collected():
		return
	var candidates := _available_points()
	if candidates.is_empty():
		return
	var selected: Marker2D
	var saved_name := GameState.get_session_pet_bonus_point()
	for point in candidates:
		if point.name == saved_name:
			selected = point
			break
	if selected == null:
		selected = candidates.pick_random()
		GameState.set_session_pet_bonus_point(String(selected.name))
	if not ResourceLoader.exists(QUESTION_TEXTURE):
		return
	var collectible := PetBonusCollectible.new()
	collectible.configure("wheel", load(QUESTION_TEXTURE))
	collectible.collected.connect(_on_collectible_collected)
	get_parent().add_child(collectible)
	collectible.global_position = selected.global_position


func _available_points() -> Array[Marker2D]:
	var all_points := spawn_points.get_children()
	var first_index := maxi(0, all_points.size() - 10)
	var candidates: Array[Marker2D] = []
	for index in range(first_index, all_points.size()):
		var point := all_points[index] as Marker2D
		if point and not _has_coin_at(point.global_position):
			candidates.append(point)
	return candidates


func _has_coin_at(point_position: Vector2) -> bool:
	for coin in get_tree().get_nodes_in_group("coins"):
		if coin is Node2D and (coin as Node2D).global_position.distance_to(point_position) < 20.0:
			return true
	return false


func _on_collectible_collected(item_id: String) -> void:
	bonus_collected.emit(item_id)
