extends "res://education/playtown/src/features/school/mika_build_word_control_v2.gd"
## MIKA Build a Word v3: bright extruded free-standing letters, not square cards.
## Completed letters stay physically inside the word slots as the same nodes.

const GLYPH_TILE_V3: Script = preload("res://education/playtown/src/features/school/mika_word_glyph_v3.gd")

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
		var tile: Control = GLYPH_TILE_V3.new()
		tile.name = "ExtrudedLetter_%02d" % i
		letters_root.add_child(tile)
		tile.call("configure_letter", choices[i], LanguageService.get_letter_voice(choices[i]))
		letter_items.append(tile)

func _on_letter_dropped_on_slot(item, slot) -> void:
	if item == null or slot == null or not is_instance_valid(item) or not is_instance_valid(slot):
		return
	# Use v2's already-tested slot validation, scoring and original audio.
	var placed_before: int = letters_placed
	super._on_letter_dropped_on_slot(item, slot)
	if letters_placed <= placed_before or not is_instance_valid(item) or not is_instance_valid(slot):
		return
	# The parent calls slot.place_letter() and then hides the dragged tile.
	# Replace the placeholder with that actual colored 3D glyph in the slot.
	var placeholder: Label = slot.get("placed_label") as Label
	if placeholder != null:
		placeholder.hide()
	var hint: Label = slot.get("hint_label") as Label
	if hint != null:
		hint.hide()
	item.call("lock_into_slot", slot)
