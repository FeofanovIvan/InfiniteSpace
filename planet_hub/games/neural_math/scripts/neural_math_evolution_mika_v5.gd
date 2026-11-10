extends "res://planet_hub/games/neural_math/scripts/neural_math_evolution_mika_v4.gd"
## Neural Math v5
## Adds a Hint button and visual colored stick hints for arithmetic and
## multiplication/division modes. Fractions intentionally keep hints disabled.
## The stage space background remains inside the safe rounded block only.

const HINT_LABELS := {
	"ru": "ПОДСКАЗКА", "en": "HINT", "pt": "DICA",
	"es": "PISTA", "de": "HINWEIS", "fr": "INDICE"
}
const HINT_OFF_TEXT := {
	"ru": "Подсказки для дробей пока отключены", "en": "Hints are off for fractions",
	"pt": "As dicas estão desativadas para frações", "es": "Las pistas están desactivadas para fracciones",
	"de": "Hinweise sind für Brüche deaktiviert", "fr": "Les indices sont désactivés pour les fractions"
}
const STICK_A := Color("73e6ff")
const STICK_B := Color("ffd471")
const STICK_C := Color("92f3ce")
const STICK_MUTED := Color(0.73, 0.88, 0.98, 0.18)

var _hint_button: Button
var _hint_visible: bool = false


func _build_header() -> void:
	super._build_header()
	_hint_button = Button.new()
	_hint_button.name = "NeuralMathHint"
	_hint_button.z_index = 18
	_hint_button.focus_mode = Control.FOCUS_NONE
	_hint_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_hint_button.add_theme_color_override("font_color", TEXT)
	_hint_button.add_theme_color_override("font_hover_color", TEXT)
	_hint_button.add_theme_color_override("font_pressed_color", TEXT)
	_hint_button.add_theme_color_override("font_disabled_color", Color(0.72, 0.82, 0.89, 0.76))
	_hint_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_hint_button.pressed.connect(_toggle_hint)
	add_child(_hint_button)
	_update_hint_button_style()
	_update_labels()


func _update_labels() -> void:
	super._update_labels()
	if _hint_button != null:
		_hint_button.text = str(HINT_LABELS.get(_locale, HINT_LABELS["en"]))
		_update_hint_button_style()


func _layout() -> void:
	super._layout()
	if _hint_button == null or _mode_buttons.size() != 3:
		return
	var w: float = _stage.size.x
	var h: float = _stage.size.y
	var padding: float = clampf(w * 0.021, 8.0, 27.0)
	var mode_width: float = clampf(w * 0.235, 128.0, 300.0)
	var available_h: float = maxf(150.0, _stage.size.y - padding * 2.0)
	var mode_height: float = minf(available_h, clampf(h * 0.74, 190.0, 320.0))
	_modes_rect = Rect2(Vector2(_stage.end.x - padding - mode_width, _stage.position.y + padding), Vector2(mode_width, mode_height))
	var caption_h: float = clampf(_stage.size.y * 0.072, 18.0, 31.0)
	var inner_top: float = _modes_rect.position.y + caption_h + 8.0
	var button_gap: float = clampf(h * 0.014, 3.0, 10.0)
	var remaining: float = maxf(84.0, _modes_rect.end.y - inner_top - padding * 0.30)
	var button_height: float = (remaining - button_gap * 3.0) / 4.0
	var button_width: float = maxf(24.0, mode_width - 14.0)
	for i in range(3):
		var button: Button = _mode_buttons[i]
		var title_units: float = maxf(1.0, float(button.text.length()) * 0.55)
		var text_fit: float = (button_width - 14.0) / title_units
		button.add_theme_font_size_override("font_size", maxi(9, roundi(minf(16.0, minf(button_height * 0.38, text_fit)))))
		button.position = Vector2(_modes_rect.position.x + 7.0, inner_top + i * (button_height + button_gap))
		button.size = Vector2(button_width, button_height)
	var hint_units: float = maxf(1.0, float(_hint_button.text.length()) * 0.60)
	var hint_fit: float = (button_width - 14.0) / hint_units
	_hint_button.add_theme_font_size_override("font_size", maxi(9, roundi(minf(16.0, minf(button_height * 0.40, hint_fit)))))
	_hint_button.position = Vector2(_modes_rect.position.x + 7.0, inner_top + 3.0 * (button_height + button_gap))
	_hint_button.size = Vector2(button_width, button_height)
	_update_hint_button_style()


