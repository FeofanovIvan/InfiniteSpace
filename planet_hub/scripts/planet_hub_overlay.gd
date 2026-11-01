@tool
extends Control
## Planet landing hub overlay. Reuses the same lower HUD for every planet,
## while allowing different backgrounds and card visibility/content per target.

signal simulator_requested
signal flight_requested
signal representative_requested(planet_id: String)

const ATLAS_PATH: String = "res://atlas/world_atlas.json"
const BACKGROUND_ROOT: String = "res://planet_hub/backgrounds/"
const CARD_ROOT: String = "res://planet_hub/cards/"
const CHARACTER_ROOT: String = "res://planet_hub/characters/"
const ROSTER_PATH: String = "res://planet_hub/data/representatives.json"
const MISSION_PATH: String = "res://planet_hub/data/missions.json"

@onready var scroll: ScrollContainer = $CardScroll
@onready var card_row: HBoxContainer = $CardScroll/CardRow
@onready var representative: Control = $CardScroll/CardRow/RepresentativeCard
@onready var mission: Control = $CardScroll/CardRow/MissionCard
@onready var hud: Control = $BottomHUD

var _atlas: Dictionary = {}
var _representative_roster: Dictionary = {}
var _mission_records: Dictionary = {}
var _mouse_scroll_drag: bool = false
var _planet_id: String = ""
var _planet_name: String = ""
var _meta: Dictionary = {}
var _background_texture: Texture2D
var _background_path: String = ""
var _is_setup: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_load_atlas()
	_load_representative_roster()
	_load_missions()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_is_setup = true
	if hud != null:
		hud.connect("simulator_pressed", Callable(self, "_on_simulator_pressed"))
		hud.connect("flight_pressed", Callable(self, "_on_flight_pressed"))
	_setup_representative_card_button()
	resized.connect(_layout_ui)
	_layout_ui()
	queue_redraw()

func _setup_representative_card_button() -> void:
	# Invisible input surface; the original card artwork remains unchanged.
	var open_button: Button = Button.new()
	open_button.name = "OpenRepresentativeDialog"
	open_button.flat = true
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	open_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		open_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	representative.add_child(open_button)
	open_button.pressed.connect(_on_representative_card_pressed)


func _on_representative_card_pressed() -> void:
	if bool(_meta.get("inhabited", false)) and not _planet_id.is_empty():
		representative_requested.emit(_planet_id)


func get_dialog_background_path() -> String:
	return _background_path


func get_dialog_portrait_path() -> String:
	var entry: Dictionary = _representative_entry()
	var asset_name: String = String(entry.get("asset", ""))
	if not asset_name.is_empty():
		var candidate: String = CHARACTER_ROOT + asset_name
		if ResourceLoader.exists(candidate):
			return candidate
	return _resolve_first_existing([
		CARD_ROOT + _planet_id + "_representative_dialog.png",
		CARD_ROOT + _planet_id + "_representative_dialog.webp",
		CARD_ROOT + _planet_id + "_representative.png",
	])


func show_for_planet(planet_id: String, display_name: String = "", crystals: int = 0) -> void:
	_planet_id = planet_id
	_meta = _find_planet_meta(planet_id)
	_planet_name = String(_meta.get("name_ru", display_name)) if bool(_meta.get("is_station", false)) else (display_name if not display_name.is_empty() else String(_meta.get("name_ru", planet_id)))
	if hud != null:
		hud.set("crystal_count", crystals)
	_apply_card_content()
	_reload_background()
	visible = true
	modulate = Color(1,1,1,0)
	create_tween().tween_property(self, "modulate", Color(1,1,1,1), 0.18)
	_layout_ui()

func hide_hub(animate: bool = true) -> void:
	if not visible:
		return
	if animate:
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color(1,1,1,0), 0.12)
		await tw.finished
	visible = false

func _load_atlas() -> void:
	_atlas.clear()
	if not FileAccess.file_exists(ATLAS_PATH):
		return
	var text := FileAccess.get_file_as_string(ATLAS_PATH)
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_atlas = parsed

func _find_planet_meta(planet_id: String) -> Dictionary:
	var systems: Array = _atlas.get("systems", [])
	for system_data in systems:
		if not (system_data is Dictionary):
			continue
		for planet in system_data.get("planets", []):
			if planet is Dictionary and String(planet.get("id", "")) == planet_id:
				var result: Dictionary = planet.duplicate(true)
				result["system_id"] = String(system_data.get("id", ""))
				result["system_name_ru"] = String(system_data.get("name_ru", ""))
				return result
		var station: Variant = system_data.get("station", null)
		if station is Dictionary and String(station.get("id", "")) == planet_id:
			var result: Dictionary = station.duplicate(true)
			result["inhabited"] = bool(station.get("accessible", true))
			result["is_station"] = true
			result["unique"] = "Изучи устройство станции и познакомься с её экипажем."
			result["system_id"] = String(system_data.get("id", ""))
			result["system_name_ru"] = String(system_data.get("name_ru", ""))
			return result
	return {}

