extends Node

signal store_ready
signal products_updated(products: Array)
signal entitlement_changed(active: bool)
signal purchase_pending
signal purchase_canceled
signal billing_error(code: int, message: String)

## Permanent, non-consumable unlock. The price is configured in the stores.
const ANDROID_PRODUCT_ID := "full_game_unlock"
const IOS_PRODUCTS := {
	"monthly": "com.feofanova.safecity.premium.monthly",
	"quarterly": "com.feofanova.safecity.premium.quarterly",
	"annual": "com.feofanova.safecity.premium.annual",
}

var android_client: BillingClient
var ios_store: Object
var available_products: Array = []
var entitlement_active := false
var _ios_product_queue: Array[String] = []
var _ios_current_product := ""
var _ios_entitlement_seen := false
var last_error_message := ""

func _ready() -> void:
	# This release changes Android monetization only. Keep the existing iOS
	# subscription flow dormant, as it was before this Android release work.
	if _android_runtime_enabled():
		_start_android_billing()

func refresh() -> void:
	last_error_message = ""
	if android_client != null and android_client.is_ready():
		android_client.query_product_details(
			PackedStringArray([ANDROID_PRODUCT_ID]),
			BillingClient.ProductType.INAPP
		)
		android_client.query_purchases(BillingClient.ProductType.INAPP)
	elif ios_store != null:
		_refresh_ios_products()

func retry_store_connection() -> void:
	last_error_message = ""
	if OS.get_name() == "iOS":
		_ios_current_product = ""
		_refresh_ios_products()
	elif android_client != null and not android_client.is_ready():
		android_client.start_connection()
	else:
		refresh()

func get_last_error_message() -> String:
	return last_error_message

