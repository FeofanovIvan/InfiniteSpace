extends Control
## v58 educational game carousel: original Play Town cards and minigames.
## The cockpit background is retained, but Miko, crew, simulator, shop,
## capacity and speed cards are intentionally absent.
signal closed
signal crystals_earned(units: int)

# v91: real live flight sky as simulator background.
const MIKO_REAL_SPACE_BACKGROUND = preload("res://simulator_ui/scripts/real_space_background.gd")
const CRYSTAL_TEXTURE: Texture2D = preload("res://planet_hub/assets/v68_neon/crystal_reference.png")
const CRYSTAL_PANEL_TEXTURE: Texture2D = preload("res://planet_hub/assets/v68_neon/crystals_panel.png")
# v79: use the actual PlanetHub bottom_hud scene script for the crystal counter.
const HUB_CRYSTAL_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
# v81.1: exact PlanetHub game frames and translated captions.
const HUB_GAME_CARD = preload("res://simulator_ui/scripts/simulator_game_card.gd")
const V81_GAME_NAMES: Dictionary = {
	"puzzle": {"ru": "Пазлы", "en": "Puzzles", "fr": "Puzzles", "de": "Puzzles", "es": "Puzles", "pt_BR": "Quebra-cabeças"},
	"wardrobe": {"ru": "Сортировка одежды", "en": "Sort clothes", "fr": "Trier les vêtements", "de": "Kleidung sortieren", "es": "Ordenar la ropa", "pt_BR": "Separar roupas"},
	"matching_pairs": {"ru": "Найди пары", "en": "Match pairs", "fr": "Trouve les paires", "de": "Paare finden", "es": "Encuentra parejas", "pt_BR": "Encontre os pares"},
	"animal_habitat": {"ru": "Среда обитания", "en": "Animal habitats", "fr": "Habitats animaux", "de": "Tierlebensräume", "es": "Hábitats animales", "pt_BR": "Habitats animais"},
	"profession": {"ru": "Профессии", "en": "Jobs", "fr": "Métiers", "de": "Berufe", "es": "Profesiones", "pt_BR": "Profissões"},
	"letter_trace": {"ru": "Пиши буквы", "en": "Trace letters", "fr": "Trace les lettres", "de": "Buchstaben schreiben", "es": "Traza letras", "pt_BR": "Trace as letras"},
	"word_trace": {"ru": "Пиши слова", "en": "Trace words", "fr": "Trace les mots", "de": "Wörter schreiben", "es": "Traza palabras", "pt_BR": "Trace as palavras"},
	"word_build": {"ru": "Составь слово", "en": "Build a word", "fr": "Forme un mot", "de": "Wort bilden", "es": "Forma palabras", "pt_BR": "Forme palavras"},
	"shape_build": {"ru": "Построй фигуру", "en": "Build shapes", "fr": "Construis des formes", "de": "Formen bauen", "es": "Construye figuras", "pt_BR": "Monte formas"},
	"draw_this": {"ru": "Нарисуй", "en": "Draw it", "fr": "Dessine", "de": "Zeichne", "es": "Dibuja", "pt_BR": "Desenhe"},
	"pick_number": {"ru": "Выбери число", "en": "Pick a number", "fr": "Choisis un nombre", "de": "Zahl auswählen", "es": "Elige un número", "pt_BR": "Escolha um número"},
	"buy_groceries": {"ru": "Список покупок", "en": "Shopping list", "fr": "Liste de courses", "de": "Einkaufsliste", "es": "Lista de compras", "pt_BR": "Lista de compras"},
	"count_groceries": {"ru": "Напиши число", "en": "Write a number", "fr": "Écris un nombre", "de": "Zahl schreiben", "es": "Escribe un número", "pt_BR": "Escreva um número"},
	"product_count": {"ru": "Посчитай продукты", "en": "Count groceries", "fr": "Compte les produits", "de": "Produkte zählen", "es": "Cuenta productos", "pt_BR": "Conte os produtos"},
	"pizza": {"ru": "Пицца и дроби", "en": "Pizza fractions", "fr": "Fractions de pizza", "de": "Pizza und Brüche", "es": "Fracciones de pizza", "pt_BR": "Frações de pizza"},
	"roll_ball": {"ru": "Лабиринт", "en": "Maze", "fr": "Labyrinthe", "de": "Labyrinth", "es": "Laberinto", "pt_BR": "Labirinto"},
	"color_mix": {"ru": "Смешай краски", "en": "Mix colors", "fr": "Mélange les couleurs", "de": "Farben mischen", "es": "Mezcla colores", "pt_BR": "Misture cores"},
	"build_path": {"ru": "Построй путь", "en": "Build a path", "fr": "Construis un chemin", "de": "Weg bauen", "es": "Construye un camino", "pt_BR": "Construa um caminho"},
	"piano": {"ru": "Пианино", "en": "Piano", "fr": "Piano", "de": "Klavier", "es": "Piano", "pt_BR": "Piano"},
}

