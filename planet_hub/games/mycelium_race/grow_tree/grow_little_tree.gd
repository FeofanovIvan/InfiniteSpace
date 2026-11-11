extends Control
## MIKA — Grow, Little Tree! / Расти, деревце! (Godot 4.7.1)
## Self-contained planting game. Original MyceliumRace.gd is left untouched.

const TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const UI_KIT = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const BACK = preload("res://simulator_ui/back_arrow_glyph.gd")
const BG = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/soil_sky.png")
const SHOVEL = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/trowel.png")
const SEED_ICON = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/seed.png")
const WATER = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/watering_can.png")
const MINERALS = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/fertilizer.png")
const HOLE = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/planting_hole.png")
const SUN_SHAFT = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/sunlight_shaft.png")
const SUN_GROUND = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/sunlight_ground.png")
const STAGES = [
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_01.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_02.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_03.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_04.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_05.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_06.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_07.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_08.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_09.png"),
    preload("res://planet_hub/games/mycelium_race/grow_tree/assets/tree_10.png")
]
const GOOD_SOUND = preload("res://learning/audio/sfx/connect_point.ogg")
const BAD_SOUND = preload("res://planet_hub/games/mycelium_race/grow_tree/audio/try_again.wav")
const ACTION_AUDIO = {
    "shovel": preload("res://planet_hub/games/mycelium_race/grow_tree/audio/dig.wav"),
    "seed": preload("res://planet_hub/games/mycelium_race/grow_tree/audio/seed.wav"),
    "water": preload("res://planet_hub/games/mycelium_race/grow_tree/audio/water.wav"),
    "sun": preload("res://planet_hub/games/mycelium_race/grow_tree/audio/sun.wav"),
    "minerals": preload("res://planet_hub/games/mycelium_race/grow_tree/audio/minerals.wav")
}
const TOOL_IDS = ["shovel", "seed", "water", "sun", "minerals"]
const TOOL_COLORS = [Color("d4d9ff"), Color("f4d594"), Color("65ceff"), Color("ffe59c"), Color("b6eb9b")]
const LOCALES = {
    "ru": {"title": "Расти, деревце!", "subtitle": "Посади · Ухаживай · Вырасти", "win": "Дерево выросло!", "lose": "Деревце завяло", "restart": "Заново", "shovel": "Лопатка", "seed": "Семечко", "water": "Лейка", "sun": "Солнце", "minerals": "Минералы"},
    "en": {"title": "Grow, Little Tree!", "subtitle": "Plant · Care · Grow", "win": "Your tree has grown!", "lose": "The tree has wilted", "restart": "Restart", "shovel": "Trowel", "seed": "Seed", "water": "Water", "sun": "Sun", "minerals": "Minerals"},
    "pt": {"title": "Cresça, Arvorezinha!", "subtitle": "Plante · Cuide · Cultive", "win": "A árvore cresceu!", "lose": "A árvore murchou", "restart": "Recomeçar", "shovel": "Pá", "seed": "Semente", "water": "Regador", "sun": "Sol", "minerals": "Minerais"},
    "es": {"title": "¡Crece, Arbolito!", "subtitle": "Planta · Cuida · Cultiva", "win": "¡El árbol ha crecido!", "lose": "El árbol se marchitó", "restart": "Reiniciar", "shovel": "Pala", "seed": "Semilla", "water": "Regadera", "sun": "Sol", "minerals": "Minerales"},
    "de": {"title": "Wachs, kleiner Baum!", "subtitle": "Pflanzen · Pflegen · Wachsen", "win": "Der Baum ist gewachsen!", "lose": "Der Baum ist verwelkt", "restart": "Neu starten", "shovel": "Schaufel", "seed": "Samen", "water": "Gießkanne", "sun": "Sonne", "minerals": "Mineralien"},
    "fr": {"title": "Pousse, petit arbre !", "subtitle": "Plante · Prends soin · Fais pousser", "win": "L’arbre a grandi !", "lose": "L’arbre s’est fané", "restart": "Recommencer", "shovel": "Pelle", "seed": "Graine", "water": "Arrosoir", "sun": "Soleil", "minerals": "Minéraux"}
}

var _language: String = "en"
var _header_title: Label
var _header_subtitle: Label
var _header_panel: Panel
var _back: Button
var _counter: Control
var _restart: Button
var _sfx: AudioStreamPlayer
var _action_sfx: AudioStreamPlayer
var _stage: Rect2 = Rect2(15, 145, 1250, 540)
var _toolbar_bottom: float = 100.0
var _now: float = 0.0
var _phase: String = "dig"
var _expected: String = "shovel"
var _plant_level: int = 0   # zero-based index into the 10 aligned images
var _has_seed: bool = false
var _health: float = 0.0     # -1 dead, +1 fully healthy
var _mistakes: int = 0
var _score: int = 0
var _correct_actions: int = 0
var _care_remaining: float = 11.0
var _selected_tool: int = -1
var _pointer_start: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_point: Vector2 = Vector2.ZERO
var _finished: bool = false
var _won: bool = false
var _effect: String = ""
var _effect_time: float = 0.0
var _effect_duration: float = 1.0
var _pending_tool: String = ""
var _plant_pop_time: float = 0.0
var _rng := RandomNumberGenerator.new()
var _intro_spoken: bool = false
var _runner_back: Button = null
var _runner_back_was_visible: bool = false
var _restart_icon: Label


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_PASS
    _rng.randomize()
    _create_header()
    _set_language_from_settings()
    _reset_game()
    resized.connect(_layout)
    _layout()
    _hide_outer_runner_back()
    call_deferred("_layout")
    call_deferred("_play_intro")


func _hide_outer_runner_back() -> void:
    # The Simulator / Planet Hub adds its own Back ABOVE the game SubViewport.
    # Hide only the matching runner control, never the game's native toolbar Back.
    var candidate: Node = get_parent()
    for depth in range(8):
        if candidate == null:
            break
        for button_name in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var external_back: Button = candidate.get_node_or_null(button_name) as Button
            if external_back != null:
                _runner_back = external_back
                _runner_back_was_visible = external_back.visible
                external_back.hide()
                return
        candidate = candidate.get_parent()

