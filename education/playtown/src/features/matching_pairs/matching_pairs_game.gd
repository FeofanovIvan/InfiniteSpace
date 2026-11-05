extends Node2D

const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const BACKGROUND_TEXTURE: Texture2D = preload("res://education/playtown/assets/matching_pairs/ui/background.webp")
const DOOR_OPEN_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/matching_pairs/door_open.mp3")
const DOOR_CLOSE_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/matching_pairs/door_close.mp3")
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const HOME_SCENE := "res://education/playtown/scenes/screens/game_select_home.tscn"
const REFERENCE_SIZE := Vector2(1536.0, 768.0)
const SYMBOL_POOL := [
	{"kind": "circle", "color": Color("#f04a49")},
	{"kind": "square", "color": Color("#44a8e8")},
	{"kind": "triangle", "color": Color("#ffd53d")},
	{"kind": "diamond", "color": Color("#9b5de5")},
	{"kind": "star", "color": Color("#72c84b")},
	{"kind": "circle", "color": Color("#ff8b35")},
	{"kind": "square", "color": Color("#ef69a6")},
	{"kind": "triangle", "color": Color("#34c7b0")},
	{"kind": "diamond", "color": Color("#5a77dc")},
	{"kind": "star", "color": Color("#ff6b60")}
]

var background: TextureRect
var ui_layer: CanvasLayer
var home_button: Button
var score_back: Panel
var score_icon: TextureRect
var score_label: Label
var doors: Array[MatchingDoor] = []
var first_door: MatchingDoor
var input_locked := false
var correct_player: AudioStreamPlayer
var wrong_player: AudioStreamPlayer
var door_open_player: AudioStreamPlayer
var door_close_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var round_number := 0
var score := 0

func _ready() -> void:
	randomize()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_start_new_round()
	call_deferred("_play_instruction")

func _build_ui() -> void:
	background = TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	home_button = GameExitButton.new()
	home_button.pressed.connect(_go_home)
	ui_layer.add_child(home_button)
	score_back = GameScorePanel.new()
	ui_layer.add_child(score_back)
	score_icon = (score_back as GameScorePanel).score_icon
	score_label = (score_back as GameScorePanel).score_label
	score_label.add_theme_font_override("font", GAME_FONT)

	correct_player = AudioStreamPlayer.new()
	correct_player.stream = preload("res://education/playtown/audio/sfx/correct.ogg")
	correct_player.bus = "SFX"
	add_child(correct_player)
	wrong_player = AudioStreamPlayer.new()
	wrong_player.stream = preload("res://education/playtown/audio/sfx/wrong.ogg")
	wrong_player.bus = "SFX"
	add_child(wrong_player)
	door_open_player = AudioStreamPlayer.new()
	door_open_player.stream = DOOR_OPEN_SOUND
	door_open_player.bus = "SFX"
	add_child(door_open_player)
	door_close_player = AudioStreamPlayer.new()
	door_close_player.stream = DOOR_CLOSE_SOUND
	door_close_player.bus = "SFX"
	add_child(door_close_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)

func _play_instruction() -> void:
	var stream := LanguageService.get_game_voice("matching_pairs_intro")
	if stream == null:
		return
	voice_player.stop()
	voice_player.stream = stream
	voice_player.play()

func _play_shape_voice(shape: String) -> void:
	var stream := LanguageService.get_shape_voice(shape)
	if stream == null:
		return
	voice_player.stop()
	voice_player.stream = stream
	voice_player.play()

func _go_home() -> void:
	SFX.transition_to_scene(HOME_SCENE)

func _start_new_round() -> void:
	input_locked = true
	first_door = null
	round_number += 1
	for door in doors:
		if is_instance_valid(door):
			door.queue_free()
	doors.clear()
	var available := SYMBOL_POOL.duplicate(true)
	available.shuffle()
	var pairs: Array[Dictionary] = []
	for index in range(4):
		pairs.append(available[index])
		pairs.append(available[index].duplicate())
	pairs.shuffle()
	for symbol in pairs:
		var door := MatchingDoor.new()
		door.configure(symbol["kind"], symbol["color"])
		door.selected.connect(_on_door_selected)
		door.modulate.a = 0.0
		add_child(door)
		doors.append(door)
	_layout_doors(false)
	for index in range(doors.size()):
		var door := doors[index]
		var tween := create_tween()
		tween.tween_interval(float(index) * 0.045)
		tween.tween_property(door, "modulate:a", 1.0, 0.18)
	input_locked = false

