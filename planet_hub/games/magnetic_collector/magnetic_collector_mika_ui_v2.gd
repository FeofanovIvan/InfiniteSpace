extends "res://planet_hub/games/magnetic_collector/MagneticCollector.gd"
## MIKA / Magnetic Collector v2: fluid frame, axis-locked rail joysticks,
## magnetic/nonmagnetic PNGs, four-light bin and batch-only crystal awards.
## The original game remains present and is not modified.

const MIKA_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_GLYPH = preload("res://simulator_ui/back_arrow_glyph.gd")
const ART_ROOT := "res://planet_hub/games/magnetic_collector/art_v2/"
const ECO_ROOT := "res://planet_hub/games/eco_sorting/art_v5/"
const BIN_ART: Texture2D = preload("res://planet_hub/games/magnetic_collector/art_v2/open_scrap_container.png")
const MAGNET_KINDS: Array[String] = ["bolt", "gear", "nut", "washer", "spring", "screw", "steel_can"]
const OTHER_KINDS: Array[String] = ["plastic_bottle", "aluminum_can", "glass_bottle", "cardboard", "banana", "plastic_bag"]
const ART_FILES: Dictionary = {
	"bolt": ART_ROOT + "01_bolt.png", "gear": ART_ROOT + "02_gear.png",
	"nut": ART_ROOT + "03_nut.png", "washer": ART_ROOT + "04_washer.png",
	"spring": ART_ROOT + "05_spring.png", "screw": ART_ROOT + "06_screw.png",
	"steel_can": ECO_ROOT + "11_metal_food_can.png",
	"plastic_bottle": ECO_ROOT + "01_plastic_bottle.png",
	"aluminum_can": ECO_ROOT + "02_crushed_aluminum_can.png",
	"glass_bottle": ECO_ROOT + "03_glass_bottle.png",
	"cardboard": ECO_ROOT + "05_cardboard_box.png",
	"banana": ECO_ROOT + "08_banana_peel.png",
	"plastic_bag": ECO_ROOT + "10_plastic_bag.png"
}
const SPEECH: Dictionary = {
	"ru": {"first":"Заполни контейнер. Собери четыре магнитных предмета.","find":"Найди металлические предметы. Не все металлы притягиваются магнитом.","horizontal":"Передвигай магнит влево и вправо.","vertical":"Опускай и поднимай магнит.","grab":"Захвати предмет.","release":"Отпусти предмет над контейнером.","wrong":"Этот предмет не притягивается магнитом.","complete":"Контейнер заполнен. Четыре кристалла!", "near":"Опусти магнит ближе к предмету.","bay":"Перенеси предмет над контейнером."},
	"en": {"first":"Fill the container. Collect four magnetic objects.","find":"Find the magnetic metal objects. Not every metal sticks to magnets.","horizontal":"Move the magnet left and right.","vertical":"Raise and lower the magnet.","grab":"Grab the object.","release":"Release it over the container.","wrong":"This object is not magnetic.","complete":"Container full. Four crystals!","near":"Move closer to an object.","bay":"Move the object above the container."},
	"pt": {"first":"Encha o recipiente. Recolha quatro objetos magnéticos.","find":"Encontre objetos metálicos magnéticos. Nem todos os metais são atraídos.","horizontal":"Mova o ímã para a esquerda e direita.","vertical":"Suba e desça o ímã.","grab":"Pegue o objeto.","release":"Solte o objeto sobre o recipiente.","wrong":"Este objeto não é magnético.","complete":"Recipiente cheio. Quatro cristais!","near":"Aproxime o ímã do objeto.","bay":"Leve o objeto ao recipiente."},
	"es": {"first":"Llena el contenedor. Recoge cuatro objetos magnéticos.","find":"Encuentra objetos metálicos magnéticos. No todos los metales se atraen.","horizontal":"Mueve el imán a izquierda y derecha.","vertical":"Sube y baja el imán.","grab":"Atrapa el objeto.","release":"Suéltalo sobre el contenedor.","wrong":"Este objeto no es magnético.","complete":"Contenedor lleno. ¡Cuatro cristales!","near":"Acerca el imán al objeto.","bay":"Lleva el objeto sobre el contenedor."},
	"de": {"first":"Fülle den Behälter. Sammle vier magnetische Gegenstände.","find":"Finde magnetische Metallgegenstände. Nicht jedes Metall ist magnetisch.","horizontal":"Bewege den Magneten nach links und rechts.","vertical":"Bewege den Magneten nach oben und unten.","grab":"Greife den Gegenstand.","release":"Lass ihn über dem Behälter los.","wrong":"Dieser Gegenstand ist nicht magnetisch.","complete":"Behälter voll. Vier Kristalle!","near":"Bewege den Magneten näher heran.","bay":"Bringe den Gegenstand über den Behälter."},
	"fr": {"first":"Remplis le conteneur. Ramasse quatre objets magnétiques.","find":"Trouve les objets métalliques magnétiques. Tous les métaux ne sont pas attirés.","horizontal":"Déplace l'aimant de gauche à droite.","vertical":"Monte et descends l'aimant.","grab":"Attrape l'objet.","release":"Lâche-le au-dessus du conteneur.","wrong":"Cet objet n'est pas magnétique.","complete":"Conteneur plein. Quatre cristaux !","near":"Approche l'aimant d'un objet.","bay":"Amène l'objet au conteneur."}
}
const TITLES: Dictionary = {
	"ru":["ЗАПОЛНИ КОНТЕЙНЕР", "НАЙДИ МЕТАЛЛИЧЕСКИЕ ПРЕДМЕТЫ"],
	"en":["FILL THE CONTAINER", "FIND THE MAGNETIC METALS"],
	"pt":["ENCHA O RECIPIENTE", "ENCONTRE METAIS MAGNÉTICOS"],
	"es":["LLENA EL CONTENEDOR", "ENCUENTRA METALES MAGNÉTICOS"],
	"de":["FÜLLE DEN BEHÄLTER", "FINDE MAGNETISCHE METALLE"],
	"fr":["REMPLIS LE CONTENEUR", "TROUVE LES MÉTAUX MAGNÉTIQUES"]
}