func _exit_tree() -> void:
    # Restore the runner for every other game; no shared scene or script edited.
    if _runner_back != null and is_instance_valid(_runner_back):
        _runner_back.visible = _runner_back_was_visible
    _runner_back = null

func _create_header() -> void:
    _header_panel = Panel.new()
    _header_panel.name = "GrowTreeTitlePanel"
    _header_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_header_panel)
    add_child(_header_panel)
    _header_title = Label.new()
    _header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _header_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header_title.clip_text = true
    _header_panel.add_child(_header_title)
    _header_subtitle = Label.new()
    _header_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _header_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _header_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header_panel.add_child(_header_subtitle)
    _back = Button.new()
    _back.name = "GrowTreeBack"
    _back.focus_mode = Control.FOCUS_NONE
    _back.add_theme_stylebox_override("normal", UI_KIT.button_style())
    _back.add_theme_stylebox_override("hover", UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("pressed", UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _back.pressed.connect(_go_back)
    _back.disabled = false
    _back.visible = true
    _back.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_back)
    var glyph: Control = BACK.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _counter = HUD.new() as Control
    _counter.name = "GrowTreeNativeScore"
    _counter.size = Vector2(1680, 158)
    add_child(_counter)
    for key in ["sim_button", "flight_button"]:
        var b: Button = _counter.get(key) as Button
        if b != null:
            b.disabled = true
            b.hide()
    _restart = Button.new()
    _restart.name = "GrowTreeRestart"
    _restart.focus_mode = Control.FOCUS_NONE
    _restart.add_theme_stylebox_override("normal", UI_KIT.button_style())
    _restart.add_theme_stylebox_override("hover", UI_KIT.button_style(true))
    _restart.add_theme_stylebox_override("pressed", UI_KIT.button_style(true))
    _restart.pressed.connect(_reset_game)
    add_child(_restart)
    _restart_icon = Label.new()
    _restart_icon.name = "GrowTreeRestartGlyph"
    _restart_icon.text = "⟳"
    _restart_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _restart_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _restart_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _restart_icon.add_theme_color_override("font_color", Color("d9fbff"))
    _restart.add_child(_restart_icon)
    _sfx = AudioStreamPlayer.new()
    _sfx.volume_db = -12.0
    add_child(_sfx)
    _action_sfx = AudioStreamPlayer.new()
    _action_sfx.volume_db = -8.0
    add_child(_action_sfx)


func _instruction_line() -> String:
    match _language:
        "ru": return "Расти, деревце! Посади семечко и помоги маленькому дереву вырасти!"
        "pt": return "Cresça, arvorezinha! Plante uma semente e ajude a pequena árvore a crescer!"
        "es": return "¡Crece, arbolito! ¡Planta una semilla y ayuda al arbolito a crecer!"
        "de": return "Wachs, kleiner Baum! Pflanze einen Samen und hilf dem Bäumchen beim Wachsen!"
        "fr": return "Pousse, petit arbre ! Plante une graine et aide ton arbre à grandir !"
        _:
            return "Grow, little tree! Plant a seed and help your little tree grow!"

func _step_speech() -> String:
    var step: String = _expected
    var prompts: Dictionary = {
        "ru": {"seed":"Теперь опусти семечко в ямку.", "water":"Полей деревце из лейки.", "sun":"Подари деревцу солнечный свет.", "minerals":"Покорми деревце минералами."},
        "en": {"seed":"Now place the seed in the hole.", "water":"Water your little tree.", "sun":"Give your little tree some sunshine.", "minerals":"Feed your little tree with minerals."},
        "pt": {"seed":"Agora coloque a semente na cova.", "water":"Regue a sua arvorezinha.", "sun":"Dê um pouco de sol à sua árvore.", "minerals":"Alimente sua árvore com minerais."},
        "es": {"seed":"Ahora pon la semilla en el hoyo.", "water":"Riega tu arbolito.", "sun":"Dale un poco de luz del sol.", "minerals":"Dale minerales a tu arbolito."},
        "de": {"seed":"Lege jetzt den Samen in das Loch.", "water":"Gieße deinen kleinen Baum.", "sun":"Schenk deinem Baum Sonnenlicht.", "minerals":"Gib deinem Baum Mineralien."},
        "fr": {"seed":"Place maintenant la graine dans le trou.", "water":"Arrose ton petit arbre.", "sun":"Offre du soleil à ton arbre.", "minerals":"Donne des minéraux à ton arbre."}
    }
    var lang_data: Dictionary = prompts.get(_language, prompts["en"])
    return str(lang_data.get(step, ""))

func _speak_next_step() -> void:
    if _finished or _pending_tool != "":
        return
    if _phase == "care" and _correct_actions % 3 != 0:
        return
    var message: String = _step_speech()
    if message.is_empty():
        return
    var speaker: Node = get_node_or_null("/root/MikaVoice")
    if speaker != null and speaker.has_method("speak_text"):
        speaker.call("speak_text", message, _language, "fungal")

func _task_prefix() -> String:
    match _language:
        "ru": return "Нужно: "
        "pt": return "Tarefa: "
        "es": return "Tarea: "
        "de": return "Aufgabe: "
        "fr": return "Tâche : "
        _:
            return "Task: "

func _play_intro() -> void:
    if _intro_spoken:
        return
    _intro_spoken = true
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null and voice.has_method("speak_text"):
        var locale := _language if _language != "pt" else "pt_BR"
        voice.call("speak_text", _instruction_line(), locale, "fungal")

func _buzz(ms: int = 35) -> void:
    if OS.get_name() in ["Android", "iOS"]:
        Input.vibrate_handheld(ms)

func _set_language_from_settings() -> void:
    var service: Node = get_node_or_null("/root/LanguageService")
    if service != null:
        var chosen: String = str(service.get("learning_locale")).to_lower()
        if chosen.is_empty() or chosen == "<null>" or chosen == "null":
            chosen = str(service.get("interface_locale")).to_lower()
        _language = chosen.substr(0, 2)
        if service.has_signal("language_changed") and not service.is_connected("language_changed", Callable(self, "_on_lang_changed")):
            service.connect("language_changed", Callable(self, "_on_lang_changed"))
    if not LOCALES.has(_language):
        _language = "en"
    _refresh_language()

func _on_lang_changed(_unused: String) -> void:
    _set_language_from_settings()

func _tr(key: String) -> String:
    var data: Dictionary = LOCALES.get(_language, LOCALES["en"])
    return str(data.get(key, key))

func _refresh_language() -> void:
    _header_title.text = _tr("title")
    _header_subtitle.text = _tr("subtitle")
    _restart.text = "      " + _tr("restart")
    _layout()

func _safe_area() -> Rect2:
    var view: Vector2 = size
    if OS.get_name() not in ["Android", "iOS"]:
        return Rect2(Vector2.ZERO, view)
    var w: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if w.x <= 50.0 or w.y <= 50.0 or safe.size.x <= 50:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(safe.position) * (view / w), Vector2(safe.size) * (view / w))

