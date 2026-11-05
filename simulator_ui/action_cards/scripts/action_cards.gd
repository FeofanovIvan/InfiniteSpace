extends Control
## InfiniteSpace v99: integrated Action Cards simulator — 20 actions, EN.
## Source gameplay: user's MIKA_Action_Cards_Godot.zip (drag, tap, test, reveal).
## Shared animated flight sky, neon back arrow, crystal rewards and touch support.

const STAGE_SCRIPT = preload("res://simulator_ui/action_cards/scripts/action_stage.gd")
const SPACE_SCRIPT = preload("res://simulator_ui/scripts/real_space_background.gd")
const BACK_ARROW_SCRIPT = preload("res://simulator_ui/back_arrow_glyph.gd")
const CRYSTAL_TEXTURE: Texture2D = preload("res://planet_hub/assets/v68_neon/crystal_reference.png")
const DATA_PATH = "res://simulator_ui/action_cards/data/actions.json"
const SCREEN = Vector2(1280.0, 720.0)
const OPTIONS_COUNT = 5

const NAVY = Color("061226")
const PANEL_BLUE = Color("0B1D3B")
const CYAN = Color("78DFFF")
const MUTED = Color("A5CBE7")
const GOLD = Color("FFE09A")
const MINT = Color("87F4D0")

var actions: Array = []
var round_pool: Array = []
var rng := RandomNumberGenerator.new()
var round_number: int = 0
var correct_answers: int = 0
var current_action: Dictionary = {}
var candidate_actions: Array = []
var answer_solved: bool = false
var selected_index: int = -1
var drag_active: bool = false
var drag_index: int = -1
var drag_start: Vector2 = Vector2.ZERO
var drag_has_moved: bool = false
var drag_kind: String = ""
var drag_touch_id: int = -1
var session_crystals: int = 0
var _host_back: Control

var _sky: Control
var _back_button: Button
var _crystal_panel: Panel
var _crystal_icon: TextureRect
var _crystal_label: Label
var _score_panel: Panel
var _score_label: Label
var canvas: Control
var game_header: Label
var progress_label: Label
var stage_panel: Panel
var prompt_caption: Label
var prompt_word: Label
var stage_art
var target_panel: Panel
var question_label: Label
var win_sprite: TextureRect
var status_label: Label
var next_button: Button
var option_panels: Array = []
var option_images: Array = []
var ghost: TextureRect

func _ready() -> void:
	# The spaceflight is paused in the Miko simulator. This mini-game must continue.
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_load_data()
	_build_interface()
	resized.connect(_fit_to_viewport)
	_fit_to_viewport()
	_reset_deck()
	_start_next_round()
	call_deferred("_hide_shell_back")

func _load_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("Missing Action Cards data: " + DATA_PATH)
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Action Cards manifest must contain an array")
		return
	for record in parsed:
		if typeof(record) == TYPE_DICTIONARY:
			actions.append(record)

