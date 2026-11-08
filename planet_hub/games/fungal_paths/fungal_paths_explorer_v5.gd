extends Control
## Fungal Paths: Bubble explores continuously while the child turns five tiles.
## Single readable level first; game logic is independent of future map artwork.
const LEVEL: Script = preload("res://planet_hub/games/fungal_paths/fungal_explorer_data_v5.gd")
const BOARD: Script = preload("res://planet_hub/games/fungal_paths/fungal_explorer_board_v5.gd")
const BUBBLE: PackedScene = preload("res://bubble/scenes/bubble_character.tscn")
const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const SPACE: Script = preload("res://simulator_ui/scripts/real_space_background.gd")
const TURN_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/connect_point.ogg")
const FINISH_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")

const WORDS: Dictionary = {
 "ru":{"title":"ГРИБНЫЕ ПУТИ","sub":"Поверни пять дорожек","hint":"Выбери пятиугольник и поворачивай стрелками. Баббл уже ищет дом!","ready":"Баббл ищет дорогу домой. Соединяй дорожки!","win":"Баббл добрался домой! Нажми ↻ для новой задачи.","left":"Повернуть выбранную дорожку влево","right":"Повернуть выбранную дорожку вправо","shuffle":"Новая задача","selected":"Выбрана дорожка %d из 5"},
 "en":{"title":"FUNGAL PATHS","sub":"Turn five roads","hint":"Select a pentagon, then use the arrows to turn it. Bubble is exploring!","ready":"Bubble keeps looking for home. Connect the roads!","win":"Bubble made it home! Tap ↻ for another puzzle.","left":"Turn selected road left","right":"Turn selected road right","shuffle":"New puzzle","selected":"Road %d of 5 selected"},
 "pt":{"title":"CAMINHOS FÚNGICOS","sub":"Gira cinco caminhos","hint":"Escolhe um pentágono e usa as setas. Bubble já procura o caminho!","ready":"Bubble continua a procurar a casa. Liga os caminhos!","win":"Bubble chegou a casa! Toca ↻ para outro desafio.","left":"Girar à esquerda","right":"Girar à direita","shuffle":"Novo desafio","selected":"Caminho %d de 5 selecionado"},
 "es":{"title":"CAMINOS FÚNGICOS","sub":"Gira cinco caminos","hint":"Elige un pentágono y usa las flechas. ¡Bubble ya está explorando!","ready":"Bubble sigue buscando su casa. ¡Conecta caminos!","win":"¡Bubble llegó a casa! Pulsa ↻ para otro reto.","left":"Girar a la izquierda","right":"Girar a la derecha","shuffle":"Nuevo reto","selected":"Camino %d de 5 seleccionado"},
 "fr":{"title":"CHEMINS FONGIQUES","sub":"Tourne cinq chemins","hint":"Choisis un pentagone et utilise les flèches. Bubble explore déjà !","ready":"Bubble cherche sa maison. Relie les chemins !","win":"Bubble est rentré ! Touche ↻ pour recommencer.","left":"Tourner à gauche","right":"Tourner à droite","shuffle":"Nouveau défi","selected":"Chemin %d sur 5 sélectionné"},
 "de":{"title":"PILZWEGE","sub":"Drehe fünf Wege","hint":"Wähle ein Fünfeck und drehe es mit den Pfeilen. Bubble sucht schon!","ready":"Bubble sucht sein Zuhause. Verbinde die Wege!","win":"Bubble ist zu Hause! Tippe ↻ für eine neue Runde.","left":"Nach links drehen","right":"Nach rechts drehen","shuffle":"Neue Aufgabe","selected":"Weg %d von 5 ausgewählt"}
}

