extends Control
## InfiniteSpace v101 Where Is It? Embedded Godot 4.7.1 3D cube with original flight sky.
## No external images, 3D model files or add-ons are required.

const CUBE_WORLD = preload("res://simulator_ui/where_is_it/scripts/cube_world.gd")
const FLIGHT_SPACE = preload("res://simulator_ui/scripts/real_space_background.gd")
const BACK_ARROW = preload("res://simulator_ui/back_arrow_glyph.gd")
const CRYSTAL_TEXTURE: Texture2D = preload("res://planet_hub/assets/v68_neon/crystal_reference.png")
const PREPOSITIONS_DATA: String = "res://simulator_ui/where_is_it/data/prepositions.json"
const DESIGN_SIZE = Vector2(1280, 720)
const ACTIVE_COLOR = Color("72d4ff")
const OK_COLOR = Color("88ffd0")
const ROUNDS_TOTAL = 2

var content: Dictionary = {}
var languages: Array = []
var rounds: Array = []
var language_index := 0
var round_index := 0
var score := 0
var active_keys: Array = []
var solved: Dictionary = {}
var chips: Dictionary = {}
var slots: Dictionary = {}
var selected_key := ""
var drag_key := ""
var drag_start := Vector2.ZERO
var drag_proxy: Label
var orbit_active := false
var last_orbit_pos := Vector2.ZERO
var stage: Control
var cube_world: Node3D
var viewport_box: SubViewportContainer
var view: SubViewport
var lang_picker: OptionButton
var heading: Label
var subtitle: Label
var round_label: Label
var score_label: Label
var feedback: Label
var instructions: Label
var front_hint: Label
var helper: Label
var next_button: Button
var reset_view_button: Button
var prev_view_button: Button
var next_view_button: Button
var chip_strip: Control
var rng := RandomNumberGenerator.new()
var _real_space: Control
var _back_button: Button
var _crystal_panel: Panel
var _crystal_amount: Label
var _session_crystals: int = 0
var _shell_back: Control
var _drag_input_kind: String = ""
var _touch_pointer: int = -1
var _orbit_input_kind: String = ""

func _ready() -> void:
	# The simulator suspends flight: keep this 3D teaching scene responsive.
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_load_content()
	_sync_language_from_game()
	_real_space = FLIGHT_SPACE.new() as Control
	_real_space.name = "Sim09_OriginalFlightStarsNebulaeMeteors"
	_real_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_real_space.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_real_space)
	_build_stage()
	_fit_stage()
	get_viewport().size_changed.connect(_fit_stage)
	_start_new_game()
	call_deferred("_hide_shell_back")
	set_process(true)

func _sync_language_from_game() -> void:
	var locale: String = str(MobileLocale.language) if has_node("/root/MobileLocale") else "en"
	if locale == "pt_BR":
		locale = "pt"
	for i in range(languages.size()):
		if str(languages[i].get("code", "")) == locale:
			language_index = i
			return

func _load_content() -> void:
	var json_text := FileAccess.get_file_as_string(PREPOSITIONS_DATA)
	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("The prepositions JSON is missing or invalid")
		return
	content = parsed
	languages = content.get("languages", [])
	rounds = content.get("rounds", [])

func _ui(key: String) -> String:
	if languages.is_empty():
		return key
	var ui: Dictionary = languages[language_index].get("ui", {})
	return str(ui.get(key, key))

func _word(key: String) -> String:
	if languages.is_empty():
		return key.to_upper()
	var words: Dictionary = languages[language_index].get("words", {})
	return str(words.get(key, key.to_upper()))