func _layout() -> void:
    if _back == null or size.x < 200.0 or size.y < 200.0:
        return
    var safe: Rect2 = _safe_area()
    _toolbar_bottom = TOOLBAR.relayout(size, safe, _back, _counter, _header_panel, _header_title, _header_subtitle)
    var margin: float = clampf(safe.size.x * 0.015, 7.0, 25.0)
    var gap: float = clampf(safe.size.y * 0.018, 5.0, 14.0)
    _stage = Rect2(safe.position.x + margin, _toolbar_bottom + gap, maxf(125.0, safe.size.x - 2.0 * margin), maxf(90.0, safe.end.y - _toolbar_bottom - gap - margin))
    _restart.position = _stage.end - Vector2(clampf(_stage.size.x * 0.155, 96.0, 190.0) + 14.0, clampf(_stage.size.y * 0.082, 38.0, 56.0) + 12.0)
    _restart.size = Vector2(clampf(_stage.size.x * 0.155, 96.0, 190.0), clampf(_stage.size.y * 0.082, 38.0, 56.0))
    _restart.add_theme_font_size_override("font_size", maxi(12, roundi(_restart.size.y * 0.34)))
    if _restart_icon != null:
        _restart_icon.position = Vector2(4.0, 0.0)
        _restart_icon.size = Vector2(_restart.size.y * 0.98, _restart.size.y)
        _restart_icon.add_theme_font_size_override("font_size", maxi(23, roundi(_restart.size.y * 0.76)))
    queue_redraw()

func _reset_game() -> void:
    _phase = "dig"
    _expected = "shovel"
    _plant_level = 0
    _has_seed = false
    _health = 0.0
    _mistakes = 0
    _score = 0
    _correct_actions = 0
    _care_remaining = 11.0
    _selected_tool = -1
    _dragging = false
    _finished = false
    _won = false
    _effect = ""
    _effect_time = 0.0
    _effect_duration = 1.0
    _pending_tool = ""
    _plant_pop_time = 0.0
    if _action_sfx != null:
        _action_sfx.stop()
    if _sfx != null:
        _sfx.stop()
    if _counter != null:
        _counter.set("crystal_count", 0)
    queue_redraw()

func _tool_rect(index: int) -> Rect2:
    var side_w: float = clampf(_stage.size.x * 0.155, 65.0, 196.0)
    var x: float = _stage.end.x - side_w - 18.0
    var bh: float = minf(_stage.size.y * 0.126, (_stage.size.y - 100.0) / 5.8)
    bh = maxf(33.0, bh)
    var top: float = _stage.position.y + maxf(25.0, _stage.size.y * 0.10)
    var free: float = maxf(0.0, _stage.size.y * 0.67 - bh)
    var spacing: float = free / 4.0
    return Rect2(x, top + float(index) * spacing, side_w, bh)

func _plant_point() -> Vector2:
    return _stage.position + Vector2(_stage.size.x * 0.48, _stage.size.y * 0.614)

func _plant_target() -> Rect2:
    var c: Vector2 = _plant_point()
    return Rect2(c - Vector2(_stage.size.x * 0.18, _stage.size.y * 0.27), Vector2(_stage.size.x * 0.36, _stage.size.y * 0.48))

func _input(event: InputEvent) -> void:
    if _finished:
        return
    if event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            _handle_pointer(mouse.position, mouse.pressed)
    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        _handle_pointer(touch.position, touch.pressed)
    elif event is InputEventMouseMotion:
        if _selected_tool >= 0 and _dragging:
            _drag_point = event.position
            queue_redraw()
    elif event is InputEventScreenDrag:
        if _selected_tool >= 0 and _dragging:
            _drag_point = event.position
            queue_redraw()

func _handle_pointer(p: Vector2, pressed: bool) -> void:
    if _pending_tool != "":
        return
    if not _stage.has_point(p):
        return
    if pressed:
        for i in range(TOOL_IDS.size()):
            if _tool_rect(i).has_point(p):
                _selected_tool = i
                _dragging = true
                _pointer_start = p
                _drag_point = p
                get_viewport().set_input_as_handled()
                queue_redraw()
                return
        if _selected_tool >= 0 and _plant_target().has_point(p):
            _perform_action(_selected_tool)
            _selected_tool = -1
            get_viewport().set_input_as_handled()
            return
    else:
        if _dragging and _selected_tool >= 0:
            _dragging = false
            if _plant_target().has_point(p):
                _perform_action(_selected_tool)
                _selected_tool = -1
            get_viewport().set_input_as_handled()
            queue_redraw()

