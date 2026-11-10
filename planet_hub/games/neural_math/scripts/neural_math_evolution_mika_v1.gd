extends Control
## MIKA / Neural Math • Evolution-style equation cards • Godot 4.7.1
## Isolated replacement for the original NeuralMath.tscn; no old TTS or keypad.
## One point per correct drop. Original shared neon title + BottomHUD center.

signal score_changed(value: int)
signal back_requested

const SHARED_HEADER = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD_SCRIPT = preload("res://planet_hub/scripts/bottom_hud.gd")
const BACK_GLYPH = preload("res://simulator_ui/back_arrow_glyph.gd")

const INK := Color("071629")
const PANEL := Color("0d223a")
const BORDER := Color("386483")
const CYAN := Color("65e7ff")
const MINT := Color("92f3ce")
const GOLD := Color("ffdb94")
const TEXT := Color("ecf9ff")
const MUTED := Color("aacfe4")
const ERROR := Color("ff8a9a")
const LOCALES := ["ru", "en", "pt", "es", "de", "fr"]
const LABELS := {
	"ru": {"title":"НЕЙРОННАЯ МАТЕМАТИКА", "subtitle":"Поставь правильную карточку в пустое место", "choose":"ВЫБЕРИ ОДИН ИЗ ПЯТИ ОТВЕТОВ", "tap":"Перетащи карточку или выбери её и нажми на пустую ячейку", "correct":"ВЕРНО! +1 БАЛЛ", "wrong":"ПОПРОБУЙ ЕЩЁ", "round":"ПРИМЕР", "points":"БАЛЛЫ", "restart":"ЗАНОВО"},
	"en": {"title":"NEURAL MATH", "subtitle":"Place the correct card in the empty space", "choose":"CHOOSE ONE OF FIVE ANSWERS", "tap":"Drag a card, or tap a card then tap the empty slot", "correct":"CORRECT! +1 POINT", "wrong":"TRY AGAIN", "round":"QUESTION", "points":"POINTS", "restart":"RESTART"},
	"pt": {"title":"MATEMÁTICA NEURAL", "subtitle":"Coloque a carta certa no espaço vazio", "choose":"ESCOLHA UMA DAS CINCO RESPOSTAS", "tap":"Arraste a carta ou toque nela e depois no espaço vazio", "correct":"CERTO! +1 PONTO", "wrong":"TENTE NOVAMENTE", "round":"QUESTÃO", "points":"PONTOS", "restart":"RECOMEÇAR"},
	"es": {"title":"MATEMÁTICA NEURAL", "subtitle":"Coloca la tarjeta correcta en el espacio vacío", "choose":"ELIGE UNA DE CINCO RESPUESTAS", "tap":"Arrastra una tarjeta o tócala y luego toca la casilla vacía", "correct":"¡BIEN! +1 PUNTO", "wrong":"INTÉNTALO OTRA VEZ", "round":"EJERCICIO", "points":"PUNTOS", "restart":"REINICIAR"},
	"de": {"title":"NEURONALE MATHEMATIK", "subtitle":"Setze die richtige Karte in das freie Feld", "choose":"WÄHLE EINE VON FÜNF ANTWORTEN", "tap":"Ziehe eine Karte oder tippe auf Karte und freies Feld", "correct":"RICHTIG! +1 PUNKT", "wrong":"VERSUCHE ES NOCHMAL", "round":"AUFGABE", "points":"PUNKTE", "restart":"NEUSTART"},
	"fr": {"title":"MATHS NEURONALES", "subtitle":"Place la bonne carte dans la case vide", "choose":"CHOISIS UNE DES CINQ RÉPONSES", "tap":"Glisse une carte ou touche la carte puis la case vide", "correct":"BRAVO ! +1 POINT", "wrong":"RÉESSAIE", "round":"QUESTION", "points":"POINTS", "restart":"RECOMMENCER"}
}

var score := 0
var _round := 0
var _correct_answer := ""
var _options: Array[String] = []
var _equation: Array[String] = []
var _missing_index := 0
var _rng := RandomNumberGenerator.new()
var _locale := "en"
var _locale_service: Node
var _selected := -1
var _active_pointer := -1
var _dragging := false
var _pointer_at := Vector2.ZERO
var _pointer_start := Vector2.ZERO
var _correct_lock := false
var _transition_time := 0.0
var _feedback_time := 0.0
var _feedback := ""
var _feedback_color := MINT
var _elapsed := 0.0

