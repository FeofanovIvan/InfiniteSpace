extends "res://learning/src/features/matching_pairs/matching_pairs_game.gd"
## MIKA Matching Pairs UI v1. Pure presentation layer over the original game.
## Pair selection, sounds, voices, rewards and round handling are inherited unchanged.

const MIKA_UI_KIT = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const MIKA_SHARED_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_NATIVE_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_BACK_GLYPH = preload("res://simulator_ui/back_arrow_glyph.gd")
const MIKA_SPACE = preload("res://simulator_ui/scripts/real_space_background.gd")

const MIKA_TITLES: Dictionary = {
	"ru": "НАЙДИ ПАРЫ",
	"en": "MATCHING PAIRS",
	"fr": "TROUVE LES PAIRES",
	"de": "FINDE DIE PAARE",
	"es": "ENCUENTRA LAS PAREJAS",
	"pt": "ENCONTRE OS PARES",
}

var _mika_space: Control
var _mika_stage: Panel
var _mika_header_back: Button
var _mika_header_title: Panel
var _mika_header_label: Label
var _mika_header_subtitle: Label
var _mika_crystal_hud: Control
var _mika_stage_bounds: Rect2 = Rect2()


func _build_ui() -> void:
	# Preserve ALL original sound players and logic; hide ONLY old visual chrome.
	super._build_ui()
	background.hide()
	home_button.hide()
	score_back.hide()

	_mika_space = MIKA_SPACE.new() as Control
	_mika_space.name = "MatchingPairs_RealSpaceBackground"
	_mika_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_space.z_index = -20
	add_child(_mika_space)

	_mika_stage = Panel.new()
	_mika_stage.name = "MatchingPairs_SharedGameStage"
	_mika_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_stage.z_index = -10
	_mika_stage.add_theme_stylebox_override("panel", MIKA_UI_KIT.stage_style())
	add_child(_mika_stage)

	_mika_header_back = Button.new()
	_mika_header_back.name = "MatchingPairs_HeaderBack"
	_mika_header_back.focus_mode = Control.FOCUS_NONE
	_mika_header_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_mika_header_back.add_theme_stylebox_override("normal", MIKA_UI_KIT.button_style())
	_mika_header_back.add_theme_stylebox_override("hover", MIKA_UI_KIT.button_style(true))
	_mika_header_back.add_theme_stylebox_override("pressed", MIKA_UI_KIT.button_style(true))
	_mika_header_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_mika_header_back.pressed.connect(_go_home)
	ui_layer.add_child(_mika_header_back)
	var arrow: Control = MIKA_BACK_GLYPH.new() as Control
	arrow.name = "OriginalSimulatorArrowGlyph"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_header_back.add_child(arrow)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_mika_header_title = Panel.new()
	_mika_header_title.name = "MatchingPairs_SharedTitlePlaque"
	_mika_header_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MIKA_SHARED_TOOLBAR.apply_title_style(_mika_header_title)
	ui_layer.add_child(_mika_header_title)

	_mika_header_label = Label.new()
	_mika_header_label.name = "MatchingPairs_LocalizedTitle"
	_mika_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mika_header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mika_header_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_header_label.clip_text = true
	_mika_header_label.add_theme_color_override("font_color", Color.WHITE)
	_mika_header_title.add_child(_mika_header_label)

	_mika_header_subtitle = Label.new()
	_mika_header_subtitle.name = "MatchingPairs_EmptySubtitle"
	_mika_header_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_header_title.add_child(_mika_header_subtitle)

	# Use the real PlanetHub crystal counter, not a redrawn star score panel.
	_mika_crystal_hud = MIKA_NATIVE_HUD.new() as Control
	_mika_crystal_hud.name = "MatchingPairs_OriginalCrystalHUD"
	_mika_crystal_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_crystal_hud.size = Vector2(1680.0, 158.0)
	ui_layer.add_child(_mika_crystal_hud)
	for node_name in ["SimulatorButton", "LaunchButton"]:
		var button: Control = _mika_crystal_hud.get_node_or_null(node_name) as Control
		if button != null:
			button.hide()
	_mika_crystal_hud.set("crystal_count", GameState.get_coin_balance())
	if not GameState.coin_balance_changed.is_connected(_mika_on_coin_balance_changed):
		GameState.coin_balance_changed.connect(_mika_on_coin_balance_changed)
	if not MobileLocale.language_changed.is_connected(_mika_on_language_changed):
		MobileLocale.language_changed.connect(_mika_on_language_changed)
	_mika_on_language_changed(str(MobileLocale.language))


