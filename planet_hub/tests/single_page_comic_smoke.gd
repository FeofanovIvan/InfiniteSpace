extends SceneTree

const INTRO_SCENE: PackedScene = preload("res://mika_motion_comic/scenes/SinglePageComicIntro.tscn")

func _initialize() -> void:
	var intro := INTRO_SCENE.instantiate()
	intro.set("autoplay", false)
	root.add_child(intro)
	await process_frame
	_assert(intro.get_duration() == 71.0, "unexpected prologue duration")
	_assert(intro.caption_cues.size() >= 14, "localized cue timeline was not loaded")
	var previous := Vector3(-1.0, -1.0, -1.0)
	for timestamp in [0.0, 10.0, 18.0, 28.0, 39.0, 50.0, 59.0, 66.0, 71.0]:
		intro.seek(timestamp)
		var state: Vector3 = intro.get_camera_state()
		_assert(state.x >= 0.0 and state.x <= 1.0, "camera x is outside the page")
		_assert(state.y >= 0.0 and state.y <= 1.0, "camera y is outside the page")
		_assert(state.z >= 0.08 and state.z <= 1.0, "invalid page crop")
		if previous.x >= 0.0:
			_assert(state.distance_to(previous) > 0.005, "camera did not advance between story beats")
		previous = state
	intro.queue_free()
	print("SINGLE_PAGE_COMIC_SMOKE_PASS")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SINGLE_PAGE_COMIC_SMOKE_FAIL: " + message)
	quit(1)
