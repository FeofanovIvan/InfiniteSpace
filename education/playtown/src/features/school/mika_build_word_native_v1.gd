extends "res://education/playtown/src/features/school/school_game.gd"
## MIKA | Build a Word / v1.0
## Keeps the original Safe City Kids dragging, artwork, words and audio.
## Uses native Simulator HUD, per-entry crystal counter, bright nebulae,
## pale-blue glass panels and browse arrows at both sides of the object.

const MKA_BACKGROUND := preload("res://simulator_ui/scripts/real_space_background.gd")
const MKA_NEBULA := preload("res://simulator_ui/scripts/mika_minigame_nebula_layer.gd")
const MKA_BACK_GLYPH := preload("res://simulator_ui/back_arrow_glyph.gd")
const MKA_HUD := preload("res://planet_hub/scripts/bottom_hud.gd")
const MKA_TOOLBAR := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")

const MKA_TEXTS: Dictionary = {
	"ru": ["СОБЕРИ СЛОВО", "Перетащи буквы на свои места"],
	"en": ["BUILD A WORD", "Drag the letters into place"],
	"fr": ["FORME UN MOT", "Glisse les lettres à leur place"],
	"de": ["WORT BAUEN", "Ziehe die Buchstaben an ihren Platz"],
	"es": ["FORMA UNA PALABRA", "Arrastra las letras a su lugar"],
	"pt_BR": ["MONTE UMA PALAVRA", "Arraste as letras para o lugar certo"]
}

const MKA_CYAN := Color("#65e9ff")
const MKA_GLASS := Color(0.09, 0.26, 0.50, 0.83)
const MKA_TRAY := Color(0.12, 0.34, 0.59, 0.88)
const MKA_SELECTED := Color("#63e9ff")

var _mka_sky_layer: CanvasLayer
var _mka_sky: Control
var _mka_nebula: Control
var _mka_ui_root: Control
var _mka_native_back: Button
var _mka_native_counter: Control
var _mka_title_panel: Panel
var _mka_title: Label
var _mka_subtitle: Label
var _mka_picture_frame: Panel
var _mka_left_arrow: Button
var _mka_right_arrow: Button
var _mka_original_back: BaseButton
var _mka_session_crystals: int = 0
var _mka_rewarded_words: Dictionary = {}
var _mka_reward_committed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mka_session_crystals = 0
	super._ready()
	_mka_refresh_texts()
	_mka_style_categories()
	_update_score()
	var host: Node = _mka_find_simulator()
	if host != null:
		_mka_original_back = host.get_node_or_null("PlayTownOriginalGameRunner/ReturnToEducationalCards") as BaseButton
		if is_instance_valid(_mka_original_back):
			_mka_original_back.hide()
	if has_node("/root/MobileLocale"):
		var mobile: Node = get_node("/root/MobileLocale")
		if mobile.has_signal("language_changed"):
			mobile.language_changed.connect(_mka_on_locale_changed)

func _mka_on_locale_changed(_locale: String) -> void:
	_mka_refresh_texts()
	_layout_for_viewport()

