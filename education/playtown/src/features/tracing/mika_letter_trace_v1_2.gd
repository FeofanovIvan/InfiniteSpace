extends "res://education/playtown/src/features/tracing/mika_letter_trace_v1_1.gd"
## MIKA Trace Letters v1.2. Native simulator top controls + bright nebula sky,
## a large left writing tile and a full alphabet in visible buttons on the right.
## Keeps the original Safe City Kids tracing logic, voice and reward pipeline.

const REAL_HUB_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const CROSSROADS_NEBULAE = preload("res://simulator_ui/scripts/mika_minigame_nebula_layer.gd")
const BRIGHT_GUIDES = preload("res://education/playtown/src/features/tracing/mika_neon_trace_hints_v12.gd")
const TILE_DARK: Color = Color("#081c40")
const TILE_GLOW: Color = Color("#33dfff")
const TILE_ACTIVE: Color = Color("#29e9f0")
const TILE_DONE: Color = Color("#b49aff")
const PALETTE: Array[Color] = [Color("#7aefff"), Color("#ab91ff"), Color("#fb8de4")]

const CAPTIONS: Dictionary = {
    "ru": ["ОБВЕДИ БУКВЫ", "Проведи пальцем по светящимся точкам", "Выбери букву", "За эту игру"],
    "en": ["TRACE LETTERS", "Follow the glowing dots", "Choose a letter", "This round"],
    "fr": ["TRACE LES LETTRES", "Suis les points lumineux", "Choisis une lettre", "Cette partie"],
    "de": ["BUCHSTABEN SCHREIBEN", "Fahre die leuchtenden Punkte nach", "Wähle einen Buchstaben", "Diese Runde"],
    "es": ["REPASA LAS LETRAS", "Sigue los puntos luminosos", "Elige una letra", "Esta partida"],
    "pt_BR": ["CONTORNE AS LETRAS", "Siga os pontos luminosos", "Escolha uma letra", "Nesta rodada"]
}

var _nebula_overlay: Control
var _title_panel: Panel
var _alphabet_panel: Panel
var _alphabet_grid: GridContainer
var _alphabet_title: Label
var _round_count: Label
var _native_hub: Control
var _letter_tiles: Array[Button] = []

func _ready() -> void:
    super._ready()
    # An identical source scene and checkpoint calculation, but a clearer neon
    # instruction marker. Do not modify the original Safe City Kids script.
    var old: Node2D = hint_drawer
    if old != null and is_instance_valid(old):
        letter_root.remove_child(old)
        old.queue_free()
    hint_drawer = BRIGHT_GUIDES.new()
    hint_drawer.game = self
    hint_drawer.name = "MikaNeonTraceGuide"
    letter_root.add_child(hint_drawer)
    _refresh_tiles()
    _relayout_native()

func _build_background() -> void:
    super._build_background()
    # No heavy black overlay. The original flight stars stay visible.
    _shadow.color = Color(0.02, 0.01, 0.06, 0.025)
    _nebula_overlay = CROSSROADS_NEBULAE.new()
    _nebula_overlay.name = "ActualCrossroadsNebulaShader_VioletPink"
    _nebula_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _nebula_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _sky.add_child(_nebula_overlay)
    _nebula_overlay.size = get_viewport_rect().size
    # Stronger writing surface, cyan front edge and purple ambience.
    var stage_skin: StyleBoxFlat = UI_KIT.stage_style()
    stage_skin.bg_color = Color(0.013, 0.06, 0.16, 0.76)
    stage_skin.border_color = Color("#52dfff")
    stage_skin.set_border_width_all(3)
    stage_skin.set_corner_radius_all(32)
    stage_skin.shadow_color = Color(0.29, 0.40, 1.0, 0.38)
    stage_skin.shadow_size = 15
    _stage_panel.add_theme_stylebox_override("panel", stage_skin)

func _make_native_back() -> Button:
    var button := Button.new()
    button.name = "NativeSimulatorBackButton"
    button.text = ""
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    var host: Node = _find_simulator_host()
    # The host method creates the precise same StyleBox + native arrow glyph
    # as the simulator's existing Back control; no replacement artwork.
    if host != null and host.has_method("_style_back_button"):
        host.call("_style_back_button", button)
    else:
        button.add_theme_stylebox_override("normal", UI_KIT.button_style(false))
        var hover: StyleBoxFlat = UI_KIT.button_style(true)
        button.add_theme_stylebox_override("hover", hover)
        button.add_theme_stylebox_override("pressed", hover)
        button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        var glyph: Control = NATIVE_BACK.new()
        glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(glyph)
        glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    button.pressed.connect(_on_exit_pressed)
    return button

