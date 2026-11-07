extends "res://education/playtown/src/features/tracing/word_trace_game.gd"
## MIKA Trace Words Native v1
## Restyles Trace Words to match the simulator: real-space background,
## native back arrow, native crystal counter, neon glass panels, vertical
## category selector and a separate in-game round reward label.


const WORD_ARROW_TEXTURE := "res://education/playtown/assets/ui/back_arrow.png"
const REAL_HUB_HUD := preload("res://planet_hub/scripts/bottom_hud.gd")
const REAL_SPACE_BG := preload("res://simulator_ui/scripts/real_space_background.gd")
const CROSSROADS_NEBULAE := preload("res://simulator_ui/scripts/mika_minigame_nebula_layer.gd")
const NATIVE_BACK := preload("res://simulator_ui/back_arrow_glyph.gd")

const PANEL_FILL := Color("#071731")
const PANEL_FILL_ALT := Color("#091d3b")
const PANEL_BORDER := Color("#32ddff")
const PANEL_BORDER_SOFT := Color("#76bbff")
const TITLE_FILL := Color("#0b1f46")
const TEXT_MAIN := Color("#f0fbff")
const TEXT_SUB := Color("#aae8ff")
const TEXT_DIM := Color("#d3c8ff")
const BTN_FILL := Color("#0b2349")
const BTN_HOVER := Color("#173a69")
const BTN_ACTIVE := Color("#58ebff")
const BTN_ACTIVE_TEXT := Color("#08244d")

const WORD_TEXTS := {
	"ru": ["ОБВЕДИ СЛОВО", "Слушай и проводи по буквам", "В этой игре"],
	"en": ["TRACE WORDS", "Listen and trace each word", "This round"],
	"fr": ["TRACE LES MOTS", "Écoute et trace chaque mot", "Cette partie"],
	"de": ["WÖRTER NACHSPUREN", "Höre zu und fahre jedes Wort nach", "Diese Runde"],
	"es": ["REPASA PALABRAS", "Escucha y repasa cada palabra", "Esta partida"],
	"pt_BR": ["CONTORNE AS PALAVRAS", "Ouça e contorne cada palavra", "Nesta rodada"]
}

var _sky: Control
var _nebula_overlay: Control
var _hud_root: Control
var _native_back_button: Button
var _native_hub: Control
var _title_panel: Panel
var _title_label: Label
var _subtitle_label: Label
var _round_panel: Panel
var _round_label: Label
var _prev_frame: Panel
var _next_frame: Panel
var _session_earned: int = 0

func _ready() -> void:
	_session_earned = 0
	super._ready()
	_apply_language()
	_restyle_category_bar()
	_update_score()

