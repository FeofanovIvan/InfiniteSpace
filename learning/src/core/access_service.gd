extends Node

signal preview_time_changed(remaining_seconds: int)
signal preview_expired
signal preview_pet_access_changed(available: bool)

const SubscriptionOverlay := preload("res://learning/src/screens/subscription_overlay.gd")
const PREVIEW_DURATION_SECONDS := 600.0
const SAVE_INTERVAL_SECONDS := 5.0
const SAVE_PATH := "user://miko_playtown_access_state.cfg"
const REVIEW_ACCESS_CODE_SHA256 := "447ee48406d10d239ed8a91c355ad22cf3e353d044bab257f8009a00d19e066a"
## Local/editor and debug exports stay fully unlocked for development.
## Release exports use PREVIEW_DURATION_SECONDS and a permanent full-game unlock.
const DEVELOPMENT_ACCESS_BYPASS := true

var preview_started := false
var preview_elapsed_seconds := 0.0
var full_game_owned := false
var subscription_active := false
## Google Play review access is deliberately session-only and is never persisted
## as a purchase. A restart always returns to the verified store entitlement.
var reviewer_access_active := false
var app_active := true
var save_elapsed := 0.0
var last_reported_seconds := -1
var expiration_emitted := false
var subscription_gate: CanvasLayer

func _ready() -> void:
	if not _monetization_runtime_enabled():
		return
	_load_state()
	if _development_access_enabled():
		return
	if full_game_owned:
		return
	if is_preview_expired():
		call_deferred("show_purchase_gate")
	else:
		start_preview()

func _process(delta: float) -> void:
	if not _monetization_runtime_enabled():
		return
	if _development_access_enabled():
		return
	if not _should_count_time():
		return
	preview_elapsed_seconds = minf(PREVIEW_DURATION_SECONDS, preview_elapsed_seconds + delta)
	save_elapsed += delta
	_update_reported_time()
	if save_elapsed >= SAVE_INTERVAL_SECONDS:
		_save_state()
	if is_preview_expired() and not expiration_emitted:
		expiration_emitted = true
		GameState.clear_preview_coins()
		_save_state()
		preview_expired.emit()
		preview_pet_access_changed.emit(false)
		show_purchase_gate()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		app_active = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		app_active = false
		_save_state()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_state()

func start_preview() -> void:
	if _development_access_enabled():
		return
	if preview_started or _entitlement_active() or is_preview_expired():
		return
	preview_started = true
	GameState.begin_preview_coins()
	_save_state()

func has_access() -> bool:
	return _development_access_enabled() or _entitlement_active() or not is_preview_expired()

func is_preview_active() -> bool:
	if _development_access_enabled():
		return false
	return preview_started and not _entitlement_active() and not is_preview_expired()

func is_preview_expired() -> bool:
	if _development_access_enabled():
		return false
	return preview_elapsed_seconds >= PREVIEW_DURATION_SECONDS

func has_preview_pet_access() -> bool:
	if _development_access_enabled():
		return not _entitlement_active()
	return not _entitlement_active() and not is_preview_expired()

func get_remaining_preview_seconds() -> int:
	if _development_access_enabled():
		return int(PREVIEW_DURATION_SECONDS)
	return maxi(0, ceili(PREVIEW_DURATION_SECONDS - preview_elapsed_seconds))

func set_full_game_owned(value: bool) -> void:
	var pet_was_available := has_preview_pet_access()
	full_game_owned = value
	if value:
		GameState.clear_preview_coins()
	_save_state()
	var pet_is_available := has_preview_pet_access()
	if pet_was_available != pet_is_available:
		preview_pet_access_changed.emit(pet_is_available)
	if value and is_instance_valid(subscription_gate):
		subscription_gate.queue_free()
		subscription_gate = null

func set_subscription_active(value: bool) -> void:
	# Compatibility for the untouched iOS subscription implementation.
	var pet_was_available := has_preview_pet_access()
	subscription_active = value
	if value:
		GameState.clear_preview_coins()
	var pet_is_available := has_preview_pet_access()
	if pet_was_available != pet_is_available:
		preview_pet_access_changed.emit(pet_is_available)
	if value and is_instance_valid(subscription_gate):
		subscription_gate.queue_free()
		subscription_gate = null

func activate_reviewer_access(code: String) -> bool:
	if not _monetization_runtime_enabled() or not _review_code_matches(code):
		return false
	reviewer_access_active = true
	GameState.clear_preview_coins()
	if is_instance_valid(subscription_gate):
		subscription_gate.queue_free()
		subscription_gate = null
	return true

func _review_code_matches(code: String) -> bool:
	return code.strip_edges().sha256_text() == REVIEW_ACCESS_CODE_SHA256

func show_purchase_gate() -> void:
	if not _monetization_runtime_enabled():
		return
	if _development_access_enabled():
		if is_instance_valid(subscription_gate):
			subscription_gate.queue_free()
			subscription_gate = null
		return
	_show_purchase_overlay(true, true)

func show_purchase_options() -> void:
	if not _monetization_runtime_enabled() or _development_access_enabled():
		return
	_show_purchase_overlay(false, false)

func _show_purchase_overlay(is_locked: bool, show_notice: bool) -> void:
	if _entitlement_active() or is_instance_valid(subscription_gate):
		return
	subscription_gate = SubscriptionOverlay.new()
	subscription_gate.set_locked(is_locked)
	subscription_gate.set_show_expiration_notice(show_notice)
	subscription_gate.tree_exited.connect(func(): subscription_gate = null)
	get_tree().root.add_child(subscription_gate)

func _should_count_time() -> bool:
	return not _development_access_enabled() and preview_started and app_active and not get_tree().paused \
		and not _entitlement_active() and not is_preview_expired()

func _entitlement_active() -> bool:
	return full_game_owned or subscription_active or reviewer_access_active

func _monetization_runtime_enabled() -> bool:
	return OS.get_name() == "Android"

func _development_access_enabled() -> bool:
	return DEVELOPMENT_ACCESS_BYPASS and OS.is_debug_build()

func _update_reported_time() -> void:
	var remaining := get_remaining_preview_seconds()
	if remaining == last_reported_seconds:
		return
	last_reported_seconds = remaining
	preview_time_changed.emit(remaining)

func _save_state() -> void:
	save_elapsed = 0.0
	var cfg := ConfigFile.new()
	cfg.set_value("preview", "started", preview_started)
	cfg.set_value("preview", "elapsed_seconds", preview_elapsed_seconds)
	cfg.set_value("purchase", "full_game_owned", full_game_owned)
	cfg.save(SAVE_PATH)

func _load_state() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	preview_started = bool(cfg.get_value("preview", "started", false))
	preview_elapsed_seconds = clampf(
		float(cfg.get_value("preview", "elapsed_seconds", 0.0)),
		0.0,
		PREVIEW_DURATION_SECONDS
	)
	full_game_owned = bool(cfg.get_value("purchase", "full_game_owned", false))
	expiration_emitted = is_preview_expired()
