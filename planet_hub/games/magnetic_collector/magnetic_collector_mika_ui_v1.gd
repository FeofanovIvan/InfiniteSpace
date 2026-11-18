extends "res://planet_hub/games/magnetic_collector/MagneticCollector.gd"
## MIKA Magnetic Collector v1.2 — scene and simulator are separate viewports.
## All visible controls belong to this scene and use ONE DESIGN transform.
## Only the central crystal capsule of the original BottomHUD is displayed.

const MIKA_SHARED_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_CRYSTAL_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_FLIGHT_JOYSTICK = preload("res://scripts/Joystick.gd")
const MIKA_BACK_GLYPH = preload("res://simulator_ui/back_arrow_glyph.gd")

const MIKA_BOARD = Rect2(29.0, 121.0, 1222.0, 580.0)
const MIKA_HEADER_Y := 19.0
const MIKA_HEADER_HEIGHT := 82.0
const MIKA_HEADER_GAP := 14.0
const MIKA_COUNTER_NATIVE_HEIGHT := 158.0
const MIKA_COUNTER_NATIVE_WIDTH := 394.0
const MIKA_COUNTER_NATIVE_LEFT := 643.0
const MIKA_LEFT_STICK_CENTER = Vector2(171.0, 604.0)
const MIKA_RIGHT_STICK_CENTER = Vector2(1103.0, 604.0)

var _mika_header: Panel
var _mika_main_title: Label
var _mika_subtitle: Label
var _mika_counter_clip: Control
var _mika_crystal_counter: Control
var _mika_scene_back: Button
var _mika_left_stick: Control
var _mika_right_stick: Control
var _mika_host_back: Button
var _mika_host_back_was_visible := true


func _ready() -> void:
	super._ready()
	_mika_build_header()
	_mika_build_flight_sticks()
	_mika_hide_legacy_controls()
	_style_button(_grab_button, Color("10375a"), Color("65e7ff"))
	_grab_button.add_theme_font_size_override("font_size", 24)
	_mika_find_host_back()
	_layout_ui()
	_apply_translation()
	_refresh_ui()


func _mika_build_header() -> void:
	# This is the ONE visible back button; host back is hidden, but remains
	# connected to the host's native return-to-cards callback.
	_mika_scene_back = Button.new()
	_mika_scene_back.name = "MikaTopBarBack"
	_mika_scene_back.text = ""
	_mika_scene_back.focus_mode = Control.FOCUS_NONE
	_mika_scene_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_mika_scene_back.z_index = 20
	var base := StyleBoxFlat.new()
	base.bg_color = Color("061c38")
	base.border_color = Color("26dfff")
	base.set_border_width_all(2)
	base.set_corner_radius_all(18)
	base.shadow_color = Color(0.04, 0.64, 1.0, 0.47)
	base.shadow_size = 6
	_mika_scene_back.add_theme_stylebox_override("normal", base)
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = Color("113a60")
	_mika_scene_back.add_theme_stylebox_override("hover", hover)
	_mika_scene_back.add_theme_stylebox_override("pressed", hover)
	_mika_scene_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(_mika_scene_back)
	var glyph := MIKA_BACK_GLYPH.new() as Control
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_scene_back.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mika_scene_back.pressed.connect(_mika_return_from_game)

	_mika_header = Panel.new()
	_mika_header.name = "MikaNativeTitlePanel"
	_mika_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_header.z_index = 20
	MIKA_SHARED_TOOLBAR.apply_title_style(_mika_header)
	add_child(_mika_header)

	_mika_main_title = Label.new()
	_mika_main_title.name = "MagneticCollectorGameTitle"
	_mika_main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mika_main_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mika_main_title.clip_text = true
	_mika_main_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_main_title.add_theme_color_override("font_color", Color.WHITE)
	_mika_main_title.add_theme_color_override("font_outline_color", Color("09233e"))
	_mika_main_title.add_theme_constant_override("outline_size", 3)
	_mika_header.add_child(_mika_main_title)

	_mika_subtitle = Label.new()
	_mika_subtitle.name = "MagneticCollectorSubtitle"
	_mika_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mika_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mika_subtitle.clip_text = true
	_mika_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_subtitle.add_theme_color_override("font_color", Color("b6e8ff"))
	_mika_header.add_child(_mika_subtitle)

	# The original BottomHUD has 1680px canvas, including Simulator/Launch
	# wings. Its only wanted part is x=643..1037; a clipping parent isolates it.
	_mika_counter_clip = Control.new()
	_mika_counter_clip.name = "MikaClippedCrystalCapsule"
	_mika_counter_clip.clip_contents = true
	_mika_counter_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_counter_clip.z_index = 20
	add_child(_mika_counter_clip)
	_mika_crystal_counter = MIKA_CRYSTAL_HUD.new() as Control
	_mika_crystal_counter.name = "MagneticCollectorEarnedCrystalCounter"
	_mika_crystal_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_counter_clip.add_child(_mika_crystal_counter)
	# Defensive second layer: hide the native wings and their interactive
	# buttons entirely, even on renderers with differing clip behavior.
	for wing_name in ["sim_button", "flight_button"]:
		var wing: Control = _mika_crystal_counter.get(wing_name) as Control
		if wing != null:
			wing.hide()
			wing.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _mika_build_flight_sticks() -> void:
	_mika_left_stick = MIKA_FLIGHT_JOYSTICK.new() as Control
	_mika_left_stick.name = "MikaHorizontalFlightJoystick"
	_mika_left_stick.z_index = 9
	add_child(_mika_left_stick)
	_mika_left_stick.direction_changed.connect(_mika_on_left_direction)

	_mika_right_stick = MIKA_FLIGHT_JOYSTICK.new() as Control
	_mika_right_stick.name = "MikaVerticalFlightJoystick"
	_mika_right_stick.z_index = 9
	add_child(_mika_right_stick)
	_mika_right_stick.direction_changed.connect(_mika_on_right_direction)


