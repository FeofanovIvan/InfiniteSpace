class_name PianoKeyboard
extends Control

signal note_played(note_name: String)
signal user_note_played(note_name: String)

const WHITE_NOTES := ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"]
const BLACK_NOTES := ["Cs4", "Ds4", "Fs4", "Gs4", "As4"]
const BLACK_AFTER_WHITE := [0, 1, 3, 4, 5]
const NOTE_FILES := {
	"C4": "res://education/playtown/audio/piano/C4.ogg",
	"Cs4": "res://education/playtown/audio/piano/Cs4.ogg",
	"D4": "res://education/playtown/audio/piano/D4.ogg",
	"Ds4": "res://education/playtown/audio/piano/Ds4.ogg",
	"E4": "res://education/playtown/audio/piano/E4.ogg",
	"F4": "res://education/playtown/audio/piano/F4.ogg",
	"Fs4": "res://education/playtown/audio/piano/Fs4.ogg",
	"G4": "res://education/playtown/audio/piano/G4.ogg",
	"Gs4": "res://education/playtown/audio/piano/Gs4.ogg",
	"A4": "res://education/playtown/audio/piano/A4.ogg",
	"As4": "res://education/playtown/audio/piano/As4.ogg",
	"B4": "res://education/playtown/audio/piano/B4.ogg",
	"C5": "res://education/playtown/audio/piano/C5.ogg"
}
const NOTE_LABELS := {
	"C4": "C", "Cs4": "C♯", "D4": "D", "Ds4": "D♯",
	"E4": "E", "F4": "F", "Fs4": "F♯", "G4": "G",
	"Gs4": "G♯", "A4": "A", "As4": "A♯", "B4": "B", "C5": "C"
}
const ACCENT_COLORS := [
	Color("#ef5350"), Color("#ff9f1c"), Color("#ffd23f"), Color("#6fcb5b"),
	Color("#38bdf8"), Color("#4f7cff"), Color("#8b5cf6"), Color("#ec5fb3")
]

