extends "res://learning/src/features/ice_cream/ice_cream_game.gd"
## MIKA Resource Rush / adaptive rival v1.8 (Godot 4.7.1).
## Preserve the exact flight-crystal PNGs, cave mask, pickups and host UI.
## Original IceCreamGame is inherited, not overwritten: unchanged movement,
## NPC AI and pickup mechanics inherited and recovered when stalled; cave art and sprites preserved.
## Fixes visually overlapping collectibles missed by tiny Area2D feet colliders.

const MIKA_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const FLIGHT_STICK = preload("res://scripts/Joystick.gd")
const PICKUP_VISUAL_REACH: float = 60.0
const CRYSTAL_SIDE: float = 112.0
# EXACT textures used by AsteroidField.gd after an asteroid shatters.
# Preserve the original rocks, crystal colours and transparent alpha untouched.
const FLIGHT_CRYSTAL_FRAGMENTS: Array[Texture2D] = [
    preload("res://asteroid_assets/fragments/03_ember/crystal_wedge.png"),
    preload("res://asteroid_assets/fragments/04_blue/needle_crown.png"),
    preload("res://asteroid_assets/fragments/06_violet/star_cluster.png")
]
var _crystal_spawn_serial: int = 0

# Resource Rush Crystal Cavern / source artwork mapped into the original world
# coordinate system. Source art is never cropped; unused margins stay outside
# the framed board. The mask was segmented from the actual uploaded cave PNG.
const CAVE_TEXTURE: Texture2D = preload("res://learning/assets/ice_cream/resource_rush_cave/cave_stage.png")
const CAVE_WALKMASK: Texture2D = preload("res://learning/assets/ice_cream/resource_rush_cave/cave_walkmask_v15.png")
const LIZARD_FRONT_SHEET: Texture2D = preload("res://learning/assets/ice_cream/resource_rush_cave/lizard_walk_front_sheet.png")
const LIZARD_UP_SHEET: Texture2D = preload("res://learning/assets/ice_cream/resource_rush_cave/lizard_walk_up_sheet.png")
const LIZARD_RIGHT_SHEET: Texture2D = preload("res://learning/assets/ice_cream/resource_rush_cave/lizard_walk_right_sheet.png")
const LIZARD_FRAME_SIZE: Vector2 = Vector2(320,480)
# 0.9m MIKA vs 1.1m lizard => visual ratio approx 1.22.
# CharacterBody2D hitboxes stay unchanged, keeping tight maze routes usable.
const LIZARD_GAME_SCALE: float = 0.3056
const CAVE_SPAWNS: Array[Vector2] = [
    Vector2(450,319),Vector2(740,243),Vector2(1096,330),Vector2(1217,318),
    Vector2(1383,508),Vector2(1180,717),Vector2(835,725),Vector2(560,708),
    Vector2(288,508),Vector2(557,510),Vector2(785,605),Vector2(1114,509)
]
var _lizard_sprite: AnimatedSprite2D
var _lizard_frames: SpriteFrames

