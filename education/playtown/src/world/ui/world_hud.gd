extends CanvasLayer
const SubscriptionButton := preload("res://education/playtown/src/world/ui/subscription_button.gd")
const SubscriptionOverlay := preload("res://education/playtown/src/screens/subscription_overlay.gd")
const LanguageButton := preload("res://education/playtown/src/world/ui/language_button.gd")
@onready var root_ui: Control = $TopUI
@onready var talk_button: TextureButton = $TopUI/TalkButtonControl/TalkButton
@onready var road_warning: TextureRect = $TopUI/RoadWarningControl/RoadWarning
@onready var score_label: Label = $TopUI/CoinBox/CoinBox/ScoreLabel
var can_talk: bool = false
var current_target_scene_path: String = ""
var coin_score: int = 0
var subscription_button: TextureButton
var subscription_overlay: CanvasLayer
var language_button_control: Control
var language_button: TextureButton
func _ready() -> void:
	talk_button.visible = false
	road_warning.visible = false
	coin_score = GameState.get_coin_balance()
	score_label.text = str(coin_score)
	GameState.coin_balance_changed.connect(_on_coin_balance_changed)
	talk_button.pressed.connect(_on_talk_button_pressed)
	_create_subscription_button()
	_create_language_button()
	BillingService.entitlement_changed.connect(_on_subscription_changed)
	get_viewport().size_changed.connect(_apply_safe_area)
	call_deferred("_apply_safe_area")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(root_ui):
		call_deferred("_apply_safe_area")

func _apply_safe_area() -> void:
	if not is_instance_valid(root_ui):
		return
	if OS.get_name() not in ["iOS", "Android"]:
		_set_safe_area_offsets(Vector4.ZERO)
		return
	var window_size := Vector2(DisplayServer.window_get_size())
	var viewport_size := get_viewport().get_visible_rect().size
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		_set_safe_area_offsets(Vector4.ZERO)
		return
	var scale_to_ui := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	var insets := Vector4(
		clampf(float(safe_rect.position.x) * scale_to_ui.x, 0.0, viewport_size.x * 0.2),
		clampf(float(safe_rect.position.y) * scale_to_ui.y, 0.0, viewport_size.y * 0.2),
		clampf(right_px * scale_to_ui.x, 0.0, viewport_size.x * 0.2),
		clampf(bottom_px * scale_to_ui.y, 0.0, viewport_size.y * 0.2)
	)
	_set_safe_area_offsets(insets)

func _set_safe_area_offsets(insets: Vector4) -> void:
	root_ui.offset_left = insets.x
	root_ui.offset_top = insets.y
	root_ui.offset_right = -insets.z
	root_ui.offset_bottom = -insets.w
	call_deferred("_layout_right_buttons")
	var nav_panel := root_ui.get_node_or_null("NavPanel")
	if nav_panel and nav_panel.has_method("_layout"):
		nav_panel.call_deferred("_layout")
func add_coin() -> void:
	GameState.add_coins(1)
func _on_coin_balance_changed(balance: int) -> void:
	coin_score = balance
	score_label.text = str(coin_score)
func show_road_warning(value: bool) -> void:
	road_warning.visible = value
func _update_talk_state(value: bool, scene_path: String) -> void:
	if value:
		can_talk = true
		current_target_scene_path = scene_path
	else:
		if current_target_scene_path == scene_path:
			can_talk = false
			current_target_scene_path = ""
	talk_button.visible = can_talk
func set_can_talk_to_mom(v: bool) -> void:
	_update_talk_state(v, "res://education/playtown/scenes/screens/game_select_home.tscn")
func set_can_talk_to_seller(v: bool) -> void:
	_update_talk_state(v, "res://education/playtown/scenes/screens/game_select_shop.tscn")
func set_can_talk_to_teacher(v: bool) -> void:
	_update_talk_state(v, "res://education/playtown/scenes/screens/game_select_school.tscn")
func set_can_talk_to_classmate(v: bool) -> void:
	_update_talk_state(v, "res://education/playtown/scenes/screens/game_select_playground.tscn")
func set_can_enter_blue_house(v: bool) -> void:
	_update_talk_state(v, "res://education/playtown/scenes/features/house_search/house_search_game.tscn")
func set_can_enter_basketball(v: bool) -> void:
	_update_talk_state(v, "res://education/playtown/scenes/features/basketball/basketball_game.tscn")
func set_can_enter_ice_cream(v: bool) -> void:
	_update_talk_state(v, "res://education/playtown/scenes/features/ice_cream/ice_cream_game.tscn")
func _on_talk_button_pressed() -> void:
	if not can_talk:
		return
	var main := get_parent()
	if main:
		var player := main.get_node_or_null("Player")
		if player:
			GameState.remember_main_player_position(player.global_position)
	SFX.transition_from_world(current_target_scene_path)

func _create_subscription_button() -> void:
	subscription_button = SubscriptionButton.new()
	subscription_button.anchor_top = 0.5
	subscription_button.anchor_bottom = 0.5
	subscription_button.offset_left = 31
	subscription_button.offset_top = -25
	subscription_button.offset_right = 135
	subscription_button.offset_bottom = 79
	subscription_button.set_active(AccessService.subscription_active)
	subscription_button.pressed.connect(_open_subscription)
	root_ui.add_child(subscription_button)

func _create_language_button() -> void:
	language_button_control = Control.new()
	language_button_control.anchor_left = 1.0
	language_button_control.anchor_right = 1.0
	language_button_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(language_button_control)
	language_button = LanguageButton.new()
	language_button_control.add_child(language_button)

func _layout_right_buttons() -> void:
	if not is_instance_valid(root_ui) or not is_instance_valid(language_button_control):
		return
	var controls: Array[Control] = [
		root_ui.get_node("HomeButtonControl"),
		language_button_control,
		root_ui.get_node("ShopButtonControl"),
		root_ui.get_node("PetButtonControl"),
	]
	var available_height := root_ui.size.y
	var top_margin := clampf(available_height * 0.018, 10.0, 18.0)
	var gap := clampf(available_height * 0.014, 8.0, 13.0)
	var stack_height := minf(available_height * 0.60, 520.0)
	var button_size := clampf((stack_height - gap * 3.0) / 4.0, 90.0, 122.0)
	var right_margin := clampf(root_ui.size.x * 0.012, 12.0, 24.0)
	for index in range(controls.size()):
		var control := controls[index]
		var y := top_margin + float(index) * (button_size + gap)
		control.anchor_left = 1.0
		control.anchor_top = 0.0
		control.anchor_right = 1.0
		control.anchor_bottom = 0.0
		control.offset_left = -right_margin
		control.offset_top = y
		control.offset_right = -right_margin
		control.offset_bottom = y
		var button := control.get_child(0) as Control
		if button:
			button.position = Vector2(-button_size, 0.0)
			button.size = Vector2(button_size, button_size)
			button.pivot_offset = button.size * 0.5

func _open_subscription() -> void:
	if is_instance_valid(subscription_overlay):
		return
	subscription_overlay = SubscriptionOverlay.new()
	add_child(subscription_overlay)

func _on_subscription_changed(active: bool) -> void:
	if is_instance_valid(subscription_button):
		subscription_button.set_active(active)
