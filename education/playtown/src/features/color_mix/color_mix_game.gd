extends Node2D

const DESIGN_SIZE := Vector2(1672.0, 941.0)
const BACK_SCENE := "res://education/playtown/scenes/screens/game_select_playground.tscn"
const BACKGROUND: Texture2D = preload("res://education/playtown/assets/color_mix/studio.webp")
const SHELF: Texture2D = preload("res://education/playtown/assets/color_mix/wood_shelf.webp")
const PEDESTAL: Texture2D = preload("res://education/playtown/assets/color_mix/wood_pedestal.webp")
const SPLASH_FILL: Texture2D = preload("res://education/playtown/assets/color_mix/splash_fill_mask.webp")
const SPLASH_OUTLINE: Texture2D = preload("res://education/playtown/assets/color_mix/splash_outline.webp")
const FlaskScript := preload("res://education/playtown/src/features/color_mix/paint_flask.gd")
const CORRECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const WRONG_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")

const SHELF_SCALE := 0.58
const SOURCE_SCALE := 0.105
const MIXER_SCALE := 0.255
const TARGET_SPLASH_SCALE := 0.145
var source_points: Array[Vector2] = [
	Vector2(148, 438), Vector2(358, 438), Vector2(148, 666), Vector2(358, 666),
	Vector2(1314, 438), Vector2(1522, 438), Vector2(1314, 666), Vector2(1522, 666),
]
var mixer_center := Vector2(836, 590)
const DROP_RADIUS := 205.0

# Existing voice indices follow the pencil palette: red, orange, yellow,
# green, cyan, blue, purple. White and black need new recordings.
const PAINTS: Array[Dictionary] = [
	{"id": "red", "hex": "#ef3f36", "voice": 0},
	{"id": "yellow", "hex": "#f4d53b", "voice": 2},
	{"id": "blue", "hex": "#397bdc", "voice": 5},
	{"id": "white", "hex": "#f7f4e8", "voice": -1},
	{"id": "green", "hex": "#53b653", "voice": 3},
	{"id": "orange", "hex": "#f28b2d", "voice": 1},
	{"id": "purple", "hex": "#995bd1", "voice": 6},
	{"id": "black", "hex": "#343847", "voice": -1},
]

const RECIPES: Array[Dictionary] = [
	{"id": "orange", "hex": "#f28b2d", "voice": 1, "needs": ["red", "yellow"]},
	{"id": "green", "hex": "#53b653", "voice": 3, "needs": ["yellow", "blue"]},
	{"id": "purple", "hex": "#995bd1", "voice": 6, "needs": ["red", "blue"]},
	{"id": "pink", "hex": "#f891b1", "voice": -1, "needs": ["red", "white"]},
	{"id": "cyan", "hex": "#65c9e8", "voice": 4, "needs": ["blue", "white"]},
	{"id": "lilac", "hex": "#d1a8f3", "voice": -1, "needs": ["purple", "white"]},
	{"id": "brown", "hex": "#8d5a35", "voice": -1, "needs": ["red", "yellow", "blue"]},
	{"id": "peach", "hex": "#ffc294", "voice": -1, "needs": ["orange", "white"]},
	{"id": "gray", "hex": "#aeb4c2", "voice": -1, "needs": ["black", "white"]},
]