const TITLES = {
    "ru": ["СБОР КРИСТАЛЛОВ", "Собери больше кристаллов, чем ящер"],
    "en": ["RESOURCE RUSH", "Collect more crystals than the lizard"],
    "pt": ["CORRIDA DOS CRISTAIS", "Colete mais cristais que o lagarto"],
    "es": ["CARRERA DE CRISTALES", "Recoge más cristales que el lagarto"],
    "fr": ["COURSE AUX CRISTAUX", "Ramasse plus de cristaux que le lézard"],
    "de": ["KRISTALLJAGD", "Sammle mehr Kristalle als der Echsenheld"]
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

    # Original joystick remains connected but invisible. Flight-style control
    # is fixed over the lower-right corner of the full-width cave.
    if movement_joystick != null:
        movement_joystick.reset()
        movement_joystick.hide()

    background_fill.color = Color("241535")
    _frame = Panel.new()
    _frame.name = "ResourceRushCyanGameFrame"
    _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _frame.z_index = -100
    # Distinct central game frame, matching the standard cyan MIKA header.
    var cave_frame_style := StyleBoxFlat.new()
    cave_frame_style.bg_color = Color("3a2454")
    cave_frame_style.border_color = Color("65e7ff")
    cave_frame_style.set_border_width_all(4)
    cave_frame_style.set_corner_radius_all(23)
    cave_frame_style.anti_aliasing = true
    cave_frame_style.shadow_color = Color(0.08, 0.60, 0.93, 0.36)
    cave_frame_style.shadow_size = 10
    _frame.add_theme_stylebox_override("panel", cave_frame_style)
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
    _clip.clip_contents = true  # Entire cave world stays INSIDE the game block.
    add_child(_clip)
    # Relocating the original stage keeps every collision/texture/AI coordinate
    # exactly the same. Only its position/scale in the viewport changes.
    # Backfill for the intentionally transparent outer corners of the cave PNG.
    var cave_underlay := ColorRect.new()
    cave_underlay.name = "ResourceRushCaveUnderlay"
    cave_underlay.color = Color("452a61")
    cave_underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cave_underlay.z_index = -25
    _clip.add_child(cave_underlay)
    cave_underlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
    _install_mika_for_girl()
    _install_cave_competitors()
    _layout()
    # Trail is sampled only from real motion on the physical cave floor.

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

# MIKA_RESOURCE_RUSH_HOST_BACK_ALIGN_V1_2
# Export the actual top-toolbar Back slot to the outer host that owns the
# clickable button (MikoMainMenu / PlanetHub). No duplicate game Back.
func resource_rush_host_back_rect() -> Rect2:
    if not is_instance_valid(_toolbar_back):
        return Rect2()
    return Rect2(_toolbar_back.position, _toolbar_back.size)


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
    # The original PlayTown _ready() invokes _layout() before these nodes exist.
    if _clip == null or _toolbar_back == null:
        super._layout()
        return
    var view: Vector2 = get_viewport().get_visible_rect().size
    if view.x < 240.0 or view.y < 180.0:
        return
    background_fill.position = Vector2.ZERO
    background_fill.size = view
    var inset: Vector4 = _safe_area_insets(view)
    var safe := Rect2(Vector2(inset.x, inset.y),
        Vector2(view.x - inset.x - inset.z, view.y - inset.y - inset.w))
    var toolbar_bottom: float = MIKA_TOOLBAR.relayout(view, safe, _toolbar_back,
        _hud, _header, _header_label, _header_subtitle)
    var gap: float = clampf(safe.size.y * 0.012, 5.0, 12.0)
    var margin: float = clampf(safe.size.x * 0.012, 6.0, 20.0)

    # The frame stays large, but the COMPLETE cave image is contained INSIDE it:
    # no cropped rocks or walls, no drawing into the screen around the frame.
    _board_rect = Rect2(
        Vector2(safe.position.x + margin, toolbar_bottom + gap),
        Vector2(maxf(100.0, safe.size.x - margin * 2.0),
            maxf(90.0, safe.end.y - toolbar_bottom - gap - margin)))
    _frame.position = _board_rect.position
    _frame.size = _board_rect.size
    _clip.position = _board_rect.position + Vector2.ONE * 6.0
    _clip.size = _board_rect.size - Vector2.ONE * 12.0

    # CONTAIN rather than cover: consistent scale for the original walkmask,
    # characters, pickups and A* grid. Violet gutters belong inside the frame.
    var source: Rect2 = cafe_visible_rect
    var zoom: float = minf(_clip.size.x / maxf(source.size.x, 1.0),
        _clip.size.y / maxf(source.size.y, 1.0))
    stage.scale = Vector2.ONE * zoom
    stage.position = (_clip.size - source.size * zoom) * 0.5 - source.position * zoom

    # Compact native score widgets at top-left/top-right, OVER the cave.
    # Both show ONLY the character portrait and a white number: no gem icon,
    # no text label, no second crystal counter next to the portraits.
    var player_panel := player_score_label.get_parent() as Control
    var npc_panel := npc_score_label.get_parent() as Control
    var card_scale: float = clampf(minf(_board_rect.size.x / 1150.0,
        _board_rect.size.y / 520.0), 0.64, 1.0)
    var score_width: float = 152.0 * card_scale
    var pad: float = maxf(9.0, margin * 0.85)
    var score_y: float = _clip.position.y + pad
    player_panel.scale = Vector2.ONE * card_scale
    npc_panel.scale = Vector2.ONE * card_scale
    player_panel.size = Vector2(152.0, 68.0)
    npc_panel.size = Vector2(152.0, 68.0)
    player_panel.position = Vector2(_clip.position.x + pad, score_y)
    npc_panel.position = Vector2(_clip.position.x + _clip.size.x - score_width - pad, score_y)
    for panel in [player_panel, npc_panel]:
        panel.add_theme_stylebox_override("panel", _blue_score_style())
        panel.z_index = 107

    # Same fixed spaceship joystick, now OVER the game frame in its bottom
    # right corner. Never reserve a side gutter or resize the cave for it.
    var joy_scale: float = clampf(minf(_board_rect.size.x / 1250.0,
        _board_rect.size.y / 560.0), 0.48, 0.90)
    var joy_size: float = 184.0 * joy_scale
    _flight_stick.scale = Vector2.ONE * joy_scale
    _flight_stick.position = Vector2(_clip.position.x + _clip.size.x - joy_size - pad,
        _clip.position.y + _clip.size.y - joy_size - pad)

func _blue_score_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.02, 0.105, 0.245, 0.93)
    style.border_color = Color("65e7ff")
    style.set_border_width_all(3)
    style.set_corner_radius_all(18)
    style.anti_aliasing = true
    style.shadow_color = Color(0.06, 0.62, 1.0, 0.25)
    style.shadow_size = 6
    style.shadow_offset = Vector2.ZERO
    return style

