extends SceneTree
## Run inside the complete Godot project:
## godot --headless --path . --script res://planet_hub/tests/story_page_two_panels_smoke.gd

const PANELS_SCRIPT: Script = preload("res://mika_motion_comic/scripts/story_page_two_panels.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var viewer: Control = PANELS_SCRIPT.new() as Control
	root.add_child(viewer)
	await process_frame
	viewer.size = Vector2(1280, 720)
	var completed: Array[int] = [0]
	viewer.sequence_completed.connect(func() -> void: completed[0] += 1)
	viewer.begin_sequence(["wormhole"])
	_assert(viewer.current_panel_id() == "wormhole", "wormhole still")
	viewer.advance_panel()
	_assert(completed[0] == 1 and not viewer.visible, "first event")
	viewer.begin_sequence(["earth_view", "simulator"])
	_assert(viewer.current_panel_id() == "earth_view", "Earth view")
	viewer.advance_panel()
	_assert(viewer.current_panel_id() == "simulator", "helmet/simulator view")
	viewer.advance_panel()
	_assert(completed[0] == 2, "return to game cue")
	viewer.begin_sequence(["earth_descent", "earth_arrival"])
	viewer.advance_panel()
	_assert(viewer.current_panel_id() == "earth_arrival", "arrival frame held")
	viewer.advance_panel()
	_assert(completed[0] == 3, "landing sequence finished")
	print("MIKA_STORY_PAGE_TWO_SMOKE_PASS")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MIKA_STORY_PAGE_TWO_SMOKE_FAIL: " + message)
	quit(1)
