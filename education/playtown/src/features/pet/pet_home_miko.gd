extends Node2D
@export var back_scene_path: String = "res://education/playtown/scenes/world/city_world.tscn"
const BG_TEXTURE := "res://education/playtown/assets/pet_home/yard_bg.jpg"
const HOUSE_TEXTURE := "res://education/playtown/assets/pet_home/item_house.png"
const BED_TEXTURE := "res://education/playtown/assets/pet_home/item_bed.png"
const FOOD_EMPTY_TEXTURE := "res://education/playtown/assets/pet_home/item_food_empty_display.png"
const FOOD_FULL_TEXTURE := "res://education/playtown/assets/pet_home/item_food_full_display.png"
const WATER_EMPTY_TEXTURE := "res://education/playtown/assets/pet_home/item_water_empty_display.png"
const WATER_FULL_TEXTURE := "res://education/playtown/assets/pet_home/item_water_full_display.png"
const WASH_FOAM_TEXTURE := "res://education/playtown/assets/pet_home/wash/foam.png"
const WASH_BRUSH_TEXTURE := "res://education/playtown/assets/pet_home/wash/brush.png"
const WASH_BUBBLE_TEXTURE := "res://education/playtown/assets/pet_home/wash/bubble.png"
const WASH_BUBBLE_POP_1_TEXTURE := "res://education/playtown/assets/pet_home/wash/bubble_pop_1.png"
const WASH_BUBBLE_POP_2_TEXTURE := "res://education/playtown/assets/pet_home/wash/bubble_pop_2.png"
const WASH_BUBBLE_COUNT := 16
const SPRITE_FRAMES := "res://education/playtown/assets/pet/animation/dog_animation.tres"
const SPRITE_FRAMES_COLLAR := "res://education/playtown/assets/pet/animation/dog_collar_animation.tres"
const ACTION_SOUND := preload("res://education/playtown/audio/sfx/correct.ogg")
const TEETH_MINIGAME_SCRIPT := preload("res://education/playtown/src/features/pet/pet_teeth_minigame.gd")
const BONE_MINIGAME_SCRIPT := preload("res://education/playtown/src/features/pet/pet_bone_minigame.gd")
const BUTTON_ORDER := ["home", "play", "feed", "water", "wash", "teeth"]
const NEED_ORDER := ["food", "water", "clean", "fun"]
const BUTTON_TEXTURES := {
	"home": ["res://education/playtown/assets/pet_home/buttons/home.png", "res://education/playtown/assets/pet_home/buttons/home_disabled.png"],
	"play": ["res://education/playtown/assets/pet_home/buttons/play.png", "res://education/playtown/assets/pet_home/buttons/play_disabled.png"],
	"feed": ["res://education/playtown/assets/pet_home/buttons/feed.png", "res://education/playtown/assets/pet_home/buttons/feed_disabled.png"],
	"water": ["res://education/playtown/assets/pet_home/buttons/water.png", "res://education/playtown/assets/pet_home/buttons/water_disabled.png"],
	"wash": ["res://education/playtown/assets/pet_home/buttons/wash.png", "res://education/playtown/assets/pet_home/buttons/wash_disabled.png"],
	"teeth": ["res://education/playtown/assets/pet_home/buttons/teeth.png", "res://education/playtown/assets/pet_home/buttons/teeth_disabled.png"],
}
const NEED_ICONS := {
	"food": "res://education/playtown/assets/pet_home/buttons/feed.png",
	"water": "res://education/playtown/assets/pet_home/buttons/water.png",
	"clean": "res://education/playtown/assets/pet_home/buttons/wash.png",
	"fun": "res://education/playtown/assets/pet_home/buttons/play.png",
}
const NEED_COLORS := {
	"food": Color("#f19a37"),
	"water": Color("#35aef2"),
	"clean": Color("#aa74df"),
	"fun": Color("#80bd39"),
}
const FRAME_SIZE := 512.0
const CONTENT_TOP := 46.0
const CONTENT_BOTTOM := 465.0
const CONTENT_LEFT := 48.0
const CONTENT_RIGHT := 473.0
const CONTENT_HEIGHT := CONTENT_BOTTOM - CONTENT_TOP
var bg: TextureRect
var house_item: TextureRect
var bed_item: TextureRect
var food_bowl: TextureRect
var water_bowl: TextureRect
var pet_sprite: AnimatedSprite2D
var indicator_panels: Array[Panel] = []
var indicator_tracks: Array[Panel] = []
var indicator_fills: Array[ColorRect] = []
var indicator_icons: Array[TextureRect] = []
var action_buttons: Dictionary = {}
var sfx_player: AudioStreamPlayer
var wash_foam: TextureRect
var wash_brush: TextureRect
var wash_progress_panel: Panel
var wash_progress_track: Panel
var wash_progress_fill: ColorRect
var wash_progress_icon: TextureRect
var wash_bubble_layer: Node2D
var wash_bubbles: Array[TextureRect] = []
var wash_rng := RandomNumberGenerator.new()
var teeth_minigame: Node2D
var bone_minigame: Node2D
var fed_this_visit := false
var watered_this_visit := false
var played_this_visit := false
var washed_this_visit := false
var brushed_this_visit := false
var wash_active := false
var wash_dragging := false
var wash_drag_offset := Vector2.ZERO
var wash_last_contact := Vector2.ZERO
var wash_progress := 0.0
var safe_area_check_elapsed := 0.0
var last_safe_insets := Vector4.ZERO
func _ready() -> void:
	# InfiniteSpace pet template: pet access is available without a shop.
	GameState.begin_pet_home_visit()
	_build_background()
	_build_world_items()
	_build_pet()
	_build_indicators()
	_build_wash_minigame()
	_build_teeth_minigame()
	_build_bone_minigame()
	_build_action_buttons()
	_build_audio()
	get_viewport().size_changed.connect(_layout)
	_refresh_scene_state()
	_layout()