func _load_representative_roster() -> void:
	_representative_roster.clear()
	if not FileAccess.file_exists(ROSTER_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROSTER_PATH))
	if parsed is Dictionary:
		var assignments: Variant = parsed.get("assignments", {})
		if assignments is Dictionary:
			_representative_roster = assignments

func _load_missions() -> void:
	_mission_records.clear()
	if not FileAccess.file_exists(MISSION_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MISSION_PATH))
	if parsed is Dictionary:
		var records: Variant = parsed.get("missions", {})
		if records is Dictionary:
			_mission_records = records

func _mission_entry() -> Dictionary:
	var record: Variant = _mission_records.get(_planet_id, {})
	if record is Dictionary and bool(record.get("enabled", false)):
		return record
	return {}

func _localized_mission_field(record: Dictionary, field: String, default_text: String = "") -> String:
	var value: Variant = record.get(field, default_text)
	if value is Dictionary:
		var language: String = "ru" if Engine.is_editor_hint() else MobileLocale.language
		return str(value.get(language, value.get("ru", value.get("en", default_text))))
	return str(value)

func _input(event: InputEvent) -> void:
	# ScrollContainer already handles touch swipes; support mouse dragging too.
	# No scrollbar is displayed on mobile or desktop.
	if not visible or not is_instance_valid(scroll):
		_mouse_scroll_drag = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_scroll_drag = scroll.get_global_rect().has_point(event.position)
		else:
			_mouse_scroll_drag = false
	elif event is InputEventMouseMotion and _mouse_scroll_drag and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		scroll.scroll_horizontal = maxi(0, scroll.scroll_horizontal - roundi(event.relative.x))

func _representative_entry() -> Dictionary:
	var entry: Variant = _representative_roster.get(_planet_id, {})
	return entry if entry is Dictionary else {}

func _resolve_first_existing(paths: Array[String]) -> String:
	for path in paths:
		if not String(path).is_empty() and ResourceLoader.exists(path):
			return path
	return ""

func _reload_background() -> void:
	_background_texture = null
	_background_path = ""
	var system_id: String = String(_meta.get("system_id", ""))
	var bg_path: String = _resolve_first_existing([
		BACKGROUND_ROOT + _planet_id + ".png",
		BACKGROUND_ROOT + _planet_id + ".jpg",
		BACKGROUND_ROOT + _planet_id + ".webp",
		BACKGROUND_ROOT + system_id + ".png",
		BACKGROUND_ROOT + system_id + ".jpg",
		BACKGROUND_ROOT + "default.png",
	])
	if not bg_path.is_empty():
		_background_path = bg_path
		_background_texture = load(bg_path) as Texture2D
	queue_redraw()

func _station_description(station_id: String) -> String:
    match station_id:
        "st_mw":
            return "Дальняя ремонтная верфь: космическая станция для обслуживания и ремонта кораблей во внешней части Солнечной системы."
        "st_lmc":
            return "Лабораторный корабль «Тарантул»: исследовательская станция, расположенная в свободном космическом пространстве."
        "st_smc":
            return "Живой архив: станция в глубоком космосе, окружённая необычной атмосферной дымкой."
        "st_ngc6822":
            return "Голова Титана: удалённый космический порт среди астероидов и окружающих его колец."
        "st_m31":
            return "Перевёрнутая пирамида: отдельная загадочная конструкция во внешнем секторе галактики."
        "st_m33":
            return "Последние врата: межгалактический переход во внешнем секторе перед Перекрёстком миров."
        _:
            return "Исследуй станцию и узнай, как она устроена."

