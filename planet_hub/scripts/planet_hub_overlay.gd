@tool
extends Control
# v69: Atlas top info, transparent lower HUD backdrop.
const TopInfoPanel = preload("res://planet_hub/scripts/top_info_panel.gd")
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
const V104_GAME_DB_PATH: String = "res://planet_hub/data/planet_game_cards_v104.json"
const V107_CARD_BIOS_PATH: String = "res://planet_hub/data/representative_card_bios_v107.json"
const V104_GAME_CARD_SCRIPT: Script = preload("res://planet_hub/scripts/planet_card.gd")
const V108_CARD_ARROW_SCRIPT: Script = preload("res://planet_hub/scripts/mika_card_entry_arrow.gd")
# InfiniteSpace v104: six-language planetary game preview cards

@onready var scroll: ScrollContainer = $CardScroll
@onready var card_row: HBoxContainer = $CardScroll/CardRow
@onready var representative: Control = $CardScroll/CardRow/RepresentativeCard
@onready var mission: Control = $CardScroll/CardRow/MissionCard
@onready var hud: Control = $BottomHUD

var _atlas: Dictionary = {}
var _representative_roster: Dictionary = {}
var _mission_records: Dictionary = {}
var _v104_game_database: Dictionary = {}
var _v107_card_bios: Dictionary = {}
var _v104_game_cards: Array[Control] = []
# v105.1: launch ONLY already-approved scenes from existing v104 cards.
# The v104 planet assignment table and the card creation/layout are preserved.
var _v1051_game_layer: Control
var _v1051_viewport: SubViewport
var _v1051_back: Button
var _v1051_playing: bool = false
var _mouse_scroll_drag: bool = false
var _planet_id: String = ""
var _planet_name: String = ""
var _meta: Dictionary = {}
var _background_texture: Texture2D
var _background_path: String = ""
var _is_setup: bool = false

var _top_info: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_load_atlas()
	_load_representative_roster()
	_load_missions()
	_v104_load_game_database()
	_v107_load_card_bios()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_is_setup = true
	if hud != null:
		hud.connect("simulator_pressed", Callable(self, "_on_simulator_pressed"))
		hud.connect("flight_pressed", Callable(self, "_on_flight_pressed"))
	_setup_representative_card_button()
	resized.connect(_layout_ui)
	_top_info = TopInfoPanel.new()
	_top_info.name = "AtlasTopInformationPanel"
	_top_info.z_index = 25
	add_child(_top_info)
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
	if is_instance_valid(_top_info):
		_top_info.configure(_planet_id, _planet_name, _meta)
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
	if _v1051_playing or not visible or not is_instance_valid(scroll):
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

func _v85_shared_empty_background_path(planet_id: String) -> String:
	# Map is data driven and only used on catalogued uninhabited worlds.
	if not FileAccess.file_exists("res://planet_hub/data/uninhabited_shared_backgrounds.json"):
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/uninhabited_shared_backgrounds.json"))
	if not (parsed is Dictionary):
		return ""
	var mapping: Variant = parsed.get("planet_to_background", {})
	if not (mapping is Dictionary) or not mapping.has(planet_id):
		return ""
	var number: int = int(mapping.get(planet_id, 0))
	if number < 1 or number > 13:
		return ""
	return "res://planet_hub/backgrounds/shared_uninhabited/%02d.png" % number


