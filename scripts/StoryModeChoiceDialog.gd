extends "res://scripts/StorySubscriptionDialog.gd"
## The existing MIKA hologram with a third action for story checkpoints.
## No OS ConfirmationDialog, new scene, or changes to the checkpoint format.

signal restart_requested

var _restart_button: Button


func _ready() -> void:
	super._ready()
	_restart_button = _make_button(false)
	_restart_button.name = "RestartStory"
	_panel.add_child(_restart_button)
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_layout()


func configure_choice(title_text: String, question: String, continue_text: String, restart_text: String, cancel_text: String) -> void:
	configure(title_text, question, continue_text, cancel_text)
	_restart_button.text = restart_text
	_layout()


func _layout() -> void:
	super._layout()
	if not is_instance_valid(_restart_button):
		return
	var width: float = _panel.size.x
	var height: float = _panel.size.y
	var inset: float = 17.0 if height < 300.0 else 24.0
	var usable: float = width - inset * 2.0
	var safe: Rect2 = MobileLocale.safe_rect(get_viewport().get_visible_rect().size)
	if width < 500.0 and safe.size.y >= 490.0:
		# Portrait phones: three full-width actions, all within the safe area.
		_panel.size.y = minf(470.0, safe.size.y - 22.0)
		_panel.position = safe.position + (safe.size - _panel.size) * 0.5
		height = _panel.size.y
		_body_label.size.y = 95.0
		var button_height: float = 48.0
		var gap: float = 10.0
		var button_width: float = usable
		var top: float = height - 3.0 * button_height - 2.0 * gap - 22.0
		for button in [_subscribe_button, _restart_button, _later_button]:
			button.position = Vector2(inset, top)
			button.size = Vector2(button_width, button_height)
			top += button_height + gap
	else:
		var gap: float = 10.0
		var button_width: float = (usable - 2.0 * gap) / 3.0
		var button_height: float = 44.0 if height < 300.0 else 50.0
		var top: float = height - button_height - (14.0 if height < 300.0 else 23.0)
		_later_button.position = Vector2(inset, top)
		_restart_button.position = Vector2(inset + button_width + gap, top)
		_subscribe_button.position = Vector2(inset + 2.0 * (button_width + gap), top)
		for button in [_subscribe_button, _restart_button, _later_button]:
			button.size = Vector2(button_width, button_height)
	for button in [_subscribe_button, _restart_button, _later_button]:
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_theme_font_size_override("font_size", 14 if width >= 500.0 else 13)
