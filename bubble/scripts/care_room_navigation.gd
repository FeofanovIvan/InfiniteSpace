extends Node2D
## Bubble room navigation prototype. DO NOT update Godot automatically.
## Left action + right joystick, using Infinity Space's flight control scheme.
## Coordinates match original room PNG (1672 x 941) / ShowerFX v4 precisely.

const ART_SIZE := Vector2(1672.0, 941.0)
const JOYSTICK_SCENE := preload("res://bubble/scripts/room_joystick.gd")
const WALK_SPEED: float = 255.0
const ACCELERATION: float = 850.0
const BRAKE_ACCELERATION: float = 1120.0
const DEAD_ZONE: float = 0.17

# Placement = ground contact / feet. Proximity is in room's art pixels.
var zones: Array[Dictionary] = [
    {"id":"shower", "name":"Душ", "point":Vector2(395, 495), "radius":112.0, "action":"bath"},
    {"id":"mirror", "name":"Зеркало / зубы", "point":Vector2(586, 489), "radius":104.0, "action":"brush_teeth"},
    {"id":"food", "name":"Кормушка", "point":Vector2(830, 487), "radius":113.0, "action":"eat"},
    {"id":"water", "name":"Поилка", "point":Vector2(1070, 487), "radius":112.0, "action":"drink"},
    {"id":"bed", "name":"Лежанка", "point":Vector2(1275, 495), "radius":115.0, "action":"sleep"}
]

@onready var stage: Node2D = $Stage
@onready var avatar: Node2D = $Stage/BubbleAnchor
@onready var bubble: MikaBubbleBrain = $Stage/BubbleAnchor/Bubble
@onready var walk_area = $Stage/WalkArea
@onready var zone_visual: Node2D = $Stage/ZoneVisual
@onready var shower_fx: MikaBubbleShowerFX = $Stage/ShowerFX
@onready var water_fx: MikaBubbleDrinkerFX = $Stage/DrinkerFX
@onready var feeder_fx: MikaBubbleFeederFX = $Stage/FeederFX

var _joystick
var _use_button: Button
var _near_label: Label
var _description: Label
var _debug_button: Button
var _intro_label: Label
var _hud_root: Control
var _world_position := Vector2(830, 690)
var _velocity := Vector2.ZERO
var _facing := 0.0
var _last_heading_for_turn := 0.0
var _movement_action: String = ""
var _turn_left: float = 0.0
var _turn_cooldown: float = 0.0
var _nearest_zone: String = ""
var _active_interaction: String = ""
var _interaction_remaining: float = 0.0
var _debug_enabled: bool = false

func _ready() -> void:
    stage.position = Vector2.ZERO
    _world_position = walk_area.nearest_point(_world_position)
    avatar.position = _world_position
    zone_visual.set("zones", zones)
    bubble.external_motion_control = true
    bubble.auto_return_idle = false
    # Demo FX must NOT hijack WASD or touches outside the context button.
    shower_fx.allow_switch_click = false
    water_fx.allow_switch_click = false
    feeder_fx.allow_switch_click = false
    shower_fx.set_process_unhandled_key_input(false)
    water_fx.set_process_unhandled_key_input(false)
    feeder_fx.set_process_unhandled_key_input(false)
    shower_fx.set_shower_on(false)
    water_fx.set_fountain_on(true)
    feeder_fx.clear_bowl()
    _make_hud()
    get_viewport().size_changed.connect(_fit_room)
    _fit_room()
    _update_nearest_zone()
    bubble.play_action("idle")
    # Late process to preserve face's projected direction after gait updates.
    process_priority = 150

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)
    _hud_root = Control.new()
    _hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(_hud_root)
    _joystick = JOYSTICK_SCENE.new()
    _joystick.name = "RightJoystick"
    _hud_root.add_child(_joystick)
    _use_button = Button.new()
    _use_button.name = "LeftUseButton"
    _use_button.text = "ИСПОЛЬЗОВАТЬ"
    _use_button.custom_minimum_size = Vector2(215, 72)
    _use_button.add_theme_font_size_override("font_size", 20)
    _use_button.add_theme_color_override("font_color", Color(0.93, 0.99, 1.0))
    _use_button.add_theme_stylebox_override("normal", _style(Color(0.05, 0.17, 0.31, 0.91), Color(0.47, 0.85, 1.0, 0.85)))
    _use_button.add_theme_stylebox_override("hover", _style(Color(0.11, 0.27, 0.43, 0.95), Color(0.85, 1.0, 1.0)))
    _use_button.add_theme_stylebox_override("pressed", _style(Color(0.09, 0.42, 0.56, 0.98), Color(0.9, 1.0, 1.0)))
    _use_button.visible = false
    _use_button.pressed.connect(_use_nearby)
    _hud_root.add_child(_use_button)
    _near_label = Label.new()
    _near_label.add_theme_font_size_override("font_size", 19)
    _near_label.add_theme_color_override("font_color", Color(0.85, 0.99, 1.0))
    _near_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _near_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hud_root.add_child(_near_label)
    _description = Label.new()
    _description.add_theme_font_size_override("font_size", 18)
    _description.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
    _description.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _description.text = "Правый джойстик — движение   •   E — взаимодействие   •   F3 — границы"
    _hud_root.add_child(_description)
    _intro_label = Label.new()
    _intro_label.add_theme_font_size_override("font_size", 21)
    _intro_label.add_theme_color_override("font_color", Color(0.90, 0.97, 1.0))
    _intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _intro_label.text = "БАББЛ · КОМНАТА УХОДА"
    _hud_root.add_child(_intro_label)
    _debug_button = Button.new()
    _debug_button.text = "Границы: выкл"
    _debug_button.add_theme_font_size_override("font_size", 16)
    _debug_button.add_theme_stylebox_override("normal", _style(Color(0.04,0.10,0.21,0.78), Color(0.4,0.6,0.82,0.60)))
    _debug_button.pressed.connect(_toggle_debug)
    _hud_root.add_child(_debug_button)

