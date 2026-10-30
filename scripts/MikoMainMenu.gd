extends Control
## MIKO bridge: actual supplied cockpit artwork + touchable holographic consoles.
## This screen is opened from the tiny ship button while space flight is paused.
## Original Miko appears in the central foreground; crew seats remain separate slots.

signal closed

const BRIDGE_TEXTURE: Texture2D = preload("res://assets/bridge/bridge_cockpit.png")
const SIMULATOR_TEXTURE: Texture2D = preload("res://assets/bridge/simulator_console.png")
const SHOP_TEXTURE: Texture2D = preload("res://assets/bridge/shop_console.png")
const CRYSTAL_TEXTURE: Texture2D = preload("res://assets/ui/crystal.png")
const SHIP_TEXTURE: Texture2D = preload("res://assets/ui/miko_ship_menu_circle.png")
const BACK_TEXTURE: Texture2D = preload("res://assets/ui/bridge_back.png")
const SETTINGS_TEXTURE: Texture2D = preload("res://assets/ui/bridge_settings.png")
const CHAR_DIR: String = "res:/" + "/assets/characters/"

var _bridge_background: TextureRect
var _hub: Control
var _detail: Control
var _top: Control
var _simulator: TextureButton
var _shop: TextureButton
var _detail_art: TextureRect
var _detail_title: Label
var _settings_title: Label
var _language_bar: HBoxContainer
var _lang_buttons: Dictionary = {}
var _detail_tint: ColorRect
var _close_button: TextureButton
var _settings_button: TextureButton
var _back_button: TextureButton
var _detail_back_button: TextureButton
var _fly_crystals_label: Label
var _capacity_label: Label
var _speed_label: Label
var _crystals: int = 0
var _capacity: int = 0
var _ship_speed: float = 0.0
var _mode: String = "hub"
var _miko_sprite: TextureRect
var _crew: Array[TextureRect] = []
var _crew_paths: Array[String] = [
	"crew_left_1.png",
	"crew_left_2.png",
	"crew_right_1.png",
	"crew_right_2.png"
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_scene()
	resized.connect(_reflow)
	MobileLocale.language_changed.connect(_refresh_locale)
	_refresh_locale(MobileLocale.language)
	_reflow()

func _build_scene() -> void:
	_bridge_background = TextureRect.new()
	_bridge_background.name = "OriginalMikoBridgeBackground"
	_bridge_background.texture = BRIDGE_TEXTURE
	_bridge_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bridge_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bridge_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bridge_background)

	_hub = Control.new()
	_hub.name = "BridgeWithSimulatorAndShop"
	_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hub)

	# Crew are behind the interactive holograms. The character PNGs are optional.
	for i in range(_crew_paths.size()):
		var crew_image: TextureRect = _add_optional_character(_hub, _crew_paths[i], "CrewSeat_%d" % (i + 1))
		_crew.append(crew_image)
	_miko_sprite = _add_optional_character(_hub, "miko.png", "OriginalMikoCharacter")

	_simulator = _make_console(_hub, "SimulatorConsole", SIMULATOR_TEXTURE, "Учебный симулятор", _open_simulator)
	_shop = _make_console(_hub, "UpgradeShopConsole", SHOP_TEXTURE, "Магазин корабля", _open_shop)

	_top = Control.new()
	_top.name = "BridgeFlightStats"
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_close_button = _make_image_button(_top, "FlyBackToSpace", SHIP_TEXTURE, "Вернуться в полёт", close_menu)
	_settings_button = _make_image_button(_top, "Settings", SETTINGS_TEXTURE, "Настройки", _open_settings)
	# Three compact HUD cards: fuel crystals, crystal capacity and ship speed.
	_fly_crystals_label = _make_stat(_top, "FuelCrystals", CRYSTAL_TEXTURE, "КРИСТАЛЛЫ", "0")
	_capacity_label = _make_stat(_top, "CrystalCapacity", CRYSTAL_TEXTURE, "ВМЕСТИМОСТЬ", "0")
	_speed_label = _make_stat(_top, "ShipSpeed", SHIP_TEXTURE, "СКОРОСТЬ", "0")

	_detail = Control.new()
	_detail.name = "SimulatorShopOrSettingsScreen"
	_detail.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_detail)
	_detail_tint = ColorRect.new()
	_detail_tint.color = Color(0.002, 0.014, 0.035, 0.79)
	_detail_tint.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail.add_child(_detail_tint)
	_detail_art = TextureRect.new()
	_detail_art.name = "SelectedInteractiveStation"
	_detail_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(_detail_art)
	_detail_title = Label.new()
	_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_title.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	_detail_title.add_theme_font_size_override("font_size", 24)
	_detail_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(_detail_title)
	_settings_title = Label.new()
	_settings_title.text = "НАСТРОЙКИ\n\nСкоро здесь появятся настройки звука и управления"
	_settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_settings_title.add_theme_color_override("font_color", Color(0.82, 0.95, 1.0))
	_settings_title.add_theme_font_size_override("font_size", 22)
	_settings_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(_settings_title)
	_language_bar = HBoxContainer.new()
	_language_bar.name = "SixLanguageSelector"
	_language_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_language_bar.add_theme_constant_override("separation", 9)
	_detail.add_child(_language_bar)
	for code in ["en", "ru", "fr", "de", "es", "pt_BR"]:
		var language_button: Button = Button.new()
		language_button.text = "PT-BR" if code == "pt_BR" else code.to_upper()
		language_button.custom_minimum_size = Vector2(76, 52)
		language_button.add_theme_font_size_override("font_size", 17)
		language_button.focus_mode = Control.FOCUS_NONE
		language_button.pressed.connect(_select_language.bind(code))
		_language_bar.add_child(language_button)
		_lang_buttons[code] = language_button
	_detail_back_button = _make_image_button(_detail, "BackToBridge", BACK_TEXTURE, MobileLocale.t("back_bridge"), _back_to_hub)
	_detail.visible = false