func _process(delta: float) -> void:
	if OS.get_name() not in ["iOS", "Android"]:
		return
	safe_area_check_elapsed += delta
	if safe_area_check_elapsed < 0.25:
		return
	safe_area_check_elapsed = 0.0
	var safe_insets := _get_safe_area_insets(get_viewport_rect().size)
	if not _insets_are_equal(safe_insets, last_safe_insets):
		_layout()
func _on_preview_pet_access_changed(_available: bool) -> void:
	pass  # No shop entitlement in the InfiniteSpace pet template.
func _build_background() -> void:
	bg = TextureRect.new()
	bg.texture = load(BG_TEXTURE)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -20
	add_child(bg)
func _build_world_items() -> void:
	house_item = _make_world_texture(HOUSE_TEXTURE, -10)
	bed_item = _make_world_texture(BED_TEXTURE, -5)
	water_bowl = _make_world_texture(WATER_EMPTY_TEXTURE, 4)
	food_bowl = _make_world_texture(FOOD_EMPTY_TEXTURE, 4)
func _make_world_texture(path: String, layer: int) -> TextureRect:
	var item := TextureRect.new()
	item.texture = load(path)
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_SCALE
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.z_index = layer
	add_child(item)
	return item
func _build_pet() -> void:
	var has_collar := GameState.is_shop_item_owned("collar")
	var animation_name := "idle_collar" if has_collar else "idle"
	pet_sprite = AnimatedSprite2D.new()
	pet_sprite.sprite_frames = load(SPRITE_FRAMES_COLLAR if has_collar else SPRITE_FRAMES)
	pet_sprite.animation = animation_name
	pet_sprite.centered = true
	pet_sprite.z_index = 2
	add_child(pet_sprite)
	pet_sprite.play(animation_name)
