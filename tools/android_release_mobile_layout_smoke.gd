extends SceneTree
## Representative Android layout checks at phone, wide-phone, and tablet ratios.

const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1200, 540), Vector2i(960, 720)]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("ANDROID_LAYOUT_FAIL: " + message)


func _wait_frames(count: int = 3) -> void:
	for _frame in range(count):
		await process_frame


func _run() -> void:
	await _test_settings()
	await _test_purchase_gate()
	await _test_simulator()
	await _test_bubble()
	await _test_racing()
	print("Android release mobile layout smoke: ", "PASS" if _failures == 0 else "%d FAILED" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_settings() -> void:
	var script := load("res://scripts/SettingsLanguagePopup.gd") as Script
	_check(script != null, "settings layout compiles")
	if script == null:
		return
	var settings := script.new() as Control
	root.add_child(settings)
	await _wait_frames()
	for viewport_size in SIZES:
		root.size = viewport_size
		await _wait_frames()
		var logical_size := root.get_visible_rect().size
		settings.size = logical_size
		settings.call("_layout")
		await _wait_frames()
		var panel := settings.get("_panel") as Control
		_check(_inside_view(panel.get_global_rect(), logical_size), "settings fit %s" % _size_label(viewport_size, logical_size))
		var slider := settings.get("_volume_slider") as Control
		_check(_inside_view(slider.get_global_rect(), logical_size), "volume control fits %s" % _size_label(viewport_size, logical_size))
	root.remove_child(settings)
	settings.free()
	await _wait_frames()


func _test_purchase_gate() -> void:
	var script := load("res://learning/src/screens/subscription_overlay.gd") as Script
	_check(script != null, "purchase gate layout compiles")
	if script == null:
		return
	var overlay := script.new() as CanvasLayer
	overlay.call("set_locked", true)
	overlay.call("set_show_expiration_notice", true)
	root.add_child(overlay)
	await _wait_frames()
	for viewport_size in SIZES:
		root.size = viewport_size
		await _wait_frames()
		var logical_size := root.get_visible_rect().size
		overlay.call("_layout")
		await _wait_frames()
		var card := overlay.get("card") as Control
		_check(_inside_view(card.get_global_rect(), logical_size), "purchase card fits %s" % _size_label(viewport_size, logical_size))
		_check((overlay.get("scroll") as ScrollContainer).vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO,
			"purchase content remains scrollable at %s" % _size_label(viewport_size, logical_size))
	root.remove_child(overlay)
	overlay.free()
	await _wait_frames()


func _test_simulator() -> void:
	var script := load("res://tools/test_doubles/mvp_menu_free_world_test_double.gd") as Script
	_check(script != null, "simulator layout compiles")
	if script == null:
		return
	var menu := script.new() as Control
	root.add_child(menu)
	await _wait_frames()
	for viewport_size in SIZES:
		root.size = viewport_size
		await _wait_frames()
		var logical_size := root.get_visible_rect().size
		menu.size = logical_size
		menu.call("_reflow")
		await _wait_frames()
		var gallery := menu.get("_gallery") as Control
		var more := menu.get("_mika_more_button") as Control
		_check(_inside_view(gallery.get_global_rect(), logical_size), "simulator gallery fits %s" % _size_label(viewport_size, logical_size))
		_check(_inside_view(more.get_global_rect(), logical_size), "more-games touch target fits %s" % _size_label(viewport_size, logical_size))
	root.remove_child(menu)
	menu.free()
	await _wait_frames()


func _test_bubble() -> void:
	var scene := load("res://bubble/scenes/care_room_actions_camera.tscn") as PackedScene
	_check(scene != null, "Bubble Care layout scene loads")
	if scene == null:
		return
	var bubble := scene.instantiate()
	root.add_child(bubble)
	await _wait_frames(5)
	for viewport_size in SIZES:
		root.size = viewport_size
		await _wait_frames()
		var logical_size := root.get_visible_rect().size
		bubble.call("_layout")
		await _wait_frames()
		var joystick := bubble.get("_joystick") as Control
		var action := bubble.get("_context_use_action") as Control
		_check(_inside_view(joystick.get_global_rect(), logical_size), "Bubble joystick fits %s" % _size_label(viewport_size, logical_size))
		_check(_inside_view(action.get_global_rect(), logical_size), "Bubble action control fits %s" % _size_label(viewport_size, logical_size))
	root.remove_child(bubble)
	bubble.free()
	await _wait_frames()


func _test_racing() -> void:
	var scene := load("res://space_racing/SpaceRace.tscn") as PackedScene
	_check(scene != null, "Space Racing layout scene loads")
	if scene == null:
		return
	var race := scene.instantiate()
	root.add_child(race)
	await _wait_frames(5)
	for viewport_size in SIZES:
		root.size = viewport_size
		await _wait_frames()
		var logical_size := root.get_visible_rect().size
		race.call("_layout")
		await _wait_frames()
		var exit_button := race.get("_exit_button") as Control
		var stick := race.get("_stick") as Control
		_check(_inside_view(exit_button.get_global_rect(), logical_size), "race Back button fits %s" % _size_label(viewport_size, logical_size))
		_check(_inside_view(stick.get_global_rect(), logical_size), "race joystick fits %s" % _size_label(viewport_size, logical_size))
	root.remove_child(race)
	race.free()
	await _wait_frames()


func _inside_view(rect: Rect2, viewport_size: Vector2) -> bool:
	var tolerance := 1.5
	return rect.position.x >= -tolerance and rect.position.y >= -tolerance \
		and rect.end.x <= float(viewport_size.x) + tolerance \
		and rect.end.y <= float(viewport_size.y) + tolerance \
		and rect.size.x > 0.0 and rect.size.y > 0.0


func _size_label(physical: Vector2i, logical: Vector2) -> String:
	return "%dx%d (logical %dx%d)" % [physical.x, physical.y, roundi(logical.x), roundi(logical.y)]
