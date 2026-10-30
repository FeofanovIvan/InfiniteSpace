extends Control
## Picture-only destination selector for young players.
## The six circular icons expand in ONE row to the LEFT of the preview.
## The strip scrolls horizontally on narrow mobile screens.
signal target_selected(target_id: String)

const TRIGGER_SIZE: float = 94.0
const TILE_SIZE: float = 64.0
const TILE_GAP: int = 8
const RAIL_GAP: float = 12.0
const RAIL_PADDING: float = 8.0
const RAIL_HEIGHT: float = 90.0
const PREFERRED_WIDTH: float = 94.0 + 12.0 + 8.0 * 2.0 + 64.0 * 6.0 + 8.0 * 5.0
const TARGETS: Array[String] = ["Venus", "Earth", "Mars", "Jupiter", "Neptune", "st_mw"]
const PREVIEWS: Dictionary = {
	"Venus": preload("res://assets/destinations/venus.png"),
	"Earth": preload("res://assets/destinations/earth.png"),
	"Mars": preload("res://assets/destinations/mars.png"),
	"Jupiter": preload("res://assets/destinations/jupiter.png"),
	"Neptune": preload("res://assets/destinations/neptune.png"),
	"EarthStation": preload("res://assets/destinations/earth_station.png"),
	"st_mw": preload("res://assets/story/callisto_shipyard.png"),
	"st_ngc6822": preload("res://assets/story/titan_skull_ngc6822.png"),
	"st_m31": preload("res://assets/story/inverted_pyramid_m31.png")
}

var _trigger: Button
var _rail: Panel
var _scroll: ScrollContainer
var _row: HBoxContainer
var _active_target: String = ""
var _preview_target: String = "Earth"
var _open: bool = false
var _tiles: Dictionary = {}
var _target_ids: Array[String] = TARGETS.duplicate()
var _target_previews: Dictionary = PREVIEWS.duplicate()
var _target_labels: Dictionary = {}
var _total_width: float = PREFERRED_WIDTH
var _rail_width: float = PREFERRED_WIDTH - TRIGGER_SIZE - RAIL_GAP
var _shown_width: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO
	size = Vector2(_total_width, TRIGGER_SIZE)

	# A visually continuous blue rail, without square cards or labels.
	_rail = Panel.new()
	_rail.name = "ExpandableDestinationsToLeft"
	_rail.clip_contents = true
	_rail.mouse_filter = Control.MOUSE_FILTER_STOP
	_rail.add_theme_stylebox_override("panel", _style(Color(0.016, 0.105, 0.19, 0.96), Color(0.33, 0.76, 0.98, 0.73), 45, 2))
	_rail.visible = false
	add_child(_rail)

	_scroll = ScrollContainer.new()
	_scroll.name = "HorizontalDestinationScroller"
	_scroll.position = Vector2(RAIL_PADDING, (RAIL_HEIGHT - TILE_SIZE) * 0.5)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = false
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll.size = Vector2.ZERO
	_rail.add_child(_scroll)
	_scroll.get_h_scroll_bar().modulate = Color.TRANSPARENT

	_row = HBoxContainer.new()
	_row.name = "SingleRowOfSixDestinations"
	_row.add_theme_constant_override("separation", TILE_GAP)
	_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(_row)
	for id in _target_ids:
		_add_tile(id)

	_trigger = Button.new()
	_trigger.name = "LargeDestinationPreview"
	_trigger.size = Vector2(TRIGGER_SIZE, TRIGGER_SIZE)
	_trigger.text = ""
	_trigger.icon = _target_previews[_preview_target]
	_trigger.expand_icon = true
	_trigger.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trigger.tooltip_text = MobileLocale.t("pick_destination")
	_trigger.focus_mode = Control.FOCUS_NONE
	_trigger.add_theme_stylebox_override("normal", _style(Color(0.025, 0.15, 0.28, 0.98), Color(0.44, 0.87, 1.0, 0.92), 47, 2))
	_trigger.add_theme_stylebox_override("hover", _style(Color(0.045, 0.24, 0.37, 0.99), Color(0.71, 0.96, 1.0), 47, 2))
	_trigger.add_theme_stylebox_override("pressed", _style(Color(0.06, 0.34, 0.49, 0.99), Color(0.87, 0.98, 1.0), 47, 2))
	_trigger.pressed.connect(_toggle_menu)
	add_child(_trigger)
	_update_selection()
	_update_geometry()
	MobileLocale.language_changed.connect(_refresh_locale)
	_refresh_locale(MobileLocale.language)


func _process(delta: float) -> void:
	var previous_width: float = _shown_width
	var desired: float = _rail_width if _open else 0.0
	if absf(_shown_width - desired) < 0.5:
		_shown_width = desired
		if not _open:
			_rail.visible = false
	else:
		# Soft, short reveal. The right edge stays anchored beside the preview.
		_shown_width = lerpf(_shown_width, desired, 1.0 - exp(-17.0 * delta))
	if not is_equal_approx(previous_width, _shown_width):
		_update_geometry()


