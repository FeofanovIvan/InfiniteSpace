extends Node

const DESIGN_SIZE := Vector2(1536.0, 864.0)
const TARGET_COUNT := 5
const ROUND_ITEM_COUNT := 10
const NON_KITCHEN_COUNT := 6
const DOOR_X := 768.0
const DOOR_DISTANCE := 112.0
const HOUSE_CROP_Y := 80.0
const CORRECT_SOUND: AudioStream = preload("res://learning/audio/sfx/correct.ogg")
const MEADOW_BACKGROUND: Texture2D = preload("res://learning/assets/house_search/sunny_cartoon_meadow.png")
const LearningObjectCatalog := preload("res://learning/src/features/shared/learning_object_catalog.gd")
const ProductCatalog := preload("res://learning/src/features/shared/product_catalog.gd")
const HouseSearchPlayerScript := preload("res://learning/src/features/house_search/house_search_player.gd")
const HouseSearchItemScript := preload("res://learning/src/features/house_search/house_search_item.gd")
const UseButtonScript := preload("res://learning/src/features/house_search/use_button.gd")
const GameExitButtonScript := preload("res://learning/src/ui/game_exit_button.gd")
const JoystickScript := preload("res://scripts/Joystick.gd")
const FossilActionScript := preload("res://learning/src/features/house_search/fossil_flight_action_button_v1.gd")
const NativeToolbarScript := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const NativeHudScript := preload("res://planet_hub/scripts/bottom_hud.gd")
const NativeBackGlyph := preload("res://simulator_ui/back_arrow_glyph.gd")
const NativeUiKit := preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
# MIKA_FOSSIL_HUNT_NATIVE_UI_V1
# MIKA_FOSSIL_HUNT_CRYSTAL_CAVE_MIKA_V2
# MIKA_FOSSIL_HUNT_DEPTH_COLLISION_GOAL_V3
# MIKA_FOSSIL_HUNT_USER_ZONES_CLIMB_V4
# MIKA_FOSSIL_HUNT_FOSSILS_YSORT_V5
# MIKA_FOSSIL_HUNT_SPAWN_FIX_V5_1
const FOSSIL_IDS_V5: Array[String] = ["01_ammonite", "02_trilobite", "03_fern_imprint", "04_fossil_fish", "05_dinosaur_tooth", "06_dinosaur_claw", "07_fossil_egg", "08_vertebra", "09_spiral_shell", "10_fossil_skull"]
const FOSSIL_ART_DIR_V5 := "res://learning/assets/house_search/fossil_items_v5/"
const FossilMikaPlayerV4Script: Script = preload("res://learning/src/features/house_search/fossil_mika_player_v4.gd")
const CaveZonesV4: Script = preload("res://learning/src/features/house_search/fossil_cave_zones_v4.gd")
const CLIMB_ASSETS_V4 = [
    "res://learning/assets/house_search/fossil_climb_v4/MIKA_climb_01.png",
    "res://learning/assets/house_search/fossil_climb_v4/MIKA_climb_02.png",
    "res://learning/assets/house_search/fossil_climb_v4/MIKA_climb_03.png",
    "res://learning/assets/house_search/fossil_climb_v4/MIKA_climb_04.png",
]
const FossilMikaPlayerV3Script: Script = preload("res://learning/src/features/house_search/fossil_mika_player_v3.gd")
const FossilMikaFramesV3: Script = preload("res://learning/src/features/house_search/fossil_mika_frames_v3.gd")
const FossilGoalRingV3Script: Script = preload("res://learning/src/features/house_search/fossil_goal_ring_v3.gd")
const CAVE_BACKGROUND: Texture2D = preload("res://learning/assets/house_search/fossil_crystal_cave_v2.png")
const CAVE_CLIP_SHADER: Shader = preload("res://learning/src/features/house_search/fossil_cave_corner_v2.gdshader")
const FossilMikaFrames: Script = preload("res://learning/src/features/house_search/fossil_mika_frames_v2.gd")
const FossilMikaPlayerScript: Script = preload("res://learning/src/features/house_search/fossil_mika_player_v2.gd")
const CAVE_ART_WIDTH := 1683.0
const CAVE_ART_HEIGHT := 935.0
const UPPER_FLOOR_Y := 449.0
const LOWER_FLOOR_Y := 744.0

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
	# Source of truth: the 14 spawn markers in Fossil_Hunt_Cave_Zones.json.
	# +HOUSE_CROP_Y because the existing _spawn_item subtracts that offset.
	"bed_l": {"position": Vector2(271.9715, 513.3861), "floor": 2, "zone": "second"}, # zone-16
	"bed_r": {"position": Vector2(353.1979, 447.7775), "floor": 2, "zone": "second"}, # zone-17
	"desk_l": {"position": Vector2(566.7594, 422.8278), "floor": 2, "zone": "second"}, # zone-18
	"desk_r": {"position": Vector2(881.6257, 471.8032), "floor": 2, "zone": "second"}, # zone-19
	"up_rug": {"position": Vector2(986.5811, 442.2332), "floor": 2, "zone": "second"}, # zone-20
	"up_floor_r": {"position": Vector2(1188.2781, 461.6385), "floor": 2, "zone": "second"}, # zone-21
	"upper_bonus": {"position": Vector2(1278.6310, 520.7786), "floor": 2, "zone": "second"}, # zone-22
	"sofa": {"position": Vector2(397.0053, 786.9091), "floor": 1, "zone": "living"}, # zone-9
	"living_floor_l": {"position": Vector2(607.8289, 754.5668), "floor": 1, "zone": "living"}, # zone-14
	"living_floor_c": {"position": Vector2(977.4545, 746.2503), "floor": 1, "zone": "living"}, # zone-11
	"counter_l1": {"position": Vector2(663.5009, 880.2396), "floor": 1, "zone": "kitchen"}, # zone-13
	"counter_r1": {"position": Vector2(901.7041, 843.2770), "floor": 1, "zone": "kitchen"}, # zone-15
	"table_l": {"position": Vector2(1021.2620, 868.2267), "floor": 1, "zone": "kitchen"}, # zone-12
	"table_r": {"position": Vector2(1160.8984, 733.3134), "floor": 1, "zone": "kitchen"}, # zone-10
}

