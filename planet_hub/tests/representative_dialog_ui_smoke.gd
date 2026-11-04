extends SceneTree
## godot --headless --path . --script res://planet_hub/tests/representative_dialog_ui_smoke.gd
## Tests the actual reusable scene, the two-column layout, and a typed conversation.
const Dialog = preload("res://planet_hub/scenes/representative_dialog.tscn")
const SAVE_PATH := "user://miko_dialogue_progress.json"
var errors: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, why: String) -> void:
	if ok:
		print("PASS: ", why)
	else:
		errors += 1
		push_error("FAIL: " + why)

func _run() -> void:
	var saved: bool = FileAccess.file_exists(SAVE_PATH)
	var original: String = FileAccess.get_file_as_string(SAVE_PATH) if saved else ""
	var dialog: Control = Dialog.instantiate() as Control
	root.add_child(dialog)
	dialog.size = Vector2(1280, 720)
	await process_frame
	dialog.call("configure_for_planet", "m31_p03", "Фазис", "", "")
	await process_frame
	var tablet: Control = dialog.get_node("TranslatorTablet")
	var dock: PanelContainer = dialog.get_node("LeftQuestionChoices")
	var character: Control = dialog.get_node("RepresentativeCharacter")
	var text_input: LineEdit = tablet.get_node("FreeTextEntry")
	var buttons: Array = [
		dock.get_node("ChoicesLayout/QuestionOption_0"),
		dock.get_node("ChoicesLayout/QuestionOption_1"),
		dock.get_node("ChoicesLayout/QuestionOption_2")
	]
	_check(dock.visible, "three floating choices visible above character")
	_check(buttons.all(func(button: Button) -> bool: return button.visible), "three buttons visible at greeting")
	_check(dock.position.x + dock.size.x <= tablet.position.x, "choices remain left of right tablet")
	_check(dock.position.y < character.position.y, "floating choices appear above the portrait")
	_check(dock.get_theme_stylebox("panel") is StyleBoxEmpty, "no opaque box surrounding clouds")
	_check(not dock.get_node("ChoicesLayout/ChoiceInstruction").visible, "no instruction banner above character")
	_check(buttons.all(func(button: Button) -> bool: return button.get_script() != null), "each cloud has native vector-drawn style")
	_check(tablet.get_node_or_null("ThreeSuggestedPhrases") == null, "old suggestions removed from chat tablet")
	_check(tablet.get_node_or_null("SuggestedAnswer") == null, "no duplicate top hint in tablet")
	var original_hint: String = str(tablet.call("_sample_answer"))
	buttons[2].emit_signal("pressed")
	_check(int(tablet.call("get_selected_suggestion")) == 2, "third left option selects one typing hint")
	_check(str(tablet.call("_sample_answer")) == str(buttons[2].call("get_phrase")), "typing hint matches selected option")
	_check(original_hint != str(tablet.call("_sample_answer")), "switching choices changes hint")
	# Enter an alternative known greeting, not the selected text.
	tablet.set("_typing_seconds", 0.0)
	text_input.text = str(buttons[0].call("get_phrase"))
	tablet.call("_on_send")
	var engine: RefCounted = tablet.get("_engine")
	_check(str(engine.get("stage")) == "choose", "alternate greeting accepted and dialogue advances")
	_check(buttons.all(func(button: Button) -> bool: return button.visible), "next three questions update on left")
	var phrase: String = "Tell me about this world."
	# Game language is RU by default; choose the Russian alternative from stored localization.
	var locale: String = str(tablet.call("get_language"))
	if locale == "ru":
		phrase = "Расскажи об этом мире."
	tablet.set("_typing_seconds", 0.0)
	text_input.text = phrase
	tablet.call("_on_send")
	_check(str(engine.get("stage")) in ["choose", "personal", "story"], "question recognized and response computed")
	# Verify a second representative reuses the panel without duplicating buttons.
	dialog.call("configure_for_planet", "m33_p01", "Светара", "", "")
	_check(dock.get_node("ChoicesLayout").get_child_count() == 4, "buttons are not duplicated between worlds")
	_check(tablet.call("get_suggestions").size() == 3, "fresh world resets three hints")
	dialog.queue_free()
	await process_frame
	if saved:
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(original)
			file.close()
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Representative UI smoke: ", "PASS" if errors == 0 else str(errors) + " errors")
	quit(0 if errors == 0 else 1)
