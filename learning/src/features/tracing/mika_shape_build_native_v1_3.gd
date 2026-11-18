extends "res://learning/src/features/tracing/mika_shape_build_native_v1_2.gd"
## Build Shapes v1.3 — explicit background-first scene composition.
## The big neon-blue card is a backdrop, NEVER a foreground glass overlay.
## Each white square has its own fully opaque paper underlay below the 6x6 grid.
## Existing v1.2 percentage-based layout, game logic and input are unchanged.

const LAYER_MAIN_BACKDROP: int = -8
const LAYER_PAPER_UNDERLAY: int = 5
const LAYER_GRID_AND_PAINT: int = 12
const LAYER_FIGURE_TITLE: int = 15

var _sample_paper_underlay_v13: ColorRect
var _draw_paper_underlay_v13: ColorRect

func _build_background() -> void:
	super._build_background()

	# The single large neon-blue block is the first visible game layer.
	# It remains entirely UNDER the two white papers and their drawn contents.
	if card != null:
		card.z_index = LAYER_MAIN_BACKDROP
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var base_style := StyleBoxFlat.new()
		base_style.anti_aliasing = true
		base_style.bg_color = Color(0.065, 0.19, 0.38, 0.91)
		base_style.border_color = Color("#55d9ff")
		base_style.set_border_width_all(3)
		base_style.set_corner_radius_all(34)
		base_style.shadow_color = Color(0.10, 0.49, 0.92, 0.32)
		base_style.shadow_size = 12
		base_style.shadow_offset = Vector2.ZERO
		card.add_theme_stylebox_override("panel", base_style)

	# These are not blue or semitransparent panels. The entire paper is
	# 100% white, with no material, overlay or shader attached.
	_sample_paper_underlay_v13 = _new_opaque_sheet("ExamplePureWhitePaperUnderlay")
	_draw_paper_underlay_v13 = _new_opaque_sheet("DrawingPureWhitePaperUnderlay")
	add_child(_sample_paper_underlay_v13)
	add_child(_draw_paper_underlay_v13)

	if title_tab != null:
		title_tab.z_index = LAYER_FIGURE_TITLE
		title_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _new_opaque_sheet(node_name: String) -> ColorRect:
	var sheet := ColorRect.new()
	sheet.name = node_name
	sheet.color = Color.WHITE
	sheet.modulate = Color.WHITE
	sheet.self_modulate = Color.WHITE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.z_index = LAYER_PAPER_UNDERLAY
	sheet.material = null
	return sheet

func _build_panels() -> void:
	super._build_panels()
	# The grid and its interactive shape strokes always render above the
	# white backing. They cannot be darkened by the base card or the sky.
	if sample_grid != null:
		sample_grid.z_index = LAYER_GRID_AND_PAINT
		sample_grid.modulate = Color.WHITE
		sample_grid.self_modulate = Color.WHITE
	if draw_grid != null:
		draw_grid.z_index = LAYER_GRID_AND_PAINT
		draw_grid.modulate = Color.WHITE
		draw_grid.self_modulate = Color.WHITE

func _layout() -> void:
	# Preserve every proportional/safe-area calculation introduced in v1.2.
	super._layout()
	# The underlays are exact matches for the grid's calculated square paper.
	# No new margins or fixed-pixel sizes are introduced.
	if sample_grid != null and _sample_paper_underlay_v13 != null:
		_match_underlay(_sample_paper_underlay_v13, sample_grid)
	if draw_grid != null and _draw_paper_underlay_v13 != null:
		_match_underlay(_draw_paper_underlay_v13, draw_grid)

func _match_underlay(underlay: ColorRect, grid: Node2D) -> void:
	var side: float = maxf(0.0, float(grid.get("_paper_side")))
	underlay.position = grid.position
	underlay.size = Vector2.ONE * side
	underlay.visible = side > 0.0
