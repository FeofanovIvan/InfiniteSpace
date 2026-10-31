extends Control
## v58 educational game carousel: original Play Town cards and minigames.
## The cockpit background is retained, but Miko, crew, simulator, shop,
## capacity and speed cards are intentionally absent.
signal closed
signal crystals_earned(units: int)

const BRIDGE_TEXTURE: Texture2D = preload("res://assets/bridge/bridge_cockpit.png")
const CRYSTAL_TEXTURE: Texture2D = preload("res://asteroid_assets/fragments/04_blue/crystal_wedge.png")
const SHIP_TEXTURE: Texture2D = preload("res://assets/ui/miko_ship_menu_circle.png")
const BACK_TEXTURE: Texture2D = preload("res://assets/ui/bridge_back.png")
const CATALOG_PATH: String = "res://education/playtown_catalog.json"
const ART_ROOT: String = "res://education/playtown/"
const PET_SCENE_PATH: String = "res://education/playtown/scenes/features/pet/pet_home_miko.tscn"
const PET_FRAMES_PATH: String = "res://education/playtown/assets/pet/pet_frames.tres"
# Running dog on the main ship screen is the actual Play Town animated character.
# The original dog sprites, puppy mini-games and sounds are copied locally.
const PET_WALK_SPEED: float = 65.0

var _background: TextureRect
var _header: Control
var _counter: Label
var _gallery: ScrollContainer
var _strip: HBoxContainer
var _back: TextureButton
var _gesture_layer: Control
var _pointer_kind: String = ""
var _pointer_index: int = -1
var _pointer_origin: Vector2 = Vector2.ZERO
var _pointer_last: Vector2 = Vector2.ZERO
var _pointer_moved: bool = false
var _pressed_card: TextureButton
var _fling_speed: float = 0.0
const DRAG_THRESHOLD: float = 14.0
const MAX_FLING_SPEED: float = 1550.0
var _game_layer: Control
var _viewport_container: SubViewportContainer
var _game_viewport: SubViewport
var _game_back: Button
var _cards: Array[Dictionary] = []
var _crystal_balance: int = 0
var _last_playtown_coins: int = 0
var _playing: bool = false
var _pet_sprite: AnimatedSprite2D
var _pet_click_area: Button
var _pet_walk_x: float = 0.0
var _pet_direction: float = 1.0
var _pet_initial_position: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_background = TextureRect.new()
	_background.texture = BRIDGE_TEXTURE
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	var dark: ColorRect = ColorRect.new()
	dark.name = "ReadableCardGalleryTint"
	dark.color = Color(0.005, 0.015, 0.045, 0.40)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dark)
	_header = Control.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)
	_back = TextureButton.new()
	_back.texture_normal = SHIP_TEXTURE
	_back.ignore_texture_size = true
	_back.stretch_mode = TextureButton.STRETCH_SCALE
	_back.focus_mode = Control.FOCUS_NONE
	_back.tooltip_text = "Вернуться к полёту"
	_back.pressed.connect(close_menu)
	_header.add_child(_back)
	var crystal: TextureRect = TextureRect.new()
	crystal.name = "ActualBlueCrystal"
	crystal.texture = CRYSTAL_TEXTURE
	crystal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crystal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(crystal)
	_counter = Label.new()
	_counter.name = "CrystalBalanceOnly"
	_counter.add_theme_font_size_override("font_size", 31)
	_counter.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0))
	_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter.text = "0"
	_header.add_child(_counter)
	_gallery = ScrollContainer.new()
	_gallery.name = "OriginalPlayTownCards_HorizontalSwipe"
	# The gallery is a fully transparent swipe surface with no navigation arrows
	# or scrolling chrome. Touch and mouse gestures use the same controller.
	_gallery.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_gallery.follow_focus = false
	_gallery.clip_contents = true
	_gallery.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_gallery)
	_strip = HBoxContainer.new()
	_strip.name = "PlayTownEducation_CardStrip"
	_strip.alignment = BoxContainer.ALIGNMENT_BEGIN
	_strip.add_theme_constant_override("separation", 20)
	_gallery.add_child(_strip)
	_strip.add_theme_constant_override("separation", 28)
	_load_original_catalog()
	# Transparent hit layer above every card: it differentiates swipes from taps,
	# so dragging a card cannot accidentally launch its mini-game.
	_gesture_layer = Control.new()
	_gesture_layer.name = "TransparentSwipeAndTapArea"
	_gesture_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_gesture_layer.clip_contents = true
	add_child(_gesture_layer)
	# A real walking Play Town puppy, not a generic icon or a pet-shop button.
	var frames: SpriteFrames = load(PET_FRAMES_PATH) as SpriteFrames
	_pet_sprite = AnimatedSprite2D.new()
	_pet_sprite.name = "PlayTownPuppy_WalkingBottom"
	_pet_sprite.sprite_frames = frames
	_pet_sprite.centered = true
	_pet_sprite.z_index = 10
	add_child(_pet_sprite)
	if frames != null and frames.has_animation("walk_right"):
		_pet_sprite.animation = "walk_right"
		_pet_sprite.play()
	_pet_click_area = Button.new()
	_pet_click_area.name = "TapTheRunningPuppy_ToPetHome"
	_pet_click_area.text = ""
	_pet_click_area.focus_mode = Control.FOCUS_NONE
	_pet_click_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		_pet_click_area.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	_pet_click_area.pressed.connect(_open_pet_home)
	add_child(_pet_click_area)
	_game_layer = Control.new()
	_game_layer.name = "PlayTownOriginalGameRunner"
	_game_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_layer.visible = false
	add_child(_game_layer)
	_viewport_container = SubViewportContainer.new()
	_viewport_container.name = "GameViewportInputForwarding"
	_viewport_container.stretch = false
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_layer.add_child(_viewport_container)
	_game_viewport = SubViewport.new()
	_game_viewport.name = "OriginalPlayTownGameViewport"
	_game_viewport.size = Vector2i(1536, 768)
	_game_viewport.handle_input_locally = true
	_game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_container.add_child(_game_viewport)
	_game_back = Button.new()
	_game_back.name = "ReturnToEducationalCards"
	_game_back.text = "❮"
	_game_back.focus_mode = Control.FOCUS_NONE
	_game_back.add_theme_font_size_override("font_size", 25)
	_game_back.pressed.connect(_return_to_cards)
	_game_layer.add_child(_game_back)
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null and portal.has_signal("game_finished"):
		portal.connect("game_finished", _return_to_cards)
	var coins: Node = get_node_or_null("/root/GameState")
	if coins != null and coins.has_signal("coin_balance_changed"):
		coins.connect("coin_balance_changed", _on_coins_changed)
	resized.connect(_reflow)
	_reflow()


