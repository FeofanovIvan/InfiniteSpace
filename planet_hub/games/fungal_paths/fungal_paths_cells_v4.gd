extends Control
## Fungal Paths v4: child-readable pentagon cells, tap-to-build route, test with a dot.
## No finished artwork, automatic solution, bridge tools, score rewards or game-over.
const GENERATOR: Script = preload("res://planet_hub/games/fungal_paths/fungal_cell_generator_v4.gd")
const CANVAS: Script = preload("res://planet_hub/games/fungal_paths/fungal_cell_canvas_v4.gd")
const DOT: Script = preload("res://planet_hub/games/fungal_paths/fungal_walker_dot_v4.gd")
const SHARED_TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const NATIVE_HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const BACK_GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const UI_KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const SPACE: Script = preload("res://simulator_ui/scripts/real_space_background.gd")

const WORDS: Dictionary = {
    "ru":{"title":"ГРИБНЫЕ ПУТИ","sub":"Соедини клетки · найди выход","build":"Нажимай на зелёные точки. Веди путь к золотому выходу.","ready":"Маршрут готов! Нажми ▶, чтобы проверить.","running":"Точка движется по твоему маршруту...","success":"Получилось! Можно придумать другой путь или новую карту.","partial":"Точка остановилась. Продолжи маршрут до выхода.","pause":"Пауза","undo":"На шаг назад","new":"Новая карта","play":"Проверить маршрут"},
    "en":{"title":"FUNGAL PATHS","sub":"Connect cells · find the exit","build":"Tap the green dots. Reach the golden exit.","ready":"Route ready! Press ▶ to test it.","running":"The dot is following your route...","success":"Great! Try another route or a new map.","partial":"The dot stopped. Continue to the exit.","pause":"Paused","undo":"Undo one step","new":"New map","play":"Test route"},
    "pt":{"title":"CAMINHOS FÚNGICOS","sub":"Liga as células · encontra a saída","build":"Toca nos pontos verdes até à saída dourada.","ready":"Caminho pronto! Toca em ▶ para testar.","running":"O ponto segue o teu caminho...","success":"Conseguiste! Experimenta outro caminho ou mapa.","partial":"O ponto parou. Continua até à saída.","pause":"Pausa","undo":"Voltar um passo","new":"Novo mapa","play":"Testar caminho"},
    "es":{"title":"CAMINOS FÚNGICOS","sub":"Une las celdas · encuentra la salida","build":"Toca los puntos verdes hasta la salida dorada.","ready":"¡Ruta lista! Pulsa ▶ para probarla.","running":"El punto sigue tu ruta...","success":"¡Muy bien! Prueba otra ruta u otro mapa.","partial":"El punto se detuvo. Sigue hasta la salida.","pause":"Pausa","undo":"Deshacer un paso","new":"Nuevo mapa","play":"Probar ruta"},
    "fr":{"title":"CHEMINS FONGIQUES","sub":"Relie les cellules · trouve la sortie","build":"Touche les points verts pour atteindre la sortie dorée.","ready":"Chemin prêt ! Appuie sur ▶ pour tester.","running":"Le point suit ton chemin...","success":"Bravo ! Essaie un autre chemin ou une autre carte.","partial":"Le point s'arrête. Continue jusqu'à la sortie.","pause":"Pause","undo":"Annuler un pas","new":"Nouvelle carte","play":"Tester le chemin"},
    "de":{"title":"PILZWEGE","sub":"Verbinde Zellen · finde den Ausgang","build":"Tippe die grünen Punkte bis zum goldenen Ausgang an.","ready":"Weg fertig! Drücke ▶ zum Testen.","running":"Der Punkt folgt deinem Weg...","success":"Super! Probiere einen anderen Weg oder eine neue Karte.","partial":"Der Punkt hält an. Baue weiter bis zum Ausgang.","pause":"Pause","undo":"Schritt zurück","new":"Neue Karte","play":"Weg testen"}
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
var _undo: Button
var _new: Button
var _hint: Label
var _host_back: Control
var _graph: Dictionary = {}
var _route: Array[int] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _last_seed: int = 0
var _is_playing: bool = false
var _paused: bool = false
var _route_segment: int = 0
var _progress: float = 0.0
var _locale: String = "en"
var _status_key: String = "build"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_PASS
    _rng.randomize()
    _space = SPACE.new() as Control
    _space.name = "MIKAFlightSpaceBackground"
    _space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _space.z_index = -20
    add_child(_space)
    _canvas = CANVAS.new() as Control
    _canvas.name = "PentagonalCellMap"
    _canvas.connect("node_selected",Callable(self,"_on_node_tapped"))
    add_child(_canvas)
    _dot = Node2D.new()
    _dot.name = "RouteTestDot"
    _dot.set_script(DOT)
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
    _back.focus_mode = Control.FOCUS_NONE
    _back.add_theme_stylebox_override("normal",UI_KIT.button_style())
    _back.add_theme_stylebox_override("hover",UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("pressed",UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
    _back.pressed.connect(_exit_to_cards)
    add_child(_back)
    var glyph: Control = BACK_GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _crystals = NATIVE_HUD.new() as Control
    _crystals.name = "NativeCrystalCounter"
    _crystals.size = Vector2(1680,158)
    add_child(_crystals)
    for name in ["SimulatorButton","LaunchButton"]:
        var element: Control = _crystals.get_node_or_null(str(name)) as Control
        if element != null:element.hide()
    var state: Node = get_node_or_null("/root/GameState")
    if state != null and state.has_method("get_coin_balance"):
        _crystals.set("crystal_count",int(state.call("get_coin_balance")))
    _play = _button("▶",_begin_play)
    _pause = _button("Ⅱ",_toggle_pause)
    _undo = _button("↶",_undo_step)
    _new = _button("↻",_new_network)
    _hint = Label.new()
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _hint.add_theme_color_override("font_color",Color("#d6f6eb"))
    _hint.add_theme_color_override("font_outline_color",Color("#061529"))
    _hint.add_theme_constant_override("outline_size",2)
    _hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_hint)
    _read_locale()
    _new_network()
    _find_host_back()
    resized.connect(_layout_game)
    if has_node("/root/MobileLocale"):
        var mobile: Node = get_node("/root/MobileLocale")
        if mobile.has_signal("language_changed"):
            mobile.connect("language_changed",_on_locale)
    _translate()
    _layout_game()
    call_deferred("_layout_game")

func _button(label_text: String,action: Callable) -> Button:
    var b: Button = Button.new()
    b.text = label_text
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
    if not WORDS.has(_locale):_locale = "en"

func _on_locale(_value: String) -> void:
    _read_locale()
    _translate()
    _layout_game()

func _translate() -> void:
    if _title == null:return
    var loc: Dictionary = WORDS[_locale]
    _title.text = str(loc["title"])
    _subtitle.text = str(loc["sub"])
    _play.tooltip_text = str(loc["play"])
    _pause.tooltip_text = str(loc["pause"])
    _undo.tooltip_text = str(loc["undo"])
    _new.tooltip_text = str(loc["new"])
    _hint.text = str(loc.get(_status_key,loc["build"]))

func _set_status(key: String) -> void:
    _status_key = key
    _translate()

func _new_network() -> void:
    var new_seed: int = _rng.randi_range(1,2000000000)
    if new_seed == _last_seed:new_seed += 1
    _last_seed = new_seed
    _graph = GENERATOR.make(new_seed)
    _canvas.call("configure",_graph)
    _route = [int(_graph["start"])]
    _is_playing = false
    _paused = false
    _route_segment = 0
    _progress = 0.0
    _set_status("build")
    _place_dot_at_start()

func _on_node_tapped(id: int) -> void:
    if _is_playing:return
    var tail: int = _route[-1]
    if id == tail:return
    if _route.has(id):
        var index: int = _route.find(id)
        _route.resize(index+1)
    else:
        var choices: Array[int] = _canvas.call("neighbors",tail)
        if not choices.has(id):return
        _route.append(id)
    _canvas.call("set_route",_route)
    _place_dot_at_start()
    _set_status("ready" if _route[-1] == int(_graph["goal"]) else "build")

func _undo_step() -> void:
    if _is_playing:
        _is_playing = false
        _paused = false
    if _route.size()>1:
        _route.pop_back()
        _canvas.call("set_route",_route)
    _place_dot_at_start()
    _set_status("build")

func _begin_play() -> void:
    if _is_playing:
        _paused = false
        _set_status("running")
        return
    if _route.size()<=1:
        _set_status("build")
        return
    _is_playing = true
    _paused = false
    _route_segment = 0
    _progress = 0.0
    _place_dot_at_start()
    _set_status("running")

func _toggle_pause() -> void:
    if not _is_playing:return
    _paused = not _paused
    _set_status("pause" if _paused else "running")

func _process(delta: float) -> void:
    if not _is_playing or _paused or _canvas == null:return
    var remaining: float = minf(delta,0.08)
    var guard: int = 0
    while remaining > 0.0 and _is_playing and guard < 6:
        guard += 1
        var from_id: int = _route[_route_segment]
        var to_id: int = _route[_route_segment+1]
        var a: Vector2 = _canvas.call("point_for",from_id)
        var b: Vector2 = _canvas.call("point_for",to_id)
        var length: float = maxf(a.distance_to(b),1.0)
        var speed: float = clampf(_canvas.size.y*0.44,100.0,280.0)
        var needed: float = (1.0-_progress)*length/speed
        if remaining < needed:
            _progress += remaining*speed/length
            remaining = 0.0
        else:
            remaining -= needed
            _progress = 0.0
            _route_segment += 1
            if _route_segment >= _route.size()-1:
                _is_playing = false
                _set_status("success" if _route[-1] == int(_graph["goal"]) else "partial")
                break
    _place_dot_on_route()

func _place_dot_at_start() -> void:
    if _canvas == null or _dot == null or _route.is_empty():return
    _dot.position = _canvas.position + _canvas.call("point_for",_route[0])
    _dot.scale = Vector2.ONE*clampf(_canvas.size.y/530.0,0.45,1.10)

func _place_dot_on_route() -> void:
    if _canvas == null or _dot == null or _route.is_empty():return
    var pos: Vector2 = _canvas.call("point_for",_route[-1])
    if _route_segment < _route.size()-1:
        var from_p: Vector2 = _canvas.call("point_for",_route[_route_segment])
        var to_p: Vector2 = _canvas.call("point_for",_route[_route_segment+1])
        pos = from_p.lerp(to_p,clampf(_progress,0.0,1.0))
    _dot.position = _canvas.position+pos

func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS","Android"]:return Rect2(Vector2.ZERO,view)
    var window: Vector2 = Vector2(DisplayServer.window_get_size())
    var area: Rect2i = DisplayServer.get_display_safe_area()
    if window.x < 10.0 or window.y < 10.0 or area.size.x < 10 or area.size.y < 10:
        return Rect2(Vector2.ZERO,view)
    return Rect2(Vector2(area.position)*(view/window),Vector2(area.size)*(view/window))

func _layout_game() -> void:
    if _canvas == null or _back == null or size.x < 230.0 or size.y < 205.0:return
    _space.position = Vector2.ZERO
    _space.size = size
    var safe: Rect2 = _safe_area(size)
    var header_end: float = SHARED_TOOLBAR.relayout(size,safe,_back,_crystals,_title_panel,_title,_subtitle)
    var margin: float = clampf(safe.size.x*0.012,5.0,20.0)
    var gap: float = clampf(safe.size.y*0.011,4.0,12.0)
    var control_h: float = clampf(safe.size.y*0.082,30.0,59.0)
    var button_w: float = clampf(control_h*1.45,40.0,90.0)
    var buttons_width: float = (button_w+gap)*4.0
    var control_y: float = header_end+gap
    var x: float = safe.position.x+margin
    for button in [_play,_pause,_undo,_new]:
        button.position = Vector2(x,control_y)
        button.size = Vector2(button_w,control_h)
        button.add_theme_font_size_override("font_size",maxi(16,roundi(control_h*0.48)))
        x += button_w+gap
    _hint.position = Vector2(x+gap,control_y)
    _hint.size = Vector2(maxf(35.0,safe.end.x-x-margin-gap),control_h)
    _hint.add_theme_font_size_override("font_size",maxi(9,roundi(control_h*0.24)))
    var map_y: float = control_y+control_h+gap
    var map_h: float = maxf(100.0,safe.end.y-map_y-margin)
    _canvas.position = Vector2(safe.position.x+margin,map_y)
    _canvas.size = Vector2(maxf(160.0,safe.size.x-margin*2.0),map_h)
    if not _is_playing:
        _place_dot_at_start()
    else:
        _place_dot_on_route()

func _find_host_back() -> void:
    var p: Node = get_parent()
    for i in range(16):
        if p == null:break
        for key in ["ReturnToEducationalCards","ReturnToExistingPlanetCards"]:
            var host: Control = p.get_node_or_null(key) as Control
            if host != null:
                _host_back = host
                host.hide()
                return
        p = p.get_parent()

func _exit_tree() -> void:
    if is_instance_valid(_host_back):_host_back.show()

func _exit_to_cards() -> void:
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition","")
        return
    var p: Node = get_parent()
    for i in range(16):
        if p == null:break
        if p.has_method("_v1051_return_to_cards"):
            p.call("_v1051_return_to_cards")
            return
        if p.has_method("_return_to_cards"):
            p.call("_return_to_cards")
            return
        p = p.get_parent()
    var fallback: String = "res://scenes/main.tscn"
    if ResourceLoader.exists(fallback):get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _exit_to_cards()
        get_viewport().set_input_as_handled()
