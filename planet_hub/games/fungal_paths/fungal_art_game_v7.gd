extends Control
## FUNGAL_V9_2_WIN_DIALOG: Route points first, then Play; Restart randomizes five entrances/exits.
## Bubble stays still while planning. A premature Play leads to local wandering.
## Original supplied artwork, Bubble, spaceship, existing HUD are preserved.
const BOARD: Script = preload("res://planet_hub/games/fungal_paths/fungal_art_board_v7.gd")
const PLAN: Script = preload("res://planet_hub/games/fungal_paths/fungal_route_plan_v9.gd")
const BUBBLE: PackedScene = preload("res://bubble/scenes/bubble_character.tscn")
const SHIP: Texture2D = preload("res://assets/ships/miko_player_ship.png")
const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const FINISH_SOUND: AudioStream = preload("res://learning/audio/sfx/bonus_wheel_win.mp3")

const WORDS: Dictionary = {
    "ru": {"title":"ГРИБНЫЕ ПУТИ", "sub":"Помоги Бабблу добраться до корабля!", "plan":"Соединяй точки. Затем нажми Play", "run":"Баббл идёт по твоему маршруту", "lost":"Баббл потерялся! Попробуй ещё", "win":"Баббл добрался до корабля!", "play":"▶ Играть", "restart":"↻ Заново", "replay":"↻ Повторить", "exit":"Выйти"},
    "en": {"title":"FUNGAL PATHS", "sub":"Help Bubble reach the ship!", "plan":"Connect the dots, then press Play", "run":"Bubble follows your route", "lost":"Bubble is lost! Try again", "win":"Bubble reached the ship!", "play":"▶ Play", "restart":"↻ Restart", "replay":"↻ Play again", "exit":"Exit"},
    "pt": {"title":"CAMINHOS FÚNGICOS", "sub":"Ajude Bubble a chegar à nave!", "plan":"Ligue os pontos e toque em Play", "run":"Bubble segue sua rota", "lost":"Bubble se perdeu! Tente de novo", "win":"Bubble chegou à nave!", "play":"▶ Jogar", "restart":"↻ Reiniciar", "replay":"↻ Jogar de novo", "exit":"Sair"},
    "es": {"title":"CAMINOS FÚNGICOS", "sub":"¡Ayuda a Bubble a llegar a la nave!", "plan":"Une los puntos y pulsa Jugar", "run":"Bubble sigue tu ruta", "lost":"¡Bubble se perdió! Intenta otra vez", "win":"¡Bubble llegó a la nave!", "play":"▶ Jugar", "restart":"↻ Reiniciar", "replay":"↻ Repetir", "exit":"Salir"},
    "fr": {"title":"CHEMINS FONGIQUES", "sub":"Aide Bubble à rejoindre le vaisseau !", "plan":"Relie les points puis appuie sur Jouer", "run":"Bubble suit ton chemin", "lost":"Bubble est perdu ! Réessaie", "win":"Bubble a rejoint le vaisseau !", "play":"▶ Jouer", "restart":"↻ Recommencer", "replay":"↻ Rejouer", "exit":"Quitter"},
    "de": {"title":"PILZWEGE", "sub":"Hilf Bubble, das Raumschiff zu erreichen!", "plan":"Punkte verbinden, dann Spielen", "run":"Bubble folgt deinem Weg", "lost":"Bubble hat sich verirrt!", "win":"Bubble hat das Raumschiff erreicht!", "play":"▶ Spielen", "restart":"↻ Neustart", "replay":"↻ Nochmal", "exit":"Verlassen"}
}

