extends Node

const DESIGN_SIZE := Vector2(1536.0, 864.0)
const TARGET_COUNT := 5
const ROUND_ITEM_COUNT := 10
const NON_KITCHEN_COUNT := 6
const DOOR_X := 768.0
const DOOR_DISTANCE := 112.0
const HOUSE_CROP_Y := 80.0
const CORRECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const MEADOW_BACKGROUND: Texture2D = preload("res://education/playtown/assets/house_search/sunny_cartoon_meadow.png")
const LearningObjectCatalog := preload("res://education/playtown/src/features/shared/learning_object_catalog.gd")
const ProductCatalog := preload("res://education/playtown/src/features/shared/product_catalog.gd")
const HouseSearchPlayerScript := preload("res://education/playtown/src/features/house_search/house_search_player.gd")
const HouseSearchItemScript := preload("res://education/playtown/src/features/house_search/house_search_item.gd")
const UseButtonScript := preload("res://education/playtown/src/features/house_search/use_button.gd")
const GameExitButtonScript := preload("res://education/playtown/src/ui/game_exit_button.gd")
const JoystickScript := preload("res://education/playtown/src/ui/child_joystick.gd")

# Six non-kitchen and four kitchen items are selected each round. Kitchenware
# comes from LearningObjectCatalog; food comes from ProductCatalog.
const NON_KITCHEN_KEYS: Array[String] = [
	"pencil", "book", "ball", "doll", "toy_car", "cube", "backpack",
	"clock", "lamp", "hat", "socks", "boots", "tshirt", "jacket", "umbrella",
]
const KITCHENWARE_KEYS: Array[String] = ["cup", "plate", "spoon"]
const PRODUCT_KEYS: Array[String] = [
	"apple", "banana", "orange", "pear", "grapes", "strawberry",
	"carrot", "milk", "bread", "cheese", "juice", "cookies",
]

# Positions use the full 1536x1024 source-image coordinate system. They are
# converted once to the cropped 1536x864 gameplay coordinate system.
const SPAWN_POINTS := {
	"bed_l": {"position": Vector2(370, 445), "floor": 2, "zone": "second"},
	"bed_r": {"position": Vector2(445, 445), "floor": 2, "zone": "second"},
	"desk_l": {"position": Vector2(935, 418), "floor": 2, "zone": "second"},
	"desk_r": {"position": Vector2(1070, 418), "floor": 2, "zone": "second"},
	"up_rug": {"position": Vector2(590, 515), "floor": 2, "zone": "second"},
	"up_floor_r": {"position": Vector2(1260, 520), "floor": 2, "zone": "second"},
	"sofa": {"position": Vector2(335, 752), "floor": 1, "zone": "living"},
	"living_floor_l": {"position": Vector2(190, 842), "floor": 1, "zone": "living"},
	"living_floor_c": {"position": Vector2(330, 842), "floor": 1, "zone": "living"},
	"living_floor_r": {"position": Vector2(470, 842), "floor": 1, "zone": "living"},
	"counter_l1": {"position": Vector2(955, 718), "floor": 1, "zone": "kitchen"},
	"counter_l2": {"position": Vector2(1020, 718), "floor": 1, "zone": "kitchen"},
	"counter_r1": {"position": Vector2(1235, 718), "floor": 1, "zone": "kitchen"},
	"counter_r2": {"position": Vector2(1275, 718), "floor": 1, "zone": "kitchen"},
	"table_l": {"position": Vector2(1075, 750), "floor": 1, "zone": "kitchen"},
	"table_c": {"position": Vector2(1150, 750), "floor": 1, "zone": "kitchen"},
	"table_r": {"position": Vector2(1225, 750), "floor": 1, "zone": "kitchen"},
}