func _build_indicators() -> void:
	for need_id in NEED_ORDER:
		var panel := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#f6ead3")
		style.border_color = Color("#d39c4c")
		style.set_border_width_all(3)
		style.set_corner_radius_all(22)
		style.shadow_color = Color(0.22, 0.13, 0.05, 0.24)
		style.shadow_size = 7
		style.shadow_offset = Vector2(0, 4)
		panel.add_theme_stylebox_override("panel", style)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.z_index = 20
		add_child(panel)
		indicator_panels.append(panel)
		var track := Panel.new()
		var track_style := StyleBoxFlat.new()
		track_style.bg_color = Color("#d8c9ad")
		track_style.border_color = Color("#a98a5d")
		track_style.set_border_width_all(2)
		track_style.set_corner_radius_all(999)
		track.add_theme_stylebox_override("panel", track_style)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.clip_contents = true
		panel.add_child(track)
		indicator_tracks.append(track)
		var fill := ColorRect.new()
		fill.color = NEED_COLORS[need_id]
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)
		indicator_fills.append(fill)
		var icon := TextureRect.new()
		icon.texture = load(NEED_ICONS[need_id])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)
		indicator_icons.append(icon)
func _build_action_buttons() -> void:
	for action_id in BUTTON_ORDER:
		var button := TextureButton.new()
		var paths: Array = BUTTON_TEXTURES[action_id]
		button.texture_normal = load(paths[0])
		button.texture_hover = load(paths[0])
		button.texture_pressed = load(paths[0])
		button.texture_disabled = load(paths[1])
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.z_index = 30
		button.pressed.connect(_on_action_pressed.bind(action_id))
		add_child(button)
		action_buttons[action_id] = button
func _build_wash_minigame() -> void:
	wash_foam = TextureRect.new()
	wash_foam.texture = load(WASH_FOAM_TEXTURE)
	wash_foam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wash_foam.stretch_mode = TextureRect.STRETCH_SCALE
	wash_foam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash_foam.z_index = 5
	wash_foam.visible = false
	add_child(wash_foam)
	wash_bubble_layer = Node2D.new()
	wash_bubble_layer.z_index = 7
	wash_bubble_layer.visible = false
	add_child(wash_bubble_layer)
	for index in range(WASH_BUBBLE_COUNT):
		var bubble := TextureRect.new()
		bubble.texture = load(WASH_BUBBLE_TEXTURE)
		bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bubble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bubble.visible = false
		wash_bubble_layer.add_child(bubble)
		wash_bubbles.append(bubble)
	wash_progress_panel = Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fff4dc")
	panel_style.border_color = Color("#d79835")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(999)
	panel_style.shadow_color = Color(0.15, 0.08, 0.02, 0.25)
	panel_style.shadow_size = 7
	panel_style.shadow_offset = Vector2(0, 4)
	wash_progress_panel.add_theme_stylebox_override("panel", panel_style)
	wash_progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash_progress_panel.z_index = 45
	wash_progress_panel.visible = false
	add_child(wash_progress_panel)
	wash_progress_track = Panel.new()
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color("#d8c9ad")
	track_style.border_color = Color("#9b794b")
	track_style.set_border_width_all(2)
	track_style.set_corner_radius_all(999)
	wash_progress_track.add_theme_stylebox_override("panel", track_style)
	wash_progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash_progress_track.clip_contents = true
	wash_progress_panel.add_child(wash_progress_track)
	wash_progress_fill = ColorRect.new()
	wash_progress_fill.color = Color("#49bdf2")
	wash_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash_progress_track.add_child(wash_progress_fill)
	wash_progress_icon = TextureRect.new()
	wash_progress_icon.texture = load(WASH_BRUSH_TEXTURE)
	wash_progress_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wash_progress_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wash_progress_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash_progress_panel.add_child(wash_progress_icon)
	wash_brush = TextureRect.new()
	wash_brush.texture = load(WASH_BRUSH_TEXTURE)
	wash_brush.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wash_brush.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wash_brush.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash_brush.z_index = 60
	wash_brush.visible = false
	add_child(wash_brush)
func _build_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = ACTION_SOUND
	sfx_player.bus = "SFX"
	add_child(sfx_player)
func _build_teeth_minigame() -> void:
	teeth_minigame = TEETH_MINIGAME_SCRIPT.new()
	add_child(teeth_minigame)
	teeth_minigame.completed.connect(_on_teeth_cleaning_completed)
func _build_bone_minigame() -> void:
	bone_minigame = BONE_MINIGAME_SCRIPT.new()
	add_child(bone_minigame)
	bone_minigame.chewing_started.connect(_on_bone_chewing_started)
	bone_minigame.completed.connect(_on_bone_game_completed)