func _build_stage() -> void:
	stage = Control.new()
	stage.name = "ResponsiveDesignSurface"
	stage.size = DESIGN_SIZE
	stage.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(stage)
	
	# Same tablet frame as the rest of InfiniteSpace; stars remain visible behind.
	_panel(Rect2(22, 16, 1236, 100), Color(0.038, 0.10, 0.21, 0.91), Color("56d5f5"), 22)
	_build_back_and_crystals()
	heading = _label("", Vector2(278, 28), Vector2(600, 44), 30, Color("f5fbff"))	
	subtitle = _label("", Vector2(280, 75), Vector2(590, 24), 16, Color("9fd5f6"))
	lang_picker = OptionButton.new()
	lang_picker.name = "LanguagePicker"
	lang_picker.position = Vector2(886, 43)
	lang_picker.size = Vector2(214, 46)
	lang_picker.add_theme_font_size_override("font_size", 18)
	lang_picker.add_theme_color_override("font_color", Color("eaf7ff"))
	_apply_button_style(lang_picker, Color("153c66"))
	stage.add_child(lang_picker)
	for i in range(languages.size()):
		lang_picker.add_item(str(languages[i].get("name", "?")), i)
	lang_picker.item_selected.connect(_on_language_selected)
	var reset_game_button := _button("↺", Rect2(1116, 43, 112, 46), Color("213d5d"))
	reset_game_button.name = "RestartAll"
	reset_game_button.pressed.connect(_start_new_game)
	reset_game_button.tooltip_text = "Restart both rounds"
	
	# Middle scene and left/right information rails.
	_panel(Rect2(22, 131, 1236, 427), Color(0.029, 0.078, 0.16, 0.86), Color("54bce8"), 25)
	_panel(Rect2(35, 145, 215, 399), Color(0.055, 0.145, 0.26, 0.91), Color("3d86b7"), 19)
	_panel(Rect2(1030, 145, 214, 399), Color(0.055, 0.145, 0.26, 0.91), Color("3d86b7"), 19)
	round_label = _label("", Vector2(51, 166), Vector2(180, 30), 20, Color("78d7ff"))
	score_label = _label("", Vector2(51, 208), Vector2(180, 33), 25, Color("eafaff"))
	instructions = _label("", Vector2(51, 261), Vector2(179, 120), 18, Color("d5eafa"))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback = _label("", Vector2(51, 396), Vector2(183, 112), 18, Color("9cefd4"))
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	viewport_box = SubViewportContainer.new()
	viewport_box.name = "Rotatable3DCube"
	viewport_box.position = Vector2(266, 148)
	viewport_box.size = Vector2(750, 395)
	viewport_box.stretch = true
	viewport_box.mouse_filter = Control.MOUSE_FILTER_STOP
	viewport_box.gui_input.connect(_on_scene_gui_input)
	stage.add_child(viewport_box)
	view = SubViewport.new()
	view.name = "Cube3DViewport"
	view.size = Vector2i(750, 395)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_box.add_child(view)
	cube_world = CUBE_WORLD.new()
	cube_world.name = "ProceduralCubeWorld"
	view.add_child(cube_world)
	
	var rotate_head := _label("", Vector2(1049, 170), Vector2(180, 55), 17, Color("9ddfff"))
	rotate_head.name = "RotateHeading"
	rotate_head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var rotate_description := _label("", Vector2(1049, 228), Vector2(180, 75), 15, Color("b9d5ed"))
	rotate_description.name = "RotateDescription"
	rotate_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prev_view_button = _button("↶", Rect2(1049, 321, 74, 53), Color("21547b"))
	next_view_button = _button("↷", Rect2(1140, 321, 74, 53), Color("21547b"))
	prev_view_button.pressed.connect(func(): cube_world.rotate_view(deg_to_rad(-25), 0.0))
	next_view_button.pressed.connect(func(): cube_world.rotate_view(deg_to_rad(25), 0.0))
	reset_view_button = _button("", Rect2(1049, 385, 177, 42), Color("20425f"))
	reset_view_button.name = "ResetView"
	reset_view_button.pressed.connect(func(): cube_world.reset_view())
	front_hint = _label("", Vector2(1049, 444), Vector2(175, 84), 14, Color("ffdc96"))
	front_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	chip_strip = Control.new()
	chip_strip.name = "WordsTray"
	chip_strip.position = Vector2(22, 572)
	chip_strip.size = Vector2(1236, 108)
	stage.add_child(chip_strip)
	var tray := Panel.new()
	tray.position = Vector2.ZERO
	tray.size = Vector2(1236, 108)
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_theme_stylebox_override("panel", _style(Color(0.06, 0.16, 0.28, 0.94), Color("53c6ef"), 22))
	chip_strip.add_child(tray)
	helper = _label("", Vector2(30, 688), Vector2(1220, 24), 13, Color("86b6d6"))
	
	# Each target is a 2D button projected from a specific fixed 3D point.
	for key in CUBE_WORLD.ANCHORS.keys():
		var marker := Button.new()
		marker.name = "Anchor_" + key
		marker.text = "?"
		marker.focus_mode = Control.FOCUS_NONE
		marker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		marker.size = Vector2(52, 48)
		marker.add_theme_font_size_override("font_size", 24)
		marker.add_theme_color_override("font_color", Color("eaf9ff"))
		_apply_button_style(marker, Color("15324d"), CUBE_WORLD.PALETTE[key])
		marker.pressed.connect(_on_target_clicked.bind(key))
		stage.add_child(marker)
		slots[key] = marker
	
	next_button = _button("", Rect2(971, 685, 250, 30), Color("2a695f"))
	next_button.name = "NextRoundButton"
	next_button.visible = false
	next_button.add_theme_font_size_override("font_size", 15)
	next_button.pressed.connect(_advance_round)

