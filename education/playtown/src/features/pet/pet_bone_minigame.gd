extends Node2D
signal chewing_started
signal completed
const BONE_TEXTURE := "res://education/playtown/assets/pet_home/bone_game/bone.png"
const CHEW_TEXTURES := [
	"res://education/playtown/assets/pet_home/bone_game/chew_0.png",
	"res://education/playtown/assets/pet_home/bone_game/chew_1.png",
	"res://education/playtown/assets/pet_home/bone_game/chew_2.png",
	"res://education/playtown/assets/pet_home/bone_game/chew_3.png",
	"res://education/playtown/assets/pet_home/bone_game/chew_4.png",
	"res://education/playtown/assets/pet_home/bone_game/chew_5.png",
]
const CHEW_SEQUENCE := [0, 1, 2, 5, 4, 3, 0]
const CHEW_LOOPS := 2
var dim: ColorRect
var draggable_bone: TextureRect
var chew_face: TextureRect
var progress_panel: Panel
var progress_track: Panel
var progress_fill: ColorRect
var progress_icon: TextureRect
var target_rect := Rect2()
var active := false
var dragging := false
var drag_offset := Vector2.ZERO
var chewing := false
var progress := 0.0
func _ready() -> void:
	z_index = 55
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	visible = false
func _build_ui() -> void:
	dim = ColorRect.new()
	dim.color = Color(0.08, 0.06, 0.03, 0.34)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.visible = false
	add_child(dim)
	draggable_bone = TextureRect.new()
	draggable_bone.texture = load(BONE_TEXTURE)
	draggable_bone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	draggable_bone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	draggable_bone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draggable_bone)
	chew_face = TextureRect.new()
	chew_face.texture = load(CHEW_TEXTURES[0])
	chew_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chew_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chew_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chew_face.visible = false
	add_child(chew_face)
	progress_panel = Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fff4dc")
	panel_style.border_color = Color("#d79835")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(999)
	panel_style.shadow_color = Color(0.12, 0.07, 0.02, 0.26)
	panel_style.shadow_size = 7
	panel_style.shadow_offset = Vector2(0, 4)
	progress_panel.add_theme_stylebox_override("panel", panel_style)
	progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_panel.visible = false
	add_child(progress_panel)
	progress_track = Panel.new()
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color("#d8c9ad")
	track_style.border_color = Color("#9b794b")
	track_style.set_border_width_all(2)
	track_style.set_corner_radius_all(999)
	progress_track.add_theme_stylebox_override("panel", track_style)
	progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_track.clip_contents = true
	progress_panel.add_child(progress_track)
	progress_fill = ColorRect.new()
	progress_fill.color = Color("#83bf3d")
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_track.add_child(progress_fill)
	progress_icon = TextureRect.new()
	progress_icon.texture = load(BONE_TEXTURE)
	progress_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	progress_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	progress_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_panel.add_child(progress_icon)
func start(pet_target_rect: Rect2) -> void:
	if active:
		return
	target_rect = pet_target_rect
	active = true
	dragging = false
	chewing = false
	progress = 0.0
	visible = true
	dim.visible = false
	chew_face.visible = false
	progress_panel.visible = false
	draggable_bone.visible = true
	draggable_bone.modulate.a = 0.0
	draggable_bone.rotation = 0.0
	_layout()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(draggable_bone, "modulate:a", 1.0, 0.24)
func _layout() -> void:
	var vs := get_viewport_rect().size
	if vs.x <= 0.0 or vs.y <= 0.0:
		return
	dim.position = Vector2.ZERO
	dim.size = vs
	var bone_w := clampf(vs.y * 0.29, 170.0, 235.0)
	draggable_bone.size = Vector2(bone_w, bone_w * 300.0 / 768.0)
	draggable_bone.pivot_offset = draggable_bone.size * 0.5
	if active and not dragging and not chewing:
		draggable_bone.position = Vector2(
			(vs.x - draggable_bone.size.x) * 0.5,
			vs.y - draggable_bone.size.y - vs.y * 0.045
		)
	var face_size := minf(vs.y * 0.68, vs.x * 0.43)
	chew_face.size = Vector2.ONE * face_size
	chew_face.position = Vector2(
		(vs.x - face_size) * 0.5,
		vs.y * 0.18
	)
	var panel_w := clampf(face_size * 0.72, 280.0, 400.0)
	var panel_h := clampf(vs.y * 0.078, 52.0, 66.0)
	progress_panel.size = Vector2(panel_w, panel_h)
	progress_panel.position = Vector2(
		(vs.x - panel_w) * 0.5,
		maxf(16.0, chew_face.position.y - panel_h - 18.0)
	)
	var icon_w := panel_h * 1.45
	var icon_h := panel_h * 0.56
	progress_track.position = Vector2(icon_w * 0.5 + 14.0, panel_h * 0.5 - 8.0)
	progress_track.size = Vector2(panel_w - icon_w - 28.0, 16.0)
	progress_icon.size = Vector2(icon_w, icon_h)
	progress_icon.position.y = panel_h * 0.5 - icon_h * 0.5
	_update_progress()
