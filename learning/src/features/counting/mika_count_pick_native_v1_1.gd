extends "res://learning/src/features/counting/count_pick_game.gd"
## MIKA Pick Up a Number v1.1 — explicit scene script path (no stale UID).
## Reuses the original product pictures, answer buttons, animations and voices.
## All round mechanics stay in count_pick_game.gd; only UI and reward bookkeeping
## are changed. The global praise pause bug is fixed in sound_service.gd.

const MIKA_NUM_SPACE := preload("res://simulator_ui/scripts/real_space_background.gd")
const MIKA_NUM_NEBULA := preload("res://simulator_ui/scripts/mika_minigame_nebula_layer.gd")
const MIKA_NUM_TOOLBAR := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_NUM_HUB := preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_NUM_BACK := preload("res://simulator_ui/back_arrow_glyph.gd")

const MIKA_NUM_TEXT := {
	"ru": ["ВЫБЕРИ ЧИСЛО", "Сосчитай предметы и выбери число"],
	"en": ["PICK A NUMBER", "Count the objects and choose a number"],
	"pt_BR": ["ESCOLHA O NÚMERO", "Conte os objetos e escolha o número"],
	"es": ["ELIGE EL NÚMERO", "Cuenta los objetos y elige el número"],
	"fr": ["CHOISIS LE NOMBRE", "Compte les objets et choisis le nombre"],
	"de": ["WÄHLE DIE ZAHL", "Zähle die Gegenstände und wähle die Zahl"]
}

# Original game-space bounds: product grid x~270...850, equals ~870...980,
# three answer buttons x=1120...1270, y~119...649.
const MIKA_NUM_GAME_BOUNDS := Rect2(240.0, 106.0, 1050.0, 550.0)

var _mika_num_space: Control
var _mika_num_nebula: Control
var _mika_num_body: Panel
var _mika_num_toolbar_root: Control
var _mika_num_back: Button
var _mika_num_hub: Control
var _mika_num_plaque: Panel
var _mika_num_title: Label
var _mika_num_subtitle: Label
var _mika_num_next: Button
var _mika_num_earned: int = 0
var _mika_num_awarded: Dictionary = {}
var _mika_num_settled: bool = false
var _mika_num_host_back: BaseButton
var _mika_num_ui_ready: bool = false

func _ready() -> void:
	set_meta("mika_pick_number_version", "v1.1-uid-repaired")
	print("[MIKA PICK NUMBER v1.1] ACTIVE from scene: ", scene_file_path, " | script: ", (get_script() as Script).resource_path)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Suppress legacy PlayTown coins; rewards go into the ship exactly once
	# via the simulator's crystals_earned signal when the player leaves.
	coins_per_round = 0
	_mika_num_awarded.clear()
	_mika_num_earned = 0
	_mika_num_settled = false
	super._ready()
	_mika_num_ui_ready = true
	_mika_num_language()
	var host: Node = _mika_num_find_host()
	if host != null:
		_mika_num_host_back = host.get_node_or_null("EmbeddedGameRunner/ReturnToEducationalCards") as BaseButton
		if is_instance_valid(_mika_num_host_back):
			_mika_num_host_back.hide()
	get_viewport().size_changed.connect(_mika_num_layout)
	if not MobileLocale.language_changed.is_connected(_mika_num_on_language):
		MobileLocale.language_changed.connect(_mika_num_on_language)
	_mika_num_update_score()
	_mika_num_layout()

func _mika_num_style(fill: Color, stroke: Color, radius: int) -> StyleBoxFlat:
	var skin := StyleBoxFlat.new()
	skin.anti_aliasing = true
	skin.bg_color = fill
	skin.border_color = stroke
	skin.set_border_width_all(3)
	skin.set_corner_radius_all(radius)
	skin.shadow_color = Color(0.20, 0.65, 1.0, 0.22)
	skin.shadow_size = 10
	skin.shadow_offset = Vector2.ZERO
	return skin

func _build_background() -> void:
	_mika_num_space = MIKA_NUM_SPACE.new() as Control
	_mika_num_space.name = "MikaCountRealSpace"
	_mika_num_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_num_space.z_index = -30
	add_child(_mika_num_space)
	_mika_num_nebula = MIKA_NUM_NEBULA.new() as Control
	_mika_num_nebula.name = "MikaCountNebulaLayer"
	_mika_num_nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_num_space.add_child(_mika_num_nebula)
	_mika_num_body = Panel.new()
	_mika_num_body.name = "MikaCountGameBody"
	_mika_num_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_num_body.z_index = -10
	_mika_num_body.add_theme_stylebox_override("panel", _mika_num_style(Color(0.07, 0.17, 0.35, 0.84), Color("#55dfff"), 28))
	add_child(_mika_num_body)

