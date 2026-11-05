extends CanvasLayer

signal closed

const WHEEL_TEXTURE: Texture2D = preload("res://education/playtown/assets/bonus_wheel/wheel.webp")
const POINTER_TEXTURE: Texture2D = preload("res://education/playtown/assets/bonus_wheel/pointer.webp")
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const WIN_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/bonus_wheel_win.mp3")
const LOSE_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/bonus_wheel_lose.mp3")
const SECTOR_COUNT := 12
const SPIN_NOTES: Array[AudioStream] = [
	preload("res://education/playtown/audio/piano/C4.ogg"),
	preload("res://education/playtown/audio/piano/E4.ogg"),
	preload("res://education/playtown/audio/piano/G4.ogg"),
	preload("res://education/playtown/audio/piano/E4.ogg"),
]
const REWARDS := [
	{"kind": "item", "id": "collar"},
	{"kind": "coins", "amount": 150},
	{"kind": "item", "id": "food"},
	{"kind": "coins", "amount": 100},
	{"kind": "item", "id": "shampoo"},
	{"kind": "item", "id": "house"},
	{"kind": "item", "id": "water"},
	{"kind": "coins", "amount": 150},
	{"kind": "item", "id": "food"},
	{"kind": "coins", "amount": 100},
	{"kind": "item", "id": "bone"},
	{"kind": "item", "id": "toothpaste"},
]

var root: Control
var backdrop: Panel
var wheel: TextureRect
var pointer: TextureRect
var result_badge: Panel
var result_label: Label
var spinning := false
var selected_index := 0
var spin_player: AudioStreamPlayer
var result_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 500
	randomize()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	get_tree().paused = true


func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false


func _build_ui() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.025, 0.10, 0.13, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	backdrop = Panel.new()
	backdrop.add_theme_stylebox_override("panel", _panel_style())
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	for index in 10:
		var star := Label.new()
		star.text = "★"
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.add_theme_font_override("font", GAME_FONT)
		star.add_theme_font_size_override("font_size", 30)
		star.add_theme_color_override("font_color", Color(1.0, 0.86, 0.24, 0.72))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.set_meta("star_index", index)
		root.add_child(star)
	wheel = TextureRect.new()
	wheel.texture = WHEEL_TEXTURE
	wheel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wheel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wheel.mouse_filter = Control.MOUSE_FILTER_STOP
	wheel.gui_input.connect(_on_wheel_input)
	root.add_child(wheel)
	pointer = TextureRect.new()
	pointer.texture = POINTER_TEXTURE
	pointer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pointer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointer.z_index = 20
	root.add_child(pointer)
	result_badge = Panel.new()
	result_badge.add_theme_stylebox_override("panel", _result_style(Color("#55b94b")))
	result_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_badge.visible = false
	result_badge.z_index = 30
	root.add_child(result_badge)
	result_label = Label.new()
	result_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_override("font", GAME_FONT)
	result_label.add_theme_color_override("font_color", Color.WHITE)
	result_label.add_theme_color_override("font_outline_color", Color("#6d4317"))
	result_label.add_theme_constant_override("outline_size", 5)
	result_badge.add_child(result_label)
	spin_player = AudioStreamPlayer.new()
	spin_player.bus = "SFX"
	spin_player.volume_db = -5.0
	add_child(spin_player)
	result_player = AudioStreamPlayer.new()
	result_player.bus = "SFX"
	add_child(result_player)


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	root.size = view
	var safe := _safe_area_insets(view)
	var usable := Rect2(Vector2(safe.x + 18.0, safe.y + 18.0), Vector2(view.x - safe.x - safe.z - 36.0, view.y - safe.y - safe.w - 36.0))
	var wheel_side := minf(usable.size.y * 0.88, usable.size.x * 0.72)
	var wheel_center := usable.position + usable.size * 0.5
	wheel.size = Vector2.ONE * wheel_side
	wheel.position = wheel_center - wheel.size * 0.5
	wheel.pivot_offset = wheel.size * 0.5
	var panel_size := Vector2(wheel_side + 62.0, minf(usable.size.y, wheel_side + 62.0))
	backdrop.size = panel_size
	backdrop.position = wheel_center - panel_size * 0.5
	var pointer_side := wheel_side * 0.16
	pointer.size = Vector2(pointer_side * 0.94, pointer_side)
	pointer.position = Vector2(wheel_center.x - pointer.size.x * 0.5, wheel.position.y - pointer.size.y * 0.82)
	var badge_size := Vector2(clampf(wheel_side * 0.34, 150.0, 250.0), clampf(wheel_side * 0.13, 70.0, 105.0))
	result_badge.size = badge_size
	result_badge.position = Vector2(wheel_center.x - badge_size.x * 0.5, wheel.position.y + wheel_side * 0.78)
	result_label.add_theme_font_size_override("font_size", int(badge_size.y * 0.56))
	var stars := []
	for child in root.get_children():
		if child.has_meta("star_index"):
			stars.append(child)
	for star in stars:
		var index := int(star.get_meta("star_index"))
		var angle := TAU * float(index) / float(stars.size())
		var radius := Vector2(panel_size.x * 0.46, panel_size.y * 0.43)
		star.size = Vector2(44.0, 44.0)
		star.position = wheel_center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y) - star.size * 0.5