func _build_back_and_crystals() -> void:
	_back_button = _button("", Rect2(33, 34, 64, 63), Color("071c38"))
	_back_button.name = "Sim09_OnlyNeonBack"
	_back_button.tooltip_text = "Назад / Back"
	_apply_button_style(_back_button, Color("071c38"), Color("49d5f4"))
	_back_button.pressed.connect(_exit_to_simulator)
	var arrow := Control.new()
	arrow.set_script(BACK_ARROW)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.add_child(arrow)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_crystal_panel = Panel.new()
	_crystal_panel.name = "Sim09SessionCrystals"
	_crystal_panel.position = Vector2(110, 35)
	_crystal_panel.size = Vector2(154, 60)
	_crystal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crystal_panel.add_theme_stylebox_override("panel", _style(Color("071c38"), Color("4bc6eb"), 20))
	stage.add_child(_crystal_panel)
	var icon := TextureRect.new()
	icon.name = "OriginalCrystal"
	icon.texture = CRYSTAL_TEXTURE
	icon.position = Vector2(8, 8)
	icon.size = Vector2(45, 45)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crystal_panel.add_child(icon)
	_crystal_amount = Label.new()
	_crystal_amount.name = "CrystalsEarnedThisVisit"
	_crystal_amount.text = "0"
	_crystal_amount.position = Vector2(58, 3)
	_crystal_amount.size = Vector2(86, 54)
	_crystal_amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crystal_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_crystal_amount.add_theme_font_size_override("font_size", 28)
	_crystal_amount.add_theme_color_override("font_color", Color.WHITE)
	_crystal_amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crystal_panel.add_child(_crystal_amount)

func _style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.20)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	return sb

func _panel(rect: Rect2, bg: Color, border: Color, radius: int) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(bg, border, radius))
	stage.add_child(p)
	return p

func _label(t: String, at: Vector2, dimensions: Vector2, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.position = at
	l.size = dimensions
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(l)
	return l

func _button(t: String, rect: Rect2, bg: Color) -> Button:
	var b := Button.new()
	b.text = t
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 24)
	_apply_button_style(b, bg, Color("82cbff"))
	stage.add_child(b)
	return b

func _apply_button_style(b: Control, bg: Color, outline: Color = Color("82cbff")) -> void:
	b.add_theme_stylebox_override("normal", _style(bg, outline, 16))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.16), outline.lightened(0.15), 16))
	b.add_theme_stylebox_override("pressed", _style(bg.darkened(0.18), outline, 16))
	b.add_theme_stylebox_override("disabled", _style(bg.darkened(0.36), outline.darkened(0.43), 16))

