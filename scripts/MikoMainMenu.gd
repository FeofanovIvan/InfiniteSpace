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

var _background: TextureRect
var _header: Control
var _counter: Label
var _gallery: ScrollContainer
var _strip: HBoxContainer
var _back: TextureButton
var _left_arrow: Button
var _right_arrow: Button
var _game_layer: Control
var _viewport_container: SubViewportContainer
var _game_viewport: SubViewport
var _game_back: Button
var _cards: Array[Dictionary] = []
var _crystal_balance: int = 0
var _last_playtown_coins: int = 0
var _playing: bool = false


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
	_gallery.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_gallery.follow_focus = true
	_gallery.clip_contents = true
	_gallery.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_gallery)
	_strip = HBoxContainer.new()
	_strip.name = "PlayTownEducation_CardStrip"
	_strip.alignment = BoxContainer.ALIGNMENT_BEGIN
	_strip.add_theme_constant_override("separation", 20)
	_gallery.add_child(_strip)
	_left_arrow = _arrow("❮", -1)
	_right_arrow = _arrow("❯", 1)
	_load_original_catalog()
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


func _arrow(glyph: String, direction: int) -> Button:
	var button: Button = Button.new()
	button.text = glyph
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 29)
	button.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.15, 0.26, 0.85)
	sb.border_color = Color(0.38, 0.75, 1.0, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(27)
	button.add_theme_stylebox_override("normal", sb)
	button.pressed.connect(_scroll_by.bind(direction))
	add_child(button)
	return button


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
		var button: Button = Button.new()
		button.name = "PlayTownCard_" + str(info.get("id", "unknown"))
		button.custom_minimum_size = Vector2(255, 315)
		button.focus_mode = Control.FOCUS_NONE
		button.clip_contents = true
		button.tooltip_text = str(info.get("name_ru", ""))
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.025, 0.09, 0.20, 0.96)
		sb.border_color = Color(0.30, 0.69, 0.95, 0.85)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(17)
		button.add_theme_stylebox_override("normal", sb)
		var picture: TextureRect = TextureRect.new()
		picture.name = "UnchangedOriginalGameCard"
		picture.texture = load(art_path) as Texture2D
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(picture)
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
	_left_arrow.visible = false
	_right_arrow.visible = false
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
	_left_arrow.visible = true
	_right_arrow.visible = true
	_header.visible = true


func _scroll_by(direction: int) -> void:
	if _gallery == null:
		return
	var move: int = int(294.0 * (1.0 if direction > 0 else -1.0))
	_gallery.scroll_horizontal = maxi(0, _gallery.scroll_horizontal + move)


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
	var card_width: float = clampf(view.x * 0.23, 150.0, 278.0)
	var card_height: float = clampf(view.y * 0.49, 205.0, 348.0)
	for child in _strip.get_children():
		var button: Button = child as Button
		button.custom_minimum_size = Vector2(card_width, card_height)
	var border: float = 84.0 * scale
	_gallery.position = Vector2(border, 118.0 * scale)
	_gallery.size = Vector2(maxf(100.0, view.x - border * 2.0), minf(view.y - 160.0 * scale, card_height + 20.0))
	_left_arrow.position = Vector2(12.0 * scale, _gallery.position.y + (_gallery.size.y - 53.0 * scale) * 0.5)
	_left_arrow.size = Vector2.ONE * 53.0 * scale
	_right_arrow.position = Vector2(view.x - 65.0 * scale, _left_arrow.position.y)
	_right_arrow.size = _left_arrow.size
	_game_layer.position = Vector2.ZERO
	_game_layer.size = view
	# Original games were authored at 1536x768: preserve their real
	# coordinates and scale the whole viewport to fit every landscape screen.
	var playtown_scale: float = minf(view.x / 1536.0, view.y / 768.0)
	_viewport_container.scale = Vector2.ONE * playtown_scale
	_viewport_container.size = Vector2(1536.0, 768.0)
	_viewport_container.position = (view - _viewport_container.size * playtown_scale) * 0.5
	_game_back.position = Vector2(12.0, 12.0) * scale
	_game_back.size = Vector2.ONE * 54.0 * scale