func _perform_action(index: int) -> void:
    if _finished or _pending_tool != "" or index < 0 or index >= TOOL_IDS.size():
        return
    var tool: String = str(TOOL_IDS[index])
    if tool != _expected:
        _register_error()
        return
    # Stage, score, seed sprite, and next task change ONLY after the full animation.
    _pending_tool = tool
    _effect = "dig" if tool == "shovel" else tool
    match tool:
        "shovel": _effect_duration = 1.60
        "seed": _effect_duration = 1.75
        "water": _effect_duration = 1.65
        "sun": _effect_duration = 1.85
        "minerals": _effect_duration = 1.75
    _effect_time = _effect_duration
    _selected_tool = -1
    _dragging = false
    var fx_sound: AudioStream = ACTION_AUDIO.get(tool) as AudioStream
    if fx_sound != null and _action_sfx != null:
        _action_sfx.stream = fx_sound
        _action_sfx.play()
    _buzz(20)
    queue_redraw()

func _finish_action_animation() -> void:
    if _pending_tool == "":
        return
    var tool: String = _pending_tool
    _pending_tool = ""
    _effect = ""
    _effect_time = 0.0
    _score += 10
    _correct_actions += 1
    _health = minf(1.0, _health + 0.13)
    if _counter != null:
        _counter.set("crystal_count", _score)
    if _sfx != null:
        _sfx.stream = GOOD_SOUND
        _sfx.play()
    _buzz(36)
    if _phase == "dig":
        _phase = "seed"
        _expected = "seed"
    elif _phase == "seed":
        _has_seed = true
        _phase = "water"
        _expected = "water"
        _plant_level = 0
    elif _phase == "water":
        _phase = "sun"
        _expected = "sun"
        _plant_level = 1
    elif _phase == "sun":
        _phase = "care"
        _plant_level = 2
        _schedule_next_care()
    elif _phase == "care":
        _plant_level = mini(_plant_level + 1, 9)
        _schedule_next_care()
    _plant_pop_time = 0.30
    if _phase == "care" and _plant_level >= 9 and _health >= 0.98:
        _finish(true)
    else:
        call_deferred("_speak_next_step")
    queue_redraw()

func _schedule_next_care() -> void:
    var options := ["water", "sun", "minerals"]
    var next: String = str(options[_rng.randi_range(0, options.size() - 1)])
    if next == _expected:
        next = str(options[(options.find(next) + 1 + _rng.randi_range(0, 1)) % options.size()])
    _expected = next
    _care_remaining = maxf(5.8, 11.0 - float(_correct_actions) * 0.36)

func _register_error() -> void:
    _mistakes += 1
    _health = maxf(-1.0, _health - 0.42)
    _effect = "error"
    _effect_duration = 0.55
    _effect_time = _effect_duration
    _sfx.stream = BAD_SOUND
    _sfx.play()
    _buzz(70)
    if _mistakes >= 3 or _health <= -0.99:
        _finish(false)
    queue_redraw()

func _finish(won: bool) -> void:
    _finished = true
    _won = won
    if won:
        _plant_level = 9
    queue_redraw()

func _process(delta: float) -> void:
    _now += delta
    if _plant_pop_time > 0.0:
        _plant_pop_time = maxf(0.0, _plant_pop_time - delta)
    if _effect_time > 0.0:
        _effect_time = maxf(0.0, _effect_time - delta)
        if _effect_time <= 0.0 and _pending_tool != "":
            _finish_action_animation()
        elif _effect_time <= 0.0:
            _effect = ""
    # Timed care does not run during an action animation or voice instruction.
    if _phase == "care" and not _finished and _pending_tool == "":
        _care_remaining -= delta
        if _care_remaining <= 0.0:
            _register_error()
            _care_remaining = maxf(5.8, 11.0 - float(_correct_actions) * 0.36)
    queue_redraw()

func _effect_progress() -> float:
    return clampf(1.0 - _effect_time / maxf(0.001, _effect_duration), 0.0, 1.0)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("06172d"))
    if _stage.size.x < 50.0:
        return
    _draw_cover_background()
    if _effect == "sun" and _effect_time > 0.0:
        _draw_sunlight()
    _draw_plant()
    _draw_hole()
    _draw_focus()
    _draw_tools()
    _draw_meter()
    _draw_effects()
    _draw_corner_mask()
    var frame := StyleBoxFlat.new()
    frame.bg_color = Color.TRANSPARENT
    frame.border_color = Color("65e7ff")
    frame.set_border_width_all(3)
    frame.set_corner_radius_all(26)
    frame.shadow_color = Color(0.0, 0.67, 1.0, 0.22)
    frame.shadow_size = 6
    frame.anti_aliasing = true
    draw_style_box(frame, _stage)
    if _finished:
        _draw_finish_banner()

func _draw_cover_background() -> void:
    var original: Vector2 = BG.get_size()
    var stage_size: Vector2 = _stage.size
    var cover: float = maxf(stage_size.x / original.x, stage_size.y / original.y)
    var crop: Vector2 = stage_size / cover
    var crop_x: float = (original.x - crop.x) * 0.5
    var grass_at: float = 577.0  # native image horizon
    var crop_y: float = clampf(grass_at - 0.614 * crop.y, 0.0, original.y - crop.y)
    # Preserve the source artwork's native colors; the former blue-grey tint
    # looked like a translucent film over the entire playable panel.
    draw_texture_rect_region(BG, _stage, Rect2(Vector2(crop_x, crop_y), crop), Color.WHITE)

func _draw_plant() -> void:
    if not _has_seed:
        return
    var center: Vector2 = _plant_point()
    var height: float = minf(_stage.size.y * 0.80, _stage.size.x * 0.37)
    var width: float = height * 344.0 / 682.0
    if _plant_pop_time > 0.0:
        var b: float = sin((1.0 - _plant_pop_time / 0.30) * PI)
        height *= 1.0 + b * 0.045
        width *= 1.0 + b * 0.045
    var top_y: float = center.y - height * 455.0 / 682.0
    var tex: Texture2D = STAGES[clampi(_plant_level, 0, 9)]
    var tint: Color = Color.WHITE
    if _health < -0.01:
        tint = Color(1.0, 0.86 + 0.13 * (1.0 + _health), 0.64 + 0.30 * (1.0 + _health), 1.0)
    draw_texture_rect(tex, Rect2(Vector2(center.x - width / 2.0, top_y), Vector2(width, height)), false, tint)


