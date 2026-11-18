extends Control
## Shop prototype: discover hulls and engines; actual purchases are not yet enabled.
signal closed
signal category_inspected(category: String)

const HULL_ICON: Texture2D = preload("res://assets/ui/hull.png")
const ENGINE_ICON: Texture2D = preload("res://assets/ui/engine.png")
const CRYSTAL_ICON: Texture2D = preload("res://assets/ui/crystal.png")
const CLOSE_ICON: Texture2D = preload("res://assets/ui/close.png")

var _frame: Panel
var _close: Button
var _hulls: Button
var _engines: Button
var _heading: Label
var _resource_label: Label
var _caption: Label
var _cards: Array[Panel] = []
var _card_pictures: Array[TextureRect] = []
var _category: String = "hull"
var _crystals: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_frame = Panel.new()
	_frame.name = "Shop_BluePanel"
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.add_theme_stylebox_override("panel", _style(Color(0.018, 0.085, 0.15, 0.98), Color(0.36, 0.73, 0.98), 28, 2))
	add_child(_frame)
	_close = Button.new()
	_close.icon = CLOSE_ICON
	_close.text = ""
	_close.expand_icon = true
	_close.focus_mode = Control.FOCUS_NONE
	_close.add_theme_stylebox_override("normal", _style(Color(0.08, 0.17, 0.26), Color(0.41, 0.80, 1), 28, 2))
	_close.pressed.connect(_exit)
	_frame.add_child(_close)
	_heading = Label.new()
	_heading.text = "МАГАЗИН МИКО"
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.add_theme_font_size_override("font_size", 29)
	_heading.add_theme_color_override("font_color", Color(0.87, 0.95, 1.0))
	_frame.add_child(_heading)
	_resource_label = Label.new()
	_resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_resource_label.add_theme_font_size_override("font_size", 21)
	_resource_label.add_theme_color_override("font_color", Color(0.60, 0.95, 1.0))
	_frame.add_child(_resource_label)
	_hulls = _tab("КОРПУСА", HULL_ICON, "hull")
	_engines = _tab("ДВИГАТЕЛИ", ENGINE_ICON, "engine")
	for i in range(3):
		var card: Panel = Panel.new()
		card.name = "ProductPreview_%d" % i
		card.add_theme_stylebox_override("panel", _style(Color(0.06, 0.15, 0.25), Color(0.25, 0.48, 0.69), 23, 2))
		_frame.add_child(card)
		_cards.append(card)
		var image: TextureRect = TextureRect.new()
		image.texture = HULL_ICON
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(image)
		_card_pictures.append(image)
		var label: Label = Label.new()
		label.name = "LockedUntilGameplay"
		label.text = "◇"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(0.91, 0.75, 0.40))
		card.add_child(label)
	_caption = Label.new()
	_caption.text = "Новые детали появятся позже"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 18)
	_caption.add_theme_color_override("font_color", Color(0.69, 0.85, 0.95))
	_frame.add_child(_caption)
	resized.connect(_reflow)
	MobileLocale.language_changed.connect(_refresh_locale)
	_refresh_locale(MobileLocale.language)
	_update_category()
	_reflow()

func _refresh_locale(_code: String) -> void:
	if _heading != null:
		_heading.text = MobileLocale.t("shop_heading")
	if _hulls != null:
		_hulls.text = MobileLocale.t("shop_hulls")
	if _engines != null:
		_engines.text = MobileLocale.t("shop_engines")
	if _caption != null:
		_caption.text = MobileLocale.t("shop_future")

func _style(bg: Color, outline: Color, rad: int, stroke: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = outline
	s.set_corner_radius_all(rad)
	s.set_border_width_all(stroke)
	return s

func _tab(label_text: String, icon: Texture2D, key: String) -> Button:
	var btn: Button = Button.new()
	btn.name = "Category_" + key
	btn.icon = icon
	btn.text = label_text
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.expand_icon = true
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.89, 0.97, 1.0))
	btn.add_theme_stylebox_override("normal", _style(Color(0.04, 0.15, 0.25), Color(0.28, 0.58, 0.78), 20, 2))
	btn.add_theme_stylebox_override("hover", _style(Color(0.08, 0.26, 0.37), Color(0.80, 0.95, 1.0), 20, 2))
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_set_category.bind(key))
	_frame.add_child(btn)
	return btn