var _background: Control
var _board
var _bubble: Node2D
var _back: Button
var _crystals: Control
var _title_panel: Panel
var _title: Label
var _subtitle: Label
var _turn_left: Button
var _turn_right: Button
var _shuffle: Button
var _help: Label
var _which: Label
var _sound: AudioStreamPlayer
var _outer_back: Control
var _locale: String = "en"
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _seed: int = 0
var _selected: int = 2
var _succeeded: bool = false
var _current: int = 0
var _target: int = -1
var _previous: int = -1
var _travel: float = 0.0
var _probe_clock: float = 0.0
var _escaping: bool = false
var _edge_visits: Dictionary = {}
var _visit_order: Array[int] = []
var _time_at_home: float = 0.0
var _last_heading: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    _background = SPACE.new() as Control
    _background.name = "FungalSpaceBackdrop"
    _background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _background.z_index = -20
    add_child(_background)
    _board = BOARD.new() as Control
    _board.name = "FiveRotatingRoads"
    _board.tile_selected.connect(_on_selected)
    _board.tile_rotated.connect(_on_rotated)
    add_child(_board)

    _bubble = BUBBLE.instantiate() as Node2D
    _bubble.name = "ExistingAnimatedBubble"
    _bubble.set("external_motion_control", true)
    _bubble.set("auto_return_idle", false)
    _bubble.z_index = 15
    add_child(_bubble)

    _title_panel = Panel.new()
    _title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_title_panel)
    add_child(_title_panel)
    _title = Label.new()
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _title.clip_text = true
    _title_panel.add_child(_title)
    _subtitle = Label.new()
    _subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _title_panel.add_child(_subtitle)
    _back = Button.new()
    _back.name = "FungalNativeBack"
    _back.focus_mode = Control.FOCUS_NONE
    _back.add_theme_stylebox_override("normal", KIT.button_style())
    _back.add_theme_stylebox_override("hover", KIT.button_style(true))
    _back.add_theme_stylebox_override("pressed", KIT.button_style(true))
    _back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _back.pressed.connect(_exit_to_cards)
    add_child(_back)
    var glyph: Control = GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _crystals = HUD.new() as Control
    _crystals.name = "NativeCrystalCounter"
    _crystals.size = Vector2(1680, 158)
    add_child(_crystals)
    var state: Node = get_node_or_null("/root/GameState")
    if state != null and state.has_method("get_coin_balance"):
        _crystals.set("crystal_count", int(state.call("get_coin_balance")))
        if state.has_signal("coin_balance_changed"):
            state.connect("coin_balance_changed", _update_coins)

    _turn_left = _make_button("↶", _rotate_left)
    _turn_right = _make_button("↷", _rotate_right)
    _turn_left.z_index = 30
    _turn_right.z_index = 30
    _shuffle = _make_button("↻", _new_challenge)
    _which = Label.new()
    _which.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _which.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _which.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _which.add_theme_color_override("font_color", Color("#ffe79c"))
    add_child(_which)
    _help = Label.new()
    _help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _help.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _help.add_theme_color_override("font_color", Color("#cefbed"))
    _help.add_theme_color_override("font_outline_color", Color("#061627"))
    _help.add_theme_constant_override("outline_size", 2)
    add_child(_help)
    _sound = AudioStreamPlayer.new()
    _sound.bus = "SFX"
    add_child(_sound)

    _read_locale()
    _new_challenge()
    _find_host_back()
    resized.connect(_layout_game)
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        mobile.connect("language_changed", _on_locale)
    _translate()
    _layout_game()
    call_deferred("_layout_game")

func _make_button(symbol: String, cb: Callable) -> Button:
    var b := Button.new()
    b.text = symbol
    b.focus_mode = Control.FOCUS_NONE
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.add_theme_stylebox_override("normal", KIT.button_style())
    b.add_theme_stylebox_override("hover", KIT.button_style(true))
    b.add_theme_stylebox_override("pressed", KIT.button_style(true))
    b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    b.add_theme_color_override("font_color", Color("#f6ffff"))
    b.pressed.connect(cb)
    add_child(b)
    return b

func _update_coins(value: int) -> void:
    if is_instance_valid(_crystals): _crystals.set("crystal_count", value)

func _read_locale() -> void:
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null:
        _locale = str(mobile.get("language")).to_lower().get_slice("_", 0)
    if not WORDS.has(_locale): _locale = "en"

func _on_locale(_new: String) -> void:
    _read_locale()
    _translate()
    _layout_game()

func _translate() -> void:
    if _title == null: return
    var words: Dictionary = WORDS[_locale]
    _title.text = str(words["title"])
    _subtitle.text = str(words["sub"])
    _turn_left.tooltip_text = str(words["left"])
    _turn_right.tooltip_text = str(words["right"])
    _shuffle.tooltip_text = str(words["shuffle"])
    _which.text = str(words["selected"]) % _selected
    _help.text = str(words["win"] if _succeeded else words["ready"])

func _on_selected(tile: int) -> void:
    _selected = tile
    _translate()
    _place_rotation_buttons()

func _rotate_left() -> void:
    _board.rotate_tile(_selected, -1)

func _rotate_right() -> void:
    _board.rotate_tile(_selected, 1)