var white_rects: Array[Rect2] = []
var black_rects: Array[Rect2] = []
var players: Dictionary = {}
var demo_tweens: Dictionary = {}
var pointer_notes: Dictionary = {}
var note_press_counts: Dictionary = {}
var guide_note := ""
var demo_note := ""
var interactive := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	for note in NOTE_FILES:
		var player := AudioStreamPlayer.new()
		player.stream = load(NOTE_FILES[note])
		player.bus = "SFX"
		player.volume_db = -1.5
		add_child(player)
		players[note] = player
	resized.connect(_rebuild_geometry)
	_rebuild_geometry()


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		accept_event()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_update_pointer(event.index, event.position)
		else:
			_release_pointer(event.index)
		accept_event()
	elif event is InputEventScreenDrag:
		_update_pointer(event.index, event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_update_pointer(-1, event.position)
		else:
			_release_pointer(-1)
		accept_event()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_pointer(-1, event.position)
		accept_event()


func _rebuild_geometry() -> void:
	white_rects.clear()
	black_rects.clear()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var white_width := size.x / float(WHITE_NOTES.size())
	for index in range(WHITE_NOTES.size()):
		white_rects.append(Rect2(index * white_width, 0.0, white_width, size.y))
	var black_width := white_width * 0.60
	var black_height := size.y * 0.61
	for white_index in BLACK_AFTER_WHITE:
		var center_x: float = (float(white_index) + 1.0) * white_width
		black_rects.append(Rect2(center_x - black_width * 0.5, 0.0, black_width, black_height))
	queue_redraw()


func _update_pointer(pointer_id: int, position: Vector2) -> void:
	var note := _note_at(position)
	var previous: String = String(pointer_notes.get(pointer_id, ""))
	if note == previous:
		return
	if not previous.is_empty():
		_set_note_pressed(previous, false)
	if note.is_empty():
		pointer_notes.erase(pointer_id)
	else:
		pointer_notes[pointer_id] = note
		_set_note_pressed(note, true)
		_play_note(note)
	queue_redraw()


func _release_pointer(pointer_id: int) -> void:
	if not pointer_notes.has(pointer_id):
		return
	var note: String = pointer_notes[pointer_id]
	pointer_notes.erase(pointer_id)
	_set_note_pressed(note, false)
	queue_redraw()


func _set_note_pressed(note: String, pressed: bool) -> void:
	var count: int = int(note_press_counts.get(note, 0))
	count += 1 if pressed else -1
	if count <= 0:
		note_press_counts.erase(note)
	else:
		note_press_counts[note] = count


func _play_note(note: String) -> void:
	var player: AudioStreamPlayer = players.get(note)
	if player:
		_cancel_demo_tween(note)
		player.volume_db = -1.5
		player.play()
	note_played.emit(note)
	user_note_played.emit(note)


func play_demo_note(note: String, duration_ms: float = 600.0) -> void:
	var player: AudioStreamPlayer = players.get(note)
	if player:
		_cancel_demo_tween(note)
		player.volume_db = -1.5
		player.play()
		var duration := maxf(0.14, duration_ms / 1000.0)
		var fade_duration := minf(0.10, duration * 0.24)
		var tween := create_tween()
		demo_tweens[note] = tween
		tween.tween_interval(maxf(0.0, duration - fade_duration))
		tween.tween_property(player, "volume_db", -35.0, fade_duration)
		tween.tween_callback(func() -> void:
			player.stop()
			player.volume_db = -1.5
			demo_tweens.erase(note)
		)
	note_played.emit(note)


func stop_all_audio() -> void:
	for note in demo_tweens.keys():
		var tween: Tween = demo_tweens[note]
		if tween:
			tween.kill()
	demo_tweens.clear()
	for player_value in players.values():
		var player: AudioStreamPlayer = player_value
		player.stop()
		player.volume_db = -1.5


func _cancel_demo_tween(note: String) -> void:
	if not demo_tweens.has(note):
		return
	var tween: Tween = demo_tweens[note]
	if tween:
		tween.kill()
	demo_tweens.erase(note)


func set_guide_note(note: String) -> void:
	guide_note = note
	queue_redraw()


func set_demo_note(note: String) -> void:
	demo_note = note
	queue_redraw()


func clear_guidance() -> void:
	guide_note = ""
	demo_note = ""
	queue_redraw()


func set_interactive(value: bool) -> void:
	interactive = value
	if not interactive:
		for pointer_id in pointer_notes.keys():
			_release_pointer(int(pointer_id))


func _note_at(position: Vector2) -> String:
	if not Rect2(Vector2.ZERO, size).has_point(position):
		return ""
	for index in range(black_rects.size()):
		if black_rects[index].has_point(position):
			return BLACK_NOTES[index]
	for index in range(white_rects.size()):
		if white_rects[index].has_point(position):
			return WHITE_NOTES[index]
	return ""


func _draw() -> void:
	for index in range(white_rects.size()):
		var note: String = WHITE_NOTES[index]
		var rect := white_rects[index].grow(-2.0)
		var pressed := note_press_counts.has(note)
		var style := StyleBoxFlat.new()
		if pressed or note == demo_note:
			style.bg_color = ACCENT_COLORS[index].lightened(0.55)
		elif note == guide_note:
			style.bg_color = Color("#fff0a3")
		else:
			style.bg_color = Color("#fffdf4")
		style.border_color = Color("#ff9e20") if note == guide_note else ACCENT_COLORS[index].darkened(0.18)
		style.set_border_width_all(maxi(2, int(size.x / 520.0)))
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		style.shadow_color = Color(0.22, 0.12, 0.05, 0.24)
		style.shadow_size = 5
		style.shadow_offset = Vector2(0.0, 4.0)
		draw_style_box(style, rect)
		var circle_radius := minf(rect.size.x * 0.18, 18.0)
		var circle_center := Vector2(rect.get_center().x, rect.end.y - circle_radius - 16.0)
		draw_circle(circle_center, circle_radius, ACCENT_COLORS[index])
		_draw_centered_label(NOTE_LABELS[note], circle_center, int(clampf(circle_radius * 1.35, 14.0, 25.0)), Color.WHITE)
	for index in range(black_rects.size()):
		var note: String = BLACK_NOTES[index]
		var rect := black_rects[index].grow(-2.0)
		var pressed := note_press_counts.has(note)
		var style := StyleBoxFlat.new()
		if pressed or note == demo_note:
			style.bg_color = Color("#7557d9")
		elif note == guide_note:
			style.bg_color = Color("#ffb52d")
		else:
			style.bg_color = Color("#30264f")
		style.border_color = Color("#fff1a6") if note == guide_note else Color("#171127")
		style.set_border_width_all(maxi(2, int(size.x / 620.0)))
		style.corner_radius_bottom_left = 13
		style.corner_radius_bottom_right = 13
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0.0, 5.0)
		draw_style_box(style, rect)
		var label_center := Vector2(rect.get_center().x, rect.end.y - 22.0)
		_draw_centered_label(NOTE_LABELS[note], label_center, int(clampf(rect.size.x * 0.25, 12.0, 20.0)), Color("#f5efff"))


func _draw_centered_label(value: String, center: Vector2, font_size: int, color: Color) -> void:
	var font := get_theme_default_font()
	var text_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(font, center - Vector2(text_size.x * 0.5, -text_size.y * 0.28), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
