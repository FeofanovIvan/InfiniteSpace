extends "res://education/playtown/src/features/ice_cream/ice_cream_game.gd"
## MIKA Resource Rush / native UI adapter v1.1 (Godot 4.7.1).
## Original IceCreamGame is inherited, not overwritten: unchanged movement,
## NPC AI, walkmask, café art, spawning, scoring, audio and original textures.
## Fixes visually overlapping collectibles missed by tiny Area2D feet colliders.

const MIKA_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const FLIGHT_STICK = preload("res://scripts/Joystick.gd")
const PICKUP_VISUAL_REACH: float = 60.0

const TITLES = {
    "ru": ["СБОР РЕСУРСОВ", "Собирай мороженое быстрее соперника"],
    "en": ["RESOURCE RUSH", "Collect ice cream faster than your rival"],
    "pt": ["CORRIDA DOS RECURSOS", "Recolha sorvetes antes do rival"],
    "es": ["CARRERA DE RECURSOS", "Recoge helados antes que tu rival"],
    "fr": ["COURSE AUX RESSOURCES", "Ramasse les glaces avant ton rival"],
    "de": ["RESSOURCENJAGD", "Sammle Eis schneller als dein Gegner"]
}

var _frame: Panel
var _clip: Panel
var _header: Panel
var _header_label: Label
var _header_subtitle: Label
var _hud: Control
var _toolbar_back: Control
var _flight_stick: Control
var _board_rect: Rect2 = Rect2()
var _locale: String = "en"

func _ready() -> void:
    # Parent creates the unchanged café, girl, friend, score panels, items,
    # music and original joystick. Our overridden _layout uses the old layout
    # until the adapter's nodes have been created.
    super._ready()

    # Old PlayTown home button duplicates the simulator's return button.
    # Preserve this node for compatibility; don't show it in Resource Rush.
    if exit_button != null:
        exit_button.hide()
        exit_button.disabled = true

    # The original joystick remains connected, but only the flight-style
    # fixed joystick (on the OUTSIDE of the stage) receives pointer events.
    if movement_joystick != null:
        movement_joystick.reset()
        movement_joystick.hide()

    background_fill.color = Color("07162d")
    _frame = Panel.new()
    _frame.name = "ResourceRushCyanGameFrame"
    _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _frame.z_index = -100
    MIKA_TOOLBAR.apply_title_style(_frame)
    add_child(_frame)

    _clip = Panel.new()
    _clip.name = "ResourceRushRoundedGameClip"
    _clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _clip.z_index = -90
    var round_mask := StyleBoxFlat.new()
    round_mask.bg_color = Color.WHITE
    round_mask.set_corner_radius_all(19)
    round_mask.anti_aliasing = true
    _clip.add_theme_stylebox_override("panel", round_mask)
    _clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
    add_child(_clip)
    # Relocating the original stage keeps every collision/texture/AI coordinate
    # exactly the same. Only its position/scale in the viewport changes.
    stage.reparent(_clip, false)
    # Original café background uses an ABSOLUTE z=-100; inside a masked
    # framed board that would place the café behind the frame and mask.
    # Keep it behind actors, but make its depth relative to the stage.
    var cafe_sprite: Sprite2D = stage.get_child(0) as Sprite2D
    if cafe_sprite != null:
        cafe_sprite.z_as_relative = true
        cafe_sprite.z_index = -5

    _header = Panel.new()
    _header.name = "ResourceRushNativeCaption"
    _header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header.z_index = 105
    MIKA_TOOLBAR.apply_title_style(_header)
    add_child(_header)
    _header_label = Label.new()
    _header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _header_label.clip_text = true
    _header_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header.add_child(_header_label)
    _header_subtitle = Label.new()
    _header_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _header_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _header_subtitle.clip_text = true
    _header_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header.add_child(_header_subtitle)

    _hud = MIKA_HUD.new() as Control
    _hud.name = "ResourceRushNativeScore"
    _hud.z_index = 106
    _hud.size = Vector2(1680.0, 158.0)
    add_child(_hud)
    for button_name in ["sim_button", "flight_button"]:
        var button: Button = _hud.get(button_name) as Button
        if button != null:
            button.disabled = true
            button.hide()
    _hud.set("crystal_count", player_score)

    # Back navigation belongs EXCLUSIVELY to the hosting simulator/PlanetHub.
    # The game reserves its toolbar slot, but never creates a second button.
    _toolbar_back = _make_back_slot()
    _flight_stick = FLIGHT_STICK.new() as Control
    _flight_stick.name = "ResourceRushFixedFlightJoystick"
    _flight_stick.z_index = 104
    _flight_stick.connect("direction_changed", _set_touch_direction)
    add_child(_flight_stick)

    _locale = _read_language()
    _refresh_title()
    var service: Node = get_node_or_null("/root/LanguageService")
    if service != null and service.has_signal("language_changed"):
        if not service.is_connected("language_changed", Callable(self, "_on_language_changed")):
            service.connect("language_changed", Callable(self, "_on_language_changed"))
    _layout()

func _make_back_slot() -> Control:
    # The two launchers (MikoMainMenu and PlanetHub) have their own Back.
    # The toolbar helper needs a Control to calculate title/counter alignment;
    # this invisible placeholder fills that API role without intercepting input.
    # Do NOT instantiate a Button, BackGlyph, or host-control clone here.
    var slot := Control.new()
    slot.name = "ResourceRushHostBackLayoutSlot"
    slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
    slot.focus_mode = Control.FOCUS_NONE
    add_child(slot)
    return slot