func _on_rotated(_tile: int) -> void:
    _sound.stream = TURN_SOUND
    _sound.play()
    if _target >= 0 and not _escaping and not _board.is_edge_open(_current, _target):
        # Road was rotated under Bubble; it walks BACK along the same segment.
        var old: int = _current
        _current = _target
        _target = old
        _travel = 1.0 - _travel
        _escaping = true
    _translate()

func _new_challenge() -> void:
    var next_seed: int = _rng.randi_range(1, 2000000000)
    if next_seed == _seed: next_seed += 1
    _seed = next_seed
    _board.configure(LEVEL.make(_seed))
    _selected = 2
    _reset_explorer()
    _translate()

func _reset_explorer() -> void:
    _current = 0
    _target = -1
    _previous = -1
    _travel = 0.0
    _probe_clock = 0.0
    _escaping = false
    _edge_visits.clear()
    _visit_order = [0]
    _succeeded = false
    _time_at_home = 0.0
    _last_heading = 0.0
    _board.set_traveled(_visit_order)
    _place_bubble(_board.point_for(0), 0.0, 0.0)

func _edge_id(a: int, b: int) -> String:
    return "%d:%d" % [mini(a,b),maxi(a,b)]

func _choose_next() -> int:
    var neighbors: Array[int] = _board.active_neighbors(_current)
    if neighbors.is_empty(): return -1
    # Once the child has connected the path, Bubble can find home on its own.
    var home_route: Array[int] = _board.path_from(_current, 6)
    if home_route.size() > 1: return home_route[1]
    var choices: Array[int] = []
    for neighbor in neighbors:
        if neighbor != _previous or neighbors.size() == 1:
            choices.append(neighbor)
    if choices.is_empty(): choices = neighbors
    # Explore the least visited usable branch, then change direction at dead ends.
    var best: int = choices[0]
    var best_count: int = 2147483647
    for candidate in choices:
        var visits: int = int(_edge_visits.get(_edge_id(_current,candidate),0))
        if visits < best_count:
            best_count = visits
            best = candidate
    return best

func _process(delta: float) -> void:
    if _board == null or _bubble == null or _board.size.x < 120.0 or _board.size.y < 70.0:
        return
    var dt: float = minf(delta, 0.07)
    if _succeeded:
        _time_at_home += dt
        _place_bubble(_board.point_for(6), 0.0, 0.0)
        return
    if _target >= 0 and not _escaping and not _board.is_edge_open(_current, _target):
        _on_edge_closed()
    if _target < 0:
        var next: int = _choose_next()
        # Finish the little inward-outward scouting motion without teleporting.
        if next >= 0 and absf(sin(_probe_clock * 2.7)) < 0.10:
            _target = next
            _travel = 0.0
            _probe_clock = 0.0
        else:
            _probe_clock += dt
            var p: Vector2 = _board.internal_probe_point(_current, _probe_clock * 2.7)
            _place_bubble(p, -PI*0.5, dt*35.0)
            return
    # Advance on the physical connection, never outside the road network.
    var a: Vector2 = _board.point_for(_current)
    var b: Vector2 = _board.point_for(_target)
    var length: float = maxf(1.0, a.distance_to(b))
    var speed: float = clampf(_board.size.y * 0.48, 75.0, 225.0)
    var stride: float = dt*speed
    _travel = minf(1.0, _travel+stride/length)
    var position_on_road: Vector2 = a.lerp(b, _travel)
    _place_bubble(position_on_road, (b-a).angle(), stride)
    if _travel >= 0.9999:
        var source: int = _current
        _current = _target
        _target = -1
        _travel = 0.0
        _previous = source
        _escaping = false
        var code: String = _edge_id(source,_current)
        _edge_visits[code] = int(_edge_visits.get(code,0))+1
        _visit_order.append(_current)
        if _visit_order.size() > 20: _visit_order.pop_front()
        _board.set_traveled(_visit_order)
        if _current == 6:
            _succeeded = true
            _bubble.call("set_room_locomotion", "idle", 0.0, 0.0)
            _translate()
            _sound.stream = FINISH_SOUND
            _sound.play()

func _on_edge_closed() -> void:
    if _target < 0: return
    var earlier: int = _current
    _current = _target
    _target = earlier
    _travel = 1.0 - _travel
    _escaping = true

func _place_bubble(point: Vector2, heading: float, traveled_pixels: float) -> void:
    if _bubble == null or _board == null: return
    _bubble.position = _board.position + point
    # The original Bubble body has radius ~200 source units.
    var scale_amount: float = clampf(_board.tile_radius() * 0.42 / 210.0, 0.035, 0.18)
    _bubble.scale = Vector2.ONE * scale_amount
    if not _succeeded:
        _bubble.call("set_room_heading", heading)
        _bubble.call("set_room_locomotion", "walk_forward", 0.76, traveled_pixels, 0.0)
    else:
        _bubble.call("set_room_locomotion", "idle", 0.0, 0.0)