var _v2_back: Button
var _v2_title_panel: Panel
var _v2_title: Label
var _v2_subtitle: Label
var _v2_counter_clip: Control
var _v2_counter: Control
var _v2_host_back: Button
var _v2_host_visible := true
var _v2_textures: Dictionary = {}
var _v2_screen := Vector2(1280.0, 720.0)
var _v2_sx := 1.0
var _v2_sy := 1.0
var _v2_round := 0
var _v2_next_pending := false
var _v2_left_touch := -1
var _v2_right_touch := -1
var _v2_mouse_held := false
var _v2_voice_once_left := false
var _v2_voice_once_right := false
var _v2_test_no_auto := false
var _v2_test_no_rewards := false


func _ready() -> void:
	super._ready()
	for kind in ART_FILES:
		_v2_textures[kind] = load(str(ART_FILES[kind])) as Texture2D
	_v2_create_header()
	_v2_find_host_back()
	_v2_hide_legacy()
	_style_button(_grab_button, Color("0b365b"), Color("65e7ff"))
	_grab_button.add_theme_font_size_override("font_size", 24)
	_grab_button.z_index = 15
	_layout_ui()
	_apply_translation()
	_refresh_ui()
	call_deferred("_v2_speak", "first")


func _v2_create_header() -> void:
	_v2_back = Button.new()
	_v2_back.name = "MikaMagnetTopBarBack"
	_v2_back.text = ""
	_v2_back.z_index = 20
	_v2_back.focus_mode = Control.FOCUS_NONE
	_v2_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var s := StyleBoxFlat.new()
	s.bg_color = Color("061c38")
	s.border_color = Color("26dfff")
	s.set_border_width_all(2)
	s.set_corner_radius_all(18)
	_v2_back.add_theme_stylebox_override("normal", s)
	var hover := s.duplicate() as StyleBoxFlat
	hover.bg_color = Color("113a60")
	_v2_back.add_theme_stylebox_override("hover", hover)
	_v2_back.add_theme_stylebox_override("pressed", hover)
	_v2_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(_v2_back)
	var glyph := MIKA_GLYPH.new() as Control
	_v2_back.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_v2_back.pressed.connect(_v2_return)

	_v2_title_panel = Panel.new()
	_v2_title_panel.name = "MagnetTopBarTitle"
	_v2_title_panel.z_index = 20
	_v2_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("061c38")
	panel.border_color = Color("65e7ff")
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(24)
	_v2_title_panel.add_theme_stylebox_override("panel", panel)
	add_child(_v2_title_panel)
	_v2_title = Label.new()
	_v2_title.name = "MagnetRoundTitle"
	_v2_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v2_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_v2_title.clip_text = true
	_v2_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_v2_title.add_theme_color_override("font_color", Color.WHITE)
	_v2_title_panel.add_child(_v2_title)
	_v2_subtitle = Label.new()
	_v2_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v2_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_v2_subtitle.clip_text = true
	_v2_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_v2_subtitle.add_theme_color_override("font_color", Color("9bd6ea"))
	_v2_title_panel.add_child(_v2_subtitle)

	_v2_counter_clip = Control.new()
	_v2_counter_clip.name = "MagnetCrystalCounterClipped"
	_v2_counter_clip.clip_contents = true
	_v2_counter_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_v2_counter_clip.z_index = 20
	add_child(_v2_counter_clip)
	_v2_counter = MIKA_HUD.new() as Control
	_v2_counter_clip.add_child(_v2_counter)
	_v2_counter.name = "MagnetBatchCrystalCounter"
	for wing_name in ["sim_button", "flight_button"]:
		var wing := _v2_counter.get(wing_name) as Control
		if wing != null:
			wing.hide()
			wing.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _v2_find_host_back() -> void:
	var holder: Node = get_viewport().get_parent()
	if holder == null:
		return
	var layer: Node = holder.get_parent()
	if layer == null:
		return
	for node_name in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
		var node := layer.get_node_or_null(node_name)
		if node is Button:
			_v2_host_back = node as Button
			_v2_host_visible = _v2_host_back.visible
			_v2_host_back.hide()
			return