func _on_door_selected(door: MatchingDoor) -> void:
	if input_locked or door.revealed or door.matched:
		return
	input_locked = true
	door_open_player.stop()
	door_open_player.play()
	await door.set_revealed(true)
	if first_door == null:
		first_door = door
		input_locked = false
		return
	var second_door := door
	if _symbols_match(first_door, second_door):
		correct_player.play()
		_play_shape_voice(first_door.symbol_kind)
		SFX.play_praise(get_viewport_rect().size * 0.5, 1.0)
		score += 1
		GameState.last_score = score
		GameState.add_coins(1)
		await get_tree().create_timer(0.28).timeout
		var matched_first := first_door
		first_door = null
		matched_first.play_match_animation()
		second_door.play_match_animation()
		await get_tree().create_timer(0.42).timeout
		doors.erase(matched_first)
		doors.erase(second_door)
		matched_first.queue_free()
		second_door.queue_free()
		if doors.is_empty():
			await get_tree().create_timer(0.9).timeout
			_start_new_round()
			return
		_layout_doors(true)
		input_locked = false
	else:
		wrong_player.play()
		SFX.play_retry(get_viewport_rect().size * 0.5)
		await get_tree().create_timer(0.7).timeout
		var previous := first_door
		first_door = null
		door_close_player.stop()
		door_close_player.play()
		await previous.set_revealed(false)
		await second_door.set_revealed(false)
		input_locked = false

func _symbols_match(a: MatchingDoor, b: MatchingDoor) -> bool:
	return a.symbol_kind == b.symbol_kind and a.symbol_color == b.symbol_color

func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	var safe_scale := clampf(scale_factor, 0.62, 1.35)
	var edge: float = 18.0 * safe_scale
	var safe := _safe_area_insets(viewport_size)
	var left_edge := edge + safe.x
	var top_edge := edge + safe.y
	var right_edge := edge + safe.z
	background.position = Vector2.ZERO
	background.size = viewport_size
	var button_size: float = 106.0 * safe_scale
	home_button.position = Vector2(left_edge, top_edge)
	home_button.size = Vector2.ONE * button_size
	var score_size: Vector2 = Vector2(225.0, 88.0) * safe_scale
	score_back.position = Vector2(viewport_size.x - score_size.x - right_edge, top_edge)
	score_back.size = score_size
	score_icon.position = Vector2(9.0, 7.0) * safe_scale
	score_icon.size = Vector2.ONE * 72.0 * safe_scale
	score_label.position = Vector2(82.0, 4.0) * safe_scale
	score_label.size = Vector2(132.0, 80.0) * safe_scale
	score_label.add_theme_font_size_override("font_size", int(42.0 * safe_scale))
	_layout_doors(false)

func _safe_area_insets(viewport_size: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_view := viewport_size / window_size
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	return Vector4(
		float(safe_rect.position.x) * scale_to_view.x,
		float(safe_rect.position.y) * scale_to_view.y,
		right_px * scale_to_view.x,
		bottom_px * scale_to_view.y
	)

func _layout_doors(animated: bool) -> void:
	if doors.is_empty():
		return
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / 1536.0, viewport_size.y / 768.0)
	var columns := 4 if doors.size() >= 8 else maxi(2, int(ceil(float(doors.size()) / 2.0)))
	var rows := int(ceil(float(doors.size()) / float(columns)))
	var top: float = maxf(12.0, 24.0 * scale_factor)
	var bottom: float = maxf(16.0, 24.0 * scale_factor)
	var horizontal_gap: float = maxf(10.0, 25.0 * scale_factor)
	var vertical_gap: float = maxf(8.0, 18.0 * scale_factor)
	var available_height: float = viewport_size.y - top - bottom
	var available_width: float = viewport_size.x - maxf(36.0, 100.0 * scale_factor)
	var door_height: float = minf((available_height - vertical_gap * float(rows - 1)) / float(rows), 285.0 * scale_factor)
	var door_width: float = door_height * 0.75
	if door_width * columns + horizontal_gap * float(columns - 1) > available_width:
		door_width = (available_width - horizontal_gap * float(columns - 1)) / float(columns)
		door_height = door_width / 0.75
	var total_height := door_height * rows + vertical_gap * float(rows - 1)
	var start_y := top + maxf(0.0, (available_height - total_height) * 0.5)
	for index in range(doors.size()):
		var row := index / columns
		var first_in_row := row * columns
		var items_in_row := mini(columns, doors.size() - first_in_row)
		var row_width := door_width * items_in_row + horizontal_gap * float(items_in_row - 1)
		var column := index - first_in_row
		var target := Vector2((viewport_size.x - row_width) * 0.5 + float(column) * (door_width + horizontal_gap), start_y + float(row) * (door_height + vertical_gap))
		var current_door := doors[index]
		current_door.size = Vector2(door_width, door_height)
		current_door.pivot_offset = current_door.size * 0.5
		if animated:
			var tween := create_tween()
			tween.tween_property(current_door, "position", target, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			current_door.position = target
