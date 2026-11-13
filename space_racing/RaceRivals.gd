extends Node2D
## Four independent race opponents, using the existing Milky Way ship artwork.
const ROUTE_SAMPLES := 240
const TOTAL_LAPS := 3
const ART: Array[Texture2D] = [
 preload("res://assets/ships/05_supercar_racer.png"),
 preload("res://assets/ships/01_police_patrol.png"),
 preload("res://assets/ships/08_science_explorer.png"),
 preload("res://assets/ships/02_pirate_raider.png")
]
const COLORS: Array[Color] = [Color(0.52, 1.0, 0.43), Color(0.37, 0.68, 1.0), Color(0.43, 1.0, 0.84), Color(1.0, 0.40, 0.71)]
var route: PackedVector2Array = PackedVector2Array()
var track_width := 650.0
var camera_world := Vector2.ZERO
var viewport_size := Vector2(1280.0, 720.0)
var racers: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var active := false
const COLLISION_RADIUS: float = 47.0
const SPRITE_BODY_SIZE: float = 104.0
const LANE_SHIFT_RATE: float = 190.0
const HEADING_LOOKAHEAD: float = 65.0
var _sprite_regions: Array[Rect2] = []
var _previous_positions: Array[Vector2] = []
var _previous_angles: Array[float] = []
const WALL_RESTITUTION: float = 0.32
const CONTACT_COOLDOWN: float = 0.42
var _contact_timers: Array[float] = []

func _ready() -> void:
 # Crop transparent padding independently for each artwork, preserving aspect ratio.
 _sprite_regions.clear()
 for texture in ART:
  var img: Image = texture.get_image()
  var used: Rect2i = img.get_used_rect()
  if used.size.x <= 0 or used.size.y <= 0:
   used = Rect2i(Vector2i.ZERO, img.get_size())
  _sprite_regions.append(Rect2(used.position, used.size))
 set_process(true)

func _process(_delta: float) -> void:
 # Draw between fixed physics ticks rather than only at 60 Hz.
 queue_redraw()

func configure(points: PackedVector2Array, width: float, seed_value: int) -> void:
 route = points
 track_width = width
 _rng.seed = seed_value + 91573
 racers.clear()
 _previous_positions.clear()
 _previous_angles.clear()
 _contact_timers = [0.0, 0.0, 0.0, 0.0]
 if route.size() < 4:
  return
 var segment_lengths: Array[float] = []
 var total := 0.0
 for i in range(route.size()):
  var length := route[i].distance_to(route[(i + 1) % route.size()])
  segment_lengths.append(length)
  total += length
 for i in range(4):
  var offset := (float(i) - 1.5) * minf(110.0, width / 6.0)
  var start_distance := -145.0 - float(i / 2) * 115.0
  racers.append({"id": i, "distance": start_distance, "lap": 0, "speed": 0.0, "base_speed": [590.0, 665.0, 710.0, 760.0][i], "lane": offset, "target_lane": offset, "phase": _rng.randf_range(0.0, TAU), "position": route[0], "angle": 0.0})
 set_meta("segment_lengths", segment_lengths)
 set_meta("route_length", total)
 active = false
 _update_positions()
 _snapshot_positions()
 queue_redraw()

func _snapshot_positions() -> void:
 _previous_positions.clear()
 _previous_angles.clear()
 for racer in racers:
  _previous_positions.append(Vector2(racer["position"]))
  _previous_angles.append(float(racer["angle"]))

func _center_at(distance: float) -> Vector2:
 if route.size() < 4:
  return Vector2.ZERO
 var length: float = float(get_meta("route_length", 1.0))
 var target: float = fposmod(distance, length)
 var segments: Array = get_meta("segment_lengths", [])
 var count: int = route.size()
 for i in range(count):
  var segment: float = float(segments[i])
  if target <= segment or i == count - 1:
   var t: float = clampf(target / maxf(segment, 0.001), 0.0, 1.0)
   var a: Vector2 = route[(i - 1 + count) % count]
   var b: Vector2 = route[i]
   var c: Vector2 = route[(i + 1) % count]
   var d: Vector2 = route[(i + 2) % count]
   # Centripetal-style tangent scaling limits overshoot on unequal segments.
   var prev_len: float = maxf(a.distance_to(b), 1.0)
   var next_len: float = maxf(c.distance_to(d), 1.0)
   var m0: Vector2 = (c - a) * (segment / maxf(prev_len + segment, 1.0))
   var m1: Vector2 = (d - b) * (segment / maxf(segment + next_len, 1.0))
   var t2: float = t * t
   var t3: float = t2 * t
   return b * (2.0 * t3 - 3.0 * t2 + 1.0) + m0 * (t3 - 2.0 * t2 + t) + c * (-2.0 * t3 + 3.0 * t2) + m1 * (t3 - t2)
  target -= segment
 return route[0]