const TEXT := {
	"target": {"ru": "СОБЕРИ ЭТОТ ЦВЕТ", "en": "MIX THIS COLOR", "pt": "MISTURE ESTA COR", "es": "MEZCLA ESTE COLOR", "de": "MISCHE DIESE FARBE", "fr": "MÉLANGE CETTE COULEUR"},
	"recipe": {"ru": "СМЕШАЙ ЭТИ ЦВЕТА", "en": "MIX THESE COLORS", "pt": "MISTURE ESTAS CORES", "es": "MEZCLA ESTOS COLORES", "de": "MISCHE DIESE FARBEN", "fr": "MÉLANGE CES COULEURS"},
	"drag": {"ru": "ПЕРЕТАЩИ КОЛБУ В ЦЕНТР", "en": "DRAG A FLASK TO THE CENTER", "pt": "ARRASTE UM FRASCO AO CENTRO", "es": "ARRASTRA UN FRASCO AL CENTRO", "de": "ZIEHE EINE FLASCHE IN DIE MITTE", "fr": "GLISSE UN FLACON AU CENTRE"},
	"more": {"ru": "ДОБАВЬ СЛЕДУЮЩИЙ ЦВЕТ", "en": "ADD THE NEXT COLOR", "pt": "ADICIONE A PRÓXIMA COR", "es": "AÑADE EL SIGUIENTE COLOR", "de": "FÜGE DIE NÄCHSTE FARBE HINZU", "fr": "AJOUTE LA COULEUR SUIVANTE"},
	"pouring": {"ru": "НАЛИВАЕМ КРАСКУ…", "en": "POURING PAINT…", "pt": "DERRAMANDO A TINTA…", "es": "VERTIENDO LA PINTURA…", "de": "FARBE WIRD EINGEGOSSEN…", "fr": "ON VERSE LA PEINTURE…"},
	"used": {"ru": "ЭТОТ ЦВЕТ УЖЕ ДОБАВЛЕН", "en": "THIS COLOR IS ALREADY ADDED", "pt": "ESTA COR JÁ FOI ADICIONADA", "es": "ESTE COLOR YA ESTÁ AÑADIDO", "de": "DIESE FARBE IST SCHON DABEI", "fr": "CETTE COULEUR EST DÉJÀ AJOUTÉE"},
	"correct": {"ru": "ОТЛИЧНО! ЦВЕТ ПОЛУЧИЛСЯ!", "en": "GREAT! YOU MADE THE COLOR!", "pt": "MUITO BEM! VOCÊ FEZ A COR!", "es": "¡MUY BIEN! ¡LOGRASTE EL COLOR!", "de": "SUPER! DIE FARBE IST FERTIG!", "fr": "BRAVO ! LA COULEUR EST RÉUSSIE !"},
	"retry": {"ru": "ПОПРОБУЙ ДРУГИЕ ЦВЕТА", "en": "TRY DIFFERENT COLORS", "pt": "TENTE OUTRAS CORES", "es": "PRUEBA OTROS COLORES", "de": "VERSUCHE ANDERE FARBEN", "fr": "ESSAIE D’AUTRES COULEURS"},
}

const COLOR_NAMES := {
	"red": {"ru": "КРАСНЫЙ", "en": "RED", "pt": "VERMELHO", "es": "ROJO", "de": "ROT", "fr": "ROUGE"},
	"yellow": {"ru": "ЖЁЛТЫЙ", "en": "YELLOW", "pt": "AMARELO", "es": "AMARILLO", "de": "GELB", "fr": "JAUNE"},
	"blue": {"ru": "СИНИЙ", "en": "BLUE", "pt": "AZUL", "es": "AZUL", "de": "BLAU", "fr": "BLEU"},
	"white": {"ru": "БЕЛЫЙ", "en": "WHITE", "pt": "BRANCO", "es": "BLANCO", "de": "WEISS", "fr": "BLANC"},
	"green": {"ru": "ЗЕЛЁНЫЙ", "en": "GREEN", "pt": "VERDE", "es": "VERDE", "de": "GRÜN", "fr": "VERT"},
	"orange": {"ru": "ОРАНЖЕВЫЙ", "en": "ORANGE", "pt": "LARANJA", "es": "NARANJA", "de": "ORANGE", "fr": "ORANGE"},
	"purple": {"ru": "ФИОЛЕТОВЫЙ", "en": "PURPLE", "pt": "ROXO", "es": "MORADO", "de": "VIOLETT", "fr": "VIOLET"},
	"black": {"ru": "ЧЁРНЫЙ", "en": "BLACK", "pt": "PRETO", "es": "NEGRO", "de": "SCHWARZ", "fr": "NOIR"},
	"pink": {"ru": "РОЗОВЫЙ", "en": "PINK", "pt": "ROSA", "es": "ROSA", "de": "ROSA", "fr": "ROSE"},
	"cyan": {"ru": "ГОЛУБОЙ", "en": "LIGHT BLUE", "pt": "AZUL-CLARO", "es": "CELESTE", "de": "HELLBLAU", "fr": "BLEU CLAIR"},
	"lilac": {"ru": "СИРЕНЕВЫЙ", "en": "LILAC", "pt": "LILÁS", "es": "LILA", "de": "FLIEDER", "fr": "LILAS"},
	"brown": {"ru": "КОРИЧНЕВЫЙ", "en": "BROWN", "pt": "MARROM", "es": "MARRÓN", "de": "BRAUN", "fr": "MARRON"},
	"peach": {"ru": "ПЕРСИКОВЫЙ", "en": "PEACH", "pt": "PÊSSEGO", "es": "MELOCOTÓN", "de": "PFIRSICH", "fr": "PÊCHE"},
	"gray": {"ru": "СЕРЫЙ", "en": "GRAY", "pt": "CINZA", "es": "GRIS", "de": "GRAU", "fr": "GRIS"},
}

