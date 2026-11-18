extends Control
## Fungal Paths v6: 10 authored route layouts, four random rotors, and Bubble walking exactly on drawn tunnels.
## All motion samples the same Bezier tunnel geometry as the renderer.
const LEVEL: Script = preload("res://planet_hub/games/fungal_paths/fungal_routes_data_v6.gd")
const BOARD: Script = preload("res://planet_hub/games/fungal_paths/fungal_routes_board_v6.gd")
const BUBBLE: PackedScene = preload("res://bubble/scenes/bubble_character.tscn")
const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const SPACE: Script = preload("res://simulator_ui/scripts/real_space_background.gd")
const TURN_SOUND: AudioStream = preload("res://learning/audio/sfx/connect_point.ogg")
const FINISH_SOUND: AudioStream = preload("res://learning/audio/sfx/correct.ogg")

const WORDS: Dictionary = {
 "ru":{"title":"ГРИБНЫЕ ПУТИ","sub":"Помоги Бабблу найти дом","ready":"Выбери одну из 4 развилок и поверни дорожку — Баббл исследует тоннели!","win":"Баббл дома! Нажми ↻ для новой карты.","left":"Повернуть дорожку влево","right":"Повернуть дорожку вправо","shuffle":"Новый маршрут","selected":"Развилка %d из 4 · карта %d из 10"},
 "en":{"title":"FUNGAL PATHS","sub":"Help Bubble find home","ready":"Choose one of 4 junctions and rotate its road. Bubble keeps exploring!","win":"Bubble is home! Tap ↻ for another map.","left":"Rotate road left","right":"Rotate road right","shuffle":"New route","selected":"Junction %d of 4 · map %d of 10"},
 "pt":{"title":"CAMINHOS FÚNGICOS","sub":"Ajude Bubble a voltar para casa","ready":"Escolha uma das 4 junções e gire o caminho. Bubble continua explorando!","win":"Bubble chegou em casa! Toque ↻ para outro mapa.","left":"Girar à esquerda","right":"Girar à direita","shuffle":"Novo caminho","selected":"Junção %d de 4 · mapa %d de 10"},
 "es":{"title":"CAMINOS FÚNGICOS","sub":"Ayuda a Bubble a volver a casa","ready":"Elige una de las 4 uniones y gira el camino. ¡Bubble sigue explorando!","win":"¡Bubble llegó a casa! Pulsa ↻ para otro mapa.","left":"Girar a la izquierda","right":"Girar a la derecha","shuffle":"Nueva ruta","selected":"Unión %d de 4 · mapa %d de 10"},
 "fr":{"title":"CHEMINS FONGIQUES","sub":"Aide Bubble à rentrer","ready":"Choisis l'un des 4 embranchements et tourne le chemin. Bubble explore !","win":"Bubble est rentré ! Appuie sur ↻ pour une nouvelle carte.","left":"Tourner à gauche","right":"Tourner à droite","shuffle":"Nouveau parcours","selected":"Jonction %d sur 4 · carte %d sur 10"},
 "de":{"title":"PILZWEGE","sub":"Hilf Bubble nach Hause","ready":"Wähle eine von 4 Kreuzungen und drehe den Weg. Bubble erkundet weiter!","win":"Bubble ist zu Hause! Tippe ↻ für eine neue Karte.","left":"Links drehen","right":"Rechts drehen","shuffle":"Neue Strecke","selected":"Knoten %d von 4 · Karte %d von 10"}
}

var _background: Control
var _board
var _bubble: Node2D
var _back: Button
var _crystals: Control
var _map_frame: Panel
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
var _selected: int = -1
var _route_id: int = -1
var _start_id: int = 15
var _home_id: int = 4
var _succeeded: bool = false
var _session_score: int = 0
var _current: int = 15
var _target: int = -1
var _previous: int = -1
var _distance: float = 0.0
var _motion_length: float = 0.0
var _motion_path: PackedVector2Array = PackedVector2Array()
var _retreating: bool = false
var _probe_clock: float = 0.0

var _edge_visits: Dictionary = {}

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
    # The same shared cyan/blue outline used by the Simulator's title panel.
    # Frame and board stay siblings: Bubble position and input coordinates remain unchanged.
    _map_frame = Panel.new()
    _map_frame.name = "FungalCyanMapFrame"
    _map_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _map_frame.z_index = -2
    TOOLBAR.apply_title_style(_map_frame)
    add_child(_map_frame)
    _board = BOARD.new() as Control
    _board.name = "FungalLivingRoads"
    _board.junction_selected.connect(_on_selected)
    _board.junction_rotated.connect(_on_rotated)
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
    # BottomHUD is shared, but this game uses ONLY its native center counter.
    # Hide the simulator/launch wings rather than replacing the approved artwork.
    var sim_button: Button = _crystals.get("sim_button") as Button
    var launch_button: Button = _crystals.get("flight_button") as Button
    if sim_button != null:
        sim_button.disabled = true
        sim_button.hide()
    if launch_button != null:
        launch_button.disabled = true
        launch_button.hide()
    # Show crystals collected DURING THIS GAME SESSION, not the global balance.
    # GameState remains the destination for earned crystals, but never overwrites this display.
    _session_score = 0
    _crystals.set("crystal_count", _session_score)

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