func _point_at(distance: float, lane: float) -> Dictionary:
 var point: Vector2 = _center_at(distance)
 var direction: Vector2 = (_center_at(distance + 12.0) - _center_at(distance - 12.0)).normalized()
 if direction.length_squared() < 0.001:
  direction = Vector2.UP
 return {"point": point + direction.rotated(PI * 0.5) * lane, "tangent": direction}

func _update_positions() -> void:
 for i in range(racers.size()):
  var racer: Dictionary = racers[i]
  var sample := _point_at(float(racer["distance"]), float(racer["lane"]))
  racer["position"] = sample["point"]
  # Average tangents around the ship to avoid abrupt rotation at polyline joints.
  var back: Vector2 = Vector2(_point_at(float(racer["distance"]) - HEADING_LOOKAHEAD, float(racer["lane"]))["point"])
  var front: Vector2 = Vector2(_point_at(float(racer["distance"]) + HEADING_LOOKAHEAD, float(racer["lane"]))["point"])
  var smooth_direction: Vector2 = (front - back).normalized()
  if smooth_direction.length_squared() > 0.001:
   racer["angle"] = smooth_direction.angle() + PI * 0.5
  racers[i] = racer

func step(delta: float) -> void:
 if not active or route.size() < 4:
  return
 _snapshot_positions()
 var total: float = float(get_meta("route_length", 1.0))
 for i in range(racers.size()):
  var racer: Dictionary = racers[i]
  if int(racer["lap"]) >= TOTAL_LAPS:
   continue
  racer["lane"] = move_toward(float(racer["lane"]), float(racer["target_lane"]), LANE_SHIFT_RATE * delta)
  var distance: float = float(racer["distance"])
  var current := _point_at(distance, float(racer["lane"]))
  var ahead := _point_at(distance + 220.0, float(racer["lane"]))
  var turn := absf(Vector2(current["tangent"]).angle_to(Vector2(ahead["tangent"])))
  var corner_factor := clampf(1.0 - turn * 0.68, 0.53, 1.0)
  var rhythm := 0.96 + 0.04 * sin(distance / 380.0 + float(racer["phase"]))
  var target_speed: float = float(racer["base_speed"]) * corner_factor * rhythm
  racer["speed"] = move_toward(float(racer["speed"]), target_speed, 460.0 * delta)
  racer["distance"] = minf(total * float(TOTAL_LAPS), distance + float(racer["speed"]) * delta)
  if float(racer["distance"]) >= total * float(TOTAL_LAPS) and not racer.has("finish_time"):
   racer["finish_time"] = float(get_meta("race_elapsed", 0.0))
  racer["lap"] = mini(TOTAL_LAPS, maxi(0, int(floor(float(racer["distance"]) / total))))
  racers[i] = racer
 _update_positions()
 _resolve_rival_contacts(delta)
 queue_redraw()

