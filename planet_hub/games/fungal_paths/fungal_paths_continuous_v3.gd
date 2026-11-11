extends Control
## Fungal Paths v3: continuous navigable mycelium, with a freely roaming probe.
## No dog, Bubble, bridges, holes, block tools, route scoring or endings yet.
## Only the game represented by lmc__fungal_paths is replaced.

const GENERATOR: Script = preload("res://planet_hub/games/fungal_paths/fungal_continuous_generator_v3.gd")
const NETWORK_CANVAS: Script = preload("res://planet_hub/games/fungal_paths/fungal_continuous_canvas_v3.gd")
const DOT_SCRIPT: Script = preload("res://planet_hub/games/fungal_paths/fungal_walker_dot_v3.gd")
const SHARED_TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const NATIVE_HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const BACK_GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const UI_KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const SPACE: Script = preload("res://simulator_ui/scripts/real_space_background.gd")

const WORDS: Dictionary = {
    "ru":{"title":"ГРИБНЫЕ ПУТИ","sub":"Непрерывная сеть · техническая версия","status":"Точка исследует грибницу","pause":"Пауза","new":"Новая сеть"},
    "en":{"title":"FUNGAL PATHS","sub":"Continuous network · technical preview","status":"The dot explores the mycelium","pause":"Paused","new":"New network"},
    "pt":{"title":"CAMINHOS FÚNGICOS","sub":"Rede contínua · versão técnica","status":"O ponto percorre o micélio","pause":"Pausado","new":"Nova rede"},
    "es":{"title":"CAMINOS FÚNGICOS","sub":"Red continua · versión técnica","status":"El punto recorre el micelio","pause":"Pausa","new":"Nueva red"},
    "fr":{"title":"CHEMINS FONGIQUES","sub":"Réseau continu · version technique","status":"Le point parcourt le mycélium","pause":"En pause","new":"Nouveau réseau"},
    "de":{"title":"PILZWEGE","sub":"Durchgehendes Netz · technische Version","status":"Der Punkt erkundet das Myzel","pause":"Pause","new":"Neues Netz"}
}

