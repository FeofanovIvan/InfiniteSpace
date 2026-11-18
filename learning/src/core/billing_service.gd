extends Node

signal store_ready
signal products_updated(products: Array)
signal entitlement_changed(active: bool)
signal purchase_pending
signal billing_error(code: int, message: String)

const ANDROID_PRODUCT_ID := "premium_access"
const ANDROID_BASE_PLANS := {
	"monthly": "monthly",
	"quarterly": "quarterly",
	"annual": "annual",
}
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
	pass

func refresh() -> void:
	last_error_message = ""
	if android_client != null and android_client.is_ready():
		android_client.query_product_details(
			PackedStringArray([ANDROID_PRODUCT_ID]),
			BillingClient.ProductType.SUBS
		)
		android_client.query_purchases(BillingClient.ProductType.SUBS, true)
	elif ios_store != null:
		_refresh_ios_products()

func retry_store_connection() -> void:
	last_error_message = ""
	if OS.get_name() == "iOS":
		_ios_current_product = ""
		_refresh_ios_products()
	else:
		refresh()

func get_last_error_message() -> String:
	return last_error_message

func purchase_plan(plan_id: String, offer_id: String = "") -> bool:
	if OS.get_name() == "iOS":
		if ios_store == null or not IOS_PRODUCTS.has(plan_id):
			return false
		ios_store.call("purchase_product", str(IOS_PRODUCTS[plan_id]), 1)
		return true
	if android_client == null or not android_client.is_ready():
		return false
	if not ANDROID_BASE_PLANS.has(plan_id):
		return false
	if offer_id.is_empty():
		offer_id = str(get_plan_info(plan_id).get("offer_id", ""))
	var result := android_client.purchase_subscription(
		ANDROID_PRODUCT_ID,
		str(ANDROID_BASE_PLANS[plan_id]),
		offer_id,
		false
	)
	if int(result.get("response_code", BillingClient.BillingResponseCode.ERROR)) != BillingClient.BillingResponseCode.OK:
		billing_error.emit(
			int(result.get("response_code", BillingClient.BillingResponseCode.ERROR)),
			str(result.get("debug_message", ""))
		)
		return false
	return true

func restore_purchases() -> void:
	if android_client != null and android_client.is_ready():
		android_client.query_purchases(BillingClient.ProductType.SUBS, true)
	elif ios_store != null:
		ios_store.call("sync")

func open_subscription_management() -> void:
	if android_client != null:
		android_client.open_subscriptions_page(ANDROID_PRODUCT_ID)
	elif OS.get_name() == "iOS":
		OS.shell_open("https://apps.apple.com/account/subscriptions")

func get_products() -> Array:
	return available_products.duplicate(true)

func get_plan_info(plan_id: String) -> Dictionary:
	if OS.get_name() == "iOS":
		for product in available_products:
			if product is Dictionary and str(product.get("plan_id", "")) == plan_id:
				return product.duplicate(true)
		return {}
	if not ANDROID_BASE_PLANS.has(plan_id):
		return {}
	var base_plan_id := str(ANDROID_BASE_PLANS[plan_id])
	var regular_offer: Dictionary = {}
	var trial_offer: Dictionary = {}
	for product in available_products:
		if not product is Dictionary:
			continue
		var offers = product.get("subscription_offer_details", [])
		if not offers is Array:
			continue
		for offer in offers:
			if not offer is Dictionary or str(offer.get("base_plan_id", "")) != base_plan_id:
				continue
			var has_trial := false
			var offer_phases = offer.get("pricing_phases", [])
			if not offer_phases is Array:
				continue
			for phase in offer_phases:
				if phase is Dictionary and int(phase.get("price_amount_micros", -1)) == 0:
					has_trial = true
			if has_trial:
				trial_offer = offer
			elif str(offer.get("offer_id", "")).is_empty():
				regular_offer = offer
	var selected := trial_offer if not trial_offer.is_empty() else regular_offer
	if selected.is_empty():
		return {}
	var result := {
		"offer_id": str(selected.get("offer_id", "")),
		"has_free_trial": not trial_offer.is_empty(),
	}
	var phases: Array = selected.get("pricing_phases", [])
	for phase in phases:
		if phase is Dictionary and int(phase.get("price_amount_micros", -1)) == 0:
			result["trial_period"] = str(phase.get("billing_period", ""))
			break
	for index in range(phases.size() - 1, -1, -1):
		var phase = phases[index]
		if phase is Dictionary and int(phase.get("price_amount_micros", 0)) > 0:
			result["formatted_price"] = str(phase.get("formatted_price", ""))
			result["billing_period"] = str(phase.get("billing_period", ""))
			break
	return result

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
	billing_error.emit(code, message)

func _on_android_disconnected() -> void:
	pass

func _on_android_products(response: Dictionary) -> void:
	var code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		billing_error.emit(code, str(response.get("debug_message", "")))
		return
	available_products = response.get("product_details", [])
	products_updated.emit(get_products())

func _on_android_purchases(response: Dictionary) -> void:
	var code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		billing_error.emit(code, str(response.get("debug_message", "")))
		return
	_process_android_purchases(response.get("purchases", []))

func _on_android_purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code == BillingClient.BillingResponseCode.USER_CANCELED:
		return
	if code != BillingClient.BillingResponseCode.OK:
		billing_error.emit(code, str(response.get("debug_message", "")))
		return
	_process_android_purchases(response.get("purchases", []))

func _process_android_purchases(purchases: Array) -> void:
	var active := false
	for purchase in purchases:
		var product_ids: PackedStringArray = purchase.get("product_ids", PackedStringArray())
		if ANDROID_PRODUCT_ID not in product_ids:
			continue
		var state := int(purchase.get("purchase_state", BillingClient.PurchaseState.UNSPECIFIED_STATE))
		if state == BillingClient.PurchaseState.PENDING:
			purchase_pending.emit()
			continue
		if state != BillingClient.PurchaseState.PURCHASED:
			continue
		if bool(purchase.get("is_suspended", false)):
			continue
		active = true
		if not bool(purchase.get("is_acknowledged", false)):
			android_client.acknowledge_purchase(str(purchase.get("purchase_token", "")))
	_set_entitlement(active)

func _on_android_acknowledged(response: Dictionary) -> void:
	var code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if code != BillingClient.BillingResponseCode.OK:
		billing_error.emit(code, str(response.get("debug_message", "")))

func _set_entitlement(active: bool) -> void:
	if entitlement_active == active:
		return
	entitlement_active = active
	AccessService.set_subscription_active(active)
	entitlement_changed.emit(active)

func _report_error(code: int, message: String) -> void:
	last_error_message = message
	billing_error.emit(code, message)