func _fit_stage() -> void:
	if stage == null:
		return
	var available := get_viewport_rect().size
	if _real_space != null:
		_real_space.position = Vector2.ZERO
		_real_space.size = available
	var factor := minf(available.x / DESIGN_SIZE.x, available.y / DESIGN_SIZE.y)
	stage.scale = Vector2.ONE * factor
	stage.position = (available - DESIGN_SIZE * factor) * 0.5
	queue_redraw()

func _on_language_selected(index: int) -> void:
	language_index = index
	_start_new_game()

func _update_language() -> void:
	heading.text = "MIKA  /  " + _ui("title")
	subtitle.text = _ui("subtitle")
	(stage.get_node("RotateHeading") as Label).text = _ui("rotate")
	(stage.get_node("RotateDescription") as Label).text = _ui("rotate_hint")
	reset_view_button.text = _ui("reset_view")
	front_hint.text = "▲  " + _ui("front_hint")
	helper.text = _ui("tutorial")
	instructions.text = _ui("instructions")
	next_button.text = _ui("next") if round_index < ROUNDS_TOTAL - 1 else _ui("restart")
	lang_picker.select(language_index)
	_update_score()

func _update_score() -> void:
	score_label.text = "%s  %d / 9" % [_ui("score"), score]
	round_label.text = "%s  %d / %d" % [_ui("round"), round_index + 1, ROUNDS_TOTAL]

func _start_new_game() -> void:
	score = 0
	round_index = 0
	cube_world.reset_view()
	_begin_round()

func _begin_round() -> void:
	selected_key = ""
	drag_key = ""
	_drag_input_kind = ""
	_touch_pointer = -1
	_remove_proxy()
	cube_world.clear_figures()
	solved.clear()
	active_keys.clear()
	if not rounds.is_empty():
		var rd: Dictionary = rounds[round_index]
		active_keys = rd.get("keys", []).duplicate()
	for key in slots.keys():
		var b: Button = slots[key]
		b.visible = active_keys.has(key)
		b.disabled = false
		b.text = "?"
		b.size = Vector2(52, 48)
		b.add_theme_font_size_override("font_size", 25)
		_apply_button_style(b, Color("163047"), CUBE_WORLD.PALETTE[key])
	for key in active_keys:
		solved[key] = false
	_clear_chips()
	_spawn_chips()
	next_button.visible = false
	feedback.text = _ui("pick_hint")
	_update_language()
	_update_slot_positions()

func _clear_chips() -> void:
	for node in chips.values():
		node.queue_free()
	chips.clear()

func _spawn_chips() -> void:
	var shuffled := active_keys.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = temp
	var count := shuffled.size()
	var margin := 16.0
	var gap := 17.0
	var width := minf(221.0, (chip_strip.size.x - 40.0 - float(count - 1) * gap) / float(maxi(1, count)))
	var total := float(count) * width + float(count - 1) * gap
	var start := (chip_strip.size.x - total) * 0.5
	for i in range(count):
		var key: String = str(shuffled[i])
		var b := Button.new()
		b.name = "Word_" + key
		b.text = _word(key)
		b.position = Vector2(start + float(i) * (width + gap), 18)
		b.size = Vector2(width, 72)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var font_size := 20 if b.text.length() <= 12 else (17 if b.text.length() <= 17 else 15)
		b.add_theme_font_size_override("font_size", font_size)
		b.add_theme_color_override("font_color", Color("09182b"))
		_apply_button_style(b, CUBE_WORLD.PALETTE[key], Color.WHITE)
		b.gui_input.connect(_on_chip_gui_input.bind(key))
		chip_strip.add_child(b)
		chips[key] = b