func _physics_process(delta: float) -> void:
    if player == null:
        return
    # A single clock for pickup tempo, independent of framerate and current score.
    _adaptive_elapsed += maxf(0.0, delta)
    # Smooth acceleration, but NEVER reduce current rival speed in this round.
    _adaptive_speed = move_toward(_adaptive_speed, _adaptive_target_speed, 24.0 * maxf(0.0, delta))
    var start_pos: Vector2 = player.position
    var npc_start: Vector2 = npc.position
    var requested: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") + touch_direction
    super._physics_process(delta)
    _check_actor_pickups(player, start_pos, player.position)
    _check_actor_pickups(npc, npc_start, npc.position)
    _mika_guard_movement(delta, start_pos, requested)

# MIKA_RESOURCE_RUSH_MIKA_UNSTUCK_V1_9_2
# The navigation A* grid uses 14 px clearance for route planning. That
# clearance is intentionally stricter than the 6.5 px physics capsule, so
# it must NOT veto a short retreat along the player's actual footsteps.
# Each breadcrumb is recorded only on safely traversed cave floor. When a
# player holds a direction but cannot advance, step back to the latest
# earlier breadcrumb across continuous walkable mask pixels. No random
# teleport, no wall-crossing, no score or AI modifications.
const MIKA_RESCUE_AFTER_SECONDS: float = 0.52
const MIKA_RESCUE_COOLDOWN_SECONDS: float = 1.65
const MIKA_SAFE_STEP: float = 7.0
const MIKA_RESCUE_MAX_DISTANCE: float = 65.0
var _mika_stall_seconds: float = 0.0
var _mika_rescue_cooldown: float = 0.0
var _mika_safe_trail: Array[Vector2] = []

func _mika_collider() -> CollisionShape2D:
    if not is_instance_valid(player):
        return null
    for child in player.get_children():
        if child is CollisionShape2D:
            return child as CollisionShape2D
    return null

func _mika_safe_for_body(floor_point: Vector2) -> bool:
    # This is used only when RECORDING positions, not when recovering them.
    # The collision rectangles do not move during a Resource Rush round.
    if not _mask_has_clearance(floor_point, 9.0):
        return false
    var hitbox: CollisionShape2D = _mika_collider()
    if hitbox == null or hitbox.shape == null:
        return false
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = hitbox.shape
    var pose: Transform2D = player.global_transform * hitbox.transform
    pose.origin += stage.to_global(floor_point) - player.global_position
    query.transform = pose
    query.collision_mask = 1
    query.exclude = [player.get_rid()]
    return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _mika_record_safe_point(floor_point: Vector2) -> void:
    if _mika_safe_trail.size() > 0 and floor_point.distance_to(_mika_safe_trail.back()) < MIKA_SAFE_STEP:
        return
    if not _mika_safe_for_body(floor_point):
        return
    _mika_safe_trail.append(floor_point)
    if _mika_safe_trail.size() > 32:
        _mika_safe_trail.pop_front()

func _mika_reverse_corridor_clear(from_point: Vector2, to_point: Vector2) -> bool:
    # Sample the ACTUAL source bitmap every 3px. Do not reuse the deliberately
    # conservative A* route test, which can reject a corridor the 6.5px actor
    # just traversed. Both points are nearby, so this cannot skip a wall.
    var delta: Vector2 = to_point - from_point
    var span: float = delta.length()
    if span > MIKA_RESCUE_MAX_DISTANCE:
        return false
    var samples: int = maxi(1, ceili(span / 3.0))
    for sample in range(samples + 1):
        if not _mask_walkable(from_point.lerp(to_point, float(sample) / float(samples))):
            return false
    return true

