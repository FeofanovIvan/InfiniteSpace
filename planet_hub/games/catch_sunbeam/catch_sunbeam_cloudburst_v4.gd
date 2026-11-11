extends Control
## MIKA · Catch a Sunbeam / Cloudburst v4.
## Clouds hide the sun; the spot jumps to a random bud (no sweep / sequence).
## A bud can ONLY be opened during its own active light window. The capture is
## credited only AFTER the opening animation finishes in sunlight.
## 15 correct captures -> local 50/50 bio-energy -> next battery, without exit.
## No GameState crystal balance changes.

const BOARD: Script = preload("res://planet_hub/games/catch_sunbeam/sunbeam_cloud_board_v4.gd")
const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const SPACE: Script = preload("res://simulator_ui/scripts/real_space_background.gd")
const SUCCESS_SFX: AudioStream = preload("res://learning/audio/sfx/correct.ogg")
const TOUCH_SFX: AudioStream = preload("res://learning/audio/sfx/connect_point.ogg")
const FULL_SFX: AudioStream = preload("res://learning/audio/sfx/coin.ogg")

const FLOWER_COUNT: int = 6
const HITS_PER_BATTERY: int = 15
const BATTERY_CAPACITY: float = 50.0
const OPEN_SECONDS: float = 0.19
const RAY_BASE_SECONDS: float = 2.15
const RAY_MIN_SECONDS: float = 0.85
const GAP_BASE_SECONDS: float = 0.47
const GAP_MIN_SECONDS: float = 0.15
const STREAK_ACCELERATION: float = 1.10

const WORDS: Dictionary = {
    "ru": {"title":"ПОЙМАЙ СОЛНЕЧНЫЙ ЛУЧ", "subtitle":"Живая технология фотосинтеза", "reset":"Сначала", "progress":"Попадания %d / 15", "ready":"Жди луч и раскрой освещённый бутон", "hit":"Энергия течёт по корням к батарее", "miss":"Луч ушёл — попробуй следующий", "full":"БАТАРЕЯ ЗАРЯЖЕНА! Цикл %d", "streak":"Серия %d · лучи быстрее"},
    "en": {"title":"CATCH A SUNBEAM", "subtitle":"Living photosynthesis technology", "reset":"Reset", "progress":"Captured %d / 15", "ready":"Wait for the beam, then open the lit bud", "hit":"Energy travels through the roots", "miss":"Beam missed — watch the next one", "full":"BATTERY CHARGED! Cycle %d", "streak":"Streak %d · faster beams"},
    "pt": {"title":"PEGUE O RAIO DE SOL", "subtitle":"Tecnologia viva de fotossíntese", "reset":"Reiniciar", "progress":"Acertos %d / 15", "ready":"Espere a luz e abra o botão iluminado", "hit":"Energia flui pelas raízes", "miss":"A luz passou — tente a próxima", "full":"BATERIA CARREGADA! Ciclo %d", "streak":"Sequência %d · luz mais rápida"},
    "es": {"title":"ATRAPA UN RAYO DE SOL", "subtitle":"Tecnología viva de fotosíntesis", "reset":"Reiniciar", "progress":"Aciertos %d / 15", "ready":"Espera el rayo y abre el capullo iluminado", "hit":"La energía fluye por las raíces", "miss":"Pasó el rayo — prueba el siguiente", "full":"¡BATERÍA CARGADA! Ciclo %d", "streak":"Racha %d · rayos más rápidos"},
    "fr": {"title":"ATTRAPE LE RAYON DE SOLEIL", "subtitle":"Technologie vivante de photosynthèse", "reset":"Recommencer", "progress":"Réussites %d / 15", "ready":"Attends la lumière et ouvre le bourgeon éclairé", "hit":"L'énergie passe par les racines", "miss":"Rayon manqué — essaie le suivant", "full":"BATTERIE CHARGÉE ! Cycle %d", "streak":"Série %d · rayons plus rapides"},
    "de": {"title":"FANG DEN SONNENSTRAHL", "subtitle":"Lebendige Fotosynthese-Technik", "reset":"Neustart", "progress":"Treffer %d / 15", "ready":"Warte auf Licht und öffne die beleuchtete Knospe", "hit":"Energie fließt durch die Wurzeln", "miss":"Strahl vorbei — versuch den nächsten", "full":"BATTERIE GELADEN! Runde %d", "streak":"Serie %d · schnellere Strahlen"}
}