const KITCHEN_SURFACES: Array[String] = [
	"counter_l1", "counter_l2", "counter_r1", "counter_r2",
	"table_l", "table_c", "table_r",
]
const KITCHEN_TALL_SURFACES: Array[String] = [
	"counter_l1", "counter_l2", "counter_r1", "counter_r2", "table_l", "table_r",
]
const ITEM_ALLOWED_POINTS := {
	"pencil": ["desk_l", "desk_r", "bed_l"],
	"book": ["bed_l", "bed_r", "desk_l", "desk_r", "sofa"],
	"ball": ["up_rug", "up_floor_r", "living_floor_l", "living_floor_c", "living_floor_r"],
	"doll": ["bed_l", "bed_r", "sofa", "up_rug", "living_floor_c"],
	"toy_car": ["up_rug", "up_floor_r", "living_floor_l", "living_floor_c", "living_floor_r"],
	"cube": ["bed_l", "bed_r", "up_rug", "living_floor_l", "living_floor_c", "sofa"],
	"backpack": ["up_floor_r", "living_floor_l", "living_floor_r"],
	"clock": ["desk_l", "desk_r"],
	"lamp": ["desk_l", "desk_r"],
	"cup": KITCHEN_SURFACES,
	"plate": ["counter_l1", "counter_l2", "counter_r1", "table_l", "table_c", "table_r"],
	"spoon": ["counter_l1", "counter_l2", "counter_r1", "table_l", "table_c", "table_r"],
	"hat": ["bed_l", "bed_r", "sofa", "desk_l"],
	"socks": ["bed_l", "bed_r", "sofa", "up_rug", "living_floor_c"],
	"boots": ["up_floor_r", "living_floor_l", "living_floor_r"],
	"tshirt": ["bed_l", "bed_r"],
	"jacket": ["bed_l", "bed_r", "sofa"],
	"umbrella": ["up_floor_r", "living_floor_r"],
	"apple": KITCHEN_SURFACES,
	"banana": KITCHEN_SURFACES,
	"orange": KITCHEN_SURFACES,
	"pear": KITCHEN_SURFACES,
	"grapes": KITCHEN_SURFACES,
	"strawberry": KITCHEN_SURFACES,
	"carrot": KITCHEN_SURFACES,
	"milk": KITCHEN_TALL_SURFACES,
	"bread": KITCHEN_SURFACES,
	"cheese": KITCHEN_SURFACES,
	"juice": KITCHEN_TALL_SURFACES,
	"cookies": KITCHEN_SURFACES,
}

const ITEM_HEIGHTS := {
	"pencil": 50.0, "spoon": 48.0,
	"book": 58.0, "clock": 56.0, "lamp": 62.0, "cup": 54.0, "plate": 48.0,
	"ball": 62.0, "toy_car": 58.0, "cube": 58.0,
	"milk": 66.0, "juice": 66.0, "umbrella": 72.0,
}

const ITEM_SIZE_CLASSES := {
	"pencil": "small", "spoon": "small", "cookies": "small",
	"backpack": "large", "boots": "large", "jacket": "large", "umbrella": "large",
	"bread": "large", "milk": "large", "juice": "large", "banana": "large", "grapes": "large",
}
const SIZE_SAFETY_MARGINS := {"small": 9.0, "medium": 13.0, "large": 18.0}
# Prevent two items in one narrow visual column when their anchors are
# vertically staggered (e.g. sofa vs floor, counter vs table).
# Keep same-height points governed by existing texture-bounds collision checks.
const STACK_COLUMN_DISTANCE := 58.0
const STACK_MIN_VERTICAL_DISTANCE := 18.0
const STACK_MAX_VERTICAL_DISTANCE := 145.0

var world_layer: Node2D
var player: HouseSearchPlayer
var first_floor_door: TextureRect
var second_floor_door: TextureRect
var ui_root: Control
var goal_icon: TextureButton
var found_strip: HBoxContainer
var score_label: Label
var use_control: Control
var use_button: Button
var movement_joystick: ChildJoystick
var current_floor := 1
var transitioning := false
var round_completed := false
var score := 0
var nearby_item: HouseSearchItem
var spawned_items: Array[HouseSearchItem] = []
var target_queue: Array[HouseSearchItem] = []
var current_target: HouseSearchItem
var closed_door_texture: Texture2D = preload("res://education/playtown/assets/house_search/door_closed.png")
var open_door_texture: Texture2D = preload("res://education/playtown/assets/house_search/door_open.png")
var item_visual_size_cache := {}


