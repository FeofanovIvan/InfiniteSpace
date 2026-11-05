extends Node2D

const CAFE_TEXTURE: Texture2D = preload("res://education/playtown/assets/ice_cream/cafe.png")
const ICE_TEXTURES: Array[Texture2D] = [
	preload("res://education/playtown/assets/ice_cream/ice_cream_strawberry.png"),
	preload("res://education/playtown/assets/ice_cream/ice_cream_mint.png"),
	preload("res://education/playtown/assets/ice_cream/ice_cream_chocolate.png"),
]
const BOY_FRAMES: SpriteFrames = preload("res://education/playtown/assets/characters/boy/boy_frames.tres")
const GIRL_FRAMES: SpriteFrames = preload("res://education/playtown/assets/characters/girl/girl_frames.tres")
const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const COLLECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
const JoystickScript := preload("res://education/playtown/src/ui/child_joystick.gd")
const SOURCE_SIZE := Vector2(1672.0, 941.0)
const PLAYER_SPEED := 225.0
const NPC_SPEED := 155.0
const CELL_SIZE := 20.0
const PICKUP_COUNT := 4
const ACTOR_COLLISION_RADIUS := 11.0
const ACTOR_COLLISION_HEIGHT := 24.0
const NAV_CLEARANCE := 13.0
const NPC_WAYPOINT_TOLERANCE := 11.0
const NPC_STUCK_THRESHOLD := 0.55
const NPC_ESCAPE_DISTANCE := 58.0
const NPC_ESCAPE_MIN_DISTANCE := 26.0
const NPC_PICKUP_REACH := 37.0
const NPC_AVOID_RADIUS := 68.0

const SPAWN_POINTS := [
	Vector2(365, 420), Vector2(515, 430), Vector2(735, 365), Vector2(900, 370),
	Vector2(1360, 425), Vector2(500, 600), Vector2(805, 720),
	Vector2(960, 715), Vector2(1150, 605),
]

# White pixels in the walkmask are walkable; black pixels are furniture/walls.
# The image must be kept aligned with cafe.png at SOURCE_SIZE.
const WALK_MASK_TEXTURE: Texture2D = preload("res://education/playtown/assets/ice_cream/cafe_walkmask.png")

# The cafe is a single flattened texture. Repainting regions over actors
# incorrectly covers their heads and bodies; keep the background behind them.

var stage: Node2D
var cafe_visible_rect: Rect2 = Rect2(Vector2.ZERO, SOURCE_SIZE)
var background_fill: ColorRect
var player: CharacterBody2D
var npc: CharacterBody2D
var player_sprite: AnimatedSprite2D
var npc_sprite: AnimatedSprite2D
var active_pickups: Array[Area2D] = []
var touch_direction := Vector2.ZERO
var movement_joystick: ChildJoystick
var exit_button: GameExitButton
var player_score_label: Label
var npc_score_label: Label
var player_score := 0
var npc_score := 0
var collect_player: AudioStreamPlayer
var astar := AStarGrid2D.new()
var walk_mask: Image
var npc_path := PackedVector2Array()
var npc_path_index := 0
var npc_target: Area2D
var repath_time := 0.0
var npc_last_position := Vector2.ZERO
var npc_stuck_time := 0.0
var npc_failed_targets: Array[Area2D] = []
var npc_detour_goal := Vector2.ZERO
var npc_detour_time := 0.0
var npc_previous_distance := INF
var npc_no_progress_time := 0.0
var npc_escape_direction := Vector2.ZERO
var npc_escape_origin := Vector2.ZERO
var npc_escape_destination := Vector2.ZERO
var npc_escape_blocked_cell := Vector2i(-1, -1)
var npc_escape_attempts := 0


func _ready() -> void:
	randomize()
	_build_stage()
	_update_visible_cafe_rect()
	_build_navigation_grid()
	_build_ui()
	for count in PICKUP_COUNT:
		_spawn_pickup()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _physics_process(delta: float) -> void:
	_move_player()
	_move_npc(delta)


