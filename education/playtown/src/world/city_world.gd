extends Node2D
const BonusWheelOverlay := preload("res://education/playtown/src/world/items/bonus_wheel_overlay.gd")
@onready var hud: CanvasLayer = $CanvasLayer
@onready var coin_sound := AudioStreamPlayer.new()
@onready var bonus_sound := AudioStreamPlayer.new()
@onready var mom: Node2D = $Mom
@onready var seller: Node2D = $Seller
@onready var teacher: Node2D = $Teacher
@onready var classmate: Node2D = $Classmate
@onready var blue_house_entrance: Node2D = $BlueHouseEntrance
@onready var basketball_entrance: Node2D = $BasketballEntrance
@onready var ice_cream_entrance: Node2D = $IceCreamEntrance
@onready var forbidden_zone: Area2D = $RoadForbiddenZone
@onready var coin_spawner: Node = $CoinSpawner
@onready var player: Node2D = $Player
var bonus_wheel_overlay: CanvasLayer
func _ready() -> void:
	AccessService.start_preview()
	get_viewport().physics_object_picking = true
	coin_sound.stream = load("res://education/playtown/audio/sfx/coin.ogg")
	coin_sound.bus = "SFX"
	coin_sound.volume_db = +2
	add_child(coin_sound)
	bonus_sound.stream = load("res://education/playtown/audio/sfx/correct.ogg")
	bonus_sound.bus = "SFX"
	add_child(bonus_sound)
	_apply_localized_voices()
	_restore_player_position()
	mom.player_near_mom.connect(_on_player_near_mom_changed)
	seller.player_near_seller.connect(_on_player_near_seller_changed)
	teacher.player_near_teacher.connect(_on_player_near_teacher_changed)
	classmate.player_near_classmate.connect(_on_player_near_classmate_changed)
	blue_house_entrance.player_near_house.connect(_on_player_near_blue_house_changed)
	basketball_entrance.player_near_house.connect(_on_player_near_basketball_changed)
	ice_cream_entrance.player_near_house.connect(_on_player_near_ice_cream_changed)
	forbidden_zone.body_entered.connect(_on_road_forbidden_zone_body_entered)
	forbidden_zone.body_exited.connect(_on_road_forbidden_zone_body_exited)
	if coin_spawner.has_signal("coins_spawned"):
		coin_spawner.coins_spawned.connect(_on_coins_ready)
	if coin_spawner.has_signal("bonus_collected"):
		coin_spawner.bonus_collected.connect(_on_pet_bonus_collected)
func _apply_localized_voices() -> void:
	_set_character_voice(classmate, "classmate")
	_set_character_voice(mom, "mom")
	_set_character_voice(teacher, "teacher")
	_set_character_voice(seller, "seller")
func _set_character_voice(character: Node, voice_key: String) -> void:
	var player_node := character.get_node_or_null("TalkSound") as AudioStreamPlayer
	var stream := LanguageService.get_world_voice(voice_key)
	if player_node and stream:
		player_node.stream = stream
func _on_pet_bonus_collected(_item_id: String) -> void:
	_stop_player_movement()
	bonus_sound.play()
	if is_instance_valid(bonus_wheel_overlay):
		return
	bonus_wheel_overlay = BonusWheelOverlay.new()
	bonus_wheel_overlay.closed.connect(_on_bonus_wheel_closed)
	add_child(bonus_wheel_overlay)
func _on_bonus_wheel_closed() -> void:
	bonus_wheel_overlay = null
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_before_exit()
		get_tree().quit()
func _save_before_exit() -> void:
	if player:
		GameState.remember_main_player_position(player.global_position)
const SAFE_BOUNDS_LEFT := 42.0
const SAFE_BOUNDS_RIGHT := 3546.0
const SAFE_BOUNDS_TOP := 42.0
const SAFE_BOUNDS_BOTTOM := 2871.0
const SAFE_FALLBACK_POS := Vector2(1401, 1498)
func _restore_player_position() -> void:
	if player == null:
		return
	var info := GameState.consume_main_player_position()
	var pos: Vector2 = SAFE_FALLBACK_POS
	if info.get("has", false):
		var saved_pos: Vector2 = info["pos"]
		if _is_position_safe(saved_pos):
			pos = saved_pos
	player.global_position = pos
	GameState.remember_main_player_position(pos)
func _is_position_safe(pos: Vector2) -> bool:
	return pos.x >= SAFE_BOUNDS_LEFT and pos.x <= SAFE_BOUNDS_RIGHT \
		and pos.y >= SAFE_BOUNDS_TOP and pos.y <= SAFE_BOUNDS_BOTTOM
func _on_coins_ready() -> void:
	_connect_coins()
func _connect_coins() -> void:
	var coins := get_tree().get_nodes_in_group("coins")
	for coin in coins:
		if coin.has_signal("coin_collected"):
			coin.coin_collected.connect(_on_coin_collected)
func _on_coin_collected() -> void:
	hud.add_coin()
	coin_sound.play()
func _stop_player_movement() -> void:
	if player and player.has_method("stop_movement_until_released"):
		player.stop_movement_until_released()
func _on_player_near_mom_changed(near: bool) -> void:
	hud.set_can_talk_to_mom(near)
func _on_player_near_seller_changed(near: bool) -> void:
	hud.set_can_talk_to_seller(near)
func _on_player_near_teacher_changed(near: bool) -> void:
	hud.set_can_talk_to_teacher(near)
func _on_player_near_classmate_changed(near: bool) -> void:
	hud.set_can_talk_to_classmate(near)
func _on_player_near_blue_house_changed(near: bool) -> void:
	hud.set_can_enter_blue_house(near)
func _on_player_near_basketball_changed(near: bool) -> void:
	hud.set_can_enter_basketball(near)
func _on_player_near_ice_cream_changed(near: bool) -> void:
	hud.set_can_enter_ice_cream(near)
func _on_road_forbidden_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		hud.show_road_warning(true)
func _on_road_forbidden_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		hud.show_road_warning(false)
