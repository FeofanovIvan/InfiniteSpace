extends "res://education/playtown/src/features/tracing/mika_shape_build_native_v1_1.gd"
## MIKA Build Shapes 1.2 — proportional, safe-area-aware responsive layout.
## Reuses all existing gameplay and original audio. Only paper rendering and
## geometry are replaced; neon floating panels are removed above the paper.

const RESPONSIVE_WHITE_PAPER := preload("res://education/playtown/src/features/tracing/mika_shape_paper_grid_v1_2.gd")

func _build_background() -> void:
	super._build_background()
	# The v1 translucent neon frames/shadows float OVER the actual paper and
	# tint it blue. Remove them, rather than trying to make their alpha smaller.
	if _mika_sample_sheet != null:
		_mika_sample_sheet.hide()
		_mika_sample_sheet.queue_free()
		_mika_sample_sheet = null
	if _mika_draw_sheet != null:
		_mika_draw_sheet.hide()
		_mika_draw_sheet.queue_free()
		_mika_draw_sheet = null

func _build_panels() -> void:
	sample_grid = RESPONSIVE_WHITE_PAPER.new()
	sample_grid.name = "SampleWhiteSquareNoOverlay"
	sample_grid.interactive = false
	sample_grid.z_index = 5
	add_child(sample_grid)

	draw_grid = RESPONSIVE_WHITE_PAPER.new()
	draw_grid.name = "DrawWhiteSquareNoOverlay"
	draw_grid.interactive = true
	draw_grid.z_index = 5
	draw_grid.edge_attempt.connect(_on_edge_attempt)
	draw_grid.interaction_started.connect(_on_user_interaction_started)
	draw_grid.coloring_completed.connect(_on_coloring_completed)
	add_child(draw_grid)

func _safe_rect() -> Rect2:
	var safe: Rect2 = super._safe_rect()
	var view: Vector2 = get_viewport_rect().size
	if OS.get_name() == "Android":
		# Some fullscreen Android navigation bars report the FULL display as
		# safe. The percentage fallback reserves the overlay on those devices.
		if view.x >= view.y and view.x - safe.end.x < view.x * 0.025:
			safe.size.x = maxf(1.0, safe.size.x - view.x * 0.065)
		elif view.y > view.x and view.y - safe.end.y < view.y * 0.025:
			safe.size.y = maxf(1.0, safe.size.y - view.y * 0.052)
	return safe