func _build_stage() -> void:
	background_fill = ColorRect.new()
	background_fill.color = Color("#f8cbdc")
	background_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_fill.z_index = -200
	add_child(background_fill)
	stage = Node2D.new()
	stage.y_sort_enabled = true
	add_child(stage)
	var background := Sprite2D.new()
	background.texture = CAFE_TEXTURE
	background.position = SOURCE_SIZE * 0.5
	background.z_index = -100
	background.z_as_relative = false
	stage.add_child(background)
	walk_mask = WALK_MASK_TEXTURE.get_image()
	_build_mask_colliders()
	var selected_is_boy := GameState.selected_character == "boy"
	player = _create_actor(BOY_FRAMES if selected_is_boy else GIRL_FRAMES, Vector2(760, 780), true)
	npc = _create_actor(GIRL_FRAMES if selected_is_boy else BOY_FRAMES, Vector2(920, 780), false)
	player_sprite = player.get_node("AnimatedSprite2D")
	npc_sprite = npc.get_node("AnimatedSprite2D")


func _create_actor(frames: SpriteFrames, start: Vector2, is_player: bool) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.name = "Player" if is_player else "Friend"
	body.position = start
	body.collision_layer = 2
	body.collision_mask = 1 | 2
	# Both characters are solid to each other, unlike the previous version.
	if is_player:
		body.add_to_group("player")
	stage.add_child(body)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = frames
	sprite.animation = &"walk_down"
	sprite.scale = Vector2(0.78, 0.78)
	sprite.position = Vector2(0, -57)
	body.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = ACTOR_COLLISION_RADIUS
	shape.height = ACTOR_COLLISION_HEIGHT
	collision.shape = shape
	collision.position = Vector2(0, -12)
	body.add_child(collision)
	return body


func _add_obstacle(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	stage.add_child(body)


# Collision bodies are generated from the SAME bitmap that NPC pathfinding reads.
# Group filled mask pixels into horizontal runs, then merge equal runs vertically.
# This avoids creating one physics shape per mask pixel.
func _build_mask_colliders() -> void:
	const BLOCK := 8
	var rows: int = ceili(SOURCE_SIZE.y / float(BLOCK))
	var columns: int = ceili(SOURCE_SIZE.x / float(BLOCK))
	var active: Dictionary = {}
	for y in range(rows + 1):
		var runs: Dictionary = {}
		if y < rows:
			var x: int = 0
			while x < columns:
				if _mask_walkable(Vector2((x + 0.5) * BLOCK, (y + 0.5) * BLOCK)):
					x += 1
					continue
				var begin: int = x
				while x < columns and not _mask_walkable(Vector2((x + 0.5) * BLOCK, (y + 0.5) * BLOCK)):
					x += 1
				runs[Vector2i(begin, x)] = true
		var next_active: Dictionary = {}
		for run in runs:
			if active.has(run):
				next_active[run] = active[run]
			else:
				next_active[run] = y
		for run in active:
			if not runs.has(run):
				var top: int = int(active[run])
				_add_obstacle(Rect2(float(run.x * BLOCK), float(top * BLOCK), float((run.y - run.x) * BLOCK), float((y - top) * BLOCK)))
		active = next_active


func _mask_walkable(point: Vector2) -> bool:
	if point.x < 0.0 or point.y < 0.0 or point.x >= SOURCE_SIZE.x or point.y >= SOURCE_SIZE.y:
		return false
	var x: int = clampi(floori(point.x * float(walk_mask.get_width()) / SOURCE_SIZE.x), 0, walk_mask.get_width() - 1)
	var y: int = clampi(floori(point.y * float(walk_mask.get_height()) / SOURCE_SIZE.y), 0, walk_mask.get_height() - 1)
	return walk_mask.get_pixel(x, y).r > 0.5


func _mask_has_clearance(point: Vector2, clearance: float) -> bool:
	if not _mask_walkable(point):
		return false
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
		Vector2(-0.7071, -0.7071), Vector2(0.7071, -0.7071),
		Vector2(-0.7071, 0.7071), Vector2(0.7071, 0.7071)]:
		if not _mask_walkable(point + offset * clearance):
			return false
	return true


func _build_navigation_grid() -> void:
	astar.region = Rect2i(0, 0, ceili(SOURCE_SIZE.x / CELL_SIZE), ceili(SOURCE_SIZE.y / CELL_SIZE))
	astar.cell_size = Vector2.ONE * CELL_SIZE
	astar.offset = Vector2.ONE * CELL_SIZE * 0.5
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for y in astar.region.size.y:
		for x in astar.region.size.x:
			var point: Vector2 = _cell_world(Vector2i(x, y))
			if not _mask_has_clearance(point, NAV_CLEARANCE):
				astar.set_point_solid(Vector2i(x, y), true)


