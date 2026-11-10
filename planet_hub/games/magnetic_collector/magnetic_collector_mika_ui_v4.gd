extends "res://planet_hub/games/magnetic_collector/magnetic_collector_mika_ui_v3.gd"
## Magnetic Collector v4
## Restores the original header proportions and flight joystick size from the
## approved shared-UI games, while keeping v3 gameplay, sounds and safe logic.
## Adds the user-approved planetary background inside the main game block.

const STAGE_BG := preload("res://planet_hub/games/magnetic_collector/backgrounds_v4/magnetic_collector_stage_bg.png")
const BOARD := Rect2(29.0, 121.0, 1222.0, 580.0)
const CONTROL_TINT := Rect2(34.0, 588.0, 1212.0, 104.0)
const LEFT_STICK_CENTER := Vector2(171.0, 604.0)
const RIGHT_STICK_CENTER := Vector2(1103.0, 604.0)


func _layout_ui() -> void:
	super._layout_ui()
	if _v2_title_panel == null or _v2_counter_clip == null or _v2_back == null:
		return
	var view: Vector2 = size if size.x > 100.0 and size.y > 100.0 else get_viewport_rect().size
	_v3_safe = _v3_safe_rect(view)
	# Match the original shared toolbar sizing used in other mini-games.
	var sw: float = _v3_safe.size.x
	var sh: float = _v3_safe.size.y
	var scale_unit: float = minf(view.x / 1680.0, view.y / 864.0)
	var margin: float = clampf(sw * 0.018, 5.0, 28.0)
	var gap: float = clampf(sw * 0.015, 5.0, 22.0)
	var minimum_title: float = minf(260.0 * scale_unit, sw * 0.32)
	var required: float = 158.0 * 0.60 + 394.0 * 0.80 + minimum_title / maxf(scale_unit, 0.01)
	var width_limit: float = maxf(0.08, (sw - 2.0 * margin - 2.0 * gap) / required)
	var s: float = minf(scale_unit, width_limit)
	var counter_scale: float = s * 0.80
	var back_size: float = s * 158.0 * 0.60
	var counter_h: float = s * 158.0 * 0.80
	var counter_w: float = s * 394.0 * 0.80
	var top: float = _v3_safe.position.y + clampf(sh * 0.022, 5.0, 22.0)
	var left: float = _v3_safe.position.x + margin
	var right: float = _v3_safe.end.x - margin
	var counter_left: float = right - counter_w
	var title_left: float = left + back_size + gap
	var title_right: float = counter_left - gap
	var title_width: float = maxf(32.0, title_right - title_left)

	_v2_back.position = Vector2(left, top + (counter_h - back_size) * 0.5)
	_v2_back.size = Vector2.ONE * back_size
	_v2_title_panel.position = Vector2(title_left, top)
	_v2_title_panel.size = Vector2(title_width, counter_h)
	_v2_title.position = Vector2(6.0, counter_h * 0.055)
	_v2_title.size = Vector2(maxf(26.0, title_width - 12.0), counter_h * 0.60)
	_v2_subtitle.position = Vector2(6.0, counter_h * 0.66)
	_v2_subtitle.size = Vector2(maxf(26.0, title_width - 12.0), counter_h * 0.28)
	_v2_subtitle.visible = title_width >= 170.0
	_v2_counter_clip.position = Vector2(counter_left, top)
	_v2_counter_clip.size = Vector2(counter_w, counter_h)
	_v2_counter.size = Vector2(1680.0, 158.0)
	_v2_counter.scale = Vector2.ONE * counter_scale
	_v2_counter.position = Vector2(-643.0 * counter_scale, 0.0)

	# Restore the original on-board proportions used by the first shared-UI build.
	if _v3_left_stick != null:
		_v3_left_stick.scale = Vector2.ONE * _scale_factor
		_v3_left_stick.position = _origin + (LEFT_STICK_CENTER - Vector2(92.0, 92.0)) * _scale_factor
	if _v3_right_stick != null:
		_v3_right_stick.scale = Vector2.ONE * _scale_factor
		_v3_right_stick.position = _origin + (RIGHT_STICK_CENTER - Vector2(92.0, 92.0)) * _scale_factor

	_place(_grab_button, Rect2(516.0, 598.0, 248.0, 72.0))
	_grab_button.z_index = 16
	_grab_button.add_theme_font_size_override("font_size", maxi(12, roundi(24.0 * _scale_factor)))
	_place(_feedback, Rect2(335.0, 550.0, 859.0, 33.0))
	_feedback.add_theme_font_size_override("font_size", maxi(11, roundi(18.0 * _scale_factor)))
	_v2_update_title()
	queue_redraw()


func _draw() -> void:
	var display: Vector2 = size if size.x > 100.0 and size.y > 100.0 else get_viewport_rect().size
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(display.x / 1280.0, display.y / 720.0))
	draw_rect(Rect2(Vector2.ZERO, DESIGN), Color("061428"))
	# The whole interactive area stays as one block, now with the supplied planet art.
	if STAGE_BG != null:
		draw_texture_rect(STAGE_BG, BOARD, false, Color.WHITE)
	# Soft dark tint keeps gameplay readable over the art.
	draw_rect(BOARD, Color(0.02, 0.08, 0.16, 0.12))
	_panel(BOARD, Color(0.0, 0.0, 0.0, 0.0), Color("65e7ff"), 29, 3)
	# Keep the bottom strip requested by the user, but inside the same gameplay block.
	draw_rect(CONTROL_TINT, Color(0.05, 0.16, 0.29, 0.32))
	for i in range(12):
		var x := 48.0 + 103.0 * float(i)
		draw_line(Vector2(x, 579.0), Vector2(x + 24.0, 579.0), Color(0.38, 0.81, 1.0, 0.18), 2.0)
	_draw_v2_rail()
	_draw_v2_bin()
	_draw_ground_items()
	_draw_magnet()
	_draw_sparks()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