const KITCHEN_SURFACES: Array[String] = [
	"counter_l1", "counter_l2", "counter_r1", "counter_r2",
	"table_l", "table_c", "table_r",
]
const KITCHEN_TALL_SURFACES: Array[String] = [
	"counter_l1", "counter_l2", "counter_r1", "counter_r2", "table_l", "table_r",
]
const ITEM_ALLOWED_POINTS := {
	# Keep the current learning-object pool; assign it to mapped fossils spots.
	"pencil": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"book": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"ball": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"doll": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"toy_car": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"cube": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"backpack": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"clock": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"lamp": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"hat": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"socks": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"boots": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"tshirt": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"jacket": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"umbrella": ["bed_l", "bed_r", "desk_l", "desk_r", "up_rug", "up_floor_r", "upper_bonus", "sofa", "living_floor_l", "living_floor_c"],
	"cup": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"plate": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"spoon": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"apple": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"banana": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"orange": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"pear": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"grapes": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"strawberry": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"carrot": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"milk": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"bread": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"cheese": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"juice": ["counter_l1", "counter_r1", "table_l", "table_r"],
	"cookies": ["counter_l1", "counter_r1", "table_l", "table_r"],
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
const STACK_COLUMN_DISTANCE := 35.0
const STACK_MIN_VERTICAL_DISTANCE := 18.0
const STACK_MAX_VERTICAL_DISTANCE := 145.0

var world_layer: Node2D
var player: HouseSearchPlayer
var first_floor_door: TextureRect
var second_floor_door: TextureRect
var ui_root: Control
var goal_icon: TextureButton
var found_strip: HBoxContainer
var _stage_panel: Panel
var _cave_background: TextureRect
var _goal_ring: TextureRect
var _native_back: Button
var _native_hud: Control
var _native_title_panel: Panel
var _native_title: Label
var _native_subtitle: Label
var _host_back: Control
var use_control: Control
var use_button: Control
var movement_joystick: Control
var current_floor := 1
var transitioning := false
var round_completed := false
var score := 0
var nearby_item: HouseSearchItem
var spawned_items: Array[HouseSearchItem] = []
var target_queue: Array[HouseSearchItem] = []
var current_target: HouseSearchItem
var closed_door_texture: Texture2D = preload("res://learning/assets/house_search/door_closed.png")
var open_door_texture: Texture2D = preload("res://learning/assets/house_search/door_open.png")
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
	if player == null or use_button == null:
		return
	nearby_item = _find_nearby_item()
	var near_door: bool = _near_ladder_v4()
	var can_act: bool = not transitioning and not round_completed and (nearby_item != null or near_door)
	use_button.call("set_stairs_up", current_floor == 1)
	use_button.call("set_door_mode", near_door)
	use_button.call("set_action_mode", "use" if near_door else "take")
	use_button.call("set_action_available", can_act)
	use_control.visible = not transitioning and not round_completed

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_exit_to_city()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE):
		if use_control.visible and bool(use_button.get("interaction_available")):
			_use_current_interaction()


