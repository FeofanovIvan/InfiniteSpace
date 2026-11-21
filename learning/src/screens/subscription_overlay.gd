extends CanvasLayer

signal closed

const PARENT_CROWN := preload("res://learning/assets/ui/subscription/parent_crown.png")
const SUBSCRIPTION_ICON := preload("res://learning/assets/ui/subscription/subscription_icon.png")
const PRIVACY_POLICY_URL := "https://mika.playtownkids.app/privacy/"
const TERMS_OF_USE_URL := "https://mika.playtownkids.app/terms/"
var backdrop: ColorRect
var card: PanelContainer
var scroll: ScrollContainer
var content_margin: MarginContainer
var content_center: CenterContainer
var content: VBoxContainer
var answer_input: LineEdit
var review_code_input: LineEdit
var message_label: Label
var challenge_answer := 0
var purchase_button: Button
var keyboard_height := 0
var locked := false
var show_expiration_notice := false
var retry_button: Button
var voice_player: AudioStreamPlayer

func set_locked(value: bool) -> void:
	locked = value

func set_show_expiration_notice(value: bool) -> void:
	show_expiration_notice = value

func _ready() -> void:
	layer = 120
	backdrop = ColorRect.new()
	backdrop.color = Color(0.04, 0.08, 0.12, 0.78)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style())
	backdrop.add_child(card)
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.scroll_deadzone = 4
	card.add_child(scroll)
	content_margin = MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 28)
	content_margin.add_theme_constant_override("margin_right", 28)
	content_margin.add_theme_constant_override("margin_top", 22)
	content_margin.add_theme_constant_override("margin_bottom", 22)
	scroll.add_child(content_margin)
	content_center = CenterContainer.new()
	content_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_child(content_center)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_theme_constant_override("separation", 9)
	content_center.add_child(content)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	get_viewport().size_changed.connect(_layout)
	set_process(true)
	BillingService.store_ready.connect(_on_store_ready)
	BillingService.products_updated.connect(_on_products_updated)
	BillingService.entitlement_changed.connect(_on_entitlement_changed)
	BillingService.purchase_pending.connect(_on_purchase_pending)
	BillingService.purchase_canceled.connect(_on_purchase_canceled)
	BillingService.billing_error.connect(_on_billing_error)
	_layout()
	if show_expiration_notice:
		_show_preview_expired_notice()
	else:
		_show_adult_gate()

func _process(_delta: float) -> void:
	var current_height := DisplayServer.virtual_keyboard_get_height()
	if current_height == keyboard_height:
		return
	keyboard_height = current_height
	_layout()
	var focused_input := _active_text_input()
	if keyboard_height > 0 and is_instance_valid(focused_input):
		scroll.ensure_control_visible.call_deferred(focused_input)

func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var keyboard_in_viewport := 0.0
	if keyboard_height > 0:
		var window_height := maxf(1.0, float(DisplayServer.window_get_size().y))
		keyboard_in_viewport = float(keyboard_height) * viewport_size.y / window_height
	var available_height := viewport_size.y - keyboard_in_viewport
	var card_size := Vector2(
		minf(760.0, viewport_size.x - 36.0),
		minf(680.0, maxf(250.0, available_height - 20.0))
	)
	card.size = card_size
	card.position.x = (viewport_size.x - card_size.x) * 0.5
	card.position.y = 10.0 if keyboard_height > 0 else (viewport_size.y - card_size.y) * 0.5
	if is_instance_valid(content_margin):
		content_margin.custom_minimum_size = Vector2(card_size.x - 12.0, card_size.y - 12.0)
	if is_instance_valid(content):
		content.custom_minimum_size = Vector2(minf(570.0, card_size.x - 92.0), 0.0)