func _build_scene() -> void:
	super._build_scene()
	# The flight background is rendered behind the original content layers.
	_mka_sky_layer = CanvasLayer.new()
	_mka_sky_layer.layer = -15
	_mka_sky_layer.name = "MikaRealSpaceBackgroundLayer"
	add_child(_mka_sky_layer)
	_mka_sky = MKA_BACKGROUND.new()
	_mka_sky.name = "ActualRealSpaceBackground"
	_mka_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mka_sky_layer.add_child(_mka_sky)
	_mka_sky.size = get_viewport_rect().size
	_mka_nebula = MKA_NEBULA.new()
	_mka_nebula.name = "BrightCrossroadsNebulae"
	_mka_nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mka_sky.add_child(_mka_nebula)
	_mka_nebula.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mka_nebula.size = _mka_sky.size
	wall.color.a = 0.0
	floor.color.a = 0.0

	category_panel.add_theme_stylebox_override("panel", _mka_glass_style(MKA_GLASS, Color("#8adfff"), 28))
	activity_card.add_theme_stylebox_override("panel", _mka_glass_style(MKA_GLASS, MKA_CYAN, 30))
	letters_tray.add_theme_stylebox_override("panel", _mka_glass_style(MKA_TRAY, Color("#92dfff"), 28))

	# An unobtrusive outline *behind* the existing original object texture.
	_mka_picture_frame = Panel.new()
	_mka_picture_frame.name = "ObjectPictureNeonBackdrop"
	_mka_picture_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mka_picture_frame.add_theme_stylebox_override("panel", _mka_glass_style(Color(0.08, 0.20, 0.39, 0.42), Color("#8befff"), 22))
	background_layer.add_child(_mka_picture_frame)
	background_layer.move_child(_mka_picture_frame, background_layer.get_children().find(icon_rect))

	# Hide the old star/coin UI and PlayTown exit. Neither is deleted: the
	# legacy game still owns its state, while MIKA displays session crystals.
	home_button.hide()
	score_back.hide()

	_mka_ui_root = Control.new()
	_mka_ui_root.name = "MIKABuildWordHUD"
	_mka_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mka_ui_root.size = get_viewport_rect().size
	ui_layer.add_child(_mka_ui_root)

	_mka_native_back = _mka_native_button("MIKASimulatorBack", false)
	_mka_native_back.pressed.connect(_go_home)
	_mka_ui_root.add_child(_mka_native_back)

	_mka_native_counter = MKA_HUD.new() as Control
	_mka_native_counter.name = "OriginalPlanetHubCrystalCounter"
	_mka_native_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mka_native_counter.size = Vector2(1680, 158)
	_mka_ui_root.add_child(_mka_native_counter)
	var sim: Control = _mka_native_counter.get_node_or_null("SimulatorButton") as Control
	var launch: Control = _mka_native_counter.get_node_or_null("LaunchButton") as Control
	if sim != null:
		sim.hide()
	if launch != null:
		launch.hide()

	_mka_title_panel = Panel.new()
	_mka_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mka_title_panel.name = "SharedNativeGameTitle"
	MKA_TOOLBAR.apply_title_style(_mka_title_panel)
	_mka_ui_root.add_child(_mka_title_panel)
	_mka_title = _mka_label("")
	_mka_subtitle = _mka_label("")
	_mka_title_panel.add_child(_mka_title)
	_mka_title_panel.add_child(_mka_subtitle)

	# The picture has the same previous/next controls as Trace Words.
	_mka_left_arrow = _mka_native_button("PreviousWord", false)
	_mka_right_arrow = _mka_native_button("NextWord", true)
	_mka_left_arrow.pressed.connect(_mka_select_word.bind(-1))
	_mka_right_arrow.pressed.connect(_mka_select_word.bind(1))
	_mka_ui_root.add_child(_mka_left_arrow)
	_mka_ui_root.add_child(_mka_right_arrow)

func _mka_glass_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.anti_aliasing = true
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.13, 0.69, 1.0, 0.42)
	style.shadow_size = 11
	style.shadow_offset = Vector2.ZERO
	return style

func _mka_label(caption: String) -> Label:
	var lbl := Label.new()
	lbl.text = caption
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color("#effaff"))
	lbl.add_theme_color_override("font_outline_color", Color("#05203d"))
	lbl.add_theme_constant_override("outline_size", 2)
	return lbl

func _mka_find_simulator() -> Node:
	var p: Node = self
	for i in range(16):
		if p == null:
			break
		if p.has_method("_return_to_cards") and p.has_signal("crystals_earned"):
			return p
		p = p.get_parent()
	return null

func _mka_native_button(button_name: String, to_right: bool) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var host: Node = _mka_find_simulator()
	if host != null and host.has_method("_style_back_button"):
		host.call("_style_back_button", button)
	else:
		var normal: StyleBoxFlat = _mka_glass_style(Color("#082144"), Color("#26dfff"), 18)
		var hover: StyleBoxFlat = _mka_glass_style(Color("#12466b"), Color("#57e9ff"), 18)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var arrow: Control = MKA_BACK_GLYPH.new()
		arrow.name = "ThickNeonBackArrow"
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(arrow)
		arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if to_right:
		# Turn the native back glyph by 180°, never mirror a bitmap.
		var arrow_node: Control = button.get_node_or_null("ThickNeonBackArrow") as Control
		if arrow_node != null:
			arrow_node.set_meta("mika_right_arrow", true)
	return button

func _mka_refresh_texts() -> void:
	if _mka_title == null:
		return
	var locale: String = "en"
	if has_node("/root/MobileLocale"):
		locale = str(MobileLocale.language)
	if not MKA_TEXTS.has(locale):
		locale = "en"
	var labels: Array = MKA_TEXTS[locale]
	_mka_title.text = str(labels[0])
	_mka_subtitle.text = str(labels[1])