func _hole_rect() -> Rect2:
    var center: Vector2 = _plant_point() + Vector2(0.0, _stage.size.y * 0.072)
    var w: float = minf(_stage.size.x * 0.23, _stage.size.y * 0.38)
    return Rect2(center - Vector2(w * 0.5, w * 0.10), Vector2(w, w * 0.46))

func _draw_hole() -> void:
    var opacity: float = 0.0
    if _phase == "seed":
        opacity = 1.0
        if _effect == "seed" and _effect_time > 0.0:
            opacity = 1.0 - smoothstep(0.53, 0.98, _effect_progress())
    elif _phase == "dig" and _effect == "dig" and _effect_time > 0.0:
        opacity = smoothstep(0.42, 0.89, _effect_progress())
    if opacity > 0.001:
        draw_texture_rect(HOLE, _hole_rect(), false, Color(1, 1, 1, opacity))

func _draw_focus() -> void:
    if _finished:
        return
    var center: Vector2 = _plant_point()
    var pulse: float = 0.45 + 0.55 * sin(_now * 4.8)
    var base: float = minf(_stage.size.x, _stage.size.y) * 0.10
    draw_circle(center, base * 1.5, Color(0.3, 1.0, 0.65, 0.025 + pulse * 0.030))
    draw_arc(center, base, 0.0, TAU, 68, Color(0.49, 1.0, 0.74, 0.30 + pulse * 0.40), 3.0, true)
    if _phase == "care":
        var remain: float = clampf(_care_remaining / 11.0, 0.0, 1.0)
        draw_arc(center, base + 8.0, -PI * 0.5, -PI * 0.5 + TAU * remain, 48, Color("ffe29a"), 3.0, true)
    _draw_prompt()


func _draw_prompt() -> void:
    var r: float = clampf(_stage.size.y * 0.092, 30.0, 68.0)
    var center: Vector2 = _stage.position + Vector2(r * 1.55, r * 1.55)
    draw_circle(center, r + 6.0, Color(0.02, 0.17, 0.30, 0.87))
    draw_arc(center, r, 0.0, TAU, 64, Color("7ceaf9"), 4.0, true)
    draw_circle(center, r * 0.82, Color(0.06, 0.18, 0.33, 0.93))
    _draw_tool_icon(TOOL_IDS.find(_expected), center, r * 1.35)
    var face: Font = get_theme_default_font()
    if face != null:
        var label_rect := Rect2(center.x - r * 1.6, center.y + r * 1.08, r * 3.6, r * 1.3)
        var size_px: int = maxi(12, roundi(r * 0.34))
        draw_string(face, label_rect.position + Vector2(0, size_px), _task_prefix() + _tr(_expected), HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, size_px, Color("e9ffff"))

func _draw_tools() -> void:
    for i in range(TOOL_IDS.size()):
        var card: Rect2 = _tool_rect(i)
        var active: bool = str(TOOL_IDS[i]) == _expected
        var skin := StyleBoxFlat.new()
        skin.bg_color = Color(0.035, 0.10, 0.22, 0.88)
        skin.border_color = Color("a2f6cb") if active else Color(0.42, 0.71, 0.81, 0.65)
        skin.set_border_width_all(3 if active else 2)
        skin.set_corner_radius_all(16)
        skin.anti_aliasing = true
        draw_style_box(skin, card)
        var icon_pos: Vector2 = card.get_center()
        _draw_tool_icon(i, icon_pos, minf(card.size.y * 0.95, card.size.x * 0.83))
        if active:
            draw_arc(icon_pos, minf(card.size.y * 0.5, card.size.x * 0.48), 0, TAU, 36, Color(0.70, 1.0, 0.83, 0.25 + 0.15 * sin(_now * 6.0)), 2.0, true)
    if _dragging and _selected_tool >= 0:
        _draw_tool_icon(_selected_tool, _drag_point, clampf(_stage.size.y * 0.11, 45, 90))

func _draw_tool_icon(index: int, center: Vector2, d: float) -> void:
    if index == 0 or index == 2 or index == 4:
        var tex: Texture2D = SHOVEL if index == 0 else (WATER if index == 2 else MINERALS)
        var aspect: float = float(tex.get_width()) / maxf(1.0, float(tex.get_height()))
        var rect: Rect2 = Rect2(center - Vector2(d * aspect, d) * 0.5, Vector2(d * aspect, d))
        draw_texture_rect(tex, rect, false)
    elif index == 1:
        # Exactly the seed from the 10-stage artwork, including the task prompt.
        var height: float = d * 0.86
        var aspect: float = float(SEED_ICON.get_width()) / maxf(1.0, float(SEED_ICON.get_height()))
        var seed_size: Vector2 = Vector2(height * aspect, height)
        draw_texture_rect(SEED_ICON, Rect2(center - seed_size * 0.5, seed_size), false)
    elif index == 3:
        draw_circle(center, d * 0.30, Color(1.0, 0.73, 0.25, 0.12))
        for j in range(10):
            var ang: float = TAU * float(j) / 10.0
            var dir := Vector2(cos(ang), sin(ang))
            draw_line(center + dir * (d * 0.32), center + dir * (d * 0.43), Color("ffe3a6"), d * 0.05, true)
        draw_circle(center, d * 0.24, Color("ffcf5c"))
        draw_circle(center - Vector2(d * 0.06, d * 0.06), d * 0.11, Color("fff8cb"))