var _space: Control
var _board: Control
var _stage_frame: Panel
var _title_panel: Panel
var _title: Label
var _subtitle: Label
var _back: Button
var _outer_back: Control
var _counter: Control
var _reset: Button
var _progress: Label
var _help: Label
var _audio: AudioStreamPlayer
var _locale: String = "en"
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Explicit phase machine: gap -> ray -> gap; 15 hits -> charged -> gap.
var _phase: String = "gap"
var _phase_time: float = 0.0
var _ray_duration: float = RAY_BASE_SECONDS
var _gap_duration: float = GAP_BASE_SECONDS
var _target_index: int = -1
var _pressed_target: bool = false
var _opening_elapsed: float = 0.0
var _ray_captured: bool = false
var _captured: int = 0
var _charge: float = 0.0
var _streak: int = 0
var _cycles: int = 0
var _missed: int = 0
var _flower_openings: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _message: String = "ready"

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()

    _space = SPACE.new() as Control
    _space.name = "ExistingSpaceSky"
    _space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _space.z_index = -20
    add_child(_space)

    _stage_frame = Panel.new()
    _stage_frame.name = "SunbeamCyanStageFrame"
    _stage_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_stage_frame)
    add_child(_stage_frame)

    _board = BOARD.new() as Control
    _board.name = "LivingSunbeamBoard"
    _board.connect("bud_pressed", _on_bud_pressed)
    add_child(_board)

    _title_panel = Panel.new()
    _title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_title_panel)
    add_child(_title_panel)
    _title = _make_label(_title_panel, HORIZONTAL_ALIGNMENT_CENTER, Color("#f5fff9"))
    _subtitle = _make_label(_title_panel, HORIZONTAL_ALIGNMENT_CENTER, Color("#b7e7ee"))

    _back = Button.new()
    _back.name = "SunbeamNativeBack"
    _style_button(_back)
    _back.pressed.connect(_exit_to_cards)
    add_child(_back)
    var glyph: Control = GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _counter = HUD.new() as Control
    _counter.name = "NativeCrystalCounter"
    _counter.size = Vector2(1680.0, 158.0)
    add_child(_counter)
    var sim_button: Button = _counter.get("sim_button") as Button
    var flight_button: Button = _counter.get("flight_button") as Button
    if sim_button != null:
        sim_button.disabled = true
        sim_button.hide()
    if flight_button != null:
        flight_button.disabled = true
        flight_button.hide()
    _counter.set("crystal_count", 0)

    _reset = Button.new()
    _reset.name = "SunbeamReset"
    _style_button(_reset)
    _reset.pressed.connect(_reset_all)
    add_child(_reset)
    _progress = _make_label(self, HORIZONTAL_ALIGNMENT_CENTER, Color("#ffe9a6"))
    _progress.name = "SunbeamProgress"
    _help = _make_label(self, HORIZONTAL_ALIGNMENT_CENTER, Color("#c7fff0"))
    _help.name = "SunbeamHint"
    _audio = AudioStreamPlayer.new()
    _audio.bus = "SFX"
    add_child(_audio)

    _read_locale()
    _reset_all()
    _find_host_back()
    resized.connect(_layout_game)
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        mobile.connect("language_changed", _on_language_changed)
    _translate()
    _layout_game()
    call_deferred("_layout_game")

func _make_label(parent: Node, alignment: HorizontalAlignment, shade: Color) -> Label:
    var label: Label = Label.new()
    label.horizontal_alignment = alignment
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.clip_text = true
    label.add_theme_color_override("font_color", shade)
    parent.add_child(label)
    return label

func _style_button(button: Button) -> void:
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_stylebox_override("normal", KIT.button_style(false))
    button.add_theme_stylebox_override("hover", KIT.button_style(true))
    button.add_theme_stylebox_override("pressed", KIT.button_style(true))
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.add_theme_color_override("font_color", Color("#f7fdff"))

func _read_locale() -> void:
    _locale = "en"
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null:
        _locale = str(mobile.get("language")).to_lower().get_slice("_", 0)
    elif get_node_or_null("/root/LanguageService") != null:
        var service: Node = get_node_or_null("/root/LanguageService")
        _locale = str(service.get("learning_locale")).to_lower().get_slice("_", 0)
    if not WORDS.has(_locale):
        _locale = "en"

func _on_language_changed(_code: String) -> void:
    _read_locale()
    _translate()
    _layout_game()

func _t(key: String) -> String:
    var data: Dictionary = WORDS.get(_locale, WORDS["en"])
    return str(data.get(key, key))

func _translate() -> void:
    if _title == null:
        return
    _title.text = _t("title")
    _subtitle.text = _t("subtitle")
    _reset.text = "↻  " + _t("reset")
    _reset.tooltip_text = _t("reset")
    _update_labels()

