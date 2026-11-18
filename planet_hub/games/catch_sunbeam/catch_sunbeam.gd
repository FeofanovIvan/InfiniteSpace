extends Control
## MIKA · Catch the Sunbeam. Independent Godot 4.7.1 prototype.
## Plants photosynthesize in the fungal civilization's educational greenhouse.
## No generated images: procedural drawing plus OPTIONAL locally copied original assets.

const LANGUAGE_CODES := ["en", "ru", "pt", "es", "de", "fr"]
const LANGUAGE_NAMES := ["English", "Русский", "Português", "Español", "Deutsch", "Français"]
const TARGET_SCORE := 8
const OPEN_SECONDS := 4.5

const STRINGS := {
	"en": {
		"title": "CATCH THE SUNBEAM", "subtitle": "The living greenhouse · Open a leaf to catch the sunlight",
		"score": "ENERGY", "tip": "Tap a leaf when the sunbeam approaches!", "nice": "Great! The leaf caught sunlight!",
		"waiting": "The leaf is open — watch for the light!", "again": "Try another leaf!", "win": "THE PLANT IS GROWING!",
		"win_note": "You helped the plant collect sunlight.", "restart": "PLAY AGAIN", "reset": "RESTART",
		"speed": "Beam speed", "slow": "Gentle", "normal": "Normal", "fast": "Quick", "language": "Language"
	},
	"ru": {
		"title": "ПОЙМАЙ СОЛНЕЧНЫЙ ЛУЧ", "subtitle": "Живая оранжерея · Раскрой лист и поймай солнечный свет",
		"score": "ЭНЕРГИЯ", "tip": "Нажми на лист, когда приближается луч!", "nice": "Отлично! Лист получил солнечный свет!",
		"waiting": "Лист раскрыт — жди солнечный луч!", "again": "Попробуй другой лист!", "win": "РАСТЕНИЕ ВЫРОСЛО!",
		"win_note": "Ты помог растению получить солнечный свет.", "restart": "ИГРАТЬ ЕЩЁ", "reset": "ЗАНОВО",
		"speed": "Скорость луча", "slow": "Медленно", "normal": "Обычно", "fast": "Быстро", "language": "Язык"
	},
	"pt": {
		"title": "PEGUE O RAIO DE SOL", "subtitle": "Estufa viva · Abra uma folha e capture a luz do sol",
		"score": "ENERGIA", "tip": "Toque numa folha quando o raio se aproximar!", "nice": "Ótimo! A folha recebeu luz solar!",
		"waiting": "A folha está aberta — espere a luz!", "again": "Tente outra folha!", "win": "A PLANTA CRESCEU!",
		"win_note": "Você ajudou a planta a receber luz solar.", "restart": "JOGAR DE NOVO", "reset": "RECOMEÇAR",
		"speed": "Velocidade", "slow": "Devagar", "normal": "Normal", "fast": "Rápido", "language": "Idioma"
	},
	"es": {
		"title": "ATRAPA EL RAYO DE SOL", "subtitle": "Invernadero vivo · Abre una hoja para recibir luz solar",
		"score": "ENERGÍA", "tip": "¡Toca una hoja cuando se acerque el rayo!", "nice": "¡Genial! ¡La hoja recibió luz solar!",
		"waiting": "La hoja está abierta. ¡Espera la luz!", "again": "¡Prueba otra hoja!", "win": "¡LA PLANTA HA CRECIDO!",
		"win_note": "Ayudaste a la planta a recibir luz solar.", "restart": "JUGAR OTRA VEZ", "reset": "REINICIAR",
		"speed": "Velocidad", "slow": "Lento", "normal": "Normal", "fast": "Rápido", "language": "Idioma"
	},
	"de": {
		"title": "FANG DEN SONNENSTRAHL", "subtitle": "Lebendiges Gewächshaus · Öffne ein Blatt für Sonnenlicht",
		"score": "ENERGIE", "tip": "Tippe auf ein Blatt, wenn der Lichtstrahl kommt!", "nice": "Super! Das Blatt hat Sonnenlicht gefangen!",
		"waiting": "Das Blatt ist offen – warte auf das Licht!", "again": "Versuche ein anderes Blatt!", "win": "DIE PFLANZE IST GEWACHSEN!",
		"win_note": "Du hast der Pflanze geholfen, Licht zu sammeln.", "restart": "NOCH MAL", "reset": "NEUSTART",
		"speed": "Tempo", "slow": "Langsam", "normal": "Normal", "fast": "Schnell", "language": "Sprache"
	},
	"fr": {
		"title": "ATTRAPE LE RAYON DE SOLEIL", "subtitle": "Serre vivante · Ouvre une feuille pour capter le soleil",
		"score": "ÉNERGIE", "tip": "Touche une feuille quand le rayon approche !", "nice": "Bravo ! La feuille a capté le soleil !",
		"waiting": "La feuille est ouverte : attends la lumière !", "again": "Essaie une autre feuille !", "win": "LA PLANTE A GRANDI !",
		"win_note": "Tu as aidé la plante à capter le soleil.", "restart": "REJOUER", "reset": "RECOMMENCER",
		"speed": "Vitesse", "slow": "Lent", "normal": "Normal", "fast": "Rapide", "language": "Langue"
	}
}

