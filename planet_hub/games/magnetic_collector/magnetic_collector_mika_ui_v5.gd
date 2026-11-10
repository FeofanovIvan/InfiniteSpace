extends "res://planet_hub/games/magnetic_collector/magnetic_collector_mika_ui_v4.gd"
## MIKA / Magnetic Collector v5 -- responsive rounded gameplay panel.
## The gameplay canvas and image use the same safe panel. The picture is cropped
## to COVER that panel without changing its size; the rounded mask is a shader.
## Joysticks use the same 184x184 flight control, moved to the bottom corners.

const V5_STAGE_SHADER = preload("res://planet_hub/games/magnetic_collector/stage_cover_rounded_v5.gdshader")
const V5_RADIUS := 26.0

var _v5_panel: Rect2 = Rect2(Vector2(32.0, 130.0), Vector2(1216.0, 558.0))
var _v5_scale := Vector2.ONE
var _v5_canvas_origin := Vector2.ZERO
var _v5_bg: ColorRect
var _v5_bg_material: ShaderMaterial
var _v5_outline: StyleBoxFlat


func _ready() -> void:
	super._ready()
	_v5_bg = ColorRect.new()
	_v5_bg.name = "RoundedCoverBackground"
	_v5_bg.color = Color.WHITE
	_v5_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_v5_bg.z_index = -1
	_v5_bg_material = ShaderMaterial.new()
	_v5_bg_material.shader = V5_STAGE_SHADER
	_v5_bg_material.set_shader_parameter("stage_texture", STAGE_BG)
	_v5_bg_material.set_shader_parameter("source_size", Vector2(STAGE_BG.get_width(), STAGE_BG.get_height()))
	_v5_bg.material = _v5_bg_material
	add_child(_v5_bg)
	_v5_outline = StyleBoxFlat.new()
	_v5_outline.draw_center = false
	_v5_outline.border_color = Color("65e7ff")
	_v5_outline.set_border_width_all(3)
	_v5_outline.set_corner_radius_all(roundi(V5_RADIUS))
	_v5_outline.anti_aliasing = true
	_v5_outline.anti_aliasing_size = 1.0
	_layout_ui()