func _ready() -> void:
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--house-spawn-self-test"):
		_run_layout_self_test(100)
		return
	_create_background()
	_create_house_world()
	_create_ui()
	_start_round()
	get_viewport().size_changed.connect(_layout_world)
	_layout_world()


func _run_layout_self_test(generation_count: int) -> void:
	var all_keys := NON_KITCHEN_KEYS.duplicate()
	all_keys.append_array(KITCHENWARE_KEYS)
	all_keys.append_array(PRODUCT_KEYS)
	if all_keys.size() != 30:
		push_error("House-search pool must contain 30 items, found %d" % all_keys.size())
		get_tree().quit(1)
		return
	for key in all_keys:
		var visual_size := _visual_size_for_key(key)
		if visual_size.x <= 0.0 or visual_size.y <= 0.0:
			push_error("Invalid visible bounds for %s" % key)
			get_tree().quit(1)
			return
	for generation in range(generation_count):
		var layout := generate_round_layout()
		if layout.size() != ROUND_ITEM_COUNT:
			push_error("Generation %d has %d items" % [generation, layout.size()])
			get_tree().quit(1)
			return
		var keys := {}
		var points := {}
		var zones := {"second": 0, "living": 0, "kitchen": 0}
		for placement in layout:
			var key := String(placement.key)
			var point_id := String(placement.point_id)
			if keys.has(key) or points.has(point_id):
				push_error("Generation %d contains a duplicate item or point" % generation)
				get_tree().quit(1)
				return
			if not (ITEM_ALLOWED_POINTS.get(key, []) as Array).has(point_id):
				push_error("Generation %d placed %s at forbidden point %s" % [generation, key, point_id])
				get_tree().quit(1)
				return
			keys[key] = true
			points[point_id] = true
			var point: Dictionary = SPAWN_POINTS[point_id]
			var zone := String(point.zone)
			zones[zone] = int(zones[zone]) + 1
		for left_index in range(layout.size()):
			for right_index in range(left_index + 1, layout.size()):
				var left: Dictionary = layout[left_index]
				var right: Dictionary = layout[right_index]
				if _points_stack_vertically(String(left.point_id), String(right.point_id)):
					push_error("Generation %d stacks items at %s and %s" % [generation, String(left.point_id), String(right.point_id)])
					get_tree().quit(1)
					return
				var margin := maxf(_safety_margin_for(String(left.key)), _safety_margin_for(String(right.key)))
				if _item_rect_at_point(String(left.key), String(left.point_id)).grow(margin).intersects(
					_item_rect_at_point(String(right.key), String(right.point_id))
				):
					push_error("Generation %d contains overlapping items" % generation)
					get_tree().quit(1)
					return
		if int(zones.second) < 2 or int(zones.living) < 2 or int(zones.kitchen) != 4:
			push_error("Generation %d has invalid zone distribution: %s" % [generation, zones])
			get_tree().quit(1)
			return
		if not _kitchen_layout_is_balanced(layout):
			push_error("Generation %d does not split kitchen items between counter and table" % generation)
			get_tree().quit(1)
			return
	print("PASS: %d valid randomized house-search layouts" % generation_count)
	get_tree().quit(0)


func _process(_delta: float) -> void:
	if player == null:
		return
	nearby_item = _find_nearby_item()
	var near_door := absf(player.position.x - DOOR_X) <= DOOR_DISTANCE
	use_button.set_stairs_up(current_floor == 1)
	use_button.set_door_mode(nearby_item == null and near_door)
	use_control.visible = not transitioning and (nearby_item != null or near_door)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_exit_to_city()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE):
		if use_control.visible:
			_use_current_interaction()