func _create_background() -> void:
	# Do not draw the old meadow, city or any second background outside the
	# stage. The supplied cave image belongs exclusively to FossilSafeStage.
	pass


func _create_house_world() -> void:
	_stage_panel = Panel.new()
	_stage_panel.name = "FossilFullSafeStage"
	_stage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_panel.clip_contents = true
	var stage_style: StyleBoxFlat = NativeUiKit.stage_style()
	stage_style.bg_color = Color("071323")
	stage_style.set_border_width_all(3)
	stage_style.set_corner_radius_all(29)
	_stage_panel.add_theme_stylebox_override("panel", stage_style)
	add_child(_stage_panel)
	_cave_background = TextureRect.new()
	_cave_background.name = "CaveOnlyInsideGamePanel"
	_cave_background.texture = CAVE_BACKGROUND
	_cave_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cave_background.stretch_mode = TextureRect.STRETCH_SCALE
	_cave_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cave_material := ShaderMaterial.new()
	cave_material.shader = CAVE_CLIP_SHADER
	_cave_background.material = cave_material
	_stage_panel.add_child(_cave_background)
	world_layer = Node2D.new()
	world_layer.name = "CrystalCaveWorld"
	# All movable sprites use the same z-index; Godot orders them by foot Y.
	world_layer.y_sort_enabled = true
	_stage_panel.add_child(world_layer)
	# The image itself contains the central ladder. There are deliberately no
	# old door cut-outs or house sprites drawn over the cave art.
	first_floor_door = null
	second_floor_door = null
	player = FossilMikaPlayerV4Script.new() as HouseSearchPlayer
	player.name = "PlayerMikaFromResourceRush"
	player.set("fossil_current_floor", 1)
	player.z_index = 0
	player.floor_y = LOWER_FLOOR_Y
	player.floor_left = 235.0
	player.floor_right = 1370.0
	player.position = Vector2(DOOR_X - 94.0, LOWER_FLOOR_Y)
	player.set("fossil_mirror_left", FossilMikaFramesV3.mirror_left())
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = FossilMikaFramesV3.make_frames()
	# The supplied single-Mika 320x680 climbing PNGs form a clean 4-frame loop.
	if sprite.sprite_frames != null:
		for climb_name in ["climb_up", "climb_down"]:
			if not sprite.sprite_frames.has_animation(climb_name):
				sprite.sprite_frames.add_animation(climb_name)
			sprite.sprite_frames.set_animation_speed(climb_name, 7.0)
			sprite.sprite_frames.set_animation_loop(climb_name, true)
		for i in range(CLIMB_ASSETS_V4.size()):
			var texture: Texture2D = load(CLIMB_ASSETS_V4[i]) as Texture2D
			if texture == null:
				push_error("Fossil Hunt: missing climb frame " + CLIMB_ASSETS_V4[i])
				continue
			sprite.sprite_frames.add_frame("climb_up", texture)
		for i in range(CLIMB_ASSETS_V4.size() - 1, -1, -1):
			var texture: Texture2D = load(CLIMB_ASSETS_V4[i]) as Texture2D
			if texture != null:
				sprite.sprite_frames.add_frame("climb_down", texture)
	if sprite.sprite_frames == null:
		push_error("Fossil Hunt: Resource Rush MIKA animation sheets could not load")
	else:
		sprite.animation = &"walk_down"
	var source_height: float = FossilMikaFramesV3.walk_frame_height()
	sprite.scale = Vector2.ONE * (132.0 / source_height)
	sprite.offset = Vector2(0.0, -source_height * 0.5)
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
	_goal_ring = FossilGoalRingV3Script.new() as TextureRect
	_goal_ring.position = Vector2(24, 24)
	_goal_ring.size = Vector2(140, 140)
	_goal_ring.texture = null
	_goal_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_goal_ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_goal_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(_goal_ring)

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
	_native_title_panel = Panel.new()
	_native_title_panel.name = "FossilNativeTitlePanel"
	_native_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	NativeToolbarScript.apply_title_style(_native_title_panel)
	ui_root.add_child(_native_title_panel)
	_native_title = Label.new()
	_native_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_native_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_native_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_native_title.clip_text = true
	_native_title_panel.add_child(_native_title)
	_native_subtitle = Label.new()
	_native_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_native_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_native_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_native_subtitle.clip_text = true
	_native_title_panel.add_child(_native_subtitle)
	_native_back = Button.new()
	_native_back.name = "FossilNativeBack"
	_native_back.focus_mode = Control.FOCUS_NONE
	_native_back.add_theme_stylebox_override("normal", NativeUiKit.button_style(false))
	_native_back.add_theme_stylebox_override("hover", NativeUiKit.button_style(true))
	_native_back.add_theme_stylebox_override("pressed", NativeUiKit.button_style(true))
	_native_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_native_back.pressed.connect(_exit_to_city)
	ui_root.add_child(_native_back)
	var glyph := NativeBackGlyph.new() as Control
	_native_back.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_native_hud = NativeHudScript.new() as Control
	_native_hud.name = "FossilNativeCrystalCounter"
	_native_hud.size = Vector2(1680.0, 158.0)
	ui_root.add_child(_native_hud)
	for control_name in ["SimulatorButton", "LaunchButton"]:
		var unused: Control = _native_hud.get_node_or_null(control_name) as Control
		if unused != null:
			unused.hide()
			if unused is BaseButton:
				(unused as BaseButton).disabled = true
	_native_hud.set("crystal_count", 0)
	_refresh_fossil_header()
	var locale_service: Node = get_node_or_null("/root/MobileLocale")
	if locale_service != null and locale_service.has_signal("language_changed"):
		locale_service.connect("language_changed", _on_fossil_locale)
	_find_host_back()


