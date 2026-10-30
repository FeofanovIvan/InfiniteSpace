extends Control
## MIKO compact HUD: seven fuel sticks, one blue crystal and two round buttons.
## No giant aircraft image or numerical resource labels on the child-facing HUD.
signal galaxy_requested
signal main_menu_requested

const CRYSTAL_ICON: Texture2D = preload("res://asteroid_assets/fragments/04_blue/crystal_wedge.png")
const GALAXY_ICON: Texture2D = preload("res://assets/ui/galaxy_button.png")
const PLAYER_SHIP_BUTTON: Texture2D = preload("res://assets/ui/miko_ship_menu_circle.png")

const HUD_WIDTH: float = 126.0
var fuel_segments: int = 7
var crystal_count: int = 0
var _bars: Array[Panel] = []
var _crystal_icon: Sprite2D
var _fuel_count_label: Label
var _blink_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(HUD_WIDTH, 142.0)
	var panel: Panel = Panel.new()
	panel.name = "FuelSticksAndBlueCrystal"
	panel.size = Vector2(HUD_WIDTH, 34.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A hard clip prevents any icon from spilling out over the gameplay field.
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _style(Color(0.016, 0.10, 0.17, 0.91), Color(0.28, 0.64, 0.87, 0.70), 14, 1))
	add_child(panel)
	for i in range(7):
		var seg: Panel = Panel.new()
		seg.name = "FuelStick_%d" % (i + 1)
		seg.position = Vector2(10.0 + float(i) * 10.0, 11.0)
		seg.size = Vector2(7.0, 12.0)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(seg)
		_bars.append(seg)
	# The exact blue crystal used by the asteroid shatter/debris system.
	# Sprite2D uses an explicit fixed scale, preventing texture auto-sizing.
	_crystal_icon = Sprite2D.new()
	_crystal_icon.name = "BlueAsteroidFragment_InsideFuelPanel"
	_crystal_icon.texture = CRYSTAL_ICON
	_crystal_icon.centered = true
	_crystal_icon.position = Vector2(95.0, 17.0)
	_crystal_icon.scale = Vector2.ONE * 0.059
	_crystal_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.add_child(_crystal_icon)
	_fuel_count_label = Label.new()
	_fuel_count_label.name = "FuelCount_50Capacity"
	_fuel_count_label.position = Vector2(101.0, 7.0)
	_fuel_count_label.size = Vector2(23.0, 22.0)
	_fuel_count_label.add_theme_font_size_override("font_size", 11)
	_fuel_count_label.add_theme_color_override("font_color", Color(0.85, 0.96, 1.0))
	_fuel_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_fuel_count_label)
	_make_icon_button("GlobalFlight", GALAXY_ICON, 46.0, MobileLocale.t("galaxy_map"), _open_galaxy)
	_make_ship_menu_button()
	_refresh()
	MobileLocale.language_changed.connect(_refresh_locale)

func _refresh_locale(_code: String) -> void:
	(get_node("GlobalFlight") as Button).tooltip_text = MobileLocale.t("galaxy_map")
	(get_node("MikoMainMenu") as TextureButton).tooltip_text = MobileLocale.t("main_menu")

func _make_icon_button(node_name: String, icon: Texture2D, top: float, description: String, callback: Callable) -> void:
	var button: Button = Button.new()
	button.name = node_name
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.position = Vector2(HUD_WIDTH - 44.0, top)
	button.size = Vector2(42.0, 42.0)
	button.tooltip_text = description
	button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.14, 0.25, 0.98), Color(0.36, 0.76, 1.0), 21, 2))
	button.add_theme_stylebox_override("hover", _style(Color(0.09, 0.28, 0.41), Color(0.72, 0.94, 1.0), 21, 2))
	button.add_theme_stylebox_override("pressed", _style(Color(0.15, 0.39, 0.49), Color(0.83, 0.98, 1.0), 21, 2))
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(callback)
	add_child(button)


func _make_ship_menu_button() -> void:
	# A single baked blue disc with a small top-down ship. We deliberately use
	# TextureButton, not Button + nested TextureRect: the latter could render
	# the native 512px ship outside its 42px parent on narrow phone displays.
	var button: TextureButton = TextureButton.new()
	button.name = "MikoMainMenu"
	button.position = Vector2(HUD_WIDTH - 44.0, 100.0)
	button.size = Vector2(42.0, 42.0)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.texture_normal = PLAYER_SHIP_BUTTON
	button.tooltip_text = MobileLocale.t("main_menu")
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_open_main_menu)
	add_child(button)

func _style(background: Color, outline: Color, corner: int, stroke: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = background
	s.border_color = outline
	s.set_border_width_all(stroke)
	s.set_corner_radius_all(corner)
	return s

func set_fuel_segments(value: int) -> void:
	var next_value: int = clampi(value, 0, 7)
	if next_value == fuel_segments:
		return
	fuel_segments = next_value
	if is_node_ready():
		_refresh()

func set_crystals(value: int) -> void:
	var next_value: int = maxi(0, value)
	if next_value == crystal_count:
		return
	crystal_count = next_value
	if is_node_ready():
		_refresh()

func _process(delta: float) -> void:
	if fuel_segments <= 1:
		var was_bright: bool = sin(_blink_time * 10.0) > 0.0
		_blink_time += delta
		if was_bright != (sin(_blink_time * 10.0) > 0.0):
			_refresh()


func _refresh() -> void:
	var lit: Color = Color("4bde80")
	if fuel_segments == 1:
		lit = Color("fa3348") if sin(_blink_time * 10.0) > 0.0 else Color("641624")
	elif fuel_segments == 2:
		lit = Color("ef8260")
	elif fuel_segments <= 4:
		lit = Color("ffd459")
	for i in range(_bars.size()):
		var cell: Panel = _bars[i]
		var active: bool = i < fuel_segments
		cell.add_theme_stylebox_override("panel", _style(lit if active else Color(0.10, 0.20, 0.27, 0.93), Color(0.8, 0.95, 1.0, 0.4) if active else Color(0.24, 0.35, 0.44, 0.7), 3, 1))
	# This is a pictogram inside the bar, not a count or a spawned world object.
	# Keep it visible even at zero collected crystals.
	if _crystal_icon != null:
		_crystal_icon.modulate = Color.WHITE
	if _fuel_count_label != null:
		_fuel_count_label.text = str(crystal_count)
		_fuel_count_label.add_theme_color_override("font_color", Color("fa585b") if fuel_segments <= 1 and sin(_blink_time * 10.0) > 0.0 else (Color("641624") if fuel_segments <= 1 else Color(0.86, 0.97, 1.0)))

func _open_galaxy() -> void:
	galaxy_requested.emit()

func _open_main_menu() -> void:
	main_menu_requested.emit()
