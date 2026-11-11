extends "res://learning/src/features/tracing/shape_trace_game.gd"
## MIKA Build Shapes — paper-grid native simulator styling.
## Keeps the original grid interactions, demo, pencil challenge & voice lines.

const SHAPE_REAL_SPACE := preload("res://simulator_ui/scripts/real_space_background.gd")
const SHAPE_NEBULAE := preload("res://simulator_ui/scripts/mika_minigame_nebula_layer.gd")
const SHAPE_TOOLBAR := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const SHAPE_HUB := preload("res://planet_hub/scripts/bottom_hud.gd")
const SHAPE_BACK_GLYPH := preload("res://simulator_ui/back_arrow_glyph.gd")
const WHITE_GRID := preload("res://learning/src/features/tracing/mika_shape_paper_grid_v1.gd")

const SHAPE_CAPTIONS := {
	"ru": ["СОБЕРИ ФИГУРУ", "Соедини точки и раскрась"],
	"en": ["BUILD SHAPES", "Connect the dots and colour"],
	"pt_BR": ["MONTE AS FORMAS", "Ligue os pontos e pinte"],
	"fr": ["CONSTRUIS LES FORMES", "Relie les points et colorie"],
	"es": ["CONSTRUYE FIGURAS", "Une los puntos y colorea"],
	"de": ["FORMEN ZEICHNEN", "Verbinde Punkte und male aus"]
}

var _mika_sky: Control
var _mika_nebula: Control
var _mika_sample_sheet: Panel
var _mika_draw_sheet: Panel
var _mika_top_root: Control
var _mika_back: Button
var _mika_hub: Control
var _mika_heading: Panel
var _mika_title: Label
var _mika_subtitle: Label
var _mika_prev: Button
var _mika_next: Button
var _mika_round_keys: Dictionary = {}
var _mika_earned: int = 0
var _mika_settled: bool = false
var _mika_host_back: BaseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mika_earned = 0
	super._ready()
	_set_shape_language()
	var host: Node = _find_sim_host()
	if host != null:
		_mika_host_back = host.get_node_or_null("EmbeddedGameRunner/ReturnToEducationalCards") as BaseButton
		if is_instance_valid(_mika_host_back):
			_mika_host_back.hide()
	_update_score()
	_layout()

func _panel_skin(fill: Color, border: Color, radius: int, glow: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(3)
	style.shadow_color = glow
	style.shadow_size = 12
	style.shadow_offset = Vector2.ZERO
	return style

func _build_background() -> void:
	super._build_background()
	bg.color = Color.TRANSPARENT
	card.add_theme_stylebox_override("panel", _panel_skin(Color(0.08, 0.20, 0.40, 0.77), Color("#66dfff"), 34, Color(0.19, 0.60, 1.0, 0.33)))
	title_tab.add_theme_stylebox_override("panel", _panel_skin(Color("#102e57"), Color("#84eaff"), 18, Color(0.19, 0.64, 1.0, 0.32)))
	title_label.add_theme_color_override("font_color", Color("#e9faff"))
	_mika_sky = SHAPE_REAL_SPACE.new()
	_mika_sky.name = "RealSimulatorCosmosBuildShapes"
	_mika_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_sky.z_index = -25
	add_child(_mika_sky)
	_mika_sky.size = get_viewport_rect().size
	_mika_nebula = SHAPE_NEBULAE.new()
	_mika_nebula.name = "CrossroadsVioletPinkNebulaeBuildShapes"
	_mika_nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_sky.add_child(_mika_nebula)
	_mika_nebula.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mika_nebula.size = get_viewport_rect().size

	_mika_sample_sheet = Panel.new()
	_mika_sample_sheet.name = "WhitePaperExample6x6"
	_mika_sample_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_sample_sheet.z_index = 7 # Border sits above the grid's white fill without blocking touches.
	_mika_sample_sheet.add_theme_stylebox_override("panel", _panel_skin(Color(1, 1, 1, 0), Color("#6ce1ff"), 13, Color(0.35, 0.74, 1.0, 0.46)))
	add_child(_mika_sample_sheet)
	_mika_draw_sheet = Panel.new()
	_mika_draw_sheet.name = "WhitePaperDrawing6x6"
	_mika_draw_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_draw_sheet.z_index = 7 # Transparent neon frame; paper is drawn by the grid itself.
	_mika_draw_sheet.add_theme_stylebox_override("panel", _panel_skin(Color(1, 1, 1, 0), Color("#6ce1ff"), 13, Color(0.35, 0.74, 1.0, 0.46)))
	add_child(_mika_draw_sheet)

func _build_panels() -> void:
	sample_grid = WHITE_GRID.new()
	sample_grid.name = "ExampleOnWhiteSquaredPaper"
	sample_grid.interactive = false
	sample_grid.z_index = 5
	add_child(sample_grid)
	draw_grid = WHITE_GRID.new()
	draw_grid.name = "DrawOnWhiteSquaredPaper"
	draw_grid.interactive = true
	draw_grid.z_index = 5
	draw_grid.edge_attempt.connect(_on_edge_attempt)
	draw_grid.interaction_started.connect(_on_user_interaction_started)
	draw_grid.coloring_completed.connect(_on_coloring_completed)
	add_child(draw_grid)

func _make_title_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("#f0fcff"))
	label.add_theme_color_override("font_outline_color", Color("#07152f"))
	label.add_theme_constant_override("outline_size", 2)
	return label