var _board
var _planner
var _bubble: Node2D
var _ship: TextureRect
var _map_frame: Panel
var _back: Button
var _crystals: Control
var _title_panel: Panel
var _title: Label
var _subtitle: Label
var _status: Label
var _play: Button
var _reset: Button
var _sound: AudioStreamPlayer
var _win_overlay: ColorRect
var _win_panel: Panel
var _win_title: Label
var _win_replay: Button
var _win_exit: Button
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _locale: String = "en"
var _start: String = "A0"
var _goal: String = "E9"
var _route: Array[String] = []
var _correct_route: Array[String] = []
var _playing: bool = false
var _lost: bool = false
var _finished: bool = false
var _current: String = "A0"
var _previous: String = ""
var _target: String = ""
var _movement_path: PackedVector2Array = PackedVector2Array()
var _movement_length: float = 0.0
var _movement_distance: float = 0.0
var _play_index: int = 0
var _lost_center: String = ""
var _lost_visits: Dictionary = {}
var _last_heading: float = 0.0
var _host_back: Control

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_PASS
    _rng.randomize()
    _map_frame = Panel.new()
    _map_frame.name = "FungalCyanMapFrame"
    _map_frame.mouse_filter = Control.MOUSE_FILTER_PASS
    _map_frame.clip_contents = true
    TOOLBAR.apply_title_style(_map_frame)
    add_child(_map_frame)
    _board = BOARD.new() as Control
    _board.name = "FungalArtworkRouteBoard"
    _map_frame.add_child(_board)
    _planner = PLAN.new() as Control
    _planner.name = "RouteDotsPlanner"
    _planner.set("board", _board)
    _planner.connect("next_node_selected", _add_route_node)
    _planner.connect("previous_node_removed", _undo_route_node)
    _map_frame.add_child(_planner)
    _planner.z_index = 12

    _ship = TextureRect.new()
    _ship.name = "GoalShip"
    _ship.texture = SHIP
    _ship.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _ship.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _ship.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_ship)
    _ship.z_index = 13

    _bubble = BUBBLE.instantiate() as Node2D
    _bubble.name = "OriginalAnimatedBubble"
    _bubble.set("external_motion_control", true)
    _bubble.set("auto_return_idle", false)
    _bubble.z_index = 16
    add_child(_bubble)
    var surface: ColorRect = _bubble.get_node_or_null("ActiveVisual/Body/Surface") as ColorRect
    if surface != null and surface.material is ShaderMaterial:
        var instance_material: ShaderMaterial = (surface.material as ShaderMaterial).duplicate(true) as ShaderMaterial
        surface.material = instance_material
        var shader: Shader = instance_material.shader
        var anchor: String = "shell=mix(shell,white,0.20+0.22*diffuse+0.08*color_drift);"
        if shader != null and shader.code.contains(anchor):
            var blue: Shader = Shader.new()
            blue.code = shader.code.replace(anchor, anchor + "\n    shell=mix(shell,vec3(0.045,0.47,1.0),0.79);")
            instance_material.shader = blue

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
    _style_button(_back)
    _back.pressed.connect(_exit_to_cards)
    add_child(_back)
    var glyph: Control = GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _crystals = HUD.new() as Control
    _crystals.name = "NativeCrystalCounter"
    _crystals.size = Vector2(1680.0, 158.0)
    add_child(_crystals)
    var sim: Button = _crystals.get("sim_button") as Button
    var launch: Button = _crystals.get("flight_button") as Button
    if sim != null:
        sim.disabled = true
        sim.hide()
    if launch != null:
        launch.disabled = true
        launch.hide()
    _crystals.set("crystal_count", 0)

    _status = Label.new()
    _status.name = "RouteStatus"
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _status.add_theme_color_override("font_color", Color("#e8ffff"))
    _status.add_theme_color_override("font_shadow_color", Color(0.015, 0.03, 0.12, 0.98))
    _status.add_theme_constant_override("shadow_offset_x", 1)
    _status.add_theme_constant_override("shadow_offset_y", 2)
    _map_frame.add_child(_status)
    _status.z_index = 20
    _play = _make_button("PlayPlannedRoute", _play_route)
    _reset = _make_button("RestartRandomPair", _restart_random_pair)
    for control in [_play, _reset]:
        _map_frame.add_child(control)
        control.z_index = 30
    # Disabled Play remains the normal bright blue; disabled is functional only.
    _play.add_theme_stylebox_override("disabled", KIT.button_style())
    _play.add_theme_color_override("font_disabled_color", Color("#eeffff"))
    _create_victory_dialog()
    _sound = AudioStreamPlayer.new()
    _sound.bus = "SFX"
    add_child(_sound)
    _read_locale()
    _new_pair()
    _find_host_back()
    resized.connect(_layout_game)
    _map_frame.resized.connect(_layout_controls)
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        mobile.connect("language_changed", _on_locale)
    _translate()
    _layout_game()
    call_deferred("_layout_game")