var stage: Node2D
var shelves: Array[Sprite2D] = []
var pedestal: Sprite2D
var source_flasks: Array[PaintFlask] = []
var central_flask: PaintFlask
var target_panel: Panel
var recipe_panel: Panel
var target_splash: Sprite2D
var target_name: Label
var recipe_count: Label
var ingredient_dots: Array[Panel] = []
var status_label: Label
var exit_button: GameExitButton
var score_panel: GameScorePanel
var voice_player: AudioStreamPlayer

var recipe_index := -1
var selected_ids: Array[String] = []
var mixed_color := Color.WHITE
var mixed_fill := 0.0
var dragged_index := -1
var dragged_touch := false
var touch_index := -1
var drag_offset := Vector2.ZERO
var input_locked := false


func _ready() -> void:
	randomize()
	_build_stage()
	_build_hud()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_start_random_round()


func _build_stage() -> void:
	stage = Node2D.new()
	stage.name = "ArtStudioStage"
	add_child(stage)
	var background := Sprite2D.new()
	background.texture = BACKGROUND
	background.centered = false
	background.z_index = -20
	stage.add_child(background)

	for shelf_position in [Vector2(250, 595), Vector2(1422, 595)]:
		var shelf := Sprite2D.new()
		shelf.texture = SHELF
		shelf.position = shelf_position
		shelf.scale = Vector2.ONE * SHELF_SCALE
		shelf.z_index = 1
		stage.add_child(shelf)
		shelves.append(shelf)

	pedestal = Sprite2D.new()
	pedestal.texture = PEDESTAL
	pedestal.position = Vector2(836, 768)
	pedestal.scale = Vector2.ONE * 0.34
	pedestal.z_index = 2
	stage.add_child(pedestal)

	central_flask = FlaskScript.new() as PaintFlask
	central_flask.position = mixer_center
	central_flask.scale = Vector2.ONE * MIXER_SCALE
	central_flask.z_index = 8
	stage.add_child(central_flask)

	for index in PAINTS.size():
		var flask := FlaskScript.new() as PaintFlask
		flask.name = "Paint_%s" % String(PAINTS[index].id)
		flask.position = source_points[index]
		flask.scale = Vector2.ONE * SOURCE_SCALE
		flask.z_index = 7
		stage.add_child(flask)
		source_flasks.append(flask)

	_build_target_panel()
	_build_recipe_panel()