func _style(fill: Color, outline: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = outline
    s.set_border_width_all(2)
    s.set_corner_radius_all(22)
    s.content_margin_left = 14.0
    s.content_margin_right = 14.0
    s.content_margin_top = 12.0
    s.content_margin_bottom = 12.0
    return s

func _fit_room() -> void:
    var vs := get_viewport_rect().size
    var factor: float = minf(vs.x / ART_SIZE.x, vs.y / ART_SIZE.y)
    stage.scale = Vector2.ONE * factor
    stage.position = (vs - ART_SIZE * factor) * 0.5
    if not is_instance_valid(_hud_root):
        return
    _hud_root.size = vs
    _joystick.position = Vector2(vs.x - 199.0, vs.y - 207.0)
    _use_button.position = Vector2(33.0, vs.y - 136.0)
    _use_button.size = Vector2(222, 74)
    _near_label.position = Vector2(25.0, vs.y - 175.0)
    _near_label.size = Vector2(260, 35)
    _description.position = Vector2(24.0, 64.0)
    _description.size = Vector2(maxf(700.0, vs.x - 48.0), 35.0)
    _intro_label.position = Vector2(24.0, 21.0)
    _intro_label.size = Vector2(360.0, 40.0)
    _debug_button.position = Vector2(vs.x - 194.0, 20.0)
    _debug_button.size = Vector2(170.0, 38.0)

func _keyboard_direction() -> Vector2:
    var axis := Vector2.ZERO
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        axis.x -= 1.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        axis.x += 1.0
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        axis.y -= 1.0
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        axis.y += 1.0
    return axis.normalized()

func _physics_process(delta: float) -> void:
    if _active_interaction != "":
        _interaction_remaining -= delta
        _velocity = Vector2.ZERO
        if _interaction_remaining <= 0.0:
            _end_interaction()
        _update_character_presentation(delta)
        return

    var input_dir: Vector2 = _joystick.direction
    if input_dir.length() <= DEAD_ZONE:
        input_dir = _keyboard_direction()
    elif input_dir.length() > 1.0:
        input_dir = input_dir.normalized()
    var active: bool = input_dir.length() > DEAD_ZONE
    var wanted: Vector2 = input_dir * WALK_SPEED if active else Vector2.ZERO
    _velocity = _velocity.move_toward(wanted, (ACCELERATION if active else BRAKE_ACCELERATION) * delta)
    if _velocity.length() < 1.3:
        _velocity = Vector2.ZERO
    if not _velocity.is_zero_approx():
        _world_position = walk_area.try_step(_world_position, _velocity * delta)
        if not walk_area.is_walkable(_world_position):
            _world_position = walk_area.nearest_point(_world_position)
    avatar.position = _world_position
    _choose_motion(_velocity, delta)
    _update_character_presentation(delta)
    _update_nearest_zone()

func _choose_motion(v: Vector2, delta: float) -> void:
    _turn_cooldown = maxf(0.0, _turn_cooldown - delta)
    _turn_left = maxf(0.0, _turn_left - delta)
    if v.length_squared() < 180.0:
        if _turn_left <= 0.0 and bubble.current_action != "idle":
            bubble.play_action("idle")
            _movement_action = ""
        return
    var target: float = atan2(v.x, v.y)
    var delta_angle: float = wrapf(target - _last_heading_for_turn, -PI, PI)
    var amount: float = absf(delta_angle)
    if amount > 0.43 and _turn_cooldown <= 0.0:
        var suffix: String = "left" if delta_angle < 0.0 else "right"
        var turn_id: String = "turn_45_" + suffix
        var turn_duration: float = 0.48
        if amount > 2.36:
            turn_id = "turn_180_" + suffix
            turn_duration = 1.0
        elif amount > 1.10:
            turn_id = "turn_90_" + suffix
            turn_duration = 0.72
        bubble.play_action(turn_id)
        _turn_left = turn_duration
        _turn_cooldown = turn_duration + 0.14
        _last_heading_for_turn = target
        _movement_action = ""
    _facing = lerp_angle(_facing, target, 1.0 - exp(-5.2 * delta))
    if _turn_left > 0.0:
        return
    var next_action: String = "walk_forward"
    if absf(v.x) > absf(v.y) * 1.1:
        next_action = "strafe_right" if v.x > 0.0 else "strafe_left"
    elif v.y < 0.0:
        next_action = "walk_backward"
    if bubble.current_action != next_action or _movement_action != next_action:
        bubble.play_action(next_action)
        _movement_action = next_action
    # Walk cycles in the legacy Brain are time-boxed; restart smoothly only
    # on completion and never let Brain teleport along a scripted trajectory.
    elif bubble.finished:
        bubble.play_action(next_action)

func _update_character_presentation(delta: float) -> void:
    var depth: float = clampf((_world_position.y - 460.0) / 380.0, 0.0, 1.0)
    var target_scale: float = lerpf(0.28, 0.405, depth)
    var s: float = lerpf(avatar.scale.x, target_scale, 1.0 - exp(-4.5 * delta))
    avatar.scale = Vector2.ONE * s
    # The Bubble scene is already procedural; face projection is extra 2.5D
    # dressing and intentionally skipped during a dedicated turn animation.
    if bubble.current_group == "turn":
        return
    if bubble._actor == null or not is_instance_valid(bubble._actor):
        return
    var face_socket: Node2D = bubble._actor.get_node_or_null("Body/Face") as Node2D
    if face_socket == null:
        return
    var front: float = cos(_facing)
    face_socket.scale.x = maxf(0.08, absf(front))
    face_socket.modulate.a = clampf((front + 0.22) / 0.5, 0.0, 1.0)
    face_socket.position.x += 0.0 # movement script owns socket displacement

func _update_nearest_zone() -> void:
    var id: String = ""
    var distance: float = INF
    for z in zones:
        var d: float = _world_position.distance_to(z["point"])
        if d < float(z["radius"]) and d < distance:
            distance = d
            id = z["id"]
    if _nearest_zone == id and _active_interaction == "":
        return
    _nearest_zone = id
    zone_visual.set("nearby_id", id)
    zone_visual.queue_redraw()
    if _active_interaction != "":
        return
    _use_button.visible = id != ""
    _use_button.text = "ИСПОЛЬЗОВАТЬ"
    if id == "":
        _near_label.text = ""
    else:
        for z in zones:
            if z["id"] == id:
                _near_label.text = "E · " + str(z["name"])
                break

func _use_nearby() -> void:
    if _active_interaction != "":
        _end_interaction()
        return
    if _nearest_zone == "":
        return
    _active_interaction = _nearest_zone
    _velocity = Vector2.ZERO
    _joystick.clear_input()
    _use_button.visible = true
    _use_button.text = "ЗАВЕРШИТЬ"
    _near_label.text = "Пробное действие: " + _zone_name(_active_interaction)
    _interaction_remaining = 4.0
    match _active_interaction:
        "shower":
            shower_fx.set_shower_on(true)
            bubble.play_action("bath")
            _interaction_remaining = 5.2
        "mirror":
            bubble.play_action("brush_teeth")
            _interaction_remaining = 5.2
        "food":
            feeder_fx.start_feeding()
            bubble.play_action("eat")
            _interaction_remaining = 5.0
        "water":
            water_fx.set_fountain_on(true)
            bubble.play_action("drink")
        "bed":
            bubble.play_action("sleep")
            _interaction_remaining = 7.0
    _description.text = "Это предпросмотр позы. Нажмите «ЗАВЕРШИТЬ» для возврата к прогулке."

func _zone_name(id: String) -> String:
    for z in zones:
        if z["id"] == id:
            return str(z["name"])
    return id

func _end_interaction() -> void:
    if _active_interaction == "shower":
        shower_fx.set_shower_on(false)
    _active_interaction = ""
    _interaction_remaining = 0.0
    bubble.play_action("idle")
    _movement_action = ""
    _description.text = "Правый джойстик — движение   •   E — взаимодействие   •   F3 — границы"
    # Force a fresh HUD refresh even if still inside the same proximity area.
    _nearest_zone = ""
    _update_nearest_zone()

func _toggle_debug() -> void:
    _debug_enabled = not _debug_enabled
    walk_area.set_debug(_debug_enabled)
    zone_visual.set("debug_visible", _debug_enabled)
    zone_visual.queue_redraw()
    _debug_button.text = "Границы: вкл" if _debug_enabled else "Границы: выкл"

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_E or event.keycode == KEY_ENTER:
        _use_nearby()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_F3:
        _toggle_debug()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_ESCAPE and _active_interaction != "":
        _end_interaction()
        get_viewport().set_input_as_handled()