func _mka_style_categories() -> void:
	if category_bar == null:
		return
	if category_bar.has_method("_apply_styles"):
		category_bar.call("_apply_styles")
	var buttons: Dictionary = category_bar.get("buttons")
	var selected: Button = buttons.get(selected_category) as Button
	if selected != null:
		var cyan := _mka_glass_style(Color("#58e9ff"), Color("#ddfdff"), 18)
		cyan.set_border_width_all(4)
		cyan.shadow_color = Color(0.24, 0.85, 1.0, 0.62)
		selected.add_theme_stylebox_override("normal", cyan)
		selected.add_theme_stylebox_override("hover", cyan)
		selected.add_theme_stylebox_override("pressed", cyan)

func _on_category_selected(category: String) -> void:
	super._on_category_selected(category)
	_mka_style_categories()

func _mka_select_word(direction: int) -> void:
	if game_words.is_empty() or waiting_next_word or game_over:
		return
	current_word_index = wrapi(current_word_index + direction, 0, game_words.size())
	_load_current_word()

func _load_current_word() -> void:
	# Let the child browse among the five words. When reaching the end,
	# resume the first unsolved entry instead of losing a pending lesson.
	if current_word_index >= game_words.size() and not game_words.is_empty():
		var unfinished: int = _mka_first_unsolved_word()
		if unfinished >= 0:
			current_word_index = unfinished
	super._load_current_word()
	_mka_restyle_slots()

func _mka_word_key(word: String) -> String:
	return str(LanguageService.current_locale) + "|" + selected_category + "|" + word.to_upper()

func _mka_first_unsolved_word() -> int:
	for idx in range(game_words.size()):
		if not _mka_rewarded_words.has(_mka_word_key(game_words[idx])):
			return idx
	return -1

func _mka_restyle_slots() -> void:
	for slot in slot_nodes:
		var block: Panel = slot.get("panel") as Panel
		if block == null:
			continue
		block.add_theme_stylebox_override("panel", _mka_glass_style(Color(0.15, 0.39, 0.62, 0.91), Color("#a7efff"), 15))
		var hint: Label = slot.get("hint_label") as Label
		if hint != null:
			hint.add_theme_color_override("font_color", Color(0.83, 0.97, 1.0, 0.27))
		var placed: Label = slot.get("placed_label") as Label
		if placed != null:
			placed.add_theme_color_override("font_color", Color("#ecfaff"))

func _on_letter_dropped_on_slot(item, slot) -> void:
	# The old SchoolGame awarded PlayTown coins for every tile. In MIKA,
	# these would be converted to fuel immediately and double-counted.
	if game_over or waiting_next_word:
		item.reset_to_start()
		return
	var index: int = int(slot.index)
	if index < 0 or index >= current_word.length() or slot_letters[index] != "":
		item.reset_to_start()
		return
	if str(item.letter).to_upper() != current_word[index]:
		_show_error()
		item.reset_to_start()
		return
	slot_letters[index] = str(item.letter).to_upper()
	letters_placed += 1
	score += 1
	GameState.last_score = score
	slot.place_letter(item.letter)
	var placed: Label = slot.get("placed_label") as Label
	if placed != null:
		placed.add_theme_color_override("font_color", Color("#a0f6ff"))
	var panel: Panel = slot.get("panel") as Panel
	if panel != null:
		panel.add_theme_stylebox_override("panel", _mka_glass_style(Color(0.11, 0.47, 0.58, 0.93), Color("#70ffe7"), 15))
	item.set_enabled(false)
	if correct_sound != null:
		correct_player.stop()
		correct_player.stream = correct_sound
		correct_player.play()
	if letters_placed >= current_word.length():
		_complete_word()

func _complete_word() -> void:
	if waiting_next_word or game_over:
		return
	var key: String = _mka_word_key(current_word)
	if not _mka_rewarded_words.has(key):
		_mka_rewarded_words[key] = true
		_mka_session_crystals += 1
		_update_score()
	super._complete_word()

func _update_score() -> void:
	if _mka_native_counter != null:
		_mka_native_counter.set("crystal_count", _mka_session_crystals)
	# Keep the original results score internal; the displayed crystal HUD is
	# 0 on entry and increases only when a NEW word is fully completed.
	if score_label != null:
		score_label.text = str(score)

