extends Control
## InfiniteSpace v102 — original MIKA Color Sort V2 with live flight cosmos,
## existing simulator back arrow and GameState crystal rewards.
const FLIGHT_SPACE = preload("res://simulator_ui/scripts/real_space_background.gd")
const BACK_ARROW = preload("res://simulator_ui/back_arrow_glyph.gd")
const CRYSTAL_TEXTURE = preload("res://planet_hub/assets/v68_neon/crystal_reference.png")
## Color Sort / Mika. All shapes, baskets and effects are drawn in Godot.
## One falling object at a time, four randomly assigned color+shape bins.

const SHAPES := ["triangle", "square", "circle", "star"]
const COLOR_KEYS := ["red", "black", "blue", "yellow", "green", "purple", "orange", "pink"]
const COLOR_VALUES := {
	"red": "#ff626c", "black": "#151d29", "blue": "#499fff", "yellow": "#ffd44d",
	"green": "#59e3a0", "purple": "#bb8cff", "orange": "#ff9a50", "pink": "#ff87c7"
}
const TOTAL_ITEMS := 12

const LANGUAGE_NAMES := {
	"en": "English", "ru": "Русский", "pt": "Português", "es": "Español",
	"de": "Deutsch", "fr": "Français"
}
const LANGUAGE_ORDER := ["en", "ru", "pt", "es", "de", "fr"]
const TRANSLATIONS := {
	"en": {"title":"COLOR SORT", "subtitle":"Match BOTH the shape and the color", "score":"Score", "misses":"Missed", "round":"Set", "item":"Item", "new":"NEW SET", "pause":"PAUSE", "resume":"RESUME", "tip":"Drag the falling shape into a basket — or tap a basket", "correct":"Great match! +1", "wrong":"Not this basket. Try another!", "missed":"Oops! It fell through.", "complete":"SET COMPLETE!", "again":"New shapes and colors are ready.", "hole":"EMPTY SPACE"},
	"ru": {"title":"СОРТИРОВКА ЦВЕТОВ", "subtitle":"Совмести И форму, И цвет", "score":"Очки", "misses":"Упало", "round":"Набор", "item":"Фигура", "new":"НОВЫЙ НАБОР", "pause":"ПАУЗА", "resume":"ПРОДОЛЖИТЬ", "tip":"Перетащи фигуру в корзину или нажми на корзину", "correct":"Правильно! +1", "wrong":"Не та корзина. Попробуй ещё!", "missed":"Ой! Фигура провалилась.", "complete":"НАБОР ЗАКОНЧЕН!", "again":"Следующий набор с новыми цветами.", "hole":"ПУСТОЕ МЕСТО"},
	"pt": {"title":"ORGANIZE AS CORES", "subtitle":"Combine a forma E a cor", "score":"Pontos", "misses":"Perdidos", "round":"Rodada", "item":"Peça", "new":"NOVA RODADA", "pause":"PAUSAR", "resume":"CONTINUAR", "tip":"Arraste a forma até uma cesta ou toque na cesta", "correct":"Muito bem! +1", "wrong":"Outra cesta. Tente de novo!", "missed":"Ops! A peça caiu.", "complete":"RODADA CONCLUÍDA!", "again":"Novas formas e cores estão prontas.", "hole":"ESPAÇO VAZIO"},
	"es": {"title":"ORDENA LOS COLORES", "subtitle":"Combina la forma Y el color", "score":"Puntos", "misses":"Caídas", "round":"Ronda", "item":"Figura", "new":"NUEVA RONDA", "pause":"PAUSA", "resume":"CONTINUAR", "tip":"Arrastra la figura a una cesta o toca la cesta", "correct":"¡Muy bien! +1", "wrong":"Esa cesta no. ¡Inténtalo otra vez!", "missed":"¡Uy! La figura cayó.", "complete":"¡RONDA COMPLETADA!", "again":"Nuevas formas y colores te esperan.", "hole":"ESPACIO VACÍO"},
	"de": {"title":"FARBEN SORTIEREN", "subtitle":"Achte auf Form UND Farbe", "score":"Punkte", "misses":"Verpasst", "round":"Runde", "item":"Figur", "new":"NEUE RUNDE", "pause":"PAUSE", "resume":"WEITER", "tip":"Ziehe die Form in einen Korb oder tippe auf einen Korb", "correct":"Super! +1", "wrong":"Falscher Korb. Versuch es erneut!", "missed":"Oh! Die Figur ist durchgefallen.", "complete":"RUNDE GESCHAFFT!", "again":"Neue Formen und Farben warten.", "hole":"LEERER PLATZ"},
	"fr": {"title":"TRIE LES COULEURS", "subtitle":"Associe la forme ET la couleur", "score":"Points", "misses":"Ratés", "round":"Manche", "item":"Forme", "new":"NOUVELLE MANCHE", "pause":"PAUSE", "resume":"REPRENDRE", "tip":"Glisse la forme dans un panier ou touche un panier", "correct":"Bravo ! +1", "wrong":"Pas ce panier. Essaie encore !", "missed":"Oups ! La forme est tombée.", "complete":"MANCHE TERMINÉE !", "again":"Voici de nouvelles formes et couleurs.", "hole":"ESPACE VIDE"}
}
const SHAPE_NAMES := {
	"en": {"triangle":"Triangle", "square":"Square", "circle":"Circle", "star":"Star"},
	"ru": {"triangle":"Треугольник", "square":"Квадрат", "circle":"Круг", "star":"Звезда"},
	"pt": {"triangle":"Triângulo", "square":"Quadrado", "circle":"Círculo", "star":"Estrela"},
	"es": {"triangle":"Triángulo", "square":"Cuadrado", "circle":"Círculo", "star":"Estrella"},
	"de": {"triangle":"Dreieck", "square":"Quadrat", "circle":"Kreis", "star":"Stern"},
	"fr": {"triangle":"Triangle", "square":"Carré", "circle":"Cercle", "star":"Étoile"}
}
const COLOR_NAMES := {
	"en": {"red":"Red", "black":"Black", "blue":"Blue", "yellow":"Yellow", "green":"Green", "purple":"Purple", "orange":"Orange", "pink":"Pink"},
	"ru": {"red":"Красный", "black":"Чёрный", "blue":"Синий", "yellow":"Жёлтый", "green":"Зелёный", "purple":"Фиолетовый", "orange":"Оранжевый", "pink":"Розовый"},
	"pt": {"red":"Vermelho", "black":"Preto", "blue":"Azul", "yellow":"Amarelo", "green":"Verde", "purple":"Roxo", "orange":"Laranja", "pink":"Rosa"},
	"es": {"red":"Rojo", "black":"Negro", "blue":"Azul", "yellow":"Amarillo", "green":"Verde", "purple":"Morado", "orange":"Naranja", "pink":"Rosa"},
	"de": {"red":"Rot", "black":"Schwarz", "blue":"Blau", "yellow":"Gelb", "green":"Grün", "purple":"Lila", "orange":"Orange", "pink":"Rosa"},
	"fr": {"red":"Rouge", "black":"Noir", "blue":"Bleu", "yellow":"Jaune", "green":"Vert", "purple":"Violet", "orange":"Orange", "pink":"Rose"}
}

