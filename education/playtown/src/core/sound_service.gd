extends Node
var scene_transition_active := false
var _master_was_muted := false
var _last_praise := -1
var _last_retry := -1

func play_praise(position: Vector2, delay := 0.65) -> void:
	_play_feedback("praise", 5, position, delay)

func play_retry(position: Vector2, delay := 0.12) -> void:
	_play_feedback("retry", 3, position, delay)

func _play_feedback(kind: String, count: int, position: Vector2, delay: float) -> void:
	var locale := LanguageService.learning_locale
	if locale not in ["ru", "en", "pt", "es", "fr", "de"]:
		return
	var previous := _last_praise if kind == "praise" else _last_retry
	var index := randi_range(1, count)
	if count > 1 and index == previous:
		index = index % count + 1
	if kind == "praise":
		_last_praise = index
	else:
		_last_retry = index
	var path := "res://education/playtown/audio/voice/%s/feedback/%s_%02d.mp3" % [locale, kind, index]
	if not ResourceLoader.exists(path):
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_play_on_bus(load(path) as AudioStream, position, 0.0, "VOICE")

func play_2d(stream: AudioStream, position: Vector2, volume_db := -6) -> void:
	_play_on_bus(stream, position, volume_db, "SFX")
func play_voice_2d(stream: AudioStream, position: Vector2, volume_db := 0.0) -> void:
	_play_on_bus(stream, position, volume_db, "VOICE")
func _play_on_bus(stream: AudioStream, position: Vector2, volume_db: float, bus: StringName) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.global_position = position
	add_child(player)
	player.play()
	player.finished.connect(func():
		player.queue_free()
	)

func transition_to_scene(scene_path: String) -> void:
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null and bool(portal.get("active")):
		portal.call("handle_scene_transition", scene_path)
		return
	if scene_transition_active or scene_path.is_empty():
		return
	scene_transition_active = true
	_stop_audio_branch(get_tree().current_scene)
	_stop_service_audio()
	_mute_during_ios_transition()
	var packed_scene := await _load_scene(scene_path)
	var error := ERR_CANT_OPEN
	if packed_scene != null:
		error = PlayTownPortal.change_scene_to_packed(packed_scene)
	else:
		error = PlayTownPortal.change_scene_to_file(scene_path)
	if error == OK:
		await get_tree().process_frame
	_restore_ios_audio()
	scene_transition_active = false

func transition_from_world(scene_path: String) -> void:
	transition_to_scene(scene_path)

func _load_scene(scene_path: String) -> PackedScene:
	var request_error := ResourceLoader.load_threaded_request(scene_path, "PackedScene", true)
	if request_error != OK:
		return null
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(scene_path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	return ResourceLoader.load_threaded_get(scene_path) as PackedScene

func _mute_during_ios_transition() -> void:
	if OS.get_name() != "iOS":
		return
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		return
	_master_was_muted = AudioServer.is_bus_mute(master_bus)
	AudioServer.set_bus_mute(master_bus, true)

func _restore_ios_audio() -> void:
	if OS.get_name() != "iOS":
		return
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, _master_was_muted)

func _stop_audio_branch(root: Node) -> void:
	if root == null:
		return
	if root is AudioStreamPlayer or root is AudioStreamPlayer2D or root is AudioStreamPlayer3D:
		root.stop()
	for child in root.get_children():
		_stop_audio_branch(child)

func _stop_service_audio() -> void:
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
			child.stop()
			child.queue_free()
