extends Node

signal preview_time_changed(remaining_seconds: int)
signal preview_expired
signal preview_pet_access_changed(available: bool)

const SubscriptionOverlay := preload("res://education/playtown/src/screens/subscription_overlay.gd")
const PREVIEW_DURATION_SECONDS := 300.0
const SAVE_INTERVAL_SECONDS := 5.0
const SAVE_PATH := "user://miko_playtown_access_state.cfg"
## Local/editor and debug exports stay fully unlocked for development.
## Release exports still use PREVIEW_DURATION_SECONDS and subscriptions.
const DEVELOPMENT_ACCESS_BYPASS := true

var preview_started := false
var preview_elapsed_seconds := 0.0
var subscription_active := false
var app_active := true
var save_elapsed := 0.0
var last_reported_seconds := -1
var expiration_emitted := false
var subscription_gate: CanvasLayer

func _ready() -> void:
	pass

func _process(delta: float) -> void:
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
		show_subscription_gate()

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
	if preview_started or subscription_active or is_preview_expired():
		return
	preview_started = true
	GameState.begin_preview_coins()
	_save_state()

func has_access() -> bool:
	return _development_access_enabled() or subscription_active or not is_preview_expired()

func is_preview_active() -> bool:
	if _development_access_enabled():
		return false
	return preview_started and not subscription_active and not is_preview_expired()

func is_preview_expired() -> bool:
	if _development_access_enabled():
		return false
	return preview_elapsed_seconds >= PREVIEW_DURATION_SECONDS

func has_preview_pet_access() -> bool:
	if _development_access_enabled():
		return not subscription_active
	return not subscription_active and not is_preview_expired()

func get_remaining_preview_seconds() -> int:
	if _development_access_enabled():
		return int(PREVIEW_DURATION_SECONDS)
	return maxi(0, ceili(PREVIEW_DURATION_SECONDS - preview_elapsed_seconds))

func set_subscription_active(value: bool) -> void:
	var pet_was_available := has_preview_pet_access()
	subscription_active = value
	if value:
		GameState.clear_preview_coins()
	_save_state()
	var pet_is_available := has_preview_pet_access()
	if pet_was_available != pet_is_available:
		preview_pet_access_changed.emit(pet_is_available)
	if value and is_instance_valid(subscription_gate):
		subscription_gate.queue_free()
		subscription_gate = null

func show_subscription_gate() -> void:
	if _development_access_enabled():
		if is_instance_valid(subscription_gate):
			subscription_gate.queue_free()
			subscription_gate = null
		return
	if subscription_active or is_instance_valid(subscription_gate):
		return
	subscription_gate = SubscriptionOverlay.new()
	subscription_gate.set_locked(true)
	subscription_gate.set_show_expiration_notice(true)
	subscription_gate.tree_exited.connect(func(): subscription_gate = null)
	get_tree().root.add_child(subscription_gate)

func _should_count_time() -> bool:
	return not _development_access_enabled() and preview_started and app_active and not get_tree().paused \
		and not subscription_active and not is_preview_expired()

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
	expiration_emitted = is_preview_expired()