func _read_language() -> String:
    var code: String = "en"
    var service: Node = get_node_or_null("/root/LanguageService")
    if service != null:
        code = str(service.get("learning_locale"))
        if code.is_empty() or code == "<null>":
            code = str(service.get("interface_locale"))
    code = code.replace("-", "_").get_slice("_", 0).to_lower()
    return code if TITLES.has(code) else "en"

func _on_language_changed(_ignored: String) -> void:
    _locale = _read_language()
    _refresh_title()
    _layout()

func _refresh_title() -> void:
    var entry: Array = TITLES.get(_locale, TITLES["en"])
    _header_label.text = str(entry[0])
    _header_subtitle.text = str(entry[1])

func _layout() -> void:
    # Called once by original _ready BEFORE this adapter's controls exist.
    if _clip == null or _toolbar_back == null:
        super._layout()
        return
    var view: Vector2 = get_viewport().get_visible_rect().size
    if view.x < 240.0 or view.y < 180.0:
        return
    background_fill.position = Vector2.ZERO
    background_fill.size = view
    var safe_insets: Vector4 = _safe_area_insets(view)
    var safe := Rect2(Vector2(safe_insets.x, safe_insets.y),
        Vector2(view.x - safe_insets.x - safe_insets.z, view.y - safe_insets.y - safe_insets.w))
    var bottom: float = MIKA_TOOLBAR.relayout(view, safe, _toolbar_back,
        _hud, _header, _header_label, _header_subtitle)
    var gap: float = clampf(safe.size.y * 0.018, 5.0, 15.0)
    var margin: float = clampf(safe.size.x * 0.014, 5.0, 24.0)

    # Original ship joystick visuals and input. One fixed bottom-right slot,
    # never on top of the café's artwork or outside the safe area.
    var js: float = clampf(minf(safe.size.x / 1280.0, safe.size.y / 720.0), 0.40, 1.12)
    var joystick_pixels: float = 184.0 * js
    _flight_stick.scale = Vector2.ONE * js
    _flight_stick.position = safe.end - Vector2.ONE * (joystick_pixels + margin)

    # Reserve a dedicated lateral gutter for the fixed joystick.
    var board_left: float = safe.position.x + margin
    var board_top: float = bottom + gap
    var board_right: float = _flight_stick.position.x - gap - margin
    var board_bottom: float = safe.end.y - margin
    _board_rect = Rect2(Vector2(board_left, board_top),
        Vector2(maxf(100.0, board_right - board_left), maxf(90.0, board_bottom - board_top)))
    _frame.position = _board_rect.position
    _frame.size = _board_rect.size
    _clip.position = _board_rect.position + Vector2.ONE * 4.0
    _clip.size = _board_rect.size - Vector2.ONE * 8.0

    # Contain rather than crop: the same café source, NPC navigation points
    # and collision mask remain visible and geometrically aligned.
    var s: float = minf(_clip.size.x / maxf(1.0, cafe_visible_rect.size.x),
        _clip.size.y / maxf(1.0, cafe_visible_rect.size.y))
    stage.scale = Vector2.ONE * s
    stage.position = (_clip.size - cafe_visible_rect.size * s) * 0.5 - cafe_visible_rect.position * s

    # Preserve the original two character/star score panels, but keep them
    # inside the framed game area rather than the common top toolbar.
    var panel_scale: float = clampf(minf(_clip.size.x / 950.0, _clip.size.y / 480.0), 0.58, 1.0)
    var player_panel := player_score_label.get_parent() as Control
    var npc_panel := npc_score_label.get_parent() as Control
    var score_w: float = 160.0 * panel_scale
    var score_gap: float = 9.0 * panel_scale
    var panel_top: float = _board_rect.position.y + margin * 0.6
    var right_edge: float = _board_rect.end.x - margin
    player_panel.scale = Vector2.ONE * panel_scale
    npc_panel.scale = Vector2.ONE * panel_scale
    player_panel.size = Vector2(160.0, 66.0)
    npc_panel.size = Vector2(160.0, 66.0)
    player_panel.position = Vector2(right_edge - 2.0 * score_w - score_gap, panel_top)
    npc_panel.position = Vector2(right_edge - score_w, panel_top)

    # The old PlayTown exit is intentionally not positioned or displayed.

func _physics_process(delta: float) -> void:
    if player == null:
        return
    var start_pos: Vector2 = player.position
    var npc_start: Vector2 = npc.position
    super._physics_process(delta)
    _check_actor_pickups(player, start_pos, player.position)
    _check_actor_pickups(npc, npc_start, npc.position)

func _check_actor_pickups(actor: CharacterBody2D, start_pos: Vector2, finish_pos: Vector2) -> void:
    # Area2D body_entered alone misses cases in which the character's sprite
    # clearly crosses an ice cream but her capsule (at her feet) misses the
    # displaced circle. Use a small, swept *visual* pickup radius as backup.
    for item in active_pickups.duplicate():
        if not is_instance_valid(item) or item not in active_pickups:
            continue
        if _distance_to_segment(item.position, start_pos, finish_pos) <= PICKUP_VISUAL_REACH:
            _on_pickup_collected(actor, item)

func _check_player_pickups(start_pos: Vector2, finish_pos: Vector2) -> void:
    # Compatibility alias for test harnesses and existing player-only hooks.
    _check_actor_pickups(player, start_pos, finish_pos)

func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
    var delta: Vector2 = finish - start
    var length_sq: float = delta.length_squared()
    if length_sq < 0.0001:
        return point.distance_to(start)
    var t: float = clampf((point - start).dot(delta) / length_sq, 0.0, 1.0)
    return point.distance_to(start + delta * t)

func _on_pickup_collected(body: Node2D, item: Area2D) -> void:
    var was_player: bool = body == player
    var before: int = player_score
    super._on_pickup_collected(body, item)
    if was_player and player_score > before and _hud != null:
        _hud.set("crystal_count", player_score)
