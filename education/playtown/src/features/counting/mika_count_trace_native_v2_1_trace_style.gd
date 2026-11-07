extends "res://education/playtown/src/features/counting/mika_count_trace_native_v2_20_tts.gd"
## MIKA Write a Number v2.1 — same composition as Pick Up a Number.
## No beige/white cards behind either the original product pictures or the
## number traces. Same neon line palette and animated trace checkpoints as
## approved Trace Letters / Trace Words, with only the forward round button.
## Keeps 1..20, original paths, responsive input, TTS and session rewards.

const MIKA_NUMBER_TRACE_HINTS := preload("res://education/playtown/src/features/tracing/mika_neon_trace_hints_v12.gd")

func _ready() -> void:
	super._ready()
	# The forward-only navigation is intentional; the native Back arrow in the
	# shared top toolbar remains present for returning to simulator cards.
	if is_instance_valid(_mika_trace_prev):
		_mika_trace_prev.hide()
		_mika_trace_prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Replace the gray original checkpoints by the exact brighter tracing
	# helper already used by Trace Letters / Trace Words (same path mathematics).
	if is_instance_valid(hint_drawer):
		var prior: Node2D = hint_drawer
		letter_root.remove_child(prior)
		prior.queue_free()
	hint_drawer = MIKA_NUMBER_TRACE_HINTS.new()
	hint_drawer.name = "SharedNeonNumberTraceHints"
	hint_drawer.game = self
	letter_root.add_child(hint_drawer)
	_update_dot_limit()
	hint_drawer.queue_redraw()
	if is_instance_valid(product_root):
		product_root.z_index = 4
	if is_instance_valid(letter_root):
		letter_root.z_index = 7
	_mika_trace_layout()
	set_meta("mika_write_number_version", "v2.1-pick-composition-trace-neon")
	print("[MIKA WRITE NUMBER v2.1] PICK STYLE + NEON TRACING active: ", scene_file_path)

func _mika_trace_add_sheets() -> void:
	# This is called from v1._ready() through virtual dispatch. Crucially do
	# NOT call super: it would recreate the unwanted cream/white rectangles.
	_mika_trace_product_sheet = null
	_mika_trace_digit_sheet = null

func _build_background() -> void:
	super._build_background()
	# Only the large, dark cyan-bordered base from Pick Up a Number remains.
	# All pictures, the equals sign and both digits draw DIRECTLY above it.
	if is_instance_valid(_mika_trace_body):
		_mika_trace_body.add_theme_stylebox_override(
			"panel", _mika_trace_style(Color(0.07, 0.17, 0.35, 0.84), Color("#55dfff"), 28)
		)

func _make_line(pts: PackedVector2Array, width: float, color: Color, z: int) -> Line2D:
	var line: Line2D = super._make_line(pts, width, color, z)
	line.antialiased = true
	line.round_precision = 24
	if z == -2:
		# Cyan edge as in Trace Letters and Trace Words.
		line.default_color = Color("#57dfff")
	elif z == -1:
		# Bright white guide, not the old beige trace card.
		line.default_color = Color("#e9faff")
	elif z == 1:
		# Smooth luminous cyan stroke that appears when the child traces it.
		line.default_color = Color("#78e5ff")
	return line

func _build_equals() -> void:
	super._build_equals()
	# Keep the original equals sign and its exact placement; only give it the
	# same cyan-edge/white-center treatment as the digits.
	for child in product_root.get_children():
		if child is Line2D:
			var stroke: Line2D = child as Line2D
			if stroke.points.size() == 2:
				stroke.default_color = Color("#57dfff") if stroke.width > 40.0 else Color("#effbff")
				stroke.antialiased = true
				stroke.round_precision = 24

func _mika_trace_layout() -> void:
	super._mika_trace_layout()
	if not _mika_trace_ready or not is_instance_valid(_mika_trace_stage):
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 120.0 or view.y < 140.0:
		return
	# Reuse the exact already-calculated responsive blue-body rectangle.
	# This avoids a second calculation that might diverge on iOS/Android.
	var body: Rect2 = Rect2(_mika_trace_body.position, _mika_trace_body.size)
	if body.size.x <= 90.0 or body.size.y <= 65.0:
		return
	var inset_x: float = body.size.x * 0.017
	var inset_y: float = body.size.y * 0.022
	var nav_w: float = body.size.x * 0.056
	# No reserved column for the removed Previous button. Keep the Next
	# button's original area, and center the remaining game content.
	var available: Rect2 = Rect2(
		body.position + Vector2(inset_x, inset_y),
		body.size - Vector2(inset_x * 2.0 + nav_w, inset_y * 2.0)
	)
	if available.size.x <= 0.0 or available.size.y <= 0.0:
		return
	var scale_factor: float = minf(
		available.size.x / MIKA_TRACE_STAGE_BOUNDS.size.x,
		available.size.y / MIKA_TRACE_STAGE_BOUNDS.size.y
	)
	var stage_size: Vector2 = MIKA_TRACE_STAGE_BOUNDS.size * scale_factor
	_mika_trace_stage.scale = Vector2.ONE * scale_factor
	_mika_trace_stage.position = available.position + (available.size - stage_size) * 0.5 - MIKA_TRACE_STAGE_BOUNDS.position * scale_factor
	if is_instance_valid(_mika_trace_prev):
		_mika_trace_prev.hide()