func _draw_meter() -> void:
    var rect: Rect2 = Rect2(_stage.position.x + maxf(13.0, _stage.size.x * 0.023), _stage.position.y + _stage.size.y * 0.30, clampf(_stage.size.x * 0.035, 18, 39), _stage.size.y * 0.55)
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color("0e1d2c")
    skin.border_color = Color("65e7ff")
    skin.set_border_width_all(2)
    skin.set_corner_radius_all(13)
    draw_style_box(skin, rect)
    var inner: Rect2 = rect.grow(-4.0)
    var mid_y: float = inner.position.y + inner.size.y * 0.5
    draw_rect(Rect2(inner.position.x, inner.position.y, inner.size.x, inner.size.y * 0.50), Color("193b34"))
    draw_rect(Rect2(inner.position.x, mid_y, inner.size.x, inner.size.y * 0.50), Color("502628"))
    var extent: float = inner.size.y * 0.5 * absf(_health)
    if _health >= 0:
        draw_rect(Rect2(inner.position.x, mid_y - extent, inner.size.x, extent), Color("67ef85"))
    else:
        draw_rect(Rect2(inner.position.x, mid_y, inner.size.x, extent), Color("f26764"))
    draw_line(Vector2(rect.position.x - 2.0, mid_y), Vector2(rect.end.x + 2.0, mid_y), Color("d8fdff"), 3.0, true)
    var marker_y: float = mid_y - _health * (inner.size.y * 0.5)
    draw_circle(Vector2(rect.get_center().x, marker_y), maxf(6.0, rect.size.x * 0.30), Color("b6fff3") if _health >= 0 else Color("ffa6a2"))
    for k in range(_mistakes):
        draw_circle(_stage.position + Vector2(rect.position.x - _stage.position.x + rect.size.x * 0.5, _stage.size.y * 0.87 + k * 14.0), 4.0, Color("ff8f84"))


func _draw_anchored_sprite(image: Texture2D, anchor_world: Vector2, anchor_uv: Vector2, rotation: float, scale_factor: float) -> void:
    # Transform a known source-image landmark onto a world-space point.
    # Water begins at the watering-can SPOUT, granules at the bag OPENING.
    var origin: Vector2 = (image.get_size() * (anchor_uv - Vector2(0.5, 0.5))).rotated(rotation) * scale_factor
    draw_set_transform(anchor_world - origin, rotation, Vector2.ONE * scale_factor)
    draw_texture(image, -image.get_size() * 0.5)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_dirt_piece(point: Vector2, radius: float, opacity: float) -> void:
    draw_circle(point + Vector2(0.7, 1.1), radius * 1.1, Color(0.30, 0.14, 0.07, opacity * 0.8))
    draw_circle(point, radius, Color(0.61, 0.34, 0.18, opacity))
    draw_circle(point + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.37, Color(0.86, 0.57, 0.32, opacity * 0.62))

func _draw_dig_animation(p: float) -> void:
    var soil: Vector2 = _plant_point() + Vector2(0.0, _stage.size.y * 0.072)
    var active: float = fmod(p * 2.0, 1.0)
    var penetration: float = smoothstep(0.10, 0.50, active)
    var lifting: float = smoothstep(0.52, 0.88, active)
    var target: Vector2 = soil + Vector2(-_stage.size.x * 0.045 * (1.0 - penetration), -_stage.size.y * 0.14 * (1.0 - penetration) - _stage.size.y * 0.04 * lifting)
    var tilt: float = -0.35 - 0.27 * penetration + 0.42 * lifting
    var scale_factor: float = minf(_stage.size.x * 0.19 / float(SHOVEL.get_width()), _stage.size.y * 0.36 / float(SHOVEL.get_height()))
    _draw_anchored_sprite(SHOVEL, target, Vector2(0.10, 0.90), tilt, scale_factor)
    for i in range(19):
        var birth: float = float(i % 9) * 0.037
        var t: float = active - birth
        if t < 0.0 or t > 0.68:
            continue
        var vx: float = (float((i * 13) % 17) - 8.0) / 8.0
        var drift: Vector2 = Vector2(vx * _stage.size.y * 0.075 * t, -_stage.size.y * 0.12 * sin(t * PI / 0.68))
        var point: Vector2 = soil + drift
        _draw_dirt_piece(point, clampf(_stage.size.y * 0.007, 2.0, 5.0) * (1.0 - t), 1.0 - t / 0.68)

func _draw_soil_closure(p: float) -> void:
    var t: float = smoothstep(0.51, 0.97, p)
    if t <= 0.0:
        return
    var hole: Rect2 = _hole_rect()
    var soil: Vector2 = hole.get_center() + Vector2(0.0, hole.size.y * 0.30)
    for i in range(20):
        var side: float = -1.0 if i % 2 == 0 else 1.0
        var a: float = float(i / 2) / 9.0
        var x: float = soil.x + side * hole.size.x * (0.46 - 0.40 * t) * (0.65 + 0.35 * a)
        var y: float = soil.y - t * hole.size.y * 0.19 + 5.0 * sin(float(i) * 2.41)
        _draw_dirt_piece(Vector2(x, y), maxf(2.0, hole.size.y * 0.09 * (0.65 + 0.45 * a)), t * 0.82)

func _draw_seed_animation(p: float) -> void:
    var hole: Rect2 = _hole_rect()
    var soil_target: Vector2 = hole.get_center() + Vector2(0.0, hole.size.y * 0.04)
    var fall: float = smoothstep(0.05, 0.49, p)
    var start: Vector2 = soil_target - Vector2(0.0, _stage.size.y * 0.26)
    var current: Vector2 = start.lerp(soil_target, fall)
    var fading: float = 1.0 - smoothstep(0.57, 0.85, p)
    var img_h: float = clampf(_stage.size.y * 0.095, 22.0, 48.0)
    var img_w: float = img_h * float(SEED_ICON.get_width()) / float(SEED_ICON.get_height())
    draw_texture_rect(SEED_ICON, Rect2(current - Vector2(img_w, img_h) * 0.5, Vector2(img_w, img_h)), false, Color(1, 1, 1, fading))
    # Soil only closes after the seed has fully descended into the open hole.
    _draw_soil_closure(p)