func _show_preview_expired_notice() -> void:
	_clear_content()
	_add_subscription_icon()
	_add_title(_t("preview_complete_title"))
	_add_body(_t("preview_complete_body"))
	_add_body(_t("one_time_purchase_notice"))
	message_label = _add_status("")
	var parent_button := _make_button(_t("for_parents"), Color(1.0, 0.66, 0.12), Color(0.35, 0.21, 0.08))
	parent_button.custom_minimum_size.y = 64
	parent_button.pressed.connect(_show_adult_gate)
	content.add_child(parent_button)
	var restore_button := _make_button(_t("restore_purchases"), Color(0.72, 0.56, 0.32))
	restore_button.pressed.connect(_restore)
	content.add_child(restore_button)
	retry_button = _make_button(_t("retry_store"), Color(0.40, 0.64, 0.84))
	retry_button.visible = false
	retry_button.pressed.connect(_retry_store)
	content.add_child(retry_button)
	var parent_hint := _add_status(_t("parent_check_hint"))
	parent_hint.add_theme_color_override("font_color", Color(0.43, 0.36, 0.25))
	parent_hint.add_theme_font_size_override("font_size", 17)

func _show_adult_gate() -> void:
	_clear_content()
	_play_parent_gate_voice()
	var first := randi_range(18, 39)
	var second := randi_range(12, 28)
	challenge_answer = first + second
	_add_crown()
	_add_title(_t("parents_title"))
	_add_body(_t("parents_subtitle"))
	var equation_panel := PanelContainer.new()
	equation_panel.custom_minimum_size = Vector2(0, 76)
	equation_panel.add_theme_stylebox_override("panel", _equation_style())
	var equation := Label.new()
	equation.text = "%d + %d = ?" % [first, second]
	equation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equation.add_theme_font_size_override("font_size", 36)
	equation.add_theme_color_override("font_color", Color(0.35, 0.21, 0.08))
	equation_panel.add_child(equation)
	content.add_child(equation_panel)
	answer_input = LineEdit.new()
	answer_input.custom_minimum_size = Vector2(0, 56)
	answer_input.placeholder_text = _t("enter_answer")
	answer_input.max_length = 3
	answer_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	answer_input.add_theme_font_size_override("font_size", 25)
	answer_input.add_theme_color_override("font_color", Color(0.31, 0.22, 0.13))
	answer_input.add_theme_color_override("font_placeholder_color", Color(0.52, 0.43, 0.32, 0.72))
	answer_input.add_theme_color_override("caret_color", Color(0.92, 0.55, 0.08))
	answer_input.add_theme_stylebox_override("normal", _input_style(Color(0.82, 0.59, 0.20)))
	answer_input.add_theme_stylebox_override("focus", _input_style(Color(1.0, 0.61, 0.08)))
	answer_input.focus_entered.connect(_on_answer_focus_entered)
	answer_input.focus_exited.connect(_on_answer_focus_exited)
	answer_input.text_submitted.connect(func(_value: String): _verify_answer())
	content.add_child(answer_input)
	message_label = _add_status("")
	var continue_button := _make_button(_t("continue"), Color(1.0, 0.66, 0.12), Color(0.35, 0.21, 0.08))
	continue_button.pressed.connect(_verify_answer)
	content.add_child(continue_button)
	var close_button := _make_button(_t("back"), Color(0.78, 0.62, 0.36))
	if locked:
		close_button.pressed.connect(_show_preview_expired_notice)
	else:
		close_button.pressed.connect(_close)
	content.add_child(close_button)
	answer_input.grab_focus.call_deferred()

func _on_answer_focus_entered() -> void:
	_layout_after_keyboard_change()

func _on_answer_focus_exited() -> void:
	_layout_after_keyboard_change()

func _layout_after_keyboard_change() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	keyboard_height = DisplayServer.virtual_keyboard_get_height()
	_layout()
	if keyboard_height > 0 and is_instance_valid(answer_input):
		scroll.ensure_control_visible(answer_input)

func _verify_answer() -> void:
	if answer_input.text.to_int() != challenge_answer:
		message_label.text = _t("try_again")
		answer_input.clear()
		answer_input.grab_focus()
		return
	_show_purchase()

