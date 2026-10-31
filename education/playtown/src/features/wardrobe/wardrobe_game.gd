extends Node2D
@export var item_scene: PackedScene
@export var items_data: Array[Dictionary] = []
@export var target_count: int = 10
@export var wrong_sound: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
@export var right_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const WARDROBE_TEXTURE: Texture2D = preload("res://education/playtown/assets/wardrobe/wardrobe.png")
const TABLE_TEXTURE: Texture2D = preload("res://education/playtown/assets/wardrobe/table.png")
const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const ZONE_SCRIPT: Script = preload("res://education/playtown/src/features/wardrobe/wardrobe_zone.gd")
const WARDROBE_VISIBLE_RECT := Rect2(105.0, 79.0, 1323.0, 767.0)
const REFERENCE_SIZE := Vector2(1536.0, 768.0)
const ZONE_LAYOUT := [
	{"category": "tshirt_white", "position": Vector2(0.125, 0.265)},
	{"category": "tshirt_blue", "position": Vector2(0.375, 0.265)},
	{"category": "tshirt_green", "position": Vector2(0.625, 0.265)},
	{"category": "tshirt_red", "position": Vector2(0.875, 0.265)},
	{"category": "shirt_blue", "position": Vector2(0.125, 0.625)},
	{"category": "skirt_red", "position": Vector2(0.375, 0.625)},
	{"category": "shirt_green", "position": Vector2(0.625, 0.625)},
	{"category": "skirt_blue", "position": Vector2(0.875, 0.625)},
]
var current_item
var game_over := false
var score := 0
var mistakes := 0
var rng := RandomNumberGenerator.new()
var background_layer: CanvasLayer
var wall: ColorRect
var floor: ColorRect
var wardrobe_sprite: Sprite2D
var table_sprite: Sprite2D
var zones_root: Node2D
var zones: Array = []
var ui_layer: CanvasLayer
var home_button: Button
var score_back: Panel
var score_icon: TextureRect
var score_label: Label
var error_flash: ColorRect
var wrong_player := AudioStreamPlayer.new()
var right_player := AudioStreamPlayer.new()
var instruction_player := AudioStreamPlayer.new()
var spawn_position := Vector2.ZERO
var item_display_size := Vector2(180.0, 155.0)
func _ready() -> void:
	_remove_legacy_layout()
	_build_responsive_layout()
	add_child(right_player)
	add_child(wrong_player)
	add_child(instruction_player)
	wrong_player.bus = "SFX"
	right_player.bus = "SFX"
	instruction_player.bus = "VOICE"
	if item_scene == null:
		return
	if items_data.is_empty():
		return
	rng.randomize()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	_update_score_label()
	_spawn_next_item()
	call_deferred("_play_instruction")


func _play_instruction() -> void:
	var stream := LanguageService.get_game_voice("wardrobe_intro")
	if stream == null:
		return
	instruction_player.stop()
	instruction_player.stream = stream
	instruction_player.play()
func _remove_legacy_layout() -> void:
	var old_hud := get_node_or_null("HUD")
	if old_hud:
		remove_child(old_hud)
		old_hud.queue_free()
	for child in get_children():
		if child is AudioStreamPlayer2D:
			child.stop()
			child.autoplay = false
func _build_responsive_layout() -> void:
	background_layer = CanvasLayer.new()
	background_layer.layer = -10
	add_child(background_layer)
	wall = ColorRect.new()
	wall.color = Color("#d9f2f4")
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(wall)
	floor = ColorRect.new()
	floor.color = Color("#f3d9a3")
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(floor)
	wardrobe_sprite = Sprite2D.new()
	wardrobe_sprite.texture = WARDROBE_TEXTURE
	wardrobe_sprite.region_enabled = true
	wardrobe_sprite.region_rect = WARDROBE_VISIBLE_RECT
	wardrobe_sprite.z_index = 0
	add_child(wardrobe_sprite)
	zones_root = Node2D.new()
	zones_root.name = "WardrobeAnchors"
	zones_root.z_index = 2
	add_child(zones_root)
	_build_zones()
	table_sprite = Sprite2D.new()
	table_sprite.texture = TABLE_TEXTURE
	table_sprite.z_index = 3
	add_child(table_sprite)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	home_button = GameExitButton.new()
	home_button.pressed.connect(_go_home)
	ui_layer.add_child(home_button)
	score_back = GameScorePanel.new()
	ui_layer.add_child(score_back)
	score_icon = (score_back as GameScorePanel).score_icon
	score_label = (score_back as GameScorePanel).score_label
	error_flash = ColorRect.new()
	error_flash.color = Color(0.92, 0.16, 0.14, 0.0)
	error_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	error_flash.visible = false
	ui_layer.add_child(error_flash)
func _build_zones() -> void:
	var textures_by_category := {}
	for data in items_data:
		textures_by_category[data.get("category", "")] = data.get("texture")
	for slot_data in ZONE_LAYOUT:
		var zone = Area2D.new()
		zone.set_script(ZONE_SCRIPT)
		zone.category = slot_data["category"]
		zones_root.add_child(zone)
		zone.setup(textures_by_category.get(zone.category))
		zones.append(zone)
