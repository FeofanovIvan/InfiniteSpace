extends RefCounted
## World address stored as an integer sector and a small fractional position.
## The screen ship remains fixed, but this address tracks real navigation.
## Keeping local coordinates small avoids float drift during very long flights.

const SECTOR_SIZE: float = 512.0
var sector: Vector2i = Vector2i.ZERO
var local: Vector2 = Vector2.ZERO


func advance(delta_units: Vector2) -> void:
	local += delta_units
	_normalize()


func copy_from(other) -> void:
	sector = other.sector
	local = other.local


func _normalize() -> void:
	var cross_x: int = floori(local.x / SECTOR_SIZE)
	var cross_y: int = floori(local.y / SECTOR_SIZE)
	sector += Vector2i(cross_x, cross_y)
	local -= Vector2(cross_x, cross_y) * SECTOR_SIZE


func displacement_from(other) -> Vector2:
	return Vector2(sector - other.sector) * SECTOR_SIZE + local - other.local


func as_dictionary() -> Dictionary:
	return {
		"sector_x": sector.x,
		"sector_y": sector.y,
		"local_x": snappedf(local.x, 0.01),
		"local_y": snappedf(local.y, 0.01)
	}
