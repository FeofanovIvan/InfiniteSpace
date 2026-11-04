extends Control
## Public in-game reference: separate from story dialogue and quest state.
## Reads the live Godot atlas, v105 local NPC identities and v96 science topics.
signal closed

const WORLD_PATH: String = "res://atlas/world_atlas.json"
const PUBLIC_PATH: String = "res://glossary/data/public_encyclopedia.json"
const NPC_PATH: String = "res://planet_hub/data/representative_profiles.json"
const SCIENCE_PATH: String = "res://planet_hub/data/crossroads_encyclopedia_v96_6_languages.json"

const CATEGORIES: Array = [
	{"id": "planets", "ru": "Планеты", "en": "Planets"},
	{"id": "stations", "ru": "Станции", "en": "Stations"},
	{"id": "races", "ru": "Расы и формы жизни", "en": "Life forms"},
	{"id": "characters", "ru": "Персонажи", "en": "Characters"},
	{"id": "science", "ru": "Наука и природа", "en": "Science and nature"},
	{"id": "terms", "ru": "Технологии и термины", "en": "Technology and terms"}
]
const RACE_BY_SYSTEM: Dictionary = {
	"mw": "Люди", "lmc": "Разумная плесень",
	"smc": "Фазовые существа", "ngc6822": "Разумные ящеры",
	"m31": "Жидкометаллическая раса", "m33": "Нейронные существа"
}

var _catalog: Dictionary = {}
var _atlas: Dictionary = {}
var _profiles: Dictionary = {}
var _science: Dictionary = {}
var _section: String = ""
var _heading: Label
var _search: LineEdit
var _rows: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_catalog = _read_json(PUBLIC_PATH)
	_atlas = _read_json(WORLD_PATH)
	_profiles = _read_json(NPC_PATH)
	_science = _read_json(SCIENCE_PATH)
	_build_ui()
	_show_categories()
	visible = false


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Glossary source missing: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_warning("Invalid glossary JSON: " + path)
	return {}


func _style(background: Color, radius: int = 16) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = background
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


func _make_label(value: String, size_px: int, color: Color, wrap: bool = true) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _build_ui() -> void:
	var bg: PanelContainer = PanelContainer.new()
	bg.name = "GlossaryFullScreenBackground"
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _style(Color(0.016, 0.031, 0.075), 0))

	var margins: MarginContainer = MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 22)
	margins.add_theme_constant_override("margin_right", 22)
	margins.add_theme_constant_override("margin_top", 16)
	margins.add_theme_constant_override("margin_bottom", 16)
	bg.add_child(margins)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margins.add_child(layout)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	layout.add_child(header)

	var back: Button = Button.new()
	back.name = "GlossaryBack"
	back.text = "❮"
	back.tooltip_text = "Назад"
	back.custom_minimum_size = Vector2(58, 54)
	back.add_theme_font_size_override("font_size", 28)
	back.add_theme_stylebox_override("normal", _style(Color(0.10, 0.20, 0.34), 12))
	back.pressed.connect(_go_back)
	header.add_child(back)

	_heading = _make_label("Глоссарий", 31, Color(0.84, 0.97, 1.0), false)
	header.add_child(_heading)

	_search = LineEdit.new()
	_search.name = "GlossarySearch"
	_search.placeholder_text = "Поиск по названиям и описаниям"
	_search.custom_minimum_size.y = 48
	_search.add_theme_font_size_override("font_size", 19)
	_search.text_changed.connect(_filter_rows)
	layout.add_child(_search)

	_scroll = ScrollContainer.new()
	_scroll.name = "GlossaryNativeTouchScroll"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = false
	layout.add_child(_scroll)

	_rows = VBoxContainer.new()
	_rows.name = "GlossaryCards"
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	_scroll.add_child(_rows)


func _language() -> String:
	var code: String = str(MobileLocale.language)
	if code in ["ru", "en", "fr", "de", "es", "pt_BR"]:
		return code
	return "ru"


func _category_name(section_id: String) -> String:
	for category in CATEGORIES:
		if str(category.get("id", "")) == section_id:
			if _language() == "ru":
				return str(category.get("ru", "Глоссарий"))
			return str(category.get("en", "Glossary"))
	return "Глоссарий"


func open_glossary(view: Vector2) -> void:
	size = view
	visible = true
	_show_categories()


func close_glossary() -> void:
	visible = false
	closed.emit()


func _go_back() -> void:
	if _section == "":
		close_glossary()
	else:
		_show_categories()


func _clear_rows() -> void:
	for old in _rows.get_children():
		_rows.remove_child(old)
		old.queue_free()
	_scroll.scroll_vertical = 0


func _show_categories() -> void:
	_section = ""
	_heading.text = "Глоссарий" if _language() == "ru" else "Glossary"
	_search.visible = false
	_search.clear()
	_clear_rows()

	var intro: Label = _make_label(
		"Выбери раздел, чтобы открыть статьи о нашем мире." if _language() == "ru"
		else "Choose a section to explore the world.",
		19, Color(0.68, 0.82, 0.91))
	_rows.add_child(intro)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2 if size.x >= 650.0 else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	_rows.add_child(grid)
	for category in CATEGORIES:
		var key: String = str(category.get("id", ""))
		var button: Button = Button.new()
		button.name = "Category_" + key
		button.text = _category_name(key) + "\n" + str(_entries_for(key).size())
		button.custom_minimum_size = Vector2(270, 100)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", Color(0.84, 0.95, 1.0))
		button.add_theme_stylebox_override("normal", _style(Color(0.075, 0.15, 0.26), 18))
		button.add_theme_stylebox_override("hover", _style(Color(0.11, 0.23, 0.36), 18))
		button.pressed.connect(_open_category.bind(key))
		grid.add_child(button)