func _mika_on_left_direction(direction: Vector2) -> void:
	_left_axis = direction.x


func _mika_on_right_direction(direction: Vector2) -> void:
	_right_axis = direction.y


func _mika_find_host_back() -> void:
	var viewport_holder: Node = get_viewport().get_parent()
	if viewport_holder == null:
		return
	var game_layer: Node = viewport_holder.get_parent()
	if game_layer == null:
		return
	var node: Node = game_layer.get_node_or_null("ReturnToEducationalCards")
	if node == null:
		node = game_layer.get_node_or_null("ReturnToExistingPlanetCards")
	if node is Button:
		_mika_host_back = node as Button
		_mika_host_back_was_visible = _mika_host_back.visible
		_mika_host_back.hide()


func _mika_return_from_game() -> void:
	if is_instance_valid(_mika_host_back):
		# The host button retains its signal wiring and is not moved, copied or
		# reparented between the two Viewports.
		_mika_host_back.pressed.emit()
	else:
		# Standalone scene used for development: Close the standalone run.
		get_tree().quit()


func _exit_tree() -> void:
	if is_instance_valid(_mika_host_back):
		_mika_host_back.visible = _mika_host_back_was_visible


func _mika_hide_legacy_controls() -> void:
	# Preserve the base game's state machinery but remove duplicate UI.
	for old_control in [_title, _subtitle, _score_label, _level_label,
		_language_picker, _restart_button, _hint_button, _pause_button,
		_instruction_label, _left_help, _right_help, _footer]:
		if is_instance_valid(old_control):
			old_control.hide()


