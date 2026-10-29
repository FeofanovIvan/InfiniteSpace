extends Node2D
## Player's screen-space hyperjump visuals. Shares EXACT draw calls with NPCs.
## Draw this node with z_index below the ship so the trail stays behind it.
const NpcJumpVisual = preload("res://scripts/NpcJumpVisual.gd")
const TRAIL_COLOR: Color = Color(0.97, 0.98, 1.0)

var _mode: String = "idle"
var _progress: float = 0.0
var _screen: Vector2 = Vector2.ZERO
var _angle: float = 0.0
var _clouds: Array[Dictionary] = []
var _random: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_random.seed = 94713
	set_process(false)

func show_charge(p: float, screen: Vector2) -> void:
	_mode = "charge"
	_progress = clampf(p, 0.0, 1.0)
	_screen = screen
	set_process(true)
	queue_redraw()

func show_dash(p: float, screen: Vector2, heading: float) -> void:
	_mode = "dash"
	_progress = clampf(p, 0.0, 1.0)
	_screen = screen
	_angle = heading
	set_process(true)
	queue_redraw()

func spawn_cloud(screen: Vector2) -> void:
	_clouds.append({"screen": screen, "life": 1.0, "phase": _random.randf_range(0.0, TAU)})
	set_process(true)
	queue_redraw()

func clear_effect() -> void:
	_mode = "idle"
	_progress = 0.0
	_clouds.clear()
	set_process(false)
	queue_redraw()

func end_jump() -> void:
	_mode = "idle"
	if _clouds.is_empty():
		set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	for i in range(_clouds.size() - 1, -1, -1):
		_clouds[i]["life"] = float(_clouds[i]["life"]) - delta
		if float(_clouds[i]["life"]) <= 0.0:
			_clouds.remove_at(i)
	if _mode == "idle" and _clouds.is_empty():
		set_process(false)
	queue_redraw()

func _draw() -> void:
	for cloud in _clouds:
		NpcJumpVisual.draw_jump_cloud(self, cloud["screen"], float(cloud["life"]), TRAIL_COLOR, float(cloud["phase"]))
	if _mode == "charge":
		NpcJumpVisual.draw_charge(self, _screen, _progress, TRAIL_COLOR)
	elif _mode == "dash":
		NpcJumpVisual.draw_dash(self, _screen, _angle, _progress, TRAIL_COLOR)