const BackArrowGlyph = preload("res://simulator_ui/back_arrow_glyph.gd")
const SHIP_TEXTURE: Texture2D = preload("res://assets/ui/miko_ship_menu_circle.png")
const BACK_TEXTURE: Texture2D = preload("res://assets/ui/bridge_back.png")
const CATALOG_PATH: String = "res://education/playtown_catalog.json"
# v94: first seven legacy lessons + three reserved future scenes.
const V94_GAME_CARD = preload("res://simulator_ui/scripts/approved_simulator_card.gd")
const V94_APPROVED_GAMES: Array[Dictionary] = [
	{"id": "sim_01", "icon": "res://simulator_ui/assets/approved_icons/sim_01_trace_letters.png", "source_id": "letter_trace"},
	{"id": "sim_02", "icon": "res://simulator_ui/assets/approved_icons/sim_02_write_words.png", "source_id": "word_trace"},
	{"id": "sim_03", "icon": "res://simulator_ui/assets/approved_icons/sim_03_spell_words.png", "source_id": "word_build"},
	{"id": "sim_04", "icon": "res://simulator_ui/assets/approved_icons/sim_04_match_shapes.png", "source_id": "shape_build"},
	{"id": "sim_05", "icon": "res://simulator_ui/assets/approved_icons/sim_05_draw_rocket.png", "source_id": "draw_this"},
	{"id": "sim_06", "icon": "res://simulator_ui/assets/approved_icons/sim_06_choose_number.png", "source_id": "pick_number"},
	{"id": "sim_07", "icon": "res://simulator_ui/assets/approved_icons/sim_07_trace_numbers.png", "source_id": "count_groceries"},
	{"id": "sim_08", "icon": "res://simulator_ui/assets/approved_icons/sim_08_daily_routine.png", "scene": "res://simulator_ui/scenes/sim_08_actioncards.tscn"},
	{"id": "sim_09", "icon": "res://simulator_ui/assets/approved_icons/sim_09_reward_star.png", "scene": "res://simulator_ui/scenes/sim_09_whereisit.tscn"},
	{"id": "sim_10", "icon": "res://simulator_ui/assets/approved_icons/sim_10_sort_shapes.png", "scene": "res://simulator_ui/scenes/sim_10_colorsort.tscn"},
	{"id": "sim_11", "icon": "res://simulator_ui/assets/approved_icons/sim_11_bubble_care.png", "scene": "res://bubble/scenes/care_room_actions_camera.tscn"}
]
const V94_GAME_NAMES: Dictionary = {
	"sim_01": {
		"ru": "Обведи буквы",
		"en": "Trace Letters",
		"fr": "Trace les lettres",
		"de": "Buchstaben nachspuren",
		"es": "Repasa las letras",
		"pt_BR": "Contorne as letras"
	},
	"sim_02": {
		"ru": "Обведи слова",
		"en": "Trace Words",
		"fr": "Trace les mots",
		"de": "Worter nachspuren",
		"es": "Repasa las palabras",
		"pt_BR": "Contorne as palavras"
	},
	"sim_03": {
		"ru": "Собери слово",
		"en": "Build a Word",
		"fr": "Forme un mot",
		"de": "Wort bilden",
		"es": "Forma una palabra",
		"pt_BR": "Monte uma palavra"
	},
	"sim_04": {
		"ru": "Собери фигуру",
		"en": "Build Shapes",
		"fr": "Construis les formes",
		"de": "Formen bauen",
		"es": "Construye figuras",
		"pt_BR": "Monte as formas"
	},
	"sim_05": {
		"ru": "Нарисуй это",
		"en": "Draw It",
		"fr": "Dessine",
		"de": "Zeichne es",
		"es": "Dibujalo",
		"pt_BR": "Desenhe"
	},
	"sim_06": {
		"ru": "Выбери число",
		"en": "Pick Up a Number",
		"fr": "Choisis un nombre",
		"de": "Zahl auswahlen",
		"es": "Elige un numero",
		"pt_BR": "Escolha um numero"
	},
	"sim_07": {
		"ru": "Напиши число",
		"en": "Write a Number",
		"fr": "Ecris un nombre",
		"de": "Zahl schreiben",
		"es": "Escribe un numero",
		"pt_BR": "Escreva um numero"
	},
	"sim_08": {
		"ru": "Действия",
		"en": "Action Cards",
		"fr": "Actions",
		"de": "Aktionen",
		"es": "Acciones",
		"pt_BR": "Acoes"
	},
	"sim_09": {
		"ru": "Где это?",
		"en": "Where Is It?",
		"fr": "Ou est-ce?",
		"de": "Wo ist es?",
		"es": "Donde esta?",
		"pt_BR": "Onde esta?"
	},
	"sim_10": {
		"ru": "Сортировка по цветам",
		"en": "Color Sort",
		"fr": "Trie les couleurs",
		"de": "Farben sortieren",
		"es": "Clasifica colores",
		"pt_BR": "Separe as cores"
	},
	"sim_11": {
		"ru": "Уход за Бабблом",
		"en": "Bubble Care",
		"fr": "Soin de Bubble",
		"de": "Bubble pflegen",
		"es": "Cuidar a Bubble",
		"pt_BR": "Cuidar do Bubble"
	}
}