func _toggle_hint() -> void:
	if _mode == 2:
		_feedback = str(HINT_OFF_TEXT.get(_locale, HINT_OFF_TEXT["en"]))
		_feedback_color = MUTED
		_feedback_time = 1.0
		if _v4_sfx != null:
			_v4_play("wrong")
		queue_redraw()
		return
	_hint_visible = not _hint_visible
	if _v4_sfx != null:
		_v4_play("select")
	queue_redraw()


func _choose_mode(mode: int) -> void:
	super._choose_mode(mode)
	_hint_visible = false
	_update_hint_button_style()


func _new_round() -> void:
	super._new_round()
	_hint_visible = false
	_update_hint_button_style()


func _update_hint_button_style() -> void:
	if _hint_button == null:
		return
	var active: bool = _mode != 2
	_hint_button.disabled = not active
	var on: bool = active and _hint_visible
	_hint_button.add_theme_stylebox_override("normal", _style(Color(0.08,0.27,0.39,0.94) if on else Color(0.025,0.10,0.19,0.89), MINT if on else Color("4c87a9"), 13, 3 if on else 2))
	_hint_button.add_theme_stylebox_override("hover", _style(Color("245071"), CYAN, 13, 2))
	_hint_button.add_theme_stylebox_override("pressed", _style(Color("21647c"), MINT, 13, 3))
	_hint_button.add_theme_stylebox_override("disabled", _style(Color(0.03,0.08,0.14,0.56), Color(0.31,0.46,0.57,0.70), 13, 2))


func _v5_hint_band_rect(for_rect: Rect2) -> Rect2:
	var top: float = _stage.position.y + clampf(_stage.size.y * 0.20, 34.0, 92.0)
	var bottom: float = for_rect.position.y - clampf(_stage.size.y * 0.024, 8.0, 16.0)
	var height: float = maxf(18.0, bottom - top)
	return Rect2(Vector2(for_rect.position.x, top), Vector2(for_rect.size.x, height))


func _v5_hint_specs() -> Array:
	var specs: Array = []
	if _equation.size() < 5:
		return specs
	var a: int = int(_equation[0])
	var b: int = int(_equation[2])
	var c: int = int(_equation[4])
	var op: String = str(_equation[1])
	if _mode == 0:
		if op == "+":
			specs.append({"index": 0, "groups": [{"count": a, "color": STICK_A}]})
			specs.append({"index": 2, "groups": [{"count": b, "color": STICK_B}]})
			specs.append({"index": 4, "groups": [{"count": a, "color": STICK_A}, {"count": b, "color": STICK_B}]})
		else:
			specs.append({"index": 0, "groups": [{"count": c, "color": STICK_C}, {"count": b, "color": STICK_B}]})
			specs.append({"index": 2, "groups": [{"count": b, "color": STICK_B}]})
			specs.append({"index": 4, "groups": [{"count": c, "color": STICK_C}]})
	elif _mode == 1:
		if op == "×":
			specs.append({"index": 0, "groups": [{"count": a, "color": STICK_A}]})
			specs.append({"index": 2, "groups": [{"count": b, "color": STICK_B}]})
			var result_groups: Array = []
			for group_index in range(b):
				result_groups.append({"count": a, "color": STICK_A if group_index % 2 == 0 else STICK_B})
			specs.append({"index": 4, "groups": result_groups})
		else:
			var dividend_groups: Array = []
			for group_index in range(c):
				dividend_groups.append({"count": b, "color": STICK_A if group_index % 2 == 0 else STICK_B})
			specs.append({"index": 0, "groups": dividend_groups})
			specs.append({"index": 2, "groups": [{"count": b, "color": STICK_B}]})
			specs.append({"index": 4, "groups": [{"count": c, "color": STICK_C}]})
	return specs