func _v2_return() -> void:
	if is_instance_valid(_v2_host_back):
		_v2_host_back.pressed.emit()
	else:
		get_tree().quit()


func _exit_tree() -> void:
	if is_instance_valid(_v2_host_back):
		_v2_host_back.visible = _v2_host_visible


func _v2_hide_legacy() -> void:
	for node in [_title, _subtitle, _score_label, _level_label, _language_picker,
		_restart_button, _hint_button, _pause_button, _instruction_label,
		_left_help, _right_help, _footer, _bay_label, _bay_hint,
		_progress_label, _overlay]:
		if is_instance_valid(node):
			node.hide()


func _v2_locale() -> String:
	return _ui_lang if SPEECH.has(_ui_lang) else "en"


func _v2_speak(key: String) -> void:
	if not is_inside_tree() or DisplayServer.get_name() == "headless":
		return
	var lang: String = _v2_locale()
	var pack: Dictionary = SPEECH.get(lang, SPEECH["en"])
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(lang)
	if voices.is_empty():
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(str(pack.get(key, "")), voices[0], 80, 1.0, 0.96, 0, true)


func _layout_ui() -> void:
	super._layout_ui()
	if _v2_title_panel == null or _v2_counter_clip == null:
		return
	_v2_screen = size if size.x > 100.0 and size.y > 100.0 else get_viewport_rect().size
	_v2_sx = _v2_screen.x / 1280.0
	_v2_sy = _v2_screen.y / 720.0
	var margin: float = 20.0 * _v2_sx
	var gap: float = maxf(7.0, 13.0 * minf(_v2_sx, _v2_sy))
	var header_h: float = clampf(_v2_screen.y * 0.11, 49.0, 94.0)
	var top: float = 18.0 * _v2_sy
	var back_size: float = header_h
	var counter_width: float = 394.0 * header_h / 158.0
	var left_title: float = margin + back_size + gap
	var right_counter: float = _v2_screen.x - margin - counter_width
	var title_width: float = maxf(30.0, right_counter - gap - left_title)
	_v2_back.position = Vector2(margin, top)
	_v2_back.size = Vector2.ONE * back_size
	_v2_title_panel.position = Vector2(left_title, top)
	_v2_title_panel.size = Vector2(title_width, header_h)
	_v2_title.position = Vector2(7, 0)
	_v2_title.size = Vector2(maxf(20.0, title_width - 14), header_h * 0.67)
	var char_n: int = maxi(_v2_title.text.length(), 1)
	var font_size: float = clampf(header_h * 0.38 * minf(1.0, (title_width / maxf(1.0, float(char_n) * header_h * 0.23))), 13.0, 32.0)
	_v2_title.add_theme_font_size_override("font_size", roundi(font_size))
	_v2_subtitle.position = Vector2(7, header_h * 0.67)
	_v2_subtitle.size = Vector2(maxf(20.0, title_width - 14), header_h * 0.27)
	_v2_subtitle.add_theme_font_size_override("font_size", maxi(9, roundi(header_h * 0.18)))
	_v2_subtitle.visible = title_width >= 145.0
	_v2_counter_clip.position = Vector2(right_counter, top)
	_v2_counter_clip.size = Vector2(counter_width, header_h)
	_v2_counter.size = Vector2(1680.0, 158.0)
	var hud_scale: float = header_h / 158.0
	_v2_counter.scale = Vector2.ONE * hud_scale
	_v2_counter.position = Vector2(-643.0 * hud_scale, 0.0)
	# Core view is stretched to the device, not letterboxed to 1280x720.
	_place(_feedback, Rect2(385.0, 545.0, 770.0, 30.0))
	_feedback.position = Vector2(385.0 * _v2_sx, 545.0 * _v2_sy)
	_feedback.size = Vector2(770.0 * _v2_sx, 30.0 * _v2_sy)
	_feedback.scale = Vector2.ONE
	_feedback.add_theme_font_size_override("font_size", maxi(11, roundi(18.0 * _v2_sy)))
	_grab_button.position = Vector2(522.0 * _v2_sx, 622.0 * _v2_sy)
	_grab_button.size = Vector2(236.0 * _v2_sx, 69.0 * _v2_sy)
	_grab_button.scale = Vector2.ONE
	_grab_button.add_theme_font_size_override("font_size", maxi(12, roundi(23.0 * _v2_sy)))
	queue_redraw()