func _create_background() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -10
	add_child(background_layer)
	var meadow := TextureRect.new()
	meadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	meadow.texture = MEADOW_BACKGROUND
	meadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	meadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(meadow)


func _create_house_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "HouseWorld"
	add_child(world_layer)

	var house := Sprite2D.new()
	house.name = "House"
	house.centered = false
	house.texture = preload("res://education/playtown/assets/house_search/house_cutaway.png")
	house.region_enabled = true
	house.region_rect = Rect2(0, 80, 1536, 864)
	world_layer.add_child(house)

	second_floor_door = _make_door(Rect2(694, 185, 148, 265))
	first_floor_door = _make_door(Rect2(697, 530, 142, 227))

	player = HouseSearchPlayerScript.new()
	player.name = "Player"
	player.z_index = 10
	player.position = Vector2(DOOR_X, 725)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = load(GameState.character_frames_path()) as SpriteFrames
	sprite.animation = &"walk_down"
	sprite.scale = Vector2(0.95, 0.95)
	player.add_child(sprite)
	world_layer.add_child(player)


func _make_door(rect: Rect2) -> TextureRect:
	var door := TextureRect.new()
	door.z_index = 8
	door.position = rect.position
	door.size = rect.size
	door.texture = closed_door_texture
	door.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	door.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_layer.add_child(door)
	return door


func _create_ui() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(ui_root)

	_create_goal_ui()
	_create_score_and_exit()
	_create_dpad()
	_create_use_button()


func _create_goal_ui() -> void:
	var ring := TextureRect.new()
	ring.position = Vector2(24, 24)
	ring.size = Vector2(140, 140)
	ring.texture = preload("res://education/playtown/assets/ui/navigation_circle.png")
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(ring)

	goal_icon = TextureButton.new()
	goal_icon.position = Vector2(46, 46)
	goal_icon.size = Vector2(96, 96)
	goal_icon.ignore_texture_size = true
	goal_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	goal_icon.focus_mode = Control.FOCUS_NONE
	goal_icon.pressed.connect(_play_target_voice)
	ui_root.add_child(goal_icon)

	found_strip = HBoxContainer.new()
	found_strip.position = Vector2(178, 54)
	found_strip.add_theme_constant_override("separation", 10)
	ui_root.add_child(found_strip)
	for index in range(TARGET_COUNT):
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(68, 68)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.modulate = Color(1, 1, 1, 0.22)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		found_strip.add_child(slot)


func _create_score_and_exit() -> void:
	var exit_button: Button = GameExitButtonScript.new()
	exit_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	exit_button.position = Vector2(-112, 18)
	exit_button.size = Vector2(94, 94)
	exit_button.pressed.connect(_exit_to_city)
	ui_root.add_child(exit_button)

	var score_box := Control.new()
	score_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score_box.position = Vector2(-260, 26)
	score_box.size = Vector2(130, 78)
	ui_root.add_child(score_box)
	var star := TextureRect.new()
	star.size = Vector2(70, 70)
	star.texture = preload("res://education/playtown/assets/ui/star.png")
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_box.add_child(star)
	score_label = Label.new()
	score_label.position = Vector2(66, 5)
	score_label.size = Vector2(64, 64)
	score_label.text = "0"
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 38)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_outline_color", Color("#75420d"))
	score_label.add_theme_constant_override("outline_size", 7)
	score_box.add_child(score_label)


func _create_dpad() -> void:
	movement_joystick = JoystickScript.new() as ChildJoystick
	movement_joystick.name = "ChildJoystick"
	# Keep the joystick in viewport coordinates. A bottom-right anchor combined
	# with a negative `position` placed it outside this full-screen UI root on
	# some aspect ratios, so the control existed but was not visible.
	movement_joystick.set_anchors_preset(Control.PRESET_TOP_LEFT)
	movement_joystick.z_index = 100
	movement_joystick.size = Vector2(220, 220)
	movement_joystick.direction_changed.connect(player.set_touch_direction)
	ui_root.add_child(movement_joystick)


