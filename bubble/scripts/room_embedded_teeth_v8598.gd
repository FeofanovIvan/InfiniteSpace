extends "res://learning/src/features/pet/pet_teeth_minigame.gd"
## MIKA v8.5.9.8 — shared pet-teeth controller, re-skinned for Bubble.
## The inherited _input, _begin_drag, _move_brush, _brush_contact_point and
## _erase_plaque are used UNCHANGED. A single 512x512 plaque image is composed
## from Bubble's ten original masks only once at the start of each session.
## No custom per-tooth collision, no Bubble FaceRig brush_at() calls.
signal progress_changed(value: float)

var _bubble_face: Node2D = null
var _session: int = 0
var _debug_contact: bool = false
var _original_masks: Array[Sprite2D] = []
var _last_log_bucket: int = -1

func _ready() -> void:
	super._ready()
	z_index = 12
	face.visible = false # Keep Bubble; never show the source dog picture.
	dim.visible = false
	progress_panel.visible = false # Keep MIKA's rounded progress bar.
	visible = false

func _bubble_face_rect() -> Rect2:
	# Both nodes are in the same HUD CanvasLayer; use viewport coordinates.
	var xf: Transform2D = _bubble_face.get_global_transform_with_canvas()
	var a: Vector2 = xf * Vector2(-205.0, -205.0)
	var b: Vector2 = xf * Vector2(205.0, 205.0)
	var tl: Vector2 = Vector2(minf(a.x, b.x), minf(a.y, b.y))
	var br: Vector2 = Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
	return Rect2(tl, br - tl)

func _layout() -> void:
	if face == null:
		return
	if not is_instance_valid(_bubble_face):
		super._layout()
		return
	var vs: Vector2 = get_viewport_rect().size
	var rect: Rect2 = _bubble_face_rect()
	face.position = rect.position
	face.size = rect.size
	plaque.position = rect.position
	plaque.size = rect.size
	# Preserve the embedded toothbrush aspect, placement, and hit box.
	var brush_w: float = clampf(rect.size.x * 0.48, 190.0, 265.0)
	toothbrush.size = Vector2(brush_w, brush_w / 3.0)
	toothbrush.pivot_offset = toothbrush.size * 0.5
	if not dragging:
		toothbrush.position = Vector2(
			minf(vs.x - toothbrush.size.x - 24.0, rect.end.x + 22.0),
			rect.position.y + rect.size.y * 0.67
		)
	face.visible = false
	progress_panel.visible = false
	_update_progress()

func begin_with_bubble(next_face: Node2D) -> void:
	stop()
	_bubble_face = next_face
	_session += 1
	var expected_session: int = _session
	# Bubble's existing jaw opening animation takes 0.55 s.
	# Capture the masks only AFTER their final positions are reached.
	await get_tree().create_timer(0.60).timeout
	if expected_session != _session or not is_instance_valid(_bubble_face):
		return
	_layout()
	if not _prepare_bubble_plaque():
		push_error("MIKA embedded teeth: failed to compose Bubble plaque masks")
		return
	progress = 0.0
	plaque_removed_alpha = 0.0
	_last_log_bucket = -1
	active = true
	ready_to_brush = true
	dragging = false
	visible = true
	dim.visible = false
	face.visible = false
	plaque.visible = true
	toothbrush.visible = true
	toothbrush.rotation = 0.0
	progress_panel.visible = false
	_update_progress()
	print("[MIKA PLAYTOWN TEETH v8.5.9.8] READY — native embedded learning module input and eraser; pixels=", snappedf(plaque_initial_alpha, 1.0), " face_rect=", face.position, "/", face.size)

