extends "res://learning/src/features/tracing/mika_shape_build_native_v1_3.gd"
## MIKA Build Shapes v1.4 — true-white paper on its OWN CanvasLayer.
## Godot z_index only sorts within a canvas. It cannot put a root Node2D
## over a CanvasLayer. Place paper + shape lines together on layer 2 and
## controls on layer 3; keep cosmos and large blue card on layer 0.
## This isolates white paper from every transparent game HUD overlay.

var _white_paper_canvas_v14: CanvasLayer

func _build_panels() -> void:
	# Parent _build_panels creates the two existing working shape grids.
	# The canvas is created first so that we can move both grids and the
	# v1.3 pure-white underlays into the SAME independent drawing layer.
	_white_paper_canvas_v14 = CanvasLayer.new()
	_white_paper_canvas_v14.name = "PureWhitePaperLayer_AboveBlueBackground"
	_white_paper_canvas_v14.layer = 2
	_white_paper_canvas_v14.follow_viewport_enabled = false
	add_child(_white_paper_canvas_v14)

	super._build_panels()

	# Both underlays are opaque Color.WHITE. They MUST be in the same canvas
	# as the grids; raising z_index on the root canvas was insufficient.
	if _sample_paper_underlay_v13 != null:
		_sample_paper_underlay_v13.reparent(_white_paper_canvas_v14, false)
		_sample_paper_underlay_v13.color = Color.WHITE
		_sample_paper_underlay_v13.modulate = Color.WHITE
		_sample_paper_underlay_v13.self_modulate = Color.WHITE
		_sample_paper_underlay_v13.material = null
		_sample_paper_underlay_v13.z_index = 0
	if _draw_paper_underlay_v13 != null:
		_draw_paper_underlay_v13.reparent(_white_paper_canvas_v14, false)
		_draw_paper_underlay_v13.color = Color.WHITE
		_draw_paper_underlay_v13.modulate = Color.WHITE
		_draw_paper_underlay_v13.self_modulate = Color.WHITE
		_draw_paper_underlay_v13.material = null
		_draw_paper_underlay_v13.z_index = 0

	# No gameplay changes: strokes, animation, coordinates and pointer input
	# remain handled by the existing ShapeTraceGrid instances.
	if sample_grid != null:
		sample_grid.reparent(_white_paper_canvas_v14, false)
		sample_grid.modulate = Color.WHITE
		sample_grid.self_modulate = Color.WHITE
		sample_grid.material = null
		sample_grid.z_index = 1
	if draw_grid != null:
		draw_grid.reparent(_white_paper_canvas_v14, false)
		draw_grid.modulate = Color.WHITE
		draw_grid.self_modulate = Color.WHITE
		draw_grid.material = null
		draw_grid.z_index = 1

func _build_hud() -> void:
	super._build_hud()
	# The title, left/right arrows, crystal counter and pencil tray must be
	# on a higher canvas than the paper, even when their z_index is smaller.
	if hud != null:
		hud.layer = 3
	if title_tab != null and _mika_top_root != null:
		title_tab.reparent(_mika_top_root, false)
		title_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
