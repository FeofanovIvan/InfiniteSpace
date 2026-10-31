extends Area2D
@export var axis: String = "ns"
var is_open: bool = true
var waiting_cars: Array[Node] = []
var occupying_cars: Array[Node] = []
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("cars"):
		return
	if not _matches_axis(body):
		return
	if is_open:
		if not occupying_cars.has(body):
			occupying_cars.append(body)
		return
	if body.has_method("set_axis_can_move"):
		body.set_axis_can_move(false)
	if not waiting_cars.has(body):
		waiting_cars.append(body)
func _on_body_exited(body: Node) -> void:
	occupying_cars.erase(body)
	waiting_cars.erase(body)
func _matches_axis(car: Node) -> bool:
	if not ("direction" in car):
		return false
	var d: Vector2 = car.direction
	if axis == "ns":
		return absf(d.y) >= absf(d.x)
	return absf(d.x) > absf(d.y)
func set_open(value: bool) -> void:
	_prune_tracked_cars()
	is_open = value
	if value:
		for car in waiting_cars:
			if is_instance_valid(car) and car.has_method("set_axis_can_move"):
				car.set_axis_can_move(true)
			if not occupying_cars.has(car):
				occupying_cars.append(car)
		waiting_cars.clear()
func has_cars_inside() -> bool:
	_prune_tracked_cars()
	return occupying_cars.size() > 0
func _prune_tracked_cars() -> void:
	var overlapping := get_overlapping_bodies()
	for index in range(occupying_cars.size() - 1, -1, -1):
		var car := occupying_cars[index]
		if not is_instance_valid(car) or not overlapping.has(car):
			occupying_cars.remove_at(index)
	for index in range(waiting_cars.size() - 1, -1, -1):
		var car := waiting_cars[index]
		if not is_instance_valid(car) or not overlapping.has(car):
			waiting_cars.remove_at(index)
func force_clear_occupying_cars() -> void:
	_prune_tracked_cars()
	for car in occupying_cars.duplicate():
		if is_instance_valid(car) and car.has_method("force_recycle"):
			car.force_recycle()
	occupying_cars.clear()