func _create_dpad() -> void:
	# Reuse the actual main-flight joystick, including its multi-touch input.
	movement_joystick = JoystickScript.new() as Control
	movement_joystick.name = "FlightJoystickForFossilHunt"
	movement_joystick.z_index = 100
	movement_joystick.size = Vector2(184.0, 184.0)
	movement_joystick.connect("direction_changed", Callable(player, "set_touch_direction"))
	ui_root.add_child(movement_joystick)


func _create_use_button() -> void:
	use_control = Control.new()
	use_control.name = "FossilFlightActionHolder"
	use_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	use_control.size = Vector2(184.0, 184.0)
	use_control.z_index = 100
	ui_root.add_child(use_control)
	# Native ActionButton from flight + local stairs icon while near the door.
	use_button = FossilActionScript.new() as Control
	use_button.size = Vector2(184.0, 184.0)
	use_button.connect("action_requested", Callable(self, "_on_fossil_action"))
	use_control.add_child(use_button)
	use_button.call("set_action_available", false)


func _on_fossil_action(_mode: String) -> void:
	_use_current_interaction()


func _layout_world() -> void:
	if world_layer == null or _stage_panel == null or _native_hud == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x < 250.0 or viewport_size.y < 185.0:
		return
	ui_root.size = viewport_size
	var safe_insets: Vector4 = _safe_area_insets(viewport_size)
	var safe := Rect2(Vector2(safe_insets.x, safe_insets.y),
			viewport_size - Vector2(safe_insets.x + safe_insets.z,
				safe_insets.y + safe_insets.w))
	var header_end: float = NativeToolbarScript.relayout(viewport_size, safe,
			_native_back, _native_hud, _native_title_panel, _native_title, _native_subtitle)
	var margin: float = clampf(safe.size.x * 0.012, 6.0, 18.0)
	var stage_top: float = header_end + clampf(safe.size.y * 0.010, 4.0, 10.0)
	_stage_panel.position = Vector2(safe.position.x + margin, stage_top)
	_stage_panel.size = Vector2(maxf(180.0, safe.size.x - margin * 2.0),
			maxf(115.0, safe.end.y - stage_top - margin))
	var stage_size: Vector2 = _stage_panel.size
	# The original artwork fills the stage; crop rock-only edges while keeping
	# the upper shelf, lower shelf and ladder inside the safe view.
	var sx: float = maxf(stage_size.x / CAVE_ART_WIDTH, stage_size.y / CAVE_ART_HEIGHT)
	var sy: float = maxf(stage_size.y / CAVE_ART_HEIGHT,
			minf(sx, stage_size.y / 590.0))
	var drawn_size := Vector2(CAVE_ART_WIDTH * sx, CAVE_ART_HEIGHT * sy)
	var ladder_x: float = 839.0
	var focus_y: float = 600.0
	var desired := Vector2(stage_size.x * 0.50 - ladder_x * sx,
			stage_size.y * 0.54 - focus_y * sy)
	var origin := Vector2(clampf(desired.x, stage_size.x - drawn_size.x, 0.0),
			clampf(desired.y, stage_size.y - drawn_size.y, 0.0))
	_cave_background.position = origin
	_cave_background.size = drawn_size
	world_layer.position = origin
	world_layer.scale = Vector2(drawn_size.x / DESIGN_SIZE.x,
			drawn_size.y / DESIGN_SIZE.y)
	var material: ShaderMaterial = _cave_background.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("stage_screen_origin",
				_stage_panel.get_global_transform_with_canvas().origin)
		material.set_shader_parameter("stage_screen_size", stage_size)
		material.set_shader_parameter("radius", 29.0)
	var visible_left: float = maxf(0.0, -origin.x / sx) / CAVE_ART_WIDTH * DESIGN_SIZE.x
	var visible_right: float = minf(CAVE_ART_WIDTH,
			(stage_size.x - origin.x) / sx) / CAVE_ART_WIDTH * DESIGN_SIZE.x
	player.floor_left = maxf(190.0, visible_left + 46.0)
	player.floor_right = minf(1370.0, visible_right - 46.0)
	# Same diameter and horizontal center line as the action circle below.
	var control_scale: float = clampf(minf(stage_size.y / 660.0,
			stage_size.x / 1100.0), 0.61, 1.03)
	var side: float = 184.0 * control_scale
	var left: float = _stage_panel.position.x + 10.0
	var bottom: float = _stage_panel.position.y + stage_size.y - side - 10.0
	use_control.position = Vector2(left, bottom)
	use_control.scale = Vector2.ONE * control_scale
	movement_joystick.position = Vector2(
			_stage_panel.position.x + stage_size.x - side - 10.0, bottom)
	movement_joystick.scale = Vector2.ONE * control_scale
	_goal_ring.position = Vector2(left, _stage_panel.position.y + 10.0)
	_goal_ring.size = Vector2(184.0, 184.0)
	_goal_ring.scale = Vector2.ONE * control_scale
	goal_icon.position = _goal_ring.position + Vector2(44.0, 44.0) * control_scale
	goal_icon.size = Vector2(96.0, 96.0) * control_scale
	var slot_side: float = clampf(side * 0.41, 30.0, 68.0)
	found_strip.position = _goal_ring.position + Vector2(side + 10.0, 30.0 * control_scale)
	for slot in found_strip.get_children():
		if slot is Control:
			(slot as Control).custom_minimum_size = Vector2.ONE * slot_side
	# Keep original 5-slot row inside the stage on narrow devices.
	var max_slot: float = maxf(23.0, (stage_size.x - side * 2.4 - 60.0) / 5.0)
	if slot_side > max_slot:
		for slot in found_strip.get_children():
			if slot is Control:
				(slot as Control).custom_minimum_size = Vector2.ONE * max_slot

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
	score = 0
	if _native_hud != null:
		_native_hud.set("crystal_count", 0)
	if found_strip != null:
		for slot in found_strip.get_children():
			if slot is TextureRect:
				(slot as TextureRect).texture = null
				(slot as TextureRect).modulate = Color(1.0, 1.0, 1.0, 0.22)
	for item in spawned_items:
		if is_instance_valid(item):
			item.queue_free()
	spawned_items.clear()
	target_queue.clear()
	# Keep the existing randomized ten positions, exact user map and 5 targets.
	# Change only what is displayed there: ten distinct fossil PNGs.
	var layout: Array[Dictionary] = generate_round_layout()
	if layout.size() != ROUND_ITEM_COUNT:
		push_error("Fossil Hunt: cannot create ten reachable fossil positions")
		return
	var fossil_order: Array[String] = FOSSIL_IDS_V5.duplicate()
	fossil_order.shuffle()
	for i in range(ROUND_ITEM_COUNT):
		var fossil_id: String = fossil_order[i]
		var fossil_texture: Texture2D = load(FOSSIL_ART_DIR_V5 + fossil_id + ".png") as Texture2D
		if fossil_texture == null:
			push_error("Fossil Hunt: missing " + fossil_id)
			return
		var fossil_data: Dictionary = {"key": fossil_id, "texture": fossil_texture}
		_spawn_item(fossil_data, String(layout[i].point_id))
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
		var second_count := randi_range(3, 4)
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
		# FOSSIL_SKIP_TOP_LEFT_V5_1: never select the two high-left ledge markers.
		if point_id == "bed_l" or point_id == "bed_r":
			continue
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
	var path := "res://learning/assets/grocery/products_v2/%s.webp" % key if PRODUCT_KEYS.has(key) else "res://learning/assets/learning_objects/%s.webp" % key
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
	item.z_index = 0
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
	var best: HouseSearchItem
	var best_distance: float = INF
	for item in spawned_items:
		if not is_instance_valid(item) or not item.visible or item.floor_number != current_floor:
			continue
		# A two-dimensional reach zone; nearby on X alone is not enough.
		var delta := Vector2(item.position.x - player.position.x,
				(item.position.y - player.position.y) * 1.20)
		if absf(delta.x) > item.interaction_distance or delta.length() > 118.0:
			continue
		if delta.length_squared() < best_distance:
			best = item
			best_distance = delta.length_squared()
	return best