func _refresh_scene_state() -> void:
	house_item.visible = true
	bed_item.visible = true
	food_bowl.texture = load(FOOD_FULL_TEXTURE if fed_this_visit else FOOD_EMPTY_TEXTURE)
	water_bowl.texture = load(WATER_FULL_TEXTURE if watered_this_visit else WATER_EMPTY_TEXTURE)
	_set_button_enabled("home", true)
	_set_button_enabled("play", not played_this_visit)
	_set_button_enabled("feed", not fed_this_visit)
	_set_button_enabled("water", not watered_this_visit)
	_set_button_enabled("wash", not washed_this_visit)
	_set_button_enabled("teeth", not brushed_this_visit)
	_refresh_indicators(false)
func _set_button_enabled(action_id: String, enabled: bool) -> void:
	var button: TextureButton = action_buttons[action_id]
	button.disabled = not enabled
	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	)
func _layout() -> void:
	var vs := get_viewport_rect().size
	if vs.x <= 0.0 or vs.y <= 0.0:
		return
	var safe_insets := _get_safe_area_insets(vs)
	last_safe_insets = safe_insets
	bg.position = Vector2.ZERO
	bg.size = vs
	var button_size := clampf(vs.y * 0.125, 66.0, 100.0)
	var button_gap := clampf(vs.y * 0.012, 6.0, 11.0)
	var right_margin := safe_insets.z + clampf(vs.x * 0.018, 14.0, 28.0)
	var buttons_height := button_size * BUTTON_ORDER.size() + button_gap * (BUTTON_ORDER.size() - 1)
	var safe_height := maxf(1.0, vs.y - safe_insets.y - safe_insets.w)
	var buttons_top := maxf(safe_insets.y + 10.0, safe_insets.y + (safe_height - buttons_height) * 0.5)
	for index in range(BUTTON_ORDER.size()):
		var action_id: String = BUTTON_ORDER[index]
		var button: TextureButton = action_buttons[action_id]
		button.size = Vector2(button_size, button_size)
		button.position = Vector2(
			vs.x - right_margin - button_size,
			buttons_top + index * (button_size + button_gap)
		)
		button.pivot_offset = button.size * 0.5
	var indicator_w := clampf(vs.x * 0.125, 126.0, 188.0)
	var indicator_h := clampf(vs.y * 0.112, 68.0, 88.0)
	var indicator_x := safe_insets.x + clampf(vs.x * 0.022, 18.0, 34.0)
	var indicator_gap := clampf(vs.y * 0.022, 12.0, 19.0)
	var indicators_height := indicator_h * indicator_panels.size() + indicator_gap * (indicator_panels.size() - 1)
	var indicators_top := safe_insets.y + (safe_height - indicators_height) * 0.5
	for index in range(indicator_panels.size()):
		var panel := indicator_panels[index]
		panel.position = Vector2(indicator_x, indicators_top + index * (indicator_h + indicator_gap))
		panel.size = Vector2(indicator_w, indicator_h)
		var icon_size := minf(indicator_h * 0.68, 58.0)
		var track: Panel = indicator_tracks[index]
		track.position = Vector2(icon_size * 0.5 + 9.0, indicator_h * 0.5 - 7.0)
		track.size = Vector2(indicator_w - icon_size - 18.0, 14.0)
		var icon: TextureRect = indicator_icons[index]
		icon.size = Vector2(icon_size, icon_size)
		icon.position.y = indicator_h * 0.5 - icon_size * 0.5
	var content_left := indicator_x + indicator_w + clampf(vs.x * 0.025, 20.0, 40.0)
	var content_right := vs.x - right_margin - button_size - clampf(vs.x * 0.02, 16.0, 32.0)
	var content_width := maxf(320.0, content_right - content_left)
	var house_w := minf(content_width * 0.42, vs.y * 0.61)
	var house_h := house_w * 653.0 / 729.0
	house_item.size = Vector2(house_w, house_h)
	house_item.position = Vector2(
		content_right - house_w,
		vs.y * 0.105
	)
	var bed_w := minf(content_width * 0.53, vs.y * 0.70)
	var bed_h := bed_w * 0.49
	bed_item.size = Vector2(bed_w, bed_h)
	bed_item.position = Vector2(
		lerpf(content_left, content_right, 0.49) - bed_w * 0.5,
		vs.y * 0.61
	)
	var bowl_w := clampf(content_width * 0.19, 126.0, 218.0)
	var bowl_h := bowl_w * 500.0 / 768.0
	water_bowl.size = Vector2(bowl_w, bowl_h)
	water_bowl.position = Vector2(content_left + content_width * 0.035, vs.y - bowl_h - vs.y * 0.035)
	food_bowl.size = Vector2(bowl_w, bowl_h)
	food_bowl.position = Vector2(content_right - bowl_w - content_width * 0.035, vs.y - bowl_h - vs.y * 0.035)
	water_bowl.pivot_offset = water_bowl.size * 0.5
	food_bowl.pivot_offset = food_bowl.size * 0.5
	_layout_pet(vs, content_left, content_right)
	_layout_wash_minigame(vs)
	_refresh_indicators(false)
