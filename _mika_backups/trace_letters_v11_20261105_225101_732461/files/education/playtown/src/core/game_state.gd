extends Node
signal coin_balance_changed(balance: int)
const PREVIEW_START_COINS := 200
var total_coins: int = 0
var preview_coins: int = 0
var preview_coins_active: bool = false
var preview_coins_initialized: bool = false
var last_score: int = 0
var letters_traced: int = 0
var words_traced: int = 0
var numbers_traced: int = 0
var selected_character: String = "girl"
var last_nav_target: String = "Дом"
var main_player_pos: Vector2 = Vector2.ZERO
var has_main_player_pos: bool = false
var main_scene_path: String = "res://education/playtown/scenes/world/city_world.tscn"
var pet_owned: bool = false
var shop_items_owned: Dictionary = {}
const CONSUMABLE_SHOP_ITEMS := ["toothpaste", "shampoo", "bone", "water", "food"]
var shop_item_stock: Dictionary = {}
var session_pet_bonus_item_id := ""
var session_pet_bonus_point_name := ""
var session_pet_bonus_collected := false
var session_pet_bonus_collected_count := 0
const SESSION_PET_BONUS_LIMIT := 2
const PET_NEED_IDS := ["food", "water", "clean", "fun"]
var pet_need_levels: Dictionary = {
	"food": 0,
	"water": 0,
	"clean": 0,
	"fun": 0,
}
const SAVE_PATH := "user://miko_playtown_save_game.cfg"
func _ready() -> void:
	load_game()
func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	if preview_coins_active:
		preview_coins += amount
	else:
		total_coins += amount
	save_game()
	coin_balance_changed.emit(get_coin_balance())
func set_total_coins(value: int) -> void:
	total_coins = max(0, value)
	save_game()
	coin_balance_changed.emit(get_coin_balance())
func get_coin_balance() -> int:
	return total_coins + (preview_coins if preview_coins_active else 0)
func begin_preview_coins() -> void:
	if preview_coins_initialized:
		return
	preview_coins_initialized = true
	preview_coins_active = true
	preview_coins = PREVIEW_START_COINS
	save_game()
	coin_balance_changed.emit(get_coin_balance())
func clear_preview_coins() -> void:
	if not preview_coins_active and preview_coins <= 0:
		return
	preview_coins_active = false
	preview_coins = 0
	save_game()
	coin_balance_changed.emit(get_coin_balance())
func _spend_coins(price: int) -> bool:
	if price < 0 or get_coin_balance() < price:
		return false
	var remaining := price
	if preview_coins_active:
		var preview_spent := mini(preview_coins, remaining)
		preview_coins -= preview_spent
		remaining -= preview_spent
	total_coins = maxi(0, total_coins - remaining)
	save_game()
	coin_balance_changed.emit(get_coin_balance())
	return true
func set_letters_traced(value: int) -> void:
	letters_traced = clampi(value, 0, 26)
	save_game()
func set_words_traced(value: int) -> void:
	words_traced = maxi(0, value)
	save_game()
func set_numbers_traced(value: int) -> void:
	numbers_traced = maxi(0, value)
	save_game()
func set_selected_character(value: String) -> void:
	if value in ["girl", "boy"]:
		selected_character = value
		save_game()
func character_frames_path() -> String:
	return "res://education/playtown/assets/characters/%s/%s_frames.tres" % [selected_character, selected_character]
func remember_nav_target(label: String) -> void:
	last_nav_target = label
func remember_main_player_position(pos: Vector2) -> void:
	main_player_pos = pos
	has_main_player_pos = true
	save_game()
func consume_main_player_position() -> Dictionary:
	return {
		"has": has_main_player_pos,
		"pos": main_player_pos
	}
func has_pet_access() -> bool:
	return pet_owned or AccessService.has_preview_pet_access()
func buy_pet(price: int) -> bool:
	if pet_owned:
		return true
	if not _spend_coins(price):
		return false
	pet_owned = true
	save_game()
	return true
func buy_shop_item(item_id: String, price: int) -> bool:
	if not has_pet_access():
		return false
	if not is_shop_item_consumable(item_id) and is_shop_item_owned(item_id):
		return true
	if not _spend_coins(price):
		return false
	if is_shop_item_consumable(item_id):
		shop_item_stock[item_id] = get_shop_item_stock(item_id) + 1
	else:
		shop_items_owned[item_id] = true
	save_game()
	return true
func is_shop_item_owned(item_id: String) -> bool:
	if is_shop_item_consumable(item_id):
		return get_shop_item_stock(item_id) > 0
	return bool(shop_items_owned.get(item_id, false))
func is_shop_item_consumable(item_id: String) -> bool:
	return item_id in CONSUMABLE_SHOP_ITEMS
func get_shop_item_stock(item_id: String) -> int:
	return maxi(0, int(shop_item_stock.get(item_id, 0)))
func consume_shop_item(item_id: String) -> bool:
	if not is_shop_item_consumable(item_id):
		return false
	var current := get_shop_item_stock(item_id)
	if current <= 0:
		return false
	if current == 1:
		shop_item_stock.erase(item_id)
	else:
		shop_item_stock[item_id] = current - 1
	save_game()
	return true
