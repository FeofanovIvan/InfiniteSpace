extends Control
## Native story checkpoint catalogue. The newest chapter returns to the main
## save; previous chapter sections replay in an independent progress lane.

signal arc_chosen(arc_id: String)

const StoryProgress: Script = preload("res://scripts/StoryProgress.gd")
const WORDS: Dictionary = {
	"ru": {"title": "ИСТОРИЯ МИКИ", "chapter1": "ГЛАВА 1 · ПЕРВЫЙ ПОЛЁТ", "chapter2": "ГЛАВА 2 · НОВАЯ ГАЛАКТИКА", "prologue": "Предисловие · Начало пути", "earth": "Земля · Первая посадка", "mars": "Марс · Встреча с Бабблом", "station": "Станция · Путь к галактикам", "chapter02": "Большое Магелланово Облако", "unlocked": "Доступно", "complete": "Пройдено", "locked": "Закрыто", "latest": "Последнее сохранение", "hint": "Автосохранение происходит при открытии каждой сюжетной точки.", "close": "Закрыть"},
	"en": {"title": "MIKA'S STORY", "chapter1": "CHAPTER 1 · FIRST FLIGHT", "chapter2": "CHAPTER 2 · NEW GALAXY", "prologue": "Prologue · The Journey Begins", "earth": "Earth · First Landing", "mars": "Mars · Meeting Bubble", "station": "Space Station · A New Route", "chapter02": "Large Magellanic Cloud", "unlocked": "Available", "complete": "Completed", "locked": "Locked", "latest": "Latest checkpoint", "hint": "The game autosaves when you reach each story checkpoint.", "close": "Close"},
	"fr": {"title": "L'HISTOIRE DE MIKA", "chapter1": "CHAPITRE 1 · PREMIER VOL", "chapter2": "CHAPITRE 2 · NOUVELLE GALAXIE", "prologue": "Prologue · Le grand départ", "earth": "Terre · Premier atterrissage", "mars": "Mars · Rencontre avec Bubble", "station": "Station spatiale · Nouveau cap", "chapter02": "Grand Nuage de Magellan", "unlocked": "Disponible", "complete": "Terminé", "locked": "Verrouillé", "latest": "Dernière sauvegarde", "hint": "Sauvegarde automatique à chaque nouvelle étape du récit.", "close": "Fermer"},
	"de": {"title": "MIKAS GESCHICHTE", "chapter1": "KAPITEL 1 · ERSTER FLUG", "chapter2": "KAPITEL 2 · NEUE GALAXIE", "prologue": "Prolog · Die Reise beginnt", "earth": "Erde · Erste Landung", "mars": "Mars · Bubble kennenlernen", "station": "Raumstation · Neuer Kurs", "chapter02": "Große Magellansche Wolke", "unlocked": "Verfügbar", "complete": "Abgeschlossen", "locked": "Gesperrt", "latest": "Letzter Spielstand", "hint": "Das Spiel speichert an jedem neuen Kapitelpunkt.", "close": "Schließen"},
	"es": {"title": "LA HISTORIA DE MIKA", "chapter1": "CAPÍTULO 1 · PRIMER VUELO", "chapter2": "CAPÍTULO 2 · NUEVA GALAXIA", "prologue": "Prólogo · Comienza el viaje", "earth": "Tierra · Primer aterrizaje", "mars": "Marte · Conoce a Bubble", "station": "Estación espacial · Nuevo rumbo", "chapter02": "Gran Nube de Magallanes", "unlocked": "Disponible", "complete": "Completado", "locked": "Bloqueado", "latest": "Último guardado", "hint": "El juego guarda al llegar a cada punto de la historia.", "close": "Cerrar"},
	"pt_BR": {"title": "A HISTÓRIA DE MIKA", "chapter1": "CAPÍTULO 1 · PRIMEIRO VOO", "chapter2": "CAPÍTULO 2 · NOVA GALÁXIA", "prologue": "Prólogo · O início da jornada", "earth": "Terra · Primeiro pouso", "mars": "Marte · Conhecendo Bubble", "station": "Estação espacial · Nova rota", "chapter02": "Grande Nuvem de Magalhães", "unlocked": "Disponível", "complete": "Concluído", "locked": "Bloqueado", "latest": "Último salvamento", "hint": "O jogo salva ao alcançar cada ponto da história.", "close": "Fechar"}
}
const CHAPTER_THREE_HEADERS: Dictionary = {
	"ru": "ГЛАВА 3 · МАЛОЕ МАГЕЛЛАНОВО ОБЛАКО",
	"en": "CHAPTER 3 · SMALL MAGELLANIC CLOUD",
	"fr": "CHAPITRE 3 · PETIT NUAGE DE MAGELLAN",
	"de": "KAPITEL 3 · KLEINE MAGELLANSCHE WOLKE",
	"es": "CAPÍTULO 3 · PEQUEÑA NUBE DE MAGALLANES",
	"pt_BR": "CAPÍTULO 3 · PEQUENA NUVEM DE MAGALHÃES"
}
const CHAPTER_TWO_EPISODES: Dictionary = {
	"ru": {
		"chapter02": "Талос · Город грибов",
		"chapter02_molly": "Молли · Росток надежды",
		"chapter02_station": "Лаборатория «Тарантул» · Солнечная энергия",
		"chapter02_departure": "Межгалактический полёт · Новый путь"
	},
	"en": {
		"chapter02": "Talos · The Fungal City",
		"chapter02_molly": "Molly · A Seed of Hope",
		"chapter02_station": "Tarantula Laboratory · Solar Energy",
		"chapter02_departure": "Intergalactic Flight · A New Route"
	},
	"fr": {
		"chapter02": "Talos · La cité des champignons",
		"chapter02_molly": "Molly · Une graine d'espoir",
		"chapter02_station": "Laboratoire Tarentule · Énergie solaire",
		"chapter02_departure": "Voyage intergalactique · Nouveau cap"
	},
	"de": {
		"chapter02": "Talos · Die Pilzstadt",
		"chapter02_molly": "Molly · Ein Keim der Hoffnung",
		"chapter02_station": "Tarantula-Labor · Sonnenenergie",
		"chapter02_departure": "Intergalaktischer Flug · Neuer Kurs"
	},
	"es": {
		"chapter02": "Talos · La ciudad de los hongos",
		"chapter02_molly": "Molly · Una semilla de esperanza",
		"chapter02_station": "Laboratorio Tarántula · Energía solar",
		"chapter02_departure": "Viaje intergaláctico · Nuevo rumbo"
	},
	"pt_BR": {
		"chapter02": "Talos · A cidade dos fungos",
		"chapter02_molly": "Molly · Uma semente de esperança",
		"chapter02_station": "Laboratório Tarântula · Energia solar",
		"chapter02_departure": "Viagem intergaláctica · Novo rumo"
	}
}
const CHAPTER_THREE_LABELS: Dictionary = {
	"ru": "Малое Магелланово Облако · Начало",
	"en": "Small Magellanic Cloud · Arrival",
	"fr": "Petit Nuage de Magellan · Arrivée",
	"de": "Kleine Magellansche Wolke · Ankunft",
	"es": "Pequeña Nube de Magallanes · Llegada",
	"pt_BR": "Pequena Nuvem de Magalhães · Chegada"
}
const CHAPTER_THREE_OKEA_LABELS: Dictionary = {
	"ru": "Окея · Лаборатория красок",
	"en": "Okea · The Color Laboratory",
	"fr": "Okea · Le laboratoire des couleurs",
	"de": "Okea · Das Farbenlabor",
	"es": "Okea · El laboratorio de colores",
	"pt_BR": "Okea · O laboratório de cores"
}
const CHAPTER_THREE_CELA_LABELS: Dictionary = {
	"ru": "Целе · Пещера кристаллов",
	"en": "Cela · The Crystal Cavern",
	"fr": "Cela · La grotte des cristaux",
	"de": "Cela · Die Kristallhöhle",
	"es": "Cela · La cueva de cristales",
	"pt_BR": "Cela · A caverna de cristais"
}
const CHAPTER_THREE_LOTUS_LABELS: Dictionary = {
	"ru": "Лотос · Тайна трёх состояний",
	"en": "Lotus · Three States of Matter",
	"fr": "Lotus · Les trois états de la matière",
	"de": "Lotus · Drei Zustände der Materie",
	"es": "Lotus · Tres estados de la materia",
	"pt_BR": "Lótus · Os três estados da matéria"
}
const CHAPTER_FOUR_LABELS: Dictionary = {
	"ru": "Галактика Барнарда · К ящерам",
	"en": "Barnard's Galaxy · The Lizards",
	"fr": "Galaxie de Barnard · Les lézards",
	"de": "Barnards Galaxie · Die Echsen",
	"es": "Galaxia de Barnard · Los lagartos",
	"pt_BR": "Galáxia de Barnard · Os lagartos"
}
const CHAPTER_FOUR_ARCHEON_LABELS: Dictionary = {
	"ru": "Археон · Поиск ископаемых",
	"en": "Archeon · The Fossil Expedition",
	"fr": "Archeon · La chasse aux fossiles",
	"de": "Archeon · Auf Fossiliensuche",
	"es": "Archeon · La búsqueda de fósiles",
	"pt_BR": "Archeon · A busca por fósseis"
}
const CHAPTER_FOUR_RUNA_LABELS: Dictionary = {
	"ru": "Руна · Тайны эволюции",
	"en": "Runa · Secrets of Evolution",
	"fr": "Runa · Les secrets de l’évolution",
	"de": "Runa · Geheimnisse der Evolution",
	"es": "Runa · Secretos de la evolución",
	"pt_BR": "Runa · Segredos da evolução"
}
const CHAPTER_FIVE_HEADERS: Dictionary = {
	"ru": "ГЛАВА 5 · АНДРОМЕДА",
	"en": "CHAPTER 5 · ANDROMEDA",
	"fr": "CHAPITRE 5 · ANDROMÈDE",
	"de": "KAPITEL 5 · ANDROMEDA",
	"es": "CAPÍTULO 5 · ANDRÓMEDA",
	"pt_BR": "CAPÍTULO 5 · ANDRÔMEDA"
}
const CHAPTER_FIVE_LABELS: Dictionary = {
	"ru": "Андромеда · Начало новой главы",
	"en": "Andromeda · A New Chapter Begins",
	"fr": "Andromède · Un nouveau chapitre",
	"de": "Andromeda · Ein neues Kapitel",
	"es": "Andrómeda · Un nuevo capítulo",
	"pt_BR": "Andrômeda · Um novo capítulo"
}
const CHAPTER_FOUR_HEADERS: Dictionary = {
	"ru": "ГЛАВА 4 · ГАЛАКТИКА БАРНАРДА",
	"en": "CHAPTER 4 · BARNARD'S GALAXY",
	"fr": "CHAPITRE 4 · GALAXIE DE BARNARD",
	"de": "KAPITEL 4 · BARNARDS GALAXIE",
	"es": "CAPÍTULO 4 · GALAXIA DE BARNARD",
	"pt_BR": "CAPÍTULO 4 · GALÁXIA DE BARNARD"
}