func set_available_width(available_width: float) -> void:
	# Main.gd reserves space for the mini-map on the left, whenever possible.
	_total_width = clampf(available_width, TRIGGER_SIZE + RAIL_GAP + 82.0, PREFERRED_WIDTH)
	_rail_width = _total_width - TRIGGER_SIZE - RAIL_GAP
	_shown_width = minf(_shown_width, _rail_width)
	_update_geometry()


func _update_geometry() -> void:
	if _trigger == null or _rail == null or _scroll == null:
		return
	size = Vector2(_total_width, TRIGGER_SIZE)
	_trigger.position = Vector2(_total_width - TRIGGER_SIZE, 0.0)
	_rail.size = Vector2(_shown_width, RAIL_HEIGHT)
	_rail.position = Vector2(_trigger.position.x - RAIL_GAP - _shown_width, 2.0)
	_scroll.size = Vector2(maxf(0.0, _shown_width - RAIL_PADDING * 2.0), RAIL_HEIGHT - _scroll.position.y)


func _toggle_menu() -> void:
	_open = not _open
	if _open:
		_rail.visible = true
		_scroll.scroll_horizontal = 0


func _choose(id: String) -> void:
	_preview_target = id
	_trigger.icon = _target_previews[id]
	_open = false
	_update_selection()
	target_selected.emit(id)


func _update_selection() -> void:
	for id in _target_ids:
		var tile: Button = _tiles.get(id) as Button
		if tile == null:
			continue
		if id == _preview_target:
			tile.add_theme_stylebox_override("normal", _style(Color(0.035, 0.29, 0.42), Color(0.75, 0.97, 1.0), 32, 2))
		else:
			tile.add_theme_stylebox_override("normal", _style(Color(0.035, 0.18, 0.29, 0.98), Color(0.28, 0.54, 0.71, 0.85), 32, 2))


func _style(bg: Color, stroke: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = stroke
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 4.0
	s.content_margin_right = 4.0
	s.content_margin_top = 4.0
	s.content_margin_bottom = 4.0
	return s


func _refresh_locale(_new_locale: String) -> void:
	if _trigger != null:
		_trigger.tooltip_text = MobileLocale.t("pick_destination")
	for id in _target_ids:
		var tile: Button = _tiles.get(id) as Button
		if tile != null:
			tile.tooltip_text = _hint(id)

func _hint(id: String) -> String:
	if ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"].has(id):
		return MobileLocale.t("planet_" + id)
	if id == "EarthStation":
		return MobileLocale.t("orbit_station")
	if id == "st_mw":
		return MobileLocale.t("shipyard")
	return str(_target_labels.get(id, id))

func set_autopilot_status(active: bool, target_id: String = "") -> void:
	_active_target = target_id if active else ""
	# Keep the selected image after STOP. A new tap is required for a new flight.
	_trigger.modulate = Color(0.82, 1.0, 1.0) if active else Color.WHITE

func _add_tile(id: String) -> void:
	var tile: Button = Button.new()
	tile.name = "PlanetPicture_" + id
	tile.text = ""
	tile.icon = _target_previews[id]
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.tooltip_text = _hint(id)
	tile.focus_mode = Control.FOCUS_NONE
	tile.add_theme_stylebox_override("normal", _style(Color(0.035, 0.18, 0.29, 0.98), Color(0.28, 0.54, 0.71, 0.85), 32, 2))
	tile.add_theme_stylebox_override("hover", _style(Color(0.065, 0.27, 0.39), Color(0.74, 0.95, 1.0), 32, 2))
	tile.add_theme_stylebox_override("pressed", _style(Color(0.07, 0.37, 0.49), Color(0.88, 0.98, 1.0), 32, 2))
	tile.pressed.connect(_choose.bind(id))
	_row.add_child(tile)
	_tiles[id] = tile


func set_region_destinations(region_id: String, planets: Array, station: Variant) -> void:
	# Existing Milky Way UI remains unchanged and limits flight to five
	# inhabited planets plus the standalone station.
	_target_ids.clear()
	_target_previews.clear()
	_target_labels.clear()
	if region_id == "mw":
		_target_ids = TARGETS.duplicate()
		_target_previews = PREVIEWS.duplicate()
	else:
		for data in planets:
			var id: String = str(data.get("id", ""))
			_target_ids.append(id)
			_target_labels[id] = str(data.get("name_en", id))
			var path: String = str(data.get("visual_asset", ""))
			if path != "":
				_target_previews[id] = load(path) as Texture2D
		if station is Dictionary:
			var station_id: String = str(station.get("id", ""))
			_target_ids.append(station_id)
			_target_labels[station_id] = str(station.get("name_en", "Station"))
			var station_asset: String = str(station.get("visual_asset", ""))
			if station_asset != "":
				_target_previews[station_id] = load(station_asset) as Texture2D
			else:
				_target_previews[station_id] = PREVIEWS["EarthStation"]
	if _row == null:
		return
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	_tiles.clear()
	for id in _target_ids:
		if _target_previews.has(id) and _target_previews[id] != null:
			_add_tile(id)
	_preview_target = _target_ids[0] if not _target_ids.is_empty() else ""
	if _preview_target != "" and _target_previews.has(_preview_target):
		_trigger.icon = _target_previews[_preview_target]
	_open = false
	_update_selection()