func _input(event: InputEvent) -> void:
	if not active or chewing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		_move_bone(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			dragging = false
	elif event is InputEventScreenDrag and dragging:
		_move_bone(event.position)
func _begin_drag(pointer_position: Vector2) -> void:
	if not Rect2(draggable_bone.position, draggable_bone.size).grow(22.0).has_point(pointer_position):
		return
	dragging = true
	drag_offset = pointer_position - draggable_bone.position
	get_viewport().set_input_as_handled()
func _move_bone(pointer_position: Vector2) -> void:
	var vs := get_viewport_rect().size
	var old_center := draggable_bone.position + draggable_bone.size * 0.5
	var next_position := pointer_position - drag_offset
	next_position.x = clampf(next_position.x, 0.0, vs.x - draggable_bone.size.x)
	next_position.y = clampf(next_position.y, 0.0, vs.y - draggable_bone.size.y)
	draggable_bone.position = next_position
	var new_center := draggable_bone.position + draggable_bone.size * 0.5
	var direction := new_center - old_center
	if direction.length_squared() > 0.1:
		draggable_bone.rotation = lerp_angle(
			draggable_bone.rotation,
			clampf(direction.y * 0.006, -0.24, 0.24),
			0.20
		)
	if _is_bone_over_mouth(new_center):
		_start_chewing()
	get_viewport().set_input_as_handled()
func _is_bone_over_mouth(point: Vector2) -> bool:
	var mouth_center := target_rect.position + target_rect.size * Vector2(0.50, 0.48)
	var radius := target_rect.size * Vector2(0.27, 0.20)
	if radius.x <= 0.0 or radius.y <= 0.0:
		return false
	var normalized := Vector2(
		(point.x - mouth_center.x) / radius.x,
		(point.y - mouth_center.y) / radius.y
	)
	return normalized.length_squared() <= 1.0
func _start_chewing() -> void:
	if chewing:
		return
	chewing = true
	dragging = false
	draggable_bone.visible = false
	dim.visible = true
	dim.modulate.a = 0.0
	chew_face.visible = true
	chew_face.modulate.a = 0.0
	progress_panel.visible = true
	progress_panel.modulate.a = 0.0
	chewing_started.emit()
	var fade := create_tween().set_parallel(true)
	fade.tween_property(dim, "modulate:a", 1.0, 0.20)
	fade.tween_property(chew_face, "modulate:a", 1.0, 0.20)
	fade.tween_property(progress_panel, "modulate:a", 1.0, 0.20)
	await fade.finished
	var total_steps := CHEW_SEQUENCE.size() * CHEW_LOOPS
	var completed_steps := 0
	for loop_index in range(CHEW_LOOPS):
		for frame_index in CHEW_SEQUENCE:
			if not active:
				return
			chew_face.texture = load(CHEW_TEXTURES[frame_index])
			completed_steps += 1
			progress = float(completed_steps) / total_steps
			_update_progress()
			await get_tree().create_timer(0.14).timeout
	progress = 1.0
	_update_progress()
	await get_tree().create_timer(0.28).timeout
	var finish_fade := create_tween().set_parallel(true)
	finish_fade.tween_property(dim, "modulate:a", 0.0, 0.20)
	finish_fade.tween_property(chew_face, "modulate:a", 0.0, 0.20)
	finish_fade.tween_property(progress_panel, "modulate:a", 0.0, 0.20)
	await finish_fade.finished
	active = false
	chewing = false
	visible = false
	completed.emit()
func _update_progress() -> void:
	if progress_track == null:
		return
	progress_fill.position = Vector2.ZERO
	progress_fill.size = Vector2(progress_track.size.x * progress, progress_track.size.y)
	progress_icon.position.x = (
		progress_track.position.x
		- progress_icon.size.x * 0.5
		+ progress_track.size.x * progress
	)