const CHAPTER_SIX_HEADERS: Dictionary = {
	"ru": "ГЛАВА 6 · ГАЛАКТИКА ТРЕУГОЛЬНИКА",
	"en": "CHAPTER 6 · TRIANGULUM GALAXY",
	"fr": "CHAPITRE 6 · GALAXIE DU TRIANGLE",
	"de": "KAPITEL 6 · DREIECKSGALAXIE",
	"es": "CAPÍTULO 6 · GALAXIA DEL TRIÁNGULO",
	"pt_BR": "CAPÍTULO 6 · GALÁXIA DO TRIÂNGULO"
}

const CHAPTER_SEVEN_HEADERS: Dictionary = {
	"ru": "ГЛАВА 7 · ПЕРЕКРЁСТОК МИРОВ",
	"en": "CHAPTER 7 · CROSSROADS OF WORLDS",
	"fr": "CHAPITRE 7 · CARREFOUR DES MONDES",
	"de": "KAPITEL 7 · KREUZUNG DER WELTEN",
	"es": "CAPÍTULO 7 · CRUCE DE MUNDOS",
	"pt_BR": "CAPÍTULO 7 · ENCRUZILHADA DE MUNDOS"
}

const CHAPTER_FINAL_EPISODES: Dictionary = {
	"ru": {
		"chapter06": "Треугольник · Прибытие",
		"chapter06_lentis": "Лентис · Нейронная цивилизация",
		"chapter06_gate": "Последние врата · Ребус",
		"chapter07": "Перекрёсток миров · Прибытие",
		"chapter07_living_world": "Живая планета · Разгадка",
		"chapter07_choice": "Выбор концовки",
		"chapter07_return": "После истории · Лентис"
	},
	"en": {
		"chapter06": "Triangulum · Arrival",
		"chapter06_lentis": "Lentis · The Neural Civilization",
		"chapter06_gate": "Last Gates · Rebus",
		"chapter07": "Crossroads of Worlds · Arrival",
		"chapter07_living_world": "Living World · The Mystery",
		"chapter07_choice": "Choose an Ending",
		"chapter07_return": "After the Story · Lentis"
	},
	"fr": {
		"chapter06": "Triangle · Arrivée",
		"chapter06_lentis": "Lentis · La civilisation neuronale",
		"chapter06_gate": "Dernières portes · Rébus",
		"chapter07": "Carrefour des mondes · Arrivée",
		"chapter07_living_world": "Planète vivante · Le mystère",
		"chapter07_choice": "Choisis ta fin",
		"chapter07_return": "Après l’histoire · Lentis"
	},
	"de": {
		"chapter06": "Dreiecksgalaxie · Ankunft",
		"chapter06_lentis": "Lentis · Die neuronale Zivilisation",
		"chapter06_gate": "Letzte Tore · Bilderrätsel",
		"chapter07": "Kreuzung der Welten · Ankunft",
		"chapter07_living_world": "Lebender Planet · Das Geheimnis",
		"chapter07_choice": "Wähle dein Ende",
		"chapter07_return": "Nach der Geschichte · Lentis"
	},
	"es": {
		"chapter06": "Triángulo · Llegada",
		"chapter06_lentis": "Lentis · La civilización neuronal",
		"chapter06_gate": "Últimas puertas · Rébus",
		"chapter07": "Cruce de mundos · Llegada",
		"chapter07_living_world": "Planeta vivo · El misterio",
		"chapter07_choice": "Elige el final",
		"chapter07_return": "Después de la historia · Lentis"
	},
	"pt_BR": {
		"chapter06": "Triângulo · Chegada",
		"chapter06_lentis": "Lentis · A civilização neural",
		"chapter06_gate": "Últimos portões · Rébus",
		"chapter07": "Encruzilhada de mundos · Chegada",
		"chapter07_living_world": "Planeta vivo · O mistério",
		"chapter07_choice": "Escolha o final",
		"chapter07_return": "Depois da história · Lentis"
	}
}