func _pour_pose(tool: String, p: float) -> Dictionary:
    # An upright tool approaches first, pivots toward the tree, pours, straightens
    # and departs. The stream originates from the exact transformed PNG landmark.
    var watering: bool = tool == "water"
    var image: Texture2D = WATER if watering else MINERALS
    var pivot_uv: Vector2 = Vector2(0.62, 0.73) if watering else Vector2(0.52, 0.75)
    var mouth_uv: Vector2 = Vector2(0.145, 0.385) if watering else Vector2(0.50, 0.18)
    var scale_factor: float
    if watering:
        scale_factor = minf(_stage.size.y * 0.39 / float(image.get_height()), _stage.size.x * 0.20 / float(image.get_width()))
    else:
        scale_factor = minf(_stage.size.y * 0.35 / float(image.get_height()), _stage.size.x * 0.17 / float(image.get_width()))
    var approach: float = smoothstep(0.015, 0.19, p)
    var tip_in: float = smoothstep(0.20, 0.42, p)
    var tip_out: float = 1.0 - smoothstep(0.77, 0.94, p)
    var tipped: float = tip_in * tip_out
    var depart: float = smoothstep(0.92, 1.0, p)
    var soil: Vector2 = _plant_point() + Vector2(0.0, _stage.size.y * 0.07)
    var pivot: Vector2
    var angle: float
    var flow: float
    if watering:
        pivot = soil + Vector2(_stage.size.x * 0.135, -_stage.size.y * 0.325)
        pivot += Vector2(_stage.size.x * 0.065, -_stage.size.y * 0.055) * (1.0 - approach)
        pivot += Vector2(-_stage.size.x * 0.006, _stage.size.y * 0.092) * tipped
        pivot += Vector2(_stage.size.x * 0.065, -_stage.size.y * 0.07) * depart
        # The PNG's nozzle is LEFT. Negative angle makes it LOWER, not rise.
        angle = -0.81 * tipped
        flow = smoothstep(0.38, 0.46, p) * (1.0 - smoothstep(0.76, 0.88, p))
    else:
        pivot = soil + Vector2(_stage.size.x * 0.145, -_stage.size.y * 0.21)
        pivot += Vector2(_stage.size.x * 0.065, -_stage.size.y * 0.05) * (1.0 - approach)
        pivot += Vector2(-_stage.size.x * 0.008, _stage.size.y * 0.040) * tipped
        pivot += Vector2(_stage.size.x * 0.07, -_stage.size.y * 0.08) * depart
        # From UPRIGHT to nearly horizontal, with its open mouth facing LEFT.
        angle = -1.30 * tipped
        flow = smoothstep(0.43, 0.51, p) * (1.0 - smoothstep(0.76, 0.88, p))
    var mouth: Vector2 = pivot + (image.get_size() * (mouth_uv - pivot_uv) * scale_factor).rotated(angle)
    return {
        "image": image, "pivot": pivot, "pivot_uv": pivot_uv,
        "mouth": mouth, "angle": angle, "scale": scale_factor,
        "flow": flow, "soil": soil, "tipped": tipped
    }

func _draw_water_animation(p: float) -> void:
    var pose: Dictionary = _pour_pose("water", p)
    _draw_anchored_sprite(WATER, pose["pivot"], pose["pivot_uv"], pose["angle"], pose["scale"])
    var ground: Vector2 = pose["soil"]
    # Only release droplets AFTER the nozzle has tilted downwards.
    # Calculate each droplet's birth position from the historical nozzle pose,
    # so falling water does not move with the can when it straightens.
    for i in range(65):
        var birth: float = 0.39 + float(i) * 0.0057
        var age: float = (p - birth) / 0.25
        if age < 0.0 or age >= 1.0:
            continue
        var birth_pose: Dictionary = _pour_pose("water", birth)
        var origin: Vector2 = birth_pose["mouth"]
        var side: float = sin(float(i) * 2.17) * _stage.size.x * 0.020
        var destination: Vector2 = ground + Vector2(side, float(i % 3) * 2.0)
        var fall: float = age * age * (3.0 - 2.0 * age)
        var at: Vector2 = origin.lerp(destination, fall)
        at.x += sin(float(i) * 1.93) * _stage.size.x * 0.005 * age
        var alpha: float = 1.0 - smoothstep(0.83, 1.0, age)
        var radius: float = clampf(_stage.size.y * 0.0056, 1.8, 3.5)
        draw_line(at - Vector2(0.0, radius * 3.0), at, Color(0.54, 0.90, 1.0, alpha * 0.75), radius * 0.85, true)
        draw_circle(at, radius, Color(0.80, 0.97, 1.0, alpha))
    if p > 0.55:
        var ring_alpha: float = (1.0 - smoothstep(0.72, 1.0, p)) * 0.58
        for j in range(3):
            var rr: float = _stage.size.y * (0.016 + float(j) * 0.013 + fmod(p * 3.6, 1.0) * 0.020)
            draw_arc(ground, rr, PI * 0.10, PI * 0.90, 24, Color(0.65, 0.94, 1.0, ring_alpha), 1.8, true)

func _draw_granule(point: Vector2, radius: float, alpha: float, violet: bool) -> void:
    # Small spherical pellet, with Bubble feeder's multi-tone volume treatment.
    var core: Color = Color(0.56, 0.34, 0.17, alpha) if not violet else Color(0.57, 0.38, 0.87, alpha)
    draw_circle(point + Vector2(0.4, 0.8), radius * 1.12, Color(0.25, 0.12, 0.11, alpha * 0.67))
    draw_circle(point, radius, core)
    draw_circle(point + Vector2(-radius * 0.25, -radius * 0.30), radius * 0.45, Color(1.0, 0.85, 0.58, alpha * 0.65))