func _show_purchase() -> void:
	_clear_content()
	purchase_button = null
	_add_crown()
	_add_title(_t("full_game_title"))
	_add_body(_t("full_game_body"))
	message_label = _add_status(_t("store_connecting"))
	if AccessService.full_game_owned:
		message_label.text = _t("full_game_active")
	else:
		purchase_button = _make_button(_t("buy_full_game"), Color(1.0, 0.70, 0.16), Color(0.35, 0.21, 0.08))
		purchase_button.disabled = true
		purchase_button.pressed.connect(_purchase)
		content.add_child(purchase_button)
		var restore_button := _make_button(_t("restore_purchases"), Color(0.72, 0.56, 0.32))
		restore_button.pressed.connect(_restore)
		content.add_child(restore_button)
		retry_button = _make_button(_t("retry_store"), Color(0.40, 0.64, 0.84))
		retry_button.visible = false
		retry_button.pressed.connect(_retry_store)
		content.add_child(retry_button)
	_add_legal_information()
	_add_reviewer_access_link()
	var close_button := _make_button(_t("back" if locked else "back_to_game"), Color(0.78, 0.62, 0.36))
	if locked:
		close_button.pressed.connect(_show_preview_expired_notice)
	else:
		close_button.pressed.connect(_close)
	content.add_child(close_button)
	_update_store_state()
	BillingService.refresh()

func _purchase() -> void:
	_set_purchase_disabled(true)
	message_label.text = _t("store_opening")
	if not BillingService.purchase_full_game():
		message_label.text = _t("store_unavailable")
		_set_purchase_disabled(false)

func _restore() -> void:
	message_label.text = _t("restoring_purchases")
	BillingService.restore_purchases()

func _retry_store() -> void:
	message_label.text = _t("store_connecting")
	if is_instance_valid(retry_button):
		retry_button.visible = false
	BillingService.retry_store_connection()

func _on_store_ready() -> void:
	if visible:
		BillingService.refresh()

func _on_products_updated(_products: Array) -> void:
	if not is_instance_valid(message_label):
		return
	_update_store_state()

func _on_entitlement_changed(active: bool) -> void:
	if active and visible:
		if locked:
			_close()
		else:
			_show_purchase()

func _on_purchase_pending() -> void:
	if is_instance_valid(message_label):
		message_label.text = _t("purchase_pending")

func _on_purchase_canceled() -> void:
	if not is_instance_valid(message_label):
		return
	_update_store_state()
	message_label.text = _t("purchase_canceled")

func _on_billing_error(_code: int, error_message: String) -> void:
	if not is_instance_valid(message_label):
		return
	message_label.text = _t("store_unavailable")
	_set_purchase_disabled(true)
	if is_instance_valid(retry_button):
		retry_button.visible = true

func _update_store_state() -> void:
	if not is_instance_valid(purchase_button):
		return
	var products_available := not BillingService.get_products().is_empty()
	_set_purchase_disabled(not products_available)
	if products_available:
		if is_instance_valid(retry_button):
			retry_button.visible = false
		message_label.text = _t("purchase_ready")
		var info: Dictionary = BillingService.get_full_game_info()
		var price := str(info.get("formatted_price", ""))
		purchase_button.text = _t("buy_full_game")
		if not price.is_empty():
			purchase_button.text += "  •  " + price
	elif not BillingService.get_last_error_message().is_empty():
		_on_billing_error(-1, BillingService.get_last_error_message())
	elif OS.get_name() == "Android":
		message_label.text = _t("store_connecting")
	else:
		message_label.text = _t("store_connecting")
		if is_instance_valid(retry_button):
			retry_button.visible = true

func _set_purchase_disabled(value: bool) -> void:
	if is_instance_valid(purchase_button):
		purchase_button.disabled = value

func _add_reviewer_access_link() -> void:
	var link := LinkButton.new()
	link.name = "ReviewerAccess"
	link.text = "Reviewer access"
	link.custom_minimum_size.y = 34
	link.add_theme_font_size_override("font_size", 15)
	link.add_theme_color_override("font_color", Color(0.42, 0.48, 0.54))
	link.add_theme_color_override("font_hover_color", Color(0.08, 0.39, 0.66))
	link.pressed.connect(_show_reviewer_access)
	content.add_child(link)