func _layout_for_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var floor_top: float = viewport_size.y * 0.72
	wall.position = Vector2.ZERO
	wall.size = Vector2(viewport_size.x, floor_top)
	floor.position = Vector2(0.0, floor_top)
	floor.size = Vector2(viewport_size.x, viewport_size.y - floor_top)
	error_flash.position = Vector2.ZERO
	error_flash.size = viewport_size
	var wardrobe_scale: float = minf(
		viewport_size.x * 0.88 / WARDROBE_VISIBLE_RECT.size.x,
		viewport_size.y * 0.91 / WARDROBE_VISIBLE_RECT.size.y
	)
	wardrobe_sprite.scale = Vector2.ONE * wardrobe_scale
	wardrobe_sprite.position = Vector2(
		viewport_size.x * 0.5,
		WARDROBE_VISIBLE_RECT.size.y * wardrobe_scale * 0.5
	)
	var visible_size: Vector2 = WARDROBE_VISIBLE_RECT.size * wardrobe_scale
	var visible_top_left: Vector2 = wardrobe_sprite.position - visible_size * 0.5
	var zone_size := Vector2(visible_size.x * 0.20, visible_size.y * 0.32)
	for index in zones.size():
		var relative_position: Vector2 = ZONE_LAYOUT[index]["position"]
		zones[index].position = visible_top_left + visible_size * relative_position
		zones[index].set_display_size(zone_size)
	var table_width: float = minf(viewport_size.x * 0.86, visible_size.x * 1.05)
	var table_scale: float = table_width / float(TABLE_TEXTURE.get_width())
	table_sprite.scale = Vector2.ONE * table_scale
	var table_height: float = float(TABLE_TEXTURE.get_height()) * table_scale
	table_sprite.position = Vector2(
		viewport_size.x * 0.5,
		viewport_size.y - table_height * 0.48
	)
	var safe_scale: float = minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	safe_scale = clampf(safe_scale, 0.62, 1.35)
	var button_size: float = 106.0 * safe_scale
	var edge: float = 18.0 * safe_scale
	home_button.position = Vector2(edge, edge)
	home_button.size = Vector2.ONE * button_size
	var score_size: Vector2 = Vector2(225.0, 88.0) * safe_scale
	score_back.position = Vector2(viewport_size.x - score_size.x - edge, edge)
	score_back.size = score_size
	score_icon.position = Vector2(9.0, 7.0) * safe_scale
	score_icon.size = Vector2.ONE * 72.0 * safe_scale
	score_label.position = Vector2(82.0, 4.0) * safe_scale
	score_label.size = Vector2(132.0, 80.0) * safe_scale
	score_label.add_theme_font_size_override("font_size", int(42.0 * safe_scale))
	item_display_size = zone_size
	spawn_position = Vector2(
		viewport_size.x * 0.5,
		table_sprite.position.y - table_height * 0.15
	)
	if current_item and is_instance_valid(current_item) and not current_item.dragging:
		current_item.global_position = spawn_position
		current_item.set_display_size(item_display_size)
func _show_error_flash() -> void:
	if wrong_sound:
		wrong_player.stop()
		wrong_player.stream = wrong_sound
		wrong_player.play()
	error_flash.visible = true
	error_flash.color.a = 0.48
	var tween := create_tween()
	tween.tween_property(error_flash, "color:a", 0.0, 0.45)
	tween.finished.connect(func() -> void: error_flash.visible = false)
func _play_correct_feedback() -> void:
	if right_sound:
		right_player.stop()
		right_player.stream = right_sound
		right_player.play()
func _update_score_label() -> void:
	score_label.text = str(GameState.get_coin_balance())
func _spawn_next_item() -> void:
	if game_over:
		return
	if current_item and is_instance_valid(current_item):
		current_item.queue_free()
	var data := items_data[rng.randi_range(0, items_data.size() - 1)]
	current_item = item_scene.instantiate()
	add_child(current_item)
	current_item.global_position = spawn_position
	current_item.category = data.get("category", "")
	current_item.sprite.texture = data.get("texture")
	current_item.voice = LanguageService.get_clothing_voice(
		current_item.category,
		data.get("voice") as AudioStream
	)
	current_item.set_display_size(item_display_size)
	current_item.dropped.connect(_on_item_dropped)
func _on_item_dropped(item) -> void:
	if game_over:
		return
	var correct_zone
	var wrong_zone
	for area in item.get_overlapping_areas():
		if not area.is_in_group("wardrobe_zone"):
			continue
		if area.category == item.category:
			correct_zone = area
			break
		if wrong_zone == null:
			wrong_zone = area
	if correct_zone:
		item.global_position = correct_zone.global_position
		score += 1
		_update_score_label()
		GameState.last_score = score
		GameState.add_coins(1)
		_play_correct_feedback()
		SFX.play_praise(get_viewport_rect().size * 0.5, 0.35)
		if score >= target_count:
			_end_game()
		else:
			_spawn_next_item()
	else:
		mistakes += 1
		_show_error_flash()
		SFX.play_retry(get_viewport_rect().size * 0.5)
		if wrong_zone:
			wrong_zone.show_error_mark()
		_spawn_next_item()
func _go_home() -> void:
	SFX.transition_to_scene("res://education/playtown/scenes/screens/game_select_home.tscn")
func _end_game() -> void:
	if game_over:
		return
	game_over = true
	GameState.last_score = score
	SFX.transition_to_scene("res://education/playtown/scenes/screens/game_select_home.tscn")