var ui_locale: String = "en"
var mode_index: int = 0
var phase: float = -PI / 2.0
var elapsed: float = 0.0
var beam_x: float = 0.0
var score: int = 0
var won: bool = false
var leaf_timers := [0.0, 0.0, 0.0]
var leaf_open := [0.0, 0.0, 0.0]
var leaf_awarded := [false, false, false]
var particles: Array = []
var feedback_t: float = 0.0
var feedback_key: String = "tip"
var background_texture: Texture2D
var sun_texture: Texture2D
var leaf_texture: Texture2D
var star_texture: Texture2D
var label_title: Label
var label_subtitle: Label
var label_feedback: Label
var label_score: Label
var label_hint: Label
var label_win: Label
var label_win_note: Label
var progress: ProgressBar
var language_select: OptionButton
var speed_select: OptionButton
var button_restart: Button
var button_win: Button
var win_overlay: Panel
var asset_warning: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_read_assets()
	var lang_service = get_node_or_null("/root/LanguageService")
	if lang_service != null:
		ui_locale = str(lang_service.get("learning_locale"))
		if not LANGUAGE_CODES.has(ui_locale):
			ui_locale = "en"
	else:
		var cfg := ConfigFile.new()
		if cfg.load("user://mika_sunbeam_settings.cfg") == OK:
			ui_locale = str(cfg.get_value("settings", "language", "en"))
		if not LANGUAGE_CODES.has(ui_locale):
			ui_locale = "en"
	_build_ui()
	_reset_game()
	get_viewport().size_changed.connect(_reflow)
	_reflow()

func _read_assets() -> void:
	if ResourceLoader.exists("res://planet_hub/games/catch_sunbeam/star_core.png"):
		star_texture = load("res://planet_hub/games/catch_sunbeam/star_core.png") as Texture2D
	if ResourceLoader.exists("res://assets/borrowed/lmc_surface.jpg"):
		background_texture = load("res://assets/borrowed/lmc_surface.jpg") as Texture2D
	if ResourceLoader.exists("res://assets/borrowed/sun.webp"):
		sun_texture = load("res://assets/borrowed/sun.webp") as Texture2D
	if ResourceLoader.exists("res://assets/borrowed/leaf.webp"):
		leaf_texture = load("res://assets/borrowed/leaf.webp") as Texture2D