func _mika_num_label(color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#061831"))
	label.add_theme_constant_override("outline_size", 2)
	return label

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "MikaCountNativeHUD"
	hud.layer = 2
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	_mika_num_toolbar_root = Control.new()
	_mika_num_toolbar_root.name = "MikaCountNativeToolbar"
	_mika_num_toolbar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_mika_num_toolbar_root)
	_mika_num_back = Button.new()
	_mika_num_back.name = "SimulatorNativeBack"
	_mika_num_back.focus_mode = Control.FOCUS_NONE
	_mika_num_back.text = ""
	_mika_num_back.mouse_filter = Control.MOUSE_FILTER_STOP
	_mika_num_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var host: Node = _mika_num_find_host()
	if host != null and host.has_method("_style_back_button"):
		host.call("_style_back_button", _mika_num_back)
	else:
		_mika_num_back.add_theme_stylebox_override("normal", _mika_num_style(Color("#09264a"), Color("#49dfff"), 17))
		_mika_num_back.add_theme_stylebox_override("hover", _mika_num_style(Color("#19436e"), Color("#9af5ff"), 17))
		_mika_num_back.add_theme_stylebox_override("pressed", _mika_num_style(Color("#19436e"), Color("#9af5ff"), 17))
		_mika_num_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var arrow: Control = MIKA_NUM_BACK.new() as Control
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mika_num_back.add_child(arrow)
		arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mika_num_back.pressed.connect(_on_exit_pressed)
	_mika_num_toolbar_root.add_child(_mika_num_back)

	_mika_num_hub = MIKA_NUM_HUB.new() as Control
	_mika_num_hub.name = "OriginalPlanetHubCrystalCounter"
	_mika_num_hub.size = Vector2(1680.0, 158.0)
	_mika_num_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mika_num_toolbar_root.add_child(_mika_num_hub)
	var simulator_control: Control = _mika_num_hub.get_node_or_null("SimulatorButton") as Control
	var launch_control: Control = _mika_num_hub.get_node_or_null("LaunchButton") as Control
	if simulator_control != null:
		simulator_control.hide()
	if launch_control != null:
		launch_control.hide()
	_mika_num_hub.set("crystal_count", 0)

	_mika_num_plaque = Panel.new()
	_mika_num_plaque.name = "SharedTitleToolbarPlaque"
	_mika_num_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MIKA_NUM_TOOLBAR.apply_title_style(_mika_num_plaque)
	_mika_num_toolbar_root.add_child(_mika_num_plaque)
	_mika_num_title = _mika_num_label(Color("#f4fdff"))
	_mika_num_subtitle = _mika_num_label(Color("#a9e5ff"))
	_mika_num_plaque.add_child(_mika_num_title)
	_mika_num_plaque.add_child(_mika_num_subtitle)

	# The original game's Next action remains available beside the board.
	_mika_num_next = Button.new()
	_mika_num_next.name = "NextNumber"
	_mika_num_next.text = "❯"
	_mika_num_next.tooltip_text = "Next / Дальше"
	_mika_num_next.focus_mode = Control.FOCUS_NONE
	_mika_num_next.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_mika_num_next.add_theme_color_override("font_color", Color("#e9fbff"))
	_mika_num_next.add_theme_stylebox_override("normal", _mika_num_style(Color("#0d2f55"), Color("#55dfff"), 14))
	_mika_num_next.add_theme_stylebox_override("hover", _mika_num_style(Color("#23547b"), Color("#9df4ff"), 14))
	_mika_num_next.add_theme_stylebox_override("pressed", _mika_num_style(Color("#23547b"), Color("#9df4ff"), 14))
	_mika_num_next.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_mika_num_next.pressed.connect(_on_next_pressed)
	_mika_num_toolbar_root.add_child(_mika_num_next)

	# Keep the parent's GameState signal target, but don't show PlayTown totals.
	score_label = Label.new()
	score_label.name = "HiddenPlayTownCoinListener"
	score_label.visible = false
	_mika_num_toolbar_root.add_child(score_label)

func _mika_num_find_host() -> Node:
	var cursor: Node = get_parent()
	for _i in range(20):
		if cursor == null:
			break
		if cursor.has_method("_return_to_cards") and cursor.has_signal("crystals_earned"):
			return cursor
		cursor = cursor.get_parent()
	return null

func _mika_num_language() -> void:
	if _mika_num_title == null:
		return
	var locale: String = str(MobileLocale.language)
	if not MIKA_NUM_TEXT.has(locale):
		locale = "en"
	_mika_num_title.text = str(MIKA_NUM_TEXT[locale][0])
	_mika_num_subtitle.text = str(MIKA_NUM_TEXT[locale][1])