var _flight_space: Control
var _back_button: Button
var _crystal_panel: Panel
var _crystal_counter: Label
var _session_crystals: int = 0
var _shell_back: Control

var language: String = "en"
var round_number: int = 0
var targets: Array[Dictionary] = []
var deck: Array[Dictionary] = []
var basket_rects: Array[Rect2] = []
var current_shape: Dictionary = {}
var current_y: float = 0.0
var current_x: float = 0.0
var active: bool = false
var dragging: bool = false
var drag_pointer: int = -1
var fall_speed: float = 47.0
var spawn_wait: float = 0.0
var spawned: int = 0
var scored: int = 0
var missed: int = 0
var paused: bool = false
var complete: bool = false
var hovered_bin: int = -1
var effects: Array[Dictionary] = []
var basket_counts: Array[int] = [0, 0, 0, 0]
var success_bin: int = -1
var success_time: float = 0.0
var pulse_time: float = 0.0
var feedback_text: String = ""
var feedback_timer: float = 0.0
var feedback_success: bool = false

var play_top: float = 145.0
var play_bottom: float = 630.0
var basket_width: float = 245.0
var basket_height: float = 200.0
var chute_width: float = 208.0

var title_label: Label
var subtitle_label: Label
var score_label: Label
var tip_label: Label
var info_label: Label
var feedback_label: Label
var round_label: Label
var new_set_button: Button
var pause_button: Button
var language_select: OptionButton
var completed_panel: PanelContainer
var completed_title: Label
var completed_body: Label
var next_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_PASS
	_flight_space = FLIGHT_SPACE.new() as Control
	_flight_space.name = "Sim10OriginalFlightSpace"
	_flight_space.process_mode = Node.PROCESS_MODE_ALWAYS
	_flight_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flight_space.z_index = -20
	add_child(_flight_space)
	_init_ui()
	_build_simulator_hud()
	_sync_language_from_host_or_local()
	_relayout()
	resized.connect(_relayout)
	_start_new_set()
	call_deferred("_hide_host_back")