func _award_home() -> void:
    # Called exactly once per completed route; _succeeded blocks duplicate rewards.
    _session_score += 1
    if is_instance_valid(_crystals):
        _crystals.set("crystal_count", _session_score)
    var state: Node = get_node_or_null("/root/GameState")
    if state != null and state.has_method("add_coins"):
        state.call("add_coins", 1)

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
    var ordinal: int = _board.editable.find(_selected)+1 if _board != null else 1
    _which.text = str(words["selected"]) % [maxi(1,ordinal),maxi(1,_route_id+1)]
    _help.text = str(words["win"] if _succeeded else words["ready"])

func _on_selected(tile: int) -> void:
    _selected = tile
    _translate()
    _place_rotation_buttons()

func _rotate_left() -> void:
    _board.rotate_selected(-1)

func _rotate_right() -> void:
    _board.rotate_selected(1)

func _on_rotated(_id: int) -> void:
    _sound.stream = TURN_SOUND
    _sound.play()
    if _target >= 0 and not _retreating and not _board.is_edge_open(_current,_target):
        _reverse_on_visible_road()
    _translate()

func _new_challenge() -> void:
    var level: Dictionary={}
    for i in range(12):
        var candidate_seed: int=_rng.randi_range(1,2000000000)
        if candidate_seed==_seed:candidate_seed+=1
        var candidate: Dictionary=LEVEL.make(candidate_seed)
        if candidate.is_empty():continue
        if int(candidate.get("route_id",-1))==_route_id and i<10:continue
        level=candidate
        _seed=candidate_seed
        break
    if level.is_empty():
        push_error("FUNGAL_V6: Could not generate connected playable routes")
        return
    _board.configure(level)
    _route_id=int(level["route_id"])
    _start_id=int(level["start"])
    _home_id=int(level["goal"])
    _selected=_board.selected
    _reset_explorer()
    _translate()
    _place_rotation_buttons()

func _reset_explorer() -> void:
    _current=_start_id
    _target=-1
    _previous=-1
    _distance=0.0
    _motion_length=0.0
    _motion_path=PackedVector2Array()
    _probe_clock=0.0
    _retreating=false
    _edge_visits.clear()
    _succeeded=false
    _time_at_home=0.0
    _last_heading=0.0
    _board.clear_ghost()
    _place_bubble(_board.point_for(_current),0.0,0.0)

func _edge_id(a:int,b:int) -> String:
    return "%d:%d" % [mini(a,b),maxi(a,b)]

func _choose_next() -> int:
    var neighbors:Array[int]=_board.active_neighbors(_current)
    if neighbors.is_empty():return -1
    # Home becomes reachable only after the child's four corrections.
    var home_route:Array[int]=_board.path_to(_current,_home_id)
    if home_route.size()>1:return home_route[1]
    var choices:Array[int]=[]
    for next_id in neighbors:
        if next_id!=_previous or neighbors.size()==1:choices.append(next_id)
    if choices.is_empty():choices=neighbors
    var minimum:int=2147483647
    var preferred:int=choices[0]
    for next_id in choices:
        var count:int=int(_edge_visits.get(_edge_id(_current,next_id),0))
        if count<minimum:
            minimum=count
            preferred=next_id
    return preferred

func _reverse_on_visible_road() -> void:
    if _target<0 or _motion_path.size()<2:return
    var reversed:PackedVector2Array=PackedVector2Array()
    for i in range(_motion_path.size()-1,-1,-1):reversed.append(_motion_path[i])
    var from_id:int=_current
    _current=_target
    _target=from_id
    _motion_path=reversed
    _distance=maxf(0.0,_motion_length-_distance)
    _retreating=true
    _board.set_ghost(_motion_path)

