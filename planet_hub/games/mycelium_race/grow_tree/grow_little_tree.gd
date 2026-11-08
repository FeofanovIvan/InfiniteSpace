extends Control
## MIKA — Grow, Little Tree! / Расти, деревце! (Godot 4.7.1)
## Self-contained planting game. Original MyceliumRace.gd is left untouched.

const TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const UI_KIT = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const BACK = preload("res://simulator_ui/back_arrow_glyph.gd")
const BG = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/soil_sky.png")
const SHOVEL = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/trowel.png")
const WATER = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/watering_can.png")
const MINERALS = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/fertilizer.png")
const HOLE = preload("res://planet_hub/games/mycelium_race/grow_tree/assets/planting_hole.png")
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
const GOOD_SOUND = preload("res://education/playtown/audio/sfx/correct.ogg")
const BAD_SOUND = preload("res://education/playtown/audio/sfx/wrong.ogg")
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
var _rng := RandomNumberGenerator.new()
var _intro_spoken: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_PASS
    _rng.randomize()
    _create_header()
    _set_language_from_settings()
    _reset_game()
    resized.connect(_layout)
    _layout()
    call_deferred("_layout")
    call_deferred("_play_intro")

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
    _back.disabled = true
    _back.visible = false
    _back.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
    _sfx = AudioStreamPlayer.new()
    add_child(_sfx)


func _instruction_line() -> String:
    match _language:
        "ru": return "Вырасти деревце: копай, сажай, поливай и свети солнцем."
        "pt": return "Cultive a arvorezinha: cave, plante, regue e dê sol."
        "es": return "Haz crecer el arbolito: cava, planta, riega y dale sol."
        "de": return "Lass den kleinen Baum wachsen: graben, pflanzen, gießen und Sonne geben."
        "fr": return "Fais pousser le petit arbre : creuse, plante, arrose et donne du soleil."
        _:
            return "Grow your little tree: dig, plant, water, and shine the sun."

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
        voice.call("speak_text", _instruction_line(), locale, "tablet")

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
    _restart.text = "⟳  " + _tr("restart")
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
    _restart.add_theme_font_size_override("font_size", maxi(12, roundi(_restart.size.y * 0.42)))
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
    if _finished or index < 0 or index >= TOOL_IDS.size():
        return
    var tool: String = str(TOOL_IDS[index])
    if tool != _expected:
        _register_error()
        return
    _score += 10
    _correct_actions += 1
    _health = minf(1.0, _health + 0.13)
    if _counter != null:
        _counter.set("crystal_count", _score)
    _sfx.stream = GOOD_SOUND
    _sfx.play()
    _buzz(28)
    if _phase == "dig":
        _phase = "seed"
        _expected = "seed"
        _effect = "dig"
    elif _phase == "seed":
        _has_seed = true
        _phase = "water"
        _expected = "water"
        _plant_level = 0
        _effect = "seed"
    elif _phase == "water":
        _phase = "sun"
        _expected = "sun"
        _plant_level = 1
        _effect = "water"
    elif _phase == "sun":
        _phase = "care"
        _plant_level = 2
        _effect = "sun"
        _schedule_next_care()
    elif _phase == "care":
        _plant_level = mini(_plant_level + 1, 9)
        _effect = tool
        _schedule_next_care()
    _effect_time = 1.0
    if _phase == "care" and _plant_level >= 9 and _health >= 0.98:
        _finish(true)
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
    _effect_time = 0.55
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
    if _effect_time > 0.0:
        _effect_time = maxf(0.0, _effect_time - delta)
    if _phase == "care" and not _finished:
        _care_remaining -= delta
        if _care_remaining <= 0.0:
            _register_error()
            _care_remaining = maxf(5.8, 11.0 - float(_correct_actions) * 0.36)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("06172d"))
    if _stage.size.x < 50.0:
        return
    _draw_cover_background()
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
    draw_texture_rect_region(BG, _stage, Rect2(Vector2(crop_x, crop_y), crop), Color(0.78, 0.83, 0.93))

func _draw_plant() -> void:
    if not _has_seed:
        return
    var center: Vector2 = _plant_point()
    var height: float = minf(_stage.size.y * 0.80, _stage.size.x * 0.37)
    var width: float = height * 344.0 / 682.0
    var top_y: float = center.y - height * 455.0 / 682.0
    var tex: Texture2D = STAGES[clampi(_plant_level, 0, 9)]
    var tint: Color = Color.WHITE
    if _health < -0.01:
        tint = Color(1.0, 0.86 + 0.13 * (1.0 + _health), 0.64 + 0.30 * (1.0 + _health), 1.0)
    draw_texture_rect(tex, Rect2(Vector2(center.x - width / 2.0, top_y), Vector2(width, height)), false, tint)


func _draw_hole() -> void:
    if _phase != "seed":
        return
    var center: Vector2 = _plant_point() + Vector2(0.0, _stage.size.y * 0.072)
    var w: float = minf(_stage.size.x * 0.23, _stage.size.y * 0.38)
    draw_texture_rect(HOLE, Rect2(center - Vector2(w * 0.5, w * 0.10), Vector2(w, w * 0.46)), false)

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
        var points := PackedVector2Array([
            center + Vector2(0, -0.36 * d), center + Vector2(0.32 * d, -0.10 * d),
            center + Vector2(0.23 * d, 0.25 * d), center + Vector2(0, 0.38 * d),
            center + Vector2(-0.23 * d, 0.25 * d), center + Vector2(-0.32 * d, -0.10 * d)
        ])
        draw_colored_polygon(points, Color("b87b3c"))
        draw_arc(center, d * 0.30, PI * 1.08, PI * 1.70, 22, Color("ffe8a6"), d * 0.06, true)
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