func _open_category(key: String) -> void:
	_section = key
	_heading.text = _category_name(key)
	_search.visible = true
	_search.clear()
	_render_entries()


func _filter_rows(_new_text: String) -> void:
	if _section != "":
		_render_entries()


func _render_entries() -> void:
	_clear_rows()
	var term: String = _search.text.strip_edges().to_lower()
	var amount: int = 0
	for entry in _entries_for(_section):
		var name: String = str(entry.get("title", ""))
		var description: String = str(entry.get("description", ""))
		if term != "" and not (term in name.to_lower() or term in description.to_lower()):
			continue
		_add_card(name, description, str(entry.get("image", "")))
		amount += 1
	if amount == 0:
		_rows.add_child(_make_label(
			"Ничего не найдено." if _language() == "ru" else "No entries found.",
			20, Color(0.73, 0.84, 0.92)))


func _add_card(name: String, description: String, image_path: String) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style(Color(0.062, 0.11, 0.19), 16))
	_rows.add_child(card)

	var horizontal: HBoxContainer = HBoxContainer.new()
	horizontal.add_theme_constant_override("separation", 16)
	card.add_child(horizontal)

	if image_path != "" and ResourceLoader.exists(image_path):
		var picture: TextureRect = TextureRect.new()
		picture.name = "ArticleImage"
		picture.texture = load(image_path) as Texture2D
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(152, 110) if size.x >= 690.0 else Vector2(98, 95)
		picture.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		horizontal.add_child(picture)

	var copy: VBoxContainer = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 7)
	horizontal.add_child(copy)
	copy.add_child(_make_label(name, 22, Color(0.76, 0.94, 1.0)))
	copy.add_child(_make_label(description, 18, Color(0.88, 0.90, 0.95)))


func _planet_picture(world_id: String) -> String:
	var paths: Array[String] = [
		"res://planet_hub/backgrounds/" + world_id + ".png",
		"res://assets/atlas/previews/ngc6822/" + world_id + ".png",
		"res://assets/atlas/planets/" + world_id + ".png"
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return path
	return ""


func _entries_for(section: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match section:
		"planets":
			var notes: Dictionary = _catalog.get("planet_notes", {})
			for raw_system in _atlas.get("systems", []):
				var system: Dictionary = raw_system
				var sid: String = str(system.get("id", ""))
				if sid == "crossroads":
					continue
				var system_title: String = str(system.get("name_ru", ""))
				for raw_world in system.get("planets", []):
					var planet: Dictionary = raw_world
					var pid: String = str(planet.get("id", ""))
					var note: Dictionary = notes.get(pid, {})
					var inhabited: bool = bool(planet.get("inhabited", planet.get("settled", false)))
					var description: String = str(note.get("description", ""))
					if inhabited:
						description = "Обитаемая · " + str(RACE_BY_SYSTEM.get(sid, "Жители")) + ". " + description
						if note.has("building"):
							description += " Сооружение: " + str(note.get("building"))
					else:
						description = "Необитаемая. " + description
					result.append({"title": str(planet.get("name_ru", pid)) + " · " + system_title,
						"description": description, "image": _planet_picture(pid)})
			result.append({"title":"Перекрёсток миров",
				"description":"Особая область космоса, где находится разумная живая жидкая планета, отвечающая колебаниями и вибрациями.",
				"image":""})
		"stations":
			for raw in _catalog.get("stations", []):
				var station: Dictionary = raw
				result.append({"title":station.get("title",""),
					"description":station.get("description",""),
					"image":station.get("image","")})
		"races":
			for raw in _catalog.get("races", []):
				var race: Dictionary = raw
				result.append({"title":race.get("title",""),
					"description":race.get("description",""),
					"image":race.get("image","")})
		"characters":
			var char_roles: Dictionary = _catalog.get("character_roles", {})
			var identities: Dictionary = _profiles.get("characters", {})
			var where: Dictionary = {}
			for raw_system in _atlas.get("systems", []):
				var system: Dictionary = raw_system
				for raw_world in system.get("planets", []):
					var world: Dictionary = raw_world
					where[str(world.get("id",""))] = str(world.get("name_ru",""))
			for raw_station in _catalog.get("stations", []):
				var station: Dictionary = raw_station
				where[str(station.get("id",""))] = str(station.get("title",""))
			var ids: Array = identities.keys()
			ids.sort()
			for key in ids:
				var identity: Dictionary = identities[key]
				var ident: String = str(key)
				var role: String = str(char_roles.get(ident, identity.get("role", "")))
				var picture: String = "res://planet_hub/characters/" + str(identity.get("portrait_template", ""))
				result.append({"title":str(identity.get("name", ident)),
					"description":role + " Место: " + str(where.get(ident, ident)) + ".",
					"image":picture})
		"science":
			var lang: String = _language()
			for raw in _science.get("topics", []):
				var topic: Dictionary = raw
				var titles: Dictionary = topic.get("title", {})
				var answers: Dictionary = topic.get("answers", {})
				var variants: Array = answers.get(lang, answers.get("ru", []))
				var description: String = str(variants[0]) if not variants.is_empty() else ""
				result.append({"title":str(titles.get(lang, titles.get("ru",""))),
					"description":description, "image":""})
		"terms":
			for raw in _catalog.get("terms", []):
				var term: Dictionary = raw
				var prefix: String = "Фантастика · " if str(term.get("kind", "")) == "fiction" else "Наука · "
				result.append({"title":term.get("title",""),
					"description":prefix + str(term.get("description","")),
					"image":term.get("image","")})
	return result