func _prepare_bubble_plaque() -> bool:
	var image: Image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var raw: Variant = _bubble_face.get("_plaque_layers")
	if not (raw is Array):
		return false
	var rect: Rect2 = _bubble_face_rect()
	if rect.size.x <= 0.1 or rect.size.y <= 0.1:
		return false
	_original_masks.clear()
	var count: int = 0
	for item in raw:
		if not (item is Dictionary):
			continue
		var node: Sprite2D = item.get("node") as Sprite2D
		var source: Image = item.get("base") as Image
		if not is_instance_valid(node) or source == null:
			continue
		var xf: Transform2D = node.get_global_transform_with_canvas()
		var size: Vector2 = Vector2(source.get_width(), source.get_height())
		for sy in range(source.get_height()):
			for sx in range(source.get_width()):
				var color: Color = source.get_pixel(sx, sy)
				if color.a <= 0.015:
					continue
				var screen: Vector2 = xf * (Vector2(float(sx), float(sy)) - size * 0.5)
				var px: int = int(round((screen.x - rect.position.x) / rect.size.x * float(TEXTURE_SIZE)))
				var py: int = int(round((screen.y - rect.position.y) / rect.size.y * float(TEXTURE_SIZE)))
				# Fill the cell area of the projected source pixel, avoiding gaps.
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						var tx: int = px + ox
						var ty: int = py + oy
						if tx < 0 or ty < 0 or tx >= TEXTURE_SIZE or ty >= TEXTURE_SIZE:
							continue
						if color.a > image.get_pixel(tx, ty).a:
							image.set_pixel(tx, ty, color)
		_original_masks.append(node)
		count += 1
	if count == 0:
		return false
	plaque_initial_alpha = 0.0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			plaque_initial_alpha += image.get_pixel(x, y).a
	if plaque_initial_alpha <= 0.1:
		return false
	plaque_image = image
	plaque_texture = ImageTexture.create_from_image(plaque_image)
	plaque.texture = plaque_texture
	# Only the single embedded learning module plaque remains visible, not duplicated masks.
	for mask in _original_masks:
		if is_instance_valid(mask):
			mask.visible = false
	print("[MIKA PLAYTOWN TEETH v8.5.9.8] COMPOSITE masks=", count, " plaque_alpha=", snappedf(plaque_initial_alpha, 1.0))
	return true

func _update_progress() -> void:
	super._update_progress() # Exactly the embedded learning module progress update.
	if active:
		progress_changed.emit(progress)
		var bucket: int = int(floor(progress * 10.0))
		if bucket > _last_log_bucket:
			_last_log_bucket = bucket
			print("[MIKA PLAYTOWN TEETH v8.5.9.8] ERASED ", snappedf(plaque_removed_alpha, 1.0), " / ", snappedf(plaque_initial_alpha, 1.0), " progress=", snappedf(progress * 100.0, 1.0), "%")

func _finish() -> void:
	# Original embedded learning module _erase_plaque() calls this when 92% is cleaned.
	# Keep MIKA's existing completion animation, not the dog's face frames.
	if not active or not ready_to_brush:
		return
	ready_to_brush = false
	dragging = false
	progress = 1.0
	_update_progress()
	active = false
	completed.emit() # Existing Bubble care controller handles the rest.

func stop(keep_clean: bool = false) -> void:
	_session += 1 # Cancel any pending jaw-open coroutine.
	active = false
	ready_to_brush = false
	dragging = false
	visible = false
	if is_instance_valid(toothbrush):
		toothbrush.visible = false
	if is_instance_valid(plaque):
		plaque.visible = false
	for mask in _original_masks:
		if is_instance_valid(mask):
			mask.visible = not keep_clean
	_original_masks.clear()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		_debug_contact = not _debug_contact
		queue_redraw()
		print("[MIKA PLAYTOWN TEETH v8.5.9.8] F8 contact=", _debug_contact)

func _process(_delta: float) -> void:
	if _debug_contact and ready_to_brush:
		queue_redraw()

func _draw() -> void:
	if not _debug_contact or not ready_to_brush:
		return
	var pt: Vector2 = _brush_contact_point()
	draw_arc(pt, 17.0, 0.0, TAU, 32, Color(0.18, 1.0, 0.35), 2.0)
	draw_line(pt - Vector2(12, 0), pt + Vector2(12, 0), Color(0.18, 1.0, 0.35), 1.5)
	draw_line(pt - Vector2(0, 12), pt + Vector2(0, 12), Color(0.18, 1.0, 0.35), 1.5)