func _make_label(font_size: int, col: Color, align_mode: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", col)
	label.horizontal_alignment = align_mode
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	add_child(label)
	return label

func _button_skin(fill: Color, outline: Color, rad: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(rad)
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style

func _style_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", Color("f4fcff"))
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _button_skin(Color("153657"), Color("67c9e8")))
	button.add_theme_stylebox_override("hover", _button_skin(Color("216084"), Color("b3edff")))
	button.add_theme_stylebox_override("pressed", _button_skin(Color("12304d"), Color("43a5cf")))

func _build_ui() -> void:
	label_title = _make_label(32, Color("fff7d5"))
	label_subtitle = _make_label(18, Color("b9eadc"))
	label_score = _make_label(21, Color("fff6bd"), HORIZONTAL_ALIGNMENT_RIGHT)
	label_feedback = _make_label(20, Color("d0f9e5"), HORIZONTAL_ALIGNMENT_CENTER)
	label_hint = _make_label(16, Color("8fc5c4"))
	progress = ProgressBar.new()
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.min_value = 0
	progress.max_value = TARGET_SCORE
	progress.value = 0
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", _button_skin(Color("0f2837"), Color("386e78"), 13))
	var bar := StyleBoxFlat.new()
	bar.bg_color = Color("a6ec7b")
	bar.set_corner_radius_all(12)
	progress.add_theme_stylebox_override("fill", bar)
	add_child(progress)

	language_select = OptionButton.new()
	language_select.focus_mode = Control.FOCUS_NONE
	language_select.add_theme_font_size_override("font_size", 17)
	language_select.add_theme_color_override("font_color", Color.WHITE)
	language_select.add_theme_stylebox_override("normal", _button_skin(Color("132d46"), Color("4593a8")))
	for i in range(LANGUAGE_CODES.size()):
		language_select.add_item(LANGUAGE_NAMES[i], i)
	language_select.item_selected.connect(_on_language_selected)
	add_child(language_select)

	speed_select = OptionButton.new()
	speed_select.focus_mode = Control.FOCUS_NONE
	speed_select.add_theme_font_size_override("font_size", 17)
	speed_select.add_theme_color_override("font_color", Color.WHITE)
	speed_select.add_theme_stylebox_override("normal", _button_skin(Color("132d46"), Color("4593a8")))
	speed_select.item_selected.connect(_on_speed_selected)
	add_child(speed_select)

	button_restart = Button.new()
	_style_button(button_restart)
	button_restart.pressed.connect(_reset_game)
	add_child(button_restart)

	win_overlay = Panel.new()
	win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	win_overlay.add_theme_stylebox_override("panel", _button_skin(Color("0c2333"), Color("b9f2b2"), 30))
	add_child(win_overlay)
	label_win = Label.new()
	label_win.add_theme_font_size_override("font_size", 32)
	label_win.add_theme_color_override("font_color", Color("f4ffcf"))
	label_win.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_win.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_overlay.add_child(label_win)
	label_win_note = Label.new()
	label_win_note.add_theme_font_size_override("font_size", 18)
	label_win_note.add_theme_color_override("font_color", Color("c4e7db"))
	label_win_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_win_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_overlay.add_child(label_win_note)
	button_win = Button.new()
	_style_button(button_win)
	button_win.pressed.connect(_reset_game)
	win_overlay.add_child(button_win)
	asset_warning = _make_label(12, Color("659899"))
	_refresh_ui()

func _t(key: String) -> String:
	var strings: Dictionary = STRINGS.get(ui_locale, STRINGS["en"])
	return str(strings.get(key, STRINGS["en"].get(key, key)))

func _refresh_ui() -> void:
	if label_title == null:
		return
	label_title.text = _t("title")
	label_subtitle.text = _t("subtitle")
	button_restart.text = _t("reset")
	button_win.text = _t("restart")
	label_win.text = _t("win")
	label_win_note.text = _t("win_note")
	label_hint.text = _t("tip")
	label_feedback.text = _t(feedback_key)
	label_score.text = "%s  %d / %d" % [_t("score"), score, TARGET_SCORE]
	speed_select.clear()
	for k in ["slow", "normal", "fast"]:
		speed_select.add_item(_t(k))
	speed_select.select(mode_index)
	var lidx := LANGUAGE_CODES.find(ui_locale)
	language_select.select(maxi(lidx, 0))

func _on_language_selected(i: int) -> void:
	ui_locale = LANGUAGE_CODES[i]
	var lang_service = get_node_or_null("/root/LanguageService")
	if lang_service != null and lang_service.has_method("set_learning_locale"):
		lang_service.call("set_learning_locale", ui_locale)
	else:
		var cfg := ConfigFile.new()
		cfg.set_value("settings", "language", ui_locale)
		cfg.save("user://mika_sunbeam_settings.cfg")
	_refresh_ui()

func _on_speed_selected(i: int) -> void:
	mode_index = i

func _reset_game() -> void:
	phase = -PI / 2.0
	elapsed = 0.0
	score = 0
	if progress != null:
		progress.value = 0
	won = false
	leaf_timers = [0.0, 0.0, 0.0]
	leaf_open = [0.0, 0.0, 0.0]
	leaf_awarded = [false, false, false]
	particles.clear()
	feedback_t = 0.0
	feedback_key = "tip"
	if win_overlay != null:
		win_overlay.visible = false
	_refresh_ui()
	queue_redraw()

func _reflow() -> void:
	var s := size
	var sc: float = clampf(minf(s.x / 1280.0, s.y / 720.0), 0.5, 1.28)
	var margin := 25.0 * sc
	label_title.position = Vector2(margin, 14 * sc)
	label_title.size = Vector2(s.x * 0.65, 43 * sc)
	label_title.add_theme_font_size_override("font_size", int(31 * sc))
	label_subtitle.position = Vector2(margin, 60 * sc)
	label_subtitle.size = Vector2(s.x * 0.73, 32 * sc)
	label_subtitle.add_theme_font_size_override("font_size", int(18 * sc))
	label_score.position = Vector2(s.x - 320 * sc, 20 * sc)
	label_score.size = Vector2(290 * sc, 32 * sc)
	progress.position = Vector2(s.x - 320 * sc, 55 * sc)
	progress.size = Vector2(290 * sc, 22 * sc)
	label_feedback.position = Vector2(s.x * 0.19, s.y * 0.75)
	label_feedback.size = Vector2(s.x * 0.62, 35 * sc)
	label_feedback.add_theme_font_size_override("font_size", int(21 * sc))
	label_hint.position = Vector2(margin, s.y - 53 * sc)
	label_hint.size = Vector2(s.x * 0.47, 34 * sc)
	label_hint.add_theme_font_size_override("font_size", int(16 * sc))
	language_select.position = Vector2(s.x - 470 * sc, s.y - 60 * sc)
	language_select.size = Vector2(170 * sc, 43 * sc)
	speed_select.position = Vector2(s.x - 287 * sc, s.y - 60 * sc)
	speed_select.size = Vector2(140 * sc, 43 * sc)
	button_restart.position = Vector2(s.x - 133 * sc, s.y - 60 * sc)
	button_restart.size = Vector2(111 * sc, 43 * sc)
	win_overlay.position = Vector2(s.x / 2.0 - 286 * sc, s.y / 2.0 - 125 * sc)
	win_overlay.size = Vector2(572 * sc, 253 * sc)
	label_win.position = Vector2(12 * sc, 26 * sc)
	label_win.size = Vector2(win_overlay.size.x - 24 * sc, 58 * sc)
	label_win.add_theme_font_size_override("font_size", int(32 * sc))
	label_win_note.position = Vector2(25 * sc, 96 * sc)
	label_win_note.size = Vector2(win_overlay.size.x - 50 * sc, 45 * sc)
	label_win_note.add_theme_font_size_override("font_size", int(18 * sc))
	button_win.position = Vector2(win_overlay.size.x / 2 - 100 * sc, 168 * sc)
	button_win.size = Vector2(200 * sc, 56 * sc)
	asset_warning.position = Vector2(25 * sc, s.y - 20 * sc)
	asset_warning.size = Vector2(450 * sc, 16 * sc)
	queue_redraw()

func _leaf_positions() -> Array:
	var s := size
	return [Vector2(s.x * 0.325, s.y * 0.55), Vector2(s.x * 0.50, s.y * 0.55), Vector2(s.x * 0.675, s.y * 0.55)]

func _beam_position() -> float:
	var centers := _leaf_positions()
	var t := (sin(phase) + 1.0) * 0.5
	return lerpf(centers[0].x, centers[2].x, t)

func _process(delta: float) -> void:
	elapsed += delta
	if not won:
		var speeds := [0.35, 0.55, 0.8]
		phase += delta * speeds[mode_index]
	beam_x = _beam_position()
	var positions := _leaf_positions()
	var sc: float = clampf(minf(size.x / 1280.0, size.y / 720.0), 0.5, 1.28)
	var beam_width := 65.0 * sc
	for i in range(3):
		if leaf_timers[i] > 0.0 and not won:
			leaf_timers[i] = maxf(0.0, float(leaf_timers[i]) - delta)
		var target: float = 1.0 if float(leaf_timers[i]) > 0.0 else 0.0
		leaf_open[i] = lerpf(float(leaf_open[i]), target, minf(1.0, 9.0 * delta))
		var distance := absf(positions[i].x - beam_x)
		if distance > beam_width * 1.8:
			leaf_awarded[i] = false
		if distance < beam_width and leaf_timers[i] > 0.0 and not leaf_awarded[i] and not won:
			_award_light(i)
	_update_particles(delta)
	if feedback_t > 0:
		feedback_t = maxf(0.0, feedback_t - delta)
		if feedback_t == 0.0 and not won:
			feedback_key = "tip"
			label_feedback.text = _t(feedback_key)
	queue_redraw()

func _award_light(i: int) -> void:
	leaf_awarded[i] = true
	leaf_timers[i] = 0.0
	score += 1
	progress.value = score
	label_score.text = "%s  %d / %d" % [_t("score"), score, TARGET_SCORE]
	feedback_key = "nice"
	label_feedback.text = _t(feedback_key)
	feedback_t = 2.8
	var c: Vector2 = _leaf_positions()[i]
	for n in range(15):
		var a := float(n) * TAU / 15.0
		particles.append({"pos": c, "vel": Vector2(cos(a), sin(a) - 0.45) * (45.0 + float(n % 4) * 19.0), "life": 1.0, "ttl": 1.0})
	if score >= TARGET_SCORE:
		won = true
		win_overlay.visible = true
		label_feedback.text = ""

func _update_particles(delta: float) -> void:
	var next_particles: Array = []
	for part in particles:
		part["life"] = float(part["life"]) - delta
		if float(part["life"]) > 0.0:
			part["pos"] = part["pos"] + part["vel"] * delta
			part["vel"] = part["vel"] + Vector2(0, 32) * delta
			next_particles.append(part)
	particles = next_particles

func _gui_input(event: InputEvent) -> void:
	if won:
		return
	var at := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			at = e.position
			pressed = true
	elif event is InputEventScreenTouch:
		var e: InputEventScreenTouch = event
		if e.pressed:
			at = e.position
			pressed = true
	if not pressed:
		return
	var points := _leaf_positions()
	var sc: float = clampf(minf(size.x / 1280.0, size.y / 720.0), 0.5, 1.28)
	for i in range(3):
		if at.distance_to(points[i]) < 77.0 * sc:
			leaf_timers[i] = OPEN_SECONDS
			feedback_key = "waiting"
			feedback_t = 1.8
			label_feedback.text = _t(feedback_key)
			accept_event()
			return

func _draw() -> void:
	var s := size
	if s.x < 1.0 or s.y < 1.0:
		return
	var sc: float = clampf(minf(s.x / 1280.0, s.y / 720.0), 0.5, 1.28)
	_draw_background(s, sc)
	_draw_sunbeam(s, sc)
	_draw_plant(s, sc)
	_draw_particles(sc)
	_draw_bottom_bar(s, sc)

func _draw_background(s: Vector2, sc: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, s), Color("061a26"))
	if background_texture != null:
		draw_texture_rect(background_texture, Rect2(Vector2.ZERO, s), false, Color(0.22, 0.45, 0.42, 0.22))
	for i in range(12):
		var t := float(i) / 12.0
		draw_rect(Rect2(0, t * s.y, s.x, s.y / 12.0 + 1.0), Color(0.04, 0.18 + t * 0.13, 0.24 + t * 0.04, 0.13))
	for i in range(70):
		var x := fposmod(float(i * 181), s.x)
		var y := fposmod(float(i * 61 + 23), s.y * 0.76)
		if star_texture != null and i % 3 == 0:
			draw_texture_rect(star_texture, Rect2(x - 9 * sc, y - 9 * sc, 18 * sc, 18 * sc), false, Color(0.64, 0.97, 0.93, 0.21))
		else:
			draw_circle(Vector2(x, y), 1.2 * sc, Color(0.64, 0.97, 0.93, 0.14 + float(i % 3) * 0.06))
	# dark backdrop plates, fungal bioluminescence and no sharp horizon
	var ground_y := s.y * 0.83
	draw_rect(Rect2(0, ground_y, s.x, s.y - ground_y), Color("09282c"))
	for i in range(10):
		var x := float(i) / 9.0 * s.x
		var r := (31.0 + float(i % 4) * 19.0) * sc
		draw_circle(Vector2(x, ground_y + 17 * sc), r, Color("0b3a3a"))
	for i in range(11):
		var x := float(i) / 10.0 * s.x
		var y := ground_y + 6.0 * sc
		_draw_small_mushroom(Vector2(x, y), sc * (0.65 + float(i % 3) * 0.24))
	# decorative fungus filaments
	var root: Vector2 = Vector2(s.x * 0.5, ground_y + 10 * sc)
	for i in range(11):
		var x := s.x * (0.12 + float(i) * 0.076)
		var path := PackedVector2Array([root, Vector2(lerpf(root.x, x, 0.45), ground_y + (28.0 + float(i % 3) * 8.0) * sc), Vector2(x, ground_y + 14 * sc)])
		draw_polyline(path, Color(0.30, 0.83, 0.67, 0.20), 3.0 * sc, true)