func _add_optional_character(parent: Control, path: String, node_name: String) -> TextureRect:
	var avatar: TextureRect = TextureRect.new()
	avatar.name = node_name
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var full_path: String = CHAR_DIR + path
	if ResourceLoader.exists(full_path):
		avatar.texture = load(full_path) as Texture2D
		avatar.visible = avatar.texture != null
	else:
		avatar.visible = false
	parent.add_child(avatar)
	return avatar

func _make_console(parent: Control, node_name: String, picture: Texture2D, tip: String, callback: Callable) -> TextureButton:
	var button: TextureButton = TextureButton.new()
	button.name = node_name
	button.texture_normal = picture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = tip
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _make_image_button(parent: Control, node_name: String, picture: Texture2D, tip: String, callback: Callable) -> TextureButton:
	var button: TextureButton = TextureButton.new()
	button.name = node_name
	button.texture_normal = picture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = tip
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _make_stat(parent: Control, node_name: String, picture: Texture2D, title: String, initial: String) -> Label:
	var panel: Panel = Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box_style: StyleBoxFlat = StyleBoxFlat.new()
	box_style.bg_color = Color(0.005, 0.044, 0.105, 0.94)
	box_style.border_color = Color(0.26, 0.72, 1.0, 0.90)
	box_style.set_border_width_all(2)
	box_style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", box_style)
	parent.add_child(panel)
	var icon: TextureRect = TextureRect.new()
	icon.name = "IndicatorIcon"
	icon.texture = picture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	var title_node: Label = Label.new()
	title_node.name = "Kind"
	title_node.text = title
	title_node.add_theme_color_override("font_color", Color(0.66, 0.88, 1.0))
	title_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_node)
	var value: Label = Label.new()
	value.name = "Value"
	value.text = initial
	value.add_theme_color_override("font_color", Color.WHITE)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(value)
	return value

func set_stats(flight_crystals: int, capacity: int, ship_speed: float) -> void:
	_crystals = maxi(0, flight_crystals)
	_capacity = maxi(0, capacity)
	_ship_speed = maxf(0.0, ship_speed)
	if _fly_crystals_label != null:
		_fly_crystals_label.text = str(_crystals)
	if _capacity_label != null:
		_capacity_label.text = str(_capacity)
	if _speed_label != null:
		_speed_label.text = str(int(round(_ship_speed)))