func _build_interface() -> void:
	# Reuse the real flight sky: original stars, plasma nebulae and flying meteors.
	# No artificial fixed stars from the old standalone demo.
	_sky = SPACE_SCRIPT.new() as Control
	_sky.name = "Sim08_RealFlightCosmos"
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky)
	canvas = Control.new()
	canvas.name = "DesignedForLandscape1280x720"
	canvas.size = SCREEN
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(canvas)

	# Same back-arrow glyph and session crystal badge used by other mini-games.
	_back_button = Button.new()
	_back_button.name = "ActionCardsNeonBack"
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.text = ""
	_back_button.position = Vector2(26, 18)
	_back_button.size = Vector2(66, 64)
	_back_button.add_theme_stylebox_override("normal", _style(Color("#061c38"), Color("#49d5f4"), 19, 3))
	_back_button.add_theme_stylebox_override("hover", _style(Color("#103859"), Color("#b8f1ff"), 19, 3))
	_back_button.add_theme_stylebox_override("pressed", _style(Color("#194267"), Color("#e5faff"), 19, 3))
	_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_back_button.pressed.connect(_return_to_simulator)
	canvas.add_child(_back_button)
	var arrow := Control.new()
	arrow.set_script(BACK_ARROW_SCRIPT)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.add_child(arrow)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_crystal_panel = Panel.new()
	_crystal_panel.name = "ActionCardsSessionCrystals"
	_crystal_panel.position = Vector2(108, 20)
	_crystal_panel.size = Vector2(150, 60)
	_crystal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crystal_panel.add_theme_stylebox_override("panel", _style(Color("#071c38"), Color("#45ccee"), 20, 2))
	canvas.add_child(_crystal_panel)
	_crystal_icon = TextureRect.new()
	_crystal_icon.name = "RealCrystalIcon"
	_crystal_icon.texture = CRYSTAL_TEXTURE
	_crystal_icon.position = Vector2(8, 8)
	_crystal_icon.size = Vector2(45, 45)
	_crystal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crystal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crystal_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crystal_panel.add_child(_crystal_icon)
	_crystal_label = _label("0", 29, Color.WHITE)
	_crystal_label.name = "CrystalsEarnedThisVisit"
	_crystal_label.position = Vector2(54, 5)
	_crystal_label.size = Vector2(85, 49)
	_crystal_panel.add_child(_crystal_label)

	_score_panel = Panel.new()
	_score_panel.name = "ActionCardsScoreTwenty"
	_score_panel.position = Vector2(272, 20)
	_score_panel.size = Vector2(164, 60)
	_score_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_panel.add_theme_stylebox_override("panel", _style(Color("#071c38"), Color("#45ccee"), 20, 2))
	canvas.add_child(_score_panel)
	_score_label = _label("✓  0 / 20", 23, Color("#e9faff"))
	_score_label.name = "CorrectInThisDeck"
	_score_label.position = Vector2(8, 5)
	_score_label.size = Vector2(148, 48)
	_score_panel.add_child(_score_label)

	game_header = _label("MIKA  /  ACTION LAB", 24, CYAN, HORIZONTAL_ALIGNMENT_LEFT)
	game_header.position = Vector2(465, 30)
	game_header.size = Vector2(500, 34)
	canvas.add_child(game_header)

	progress_label = _label("ROUND 01 / 20", 19, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	progress_label.position = Vector2(985, 32)
	progress_label.size = Vector2(250, 32)
	canvas.add_child(progress_label)

	stage_panel = Panel.new()
	stage_panel.name = "BigCentralActionCard"
	stage_panel.position = Vector2(260, 83)
	stage_panel.size = Vector2(760, 398)
	stage_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	stage_panel.add_theme_stylebox_override("panel", _style(Color(0.035, 0.094, 0.190, 0.88), Color("#56BAEC"), 26, 3))
	canvas.add_child(stage_panel)

	prompt_caption = _label("FIND THE ACTION", 19, MUTED)
	prompt_caption.position = Vector2(120, 21)
	prompt_caption.size = Vector2(520, 31)
	stage_panel.add_child(prompt_caption)

	prompt_word = _label("JUMP", 44, Color.WHITE)
	prompt_word.position = Vector2(60, 55)
	prompt_word.size = Vector2(640, 62)
	stage_panel.add_child(prompt_word)

	stage_art = STAGE_SCRIPT.new()
	stage_art.name = "StageSVGReveal"
	stage_art.position = Vector2(100, 232)
	stage_art.size = Vector2(560, 160)
	stage_panel.add_child(stage_art)

	target_panel = Panel.new()
	target_panel.name = "DropTarget"
	target_panel.position = Vector2(270, 142)
	target_panel.size = Vector2(220, 201)
	target_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	target_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	target_panel.add_theme_stylebox_override("panel", _style(Color(0.065, 0.180, 0.329, 0.94), Color("67C9EE"), 85, 3))
	target_panel.gui_input.connect(_on_target_input)
	stage_panel.add_child(target_panel)

	question_label = _label("?", 115, Color("C6F5FF"))
	question_label.position = Vector2(0, 14)
	question_label.size = Vector2(220, 145)
	question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_panel.add_child(question_label)

	win_sprite = TextureRect.new()
	win_sprite.name = "RevealedMika"
	win_sprite.position = Vector2(257, 129)
	win_sprite.size = Vector2(246, 250)
	win_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	win_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_sprite.pivot_offset = win_sprite.size * 0.5
	win_sprite.visible = false
	stage_panel.add_child(win_sprite)

	status_label = _label("Drag Mika from the bottom onto the question mark.", 20, MUTED)
	status_label.position = Vector2(125, 482)
	status_label.size = Vector2(1030, 32)
	canvas.add_child(status_label)

	next_button = _button("NEXT  →", GOLD)
	next_button.name = "NextRound"
	next_button.position = Vector2(1052, 268)
	next_button.size = Vector2(173, 58)
	next_button.visible = false
	next_button.pressed.connect(_next_pressed)
	canvas.add_child(next_button)

	for i in range(OPTIONS_COUNT):
		var tile := Panel.new()
		tile.name = "Option_%d" % (i + 1)
		tile.position = Vector2(74 + i * 232, 524)
		tile.size = Vector2(208, 174)
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.add_theme_stylebox_override("panel", _option_style(false))
		tile.gui_input.connect(_on_option_input.bind(i))
		canvas.add_child(tile)
		option_panels.append(tile)

		var pic := TextureRect.new()
		pic.name = "MikaActionArtwork"
		pic.position = Vector2(12, 5)
		pic.size = Vector2(184, 161)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(pic)
		option_images.append(pic)

	ghost = TextureRect.new()
	ghost.name = "DraggedMikaOnly"
	ghost.size = Vector2(196, 190)
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.visible = false
	canvas.add_child(ghost) # Always on top of other widgets.

func _label(text_value: String, font_size: int, tint: Color, horizontal := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = horizontal
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", tint)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style(bg: Color, outline: Color, radius: int, border_size: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = outline
	sb.set_border_width_all(border_size)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0.1, 0.7, 1.0, 0.13)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 3)
	return sb

