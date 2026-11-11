extends Control
## MIKA Build a Word v2: 100% procedural draggable letter.
## No PNG glyph, Sprite2D, Area2D, physics picking, or collision shape.

const GAME_FONT: Font = preload("res://learning/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const PALETTE: Array[Color] = [
	Color("#ff7278"), Color("#36b8f7"), Color("#ffd166"),
	Color("#75e19e"), Color("#c79aff"), Color("#ffa971"),
	Color("#fd8fd3"), Color("#59e0d4")
]

var letter: String = ""
var dragging: bool = false
var enabled: bool = true
var start_position: Vector2 = Vector2.ZERO
var letter_voice: AudioStream

var _back: Panel
var _front: Panel
var _depth: Label
var _glyph: Label
var _glint: ColorRect
var _audio: AudioStreamPlayer
var _base_color: Color = PALETTE[0]
var _tile_side: Vector2 = Vector2(70, 70)
var _is_selected: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30
	_back = Panel.new()
	_back.name = "ExtrudedDepth"
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_back)
	_front = Panel.new()
	_front.name = "GlassLetterFace"
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_front)
	_depth = Label.new()
	_depth.name = "GlyphShadow"
	_setup_label(_depth)
	add_child(_depth)
	_glyph = Label.new()
	_glyph.name = "ActualLetterNotImage"
	_setup_label(_glyph)
	add_child(_glyph)
	_glint = ColorRect.new()
	_glint.name = "UpperSurfaceGlint"
	_glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glint)
	_audio = AudioStreamPlayer.new()
	_audio.bus = "VOICE"
	add_child(_audio)
	_redraw_geometry()

func _setup_label(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", GAME_FONT)
	label.add_theme_color_override("font_outline_color", Color("#092342"))
	label.add_theme_constant_override("outline_size", 3)

func configure_letter(value: String, voice: AudioStream) -> void:
	letter = value.to_upper()
	letter_voice = voice
	var key: int = 0
	if not letter.is_empty():
		key = letter.unicode_at(0)
	_base_color = PALETTE[posmod(key, PALETTE.size())]
	if _glyph != null:
		_glyph.text = letter
		_depth.text = letter
		_update_style()

func set_display_size(target_size: Vector2) -> void:
	var old_center: Vector2 = position + size * 0.5
	_tile_side = Vector2(maxf(8.0, target_size.x), maxf(8.0, target_size.y))
	size = _tile_side
	pivot_offset = size * 0.5
	position = old_center - size * 0.5
	_redraw_geometry()

func set_start_position(value: Vector2) -> void:
	start_position = value
	if not dragging:
		position = value - size * 0.5

func reset_to_start() -> void:
	dragging = false
	rotation = 0.0
	scale = Vector2.ONE
	z_index = 30
	position = start_position - size * 0.5
	_is_selected = false
	_update_style()

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	if not value:
		dragging = false
		_is_selected = false
		if _audio != null:
			_audio.stop()

func contains_screen_point(point: Vector2) -> bool:
	return enabled and visible and Rect2(global_position, size).grow(maxf(0.0, size.x * 0.08)).has_point(point)

func centre() -> Vector2:
	return position + size * 0.5

func begin_drag() -> void:
	if not enabled:
		return
	dragging = true
	_is_selected = true
	z_index = 70
	scale = Vector2.ONE * 1.065
	rotation = 0.0
	_update_style()
	play_letter_voice()

func move_centre_to(point: Vector2) -> void:
	position = point - size * 0.5

func finish_drag() -> void:
	dragging = false
	scale = Vector2.ONE
	rotation = 0.0
	z_index = 30
	_update_style()

func set_selected(value: bool) -> void:
	_is_selected = value
	_update_style()

func play_letter_voice() -> void:
	if letter_voice != null and _audio != null:
		_audio.stop()
		_audio.stream = letter_voice
		_audio.play()

func _redraw_geometry() -> void:
	if _front == null:
		return
	var depth_px: float = clampf(size.y * 0.08, 1.5, 6.0)
	_back.position = Vector2(0.0, depth_px)
	_back.size = size - Vector2(0.0, depth_px)
	_front.position = Vector2.ZERO
	_front.size = size - Vector2(0.0, depth_px * 0.45)
	for label in [_depth, _glyph]:
		label.size = size
		label.add_theme_font_size_override("font_size", maxi(9, roundi(size.y * 0.68)))
	_depth.position = Vector2(0.8, maxf(1.0, depth_px * 0.65))
	_glyph.position = Vector2.ZERO
	_glint.position = Vector2(size.x * 0.17, maxf(2.0, size.y * 0.11))
	_glint.size = Vector2(size.x * 0.62, maxf(1.0, size.y * 0.035))
	_glint.color = Color(1.0, 1.0, 1.0, 0.28)
	_update_style()

func _update_style() -> void:
	if _front == null:
		return
	var radius: int = maxi(4, roundi(minf(size.x, size.y) * 0.23))
	var body := StyleBoxFlat.new()
	body.anti_aliasing = true
	body.set_corner_radius_all(radius)
	body.bg_color = _base_color.darkened(0.48)
	body.border_color = _base_color.darkened(0.65)
	body.set_border_width_all(maxi(1, roundi(size.y * 0.045)))
	body.shadow_color = Color(0.02, 0.04, 0.14, 0.55)
	body.shadow_size = maxi(2, roundi(size.y * 0.12))
	body.shadow_offset = Vector2(0.0, maxf(1.0, size.y * 0.065))
	_back.add_theme_stylebox_override("panel", body)

	var face := StyleBoxFlat.new()
	face.anti_aliasing = true
	face.set_corner_radius_all(radius)
	face.bg_color = _base_color.lightened(0.18) if _is_selected else _base_color
	face.border_color = Color("#e7ffff") if _is_selected else _base_color.lightened(0.38)
	face.set_border_width_all(maxi(1, roundi(size.y * 0.055)))
	face.shadow_color = Color(0.10, 0.77, 1.0, 0.62 if _is_selected else 0.21)
	face.shadow_size = maxi(2, roundi(size.y * (0.16 if _is_selected else 0.08)))
	_front.add_theme_stylebox_override("panel", face)
	_depth.add_theme_color_override("font_color", _base_color.darkened(0.58))
	_glyph.add_theme_color_override("font_color", Color("#072341") if _base_color.get_luminance() > 0.54 else Color.WHITE)