func _draw_small_mushroom(p: Vector2, sc: float) -> void:
	draw_line(p + Vector2(0, 0), p + Vector2(0, -32 * sc), Color("3d9393"), 5 * sc, true)
	var cap := PackedVector2Array([p + Vector2(-17, -26) * sc, p + Vector2(-12, -40) * sc, p + Vector2(0, -45) * sc, p + Vector2(14, -38) * sc, p + Vector2(21, -26) * sc])
	draw_colored_polygon(cap, Color("346f82"))
	draw_circle(p + Vector2(-3, -35) * sc, 3 * sc, Color("8be5cb"))
	draw_circle(p + Vector2(9, -33) * sc, 2 * sc, Color("d8ffe9"))

func _draw_sunbeam(s: Vector2, sc: float) -> void:
	var sun := Vector2(s.x * 0.17, s.y * 0.24)
	var target := Vector2(beam_x, s.y * 0.57)
	# moving light cone, solar energy is not a solid object
	for i in range(4):
		var alpha := 0.045 + float(i) * 0.022
		var spread := (95.0 - float(i) * 20.0) * sc
		var cone := PackedVector2Array([sun + Vector2(-19, 0) * sc, sun + Vector2(19, 0) * sc, target + Vector2(spread, 0), target - Vector2(spread, 0)])
		draw_colored_polygon(cone, Color(1.0, 0.91, 0.52, alpha))
	var beam_target := Vector2(beam_x, s.y * 0.57)
	draw_circle(beam_target, 80 * sc, Color(1.0, 0.92, 0.36, 0.075))
	draw_arc(beam_target, 61 * sc, 0, TAU, 56, Color(1, 0.95, 0.65, 0.35), 2.0 * sc, true)
	# sun body with gentle rays
	for i in range(12):
		var a := float(i) * TAU / 12.0 + elapsed * 0.12
		draw_line(sun + Vector2(cos(a), sin(a)) * 44 * sc, sun + Vector2(cos(a), sin(a)) * 55 * sc, Color("ffe39b"), 4 * sc, true)
	draw_circle(sun, 49 * sc, Color(1,0.81,0.36,0.10))
	draw_circle(sun, 38 * sc, Color("ffc65e"))
	draw_circle(sun, 30 * sc, Color("ffe99e"))
	if sun_texture != null:
		draw_texture_rect(sun_texture, Rect2(sun - Vector2.ONE * 29 * sc, Vector2.ONE * 58 * sc), false, Color(1,1,1,0.8))