var _view := Vector2(1280,720)
var _safe := Rect2(28,18,1224,672)
var _stage := Rect2(29,126,1222,564)
var _target_rect := Rect2()
var _choice_rects: Array[Rect2] = []
var _expression_rects: Array[Rect2] = []
var _header_bottom := 96.0
var _font: Font

var _back: Button
var _host_back: Button
var _host_back_was_visible := true
var _title_panel: Panel
var _title_label: Label
var _subtitle_label: Label
var _hud_clip: Control
var _hud: Control
var _restart: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	_rng.randomize()
	_read_language()
	_build_header()
	_discover_host_back()
	_new_round()
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _read_language() -> void:
	_locale_service = get_node_or_null("/root/LanguageService")
	if _locale_service == null:
		_locale_service = get_node_or_null("/root/MobileLocale")
	if _locale_service != null:
		var v: Variant = _locale_service.get("interface_locale")
		if v == null:
			v = _locale_service.get("language")
		var code := str(v).substr(0,2)
		if LOCALES.has(code):
			_locale = code
		if _locale_service.has_signal("language_changed"):
			_locale_service.connect("language_changed", Callable(self,"_language_changed"))
	else:
		var cfg := ConfigFile.new()
		if cfg.load("user://mika_neural_math.cfg") == OK:
			var saved := str(cfg.get_value("settings","learning_locale","en"))
			if LOCALES.has(saved):
				_locale = saved


func _language_changed(_value: String) -> void:
	_read_language_again()
	_update_labels()
	_layout()


func _read_language_again() -> void:
	if _locale_service == null:
		return
	var v: Variant = _locale_service.get("interface_locale")
	if v == null:
		v = _locale_service.get("language")
	var code := str(v).substr(0,2)
	_locale = code if LOCALES.has(code) else "en"


func _t(key: String) -> String:
	var d: Dictionary = LABELS.get(_locale,LABELS["en"])
	return str(d.get(key,key))