func _build_background() -> void:
	_sky = REAL_SPACE_BG.new()
	_sky.name = "TraceWordsRealSpaceBackground"
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky)
	_sky.position = Vector2.ZERO
	_sky.size = get_viewport_rect().size

	_nebula_overlay = CROSSROADS_NEBULAE.new()
	_nebula_overlay.name = "TraceWordsNebulaBoost"
	_nebula_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nebula_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sky.add_child(_nebula_overlay)
	_nebula_overlay.size = get_viewport_rect().size

	main_card = Panel.new()
	main_card.name = "TraceWordsMainPanel"
	main_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_card.add_theme_stylebox_override("panel", _panel_style(PANEL_FILL, PANEL_BORDER, 34, 16, Color(0.22, 0.54, 1.0, 0.38)))
	main_card.z_index = 0
	add_child(main_card)

	category_card = Panel.new()
	category_card.name = "TraceWordsCategoryPanel"
	category_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	category_card.add_theme_stylebox_override("panel", _panel_style(PANEL_FILL_ALT, PANEL_BORDER_SOFT, 30, 14, Color(0.38, 0.25, 1.0, 0.26)))
	category_card.z_index = 0
	add_child(category_card)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "MikaWordTraceNativeHUD"
	add_child(hud)

	_hud_root = Control.new()
	_hud_root.name = "TraceWordsHUDRoot"
	_hud_root.size = get_viewport_rect().size
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_hud_root)

	_native_back_button = _make_native_back()
	_hud_root.add_child(_native_back_button)
	exit_button = _native_back_button

	_native_hub = REAL_HUB_HUD.new() as Control
	_native_hub.name = "OriginalPlanetHubCounter"
	_native_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_native_hub.size = Vector2(1680.0, 158.0)
	_hud_root.add_child(_native_hub)
	var sim_button: Control = _native_hub.get_node_or_null("SimulatorButton") as Control
	var launch_button: Control = _native_hub.get_node_or_null("LaunchButton") as Control
	if sim_button != null:
		sim_button.hide()
	if launch_button != null:
		launch_button.hide()

	_title_panel = Panel.new()
	_title_panel.name = "TraceWordsTitlePanel"
	_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_panel.add_theme_stylebox_override("panel", _panel_style(TITLE_FILL, PANEL_BORDER, 26, 10, Color(0.20, 0.55, 1.0, 0.38)))
	_hud_root.add_child(_title_panel)
	_title_label = _make_label("", 32, TEXT_MAIN, true)
	_subtitle_label = _make_label("", 16, TEXT_SUB, false)
	_title_panel.add_child(_title_label)
	_title_panel.add_child(_subtitle_label)

	category_bar = CATEGORY_BAR_SCRIPT.new()
	category_bar.setup(selected_category)
	category_bar.category_selected.connect(_on_category_selected)
	_hud_root.add_child(category_bar)

	_prev_frame = Panel.new()
	_prev_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prev_frame.add_theme_stylebox_override("panel", _arrow_frame_style(false))
	_hud_root.add_child(_prev_frame)
	prev_button = TextureButton.new()
	prev_button.texture_normal = load(WORD_ARROW_TEXTURE) as Texture2D
	prev_button.ignore_texture_size = true
	prev_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	prev_button.flip_h = true
	prev_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	prev_button.pressed.connect(_on_prev_pressed)
	_hud_root.add_child(prev_button)

	_next_frame = Panel.new()
	_next_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next_frame.add_theme_stylebox_override("panel", _arrow_frame_style(false))
	_hud_root.add_child(_next_frame)
	next_button = TextureButton.new()
	next_button.texture_normal = load(WORD_ARROW_TEXTURE) as Texture2D
	next_button.ignore_texture_size = true
	next_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	next_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_button.pressed.connect(_on_next_pressed)
	_hud_root.add_child(next_button)

	word_icon = TextureButton.new()
	word_icon.ignore_texture_size = true
	word_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	word_icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	word_icon.pressed.connect(_play_word_voice)
	_hud_root.add_child(word_icon)

	score_label = Label.new()
	score_label.name = "HiddenCoinListener"
	score_label.visible = false
	_hud_root.add_child(score_label)

	_round_panel = Panel.new()
	_round_panel.name = "TraceWordsRoundPanel"
	_round_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0a2147"), Color("#af98ff"), 22, 8, Color(0.54, 0.33, 1.0, 0.25)))
	_hud_root.add_child(_round_panel)
	_round_label = _make_label("", 16, TEXT_DIM, false)
	_round_panel.add_child(_round_label)

func _panel_style(fill: Color, border: Color, radius: int, shadow_size: int, shadow: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 0)
	return style

func _arrow_frame_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
	style.bg_color = BTN_ACTIVE if active else BTN_FILL
	style.border_color = PANEL_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.11, 0.77, 1.0, 0.36)
	style.shadow_size = 8
	style.shadow_offset = Vector2.ZERO
	return style

func _make_label(text: String, size_px: int, color: Color, outlined: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	if outlined:
		label.add_theme_color_override("font_outline_color", Color("#051326"))
		label.add_theme_constant_override("outline_size", 3)
	return label

func _find_simulator_host() -> Node:
	var node: Node = self
	for i in range(16):
		if node == null:
			break
		if node.has_method("_style_back_button") or node.has_signal("crystals_earned") or node.has_method("_return_to_cards"):
			return node
		node = node.get_parent()
	return null

func _make_native_back() -> Button:
	var button := Button.new()
	button.name = "TraceWordsBackButton"
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var host: Node = _find_simulator_host()
	if host != null and host.has_method("_style_back_button"):
		host.call("_style_back_button", button)
	else:
		var normal := _panel_style(BTN_FILL, PANEL_BORDER, 18, 6, Color(0.11, 0.77, 1.0, 0.24))
		var hover := _panel_style(BTN_HOVER, PANEL_BORDER, 18, 8, Color(0.11, 0.77, 1.0, 0.36))
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var glyph: Control = NATIVE_BACK.new()
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(glyph)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_exit_pressed)
	return button

func _current_locale() -> String:
	var locale := str(MobileLocale.language)
	if WORD_TEXTS.has(locale):
		return locale
	return "en"

