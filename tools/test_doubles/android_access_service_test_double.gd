extends "res://learning/src/core/access_service.gd"

var purchase_gate_count := 0
var review_code_valid := false


func _monetization_runtime_enabled() -> bool:
	return true


func _development_access_enabled() -> bool:
	return false


func _load_state() -> void:
	pass


func _save_state() -> void:
	save_elapsed = 0.0


func _review_code_matches(_code: String) -> bool:
	return review_code_valid


func show_purchase_gate() -> void:
	purchase_gate_count += 1