func _layout_ui() -> void:
	super._layout_ui()
	if _mika_header == null or _mika_counter_clip == null or _mika_left_stick == null:
		return
	# The frame, Back, title, counter, and joysticks share the exact same
	# DESIGN -> viewport transform. No mixed host/SubViewport coordinates.
	var s: float = _scale_factor
	var left: float = MIKA_BOARD.position.x
	var right: float = MIKA_BOARD.end.x
	var top: float = MIKA_HEADER_Y
	var h: float = MIKA_HEADER_HEIGHT
	var back_side: float = h
	var counter_width: float = MIKA_COUNTER_NATIVE_WIDTH * h / MIKA_COUNTER_NATIVE_HEIGHT
	var counter_x: float = right - counter_width
	var title_x: float = left + back_side + MIKA_HEADER_GAP
	var title_width: float = counter_x - MIKA_HEADER_GAP - title_x
	_mika_scene_back.position = _origin + Vector2(left, top) * s
	_mika_scene_back.size = Vector2.ONE * h * s
	_mika_header.position = _origin + Vector2(title_x, top) * s
	_mika_header.size = Vector2(title_width, h) * s
	_mika_main_title.position = Vector2(9.0, 4.0) * s
	_mika_main_title.size = Vector2(title_width - 18.0, 49.0) * s
	var title_font := maxi(18, roundi(34.0 * s))
	_mika_main_title.add_theme_font_size_override("font_size", title_font)
	_mika_subtitle.position = Vector2(9.0, 54.0) * s
	_mika_subtitle.size = Vector2(title_width - 18.0, 22.0) * s
	_mika_subtitle.add_theme_font_size_override("font_size", maxi(11, roundi(16.0 * s)))
	_mika_subtitle.visible = title_width >= 300.0
	_mika_counter_clip.position = _origin + Vector2(counter_x, top) * s
	_mika_counter_clip.size = Vector2(counter_width, h) * s
	_mika_crystal_counter.size = Vector2(1680.0, MIKA_COUNTER_NATIVE_HEIGHT)
	var hud_scale: float = (h * s) / MIKA_COUNTER_NATIVE_HEIGHT
	_mika_crystal_counter.scale = Vector2.ONE * hud_scale
	_mika_crystal_counter.position = Vector2(-MIKA_COUNTER_NATIVE_LEFT * hud_scale, 0.0)
	# Preserve the 184x184 input area from the actual flight Joystick.gd.
	_mika_left_stick.scale = Vector2.ONE * s
	_mika_left_stick.position = _origin + (MIKA_LEFT_STICK_CENTER - Vector2(92.0, 92.0)) * s
	_mika_right_stick.scale = Vector2.ONE * s
	_mika_right_stick.position = _origin + (MIKA_RIGHT_STICK_CENTER - Vector2(92.0, 92.0)) * s
	_place(_grab_button, Rect2(516.0, 598.0, 248.0, 72.0))
	_grab_button.z_index = 10
	_place(_feedback, Rect2(335.0, 550.0, 859.0, 33.0))
	_place(_bay_label, Rect2(96.0, 366.0, 219.0, 33.0))
	_place(_bay_hint, Rect2(94.0, 403.0, 226.0, 25.0))
	_place(_progress_label, Rect2(92.0, 488.0, 235.0, 24.0))
	queue_redraw()


func _apply_translation() -> void:
	super._apply_translation()
	if _mika_main_title != null:
		_mika_main_title.text = _title.text
		_mika_subtitle.text = _subtitle.text


func _refresh_ui() -> void:
	super._refresh_ui()
	if _mika_crystal_counter != null:
		_mika_crystal_counter.set("crystal_count", _score)


func _start_level() -> void:
	super._start_level()
	if _mika_left_stick != null:
		_mika_left_stick.call("clear_input")
	if _mika_right_stick != null:
		_mika_right_stick.call("clear_input")


func _input(event: InputEvent) -> void:
	# The flight joystick instances already handle independent multitouch.
	# Do not process touches a second time in the old hand-drawn controller.
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_magnet()
				get_viewport().set_input_as_handled()
			KEY_H:
				_show_hint()
			KEY_P:
				_toggle_pause()
			KEY_R:
				_new_game()


func _draw_joysticks() -> void:
	# Rendered and driven by two instances of the real flight Joystick.gd.
	pass


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN), Color("061428"))
	for i in range(64):
		var px := fmod(float(i * 139 + 21), DESIGN.x)
		var py := fmod(float(i * 79 + 47), DESIGN.y)
		draw_circle(Vector2(px, py), 0.85 + float(i % 3) * 0.25, Color(0.68, 0.86, 1.0, 0.15))
	_panel(MIKA_BOARD, Color("0b1e35"), Color("65e7ff"), 29, 3)
	# Small bottom control strip INSIDE the large stage, not a second frame.
	draw_rect(Rect2(34.0, 588.0, 1212.0, 104.0), Color(0.05, 0.16, 0.29, 0.24))
	for i in range(12):
		var x := 48.0 + 103.0 * float(i)
		draw_line(Vector2(x, 579.0), Vector2(x + 24.0, 579.0), Color(0.38, 0.81, 1.0, 0.18), 2.0)
