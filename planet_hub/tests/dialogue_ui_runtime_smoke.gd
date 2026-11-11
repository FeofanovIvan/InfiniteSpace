extends SceneTree

const REPRESENTATIVE_SCENE := preload("res://planet_hub/scenes/representative_dialog.tscn")
const CROSSROADS_SCRIPT := preload("res://planet_hub/scripts/crossroads_dialog_v104.gd")

var fails: int = 0

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		fails += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var host := Control.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var representative: Control = REPRESENTATIVE_SCENE.instantiate()
	host.add_child(representative)
	representative.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	representative.call("configure_for_planet", "mw_p01", "Earth", "", "")
	var tablet: Control = representative.get_node("TranslatorTablet")
	for i in range(10):
		tablet.call("_add_message", "Runtime scroll message %02d" % i, i % 2 == 1)
	for _i in range(4):
		await process_frame
	var scroll: ScrollContainer = tablet.get("_chat_scroll")
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	_check(float(scroll.scroll_vertical) + float(bar.page) >= float(bar.max_value) - 2.0,
		"chat follows the newest laid-out message")
	representative.queue_free()
	await process_frame

	var crossroads: Control = CROSSROADS_SCRIPT.new()
	host.add_child(crossroads)
	crossroads.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	crossroads.call("open_dialog")
	for _i in range(3):
		await process_frame
	var toolbar: Control = crossroads.get("_toolbar")
	var sky: Node = crossroads.get("_sky")
	var planet: Node = crossroads.get("_planet")
	_check(toolbar.size.y >= 48.0 and toolbar.size.y <= 90.0, "Crossroads toolbar keeps mobile touch height")
	_check(sky.process_mode != Node.PROCESS_MODE_DISABLED and planet.process_mode != Node.PROCESS_MODE_DISABLED,
		"Crossroads animation runs while open")
	crossroads.call("_on_original_back_pressed")
	await process_frame
	_check(sky.process_mode == Node.PROCESS_MODE_DISABLED and planet.process_mode == Node.PROCESS_MODE_DISABLED,
		"Crossroads animation stops while closed")

	print("Dialogue UI runtime smoke: ", "PASS" if fails == 0 else "%d FAILED" % fails)
	quit(0 if fails == 0 else 1)
