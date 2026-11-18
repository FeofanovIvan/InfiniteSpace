extends SceneTree
## Adaptive exploration music state/loop smoke.
## Run with --headless --path PROJECT --script res://planet_hub/tests/adaptive_music_smoke.gd

const MUSIC_SCRIPT := preload("res://scripts/AdaptiveMusic.gd")
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failed += 1
		push_error("ADAPTIVE_MUSIC_FAIL: " + message)


func _run() -> void:
	var music: AdaptiveMusic = MUSIC_SCRIPT.new() as AdaptiveMusic
	root.add_child(music)
	await process_frame
	var flight := music.get_node("FlightActionMusic") as AudioStreamPlayer
	var calm := music.get_node("PlanetCalmMusic") as AudioStreamPlayer
	_check(music.get_context() == "flight" and flight.playing, "flight music starts with exploration")
	_check(bool(flight.stream.get("loop")) and bool(calm.stream.get("loop")), "both tracks loop")
	_check(is_equal_approx(flight.volume_db, -13.0), "flight gain stays unobtrusive")

	paused = true
	music.set_context("calm", true)
	await process_frame
	_check(music.get_context() == "calm" and calm.playing and not flight.playing,
		"calm music switches while the planet screen is paused")
	_check(is_equal_approx(calm.volume_db, -12.0), "calm gain stays unobtrusive")

	music.set_context("silent", true)
	await process_frame
	_check(not calm.playing and not flight.playing, "simulators can silence exploration music")
	paused = false
	root.remove_child(music)
	music.free()
	await process_frame
	print("Adaptive music smoke: ", "PASS" if _failed == 0 else "%d FAILED" % _failed)
	quit(0 if _failed == 0 else 1)