func _option_style(is_selected: bool) -> StyleBoxFlat:
	if is_selected:
		return _style(Color("173E65"), GOLD, 23, 4)
	return _style(Color(0.035, 0.13, 0.27, 0.87), Color("4C8CB6"), 23, 2)

func _button(text_value: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 21)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _style(Color("#8e510c"), accent, 18, 3))
	btn.add_theme_stylebox_override("hover", _style(Color("#a76a17"), Color("#fff5d4"), 18, 3))
	btn.add_theme_stylebox_override("pressed", _style(Color("#694006"), Color("#ffe5ab"), 18, 3))
	return btn

func _fit_to_viewport() -> void:
	if canvas == null:
		return
	var view := size
	if view.x < 1.0 or view.y < 1.0:
		view = get_viewport_rect().size
	var factor := minf(view.x / SCREEN.x, view.y / SCREEN.y)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (view - SCREEN * factor) * 0.5
	_sky.position = Vector2.ZERO
	_sky.size = view

func _reset_deck() -> void:
	round_pool.clear()
	for action in actions:
		round_pool.append(action)
	round_pool.shuffle()
	round_number = 0
	correct_answers = 0

func _start_next_round() -> void:
	if actions.is_empty():
		status_label.text = "No action images found. Check data/actions.json."
		return
	if round_pool.is_empty():
		_reset_deck()
	current_action = round_pool.pop_back()
	round_number += 1
	answer_solved = false
	selected_index = -1
	drag_active = false
	ghost.visible = false
	win_sprite.visible = false
	win_sprite.scale = Vector2.ONE
	win_sprite.modulate = Color.WHITE
	target_panel.visible = true
	prompt_word.text = str(current_action.get("title", "")).to_upper()
	stage_art.set_stage(str(current_action.get("stage", "")))
	stage_art.reveal = 0.0
	status_label.text = "Drag Mika from the bottom onto the question mark."
	status_label.add_theme_color_override("font_color", MUTED)
	next_button.visible = false

	candidate_actions = _pick_five_choices(current_action)
	for i in range(OPTIONS_COUNT):
		option_images[i].texture = load(str(candidate_actions[i].get("image", ""))) as Texture2D
		option_images[i].modulate = Color.WHITE
		option_panels[i].modulate = Color.WHITE
		option_panels[i].add_theme_stylebox_override("panel", _option_style(false))
	progress_label.text = "ROUND %02d / %02d" % [round_number, actions.size()]
	_score_label.text = "✓  %d / %d" % [correct_answers, actions.size()]