func _mika_release_from_trap() -> bool:
    # Trust breadcrumbs already checked when MIKA was physically standing on
    # them. Rechecking a collision shape while the body is temporarily wedged
    # can produce an inconsistent physics-space result. The cave is static.
    for i in range(_mika_safe_trail.size() - 1, -1, -1):
        var safe_point: Vector2 = _mika_safe_trail[i]
        var distance: float = safe_point.distance_to(player.position)
        # 1.9 rejected every 7-18px breadcrumb, making the actual escape fail.
        if distance < 2.0 or distance > MIKA_RESCUE_MAX_DISTANCE:
            continue
        if not _mika_reverse_corridor_clear(player.position, safe_point):
            continue
        player.position = safe_point
        player.velocity = Vector2.ZERO
        _mika_safe_trail.clear()
        _mika_safe_trail.append(safe_point)
        _update_animation(player_sprite, Vector2.ZERO)
        return true
    return false

func _mika_guard_movement(delta: float, previous: Vector2, requested: Vector2) -> void:
    _mika_rescue_cooldown = maxf(0.0, _mika_rescue_cooldown - delta)
    _mika_record_safe_point(previous)
    _mika_record_safe_point(player.position)
    if requested.length_squared() < 0.12:
        _mika_stall_seconds = 0.0
        return
    var actual_movement: float = previous.distance_to(player.position)
    if actual_movement >= maxf(0.25, PLAYER_SPEED * delta * 0.10):
        _mika_stall_seconds = 0.0
        return
    _mika_stall_seconds += delta
    if _mika_stall_seconds < MIKA_RESCUE_AFTER_SECONDS or _mika_rescue_cooldown > 0.0:
        return
    if _mika_release_from_trap():
        _mika_rescue_cooldown = MIKA_RESCUE_COOLDOWN_SECONDS
    _mika_stall_seconds = 0.0

# Deliberately use the ORIGINAL PlayTown NPC A* and collision recovery.
# Previous custom 2.6s reset interrupted its own escape and target pursuit.
# The NPC now starts on clear floor, safely away from the rock collider.

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
    # The HUD in this game is the LOCAL match counter (always starts at 0).
    # The inherited method already calls GameState.add_coins(1), so every
    # real MIKA collection is ALSO credited to the permanent global balance.
    if was_player and player_score > before:
        _adaptive_register_player_pickup()
        if _hud != null:
            _hud.set("crystal_count", player_score)



# MIKA_RESOURCE_RUSH_ADAPTIVE_RIVAL_V1_8
# Observe how quickly the human ACTUALLY collects successive crystals.
# Use the fastest recent 2-5 pickup burst so difficulty only ever increases;
# a pause or slow period never makes the lizard slow down again in this round.
const RIVAL_START_SPEED: float = 95.0
const RIVAL_MAX_SPEED: float = 199.0  # Player's original speed is 225.
const RIVAL_ACCELERATION: float = 24.0 # World units per second squared.
const RIVAL_RATE_LOW: float = 0.25     # Crystals per second.
const RIVAL_RATE_HIGH: float = 1.55

var _adaptive_elapsed: float = 0.0
var _adaptive_player_pickups: Array[float] = []
var _adaptive_peak_rate: float = 0.0
var _adaptive_speed: float = RIVAL_START_SPEED
var _adaptive_target_speed: float = RIVAL_START_SPEED

func _adaptive_register_player_pickup() -> void:
    _adaptive_player_pickups.append(_adaptive_elapsed)
    # Only the most recent five pickups are needed to measure an energetic burst.
    while _adaptive_player_pickups.size() > 5:
        _adaptive_player_pickups.remove_at(0)
    var total: int = _adaptive_player_pickups.size()
    if total < 2:
        return
    var last: float = _adaptive_player_pickups[total - 1]
    for span_size in range(2, total + 1):
        var first: float = _adaptive_player_pickups[total - span_size]
        var window: float = maxf(0.85, last - first)
        var rate: float = float(span_size - 1) / window
        _adaptive_peak_rate = maxf(_adaptive_peak_rate, rate)
    var progress: float = clampf((minf(_adaptive_peak_rate, 3.0) - RIVAL_RATE_LOW) /
        (RIVAL_RATE_HIGH - RIVAL_RATE_LOW), 0.0, 1.0)
    var demanded: float = lerpf(RIVAL_START_SPEED, RIVAL_MAX_SPEED, progress)
    _adaptive_target_speed = maxf(_adaptive_target_speed, demanded)
    # A quicker navigator revisits unreachable targets sooner, but never
    # changes the underlying original A* pathfinding or stuck recovery.
    repath_time = minf(repath_time, _adaptive_repath_seconds())

func _adaptive_repath_seconds() -> float:
    var fraction: float = clampf(_adaptive_peak_rate / RIVAL_RATE_HIGH, 0.0, 1.0)
    return lerpf(1.45, 0.50, fraction)