func _spawn_pickup() -> void:
	var free_indices: Array[int] = []
	for index in SPAWN_POINTS.size():
		var occupied := false
		for item in active_pickups:
			if is_instance_valid(item) and int(item.get_meta("spawn_index", -1)) == index:
				occupied = true
				break
		if not occupied:
			free_indices.append(index)
	if free_indices.is_empty():
		return
	var spawn_index: int = int(free_indices.pick_random())
	var item := Area2D.new()
	item.position = SPAWN_POINTS[spawn_index]
	item.collision_layer = 2
	item.collision_mask = 2
	item.monitoring = true
	item.set_meta("spawn_index", spawn_index)
	stage.add_child(item)
	var sprite := Sprite2D.new()
	sprite.texture = ICE_TEXTURES.pick_random()
	var texture_size := sprite.texture.get_size()
	sprite.scale = Vector2.ONE * (72.0 / maxf(texture_size.x, texture_size.y))
	sprite.position = Vector2(0, -34)
	item.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 34.0
	collision.shape = shape
	collision.position = Vector2(0, -25)
	item.add_child(collision)
	item.body_entered.connect(_on_pickup_collected.bind(item))
	active_pickups.append(item)
	var tween := item.create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -42.0, 0.65).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", -34.0, 0.65).set_trans(Tween.TRANS_SINE)


func _on_pickup_collected(body: Node2D, item: Area2D) -> void:
	if not is_instance_valid(item) or item not in active_pickups:
		return
	if body != player and body != npc:
		return
	active_pickups.erase(item)
	if item == npc_target:
		npc_target = null
		npc_path = PackedVector2Array()
		repath_time = 0.0
	npc_failed_targets.erase(item)
	if body == player:
		player_score += 1
		player_score_label.text = str(player_score)
		GameState.add_coins(1)
	else:
		npc_score += 1
		npc_score_label.text = str(npc_score)
	collect_player.play()
	item.queue_free()
	_respawn_after_delay()


func _respawn_after_delay() -> void:
	await get_tree().create_timer(0.55).timeout
	if is_inside_tree():
		_spawn_pickup()


func _move_player() -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") + touch_direction
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	player.velocity = direction * PLAYER_SPEED
	player.move_and_slide()
	_update_animation(player_sprite, direction)


func _move_npc(delta: float) -> void:
	# Recovery owns movement until the NPC has physically backed out.
	# Do not let normal route following overwrite its velocity.
	if npc_escape_direction != Vector2.ZERO:
		_move_npc_escape(delta)
		return
	# Pickups are drawn above their logical floor positions. Collect when
	# the NPC reaches an accessible interaction position, not the art center.
	if is_instance_valid(npc_target) and npc_target in active_pickups:
		if npc.position.distance_to(npc_target.position) <= NPC_PICKUP_REACH:
			_on_pickup_collected(npc, npc_target)
			return
	# Static furniture is planned globally; the player is a dynamic obstacle.
	repath_time -= delta
	if not is_instance_valid(npc_target) or npc_target not in active_pickups:
		_choose_npc_target()
	# Keep a working route. Rebuilding it periodically can make the NPC
	# return to the same grid cell every time it passes a planter.
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

	# The goal is an interaction position on open floor, not necessarily the
	# ice-cream sprite's centre (which can stand near an obstacle).
	if npc_path_index >= npc_path.size() and npc_detour_time <= 0.0 and is_instance_valid(npc_target):
		if npc.position.distance_to(npc_target.position) <= NPC_PICKUP_REACH:
			direction = Vector2.ZERO
		elif _segment_is_walkable(npc.position, npc_target.position):
			direction = npc.position.direction_to(npc_target.position)
		else:
			_rebuild_npc_path()

	# Dynamic avoidance: sidestep the player onto navigable floor rather than
	# repeatedly attempting to push through them or through furniture.
	var player_distance := npc.position.distance_to(player.position)
	if player_distance < NPC_AVOID_RADIUS and direction != Vector2.ZERO:
		var ahead := npc.position + direction * minf(42.0, player_distance + 5.0)
		if ahead.distance_to(player.position) < 36.0:
			var sidestep := _select_sidestep(direction)
			if sidestep != Vector2.ZERO:
				direction = sidestep
			else:
				direction = Vector2.ZERO

	# A detour must be a real A* path, not direct movement through furniture.
	if npc_detour_time > 0.0:
		npc_detour_time -= delta

	var previous_position := npc.position
	npc.velocity = direction * NPC_SPEED
	npc.move_and_slide()
	_update_animation(npc_sprite, npc.velocity if npc.position.distance_to(previous_position) > 0.1 else Vector2.ZERO)
	var actual_movement := npc.position.distance_to(previous_position)
	if direction != Vector2.ZERO and actual_movement < NPC_SPEED * delta * 0.25:
		npc_stuck_time += delta
	else:
		npc_stuck_time = 0.0
	# Detect moving back and forth without approaching the waypoint, too.
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
		# Scan LEFT / RIGHT / BACK first. Do not immediately retry the blocked A* leg.
		var blocked_direction: Vector2 = direction if direction != Vector2.ZERO else Vector2.UP
		_begin_npc_escape(blocked_direction)