func _mka_commit_reward() -> void:
	if _mka_reward_committed:
		return
	_mka_reward_committed = true
	if _mka_session_crystals <= 0:
		return
	var host: Node = _mka_find_simulator()
	if host != null and host.has_signal("crystals_earned"):
		host.emit_signal("crystals_earned", _mka_session_crystals)
		# Update the visible simulator meter from actual Main fuel, not a
		# hardcoded 50. Main._on_fuel_collected enforces current capacity.
		var walk: Node = host.get_parent()
		for i in range(8):
			if walk == null:
				break
			var fuel: Variant = walk.get("_fuel_units")
			if fuel is int or fuel is float:
				if host.has_method("set_stats"):
					host.call("set_stats", maxi(0, floori(float(fuel) + 0.001)), 0, 0.0)
				break
			walk = walk.get_parent()

func _go_home() -> void:
	_mka_commit_reward()
	SFX.transition_to_scene(results_scene_path)

func _finish_game() -> void:
	if game_over:
		return
	_mka_commit_reward()
	super._finish_game()

func _exit_tree() -> void:
	_mka_commit_reward()
	if is_instance_valid(_mka_original_back):
		_mka_original_back.show()

func _layout_for_viewport() -> void:
	var view: Vector2 = get_viewport_rect().size
	if view.x < 120.0 or view.y < 120.0 or _mka_ui_root == null:
		return
	_mka_ui_root.size = view
	if _mka_sky != null:
		_mka_sky.size = view
	if _mka_nebula != null:
		_mka_nebula.size = view

	var ins: Vector4 = _safe_area_insets(view)
	var safe := Rect2(Vector2(ins.x, ins.y), view - Vector2(ins.x + ins.z, ins.y + ins.w))
	var toolbar_bottom: float = MKA_TOOLBAR.relayout(view, safe, _mka_native_back, _mka_native_counter, _mka_title_panel, _mka_title, _mka_subtitle)
	var back_and_gap: float = maxf(7.0, safe.size.y * 0.022)
	var body_top: float = toolbar_bottom + back_and_gap
	var bottom: float = safe.end.y - maxf(7.0, safe.size.y * 0.021)
	var body_h: float = maxf(65.0, bottom - body_top)
	var sw: float = safe.size.x
	var outer: float = maxf(6.0, minf(26.0, sw * 0.018))
	var gap: float = maxf(6.0, minf(22.0, sw * 0.016))
	var is_portrait: bool = sw < safe.size.y * 0.88
	var content_x: float
	var content_w: float
	var content_y: float = body_top
	var content_h: float = body_h

	if is_portrait:
		var bar_h: float = clampf(body_h * 0.11, 42.0, 74.0)
		category_panel.position = Vector2(safe.position.x + outer, body_top)
		category_panel.size = Vector2(maxf(30.0, sw - outer * 2.0), bar_h)
		var pad: float = maxf(3.0, bar_h * 0.07)
		category_bar.set_layout(Rect2(category_panel.position + Vector2(pad, pad), category_panel.size - Vector2(pad * 2.0, pad * 2.0)), false)
		content_y = body_top + bar_h + gap
		content_h = maxf(42.0, body_h - bar_h - gap)
		content_x = safe.position.x + outer
		content_w = maxf(28.0, sw - outer * 2.0)
	else:
		var bar_w: float = clampf(sw * 0.11, 76.0, 174.0)
		category_panel.position = Vector2(safe.position.x + outer, body_top)
		category_panel.size = Vector2(bar_w, body_h)
		var pad: float = clampf(bar_w * 0.09, 5.0, 17.0)
		category_bar.set_layout(Rect2(category_panel.position + Vector2(pad, pad), category_panel.size - Vector2(pad * 2.0, pad * 2.0)), true)
		content_x = safe.position.x + outer + bar_w + gap
		content_w = maxf(28.0, safe.end.x - outer - content_x)

	var tray_h: float = clampf(content_h * 0.28, 72.0, 200.0)
	var panel_h: float = maxf(50.0, content_h - tray_h - gap)
	var image_panel := Rect2(content_x, content_y, content_w, panel_h)
	var tray_panel := Rect2(content_x, content_y + panel_h + gap, content_w, tray_h)
	activity_card.position = image_panel.position
	activity_card.size = image_panel.size
	letters_tray.position = tray_panel.position
	letters_tray.size = tray_panel.size

	var image_size: float = minf(minf(content_w * (0.32 if is_portrait else 0.17), panel_h * 0.44), 185.0)
	image_size = maxf(27.0, image_size)
	var image_center := Vector2(content_x + content_w * 0.5, content_y + maxf(11.0, panel_h * 0.048) + image_size * 0.5)
	var frame_side: float = image_size * 1.12
	_mka_picture_frame.size = Vector2.ONE * frame_side
	_mka_picture_frame.position = image_center - _mka_picture_frame.size * 0.5
	icon_rect.size = Vector2.ONE * image_size
	icon_rect.position = image_center - Vector2.ONE * (image_size * 0.5)

	# Prev / next stay immediately beside the image, just like Trace Words.
	var arrow_side: float = clampf(image_size * 0.55, 28.0, 94.0)
	var arrow_offset: float = maxf(7.0, minf(content_w * 0.06, 44.0))
	_mka_left_arrow.size = Vector2.ONE * arrow_side
	_mka_right_arrow.size = Vector2.ONE * arrow_side
	_mka_left_arrow.position = Vector2(image_center.x - image_size * 0.5 - arrow_side - arrow_offset, image_center.y - arrow_side * 0.5)
	_mka_right_arrow.position = Vector2(image_center.x + image_size * 0.5 + arrow_offset, image_center.y - arrow_side * 0.5)
	for arrow_button in [_mka_left_arrow, _mka_right_arrow]:
		var arrow_glyph: Control = arrow_button.get_node_or_null("ThickNeonBackArrow") as Control
		if arrow_glyph != null:
			arrow_glyph.size = arrow_button.size
			arrow_glyph.pivot_offset = arrow_glyph.size * 0.5
			arrow_glyph.rotation = PI if arrow_glyph.has_meta("mika_right_arrow") else 0.0

	var count: int = slot_nodes.size()
	if count > 0:
		var columns: int = mini(count, 6 if is_portrait else 12)
		var rows: int = ceili(float(count) / float(columns))
		var slots_gap: float = maxf(3.0, minf(12.0, content_w * 0.013))
		var slots_width: float = content_w * 0.90
		var available_slot_h: float = maxf(18.0, panel_h - (image_center.y - content_y + image_size * 0.5) - 12.0)
		var cell: float = minf(minf(96.0, (slots_width - (columns - 1) * slots_gap) / columns), (available_slot_h - (rows - 1) * slots_gap) / rows)
		cell = maxf(10.0, cell)
		var y_start: float = image_panel.end.y - maxf(8.0, panel_h * 0.04) - (rows * cell + (rows - 1) * slots_gap)
		for i in range(count):
			var row: int = int(i / columns)
			var col: int = i % columns
			var row_length: int = mini(columns, count - row * columns)
			var row_width: float = float(row_length) * cell + float(row_length - 1) * slots_gap
			slot_nodes[i].position = Vector2(image_center.x - row_width * 0.5 + cell * 0.5 + col * (cell + slots_gap), y_start + row * (cell + slots_gap) + cell * 0.5)
			slot_nodes[i].set_display_size(Vector2.ONE * cell)

	# Keep all colored choice letters visible; two rows on narrow screens.
	var tiles: int = letter_items.size()
	if tiles > 0:
		var tile_columns: int = mini(tiles, 7 if is_portrait else 14)
		var tile_rows: int = ceili(float(tiles) / float(tile_columns))
		var tile_gap: float = maxf(2.0, minf(12.0, content_w * 0.012))
		var tile_w: float = maxf(16.0, content_w - 24.0)
		var tile_h: float = maxf(18.0, tray_h - 14.0)
		var tile_side: float = minf(minf(86.0, (tile_w - (tile_columns - 1) * tile_gap) / tile_columns), (tile_h - (tile_rows - 1) * tile_gap) / tile_rows)
		tile_side = maxf(10.0, tile_side)
		var choice_top: float = tray_panel.position.y + (tray_h - tile_rows * tile_side - (tile_rows - 1) * tile_gap) * 0.5
		for i in range(tiles):
			var row: int = int(i / tile_columns)
			var col: int = i % tile_columns
			var row_length: int = mini(tile_columns, tiles - row * tile_columns)
			var row_width: float = row_length * tile_side + (row_length - 1) * tile_gap
			var target := Vector2(image_center.x - row_width * 0.5 + tile_side * 0.5 + col * (tile_side + tile_gap), choice_top + row * (tile_side + tile_gap) + tile_side * 0.5)
			var item = letter_items[i]
			item.set_display_size(Vector2.ONE * tile_side)
			if not item.dragging:
				item.set_start_position(target)

	error_flash.position = Vector2.ZERO
	error_flash.size = view
	success_mark.size = Vector2.ONE * minf(135.0, panel_h * 0.28)
	success_mark.position = image_center - success_mark.size * 0.5
	success_mark.add_theme_font_size_override("font_size", roundi(success_mark.size.x * 0.72))
	_update_score()