func _build_target_panel() -> void:
	target_panel = Panel.new()
	target_panel.position = Vector2(612, 22)
	target_panel.size = Vector2(448, 238)
	target_panel.z_index = 30
	target_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff8e8"), Color("#e89a31"), 5, 30))
	stage.add_child(target_panel)
	var title := _label(_t("target"), 28, Color("#8a4d20"))
	title.position = Vector2(16, 8)
	title.size = Vector2(target_panel.size.x - 32, 43)
	target_panel.add_child(title)
	target_splash = Sprite2D.new()
	target_splash.texture = SPLASH_FILL
	target_splash.position = Vector2(target_panel.size.x * 0.5, 124)
	target_splash.scale = Vector2.ONE * TARGET_SPLASH_SCALE
	target_panel.add_child(target_splash)
	var outline := Sprite2D.new()
	outline.texture = SPLASH_OUTLINE
	outline.position = target_splash.position
	outline.scale = target_splash.scale
	target_panel.add_child(outline)
	target_name = _label("", 27, Color("#6e4125"))
	target_name.position = Vector2(18, 190)
	target_name.size = Vector2(target_panel.size.x - 36, 38)
	target_panel.add_child(target_name)


func _build_recipe_panel() -> void:
	recipe_panel = Panel.new()
	recipe_panel.position = Vector2(1254, 112)
	recipe_panel.size = Vector2(356, 176)
	recipe_panel.z_index = 30
	recipe_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff8e8"), Color("#d98229"), 5, 26))
	stage.add_child(recipe_panel)
	var title := _label(_t("recipe"), 23, Color("#8a4d20"))
	title.position = Vector2(12, 8)
	title.size = Vector2(recipe_panel.size.x - 24, 40)
	recipe_panel.add_child(title)
	for index in range(3):
		var dot := Panel.new()
		dot.position = Vector2(56 + index * 90, 58)
		dot.size = Vector2(70, 70)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		recipe_panel.add_child(dot)
		ingredient_dots.append(dot)
	recipe_count = _label("", 23, Color("#6e4125"))
	recipe_count.position = Vector2(18, 132)
	recipe_count.size = Vector2(recipe_panel.size.x - 36, 35)
	recipe_panel.add_child(recipe_count)


func _build_hud() -> void:
	exit_button = GameExitButton.new()
	exit_button.z_index = 100
	exit_button.pressed.connect(_go_back)
	add_child(exit_button)
	score_panel = GameScorePanel.new()
	score_panel.z_index = 100
	add_child(score_panel)
	status_label = _label(_t("drag"), 25, Color("#71411f"))
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)


func _layout() -> void:
	var view := get_viewport_rect().size
	if view.x <= 1.0 or view.y <= 1.0:
		return
	var scale_factor := maxf(view.x / DESIGN_SIZE.x, view.y / DESIGN_SIZE.y)
	stage.scale = Vector2.ONE * scale_factor
	stage.position = (view - DESIGN_SIZE * scale_factor) * 0.5
	var visible_left := clampf(-stage.position.x / scale_factor, 0.0, DESIGN_SIZE.x)
	var visible_right := clampf((view.x - stage.position.x) / scale_factor, 0.0, DESIGN_SIZE.x)
	var visible_top := clampf(-stage.position.y / scale_factor, 0.0, DESIGN_SIZE.y)
	_layout_stage_content(visible_left, visible_right, visible_top)
	var safe := _safe_area_insets(view)
	var control_side := clampf(minf(view.x, view.y) * 0.115, 76.0, 96.0)
	exit_button.position = Vector2(safe.x + 18.0, safe.y + 16.0)
	exit_button.size = Vector2.ONE * control_side
	var score_width := clampf(control_side * 2.15, 160.0, 206.0)
	score_panel.position = Vector2(view.x - safe.z - score_width - 18.0, safe.y + 16.0)
	score_panel.size = Vector2(score_width, control_side)