func _create_victory_dialog() -> void:
    # This is an actual modal scene overlay, not a temporary status string.
    # It is clipped by the SAME rounded map frame as the supplied artwork.
    _win_overlay = ColorRect.new()
    _win_overlay.name = "FungalVictoryOverlay"
    _win_overlay.color = Color(0.006, 0.024, 0.085, 0.80)
    _win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _win_overlay.z_index = 70
    _map_frame.add_child(_win_overlay)
    _win_panel = Panel.new()
    _win_panel.name = "FungalVictoryWindow"
    _win_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    TOOLBAR.apply_title_style(_win_panel)
    _win_overlay.add_child(_win_panel)
    _win_title = Label.new()
    _win_title.name = "VictoryMessage"
    _win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _win_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _win_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _win_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _win_title.add_theme_color_override("font_color", Color("#e7fbff"))
    _win_title.add_theme_color_override("font_shadow_color", Color(0.00, 0.11, 0.28, 0.95))
    _win_title.add_theme_constant_override("shadow_offset_y", 2)
    _win_panel.add_child(_win_title)
    _win_replay = _make_button("VictoryPlayAgain", _restart_random_pair)
    _win_exit = _make_button("VictoryExit", _exit_to_cards)
    for button in [_win_replay, _win_exit]:
        _win_panel.add_child(button)
    _win_overlay.hide()

func _layout_victory_dialog() -> void:
    if _win_overlay == null or _map_frame == null:
        return
    var available: Vector2 = _map_frame.size
    _win_overlay.position = Vector2.ZERO
    _win_overlay.size = available
    var width: float = minf(available.x - 24.0, clampf(available.x * 0.76, 265.0, 560.0))
    var height: float = minf(available.y - 20.0, clampf(available.y * 0.62, 164.0, 278.0))
    width = maxf(140.0, width)
    height = maxf(110.0, height)
    _win_panel.position = (available - Vector2(width, height)) * 0.5
    _win_panel.size = Vector2(width, height)
    var inset: float = clampf(width * 0.042, 9.0, 22.0)
    _win_title.position = Vector2(inset, height * 0.105)
    _win_title.size = Vector2(width - inset * 2.0, height * 0.43)
    var title_chars: int = maxi(20, _win_title.text.length())
    var font_size: int = mini(29, maxi(13, roundi(width / float(title_chars) * 2.7)))
    _win_title.add_theme_font_size_override("font_size", font_size)
    var button_h: float = clampf(height * 0.27, 38.0, 63.0)
    var button_gap: float = clampf(width * 0.035, 9.0, 17.0)
    var button_width: float = maxf(62.0, (width - inset * 2.0 - button_gap) * 0.5)
    var buttons_y: float = height - button_h - maxf(13.0, height * 0.115)
    _win_replay.position = Vector2(inset, buttons_y)
    _win_exit.position = Vector2(inset + button_width + button_gap, buttons_y)
    for button in [_win_replay, _win_exit]:
        button.size = Vector2(button_width, button_h)
        var chars: int = maxi(7, button.text.length())
        button.add_theme_font_size_override("font_size", maxi(11, mini(21, roundi(button_width / float(chars) * 1.55))))

func _show_victory_dialog() -> void:
    if _win_overlay != null:
        _win_overlay.show()
        _win_overlay.move_to_front()
        _layout_victory_dialog()

func _style_button(button: Button) -> void:
    button.add_theme_stylebox_override("normal", KIT.button_style())
    button.add_theme_stylebox_override("hover", KIT.button_style(true))
    button.add_theme_stylebox_override("pressed", KIT.button_style(true))
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.add_theme_color_override("font_color", Color("#eeffff"))

func _make_button(identifier: String, action: Callable) -> Button:
    var button: Button = Button.new()
    button.name = identifier
    button.focus_mode = Control.FOCUS_NONE
    _style_button(button)
    button.pressed.connect(action)
    return button

func _read_locale() -> void:
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null:
        _locale = str(mobile.get("language")).to_lower().get_slice("_", 0)
    if not WORDS.has(_locale):
        _locale = "en"

func _on_locale(_lang: String) -> void:
    _read_locale()
    _translate()
    _layout_game()