func _get_safe_area_insets(viewport_size: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_viewport := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	return Vector4(
		clampf(float(safe_rect.position.x) * scale_to_viewport.x, 0.0, viewport_size.x * 0.2),
		clampf(float(safe_rect.position.y) * scale_to_viewport.y, 0.0, viewport_size.y * 0.2),
		clampf(right_px * scale_to_viewport.x, 0.0, viewport_size.x * 0.2),
		clampf(bottom_px * scale_to_viewport.y, 0.0, viewport_size.y * 0.2)
	)
func _insets_are_equal(first: Vector4, second: Vector4) -> bool:
	return is_equal_approx(first.x, second.x) \
		and is_equal_approx(first.y, second.y) \
		and is_equal_approx(first.z, second.z) \
		and is_equal_approx(first.w, second.w)
func _layout_wash_minigame(vs: Vector2) -> void:
	var pet_rect := _pet_content_rect()
	var foam_w := pet_rect.size.x * 0.98
	var foam_h := foam_w * 0.5
	wash_foam.size = Vector2(foam_w, foam_h)
	wash_foam.position = Vector2(
		pet_rect.get_center().x - foam_w * 0.5,
		pet_rect.end.y - foam_h * 0.90
	)
	wash_foam.pivot_offset = wash_foam.size * 0.5
	var progress_w := clampf(pet_rect.size.x * 0.78, 230.0, 360.0)
	var progress_h := clampf(vs.y * 0.072, 48.0, 62.0)
	wash_progress_panel.size = Vector2(progress_w, progress_h)
	wash_progress_panel.position = Vector2(
		pet_rect.get_center().x - progress_w * 0.5,
		maxf(12.0, pet_rect.position.y - progress_h - 24.0)
	)
	var indicator_icon_w := progress_h * 1.22
	var indicator_icon_h := progress_h * 0.62
	wash_progress_track.position = Vector2(indicator_icon_w * 0.5 + 13.0, progress_h * 0.5 - 8.0)
	wash_progress_track.size = Vector2(progress_w - indicator_icon_w - 26.0, 16.0)
	wash_progress_icon.size = Vector2(indicator_icon_w, indicator_icon_h)
	wash_progress_icon.position.y = progress_h * 0.5 - indicator_icon_h * 0.5
	var brush_w := clampf(pet_rect.size.x * 0.43, 145.0, 205.0)
	wash_brush.size = Vector2(brush_w, brush_w / 3.0)
	wash_brush.pivot_offset = wash_brush.size * 0.5
	if not wash_dragging:
		wash_brush.position = Vector2(
			minf(vs.x - wash_brush.size.x - 18.0, pet_rect.end.x + 24.0),
			pet_rect.position.y + pet_rect.size.y * 0.45
		)
	_update_wash_progress()
func _refresh_indicators(animated: bool) -> void:
	for index in range(NEED_ORDER.size()):
		var need_id: String = NEED_ORDER[index]
		var ratio := GameState.get_pet_need(need_id) / 100.0
		var track: Panel = indicator_tracks[index]
		var fill: ColorRect = indicator_fills[index]
		var icon: TextureRect = indicator_icons[index]
		var target_fill_size := Vector2(track.size.x * ratio, track.size.y)
		var target_icon_x := track.position.x - icon.size.x * 0.5 + track.size.x * ratio
		if animated:
			var tween := create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(fill, "size", target_fill_size, 0.28)
			tween.tween_property(icon, "position:x", target_icon_x, 0.28)
		else:
			fill.position = Vector2.ZERO
			fill.size = target_fill_size
			icon.position.x = target_icon_x
func _layout_pet(vs: Vector2, content_left: float, content_right: float) -> void:
	var target_total_h := clampf(vs.y * 0.47, 225.0, 580.0)
	var pet_scale := target_total_h / CONTENT_HEIGHT
	pet_sprite.scale = Vector2(pet_scale, pet_scale)
	var ground_y := vs.y * (0.805 if bed_item.visible else 0.835)
	var content_center_x := (CONTENT_LEFT + CONTENT_RIGHT) * 0.5
	var frame_center := FRAME_SIZE * 0.5
	var desired_center_x := lerpf(content_left, content_right, 0.50)
	var pos_x := desired_center_x - (content_center_x - frame_center) * pet_scale
	var pos_y := ground_y - (CONTENT_BOTTOM - frame_center) * pet_scale
	pet_sprite.position = Vector2(pos_x, pos_y)
func _pet_content_rect() -> Rect2:
	var pet_scale := pet_sprite.scale.x
	var frame_top_left := pet_sprite.position - Vector2.ONE * FRAME_SIZE * 0.5 * pet_scale
	return Rect2(
		frame_top_left + Vector2(CONTENT_LEFT, CONTENT_TOP) * pet_scale,
		Vector2(CONTENT_RIGHT - CONTENT_LEFT, CONTENT_HEIGHT) * pet_scale
	)
func _on_action_pressed(action_id: String) -> void:
	match action_id:
		"home":
			_on_home_pressed()
		"feed":
			_feed_pet()
		"water":
			_water_pet()
		"play":
			_play_with_pet()
		"wash":
			_wash_pet()
		"teeth":
			_brush_pet_teeth()
func _feed_pet() -> void:
	if fed_this_visit:
		return
	fed_this_visit = true
	# InfiniteSpace template: no store stock is consumed.
	GameState.increase_pet_need("food")
	_set_button_enabled("feed", false)
	_animate_fill(food_bowl, FOOD_FULL_TEXTURE)
	_refresh_indicators(true)
func _water_pet() -> void:
	if watered_this_visit:
		return
	watered_this_visit = true
	# InfiniteSpace template: no store stock is consumed.
	GameState.increase_pet_need("water")
	_set_button_enabled("water", false)
	_animate_fill(water_bowl, WATER_FULL_TEXTURE)
	_refresh_indicators(true)
func _play_with_pet() -> void:
	if played_this_visit:
		return
	for action_id in BUTTON_ORDER:
		_set_button_enabled(action_id, action_id == "home")
	sfx_player.play()
	bone_minigame.start(_pet_content_rect())
func _on_bone_chewing_started() -> void:
	pet_sprite.visible = false
func _on_bone_game_completed() -> void:
	played_this_visit = true
	# InfiniteSpace template: no store stock is consumed.
	GameState.increase_pet_need("fun")
	pet_sprite.visible = true
	sfx_player.play()
	_refresh_scene_state()
	_refresh_indicators(true)
func _wash_pet() -> void:
	if wash_active or washed_this_visit:
		return
	wash_active = true
	wash_progress = 0.0
	wash_dragging = false
	_update_wash_progress()
	for action_id in BUTTON_ORDER:
		_set_button_enabled(action_id, action_id == "home")
	wash_foam.visible = true
	wash_bubble_layer.visible = true
	wash_brush.visible = true
	wash_progress_panel.visible = true
	wash_foam.modulate.a = 0.0
	wash_foam.scale = Vector2(0.82, 0.82)
	wash_brush.modulate.a = 0.0
	wash_progress_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(wash_foam, "modulate:a", 1.0, 0.25)
	tween.tween_property(wash_foam, "scale", Vector2.ONE, 0.35)
	tween.tween_property(wash_brush, "modulate:a", 1.0, 0.25)
	tween.tween_property(wash_progress_panel, "modulate:a", 1.0, 0.25)
	_start_wash_bubbles()
	sfx_player.play()
func _input(event: InputEvent) -> void:
	if not wash_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_brush_drag(event.position)
		else:
			wash_dragging = false
	elif event is InputEventMouseMotion and wash_dragging:
		_move_wash_brush(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_brush_drag(event.position)
		else:
			wash_dragging = false
	elif event is InputEventScreenDrag and wash_dragging:
		_move_wash_brush(event.position)
func _begin_brush_drag(pointer_position: Vector2) -> void:
	var hit_rect := Rect2(wash_brush.position, wash_brush.size).grow(24.0)
	if not hit_rect.has_point(pointer_position):
		return
	wash_dragging = true
	wash_drag_offset = pointer_position - wash_brush.position
	wash_last_contact = _brush_contact_point()
func _move_wash_brush(pointer_position: Vector2) -> void:
	var vs := get_viewport_rect().size
	var old_contact := _brush_contact_point()
	var next_position := pointer_position - wash_drag_offset
	next_position.x = clampf(next_position.x, 0.0, vs.x - wash_brush.size.x)
	next_position.y = clampf(next_position.y, 0.0, vs.y - wash_brush.size.y)
	wash_brush.position = next_position
	var new_contact := _brush_contact_point()
	var movement := new_contact.distance_to(old_contact)
	var direction := new_contact - old_contact
	if direction.length_squared() > 0.1:
		wash_brush.rotation = lerp_angle(
			wash_brush.rotation,
			clampf(direction.y * 0.008, -0.28, 0.28),
			0.22
		)
	if movement >= 2.0 and _is_point_over_pet(new_contact):
		var required_distance := maxf(1500.0, vs.y * 4.10)
		wash_progress = minf(1.0, wash_progress + minf(movement, 42.0) / required_distance)
		_update_wash_progress()
		if wash_progress >= 1.0:
			_finish_washing()
	wash_last_contact = new_contact
func _brush_contact_point() -> Vector2:
	return wash_brush.position + Vector2(wash_brush.size.x * 0.25, wash_brush.size.y * 0.72)
func _is_point_over_pet(point: Vector2) -> bool:
	var rect := _pet_content_rect()
	var center := rect.get_center()
	var radius := rect.size * Vector2(0.49, 0.50)
	if radius.x <= 0.0 or radius.y <= 0.0:
		return false
	var normalized := Vector2(
		(point.x - center.x) / radius.x,
		(point.y - center.y) / radius.y
	)
	return normalized.length_squared() <= 1.0
func _update_wash_progress() -> void:
	if wash_progress_track == null or wash_progress_icon == null:
		return
	wash_progress_fill.position = Vector2.ZERO
	wash_progress_fill.size = Vector2(wash_progress_track.size.x * wash_progress, wash_progress_track.size.y)
	wash_progress_icon.position.x = (
		wash_progress_track.position.x
		- wash_progress_icon.size.x * 0.5
		+ wash_progress_track.size.x * wash_progress
	)
func _start_wash_bubbles() -> void:
	wash_rng.randomize()
	for index in range(wash_bubbles.size()):
		var bubble: TextureRect = wash_bubbles[index]
		bubble.visible = false
		_start_bubble_after_delay(bubble, index * 0.11)
func _start_bubble_after_delay(bubble: TextureRect, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if wash_active:
		_animate_wash_bubble(bubble)
func _animate_wash_bubble(bubble: TextureRect) -> void:
	if not wash_active:
		bubble.visible = false
		return
	var pet_rect := _pet_content_rect()
	var diameter := wash_rng.randf_range(22.0, 62.0)
	var start_center := Vector2(
		wash_rng.randf_range(wash_foam.position.x + wash_foam.size.x * 0.12, wash_foam.position.x + wash_foam.size.x * 0.88),
		wash_rng.randf_range(wash_foam.position.y + wash_foam.size.y * 0.48, wash_foam.position.y + wash_foam.size.y * 0.78)
	)
	var target_center := Vector2(
		start_center.x + wash_rng.randf_range(-95.0, 95.0),
		wash_rng.randf_range(pet_rect.position.y - pet_rect.size.y * 0.08, pet_rect.position.y + pet_rect.size.y * 0.24)
	)
	var duration := wash_rng.randf_range(2.2, 3.8)
	bubble.texture = load(WASH_BUBBLE_TEXTURE)
	bubble.size = Vector2.ONE * diameter
	bubble.pivot_offset = bubble.size * 0.5
	bubble.position = start_center - bubble.size * 0.5
	bubble.rotation = wash_rng.randf_range(-0.12, 0.12)
	bubble.modulate = Color(1, 1, 1, 0.78)
	bubble.visible = true
	var tween := create_tween().set_parallel(true)
	bubble.set_meta("wash_tween", tween)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(bubble, "position", target_center - bubble.size * 0.5, duration)
	tween.tween_property(bubble, "rotation", wash_rng.randf_range(-0.35, 0.35), duration)
	await tween.finished
	if not wash_active:
		bubble.visible = false
		return
	bubble.texture = load(WASH_BUBBLE_POP_1_TEXTURE)
	bubble.modulate.a = 1.0
	await get_tree().create_timer(0.10).timeout
	if not wash_active:
		bubble.visible = false
		return
	bubble.texture = load(WASH_BUBBLE_POP_2_TEXTURE)
	var pop_tween := create_tween()
	bubble.set_meta("wash_tween", pop_tween)
	pop_tween.tween_property(bubble, "modulate:a", 0.0, 0.14)
	await pop_tween.finished
	bubble.visible = false
	if wash_active:
		await get_tree().create_timer(wash_rng.randf_range(0.05, 0.35)).timeout
		if wash_active:
			_animate_wash_bubble(bubble)
func _finish_washing() -> void:
	if not wash_active:
		return
	wash_active = false
	wash_dragging = false
	_stop_wash_bubbles()
	washed_this_visit = true
	# InfiniteSpace template: no store stock is consumed.
	GameState.increase_pet_need("clean")
	sfx_player.play()
	_refresh_scene_state()
	_refresh_indicators(true)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(wash_foam, "modulate:a", 0.0, 0.35)
	tween.tween_property(wash_brush, "modulate:a", 0.0, 0.25)
	tween.tween_property(wash_progress_panel, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(_hide_wash_minigame)
func _hide_wash_minigame() -> void:
	wash_foam.visible = false
	wash_bubble_layer.visible = false
	wash_brush.visible = false
	wash_progress_panel.visible = false
	wash_foam.scale = Vector2.ONE
	wash_brush.rotation = 0.0
func _stop_wash_bubbles() -> void:
	for bubble in wash_bubbles:
		if bubble.has_meta("wash_tween"):
			var tween: Tween = bubble.get_meta("wash_tween")
			if tween != null and tween.is_valid():
				tween.kill()
		bubble.visible = false
func _brush_pet_teeth() -> void:
	if brushed_this_visit:
		return
	for action_id in BUTTON_ORDER:
		_set_button_enabled(action_id, action_id == "home")
	pet_sprite.visible = false
	sfx_player.play()
	teeth_minigame.start()
func _on_teeth_cleaning_completed() -> void:
	brushed_this_visit = true
	# InfiniteSpace template: no store stock is consumed.
	pet_sprite.visible = true
	sfx_player.play()
	_refresh_scene_state()
func _animate_fill(bowl: TextureRect, full_texture_path: String) -> void:
	sfx_player.play()
	if bowl.has_meta("fill_tween"):
		var old_tween: Tween = bowl.get_meta("fill_tween")
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()
	var tween := create_tween()
	bowl.set_meta("fill_tween", tween)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bowl, "scale", Vector2(1.10, 0.88), 0.10)
	tween.tween_callback(func() -> void: bowl.texture = load(full_texture_path))
	tween.tween_property(bowl, "scale", Vector2(0.94, 1.08), 0.12)
	tween.tween_property(bowl, "scale", Vector2.ONE, 0.16)
func _on_home_pressed() -> void:
	SFX.transition_to_scene(back_scene_path)