func _apply_translation() -> void:
	super._apply_translation()
	_v2_update_title()


func _v2_update_title() -> void:
	if _v2_title == null:
		return
	var lang := _v2_locale()
	var titles: Array = TITLES[lang]
	_v2_title.text = str(titles[0 if _v2_round == 0 else 1])
	_v2_subtitle.text = "MAGNET CRANE  •  %d / 4" % _collected
	# Text can change between rounds, so re-fit font instead of keeping the
	# size computed for the empty title during the first layout pass.
	if _v2_title_panel != null and _v2_title_panel.size.x > 10.0:
		var available: float = _v2_title_panel.size.x - 18.0
		var count: int = maxi(1, _v2_title.text.length())
		var baseline: float = _v2_title_panel.size.y * 0.38
		var fitted: float = minf(baseline, available / (float(count) * 0.57))
		_v2_title.add_theme_font_size_override("font_size", maxi(12, roundi(fitted)))


func _refresh_ui() -> void:
	super._refresh_ui()
	if _v2_counter != null:
		_v2_counter.set("crystal_count", _score)
		_v2_update_title()
	if _overlay != null:
		_overlay.hide()
	if _grab_button != null:
		_grab_button.disabled = _level_complete
	queue_redraw()


func _new_game() -> void:
	_v2_round = 0
	_score = 0
	_start_level()


func _start_level() -> void:
	_level_index = mini(_v2_round, 1)
	_level_goal = 4
	_collected = 0
	_carrying = -1
	_level_complete = false
	_paused = false
	_v2_next_pending = false
	_v2_left_touch = -1
	_v2_right_touch = -1
	_v2_voice_once_left = false
	_v2_voice_once_right = false
	_left_axis = 0.0
	_right_axis = 0.0
	_magnet_pos = Vector2(730.0, 326.0)
	_hint_index = -1
	_hint_timer = 0.0
	_objects.clear()
	_particles.clear()
	var metals: Array[String] = MAGNET_KINDS.duplicate()
	metals.shuffle()
	var picks: Array[String] = []
	for index in range(4):
		picks.append(metals[index])
	if _v2_round >= 1:
		picks.append_array(OTHER_KINDS)
	picks.shuffle()
	var start_x := 435.0
	var span: float = 732.0 / float(maxi(1, picks.size() - 1))
	for index in range(picks.size()):
		var kind := picks[index]
		_objects.append({"kind":kind, "magnetic":MAGNET_KINDS.has(kind),
			"pos":Vector2(start_x + span * float(index), 508.0 - float(index % 3) * 2.0), "delivered":false})
	_set_feedback("ready", 0.0)
	_refresh_ui()
	if _v2_title != null:
		call_deferred("_v2_speak", "first" if _v2_round == 0 else "find")