func _on_chip_gui_input(event: InputEvent, key: String) -> void:
	if solved.get(key, false) or drag_key != "":
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_drag_input_kind = "mouse"
			_begin_chip_press(key, _pointer_in_stage(event.global_position))
	elif event is InputEventScreenTouch:
		if event.pressed:
			_drag_input_kind = "touch"
			_touch_pointer = event.index
			# GUI input coordinates for touch are relative to the word button.
			var button: Button = chips[key]
			var viewport_point: Vector2 = button.get_global_transform_with_canvas() * event.position
			_begin_chip_press(key, _pointer_in_stage(viewport_point))

func _pointer_in_stage(screen_point: Vector2) -> Vector2:
	return (screen_point - stage.position) / stage.scale.x

func _begin_chip_press(key: String, point: Vector2) -> void:
	orbit_active = false
	drag_key = key
	drag_start = point
	selected_key = key
	_refresh_chips()

func _refresh_chips() -> void:
	for key in chips.keys():
		var b: Button = chips[key]
		if not b.visible:
			continue
		var col: Color = CUBE_WORLD.PALETTE[key]
		if selected_key == key:
			_apply_button_style(b, col.lightened(0.16), Color("fff8d5"))
		else:
			_apply_button_style(b, col, Color.WHITE)

func _input(event: InputEvent) -> void:
	if drag_key == "":
		return
	if _drag_input_kind == "mouse":
		if event is InputEventMouseMotion:
			_drag_move(_pointer_in_stage(event.position))
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_chip_press(_pointer_in_stage(event.position))
	elif _drag_input_kind == "touch":
		if event is InputEventScreenDrag and event.index == _touch_pointer:
			_drag_move(_pointer_in_stage(event.position))
		elif event is InputEventScreenTouch and event.index == _touch_pointer and not event.pressed:
			_end_chip_press(_pointer_in_stage(event.position))
			_touch_pointer = -1

func _drag_move(point: Vector2) -> void:
	if drag_proxy == null and point.distance_to(drag_start) > 12.0:
		_create_proxy(drag_key)
	if drag_proxy != null:
		drag_proxy.position = point - drag_proxy.size * 0.5

func _create_proxy(key: String) -> void:
	drag_proxy = Label.new()
	drag_proxy.name = "DraggedWordOnly"
	drag_proxy.text = _word(key)
	drag_proxy.size = Vector2(177, 59)
	drag_proxy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drag_proxy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_proxy.add_theme_color_override("font_color", Color("04172a"))
	drag_proxy.add_theme_font_size_override("font_size", 20 if drag_proxy.text.length() < 14 else 16)
	drag_proxy.add_theme_stylebox_override("normal", _style(CUBE_WORLD.PALETTE[key], Color.WHITE, 18))
	drag_proxy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_proxy.z_index = 100
	stage.add_child(drag_proxy)

func _remove_proxy() -> void:
	if drag_proxy != null:
		drag_proxy.queue_free()
		drag_proxy = null

func _end_chip_press(point: Vector2) -> void:
	var key := drag_key
	drag_key = ""
	_drag_input_kind = ""
	var was_dragging := drag_proxy != null
	_remove_proxy()
	if not was_dragging:
		feedback.text = _ui("tap_hint")
		return
	var destination := ""
	var best_distance := 1.0e10
	for target_key in active_keys:
		if solved.get(target_key, false):
			continue
		var button: Button = slots[target_key]
		var rect := Rect2(button.position, button.size)
		var center := rect.get_center()
		var distance := center.distance_to(point)
		if rect.grow(20).has_point(point) and distance < best_distance:
			best_distance = distance
			destination = target_key
	if destination != "":
		_try_place(key, destination)
	else:
		feedback.text = _ui("tap_hint")

func _on_target_clicked(key: String) -> void:
	if selected_key == "":
		feedback.text = _ui("pick_hint")
		return
	_try_place(selected_key, key)