func _show_reviewer_access() -> void:
	_clear_content()
	_add_crown()
	_add_title("Reviewer access")
	_add_body("Enter the reusable access code supplied in Google Play Console.")
	review_code_input = LineEdit.new()
	review_code_input.name = "ReviewerAccessCode"
	review_code_input.custom_minimum_size = Vector2(0, 56)
	review_code_input.placeholder_text = "Access code"
	review_code_input.max_length = 64
	review_code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	review_code_input.add_theme_font_size_override("font_size", 22)
	review_code_input.add_theme_color_override("font_color", Color(0.31, 0.22, 0.13))
	review_code_input.add_theme_stylebox_override("normal", _input_style(Color(0.45, 0.62, 0.76)))
	review_code_input.add_theme_stylebox_override("focus", _input_style(Color(0.08, 0.39, 0.66)))
	review_code_input.focus_entered.connect(_layout_after_keyboard_change)
	review_code_input.focus_exited.connect(_layout_after_keyboard_change)
	review_code_input.text_submitted.connect(func(_value: String): _verify_reviewer_code())
	content.add_child(review_code_input)
	message_label = _add_status("")
	var unlock_button := _make_button("Unlock for review", Color(0.24, 0.53, 0.72))
	unlock_button.pressed.connect(_verify_reviewer_code)
	content.add_child(unlock_button)
	var back_button := _make_button(_t("back"), Color(0.78, 0.62, 0.36))
	back_button.pressed.connect(_show_purchase)
	content.add_child(back_button)
	review_code_input.grab_focus.call_deferred()

func _verify_reviewer_code() -> void:
	if not is_instance_valid(review_code_input):
		return
	if AccessService.activate_reviewer_access(review_code_input.text):
		message_label.text = "Review access enabled for this session."
		return
	message_label.text = "Invalid access code."
	review_code_input.clear()
	review_code_input.grab_focus()

func _close() -> void:
	if locked and not AccessService.has_access():
		return
	closed.emit()
	queue_free()

func _add_legal_information() -> void:
	var renewal_notice := Label.new()
	renewal_notice.text = _t("one_time_purchase_legal")
	renewal_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	renewal_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	renewal_notice.add_theme_font_size_override("font_size", 16)
	renewal_notice.add_theme_color_override("font_color", Color(0.42, 0.35, 0.26))
	content.add_child(renewal_notice)
	var links := HBoxContainer.new()
	links.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	links.add_theme_constant_override("separation", 28)
	content.add_child(links)
	for item in [
		[_t("privacy_policy"), PRIVACY_POLICY_URL],
		[_t("terms_of_use"), TERMS_OF_USE_URL],
	]:
		var link := LinkButton.new()
		link.text = item[0]
		link.custom_minimum_size.y = 34
		link.add_theme_font_size_override("font_size", 17)
		link.add_theme_color_override("font_color", Color(0.08, 0.39, 0.66))
		link.add_theme_color_override("font_hover_color", Color(0.96, 0.51, 0.08))
		link.pressed.connect(_open_legal_url.bind(item[1]))
		links.add_child(link)

func _open_legal_url(url: String) -> void:
	OS.shell_open(url)

func _clear_content() -> void:
	answer_input = null
	review_code_input = null
	for child in content.get_children():
		child.queue_free()

func _active_text_input() -> LineEdit:
	if is_instance_valid(review_code_input):
		return review_code_input
	return answer_input if is_instance_valid(answer_input) else null

func _add_crown() -> TextureRect:
	var crown := TextureRect.new()
	crown.texture = PARENT_CROWN
	crown.custom_minimum_size = Vector2(0, 74)
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(crown)
	return crown

func _add_subscription_icon() -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = SUBSCRIPTION_ICON
	icon.custom_minimum_size = Vector2(0, 116)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	return icon

func _add_title(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", Color(0.35, 0.21, 0.08))
	content.add_child(label)
	return label

func _add_body(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color(0.32, 0.27, 0.20))
	content.add_child(label)
	return label

func _add_status(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.custom_minimum_size = Vector2(0, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.68, 0.28, 0.18))
	content.add_child(label)
	return label

func _make_button(label: String, color: Color, text_color: Color = Color.WHITE) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 54)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color(0.47, 0.41, 0.31))
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.85, 0.80, 0.68)))
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.88)
	style.border_color = Color(0.96, 0.61, 0.10)
	style.set_border_width_all(4)
	style.set_corner_radius_all(30)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 18
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(0.28)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

func _equation_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.91, 0.64)
	style.border_color = Color(0.94, 0.62, 0.14)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	return style

func _input_style(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.995, 0.96)
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style

func _t(key: String) -> String:
	return LanguageService.get_ui_text(key)

func _play_parent_gate_voice() -> void:
	var stream := LanguageService.get_ui_voice("parent_gate_intro")
	if stream == null:
		return
	voice_player.stream = stream
	voice_player.play()