# Physical clearance test uses the actual capsule and nearby actors as well as
# the bitmap. The bitmap alone can approve a line the physics engine blocks.
func _npc_escape_clearance(candidate_direction: Vector2, max_distance: float) -> float:
	var direction: Vector2 = candidate_direction.normalized()
	if direction == Vector2.ZERO:
		return 0.0
	var free_distance: float = 0.0
	var step: float = 8.0
	var distance: float = step
	while distance <= max_distance + 0.01:
		var candidate: Vector2 = npc.position + direction * distance
		if not _mask_has_clearance(candidate, ACTOR_COLLISION_RADIUS + 2.0):
			break
		# test_move() works in global transform units; use the full swept
		# capsule, avoiding furniture and the player, not just a point sample.
		var global_motion: Vector2 = npc.global_transform.basis_xform(direction * distance)
		if npc.test_move(npc.global_transform, global_motion):
			break
		free_distance = distance
		distance += step
	return free_distance


func _begin_npc_escape(blocked_direction: Vector2) -> void:
	var forward: Vector2 = blocked_direction.normalized()
	var left: Vector2 = Vector2(-forward.y, forward.x)
	var right: Vector2 = Vector2(forward.y, -forward.x)
	var back: Vector2 = -forward
	# Include diagonal backward exits when a planter and the player create
	# a corner. Try a direction only if the *actual collision capsule* fits.
	var candidates: Array[Vector2] = [left, right, back, (left + back).normalized(), (right + back).normalized()]
	var best_direction: Vector2 = Vector2.ZERO
	var best_distance: float = 0.0
	var best_score: float = -INF
	for candidate in candidates:
		var available: float = _npc_escape_clearance(candidate, 104.0)
		if available < NPC_ESCAPE_MIN_DISTANCE:
			continue
		var destination: Vector2 = npc.position + candidate * available
		var score: float = available * 0.6
		# Prefer sideways escape but allow reverse when no side is open.
		if candidate == left or candidate == right:
			score += 15.0
		if is_instance_valid(npc_target):
			score -= destination.distance_to(npc_target.position) * 0.08
		if destination.distance_to(player.position) < 45.0:
			score -= 70.0
		if score > best_score:
			best_score = score
			best_distance = available
			best_direction = candidate
	if best_direction == Vector2.ZERO:
		# Current body may be pressed into a collision edge. Let the NPC
		# pick another pickup rather than repeatedly hammer that edge.
		npc_escape_attempts += 1
		if is_instance_valid(npc_target) and npc_target not in npc_failed_targets:
			npc_failed_targets.append(npc_target)
		npc_target = null
		npc_path = PackedVector2Array()
		npc_path_index = 0
		repath_time = 0.5
		return
	npc_escape_direction = best_direction
	npc_escape_origin = npc.position
	npc_escape_destination = npc.position + best_direction * minf(best_distance, NPC_ESCAPE_DISTANCE)
	# Temporarily avoid the grid cell towards which the blocked route led.
	# The cell is used only for the next path calculation.
	npc_escape_blocked_cell = _nearest_open_cell(npc.position + forward * CELL_SIZE * 1.5)
	npc_escape_attempts += 1
	npc_path = PackedVector2Array()
	npc_path_index = 0
	npc_detour_time = 0.0