func _translate() -> void:
    if _title == null:
        return
    var words: Dictionary = WORDS[_locale]
    _title.text = str(words["title"])
    _subtitle.text = str(words["sub"])
    _play.text = str(words["play"])
    _reset.text = str(words["restart"])
    _status.text = "" if _finished else str(words["lost"] if _lost else words["run"] if _playing else words["plan"])
    _status.visible = not _finished
    _play.disabled = _playing or _finished # Visually identical to enabled Play.
    _win_title.text = str(words["win"])
    _win_replay.text = str(words["replay"])
    _win_exit.text = str(words["exit"])
    _planner.set("enabled", not _playing and not _finished)
    if _win_overlay != null:
        _win_overlay.visible = _finished
    _layout_controls()

func _shortest_route(start_id: String, end_id: String) -> Array[String]:
    var queue: Array[String] = [start_id]
    var parent: Dictionary = {}
    parent[start_id] = ""
    while not queue.is_empty():
        var node_id: String = queue.pop_front()
        if node_id == end_id:
            break
        for neighbor in _board.neighbors_for(node_id):
            if not parent.has(neighbor):
                parent[neighbor] = node_id
                queue.append(neighbor)
    var path: Array[String] = []
    if not parent.has(end_id):
        return path
    var cursor: String = end_id
    while cursor != "":
        path.push_front(cursor)
        cursor = str(parent[cursor])
    return path

func _new_pair() -> void:
    var starts: Array = _board.path_data.get("starts", [])
    var goals: Array = _board.path_data.get("exits", [])
    if starts.size() != 5 or goals.size() != 5:
        push_error("FUNGAL_V9: Five entrances and five exits required")
        return
    # Each new round selects independently among the original five left entrances
    # and the five right-hand ship exits; never reverse the sides.
    var earlier_pair: String = _start + ":" + _goal
    var next_pair: String = earlier_pair
    for tries in range(30):
        _start = str(starts[_rng.randi_range(0, starts.size() - 1)])
        _goal = str(goals[_rng.randi_range(0, goals.size() - 1)])
        next_pair = _start + ":" + _goal
        if next_pair != earlier_pair:
            break
    if next_pair == earlier_pair:
        _goal = str(goals[(goals.find(_goal) + 1) % goals.size()])
    _correct_route = _shortest_route(_start, _goal)
    if _correct_route.size() < 2:
        push_error("FUNGAL_V9: Disconnected route graph")
        return
    _reset_route()

func _reset_route() -> void:
    if _sound != null:
        _sound.stop()
    _playing = false
    _lost = false
    _finished = false
    _current = _start
    _previous = ""
    _target = ""
    _movement_path = PackedVector2Array()
    _movement_length = 0.0
    _movement_distance = 0.0
    _play_index = 0
    _lost_center = ""
    _lost_visits.clear()
    # Seed the first point at the FIRST JUNCTION, not in empty space by Bubble.
    # Bubble begins at the outer entrance and reaches the bright first dot via
    # an already visible warm-red initial path. The NEXT dot is a pulsing hint.
    _route = [_start]
    if _correct_route.size() > 1:
        _route.append(_correct_route[1])
    _planner.set("route", _route)
    _planner.set("next_hint", _correct_route[2] if _correct_route.size() > 2 else "")
    _planner.set("_pulse", 0.0)
    _planner.set("failed", false)
    _planner.refresh()
    _bubble.call("set_room_locomotion", "idle", 0.0, 0.0)
    _translate()
    _layout_actors()

func _restart_random_pair() -> void:
    # One button creates a new puzzle. Keep the entrances on the left and ship on the right.
    _new_pair()

func _add_route_node(node_id: String) -> void:
    if _playing or _finished or _route.is_empty():
        return
    var endpoint: String = _route[-1]
    if not _board.neighbors_for(endpoint).has(node_id) or _route.has(node_id):
        return # No skipped turns, crossings, or revisiting earlier nodes.
    if endpoint == _goal:
        return
    _route.append(node_id)
    _planner.set("route", _route)
    _planner.refresh()
    _translate()

func _undo_route_node() -> void:
    if _playing or _finished or _route.size() <= 2:
        return
    _route.pop_back()
    _planner.set("route", _route)
    _planner.refresh()
    _translate()

func _play_route() -> void:
    if _playing or _finished:
        return
    _playing = true
    _lost = false
    _current = _start
    _target = ""
    _play_index = 0
    _last_heading = 0.0
    _translate()
    _layout_actors()