func _layout_stage_content(visible_left: float, visible_right: float, visible_top: float) -> void:
	var center_x := (visible_left + visible_right) * 0.5
	var side_inset := 226.0
	var left_shelf_x := visible_left + side_inset
	var right_shelf_x := visible_right - side_inset
	shelves[0].position = Vector2(left_shelf_x, 592)
	shelves[1].position = Vector2(right_shelf_x, 592)
	source_points = [
		Vector2(left_shelf_x - 92, 462), Vector2(left_shelf_x + 92, 462),
		Vector2(left_shelf_x - 92, 650), Vector2(left_shelf_x + 92, 650),
		Vector2(right_shelf_x - 92, 462), Vector2(right_shelf_x + 92, 462),
		Vector2(right_shelf_x - 92, 650), Vector2(right_shelf_x + 92, 650),
	]
	mixer_center = Vector2(center_x, 588)
	central_flask.position = mixer_center
	pedestal.position = Vector2(center_x, 758)
	target_panel.position = Vector2(center_x - target_panel.size.x * 0.5, visible_top + 18)
	recipe_panel.position = Vector2(visible_right - recipe_panel.size.x - 30, visible_top + 130)
	if dragged_index < 0 and not input_locked:
		for index in source_flasks.size():
			source_flasks[index].position = source_points[index]


func _input(event: InputEvent) -> void:
	if input_locked:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_drag(touch.position, true, touch.index)
		else:
			_end_drag(touch.position, true, touch.index)
	elif event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		if dragged_index >= 0 and dragged_touch and screen_drag.index == touch_index:
			_move_drag(screen_drag.position)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_begin_drag(mouse.position, false, -1)
		else:
			_end_drag(mouse.position, false, -1)
	elif event is InputEventMouseMotion and dragged_index >= 0 and not dragged_touch:
		_move_drag((event as InputEventMouseMotion).position)


func _begin_drag(viewport_point: Vector2, is_touch: bool, pointer_index: int) -> void:
	if dragged_index >= 0:
		return
	var point := _to_stage(viewport_point)
	for index in range(source_flasks.size() - 1, -1, -1):
		if source_flasks[index].position.distance_to(point) > 105.0:
			continue
		var paint_id := String(PAINTS[index].id)
		if selected_ids.has(paint_id):
			_set_status("used", Color("#a9582d"))
			return
		dragged_index = index
		dragged_touch = is_touch
		touch_index = pointer_index
		drag_offset = source_flasks[index].position - point
		source_flasks[index].z_index = 80
		source_flasks[index].scale = Vector2.ONE * (SOURCE_SCALE * 1.12)
		_play_color_voice(int(PAINTS[index].voice))
		get_viewport().set_input_as_handled()
		return


func _move_drag(viewport_point: Vector2) -> void:
	if dragged_index < 0:
		return
	var point := _to_stage(viewport_point) + drag_offset
	source_flasks[dragged_index].position = Vector2(
		clampf(point.x, 70.0, DESIGN_SIZE.x - 70.0),
		clampf(point.y, 260.0, DESIGN_SIZE.y - 90.0)
	)
	get_viewport().set_input_as_handled()


func _end_drag(viewport_point: Vector2, is_touch: bool, pointer_index: int) -> void:
	if dragged_index < 0 or dragged_touch != is_touch or (is_touch and pointer_index != touch_index):
		return
	var index := dragged_index
	dragged_index = -1
	touch_index = -1
	var point := _to_stage(viewport_point)
	get_viewport().set_input_as_handled()
	input_locked = true
	if point.distance_to(mixer_center) <= DROP_RADIUS:
		_set_status("pouring", Color("#71411f"))
		await _pour(index)
		_finish_ingredient(index)
	else:
		await _return_flask(index)
		input_locked = false
		_set_status("drag", Color("#71411f"))