func _move_npc_escape(_delta: float) -> void:
	var remaining: float = npc.position.distance_to(npc_escape_destination)
	if remaining < 8.0:
		_finish_npc_escape()
		return
	var desired: Vector2 = npc.position.direction_to(npc_escape_destination)
	var old_position: Vector2 = npc.position
	npc.velocity = desired * NPC_SPEED * 0.85
	npc.move_and_slide()
	var actual: float = npc.position.distance_to(old_position)
	_update_animation(npc_sprite, desired if actual > 0.15 else Vector2.ZERO)
	if actual < 0.15 or npc.position.distance_to(npc_escape_origin) > NPC_ESCAPE_DISTANCE + 4.0:
		_finish_npc_escape()


func _finish_npc_escape() -> void:
	npc_escape_direction = Vector2.ZERO
	npc.velocity = Vector2.ZERO
	npc_stuck_time = 0.0
	npc_no_progress_time = 0.0
	npc_previous_distance = INF
	# Block the failed cell for *one* pathfinding calculation so A* does not
	# simply choose the identical leg, then restore the shared navigation grid.
	var blocked: Vector2i = npc_escape_blocked_cell
	npc_escape_blocked_cell = Vector2i(-1, -1)
	var current: Vector2i = _nearest_open_cell(npc.position)
	var restore: bool = astar.region.has_point(blocked) and blocked != current and not astar.is_point_solid(blocked)
	if restore:
		astar.set_point_solid(blocked, true)
	if is_instance_valid(npc_target) and npc_target in active_pickups:
		_rebuild_npc_path()
	else:
		_choose_npc_target()
	if restore:
		astar.set_point_solid(blocked, false)
	if npc_path.is_empty() and npc_escape_attempts >= 2:
		if is_instance_valid(npc_target) and npc_target not in npc_failed_targets:
			npc_failed_targets.append(npc_target)
		npc_target = null
		_choose_npc_target()
	else:
		npc_escape_attempts = 0


func _select_sidestep(forward: Vector2) -> Vector2:
	var sides: Array[Vector2] = [Vector2(-forward.y, forward.x), Vector2(forward.y, -forward.x)]
	var best := Vector2.ZERO
	var best_score := -INF
	for side in sides:
		var probe: Vector2 = npc.position + side * 34.0
		if not _segment_is_walkable(npc.position, probe):
			continue
		if probe.distance_to(player.position) <= npc.position.distance_to(player.position):
			continue
		var score: float = probe.distance_to(player.position)
		if is_instance_valid(npc_target):
			score -= probe.distance_to(npc_target.position) * 0.1
		if score > best_score:
			best_score = score
			best = side
	return best


func _find_escape_waypoint() -> Vector2:
	var start := _nearest_open_cell(npc.position)
	var best_point := Vector2.ZERO
	var best_score := -INF
	for y in range(-3, 4):
		for x in range(-3, 4):
			var cell := start + Vector2i(x, y)
			if not astar.region.has_point(cell) or astar.is_point_solid(cell):
				continue
			var point := _cell_world(cell)
			if npc.position.distance_to(point) < 25.0:
				continue
			if not _segment_is_walkable(npc.position, point):
				continue
			if point.distance_to(player.position) < 43.0:
				continue
			var score := point.distance_to(player.position) * 0.3
			if is_instance_valid(npc_target):
				score -= point.distance_to(npc_target.position)
			if score > best_score:
				best_score = score
				best_point = point
	return best_point


