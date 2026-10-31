extends Node2D
signal completed
const FACE_TEXTURES := [
	"res://education/playtown/assets/pet_home/teeth/face_0.png",
	"res://education/playtown/assets/pet_home/teeth/face_1.png",
	"res://education/playtown/assets/pet_home/teeth/face_2.png",
	"res://education/playtown/assets/pet_home/teeth/face_3.png",
	"res://education/playtown/assets/pet_home/teeth/face_4.png",
	"res://education/playtown/assets/pet_home/teeth/face_5.png",
]
const PLAQUE_TEXTURE := "res://education/playtown/assets/pet_home/teeth/plaque_overlay.png"
const TOOTHBRUSH_TEXTURE := "res://education/playtown/assets/pet_home/teeth/toothbrush.png"
const TEXTURE_SIZE := 512
const COMPLETE_THRESHOLD := 0.92
var dim: ColorRect
var face: TextureRect
var plaque: TextureRect
var toothbrush: TextureRect
var progress_panel: Panel
var progress_track: Panel
var progress_fill: ColorRect
var yellow_sample: Panel
var white_sample: Panel
var plaque_image: Image
var plaque_texture: ImageTexture
var plaque_initial_alpha := 0.0
var plaque_removed_alpha := 0.0
var progress := 0.0
var active := false
var ready_to_brush := false
var dragging := false
var drag_offset := Vector2.ZERO
func _ready() -> void:
	z_index = 70
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	visible = false
func _build_ui() -> void:
	dim = ColorRect.new()
	dim.color = Color(0.08, 0.06, 0.03, 0.38)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	face = TextureRect.new()
	face.texture = load(FACE_TEXTURES[0])
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(face)
	plaque = TextureRect.new()
	plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plaque.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.visible = false
	add_child(plaque)
	progress_panel = Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fff4dc")
	panel_style.border_color = Color("#d79835")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(18)
	panel_style.shadow_color = Color(0.12, 0.07, 0.02, 0.26)
	panel_style.shadow_size = 7
	panel_style.shadow_offset = Vector2(0, 4)
	progress_panel.add_theme_stylebox_override("panel", panel_style)
	progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_panel.visible = false
	add_child(progress_panel)
	yellow_sample = _make_sample_panel(Color("#dfb238"))
	progress_panel.add_child(yellow_sample)
	white_sample = _make_sample_panel(Color("#fffdf2"))
	progress_panel.add_child(white_sample)
	progress_track = Panel.new()
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color("#d7b54c")
	track_style.border_color = Color("#9c7832")
	track_style.set_border_width_all(2)
	track_style.set_corner_radius_all(999)
	progress_track.add_theme_stylebox_override("panel", track_style)
	progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_track.clip_contents = true
	progress_panel.add_child(progress_track)
	progress_fill = ColorRect.new()
	progress_fill.color = Color("#fffdf2")
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_track.add_child(progress_fill)
	toothbrush = TextureRect.new()
	toothbrush.texture = load(TOOTHBRUSH_TEXTURE)
	toothbrush.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	toothbrush.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	toothbrush.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toothbrush.visible = false
	add_child(toothbrush)
func _make_sample_panel(color: Color) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#8c682d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel
func start() -> void:
	if active:
		return
	active = true
	ready_to_brush = false
	dragging = false
	progress = 0.0
	visible = true
	dim.modulate.a = 0.0
	face.modulate.a = 0.0
	face.texture = load(FACE_TEXTURES[0])
	plaque.visible = false
	toothbrush.visible = false
	progress_panel.visible = false
	_layout()
	var fade := create_tween().set_parallel(true)
	fade.tween_property(dim, "modulate:a", 1.0, 0.22)
	fade.tween_property(face, "modulate:a", 1.0, 0.22)
	await fade.finished
	for frame_index in range(FACE_TEXTURES.size()):
		if not active:
			return
		face.texture = load(FACE_TEXTURES[frame_index])
		await get_tree().create_timer(0.115).timeout
	_prepare_plaque()
	plaque.visible = true
	toothbrush.visible = true
	progress_panel.visible = true
	toothbrush.modulate.a = 0.0
	progress_panel.modulate.a = 0.0
	var controls_fade := create_tween().set_parallel(true)
	controls_fade.tween_property(toothbrush, "modulate:a", 1.0, 0.18)
	controls_fade.tween_property(progress_panel, "modulate:a", 1.0, 0.18)
	await controls_fade.finished
	ready_to_brush = true
func _prepare_plaque() -> void:
	var source: Texture2D = load(PLAQUE_TEXTURE)
	plaque_image = source.get_image().duplicate()
	plaque_texture = ImageTexture.create_from_image(plaque_image)
	plaque.texture = plaque_texture
	plaque_initial_alpha = 0.0
	plaque_removed_alpha = 0.0
	for y in range(plaque_image.get_height()):
		for x in range(plaque_image.get_width()):
			plaque_initial_alpha += plaque_image.get_pixel(x, y).a
	_update_progress()
