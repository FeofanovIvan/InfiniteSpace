extends "res://education/playtown/src/features/tracing/letter_trace_game.gd"
## MIKA Trace Letters v1.1: new presentation around ORIGINAL Safe City Kids mechanics.
## Preserves original paths, checkpoint geometry, letter voices, feedback and SFX.
## Awards unique letters per session. Sends reward through simulator signal, no MikoMainMenu modifications.

const LIVE_SPACE = preload("res://simulator_ui/scripts/real_space_background.gd")
const NATIVE_BACK = preload("res://simulator_ui/back_arrow_glyph.gd")
const UI_KIT = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const HUB_CRYSTAL: Texture2D = preload("res://planet_hub/assets/v68_neon/crystal_reference.png")
const HUB_COUNTER: Texture2D = preload("res://planet_hub/assets/v68_neon/crystals_panel.png")

const ICE: Color = Color("#26dfff")
const WHITE: Color = Color("#eefbff")
const QUIET: Color = Color("#9dc7d8")
const MINT: Color = Color("#96ffd3")
const TEXTS: Dictionary = {
    "ru": ["ОБВЕДИ БУКВУ", "Веди пальцем по светящемуся пути", "Заработано", "Отлично! +1 кристалл", "Буква уже пройдена"],
    "en": ["TRACE THE LETTER", "Follow the glowing line with your finger", "Earned", "Great job! +1 crystal", "Already completed"],
    "fr": ["TRACE LA LETTRE", "Suis la ligne lumineuse avec ton doigt", "Gagnés", "Bravo ! +1 cristal", "Lettre déjà tracée"],
    "de": ["BUCHSTABEN NACHFAHREN", "Fahre die leuchtende Linie mit dem Finger nach", "Verdient", "Toll! +1 Kristall", "Schon geschafft"],
    "es": ["REPASA LA LETRA", "Sigue la línea luminosa con el dedo", "Ganados", "¡Muy bien! +1 cristal", "Ya completada"],
    "pt_BR": ["CONTORNE A LETRA", "Siga a linha brilhante com o dedo", "Ganhos", "Muito bem! +1 cristal", "Já concluída"]
}

@export var crystals_per_new_letter: int = 1

var _sky: Control
var _shadow: ColorRect
var _stage_panel: Panel
var _hud_root: Control
var _native_back_button: Button
var _prev_button: Button
var _next_button: Button
var _title: Label
var _instructions: Label
var _feedback: Label
var _counter_panel: NinePatchRect
var _counter_icon: TextureRect
var _counter_divider: ColorRect
var _earned_caption: Label
var _earned: int = 0
var _already_rewarded: Dictionary = {}
var _settled: bool = false
var _original_host_back: BaseButton
var _mouse_pressed: bool = false
var _touch_held: bool = false
var _stage_scale: float = 1.0
var _safe: Rect2 = Rect2()

func _ready() -> void:
    # The flight is paused while the simulator is shown. Game and sky continue.
    process_mode = Node.PROCESS_MODE_ALWAYS
    super._ready()
    get_viewport().size_changed.connect(_relayout_native)
    MobileLocale.language_changed.connect(_language_changed)
    _language_changed(MobileLocale.language)
    _hide_simulator_back()
    _relayout_native()

func _find_simulator_host() -> Node:
    # The mini-game is a child of the simulator's SubViewport. Walk the live
    # parent chain instead of relying on a brittle script or node path.
    var current: Node = get_parent()
    for i in range(8):
        if current == null:
            break
        if current.has_signal("crystals_earned") and current.has_method("set_stats"):
            return current
        current = current.get_parent()
    return null

func _hide_simulator_back() -> void:
    # The regular simulator Back button would otherwise overlap this game's
    # own neon Back button. Restore it as the game leaves.
    var host: Node = _find_simulator_host()
    if host == null:
        return
    _original_host_back = host.get_node_or_null("PlayTownOriginalGameRunner/ReturnToEducationalCards") as BaseButton
    if is_instance_valid(_original_host_back):
        _original_host_back.hide()

func _synchronize_simulator_counter(host: Node) -> void:
    # Main owns the real tank and applies its current capacity, even if future
    # upgrades raise that capacity above the present 50.
    var node: Node = host.get_parent()
    for i in range(8):
        if node == null:
            break
        var fuel: Variant = node.get("_fuel_units")
        if fuel is float or fuel is int:
            host.call("set_stats", maxi(0, floori(float(fuel) + 0.001)), 0, 0.0)
            return
        node = node.get_parent()