func _on_wheel_input(event: InputEvent) -> void:
	if spinning:
		return
	if event is InputEventScreenTouch and event.pressed:
		_spin()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_spin()


func _spin() -> void:
	spinning = true
	selected_index = randi_range(0, SECTOR_COUNT - 1)
	var sector_angle := TAU / float(SECTOR_COUNT)
	var target_mod := fposmod(-float(selected_index) * sector_angle, TAU)
	var current_mod := fposmod(wheel.rotation, TAU)
	var travel := fposmod(target_mod - current_mod, TAU) + TAU * float(randi_range(5, 7))
	_play_spin_music()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(wheel, "rotation", wheel.rotation + travel, 4.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_resolve_reward)


func _resolve_reward() -> void:
	spinning = false
	spin_player.stop()
	var reward: Dictionary = REWARDS[selected_index]
	var granted := false
	if String(reward.kind) == "coins":
		var amount := int(reward.amount)
		GameState.add_coins(amount)
		result_label.text = "+%d ★" % amount
		granted = true
	else:
		granted = GameState.grant_bonus_wheel_item(String(reward.id))
		result_label.text = "+1  ✓" if granted else "✕"
	result_badge.add_theme_stylebox_override("panel", _result_style(Color("#55b94b") if granted else Color("#dc4b43")))
	result_player.stream = WIN_SOUND if granted else LOSE_SOUND
	result_player.volume_db = -2.0 if granted else -3.0
	result_player.pitch_scale = 1.0
	result_player.play()
	result_badge.visible = true
	result_badge.modulate.a = 0.0
	result_badge.scale = Vector2(0.55, 0.55)
	result_badge.pivot_offset = result_badge.size * 0.5
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(result_badge, "modulate:a", 1.0, 0.22)
	tween.tween_property(result_badge, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(2.0)
	tween.tween_callback(_close)


func _play_spin_music() -> void:
	var step := 0
	var started_at := Time.get_ticks_msec()
	while spinning and is_inside_tree():
		spin_player.stream = SPIN_NOTES[step % SPIN_NOTES.size()]
		spin_player.pitch_scale = lerpf(1.08, 0.92, clampf(float(Time.get_ticks_msec() - started_at) / 4000.0, 0.0, 1.0))
		spin_player.play()
		step += 1
		var progress := clampf(float(Time.get_ticks_msec() - started_at) / 4000.0, 0.0, 1.0)
		await get_tree().create_timer(lerpf(0.11, 0.30, progress), true).timeout


func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()


func _safe_area_insets(view: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0:
		return Vector4.ZERO
	var scale := Vector2(view.x / window_size.x, view.y / window_size.y)
	return Vector4(float(safe_rect.position.x) * scale.x, float(safe_rect.position.y) * scale.y, maxf(0.0, window_size.x - safe_rect.end.x) * scale.x, maxf(0.0, window_size.y - safe_rect.end.y) * scale.y)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff2cf")
	style.border_color = Color("#f3a51f")
	style.set_border_width_all(6)
	style.set_corner_radius_all(46)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 18
	return style


func _result_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#ffe46d")
	style.set_border_width_all(5)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 10
	return style