func purchase_full_game() -> bool:
	if not _android_runtime_enabled() or android_client == null or not android_client.is_ready():
		return false
	var info := get_full_game_info()
	var result := android_client.purchase(
		ANDROID_PRODUCT_ID,
		str(info.get("purchase_option_id", "")),
		str(info.get("offer_id", "")),
		false
	)
	var code := int(result.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
		android_client.query_purchases(BillingClient.ProductType.INAPP)
		return true
	if code != BillingClient.BillingResponseCode.OK:
		_report_error(code, str(result.get("debug_message", "")))
		return false
	return true

func purchase_plan(plan_id: String, _offer_id: String = "") -> bool:
	# Preserve the pre-existing iOS subscription products. Android never calls
	# this method in the one-time-purchase release.
	if OS.get_name() != "iOS" or ios_store == null or not IOS_PRODUCTS.has(plan_id):
		return false
	ios_store.call("purchase_product", str(IOS_PRODUCTS[plan_id]), 1)
	return true

func restore_purchases() -> void:
	if android_client != null and android_client.is_ready():
		android_client.query_purchases(BillingClient.ProductType.INAPP)
	elif ios_store != null:
		ios_store.call("sync")

func open_subscription_management() -> void:
	if OS.get_name() == "iOS":
		OS.shell_open("https://apps.apple.com/account/subscriptions")

func get_products() -> Array:
	return available_products.duplicate(true)

func get_full_game_info() -> Dictionary:
	if available_products.is_empty():
		return {}
	var product = available_products[0]
	if not product is Dictionary:
		return {}
	var result := {
		"formatted_price": str(product.get("formatted_price", product.get("localized_price", ""))),
		"purchase_option_id": "",
		"offer_id": "",
	}
	var offers = product.get("one_time_purchase_offer_details", [])
	if offers is Dictionary:
		offers = [offers]
	if offers is Array and not offers.is_empty() and offers[0] is Dictionary:
		var offer: Dictionary = offers[0]
		result["formatted_price"] = str(offer.get("formatted_price", result["formatted_price"]))
		result["purchase_option_id"] = str(offer.get("purchase_option_id", ""))
		result["offer_id"] = str(offer.get("offer_id", ""))
	return result

func get_plan_info(plan_id: String) -> Dictionary:
	if OS.get_name() != "iOS":
		return {}
	for product in available_products:
		if product is Dictionary and str(product.get("plan_id", "")) == plan_id:
			return product.duplicate(true)
	return {}

func is_store_available() -> bool:
	if OS.get_name() == "iOS":
		return ios_store != null
	return android_client != null and android_client.is_ready()

func _start_ios_billing() -> void:
	if not ClassDB.class_exists("GodotStoreKit2"):
		_report_error(-1, "StoreKit 2 plugin is unavailable in this build")
		return
	ios_store = ClassDB.instantiate("GodotStoreKit2")
	if ios_store == null:
		_report_error(-1, "StoreKit 2 could not be initialized")
		return
	ios_store.connect("product_info_received", _on_ios_product_info)
	ios_store.connect("transaction_state_changed", _on_ios_transaction_state_changed)
	ios_store.connect("synchronized", _on_ios_synchronized)
	store_ready.emit()
	_refresh_ios_products()

func _refresh_ios_products() -> void:
	if ios_store == null or not _ios_current_product.is_empty():
		return
	available_products.clear()
	_ios_product_queue.clear()
	for product_id in IOS_PRODUCTS.values():
		_ios_product_queue.append(str(product_id))
	_ios_entitlement_seen = false
	_request_next_ios_product()

func _request_next_ios_product() -> void:
	if ios_store == null:
		return
	if _ios_product_queue.is_empty():
		_set_entitlement(_ios_entitlement_seen)
		products_updated.emit(get_products())
		return
	_ios_current_product = _ios_product_queue.pop_front()
	ios_store.call("request_product_info", _ios_current_product)

func _on_ios_product_info(info: Dictionary) -> void:
	var requested_id := _ios_current_product
	_ios_current_product = ""
	var error := str(info.get("error", ""))
	if error.is_empty():
		var product_id := str(info.get("product_id", requested_id))
		var plan_id := _ios_plan_for_product(product_id)
		if not plan_id.is_empty():
			var product := info.duplicate(true)
			product["plan_id"] = plan_id
			product["formatted_price"] = str(info.get("localized_price", ""))
			product["has_free_trial"] = true
			product["trial_period"] = "P1W"
			available_products.append(product)
			_ios_entitlement_seen = _ios_entitlement_seen or bool(info.get("is_purchased", false))
	else:
		_report_error(-1, error)
	_request_next_ios_product()

func _on_ios_transaction_state_changed(transaction: Dictionary) -> void:
	var error := str(transaction.get("error", ""))
	if not error.is_empty():
		_report_error(-1, error)
		return
	var state := int(transaction.get("transaction_state", 0))
	match state:
		2, 3:
			purchase_pending.emit()
		4, 5:
			_set_entitlement(true)
			_refresh_ios_products()
		1, 6:
			_refresh_ios_products()
		0:
			_report_error(-1, "The purchase could not be completed")

func _on_ios_synchronized(error: String) -> void:
	if not error.is_empty():
		_report_error(-1, error)
		return
	_refresh_ios_products()

func _ios_plan_for_product(product_id: String) -> String:
	for plan_id in IOS_PRODUCTS:
		if str(IOS_PRODUCTS[plan_id]) == product_id:
			return str(plan_id)
	return ""

func _start_android_billing() -> void:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		_report_error(-1, "Google Play Billing plugin is unavailable in this build")
		return
	android_client = BillingClient.new()
	add_child(android_client)
	android_client.connected.connect(_on_android_connected)
	android_client.connect_error.connect(_on_android_connect_error)
	android_client.disconnected.connect(_on_android_disconnected)
	android_client.query_product_details_response.connect(_on_android_products)
	android_client.query_purchases_response.connect(_on_android_purchases)
	android_client.on_purchase_updated.connect(_on_android_purchase_updated)
	android_client.acknowledge_purchase_response.connect(_on_android_acknowledged)
	android_client.start_connection()

func _on_android_connected() -> void:
	store_ready.emit()
	refresh()

func _on_android_connect_error(code: int, message: String) -> void:
	_report_error(code, message)

func _on_android_disconnected() -> void:
	_report_error(BillingClient.BillingResponseCode.SERVICE_DISCONNECTED, "Google Play Billing disconnected")

func _on_android_products(response: Dictionary) -> void:
	var code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		_report_error(code, str(response.get("debug_message", "")))
		return
	available_products = response.get("product_details", [])
	if available_products.is_empty():
		_report_error(BillingClient.BillingResponseCode.ITEM_UNAVAILABLE, "full_game_unlock is unavailable")
		return
	products_updated.emit(get_products())

func _on_android_purchases(response: Dictionary) -> void:
	var code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		_report_error(code, str(response.get("debug_message", "")))
		return
	_process_android_purchases(response.get("purchases", []))

func _on_android_purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code == BillingClient.BillingResponseCode.USER_CANCELED:
		purchase_canceled.emit()
		return
	if code != BillingClient.BillingResponseCode.OK:
		_report_error(code, str(response.get("debug_message", "")))
		return
	_process_android_purchases(response.get("purchases", []))

func _process_android_purchases(purchases: Array) -> void:
	var owned := false
	for purchase in purchases:
		if not purchase is Dictionary:
			continue
		var product_ids: PackedStringArray = purchase.get("product_ids", PackedStringArray())
		if ANDROID_PRODUCT_ID not in product_ids:
			continue
		var state := int(purchase.get("purchase_state", BillingClient.PurchaseState.UNSPECIFIED_STATE))
		if state == BillingClient.PurchaseState.PENDING:
			purchase_pending.emit()
			continue
		if state != BillingClient.PurchaseState.PURCHASED:
			continue
		if bool(purchase.get("is_acknowledged", false)):
			owned = true
		else:
			var purchase_token := str(purchase.get("purchase_token", ""))
			if purchase_token.is_empty():
				_report_error(BillingClient.BillingResponseCode.ERROR, "Purchased item has no purchase token")
			else:
				android_client.acknowledge_purchase(purchase_token)
	_set_entitlement(owned)

func _on_android_acknowledged(response: Dictionary) -> void:
	var code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		_report_error(code, str(response.get("debug_message", "")))
		return
	# Re-query and grant access only after Google Play confirms acknowledge.
	android_client.query_purchases(BillingClient.ProductType.INAPP)

func _set_entitlement(active: bool) -> void:
	var changed := entitlement_active != active
	entitlement_active = active
	if OS.get_name() == "Android":
		AccessService.set_full_game_owned(active)
	elif OS.get_name() == "iOS":
		AccessService.set_subscription_active(active)
	if changed:
		entitlement_changed.emit(active)

func _report_error(code: int, message: String) -> void:
	last_error_message = message
	billing_error.emit(code, message)

func _android_runtime_enabled() -> bool:
	return OS.get_name() == "Android"