func _reload_background() -> void:
	_background_texture = null
	_background_path = ""
	## v85: 13 shared backgrounds for 24 uninhabited worlds; never override inhabited worlds.
	if _meta.has("inhabited") and not bool(_meta.get("inhabited", true)) and not bool(_meta.get("is_station", false)):
		var shared_path: String = _v85_shared_empty_background_path(_planet_id)
		if not shared_path.is_empty() and ResourceLoader.exists(shared_path):
			var shared_texture: Texture2D = load(shared_path) as Texture2D
			if shared_texture != null:
				_background_path = shared_path
				_background_texture = shared_texture
				queue_redraw()
				return
	var system_id: String = String(_meta.get("system_id", ""))
	var bg_path: String = _resolve_first_existing([
		BACKGROUND_ROOT + _planet_id + ".png",
		BACKGROUND_ROOT + _planet_id + ".jpg",
		BACKGROUND_ROOT + _planet_id + ".webp",
		BACKGROUND_ROOT + system_id + ".png" if bool(_meta.get("is_station", false)) else "",
		BACKGROUND_ROOT + system_id + ".jpg" if bool(_meta.get("is_station", false)) else "",
		BACKGROUND_ROOT + "default.png" if bool(_meta.get("is_station", false)) else "",
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
		representative.set("card_title", _planet_name)
		# A location card, not an identity card: do not display character names.
		representative.set("card_subtitle", _planet_name)
		var rep_text: String = String(_meta.get("unique", ""))
		if is_station:
			rep_text = _station_description(_planet_id)
		elif rep_text.is_empty():
			rep_text = "Познакомься с этим миром и узнай, кто здесь живёт."
		representative.set("card_description", rep_text)
		representative.set("card_subtitle", "")
		# v107: names and one short, canonical v106 sentence. Existing portraits and layout stay.
		var v107_person: Dictionary = _v107_card_bios.get(_planet_id, {})
		if not v107_person.is_empty():
			var v107_name: String = _v104_card_localized(v107_person.get("name", {}))
			var v107_bio: String = _v104_card_localized(v107_person.get("bio", {}))
			if not v107_name.is_empty():
				representative.set("card_title", v107_name)
			if not v107_bio.is_empty():
				representative.set("card_description", v107_bio)
		var portrait_path: String = get_dialog_portrait_path()
		var portrait_name: String = portrait_path.get_file()
		var humanoid: bool = portrait_name.begins_with("05_human_") or portrait_name.begins_with("06_human_") or portrait_name.begins_with("01_reptile_") or portrait_name.begins_with("02_reptile_")
		representative.set("image_fit_mode", "portrait_top" if humanoid else "contain")
		representative.set("image_path", portrait_path)
		_v108_ensure_entry_arrow(representative, true)
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
	_v104_refresh_game_cards()
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
	# Compact top panel lies inside mobile-safe bounds.
	var top_safe: Rect2 = MobileLocale.safe_rect(Vector2(sw, sh))
	var top_h: float = clampf(sh * 0.105, 49.0, 108.0)
	var top_w: float = minf(top_safe.size.x * 0.94, 1490.0)
	if is_instance_valid(_top_info):
		_top_info.position = Vector2(top_safe.position.x + (top_safe.size.x - top_w) * 0.5, top_safe.position.y + 2.0)
		_top_info.size = Vector2(top_w, top_h)
	var cards: Array[Control] = _visible_cards()
	var card_w: float = 430.0 * scale_ui
	# v72: cards centered between top info and bottom HUD.
	# v72: content region is NOT the full screen. Keep clear of both panels.
	var cards_top: float = top_safe.position.y + 2.0 + top_h + maxf(8.0, 12.0 * scale_ui)
	var cards_bottom: float = minf(hud.position.y, top_safe.end.y) - maxf(8.0, 12.0 * scale_ui)
	var card_region_h: float = maxf(70.0, cards_bottom - cards_top)
	var card_h: float = minf(540.0 * scale_ui, maxf(66.0, card_region_h - 4.0 * scale_ui))
	var gap: float = 46.0 * scale_ui
	var count: int = cards.size()
	var row_w: float = float(count) * card_w + float(maxi(0, count - 1)) * gap
	card_row.add_theme_constant_override("separation", int(gap))
	for child in card_row.get_children():
		if child is Control:
			child.custom_minimum_size = Vector2(card_w, card_h)
	card_row.custom_minimum_size = Vector2(row_w, card_h)
	var scroll_h: float = minf(card_region_h, card_h + 4.0 * scale_ui)
	var scroll_y: float = cards_top + maxf(0.0, (card_region_h - scroll_h) * 0.5)
	scroll.position = Vector2(maxf(12 * scale_ui, (sw - row_w) * 0.5), scroll_y)
	scroll.size = Vector2(minf(row_w, sw - 24 * scale_ui), scroll_h)
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

func _on_simulator_pressed() -> void:
	simulator_requested.emit()

func _on_flight_pressed() -> void:
	flight_requested.emit()

func _v107_load_card_bios() -> void:
	_v107_card_bios.clear()
	if not FileAccess.file_exists(V107_CARD_BIOS_PATH):
		push_warning("Missing representative card biographies: " + V107_CARD_BIOS_PATH)
		return
	var v107_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(V107_CARD_BIOS_PATH))
	if v107_data is Dictionary:
		var v107_records: Variant = v107_data.get("characters", {})
		if v107_records is Dictionary:
			_v107_card_bios = v107_records


func _v104_load_game_database() -> void:
	_v104_game_database.clear()
	if not FileAccess.file_exists(V104_GAME_DB_PATH):
		push_warning("Missing game cards catalog: " + V104_GAME_DB_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(V104_GAME_DB_PATH))
	if parsed is Dictionary:
		_v104_game_database = parsed


func _v104_card_localized(value: Variant) -> String:
	if not (value is Dictionary):
		return str(value)
	var lang: String = "ru" if Engine.is_editor_hint() else MobileLocale.language
	return str(value.get(lang,value.get("en","")))


func _v104_card_status(code: String) -> String:
	var lang: String = "ru" if Engine.is_editor_hint() else MobileLocale.language
	var names: Dictionary = {
		"ru":{"ready":"Играть", "playtown":"Основа готова", "adapt":"Нужна адаптация", "missing":"В разработке"},
		"en":{"ready":"Play", "playtown":"Source available", "adapt":"Needs adaptation", "missing":"In development"},
		"fr":{"ready":"Jouer", "playtown":"Base disponible", "adapt":"À adapter", "missing":"En développement"},
		"de":{"ready":"Spielen", "playtown":"Vorlage vorhanden", "adapt":"Anpassung nötig", "missing":"In Entwicklung"},
		"es":{"ready":"Jugar", "playtown":"Base disponible", "adapt":"Por adaptar", "missing":"En desarrollo"},
		"pt_BR":{"ready":"Jogar", "playtown":"Base disponível", "adapt":"Precisa adaptar", "missing":"Em desenvolvimento"}
	}
	var localized: Dictionary = names.get(lang,names["en"])
	return str(localized.get(code,localized["missing"]))


func _v104_refresh_game_cards() -> void:
	for old_card in _v104_game_cards:
		if is_instance_valid(old_card):
			card_row.remove_child(old_card)
			old_card.queue_free()
	_v104_game_cards.clear()
	if _v104_game_database.is_empty() or _planet_id.is_empty():
		return
	var by_planet: Dictionary = _v104_game_database.get("planet_cards", {})
	var game_records: Dictionary = _v104_game_database.get("games", {})
	var game_ids: Array = by_planet.get(_planet_id, [])
	for game_id_value in game_ids:
		var game_id: String = str(game_id_value)
		var record: Dictionary = game_records.get(game_id, {})
		if record.is_empty():
			continue
		var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
		card.name = "GamePreview_" + game_id
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.set("card_title",_v104_card_localized(record.get("title", {})))
		card.set("card_subtitle", "" if bool(record.get("launch_enabled", false)) else _v104_card_status(str(record.get("source_status", "missing"))))
		card.set("card_description",_v104_card_localized(record.get("description", {})))
		card.set("accent",Color("55cdff"))
		card.set("image_fit_mode","contain")
		var card_image: String = str(record.get("image_path", ""))
		if not card_image.is_empty():
			card.set("image_path", card_image)
			card.set("art_bay_enabled", true)
		card_row.add_child(card)
		if bool(record.get("launch_enabled", false)):
			_v108_ensure_entry_arrow(card, false)
		_v104_game_cards.append(card)
		var hint: Label = card.get_node_or_null("ImagePlaceholder") as Label
		if hint != null:
			hint.text = "✦"
			hint.add_theme_font_size_override("font_size",42)
		# The exact existing card is clickable ONLY when its validated game exists.
		# The hit area is transparent, like the existing RepresentativeCard overlay.
		var scene_path: String = str(record.get("source_scene", ""))
		if bool(record.get("launch_enabled", false)) and not scene_path.is_empty() and ResourceLoader.exists(scene_path):
			var hit: Button = Button.new()
			hit.name = "OpenExistingGame"
			hit.flat = true
			hit.focus_mode = Control.FOCUS_NONE
			hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			hit.tooltip_text = _v104_card_localized(record.get("title", {}))
			for state in ["normal", "hover", "pressed", "disabled", "focus"]:
				hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
			card.add_child(hit)
			hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hit.pressed.connect(_v1051_open_existing_game.bind(game_id))


# v105.1 uses the SAME full-screen SubViewport technique as MikoMainMenu.
# This is a hidden game-runner, not a new PlanetHub card, selector or menu.
func _v1051_setup_runner() -> void:
	if is_instance_valid(_v1051_game_layer):
		return
	_v1051_game_layer = Control.new()
	_v1051_game_layer.name = "ExistingPlanetGameRunner"
	_v1051_game_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_v1051_game_layer.clip_contents = true
	_v1051_game_layer.visible = false
	_v1051_game_layer.z_index = 100
	add_child(_v1051_game_layer)
	_v1051_game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dark: ColorRect = ColorRect.new()
	dark.name = "FullscreenGameBackdrop"
	dark.color = Color("061225")
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_v1051_game_layer.add_child(dark)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var container: SubViewportContainer = SubViewportContainer.new()
	container.name = "ExistingGameInputForwarding"
	container.stretch = true
	container.stretch_shrink = 1
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	_v1051_game_layer.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_v1051_viewport = SubViewport.new()
	_v1051_viewport.name = "ExistingPlanetGameViewport"
	_v1051_viewport.handle_input_locally = true
	_v1051_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(_v1051_viewport)
	# Same concept as simulator's ReturnToEducationalCards button.
	_v1051_back = Button.new()
	_v1051_back.name = "ReturnToExistingPlanetCards"
	_v1051_back.text = "❮"
	_v1051_back.focus_mode = Control.FOCUS_NONE
	_v1051_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_v1051_back.add_theme_font_size_override("font_size", 27)
	_v1051_back.add_theme_color_override("font_color", Color("eafaff"))
	var skin: StyleBoxFlat = StyleBoxFlat.new()
	skin.bg_color = Color("061c38")
	skin.border_color = Color("26dfff")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(17)
	_v1051_back.add_theme_stylebox_override("normal", skin)
	var hover: StyleBoxFlat = skin.duplicate() as StyleBoxFlat
	hover.bg_color = Color("113a60")
	_v1051_back.add_theme_stylebox_override("hover", hover)
	_v1051_back.add_theme_stylebox_override("pressed", hover)
	_v1051_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_v1051_back.pressed.connect(_v1051_return_to_cards)
	_v1051_game_layer.add_child(_v1051_back)
	_v1051_game_layer.resized.connect(_v1051_layout_back)
	_v1051_layout_back()
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null and portal.has_signal("game_finished"):
		portal.connect("game_finished", _v1051_return_to_cards)


func _v1051_layout_back() -> void:
	if _v1051_back == null or not is_instance_valid(_v1051_game_layer):
		return
	var sc: float = clampf(minf(size.x / 1280.0, size.y / 720.0), 0.7, 1.3)
	_v1051_back.position = Vector2(12.0, 12.0) * sc
	_v1051_back.size = Vector2.ONE * 56.0 * sc


func _v1051_open_existing_game(game_id: String) -> void:
	if _v1051_playing or _planet_id.is_empty():
		return
	var games: Dictionary = _v104_game_database.get("games", {})
	var record: Dictionary = games.get(game_id, {})
	if not bool(record.get("launch_enabled", false)):
		return
	var scene_path: String = str(record.get("source_scene", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("Planet game scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_warning("Planet game could not load: " + scene_path)
		return
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal == null or bool(portal.get("active")):
		push_warning("Cannot start planet game: PlayTownPortal is busy or missing")
		return
	if not is_instance_valid(_v1051_game_layer):
		_v1051_setup_runner()
	var instance: Node = packed.instantiate()
	if instance == null:
		return
	var lang: Node = get_node_or_null("/root/LanguageService")
	if lang != null and lang.has_method("set_locale"):
		var locale: String = str(MobileLocale.language)
		lang.call("set_locale", "pt" if locale == "pt_BR" else locale, false)
	_mouse_scroll_drag = false
	_v1051_playing = true
	scroll.hide()
	hud.hide()
	if is_instance_valid(_top_info):
		_top_info.hide()
	_v1051_game_layer.show()
	_v1051_game_layer.move_to_front()
	portal.call("start_game", scene_path)
	_v1051_viewport.add_child(instance)


func _v1051_return_to_cards() -> void:
	if not _v1051_playing:
		return
	_v1051_playing = false
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null:
		portal.call("stop_game")
	if is_instance_valid(_v1051_viewport):
		for instance in _v1051_viewport.get_children():
			_v1051_viewport.remove_child(instance)
			instance.queue_free()
	_v1051_game_layer.hide()
	scroll.show()
	hud.show()
	if is_instance_valid(_top_info):
		_top_info.show()
	_layout_ui()


func _unhandled_key_input(event: InputEvent) -> void:
	if _v1051_playing and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_v1051_return_to_cards()
		get_viewport().set_input_as_handled()


# v108-existing-card-voice -- no new cards or buttons that launch scenes.
func _v108_ensure_entry_arrow(card: Control, is_representative: bool) -> void:
	if card == null or card.get_node_or_null("MikaEntryArrow") != null:
		return
	var arrow: Control = V108_CARD_ARROW_SCRIPT.new() as Control
	if arrow == null:
		return
	arrow.set("representative_mode", is_representative)
	card.add_child(arrow)