func _draw_plant(s: Vector2, sc: float) -> void:
	var ground_y := s.y * 0.83
	var positions := _leaf_positions()
	var root := Vector2(s.x * 0.5, ground_y + 9 * sc)
	# roots and stems for one living organism
	for i in range(3):
		var end: Vector2 = positions[i] + Vector2(0, 41 * sc)
		var path := PackedVector2Array([root, Vector2(lerpf(root.x, end.x, 0.32), ground_y - 68 * sc), Vector2(lerpf(root.x, end.x, 0.68), end.y + 75 * sc), end])
		draw_polyline(path, Color("183f31"), 16 * sc, true)
		draw_polyline(path, Color("4b9c62"), 9 * sc, true)
		draw_polyline(path, Color("8bc887"), 3 * sc, true)
	# plant growth body and bloom
	draw_circle(root - Vector2(0, 8 * sc), (18 + score * 1.5) * sc, Color("58b88e"))
	if score >= 3:
		var flower_p := root + Vector2(0, -(26.0 + float(score) * 6.0) * sc)
		for n in range(5):
			var a := float(n) * TAU / 5.0
			draw_circle(flower_p + Vector2(cos(a), sin(a)) * (10.0 + float(score) * 0.7) * sc, 10 * sc, Color("ffbdc9"))
		draw_circle(flower_p, 9 * sc, Color("ffe48e"))
	for i in range(3):
		_draw_leaf(positions[i], sc, float(leaf_open[i]), i)