const ART_ROOT: String = "res://education/playtown/"
const PET_SCENE_PATH: String = "res://bubble/scenes/care_room_actions_camera.tscn"
# v77: standalone Bubble replaces the PlayTown walking dog.
# Footer scene preload removed: sim_11 is the only entry to Bubble Care.
# MIKA_BUBBLE_CARE_HUD_V8_4_8
# MIKA_BUBBLE_ICONS_FIRST_CARD_V8_4_9_2
# MIKA_BUBBLE_CARE_MAIN_HUD_V8_5_0
# Running dog on the main ship screen is the actual Play Town animated character.
# The original dog sprites, puppy mini-games and sounds are copied locally.
const PET_WALK_SPEED: float = 65.0
# v58.6: sizes relative to the previous Play Town ship screen.
const PUPPY_VISUAL_MULTIPLIER: float = 3.0
const EDUCATIONAL_CARD_MULTIPLIER: float = 0.85
const PUPPY_SOURCE_FRAME: float = 512.0
const PUPPY_OLD_SCALE: float = 0.26

var _background: Control
var _header: Control
var _counter: Label
var _crystal_panel: NinePatchRect
var _crystal_divider_glow: ColorRect
var _crystal_divider: ColorRect
var _hub_counter: Control
var _gallery: ScrollContainer
var _strip: HBoxContainer
var _back: Button
var _gesture_layer: Control
var _pointer_kind: String = ""
var _pointer_index: int = -1
var _pointer_origin: Vector2 = Vector2.ZERO
var _pointer_last: Vector2 = Vector2.ZERO
var _pointer_moved: bool = false
var _pressed_card: TextureButton
var _fling_speed: float = 0.0
const DRAG_THRESHOLD: float = 14.0
const MAX_FLING_SPEED: float = 1550.0
var _game_layer: Control
var _game_backdrop: ColorRect
var _viewport_container: SubViewportContainer
var _game_viewport: SubViewport
var _game_back: Button
var _cards: Array[Dictionary] = []
var _crystal_balance: int = 0
var _last_playtown_coins: int = 0
var _playing: bool = false
var _bubble_direct: bool = false
var _pet_sprite: Node2D
var _pet_click_area: Button
var _pet_walk_x: float = 0.0
var _pet_direction: float = 1.0
var _pet_visual_heading: float = 0.0
var _pet_emotion_clock: float = 0.0
var _pet_initial_position: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_background = MIKO_REAL_SPACE_BACKGROUND.new() as Control
	_background.name = "OriginalFlightSpaceBackdrop"
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	var dark: ColorRect = ColorRect.new()
	dark.name = "ReadableCardGalleryTint"
	dark.color = Color(0.005, 0.015, 0.045, 0.40)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dark)
	_header = Control.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)
	_back = Button.new()
	_back.name = "ReturnFromSimulator"
	_style_back_button(_back)
	_back.tooltip_text = "Вернуться к полёту"
	_back.pressed.connect(close_menu)
	_header.add_child(_back)
	_crystal_panel = NinePatchRect.new()
	_crystal_panel.name = "PlanetHubCrystalCapsule"
	_crystal_panel.texture = CRYSTAL_PANEL_TEXTURE
	# v78: Same nine-patch edge proportions as the PlanetHub v68 center capsule,
	# scaled by 68/158 to match the 68px return button rather than stretched.
	_crystal_panel.patch_margin_left = 28
	_crystal_panel.patch_margin_right = 28
	_crystal_panel.patch_margin_top = 19
	_crystal_panel.patch_margin_bottom = 19
	_crystal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_crystal_panel)
	# PlanetHub has TWO cyan divider layers between the crystal and number.
	_crystal_divider_glow = ColorRect.new()
	_crystal_divider_glow.name = "PlanetHubCounterDividerGlow"
	_crystal_divider_glow.color = Color(0.11, 0.76, 1.0, 0.34)
	_crystal_divider_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_crystal_divider_glow)
	_crystal_divider = ColorRect.new()
	_crystal_divider.name = "PlanetHubCounterDivider"
	_crystal_divider.color = Color(0.57, 0.92, 1.0, 0.94)
	_crystal_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_crystal_divider)
	var crystal: TextureRect = TextureRect.new()
	crystal.name = "ActualBlueCrystal"
	crystal.texture = CRYSTAL_TEXTURE
	crystal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crystal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(crystal)
	_counter = Label.new()
	_counter.name = "CrystalBalanceOnly"
	_counter.add_theme_font_size_override("font_size", 31)
	_counter.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0))
	_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter.text = "0"
	_header.add_child(_counter)
	_install_exact_hub_counter()
	_gallery = ScrollContainer.new()
	_gallery.name = "OriginalPlayTownCards_HorizontalSwipe"
	# The gallery is a fully transparent swipe surface with no navigation arrows
	# or scrolling chrome. Touch and mouse gestures use the same controller.
	_gallery.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_gallery.follow_focus = false
	_gallery.clip_contents = true
	_gallery.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_gallery)
	_strip = HBoxContainer.new()
	_strip.name = "PlayTownEducation_CardStrip"
	_strip.alignment = BoxContainer.ALIGNMENT_BEGIN
	_strip.add_theme_constant_override("separation", 20)
	_gallery.add_child(_strip)
	_strip.add_theme_constant_override("separation", 28)
	_load_original_catalog()
	# Bubble Care now opens directly from the flight button.
	_v1151p24_add_planet_cards()
	MobileLocale.language_changed.connect(_v81_refresh_game_titles)
	_v81_refresh_game_titles()
	# Transparent hit layer above every card: it differentiates swipes from taps,
	# so dragging a card cannot accidentally launch its mini-game.
	_gesture_layer = Control.new()
	_gesture_layer.name = "TransparentSwipeAndTapArea"
	_gesture_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_gesture_layer.clip_contents = true
	add_child(_gesture_layer)
	# v8.4.9: no footer Bubble or invisible touch hotspot; open care via card 1.
	_pet_sprite = null
	_pet_click_area = null
	_game_layer = Control.new()
	_game_layer.name = "PlayTownOriginalGameRunner"
	_game_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_layer.clip_contents = true
	_game_layer.visible = false
	add_child(_game_layer)
	# Shield the mini-game from the simulator background even if its scene has alpha.
	_game_backdrop = ColorRect.new()
	_game_backdrop.name = "FullScreenGameBackground"
	_game_backdrop.color = Color("061225")
	_game_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_layer.add_child(_game_backdrop)
	_game_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport_container = SubViewportContainer.new()
	_viewport_container.name = "GameViewportInputForwarding"
	# Same pixel size as the device screen; no 1536×768 window inside the menu.
	_viewport_container.stretch = true
	_viewport_container.stretch_shrink = 1
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_layer.add_child(_viewport_container)
	_game_viewport = SubViewport.new()
	_game_viewport.name = "OriginalPlayTownGameViewport"
	# v88: game viewport resolution is controlled by full-size SubViewportContainer.
	_game_viewport.handle_input_locally = true
	_game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_container.add_child(_game_viewport)
	_game_back = Button.new()
	_game_back.name = "ReturnToEducationalCards"
	_game_back.text = ""
	_style_back_button(_game_back)
	_game_back.pressed.connect(_return_to_cards)
	_game_layer.add_child(_game_back)
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null and portal.has_signal("game_finished"):
		portal.connect("game_finished", _return_to_cards)
	var coins: Node = get_node_or_null("/root/GameState")
	if coins != null and coins.has_signal("coin_balance_changed"):
		coins.connect("coin_balance_changed", _on_coins_changed)
	resized.connect(_reflow)
	_reflow()


