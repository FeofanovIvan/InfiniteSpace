extends "res://education/playtown/src/features/tracing/mika_shape_build_native_v1.gd"
## v1.1: larger square papers and vertical pencil tray.

const WHITE_GRID_V11 := preload("res://education/playtown/src/features/tracing/mika_shape_paper_grid_v1_1.gd")

func _build_panels() -> void:
	sample_grid = WHITE_GRID_V11.new()
	sample_grid.name = "ExampleOnWhiteSquaredPaper"
	sample_grid.interactive = false
	sample_grid.z_index = 5
	add_child(sample_grid)
	draw_grid = WHITE_GRID_V11.new()
	draw_grid.name = "DrawOnWhiteSquaredPaper"
	draw_grid.interactive = true
	draw_grid.z_index = 5
	draw_grid.edge_attempt.connect(_on_edge_attempt)
	draw_grid.interaction_started.connect(_on_user_interaction_started)
	draw_grid.coloring_completed.connect(_on_coloring_completed)
	add_child(draw_grid)

func _pencil_bar_style() -> StyleBoxFlat:
	return _panel_skin(Color(0.07, 0.19, 0.39, 0.88), Color("#72dfff"), 22, Color(0.24, 0.60, 1.0, 0.34))

func _layout() -> void:
	if _mika_top_root == null or sample_grid == null or draw_grid == null:
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 120.0 or view.y < 160.0:
		return
	var safe: Rect2 = _safe_rect()
	_mika_top_root.size = view
	bg.size = view
	_mika_sky.size = view
	_mika_nebula.size = view
	var header_bottom: float = SHAPE_TOOLBAR.relayout(view, safe, _mika_back, _mika_hub, _mika_heading, _mika_title, _mika_subtitle)
	var sw: float = safe.size.x
	var sh: float = safe.size.y
	var pad: float = clampf(sw * 0.018, 8.0, 24.0)
	var body_top: float = header_bottom + clampf(sh * 0.018, 8.0, 18.0)
	var body_bottom: float = safe.end.y - pad
	card.position = Vector2(safe.position.x + pad, body_top)
	card.size = Vector2(sw - 2.0 * pad, maxf(170.0, body_bottom - body_top))
	var center_x: float = safe.position.x + sw * 0.5
	var nav_h: float = clampf(sh * 0.080, 34.0, 58.0)
	var nav_y: float = body_top + clampf(sh * 0.014, 6.0, 14.0)
	var title_w: float = minf(sw * 0.30, 380.0)
	var arrow_size: float = nav_h
	var nav_gap: float = clampf(sw * 0.012, 6.0, 16.0)
	title_tab.position = Vector2(center_x - title_w * 0.5, nav_y)
	title_tab.size = Vector2(title_w, nav_h)
	title_label.add_theme_font_size_override("font_size", maxi(11, roundi(nav_h * 0.44)))
	_mika_prev.position = Vector2(title_tab.position.x - arrow_size - nav_gap, nav_y)
	_mika_prev.size = Vector2.ONE * arrow_size
	_mika_next.position = Vector2(title_tab.position.x + title_w + nav_gap, nav_y)
	_mika_next.size = Vector2.ONE * arrow_size
	for btn in [_mika_prev, _mika_next]:
		btn.add_theme_font_size_override("font_size", maxi(14, roundi(nav_h * 0.60)))

	var content_top: float = nav_y + nav_h + clampf(sh * 0.018, 10.0, 18.0)
	var content_bottom: float = body_bottom - clampf(sh * 0.018, 10.0, 18.0)
	var available_h: float = maxf(120.0, content_bottom - content_top)
	var inner_pad: float = clampf(sw * 0.012, 8.0, 16.0)
	var panel_gap: float = clampf(sw * 0.020, 10.0, 22.0)
	var tray_w: float = clampf(sw * 0.085, 76.0, 108.0)
	var total_content_w: float = card.size.x - inner_pad * 2.0
	var sheet_size: float = minf(available_h, (total_content_w - tray_w - panel_gap * 2.0) / 2.0)
	if sheet_size < 100.0:
		sheet_size = 100.0
	var content_w_used: float = sheet_size * 2.0 + tray_w + panel_gap * 2.0
	var start_x: float = safe.position.x + sw * 0.5 - content_w_used * 0.5
	var grid_y: float = content_top + maxf(0.0, (available_h - sheet_size) * 0.5)
	var sample_rect := Rect2(Vector2(start_x, grid_y), Vector2.ONE * sheet_size)
	var draw_rect := Rect2(Vector2(start_x + sheet_size + panel_gap, grid_y), Vector2.ONE * sheet_size)
	var tray_rect := Rect2(Vector2(draw_rect.position.x + sheet_size + panel_gap, grid_y), Vector2(tray_w, sheet_size))

	_mika_sample_sheet.position = sample_rect.position
	_mika_sample_sheet.size = sample_rect.size
	_mika_draw_sheet.position = draw_rect.position
	_mika_draw_sheet.size = draw_rect.size
	sample_grid.set_layout(sample_rect)
	draw_grid.set_layout(draw_rect)

	pencil_bar.position = tray_rect.position
	pencil_bar.size = tray_rect.size
	var tray_pad: float = clampf(tray_rect.size.x * 0.12, 6.0, 12.0)
	var item_gap: float = clampf(tray_rect.size.y * 0.012, 3.0, 8.0)
	var item_h: float = maxf(20.0, (tray_rect.size.y - tray_pad * 2.0 - item_gap * 6.0) / 7.0)
	for i in range(pencil_cards.size()):
		var holder: Panel = pencil_cards[i]
		holder.position = Vector2(tray_pad, tray_pad + float(i) * (item_h + item_gap))
		holder.size = Vector2(tray_rect.size.x - tray_pad * 2.0, item_h)
		pencil_buttons[i].position = Vector2.ONE * 3.0
		pencil_buttons[i].size = holder.size - Vector2.ONE * 6.0