func _layout() -> void:
	if _mika_top_root == null or sample_grid == null or draw_grid == null:
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x <= 0.0 or view.y <= 0.0:
		return
	var safe: Rect2 = _safe_rect()
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return

	_mika_top_root.size = view
	bg.position = Vector2.ZERO
	bg.size = view
	_mika_sky.size = view
	_mika_nebula.size = view
	var header_bottom: float = SHAPE_TOOLBAR.relayout(view, safe, _mika_back, _mika_hub, _mika_heading, _mika_title, _mika_subtitle)

	# ALL layout distances below are ratios of the AVAILABLE safe region or
	# current container. No fixed minimum square size can cause overflow.
	var outer_x: float = safe.size.x * 0.018
	var outer_y: float = safe.size.y * 0.018
	var card_top: float = header_bottom + outer_y
	var card_bottom: float = safe.end.y - outer_y
	var card_w: float = safe.size.x - 2.0 * outer_x
	var card_h: float = maxf(1.0, card_bottom - card_top)
	card.position = Vector2(safe.position.x + outer_x, card_top)
	card.size = Vector2(card_w, card_h)

	var nav_padding_y: float = card_h * 0.022
	var nav_h: float = minf(card_h * 0.115, card_w * 0.075)
	var nav_y: float = card_top + nav_padding_y
	var nav_gap: float = card_w * 0.013
	var title_w: float = card_w * 0.33
	var nav_total_w: float = title_w + 2.0 * nav_h + 2.0 * nav_gap
	var nav_start: float = card.position.x + (card_w - nav_total_w) * 0.5
	_mika_prev.position = Vector2(nav_start, nav_y)
	_mika_prev.size = Vector2.ONE * nav_h
	title_tab.position = Vector2(nav_start + nav_h + nav_gap, nav_y)
	title_tab.size = Vector2(title_w, nav_h)
	_mika_next.position = Vector2(title_tab.position.x + title_w + nav_gap, nav_y)
	_mika_next.size = Vector2.ONE * nav_h
	title_label.add_theme_font_size_override("font_size", maxi(8, roundi(nav_h * 0.43)))
	for button in [_mika_prev, _mika_next]:
		button.add_theme_font_size_override("font_size", maxi(8, roundi(nav_h * 0.60)))

	var inner_x: float = card_w * 0.025
	var inner_y: float = card_h * 0.025
	var content_left: float = card.position.x + inner_x
	var content_right: float = card.position.x + card_w - inner_x
	var content_top: float = nav_y + nav_h + inner_y
	var content_bottom: float = card.position.y + card_h - inner_y
	var content_width: float = maxf(1.0, content_right - content_left)
	var content_height: float = maxf(1.0, content_bottom - content_top)
	var gap: float = content_width * 0.018
	var portrait: bool = safe.size.y > safe.size.x * 1.12
	var tray_w: float = content_width * (0.13 if portrait else 0.09)
	var sheet_side: float
	var first_position: Vector2
	var second_position: Vector2
	var tray_position: Vector2
	var tray_height: float

	if portrait:
		# Two full-size white squares STACKED; the pencils stay on the right.
		var available_sheet_w: float = content_width - tray_w - gap
		var available_sheet_h: float = (content_height - gap) * 0.5
		sheet_side = maxf(1.0, minf(available_sheet_w, available_sheet_h))
		var used_w: float = sheet_side + gap + tray_w
		var start_x: float = content_left + (content_width - used_w) * 0.5
		var used_h: float = sheet_side * 2.0 + gap
		var start_y: float = content_top + (content_height - used_h) * 0.5
		first_position = Vector2(start_x, start_y)
		second_position = Vector2(start_x, start_y + sheet_side + gap)
		tray_position = Vector2(start_x + sheet_side + gap, content_top + (content_height - sheet_side) * 0.5)
		tray_height = sheet_side
	else:
		# Two squares SIDE BY SIDE, with an independent vertical pencil tray.
		var available_sheet_w: float = (content_width - tray_w - 2.0 * gap) * 0.5
		sheet_side = maxf(1.0, minf(available_sheet_w, content_height))
		var used_w: float = sheet_side * 2.0 + tray_w + gap * 2.0
		var start_x: float = content_left + (content_width - used_w) * 0.5
		var start_y: float = content_top + (content_height - sheet_side) * 0.5
		first_position = Vector2(start_x, start_y)
		second_position = Vector2(start_x + sheet_side + gap, start_y)
		tray_position = Vector2(second_position.x + sheet_side + gap, start_y)
		tray_height = sheet_side

	var sample_rect := Rect2(first_position, Vector2.ONE * sheet_side)
	var draw_rect := Rect2(second_position, Vector2.ONE * sheet_side)
	# The grid owns the WHITE square; no additional panels are laid over it.
	sample_grid.set_layout(sample_rect)
	draw_grid.set_layout(draw_rect)

	# Space is reserved for pencils in BOTH stages so the papers never jump.
	pencil_bar.position = tray_position
	pencil_bar.size = Vector2(tray_w, tray_height)
	var tray_pad: float = tray_w * 0.095
	var item_gap: float = tray_height * 0.013
	var card_w_inner: float = tray_w - 2.0 * tray_pad
	var item_h: float = (tray_height - 2.0 * tray_pad - 6.0 * item_gap) / 7.0
	for i in range(pencil_cards.size()):
		var holder: Panel = pencil_cards[i]
		holder.position = Vector2(tray_pad, tray_pad + float(i) * (item_h + item_gap))
		holder.size = Vector2(card_w_inner, item_h)
		var inset_x: float = card_w_inner * 0.055
		var inset_y: float = item_h * 0.055
		pencil_buttons[i].position = Vector2(inset_x, inset_y)
		pencil_buttons[i].size = Vector2(card_w_inner - 2.0 * inset_x, item_h - 2.0 * inset_y)