func _use_current_interaction() -> void:
	if transitioning or round_completed:
		return
	if _near_ladder_v4():
		_change_floor()
	elif nearby_item != null and is_instance_valid(nearby_item):
		_try_collect(nearby_item)

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
	_native_hud.set("crystal_count", score)
	# Preserve original one-coin global reward; do not grant it twice.
	GameState.add_coins(1)
	SFX.play_2d(CORRECT_SOUND, player.global_position, -4.0)
	if found_voice:
		SFX.play_voice_2d(found_voice, player.global_position, 1.0)
	if score >= TARGET_COUNT:
		round_completed = true
		goal_icon.texture_normal = null
		player.clear_touch_direction()
		movement_joystick.clear_input()
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


func _near_ladder_v4() -> bool:
	if player == null:
		return false
	var floor_name: String = "lower" if current_floor == 1 else "upper"
	var entries: Dictionary = player.get("_stair_entries_v4")
	var positions: PackedVector2Array = entries.get(floor_name, PackedVector2Array())
	for p in positions:
		if player.position.distance_to(CaveZonesV4.source_to_world(p)) <= 69.0:
			return true
	return false

func _change_floor() -> void:
	if transitioning or round_completed or not _near_ladder_v4():
		return
	transitioning = true
	player.input_enabled = false
	player.clear_touch_direction()
	movement_joystick.clear_input()
	var up: bool = current_floor == 1
	var next_floor: int = 2 if up else 1
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var old_scale: Vector2 = sprite.scale
	var old_offset: Vector2 = sprite.offset
	var old_flip: bool = sprite.flip_h
	var entry_source: Vector2 = Vector2(845.0, 810.0) if up else Vector2(845.0, 498.0)
	var exit_source: Vector2 = Vector2(845.0, 498.0) if up else Vector2(845.0, 810.0)
	var side_source: Vector2 = Vector2(782.0, 490.0) if up else Vector2(782.0, 820.0)
	var entry: Vector2 = CaveZonesV4.source_to_world(entry_source)
	var exit_position: Vector2 = CaveZonesV4.source_to_world(exit_source)
	var side_position: Vector2 = CaveZonesV4.source_to_world(side_source)
	# Walk to the marked ladder and then play the four original rear-view poses.
	var approach := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	approach.tween_property(player, "position", entry, 0.35)
	await approach.finished
	if not is_inside_tree():
		return
	sprite.flip_h = false
	sprite.scale = Vector2.ONE * (142.0 / 633.0)
	sprite.offset = Vector2(0.0, -319.0)
	sprite.play(&"climb_up" if up else &"climb_down")
	var climb := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	climb.tween_property(player, "position", exit_position, 1.45)
	await climb.finished
	if not is_inside_tree():
		return
	current_floor = next_floor
	player.set("fossil_current_floor", current_floor)
	player.floor_y = exit_position.y
	var step_out := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	step_out.tween_property(player, "position", side_position, 0.27)
	await step_out.finished
	if not is_inside_tree():
		return
	sprite.stop()
	sprite.scale = old_scale
	sprite.offset = old_offset
	sprite.flip_h = old_flip
	sprite.animation = &"walk_down"
	player.position = side_position
	player.input_enabled = true
	transitioning = false