func _apply_language() -> void:
	var phrases: Array = WORD_TEXTS[_current_locale()]
	if _title_label != null:
		_title_label.text = str(phrases[0])
	if _subtitle_label != null:
		_subtitle_label.text = str(phrases[1])
	_update_score()

func _category_button_style(selected: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
	style.bg_color = BTN_ACTIVE if selected else (BTN_HOVER if hover else BTN_FILL)
	style.border_color = PANEL_BORDER if selected else Color("#6aa4ff")
	style.set_border_width_all(4 if selected else 2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.11, 0.77, 1.0, 0.42 if selected else 0.18)
	style.shadow_size = 8 if selected else 3
	style.shadow_offset = Vector2.ZERO
	return style

func _restyle_category_bar() -> void:
	if category_bar == null:
		return
	var buttons: Dictionary = category_bar.get("buttons")
	for category in ObjectCatalog.CATEGORIES:
		var button: Button = buttons.get(category)
		if button == null:
			continue
		var selected: bool = category == selected_category
		button.add_theme_stylebox_override("normal", _category_button_style(selected, false))
		button.add_theme_stylebox_override("hover", _category_button_style(selected, true))
		button.add_theme_stylebox_override("pressed", _category_button_style(true, true))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.modulate = Color.WHITE
		button.scale = Vector2.ONE * (1.06 if selected else 1.0)
		button.tooltip_text = category.capitalize()

func _on_category_selected(category: String) -> void:
	selected_category = category
	_reload_word_pool()
	if word_objects.is_empty():
		return
	word_index = 0
	_load_word()
	_restyle_category_bar()

func _set_score_text(balance: int) -> void:
	if score_label != null:
		score_label.text = str(balance)
	_update_score()

func _simulator_crystals() -> int:
	var host: Node = _find_simulator_host()
	if host == null:
		return 0
	var count: Variant = host.get("_crystal_balance")
	if count is int or count is float:
		return maxi(0, int(count))
	return 0

func _update_score() -> void:
	if _native_hub != null:
		_native_hub.set("crystal_count", _simulator_crystals())
	if _round_label != null:
		var prefix: String = str(WORD_TEXTS[_current_locale()][2])
		_round_label.text = "%s: +%d" % [prefix, _session_earned]

func _finish_word() -> void:
	_session_earned += coins_per_word
	super._finish_word()
	_update_score()

func _load_word(play_voice: bool = true) -> void:
	super._load_word(play_voice)
	_restyle_category_bar()

func _layout_hud_controls() -> void:
	if _hud_root == null or category_bar == null or word_icon == null or prev_button == null or next_button == null:
		return
	var view := get_viewport_rect().size
	if view.x < 100.0 or view.y < 100.0:
		return
	_hud_root.size = view
	if _sky != null:
		_sky.size = view
	if _nebula_overlay != null:
		_nebula_overlay.size = view
	var safe := _safe_area_insets(view)
	var left := safe.x
	var top := safe.y
	var right := view.x - safe.z
	var bottom := view.y - safe.w
	var sw := right - left
	var sh := bottom - top
	var hub_s: float = minf(view.y / 864.0, view.x / 1680.0)
	var counter_s: float = hub_s * 0.80
	var back_s: float = hub_s * 0.60
	var edge_gap: float = maxf(6.0, minf(24.0 * hub_s, sw * 0.03))
	var top_y: float = top + maxf(6.0, 20.0 * hub_s)
	var back_size: float = 158.0 * back_s
	_native_back_button.position = Vector2(left + edge_gap, top_y)
	_native_back_button.size = Vector2.ONE * back_size
	_native_hub.scale = Vector2.ONE * counter_s
	_native_hub.position = Vector2(right - edge_gap - (643.0 + 394.0) * counter_s, top_y)
	var title_left: float = _native_back_button.position.x + back_size + maxf(10.0, 18.0 * hub_s)
	var title_right: float = _native_hub.position.x - maxf(10.0, 18.0 * hub_s)
	var title_w: float = maxf(180.0, title_right - title_left)
	var header_h: float = maxf(back_size, 158.0 * counter_s)
	_title_panel.position = Vector2(title_left, top_y)
	_title_panel.size = Vector2(title_w, header_h)
	var font_scale: float = clampf(minf(sw / 1450.0, sh / 800.0), 0.46, 1.32)
	_title_label.position = Vector2(6.0, header_h * 0.08)
	_title_label.size = Vector2(title_w - 12.0, header_h * 0.58)
	_title_label.add_theme_font_size_override("font_size", maxi(11, roundi(36.0 * font_scale * minf(1.0, 18.0 / float(maxi(1, _title_label.text.length()))))))
	_subtitle_label.position = Vector2(6.0, header_h * 0.68)
	_subtitle_label.size = Vector2(title_w - 12.0, header_h * 0.20)
	_subtitle_label.add_theme_font_size_override("font_size", maxi(8, roundi(17.0 * font_scale)))
	_subtitle_label.visible = title_w > 260.0

	var body_top: float = top_y + header_h + clampf(sh * 0.025, 10.0, 24.0)
	var body_bottom: float = bottom - clampf(sh * 0.025, 10.0, 24.0)
	var body_h: float = maxf(280.0, body_bottom - body_top)
	var outer_gap: float = clampf(sw * 0.018, 12.0, 28.0)
	var between_gap: float = clampf(sw * 0.016, 12.0, 24.0)
	var category_w: float = clampf(sw * 0.12, 132.0, 182.0)
	var main_x: float = left + outer_gap + category_w + between_gap
	var main_w: float = maxf(520.0, right - outer_gap - main_x)
	category_card.position = Vector2(left + outer_gap, body_top)
	category_card.size = Vector2(category_w, body_h)
	main_card.position = Vector2(main_x, body_top)
	main_card.size = Vector2(main_w, body_h)

	var cat_pad: float = clampf(category_w * 0.10, 10.0, 18.0)
	category_bar.set_layout(Rect2(Vector2(category_card.position.x + cat_pad, category_card.position.y + cat_pad), Vector2(category_w - cat_pad * 2.0, body_h - cat_pad * 2.0)), true)

	var icon_size: float = clampf(body_h * 0.18, 118.0, 170.0)
	word_icon.size = Vector2.ONE * icon_size
	word_icon.position = Vector2(main_card.position.x + main_card.size.x * 0.5 - icon_size * 0.5, main_card.position.y + clampf(body_h * 0.035, 16.0, 28.0))
	var arrow_side: float = clampf(icon_size * 0.68, 74.0, 108.0)
	_prev_frame.size = Vector2.ONE * arrow_side
	_next_frame.size = Vector2.ONE * arrow_side
	var arrow_y: float = word_icon.position.y + (icon_size - arrow_side) * 0.5
	var arrow_gap: float = clampf(main_card.size.x * 0.065, 20.0, 54.0)
	_prev_frame.position = Vector2(word_icon.position.x - arrow_gap - arrow_side, arrow_y)
	_next_frame.position = Vector2(word_icon.position.x + icon_size + arrow_gap, arrow_y)
	prev_button.position = _prev_frame.position + Vector2(10.0, 10.0)
	prev_button.size = _prev_frame.size - Vector2(20.0, 20.0)
	next_button.position = _next_frame.position + Vector2(10.0, 10.0)
	next_button.size = _next_frame.size - Vector2(20.0, 20.0)

	var round_h: float = clampf(body_h * 0.085, 52.0, 64.0)
	_round_panel.size = Vector2(clampf(main_card.size.x * 0.28, 220.0, 320.0), round_h)
	_round_panel.position = Vector2(main_card.position.x + main_card.size.x * 0.5 - _round_panel.size.x * 0.5, main_card.position.y + main_card.size.y - round_h - clampf(body_h * 0.035, 16.0, 24.0))
	_round_label.position = Vector2(8.0, 5.0)
	_round_label.size = _round_panel.size - Vector2(16.0, 10.0)
	_round_label.add_theme_font_size_override("font_size", maxi(10, roundi(16.0 * font_scale)))

	var trace_top: float = word_icon.position.y + icon_size + clampf(body_h * 0.03, 12.0, 22.0)
	var trace_bottom: float = _round_panel.position.y - clampf(body_h * 0.03, 12.0, 22.0)
	var trace_side_pad: float = clampf(main_card.size.x * 0.055, 28.0, 52.0)
	var new_trace_size := Vector2(maxf(360.0, main_card.size.x - trace_side_pad * 2.0), maxf(150.0, trace_bottom - trace_top))
	var rebuild_trace: bool = not trace_area_size.is_equal_approx(new_trace_size)
	trace_area_size = new_trace_size
	letter_root.position = Vector2(main_card.position.x + main_card.size.x * 0.5, (trace_top + trace_bottom) * 0.5)
	if rebuild_trace and not strokes.is_empty():
		_load_word(false)
	_update_score()