func _draw_minerals_animation(p: float) -> void:
    var pose: Dictionary = _pour_pose("minerals", p)
    _draw_anchored_sprite(MINERALS, pose["pivot"], pose["pivot_uv"], pose["angle"], pose["scale"])
    var soil: Vector2 = pose["soil"]
    # Individual pellets come from the bag's rotating OPEN TOP, not from the
    # center of the screen. Feed only starts once the bag is almost horizontal.
    for i in range(70):
        var birth: float = 0.44 + float(i) * 0.0049
        var age: float = (p - birth) / 0.30
        if age < 0.0 or age >= 1.0:
            continue
        var birth_pose: Dictionary = _pour_pose("minerals", birth)
        var origin: Vector2 = birth_pose["mouth"] + Vector2(-2.5, 1.5)
        var drift: float = sin(float(i) * 2.37) * _stage.size.x * 0.047
        var destination: Vector2 = soil + Vector2(drift, float(i % 4) * 2.0)
        var fall: float = age * age * (3.0 - 2.0 * age)
        var at: Vector2 = origin.lerp(destination, fall)
        at.x += sin(float(i) * 4.21) * _stage.size.x * 0.006 * age
        var opacity: float = 1.0 - smoothstep(0.83, 1.0, age)
        var radius: float = clampf(_stage.size.y * 0.0052, 1.6, 3.5) * (0.85 + float(i % 4) * 0.12)
        _draw_granule(at, radius, opacity, i % 5 == 0)
    # Pellets briefly accumulate on the soil as the bag is straightening.
    var landed: float = smoothstep(0.60, 0.79, p) * (1.0 - smoothstep(0.87, 1.0, p))
    for j in range(16):
        var pos: Vector2 = soil + Vector2(sin(float(j) * 2.7) * _stage.size.x * 0.052, -float(j % 3) * 1.8)
        _draw_granule(pos, clampf(_stage.size.y * 0.0055, 1.6, 3.5), landed, j % 5 == 0)

func _draw_sunlight() -> void:
    var p: float = _effect_progress()
    var glow: float = smoothstep(0.07, 0.30, p) * (1.0 - smoothstep(0.78, 0.98, p))
    var focus: Vector2 = _plant_point()
    var sweep: float = _stage.size.x * 0.055 * (1.0 - smoothstep(0.02, 0.43, p))
    var x: float = focus.x + sweep + sin(_now * 3.1) * _stage.size.x * 0.005
    var width: float = clampf(_stage.size.x * 0.23, 100.0, 320.0)
    var shaft: Rect2 = Rect2(Vector2(x - width * 0.5, _stage.position.y), Vector2(width, focus.y - _stage.position.y + _stage.size.y * 0.10))
    draw_texture_rect(SUN_SHAFT, shaft, false, Color(1.0, 0.98, 0.77, glow * 0.86))
    draw_texture_rect(SUN_SHAFT, Rect2(shaft.position + Vector2(width * 0.23, 0.0), Vector2(width * 0.54, shaft.size.y)), false, Color(1, 1, 0.92, glow * 0.26))
    var halo_w: float = width * 1.15
    draw_texture_rect(SUN_GROUND, Rect2(Vector2(x - halo_w * 0.5, focus.y - _stage.size.y * 0.025), Vector2(halo_w, _stage.size.y * 0.17)), false, Color(1, 0.97, 0.75, glow * 0.93))
    # Gentle floating motes, not a hard rectangle or extra cartoon sun.
    for i in range(14):
        var fx: float = x + sin(float(i) * 12.31 + _now * 0.5) * width * 0.33
        var fy: float = _stage.position.y + fmod(float(i) * 69.7 + _now * (11.0 + float(i % 4) * 4.0), maxf(10.0, shaft.size.y))
        draw_circle(Vector2(fx, fy), 1.0 + float(i % 3), Color(1.0, 0.99, 0.72, glow * (0.25 + 0.09 * float(i % 3))))

func _draw_effects() -> void:
    if _effect_time <= 0.0:
        return
    var p: float = _effect_progress()
    match _effect:
        "dig": _draw_dig_animation(p)
        "seed": _draw_seed_animation(p)
        "water": _draw_water_animation(p)
        "minerals": _draw_minerals_animation(p)
        "sun":
            # Beam is rendered below the tree by _draw_sunlight().
            pass
        "error":
            draw_arc(_plant_point(), _stage.size.y * 0.09, 0, TAU, 48, Color(1.0, 0.22, 0.24, 0.60 * (1.0 - p)), 4.0, true)

func _draw_corner_mask() -> void:
    # Precise cutouts over stage artwork. No square background leaks beyond rounded corners.
    var radius: float = minf(26.0, _stage.size.y * 0.08)
    var fill: Color = Color("06172d")
    var centers := [
        _stage.position + Vector2(radius, radius),
        Vector2(_stage.end.x - radius, _stage.position.y + radius),
        _stage.end - Vector2(radius, radius),
        Vector2(_stage.position.x + radius, _stage.end.y - radius)
    ]
    var corners := [_stage.position, Vector2(_stage.end.x, _stage.position.y), _stage.end, Vector2(_stage.position.x, _stage.end.y)]
    var starts := [PI, -PI * 0.5, 0.0, PI * 0.5]
    for i in range(4):
        var poly := PackedVector2Array()
        poly.append(corners[i])
        for k in range(17):
            var angle: float = float(starts[i]) + float(k) * PI * 0.5 / 16.0
            poly.append(centers[i] + Vector2(cos(angle), sin(angle)) * radius)
        draw_colored_polygon(poly, fill)

func _draw_finish_banner() -> void:
    var w: float = _stage.size.x * 0.55
    var h: float = clampf(_stage.size.y * 0.22, 60.0, 146.0)
    var rect: Rect2 = Rect2(_stage.get_center() - Vector2(w, h) * 0.5, Vector2(w, h))
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.03, 0.14, 0.25, 0.94)
    skin.border_color = Color("8cf5a5") if _won else Color("fa9292")
    skin.set_border_width_all(3)
    skin.set_corner_radius_all(20)
    draw_style_box(skin, rect)
    var face := ThemeDB.fallback_font
    draw_string(face, rect.position + Vector2(15.0, rect.size.y * 0.64), _tr("win") if _won else _tr("lose"), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 30.0, maxi(12, roundi(h * 0.21)), Color("f1fff1"))

func _go_back() -> void:
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "")
        return
    var parent_node: Node = get_parent()
    for i in range(16):
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
        _go_back()
        get_viewport().set_input_as_handled()
