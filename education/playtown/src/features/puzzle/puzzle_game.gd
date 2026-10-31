extends Node2D
const PIECES_DIR := "res://education/playtown/assets/puzzle/pieces"
const INFO_PANEL_TEXTURE := "res://education/playtown/assets/puzzle/ui/info_panel.png"
const TRAY_STRIP_TEXTURE := "res://education/playtown/assets/puzzle/ui/tray_strip.png"
const STAR_TEXTURE := "res://education/playtown/assets/ui/star.png"
const GOLD := Color(0.901961, 0.686275, 0.286275)
const GOLD_SHADOW := Color(0.709804, 0.505882, 0.14902)
const GOLD_OUTLINE := Color(0.85098, 0.631373, 0.231373)
const CORRECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const WRONG_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
const BEIGE_BG := Color(0.93, 0.87, 0.78)
const HUD_RESERVE_H := 124.0
const TRAY_HUD_GAP := 6.0
const SIDE_MARGIN_FRAC := 0.02
const TOP_MARGIN_FRAC := 0.03
const PANEL_WIDTH_FRAC := 0.27
const TRAY_HEIGHT_FRAC := 0.165
const GAP := 14.0
@export var back_scene_path: String = "res://education/playtown/scenes/screens/game_select_home.tscn"
const PANEL_PREVIEW_FRAC := Rect2(0.0487, 0.1875, 0.9026, 0.5625)
const PANEL_NAV_PREV_FRAC := Rect2(0.0885, 0.7779, 0.3526, 0.1537)
const PANEL_NAV_NEXT_FRAC := Rect2(0.5487, 0.7787, 0.3538, 0.1529)
const TRAY_CONTENT_FRAC := Rect2(0.1121, 0.05, 0.7745, 0.90)
const TRAY_ARROW_LEFT_CENTER_FRAC := Vector2(0.0718, 0.4628)
const TRAY_ARROW_RIGHT_CENTER_FRAC := Vector2(0.9265, 0.4628)
const TRAY_ARROW_SIZE_FRAC := Vector2(0.0792, 0.3784)
const BOARD_FILL_COLOR := Color(253.0 / 255.0, 233.0 / 255.0, 200.0 / 255.0)
const BOARD_BORDER_COLOR := Color(210.0 / 255.0, 160.0 / 255.0, 95.0 / 255.0)
const PUZZLES: Array[Dictionary] = [
	{"key": "kitten",         "name": "Kitten",            "rows": 3, "cols": 5},
	{"key": "amusement_park", "name": "Funfair",           "rows": 3, "cols": 4},
	{"key": "fire_truck",     "name": "Fire Truck",        "rows": 3, "cols": 4},
	{"key": "rocket",         "name": "Rocket",            "rows": 3, "cols": 4},
	{"key": "fish",           "name": "Underwater World",  "rows": 3, "cols": 4},
	{"key": "safari",         "name": "Safari",            "rows": 3, "cols": 4},
	{"key": "tractor",        "name": "Tractor",           "rows": 3, "cols": 4},
	{"key": "puppy",          "name": "Puppy",             "rows": 3, "cols": 5},
]
const PIECE_SCRIPT := preload("res://education/playtown/src/features/puzzle/puzzle_piece.gd")
const SLOT_SCRIPT := preload("res://education/playtown/src/features/puzzle/puzzle_slot.gd")
var bg_color_rect: ColorRect
var hud: CanvasLayer
var board_frame: Panel
var exit_button: Button
var score_label: Label
var star_pic: TextureRect
var preview_pic: TextureRect
var nav_prev: Button
var nav_next: Button
var info_panel_pic: TextureRect
var seams_pic: TextureRect
var board_area: Control
var board_grid: GridContainer
var tray_strip_pic: TextureRect
var tray_scroll: ScrollContainer
var tray_box: HBoxContainer
var arrow_left: Button
var arrow_right: Button
var drag_layer: Control
var sfx: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var current_puzzle_idx: int = 0
var current_rows: int = 3
var current_cols: int = 4
var current_aspect: float = 1.5
var ratio_w: float = 1.6
var ratio_h: float = 1.6
var slots: Array = []
var pieces: Array = []
var filled_count: int = 0
var score: int = 0
var game_over: bool = false
var info_panel_size: Vector2 = Vector2.ZERO
var tray_strip_size: Vector2 = Vector2.ZERO
func _ready() -> void:
	sfx = AudioStreamPlayer.new()
	sfx.bus = "SFX"
	add_child(sfx)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	_build_ui()
	current_puzzle_idx = randi() % PUZZLES.size()
	get_viewport().size_changed.connect(_layout)
	_load_puzzle(current_puzzle_idx)
	call_deferred("_play_instruction")