func _update_labels() -> void:
    if _progress == null:
        return
    _progress.text = _t("progress") % _captured
    if _phase == "charged":
        _help.text = _t("full") % _cycles
    elif _message == "miss":
        _help.text = _t("miss")
    elif _streak >= 2:
        _help.text = _t("streak") % _streak
    else:
        _help.text = _t(_message)
    if _counter != null:
        _counter.set("crystal_count", roundi(_charge))

func _reset_all() -> void:
    _phase = "gap"
    _phase_time = 0.0
    _ray_duration = RAY_BASE_SECONDS
    _gap_duration = 0.38
    _target_index = -1
    _pressed_target = false
    _opening_elapsed = 0.0
    _ray_captured = false
    _captured = 0
    _charge = 0.0
    _streak = 0
    _cycles = 0
    _missed = 0
    _flower_openings = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    _message = "ready"
    if _board != null:
        _board.call("reset_fx")
        _board.call("set_visual_state", _flower_openings, -1, 0.0, _charge)
    _update_labels()

func beam_speed() -> float:
    # Relative rate: 1.0 at zero streak, rising after *every* successful hit.
    return minf(2.8, pow(STREAK_ACCELERATION, float(_streak)))

func _ray_window_seconds() -> float:
    return maxf(RAY_MIN_SECONDS, RAY_BASE_SECONDS / beam_speed())

func _gap_window_seconds() -> float:
    return maxf(GAP_MIN_SECONDS, GAP_BASE_SECONDS / pow(1.08, float(_streak)))

func _start_random_ray() -> void:
    _start_ray(_rng.randi_range(0, FLOWER_COUNT - 1))

func _start_ray(index: int) -> void:
    if index < 0 or index >= FLOWER_COUNT:
        return
    _phase = "ray"
    _phase_time = 0.0
    _ray_duration = _ray_window_seconds()
    _target_index = index
    _pressed_target = false
    _opening_elapsed = 0.0
    _ray_captured = false
    _message = "ready"
    _update_labels()

func _ray_intensity() -> float:
    if _phase != "ray" or _target_index < 0:
        return 0.0
    var fade_in: float = clampf(_phase_time / 0.16, 0.0, 1.0)
    var fade_out: float = clampf((_ray_duration - _phase_time) / 0.19, 0.0, 1.0)
    return minf(fade_in, fade_out)

func _on_bud_pressed(index: int) -> void:
    if _phase != "ray" or index != _target_index or _ray_captured:
        return
    if _ray_intensity() < 0.16:
        return
    if not _pressed_target:
        _pressed_target = true
        _opening_elapsed = 0.0
        _play_sound(TOUCH_SFX)

func _tick_logic(delta: float) -> void:
    var dt: float = minf(maxf(delta, 0.0), 0.08)
    if _phase == "gap":
        _phase_time += dt
        if _phase_time >= _gap_duration:
            _start_random_ray()
    elif _phase == "charged":
        _phase_time += dt
        if _phase_time >= 1.35:
            _begin_next_battery()
    elif _phase == "ray":
        _phase_time += dt
        if _pressed_target:
            _opening_elapsed += dt

    for i in range(FLOWER_COUNT):
        var goal: float = 1.0 if (_phase == "ray" and i == _target_index and _pressed_target) else 0.0
        _flower_openings[i] = move_toward(_flower_openings[i], goal, dt / OPEN_SECONDS)

    if _phase == "ray":
        if _pressed_target and not _ray_captured and _target_index >= 0:
            if _opening_elapsed >= OPEN_SECONDS and _flower_openings[_target_index] >= 0.94 and _ray_intensity() >= 0.16:
                _capture_target()
        if _phase == "ray" and _phase_time >= _ray_duration:
            _finish_ray()

    if _board != null:
        var visible_target: int = _target_index if _phase == "ray" else -1
        _board.call("set_visual_state", _flower_openings, visible_target, _ray_intensity(), _charge)

func _process(delta: float) -> void:
    if _board != null:
        _tick_logic(delta)

func _capture_target() -> void:
    if _phase != "ray" or _ray_captured or _target_index < 0:
        return
    _ray_captured = true
    _streak += 1
    _captured += 1
    _charge = minf(BATTERY_CAPACITY, BATTERY_CAPACITY * float(_captured) / float(HITS_PER_BATTERY))
    _board.call("pulse_from", _target_index)
    _play_sound(SUCCESS_SFX)
    _message = "hit"
    if _captured >= HITS_PER_BATTERY:
        _cycles += 1
        _charge = BATTERY_CAPACITY
        _phase = "charged"
        _phase_time = 0.0
        _play_sound(FULL_SFX)
    _update_labels()