func _build_hud() -> void:
    hud = CanvasLayer.new()
    hud.name = "MikaNativeGameUI"
    add_child(hud)
    _hud_root = Control.new()
    _hud_root.name = "AdaptiveLettersHUD"
    _hud_root.size = get_viewport_rect().size
    _hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(_hud_root)
    _native_back_button = _make_native_back()
    _hud_root.add_child(_native_back_button)

    # Instantiate the EXACT PlanetHub counter logic/assets from the simulator.
    # We never stretch its crystal: size remains canonical 1680x158 internally,
    # and it is uniformly scaled with the same counter_s as MikoMainMenu._reflow.
    _native_hub = REAL_HUB_HUD.new() as Control
    _native_hub.name = "OriginalPlanetHubCounterNotRecreated"
    _native_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _native_hub.size = Vector2(1680.0, 158.0)
    _hud_root.add_child(_native_hub)
    var sim_button: Control = _native_hub.get_node_or_null("SimulatorButton") as Control
    var flight_button: Control = _native_hub.get_node_or_null("LaunchButton") as Control
    if sim_button != null:
        sim_button.hide()
    if flight_button != null:
        flight_button.hide()

    _title_panel = Panel.new()
    _title_panel.name = "NeonTitlePlaque"
    _title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var title_style: StyleBoxFlat = UI_KIT.button_style(false)
    title_style.set_corner_radius_all(26)
    title_style.bg_color = Color(0.015, 0.075, 0.19, 0.85)
    title_style.border_color = Color("#4deeff")
    title_style.set_border_width_all(3)
    title_style.shadow_color = Color(0.25, 0.57, 1.0, 0.44)
    title_style.shadow_size = 9
    _title_panel.add_theme_stylebox_override("panel", title_style)
    _hud_root.add_child(_title_panel)
    _title = _make_label("", 30, WHITE)
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title_panel.add_child(_title)
    _instructions = _make_label("", 16, Color("#aeefff"))
    _instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title_panel.add_child(_instructions)

    _alphabet_panel = Panel.new()
    _alphabet_panel.name = "AlphabetNeonGlassPanel"
    _alphabet_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var grid_style: StyleBoxFlat = UI_KIT.stage_style()
    grid_style.bg_color = Color(0.012, 0.04, 0.16, 0.72)
    grid_style.border_color = Color("#6de1ff")
    grid_style.set_border_width_all(3)
    grid_style.set_corner_radius_all(32)
    grid_style.shadow_color = Color(0.34, 0.25, 1.0, 0.34)
    grid_style.shadow_size = 14
    _alphabet_panel.add_theme_stylebox_override("panel", grid_style)
    _hud_root.add_child(_alphabet_panel)

    _alphabet_title = _make_label("", 17, Color("#c3f3ff"))
    _alphabet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _alphabet_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _alphabet_panel.add_child(_alphabet_title)

    # No ScrollContainer: EVERY letter is visible at once, including all 33
    # Russian letters. The grid recomputes its columns and tile size on resize.
    _alphabet_grid = GridContainer.new()
    _alphabet_grid.name = "AllAlphabetButtonsVisibleTogether"
    _alphabet_grid.mouse_filter = Control.MOUSE_FILTER_PASS
    _alphabet_panel.add_child(_alphabet_grid)

    # Do not attach PlayTown's coin counter to the ship HUD. The old class
    # listens for coin_balance_changed; keep that signal on an invisible label.
    score_label = Label.new()
    score_label.name = "PlayTownCoinListener_Offscreen"
    score_label.visible = false
    _hud_root.add_child(score_label)
    _round_count = _make_label("", 15, Color("#dcceff"))
    _round_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _round_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _alphabet_panel.add_child(_round_count)
    _build_alphabet()
    _feedback = _make_label("", 17, MINT)
    _feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _hud_root.add_child(_feedback)