func _pick_five_choices(right: Dictionary) -> Array:
	var choices: Array = [right]
	var distractors: Array = []
	for a in actions:
		if a.get("id", "") != right.get("id", ""):
			distractors.append(a)
	distractors.shuffle()
	# Keep very similar verbs apart on early rounds to avoid confusing younger learners.
	var confusing_pairs := {
		"walk": "run", "run": "walk", "lie_down": "sleep", "sleep": "lie_down",
		"eat": "bite", "bite": "eat", "draw": "write", "write": "draw",
		"throw": "catch", "catch": "throw"
	}
	var conflict := str(confusing_pairs.get(str(right.get("slug", "")), ""))
	for other in distractors:
		if choices.size() >= OPTIONS_COUNT:
			break
		if str(other.get("slug", "")) == conflict and round_number <= 10:
			continue
		choices.append(other)
	if choices.size() < OPTIONS_COUNT:
		for other in distractors:
			if choices.size() >= OPTIONS_COUNT:
				break
			if not choices.has(other):
				choices.append(other)
	choices.shuffle()
	return choices

func _option_point_to_canvas(index: int, local_point: Vector2) -> Vector2:
	# Convert the incoming GUI-local touch position into the scaled canvas.
	var viewport_point: Vector2 = option_panels[index].get_global_transform_with_canvas() * local_point
	return canvas.get_global_transform_with_canvas().affine_inverse() * viewport_point


func _viewport_point_to_canvas(viewport_point: Vector2) -> Vector2:
	return canvas.get_global_transform_with_canvas().affine_inverse() * viewport_point


func _on_option_input(event: InputEvent, index: int) -> void:
	if answer_solved or drag_active:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_begin_drag(index, _option_point_to_canvas(index, mouse.position), "mouse", -1)
			accept_event()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_begin_drag(index, _option_point_to_canvas(index, touch.position), "touch", touch.index)
			accept_event()


func _begin_drag(index: int, pointer_point: Vector2, kind: String, pointer_index: int) -> void:
	if drag_active:
		return
	selected_index = index
	drag_index = index
	drag_active = true
	drag_kind = kind
	drag_touch_id = pointer_index
	drag_has_moved = false
	drag_start = pointer_point
	ghost.texture = option_images[index].texture
	ghost.visible = true
	ghost.modulate = Color(1, 1, 1, 0.90)
	_move_ghost(drag_start)
	for i in range(OPTIONS_COUNT):
		option_panels[i].add_theme_stylebox_override("panel", _option_style(i == index))
	status_label.text = "Drop Mika onto the question mark!"


func _move_ghost(point: Vector2) -> void:
	ghost.position = point - ghost.size * 0.5 + Vector2(0, -25)
	var hover := _is_over_target(point)
	var accent := MINT if hover else CYAN
	target_panel.add_theme_stylebox_override("panel", _style(Color("102E54"), accent, 85, 4 if hover else 3))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5 and not answer_solved:
			selected_index = int(event.keycode) - int(KEY_1)
			for j in range(OPTIONS_COUNT):
				option_panels[j].add_theme_stylebox_override("panel", _option_style(j == selected_index))
			status_label.text = "Now press Enter or click the question mark."
		elif event.keycode == KEY_ENTER and selected_index >= 0 and not answer_solved:
			_check_answer(selected_index)
		elif event.keycode == KEY_SPACE and answer_solved:
			_next_pressed()
	if not drag_active:
		return
	if drag_kind == "mouse":
		if event is InputEventMouseMotion:
			var point: Vector2 = canvas.get_local_mouse_position()
			if point.distance_to(drag_start) > 10.0:
				drag_has_moved = true
			_move_ghost(point)
		elif event is InputEventMouseButton:
			var mouse: InputEventMouseButton = event
			if mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
				_finish_drag(canvas.get_local_mouse_position())
	elif drag_kind == "touch":
		if event is InputEventScreenDrag:
			var swipe: InputEventScreenDrag = event
			if swipe.index == drag_touch_id:
				var point: Vector2 = _viewport_point_to_canvas(swipe.position)
				if point.distance_to(drag_start) > 10.0:
					drag_has_moved = true
				_move_ghost(point)
		elif event is InputEventScreenTouch:
			var touch: InputEventScreenTouch = event
			if touch.index == drag_touch_id and not touch.pressed:
				_finish_drag(_viewport_point_to_canvas(touch.position))