func _cell_world(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE


func _choose_npc_target() -> void:
	npc_target = null
	npc_path = PackedVector2Array()
	npc_path_index = 0
	if active_pickups.is_empty():
		return
	var start := _nearest_open_cell(npc.position)
	if not astar.region.has_point(start) or astar.is_point_solid(start):
		return
	var best_cost := INF
	for item in active_pickups:
		if not is_instance_valid(item) or item in npc_failed_targets:
			continue
		var candidate := _path_to_pickup(start, item.position)
		if candidate.is_empty():
			continue
		var cost := npc.position.distance_to(candidate[0])
		for i in range(1, candidate.size()):
			cost += candidate[i - 1].distance_to(candidate[i])
		if cost < best_cost:
			best_cost = cost
			npc_target = item
			npc_path = candidate
	if npc_target == null and not npc_failed_targets.is_empty():
		# Allow previously rejected pickups to be retried when the world changes.
		npc_failed_targets.clear()
		repath_time = 1.2
		return
	npc_path_index = 0
	npc_previous_distance = INF
	repath_time = 1.5


func _rebuild_npc_path() -> void:
	repath_time = 1.5
	if not is_instance_valid(npc_target):
		_choose_npc_target()
		return
	var start := _nearest_open_cell(npc.position)
	if not astar.region.has_point(start):
		npc_path = PackedVector2Array()
	else:
		npc_path = _path_to_pickup(start, npc_target.position)
	npc_path_index = 0
	npc_previous_distance = INF
	if npc_path.is_empty():
		npc_failed_targets.append(npc_target)
		npc_target = null
		_choose_npc_target()


func _path_to_pickup(start: Vector2i, pickup_position: Vector2) -> PackedVector2Array:
	# Search *reachable* interaction cells; do not route into a table just
	# because the pickup graphic is close to that table.
	var centre := _nearest_open_cell(pickup_position)
	var best_path := PackedVector2Array()
	var best_cost := INF
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var cell := centre + Vector2i(dx, dy)
			if not astar.region.has_point(cell) or astar.is_point_solid(cell):
				continue
			var point := _cell_world(cell)
			if point.distance_to(pickup_position) > NPC_PICKUP_REACH:
				continue
			var route := astar.get_point_path(start, cell)
			if route.is_empty():
				continue
			var cost := 0.0
			for j in range(1, route.size()):
				cost += route[j - 1].distance_to(route[j])
			if cost < best_cost:
				best_cost = cost
				best_path = route
	return best_path


func _segment_is_walkable(start: Vector2, finish: Vector2) -> bool:
	var distance := start.distance_to(finish)
	var samples := maxi(1, int(ceil(distance / (CELL_SIZE * 0.5))))
	for i in range(samples + 1):
		var point := start.lerp(finish, float(i) / samples)
		var cell := Vector2i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE))
		if not astar.region.has_point(cell) or astar.is_point_solid(cell):
			return false
		if not _mask_has_clearance(point, ACTOR_COLLISION_RADIUS):
			return false
	return true


func _nearest_open_cell(world_position: Vector2) -> Vector2i:
	var cell := Vector2i(clampi(floori(world_position.x / CELL_SIZE), 0, astar.region.size.x - 1), clampi(floori(world_position.y / CELL_SIZE), 0, astar.region.size.y - 1))
	if not astar.is_point_solid(cell):
		return cell
	# Search nearest by distance, not first found in row order.
	var closest := cell
	var best := INF
	for radius in range(1, 12):
		for y in range(cell.y - radius, cell.y + radius + 1):
			for x in range(cell.x - radius, cell.x + radius + 1):
				var candidate := Vector2i(x, y)
				if not astar.region.has_point(candidate) or astar.is_point_solid(candidate):
					continue
				var cost := Vector2(candidate).distance_squared_to(Vector2(cell))
				if cost < best:
					best = cost
					closest = candidate
		if best < INF:
			return closest
	return closest


func _update_animation(sprite: AnimatedSprite2D, direction: Vector2) -> void:
	if direction.length_squared() < 0.01:
		sprite.stop()
		return
	if absf(direction.x) > absf(direction.y):
		sprite.play(&"walk_right" if direction.x > 0.0 else &"walk_left")
	else:
		sprite.play(&"walk_down" if direction.y > 0.0 else &"walk_up")


func _build_ui() -> void:
	exit_button = GameExitButton.new()
	exit_button.pressed.connect(_go_back)
	exit_button.z_index = 100
	add_child(exit_button)
	player_score_label = _create_score_panel(true)
	npc_score_label = _create_score_panel(false)
	movement_joystick = JoystickScript.new() as ChildJoystick
	movement_joystick.name = "ChildJoystick"
	movement_joystick.z_index = 100
	movement_joystick.direction_changed.connect(_set_touch_direction)
	add_child(movement_joystick)
	collect_player = AudioStreamPlayer.new()
	collect_player.stream = COLLECT_SOUND
	collect_player.bus = "SFX"
	add_child(collect_player)


