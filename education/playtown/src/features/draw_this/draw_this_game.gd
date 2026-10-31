extends Node2D

const ICONS: Array[Texture2D] = [
	preload("res://education/playtown/assets/draw_this/bee.webp"),
	preload("res://education/playtown/assets/draw_this/snail_complete.webp"),
	preload("res://education/playtown/assets/draw_this/butterfly.webp"),
	preload("res://education/playtown/assets/draw_this/beetle.webp"),
	preload("res://education/playtown/assets/draw_this/cloud.webp"),
]
const PENCILS: Array[Texture2D] = [
	preload("res://education/playtown/assets/draw_this/pencils/01_red.webp"),
	preload("res://education/playtown/assets/draw_this/pencils/02_orange.webp"),
	preload("res://education/playtown/assets/draw_this/pencils/03_yellow.webp"),
	preload("res://education/playtown/assets/draw_this/pencils/04_green.webp"),
	preload("res://education/playtown/assets/draw_this/pencils/05_cyan.webp"),
	preload("res://education/playtown/assets/draw_this/pencils/06_blue.webp"),
	preload("res://education/playtown/assets/draw_this/pencils/07_purple.webp"),
]
const COLORS: Array[Color] = [
	Color("#ed3b45"), Color("#f28c28"), Color("#f1c62a"), Color("#4aaa45"),
	Color("#24b9c9"), Color("#168fd0"), Color("#9754c8"),
]
const TRACE_ACTIONS := [2, 3, 4, 1, 5]

var background: ColorRect
var outer_panel: Panel
var sidebar: Panel
var canvas_panel: Panel
var canvas: DrawThisCanvas
var exercise_buttons: Array[Button] = []
var exit_button: GameExitButton
var color_button: Button
var palette_icon: DrawPaletteIcon
var eraser_button: Button
var eraser_icon: DrawToolIcon
var clear_button: Button
var clear_icon: DrawToolIcon
var palette_panel: Panel
var pencil_buttons: Array[TextureButton] = []
var selected_exercise := 0
var voice_player: AudioStreamPlayer


func _ready() -> void:
	background = ColorRect.new()
	background.color = Color("#bfeadd")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	outer_panel = Panel.new()
	outer_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff3ca"), Color("#e7b84e"), 4, 28, true))
	add_child(outer_panel)

	sidebar = Panel.new()
	sidebar.add_theme_stylebox_override("panel", _panel_style(Color("#f8f0ce"), Color("#e6ba59"), 3, 22, true))
	outer_panel.add_child(sidebar)
	for index in range(ICONS.size()):
		var button := Button.new()
		button.text = ""
		button.icon = ICONS[index]
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_select_exercise.bind(index))
		sidebar.add_child(button)
		exercise_buttons.append(button)

	exit_button = GameExitButton.new()
	exit_button.pressed.connect(_exit_game)
	sidebar.add_child(exit_button)

	canvas_panel = Panel.new()
	canvas_panel.clip_contents = true
	canvas_panel.add_theme_stylebox_override("panel", _panel_style(Color.WHITE, Color("#ebb74d"), 3, 24, true))
	outer_panel.add_child(canvas_panel)
	canvas = DrawThisCanvas.new()
	canvas_panel.add_child(canvas)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)

	color_button = Button.new()
	color_button.text = ""
	color_button.focus_mode = Control.FOCUS_NONE
	color_button.add_theme_stylebox_override("normal", _panel_style(Color("#fff6d8"), Color("#d89b35"), 3, 18, true))
	color_button.add_theme_stylebox_override("hover", _panel_style(Color("#ffffff"), Color("#e8a93e"), 3, 18, true))
	color_button.add_theme_stylebox_override("pressed", _panel_style(Color("#f1dfa7"), Color("#c98224"), 3, 18, false))
	color_button.pressed.connect(_toggle_palette)
	color_button.z_index = 30
	outer_panel.add_child(color_button)
	palette_icon = DrawPaletteIcon.new()
	palette_icon.z_index = 31
	color_button.add_child(palette_icon)

	eraser_button = _make_tool_button()
	eraser_button.pressed.connect(_toggle_eraser)
	outer_panel.add_child(eraser_button)
	eraser_icon = DrawToolIcon.new()
	eraser_icon.tool = DrawToolIcon.Tool.ERASER
	eraser_button.add_child(eraser_icon)

	clear_button = _make_tool_button()
	clear_button.pressed.connect(_clear_drawing)
	outer_panel.add_child(clear_button)
	clear_icon = DrawToolIcon.new()
	clear_icon.tool = DrawToolIcon.Tool.CLEAR
	clear_button.add_child(clear_icon)

	palette_panel = Panel.new()
	palette_panel.visible = false
	palette_panel.z_index = 29
	palette_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff8df"), Color("#dfa33d"), 3, 18, true))
	outer_panel.add_child(palette_panel)
	for index in range(PENCILS.size()):
		var pencil := TextureButton.new()
		pencil.texture_normal = PENCILS[index]
		pencil.ignore_texture_size = true
		pencil.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pencil.focus_mode = Control.FOCUS_NONE
		pencil.pressed.connect(_choose_color.bind(index))
		palette_panel.add_child(pencil)
		pencil_buttons.append(pencil)

	get_viewport().size_changed.connect(_layout)
	_apply_exercise_styles()
	_apply_tool_styles()
	_layout()
	call_deferred("_play_current_instruction")