func _v5_draw_groups(area: Rect2, groups: Array) -> void:
	if groups.is_empty() or area.size.x < 12.0 or area.size.y < 8.0:
		return
	var total: int = 0
	for item in groups:
		total += int(item.get("count", 0))
	if total <= 0:
		return
	var panel: Rect2 = area.grow_individual(-1.0, -1.0, -1.0, -1.0)
	_box(panel, Color(0.02, 0.08, 0.15, 0.38), Color(0.30, 0.54, 0.67, 0.28), 10, 1)
	var pad_x: float = clampf(panel.size.x * 0.06, 3.0, 8.0)
	var pad_y: float = clampf(panel.size.y * 0.10, 2.0, 6.0)
	var usable_w: float = maxf(20.0, panel.size.x - 2.0 * pad_x)
	var desired_rows: int = clampi(ceili(float(total) / 12.0), 1, 3)
	var per_row: int = maxi(1, ceili(float(total) / float(desired_rows)))
	var row_gap: float = clampf(panel.size.y * 0.07, 2.0, 5.0)
	var row_h: float = maxf(6.0, (panel.size.y - 2.0 * pad_y - row_gap * float(desired_rows - 1)) / float(desired_rows))
	var stick_h: float = clampf(row_h * 0.74, 5.0, 18.0)
	var stick_pitch: float = maxf(4.0, minf(12.0, usable_w / maxf(1.0, float(per_row))))
	var group_gap: float = maxf(4.0, stick_pitch * 0.55)
	var x: float = panel.position.x + pad_x
	var row: int = 0
	var slot_in_row: int = 0
	for group_index in range(groups.size()):
		var item: Dictionary = groups[group_index]
		var count: int = int(item.get("count", 0))
		var tint: Color = item.get("color", STICK_A)
		for _j in range(count):
			if slot_in_row >= per_row and row < desired_rows - 1:
				row += 1
				slot_in_row = 0
				x = panel.position.x + pad_x
			var y1: float = panel.position.y + pad_y + float(row) * (row_h + row_gap) + (row_h - stick_h) * 0.5
			var y2: float = y1 + stick_h
			draw_line(Vector2(x, y1), Vector2(x, y2), tint, maxf(2.0, stick_pitch * 0.33), true)
			draw_circle(Vector2(x, y1), maxf(1.0, stick_pitch * 0.13), tint)
			draw_circle(Vector2(x, y2), maxf(1.0, stick_pitch * 0.13), tint)
			x += stick_pitch
			slot_in_row += 1
		if group_index < groups.size() - 1:
			if slot_in_row < per_row:
				x += group_gap
				slot_in_row += 1
			elif row < desired_rows - 1:
				row += 1
				slot_in_row = 0
				x = panel.position.x + pad_x


func _v5_debug_hint_snapshot() -> Dictionary:
	var snapshot := {"mode": _mode, "visible": _hint_visible, "enabled": _hint_button != null and not _hint_button.disabled, "specs": []}
	for spec in _v5_hint_specs():
		var counts: Array = []
		for group in spec.get("groups", []):
			counts.append(int(group.get("count", 0)))
		snapshot["specs"].append({"index": int(spec.get("index", -1)), "counts": counts})
	return snapshot


func _draw() -> void:
	super._draw()
	if not _hint_visible or _mode == 2 or _expression_rects.size() < 5:
		return
	for spec in _v5_hint_specs():
		var index: int = int(spec.get("index", -1))
		if index < 0 or index >= _expression_rects.size():
			continue
		var area: Rect2 = _v5_hint_band_rect(_expression_rects[index])
		_v5_draw_groups(area, spec.get("groups", []))