func _draw_effects() -> void:
    if _effect_time <= 0.0:
        return
    var focus: Vector2 = _plant_point()
    var p: float = 1.0 - _effect_time
    if _effect == "dig":
        var ground_focus: Vector2 = focus + Vector2(0.0, _stage.size.y * 0.075)
        var shovel_pos: Vector2 = ground_focus + Vector2(-_stage.size.x * 0.11 + p * _stage.size.x * 0.085, -_stage.size.y * 0.015 + sin(p * PI) * _stage.size.y * 0.028)
        draw_set_transform(shovel_pos, -0.72 + 0.22 * sin(p * PI), Vector2.ONE * clampf(_stage.size.y / 1100.0, 0.24, 0.36))
        draw_texture(SHOVEL, -SHOVEL.get_size() * 0.5)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        for i in range(18):
            var t: float = float(i) / 17.0
            var x: float = ground_focus.x + (t - 0.5) * _stage.size.x * 0.13
            var y: float = ground_focus.y + 3.0 + 5.0 * sin(t * PI) - 18.0 * sin(p * PI)
            draw_circle(Vector2(x, y), 2.8 + 2.2 * (1.0 - p), Color(0.67, 0.42, 0.24, 0.78 * _effect_time))
    elif _effect == "seed":
        var seed_center := focus + Vector2(0.0, -18.0 + p * 34.0)
        var seed_points := PackedVector2Array()
        for j in range(20):
            var ang: float = TAU * float(j) / 20.0
            seed_points.append(seed_center + Vector2(sin(ang) * 8.0, cos(ang) * 11.0))
        draw_colored_polygon(seed_points, Color("9b6a35", _effect_time))
        draw_line(seed_center + Vector2(0, -7), seed_center + Vector2(0, 8), Color("e7d4aa", _effect_time), 2.0, true)
    elif _effect == "sun":
        var top_y: float = _stage.position.y + 3.0
        var ground_y: float = _plant_point().y + _stage.size.y * 0.06
        var beam_w: float = clampf(_stage.size.x * 0.13, 56.0, 110.0)
        for k in range(5):
            var pad := float(k) * 10.0
            var alpha := (0.06 + float(5 - k) * 0.03) * _effect_time
            draw_rect(Rect2(focus.x - beam_w * 0.5 - pad * 0.3, top_y, beam_w + pad * 0.6, ground_y - top_y), Color(1.0, 0.95, 0.58, alpha))
        draw_circle(Vector2(focus.x, top_y + 35.0), 18.0, Color(1.0, 0.88, 0.30, 0.85 * _effect_time))
        draw_circle(Vector2(focus.x, top_y + 35.0), 30.0, Color(1.0, 0.94, 0.70, 0.18 * _effect_time))
    elif _effect == "water":
        var can_pos: Vector2 = focus + Vector2(_stage.size.x * 0.10, -_stage.size.y * 0.15)
        draw_set_transform(can_pos, -0.48, Vector2.ONE * clampf(_stage.size.y / 980.0, 0.32, 0.48))
        draw_texture(WATER, -WATER.get_size() * 0.5)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        for i in range(18):
            var t: float = float(i) / 17.0
            var drop_x: float = can_pos.x - 45.0 + t * 22.0
            var drop_y: float = can_pos.y + 25.0 + p * 140.0 + fmod(float(i * 19), 28.0)
            draw_line(Vector2(drop_x, drop_y - 9.0), Vector2(drop_x, minf(drop_y + 11.0, focus.y + 34.0)), Color(0.55, 0.89, 1.0, 0.80 * _effect_time), 2.5, true)
            draw_circle(Vector2(drop_x, minf(drop_y + 13.0, focus.y + 35.0)), 2.8, Color(0.70, 0.96, 1.0, 0.92 * _effect_time))
    elif _effect == "minerals":
        var bag_pos: Vector2 = focus + Vector2(_stage.size.x * 0.09, -_stage.size.y * 0.12)
        draw_set_transform(bag_pos, -0.32, Vector2.ONE * clampf(_stage.size.y / 980.0, 0.32, 0.48))
        draw_texture(MINERALS, -MINERALS.get_size() * 0.5)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        for i in range(16):
            var dx: float = sin(float(i) * 1.71) * _stage.size.x * 0.026
            var dy: float = p * 92.0 + fmod(float(i * 17), 40.0)
            var particle := focus + Vector2(dx, -34.0 + dy)
            draw_circle(particle, 3.2, Color(0.83, 0.72, 0.97, 0.92 * _effect_time))
            draw_circle(particle + Vector2(2.0, -2.0), 1.2, Color(0.95, 0.90, 1.0, 0.85 * _effect_time))
    elif _effect == "error":
        draw_arc(focus, _stage.size.y * 0.09, 0, TAU, 48, Color(1.0, 0.22, 0.24, 0.6 * _effect_time), 4.0, true)

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
    var portal: Node = get_node_or_null("/root/PlayTownPortal")
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
    var fallback: String = "res://education/playtown/scenes/screens/game_select_school.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _go_back()
        get_viewport().set_input_as_handled()