# Soft impulse response: NPCs lose speed and shift lanes after contact.
# This remains deterministic and avoids a rigid-body dependency.
func _resolve_rival_contacts(delta: float) -> void:
 for i in range(racers.size()):
  _contact_timers[i] = maxf(0.0, _contact_timers[i] - delta)
  var a: Dictionary = racers[i]
  var half: float = track_width * 0.5 - COLLISION_RADIUS - 12.0
  var lane: float = float(a["lane"])
  if absf(lane) > half:
   a["lane"] = clampf(lane, -half, half)
   a["target_lane"] = float(a["lane"])
   a["speed"] = float(a["speed"]) * (1.0 - WALL_RESTITUTION)
  racers[i] = a
 for i in range(racers.size()):
  for j in range(i + 1, racers.size()):
   var a: Dictionary = racers[i]
   var b: Dictionary = racers[j]
   var offset: Vector2 = Vector2(a["position"]) - Vector2(b["position"])
   if offset.length_squared() >= pow(COLLISION_RADIUS * 2.0, 2.0):
    continue
   if _contact_timers[i] > 0.0 or _contact_timers[j] > 0.0:
    continue
   var lane_push: float = 52.0 if float(a["lane"]) >= float(b["lane"]) else -52.0
   var half: float = track_width * 0.5 - COLLISION_RADIUS - 12.0
   a["target_lane"] = clampf(float(a["target_lane"]) + lane_push, -half, half)
   b["target_lane"] = clampf(float(b["target_lane"]) - lane_push, -half, half)
   a["speed"] = float(a["speed"]) * 0.73
   b["speed"] = float(b["speed"]) * 0.73
   racers[i] = a
   racers[j] = b
   _contact_timers[i] = CONTACT_COOLDOWN
   _contact_timers[j] = CONTACT_COOLDOWN
 _update_positions()

# Called by the player controller after movement. Returns a separation impulse.
func player_contact(player_world: Vector2, player_velocity: Vector2) -> Dictionary:
 var separation := Vector2.ZERO
 var velocity: Vector2 = player_velocity
 for i in range(racers.size()):
  var racer: Dictionary = racers[i]
  var offset: Vector2 = player_world + separation - Vector2(racer["position"])
  var distance: float = offset.length()
  var minimum: float = COLLISION_RADIUS + 45.0
  if distance >= minimum:
   continue
  var normal: Vector2 = offset / distance if distance > 0.01 else Vector2.RIGHT.rotated(float(i))
  separation += normal * (minimum - distance + 0.5)
  if _contact_timers[i] <= 0.0:
   var relative_normal: float = velocity.dot(normal)
   if relative_normal < 0.0:
    velocity -= normal * relative_normal * 1.22
   velocity *= 0.68
   racer["speed"] = float(racer["speed"]) * 0.66
   racer["target_lane"] = clampf(float(racer["target_lane"]) - 35.0 * signf(normal.cross(Vector2.from_angle(float(racer["angle"]) - PI * 0.5))), -track_width * 0.5 + 58.0, track_width * 0.5 - 58.0)
   racers[i] = racer
   _contact_timers[i] = CONTACT_COOLDOWN
 _update_positions()
 return {"push": separation, "velocity": velocity}

func progress_values() -> Array[float]:
 var values: Array[float] = []
 for racer in racers:
  values.append(float(racer["distance"]))
 return values

func positions() -> Array[Vector2]:
 var result: Array[Vector2] = []
 for racer in racers:
  result.append(Vector2(racer["position"]))
 return result

func _draw() -> void:
 var center: Vector2 = viewport_size * 0.5
 var alpha: float = clampf(Engine.get_physics_interpolation_fraction(), 0.0, 1.0)
 for racer in racers:
  var i: int = int(racer["id"])
  var world_position: Vector2 = Vector2(racer["position"])
  var heading: float = float(racer["angle"])
  if i < _previous_positions.size():
   world_position = _previous_positions[i].lerp(world_position, alpha)
   heading = lerp_angle(_previous_angles[i], heading, alpha)
  var screen: Vector2 = world_position - camera_world + center
  if screen.x < -110.0 or screen.y < -110.0 or screen.x > viewport_size.x + 110.0 or screen.y > viewport_size.y + 110.0:
   continue
  var source: Rect2 = _sprite_regions[i] if i < _sprite_regions.size() else Rect2(Vector2.ZERO, ART[i].get_size())
  var visible_size: Vector2 = source.size
  var factor: float = SPRITE_BODY_SIZE / maxf(visible_size.x, visible_size.y)
  var dest_size: Vector2 = visible_size * factor
  draw_set_transform(screen, heading)
  draw_texture_rect_region(ART[i], Rect2(-dest_size * 0.5, dest_size), source)
  draw_set_transform(Vector2.ZERO)