func _exit_to_city() -> void:
	if transitioning:
		return
	if is_instance_valid(_host_back):
		_host_back.show()
	var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
	if portal != null and bool(portal.get("active")):
		portal.call("handle_scene_transition", "res://")
		return
	SFX.transition_to_scene(GameState.main_scene_path)


func _find_host_back() -> void:
	var ancestor: Node = get_parent()
	while ancestor != null:
		for identifier in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
			var old_button: Control = ancestor.get_node_or_null(identifier) as Control
			if old_button != null:
				_host_back = old_button
				_host_back.hide()
				return
		ancestor = ancestor.get_parent()


func _exit_tree() -> void:
	if is_instance_valid(_host_back):
		_host_back.show()


func _on_fossil_locale(_unused: String) -> void:
	_refresh_fossil_header()
	_layout_world()


func _refresh_fossil_header() -> void:
	if _native_title == null or _native_subtitle == null:
		return
	var code := "en"
	var mobile: Node = get_node_or_null("/root/MobileLocale")
	if mobile != null:
		code = str(mobile.get("language")).to_lower().get_slice("_", 0).get_slice("-", 0)
	elif get_node_or_null("/root/LanguageService") != null:
		code = str(get_node("/root/LanguageService").get("interface_locale")).to_lower().get_slice("_", 0)
	var names := {
		"ru": ["ПОИСК ОКАМЕНЕЛОСТЕЙ", "Найди и собери спрятанные предметы"],
		"en": ["FOSSIL HUNT", "Find and collect the hidden objects"],
		"pt": ["CAÇA AOS FÓSSEIS", "Encontre e recolha os objetos escondidos"],
		"es": ["BÚSQUEDA DE FÓSILES", "Busca y recoge los objetos ocultos"],
		"fr": ["CHASSE AUX FOSSILES", "Trouve et ramasse les objets cachés"],
		"de": ["FOSSILIENSUCHE", "Finde und sammle die versteckten Gegenstände"]
	}
	var words: Array = names.get(code, names["en"])
	_native_title.text = str(words[0])
	_native_subtitle.text = str(words[1])