func _build_background() -> void:
    _sky = LIVE_SPACE.new() as Control
    _sky.name = "SharedNativeSpaceBackdrop"
    _sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _sky.size = get_viewport_rect().size
    _sky.z_index = -15
    add_child(_sky)
    _shadow = ColorRect.new()
    _shadow.name = "SubtleSpaceReadabilityTint"
    _shadow.color = Color(0.005, 0.025, 0.06, 0.22)
    _shadow.size = get_viewport_rect().size
    _shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _shadow.z_index = -12
    add_child(_shadow)
    _stage_panel = Panel.new()
    _stage_panel.name = "PlanetHubNeonWritingSurface"
    _stage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _stage_panel.z_index = -9
    _stage_panel.add_theme_stylebox_override("panel", UI_KIT.stage_style())
    add_child(_stage_panel)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    hud.name = "MikaNativeGameUI"
    add_child(hud)
    _hud_root = Control.new()
    _hud_root.name = "ViewportAdaptiveUI"
    _hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hud_root.size = get_viewport_rect().size
    hud.add_child(_hud_root)

    _native_back_button = _make_button("NativeBack", true)
    _native_back_button.pressed.connect(_on_exit_pressed)
    _hud_root.add_child(_native_back_button)
    _native_back_button.tooltip_text = "Back"
    var arrow := NATIVE_BACK.new() as Control
    arrow.name = "ActualSimulatorBackGlyph"
    arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _native_back_button.add_child(arrow)
    arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _title = _make_label("", 31, WHITE)
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _hud_root.add_child(_title)

    _instructions = _make_label("", 17, QUIET)
    _instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _hud_root.add_child(_instructions)

    _counter_panel = NinePatchRect.new()
    _counter_panel.name = "ExactPlanetHubCrystalsPanel"
    _counter_panel.texture = HUB_COUNTER
    _counter_panel.patch_margin_left = 28
    _counter_panel.patch_margin_right = 28
    _counter_panel.patch_margin_top = 19
    _counter_panel.patch_margin_bottom = 19
    _counter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hud_root.add_child(_counter_panel)
    _counter_icon = TextureRect.new()
    _counter_icon.name = "ActualBlueCrystal"
    _counter_icon.texture = HUB_CRYSTAL
    _counter_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _counter_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _counter_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _counter_panel.add_child(_counter_icon)
    _counter_divider = ColorRect.new()
    _counter_divider.color = Color("#60eaff")
    _counter_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _counter_panel.add_child(_counter_divider)
    score_label = _make_label("0", 33, WHITE)
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _counter_panel.add_child(score_label)
    _earned_caption = _make_label("", 14, QUIET)
    _earned_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _earned_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _hud_root.add_child(_earned_caption)

    _prev_button = _make_button("PreviousLetter", false)
    _prev_button.text = "‹"
    _prev_button.pressed.connect(_on_prev_pressed)
    _hud_root.add_child(_prev_button)
    _next_button = _make_button("NextLetter", false)
    _next_button.text = "›"
    _next_button.pressed.connect(_on_next_pressed)
    _hud_root.add_child(_next_button)

    _feedback = _make_label("", 18, MINT)
    _feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hud_root.add_child(_feedback)

