extends "res://learning/src/features/counting/mika_count_trace_native_v2_1_trace_style.gd"
## Write a Number v2.2 — all two-digit numerals fit in the right-hand
## drawing lane, outside the equals sign. The stage's responsive transform,
## native paths, input hit testing, TTS and rewards remain unchanged.

var _mika_two_digit_rest_scale: Vector2 = Vector2.ONE

func _build_digits(text: String) -> void:
	# Retain the original stroke/point/recognition generation, including the
	# approved neon tracing style from v2.1.
	super._build_digits(text)
	if text.length() <= 1:
		# Base _load_round() resets scale but not position. Reset both when
		# wrapping from 20 to 1 or when switching back to a single digit.
		letter_root.position = DIGIT_CENTER
		letter_root.scale = Vector2.ONE
		_mika_two_digit_rest_scale = Vector2.ONE
		return

	# Compute the visible RIGHT edge of the actual = sign, including the
	# thick outline. These are stage-local coordinates before responsive UI
	# scaling, so this works at every display resolution and aspect ratio.
	var equals_right: float = EQUALS_CENTER.x
	for child in product_root.get_children():
		if child is Line2D:
			var line: Line2D = child as Line2D
			for point in line.points:
				equals_right = maxf(equals_right, point.x + line.width * 0.5)

	var stage_width: float = MIKA_TRACE_STAGE_BOUNDS.size.x
	var safety_gap: float = stage_width * 0.025
	var right_inset: float = stage_width * 0.015
	var lane_left: float = equals_right + safety_gap
	var lane_right: float = MIKA_TRACE_STAGE_BOUNDS.end.x - right_inset
	var lane_width: float = maxf(1.0, lane_right - lane_left)

	# Base _build_digits constructs a 330-unit double-digit group. Scale
	# both dimensions uniformly (not a stretched digit), and recenter it
	# within the safe lane. This also scales the actual touch coordinates
	# because input uses letter_root.to_local().
	var count: int = text.length()
	var glyph_w: float = minf(MAX_DIGIT_W, DIGIT_AREA_W / (float(count) + GAP_RATIO * float(count - 1)))
	var group_width: float = glyph_w * (float(count) + GAP_RATIO * float(count - 1))
	var factor: float = minf(1.0, lane_width / maxf(group_width, 1.0))
	_mika_two_digit_rest_scale = Vector2.ONE * factor
	letter_root.scale = _mika_two_digit_rest_scale
	letter_root.position = Vector2(lane_left + lane_width * 0.5, DIGIT_CENTER.y)

func _finish_number() -> void:
	var completed_two_digits: bool = str(_current_number()).length() > 1
	var normal_scale: Vector2 = _mika_two_digit_rest_scale
	super._finish_number()
	if not completed_two_digits or celebrate_tween == null:
		return
	# The legacy success tween scales every numeral back to 1.0, which
	# momentarily breaks the new two-digit safety gap. Preserve the fitted
	# scale throughout celebration before switching to the next number.
	celebrate_tween.kill()
	celebrate_tween = create_tween()
	celebrate_tween.tween_interval(0.9)
	celebrate_tween.tween_property(letter_root, "scale", normal_scale * 1.04, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	celebrate_tween.tween_property(letter_root, "scale", normal_scale, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	celebrate_tween.tween_callback(_advance_round)

func _ready() -> void:
	super._ready()
	set_meta("mika_write_number_version", "v2.2-two-digit-clear-equals")
	print("[MIKA WRITE NUMBER v2.2] TWO-DIGIT EQUALS SPACING active: ", scene_file_path)