func _choose_npc_target() -> void:
    super._choose_npc_target()
    repath_time = minf(repath_time, _adaptive_repath_seconds())

func _rebuild_npc_path() -> void:
    super._rebuild_npc_path()
    repath_time = minf(repath_time, _adaptive_repath_seconds())

# The original PlayTown movement / collision / A* / escape logic is preserved
# verbatim except that the two NPC_SPEED usages become _adaptive_speed.
# Avoid scaling transforms or moving the actor a second time: those broke
# collision checks and made the rival stall in narrow cave passages.
func _move_npc(delta: float) -> void:
    if npc_escape_direction != Vector2.ZERO:
        _move_npc_escape(delta)
        return
    if is_instance_valid(npc_target) and npc_target in active_pickups:
        if npc.position.distance_to(npc_target.position) <= NPC_PICKUP_REACH:
            _on_pickup_collected(npc, npc_target)
            return
    repath_time -= delta
    if not is_instance_valid(npc_target) or npc_target not in active_pickups:
        _choose_npc_target()
    elif npc_path.is_empty() and repath_time <= 0.0:
        _rebuild_npc_path()

    var direction := Vector2.ZERO
    var waypoint := Vector2.ZERO
    while npc_path_index < npc_path.size():
        waypoint = npc_path[npc_path_index]
        if npc.position.distance_to(waypoint) <= NPC_WAYPOINT_TOLERANCE:
            npc_path_index += 1
        else:
            direction = npc.position.direction_to(waypoint)
            break

    if npc_detour_time > 0.0 and npc_path_index >= npc_path.size():
        npc_detour_time = 0.0
        _rebuild_npc_path()

    if npc_path_index >= npc_path.size() and npc_detour_time <= 0.0 and is_instance_valid(npc_target):
        if npc.position.distance_to(npc_target.position) <= NPC_PICKUP_REACH:
            direction = Vector2.ZERO
        elif _segment_is_walkable(npc.position, npc_target.position):
            direction = npc.position.direction_to(npc_target.position)
        else:
            _rebuild_npc_path()

    var player_distance := npc.position.distance_to(player.position)
    if player_distance < NPC_AVOID_RADIUS and direction != Vector2.ZERO:
        var ahead := npc.position + direction * minf(42.0, player_distance + 5.0)
        if ahead.distance_to(player.position) < 36.0:
            var sidestep := _select_sidestep(direction)
            if sidestep != Vector2.ZERO:
                direction = sidestep
            else:
                direction = Vector2.ZERO

    if npc_detour_time > 0.0:
        npc_detour_time -= delta

    var previous_position := npc.position
    npc.velocity = direction * _adaptive_speed
    npc.move_and_slide()
    _update_animation(npc_sprite, npc.velocity if npc.position.distance_to(previous_position) > 0.1 else Vector2.ZERO)
    var actual_movement := npc.position.distance_to(previous_position)
    if direction != Vector2.ZERO and actual_movement < _adaptive_speed * delta * 0.25:
        npc_stuck_time += delta
    else:
        npc_stuck_time = 0.0

    if npc_path_index < npc_path.size():
        var remaining := npc.position.distance_to(npc_path[npc_path_index])
        if remaining >= npc_previous_distance - 0.5:
            npc_no_progress_time += delta
        else:
            npc_no_progress_time = 0.0
        npc_previous_distance = remaining
    else:
        npc_previous_distance = INF
        npc_no_progress_time = 0.0
    npc_last_position = npc.position
    if npc_stuck_time > NPC_STUCK_THRESHOLD or npc_no_progress_time > 1.2:
        npc_stuck_time = 0.0
        npc_no_progress_time = 0.0
        npc_previous_distance = INF
        var blocked_direction: Vector2 = direction if direction != Vector2.ZERO else Vector2.UP
        _begin_npc_escape(blocked_direction)

func _move_npc_escape(_delta: float) -> void:
    var remaining: float = npc.position.distance_to(npc_escape_destination)
    if remaining < 8.0:
        _finish_npc_escape()
        return
    var desired: Vector2 = npc.position.direction_to(npc_escape_destination)
    var old_position: Vector2 = npc.position
    npc.velocity = desired * _adaptive_speed * 0.85
    npc.move_and_slide()
    var actual: float = npc.position.distance_to(old_position)
    _update_animation(npc_sprite, desired if actual > 0.15 else Vector2.ZERO)
    if actual < 0.15 or npc.position.distance_to(npc_escape_origin) > NPC_ESCAPE_DISTANCE + 4.0:
        _finish_npc_escape()

