extends "res://education/playtown/src/features/school/mika_build_word_native_v1.gd"
## MIKA Build a Word 2.0: simple 2D Control based input, no Area2D picking.
## All glyphs are native Godot labels and neon StyleBoxFlat cards.
## Mouse and touch handled in the game scene itself, even under SubViewport.

const TILE_CONTROL_V2: Script = preload("res://education/playtown/src/features/school/mika_word_tile_control_v2.gd")
const SLOT_CONTROL_V2: Script = preload("res://education/playtown/src/features/school/mika_word_slot_control_v2.gd")

var _active_tile_v2: Control
var _selected_tile_v2: Control
var _active_pointer_v2: int = -1 # -1 none, -2 mouse, >=0 touch index
var _grab_delta_v2: Vector2 = Vector2.ZERO
var _press_point_v2: Vector2 = Vector2.ZERO
var _dragged_far_v2: bool = false
var _drop_threshold_v2: float = 10.0

func _ready() -> void:
	_active_pointer_v2 = -1
	_active_tile_v2 = null
	_selected_tile_v2 = null
	super._ready()

func _create_slots() -> void:
	_clear_selection_v2()
	for previous in slots_root.get_children():
		slots_root.remove_child(previous)
		previous.queue_free()
	slot_nodes.clear()
	for i in range(current_word.length()):
		var slot: Control = SLOT_CONTROL_V2.new()
		slot.name = "WordSlot_%02d" % i
		slot.set("index", i)
		slot.set("expected_letter", current_word[i])
		slots_root.add_child(slot)
		slot.call("setup", current_word[i])
		slot_nodes.append(slot)

func _create_letter_choices() -> void:
	_clear_selection_v2()
	for previous in letters_root.get_children():
		letters_root.remove_child(previous)
		previous.queue_free()
	letter_items.clear()
	var choices: Array[String] = []
	for i in range(current_word.length()):
		choices.append(current_word[i])
	var alphabet: Array[String] = LanguageService.get_alphabet()
	if alphabet.is_empty():
		alphabet = ["A", "B", "C", "D", "E", "F", "G", "H"]
	var wanted: int = maxi(8, current_word.length() + 2)
	var tries: int = 0
	while choices.size() < wanted and tries < 300:
		tries += 1
		var suggestion: String = alphabet[rng.randi_range(0, alphabet.size() - 1)]
		if not choices.has(suggestion):
			choices.append(suggestion)
	choices.shuffle()
	for i in range(choices.size()):
		var tile: Control = TILE_CONTROL_V2.new()
		tile.name = "NativeLetterTile_%02d" % i
		letters_root.add_child(tile)
		tile.call("configure_letter", choices[i], LanguageService.get_letter_voice(choices[i]))
		letter_items.append(tile)

func _unhandled_input(_event: InputEvent) -> void:
	# Explicitly disable the v1.0.2 Area2D physics fallback: all inputs are
	# handled by the game root in _input() below. This prevents double captures.
	pass

func _input(event: InputEvent) -> void:
	if game_over or waiting_next_word:
		return
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_on_pointer_down_v2(event.position, -2)
		else:
			_on_pointer_up_v2(event.position, -2)
	elif event is InputEventMouseMotion:
		if _active_pointer_v2 == -2:
			_on_pointer_move_v2(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_pointer_down_v2(event.position, event.index)
		else:
			_on_pointer_up_v2(event.position, event.index)
	elif event is InputEventScreenDrag:
		if _active_pointer_v2 == event.index:
			_on_pointer_move_v2(event.position)

func _on_pointer_down_v2(point: Vector2, pointer_id: int) -> void:
	if _active_pointer_v2 != -1:
		return
	var tile: Control = _tile_at_v2(point)
	if tile == null:
		if _selected_tile_v2 != null:
			var slot: Control = _slot_at_v2(point)
			if slot != null:
				var selected: Control = _selected_tile_v2
				_clear_selection_v2()
				_drop_tile_v2(selected, slot)
				get_viewport().set_input_as_handled()
			return
		return
	if _selected_tile_v2 != null and _selected_tile_v2 != tile:
		_selected_tile_v2.call("set_selected", false)
	_selected_tile_v2 = null
	_active_tile_v2 = tile
	_active_pointer_v2 = pointer_id
	_press_point_v2 = point
	_dragged_far_v2 = false
	_grab_delta_v2 = tile.call("centre") - point
	tile.move_to_front()
	tile.call("begin_drag")
	get_viewport().set_input_as_handled()

func _on_pointer_move_v2(point: Vector2) -> void:
	if _active_tile_v2 == null or not is_instance_valid(_active_tile_v2):
		return
	if _press_point_v2.distance_to(point) > _drop_threshold_v2:
		_dragged_far_v2 = true
	_active_tile_v2.call("move_centre_to", point + _grab_delta_v2)
	get_viewport().set_input_as_handled()

func _on_pointer_up_v2(point: Vector2, pointer_id: int) -> void:
	if _active_pointer_v2 != pointer_id or _active_tile_v2 == null:
		return
	var tile: Control = _active_tile_v2
	var moved: bool = _dragged_far_v2 or _press_point_v2.distance_to(point) > _drop_threshold_v2
	_active_tile_v2 = null
	_active_pointer_v2 = -1
	tile.call("finish_drag")
	var target: Control = _slot_at_v2(point)
	if target == null and moved:
		target = _slot_at_v2(tile.call("centre"))
	if target != null:
		_clear_selection_v2()
		_drop_tile_v2(tile, target)
	elif moved:
		tile.call("reset_to_start")
	else:
		# Friendly alternative for small screens: tap the letter, then the slot.
		tile.call("reset_to_start")
		tile.call("set_selected", true)
		_selected_tile_v2 = tile
	get_viewport().set_input_as_handled()

func _tile_at_v2(point: Vector2) -> Control:
	for i in range(letter_items.size() - 1, -1, -1):
		var tile: Control = letter_items[i] as Control
		if tile != null and is_instance_valid(tile) and tile.visible and tile.call("contains_screen_point", point):
			return tile
	return null

func _slot_at_v2(point: Vector2) -> Control:
	var nearest: Control
	var distance: float = INF
	for item in slot_nodes:
		var slot: Control = item as Control
		if slot == null or not is_instance_valid(slot):
			continue
		if slot.call("contains_screen_point", point):
			var delta: Vector2 = slot.global_position - point
			var d: float = delta.length_squared()
			if d < distance:
				distance = d
				nearest = slot
	return nearest

func _drop_tile_v2(tile: Control, slot: Control) -> void:
	if tile == null or slot == null:
		return
	_on_letter_dropped_on_slot(tile, slot)

func _on_letter_dropped_wrong(item) -> void:
	if item == null or not is_instance_valid(item):
		return
	if not game_over and not waiting_next_word:
		_show_error()
	item.call("reset_to_start")

func _clear_selection_v2() -> void:
	if _active_tile_v2 != null and is_instance_valid(_active_tile_v2):
		_active_tile_v2.call("reset_to_start")
	if _selected_tile_v2 != null and is_instance_valid(_selected_tile_v2):
		_selected_tile_v2.call("set_selected", false)
	_active_tile_v2 = null
	_selected_tile_v2 = null
	_active_pointer_v2 = -1
	_dragged_far_v2 = false
