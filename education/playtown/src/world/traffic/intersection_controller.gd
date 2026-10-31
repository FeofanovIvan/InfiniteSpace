extends Node2D
@export var go_duration: float = 5.0
@export var pedestrian_duration: float = 3.0
@export var max_clearing_duration: float = 12.0
@onready var ns_gate: Area2D = $NSGate
@onready var ew_gate: Area2D = $EWGate
@onready var pedestrian_barrier: StaticBody2D = $PedestrianBarrier
@onready var player_zone: Area2D = $PlayerZone
@onready var lights: Array = [$TrafficLightNW, $TrafficLightNE, $TrafficLightSW, $TrafficLightSE]
@onready var timer: Timer = Timer.new()
var state: String = "ns_go"
var next_car_state: String = "ew_go"
var state_elapsed: float = 0.0
func _ready() -> void:
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	_enter_state("ns_go")
func _enter_state(new_state: String) -> void:
	state = new_state
	state_elapsed = 0.0
	match state:
		"ns_go":
			ns_gate.set_open(true)
			ew_gate.set_open(false)
			_set_pedestrian_go(false)
			timer.start(go_duration)
		"ew_go":
			ew_gate.set_open(true)
			ns_gate.set_open(false)
			_set_pedestrian_go(false)
			timer.start(go_duration)
		"clearing":
			ns_gate.set_open(false)
			ew_gate.set_open(false)
			timer.stop()
		"all_stop":
			_set_pedestrian_go(true)
			timer.start(pedestrian_duration)
		"ped_clearing":
			timer.stop()
func _on_timer_timeout() -> void:
	match state:
		"ns_go":
			next_car_state = "ew_go"
			_enter_state("clearing")
		"ew_go":
			next_car_state = "ns_go"
			_enter_state("clearing")
		"all_stop":
			_enter_state("ped_clearing")
func _process(delta: float) -> void:
	state_elapsed += delta
	match state:
		"clearing":
			if ns_gate.has_cars_inside() or ew_gate.has_cars_inside():
				if state_elapsed >= max_clearing_duration:
					ns_gate.force_clear_occupying_cars()
					ew_gate.force_clear_occupying_cars()
				return
			_enter_state("all_stop")
		"ped_clearing":
			if player_zone and player_zone.player_inside:
				return
			_enter_state(next_car_state)
func _set_pedestrian_go(go: bool) -> void:
	for light in lights:
		if light and light.has_method("set_pedestrian_go"):
			light.set_pedestrian_go(go)
	if pedestrian_barrier:
		for child in pedestrian_barrier.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", go)
