extends SceneTree
## Runtime checks for the adaptive low-GPU paths used by Crossroads and Bubble.

const CROSSROADS_SCRIPT := preload("res://planet_hub/scripts/crossroads_dialog_v104.gd")
const BUBBLE_SCENE := preload("res://bubble/scenes/bubble_character.tscn")
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failed += 1
		push_error("MOBILE_PERFORMANCE_FAIL: " + message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var host := Control.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var crossroads: Control = CROSSROADS_SCRIPT.new() as Control
	host.add_child(crossroads)
	crossroads.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	crossroads.call("open_dialog")
	crossroads.call("set_performance_quality_low", true)
	await process_frame
	var sky: Node = crossroads.get("_sky")
	var planet: Node = crossroads.get("_planet")
	_check(bool(crossroads.call("is_performance_quality_low")), "Crossroads enters adaptive low-GPU mode")
	_check(bool(sky.call("is_quality_low")), "secondary sky effects use the low-GPU path")
	_check(not planet.get_node("WaveRings").visible and not planet.get_node("ArcLightning").visible,
		"expensive storm layers are hidden")
	_check(not planet.get_node("World/Aura").visible and not planet.get_node("World/Flares").visible,
		"secondary living-world passes are hidden")
	crossroads.call("set_performance_quality_low", false)
	await process_frame
	_check(planet.get_node("WaveRings").visible and planet.get_node("World/Aura").visible,
		"full quality can recover without rebuilding the scene")
	crossroads.call("_on_original_back_pressed")
	crossroads.queue_free()
	await process_frame

	var bubble: MikaBubbleBrain = BUBBLE_SCENE.instantiate() as MikaBubbleBrain
	host.add_child(bubble)
	await process_frame
	bubble.set_render_quality_low(true)
	var surface: ColorRect = bubble.get_node("ActiveVisual/Body/Surface") as ColorRect
	var material := surface.material as ShaderMaterial
	_check(is_equal_approx(float(material.get_shader_parameter("detail_level")), 0.0),
		"Bubble keeps its shape while reducing only expensive highlights")
	bubble.set_render_quality_low(false)
	_check(is_equal_approx(float(material.get_shader_parameter("detail_level")), 1.0),
		"Bubble restores full shader detail")

	root.remove_child(host)
	host.free()
	await process_frame
	print("Mobile performance smoke: ", "PASS" if _failed == 0 else "%d FAILED" % _failed)
	quit(0 if _failed == 0 else 1)