func _style_back_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = ""
	var style := StyleBoxFlat.new()
	style.bg_color = Color("061c38")
	style.border_color = Color("26dfff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.04, 0.64, 1.0, 0.47)
	style.shadow_size = 6
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("113a60")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var glyph: Control = BackArrowGlyph.new()
	glyph.name = "ThickNeonBackArrow"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _install_exact_hub_counter() -> void:
	# Reuse the actual PlanetHub v68 bottom HUD, not a second recreation.
	# The only visible part is its real center counter (art, separators and text).
	_crystal_panel.hide()
	_crystal_divider_glow.hide()
	_crystal_divider.hide()
	var old_crystal: TextureRect = _header.get_node("ActualBlueCrystal") as TextureRect
	old_crystal.hide()
	_counter.hide()
	_hub_counter = HUB_CRYSTAL_HUD.new() as Control
	_hub_counter.name = "ExactPlanetHubCounter_OriginalBottomHud"
	_hub_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Give the HUD its real 1680 x 158 design canvas before _ready().
	_hub_counter.size = Vector2(1680.0, 158.0)
	_header.add_child(_hub_counter)
	# Side controls belong to the PlanetHub, not the simulator.
	var simulator_button: Control = _hub_counter.get_node("SimulatorButton") as Control
	var launch_button: Control = _hub_counter.get_node("LaunchButton") as Control
	simulator_button.hide()
	launch_button.hide()
	_hub_counter.set("crystal_count", _crystal_balance)


func _v81_game_title(game_id: String) -> String:
	var available: Dictionary = V94_GAME_NAMES.get(game_id, V81_GAME_NAMES.get(game_id, {}))
	var language: String = str(MobileLocale.language)
	if available.is_empty():
		return game_id.capitalize().replace("_", " ")
	return str(available.get(language, available.get("en", game_id)))


func _v81_refresh_game_titles(_locale: String = "") -> void:
	if _strip == null:
		return
	for child in _strip.get_children():
		var button: TextureButton = child as TextureButton
		if button == null:
			continue
		var game_id: String = str(button.get_meta("game_id", ""))
		if game_id.is_empty():
			continue
		var caption: String = _v81_game_title(game_id)
		button.tooltip_text = caption
		var frame: Control = button.get_node_or_null("PlanetHubGameFrame") as Control
		if frame == null:
			continue
		frame.set("card_title", caption)
		# Reserved artwork space remains an empty grid for future illustration.
		var placeholder: Label = frame.get_node_or_null("ImagePlaceholder") as Label
		if placeholder != null:
			placeholder.visible = false


func _load_original_catalog() -> void:
	# v94: the original 19-game catalog is a *library*, never removed.
	# Only the 10 approved cards are visible in the educational simulator.
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("Missing original Play Town catalog: " + CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not (parsed is Array):
		push_error("Invalid original Play Town catalog")
		return
	var legacy_by_id: Dictionary = {}
	for raw_info in parsed:
		if raw_info is Dictionary:
			legacy_by_id[str(raw_info.get("id", ""))] = raw_info
	for specification in V94_APPROVED_GAMES:
		if str(specification.get("id", "")) == "sim_11":
			continue  # Bubble lives in the main flight HUD only.
		var game_id: String = str(specification.get("id", ""))
		var icon_path: String = str(specification.get("icon", ""))
		var scene_path: String = str(specification.get("scene", ""))
		var original_art: String = ""
		var source_id: String = str(specification.get("source_id", ""))
		if not source_id.is_empty():
			var original: Dictionary = legacy_by_id.get(source_id, {})
			if original.is_empty():
				push_error("v94: missing source game " + source_id)
				continue
			scene_path = ART_ROOT + str(original.get("scene", ""))
			original_art = ART_ROOT + str(original.get("texture", ""))
		if not ResourceLoader.exists(scene_path) or not ResourceLoader.exists(icon_path):
			push_error("v94: missing approved scene or icon: " + scene_path + " / " + icon_path)
			continue
		var info: Dictionary = specification.duplicate(true)
		info["scene_path"] = scene_path
		_cards.append(info)
		var button := TextureButton.new()
		button.name = "PlayTownCard_" + game_id
		button.texture_normal = null
		button.set_meta("game_id", game_id)
		button.set_meta("original_art_path", original_art)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.tooltip_text = _v81_game_title(game_id)
		button.custom_minimum_size = Vector2(255.0, 315.0)
		button.pressed.connect(_open_game.bind(scene_path))
		_strip.add_child(button)
		var frame: Control = V94_GAME_CARD.new() as Control
		frame.name = "PlanetHubGameFrame"
		frame.set("card_title", _v81_game_title(game_id))
		frame.set("card_subtitle", "")
		frame.set("card_description", "")
		frame.set("image_fit_mode", "contain")
		frame.set("image_path", icon_path)
		button.add_child(frame)
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_stats(flight_crystals: int, _capacity: int, _ship_speed: float) -> void:
	_crystal_balance = maxi(0, flight_crystals)
	if _counter != null:
		_counter.text = str(_crystal_balance)
		_reflow()  # v78: refit the same PlanetHub digit-size rule as balance changes.


func open_menu(view: Vector2) -> void:
	_bubble_direct = false
	size = view
	visible = true
	_return_to_cards()
	_reflow()



# Open the EXISTING Bubble Care scene using the simulator's actual SubViewport,
# native back button, game exit, language and game-state wiring. No new actor.
func open_bubble_care_direct(view: Vector2) -> void:
	if _playing:
		return
	_bubble_direct = true
	size = view
	visible = true
	_reflow()
	_open_game(PET_SCENE_PATH)
	if not _playing:
		_bubble_direct = false
		visible = false

func close_menu() -> void:
	_return_to_cards()
	visible = false
	closed.emit()


func _open_pet_home() -> void:
	# Use the original Play Town PetHome scene and all original gameplay actions.
	# The Miko-specific duplicate unlocks pet actions without Play Town shop stock.
	if _playing:
		return
	_open_game(PET_SCENE_PATH)


func _open_game(scene_path: String) -> void:
	if _playing or not ResourceLoader.exists(scene_path):
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("Cannot load original Play Town game: " + scene_path)
		return
	# Reuse the language selected in Miko for the real Play Town lessons.
	var language: Node = get_node_or_null("/root/LanguageService")
	if language != null:
		var locale: String = str(MobileLocale.language)
		if locale == "pt_BR":
			locale = "pt"
		language.call("set_locale", locale, false)
	var coins: Node = get_node_or_null("/root/GameState")
	if coins != null:
		_last_playtown_coins = int(coins.call("get_coin_balance"))
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null:
		portal.call("start_game", scene_path)
	var original: Node = packed.instantiate()
	original.name = "UnchangedGameFromSafeCityKids"
	_game_viewport.add_child(original)
	_playing = true
	_gallery.visible = false
	_gesture_layer.visible = false
	# Footer Bubble removed; the care card still launches its original scene.
	_pointer_kind = ""
	_fling_speed = 0.0
	_header.visible = false
	_game_layer.visible = true
	_reflow()


func _on_coins_changed(balance: int) -> void:
	if not _playing:
		return
	var gained: int = maxi(0, balance - _last_playtown_coins)
	_last_playtown_coins = balance
	if gained > 0:
		crystals_earned.emit(gained)
		_crystal_balance = mini(50, _crystal_balance + gained)
		_counter.text = str(_crystal_balance)
		_reflow()  # v78: refit the same PlanetHub digit-size rule as balance changes.


func _return_to_cards() -> void:
	if _bubble_direct and _playing:
		_bubble_direct = false
		close_menu()
		return

	_playing = false
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null:
		portal.call("stop_game")
	for child in _game_viewport.get_children():
		child.queue_free()
	_game_layer.visible = false
	_gallery.visible = true
	_gesture_layer.visible = true
	# The gallery shows cards only; no footer character or click hotspot.
	_pointer_kind = ""
	_fling_speed = 0.0
	_header.visible = true


func _card_under_point(screen_point: Vector2) -> TextureButton:
	for child in _strip.get_children():
		var card: TextureButton = child as TextureButton
		if card != null and card.get_global_rect().has_point(screen_point):
			return card
	return null


func _gesture_begin(kind: String, pointer_index: int, screen_point: Vector2) -> void:
	if _pointer_kind != "" or not _gesture_layer.get_global_rect().has_point(screen_point):
		return
	_pointer_kind = kind
	_pointer_index = pointer_index
	_pointer_origin = screen_point
	_pointer_last = screen_point
	_pointer_moved = false
	_pressed_card = _card_under_point(screen_point)
	_fling_speed = 0.0


func _gesture_move(screen_point: Vector2) -> void:
	if _pointer_kind == "":
		return
	var delta_x: float = screen_point.x - _pointer_last.x
	if screen_point.distance_to(_pointer_origin) > DRAG_THRESHOLD:
		_pointer_moved = true
	if _pointer_moved:
		var max_scroll: int = maxi(0, roundi(_strip.size.x - _gallery.size.x))
		var next_scroll: int = clampi(roundi(float(_gallery.scroll_horizontal) - delta_x), 0, max_scroll)
		_gallery.scroll_horizontal = next_scroll
		_fling_speed = clampf(-delta_x / maxf(get_process_delta_time(), 0.016), -MAX_FLING_SPEED, MAX_FLING_SPEED)
	_pointer_last = screen_point


func _gesture_end(screen_point: Vector2) -> void:
	if _pointer_kind == "":
		return
	var clicked: TextureButton = _pressed_card
	var was_swipe: bool = _pointer_moved
	_pointer_kind = ""
	_pointer_index = -1
	_pressed_card = null
	if not was_swipe and clicked != null and clicked == _card_under_point(screen_point):
		_fling_speed = 0.0
		# The original TextureButton owns the signal and launches its game.
		clicked.pressed.emit()
	elif not was_swipe:
		_fling_speed = 0.0


func _input(event: InputEvent) -> void:
	if not visible or _playing or not _gesture_layer.visible:
		return
	# Input positions are in viewport coordinates, including when the cursor
	# leaves the gallery during a drag. The transparent input area prevents
	# duplicate TextureButton clicks or unwanted releases.
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_gesture_begin("touch", touch.index, touch.position)
		elif _pointer_kind == "touch" and _pointer_index == touch.index:
			_gesture_end(touch.position)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if _pointer_kind == "touch" and _pointer_index == drag.index:
			_gesture_move(drag.position)
	elif event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_gesture_begin("mouse", 0, mouse_button.position)
			elif _pointer_kind == "mouse":
				_gesture_end(mouse_button.position)
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if _pointer_kind == "mouse" and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_gesture_move(motion.position)
	elif event is InputEventPanGesture:
		# Two-finger trackpad swipes on Mac work without dragging a mouse.
		var pan: InputEventPanGesture = event
		if _pointer_kind == "" and _gesture_layer.get_global_rect().has_point(pan.position):
			var max_scroll: int = maxi(0, roundi(_strip.size.x - _gallery.size.x))
			_gallery.scroll_horizontal = clampi(roundi(float(_gallery.scroll_horizontal) + pan.delta.x * 45.0), 0, max_scroll)
			_fling_speed = 0.0


func _process(delta: float) -> void:
	if not visible or _playing or _pointer_kind != "" or absf(_fling_speed) < 8.0:
		return
	var max_scroll: int = maxi(0, roundi(_strip.size.x - _gallery.size.x))
	var next_scroll: int = clampi(roundi(float(_gallery.scroll_horizontal) + _fling_speed * delta), 0, max_scroll)
	if next_scroll == _gallery.scroll_horizontal:
		_fling_speed = 0.0
	else:
		_gallery.scroll_horizontal = next_scroll
		_fling_speed *= exp(-6.0 * delta)


func _reflow() -> void:
	if _background == null or size.x < 10.0 or size.y < 10.0:
		return
	var view: Vector2 = size
	var scale: float = clampf(minf(view.x / 1280.0, view.y / 720.0), 0.62, 1.28)
	_background.position = Vector2.ZERO
	_background.size = view
	_header.position = Vector2.ZERO
	_header.size = view
	# v82: preserve original NinePatch margins by scaling full native HUD canvas.
	var hub_s: float = minf(view.y / 864.0, view.x / 1680.0)
	var counter_s: float = hub_s * 0.80
	var back_s: float = hub_s * 0.60
	var counter_h: float = 158.0 * counter_s
	var counter_w: float = 394.0 * counter_s
	var edge_gap: float = maxf(10.0, 24.0 * hub_s)
	var top_y: float = 20.0 * hub_s
	_back.position = Vector2(edge_gap, top_y)
	_back.size = Vector2.ONE * (158.0 * back_s)
	# Lay out the HUD *once* at original size, then transform every child equally.
	# NinePatch corners stay at their canonical 66px/44px margins internally.
	_hub_counter.size = Vector2(1680.0, 158.0)
	_hub_counter.scale = Vector2.ONE * counter_s
	_hub_counter.position = Vector2(view.x - edge_gap - (643.0 + 394.0) * counter_s, top_y)
	_hub_counter.set("crystal_count", _crystal_balance)
	# v83: game frames end at Bubble top (not viewport bottom).
	# The bottom edge of the counter bounds the TOP of the game gallery.
	var margin: float = maxf(14.0, 22.0 * scale)
	var top_clearance: float = maxf(14.0, 21.0 * scale)
	var cards_top: float = maxf(100.0 * scale, top_y + counter_h + top_clearance)
	# Preserve the previous reserved footer extent is above the lower screen edge
	# by TWO creature half-extents, plus the 8-pixel resting clearance.
	# Use its real +15% scale rather than an arbitrary percentage of screen height.
	var bubble_ui_scale: float = clampf(minf(view.x / 1280.0, view.y / 720.0), 0.60, 1.35)
	var bubble_scale_for_cards: float = 0.368 * bubble_ui_scale
	var bubble_top: float = view.y - 2.0 * (375.0 * bubble_scale_for_cards) - 8.0 * bubble_ui_scale
	# Cards meet the upper boundary of Bubble with only a small visual gap.
	var cards_bottom: float = minf(view.y - 8.0 * scale, bubble_top + 3.0 * bubble_ui_scale)
	var available_height: float = maxf(94.0 * scale, cards_bottom - cards_top)
	var card_height: float = maxf(88.0 * scale, available_height - maxf(4.0, 6.0 * scale))
	var card_width: float = card_height * (430.0 / 540.0)
	for child in _strip.get_children():
		var button: TextureButton = child as TextureButton
		if button == null:
			continue
		button.custom_minimum_size = Vector2(card_width, card_height)
	_gallery.position = Vector2(margin, cards_top)
	_gallery.size = Vector2(maxf(100.0, view.x - margin * 2.0), available_height)
	_gesture_layer.position = _gallery.position
	_gesture_layer.size = _gallery.size
	# v88: fullscreen game viewport at native screen size (no framed subwindow).
	_game_layer.position = Vector2.ZERO
	_game_layer.size = view
	_game_backdrop.position = Vector2.ZERO
	_game_backdrop.size = view
	# Godot automatically adapts the SubViewport's resolution to this Control.
	# Do not multiply Control.scale: scaling causes blur and a letterboxed window.
	_viewport_container.scale = Vector2.ONE
	_viewport_container.position = Vector2.ZERO
	_viewport_container.size = view
	# Exact same style, position and actual pixel size as the hub Back.
	_game_back.position = _back.position
	_game_back.size = _back.size
	# Keep the new 68px exit button; do not shrink it back to the rocket size.
	# Card dimensions and gallery positions intentionally unchanged.

# MIKA TEMP24 / v115.1: append approved PLANET games to existing 11-card simulator.
# This block does not modify any of the 11 original cards or their callbacks.
const _V1151P24_CATALOG: String = "res://simulator_ui/data/temp_planet_cards_v1151p24.json"
const _V1151P24_PLANETS: String = "res://planet_hub/data/planet_game_cards_v104.json"
const _V1151P24_ART: String = "res://simulator_ui/assets/temp_planet_cards_v1151p24/"
var _v1151p24_by_id: Dictionary = {}
var _v1151p24_planet_scenes: Dictionary = {}

func _v1151p24_locale() -> String:
	var locale: String = str(MobileLocale.language)
	if not ["ru", "en", "fr", "de", "es", "pt_BR"].has(locale):
		return "ru"
	return locale

func _v1151p24_title(data: Dictionary, fallback: String) -> String:
	return str(data.get(_v1151p24_locale(), data.get("ru", fallback)))

func _v1151p24_add_planet_cards() -> void:
	if not FileAccess.file_exists(_V1151P24_CATALOG):
		push_warning("MIKA temporary planet games registry missing")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_V1151P24_CATALOG))
	if not (parsed is Dictionary):
		push_error("MIKA temporary planet games registry invalid")
		return
	var games: Array = (parsed as Dictionary).get("entries", [])
	if games.size() != 24:
		push_error("MIKA temporary planet games: expected 24")
		return
	if FileAccess.file_exists(_V1151P24_PLANETS):
		var current: Variant = JSON.parse_string(FileAccess.get_file_as_string(_V1151P24_PLANETS))
		if current is Dictionary:
			_v1151p24_planet_scenes = (current as Dictionary).get("games", {})
	_v1151p24_by_id.clear()
	for raw in games:
		if not (raw is Dictionary):
			continue
		var game: Dictionary = raw as Dictionary
		var game_id: String = str(game.get("id", ""))
		if game_id.is_empty() or _v1151p24_by_id.has(game_id):
			continue
		_v1151p24_by_id[game_id] = game
		var art_path: String = _V1151P24_ART + game_id + ".png"
		var art: Texture2D = load(art_path) as Texture2D
		if art == null:
			push_warning("MIKA missing temporary planet card art: " + art_path)
			continue
		var button: TextureButton = TextureButton.new()
		button.name = "TemporaryPlanetCard_" + game_id
		button.texture_normal = art
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.custom_minimum_size = Vector2(255.0, 315.0)
		var available: bool = not _v1151p24_find_scene(game).is_empty()
		var title_text: String = _v1151p24_title(game.get("title", {}), game_id)
		button.tooltip_text = title_text if available else title_text + " — сцена пока отсутствует"
		var label: Label = Label.new()
		label.name = "PlanetGameTitle"
		label.anchor_left = 0.0
		label.anchor_right = 1.0
		label.anchor_top = 1.0
		label.anchor_bottom = 1.0
		label.offset_left = 0.0
		label.offset_right = 0.0
		label.offset_top = -42.0
		label.offset_bottom = -1.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color("dff7ff") if available else Color("ffb69c"))
		label.text = title_text
		button.add_child(label)
		button.pressed.connect(_v1151p24_open_card.bind(game_id))
		_strip.add_child(button)