func _layout() -> void:
	var vs := get_viewport_rect().size
	if vs.x <= 0.0 or vs.y <= 0.0:
		return
	dim.position = Vector2.ZERO
	dim.size = vs
	var face_size := minf(vs.y * 0.69, vs.x * 0.43)
	face.size = Vector2.ONE * face_size
	face.position = Vector2(
		(vs.x - face_size) * 0.5,
		vs.y * 0.18
	)
	plaque.position = face.position
	plaque.size = face.size
	var panel_w := clampf(face_size * 0.78, 300.0, 430.0)
	var panel_h := clampf(vs.y * 0.088, 58.0, 72.0)
	progress_panel.size = Vector2(panel_w, panel_h)
	progress_panel.position = Vector2(
		(vs.x - panel_w) * 0.5,
		maxf(18.0, face.position.y - panel_h - 18.0)
	)
	var sample_size := panel_h * 0.56
	yellow_sample.size = Vector2.ONE * sample_size
	yellow_sample.position = Vector2(12.0, (panel_h - sample_size) * 0.5)
	white_sample.size = Vector2.ONE * sample_size
	white_sample.position = Vector2(panel_w - sample_size - 12.0, (panel_h - sample_size) * 0.5)
	progress_track.position = Vector2(sample_size + 24.0, panel_h * 0.5 - 9.0)
	progress_track.size = Vector2(panel_w - sample_size * 2.0 - 48.0, 18.0)
	var brush_w := clampf(face_size * 0.48, 190.0, 265.0)
	toothbrush.size = Vector2(brush_w, brush_w / 3.0)
	toothbrush.pivot_offset = toothbrush.size * 0.5
	if not dragging:
		toothbrush.position = Vector2(
			minf(vs.x - toothbrush.size.x - 24.0, face.position.x + face_size + 22.0),
			face.position.y + face_size * 0.58
		)
	_update_progress()
func _input(event: InputEvent) -> void:
	if not active or not ready_to_brush:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		_move_brush(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			dragging = false
	elif event is InputEventScreenDrag and dragging:
		_move_brush(event.position)
func _begin_drag(pointer_position: Vector2) -> void:
	if not Rect2(toothbrush.position, toothbrush.size).grow(24.0).has_point(pointer_position):
		return
	dragging = true
	drag_offset = pointer_position - toothbrush.position
	get_viewport().set_input_as_handled()
func _move_brush(pointer_position: Vector2) -> void:
	var vs := get_viewport_rect().size
	var old_contact := _brush_contact_point()
	var next_position := pointer_position - drag_offset
	next_position.x = clampf(next_position.x, 0.0, vs.x - toothbrush.size.x)
	next_position.y = clampf(next_position.y, 0.0, vs.y - toothbrush.size.y)
	toothbrush.position = next_position
	var new_contact := _brush_contact_point()
	var movement := new_contact.distance_to(old_contact)
	if movement >= 1.5:
		var direction := new_contact - old_contact
		toothbrush.rotation = lerp_angle(
			toothbrush.rotation,
			clampf(direction.y * 0.007, -0.22, 0.22),
			0.2
		)
		_erase_plaque(new_contact)
	get_viewport().set_input_as_handled()
func _brush_contact_point() -> Vector2:
	return toothbrush.position + Vector2(toothbrush.size.x * 0.17, toothbrush.size.y * 0.53)
func _erase_plaque(global_point: Vector2) -> void:
	var face_rect := Rect2(face.position, face.size)
	if not face_rect.has_point(global_point):
		return
	var local_uv := (global_point - face.position) / face.size
	var center := Vector2(local_uv.x, local_uv.y) * TEXTURE_SIZE
	var radius := clampf(toothbrush.size.y * 0.28 / face.size.x * TEXTURE_SIZE, 10.0, 25.0)
	var min_x := maxi(0, int(center.x - radius))
	var max_x := mini(TEXTURE_SIZE - 1, int(center.x + radius))
	var min_y := maxi(0, int(center.y - radius))
	var max_y := mini(TEXTURE_SIZE - 1, int(center.y + radius))
	var changed := false
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance := Vector2(x, y).distance_to(center)
			if distance > radius:
				continue
			var color := plaque_image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			var erase_strength := clampf(1.0 - distance / radius, 0.0, 1.0) * 0.78
			var new_alpha := color.a * (1.0 - erase_strength)
			plaque_removed_alpha += color.a - new_alpha
			color.a = new_alpha
			plaque_image.set_pixel(x, y, color)
			changed = true
	if not changed:
		return
	plaque_texture.update(plaque_image)
	progress = clampf(plaque_removed_alpha / maxf(1.0, plaque_initial_alpha), 0.0, 1.0)
	_update_progress()
	if progress >= COMPLETE_THRESHOLD:
		_finish()
func _update_progress() -> void:
	if progress_track == null:
		return
	progress_fill.position = Vector2.ZERO
	progress_fill.size = Vector2(progress_track.size.x * progress, progress_track.size.y)
	progress_fill.color = Color("#dfb238").lerp(Color("#fffdf2"), progress)
func _finish() -> void:
	if not active or not ready_to_brush:
		return
	ready_to_brush = false
	dragging = false
	progress = 1.0
	_update_progress()
	toothbrush.visible = false
	await get_tree().create_timer(0.35).timeout
	plaque.visible = false
	progress_panel.visible = false
	for frame_index in range(FACE_TEXTURES.size() - 1, -1, -1):
		face.texture = load(FACE_TEXTURES[frame_index])
		await get_tree().create_timer(0.10).timeout
	var fade := create_tween().set_parallel(true)
	fade.tween_property(face, "modulate:a", 0.0, 0.20)
	fade.tween_property(dim, "modulate:a", 0.0, 0.20)
	await fade.finished
	active = false
	visible = false
	completed.emit()