func _select_exercise(index: int) -> void:
	selected_exercise = index
	canvas.set_exercise(index)
	palette_panel.visible = false
	_apply_exercise_styles()
	_play_current_instruction()


func _toggle_palette() -> void:
	palette_panel.visible = not palette_panel.visible


func _choose_color(index: int) -> void:
	canvas.set_draw_color(COLORS[index])
	palette_icon.set_selected_color(COLORS[index])
	palette_panel.visible = false
	_apply_tool_styles()
	_play_voice(LanguageService.get_color_voice(index))


func _toggle_eraser() -> void:
	canvas.set_eraser_enabled(not canvas.eraser_enabled)
	palette_panel.visible = false
	_apply_tool_styles()


func _clear_drawing() -> void:
	canvas.clear_drawing()
	palette_panel.visible = false


func _make_tool_button() -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.z_index = 30
	return button


func _apply_tool_styles() -> void:
	var eraser_fill := Color("#ffd0dc") if canvas.eraser_enabled else Color("#fff6d8")
	var eraser_border := Color("#e55b7b") if canvas.eraser_enabled else Color("#d89b35")
	eraser_button.add_theme_stylebox_override("normal", _panel_style(eraser_fill, eraser_border, 3, 18, true))
	eraser_button.add_theme_stylebox_override("hover", _panel_style(eraser_fill.lightened(0.06), eraser_border, 3, 18, true))
	eraser_button.add_theme_stylebox_override("pressed", _panel_style(eraser_fill.darkened(0.07), eraser_border, 3, 18, false))
	clear_button.add_theme_stylebox_override("normal", _panel_style(Color("#fff6d8"), Color("#d89b35"), 3, 18, true))
	clear_button.add_theme_stylebox_override("hover", _panel_style(Color("#ffffff"), Color("#e8a93e"), 3, 18, true))
	clear_button.add_theme_stylebox_override("pressed", _panel_style(Color("#f1dfa7"), Color("#c98224"), 3, 18, false))


func _play_current_instruction() -> void:
	_play_voice(LanguageService.get_trace_action_voice(TRACE_ACTIONS[selected_exercise]))


func _play_voice(stream: AudioStream) -> void:
	if stream == null:
		return
	voice_player.stop()
	voice_player.stream = stream
	voice_player.play()


func _apply_exercise_styles() -> void:
	for index in range(exercise_buttons.size()):
		var selected := index == selected_exercise
		var fill := Color("#d9f5a8") if selected else Color("#fff8dc")
		var border := Color("#65b931") if selected else Color("#efc35e")
		var button := exercise_buttons[index]
		button.add_theme_stylebox_override("normal", _panel_style(fill, border, 3, 16, true))
		button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.08), border, 3, 16, true))
		button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.08), border, 3, 16, false))