func _finish_ray() -> void:
    if _phase != "ray":
        return
    if not _ray_captured:
        _missed += 1
        _streak = 0
        _message = "miss"
    else:
        _message = "hit"
    _phase = "gap"
    _phase_time = 0.0
    _gap_duration = _gap_window_seconds()
    _target_index = -1
    _pressed_target = false
    _opening_elapsed = 0.0
    _ray_captured = false
    _update_labels()

func _begin_next_battery() -> void:
    # Infinite play; keep the streak and accumulated cycles. Only reset charge.
    _phase = "gap"
    _phase_time = 0.0
    _gap_duration = _gap_window_seconds()
    _target_index = -1
    _pressed_target = false
    _opening_elapsed = 0.0
    _ray_captured = false
    _captured = 0
    _charge = 0.0
    _flower_openings = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    _message = "ready"
    _update_labels()

func _play_sound(sound: AudioStream) -> void:
    if _audio == null:
        return
    _audio.stop()
    _audio.stream = sound
    _audio.play()

func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view)
    var screen: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if screen.x < 50.0 or screen.y < 50.0 or safe.size.x < 50:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(safe.position) * (view / screen), Vector2(safe.size) * (view / screen))

func _layout_game() -> void:
    if _board == null or _back == null or size.x < 235.0 or size.y < 190.0:
        return
    _space.position = Vector2.ZERO
    _space.size = size
    var safe: Rect2 = _safe_area(size)
    var header_end: float = TOOLBAR.relayout(size, safe, _back, _counter, _title_panel, _title, _subtitle)
    var margin: float = clampf(safe.size.x * 0.01, 5.0, 17.0)
    var gap: float = clampf(safe.size.y * 0.009, 3.0, 10.0)
    var control_height: float = clampf(safe.size.y * 0.069, 28.0, 48.0)
    var reset_width: float = clampf(safe.size.x * 0.13, 70.0, 165.0)
    _reset.position = Vector2(safe.position.x + margin, header_end + gap)
    _reset.size = Vector2(reset_width, control_height)
    _reset.add_theme_font_size_override("font_size", maxi(11, roundi(control_height * 0.38)))
    var progress_x: float = _reset.position.x + reset_width + gap
    var progress_width: float = clampf(safe.size.x * 0.19, 93.0, 265.0)
    _progress.position = Vector2(progress_x, header_end + gap)
    _progress.size = Vector2(progress_width, control_height)
    _progress.add_theme_font_size_override("font_size", maxi(10, roundi(control_height * 0.4)))
    var help_x: float = progress_x + progress_width + gap
    _help.position = Vector2(help_x, header_end + gap)
    _help.size = Vector2(maxf(40.0, safe.end.x - help_x - margin), control_height)
    _help.add_theme_font_size_override("font_size", maxi(10, roundi(control_height * 0.34)))
    var top: float = header_end + control_height + gap * 2.0
    _stage_frame.position = Vector2(safe.position.x + margin, top)
    _stage_frame.size = Vector2(maxf(160.0, safe.size.x - margin * 2.0), maxf(92.0, safe.end.y - top - margin))
    var inset: float = clampf(minf(_stage_frame.size.x, _stage_frame.size.y) * 0.018, 5.0, 13.0)
    _board.position = _stage_frame.position + Vector2.ONE * inset
    _board.size = _stage_frame.size - Vector2.ONE * inset * 2.0

func _find_host_back() -> void:
    var parent_node: Node = get_parent()
    for _i in range(16):
        if parent_node == null:
            break
        for name in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var candidate: Control = parent_node.get_node_or_null(name) as Control
            if candidate != null:
                _outer_back = candidate
                _outer_back.hide()
                return
        parent_node = parent_node.get_parent()

func _exit_tree() -> void:
    if is_instance_valid(_outer_back):
        _outer_back.show()

func _exit_to_cards() -> void:
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "")
        return
    var parent_node: Node = get_parent()
    for _i in range(16):
        if parent_node == null:
            break
        if parent_node.has_method("_v1051_return_to_cards"):
            parent_node.call("_v1051_return_to_cards")
            return
        if parent_node.has_method("_return_to_cards"):
            parent_node.call("_return_to_cards")
            return
        parent_node = parent_node.get_parent()
    var fallback: String = "res://scenes/main.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _exit_to_cards()
        get_viewport().set_input_as_handled()