const CHAPTER_FIVE_PHASIS_LABELS: Dictionary = {
	"ru": "Фазис · Магнитные существа",
	"en": "Phasis · The Magnetic Beings",
	"fr": "Fasis · Les êtres magnétiques",
	"de": "Phasis · Die Magnetwesen",
	"es": "Fasis · Los seres magnéticos",
	"pt_BR": "Fásis · Os seres magnéticos"
}

const CHAPTER_FIVE_STATION_LABELS: Dictionary = {
	"ru": "Станция «Перевёрнутая пирамида» · Архив",
	"en": "Inverted Pyramid Station · The Archive",
	"fr": "Station de la Pyramide inversée · Archives",
	"de": "Station der umgekehrten Pyramide · Archiv",
	"es": "Estación Pirámide Invertida · Archivo",
	"pt_BR": "Estação Pirâmide Invertida · Arquivo"
}

const CHAPTER_FIVE_ARCHIVE_LABELS: Dictionary = {
	"ru": "Галактический архив · Сигнал",
	"en": "Galactic Archive · The Signal",
	"fr": "Archives galactiques · Le signal",
	"de": "Galaktisches Archiv · Das Signal",
	"es": "Archivo galáctico · La señal",
	"pt_BR": "Arquivo galáctico · O sinal"
}