func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS","Android"]: return Rect2(Vector2.ZERO, view)
    var screen: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if screen.x < 50.0 or screen.y < 50.0 or safe.size.x < 50: return Rect2(Vector2.ZERO,view)
    return Rect2(Vector2(safe.position)*(view/screen),Vector2(safe.size)*(view/screen))

func _layout_game() -> void:
    if _board == null or _back == null or size.x < 235.0 or size.y < 190.0: return
    _background.position = Vector2.ZERO
    _background.size = size
    var safe: Rect2 = _safe_area(size)
    var header_end: float = TOOLBAR.relayout(size,safe,_back,_crystals,_title_panel,_title,_subtitle)
    var margin: float = clampf(safe.size.x*0.012,6.0,20.0)
    var gap: float = clampf(safe.size.y*0.010,4.0,11.0)
    var controls_h: float = clampf(safe.size.y*0.075,27.0,53.0)
    var button_w: float = clampf(controls_h*1.54,40.0,86.0)
    var x: float = safe.position.x+margin
    _shuffle.position = Vector2(x,header_end+gap)
    _shuffle.size = Vector2(button_w,controls_h)
    _shuffle.add_theme_font_size_override("font_size",maxi(18,roundi(controls_h*0.58)))
    x += button_w+gap
    _which.position = Vector2(x+gap,header_end+gap)
    _which.size = Vector2(maxf(65.0,safe.size.x*0.21),controls_h)
    _which.add_theme_font_size_override("font_size",maxi(10,roundi(controls_h*0.29)))
    var text_x: float = x+_which.size.x+gap*2.0
    _help.position = Vector2(text_x,header_end+gap)
    _help.size = Vector2(maxf(40.0,safe.end.x-text_x-margin),controls_h)
    _help.add_theme_font_size_override("font_size",maxi(9,roundi(controls_h*0.27)))
    var top: float = header_end+controls_h+gap*2.0
    _board.position = Vector2(safe.position.x+margin,top)
    _board.size = Vector2(maxf(180.0,safe.size.x-2.0*margin),maxf(96.0,safe.end.y-top-margin))
    _place_rotation_buttons()
    if _target < 0: _place_bubble(_board.point_for(_current),0.0,0.0)
    else:
        var a:Vector2=_board.point_for(_current)
        var b:Vector2=_board.point_for(_target)
        _place_bubble(a.lerp(b,_travel), (b-a).angle(),0.0)

func _place_rotation_buttons() -> void:
    if _board == null or _turn_left == null or _turn_right == null or _board.size.x < 120.0: return
    # Direction arrows appear beside the SELECTED road, not in a distant toolbar.
    var center: Vector2 = _board.position + _board.point_for(_selected)
    var radius: float = _board.tile_radius()
    var button_size: float = clampf(radius*0.93,30.0,58.0)
    var gap: float = radius+button_size*0.75
    for data in [[_turn_left,-1.0],[_turn_right,1.0]]:
        var button: Button = data[0] as Button
        var direction: float = float(data[1])
        button.size = Vector2.ONE*button_size
        button.position = center+Vector2(direction*gap,0.0)-button.size*0.5
        button.add_theme_font_size_override("font_size",maxi(18,roundi(button_size*0.59)))

func _find_host_back() -> void:
    var p: Node = get_parent()
    for i in range(16):
        if p == null: break
        for name in ["ReturnToEducationalCards","ReturnToExistingPlanetCards"]:
            var host: Control = p.get_node_or_null(name) as Control
            if host != null:
                _outer_back = host
                _outer_back.hide()
                return
        p = p.get_parent()

func _exit_tree() -> void:
    if is_instance_valid(_outer_back): _outer_back.show()

func _exit_to_cards() -> void:
    var portal: Node = get_node_or_null("/root/PlayTownPortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition","")
        return
    var p: Node = get_parent()
    for i in range(16):
        if p == null: break
        if p.has_method("_v1051_return_to_cards"):
            p.call("_v1051_return_to_cards")
            return
        if p.has_method("_return_to_cards"):
            p.call("_return_to_cards")
            return
        p = p.get_parent()
    var fallback: String = "res://education/playtown/scenes/screens/game_select_school.tscn"
    if ResourceLoader.exists(fallback): get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _exit_to_cards()
        get_viewport().set_input_as_handled()