func _release_item() -> void:
	if _carrying < 0 or _level_complete:
		return
	var current: Dictionary = _objects[_carrying]
	if _magnet_pos.x <= 335.0:
		current["delivered"] = true
		_objects[_carrying] = current
		_carrying = -1
		_collected += 1
		_flash = 0.8
		_spawn_sparks(Vector2(222.0, 463.0), GREEN, 18)
		_set_feedback("delivered", 1.6)
		if _collected == 4:
			_level_complete = true
			_score += 4
			if not _v2_test_no_rewards:
				var state: Node = get_node_or_null("/root/GameState")
				if state != null:
					if state.has_method("add_coins"):
						state.call("add_coins", 4)
					state.set("last_score", _score)
			_spawn_sparks(Vector2(232.0, 530.0), GREEN, 36)
			_set_feedback("complete", 1.4)
			_v2_speak("complete")
			if not _v2_next_pending and not _v2_test_no_auto:
				_v2_next_pending = true
				_v2_advance_later()
	else:
		current["pos"] = Vector2(clampf(_magnet_pos.x, 414.0, 1170.0), 508.0)
		_objects[_carrying] = current
		_carrying = -1
		_set_feedback("not_at_bay", 2.0)
		_v2_speak("bay")
	# Both direct delivery and normal Button-driven delivery refresh the HUD.
	_refresh_ui()


func _v2_advance_later() -> void:
	await get_tree().create_timer(1.45).timeout
	if not is_inside_tree() or not _v2_next_pending:
		return
	_v2_round += 1
	_start_level()


func _grab_item() -> void:
	super._grab_item()
	if _carrying >= 0:
		_v2_speak("grab")
	elif _feedback_key == "not_magnetic":
		_v2_speak("wrong")
	else:
		_v2_speak("near")