func _play_instruction() -> void:
	var stream := LanguageService.get_game_voice("puzzle_intro")
	if stream:
		voice_player.stream = stream
		voice_player.play()
func _build_ui() -> void:
	bg_color_rect = ColorRect.new()
	bg_color_rect.color = BEIGE_BG
	bg_color_rect.z_index = -10
	bg_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_color_rect)
	board_frame = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = BOARD_FILL_COLOR
	sb.border_color = BOARD_BORDER_COLOR
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(28)
	sb.shadow_color = Color(0.35, 0.22, 0.08, 0.18)
	sb.shadow_size = 10
	board_frame.add_theme_stylebox_override("panel", sb)
	board_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board_frame)
	seams_pic = TextureRect.new()
	seams_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seams_pic.stretch_mode = TextureRect.STRETCH_SCALE
	seams_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(seams_pic)
	board_area = Control.new()
	board_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board_area)
	board_grid = GridContainer.new()
	board_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_area.add_child(board_grid)
	info_panel_pic = TextureRect.new()
	if ResourceLoader.exists(INFO_PANEL_TEXTURE):
		var tex: Texture2D = load(INFO_PANEL_TEXTURE)
		info_panel_pic.texture = tex
		info_panel_size = Vector2(tex.get_width(), tex.get_height())
	info_panel_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_panel_pic.stretch_mode = TextureRect.STRETCH_SCALE
	info_panel_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info_panel_pic)
	preview_pic = TextureRect.new()
	preview_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview_pic)
	nav_prev = _make_hit_button()
	nav_prev.pressed.connect(_on_nav_prev)
	add_child(nav_prev)
	nav_next = _make_hit_button()
	nav_next.pressed.connect(_on_nav_next)
	add_child(nav_next)
	tray_strip_pic = TextureRect.new()
	if ResourceLoader.exists(TRAY_STRIP_TEXTURE):
		var ttex: Texture2D = load(TRAY_STRIP_TEXTURE)
		tray_strip_pic.texture = ttex
		tray_strip_size = Vector2(ttex.get_width(), ttex.get_height())
	tray_strip_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray_strip_pic.stretch_mode = TextureRect.STRETCH_SCALE
	tray_strip_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tray_strip_pic)
	tray_scroll = ScrollContainer.new()
	tray_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tray_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(tray_scroll)
	tray_box = HBoxContainer.new()
	tray_box.add_theme_constant_override("separation", 18)
	tray_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tray_scroll.add_child(tray_box)
	arrow_left = _make_hit_button()
	arrow_left.pressed.connect(_on_arrow_left)
	add_child(arrow_left)
	arrow_right = _make_hit_button()
	arrow_right.pressed.connect(_on_arrow_right)
	add_child(arrow_right)
	drag_layer = Control.new()
	drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_layer)
	hud = CanvasLayer.new()
	add_child(hud)
	exit_button = GameExitButton.new()
	exit_button.anchor_top = 1.0
	exit_button.anchor_bottom = 1.0
	exit_button.offset_left = 40.0
	exit_button.offset_right = 140.0
	exit_button.offset_top = -120.0
	exit_button.offset_bottom = -20.0
	exit_button.pressed.connect(_on_exit_pressed)
	hud.add_child(exit_button)
	var score_panel := GameScorePanel.new()
	score_panel.anchor_left = 1.0
	score_panel.anchor_right = 1.0
	score_panel.anchor_top = 1.0
	score_panel.anchor_bottom = 1.0
	score_panel.offset_left = -280.0
	score_panel.offset_right = -40.0
	score_panel.offset_top = -112.0
	score_panel.offset_bottom = -24.0
	hud.add_child(score_panel)
	star_pic = score_panel.score_icon
	score_label = score_panel.score_label
	_layout()