func _mika_num_on_language(_locale: String) -> void:
	_mika_num_language()
	if _mika_num_ui_ready:
		_mika_num_layout()

func _mika_num_safe_area(view: Vector2) -> Rect2:
	if OS.get_name() not in ["Android", "iOS"]:
		return Rect2(Vector2.ZERO, view)
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if window.x <= 0.0 or window.y <= 0.0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Rect2(Vector2.ZERO, view)
	var ratio: Vector2 = view / window
	return Rect2(Vector2(safe.position) * ratio, Vector2(safe.size) * ratio)

func _mika_num_layout() -> void:
	if not _mika_num_ui_ready or _mika_num_toolbar_root == null or product_root == null:
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 120.0 or view.y < 140.0:
		return
	var safe: Rect2 = _mika_num_safe_area(view)
	_mika_num_space.position = Vector2.ZERO
	_mika_num_space.size = view
	_mika_num_nebula.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mika_num_nebula.size = view
	_mika_num_toolbar_root.size = view
	var head_bottom: float = MIKA_NUM_TOOLBAR.relayout(view, safe, _mika_num_back, _mika_num_hub, _mika_num_plaque, _mika_num_title, _mika_num_subtitle)
	var edge_x: float = safe.size.x * 0.022
	var gap_y: float = safe.size.y * 0.023
	var body: Rect2 = Rect2(
		Vector2(safe.position.x + edge_x, head_bottom + gap_y),
		Vector2(safe.size.x - edge_x * 2.0, safe.end.y - head_bottom - gap_y * 2.0)
	)
	if body.size.x <= 80.0 or body.size.y <= 70.0:
		return
	_mika_num_body.position = body.position
	_mika_num_body.size = body.size
	var board_margin_x: float = body.size.x * 0.024
	var board_margin_y: float = body.size.y * 0.035
	var next_column: float = body.size.x * 0.095
	var inner: Rect2 = Rect2(
		body.position + Vector2(board_margin_x, board_margin_y),
		body.size - Vector2(board_margin_x * 2.0 + next_column, board_margin_y * 2.0)
	)
	var factor: float = minf(inner.size.x / MIKA_NUM_GAME_BOUNDS.size.x, inner.size.y / MIKA_NUM_GAME_BOUNDS.size.y)
	var drawn: Vector2 = MIKA_NUM_GAME_BOUNDS.size * factor
	product_root.scale = Vector2.ONE * factor
	product_root.position = inner.position + (inner.size - drawn) * 0.5 - MIKA_NUM_GAME_BOUNDS.position * factor

	var btn_side: float = minf(next_column * 0.73, body.size.y * 0.135)
	_mika_num_next.position = Vector2(body.end.x - next_column + (next_column - btn_side) * 0.5, body.position.y + (body.size.y - btn_side) * 0.5)
	_mika_num_next.size = Vector2.ONE * btn_side
	_mika_num_next.add_theme_font_size_override("font_size", maxi(12, roundi(btn_side * 0.54)))

func _update_score() -> void:
	_mika_num_update_score()

func _mika_num_update_score() -> void:
	if _mika_num_hub != null:
		_mika_num_hub.set("crystal_count", _mika_num_earned)

func _on_option_pressed(btn: Button, value: int) -> void:
	var correct: bool = not round_over and value == current_number
	var number_completed: int = current_number
	# Keep parent selection, voice, shake, success animation, praise and retry.
	super._on_option_pressed(btn, value)
	if correct and not _mika_num_awarded.has(number_completed):
		_mika_num_awarded[number_completed] = true
		_mika_num_earned += 1
		_mika_num_update_score()

func _mika_num_settle_rewards() -> void:
	if _mika_num_settled:
		return
	_mika_num_settled = true
	if _mika_num_earned <= 0:
		return
	var host: Node = _mika_num_find_host()
	if host != null:
		host.emit_signal("crystals_earned", _mika_num_earned)
		var p: Node = host.get_parent()
		for _i in range(9):
			if p == null:
				break
			var fuel: Variant = p.get("_fuel_units")
			if fuel is float or fuel is int:
				if host.has_method("set_stats"):
					host.call("set_stats", maxi(0, floori(float(fuel) + 0.001)), 0, 0.0)
				break
			p = p.get_parent()

func _on_exit_pressed() -> void:
	_mika_num_settle_rewards()
	var host: Node = _mika_num_find_host()
	if host != null:
		host.call("_return_to_cards")
	else:
		SFX.transition_to_scene(exit_scene_path)

func _exit_tree() -> void:
	_mika_num_settle_rewards()
	if is_instance_valid(_mika_num_host_back):
		_mika_num_host_back.show()
	if MobileLocale.language_changed.is_connected(_mika_num_on_language):
		MobileLocale.language_changed.disconnect(_mika_num_on_language)