func _begin_edge(to_id: String) -> bool:
    if not _board.neighbors_for(_current).has(to_id):
        return false
    _target = to_id
    _movement_path = _board.edge_points(_current, _target)
    _movement_length = _board.path_length(_movement_path)
    _movement_distance = 0.0
    if _movement_path.size() < 2 or _movement_length <= 0.1:
        _target = ""
        return false
    return true

func _graph_steps(center: String, destination: String, maximum: int) -> bool:
    if center == destination:
        return true
    var visited: Dictionary = {}
    visited[center] = true
    var queue: Array[String] = [center]
    var distances: Dictionary = {}
    distances[center] = 0
    while not queue.is_empty():
        var current_id: String = queue.pop_front()
        var depth: int = int(distances[current_id])
        if depth >= maximum:
            continue
        for candidate in _board.neighbors_for(current_id):
            if candidate == destination:
                return true
            if not visited.has(candidate):
                visited[candidate] = true
                distances[candidate] = depth + 1
                queue.append(candidate)
    return false

func _lost_next() -> String:
    # A wrong/incomplete plan NEVER launches an autonomous search toward the goal.
    # Bubble explores only the small local neighborhood of its wrong turn.
    var options: Array[String] = []
    for candidate in _board.neighbors_for(_current):
        if candidate == _goal:
            continue
        if not _graph_steps(_lost_center, candidate, 3):
            continue
        options.append(candidate)
    if options.is_empty():
        return ""
    var best_id: String = options[0]
    var best_cost: float = INF
    for candidate in options:
        var pair: String = _current + ":" + candidate if _current < candidate else candidate + ":" + _current
        var cost: float = float(_lost_visits.get(pair, 0)) * 2.2 + _rng.randf() * 1.3
        if candidate == _previous and options.size() > 1:
            cost += 1.2
        if cost < best_cost:
            best_cost = cost
            best_id = candidate
    return best_id

func _process(delta: float) -> void:
    if not _playing or _board == null or _bubble == null or _board.map_rect.size.x < 40.0:
        return
    if _target == "":
        if _lost:
            if not _begin_edge(_lost_next()):
                _bubble.call("set_room_locomotion", "idle", 0.0, 0.0)
                return
        elif _play_index < _route.size() - 1:
            if not _begin_edge(_route[_play_index + 1]):
                _enter_lost()
                return
        else:
            if _current == _goal:
                _finished = true
                _playing = false
                _sound.stream = FINISH_SOUND
                _sound.play()
                _bubble.call("set_room_locomotion", "idle", 0.0, 0.0)
                _translate()
                _show_victory_dialog()
            else:
                _enter_lost()
            return
    var speed: float = clampf(_board.map_rect.size.y * 0.30, 72.0, 160.0)
    var advance: float = minf(delta, 0.055) * speed
    _movement_distance = minf(_movement_length, _movement_distance + advance)
    var point: Vector2 = _board.point_at(_movement_path, _movement_distance)
    var heading: float = _board.heading_at(_movement_path, _movement_distance)
    _last_heading = heading
    _place_bubble(point, heading, advance)
    if _movement_distance >= _movement_length - 0.05:
        var origin: String = _current
        _previous = origin
        _current = _target
        _target = ""
        _movement_length = 0.0
        _movement_distance = 0.0
        _movement_path = PackedVector2Array()
        if _lost:
            var key: String = origin + ":" + _current if origin < _current else _current + ":" + origin
            _lost_visits[key] = int(_lost_visits.get(key, 0)) + 1
        else:
            _play_index += 1

func _enter_lost() -> void:
    _lost = true
    _lost_center = _current
    _lost_visits.clear()
    _planner.set("failed", true)
    _planner.refresh()
    _translate()

func _place_bubble(point: Vector2, heading: float, advance: float) -> void:
    _bubble.position = _map_frame.position + _board.position + point
    _bubble.scale = Vector2.ONE * (2.0 * clampf(_board.map_rect.size.y / 850.0 * 0.115, 0.047, 0.14))
    _bubble.call("set_room_heading", heading)
    if _playing:
        _bubble.call("set_room_locomotion", "walk_forward", 0.76, advance)