func open_shop(view: Vector2, crystals: int) -> void:
	_crystals = maxi(0, crystals)
	_category = "hull"
	visible = true
	size = view
	_resource_label.text = "◆  " + str(_crystals)
	_update_category()
	_reflow()

func _exit() -> void:
	visible = false
	closed.emit()

func _set_category(key: String) -> void:
	_category = key
	_update_category()
	category_inspected.emit(key)

func _update_category() -> void:
	if _hulls == null or _engines == null:
		return
	for btn in [_hulls, _engines]:
		var chosen: bool = (btn == _hulls and _category == "hull") or (btn == _engines and _category == "engine")
		btn.add_theme_stylebox_override("normal", _style(Color(0.10, 0.30, 0.40) if chosen else Color(0.04, 0.15, 0.25), Color(0.78, 0.96, 1.0) if chosen else Color(0.28, 0.58, 0.78), 20, 2))
	for i in range(_card_pictures.size()):
		_card_pictures[i].texture = HULL_ICON if _category == "hull" else ENGINE_ICON
		_card_pictures[i].modulate = [Color(0.94, 0.98, 1.0), Color(0.65, 0.90, 1.0), Color(1.0, 0.83, 0.60)][i]

func _reflow() -> void:
	if _frame == null:
		return
	var v: Vector2 = size
	var scale_unit: float = clampf(minf(v.x / 1000.0, v.y / 640.0), 0.48, 1.0)
	var width: float = minf(v.x - 30.0, 890.0 * scale_unit)
	var height: float = minf(v.y - 25.0, 565.0 * scale_unit)
	_frame.size = Vector2(width, height)
	_frame.position = (v - _frame.size) * 0.5
	_close.size = Vector2(48.0 * scale_unit, 48.0 * scale_unit)
	_close.position = Vector2(width - 59.0 * scale_unit, 11.0 * scale_unit)
	_heading.position = Vector2(40.0 * scale_unit, 17.0 * scale_unit)
	_heading.size = Vector2(width - 80.0 * scale_unit, 40.0 * scale_unit)
	_heading.add_theme_font_size_override("font_size", maxi(15, int(29.0 * scale_unit)))
	_resource_label.position = Vector2(width - 146.0 * scale_unit, 63.0 * scale_unit)
	_resource_label.size = Vector2(112.0 * scale_unit, 32.0 * scale_unit)
	var tab_width: float = minf((width - 70.0 * scale_unit) * 0.5, 250.0 * scale_unit)
	_hulls.position = Vector2(width * 0.5 - tab_width - 10.0 * scale_unit, 112.0 * scale_unit)
	_engines.position = Vector2(width * 0.5 + 10.0 * scale_unit, 112.0 * scale_unit)
	for btn in [_hulls, _engines]:
		btn.size = Vector2(tab_width, 58.0 * scale_unit)
		btn.add_theme_font_size_override("font_size", maxi(11, int(18.0 * scale_unit)))
	var gap: float = 18.0 * scale_unit
	var card_width: float = (width - 76.0 * scale_unit - gap * 2.0) / 3.0
	var card_height: float = 260.0 * scale_unit
	for i in range(3):
		var card: Panel = _cards[i]
		card.position = Vector2(38.0 * scale_unit + (card_width + gap) * float(i), 195.0 * scale_unit)
		card.size = Vector2(card_width, card_height)
		_card_pictures[i].position = Vector2(card_width * 0.10, 15.0 * scale_unit)
		_card_pictures[i].size = Vector2(card_width * 0.80, card_height * 0.74)
		var lock: Label = card.get_node("LockedUntilGameplay") as Label
		lock.size = Vector2(card_width, 37.0 * scale_unit)
		lock.position = Vector2(0.0, card_height - 47.0 * scale_unit)
	_caption.position = Vector2(0.0, height - 77.0 * scale_unit)
	_caption.size = Vector2(width, 35.0 * scale_unit)
	_caption.add_theme_font_size_override("font_size", maxi(12, int(18.0 * scale_unit)))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.008, 0.025, 0.85))

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_exit()
		get_viewport().set_input_as_handled()