func _init_ui() -> void:
	title_label = _label(30, Color("ecf9ff"))
	subtitle_label = _label(17, Color("aacfe9"))
	score_label = _label(18, Color("e2f5ff"))
	round_label = _label(17, Color("94daff"))
	tip_label = _label(16, Color("c1def5"))
	info_label = _label(15, Color("84bbda"))
	feedback_label = _label(19, Color("90ffd4"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.visible = false
	
	language_select = OptionButton.new()
	language_select.focus_mode = Control.FOCUS_NONE
	language_select.add_theme_font_size_override("font_size", 16)
	language_select.add_theme_color_override("font_color", Color("e3f4ff"))
	for code in LANGUAGE_ORDER:
		language_select.add_item(LANGUAGE_NAMES[code])
	language_select.item_selected.connect(_on_language_selected)
	add_child(language_select)
	
	new_set_button = _button("NEW SET")
	new_set_button.pressed.connect(_start_new_set)
	pause_button = _button("PAUSE")
	pause_button.pressed.connect(_toggle_pause)
	
	completed_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10294a")
	style.border_color = Color("8bd1ff")
	style.set_border_width_all(3)
	style.set_corner_radius_all(26)
	style.set_content_margin_all(22)
	completed_panel.add_theme_stylebox_override("panel", style)
	add_child(completed_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	completed_panel.add_child(column)
	completed_title = Label.new()
	completed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completed_title.add_theme_font_size_override("font_size", 29)
	completed_title.add_theme_color_override("font_color", Color("f4fdff"))
	column.add_child(completed_title)
	completed_body = Label.new()
	completed_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completed_body.add_theme_font_size_override("font_size", 18)
	completed_body.add_theme_color_override("font_color", Color("badcf4"))
	column.add_child(completed_body)
	next_button = _button("NEXT SET")
	remove_child(next_button)
	next_button.pressed.connect(_start_new_set)
	column.add_child(next_button)
	completed_panel.visible = false

func _build_simulator_hud() -> void:
	_back_button = _button("")
	_back_button.name = "Sim10OnlyNeonBack"
	_back_button.tooltip_text = "Назад / Back"
	_back_button.add_theme_stylebox_override("normal", _button_style(Color("071c38"), Color("49d5f4")))
	_back_button.add_theme_stylebox_override("hover", _button_style(Color("164466"), Color("b2efff")))
	_back_button.add_theme_stylebox_override("pressed", _button_style(Color("1d5472"), Color("e3fbff")))
	_back_button.pressed.connect(_exit_to_simulator)
	var arrow := Control.new()
	arrow.name = "Sim10BackGlyph"
	arrow.set_script(BACK_ARROW)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.add_child(arrow)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_crystal_panel = Panel.new()
	_crystal_panel.name = "Sim10SessionCrystals"
	_crystal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crystal_style := StyleBoxFlat.new()
	crystal_style.bg_color = Color("071c38")
	crystal_style.border_color = Color("4bc6eb")
	crystal_style.set_border_width_all(2)
	crystal_style.set_corner_radius_all(20)
	_crystal_panel.add_theme_stylebox_override("panel", crystal_style)
	add_child(_crystal_panel)
	var icon := TextureRect.new()
	icon.name = "CrystalIcon"
	icon.texture = CRYSTAL_TEXTURE
	icon.position = Vector2(7, 7)
	icon.size = Vector2(46, 45)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crystal_panel.add_child(icon)
	_crystal_counter = Label.new()
	_crystal_counter.name = "CrystalsEarnedThisVisit"
	_crystal_counter.text = "0"
	_crystal_counter.position = Vector2(58, 3)
	_crystal_counter.size = Vector2(80, 54)
	_crystal_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crystal_counter.add_theme_font_size_override("font_size", 28)
	_crystal_counter.add_theme_color_override("font_color", Color.WHITE)
	_crystal_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crystal_panel.add_child(_crystal_counter)

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("edf9ff"))
	button.add_theme_stylebox_override("normal", _button_style(Color("164267"), Color("49d5f4")))
	button.add_theme_stylebox_override("hover", _button_style(Color("225a81"), Color("a9edff")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("d28b3d"), Color("ffd371")))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(button)
	return button

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	return style

func _relayout() -> void:
	var w := size.x
	var h := size.y
	if w < 240.0 or h < 220.0:
		return
	_flight_space.position = Vector2.ZERO
	_flight_space.size = Vector2(w, h)
	_back_button.position = Vector2(23, 17)
	_back_button.size = Vector2(65, 61)
	_crystal_panel.position = Vector2(100, 17)
	_crystal_panel.size = Vector2(140, 61)
	var compact := w < 1050.0
	play_top = 159.0 if compact else 145.0
	play_bottom = h - (76.0 if compact else 79.0)
	basket_width = clampf(w * 0.212, 130.0, 260.0)
	basket_height = maxf(76.0, (play_bottom - play_top - 45.0) * 0.5)
	chute_width = clampf(w * 0.185, 110.0, 242.0)
	basket_rects = [
		Rect2(35.0, play_top + 10.0, basket_width, basket_height),
		Rect2(35.0, play_top + 33.0 + basket_height, basket_width, basket_height),
		Rect2(w - 35.0 - basket_width, play_top + 10.0, basket_width, basket_height),
		Rect2(w - 35.0 - basket_width, play_top + 33.0 + basket_height, basket_width, basket_height)
	]
	fall_speed = maxf(30.0, (play_bottom - play_top) / 10.0)
	# Reserve the upper-left for our single Back button and crystal counter.
	var heading_x := maxf(265.0, w * 0.275)
	title_label.position = Vector2(heading_x, 17)
	title_label.size = Vector2(maxf(215, minf(505.0, w * 0.34)), 40)
	title_label.add_theme_font_size_override("font_size", 23 if compact else 30)
	subtitle_label.position = Vector2(heading_x, 58)
	subtitle_label.size = Vector2(maxf(210, minf(515.0, w * 0.35)), 29)
	subtitle_label.add_theme_font_size_override("font_size", 14 if compact else 17)
	score_label.position = Vector2(32, 99)
	score_label.size = Vector2(maxf(250, w * 0.40), 26)
	round_label.position = Vector2(w * 0.37, 103)
	round_label.size = Vector2(290, 24)
	tip_label.position = Vector2(30, h - 48)
	tip_label.size = Vector2(w - 60, 24)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.position = Vector2(w * 0.5 - 160, play_bottom + 6)
	info_label.size = Vector2(320, 26)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.position = Vector2(w * 0.5 - 200, play_top + 14)
	feedback_label.size = Vector2(400, 28)
	language_select.position = Vector2(w - 193, 19)
	language_select.size = Vector2(164, 40)
	new_set_button.position = Vector2(w - 486, 20)
	new_set_button.size = Vector2(158, 40)
	pause_button.position = Vector2(w - 317, 20)
	pause_button.size = Vector2(116, 40)
	completed_panel.position = Vector2(w / 2.0 - 242.0, h / 2.0 - 102.0)
	completed_panel.size = Vector2(484.0, 204.0)
	if active and not dragging:
		current_x = w * 0.5
	queue_redraw()

func _sync_language_from_host_or_local() -> void:
	var mobile: Node = get_node_or_null("/root/MobileLocale")
	if mobile != null:
		var locale := str(mobile.get("language")).to_lower().split("_")[0]
		if LANGUAGE_ORDER.has(locale):
			language = locale
		language_select.visible = false
		if mobile.has_signal("language_changed"):
			mobile.connect("language_changed", _on_host_language_changed)
		return
	var service: Node = get_node_or_null("/root/LanguageService")
	if service != null:
		var locale := str(service.get("learning_locale")).to_lower().split("_")[0]
		if LANGUAGE_ORDER.has(locale):
			language = locale
		language_select.visible = false
		if service.has_signal("language_changed"):
			service.connect("language_changed", _on_host_language_changed)
		return
	var cfg := ConfigFile.new()
	if cfg.load("user://color_sort_settings.cfg") == OK:
		var saved := str(cfg.get_value("language", "learning", "en"))
		if LANGUAGE_ORDER.has(saved):
			language = saved
	language_select.select(LANGUAGE_ORDER.find(language))

func _on_host_language_changed(_unused: String) -> void:
	var mobile: Node = get_node_or_null("/root/MobileLocale")
	var service: Node = get_node_or_null("/root/LanguageService")
	var locale := ""
	if mobile != null:
		locale = str(mobile.get("language")).to_lower().split("_")[0]
	elif service != null:
		locale = str(service.get("learning_locale")).to_lower().split("_")[0]
	if LANGUAGE_ORDER.has(locale):
		language = locale
	_update_labels()

func _on_language_selected(index: int) -> void:
	language = LANGUAGE_ORDER[index]
	var cfg := ConfigFile.new()
	cfg.set_value("language", "learning", language)
	cfg.save("user://color_sort_settings.cfg")
	_update_labels()
	queue_redraw()

func _t(key: String) -> String:
	return String(TRANSLATIONS[language][key])

func _update_labels() -> void:
	title_label.text = _t("title")
	subtitle_label.text = _t("subtitle")
	score_label.text = "%s: %d    %s: %d" % [_t("score"), scored, _t("misses"), missed]
	round_label.text = "%s %d  ·  %s %d/%d" % [_t("round"), round_number, _t("item"), spawned, TOTAL_ITEMS]
	tip_label.text = _t("tip")
	info_label.text = _t("hole")
	new_set_button.text = _t("new")
	pause_button.text = _t("resume") if paused else _t("pause")
	completed_title.text = _t("complete")
	completed_body.text = "%s: %d/%d\n%s" % [_t("score"), scored, TOTAL_ITEMS, _t("again")]
	next_button.text = _t("new")
	queue_redraw()

func _start_new_set() -> void:
	round_number += 1
	paused = false
	complete = false
	active = false
	dragging = false
	feedback_timer = 0.0
	feedback_label.visible = false
	spawned = 0
	scored = 0
	missed = 0
	effects.clear()
	basket_counts = [0, 0, 0, 0]
	success_bin = -1
	success_time = 0.0
	completed_panel.visible = false
	targets.clear()
	deck.clear()
	var shape_choices := SHAPES.duplicate()
	var color_choices := COLOR_KEYS.duplicate()
	shape_choices.shuffle()
	color_choices.shuffle()
	for i in range(4):
		targets.append({"shape": shape_choices[i], "color": color_choices[i]})
	targets.shuffle()
	for i in range(3):
		for target in targets:
			deck.append(target.duplicate())
	deck.shuffle()
	spawn_wait = 0.2
	_update_labels()

func _toggle_pause() -> void:
	if complete:
		return
	paused = not paused
	_update_labels()

func _spawn_next() -> void:
	if spawned >= TOTAL_ITEMS:
		_finish_round()
		return
	current_shape = deck[spawned].duplicate()
	spawned += 1
	current_x = size.x * 0.5
	current_y = play_top + 67.0
	active = true
	spawn_wait = 0.0
	_update_labels()

func _finish_round() -> void:
	complete = true
	paused = false
	active = false
	dragging = false
	completed_panel.visible = true
	_update_labels()

func _process(delta: float) -> void:
	pulse_time += delta
	if success_time > 0.0:
		success_time = maxf(0.0, success_time - delta)
		if success_time <= 0.0:
			success_bin = -1
	if paused or complete:
		return
	if feedback_timer > 0.0:
		feedback_timer -= delta
		if feedback_timer <= 0.0:
			feedback_label.visible = false
	for i in range(effects.size() - 1, -1, -1):
		var p: Dictionary = effects[i]
		p["position"] = p["position"] + p["velocity"] * delta
		p["velocity"] = p["velocity"] * 0.985 + Vector2(0, 36.0) * delta
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			effects.remove_at(i)
	if active:
		if not dragging:
			current_y += fall_speed * delta
			if current_y >= play_bottom - 22.0:
				_on_missed()
	else:
		if spawn_wait > 0.0:
			spawn_wait -= delta
		else:
			_spawn_next()
	queue_redraw()

func _on_missed() -> void:
	missed += 1
	active = false
	dragging = false
	spawn_wait = 0.7
	_show_feedback(_t("missed"), false)
	_update_labels()

func _show_feedback(message: String, good: bool) -> void:
	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", Color("83f6c9") if good else Color("ffc7a5"))
	feedback_label.visible = true
	feedback_timer = 1.5

func _choose_basket(index: int) -> void:
	if not active or paused or complete or index < 0 or index >= targets.size():
		return
	var goal: Dictionary = targets[index]
	if goal["shape"] == current_shape["shape"] and goal["color"] == current_shape["color"]:
		scored += 1
		# Award exactly once for a newly sorted piece. The next input sees active=false.
		_session_crystals += 1
		_crystal_counter.text = str(_session_crystals)
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state != null and game_state.has_method("add_coins"):
			game_state.call("add_coins", 1)
		basket_counts[index] += 1
		success_bin = index
		success_time = 0.72
		_emit_confetti(basket_rects[index].get_center(), Color(COLOR_VALUES[String(goal["color"])]))
		_show_feedback(_t("correct"), true)
		active = false
		dragging = false
		hovered_bin = -1
		spawn_wait = 0.60
		_update_labels()
	else:
		_show_feedback(_t("wrong"), false)
		current_x = size.x * 0.5
		dragging = false
		hovered_bin = -1

func _emit_confetti(at: Vector2, base: Color) -> void:
	for i in range(16):
		var angle := float(i) * TAU / 16.0
		var speed := 55.0 + float(i % 4) * 18.0
		effects.append({"position": at, "velocity": Vector2(cos(angle), sin(angle)) * speed, "life": 0.9, "color": base if i % 3 != 0 else Color("fef8be")})

func _basket_at(point: Vector2) -> int:
	for i in range(basket_rects.size()):
		if basket_rects[i].has_point(point):
			return i
	return -1

func _input(event: InputEvent) -> void:
	if paused or complete or not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_at(event.position, -1)
		else:
			_release_at(event.position, -1)
	elif event is InputEventMouseMotion and dragging and drag_pointer == -1:
		_move_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_press_at(event.position, event.index)
		else:
			_release_at(event.position, event.index)
	elif event is InputEventScreenDrag and dragging and drag_pointer == event.index:
		_move_drag(event.position)

func _press_at(point: Vector2, pointer: int) -> void:
	if point.y < play_top or point.y > play_bottom:
		return
	if point.distance_to(Vector2(current_x, current_y)) <= 58.0:
		dragging = true
		drag_pointer = pointer
		hovered_bin = -1
		return
	var basket := _basket_at(point)
	if basket >= 0:
		_choose_basket(basket)

func _move_drag(point: Vector2) -> void:
	current_x = clampf(point.x, 35.0, size.x - 35.0)
	current_y = clampf(point.y, play_top + 42.0, play_bottom - 18.0)
	hovered_bin = _basket_at(point)
	queue_redraw()

func _release_at(point: Vector2, pointer: int) -> void:
	if not dragging or pointer != drag_pointer:
		return
	dragging = false
	hovered_bin = -1
	var basket := _basket_at(point)
	if basket >= 0:
		_choose_basket(basket)
	else:
		current_x = size.x * 0.5
		current_y = minf(current_y, play_bottom - 30.0)
	queue_redraw()

func _draw() -> void:
	if size.x < 240.0 or size.y < 220.0:
		return
	_draw_background()
	_draw_chute()
	for i in range(mini(4, targets.size())):
		_draw_basket(basket_rects[i], targets[i], i, i == hovered_bin)
	_draw_hole()
	if active:
		var c := Color(COLOR_VALUES[String(current_shape["color"])])
		_draw_glow(Vector2(current_x, current_y), 77.0 if dragging else 59.0, c, 0.17)
		if not dragging:
			for j in range(4):
				draw_circle(Vector2(current_x, current_y - 20.0 - float(j) * 11.0), 3.3 - float(j) * 0.45, Color(c.r, c.g, c.b, 0.18 - float(j) * 0.032))
		_draw_shape(Vector2(current_x, current_y), 33.0 if not dragging else 43.0, String(current_shape["shape"]), String(current_shape["color"]), true)
	for p in effects:
		var c: Color = p["color"]
		draw_circle(p["position"], maxf(2.0, 4.0 * float(p["life"])), Color(c.r, c.g, c.b, minf(1.0, float(p["life"]))))
	if paused:
		_draw_pause_overlay()

func _draw_background() -> void:
	var w := size.x
	var h := size.y
	# Flight starfield / nebulae / meteors are actual animated project nodes.
	# This subtle translucent layer preserves their visibility behind the panels.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.024, 0.060, 0.18), true)
	_draw_glow(Vector2(w * 0.11, h * 0.32), 290, Color("285fb0"), 0.065)
	_draw_glow(Vector2(w * 0.88, h * 0.70), 290, Color("1a7a9b"), 0.065)
	# Slightly lighter tablet frame; translucent interior leaves live stars visible.
	_draw_round_rect(Rect2(12, play_top - 15, w - 24, play_bottom - play_top + 36), 34, Color(0.070, 0.165, 0.275, 0.87), Color("58bbf1"), 3)
	_draw_round_rect(Rect2(24, play_top - 4, w - 48, play_bottom - play_top + 17), 26, Color(0.035, 0.100, 0.195, 0.70), Color("2d779f"), 2)
	_draw_round_rect(Rect2(22, 93, minf(w * 0.52, 610), 39), 15, Color("122e4d"), Color("35739a"), 1)
	draw_line(Vector2(32, play_top - 17), Vector2(w - 32, play_top - 17), Color("6abaf0", 0.27), 2, true)
	for j in range(4):
		var cx := 41.0 if j % 2 == 0 else w - 41.0
		var cy := play_top + 17.0 if j < 2 else play_bottom - 7.0
		draw_circle(Vector2(cx, cy), 3.5, Color("83dcff", 0.68))

func _draw_chute() -> void:
	var cx := size.x * 0.5
	var track := Rect2(cx - chute_width * 0.5, play_top + 4, chute_width, play_bottom - play_top - 3)
	_draw_round_rect(track, 26, Color("061629"), Color("377ba5"), 2)
	_draw_round_rect(track.grow(-10), 19, Color("091e38"), Color("214563"), 1)
	for side in [-1, 1]:
		var x := cx + float(side) * (chute_width * 0.5 - 19.0)
		draw_line(Vector2(x, play_top + 31), Vector2(x, play_bottom - 28), Color("5bc8ff", 0.33), 2, true)
		for j in range(11):
			var y := play_top + 35.0 + float(j) * (play_bottom - play_top - 67.0) / 10.0
			draw_line(Vector2(x - 6.0, y), Vector2(x + 6.0, y), Color("69c4f5", 0.20), 2, true)
	var emitter := Vector2(cx, play_top + 19)
	_draw_glow(emitter, 52, Color("69c9ff"), 0.16)
	draw_arc(emitter, 35, 0.0, TAU, 40, Color("6bd2ff", 0.47 + 0.13 * sin(pulse_time * 1.6)), 2, true)
	for j in range(9):
		var y := play_top + 60.0 + float(j) * (play_bottom - play_top - 115.0) / 8.0
		draw_line(Vector2(cx - 8, y), Vector2(cx + 8, y), Color("6ac9ff", 0.14), 2, true)

func _draw_basket(rect: Rect2, target: Dictionary, index: int, is_hover: bool) -> void:
	var tint := Color(COLOR_VALUES[String(target["color"])])
	var good := success_bin == index and success_time > 0.0
	if is_hover or good:
		_draw_glow(rect.get_center(), rect.size.x * 0.69, tint, 0.17)
	var outline := Color("e9fdff") if is_hover or good else Color("578cb4")
	_draw_round_rect(rect, 24, Color("153c5b") if is_hover else Color("103151"), outline, 4 if is_hover or good else 2)
	var inside := rect.grow(-9)
	_draw_round_rect(inside, 17, Color("0b2540"), Color(tint.r, tint.g, tint.b, 0.46), 1)
	# Number and three collection indicator dots.
	_draw_round_rect(Rect2(inside.position.x + 8, inside.position.y + 8, 39, 26), 10, Color("21496c"), Color(tint.r, tint.g, tint.b, 0.80), 2)
	_draw_caption("%02d" % (index + 1), Rect2(inside.position.x + 10, inside.position.y + 8, 35, 24), 16, Color("edfaff"))
	var pip_x := inside.end.x - 52.0
	for j in range(3):
		var p := Vector2(pip_x + float(j) * 14.0, inside.position.y + 21.0)
		draw_circle(p, 4.1, tint if j < basket_counts[index] else Color("2d4e68"))
	# Large luminous target symbol. Every reset changes its assigned color.
	var short_basket := rect.size.y < 166.0
	var center := Vector2(rect.get_center().x, rect.position.y + rect.size.y * (0.32 if short_basket else 0.37))
	var icon_r := minf(44.0, rect.size.y * (0.19 if short_basket else 0.215))
	_draw_glow(center, icon_r * 1.75, tint, 0.16)
	_draw_shape(center, icon_r, String(target["shape"]), String(target["color"]), false)
	# Distinct basket lip and ribbed basket shell.
	var lip_y := rect.position.y + rect.size.y * (0.56 if short_basket else 0.637)
	draw_line(Vector2(inside.position.x+17, lip_y), Vector2(inside.end.x-17, lip_y), Color(tint.r, tint.g, tint.b, 0.8), 4, true)
	for j in range(3):
		var dx := (float(j) - 1.0) * 30.0
		draw_line(Vector2(center.x + dx - 13.0, lip_y + 8), Vector2(center.x + dx + 4.0, lip_y + 23), Color("63a9ce", 0.30), 2, true)
	var color_name := String(COLOR_NAMES[language][String(target["color"])]).to_upper()
	var shape_name := String(SHAPE_NAMES[language][String(target["shape"])]).to_upper()
	var f := 11 if short_basket else (12 if rect.size.x < 193.0 else 15)
	var color_y := rect.end.y - (52.0 if short_basket else 64.0)
	var shape_y := rect.end.y - (29.0 if short_basket else 38.0)
	_draw_caption(color_name, Rect2(rect.position.x+9, color_y, rect.size.x-18, 21), f, Color("a8d3f3"))
	_draw_caption(shape_name, Rect2(rect.position.x+9, shape_y, rect.size.x-18, 21), f+1, Color("eefbff"))

func _draw_hole() -> void:
	var cx := size.x * 0.5
	var y := play_bottom - 13.0
	_draw_glow(Vector2(cx, y), chute_width * 0.48, Color("9669bc"), 0.16)
	_draw_round_rect(Rect2(cx - chute_width * 0.38, y - 9.0, chute_width * 0.76, 25.0), 12, Color("02040d"), Color("9f76d2"), 3)
	for j in range(5):
		var x := cx - chute_width * 0.26 + float(j) * chute_width * 0.13
		draw_circle(Vector2(x, y+7), 2, Color("ad93e1", 0.28))

func _draw_glow(center: Vector2, radius: float, tint: Color, alpha: float) -> void:
	for j in range(3):
		var rad := radius * (1.0 - float(j) * 0.24)
		draw_circle(center, rad, Color(tint.r, tint.g, tint.b, alpha * (0.35 + float(j) * 0.21)))

func _draw_shape(center: Vector2, radius: float, shape: String, color_key: String, falling: bool) -> void:
	var tint := Color(COLOR_VALUES[color_key])
	var stroke := Color("e9f5ff") if color_key == "black" else Color("12253d")
	if falling:
		draw_circle(center, radius + 16.0, Color(tint.r, tint.g, tint.b, 0.12))
	match shape:
		"triangle":
			var pts := PackedVector2Array([center+Vector2(0,-radius), center+Vector2(-radius*0.92,radius*0.84), center+Vector2(radius*0.92,radius*0.84)])
			draw_colored_polygon(pts,tint)
			pts.append(pts[0])
			draw_polyline(pts,stroke,3.2,true)
		"square":
			var r := Rect2(center-Vector2.ONE*radius*0.84, Vector2.ONE*radius*1.68)
			draw_rect(r,tint,true)
			draw_rect(r,stroke,false,3.2)
		"circle":
			draw_circle(center,radius*0.9,tint)
			draw_arc(center,radius*0.9,0,TAU,48,stroke,3.2,true)
		"star":
			var pts := PackedVector2Array()
			for j in range(10):
				var rr := radius if j%2==0 else radius*0.46
				var a := -PI*0.5+j*PI/5.0
				pts.append(center+Vector2(cos(a),sin(a))*rr)
			draw_colored_polygon(pts,tint)
			pts.append(pts[0])
			draw_polyline(pts,stroke,3.0,true)
	# Small glint and highlight make the colored pieces feel like toys.
	if color_key != "black":
		var glint := center + Vector2(-radius * 0.19, -radius * 0.30)
		draw_circle(glint, maxf(1.6, radius * 0.064), Color(1, 1, 1, 0.65))

func _draw_caption(value: String, where: Rect2, font_size: int, col: Color) -> void:
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(where.position.x, where.position.y + where.size.y * 0.7), value, HORIZONTAL_ALIGNMENT_CENTER, where.size.x, font_size, col)

func _draw_round_rect(r: Rect2, radius: int, fill: Color, border: Color, stroke: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(stroke)
	style.set_corner_radius_all(radius)
	draw_style_box(style, r)

func _draw_pause_overlay() -> void:
	var r := Rect2(size.x*0.5-135, size.y*0.5-40, 270, 80)
	_draw_round_rect(r,23,Color("112e4c"),Color("8acdf4"),2)
	_draw_caption(_t("pause"),r,29,Color("edf9ff"))


func _hide_host_back() -> void:
	# MikoMainMenu hosts the minigame in a SubViewport.
	var viewport_node: Node = get_parent()
	if viewport_node != null and viewport_node.get_parent() != null and viewport_node.get_parent().get_parent() != null:
		var runner: Node = viewport_node.get_parent().get_parent()
		_shell_back = runner.get_node_or_null("ReturnToEducationalCards") as Control
	if is_instance_valid(_shell_back):
		_shell_back.hide()


func _exit_tree() -> void:
	if is_instance_valid(_shell_back):
		_shell_back.show()


func _exit_to_simulator() -> void:
	var portal: Node = get_node_or_null("/root/PlayTownPortal")
	if portal != null and portal.has_method("handle_scene_transition"):
		portal.call("handle_scene_transition", "res://education/playtown/scenes/screens/game_select_school.tscn")
	else:
		push_error("Color Sort: PlayTownPortal is not available")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_exit_to_simulator()
		get_viewport().set_input_as_handled()