# MIKA_RESOURCE_RUSH_MIKA_24_FRAMES_V1_3
# Replace ONLY the original girl appearance; keep both CharacterBody2D
# objects, their collision capsules, movement, navigation, pickups, scores and
# UI geometry unchanged. 3 atlases x 8 frames = user-supplied 24 frames.
const MIKA_FRONT_SHEET: Texture2D = preload("res://learning/assets/ice_cream/resource_rush_mika/mika_walk_front_sheet.png")
const MIKA_UP_SHEET: Texture2D = preload("res://learning/assets/ice_cream/resource_rush_mika/mika_walk_up_sheet.png")
const MIKA_RIGHT_SHEET: Texture2D = preload("res://learning/assets/ice_cream/resource_rush_mika/mika_walk_right_sheet.png")
const MIKA_FRAME_SIZE: Vector2 = Vector2(320.0, 480.0)
# Transparent canvas feet are at y=458. With a 0.25 scale the character's
# feet line up at actor y=0: -54.5 + (458-240)*0.25 = 0.
const MIKA_GAME_SCALE: float = 0.25

var _mika_sprite: AnimatedSprite2D
var _mika_frames: SpriteFrames

func _install_mika_for_girl() -> void:
    # Original stage generates a girl as player when girl is selected; when
    # boy is selected the girl is the rival NPC. Replace just that character.
    var girl_is_player: bool = str(GameState.selected_character) != "boy"
    _mika_sprite = player_sprite if girl_is_player else npc_sprite
    if _mika_sprite == null:
        push_warning("Resource Rush: MIKA character could not be installed")
        return
    _mika_frames = SpriteFrames.new()
    for animation_name in ["walk_down", "walk_up", "walk_right", "walk_left"]:
        var clip_name := StringName(animation_name)
        _mika_frames.add_animation(clip_name)
        _mika_frames.set_animation_speed(clip_name, 8.0)
        _mika_frames.set_animation_loop(clip_name, true)
        var sheet: Texture2D = MIKA_FRONT_SHEET
        if animation_name == "walk_up":
            sheet = MIKA_UP_SHEET
        elif animation_name == "walk_right" or animation_name == "walk_left":
            sheet = MIKA_RIGHT_SHEET
        for frame_index in range(8):
            var atlas_frame := AtlasTexture.new()
            atlas_frame.atlas = sheet
            atlas_frame.region = Rect2(
                Vector2(float(frame_index % 4) * MIKA_FRAME_SIZE.x,
                        float(floori(float(frame_index) / 4.0)) * MIKA_FRAME_SIZE.y),
                MIKA_FRAME_SIZE)
            atlas_frame.filter_clip = true
            _mika_frames.add_frame(clip_name, atlas_frame)
    _mika_sprite.sprite_frames = _mika_frames
    _mika_sprite.animation = &"walk_down"
    _mika_sprite.frame = 0
    _mika_sprite.flip_h = false
    _mika_sprite.scale = Vector2.ONE * MIKA_GAME_SCALE
    _mika_sprite.position = Vector2(0.0, -54.5)
    _mika_sprite.stop()

    # The original score panel contains a portrait as child #0. Replace only
    # the girl's portrait; leave the score, star, layout and boy unchanged.
    var score_label: Label = player_score_label if girl_is_player else npc_score_label
    if score_label != null:
        var score_panel: Control = score_label.get_parent() as Control
        if score_panel != null and score_panel.get_child_count() > 0:
            var portrait: TextureRect = score_panel.get_child(0) as TextureRect
            if portrait != null:
                portrait.texture = _mika_frames.get_frame_texture(&"walk_down", 0)

func _update_animation(sprite: AnimatedSprite2D, direction: Vector2) -> void:
    if (sprite == _mika_sprite or sprite == _lizard_sprite) and direction.length_squared() >= 0.01:
        # There are no dedicated left frames in the supplied archive.
        # Mirror the 8 walk-right frames without modifying the PNGs.
        sprite.flip_h = absf(direction.x) > absf(direction.y) and direction.x < 0.0
    super._update_animation(sprite, direction)