const CHAPTER_FIVE_ARRIVAL_LABELS: Dictionary = {
	"ru": "Андромеда · Прибытие",
	"en": "Andromeda · Arrival",
	"fr": "Andromède · Arrivée",
	"de": "Andromeda · Ankunft",
	"es": "Andrómeda · Llegada",
	"pt_BR": "Andrômeda · Chegada"
}

var _veil: ColorRect
var _panel: Panel
var _heading: Label
var _close: Button
var _scroll: ScrollContainer
var _list: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_veil = ColorRect.new()
	_veil.color = Color(0.0, 0.015, 0.06, 0.92)
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = Panel.new()
	_panel.name = "StoryArcArchivePanel"
	_panel.add_theme_stylebox_override("panel", _style(Color("061d35"), Color("34ddff"), 23))
	add_child(_panel)
	_heading = Label.new()
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heading.add_theme_color_override("font_color", Color("eafaff"))
	_panel.add_child(_heading)
	_close = Button.new()
	_close.text = "✕"
	_close.focus_mode = Control.FOCUS_NONE
	_close.pressed.connect(close_browser)
	_close.add_theme_stylebox_override("normal", _style(Color("092c50"), Color("32dfff"), 13))
	_close.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(_close)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 15)
	_scroll.add_child(_list)
	resized.connect(_layout)
	MobileLocale.language_changed.connect(_on_language_changed)
	_layout()