func _tile_style(active: bool, done: bool, hovered: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.anti_aliasing = true
    style.set_corner_radius_all(16)
    style.set_border_width_all(3 if active else 2)
    style.bg_color = Color(0.075, 0.77, 0.91, 0.96) if active else (Color(0.15, 0.09, 0.34, 0.92) if done else TILE_DARK)
    style.border_color = TILE_ACTIVE if active else (TILE_DONE if done else TILE_GLOW)
    if hovered and not active:
        style.bg_color = Color(0.10, 0.20, 0.44, 0.97)
    style.shadow_color = Color(0.13, 0.84, 1.0, 0.58) if active else Color(0.24, 0.43, 1.0, 0.38)
    style.shadow_size = 8 if active else 5
    return style

func _build_alphabet() -> void:
    for child in _alphabet_grid.get_children():
        _alphabet_grid.remove_child(child)
        child.queue_free()
    _letter_tiles.clear()
    for i in range(letters.size()):
        var b := Button.new()
        b.name = "Alphabet_%02d" % i
        b.text = letters[i]
        b.focus_mode = Control.FOCUS_NONE
        b.mouse_filter = Control.MOUSE_FILTER_STOP
        b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        b.pressed.connect(_select_letter.bind(i))
        _alphabet_grid.add_child(b)
        _letter_tiles.append(b)
    _refresh_tiles()

func _select_letter(index: int) -> void:
    if index < 0 or index >= letters.size():
        return
    if celebrate_tween != null:
        celebrate_tween.kill()
        celebrate_tween = null
    tracing = false
    _mouse_pressed = false
    _touch_held = false
    letter_index = index
    _load_letter()

func _refresh_tiles() -> void:
    for i in range(_letter_tiles.size()):
        var b: Button = _letter_tiles[i]
        var active: bool = i == letter_index
        var done: bool = _already_rewarded.has(str(LanguageService.learning_locale) + ":" + letters[i])
        b.add_theme_stylebox_override("normal", _tile_style(active, done))
        b.add_theme_stylebox_override("hover", _tile_style(active, done, true))
        b.add_theme_stylebox_override("pressed", _tile_style(active, done, true))
        var color: Color = Color("#072047") if active else (Color("#e1d8ff") if done else WHITE)
        b.add_theme_color_override("font_color", color)
        b.add_theme_color_override("font_hover_color", color)
        b.add_theme_color_override("font_pressed_color", color)

func _language_changed(code: String) -> void:
    # Do not invoke v1.1's language handler: its caption target belongs to
    # the old HUD and does not exist when using the original PlanetHub HUD.
    var locale: String = code if CAPTIONS.has(code) else "en"
    var phrases: Array = CAPTIONS[locale]
    if _title != null:
        _title.text = str(phrases[0])
    if _instructions != null:
        _instructions.text = str(phrases[1])
    if _alphabet_title != null:
        _alphabet_title.text = str(phrases[2])
    _update_score()
    _relayout_native()

func _load_letter() -> void:
    super._load_letter()
    # Recolor the ORIGINAL paths; not a raster redraw and not new mechanics.
    for outline in outline_lines:
        if is_instance_valid(outline):
            (outline as Line2D).default_color = Color("#57dfff")
    for body in body_lines:
        if is_instance_valid(body):
            (body as Line2D).default_color = Color("#e9faff")
    for filling in fill_lines:
        if is_instance_valid(filling):
            (filling as Line2D).default_color = PALETTE[letter_index % PALETTE.size()]
    _refresh_tiles()

func _finish_letter() -> void:
    super._finish_letter()
    _refresh_tiles()

func _advance_letter() -> void:
    super._advance_letter()
    _refresh_tiles()

func _update_score() -> void:
    # The source of truth is the ship, never the legacy PlayTown coins.
    # Rewards from this session are committed once when leaving this game.
    var current: int = 0
    var capacity: int = 50
    var host: Node = _find_simulator_host()
    if host != null:
        var count: Variant = host.get("_crystal_balance")
        if count is int or count is float:
            current = maxi(0, int(count))
        var walk: Node = host.get_parent()
        for step in range(8):
            if walk == null:
                break
            var max_fuel: Variant = walk.get("fuel_capacity")
            if max_fuel is float or max_fuel is int:
                capacity = maxi(1, roundi(float(max_fuel)))
                break
            walk = walk.get_parent()
    if _native_hub != null:
        _native_hub.set("crystal_count", mini(capacity, current + _earned))
    if _round_count != null:
        var locale: String = MobileLocale.language if CAPTIONS.has(MobileLocale.language) else "en"
        _round_count.text = "%s: +%d" % [CAPTIONS[locale][3], _earned]

func _relayout_native() -> void:
    if _hud_root == null or letter_root == null or _sky == null or _alphabet_panel == null:
        return
    var view: Vector2 = get_viewport_rect().size
    if view.x < 100.0 or view.y < 100.0:
        return
    _safe = _safe_rect()
    _hud_root.size = view
    _sky.size = view
    if _nebula_overlay != null:
        _nebula_overlay.size = view
    _shadow.size = view

    var safe_left: float = _safe.position.x
    var safe_right: float = _safe.end.x
    var safe_top: float = _safe.position.y
    var safe_bottom: float = _safe.end.y
    var sw: float = _safe.size.x
    var sh: float = _safe.size.y

    # Exactly the original simulator controls, at the original simulator's
    # UNIFORM scale (not two hand-built imitations, and never stretched).
    var hub_s: float = minf(view.y / 864.0, view.x / 1680.0)
    var counter_s: float = hub_s * 0.80
    var back_s: float = hub_s * 0.60
    var edge_gap: float = maxf(5.0, minf(24.0 * hub_s, sw * 0.03))
    var top_y: float = safe_top + maxf(6.0, 20.0 * hub_s)
    var back_size: float = 158.0 * back_s
    _native_back_button.position = Vector2(safe_left + edge_gap, top_y)
    _native_back_button.size = Vector2.ONE * back_size
    _native_hub.size = Vector2(1680.0, 158.0)
    _native_hub.scale = Vector2.ONE * counter_s
    _native_hub.position = Vector2(safe_right - edge_gap - (643.0 + 394.0) * counter_s, top_y)
    _update_score()

    var heading_left: float = safe_left + edge_gap + back_size + maxf(7.0, 18.0 * hub_s)
    var heading_right: float = safe_right - edge_gap - 394.0 * counter_s - maxf(7.0, 18.0 * hub_s)
    var heading_w: float = maxf(44.0, heading_right - heading_left)
    var header_height: float = maxf(back_size, 158.0 * counter_s)
    _title_panel.position = Vector2(heading_left, top_y)
    _title_panel.size = Vector2(heading_w, header_height)
    var title_h: float = header_height * 0.65
    _title.position = Vector2(5.0, header_height * 0.06)
    _title.size = Vector2(maxf(32.0, heading_w - 10.0), title_h)
    var font_scale: float = clampf(minf(sw / 1450.0, sh / 800.0), 0.40, 1.30)
    var current_title: String = _title.text
    var text_scale: float = minf(1.0, maxf(0.44, 23.0 / float(maxi(1, current_title.length()))))
    _title.add_theme_font_size_override("font_size", maxi(9, roundi(35.0 * font_scale * text_scale)))
    _instructions.position = Vector2(5.0, header_height * 0.67)
    _instructions.size = Vector2(maxf(32.0, heading_w - 10.0), header_height * 0.25)
    _instructions.add_theme_font_size_override("font_size", maxi(8, roundi(17.0 * font_scale)))
    _instructions.visible = heading_w > 200.0

    # BOTH areas ALWAYS side by side, even in portrait orientation. No
    # scroll, paging or hidden alphabet rows, by explicit design decision.
    var margin: float = clampf(sw * 0.018, 5.0, 28.0)
    var gap: float = clampf(sw * 0.016, 5.0, 26.0)
    var body_top: float = top_y + header_height + clampf(sh * 0.026, 7.0, 22.0)
    var body_bottom: float = safe_bottom - clampf(sh * 0.025, 7.0, 24.0)
    var available_h: float = maxf(75.0, body_bottom - body_top)
    var content_w: float = maxf(90.0, sw - margin * 2.0)
    var left_w: float = maxf(45.0, (content_w - gap) * 0.435)
    var right_w: float = maxf(45.0, content_w - gap - left_w)
    var square: float = minf(left_w, available_h)
    _stage_panel.size = Vector2(square, square)
    _stage_panel.position = Vector2(safe_left + margin + (left_w - square) * 0.5, body_top + (available_h - square) * 0.5)
    _alphabet_panel.position = Vector2(safe_left + margin + left_w + gap, body_top)
    _alphabet_panel.size = Vector2(right_w, available_h)

    var center: Vector2 = _stage_panel.position + _stage_panel.size * 0.5
    _stage_scale = clampf(minf((_stage_panel.size.x - 14.0) / 455.0, (_stage_panel.size.y - 14.0) / 560.0), 0.10, 1.9)
    letter_root.position = center
    if not letter_done:
        letter_root.scale = Vector2.ONE * _stage_scale

    var panel_w: float = _alphabet_panel.size.x
    var panel_h: float = _alphabet_panel.size.y
    var inner_margin: float = clampf(panel_w * 0.027, 4.0, 20.0)
    var label_h: float = clampf(panel_h * 0.070, 16.0, 40.0)
    var bottom_h: float = clampf(panel_h * 0.072, 17.0, 39.0)
    _alphabet_title.position = Vector2(inner_margin, 4.0)
    _alphabet_title.size = Vector2(maxf(20.0, panel_w - inner_margin * 2.0), label_h)
    _alphabet_title.add_theme_font_size_override("font_size", maxi(10, roundi(18.0 * font_scale)))
    _round_count.position = Vector2(inner_margin, panel_h - bottom_h - 4.0)
    _round_count.size = Vector2(maxf(20.0, panel_w - inner_margin * 2.0), bottom_h)
    _round_count.add_theme_font_size_override("font_size", maxi(10, roundi(16.0 * font_scale)))

    var inner_top: float = label_h + 9.0
    var inner_h: float = maxf(12.0, panel_h - inner_top - bottom_h - 12.0)
    var inner_w: float = maxf(12.0, panel_w - inner_margin * 2.0)
    var button_count: int = maxi(1, _letter_tiles.size())
    var best_tile: float = 0.0
    var best_columns: int = 1
    var best_gap: float = 3.0
    # Choose the largest SQUARE buttons that accommodate the entire alphabet.
    # The 33-letter Russian alphabet fits just as the 26-letter English one.
    for columns in range(2, mini(12, button_count) + 1):
        var rows: int = ceili(float(button_count) / float(columns))
        var trial_gap: float = clampf(minf(inner_w / float(columns), inner_h / float(rows)) * 0.12, 2.0, 12.0)
        var fit_w: float = (inner_w - float(columns - 1) * trial_gap) / float(columns)
        var fit_h: float = (inner_h - float(rows - 1) * trial_gap) / float(rows)
        var cell: float = minf(fit_w, fit_h)
        if cell > best_tile:
            best_tile = cell
            best_columns = columns
            best_gap = trial_gap
    var columns_final: int = best_columns
    var rows_final: int = ceili(float(button_count) / float(columns_final))
    var cell_side: float = maxf(7.0, best_tile - 0.6)
    _alphabet_grid.columns = columns_final
    _alphabet_grid.add_theme_constant_override("h_separation", roundi(best_gap))
    _alphabet_grid.add_theme_constant_override("v_separation", roundi(best_gap))
    var content_grid_w: float = cell_side * columns_final + float(columns_final - 1) * roundf(best_gap)
    var content_grid_h: float = cell_side * rows_final + float(rows_final - 1) * roundf(best_gap)
    _alphabet_grid.position = Vector2(inner_margin + (inner_w - content_grid_w) * 0.5, inner_top + (inner_h - content_grid_h) * 0.5)
    _alphabet_grid.size = Vector2(content_grid_w, content_grid_h)
    var tile_font: int = maxi(8, roundi(cell_side * 0.52))
    for tile in _letter_tiles:
        tile.custom_minimum_size = Vector2.ONE * cell_side
        tile.add_theme_font_size_override("font_size", tile_font)

    _feedback.position = Vector2(_stage_panel.position.x + 4.0, _stage_panel.position.y + _stage_panel.size.y - clampf(45.0 * font_scale, 16.0, 45.0))
    _feedback.size = Vector2(maxf(25.0, _stage_panel.size.x - 8.0), clampf(40.0 * font_scale, 16.0, 40.0))
    _feedback.add_theme_font_size_override("font_size", maxi(9, roundi(16.0 * font_scale)))

func _play_instruction_and_letter() -> void:
    # Keep the existing voice files and their order without changes.
    super._play_instruction_and_letter()
