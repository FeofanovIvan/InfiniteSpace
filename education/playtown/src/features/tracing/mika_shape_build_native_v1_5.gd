extends "res://education/playtown/src/features/tracing/mika_shape_build_native_v1_2.gd"
## Build Shapes v1.5 — CLEAN canvas composition.
## Unlike 1.3/1.4, does NOT construct the old translucent paper panels,
## then try to cover them with more elements. Only three actual layers:
## 0) space + decorative blue card; 30) 2 white drawn grid canvases;
## 31) buttons/title/pencils. The grid itself draws Color.WHITE.
## Keeps the fully responsive relative layout and learning mechanics of v1.2.

var _white_grid_layer_v15: CanvasLayer

func _ready() -> void:
	super._ready()
	# Lets the tester confirm the running scene actually uses this version.
	print("[MIKA BUILD SHAPES v1.5] CLEAN COMPOSITION active | paper layer=30 | HUD layer=31")

func _build_background() -> void:
	# Deliberately DO NOT call super._build_background(): that older function
	# creates cyan outlined panels above the papers. No duplicate glass
	# sheets/underlays exist in this clean version at all.
	bg = ColorRect.new()
	bg.name = "LayoutBackdropTransparent"
	bg.color = Color.TRANSPARENT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -40
	add_child(bg)

	_mika_sky = SHAPE_REAL_SPACE.new()
	_mika_sky.name = "BuildShapesSpaceBehindCardOnly"
	_mika_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_sky.z_index = -30
	add_child(_mika_sky)
	_mika_sky.size = get_viewport_rect().size

	_mika_nebula = SHAPE_NEBULAE.new()
	_mika_nebula.name = "BuildShapesNebulaBehindCardOnly"
	_mika_nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_sky.add_child(_mika_nebula)
	_mika_nebula.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mika_nebula.size = get_viewport_rect().size

	# The only blue block in the game, and ONLY in the base/root canvas.
	card = Panel.new()
	card.name = "SingleLargeBlueBackgroundBEHINDPaper"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index = -8
	var card_skin := _panel_skin(
		Color(0.065, 0.19, 0.38, 0.88),
		Color("#55d9ff"), 34, Color(0.10, 0.49, 0.92, 0.32)
	)
	card.add_theme_stylebox_override("panel", card_skin)
	add_child(card)

	# Original shape-name tab, later moved to the *controls* canvas.
	title_tab = _make_tab("SQUARE", 40)
	title_tab.name = "ShapeNameOnControlLayer"
	title_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_tab.add_theme_stylebox_override(
		"panel", _panel_skin(Color("#102e57"), Color("#84eaff"), 18,
			Color(0.19, 0.64, 1.0, 0.32))
	)
	title_label.add_theme_color_override("font_color", Color("#e9faff"))

func _build_panels() -> void:
	# The ONLY nodes drawn over the white square area are the actual grids.
	# Their _draw() begins with a fully opaque Color.WHITE draw_rect.
	_white_grid_layer_v15 = CanvasLayer.new()
	_white_grid_layer_v15.name = "OnlyTwoWhiteGridSheets_AfterBlueBackground"
	_white_grid_layer_v15.layer = 30
	_white_grid_layer_v15.follow_viewport_enabled = false
	add_child(_white_grid_layer_v15)

	sample_grid = RESPONSIVE_WHITE_PAPER.new()
	sample_grid.name = "ActualWhiteSampleGrid_NoOverlay"
	sample_grid.interactive = false
	sample_grid.z_index = 0
	sample_grid.modulate = Color.WHITE
	sample_grid.self_modulate = Color.WHITE
	sample_grid.material = null
	_white_grid_layer_v15.add_child(sample_grid)

	draw_grid = RESPONSIVE_WHITE_PAPER.new()
	draw_grid.name = "ActualWhiteDrawingGrid_NoOverlay"
	draw_grid.interactive = true
	draw_grid.z_index = 0
	draw_grid.modulate = Color.WHITE
	draw_grid.self_modulate = Color.WHITE
	draw_grid.material = null
	draw_grid.edge_attempt.connect(_on_edge_attempt)
	draw_grid.interaction_started.connect(_on_user_interaction_started)
	draw_grid.coloring_completed.connect(_on_coloring_completed)
	_white_grid_layer_v15.add_child(draw_grid)

func _build_hud() -> void:
	super._build_hud()
	# This canvas contains only interactive controls and is above the paper.
	if hud != null:
		hud.layer = 31
	if title_tab != null and _mika_top_root != null:
		title_tab.reparent(_mika_top_root, false)
		title_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