func _style(bg: Color, outline: Color, corners: int) -> StyleBoxFlat:
	var result: StyleBoxFlat = StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = outline
	result.set_border_width_all(2)
	result.set_corner_radius_all(corners)
	return result


func open_browser() -> void:
	visible = true
	_rebuild_items()
	_layout()


func close_browser() -> void:
	visible = false


func _on_language_changed(_locale: String) -> void:
	if visible:
		_rebuild_items()
		_layout()


func _rebuild_items() -> void:
	for item in _list.get_children():
		_list.remove_child(item)
		item.queue_free()
	var words: Dictionary = WORDS.get(MobileLocale.language, WORDS["en"])
	var language: String = str(MobileLocale.language)
	var newest_arc: String = StoryProgress.latest_unlocked_arc()
	var active_arc: String = StoryProgress.current_arc() if StoryProgress.read_mode() == "story" else ""
	var current_labels: Dictionary = {"ru": "Сейчас", "en": "Current", "pt_BR": "Atual", "es": "Actual", "fr": "En cours", "de": "Aktuell"}
	var latest_labels: Dictionary = {"ru": "Последняя достигнутая", "en": "Furthest reached", "pt_BR": "Última alcançada", "es": "Última alcanzada", "fr": "Dernière atteinte", "de": "Zuletzt erreicht"}
	_heading.text = str(words["title"])
	_close.tooltip_text = str(words["close"])
	for arc_id in StoryProgress.known_arcs():
		if arc_id in ["prologue", "chapter02", "chapter03", "chapter04", "chapter05", "chapter06", "chapter07"]:
			var chapter_title: Label = Label.new()
			chapter_title.text = str(CHAPTER_FIVE_HEADERS.get(language, CHAPTER_FIVE_HEADERS["en"])) if arc_id == "chapter05" else str(CHAPTER_FOUR_HEADERS.get(language, CHAPTER_FOUR_HEADERS["en"])) if arc_id == "chapter04" else str(CHAPTER_THREE_HEADERS.get(language, CHAPTER_THREE_HEADERS["en"])) if arc_id == "chapter03" else str(words["chapter2" if arc_id == "chapter02" else "chapter1"])
			# MIKA_V562_CHAPTER_TITLES
			if arc_id == "chapter05":
				chapter_title.text = str(CHAPTER_FIVE_HEADERS.get(language, CHAPTER_FIVE_HEADERS["en"]))
			elif arc_id == "chapter06":
				chapter_title.text = str(CHAPTER_SIX_HEADERS.get(language, CHAPTER_SIX_HEADERS["en"]))
			elif arc_id == "chapter07":
				chapter_title.text = str(CHAPTER_SEVEN_HEADERS.get(language, CHAPTER_SEVEN_HEADERS["en"]))
			chapter_title.custom_minimum_size = Vector2(0.0, 41.0)
			chapter_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			chapter_title.add_theme_font_size_override("font_size", 18)
			chapter_title.add_theme_color_override("font_color", Color("ffcb7b"))
			_list.add_child(chapter_title)
		var available: bool = StoryProgress.is_unlocked(arc_id)
		var completed: bool = StoryProgress.is_completed(arc_id)
		var label: String = str(CHAPTER_FIVE_LABELS.get(language, CHAPTER_FIVE_LABELS["en"])) if arc_id == "chapter05" else str(CHAPTER_FOUR_RUNA_LABELS.get(language, CHAPTER_FOUR_RUNA_LABELS["en"])) if arc_id == "chapter04_runa" else str(CHAPTER_FOUR_ARCHEON_LABELS.get(language, CHAPTER_FOUR_ARCHEON_LABELS["en"])) if arc_id == "chapter04_archeon" else str(CHAPTER_FOUR_LABELS.get(language, CHAPTER_FOUR_LABELS["en"])) if arc_id == "chapter04" else str(CHAPTER_THREE_LOTUS_LABELS.get(language, CHAPTER_THREE_LOTUS_LABELS["en"])) if arc_id == "chapter03_lotus" else str(CHAPTER_THREE_LABELS.get(language, CHAPTER_THREE_LABELS["en"])) if arc_id == "chapter03" else str(CHAPTER_THREE_OKEA_LABELS.get(language, CHAPTER_THREE_OKEA_LABELS["en"])) if arc_id == "chapter03_okea" else str(CHAPTER_THREE_CELA_LABELS.get(language, CHAPTER_THREE_CELA_LABELS["en"])) if arc_id == "chapter03_cela" else str((CHAPTER_TWO_EPISODES.get(language, CHAPTER_TWO_EPISODES["en"]) as Dictionary).get(arc_id, words.get(arc_id, arc_id)))
		# MIKA_V562_EPISODE_LABELS
		if arc_id == "chapter05":
			label = str(CHAPTER_FIVE_ARRIVAL_LABELS.get(language, CHAPTER_FIVE_ARRIVAL_LABELS["en"]))
		elif arc_id == "chapter05_phasis":
			label = str(CHAPTER_FIVE_PHASIS_LABELS.get(language, CHAPTER_FIVE_PHASIS_LABELS["en"]))
		elif arc_id == "chapter05_station":
			label = str(CHAPTER_FIVE_STATION_LABELS.get(language, CHAPTER_FIVE_STATION_LABELS["en"]))
		elif arc_id == "chapter05_archive":
			label = str(CHAPTER_FIVE_ARCHIVE_LABELS.get(language, CHAPTER_FIVE_ARCHIVE_LABELS["en"]))
		elif arc_id.begins_with("chapter06") or arc_id.begins_with("chapter07"):
			label = str((CHAPTER_FINAL_EPISODES.get(language, CHAPTER_FINAL_EPISODES["en"]) as Dictionary).get(arc_id, arc_id))
		var is_current: bool = arc_id == active_arc
		var is_latest: bool = arc_id == newest_arc and available
		var status: String = str(words["complete"] if completed else words["unlocked"] if available else words["locked"])
		if is_current:
			status += " · " + str(current_labels.get(language, current_labels["en"]))
		if is_latest:
			status += " · " + str(latest_labels.get(language, latest_labels["en"]))
		var entry: Button = Button.new()
		entry.name = "Arc_" + arc_id
		entry.text = ("▶  " if available else "🔒  ") + label + "\n" + status
		entry.alignment = HORIZONTAL_ALIGNMENT_CENTER
		entry.custom_minimum_size = Vector2(0.0, 78.0)
		entry.disabled = not available
		entry.focus_mode = Control.FOCUS_NONE
		entry.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		entry.add_theme_font_size_override("font_size", 20)
		entry.add_theme_color_override("font_color", Color("eaffff"))
		var entry_bg: Color = Color("70501b") if is_latest else (Color("1b6477") if is_current else Color("134767"))
		var entry_border: Color = Color("ffcd70") if is_latest else (Color("b2ffff") if is_current else Color("58d6ff"))
		if is_latest and is_current:
			entry_border = Color("b2ffff")
		entry.add_theme_stylebox_override("normal", _style(entry_bg, entry_border, 15))
		entry.add_theme_stylebox_override("hover", _style(Color("206884"), Color("a2f5ff"), 15))
		entry.add_theme_stylebox_override("disabled", _style(Color("14263d"), Color("35526b"), 15))
		entry.pressed.connect(_choose_arc.bind(arc_id))
		_list.add_child(entry)
	var hint: Label = Label.new()
	hint.text = str(words["hint"])
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(0.0, 85.0)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("95c9e8"))
	_list.add_child(hint)


func _choose_arc(arc_id: String) -> void:
	if not StoryProgress.is_unlocked(arc_id):
		return
	close_browser()
	arc_chosen.emit(arc_id)


func _layout() -> void:
	if _panel == null:
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 180.0 or view.y < 180.0:
		return
	var safe: Rect2 = MobileLocale.safe_rect(view)
	var w: float = minf(710.0, safe.size.x - 24.0)
	var h: float = minf(620.0, safe.size.y - 24.0)
	_panel.position = safe.position + (safe.size - Vector2(w, h)) * 0.5
	_panel.size = Vector2(w, h)
	_heading.position = Vector2(65.0, 17.0)
	_heading.size = Vector2(w - 130.0, 55.0)
	_heading.add_theme_font_size_override("font_size", clampi(roundi(w * 0.045), 19, 28))
	_close.position = Vector2(w - 66.0, 16.0)
	_close.size = Vector2(48.0, 48.0)
	_scroll.position = Vector2(30.0, 95.0)
	_scroll.size = Vector2(w - 60.0, h - 119.0)
