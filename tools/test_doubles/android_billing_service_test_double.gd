extends "res://learning/src/core/billing_service.gd"

var observed_entitlements: Array[bool] = []


func _android_runtime_enabled() -> bool:
	return true


func _set_entitlement(active: bool) -> void:
	entitlement_active = active
	observed_entitlements.append(active)
