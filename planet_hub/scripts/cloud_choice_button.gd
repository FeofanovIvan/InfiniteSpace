@tool
extends Button
## v98: one native draw surface for the original Launch / Simulator oval artwork
## AND its centered lettering. No child Label can drift outside the pill.
## This is a visual typing suggestion. Pressed signals remain owned by the dialog.

const CHOICE_CYAN: Texture2D = preload("res://planet_hub/assets/v97_dialogue/dialogue_choice_cyan.png")
const CHOICE_LAUNCH: Texture2D = preload("res://planet_hub/assets/v98_dialogue/dialogue_choice_launch.png")

@export var chosen: bool = false:
	set(value):
		chosen = value
		queue_redraw()

var _phrase: String = ""
var _draw_font_size: int = 19


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	# The background and the text are BOTH drawn by _draw(), not by Godot's
	# default Button theme or an independent Label.
	text = ""
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color", "font_focus_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	resized.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func set_phrase(phrase: String) -> void:
	_phrase = phrase.strip_edges()
	tooltip_text = _phrase
	# Never hand the text to native Button: its label drawing must not compete
	# with our precisely-centered CanvasItem drawing.
	text = ""
	queue_redraw()


func get_phrase() -> String:
	return _phrase


func _font() -> Font:
	return ThemeDB.fallback_font


func _text_width(value: String, font: Font, px: int) -> float:
	return font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


func _wrap_lines(value: String, font: Font, px: int, max_line_width: float) -> Array[String]:
	var lines: Array[String] = []
	for paragraph in value.replace("\r", "").split("\n", true):
		var current: String = ""
		for word in paragraph.split(" ", false):
			var candidate: String = word if current.is_empty() else current + " " + word
			if _text_width(candidate, font, px) <= max_line_width:
				current = candidate
				continue
			if not current.is_empty():
				lines.append(current)
				current = ""
			if _text_width(word, font, px) <= max_line_width:
				current = word
			else:
				# Handle strings without spaces (and very long scientific terms).
				var fragment: String = ""
				for n in range(word.length()):
					var letter: String = word.substr(n, 1)
					if not fragment.is_empty() and _text_width(fragment + letter, font, px) > max_line_width:
						lines.append(fragment)
						fragment = ""
					fragment += letter
				current = fragment
		if not current.is_empty():
			lines.append(current)
		elif paragraph.is_empty():
			lines.append("")
	if lines.is_empty():
		lines.append("")
	return lines


func suggested_size(max_width: float, target_font_size: int, basic_height: float) -> Vector2:
	# This method is called from the parent layout whenever a suggestion changes.
	# Width grows with the real measured phrase, not with its slot index.
	var font: Font = _font()
	var px: int = clampi(target_font_size, 13, 23)
	var usable_width: float = maxf(80.0, max_width)
	var horizontal_padding: float = clampf(basic_height * 0.95, 48.0, 82.0)
	var natural_width: float = _text_width(_phrase, font, px) + horizontal_padding
	var preferred_width: float = clampf(natural_width, minf(154.0, usable_width), usable_width)
	var inner_width: float = maxf(28.0, preferred_width - horizontal_padding)
	var rows: Array[String] = _wrap_lines(_phrase, font, px, inner_width)
	# On a narrow screen, prefer 2-3 legible lines over cutting off the phrase.
	while rows.size() > 3 and px > 13:
		px -= 1
		rows = _wrap_lines(_phrase, font, px, inner_width)
	_draw_font_size = px
	var line_height: float = maxf(float(px) * 1.24, font.get_height(px) * 1.04)
	var preferred_height: float = maxf(basic_height, line_height * float(rows.size()) + maxf(18.0, basic_height * 0.30))
	return Vector2(preferred_width, preferred_height)


func _draw() -> void:
	if size.x < 24.0 or size.y < 24.0:
		return
	var texture: Texture2D = CHOICE_LAUNCH if chosen else CHOICE_CYAN
	# Original v68 Launch has an ORANGE interior (not just an orange rim).
	# Original v68 Simulator has a deep-blue interior and a cyan rim.
	var tint: Color = Color(1.08, 1.08, 1.08, 1.0) if is_hovered() else Color.WHITE
	draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, tint)
	if _phrase.is_empty():
		return
	var font: Font = _font()
	var px: int = _draw_font_size
	var inner_width: float = maxf(24.0, size.x - clampf(size.y * 0.95, 48.0, 82.0))
	var lines: Array[String] = _wrap_lines(_phrase, font, px, inner_width)
	var line_height: float = maxf(float(px) * 1.24, font.get_height(px) * 1.04)
	var text_block_height: float = line_height * float(lines.size())
	var first_baseline: float = (size.y - text_block_height) * 0.5 + (line_height - font.get_height(px)) * 0.5 + font.get_ascent(px)
	for i in range(lines.size()):
		var line: String = lines[i]
		var measured: float = _text_width(line, font, px)
		var at: Vector2 = Vector2((size.x - measured) * 0.5, first_baseline + float(i) * line_height)
		# A subtle navy outline, then two near-overlapping white draws for the
		# slightly heavier lettering of the existing Launch/Simulator UI.
		for offset in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2(0.0, 1.0)]:
			draw_string(font, at + offset, line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, Color("#04172d"))
		draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, Color.WHITE)
		draw_string(font, at + Vector2(0.45, 0.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, Color(1.0, 1.0, 1.0, 0.76))