func get_session_pet_bonus_item() -> String:
	if session_pet_bonus_item_id.is_empty():
		session_pet_bonus_item_id = String(CONSUMABLE_SHOP_ITEMS.pick_random())
	return session_pet_bonus_item_id
func get_session_pet_bonus_point() -> String:
	return session_pet_bonus_point_name
func set_session_pet_bonus_point(point_name: String) -> void:
	session_pet_bonus_point_name = point_name
func is_session_pet_bonus_collected() -> bool:
	return session_pet_bonus_collected_count >= SESSION_PET_BONUS_LIMIT
func get_session_pet_bonus_remaining() -> int:
	return maxi(0, SESSION_PET_BONUS_LIMIT - session_pet_bonus_collected_count)
func collect_session_pet_bonus(item_id: String) -> bool:
	if get_session_pet_bonus_remaining() <= 0 or item_id != "wheel":
		return false
	session_pet_bonus_collected_count += 1
	session_pet_bonus_collected = is_session_pet_bonus_collected()
	return true
func grant_bonus_wheel_item(item_id: String) -> bool:
	if item_id in CONSUMABLE_SHOP_ITEMS:
		if get_shop_item_stock(item_id) > 0:
			return false
		shop_item_stock[item_id] = 1
	elif item_id in ["collar", "house", "bed"]:
		if bool(shop_items_owned.get(item_id, false)):
			return false
		shop_items_owned[item_id] = true
	else:
		return false
	save_game()
	return true
func begin_pet_home_visit() -> void:
	for need_id in PET_NEED_IDS:
		pet_need_levels[need_id] = maxi(0, get_pet_need(need_id) - 50)
	save_game()
func get_pet_need(need_id: String) -> int:
	return clampi(int(pet_need_levels.get(need_id, 0)), 0, 100)
func increase_pet_need(need_id: String, amount: int = 100) -> void:
	if need_id not in PET_NEED_IDS:
		return
	pet_need_levels[need_id] = clampi(get_pet_need(need_id) + amount, 0, 100)
	save_game()
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("coins", "total_coins", total_coins)
	cfg.set_value("coins", "preview_coins", preview_coins)
	cfg.set_value("coins", "preview_active", preview_coins_active)
	cfg.set_value("coins", "preview_initialized", preview_coins_initialized)
	cfg.set_value("mini", "last_score", last_score)
	cfg.set_value("letters", "traced", letters_traced)
	cfg.set_value("words", "traced", words_traced)
	cfg.set_value("numbers", "traced", numbers_traced)
	cfg.set_value("player", "character", selected_character)
	cfg.set_value("main", "has_pos", has_main_player_pos)
	cfg.set_value("main", "player_pos_x", main_player_pos.x)
	cfg.set_value("main", "player_pos_y", main_player_pos.y)
	cfg.set_value("main", "scene_path", main_scene_path)
	cfg.set_value("shop", "pet_owned", pet_owned)
	cfg.set_value("shop", "items_owned", shop_items_owned)
	cfg.set_value("shop", "item_stock", shop_item_stock)
	cfg.set_value("pet_home", "need_levels", pet_need_levels)
	cfg.save(SAVE_PATH)
func load_game() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return
	total_coins = int(cfg.get_value("coins", "total_coins", 0))
	preview_coins = maxi(0, int(cfg.get_value("coins", "preview_coins", 0)))
	preview_coins_active = bool(cfg.get_value("coins", "preview_active", false))
	preview_coins_initialized = bool(cfg.get_value("coins", "preview_initialized", false))
	last_score = int(cfg.get_value("mini", "last_score", 0))
	letters_traced = int(cfg.get_value("letters", "traced", 0))
	words_traced = int(cfg.get_value("words", "traced", 0))
	numbers_traced = int(cfg.get_value("numbers", "traced", 0))
	selected_character = str(cfg.get_value("player", "character", "girl"))
	has_main_player_pos = bool(cfg.get_value("main", "has_pos", false))
	var x := float(cfg.get_value("main", "player_pos_x", 0.0))
	var y := float(cfg.get_value("main", "player_pos_y", 0.0))
	main_player_pos = Vector2(x, y)
	main_scene_path = str(cfg.get_value("main", "scene_path", main_scene_path))
	pet_owned = bool(cfg.get_value("shop", "pet_owned", false))
	shop_items_owned = cfg.get_value("shop", "items_owned", {})
	if not (shop_items_owned is Dictionary):
		shop_items_owned = {}
	shop_item_stock = cfg.get_value("shop", "item_stock", {})
	if not (shop_item_stock is Dictionary):
		shop_item_stock = {}
	pet_need_levels = cfg.get_value("pet_home", "need_levels", pet_need_levels)
	if not (pet_need_levels is Dictionary):
		pet_need_levels = {}
	for need_id in PET_NEED_IDS:
		pet_need_levels[need_id] = get_pet_need(need_id)
	for item_id in CONSUMABLE_SHOP_ITEMS:
		if bool(shop_items_owned.get(item_id, false)):
			shop_item_stock[item_id] = maxi(1, get_shop_item_stock(item_id))
			shop_items_owned.erase(item_id)