func open_menu(view: Vector2) -> void:
	size = view
	visible = true
	_back_to_hub()
	_reflow()

func close_menu() -> void:
	visible = false
	closed.emit()

func _open_simulator() -> void:
	_open_detail("simulator")

func _open_shop() -> void:
	_open_detail("shop")

func _open_settings() -> void:
	_open_detail("settings")

func _open_detail(mode: String) -> void:
	_mode = mode
	_hub.visible = false
	_top.visible = false
	_detail.visible = true
	_language_bar.visible = mode == "settings"
	_settings_title.visible = mode == "settings"
	_detail_art.visible = mode != "settings"
	_detail_title.visible = mode != "settings"
	if mode == "simulator":
		_detail_art.texture = SIMULATOR_TEXTURE
		_detail_title.text = MobileLocale.t("sim_soon")
	elif mode == "shop":
		_detail_art.texture = SHOP_TEXTURE
		_detail_title.text = MobileLocale.t("shop_soon")
	_reflow()

func _select_language(code: String) -> void:
	MobileLocale.set_language(code)

func _refresh_locale(_code: String) -> void:
	if _settings_title != null:
		_settings_title.text = MobileLocale.t("settings") + "\n\n" + MobileLocale.t("settings_description")
	if _close_button != null:
		_close_button.tooltip_text = MobileLocale.t("bridge_flight")
	if _settings_button != null:
		_settings_button.tooltip_text = MobileLocale.t("bridge_settings")
	if _detail_back_button != null:
		_detail_back_button.tooltip_text = MobileLocale.t("back_bridge")
	if _simulator != null:
		_simulator.tooltip_text = MobileLocale.t("bridge_sim")
	if _shop != null:
		_shop.tooltip_text = MobileLocale.t("bridge_shop")
	for key in _lang_buttons:
		var button: Button = _lang_buttons[key] as Button
		button.modulate = Color(1.0, 0.94, 0.50) if key == MobileLocale.language else Color.WHITE
	for pair in [["FuelCrystals", "crystals"], ["CrystalCapacity", "capacity"], ["ShipSpeed", "speed"]]:
		var stat: Panel = _top.get_node_or_null(pair[0]) as Panel
		if stat != null:
			(stat.get_node("Kind") as Label).text = MobileLocale.t(pair[1])
	if _mode == "simulator":
		_detail_title.text = MobileLocale.t("sim_soon")
	elif _mode == "shop":
		_detail_title.text = MobileLocale.t("shop_soon")

func _back_to_hub() -> void:
	_mode = "hub"
	_detail.visible = false
	_hub.visible = true
	_top.visible = true

