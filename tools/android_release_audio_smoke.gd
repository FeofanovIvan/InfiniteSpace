extends SceneTree
## Android release audio audit for buses, six-language recorded instructions,
## adaptive exploration music, Bubble Care, Space Racing, and volume settings.

const ADAPTIVE_MUSIC_SCRIPT := preload("res://scripts/AdaptiveMusic.gd")
const BUBBLE_AUDIO_SCRIPT := preload("res://bubble/scripts/BubbleCareAudio.gd")
const RACE_AUDIO_SCRIPT := preload("res://space_racing/RaceStartAudio.gd")
const LOCALES: Array[String] = ["ru", "en", "pt", "es", "de", "fr"]
const UI_VOICE_KEYS: Array[String] = [
	"parent_gate_intro",
]
const GAME_VOICE_KEYS: Array[String] = [
	"puzzle_intro", "matching_pairs_intro", "animal_habitat_intro",
	"letter_trace_intro", "shape_trace_intro", "word_build_intro", "word_trace_intro",
	"tilt_maze_intro", "count_products_intro",
	"collect_basket_intro", "write_product_count_intro", "collect_product_count_intro",
]
const SHAPES: Array[String] = ["circle", "square", "triangle", "diamond", "star"]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("ANDROID_AUDIO_FAIL: " + message)


func _run() -> void:
	_test_bus_layout()
	_test_recorded_voices()
	await _test_music_modes()
	await _test_volume_setting()
	print("Android release audio smoke: ", "PASS" if _failures == 0 else "%d FAILED" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_bus_layout() -> void:
	for bus_name in ["Master", "Music", "SFX", "VOICE"]:
		_check(AudioServer.get_bus_index(bus_name) >= 0, "%s audio bus is available" % bus_name)


func _test_recorded_voices() -> void:
	var language_service := root.get_node_or_null("LanguageService")
	_check(language_service != null, "LanguageService autoload is available")
	if language_service == null:
		return
	for locale in LOCALES:
		var ui_complete := true
		for key in UI_VOICE_KEYS:
			ui_complete = ui_complete and language_service.call("get_ui_voice", key, locale) != null
		_check(ui_complete, "recorded UI instructions are complete: %s" % locale)
		var games_complete := true
		for key in GAME_VOICE_KEYS:
			games_complete = games_complete and language_service.call("get_game_voice", key, locale) != null
		_check(games_complete, "recorded game introductions are complete: %s" % locale)
		var shapes_complete := true
		for shape in SHAPES:
			shapes_complete = shapes_complete and language_service.call("get_shape_voice", shape, locale) != null
		_check(shapes_complete, "recorded shape voices are complete: %s" % locale)
		var numbers_complete := true
		for number in range(11):
			numbers_complete = numbers_complete and language_service.call("get_number_voice", number, locale) != null
		_check(numbers_complete, "recorded number voices 0-10 are complete: %s" % locale)
		var math_complete: bool = (
			language_service.call("get_math_voice", "plus", locale) != null
			and language_service.call("get_math_voice", "minus", locale) != null
		)
		_check(math_complete, "recorded plus/minus voices are complete: %s" % locale)


func _test_music_modes() -> void:
	var exploration: AdaptiveMusic = ADAPTIVE_MUSIC_SCRIPT.new() as AdaptiveMusic
	exploration.name = "AdaptiveExplorationMusic"
	root.add_child(exploration)
	await process_frame
	var flight := exploration.get_node("FlightActionMusic") as AudioStreamPlayer
	var calm := exploration.get_node("PlanetCalmMusic") as AudioStreamPlayer
	_check(flight.playing and bool(flight.stream.get("loop")), "Singularity Action loops in free flight")
	exploration.set_context("calm", true)
	await process_frame
	_check(calm.playing and bool(calm.stream.get("loop")) and not flight.playing,
		"Singularity Calm replaces Action on planet scenes")

	var bubble: Node = BUBBLE_AUDIO_SCRIPT.new()
	root.add_child(bubble)
	await process_frame
	var bubble_music := bubble.get_node("BubbleCareMusic") as AudioStreamPlayer
	_check(exploration.get_context() == "silent" and bubble_music.playing and bool(bubble_music.stream.get("loop")),
		"Bubble Care loops its room track and silences exploration music")
	_check(_playing_music_count() == 1, "Bubble Care never overlaps two background tracks")
	bubble.call("start_action", "shower")
	var bubble_loop := bubble.get_node("BubbleCareActionLoop") as AudioStreamPlayer
	var bubble_event := bubble.get_node("BubbleCareEventSound") as AudioStreamPlayer
	_check(bubble_loop.stream != null and bubble_event.stream != null, "Bubble Care action effects are connected")
	root.remove_child(bubble)
	bubble.free()
	await process_frame
	_check(exploration.get_context() == "calm" and calm.playing, "Bubble Care restores the previous music context")

	var race: Node = RACE_AUDIO_SCRIPT.new()
	root.add_child(race)
	await process_frame
	_check(exploration.get_context() == "silent" and _playing_music_count() == 0,
		"Space Racing silences exploration music before its countdown")
	race.call("signal_light", 0)
	race.call("start_music")
	await process_frame
	var race_music := race.get_node("RaceMusicOnly") as AudioStreamPlayer
	var race_signal := race.get_node("ThreeRaceLightSignals") as AudioStreamPlayer
	_check(race_music.playing and bool(race_music.stream.get("loop")), "Space Racing loops its dedicated race track")
	_check(race_signal.stream != null, "Space Racing traffic-light effects are connected")
	_check(_playing_music_count() == 1, "Space Racing never overlaps two background tracks")
	root.remove_child(race)
	race.free()
	await process_frame
	_check(exploration.get_context() == "calm" and calm.playing, "Space Racing restores the previous music context")
	root.remove_child(exploration)
	exploration.free()
	await process_frame


func _test_volume_setting() -> void:
	var master_index := AudioServer.get_bus_index("Master")
	var previous_db := AudioServer.get_bus_volume_db(master_index)
	var voice_service := root.get_node_or_null("MikaVoice")
	var previous_voice := int(voice_service.get("volume")) if voice_service != null else 75
	# Load after autoloads enter the tree so MobileLocale resolves reliably in
	# headless --script mode, matching the production project startup order.
	var settings_script := load("res://scripts/SettingsLanguagePopup.gd") as Script
	_check(settings_script != null, "settings audio control compiles")
	if settings_script == null:
		return
	var settings: Control = settings_script.new() as Control
	root.add_child(settings)
	settings.size = Vector2(1280, 720)
	await process_frame
	var slider := settings.get("_volume_slider") as HSlider
	_check(slider != null and is_equal_approx(slider.min_value, 0.0) and is_equal_approx(slider.max_value, 100.0),
		"settings expose a 0-100 volume control")
	settings.call("_apply_master_volume", 35.0)
	_check(is_equal_approx(AudioServer.get_bus_volume_db(master_index), linear_to_db(0.35)),
		"settings change music, effects, and recorded voice through Master")
	_check(voice_service == null or int(voice_service.get("volume")) == 35,
		"settings change system TTS volume too")
	AudioServer.set_bus_volume_db(master_index, previous_db)
	if voice_service != null:
		voice_service.set("volume", previous_voice)
	root.remove_child(settings)
	settings.free()
	await process_frame


func _playing_music_count() -> int:
	return _count_playing_music(root)


func _count_playing_music(node: Node) -> int:
	var count := 0
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		if player.bus == &"Music" and player.playing:
			count += 1
	for child in node.get_children():
		count += _count_playing_music(child)
	return count