func _v1151p24_find_scene(game: Dictionary) -> String:
	# MIKA_FUNGAL_V7_2_LIVE_SCENE_RESOLUTION
	# Resolve installed scene by its actual location even if the card catalogue
	# was loaded before the last version was installed.
	if str(game.get("id", "")) == "lmc__fungal_paths":
		var live_scene: String = "res://planet_hub/games/fungal_paths/FungalPathsArtwork.tscn"
		if ResourceLoader.exists(live_scene) or FileAccess.file_exists(live_scene):
			var packed_game: Resource = load(live_scene)
			if packed_game is PackedScene:
				return live_scene
	var candidates: Array[String] = []
	var current: Dictionary = _v1151p24_planet_scenes.get(str(game.get("id", "")), {})
	var preferred: String = str(current.get("source_scene", ""))
	if preferred.begins_with("res://"):
		candidates.append(preferred)
	for candidate in game.get("scene_candidates", []):
		var path: String = str(candidate)
		if path.begins_with("res://") and not candidates.has(path):
			candidates.append(path)
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""

func _v1151p24_open_card(game_id: String) -> void:
	if _playing or not _v1151p24_by_id.has(game_id):
		return
	var game: Dictionary = _v1151p24_by_id[game_id]
	var scene_path: String = _v1151p24_find_scene(game)
	if scene_path.is_empty():
		var warning: AcceptDialog = AcceptDialog.new()
		warning.title = "Игра ещё не подключена"
		warning.dialog_text = _v1151p24_title(game.get("title", {}), game_id) + "\nСцена мини-игры отсутствует в текущей сборке."
		warning.confirmed.connect(warning.queue_free)
		warning.canceled.connect(warning.queue_free)
		add_child(warning)
		warning.popup_centered_ratio(0.32)
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("MIKA cannot load planet game: " + scene_path)
		return
	# Reuse existing simulator viewport and Back button, without opening a second portal.
	var language: Node = get_node_or_null("/root/LanguageService")
	if language != null:
		var locale: String = str(MobileLocale.language)
		if locale == "pt_BR":
			locale = "pt"
		language.call("set_locale", locale, false)
	var coins: Node = get_node_or_null("/root/GameState")
	if coins != null:
		_last_playtown_coins = int(coins.call("get_coin_balance"))
	var instance: Node = packed.instantiate()
	if instance == null:
		push_error("MIKA could not instantiate planet game: " + scene_path)
		return
	instance.name = "TemporaryPlanetGame_" + game_id
	# MIKA_EARTH_PLAYTOWN_PORTAL_BRIDGE_V1
	# All 24 temporary planet cards use the exact same return bridge as the
	# approved ten simulator cards. Start BEFORE entering the scene tree.
	var planet_portal: Node = get_node_or_null("/root/PlayTownPortal")
	if planet_portal == null or not planet_portal.has_method("start_game"):
		instance.free()
		push_error("MIKA planet game: PlayTownPortal is unavailable")
		return
	planet_portal.call("start_game", scene_path)
	_game_viewport.add_child(instance)
	_playing = true
	_gallery.visible = false
	_gesture_layer.visible = false
	# v8.4.9.2: footer Bubble was removed; planet games launch as usual.
	_pointer_kind = ""
	_fling_speed = 0.0
	_header.visible = false
	_game_layer.visible = true
	_game_back.move_to_front()
	_reflow()
