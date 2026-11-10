extends Button
## MIKA_FUEL_EMPTY_SIMULATOR_V122
## MIKA_FUEL_EMPTY_SIMULATOR_V122_1_CLICK_AND_ART_FIX
## A non-modal reuse of the SAME approved card as Bubble's flight reminder.
## Only our existing helmet art/text are different. No image generation/UI restyle.
signal simulator_requested

const CARD_SCRIPT: Script = preload("res://simulator_ui/scripts/approved_simulator_card.gd")
const HELMET_IMAGE: String = "res://addons/mika_fuel_empty_simulator/assets/simulator_helmet_original.png"
const TITLES: Dictionary = {
	"ru": "Симулятор",
	"en": "Simulator",
	"fr": "Simulateur",
	"de": "Simulator",
	"es": "Simulador",
	"pt_BR": "Simulador"
}

var _host: Node2D
var _card: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	text = ""
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	pressed.connect(_on_pressed)
	_card = CARD_SCRIPT.new() as Control
	if _card == null:
		push_error("Fuel simulator reminder: approved simulator card is unavailable")
		return
	_card.name = "SameApprovedSimulatorPortraitCard"
	_card.set("card_subtitle", "")
	_card.set("card_description", "")
	_card.set("image_fit_mode", "contain")
	_card.set("image_path", HELMET_IMAGE)
	add_child(_card)
	# The approved card sets mouse_filter = STOP in its own _ready().
	# add_child() invokes that _ready(): ONLY THEN can we make the card click-through.
	# The parent Button remains the one and only tap target; no UI change.
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var parent_control: Control = get_parent() as Control
	if parent_control != null:
		parent_control.resized.connect(_layout_like_bubble)
	if not MobileLocale.language_changed.is_connected(_on_locale_changed):
		MobileLocale.language_changed.connect(_on_locale_changed)
	_on_locale_changed(str(MobileLocale.language))
	_layout_like_bubble()

func configure(host: Node2D) -> void:
	_host = host
	_update_visibility()

func _on_locale_changed(locale: String) -> void:
	var title: String = str(TITLES.get(locale, TITLES["en"]))
	if _card != null:
		_card.set("card_title", title)
	tooltip_text = title

func _layout_like_bubble() -> void:
	var parent_control: Control = get_parent() as Control
	if parent_control == null:
		return
	var view: Vector2 = parent_control.size
	if view.x <= 1.0 or view.y <= 1.0:
		return
	# Exactly the same size formula as Main.gd::_layout_bubble_popup().
	var sc: float = clampf(minf(view.x / 1280.0, view.y / 720.0), 0.44, 0.92)
	var portrait: Vector2 = Vector2(430.0, 540.0) * sc
	size = portrait
	position = (view - portrait) * 0.5

func _process(_delta: float) -> void:
	_update_visibility()

func _update_visibility() -> void:
	if _host == null or not is_instance_valid(_host) or _card == null:
		visible = false
		return
	# The flight loop is NOT paused. A magnetic crystal pickup can happen
	# while this clickable card is shown, and immediately hides it again.
	var fuel: float = float(_host.get("_fuel_units"))
	var speed: Variant = _host.get("velocity")
	var stopped: bool = false
	if speed is Vector2:
		var speed_vector: Vector2 = speed
		stopped = speed_vector.length_squared() <= 0.000625
	var flight_ready: bool = bool(_host.call("_bubble_flight_available"))
	visible = fuel <= 0.0 and stopped and flight_ready

func _on_pressed() -> void:
	if not visible:
		return
	simulator_requested.emit()