func _style(fill: Color, edge: Color, radius: int = 18, weight: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.anti_aliasing = true
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(weight)
	box.set_corner_radius_all(radius)
	return box


func _build_header() -> void:
	_back = Button.new()
	_back.name = "NeuralMathSharedBack"
	_back.focus_mode = Control.FOCUS_NONE
	_back.z_index = 22
	_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_back.add_theme_stylebox_override("normal", _style(Color("061c38"),Color("26dfff")))
	_back.add_theme_stylebox_override("hover", _style(Color("113a60"),CYAN))
	_back.add_theme_stylebox_override("pressed", _style(Color("113a60"),CYAN))
	_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(_back)
	var arrow: Control = BACK_GLYPH.new() as Control
	_back.add_child(arrow)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back.pressed.connect(_return_to_cards)

	_title_panel = Panel.new()
	_title_panel.name = "NeuralMathStandardTitle"
	_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_panel.z_index = 20
	SHARED_HEADER.apply_title_style(_title_panel)
	add_child(_title_panel)
	_title_label = Label.new()
	_title_label.name = "NeuralMathTitleLabel"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.clip_text = true
	_title_label.add_theme_color_override("font_color",TEXT)
	_title_label.add_theme_color_override("font_outline_color",INK)
	_title_label.add_theme_constant_override("outline_size",2)
	_title_panel.add_child(_title_label)
	_subtitle_label = Label.new()
	_subtitle_label.name = "NeuralMathSubtitle"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_label.clip_text = true
	_subtitle_label.add_theme_color_override("font_color",MUTED)
	_title_panel.add_child(_subtitle_label)

	_hud_clip = Control.new()
	_hud_clip.name = "NativeCrystalCounterClipped"
	_hud_clip.clip_contents = true
	_hud_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_clip.z_index = 20
	add_child(_hud_clip)
	_hud = HUD_SCRIPT.new() as Control
	_hud.name = "NeuralMathNativeCrystalCounter"
	_hud_clip.add_child(_hud)
	# BottomHUD's 394 px center is retained. Original Simulator and Flight wings
	# are not interactive inside this minigame.
	for attr in ["sim_button","flight_button"]:
		var wing: Control = _hud.get(attr) as Control
		if wing != null:
			wing.hide()
			wing.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_restart = Button.new()
	_restart.name = "NeuralMathRestart"
	_restart.z_index = 17
	_restart.focus_mode = Control.FOCUS_NONE
	_restart.add_theme_stylebox_override("normal",_style(Color("15324c"),Color("568ba9"),13))
	_restart.add_theme_stylebox_override("hover",_style(Color("22506c"),CYAN,13))
	_restart.add_theme_stylebox_override("pressed",_style(Color("17435c"),MINT,13))
	_restart.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	_restart.add_theme_color_override("font_color",TEXT)
	_restart.pressed.connect(_restart_game)
	add_child(_restart)
	_update_labels()


func _discover_host_back() -> void:
	var holder: Node = get_viewport().get_parent()
	if holder == null:
		return
	var layer: Node = holder.get_parent()
	if layer == null:
		return
	for node_name in ["ReturnToEducationalCards","ReturnToExistingPlanetCards"]:
		var target := layer.get_node_or_null(node_name)
		if target is Button:
			_host_back = target as Button
			_host_back_was_visible = _host_back.visible
			_host_back.hide()
			return


func _return_to_cards() -> void:
	back_requested.emit()
	if is_instance_valid(_host_back):
		_host_back.pressed.emit()


func _exit_tree() -> void:
	if is_instance_valid(_host_back):
		_host_back.visible = _host_back_was_visible


func _update_labels() -> void:
	if _title_label == null:
		return
	_title_label.text = _t("title")
	_subtitle_label.text = _t("subtitle")
	_restart.text = _t("restart")
	_hud.set("crystal_count",score)
	queue_redraw()


func _safe_rect(view: Vector2) -> Rect2:
	var sx: float = clampf(view.x * 0.035, 12.0, 66.0)
	var sy: float = clampf(view.y * 0.027, 9.0, 29.0)
	var by: float = clampf(view.y * 0.046, 12.0, 42.0)
	# Respect device cutouts and the bottom gesture area for native mobile windows.
	if DisplayServer.get_name() in ["Android", "iOS"]:
		var display: Vector2i = DisplayServer.screen_get_size()
		var usable: Rect2i = DisplayServer.get_display_safe_area()
		if display.x > 0 and display.y > 0 and usable.size.x > 0 and usable.size.y > 0:
			sx = maxf(sx, maxf(float(usable.position.x),float(display.x-usable.end.x))/float(display.x)*view.x)
			sy = maxf(sy,float(usable.position.y)/float(display.y)*view.y)
			by = maxf(by,float(display.y-usable.end.y)/float(display.y)*view.y)
	sx = minf(sx,view.x*0.16)
	sy = minf(sy,view.y*0.13)
	by = minf(by,view.y*0.13)
	return Rect2(Vector2(sx,sy),Vector2(maxf(200.0,view.x-sx*2.0),maxf(150.0,view.y-sy-by)))


func _layout() -> void:
	if _title_panel == null:
		return
	_view = size if size.x > 150.0 and size.y > 180.0 else get_viewport_rect().size
	_safe = _safe_rect(_view)
	# Exact dimensions from the shared title / BottomHUD header logic.
	var sw := _safe.size.x
	var sh := _safe.size.y
	var s: float = minf(_view.x/1680.0,_view.y/864.0)
	var margin: float = clampf(sw*0.018,5.0,28.0)
	var gap: float = clampf(sw*0.015,5.0,22.0)
	var minimum_title: float = minf(260.0*s,sw*0.32)
	var required: float = 158.0*0.60+394.0*0.80+minimum_title/maxf(s,0.01)
	s = minf(s,maxf(0.08,(sw-2.0*margin-2.0*gap)/required))
	var back_size := 158.0*s*0.60
	var counter_h := 158.0*s*0.80
	var counter_w := 394.0*s*0.80
	var top: float = _safe.position.y+clampf(sh*0.022,5.0,22.0)
	var left: float = _safe.position.x+margin
	var counter_left: float = _safe.end.x-margin-counter_w
	var title_left: float = left+back_size+gap
	var title_width: float = maxf(32.0,counter_left-gap-title_left)
	_back.position = Vector2(left,top+(counter_h-back_size)*0.5)
	_back.size = Vector2.ONE*back_size
	_title_panel.position = Vector2(title_left,top)
	_title_panel.size = Vector2(title_width,counter_h)
	_title_label.position = Vector2(6.0,counter_h*0.055)
	_title_label.size = Vector2(maxf(26.0,title_width-12.0),counter_h*0.60)
	_subtitle_label.position = Vector2(6.0,counter_h*0.66)
	_subtitle_label.size = Vector2(maxf(26.0,title_width-12.0),counter_h*0.28)
	_subtitle_label.visible = title_width>=170.0
	var title_px := maxf(9.0,minf(39.0*s,(title_width-16.0)/maxf(1.0,float(_title_label.text.length())*0.55)))
	_title_label.add_theme_font_size_override("font_size",maxi(10,roundi(title_px)))
	var subtitle_px := maxf(8.0,minf(17.0*s,(title_width-16.0)/maxf(1.0,float(_subtitle_label.text.length())*0.48)))
	_subtitle_label.add_theme_font_size_override("font_size",maxi(8,roundi(subtitle_px)))
	_hud_clip.position = Vector2(counter_left,top)
	_hud_clip.size = Vector2(counter_w,counter_h)
	_hud.size = Vector2(1680.0,158.0)
	_hud.scale = Vector2.ONE*s*0.80
	_hud.position = Vector2(-643.0*s*0.80,0.0)
	_header_bottom = top+counter_h
	var stage_top: float = _header_bottom+clampf(sh*0.030,6.0,20.0)
	_stage = Rect2(Vector2(_safe.position.x+margin,stage_top),Vector2(_safe.size.x-2.0*margin,maxf(110.0,_safe.end.y-stage_top-6.0)))

	# Evolution layout: equation above, five equally sized answer cards below.
	var w: float = _stage.size.x
	var h: float = _stage.size.y
	var equation_h: float = clampf(h*0.235,45.0,135.0)
	var equation_mid: float = _stage.position.y+h*0.37
	var unit_w: float = minf(w*0.19,equation_h*1.27)
	var small_w: float = unit_w*0.75
	var span: float = unit_w*3.0+small_w*2.0+minf(20.0,w*0.018)*4.0
	var available: float = w*0.88
	var factor: float = minf(1.0,available/maxf(span,1.0))
	unit_w *= factor
	small_w *= factor
	var eq_gap: float = minf(20.0,w*0.018)*factor
	span = unit_w*3.0+small_w*2.0+eq_gap*4.0
	var xx: float = _stage.get_center().x-span*0.5
	_expression_rects.clear()
	for i in range(5):
		var tw: float = small_w if i == 1 or i == 3 else unit_w
		_expression_rects.append(Rect2(Vector2(xx,equation_mid-equation_h*0.5),Vector2(tw,equation_h)))
		xx += tw+eq_gap
	_target_rect = _expression_rects[_missing_index]
	var opt_gap: float = clampf(w*0.014,5.0,20.0)
	var choices_width: float = w*0.87
	var opt_width: float = (choices_width-4.0*opt_gap)/5.0
	var opt_height: float = clampf(h*0.21,44.0,110.0)
	var opt_y: float = _stage.end.y-opt_height-clampf(h*0.045,10.0,34.0)
	var opt_x: float = _stage.get_center().x-choices_width*0.5
	_choice_rects.clear()
	for i in range(5):
		_choice_rects.append(Rect2(Vector2(opt_x+i*(opt_width+opt_gap),opt_y),Vector2(opt_width,opt_height)))
	var rw: float = clampf(w*0.12,58.0,156.0)
	var rh: float = clampf(h*0.073,23.0,38.0)
	_restart.position = Vector2(_stage.end.x-rw-maxf(10.0,w*0.018),_stage.position.y+clampf(h*0.035,8.0,20.0))
	_restart.size = Vector2(rw,rh)
	_restart.add_theme_font_size_override("font_size",maxi(10,roundi(minf(17.0,rh*0.50))))
	queue_redraw()


func _restart_game() -> void:
	score = 0
	_round = 0
	_correct_lock = false
	_transition_time = 0.0
	_feedback_time = 0.0
	_hud.set("crystal_count",0)
	score_changed.emit(score)
	_new_round()


func _new_round() -> void:
	_selected = -1
	_active_pointer = -1
	_dragging = false
	_correct_lock = false
	_feedback = ""
	_feedback_time = 0.0
	# Four numeric completions followed by one missing-operator puzzle.
	var sign_mode: bool = _round % 5 == 4
	var op: String = "+" if _rng.randi_range(0,1)==0 else "−"
	var a: int = _rng.randi_range(2,12)
	var b: int = _rng.randi_range(1,9)
	var result: int = 0
	if op == "−":
		a = maxi(a,b)
		b = mini(a-1,b)
		b = maxi(1,b)
		result = a-b
	else:
		result = a+b
	if sign_mode:
		# Prevent a second true operation when options include multiplication.
		while op == "+" and a*b == a+b:
			a = _rng.randi_range(3,12)
			b = _rng.randi_range(3,9)
			result = a+b
		_missing_index = 1
		_correct_answer = op
		_options.assign(["+","−","×","÷","≠"])
		_options.shuffle()
	else:
		_missing_index = [0,2,4][_rng.randi_range(0,2)]
		_correct_answer = str(a if _missing_index == 0 else (b if _missing_index==2 else result))
		_options = _numeric_choices(int(_correct_answer))
	_equation.assign([str(a),op,str(b),"=",str(result)])
	_layout()
	queue_redraw()


func _numeric_choices(correct: int) -> Array[String]:
	var values: Array[int] = [correct]
	var attempts := 0
	while values.size() < 5 and attempts < 120:
		attempts += 1
		var n := clampi(correct+_rng.randi_range(-9,9),0,25)
		if not values.has(n):
			values.append(n)
	var n := 0
	while values.size() < 5:
		if not values.has(n):
			values.append(n)
		n += 1
	values.shuffle()
	var choices: Array[String] = []
	for number in values:
		choices.append(str(number))
	return choices


func _try_answer(index: int) -> void:
	if _correct_lock or index < 0 or index >= _options.size():
		return
	if _options[index] == _correct_answer:
		_correct_lock = true
		score += 1
		_hud.set("crystal_count",score)
		score_changed.emit(score)
		_feedback = _t("correct")
		_feedback_color = MINT
		_transition_time = 0.85
		_feedback_time = 0.85
	else:
		_feedback = _t("wrong")
		_feedback_color = ERROR
		_feedback_time = 1.4
		_selected = -1
	queue_redraw()


func _choice_at(point: Vector2) -> int:
	for i in range(_choice_rects.size()):
		if _choice_rects[i].has_point(point):
			return i
	return -1


func _handle_press(pointer: int, point: Vector2) -> void:
	if _correct_lock or _active_pointer >= 0:
		return
	var chosen: int = _choice_at(point)
	if chosen >= 0:
		_selected = chosen
		_active_pointer = pointer
		_pointer_start = point
		_pointer_at = point
		_dragging = false
		queue_redraw()
	elif _target_rect.grow(12.0).has_point(point) and _selected >= 0:
		_try_answer(_selected)


func _handle_move(pointer: int, point: Vector2) -> void:
	if pointer != _active_pointer:
		return
	_pointer_at = point
	_dragging = _dragging or point.distance_to(_pointer_start)>9.0
	queue_redraw()


func _handle_release(pointer: int, point: Vector2) -> void:
	if pointer != _active_pointer:
		return
	if _selected >= 0 and _dragging and _target_rect.grow(18.0).has_point(point):
		_try_answer(_selected)
	_dragging = false
	_active_pointer = -1
	queue_redraw()


func _screen_to_local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse()*point


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_handle_press(touch.index,_screen_to_local(touch.position))
		else:
			_handle_release(touch.index,_screen_to_local(touch.position))
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		_handle_move(drag.index,_screen_to_local(drag.position))
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_handle_press(10000,_screen_to_local(mouse.position))
		else:
			_handle_release(10000,_screen_to_local(mouse.position))
	elif event is InputEventMouseMotion and _active_pointer == 10000:
		_handle_move(10000,_screen_to_local((event as InputEventMouseMotion).position))


func _process(delta: float) -> void:
	_elapsed += delta
	if _feedback_time>0.0:
		_feedback_time = maxf(0.0,_feedback_time-delta)
	if _transition_time>0.0:
		_transition_time = maxf(0.0,_transition_time-delta)
		if _transition_time==0.0:
			_round += 1
			_new_round()
	queue_redraw()


func _box(rect: Rect2, fill: Color, edge: Color, radius: int = 20, thick: int = 2) -> void:
	draw_style_box(_style(fill,edge,radius,thick),rect)


func _print_center(text_value: String, rect: Rect2, font_max: float, tint: Color = TEXT) -> void:
	if _font == null or rect.size.x<=0.0:
		return
	var px: int = maxi(12,roundi(minf(font_max,rect.size.y*0.58)))
	while px>12 and _font.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1.0,px).x > rect.size.x-8.0:
		px -= 1
	var baseline: float = rect.get_center().y+float(px)*0.35
	draw_string(_font,Vector2(rect.position.x+4.0,baseline),text_value,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-8.0,px,tint)