func _screen_to_design(pos: Vector2) -> Vector2:
	var display: Vector2 = size if size.x > 100.0 and size.y > 100.0 else get_viewport_rect().size
	return Vector2(pos.x * 1280.0 / maxf(display.x, 1.0), pos.y * 720.0 / maxf(display.y, 1.0))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_toggle_magnet()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_new_game()
	if event is InputEventScreenTouch:
		var point := _screen_to_design(event.position)
		if event.pressed:
			_v2_pointer_down(event.index, point)
		else:
			_v2_pointer_up(event.index)
	elif event is InputEventScreenDrag:
		_v2_pointer_move(event.index, _screen_to_design(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_v2_mouse_held = event.pressed
		if event.pressed:
			_v2_pointer_down(1000, _screen_to_design(event.position))
		else:
			_v2_pointer_up(1000)
	elif event is InputEventMouseMotion and _v2_mouse_held:
		_v2_pointer_move(1000, _screen_to_design(event.position))


func _v2_pointer_down(pointer: int, point: Vector2) -> void:
	if _level_complete:
		return
	if Rect2(64, 608, 404, 94).has_point(point) and _v2_left_touch < 0:
		_v2_left_touch = pointer
		_v2_pointer_move(pointer, point)
		if not _v2_voice_once_left:
			_v2_voice_once_left = true
			_v2_speak("horizontal")
	elif Rect2(992, 610, 207, 92).has_point(point) and _v2_right_touch < 0:
		_v2_right_touch = pointer
		_v2_pointer_move(pointer, point)
		if not _v2_voice_once_right:
			_v2_voice_once_right = true
			_v2_speak("vertical")


func _v2_pointer_move(pointer: int, point: Vector2) -> void:
	if pointer == _v2_left_touch:
		_left_axis = clampf((point.x - 265.0) / 145.0, -1.0, 1.0)
	if pointer == _v2_right_touch:
		_right_axis = clampf((point.y - 653.0) / 26.0, -1.0, 1.0)
	queue_redraw()


func _v2_pointer_up(pointer: int) -> void:
	if pointer == _v2_left_touch:
		_v2_left_touch = -1
		_left_axis = 0.0
	if pointer == _v2_right_touch:
		_v2_right_touch = -1
		_right_axis = 0.0
	queue_redraw()


func _draw() -> void:
	var display: Vector2 = size if size.x > 100.0 and size.y > 100.0 else get_viewport_rect().size
	# Horizontal and vertical layout fill the whole SubViewport independently.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(display.x / 1280.0, display.y / 720.0))
	_panel(Rect2(20, 123, 1240, 469), Color("0b2137"), Color("52dafa"), 27, 3)
	# Factory / rails run above the container as well as the objects.
	_draw_v2_rail()
	_draw_v2_bin()
	_draw_ground_items()
	_draw_magnet()
	_draw_sparks()
	_panel(Rect2(20, 606, 1240, 100), Color("0a1b34"), Color("458cc1"), 23, 2)
	_draw_v2_sliders()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_v2_rail() -> void:
	draw_line(Vector2(144, 214), Vector2(1224, 214), Color(0.01, 0.03, 0.08, 0.56), 16.0)
	_panel(Rect2(145, 201, 1083, 23), Color("365677"), Color("84adcf"), 8, 2)
	draw_line(Vector2(153, 206), Vector2(1216, 206), Color("a6cadf"), 3.0)
	for index in range(22):
		var x := 161.0 + float(index) * 47.0
		draw_line(Vector2(x, 219), Vector2(x + 19, 219), Color("163b5c"), 4.0)
	draw_rect(Rect2(408, 548, 813, 7), Color("294f67"))


func _draw_v2_bin() -> void:
	# The user's OPEN-TOP container, not a painted rectangle or a side-view box.
	draw_texture_rect(BIN_ART, Rect2(91, 381, 271, 137), false, Color.WHITE)
	# Four empty indicator rings directly underneath the container.
	for index in range(4):
		var center := Vector2(147.0 + float(index) * 48.0, 555.0)
		var lit: bool = index < _collected
		if lit:
			draw_circle(center, 18.5, Color(0.22, 1.0, 0.72, 0.13))
		draw_circle(center, 13.0, Color("35e9bd") if lit else Color("102b3f"))
		draw_arc(center, 13.0, 0.0, TAU, 36, Color("d0fff3") if lit else Color("75a9c8"), 2.6, true)
		if lit:
			draw_circle(center, 5.0, Color("e5fff6"))


func _draw_item(kind: String, pos: Vector2, factor: float) -> void:
	var texture: Texture2D = _v2_textures.get(kind) as Texture2D
	if texture == null:
		super._draw_item(kind, pos, factor)
		return
	var raw: Vector2 = texture.get_size()
	var aspect: float = raw.x / maxf(raw.y, 1.0)
	var max_side: float = 56.0 * factor
	var width: float = max_side if aspect >= 1.0 else max_side * aspect
	var height: float = max_side / maxf(aspect, 0.01) if aspect >= 1.0 else max_side
	var dimensions := Vector2(width, height)
	draw_texture_rect(texture, Rect2(pos - dimensions * 0.5, dimensions), false, Color.WHITE)


func _draw_v2_sliders() -> void:
	_draw_v2_track(Rect2(112, 650, 304, 9), Vector2(265 + _left_axis * 145.0, 654.5), true)
	_draw_v2_track(Rect2(1070, 625, 9, 58), Vector2(1074.5, 653 + _right_axis * 26.0), false)


func _draw_v2_track(track: Rect2, knob: Vector2, horizontal: bool) -> void:
	_panel(track, Color("152f4c"), Color("5c92bd"), 6, 1)
	var center := track.get_center()
	draw_line(center, knob, Color("76f4e3"), 5.0, true)
	draw_circle(knob, 25.0, Color(0.04, 0.23, 0.38, 0.85))
	draw_circle(knob, 20.0, Color("6fddf2"))
	draw_arc(knob, 20.0, 0.0, TAU, 36, Color("e2fdff"), 2.3, true)
	draw_circle(knob - Vector2(5, 6), 5.0, Color(1, 1, 1, 0.65))
	if horizontal:
		draw_line(Vector2(81, 654), Vector2(96, 654), Color("b4e5f7"), 3.0, true)
		draw_line(Vector2(435, 654), Vector2(450, 654), Color("b4e5f7"), 3.0, true)
	else:
		draw_line(Vector2(1075, 614), Vector2(1075, 610), Color("b4e5f7"), 3.0, true)
		draw_line(Vector2(1075, 693), Vector2(1075, 700), Color("b4e5f7"), 3.0, true)