func _draw_leaf(p: Vector2, sc: float, openness: float, index: int) -> void:
	var r := (48.0 + openness * 6.0) * sc
	var lit := absf(p.x - beam_x) < 64.0 * sc
	var glow: Color = Color("ffee88") if lit else Color("6cdda7")
	draw_circle(p, r + 13 * sc, Color(glow.r, glow.g, glow.b, 0.08 if not lit else 0.18))
	draw_arc(p, r + 2 * sc, 0, TAU, 48, Color(glow.r, glow.g, glow.b, 0.38 if not lit else 0.88), 2.5 * sc, true)
	# Closed leaf remains recognisable; opening widens it into a leaf silhouette
	var half_w := lerpf(10.0, 42.0, openness) * sc
	var top := p + Vector2(0, -47 * sc)
	var bottom := p + Vector2(0, 44 * sc)
	var poly := PackedVector2Array([
		top,
		p + Vector2(-half_w * 0.62, -25 * sc),
		p + Vector2(-half_w, -1 * sc),
		p + Vector2(-half_w * 0.77, 24 * sc),
		bottom,
		p + Vector2(half_w * 0.77, 24 * sc),
		p + Vector2(half_w, -1 * sc),
		p + Vector2(half_w * 0.62, -25 * sc)
	])
	draw_colored_polygon(poly, Color("79d78c") if openness > 0.35 else Color("347d61"))
	draw_polyline(PackedVector2Array([bottom, p, top]), Color("c5f8ad"), 3 * sc, true)
	if openness > 0.2:
		for side in [-1.0, 1.0]:
			draw_line(p + Vector2(0, 8 * sc), p + Vector2(side * half_w * 0.7, -4 * sc), Color(0.83, 1.0, 0.67, 0.6), 2 * sc, true)
	if leaf_texture != null and openness > 0.65:
		draw_texture_rect(leaf_texture, Rect2(p - Vector2.ONE * 33 * sc, Vector2.ONE * 66 * sc), false, Color(1,1,1,0.13))
	if lit and openness > 0.4:
		draw_circle(p + Vector2(0, -2 * sc), 8 * sc, Color(1,0.95,0.62,0.68))
	# Tiny index marker serves as an affordance, no language-specific words baked in
	var dot := p + Vector2(0, 60 * sc)
	draw_circle(dot, 5 * sc, Color("b3f0ce") if leaf_timers[index] > 0 else Color("44776a"))

func _draw_particles(sc: float) -> void:
	for part in particles:
		var life := float(part["life"])
		var p: Vector2 = part["pos"]
		draw_circle(p, (2 + 3 * life) * sc, Color(1.0, 0.97, 0.56, life))

func _draw_bottom_bar(s: Vector2, sc: float) -> void:
	var top := s.y - 70 * sc
	draw_rect(Rect2(0, top, s.x, 70 * sc), Color(0.025, 0.09, 0.14, 0.9))
	draw_line(Vector2(0, top), Vector2(s.x, top), Color("315d64"), 2 * sc)