func _draw() -> void:
	if _expression_rects.size()!=5 or _options.size()!=5:
		return
	draw_rect(Rect2(Vector2.ZERO,_view),INK)
	_box(_stage,PANEL,CYAN,26,3)
	# A discreet original neural network; Evolution-style clean central stage.
	for i in range(13):
		var xx: float = _stage.position.x+20.0+fmod(float(i*151),maxf(1.0,_stage.size.x-45.0))
		var yy: float = _stage.position.y+35.0+fmod(float(i*43),maxf(1.0,_stage.size.y-70.0))
		var p := Vector2(xx,yy)
		draw_circle(p,3.5,Color(0.42,0.79,1.0,0.17))
		if i<12:
			var qq := p+Vector2(25.0,-20.0)
			if _stage.grow(-22.0).has_point(qq):
				draw_line(p,qq,Color(0.3,0.68,0.95,0.11),1.5)
	var h: float = _stage.size.y
	var meta_rect := Rect2(_stage.position.x+24.0,_stage.position.y+clampf(h*0.045,11.0,23.0),_stage.size.x*0.47,28.0)
	_print_center("%s %d" % [_t("round"),_round+1],meta_rect,22.0,MINT)
	var guide_rect := Rect2(_stage.position.x+20.0,_stage.position.y+h*0.145,_stage.size.x-40.0,maxf(20.0,h*0.09))
	_print_center(_t("tap"),guide_rect,minf(20.0,h*0.061),MUTED)

	for i in range(5):
		var rect: Rect2 = _expression_rects[i]
		var unknown: bool = i==_missing_index
		var edge: Color = MINT if _correct_lock and unknown else (GOLD if unknown else BORDER)
		var fill: Color = Color("255269") if unknown else Color("122c48")
		_box(rect,fill,edge,18,3 if unknown else 2)
		if unknown:
			draw_arc(rect.get_center(),minf(rect.size.x,rect.size.y)*0.43,0.0,TAU,48,Color(1.0,0.84,0.53,0.19+0.08*sin(_elapsed*3.0)),2.0,true)
		var val: String = _correct_answer if _correct_lock and unknown else ("?" if unknown else _equation[i])
		_print_center(val,rect,minf(70.0,rect.size.y*0.73),MINT if _correct_lock and unknown else (GOLD if unknown else TEXT))

	var choose_rect := Rect2(_stage.position.x+20.0,_choice_rects[0].position.y-clampf(h*0.11,23.0,56.0),_stage.size.x-40.0,30.0)
	_print_center(_feedback if _feedback_time>0.0 else _t("choose"),choose_rect,minf(22.0,h*0.068),_feedback_color if _feedback_time>0.0 else MUTED)
	for i in range(5):
		var rect: Rect2 = _choice_rects[i]
		var selected: bool = i==_selected
		var is_correct: bool = _correct_lock and _options[i]==_correct_answer
		var accent: Color = MINT if is_correct else (GOLD if selected else Color("4c87a9"))
		_box(rect,Color("15374f") if not selected else Color("28506b"),accent,19,3 if selected else 2)
		_print_center(_options[i],rect,minf(51.0,rect.size.y*0.7),TEXT)
	if _dragging and _selected>=0 and not _correct_lock:
		var rw: float = _choice_rects[_selected].size.x
		var rh: float = _choice_rects[_selected].size.y
		var ghost: Rect2 = Rect2(_pointer_at-Vector2(rw,rh)*0.5,Vector2(rw,rh))
		_box(ghost,Color(0.16,0.35,0.48,0.95),GOLD,17,3)
		_print_center(_options[_selected],ghost,minf(52.0,rh*0.69),TEXT)