func _layout_ui() -> void:
	# Inherit the exact approved shared toolbar from v4. Override ONLY the
	# gameplay panel and its related controls, not header/back/counter geometry.
	super._layout_ui()
	if _v2_title_panel == null or _v3_left_stick == null or _v3_right_stick == null:
		return
	var view: Vector2 = size if size.x > 100.0 and size.y > 100.0 else get_viewport_rect().size
	var safe: Rect2 = _v3_safe_rect(view)
	_v3_safe = safe
	var horizontal_gap: float = clampf(safe.size.x * 0.012, 5.0, 20.0)
	var vertical_gap: float = clampf(safe.size.y * 0.015, 6.0, 18.0)
	var game_top: float = _v2_title_panel.position.y + _v2_title_panel.size.y + vertical_gap
	var game_bottom: float = safe.end.y - vertical_gap
	var game_left: float = safe.position.x + horizontal_gap
	var game_right: float = safe.end.x - horizontal_gap
	_v5_panel = Rect2(Vector2(game_left, game_top),
		Vector2(maxf(120.0, game_right - game_left), maxf(110.0, game_bottom - game_top)))

	# Map the original gameplay's logical 1222x580 board to the panel, not the
	# entire display. This keeps magnet, rails, objects and bin in registration.
	_v5_scale = Vector2(_v5_panel.size.x / BOARD.size.x, _v5_panel.size.y / BOARD.size.y)
	_v5_canvas_origin = _v5_panel.position - BOARD.position * _v5_scale
	if _v5_bg != null:
		_v5_bg.position = _v5_panel.position
		_v5_bg.size = _v5_panel.size
		_v5_bg_material.set_shader_parameter("panel_size", _v5_panel.size)
		_v5_bg_material.set_shader_parameter("corner_radius", V5_RADIUS)

	# Native flight stick: design size 184px. Preserve the reference size at
	# 1280x720, scale only when a smaller panel physically requires it.
	var native_scale: float = minf(view.x / 1280.0, view.y / 720.0)
	var available_scale: float = minf(_v5_panel.size.y * 0.46 / 184.0, _v5_panel.size.x * 0.26 / 184.0)
	var stick_scale: float = minf(native_scale, available_scale)
	var stick_width: float = 184.0 * stick_scale
	var stick_inset: float = clampf(_v5_panel.size.x * 0.009, 5.0, 14.0)
	var stick_bottom: float = clampf(_v5_panel.size.y * 0.014, 5.0, 12.0)
	_v3_left_stick.scale = Vector2.ONE * stick_scale
	_v3_right_stick.scale = Vector2.ONE * stick_scale
	_v3_left_stick.position = Vector2(_v5_panel.position.x + stick_inset,
		_v5_panel.end.y - stick_bottom - stick_width)
	_v3_right_stick.position = Vector2(_v5_panel.end.x - stick_inset - stick_width,
		_v5_panel.end.y - stick_bottom - stick_width)

	# Keep the magnet button between the sticks and inside the panel at all
	# tested ratios; its size follows panel height, not the background picture.
	var button_h: float = clampf(_v5_panel.size.y * (72.0 / 580.0), 31.0, 76.0)
	var button_w: float = minf(_v5_panel.size.x * 0.30, maxf(120.0, 248.0 * native_scale))
	_grab_button.scale = Vector2.ONE
	_grab_button.position = Vector2(_v5_panel.get_center().x - button_w * 0.5,
		_v5_panel.end.y - stick_bottom - (stick_width + button_h) * 0.5)
	_grab_button.size = Vector2(button_w, button_h)
	_grab_button.add_theme_font_size_override("font_size", maxi(11, roundi(24.0 * minf(native_scale, 1.0))))
	_feedback.scale = Vector2.ONE
	_feedback.position = Vector2(_v5_panel.position.x + _v5_panel.size.x * 0.31,
		_v5_panel.position.y + _v5_panel.size.y * 0.735)
	_feedback.size = Vector2(_v5_panel.size.x * 0.38, _v5_panel.size.y * 0.045)
	_feedback.add_theme_font_size_override("font_size", maxi(9, roundi(18.0 * minf(native_scale, 1.0))))
	queue_redraw()


func _draw() -> void:
	# The shader-painted background is a child at z_index -1, behind this draw.
	# Paint only OUTSIDE the panel; never place an opaque surface over the image.
	var view: Vector2 = size if size.x > 100.0 and size.y > 100.0 else get_viewport_rect().size
	var p: Rect2 = _v5_panel
	var dark := Color("061428")
	draw_rect(Rect2(0.0, 0.0, view.x, p.position.y), dark)
	draw_rect(Rect2(0.0, p.position.y, p.position.x, p.size.y), dark)
	draw_rect(Rect2(p.end.x, p.position.y, maxf(0.0, view.x - p.end.x), p.size.y), dark)
	draw_rect(Rect2(0.0, p.end.y, view.x, maxf(0.0, view.y - p.end.y)), dark)

	# Gameplay stays aligned to the actual responsive board, regardless of crop.
	draw_set_transform(_v5_canvas_origin, 0.0, _v5_scale)
	# A subtle lower control tint remains INSIDE the same rounded block.
	draw_rect(Rect2(BOARD.position.x + 13.0, 590.0,
		BOARD.size.x - 26.0, 97.0), Color(0.05, 0.16, 0.29, 0.27))
	for i in range(12):
		var x: float = 48.0 + 103.0 * float(i)
		draw_line(Vector2(x, 579.0), Vector2(x + 24.0, 579.0), Color(0.38, 0.81, 1.0, 0.18), 2.0)
	_draw_v2_rail()
	_draw_v2_bin()
	_draw_ground_items()
	_draw_magnet()
	_draw_sparks()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The outline has precisely the same radius and rect as the shader mask.
	if _v5_outline != null:
		draw_style_box(_v5_outline, p)