func _create_score_panel(for_player: bool) -> Label:
	var panel := Panel.new()
	panel.name = "PlayerScore" if for_player else "FriendScore"
	panel.add_theme_stylebox_override("panel", _score_style(Color("#fff2c7") if for_player else Color("#ffe0ec")))
	panel.z_index = 100
	add_child(panel)
	var portrait := TextureRect.new()
	portrait.texture = (BOY_FRAMES.get_frame_texture(&"walk_down", 0) if GameState.selected_character == "boy" else GIRL_FRAMES.get_frame_texture(&"walk_down", 0)) if for_player else (GIRL_FRAMES.get_frame_texture(&"walk_down", 0) if GameState.selected_character == "boy" else BOY_FRAMES.get_frame_texture(&"walk_down", 0))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(7, 5)
	portrait.size = Vector2(48, 58)
	panel.add_child(portrait)
	var star := TextureRect.new()
	star.texture = STAR_TEXTURE
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.position = Vector2(56, 10)
	star.size = Vector2(45, 45)
	panel.add_child(star)
	var label := Label.new()
	label.text = "0"
	label.position = Vector2(101, 5)
	label.size = Vector2(55, 55)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 31)
	label.add_theme_color_override("font_color", Color("#6b3b29"))
	panel.add_child(label)
	return label


# Measure actual nontransparent café pixels once. Keep logical source coordinates
# unchanged so all navigation, obstacles, pickups and actors stay aligned.
func _update_visible_cafe_rect() -> void:
	var source_image: Image = CAFE_TEXTURE.get_image()
	if source_image == null or source_image.is_empty():
		cafe_visible_rect = Rect2(Vector2.ZERO, SOURCE_SIZE)
		return
	var used: Rect2i = source_image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		cafe_visible_rect = Rect2(Vector2.ZERO, SOURCE_SIZE)
	else:
		cafe_visible_rect = Rect2(Vector2(used.position), Vector2(used.size))


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	background_fill.position = Vector2.ZERO
	background_fill.size = view
	# Fit VISIBLE café artwork (not its transparent PNG canvas) into screen.
	# Use the limiting dimension; never crop or distort the artwork.
	var scale_factor: float = minf(view.x / cafe_visible_rect.size.x, view.y / cafe_visible_rect.size.y)
	stage.scale = Vector2.ONE * scale_factor
	stage.position = (view - cafe_visible_rect.size * scale_factor) * 0.5 - cafe_visible_rect.position * scale_factor
	var safe := _safe_area_insets(view)
	exit_button.position = Vector2(safe.x + 16, safe.y + 16)
	exit_button.size = Vector2(90, 84)
	var player_panel := player_score_label.get_parent() as Control
	var npc_panel := npc_score_label.get_parent() as Control
	player_panel.position = Vector2(view.x - safe.z - 350, safe.y + 16)
	npc_panel.position = Vector2(view.x - safe.z - 180, safe.y + 16)
	player_panel.size = Vector2(160, 66)
	npc_panel.size = Vector2(160, 66)
	var joystick_side: float = clampf(minf(view.x, view.y) * 0.245, 154.0, 220.0)
	movement_joystick.size = Vector2.ONE * joystick_side
	movement_joystick.position = Vector2(
		view.x - safe.z - joystick_side - 18.0,
		view.y - safe.w - joystick_side - 18.0
	)


func _set_touch_direction(direction: Vector2) -> void:
	touch_direction = direction


func _score_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#e79a37")
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.25, 0.10, 0.05, 0.25)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 5)
	return style


func _safe_area_insets(view: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0:
		return Vector4.ZERO
	var scale := Vector2(view.x / window_size.x, view.y / window_size.y)
	return Vector4(float(safe_rect.position.x) * scale.x, float(safe_rect.position.y) * scale.y, maxf(0.0, window_size.x - safe_rect.end.x) * scale.x, maxf(0.0, window_size.y - safe_rect.end.y) * scale.y)


func _go_back() -> void:
	SFX.transition_to_scene(GameState.main_scene_path)