func _make_hit_button() -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var glow := ColorRect.new()
	glow.color = Color(1, 1, 1, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.name = "Glow"
	btn.add_child(glow)
	btn.button_down.connect(func():
		var tw := btn.create_tween()
		tw.set_parallel(true)
		tw.tween_property(glow, "color:a", 0.35, 0.06)
		tw.tween_property(btn, "scale", Vector2(0.93, 0.93), 0.06)
	)
	btn.button_up.connect(func():
		var tw := btn.create_tween()
		tw.set_parallel(true)
		tw.tween_property(glow, "color:a", 0.0, 0.18)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	return btn
func _on_exit_pressed() -> void:
	SFX.transition_to_scene(back_scene_path)
func _fit_by_width(img_size: Vector2, zone: Rect2) -> Rect2:
	if img_size.x <= 0.0 or img_size.y <= 0.0:
		return zone
	var scale: float = zone.size.x / img_size.x
	var rendered := img_size * scale
	return Rect2(
		zone.position + Vector2(0.0, (zone.size.y - rendered.y) * 0.5),
		rendered
	)
func _fit_by_height(img_size: Vector2, zone: Rect2) -> Rect2:
	if img_size.x <= 0.0 or img_size.y <= 0.0:
		return zone
	var scale: float = zone.size.y / img_size.y
	var rendered := img_size * scale
	return Rect2(
		zone.position + Vector2((zone.size.x - rendered.x) * 0.5, 0.0),
		rendered
	)
func _fit_contain(img_size: Vector2, zone: Rect2) -> Rect2:
	if img_size.x <= 0.0 or img_size.y <= 0.0:
		return zone
	var scale: float = minf(zone.size.x / img_size.x, zone.size.y / img_size.y)
	var rendered := img_size * scale
	return Rect2(
		zone.position + (zone.size - rendered) * 0.5,
		rendered
	)
func _sub_rect(outer: Rect2, frac: Rect2) -> Rect2:
	return Rect2(
		outer.position + frac.position * outer.size,
		frac.size * outer.size
	)
func _layout() -> void:
	var vs := get_viewport_rect().size
	bg_color_rect.position = Vector2.ZERO
	bg_color_rect.size = vs
	var side_margin: float = vs.x * SIDE_MARGIN_FRAC
	var top_margin: float = vs.y * TOP_MARGIN_FRAC
	var hud_top: float = vs.y - HUD_RESERVE_H
	var tray_avail_w: float = vs.x - side_margin * 2.0
	var tray_aspect: float = TRAY_HEIGHT_FRAC * 6.06
	if tray_strip_size.x > 0.0 and tray_strip_size.y > 0.0:
		tray_aspect = tray_strip_size.x / tray_strip_size.y
	var tray_w: float = tray_avail_w
	var tray_h: float = tray_w / tray_aspect
	var tray_h_cap: float = vs.y * 0.30
	if tray_h > tray_h_cap:
		tray_h = tray_h_cap
		tray_w = tray_h * tray_aspect
	var tray_x: float = side_margin + (tray_avail_w - tray_w) * 0.5
	var tray_zone := Rect2(
		tray_x, hud_top - TRAY_HUD_GAP - tray_h,
		tray_w, tray_h
	)
	var content_top: float = top_margin
	var content_bottom: float = tray_zone.position.y - GAP
	var content_h: float = maxf(content_bottom - content_top, 10.0)
	var panel_w: float = vs.x * PANEL_WIDTH_FRAC
	var board_zone := Rect2(
		side_margin, content_top,
		vs.x - side_margin * 2.0 - panel_w - GAP, content_h
	)
	var panel_zone := Rect2(
		board_zone.position.x + board_zone.size.x + GAP, content_top,
		panel_w, content_h
	)
	board_frame.position = board_zone.position
	board_frame.size = board_zone.size
	var board_margin: float = 0.93
	var board_avail_w: float = board_zone.size.x * board_margin
	var board_avail_h: float = board_zone.size.y * board_margin
	var limit_w: float = board_avail_w / (ratio_w + float(current_cols) - 1.0)
	var limit_h: float = board_avail_h / (ratio_h + float(current_rows) - 1.0)
	var cell_size: float = minf(limit_w, limit_h)
	cell_size = maxf(cell_size, 16.0)
	var piece_w: float = cell_size * ratio_w
	var piece_h: float = cell_size * ratio_h
	var sep_w: float = -(piece_w - cell_size)
	var sep_h: float = -(piece_h - cell_size)
	board_grid.columns = current_cols
	board_grid.add_theme_constant_override("h_separation", int(round(sep_w)))
	board_grid.add_theme_constant_override("v_separation", int(round(sep_h)))
	for slot in slots:
		slot.custom_minimum_size = Vector2(piece_w, piece_h)
	var board_w: float = cell_size * (ratio_w + float(current_cols) - 1.0)
	var board_h: float = cell_size * (ratio_h + float(current_rows) - 1.0)
	board_area.position = board_zone.position + (board_zone.size - Vector2(board_w, board_h)) * 0.5
	board_area.size = Vector2(board_w, board_h)
	board_grid.position = Vector2.ZERO
	board_grid.size = Vector2(board_w, board_h)
	var pad_w: float = (piece_w - cell_size) * 0.5
	var pad_h: float = (piece_h - cell_size) * 0.5
	var core_w: float = cell_size * float(current_cols)
	var core_h: float = cell_size * float(current_rows)
	seams_pic.position = board_area.position + Vector2(pad_w, pad_h)
	seams_pic.size = Vector2(core_w, core_h)
	var panel_rect := _fit_contain(info_panel_size, panel_zone)
	info_panel_pic.position = panel_rect.position
	info_panel_pic.size = panel_rect.size
	var preview_zone := _sub_rect(panel_rect, PANEL_PREVIEW_FRAC)
	var pv_inset: float = preview_zone.size.x * 0.06
	preview_pic.position = preview_zone.position + Vector2(pv_inset, pv_inset)
	preview_pic.size = preview_zone.size - Vector2(pv_inset, pv_inset) * 2.0
	_place_hit_button(nav_prev, _sub_rect(panel_rect, PANEL_NAV_PREV_FRAC))
	_place_hit_button(nav_next, _sub_rect(panel_rect, PANEL_NAV_NEXT_FRAC))
	var tray_rect := _fit_by_width(tray_strip_size, tray_zone)
	tray_strip_pic.position = tray_rect.position
	tray_strip_pic.size = tray_rect.size
	var tray_content := _sub_rect(tray_rect, TRAY_CONTENT_FRAC)
	var arrow_w: float = TRAY_ARROW_SIZE_FRAC.x * tray_rect.size.x
	var arrow_h: float = TRAY_ARROW_SIZE_FRAC.y * tray_rect.size.y
	var arrow_l_center: Vector2 = tray_rect.position + TRAY_ARROW_LEFT_CENTER_FRAC * tray_rect.size
	var arrow_r_center: Vector2 = tray_rect.position + TRAY_ARROW_RIGHT_CENTER_FRAC * tray_rect.size
	_place_hit_button(arrow_left, Rect2(arrow_l_center - Vector2(arrow_w, arrow_h) * 0.5, Vector2(arrow_w, arrow_h)))
	_place_hit_button(arrow_right, Rect2(arrow_r_center - Vector2(arrow_w, arrow_h) * 0.5, Vector2(arrow_w, arrow_h)))
	var scroll_margin: float = tray_content.size.x * 0.01
	tray_scroll.position = Vector2(tray_content.position.x + scroll_margin, tray_content.position.y)
	tray_scroll.size = Vector2(tray_content.size.x - scroll_margin * 2.0, tray_content.size.y)
	var hbar := tray_scroll.get_h_scroll_bar()
	if hbar:
		hbar.modulate = Color(1, 1, 1, 0)
	var tray_cell_size: float = minf(cell_size, (tray_scroll.size.y * 0.94) / ratio_h)
	tray_cell_size = maxf(tray_cell_size, 12.0)
	var tray_piece_w: float = tray_cell_size * ratio_w
	var tray_piece_h: float = tray_cell_size * ratio_h
	for piece in pieces:
		piece.custom_minimum_size = Vector2(tray_piece_w, tray_piece_h)
func _place_hit_button(btn: Button, zone: Rect2) -> void:
	btn.position = zone.position
	btn.size = zone.size
	btn.pivot_offset = zone.size * 0.5
	var glow: ColorRect = btn.get_node_or_null("Glow")
	if glow:
		glow.size = zone.size
func _on_nav_prev() -> void:
	var idx: int = (current_puzzle_idx - 1 + PUZZLES.size()) % PUZZLES.size()
	_load_puzzle(idx)
func _on_nav_next() -> void:
	var idx: int = (current_puzzle_idx + 1) % PUZZLES.size()
	_load_puzzle(idx)
func _pick_random_puzzle_excluding(exclude_idx: int) -> int:
	if PUZZLES.size() <= 1:
		return 0
	var idx: int = exclude_idx
	while idx == exclude_idx:
		idx = randi() % PUZZLES.size()
	return idx
func _load_puzzle(puzzle_idx: int) -> void:
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	for piece in pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	pieces.clear()
	filled_count = 0
	current_puzzle_idx = puzzle_idx
	var data: Dictionary = PUZZLES[puzzle_idx]
	var key: String = String(data["key"])
	current_rows = int(data["rows"])
	current_cols = int(data["cols"])
	var full_tex_path := "res://education/playtown/assets/puzzle/%s.jpg" % key
	var full_tex: Texture2D = load(full_tex_path)
	if full_tex == null:
		return
	current_aspect = float(full_tex.get_width()) / float(full_tex.get_height())
	var core_w_px: float = float(full_tex.get_width()) / float(current_cols)
	var core_h_px: float = float(full_tex.get_height()) / float(current_rows)
	preview_pic.texture = full_tex
	var seams_path := "%s/%s/seams.png" % [PIECES_DIR, key]
	if ResourceLoader.exists(seams_path):
		seams_pic.texture = load(seams_path)
	var first_piece_tex: Texture2D = null
	for row in range(current_rows):
		for col in range(current_cols):
			var idx: int = row * current_cols + col
			var piece_path := "%s/%s/%d_%d.png" % [PIECES_DIR, key, row, col]
			var piece_tex: Texture2D = load(piece_path)
			if piece_tex == null:
				continue
			if first_piece_tex == null:
				first_piece_tex = piece_tex
			var slot := Control.new()
			slot.set_script(SLOT_SCRIPT)
			board_grid.add_child(slot)
			slot.correct_id = idx
			slots.append(slot)
	if first_piece_tex != null:
		ratio_w = float(first_piece_tex.get_width()) / core_w_px
		ratio_h = float(first_piece_tex.get_height()) / core_h_px
	var ids: Array[int] = []
	for i in range(current_rows * current_cols):
		ids.append(i)
	ids.shuffle()
	for id in ids:
		var row: int = id / current_cols
		var col: int = id % current_cols
		var piece_path := "%s/%s/%d_%d.png" % [PIECES_DIR, key, row, col]
		var piece_tex: Texture2D = load(piece_path)
		if piece_tex == null:
			continue
		var piece := TextureRect.new()
		piece.set_script(PIECE_SCRIPT)
		tray_box.add_child(piece)
		piece.setup(id, piece_tex, tray_box, drag_layer)
		piece.drag_ended.connect(_on_piece_drag_ended)
		pieces.append(piece)
	tray_scroll.scroll_horizontal = 0
	_layout()
func _on_piece_drag_ended(piece) -> void:
	if game_over:
		return
	var center: Vector2 = piece.global_position + piece.size * 0.5
	var matched_slot = null
	for slot in slots:
		if is_instance_valid(slot) and not slot.filled:
			var r: Rect2 = Rect2(slot.global_position, slot.size)
			if r.has_point(center):
				matched_slot = slot
				break
	if matched_slot != null and matched_slot.correct_id == piece.piece_id:
		matched_slot.fill(piece.texture)
		piece.lock_into_slot()
		pieces.erase(piece)
		_play_sfx(CORRECT_SOUND)
		score += 1
		_update_score_label()
		GameState.add_coins(1)
		filled_count += 1
		if filled_count >= slots.size():
			_on_puzzle_complete()
	else:
		if matched_slot != null:
			_play_sfx(WRONG_SOUND)
			SFX.play_retry(get_viewport_rect().size * 0.5)
		piece.return_to_tray()
func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	sfx.stop()
	sfx.stream = stream
	sfx.play()
func _update_score_label() -> void:
	score_label.text = str(GameState.get_coin_balance())
	GameState.last_score = score
func _on_puzzle_complete() -> void:
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.9)
	var data: Dictionary = PUZZLES[current_puzzle_idx]
	var key: String = String(data["key"])
	var voice_path := "res://education/playtown/audio/sfx/puzzle/%s.ogg" % key
	if ResourceLoader.exists(voice_path):
		voice_player.stream = load(voice_path)
		voice_player.play()
	board_area.pivot_offset = board_area.size * 0.5
	var tw := create_tween()
	tw.tween_property(board_area, "scale", Vector2(1.05, 1.05), 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(board_area, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_interval(1.1)
	tw.tween_callback(func():
		_load_puzzle(_pick_random_puzzle_excluding(current_puzzle_idx))
	)
func _on_arrow_left() -> void:
	_scroll_tray_by(-260.0)
func _on_arrow_right() -> void:
	_scroll_tray_by(260.0)
func _scroll_tray_by(amount: float) -> void:
	var max_scroll: float = float(tray_scroll.get_h_scroll_bar().max_value - tray_scroll.size.x)
	max_scroll = maxf(max_scroll, 0.0)
	var target: float = clampf(float(tray_scroll.scroll_horizontal) + amount, 0.0, max_scroll)
	var tw := create_tween()
	tw.tween_property(tray_scroll, "scroll_horizontal", int(target), 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