func _load_original_catalog() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("Missing educational card catalog: " + CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Array:
		push_error("Invalid educational card catalog")
		return
	for entry in parsed:
		if not entry is Dictionary:
			continue
		var info: Dictionary = entry
		var art_path: String = ART_ROOT + str(info.get("texture", ""))
		var scene_path: String = ART_ROOT + str(info.get("scene", ""))
		if not ResourceLoader.exists(art_path) or not ResourceLoader.exists(scene_path):
			push_warning("Incomplete local Play Town copy: " + art_path + " or " + scene_path)
			continue
		_cards.append(info)
		# Each original card image IS the complete clickable block. No Panel,
		# StyleBox, label, dark rectangle or border behind it.
		var button: TextureButton = TextureButton.new()
		button.name = "PlayTownCard_" + str(info.get("id", "unknown"))
		button.texture_normal = load(art_path) as Texture2D
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.tooltip_text = str(info.get("name_ru", ""))
		button.custom_minimum_size = Vector2(255.0, 315.0)
		button.pressed.connect(_open_game.bind(scene_path))
		_strip.add_child(button)


func set_stats(flight_crystals: int, _capacity: int, _ship_speed: float) -> void:
	_crystal_balance = maxi(0, flight_crystals)
	if _counter != null:
		_counter.text = str(_crystal_balance)


func open_menu(view: Vector2) -> void:
	size = view
	visible = true
	_return_to_cards()
	_reflow()


func close_menu() -> void:
	_return_to_cards()
	visible = false
	closed.emit()


func _open_pet_home() -> void:
	# Use the original Play Town PetHome scene and all original gameplay actions.
	# The Miko-specific duplicate unlocks pet actions without Play Town shop stock.
	if _playing:
		return
	_open_game(PET_SCENE_PATH)


func _open_game(scene_path: String) -> void:
	if _playing or not ResourceLoader.exists(scene_path):
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("Cannot load original Play Town game: " + scene_path)
		return
	# Reuse the language selected in Miko for the real Play Town lessons.
	var language: Node = get_node_or_null("/root/LanguageService")
	if language != null:
		var locale: String = str(MobileLocale.language)
		if locale == "pt_BR":
			locale = "pt"
		language.call("set_locale", locale, false)
	var coins: Node = get_node_or_null("/root/GameState")
	if coins != null:
		_last_playtown_coins = int(coins.call("get_coin_balance"))
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null:
		portal.call("start_game", scene_path)
	var original: Node = packed.instantiate()
	original.name = "UnchangedGameFromSafeCityKids"
	_game_viewport.add_child(original)
	_playing = true
	_gallery.visible = false
	_gesture_layer.visible = false
	_pet_sprite.visible = false
	_pet_click_area.visible = false
	_pointer_kind = ""
	_fling_speed = 0.0
	_header.visible = false
	_game_layer.visible = true
	_reflow()


func _on_coins_changed(balance: int) -> void:
	if not _playing:
		return
	var gained: int = maxi(0, balance - _last_playtown_coins)
	_last_playtown_coins = balance
	if gained > 0:
		crystals_earned.emit(gained)
		_crystal_balance = mini(50, _crystal_balance + gained)
		_counter.text = str(_crystal_balance)


func _return_to_cards() -> void:
	_playing = false
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null:
		portal.call("stop_game")
	for child in _game_viewport.get_children():
		child.queue_free()
	_game_layer.visible = false
	_gallery.visible = true
	_gesture_layer.visible = true
	_pet_sprite.visible = true
	_pet_click_area.visible = true
	_pointer_kind = ""
	_fling_speed = 0.0
	_header.visible = true


func _card_under_point(screen_point: Vector2) -> TextureButton:
	for child in _strip.get_children():
		var card: TextureButton = child as TextureButton
		if card != null and card.get_global_rect().has_point(screen_point):
			return card
	return null


func _gesture_begin(kind: String, pointer_index: int, screen_point: Vector2) -> void:
	if _pointer_kind != "" or not _gesture_layer.get_global_rect().has_point(screen_point):
		return
	_pointer_kind = kind
	_pointer_index = pointer_index
	_pointer_origin = screen_point
	_pointer_last = screen_point
	_pointer_moved = false
	_pressed_card = _card_under_point(screen_point)
	_fling_speed = 0.0


func _gesture_move(screen_point: Vector2) -> void:
	if _pointer_kind == "":
		return
	var delta_x: float = screen_point.x - _pointer_last.x
	if screen_point.distance_to(_pointer_origin) > DRAG_THRESHOLD:
		_pointer_moved = true
	if _pointer_moved:
		var max_scroll: int = maxi(0, roundi(_strip.size.x - _gallery.size.x))
		var next_scroll: int = clampi(roundi(float(_gallery.scroll_horizontal) - delta_x), 0, max_scroll)
		_gallery.scroll_horizontal = next_scroll
		_fling_speed = clampf(-delta_x / maxf(get_process_delta_time(), 0.016), -MAX_FLING_SPEED, MAX_FLING_SPEED)
	_pointer_last = screen_point


func _gesture_end(screen_point: Vector2) -> void:
	if _pointer_kind == "":
		return
	var clicked: TextureButton = _pressed_card
	var was_swipe: bool = _pointer_moved
	_pointer_kind = ""
	_pointer_index = -1
	_pressed_card = null
	if not was_swipe and clicked != null and clicked == _card_under_point(screen_point):
		_fling_speed = 0.0
		# The original TextureButton owns the signal and launches its game.
		clicked.pressed.emit()
	elif not was_swipe:
		_fling_speed = 0.0


func _input(event: InputEvent) -> void:
	if not visible or _playing or not _gesture_layer.visible:
		return
	# Input positions are in viewport coordinates, including when the cursor
	# leaves the gallery during a drag. The transparent input area prevents
	# duplicate TextureButton clicks or unwanted releases.
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_gesture_begin("touch", touch.index, touch.position)
		elif _pointer_kind == "touch" and _pointer_index == touch.index:
			_gesture_end(touch.position)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if _pointer_kind == "touch" and _pointer_index == drag.index:
			_gesture_move(drag.position)
	elif event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_gesture_begin("mouse", 0, mouse_button.position)
			elif _pointer_kind == "mouse":
				_gesture_end(mouse_button.position)
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if _pointer_kind == "mouse" and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_gesture_move(motion.position)
	elif event is InputEventPanGesture:
		# Two-finger trackpad swipes on Mac work without dragging a mouse.
		var pan: InputEventPanGesture = event
		if _pointer_kind == "" and _gesture_layer.get_global_rect().has_point(pan.position):
			var max_scroll: int = maxi(0, roundi(_strip.size.x - _gallery.size.x))
			_gallery.scroll_horizontal = clampi(roundi(float(_gallery.scroll_horizontal) + pan.delta.x * 45.0), 0, max_scroll)
			_fling_speed = 0.0


func _advance_puppy(delta: float) -> void:
	if _pet_sprite == null or _pet_click_area == null or size.x < 120.0:
		return
	var ui_scale: float = clampf(minf(size.x / 1280.0, size.y / 720.0), 0.62, 1.28)
	var inset: float = 82.0 * ui_scale
	var left: float = inset
	var right: float = maxf(left + 1.0, size.x - inset)
	if _pet_initial_position:
		_pet_walk_x = (left + right) * 0.5
		_pet_initial_position = false
	_pet_walk_x += PET_WALK_SPEED * ui_scale * _pet_direction * delta
	if _pet_walk_x >= right:
		_pet_walk_x = right
		_pet_direction = -1.0
	elif _pet_walk_x <= left:
		_pet_walk_x = left
		_pet_direction = 1.0
	var anim: StringName = &"walk_right" if _pet_direction > 0.0 else &"walk_left"
	if _pet_sprite.sprite_frames != null and _pet_sprite.sprite_frames.has_animation(anim):
		if _pet_sprite.animation != anim:
			_pet_sprite.play(anim)
	var anchor: Vector2 = Vector2(_pet_walk_x, size.y - 60.0 * ui_scale)
	_pet_sprite.position = anchor
	_pet_sprite.scale = Vector2.ONE * (0.26 * ui_scale)
	_pet_click_area.position = anchor - Vector2(68.0, 70.0) * ui_scale
	_pet_click_area.size = Vector2(136.0, 140.0) * ui_scale


func _process(delta: float) -> void:
	if visible and not _playing:
		_advance_puppy(delta)
	if not visible or _playing or _pointer_kind != "" or absf(_fling_speed) < 8.0:
		return
	var max_scroll: int = maxi(0, roundi(_strip.size.x - _gallery.size.x))
	var next_scroll: int = clampi(roundi(float(_gallery.scroll_horizontal) + _fling_speed * delta), 0, max_scroll)
	if next_scroll == _gallery.scroll_horizontal:
		_fling_speed = 0.0
	else:
		_gallery.scroll_horizontal = next_scroll
		_fling_speed *= exp(-6.0 * delta)


func _reflow() -> void:
	if _background == null or size.x < 10.0 or size.y < 10.0:
		return
	var view: Vector2 = size
	var scale: float = clampf(minf(view.x / 1280.0, view.y / 720.0), 0.62, 1.28)
	_background.position = Vector2.ZERO
	_background.size = view
	_header.position = Vector2.ZERO
	_header.size = view
	_back.size = Vector2.ONE * 58.0 * scale
	_back.position = Vector2(23.0, 18.0) * scale
	var crystal: TextureRect = _header.get_node("ActualBlueCrystal") as TextureRect
	crystal.size = Vector2.ONE * 57.0 * scale
	crystal.position = Vector2(view.x * 0.5 - 60.0 * scale, 17.0 * scale)
	_counter.position = Vector2(view.x * 0.5 + 5.0 * scale, 18.0 * scale)
	_counter.size = Vector2(100.0, 45.0) * scale
	var card_height: float = clampf(view.y * 0.61, 166.0, 440.0)
	for child in _strip.get_children():
		var button: TextureButton = child as TextureButton
		if button == null or button.texture_normal == null:
			continue
		var aspect: float = float(button.texture_normal.get_width()) / maxf(1.0, float(button.texture_normal.get_height()))
		var card_width: float = clampf(card_height * aspect, 112.0 * scale, minf(480.0 * scale, view.x * 0.75))
		button.custom_minimum_size = Vector2(card_width, card_height)
	var margin: float = maxf(14.0, 22.0 * scale)
	_gallery.position = Vector2(margin, 100.0 * scale)
	_gallery.size = Vector2(maxf(100.0, view.x - margin * 2.0), minf(view.y - 116.0 * scale, card_height + 20.0 * scale))
	_gesture_layer.position = _gallery.position
	_gesture_layer.size = _gallery.size
	_game_layer.position = Vector2.ZERO
	_game_layer.size = view
	# Original games were authored at 1536x768: preserve their real
	# coordinates and scale the whole viewport to fit every landscape screen.
	var playtown_scale: float = minf(view.x / 1536.0, view.y / 768.0)
	_viewport_container.scale = Vector2.ONE * playtown_scale
	_viewport_container.size = Vector2(1536.0, 768.0)
	_viewport_container.position = (view - _viewport_container.size * playtown_scale) * 0.5
	_game_back.position = Vector2(12.0, 12.0) * scale
	_game_back.size = Vector2.ONE * 48.0 * scale
	# A compact top-left return-to-flight button; no pet-shop top-right icon.
	_back.size = Vector2.ONE * 51.0 * scale
	_advance_puppy(0.0)