func _create_use_button() -> void:
	use_control = Control.new()
	use_control.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	use_control.position = Vector2(28, -188)
	use_control.size = Vector2(160, 160)
	use_control.visible = false
	ui_root.add_child(use_control)
	use_button = UseButtonScript.new()
	use_button.size = Vector2(154, 154)
	use_button.pressed.connect(_use_current_interaction)
	use_control.add_child(use_button)


func _layout_world() -> void:
	if world_layer == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	world_layer.scale = Vector2.ONE * factor
	world_layer.position = (viewport_size - DESIGN_SIZE * factor) * 0.5
	if movement_joystick != null:
		var safe := _safe_area_insets(viewport_size)
		var side := clampf(minf(viewport_size.x, viewport_size.y) * 0.245, 154.0, 220.0)
		movement_joystick.size = Vector2.ONE * side
		movement_joystick.position = Vector2(
			viewport_size.x - safe.z - side - maxf(18.0, side * 0.10),
			viewport_size.y - safe.w - side - maxf(16.0, side * 0.08)
		)


func _safe_area_insets(view: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_view := view / window_size
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	return Vector4(
		float(safe_rect.position.x) * scale_to_view.x,
		float(safe_rect.position.y) * scale_to_view.y,
		right_px * scale_to_view.x,
		bottom_px * scale_to_view.y
	)


func _start_round() -> void:
	for item in spawned_items:
		if is_instance_valid(item):
			item.queue_free()
	spawned_items.clear()
	target_queue.clear()
	var locale := LanguageService.learning_locale
	var objects_by_key := _index_entries(LearningObjectCatalog.all(locale, "objects"))
	var products_by_key := _index_entries(ProductCatalog.all(locale))
	var layout := generate_round_layout()
	for placement in layout:
		var key := String(placement.key)
		var data: Dictionary = products_by_key.get(key, {}) if PRODUCT_KEYS.has(key) else objects_by_key.get(key, {})
		_spawn_item(data, String(placement.point_id))
	if spawned_items.size() != ROUND_ITEM_COUNT:
		push_error("House search expected %d items, spawned %d" % [ROUND_ITEM_COUNT, spawned_items.size()])
	target_queue.assign(spawned_items)
	target_queue.shuffle()
	while target_queue.size() > TARGET_COUNT:
		target_queue.pop_back()
	_show_next_target()
	_create_debug_spawn_markers()


func generate_round_layout() -> Array[Dictionary]:
	var kitchen_pool := KITCHENWARE_KEYS.duplicate()
	kitchen_pool.append_array(PRODUCT_KEYS)
	for _attempt in range(64):
		var non_kitchen := _random_subset(NON_KITCHEN_KEYS, NON_KITCHEN_COUNT)
		var kitchen := _random_subset(kitchen_pool, ROUND_ITEM_COUNT - NON_KITCHEN_COUNT)
		var used_points := {}
		var layout: Array[Dictionary] = []
		var second_count := randi_range(2, 4)
		var non_kitchen_limits := {"second": second_count, "living": NON_KITCHEN_COUNT - second_count}
		if not _assign_items(non_kitchen, 0, used_points, layout, non_kitchen_limits, {}):
			continue
		if not _assign_items(kitchen, 0, used_points, layout, {"kitchen": kitchen.size()}, {}):
			continue
		if not _kitchen_layout_is_balanced(layout):
			continue
		layout.shuffle()
		return layout
	push_error("Could not create a valid house-search layout")
	return []


func _random_subset(source: Array[String], count: int) -> Array[String]:
	var shuffled := source.duplicate()
	shuffled.shuffle()
	var result: Array[String] = []
	for index in range(mini(count, shuffled.size())):
		result.append(shuffled[index])
	return result


func _assign_items(
	keys: Array[String],
	index: int,
	used_points: Dictionary,
	placements: Array[Dictionary],
	zone_limits: Dictionary,
	zone_counts: Dictionary
) -> bool:
	if index >= keys.size():
		for zone in zone_limits:
			if int(zone_counts.get(zone, 0)) != int(zone_limits[zone]):
				return false
		return true
	var key := keys[index]
	var candidates: Array = (ITEM_ALLOWED_POINTS.get(key, []) as Array).duplicate()
	candidates.shuffle()
	for point_value in candidates:
		var point_id := String(point_value)
		if used_points.has(point_id):
			continue
		var point: Dictionary = SPAWN_POINTS.get(point_id, {})
		var zone := String(point.get("zone", ""))
		if not zone_limits.has(zone):
			continue
		var next_zone_count := int(zone_counts.get(zone, 0)) + 1
		if next_zone_count > int(zone_limits[zone]):
			continue
		if _placement_overlaps(key, point_id, placements):
			continue
		used_points[point_id] = true
		zone_counts[zone] = next_zone_count
		placements.append({"key": key, "point_id": point_id})
		if _assign_items(keys, index + 1, used_points, placements, zone_limits, zone_counts):
			return true
		placements.pop_back()
		used_points.erase(point_id)
		if next_zone_count == 1:
			zone_counts.erase(zone)
		else:
			zone_counts[zone] = next_zone_count - 1
	return false


func _kitchen_layout_is_balanced(placements: Array[Dictionary]) -> bool:
	var has_counter := false
	var has_table := false
	var kitchen_count := 0
	for placement in placements:
		var point_id := String(placement.point_id)
		var point: Dictionary = SPAWN_POINTS[point_id]
		if String(point.zone) != "kitchen":
			continue
		kitchen_count += 1
		has_table = has_table or point_id.begins_with("table_")
		has_counter = has_counter or point_id.begins_with("counter_")
	return kitchen_count == ROUND_ITEM_COUNT - NON_KITCHEN_COUNT and has_counter and has_table


func _placement_overlaps(key: String, point_id: String, placements: Array[Dictionary]) -> bool:
	var candidate_rect := _item_rect_at_point(key, point_id)
	var candidate_margin := _safety_margin_for(key)
	for placement in placements:
		var placed_key := String(placement.key)
		var placed_point_id := String(placement.point_id)
		# Two items must never appear in one vertical sightline,
		# even if their visible rectangles do not actually intersect.
		if _points_stack_vertically(point_id, placed_point_id):
			return true
		var safe_margin := maxf(candidate_margin, _safety_margin_for(placed_key))
		if candidate_rect.grow(safe_margin).intersects(_item_rect_at_point(placed_key, placed_point_id)):
			return true
	return false


func _points_stack_vertically(first_id: String, second_id: String) -> bool:
	var first: Dictionary = SPAWN_POINTS.get(first_id, {})
	var second: Dictionary = SPAWN_POINTS.get(second_id, {})
	if first.is_empty() or second.is_empty():
		return false
	# Different floors never conflict in the 2D layout.
	if int(first.floor) != int(second.floor):
		return false
	var first_pos: Vector2 = first.position
	var second_pos: Vector2 = second.position
	var dx: float = absf(first_pos.x - second_pos.x)
	var dy: float = absf(first_pos.y - second_pos.y)
	return dx <= STACK_COLUMN_DISTANCE and dy >= STACK_MIN_VERTICAL_DISTANCE and dy <= STACK_MAX_VERTICAL_DISTANCE


func _item_rect_at_point(key: String, point_id: String) -> Rect2:
	var point: Dictionary = SPAWN_POINTS[point_id]
	var anchor: Vector2 = point.position
	var visual_size := _visual_size_for_key(key)
	return Rect2(anchor.x - visual_size.x * 0.5, anchor.y - visual_size.y, visual_size.x, visual_size.y)


func _visual_size_for_key(key: String) -> Vector2:
	if item_visual_size_cache.has(key):
		return item_visual_size_cache[key]
	var path := "res://education/playtown/assets/grocery/products_v2/%s.webp" % key if PRODUCT_KEYS.has(key) else "res://education/playtown/assets/learning_objects/%s.webp" % key
	var item_texture := load(path) as Texture2D
	var target_height := float(ITEM_HEIGHTS.get(key, 60.0))
	var result := Vector2(target_height, target_height)
	if item_texture:
		var image := item_texture.get_image()
		var used := image.get_used_rect() if image and not image.is_empty() else Rect2i(Vector2i.ZERO, Vector2i(item_texture.get_size()))
		if used.size.y > 0:
			result = Vector2(float(used.size.x) * target_height / float(used.size.y), target_height)
	item_visual_size_cache[key] = result
	return result


func _safety_margin_for(key: String) -> float:
	var size_class := String(ITEM_SIZE_CLASSES.get(key, "medium"))
	return float(SIZE_SAFETY_MARGINS.get(size_class, 13.0))


func _index_entries(entries: Array[Dictionary]) -> Dictionary:
	var result := {}
	for entry in entries:
		result[String(entry.get("key", ""))] = entry
	return result


func _spawn_item(data: Dictionary, point_id: String) -> void:
	if data.is_empty() or data.get("texture") == null:
		return
	var source_point: Dictionary = SPAWN_POINTS.get(point_id, {})
	if source_point.is_empty():
		return
	var source_position: Vector2 = source_point.position
	var local_position := Vector2(source_position.x, source_position.y - HOUSE_CROP_Y)
	var key := String(data.get("key", ""))
	var item: HouseSearchItem = HouseSearchItemScript.new()
	item.z_index = 6
	item.configure(data, int(source_point.floor), local_position, float(ITEM_HEIGHTS.get(key, 60.0)))
	item.set_meta("spawn_point_id", point_id)
	world_layer.add_child(item)
	spawned_items.append(item)


func _create_debug_spawn_markers() -> void:
	if not OS.is_debug_build() or not OS.get_cmdline_user_args().has("--house-spawn-debug"):
		return
	for point_id in SPAWN_POINTS:
		var point: Dictionary = SPAWN_POINTS[point_id]
		var source_position: Vector2 = point.position
		var marker := Label.new()
		marker.position = Vector2(source_position.x - 7.0, source_position.y - HOUSE_CROP_Y - 7.0)
		marker.text = "● %s" % String(point_id).to_upper()
		marker.z_index = 50
		marker.add_theme_font_size_override("font_size", 14)
		marker.add_theme_color_override("font_color", Color.MAGENTA)
		marker.add_theme_color_override("font_outline_color", Color.WHITE)
		marker.add_theme_constant_override("outline_size", 4)
		world_layer.add_child(marker)


func _show_next_target() -> void:
	if target_queue.is_empty():
		current_target = null
		goal_icon.texture_normal = null
		SFX.play_praise(player.global_position, 0.25)
		return
	current_target = target_queue[0]
	goal_icon.texture_normal = current_target.texture
	await get_tree().create_timer(0.35).timeout
	_play_target_voice()


func _play_target_voice() -> void:
	if current_target == null or not is_instance_valid(current_target):
		return
	var voice := current_target.item_data.get("voice") as AudioStream
	if voice:
		SFX.play_voice_2d(voice, player.global_position, 1.0)


func _find_nearby_item() -> HouseSearchItem:
	var nearest: HouseSearchItem
	var distance := INF
	for item in spawned_items:
		if not is_instance_valid(item) or not item.can_use(player.position.x, current_floor):
			continue
		var item_distance := absf(item.position.x - player.position.x)
		if item_distance < distance:
			nearest = item
			distance = item_distance
	return nearest


func _use_current_interaction() -> void:
	if transitioning or round_completed:
		return
	if nearby_item != null and is_instance_valid(nearby_item):
		_try_collect(nearby_item)
	elif absf(player.position.x - DOOR_X) <= DOOR_DISTANCE:
		_change_floor()


func _try_collect(item: HouseSearchItem) -> void:
	if item != current_target:
		var shake := create_tween()
		var origin := item.position
		shake.tween_property(item, "position:x", origin.x - 10.0, 0.07)
		shake.tween_property(item, "position:x", origin.x + 10.0, 0.07)
		shake.tween_property(item, "position:x", origin.x, 0.07)
		SFX.play_retry(player.global_position, 0.0)
		return
	transitioning = true
	player.input_enabled = false
	use_control.visible = false
	var found_texture := item.texture
	var found_voice := item.item_data.get("voice") as AudioStream
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(item, "scale", item.scale * 0.12, 0.34)
	tween.tween_property(item, "modulate:a", 0.0, 0.34)
	tween.tween_property(item, "position:y", item.position.y - 45.0, 0.34)
	await tween.finished
	spawned_items.erase(item)
	target_queue.pop_front()
	item.queue_free()
	var slot := found_strip.get_child(score) as TextureRect
	slot.texture = found_texture
	slot.modulate = Color.WHITE
	score += 1
	score_label.text = str(score)
	GameState.add_coins(1)
	SFX.play_2d(CORRECT_SOUND, player.global_position, -4.0)
	if found_voice:
		SFX.play_voice_2d(found_voice, player.global_position, 1.0)
	if score >= TARGET_COUNT:
		round_completed = true
		goal_icon.texture_normal = null
		player.clear_touch_direction()
		movement_joystick.reset()
		# Keep controls locked until the return transition starts.
		await get_tree().create_timer(0.75).timeout
		if not is_inside_tree():
			return
		SFX.play_praise(player.global_position, 0.0)
		await get_tree().create_timer(0.8).timeout
		if is_inside_tree():
			SFX.transition_to_scene(GameState.main_scene_path)
		return
	player.input_enabled = true
	transitioning = false
	await get_tree().create_timer(0.9).timeout
	if is_inside_tree():
		_show_next_target()


func _change_floor() -> void:
	transitioning = true
	player.input_enabled = false
	player.clear_touch_direction()
	movement_joystick.reset()
	player.play_walk(Vector2.UP)
	var source := first_floor_door if current_floor == 1 else second_floor_door
	var destination := second_floor_door if current_floor == 1 else first_floor_door
	var source_inside := Vector2(DOOR_X, 645.0 if current_floor == 1 else 318.0)
	var destination_inside := Vector2(DOOR_X, 318.0 if current_floor == 1 else 645.0)
	var next_floor := 2 if current_floor == 1 else 1
	source.texture = open_door_texture
	var enter := create_tween().set_parallel(true)
	enter.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	enter.tween_property(player, "position", source_inside, 0.62)
	enter.tween_property(player, "scale", Vector2(0.58, 0.58), 0.62)
	enter.tween_property(player, "modulate:a", 0.15, 0.62)
	await enter.finished
	player.visible = false
	source.texture = closed_door_texture
	await get_tree().create_timer(0.25).timeout
	current_floor = next_floor
	player.set_floor(current_floor, DOOR_X)
	player.position = destination_inside
	player.scale = Vector2(0.58, 0.58)
	player.modulate.a = 0.15
	player.play_walk(Vector2.DOWN)
	destination.texture = open_door_texture
	await get_tree().create_timer(0.2).timeout
	player.visible = true
	var destination_position := Vector2(DOOR_X, 725.0 if current_floor == 1 else 397.0)
	var leave := create_tween().set_parallel(true)
	leave.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	leave.tween_property(player, "position", destination_position, 0.72)
	leave.tween_property(player, "scale", Vector2.ONE, 0.72)
	leave.tween_property(player, "modulate:a", 1.0, 0.72)
	await leave.finished
	destination.texture = closed_door_texture
	player.set_floor(current_floor, DOOR_X)
	player.face(Vector2.DOWN)
	player.input_enabled = true
	transitioning = false


func _exit_to_city() -> void:
	if transitioning:
		return
	SFX.transition_to_scene(GameState.main_scene_path)