func _pour(index: int) -> void:
	var flask := source_flasks[index]
	var on_left := index < 4
	# Place the rotated neck directly above the central neck. With the current
	# flask scale/angle its local mouth shifts about 48 px toward the center.
	var pour_position := mixer_center + Vector2(-48 if on_left else 48, -210)
	var angle := 65.0 if on_left else -65.0
	var approach := create_tween().set_parallel(true)
	approach.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	approach.tween_property(flask, "position", pour_position, 0.42)
	approach.tween_property(flask, "rotation_degrees", angle, 0.42)
	approach.tween_property(flask, "scale", Vector2.ONE * (SOURCE_SCALE * 1.06), 0.42)
	await approach.finished

	var ingredient_color := Color(String(PAINTS[index].hex))
	var stream := Line2D.new()
	stream.default_color = ingredient_color
	stream.width = 0.0
	stream.joint_mode = Line2D.LINE_JOINT_ROUND
	stream.begin_cap_mode = Line2D.LINE_CAP_ROUND
	stream.end_cap_mode = Line2D.LINE_CAP_ROUND
	stream.z_index = 75
	# These points follow the real mouths of the rotated source flask and
	# the central flask. This is the pouring geometry used by the prototype.
	var lip := flask.transform * Vector2(0, -470)
	var mouth := central_flask.transform * Vector2(0, -470)
	stream.points = PackedVector2Array([lip, lip.lerp(mouth, 0.5) + Vector2(0, 8), mouth])
	stage.add_child(stream)
	var stream_in := create_tween()
	stream_in.tween_property(stream, "width", 11.0, 0.17)
	await stream_in.finished

	var required: Array = RECIPES[recipe_index].needs
	var next_color := _calculated_color(index)
	var from_color := mixed_color
	var from_fill := mixed_fill
	var to_fill := minf(0.78, float(selected_ids.size() + 1) / float(required.size()) * 0.76)
	var flow := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flow.tween_method(_update_flow.bind(flask, ingredient_color, from_color, next_color, from_fill, to_fill), 0.0, 1.0, 0.73)
	await flow.finished
	mixed_color = next_color
	mixed_fill = to_fill
	var stream_out := create_tween()
	stream_out.tween_property(stream, "width", 0.0, 0.12)
	await stream_out.finished
	stream.queue_free()
	await _return_flask(index)
	flask.set_paint(ingredient_color, 0.72)


func _return_flask(index: int) -> void:
	var flask := source_flasks[index]
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(flask, "position", source_points[index], 0.34)
	tween.tween_property(flask, "rotation", 0.0, 0.34)
	tween.tween_property(flask, "scale", Vector2.ONE * SOURCE_SCALE, 0.34)
	await tween.finished
	flask.z_index = 7


func _finish_ingredient(index: int) -> void:
	selected_ids.append(String(PAINTS[index].id))
	var required: Array = RECIPES[recipe_index].needs
	recipe_count.text = "%d / %d" % [selected_ids.size(), required.size()]
	if selected_ids.size() < required.size():
		input_locked = false
		_set_status("more", Color("#71411f"))
		return
	if _sorted_strings(selected_ids) == _sorted_strings(required):
		await _complete_round()
	else:
		_set_status("retry", Color("#b44b42"))
		SFX.play_retry(mixer_center, 0.0)
		await get_tree().create_timer(1.0).timeout
		_reset_round_state()


func _complete_round() -> void:
	central_flask.set_paint(Color(String(RECIPES[recipe_index].hex)), 0.78)
	_set_status("correct", Color("#327947"))
	GameState.add_coins(1)
	SFX.play_2d(CORRECT_SOUND, mixer_center, -4.0)
	SFX.play_praise(mixer_center, 0.0)
	_play_color_voice(int(RECIPES[recipe_index].voice))
	var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(central_flask, "scale", Vector2.ONE * (MIXER_SCALE * 1.10), 0.22)
	pop.tween_property(central_flask, "scale", Vector2.ONE * MIXER_SCALE, 0.18)
	await pop.finished
	await get_tree().create_timer(1.05).timeout
	_start_random_round()