func _layout() -> void:
	var view := get_viewport_rect().size
	var safe := _safe_area_insets(view)
	background.position = Vector2.ZERO
	background.size = view
	var margin := clampf(minf(view.x, view.y) * 0.018, 6.0, 18.0)
	outer_panel.position = Vector2(safe.x + margin, safe.y + margin)
	outer_panel.size = Vector2(view.x - safe.x - safe.z - margin * 2.0, view.y - safe.y - safe.w - margin * 2.0)
	var inner := clampf(outer_panel.size.y * 0.022, 7.0, 18.0)
	var side_width := clampf(outer_panel.size.x * 0.135, 88.0, 170.0)
	sidebar.position = Vector2(inner, inner)
	sidebar.size = Vector2(side_width, outer_panel.size.y - inner * 2.0)
	canvas_panel.position = Vector2(sidebar.position.x + sidebar.size.x + inner, inner)
	canvas_panel.size = Vector2(outer_panel.size.x - canvas_panel.position.x - inner, outer_panel.size.y - inner * 2.0)
	var canvas_inset := clampf(canvas_panel.size.y * 0.012, 3.0, 9.0)
	canvas.position = Vector2.ONE * canvas_inset
	canvas.size = canvas_panel.size - Vector2.ONE * canvas_inset * 2.0

	var side_pad := clampf(side_width * 0.11, 7.0, 16.0)
	var available_h := sidebar.size.y - side_pad * 3.0
	var exit_h := clampf(sidebar.size.y * 0.14, 48.0, 100.0)
	var gap := clampf(sidebar.size.y * 0.012, 3.0, 10.0)
	var exercise_h := minf(side_width - side_pad * 2.0, (available_h - exit_h - gap * 5.0) / 5.0)
	for index in range(exercise_buttons.size()):
		var button := exercise_buttons[index]
		button.position = Vector2(side_pad, side_pad + float(index) * (exercise_h + gap))
		button.size = Vector2(side_width - side_pad * 2.0, exercise_h)
	exit_button.position = Vector2(side_pad, sidebar.size.y - exit_h - side_pad)
	exit_button.size = Vector2(side_width - side_pad * 2.0, exit_h)

	var color_size := clampf(canvas_panel.size.y * 0.13, 52.0, 88.0)
	color_button.size = Vector2.ONE * color_size
	color_button.position = canvas_panel.position + canvas_panel.size - Vector2.ONE * (color_size + 16.0)
	palette_icon.position = Vector2.ONE * color_size * 0.08
	palette_icon.size = Vector2.ONE * color_size * 0.84
	var tool_gap := clampf(color_size * 0.13, 6.0, 11.0)
	eraser_button.size = Vector2.ONE * color_size
	eraser_button.position = color_button.position - Vector2(0.0, color_size + tool_gap)
	eraser_icon.position = Vector2.ONE * color_size * 0.10
	eraser_icon.size = Vector2.ONE * color_size * 0.80
	clear_button.size = Vector2.ONE * color_size
	clear_button.position = eraser_button.position - Vector2(0.0, color_size + tool_gap)
	clear_icon.position = Vector2.ONE * color_size * 0.10
	clear_icon.size = Vector2.ONE * color_size * 0.80

	var pencil_h := clampf(color_size * 1.08, 54.0, 94.0)
	var pencil_w := pencil_h * 0.58
	var palette_pad := 9.0
	palette_panel.size = Vector2(pencil_w * float(pencil_buttons.size()) + palette_pad * float(pencil_buttons.size() + 1), pencil_h + palette_pad * 2.0)
	palette_panel.position = Vector2(color_button.position.x - palette_panel.size.x - 10.0, color_button.position.y + color_button.size.y - palette_panel.size.y)
	palette_panel.position.x = maxf(canvas_panel.position.x + 10.0, palette_panel.position.x)
	for index in range(pencil_buttons.size()):
		pencil_buttons[index].position = Vector2(palette_pad + float(index) * (pencil_w + palette_pad), palette_pad)
		pencil_buttons[index].size = Vector2(pencil_w, pencil_h)


func _exit_game() -> void:
	PlayTownPortal.change_scene_to_file("res://education/playtown/scenes/screens/game_select_school.tscn")


func _panel_style(fill: Color, border: Color, border_width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	if shadow:
		style.shadow_color = Color(0.25, 0.17, 0.08, 0.18)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _safe_area_insets(viewport_size: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_viewport := viewport_size / window_size
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	return Vector4(
		clampf(float(safe_rect.position.x) * scale_to_viewport.x, 0.0, viewport_size.x * 0.2),
		clampf(float(safe_rect.position.y) * scale_to_viewport.y, 0.0, viewport_size.y * 0.2),
		clampf(right_px * scale_to_viewport.x, 0.0, viewport_size.x * 0.2),
		clampf(bottom_px * scale_to_viewport.y, 0.0, viewport_size.y * 0.2)
	)