func _mika_on_language_changed(locale: String) -> void:
	if _mika_header_label == null:
		return
	var code: String = locale.to_lower()
	if code.begins_with("pt"):
		code = "pt"
	elif code.length() > 2:
		code = code.substr(0, 2)
	_mika_header_label.text = str(MIKA_TITLES.get(code, MIKA_TITLES["en"]))
	_layout()


func _mika_on_coin_balance_changed(balance: int) -> void:
	if _mika_crystal_hud != null:
		_mika_crystal_hud.set("crystal_count", balance)


func _layout() -> void:
	if _mika_space == null or _mika_header_back == null or _mika_stage == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x < 190.0 or viewport_size.y < 190.0:
		return
	_mika_space.position = Vector2.ZERO
	_mika_space.size = viewport_size
	var insets: Vector4 = _safe_area_insets(viewport_size)
	var safe: Rect2 = Rect2(
		Vector2(insets.x, insets.y),
		Vector2(maxf(190.0, viewport_size.x - insets.x - insets.z),
		maxf(190.0, viewport_size.y - insets.y - insets.w))
	)
	var top_bottom: float = MIKA_SHARED_TOOLBAR.relayout(viewport_size, safe,
		_mika_header_back, _mika_crystal_hud, _mika_header_title,
		_mika_header_label, _mika_header_subtitle)
	# One centered title line, no secondary row or legacy in-game indicators.
	_mika_header_subtitle.hide()
	_mika_header_label.position = Vector2(6.0, 0.0)
	_mika_header_label.size = Vector2(maxf(32.0, _mika_header_title.size.x - 12.0),
		_mika_header_title.size.y)

	var margin: float = clampf(minf(safe.size.x, safe.size.y) * 0.026, 10.0, 28.0)
	var gap: float = clampf(safe.size.y * 0.018, 7.0, 18.0)
	var board_y: float = minf(safe.end.y - 110.0, top_bottom + gap)
	_mika_stage_bounds = Rect2(
		Vector2(safe.position.x + margin, board_y),
		Vector2(maxf(100.0, safe.size.x - 2.0 * margin),
			maxf(95.0, safe.end.y - board_y - margin))
	)
	_mika_stage.position = _mika_stage_bounds.position
	_mika_stage.size = _mika_stage_bounds.size
	_layout_doors(false)


func _layout_doors(animated: bool) -> void:
	if doors.is_empty() or _mika_stage == null or _mika_stage_bounds.size.x < 70.0:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / 1536.0, viewport_size.y / 768.0)
	var padding: float = clampf(minf(_mika_stage_bounds.size.x,
		_mika_stage_bounds.size.y) * 0.045, 13.0, 34.0)
	var inner: Rect2 = _mika_stage_bounds.grow(-padding)
	var columns: int = 4 if doors.size() >= 8 else maxi(2, int(ceil(float(doors.size()) / 2.0)))
	var rows: int = int(ceil(float(doors.size()) / float(columns)))
	var horizontal_gap: float = clampf(inner.size.x * 0.014, 7.0, 24.0)
	var vertical_gap: float = clampf(inner.size.y * 0.031, 7.0, 20.0)
	var available_width: float = maxf(60.0, inner.size.x - horizontal_gap * float(columns - 1))
	var available_height: float = maxf(60.0, inner.size.y - vertical_gap * float(rows - 1))
	var door_height: float = minf(available_height / float(rows), 285.0 * scale_factor)
	var door_width: float = door_height * 0.75
	if door_width * float(columns) > available_width:
		door_width = available_width / float(columns)
		door_height = door_width / 0.75
	var total_height: float = door_height * float(rows) + vertical_gap * float(rows - 1)
	var start_y: float = inner.position.y + maxf(0.0, (inner.size.y - total_height) * 0.5)
	for index in range(doors.size()):
		var row: int = index / columns
		var first_in_row: int = row * columns
		var items_in_row: int = mini(columns, doors.size() - first_in_row)
		var row_width: float = door_width * float(items_in_row) + horizontal_gap * float(items_in_row - 1)
		var column: int = index - first_in_row
		var target: Vector2 = Vector2(
			inner.position.x + (inner.size.x - row_width) * 0.5
				+ float(column) * (door_width + horizontal_gap),
			start_y + float(row) * (door_height + vertical_gap)
		)
		var current_door: MatchingDoor = doors[index]
		current_door.size = Vector2(door_width, door_height)
		current_door.pivot_offset = current_door.size * 0.5
		if animated:
			var tween := create_tween()
			tween.tween_property(current_door, "position", target, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			current_door.position = target