func _reflow() -> void:
	if _bridge_background == null:
		return
	var view: Vector2 = size
	var safe: Rect2 = MobileLocale.safe_rect(view)
	if view.x <= 0.0 or view.y <= 0.0:
		return
	_bridge_background.position = Vector2.ZERO
	_bridge_background.size = view
	_hub.position = Vector2.ZERO
	_hub.size = view
	_top.position = Vector2.ZERO
	_top.size = view
	_detail.position = Vector2.ZERO
	_detail.size = view
	_detail_tint.position = Vector2.ZERO
	_detail_tint.size = view
	# All positions are proportional to the viewport, suitable for mobile landscape.
	var s: float = clampf(minf(view.x / 1280.0, view.y / 720.0), 0.58, 1.35)
	var podium_width: float = minf(view.x * 0.39, 490.0 * s)
	var podium_height: float = podium_width * 2.0 / 3.0
	var podium_y: float = view.y - podium_height - 3.0 * s
	_simulator.position = Vector2(view.x * 0.015, podium_y)
	_simulator.size = Vector2(podium_width, podium_height)
	_shop.position = Vector2(view.x - podium_width - view.x * 0.015, podium_y)
	_shop.size = Vector2(podium_width, podium_height)
	# Original MIKO sprite is drawn only if the matching PNG is present.
	_miko_sprite.size = Vector2(176.0, 242.0) * s
	_miko_sprite.position = Vector2(view.x * 0.5 - _miko_sprite.size.x * 0.5, view.y * 0.89 - _miko_sprite.size.y)
	var seat_centers: Array[Vector2] = [
		Vector2(0.225, 0.48), Vector2(0.375, 0.48),
		Vector2(0.625, 0.48), Vector2(0.775, 0.48)
	]
	for i in range(_crew.size()):
		var figure: TextureRect = _crew[i]
		figure.size = Vector2(92.0, 143.0) * s
		figure.position = seat_centers[i] * view - figure.size * Vector2(0.5, 0.58)
	# Leave the middle of the header for cockpit scenery, not a wall of data.
	var corner: float = 63.0 * s
	_close_button.size = Vector2.ONE * corner
	_close_button.position = safe.position + Vector2(6.0 * s, 6.0 * s)
	_settings_button.size = Vector2.ONE * corner
	_settings_button.position = Vector2(safe.end.x - corner - 6.0 * s, safe.position.y + 6.0 * s)
	var gutter: float = 12.0 * s
	var stat_total_width: float = minf(view.x - 2.0 * (corner + 26.0 * s), 835.0 * s)
	var stat_width: float = (stat_total_width - 2.0 * gutter) / 3.0
	var first_x: float = (view.x - stat_total_width) * 0.5
	var panel_names: Array[String] = ["FuelCrystals", "CrystalCapacity", "ShipSpeed"]
	for i in range(3):
		var panel: Panel = _top.get_node(panel_names[i]) as Panel
		panel.position = Vector2(first_x + i * (stat_width + gutter), 14.0 * s)
		panel.size = Vector2(stat_width, 56.0 * s)
		var indicator_icon: TextureRect = panel.get_node("IndicatorIcon") as TextureRect
		indicator_icon.position = Vector2(9.0, 6.0) * s
		indicator_icon.size = Vector2(40.0, 40.0) * s
		var label: Label = panel.get_node("Kind") as Label
		label.position = Vector2(52.0, 7.0) * s
		label.size = Vector2(maxf(80.0, stat_width / s - 115.0), 20.0) * s
		label.add_theme_font_size_override("font_size", maxi(10, int(14.0 * s)))
		var value: Label = panel.get_node("Value") as Label
		value.position = Vector2(stat_width - 60.0 * s, 13.0 * s)
		value.size = Vector2(47.0, 31.0) * s
		value.add_theme_font_size_override("font_size", maxi(14, int(26.0 * s)))
	# Larger screen graphics, but a small and clear top-left return button.
	_detail_back_button.position = safe.position + Vector2(6.0 * s, 6.0 * s)
	_detail_back_button.size = Vector2.ONE * 63.0 * s
	_detail_art.size = Vector2(minf(view.x * 0.86, view.y * 1.23), view.y * 0.78)
	_detail_art.position = (view - _detail_art.size) * 0.5 + Vector2(0.0, 26.0 * s)
	_detail_title.position = Vector2(0.0, view.y - 57.0 * s)
	_detail_title.size = Vector2(view.x, 40.0 * s)
	_detail_title.add_theme_font_size_override("font_size", maxi(14, int(23.0 * s)))
	_settings_title.size = view * Vector2(0.78, 0.42)
	_settings_title.position = Vector2((view.x - _settings_title.size.x) * 0.5, view.y * 0.25)
	_settings_title.add_theme_font_size_override("font_size", maxi(14, int(22.0 * s)))
	_language_bar.size = Vector2(minf(view.x * 0.90, 680.0 * s), 62.0 * s)
	_language_bar.position = Vector2((view.x - _language_bar.size.x) * 0.5, view.y * 0.62)
	var button_size: float = maxf(48.0, (_language_bar.size.x - 45.0) / 6.0)
	for code in _lang_buttons:
		var button: Button = _lang_buttons[code] as Button
		button.custom_minimum_size = Vector2(button_size, maxf(46.0, 52.0 * s))