func _start_random_round() -> void:
	var next := randi_range(0, RECIPES.size() - 1)
	if RECIPES.size() > 1 and next == recipe_index:
		next = (next + randi_range(1, RECIPES.size() - 1)) % RECIPES.size()
	recipe_index = next
	_reset_round_state()
	var recipe: Dictionary = RECIPES[recipe_index]
	target_splash.modulate = Color(String(recipe.hex))
	target_name.text = _color_name(String(recipe.id))
	var required: Array = recipe.needs
	for index in ingredient_dots.size():
		var dot := ingredient_dots[index]
		dot.visible = index < required.size()
		if dot.visible:
			dot.add_theme_stylebox_override("panel", _dot_style(_paint_color(String(required[index]))))
	recipe_count.text = "0 / %d" % required.size()
	_set_status("drag", Color("#71411f"))
	input_locked = false
	call_deferred("_play_color_voice", int(recipe.voice))


func _reset_round_state() -> void:
	selected_ids.clear()
	mixed_color = Color.WHITE
	mixed_fill = 0.0
	dragged_index = -1
	touch_index = -1
	central_flask.set_paint(Color.WHITE, 0.0)
	central_flask.scale = Vector2.ONE * MIXER_SCALE
	for index in source_flasks.size():
		var flask := source_flasks[index]
		flask.position = source_points[index]
		flask.rotation = 0.0
		flask.scale = Vector2.ONE * SOURCE_SCALE
		flask.z_index = 7
		flask.set_paint(Color(String(PAINTS[index].hex)), 0.72)
	if recipe_index >= 0:
		recipe_count.text = "0 / %d" % (RECIPES[recipe_index].needs as Array).size()
	input_locked = false


func _calculated_color(incoming_index: int) -> Color:
	var incoming := Color(String(PAINTS[incoming_index].hex))
	if selected_ids.is_empty():
		return incoming
	var picks := selected_ids.duplicate()
	picks.append(String(PAINTS[incoming_index].id))
	var expected: Array = RECIPES[recipe_index].needs
	if _sorted_strings(picks) == _sorted_strings(expected):
		return Color(String(RECIPES[recipe_index].hex))
	return mixed_color.lerp(incoming, 0.5)


func _update_flow(t: float, flask: PaintFlask, ingredient: Color, before: Color, after: Color, fill_before: float, fill_after: float) -> void:
	flask.set_paint(ingredient, lerpf(0.72, 0.38, t))
	central_flask.set_paint(before.lerp(after, t), lerpf(fill_before, fill_after, t))


func _sorted_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	result.sort()
	return result


func _paint_color(paint_id: String) -> Color:
	for paint in PAINTS:
		if String(paint.id) == paint_id:
			return Color(String(paint.hex))
	return Color.WHITE


func _to_stage(viewport_point: Vector2) -> Vector2:
	return stage.get_global_transform_with_canvas().affine_inverse() * viewport_point


func _play_color_voice(index: int) -> void:
	if index < 0 or voice_player == null:
		return
	var stream := LanguageService.get_color_voice(index)
	if stream == null:
		return
	voice_player.stop()
	voice_player.stream = stream
	voice_player.play()


func _set_status(key: String, color: Color) -> void:
	status_label.text = _t(key)
	status_label.add_theme_color_override("font_color", color)


func _t(key: String) -> String:
	var values: Dictionary = TEXT.get(key, {})
	var locale := String(LanguageService.learning_locale)
	return String(values.get(locale, values.get("en", key)))


func _color_name(key: String) -> String:
	var values: Dictionary = COLOR_NAMES.get(key, {})
	var locale := String(LanguageService.learning_locale)
	return String(values.get(locale, values.get("en", key.to_upper())))


func _go_back() -> void:
	SFX.transition_to_scene(BACK_SCENE)


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	return label


func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.32, 0.16, 0.06, 0.23)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style


func _dot_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.WHITE
	style.set_border_width_all(5)
	style.set_corner_radius_all(35)
	style.shadow_color = Color(0.25, 0.12, 0.03, 0.25)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 4)
	return style


func _safe_area_insets(view: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_view := view / window_size
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	return Vector4(
		float(safe_rect.position.x) * scale_to_view.x,
		float(safe_rect.position.y) * scale_to_view.y,
		right_px * scale_to_view.x,
		bottom_px * scale_to_view.y
	)
