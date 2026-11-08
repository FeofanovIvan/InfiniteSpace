extends "res://education/playtown/src/features/school/mika_word_tile_control_v2.gd"
## MIKA Build a Word v3: the letter itself is a colorful 3D-like glyph.
## The Control rect remains an invisible touch target; no colored square tile.
## Accepted letter nodes are preserved inside their destination slot.

var _extrusion_labels: Array[Label] = []
var _edge_highlight: Label
var _locked_into_slot: bool = false
var _target_slot: Control

func _ready() -> void:
	super._ready()
	# Original square panels remain allocated but are never rendered.
	_back.hide()
	_front.hide()
	_glint.hide()
	# Repeated offsets create real extrusion of the glyph outline, not a box.
	for i in range(5):
		var side := Label.new()
		side.name = "LetterExtrusionDepth_%d" % i
		_setup_label(side)
		add_child(side)
		move_child(side, _glyph.get_index())
		_extrusion_labels.append(side)
	_edge_highlight = Label.new()
	_edge_highlight.name = "LetterUpperEdge"
	_setup_label(_edge_highlight)
	add_child(_edge_highlight)
	move_child(_edge_highlight, _glyph.get_index())
	_refresh_glyph_visuals()

func configure_letter(value: String, voice: AudioStream) -> void:
	super.configure_letter(value, voice)
	_refresh_glyph_visuals()

func _redraw_geometry() -> void:
	super._redraw_geometry()
	_refresh_glyph_visuals()

func _update_style() -> void:
	# v2 normally draws a colorful rectangle; in v3 only the font is colored.
	if _glyph == null:
		return
	_glyph.add_theme_color_override("font_color", _base_color.lightened(0.27 if _is_selected else 0.10))
	_glyph.add_theme_color_override("font_outline_color", _base_color.darkened(0.55))
	_glyph.add_theme_constant_override("outline_size", clampi(roundi(size.y * 0.045), 1, 5))
	_depth.add_theme_color_override("font_color", _base_color.darkened(0.75))
	if not _extrusion_labels.is_empty():
		_refresh_glyph_visuals()

func _refresh_glyph_visuals() -> void:
	if _glyph == null:
		return
	var font_size: int = maxi(10, roundi(minf(size.x, size.y) * 0.78))
	_glyph.text = letter
	_depth.text = letter
	_glyph.size = size
	_glyph.position = Vector2(0.0, -2.0)
	_glyph.add_theme_font_size_override("font_size", font_size)
	_depth.size = size
	_depth.position = Vector2(1.1, maxf(2.0, size.y * 0.095))
	_depth.add_theme_font_size_override("font_size", font_size)
	var extrusion_step: float = clampf(size.y * 0.015, 0.70, 1.80)
	for index in range(_extrusion_labels.size()):
		var lbl: Label = _extrusion_labels[index]
		lbl.text = letter
		lbl.size = size
		lbl.position = Vector2(0.0, float(_extrusion_labels.size() - index) * extrusion_step)
		lbl.add_theme_font_size_override("font_size", font_size)
		lbl.add_theme_color_override("font_color", _base_color.darkened(0.63 - float(index) * 0.075))
		lbl.add_theme_color_override("font_outline_color", _base_color.darkened(0.79))
		lbl.add_theme_constant_override("outline_size", 2)
	if _edge_highlight != null:
		_edge_highlight.text = letter
		_edge_highlight.size = size
		_edge_highlight.position = Vector2(-1.0, -3.2)
		_edge_highlight.add_theme_font_size_override("font_size", font_size)
		_edge_highlight.add_theme_color_override("font_color", _base_color.lightened(0.75))
		_edge_highlight.add_theme_color_override("font_outline_color", _base_color.lightened(0.58))
		_edge_highlight.add_theme_constant_override("outline_size", 1)
		_edge_highlight.modulate = Color(1.0, 1.0, 1.0, 0.60)
	# No backplate at any time, including when dragging or selected.
	if _back != null:
		_back.hide()
	if _front != null:
		_front.hide()
	if _glint != null:
		_glint.hide()

func set_enabled(value: bool) -> void:
	if not value:
		# A successful placement should not make the selected letter vanish.
		enabled = false
		dragging = false
		_is_selected = false
		visible = true
		_update_style()
		return
	if _locked_into_slot:
		return
	super.set_enabled(value)

func set_display_size(target_size: Vector2) -> void:
	if _locked_into_slot and is_instance_valid(_target_slot):
		var cell: Vector2 = _target_slot.get("_cell_size")
		super.set_display_size(cell * 0.88)
		position = -size * 0.5
	else:
		super.set_display_size(target_size)

func set_start_position(value: Vector2) -> void:
	if _locked_into_slot:
		return
	super.set_start_position(value)

func reset_to_start() -> void:
	if _locked_into_slot:
		return
	super.reset_to_start()

func contains_screen_point(point: Vector2) -> bool:
	if _locked_into_slot:
		return false
	return super.contains_screen_point(point)

func lock_into_slot(slot: Control) -> void:
	if slot == null or not is_instance_valid(slot) or _locked_into_slot:
		return
	_locked_into_slot = true
	_target_slot = slot
	enabled = false
	dragging = false
	_is_selected = false
	visible = true
	rotation = 0.0
	scale = Vector2.ONE
	z_index = 30
	# Move the ACTUAL dragged letter to the word cell; no substitute glyph.
	reparent(slot, true)
	set_display_size(Vector2.ONE * 50.0)
	position = -size * 0.5
	_update_style()