# ------------------- CRYSTAL CAVERN GAMEPLAY OVERRIDES -------------------
# MIKA_RESOURCE_RUSH_ORIGINAL_FLIGHT_FRAGMENTS_V1_7
# Navmesh and physics previously disagreed in 8px-wide border cells: A*
# planned a path but the rival's old 11px capsule could not pass the corridor.
# Keep the original AI / 20px grid, but give the lizard a smaller FOOTPRINT.
# Visual size (1.1m) is unchanged, as are MIKA's collision and control.
func _create_actor(frames: SpriteFrames, start: Vector2, is_player: bool) -> CharacterBody2D:
    var body: CharacterBody2D = super._create_actor(frames, start, is_player)
    if is_player:
        # Parent café capsule (r=11, h=24) catches on coarse cave corners.
        # Use the SAME 6.5 px footprint as the rival; visuals stay 0.9m.
        for child in body.get_children():
            if child is CollisionShape2D:
                var capsule := CapsuleShape2D.new()
                capsule.radius = 6.5
                capsule.height = 19.0
                (child as CollisionShape2D).shape = capsule
                (child as CollisionShape2D).position = Vector2(0.0, -8.0)
                break
    if not is_player:
        # Parent creates CollisionShape2D with no explicit name; at runtime
        # Godot can assign @CollisionShape2D@N, so path lookup is unreliable.
        # Search by actual node type to keep the lizard footprint passable.
        var hitbox: CollisionShape2D = null
        for child in body.get_children():
            if child is CollisionShape2D:
                hitbox = child as CollisionShape2D
                break
        if hitbox == null:
            push_error("Resource Rush: lizard collision child was not created")
        else:
            var capsule := CapsuleShape2D.new()
            capsule.radius = 6.5
            capsule.height = 19.0
            hitbox.shape = capsule
            hitbox.position = Vector2(0.0, -8.0)
    return body

# A* should not prefer paths pressed against small mask irregularities.
# 14px clearance still connects ALL 12 genuine cave collection sites;
# a larger 15px grid clearance disconnects the upper passage.
func _build_navigation_grid() -> void:
    super._build_navigation_grid()
    for y in range(astar.region.size.y):
        for x in range(astar.region.size.x):
            var cell := Vector2i(x, y)
            if not astar.is_point_solid(cell) and not _mask_has_clearance(_cell_world(cell), 14.0):
                astar.set_point_solid(cell, true)

func _build_mask_colliders() -> void:
    # Called from original _build_stage, BEFORE navigation and spawning.
    # Override the old café walkmask before collision rectangles are built.
    walk_mask = CAVE_WALKMASK.get_image()
    super._build_mask_colliders()

func _build_stage() -> void:
    super._build_stage()
    var old_cafe: Sprite2D = stage.get_child(0) as Sprite2D
    if old_cafe != null:
        old_cafe.texture = CAVE_TEXTURE
    # Both actors begin together near the open lower floor. Coordinate space
    # remains the original 1672x941 so collision/pathfinding is untouched.
    player.position = Vector2(780.0, 745.0)
    npc.position = Vector2(865.0, 720.0)

func _update_visible_cafe_rect() -> void:
    # Uploaded 1536x1024 image is scaled proportionally, never stretched or
    # cropped. The background file includes transparent lateral padding.
    # Exact painted bounds from the supplied PNG; no empty transparent bars.
    cafe_visible_rect = Rect2(Vector2(130.0, 1.0), Vector2(1412.0, 911.0))

# Keep the native asteroid-fragment PNGs. They already have transparent edges;
# no image extraction, recolouring or runtime cropping is performed.

func _spawn_pickup() -> void:
    var free_indices: Array[int] = []
    var distant_indices: Array[int] = []
    for index in range(CAVE_SPAWNS.size()):
        var occupied: bool = false
        var near_another: bool = false
        for item in active_pickups:
            if not is_instance_valid(item):
                continue
            if int(item.get_meta("spawn_index", -1)) == index:
                occupied = true
                break
            if item.position.distance_to(CAVE_SPAWNS[index]) < 260.0:
                near_another = true
        if occupied:
            continue
        # A new match must start at 0:0. The initial character positions are
        # close to spawn index 6 (835,725), and Area2D / swept pickup detection
        # used to collect that crystal on the first physics frame. Never spawn
        # an item inside either actor's pickup reach, including on respawns.
        var spot: Vector2 = CAVE_SPAWNS[index]
        if is_instance_valid(player) and spot.distance_to(player.position) < 120.0:
            continue
        if is_instance_valid(npc) and spot.distance_to(npc.position) < 120.0:
            continue
        free_indices.append(index)
        if not near_another:
            distant_indices.append(index)
    if free_indices.is_empty():
        return
    # Spread the crystals across the cave where possible. Still allow every
    # available position when four distant sites cannot be found.
    var choices: Array[int] = distant_indices if not distant_indices.is_empty() else free_indices
    var spawn_index: int = int(choices.pick_random())
    var item := Area2D.new()
    item.position = CAVE_SPAWNS[spawn_index]
    item.collision_layer = 2
    item.collision_mask = 2
    item.monitoring = true
    item.set_meta("spawn_index", spawn_index)
    var kind: int = _crystal_spawn_serial % 3
    _crystal_spawn_serial += 1
    item.set_meta("crystal_kind", kind)
    stage.add_child(item)
    var sprite := Sprite2D.new()
    sprite.texture = FLIGHT_CRYSTAL_FRAGMENTS[kind]
    var tex_size: Vector2 = sprite.texture.get_size()
    sprite.scale = Vector2.ONE * (CRYSTAL_SIDE / maxf(1.0, maxf(tex_size.x, tex_size.y)))
    sprite.position = Vector2(0.0, -32.0)
    item.add_child(sprite)
    var collision := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 31.0
    collision.shape = circle
    collision.position = Vector2(0.0, -24.0)
    item.add_child(collision)
    item.body_entered.connect(_on_pickup_collected.bind(item))
    active_pickups.append(item)