func _try_place(key: String, destination: String) -> void:
	if solved.get(destination, false):
		return
	if key != destination:
		feedback.text = _ui("wrong")
		feedback.add_theme_color_override("font_color", Color("ffc48c"))
		return
	solved[key] = true
	score += 1
	# Reward is granted only once for this key in the current round.
	_session_crystals += 1
	_crystal_amount.text = str(_session_crystals)
	GameState.add_coins(1)
	cube_world.reveal(key)
	var slot: Button = slots[key]
	slot.text = _word(key)
	slot.size = Vector2(minf(170.0, maxf(90.0, float(slot.text.length() * 10 + 22))), 42)
	slot.add_theme_font_size_override("font_size", 15 if slot.text.length() > 14 else 18)
	_apply_button_style(slot, CUBE_WORLD.PALETTE[key].darkened(0.25), Color("e8faff"))
	slot.disabled = true
	chips[key].visible = false
	selected_key = ""
	_refresh_chips()
	feedback.text = _ui("correct")
	feedback.add_theme_color_override("font_color", OK_COLOR)
	_update_score()
	if _all_solved():
		feedback.text = _ui("done") if round_index == ROUNDS_TOTAL - 1 else _ui("correct")
		next_button.text = _ui("restart") if round_index == ROUNDS_TOTAL - 1 else _ui("next")
		next_button.visible = true

func _all_solved() -> bool:
	for key in active_keys:
		if not solved.get(key, false):
			return false
	return true

func _advance_round() -> void:
	if round_index < ROUNDS_TOTAL - 1:
		round_index += 1
		_begin_round()
	else:
		_start_new_game()

func _on_scene_gui_input(event: InputEvent) -> void:
	if drag_key != "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		orbit_active = event.pressed
		_orbit_input_kind = "mouse" if event.pressed else ""
		last_orbit_pos = event.position
	elif event is InputEventMouseMotion and orbit_active and _orbit_input_kind == "mouse":
		var delta: Vector2 = event.position - last_orbit_pos
		last_orbit_pos = event.position
		cube_world.rotate_view(-delta.x * 0.008, delta.y * 0.006)
	elif event is InputEventScreenTouch:
		orbit_active = event.pressed
		_orbit_input_kind = "touch" if event.pressed else ""
		last_orbit_pos = event.position
	elif event is InputEventScreenDrag and orbit_active and _orbit_input_kind == "touch":
		var delta: Vector2 = event.position - last_orbit_pos
		last_orbit_pos = event.position
		cube_world.rotate_view(-delta.x * 0.008, delta.y * 0.006)

func _process(_delta: float) -> void:
	if cube_world != null and slots.size() > 0:
		_update_slot_positions()

func _update_slot_positions() -> void:
	for key in active_keys:
		var b: Button = slots[key]
		if cube_world.is_anchor_behind_camera(key):
			b.visible = false
			continue
		b.visible = true
		var scene_pos: Vector2 = cube_world.project_key(key)
		var scaled_projected := Vector2(scene_pos.x, scene_pos.y)
		b.position = viewport_box.position + scaled_projected - b.size * 0.5
		# Keep targets away from outside control rails if camera goes too far.
		b.position.x = clampf(b.position.x, 267.0, 1013.0 - b.size.x)
		b.position.y = clampf(b.position.y, 153.0, 538.0 - b.size.y)

func _hide_shell_back() -> void:
	# The mini-game is placed directly under a SubViewport from MikoMainMenu.
	var vp: Node = get_parent()
	if vp != null and vp.get_parent() != null and vp.get_parent().get_parent() != null:
		var runner: Node = vp.get_parent().get_parent()
		_shell_back = runner.get_node_or_null("ReturnToEducationalCards") as Control
	if is_instance_valid(_shell_back):
		_shell_back.hide()

func _exit_tree() -> void:
	if is_instance_valid(_shell_back):
		_shell_back.show()

func _exit_to_simulator() -> void:
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null and portal.has_method("handle_scene_transition"):
		portal.call("handle_scene_transition", "res://education/playtown/scenes/screens/game_select_school.tscn")
	else:
		push_error("Where Is It: PlayTownPortal not available for returning to the simulator")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_exit_to_simulator()
		get_viewport().set_input_as_handled()
