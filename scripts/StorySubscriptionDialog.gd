extends CanvasLayer
## Native MIKA neon hologram; no OS-styled ConfirmationDialog and no new .tscn.

signal subscribe_requested
signal dismissed

var _root: Control
var _panel: Panel
var _kicker: Label
var _divider: ColorRect
var _title_label: Label
var _body_label: Label
var _subscribe_button: Button
var _later_button: Button


func _ready() -> void:
	layer = 170
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "MIKA_SubscriptionHologram"
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "SpaceDimmer"
	backdrop.color = Color(0.005, 0.018, 0.055, 0.83)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# A plain Panel is critical: containers calculate intrinsic height before
	# wrapped text has a width and can push the buttons thousands of pixels away.
	_panel = Panel.new()
	_panel.name = "NeonSubscriptionCard"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(_panel)
	_kicker = Label.new()
	_kicker.text = "✦  MIKA  /  INFINITE SPACE"
	_kicker.add_theme_color_override("font_color", Color("ffbf66"))
	_kicker.add_theme_font_size_override("font_size", 13)
	_panel.add_child(_kicker)
	_divider = ColorRect.new()
	_divider.color = Color("25d9ff")
	_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_divider)
	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color("eafbff"))
	_panel.add_child(_title_label)
	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_label.add_theme_font_size_override("font_size", 18)
	_body_label.add_theme_color_override("font_color", Color("b7dbea"))
	_panel.add_child(_body_label)
	_later_button = _make_button(false)
	_panel.add_child(_later_button)
	_later_button.pressed.connect(func() -> void: dismissed.emit())
	_subscribe_button = _make_button(true)
	_panel.add_child(_subscribe_button)
	_subscribe_button.pressed.connect(func() -> void: subscribe_requested.emit())
	_root.resized.connect(_layout)
	_layout()


func _panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("071f3b")
	style.border_color = Color("2edaff")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.04, 0.60, 1.0, 0.55)
	style.shadow_size = 16
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


func _button_style(primary: bool, hovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("554021") if primary and hovered else (Color("3b2c1c") if primary else (Color("134567") if hovered else Color("0b314e")))
	style.border_color = Color("ffbb63") if primary else Color("32d5f4")
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.shadow_color = Color(1.0, 0.46, 0.10, 0.35) if primary else Color(0.03, 0.65, 1.0, 0.28)
	style.shadow_size = 6
	return style


func _make_button(primary: bool) -> Button:
	var button: Button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(135, 50)
	button.add_theme_stylebox_override("normal", _button_style(primary, false))
	button.add_theme_stylebox_override("hover", _button_style(primary, true))
	button.add_theme_stylebox_override("pressed", _button_style(primary, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("fff7df") if primary else Color("e4f7ff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 17)
	return button


func configure(title_text: String, body_text: String, subscribe_text: String, later_text: String) -> void:
	_title_label.text = title_text
	_body_label.text = body_text
	_subscribe_button.text = subscribe_text
	_subscribe_button.show()
	_later_button.text = later_text
	_layout()


func show_store_unavailable(title_text: String, body_text: String, ok_text: String) -> void:
	_title_label.text = title_text
	_body_label.text = body_text
	_subscribe_button.hide()
	_later_button.text = ok_text
	_layout()


func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	var safe: Rect2 = MobileLocale.safe_rect(view)
	var width: float = minf(660.0, maxf(1.0, safe.size.x - 32.0))
	var height: float = minf(348.0, maxf(1.0, safe.size.y - 28.0))
	_panel.size = Vector2(width, height)
	_panel.position = safe.position + (safe.size - _panel.size) * 0.5
	var compact: bool = height < 300.0
	var inset: float = 17.0 if compact else 24.0
	var usable: float = maxf(0.0, width - 2.0 * inset)
	_kicker.position = Vector2(inset, 12.0 if compact else 17.0)
	_kicker.size = Vector2(usable, 20.0)
	_divider.position = Vector2(inset, 38.0 if compact else 45.0)
	_divider.size = Vector2(usable, 2.0)
	_title_label.position = Vector2(inset, 46.0 if compact else 57.0)
	_title_label.size = Vector2(usable, 38.0 if compact else 43.0)
	_title_label.add_theme_font_size_override("font_size", 21 if compact else 25)
	var text_top: float = 88.0 if compact else 108.0
	var button_height: float = 44.0 if compact else 50.0
	var button_y: float = height - button_height - (14.0 if compact else 23.0)
	_body_label.position = Vector2(inset, text_top)
	_body_label.size = Vector2(usable, maxf(25.0, button_y - text_top - 12.0))
	_body_label.add_theme_font_size_override("font_size", 15 if compact else 18)
	var later_width: float = minf(145.0, maxf(90.0, usable * 0.33))
	var buy_width: float = minf(222.0, maxf(120.0, usable * 0.49))
	var gap: float = 11.0
	if not _subscribe_button.visible:
		_later_button.position = Vector2(width - inset - later_width, button_y)
	else:
		_later_button.position = Vector2(width - inset - later_width - gap - buy_width, button_y)
	_later_button.size = Vector2(later_width, button_height)
	_subscribe_button.position = Vector2(width - inset - buy_width, button_y)
	_subscribe_button.size = Vector2(buy_width, button_height)
	_later_button.add_theme_font_size_override("font_size", 15 if compact else 17)
	_subscribe_button.add_theme_font_size_override("font_size", 15 if compact else 17)