func _native_back_button() -> Button:
	var button := Button.new()
	button.name = "BuildShapesNativeBack"
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var host: Node = _find_sim_host()
	if host != null and host.has_method("_style_back_button"):
		host.call("_style_back_button", button)
	else:
		button.add_theme_stylebox_override("normal", _panel_skin(Color("#0a2449"), Color("#35dfff"), 18, Color(0.08, 0.69, 1.0, 0.36)))
		button.add_theme_stylebox_override("hover", _panel_skin(Color("#15385f"), Color("#6defff"), 18, Color(0.08, 0.69, 1.0, 0.42)))
		button.add_theme_stylebox_override("pressed", _panel_skin(Color("#15385f"), Color("#6defff"), 18, Color(0.08, 0.69, 1.0, 0.42)))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var glyph: Control = SHAPE_BACK_GLYPH.new()
		button.add_child(glyph)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_exit_pressed)
	return button

func _make_nav_button(label: String, go_back: bool) -> Button:
	var button := Button.new()
	button.name = "PreviousShape" if go_back else "NextShape"
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", Color("#e8fcff"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_stylebox_override("normal", _panel_skin(Color("#0a2a52"), Color("#55dfff"), 16, Color(0.12, 0.68, 1.0, 0.29)))
	button.add_theme_stylebox_override("hover", _panel_skin(Color("#16446d"), Color("#9bf1ff"), 16, Color(0.12, 0.68, 1.0, 0.40)))
	button.add_theme_stylebox_override("pressed", _panel_skin(Color("#2b6c87"), Color("#9bf1ff"), 16, Color(0.12, 0.68, 1.0, 0.40)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if go_back:
		button.pressed.connect(_on_prev_pressed)
	else:
		button.pressed.connect(_on_next_pressed)
	return button

func _pencil_bar_style() -> StyleBoxFlat:
	return _panel_skin(Color(0.07, 0.19, 0.39, 0.94), Color("#72dfff"), 22, Color(0.24, 0.60, 1.0, 0.34))

func _pencil_card_style(color: Color, selected: bool) -> StyleBoxFlat:
	var style := _panel_skin(color.lightened(0.83 if not selected else 0.66), Color("#8df0ff") if selected else color.lightened(0.24), 15, Color(0.25, 0.72, 1.0, 0.35 if selected else 0.16))
	style.set_border_width_all(4 if selected else 2)
	return style

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "BuildShapesNativeHUD"
	add_child(hud)
	_mika_top_root = Control.new()
	_mika_top_root.name = "BuildShapesHeaderContainer"
	_mika_top_root.size = get_viewport_rect().size
	_mika_top_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_mika_top_root)

	_mika_back = _native_back_button()
	_mika_top_root.add_child(_mika_back)
	_mika_hub = SHAPE_HUB.new() as Control
	_mika_hub.name = "OriginalPlanetHubCrystalCounter"
	_mika_hub.size = Vector2(1680.0, 158.0)
	_mika_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_top_root.add_child(_mika_hub)
	var sim_btn: Control = _mika_hub.get_node_or_null("SimulatorButton") as Control
	var launch_btn: Control = _mika_hub.get_node_or_null("LaunchButton") as Control
	if sim_btn != null:
		sim_btn.hide()
	if launch_btn != null:
		launch_btn.hide()
	_mika_heading = Panel.new()
	_mika_heading.name = "SharedTitleToolbarPlaque"
	_mika_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_top_root.add_child(_mika_heading)
	SHAPE_TOOLBAR.apply_title_style(_mika_heading)
	_mika_title = _make_title_label()
	_mika_subtitle = _make_title_label()
	_mika_subtitle.add_theme_color_override("font_color", Color("#acebff"))
	_mika_heading.add_child(_mika_title)
	_mika_heading.add_child(_mika_subtitle)

	_mika_prev = _make_nav_button("❮", true)
	_mika_next = _make_nav_button("❯", false)
	_mika_top_root.add_child(_mika_prev)
	_mika_top_root.add_child(_mika_next)

	# The parent connects coin_balance_changed to score_label; keep a hidden
	# listener only. The visible counter is always THIS attempt's earnings.
	score_label = Label.new()
	score_label.visible = false
	score_label.name = "LegacyPlayTownCoinsHidden"
	_mika_top_root.add_child(score_label)

	pencil_bar = Panel.new()
	pencil_bar.name = "NativePencilTray"
	pencil_bar.add_theme_stylebox_override("panel", _pencil_bar_style())
	pencil_bar.visible = false
	_mika_top_root.add_child(pencil_bar)
	for index in range(PENCIL_TEXTURES.size()):
		var pencil_card := Panel.new()
		pencil_card.name = "PencilOption_%02d" % index
		pencil_card.add_theme_stylebox_override("panel", _pencil_card_style(PENCIL_COLORS[index], false))
		pencil_bar.add_child(pencil_card)
		pencil_cards.append(pencil_card)
		var pencil_button := TextureButton.new()
		pencil_button.texture_normal = PENCIL_TEXTURES[index]
		pencil_button.ignore_texture_size = true
		pencil_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pencil_button.focus_mode = Control.FOCUS_NONE
		pencil_button.pressed.connect(_on_pencil_pressed.bind(index))
		pencil_card.add_child(pencil_button)
		pencil_buttons.append(pencil_button)

func _safe_rect() -> Rect2:
	var view: Vector2 = get_viewport_rect().size
	if OS.get_name() not in ["iOS", "Android"]:
		return Rect2(Vector2.ZERO, view)
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if window.x <= 0.0 or window.y <= 0.0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Rect2(Vector2.ZERO, view)
	var scale_vector: Vector2 = view / window
	return Rect2(Vector2(safe.position) * scale_vector, Vector2(safe.size) * scale_vector)

func _set_shape_language() -> void:
	if _mika_title == null:
		return
	var locale: String = str(MobileLocale.language)
	if not SHAPE_CAPTIONS.has(locale):
		locale = "en"
	_mika_title.text = SHAPE_CAPTIONS[locale][0]
	_mika_subtitle.text = SHAPE_CAPTIONS[locale][1]

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
	var pad: float = clampf(sw * 0.022, 7.0, 30.0)
	var gap: float = clampf(sw * 0.018, 6.0, 25.0)
	var body_top: float = header_bottom + clampf(sh * 0.022, 7.0, 22.0)
	var body_bottom: float = safe.end.y - pad
	card.position = Vector2(safe.position.x + pad, body_top)
	card.size = Vector2(sw - 2.0 * pad, maxf(150.0, body_bottom - body_top))
	var center_x: float = safe.position.x + sw * 0.5
	var nav_h: float = clampf(sh * 0.087, 32.0, 64.0)
	var nav_y: float = body_top + clampf(sh * 0.016, 6.0, 18.0)
	var title_w: float = minf(sw * 0.32, 430.0)
	var arrow_size: float = nav_h
	var nav_gap: float = clampf(sw * 0.015, 5.0, 20.0)
	title_tab.position = Vector2(center_x - title_w * 0.5, nav_y)
	title_tab.size = Vector2(title_w, nav_h)
	title_label.add_theme_font_size_override("font_size", maxi(11, roundi(nav_h * 0.45)))
	_mika_prev.position = Vector2(title_tab.position.x - arrow_size - nav_gap, nav_y)
	_mika_prev.size = Vector2.ONE * arrow_size
	_mika_next.position = Vector2(title_tab.position.x + title_w + nav_gap, nav_y)
	_mika_next.size = Vector2.ONE * arrow_size
	for btn in [_mika_prev, _mika_next]:
		btn.add_theme_font_size_override("font_size", maxi(14, roundi(nav_h * 0.62)))

	var pencil_h: float = clampf(sh * 0.148, 62.0, 135.0)
	var pencil_gap_bottom: float = clampf(sh * 0.028, 9.0, 26.0)
	var grid_top: float = nav_y + nav_h + clampf(sh * 0.017, 7.0, 19.0)
	var grid_bottom: float = body_bottom - pencil_h - pencil_gap_bottom * 1.3
	var available_h: float = maxf(65.0, grid_bottom - grid_top)
	var panel_gap: float = clampf(sw * 0.026, 9.0, 34.0)
	var available_w: float = maxf(110.0, sw - 2.0 * pad - 26.0)
	var sheet_size: float = maxf(60.0, minf(available_h, (available_w - panel_gap) * 0.5))
	var combined_w: float = sheet_size * 2.0 + panel_gap
	var start_x: float = center_x - combined_w * 0.5
	var grid_y: float = grid_top + maxf(0.0, (available_h - sheet_size) * 0.50)
	var sample_rect := Rect2(Vector2(start_x, grid_y), Vector2.ONE * sheet_size)
	var draw_rect := Rect2(Vector2(start_x + sheet_size + panel_gap, grid_y), Vector2.ONE * sheet_size)
	_mika_sample_sheet.position = sample_rect.position
	_mika_sample_sheet.size = sample_rect.size
	_mika_draw_sheet.position = draw_rect.position
	_mika_draw_sheet.size = draw_rect.size
	sample_grid.set_layout(sample_rect)
	draw_grid.set_layout(draw_rect)

	var pencil_w: float = minf(sw - pad * 4.0, maxf(360.0, sheet_size * 2.0))
	pencil_bar.position = Vector2(center_x - pencil_w * 0.5, body_bottom - pencil_h - 8.0)
	pencil_bar.size = Vector2(pencil_w, pencil_h)
	var pencil_pad: float = clampf(pencil_h * 0.085, 5.0, 12.0)
	var pencil_gap: float = clampf(pencil_w * 0.011, 3.0, 8.0)
	var pencil_card_w: float = maxf(12.0, (pencil_w - pencil_pad * 2.0 - pencil_gap * 6.0) / 7.0)
	for i in range(pencil_cards.size()):
		var holder: Panel = pencil_cards[i]
		holder.position = Vector2(pencil_pad + float(i) * (pencil_card_w + pencil_gap), pencil_pad)
		holder.size = Vector2(pencil_card_w, pencil_h - pencil_pad * 2.0)
		pencil_buttons[i].position = Vector2.ONE * 3.0
		pencil_buttons[i].size = holder.size - Vector2.ONE * 6.0

func _update_score() -> void:
	if _mika_hub != null:
		_mika_hub.set("crystal_count", _mika_earned)

func _on_coloring_completed() -> void:
	if not coloring_stage:
		return
	coloring_stage = false
	pencil_bar.visible = false
	var key: String = str(LanguageService.learning_locale) + ":" + str(shapes[shape_index]["name"])
	if not _mika_round_keys.has(key):
		_mika_round_keys[key] = true
		_mika_earned += 1
	_play_sfx(coin_sound)
	_update_score()
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.8)
	if celebrate_tween != null:
		celebrate_tween.kill()
	celebrate_tween = create_tween()
	celebrate_tween.tween_property(draw_grid, "scale", Vector2(1.065, 1.065), 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	celebrate_tween.tween_property(draw_grid, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	celebrate_tween.tween_interval(0.60)
	celebrate_tween.tween_callback(_advance_shape)

func _find_sim_host() -> Node:
	var node: Node = self
	for i in range(18):
		if node == null:
			break
		if node.has_signal("crystals_earned"):
			return node
		node = node.get_parent()
	return null

func _settle_shape_rewards() -> void:
	if _mika_settled:
		return
	_mika_settled = true
	if _mika_earned <= 0:
		return
	var host: Node = _find_sim_host()
	if host != null and host.has_signal("crystals_earned"):
		host.emit_signal("crystals_earned", _mika_earned)
		# Read the actual ship tank again; Main.gd applies capacity and upgrades.
		var cursor: Node = host.get_parent()
		for i in range(9):
			if cursor == null:
				break
			var fuel_value: Variant = cursor.get("_fuel_units")
			if fuel_value is float or fuel_value is int:
				if host.has_method("set_stats"):
					host.call("set_stats", maxi(0, floori(float(fuel_value))), 0, 0.0)
				break
			cursor = cursor.get_parent()
	else:
		GameState.add_coins(_mika_earned)

func _on_exit_pressed() -> void:
	_settle_shape_rewards()
	var host: Node = _find_sim_host()
	if host != null and host.has_method("_return_to_cards"):
		host.call("_return_to_cards")
	else:
		SFX.transition_to_scene(exit_scene_path)

func _exit_tree() -> void:
	_settle_shape_rewards()
	if is_instance_valid(_mika_host_back):
		_mika_host_back.show()