func _install_cave_competitors() -> void:
    # Always MIKA as player and the approved orange lizard as NPC regardless
    # of PlayTown's global boy/girl preference. Keep physics capsules intact.
    if _mika_frames == null:
        push_error("Resource Rush Cave: MIKA 24-frame atlas missing")
        return
    _mika_sprite = player_sprite
    player_sprite.sprite_frames = _mika_frames
    player_sprite.animation = &"walk_down"
    player_sprite.frame = 0
    player_sprite.scale = Vector2.ONE * MIKA_GAME_SCALE
    player_sprite.position = Vector2(0.0, -54.5)
    player_sprite.stop()
    _lizard_frames = SpriteFrames.new()
    for direction in ["walk_down", "walk_up", "walk_right", "walk_left"]:
        var key := StringName(direction)
        _lizard_frames.add_animation(key)
        _lizard_frames.set_animation_speed(key, 8.0)
        _lizard_frames.set_animation_loop(key, true)
        var sheet: Texture2D = LIZARD_FRONT_SHEET
        if direction == "walk_up":
            sheet = LIZARD_UP_SHEET
        elif direction == "walk_right" or direction == "walk_left":
            sheet = LIZARD_RIGHT_SHEET
        for i in range(8):
            var frame := AtlasTexture.new()
            frame.atlas = sheet
            frame.region = Rect2(Vector2(float(i%4)*LIZARD_FRAME_SIZE.x, float(floori(float(i)/4.0))*LIZARD_FRAME_SIZE.y),LIZARD_FRAME_SIZE)
            frame.filter_clip = true
            _lizard_frames.add_frame(key,frame)
    _lizard_sprite = npc_sprite
    _lizard_sprite.sprite_frames = _lizard_frames
    _lizard_sprite.animation = &"walk_down"
    _lizard_sprite.frame = 0
    _lizard_sprite.scale = Vector2.ONE * LIZARD_GAME_SCALE
    _lizard_sprite.position = Vector2(0.0, -(464.0-240.0)*LIZARD_GAME_SCALE)
    _lizard_sprite.stop()
    # Existing PlayTown panels: portrait + white numeral only, zero initially.
    var player_panel: Control = player_score_label.get_parent() as Control
    var rival_panel: Control = npc_score_label.get_parent() as Control
    if player_panel != null:
        var icon: TextureRect = player_panel.get_child(0) as TextureRect
        if icon != null:
            icon.texture = _mika_frames.get_frame_texture(&"walk_down", 0)
        var old_star: TextureRect = player_panel.get_child(1) as TextureRect
        if old_star != null:
            old_star.hide()
    if rival_panel != null:
        var icon: TextureRect = rival_panel.get_child(0) as TextureRect
        if icon != null:
            icon.texture = _lizard_frames.get_frame_texture(&"walk_down", 0)
        var old_star: TextureRect = rival_panel.get_child(1) as TextureRect
        if old_star != null:
            old_star.hide()
    for score_label in [player_score_label, npc_score_label]:
        score_label.position = Vector2(73.0, 5.0)
        score_label.size = Vector2(72.0, 57.0)
        score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        score_label.add_theme_font_size_override("font_size", 36)
        score_label.add_theme_color_override("font_color", Color("f5ffff"))
        score_label.add_theme_color_override("font_shadow_color", Color("07162d"))
        score_label.add_theme_constant_override("shadow_offset_x", 1)
        score_label.add_theme_constant_override("shadow_offset_y", 2)
    # The match always begins at zero. Global wallet is never reset;
    # each actual player pickup still calls inherited GameState.add_coins(1).
    player_score = 0
    npc_score = 0
    player_score_label.text = "0"
    npc_score_label.text = "0"
    if _hud != null:
        _hud.set("crystal_count", 0)