var _space: Control
var _canvas: Control
var _dot: Node2D
var _title_panel: Panel
var _title: Label
var _subtitle: Label
var _back: Button
var _crystals: Control
var _play: Button
var _pause: Button
var _new: Button
var _hint: Label
var _host_back: Control
var _graph: Dictionary = {}
var _rand := RandomNumberGenerator.new()
var _last_seed: int = 0
var _from_id: int = 0
var _to_id: int = 0
var _previous_id: int = -1
var _segment: float = 0.0
var _running: bool = false
var _paused: bool = false
var _visits: Dictionary = {}
var _locale: String = "en"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_PASS
    _rand.randomize()
    _space = SPACE.new() as Control
    _space.name = "MIKAFlightSpaceBackground"
    _space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _space.z_index = -20
    add_child(_space)
    _canvas = NETWORK_CANVAS.new() as Control
    _canvas.name = "ContinuousMyceliumMap"
    _canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_canvas)
    _dot = Node2D.new()
    _dot.name = "RoamingTestDot"
    _dot.set_script(DOT_SCRIPT)
    _dot.z_index = 20
    add_child(_dot)
    _title_panel = Panel.new()
    SHARED_TOOLBAR.apply_title_style(_title_panel)
    _title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_title_panel)
    _title = Label.new()
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title.clip_text = true
    _title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _title_panel.add_child(_title)
    _subtitle = Label.new()
    _subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _subtitle.clip_text = true
    _subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _title_panel.add_child(_subtitle)
    _back = Button.new()
    _back.name = "FungalPathsNativeBack"
    _back.text = ""
    _back.focus_mode = Control.FOCUS_NONE
    _back.add_theme_stylebox_override("normal", UI_KIT.button_style())
    _back.add_theme_stylebox_override("hover", UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("pressed", UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _back.pressed.connect(_exit_to_cards)
    add_child(_back)
    var arrow: Control = BACK_GLYPH.new() as Control
    arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(arrow)
    arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _crystals = NATIVE_HUD.new() as Control
    _crystals.name = "NativeCrystalCounter"
    _crystals.size = Vector2(1680,158)
    _crystals.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_crystals)
    for name in ["SimulatorButton","LaunchButton"]:
        var element: Control = _crystals.get_node_or_null(str(name)) as Control
        if element != null:
            element.hide()
    var state: Node = get_node_or_null("/root/GameState")
    if state != null and state.has_method("get_coin_balance"):
        _crystals.set("crystal_count", int(state.call("get_coin_balance")))
    _play = _button("▶",_resume)
    _pause = _button("Ⅱ",_hold)
    _new = _button("↻",_new_network)
    _hint = Label.new()
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _hint.add_theme_color_override("font_color",Color("#d6f6eb"))
    _hint.add_theme_color_override("font_outline_color",Color("#061529"))
    _hint.add_theme_constant_override("outline_size",2)
    _hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hint.clip_text = true
    add_child(_hint)
    _read_locale()
    _translate()
    _new_network()
    _find_host_back()
    resized.connect(_layout_game)
    if has_node("/root/MobileLocale"):
        var mobile: Node = get_node("/root/MobileLocale")
        if mobile.has_signal("language_changed"):
            mobile.connect("language_changed", _on_locale)
    _layout_game()
    call_deferred("_layout_game")

func _button(text_value: String, action: Callable) -> Button:
    var b := Button.new()
    b.text = text_value
    b.focus_mode = Control.FOCUS_NONE
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.add_theme_stylebox_override("normal",UI_KIT.button_style())
    b.add_theme_stylebox_override("hover",UI_KIT.button_style(true))
    b.add_theme_stylebox_override("pressed",UI_KIT.button_style(true))
    b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
    b.add_theme_color_override("font_color",Color("#e8faff"))
    b.pressed.connect(action)
    add_child(b)
    return b

func _read_locale() -> void:
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null:
        _locale = str(mobile.get("language")).to_lower().get_slice("_",0)
    if not WORDS.has(_locale):
        _locale = "en"

func _on_locale(_value: String) -> void:
    _read_locale()
    _translate()
    _layout_game()

func _translate() -> void:
    var l: Dictionary = WORDS[_locale]
    _title.text = str(l["title"])
    _subtitle.text = str(l["sub"])
    _new.tooltip_text = str(l["new"])
    _play.tooltip_text = "Play"
    _pause.tooltip_text = str(l["pause"])
    _hint.text = str(l["pause"] if _paused else l["status"])

func _new_network() -> void:
    var seed_value: int = _rand.randi_range(1,2000000000)
    if seed_value == _last_seed:
        seed_value = seed_value+1
    _last_seed = seed_value
    _graph = GENERATOR.make(seed_value)
    _canvas.call("configure",_graph)
    _from_id = int(_graph.get("start",0))
    _to_id = _from_id
    _previous_id = -1
    _segment = 0.0
    _visits.clear()
    _visits[_from_id] = 1
    _running = true
    _paused = false
    _choose_next()
    _position_dot()
    _translate()

func _choose_next() -> void:
    var available: Array[int] = _canvas.call("neighbors",_from_id)
    if available.is_empty():
        _running = false
        return
    if available.size() > 1 and available.has(_previous_id):
        available.erase(_previous_id)
    var best_value: float = INF
    var options: Array[int] = []
    for id in available:
        var seen: float = float(_visits.get(id,0))
        var value: float = seen + _rand.randf_range(0.0,1.15)
        if value < best_value - 0.18:
            options.clear()
            options.append(id)
            best_value = value
        elif value <= best_value + 0.18:
            options.append(id)
    _to_id = options[_rand.randi_range(0,options.size()-1)] if not options.is_empty() else available[0]
    _segment = 0.0

func _process(delta: float) -> void:
    if not _running or _paused or not is_instance_valid(_canvas):
        return
    var remaining: float = minf(delta,0.09)
    var guard: int = 0
    while remaining > 0.00001 and guard < 4:
        guard += 1
        var a: Vector2 = _canvas.call("point_for",_from_id)
        var b: Vector2 = _canvas.call("point_for",_to_id)
        var path_length: float = maxf(4.0,a.distance_to(b))
        var speed: float = clampf(_canvas.size.y*0.33,68.0,225.0)
        var needed: float = (1.0-_segment)*path_length/speed
        if remaining < needed:
            _segment += remaining*speed/path_length
            remaining = 0.0
        else:
            remaining -= needed
            _segment = 1.0
            var reached: int = _to_id
            _previous_id = _from_id
            _from_id = reached
            _visits[_from_id] = int(_visits.get(_from_id,0))+1
            _choose_next()
    _position_dot()

func _position_dot() -> void:
    if not is_instance_valid(_canvas) or not is_instance_valid(_dot):
        return
    var local: Vector2 = _canvas.call("edge_point",_from_id,_to_id,_segment)
    _dot.position = _canvas.position+local
    var scale_factor: float = clampf(_canvas.size.y/570.0,0.44,1.15)
    _dot.scale = Vector2.ONE*scale_factor

func _resume() -> void:
    _running = true
    _paused = false
    _translate()

func _hold() -> void:
    _paused = true
    _translate()

func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS","Android"]:
        return Rect2(Vector2.ZERO,view)
    var window: Vector2 = Vector2(DisplayServer.window_get_size())
    var area: Rect2i = DisplayServer.get_display_safe_area()
    if window.x < 10.0 or window.y < 10.0 or area.size.x < 10 or area.size.y < 10:
        return Rect2(Vector2.ZERO,view)
    return Rect2(Vector2(area.position)*(view/window),Vector2(area.size)*(view/window))

func _layout_game() -> void:
    if _canvas == null or _back == null or size.x < 230 or size.y < 205:
        return
    _space.position = Vector2.ZERO
    _space.size = size
    var safe: Rect2 = _safe_area(size)
    var header_end: float = SHARED_TOOLBAR.relayout(size,safe,_back,_crystals,_title_panel,_title,_subtitle)
    var margin: float = clampf(safe.size.x*0.012,5.0,20.0)
    var gap: float = clampf(safe.size.y*0.011,4.0,12.0)
    var control_h: float = clampf(safe.size.y*0.085,31.0,62.0)
    var button_w: float = clampf(control_h*1.55,40.0,105.0)
    var x: float = safe.position.x+margin
    for button in [_play,_pause,_new]:
        button.position = Vector2(x,header_end+gap)
        button.size = Vector2(button_w,control_h)
        button.add_theme_font_size_override("font_size",maxi(15,roundi(control_h*0.50)))
        x += button_w+gap
    _hint.position = Vector2(x+gap,header_end+gap)
    _hint.size = Vector2(maxf(30.0,safe.end.x-margin-x-gap),control_h)
    _hint.add_theme_font_size_override("font_size",maxi(9,roundi(control_h*0.30)))
    var map_y: float = header_end+gap*2.0+control_h
    var map_bottom: float = safe.end.y-margin
    _canvas.position = Vector2(safe.position.x+margin,map_y)
    _canvas.size = Vector2(maxf(150.0,safe.size.x-margin*2.0),maxf(90.0,map_bottom-map_y))
    _position_dot()

func _find_host_back() -> void:
    var p: Node = get_parent()
    for i in range(16):
        if p == null:
            break
        for key in ["ReturnToEducationalCards","ReturnToExistingPlanetCards"]:
            var b: Control = p.get_node_or_null(key) as Control
            if b != null:
                _host_back = b
                _host_back.hide()
                return
        p = p.get_parent()

func _exit_tree() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()

func _exit_to_cards() -> void:
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition","")
        return
    var p: Node = get_parent()
    for i in range(16):
        if p == null:
            break
        if p.has_method("_v1051_return_to_cards"):
            p.call("_v1051_return_to_cards")
            return
        if p.has_method("_return_to_cards"):
            p.call("_return_to_cards")
            return
        p = p.get_parent()
    var fallback: String = "res://scenes/main.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _exit_to_cards()
        get_viewport().set_input_as_handled()