func _layout_actors() -> void:
    if _board == null or _board.map_rect.size.x < 20.0:
        return
    var side: float = 1.5 * clampf(_board.map_rect.size.y * 0.134, 42.0, 90.0)
    var exit_p: Vector2 = _board.position + _board.point_for(_goal)
    var x: float = exit_p.x + side * 0.77
    var center: Vector2 = Vector2(clampf(x, side * 0.5 + 6.0, maxf(side * 0.5 + 6.0, _map_frame.size.x - side * 0.5 - 6.0)), clampf(exit_p.y, side * 0.5 + 6.0, maxf(side * 0.5 + 6.0, _map_frame.size.y - side * 0.5 - 6.0)))
    _ship.size = Vector2.ONE * side
    _ship.position = _map_frame.position + center - Vector2.ONE * side * 0.5
    if _target != "" and _movement_path.size() >= 2:
        _place_bubble(_board.point_at(_movement_path, _movement_distance), _last_heading, 0.0)
    else:
        _place_bubble(_board.point_for(_current), _last_heading, 0.0)

func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["Android", "iOS"]:
        return Rect2(Vector2.ZERO, view)
    var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if window_size.x <= 50.0 or window_size.y <= 50.0 or safe.size.x <= 50:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(safe.position) * (view / window_size), Vector2(safe.size) * (view / window_size))

func _layout_game() -> void:
    if _board == null or _back == null or size.x < 235.0 or size.y < 180.0:
        return
    var safe: Rect2 = _safe_area(size)
    var header: float = TOOLBAR.relayout(size, safe, _back, _crystals, _title_panel, _title, _subtitle)
    var margin: float = clampf(safe.size.x * 0.012, 6.0, 20.0)
    var top: float = header + clampf(safe.size.y * 0.009, 4.0, 11.0)
    _map_frame.position = Vector2(safe.position.x + margin, top)
    _map_frame.size = Vector2(maxf(175.0, safe.size.x - margin * 2.0), maxf(100.0, safe.end.y - top - margin))
    _board.position = Vector2(3.0, 3.0)
    _board.size = _map_frame.size - Vector2.ONE * 6.0
    _planner.position = _board.position
    _planner.size = _board.size
    _planner.refresh()
    if _target != "" and _movement_length > 0.0:
        var progress: float = _movement_distance / _movement_length
        _movement_path = _board.edge_points(_current, _target)
        _movement_length = _board.path_length(_movement_path)
        _movement_distance = progress * _movement_length
    _layout_controls()
    _layout_actors()

func _layout_controls() -> void:
    if _map_frame == null or _play == null:
        return
    var width: float = _map_frame.size.x
    var height: float = _map_frame.size.y
    if width < 80.0 or height < 80.0:
        return
    var pad: float = clampf(height * 0.025, 8.0, 18.0)
    # Two clear buttons stacked in the upper LEFT corner of the map frame.
    # No third button; all controls stay within the adaptive rounded panel.
    var button_width: float = minf(clampf(width * 0.19, 135.0, 214.0), width - pad * 2.0)
    var button_height: float = minf(clampf(height * 0.145, 44.0, 61.0), (height - pad * 3.0) * 0.5)
    var gap: float = clampf(height * 0.022, 6.0, 11.0)
    _play.position = Vector2(pad, pad)
    _play.size = Vector2(button_width, button_height)
    _reset.position = Vector2(pad, pad + button_height + gap)
    _reset.size = Vector2(button_width, button_height)
    for button in [_play, _reset]:
        var characters: int = maxi(7, button.text.length())
        var font: int = maxi(12, mini(22, roundi(button.size.x / float(characters) * 1.7)))
        button.add_theme_font_size_override("font_size", font)
    # Status is kept away from the action buttons; don't cover top-left roads.
    var status_width: float = maxf(60.0, width - button_width - pad * 4.0)
    _status.position = Vector2(pad * 2.0 + button_width, pad + 5.0)
    _status.size = Vector2(status_width, clampf(height * 0.09, 25.0, 42.0))
    _status.add_theme_font_size_override("font_size", maxi(11, mini(19, roundi(height * 0.049))))
    _layout_victory_dialog()

func _find_host_back() -> void:
    var ancestor: Node = get_parent()
    while ancestor != null:
        for identifier in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var button: Control = ancestor.get_node_or_null(identifier) as Control
            if button != null:
                _host_back = button
                _host_back.hide()
                return
        ancestor = ancestor.get_parent()

func _exit_to_cards() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "res://")
        return
    var tree: SceneTree = get_tree()
    if tree != null:
        tree.change_scene_to_file("res://scenes/main.tscn")

func _exit_tree() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