func _process(delta:float) -> void:
    if _board==null or _bubble==null or _board.size.x<120 or _board.size.y<90:
        return
    var dt:float=minf(delta,0.05)
    if _succeeded:
        _time_at_home+=dt
        _place_bubble(_board.point_for(_home_id),_last_heading,0.0)
        return
    if _target>=0 and not _retreating and not _board.is_edge_open(_current,_target):
        _reverse_on_visible_road()
    if _target<0:
        var next_id:int=_choose_next()
        if next_id>=0:
            _target=next_id
            _motion_path=_board.edge_points(_current,_target)
            _motion_length=_board.polyline_length(_motion_path)
            _distance=0.0
            _probe_clock=0.0
        else:
            # When trapped, Bubble walks back and forth INSIDE its cell's
            # illuminated stub, so it never freezes or crosses empty space.
            _probe_clock+=dt
            var probe:PackedVector2Array=_board.probe_path(_current)
            var travel_fraction:float=absf(sin(_probe_clock*1.30))
            var dist:float=_board.polyline_length(probe)*travel_fraction
            var pos:Vector2=_board.point_on_polyline(probe,dist)
            var heading:float=_board.heading_on_polyline(probe,dist)
            if cos(_probe_clock*1.30)<0:heading+=PI
            _place_bubble(pos,heading,dt*20.0)
            return
    if _motion_path.size()<2 or _motion_length<=0.001:
        _target=-1
        return
    var speed:float=clampf(_board.size.y*0.25,44.0,145.0)
    var moved:float=dt*speed
    _distance=minf(_motion_length,_distance+moved)
    var place:Vector2=_board.point_on_polyline(_motion_path,_distance)
    var heading:float=_board.heading_on_polyline(_motion_path,_distance)
    _last_heading=heading
    _place_bubble(place,heading,moved)
    if _distance>=_motion_length-0.05:
        var earlier:int=_current
        _current=_target
        _target=-1
        _distance=0.0
        _motion_length=0.0
        _motion_path=PackedVector2Array()
        _previous=earlier
        _retreating=false
        _board.clear_ghost()
        var code:String=_edge_id(earlier,_current)
        _edge_visits[code]=int(_edge_visits.get(code,0))+1
        _board.record_edge(earlier,_current)
        if _current==_home_id:
            _succeeded=true
            _award_home()
            _bubble.call("set_room_locomotion","idle",0.0,0.0)
            _translate()
            _sound.stream=FINISH_SOUND
            _sound.play()

func _place_bubble(point:Vector2,heading:float,traveled_pixels:float) -> void:
    if _bubble==null or _board==null:return
    _bubble.position=_board.position+point
    var scale_amount:float=clampf(_board.tile_radius()*0.62/210.0,0.038,0.13)
    _bubble.scale=Vector2.ONE*scale_amount
    _bubble.call("set_room_heading",heading)
    if _succeeded:
        _bubble.call("set_room_locomotion","idle",0.0,0.0)
    else:
        _bubble.call("set_room_locomotion","walk_forward",0.76,traveled_pixels,0.0)

func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS","Android"]: return Rect2(Vector2.ZERO, view)
    var screen: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if screen.x < 50.0 or screen.y < 50.0 or safe.size.x < 50: return Rect2(Vector2.ZERO,view)
    return Rect2(Vector2(safe.position)*(view/screen),Vector2(safe.size)*(view/screen))

func _layout_game() -> void:
    if _board == null or _back == null or size.x < 235.0 or size.y < 190.0:return
    _background.position=Vector2.ZERO
    _background.size=size
    var safe:Rect2=_safe_area(size)
    var header_end:float=TOOLBAR.relayout(size,safe,_back,_crystals,_title_panel,_title,_subtitle)
    var margin:float=clampf(safe.size.x*0.009,5.0,17.0)
    var gap:float=clampf(safe.size.y*0.007,3.0,9.0)
    var controls_h:float=clampf(safe.size.y*0.075,29.0,52.0)
    var button_w:float=clampf(controls_h*1.48,43.0,79.0)
    var x:float=safe.position.x+margin
    _shuffle.position=Vector2(x,header_end+gap)
    _shuffle.size=Vector2(button_w,controls_h)
    _shuffle.add_theme_font_size_override("font_size",maxi(18,roundi(controls_h*0.58)))
    x+=button_w+gap
    _which.position=Vector2(x,header_end+gap)
    _which.size=Vector2(maxf(105.0,safe.size.x*0.25),controls_h)
    _which.add_theme_font_size_override("font_size",maxi(9,roundi(controls_h*0.25)))
    var text_x:float=x+_which.size.x+gap
    _help.position=Vector2(text_x,header_end+gap)
    _help.size=Vector2(maxf(30.0,safe.end.x-text_x-margin),controls_h)
    _help.add_theme_font_size_override("font_size",maxi(9,roundi(controls_h*0.25)))
    var top:float=header_end+controls_h+gap*2.0
    var fraction:float=_distance/maxf(_motion_length,0.001)
    # Add a visible cyan border without altering the board's road geometry.
    _map_frame.position=Vector2(safe.position.x+margin,top)
    _map_frame.size=Vector2(maxf(170.0,safe.size.x-2.0*margin),maxf(112.0,safe.end.y-top-margin))
    var inset:float=clampf(minf(_map_frame.size.x,_map_frame.size.y)*0.025,7.0,15.0)
    _board.position=_map_frame.position+Vector2.ONE*inset
    _board.size=_map_frame.size-Vector2.ONE*(inset*2.0)
    if _target>=0:
        _motion_path=_board.edge_points(_current,_target)
        _motion_length=_board.polyline_length(_motion_path)
        _distance=fraction*_motion_length
    _place_rotation_buttons()
    if _target<0:
        _place_bubble(_board.point_for(_current),0.0,0.0)
    else:
        var point:Vector2=_board.point_on_polyline(_motion_path,_distance)
        var heading:float=_board.heading_on_polyline(_motion_path,_distance)
        _place_bubble(point,heading,0.0)

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
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
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
    var fallback: String = "res://scenes/main.tscn"
    if ResourceLoader.exists(fallback): get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _exit_to_cards()
        get_viewport().set_input_as_handled()