func _make_label(value: String, font_px: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.clip_text = true
    label.add_theme_font_size_override("font_size", font_px)
    label.add_theme_color_override("font_color", tint)
    label.add_theme_color_override("font_outline_color", Color("#06162f"))
    label.add_theme_constant_override("outline_size", 2)
    return label

func _make_button(node_name: String, is_back: bool) -> Button:
    var button := Button.new()
    button.name = node_name
    button.text = ""
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_stylebox_override("normal", UI_KIT.button_style(false))
    var hover: StyleBoxFlat = UI_KIT.button_style(true)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    if not is_back:
        button.add_theme_font_size_override("font_size", 43)
        button.add_theme_color_override("font_color", WHITE)
        button.add_theme_color_override("font_hover_color", WHITE)
        button.add_theme_color_override("font_pressed_color", WHITE)
    return button

func _language_changed(code: String) -> void:
    var locale: String = code if TEXTS.has(code) else "en"
    var t: Array = TEXTS[locale]
    _title.text = str(t[0])
    _instructions.text = str(t[1])
    _earned_caption.text = str(t[2])
    _relayout_native()

func _safe_rect() -> Rect2:
    var v: Vector2 = get_viewport_rect().size
    return MobileLocale.safe_rect(v)

func _relayout_native() -> void:
    if _hud_root == null or letter_root == null or _sky == null:
        return
    var view: Vector2 = get_viewport_rect().size
    _safe = _safe_rect()
    _hud_root.size = view
    _sky.size = view
    _shadow.size = view
    var safe_left: float = _safe.position.x
    var safe_right: float = _safe.end.x
    var safe_top: float = _safe.position.y
    var safe_bottom: float = _safe.end.y
    var vw: float = _safe.size.x
    var vh: float = _safe.size.y
    var portrait: bool = vh > vw * 1.20
    var ui_scale: float = clampf(minf(vw / 1150.0, vh / 700.0), 0.60, 1.45)
    var side: float = clampf(vh * 0.092, 46.0, 76.0)
    var edge: float = maxf(5.0, minf(vw * 0.025, 28.0))
    var top: float = safe_top + maxf(5.0, vh * 0.020)
    _native_back_button.position = Vector2(safe_left + edge, top)
    _native_back_button.size = Vector2.ONE * side

    var counter_w: float = side * 3.20
    var counter_h: float = side * 0.98
    _counter_panel.position = Vector2(safe_right - edge - counter_w, top)
    _counter_panel.size = Vector2(counter_w, counter_h)
    _counter_icon.position = Vector2(counter_w * 0.065, counter_h * 0.12)
    _counter_icon.size = Vector2(counter_w * 0.32, counter_h * 0.77)
    _counter_divider.position = Vector2(counter_w * 0.46, counter_h * 0.19)
    _counter_divider.size = Vector2(maxf(1.0, 2.0 * ui_scale), counter_h * 0.62)
    score_label.position = Vector2(counter_w * 0.51, 0)
    score_label.size = Vector2(counter_w * 0.42, counter_h)
    score_label.add_theme_font_size_override("font_size", maxi(19, roundi(36.0 * ui_scale)))
    _earned_caption.position = Vector2(_counter_panel.position.x, top + counter_h - 2.0)
    _earned_caption.size = Vector2(counter_w, maxf(12.0, side * 0.23))
    _earned_caption.add_theme_font_size_override("font_size", maxi(10, roundi(14.0 * ui_scale)))
    var heading_left: float = _native_back_button.position.x + side + edge
    var heading_right: float = _counter_panel.position.x - edge
    _title.position = Vector2(heading_left, top + 2)
    _title.size = Vector2(maxf(40.0, heading_right - heading_left), side * 0.57)
    _title.add_theme_font_size_override("font_size", maxi(15, roundi(31.0 * ui_scale)))
    _instructions.position = Vector2(heading_left, top + side * 0.57)
    _instructions.size = Vector2(maxf(40.0, heading_right - heading_left), side * 0.37)
    _instructions.add_theme_font_size_override("font_size", maxi(10, roundi(17.0 * ui_scale)))
    _instructions.visible = heading_right - heading_left > 250.0

    var header_bottom: float = top + side + maxf(9.0, vh * 0.035)
    var footer_h: float = maxf(42.0, side * 0.80)
    var stage_top: float = header_bottom
    var stage_bottom: float = maxf(stage_top + 80.0, safe_bottom - footer_h - maxf(12.0, vh * 0.045))
    var stage_height: float = maxf(90.0, stage_bottom - stage_top)
    var arrow_side: float = side * 0.85
    var gap: float = maxf(8.0, 15.0 * ui_scale)
    var margin_for_arrows: float = 0.0 if portrait else arrow_side + gap * 2.0
    var usable_width: float = maxf(100.0, vw - edge * 2.0 - margin_for_arrows * 2.0)
    _stage_scale = clampf(minf((usable_width - 20.0) / 470.0, (stage_height - 15.0) / 580.0), 0.22, 1.70)
    var stage_w: float = 455.0 * _stage_scale
    var stage_h: float = 560.0 * _stage_scale
    var stage_center: Vector2 = Vector2((safe_left + safe_right) * 0.5, (stage_top + stage_bottom) * 0.5)
    _stage_panel.size = Vector2(stage_w, stage_h)
    _stage_panel.position = stage_center - _stage_panel.size * 0.5
    letter_root.position = stage_center
    if not letter_done:
        letter_root.scale = Vector2.ONE * _stage_scale
    _feedback.position = Vector2(safe_left + edge, safe_bottom - footer_h * 0.95)
    _feedback.size = Vector2(vw - edge * 2.0, footer_h * 0.80)
    _feedback.add_theme_font_size_override("font_size", maxi(12, roundi(17.0 * ui_scale)))
    for btn in [_prev_button, _next_button]:
        btn.size = Vector2.ONE * arrow_side
        btn.add_theme_font_size_override("font_size", maxi(25, roundi(45.0 * ui_scale)))
    if portrait:
        _prev_button.position = Vector2(stage_center.x - arrow_side - gap, stage_bottom + gap)
        _next_button.position = Vector2(stage_center.x + gap, stage_bottom + gap)
    else:
        _prev_button.position = Vector2(_stage_panel.position.x - arrow_side - gap, stage_center.y - arrow_side * 0.5)
        _next_button.position = Vector2(_stage_panel.position.x + stage_w + gap, stage_center.y - arrow_side * 0.5)

func _load_letter() -> void:
    super._load_letter()
    if _hud_root != null:
        _feedback.text = ""
    _relayout_native()

func _update_score() -> void:
    if score_label != null:
        score_label.text = str(_earned)

func _unhandled_input(event: InputEvent) -> void:
    if letter_done or letters.is_empty():
        return
    if event is InputEventScreenTouch:
        if event.index != 0:
            return
        _touch_held = event.pressed
        if event.pressed:
            _start_trace(letter_root.to_local(event.position))
        else:
            tracing = false
    elif event is InputEventScreenDrag:
        if event.index == 0 and _touch_held:
            _move_trace(letter_root.to_local(event.position))
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _mouse_pressed = event.pressed
            if _mouse_pressed:
                _start_trace(letter_root.to_local(event.position))
            elif not _touch_held:
                tracing = false
    elif event is InputEventMouseMotion and _mouse_pressed:
        _move_trace(letter_root.to_local(event.position))

func _finish_letter() -> void:
    letter_done = true
    tracing = false
    # Preserve the original six-language Safe City Kids feedback and phonetics.
    SFX.play_praise(get_viewport_rect().size * 0.5, 0.9)
    _play_sfx(coin_sound)
    _play_letter_voice()
    if letter_index >= GameState.letters_traced:
        GameState.set_letters_traced(letter_index + 1)
    var letter_key: String = str(LanguageService.learning_locale) + ":" + _current_letter()
    var lang: String = MobileLocale.language if TEXTS.has(MobileLocale.language) else "en"
    if not _already_rewarded.has(letter_key):
        _already_rewarded[letter_key] = true
        _earned += maxi(0, crystals_per_new_letter)
        _feedback.text = str(TEXTS[lang][3])
    else:
        _feedback.text = str(TEXTS[lang][4])
    _update_score()
    if celebrate_tween != null:
        celebrate_tween.kill()
    var start: Vector2 = Vector2.ONE * _stage_scale
    celebrate_tween = create_tween()
    celebrate_tween.tween_property(letter_root, "scale", start * 1.075, 0.23).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    celebrate_tween.tween_property(letter_root, "scale", start, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    celebrate_tween.tween_interval(0.55)
    celebrate_tween.tween_callback(_advance_letter)

func _on_exit_pressed() -> void:
    # Commit before the portal notifies the simulator to close the mini-game.
    settle_rewards()
    SFX.transition_to_scene(exit_scene_path)

func settle_rewards() -> void:
    if _settled:
        return
    _settled = true
    if _earned <= 0:
        return
    var host: Node = _find_simulator_host()
    if host != null:
        # The existing Main.gd listener refills the REAL flight-fuel tank;
        # its capacity check handles 45 + 6 => 50 automatically.
        host.emit_signal("crystals_earned", _earned)
        _synchronize_simulator_counter(host)
    else:
        # Standalone test scene outside InfiniteSpace simulator.
        GameState.add_coins(_earned)

func _exit_tree() -> void:
    # Covers nonstandard exits, including closing the simulator itself.
    settle_rewards()
    if is_instance_valid(_original_host_back):
        _original_host_back.show()