func _apply_card_content() -> void:
	var inhabited: bool = bool(_meta.get("inhabited", false))
	if representative != null:
		representative.visible = inhabited
		var is_station: bool = bool(_meta.get("is_station", false))
		representative.set("card_title", "Представитель станции" if is_station else "Представитель планеты")
		# A location card, not an identity card: do not display character names.
		representative.set("card_subtitle", _planet_name)
		var rep_text: String = String(_meta.get("unique", ""))
		if is_station:
			rep_text = _station_description(_planet_id)
		elif rep_text.is_empty():
			rep_text = "Познакомься с этим миром и узнай, кто здесь живёт."
		representative.set("card_description", rep_text)
		var portrait_path: String = get_dialog_portrait_path()
		var portrait_name: String = portrait_path.get_file()
		var humanoid: bool = portrait_name.begins_with("05_human_") or portrait_name.begins_with("06_human_") or portrait_name.begins_with("01_reptile_") or portrait_name.begins_with("02_reptile_")
		representative.set("image_fit_mode", "portrait_top" if humanoid else "contain")
		representative.set("image_path", portrait_path)
	if mission != null:
		var assignment: Dictionary = _mission_entry()
		# A mission card is absent unless an explicit enabled DB row exists.
		mission.visible = not assignment.is_empty()
		if mission.visible:
			var is_station: bool = bool(_meta.get("is_station", false))
			var default_title: String = "Задание станции" if is_station else "Задание планеты"
			mission.set("card_title", _localized_mission_field(assignment, "title", default_title))
			mission.set("card_subtitle", _localized_mission_field(assignment, "subtitle", _planet_name))
			mission.set("card_description", _localized_mission_field(assignment, "description"))
			var image: String = _localized_mission_field(assignment, "image", "")
			if not image.is_empty() and not ResourceLoader.exists(image):
				image = ""
			mission.set("image_path", image)
	_layout_ui()

func _visible_cards() -> Array[Control]:
	var cards: Array[Control] = []
	for child in card_row.get_children():
		if child is Control and child.visible:
			cards.append(child)
	return cards

func _layout_ui() -> void:
	if not _is_setup:
		return
	var sw: float = size.x
	var sh: float = size.y
	if sw < 200 or sh < 180:
		return
	var scale_ui: float = minf(sh / 864.0, sw / 1450.0)
	scale_ui = clampf(scale_ui, 0.40, 2.0)
	var bottom_h: float = 158.0 * (sh / 864.0)
	hud.position = Vector2(0, sh - bottom_h)
	hud.size = Vector2(sw, bottom_h)
	var cards: Array[Control] = _visible_cards()
	var card_w: float = 430.0 * scale_ui
	var card_h: float = minf(540.0 * scale_ui, sh - bottom_h - 54.0 * scale_ui)
	var gap: float = 46.0 * scale_ui
	var count: int = cards.size()
	var row_w: float = float(count) * card_w + float(maxi(0, count - 1)) * gap
	card_row.add_theme_constant_override("separation", int(gap))
	for child in card_row.get_children():
		if child is Control:
			child.custom_minimum_size = Vector2(card_w, card_h)
	card_row.custom_minimum_size = Vector2(row_w, card_h)
	scroll.position = Vector2(maxf(12 * scale_ui, (sw - row_w) * 0.5), maxf(12 * scale_ui, (sh - bottom_h - card_h) * 0.5 + 24 * scale_ui))
	scroll.size = Vector2(minf(row_w, sw - 24 * scale_ui), card_h + 4 * scale_ui)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	queue_redraw()

func _draw() -> void:
	var sw: float = size.x
	var sh: float = size.y
	if sw < 2 or sh < 2:
		return
	if _background_texture != null:
		var ts: Vector2 = _background_texture.get_size()
		var scale_cover: float = maxf(sw / ts.x, sh / ts.y)
		var crop_size: Vector2 = Vector2(sw, sh) / scale_cover
		var src: Rect2 = Rect2((ts - crop_size) * 0.5, crop_size)
		draw_texture_rect_region(_background_texture, Rect2(Vector2.ZERO, size), src)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("061527"))
		for n in range(18):
			var fy: float = float(n) / 18.0
			draw_rect(Rect2(0, fy * sh, sw, sh / 18 + 1), Color(0.016 + fy * 0.018, 0.075 + fy * 0.012, 0.15 + fy * 0.035, 0.42))
		var r: RandomNumberGenerator = RandomNumberGenerator.new()
		r.seed = hash(_planet_id)
		for i in range(175):
			var pt: Vector2 = Vector2(r.randf_range(0, sw), r.randf_range(0, sh * 0.86))
			draw_circle(pt, r.randf_range(0.5, 1.5), Color(0.57, 0.8, 1, r.randf_range(0.2, 0.8)))
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(40, 58), _planet_name if not _planet_name.is_empty() else "Планета", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.75, 0.9, 1.0, 0.8))
	draw_rect(Rect2(0, 0, sw, sh), Color(0.0, 0.03, 0.08, 0.18))
	var bottom_h: float = 158.0 * (sh / 864.0)
	draw_rect(Rect2(0, sh - bottom_h - 10.0, sw, bottom_h + 10.0), Color(0.0, 0.02, 0.06, 0.25))

func _on_simulator_pressed() -> void:
	simulator_requested.emit()

func _on_flight_pressed() -> void:
	flight_requested.emit()
