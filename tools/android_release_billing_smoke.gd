extends SceneTree
## Deterministic Android monetization state smoke. No store or filesystem writes.

var failures := 0


class MockBillingClient:
	extends BillingClient

	var billing_ready := true
	var purchase_response := {"response_code": BillingResponseCode.OK}
	var purchase_calls: Array[Dictionary] = []
	var acknowledge_tokens: Array[String] = []
	var query_types: Array[int] = []

	func is_ready() -> bool:
		return billing_ready

	func purchase(product_id: String, purchase_option_id: String = "", offer_id: String = "", is_offer_personalized: bool = false) -> Dictionary:
		purchase_calls.append({
			"product_id": product_id,
			"purchase_option_id": purchase_option_id,
			"offer_id": offer_id,
			"personalized": is_offer_personalized,
		})
		return purchase_response.duplicate(true)

	func acknowledge_purchase(purchase_token: String):
		acknowledge_tokens.append(purchase_token)

	func query_purchases(product_type: ProductType, _include_suspended_subs: bool = false) -> void:
		query_types.append(product_type)


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("ANDROID_RELEASE_SMOKE_FAIL: " + message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	_test_billing_state_machine()
	await _test_active_play_timer()
	await _test_parent_purchase_ui()
	print("Android release billing smoke: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(0 if failures == 0 else 1)


func _test_billing_state_machine() -> void:
	var billing_double: Script = load("res://tools/test_doubles/android_billing_service_test_double.gd") as Script
	_check(billing_double != null, "billing test double compiles")
	if billing_double == null:
		return
	var service = billing_double.new()
	root.add_child(service)
	var client := MockBillingClient.new()
	service.add_child(client)
	service.android_client = client
	service.available_products = [{
		"product_id": "full_game_unlock",
		"one_time_purchase_offer_details": [{
			"formatted_price": "R$ 79,90",
			"purchase_option_id": "one_time",
			"offer_id": "",
		}],
	}]

	_check(service.ANDROID_PRODUCT_ID == "full_game_unlock", "one-time product id is exact")
	var info: Dictionary = service.get_full_game_info()
	_check(info.get("formatted_price") == "R$ 79,90", "localized Play price is used")
	_check(service.purchase_full_game(), "purchase flow starts when billing is ready")
	_check(client.purchase_calls.size() == 1, "purchase is called exactly once")
	_check(client.purchase_calls[0].get("product_id") == "full_game_unlock", "purchase uses full_game_unlock")
	_check(client.purchase_calls[0].get("purchase_option_id") == "one_time", "purchase option comes from Play product details")

	var canceled_count := [0]
	service.purchase_canceled.connect(func(): canceled_count[0] += 1)
	service._on_android_purchase_updated({"response_code": BillingClient.BillingResponseCode.USER_CANCELED})
	_check(canceled_count[0] == 1, "canceled purchase is reported without entitlement")

	var pending_count := [0]
	service.purchase_pending.connect(func(): pending_count[0] += 1)
	service.observed_entitlements.clear()
	service._process_android_purchases([{
		"product_ids": PackedStringArray(["full_game_unlock"]),
		"purchase_state": BillingClient.PurchaseState.PENDING,
		"purchase_token": "pending-token",
	}])
	_check(pending_count[0] == 1, "pending purchase is reported")
	_check(service.observed_entitlements.back() == false, "pending purchase never unlocks")
	_check(client.acknowledge_tokens.is_empty(), "pending purchase is not acknowledged")

	service.observed_entitlements.clear()
	service._process_android_purchases([{
		"product_ids": PackedStringArray(["full_game_unlock"]),
		"purchase_state": BillingClient.PurchaseState.PURCHASED,
		"purchase_token": "new-token",
		"is_acknowledged": false,
	}])
	_check(client.acknowledge_tokens == ["new-token"], "completed purchase is acknowledged")
	_check(service.observed_entitlements.back() == false, "access waits for acknowledge confirmation")

	client.query_types.clear()
	service._on_android_acknowledged({"response_code": BillingClient.BillingResponseCode.OK})
	_check(client.query_types == [BillingClient.ProductType.INAPP], "successful acknowledge re-queries INAPP purchases")

	service.observed_entitlements.clear()
	service._process_android_purchases([{
		"product_ids": PackedStringArray(["full_game_unlock"]),
		"purchase_state": BillingClient.PurchaseState.PURCHASED,
		"purchase_token": "owned-token",
		"is_acknowledged": true,
	}])
	_check(service.observed_entitlements.back() == true, "acknowledged purchase grants permanent access")

	service.observed_entitlements.clear()
	service._process_android_purchases([])
	_check(service.observed_entitlements.back() == false, "empty verified purchase list does not grant access")

	client.purchase_response = {"response_code": BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED}
	client.query_types.clear()
	_check(service.purchase_full_game(), "already-owned response starts entitlement restore")
	_check(client.query_types == [BillingClient.ProductType.INAPP], "already-owned response is verified by INAPP query")

	var error_count := [0]
	service.billing_error.connect(func(_code: int, _message: String): error_count[0] += 1)
	service._on_android_connect_error(BillingClient.BillingResponseCode.NETWORK_ERROR, "offline")
	_check(error_count[0] == 1 and service.get_last_error_message() == "offline", "offline/store error is surfaced without unlocking")

	service.queue_free()


func _test_active_play_timer() -> void:
	var access_double: Script = load("res://tools/test_doubles/android_access_service_test_double.gd") as Script
	_check(access_double != null, "access test double compiles")
	if access_double == null:
		return
	var access = access_double.new()
	root.add_child(access)
	await process_frame
	_check(access.PREVIEW_DURATION_SECONDS == 600.0, "free active-play limit is 600 seconds")
	_check(access.preview_started, "Android release timer starts once")

	access.preview_elapsed_seconds = 598.0
	access.app_active = true
	paused = false
	access._process(1.0)
	_check(access.preview_elapsed_seconds == 599.0 and access.purchase_gate_count == 0, "active time advances before expiry")
	access._process(1.0)
	_check(access.preview_elapsed_seconds == 600.0 and access.purchase_gate_count == 1, "gate opens exactly at ten active minutes")

	access.preview_elapsed_seconds = 100.0
	access.expiration_emitted = false
	access.app_active = false
	access._process(10.0)
	_check(access.preview_elapsed_seconds == 100.0, "background/inactive time is not counted")
	access.app_active = true
	paused = true
	access._process(10.0)
	paused = false
	_check(access.preview_elapsed_seconds == 100.0, "paused/system-menu time is not counted")

	access.set_full_game_owned(true)
	access._process(10.0)
	_check(access.preview_elapsed_seconds == 100.0 and access.has_access(), "owned full game permanently disables the timer")
	access.set_full_game_owned(false)
	access.review_code_valid = false
	_check(not access.activate_reviewer_access("wrong-code"), "invalid reviewer code never unlocks")
	_check(not access.reviewer_access_active and not access.full_game_owned, "failed review access does not change purchase state")
	access.review_code_valid = true
	_check(access.activate_reviewer_access("test-only-code"), "valid reviewer code unlocks the current session")
	_check(access.has_access() and access.reviewer_access_active, "reviewer session grants full access")
	_check(not access.full_game_owned, "reviewer access never impersonates a purchase")
	access.queue_free()
	await process_frame


func _test_parent_purchase_ui() -> void:
	var billing_service: Node = root.get_node("BillingService")
	var language_service: Node = root.get_node("LanguageService")
	var language_script: Script = load("res://learning/src/core/localization/language_service.gd") as Script
	var previous_products: Array = billing_service.get("available_products").duplicate(true)
	billing_service.set("available_products", [{
		"product_id": "full_game_unlock",
		"one_time_purchase_offer_details": [{"formatted_price": "€14,49"}],
	}])
	var overlay_script: Script = load("res://learning/src/screens/subscription_overlay.gd") as Script
	_check(overlay_script != null, "parent purchase UI compiles")
	if overlay_script == null:
		return
	var overlay = overlay_script.new()
	overlay.set_locked(true)
	overlay.set_show_expiration_notice(true)
	root.add_child(overlay)
	await process_frame
	var labels := _collect_control_text(overlay)
	_check(labels.has(language_service.call("get_ui_text", "preview_complete_title")), "gate shows Continue the adventure title")
	_check(labels.has(language_service.call("get_ui_text", "for_parents")), "gate has explicit For parents action")
	_check(labels.has(language_service.call("get_ui_text", "restore_purchases")), "gate offers purchase restore before payment")

	overlay._show_adult_gate()
	await process_frame
	_check(is_instance_valid(overlay.answer_input), "parent section uses a numeric challenge")
	overlay.answer_input.text = str(overlay.challenge_answer)
	overlay._verify_answer()
	overlay._on_products_updated(billing_service.get("available_products"))
	await process_frame
	_check(is_instance_valid(overlay.purchase_button), "purchase button appears only after parent challenge")
	_check("€14,49" in overlay.purchase_button.text, "purchase button displays the localized Play price")
	_check(not overlay.purchase_button.disabled, "confirmed product enables the explicit purchase button")
	overlay._show_reviewer_access()
	await process_frame
	_check(is_instance_valid(overlay.review_code_input), "purchase screen exposes the documented reviewer-code entry")

	for locale in ["ru", "en", "pt", "es", "de", "fr"]:
		_check(not str(language_script.UI_TEXT["full_game_title"].get(locale, "")).is_empty(), "purchase UI localized: " + locale)

	overlay.queue_free()
	billing_service.set("available_products", previous_products)
	await process_frame


func _collect_control_text(node: Node) -> Array[String]:
	var values: Array[String] = []
	if node is Label or node is Button:
		values.append(str(node.get("text")))
	for child in node.get_children():
		values.append_array(_collect_control_text(child))
	return values