func _finish_drag(point: Vector2) -> void:
	if not drag_active:
		return
	drag_active = false
	drag_kind = ""
	drag_touch_id = -1
	ghost.visible = false
	target_panel.add_theme_stylebox_override("panel", _style(Color("102E54"), Color("67C9EE"), 85, 3))
	if _is_over_target(point):
		_check_answer(drag_index)
	elif drag_has_moved:
		status_label.text = "Place Mika on the question mark. Try again!"
	else:
		status_label.text = "Selected! Now tap the question mark in the middle."


func _is_over_target(point: Vector2) -> bool:
	# Forgiving drop zone for young children: question mark and its surroundings.
	var region := Rect2(stage_panel.position + target_panel.position, target_panel.size)
	return region.grow(52.0).has_point(point)

func _on_target_input(event: InputEvent) -> void:
	if answer_solved or drag_active:
		return
	var clicked: bool = false
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		clicked = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		clicked = event.pressed
	if clicked:
		if selected_index >= 0:
			_check_answer(selected_index)
		else:
			status_label.text = "Pick one of the five Mikas below first."
		accept_event()

func _check_answer(index: int) -> void:
	if answer_solved or index < 0 or index >= candidate_actions.size():
		return
	var given: Dictionary = candidate_actions[index]
	if given.get("id", "") == current_action.get("id", ""):
		_finish_correct()
	else:
		status_label.text = "Not quite! Look closely and try another Mika."
		status_label.add_theme_color_override("font_color", GOLD)
		option_panels[index].add_theme_stylebox_override("panel", _style(Color("422743"), Color("FFA7BE"), 23, 3))
		selected_index = -1

func _finish_correct() -> void:
	answer_solved = true
	correct_answers += 1
	# Exactly one reward per correctly completed round; mistakes and mere picks earn zero.
	# The GameState signal also updates the flight crystal counter through MikoMainMenu.
	session_crystals += 1
	_crystal_label.text = str(session_crystals)
	_score_label.text = "✓  %d / %d" % [correct_answers, actions.size()]
	GameState.last_score = correct_answers
	GameState.add_coins(1)
	status_label.text = "GREAT JOB!  Mika can %s!" % str(current_action.get("title", "")).to_upper()
	status_label.add_theme_color_override("font_color", MINT)
	target_panel.visible = false
	win_sprite.texture = load(str(current_action.get("image", ""))) as Texture2D
	win_sprite.visible = true
	win_sprite.modulate = Color(1, 1, 1, 0)
	win_sprite.scale = Vector2(0.76, 0.76)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(stage_art, "reveal", 1.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(win_sprite, "modulate:a", 1.0, 0.38)
	tween.tween_property(win_sprite, "scale", Vector2.ONE, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	next_button.visible = true
	next_button.text = "PLAY AGAIN" if round_number >= actions.size() else "NEXT  →"
	for i in range(OPTIONS_COUNT):
		option_panels[i].modulate = Color(1,1,1,1) if i == selected_index else Color(1,1,1,0.50)

func _next_pressed() -> void:
	if not answer_solved:
		return
	if round_number >= actions.size():
		_reset_deck()
	_start_next_round()

func _hide_shell_back() -> void:
	# This scene runs inside MikoMainMenu's SubViewport: hide the host arrow,
	# so only this game's neon arrow remains. Restore it on leaving.
	var vp: Node = get_parent()
	if vp != null and vp.get_parent() != null and vp.get_parent().get_parent() != null:
		var runner: Node = vp.get_parent().get_parent()
		_host_back = runner.get_node_or_null("ReturnToEducationalCards") as Control
	if is_instance_valid(_host_back):
		_host_back.visible = false


func _exit_tree() -> void:
	if is_instance_valid(_host_back):
		_host_back.visible = true


func _return_to_simulator() -> void:
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null and portal.has_method("handle_scene_transition"):
		portal.call("handle_scene_transition", "res://education/playtown/scenes/screens/game_select_playground.tscn")
	else:
		push_error("Action Cards: missing PlayTownPortal; cannot exit embedded simulator")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_return_to_simulator()
		get_viewport().set_input_as_handled()
