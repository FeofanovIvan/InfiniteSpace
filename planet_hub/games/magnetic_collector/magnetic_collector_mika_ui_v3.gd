extends "res://planet_hub/games/magnetic_collector/magnetic_collector_mika_ui_v2.gd"
## MIKA magnetic collector v3: safe-area stage, cockpit axis-lock sticks,
## single board and 4 magnetic + 6 distractor items in EVERY round.
## The tested v2 gameplay and 4/4 delayed reward logic are preserved.

const AXIS_STICK = preload("res://planet_hub/games/magnetic_collector/axis_locked_flight_joystick_v3.gd")
const SFX_FOLDER := "res://planet_hub/games/magnetic_collector/sfx_v3/"
const HELP_LINE := {
	"en": "Find magnetic objects. Lower the magnet and press Activate Magnet.",
	"ru": "Найди магнитные предметы. Опусти магнит и включи его.",
	"pt": "Encontre objetos magnéticos. Abaixe o ímã e ative-o.",
	"es": "Busca objetos magnéticos. Baja el imán y actívalo.",
	"de": "Finde magnetische Gegenstände. Senke den Magneten und aktiviere ihn.",
	"fr": "Trouve les objets magnétiques. Abaisse l'aimant et active-le."
}
const GUIDE_CARRY := {
	"en": "Move the object over the container and press Release Item.",
	"ru": "Перенеси предмет над контейнером и нажми «Отпустить».",
	"pt": "Leve o objeto até o recipiente e pressione Soltar.",
	"es": "Lleva el objeto al contenedor y pulsa Soltar.",
	"de": "Bringe den Gegenstand zum Behälter und drücke Loslassen.",
	"fr": "Amène l'objet au conteneur, puis appuie sur Relâcher."
}

var _v3_safe: Rect2 = Rect2(Vector2(32, 18), Vector2(1216, 684))
var _v3_left_stick: Control
var _v3_right_stick: Control
var _v3_audio: AudioStreamPlayer
var _v3_sounds: Dictionary = {}
var _v3_last_instruction_ms: int = -10000


func _ready() -> void:
	super._ready()
	_v3_create_sticks()
	_v3_create_sounds()
	# Feedback is ordinary text inside the stage, never a standalone bottom bar.
	_feedback.visible = false
	_grab_button.z_index = 16
	_layout_ui()
	_apply_translation()


func _v3_create_sticks() -> void:
	_v3_left_stick = AXIS_STICK.new() as Control
	_v3_left_stick.name = "MikaFlightJoystickHorizontal"
	_v3_left_stick.set("motion_axis", 0)
	_v3_left_stick.z_index = 17
	add_child(_v3_left_stick)
	_v3_left_stick.connect("direction_changed", Callable(self, "_v3_move_x"))
	_v3_right_stick = AXIS_STICK.new() as Control
	_v3_right_stick.name = "MikaFlightJoystickVertical"
	_v3_right_stick.set("motion_axis", 1)
	_v3_right_stick.z_index = 17
	add_child(_v3_right_stick)
	_v3_right_stick.connect("direction_changed", Callable(self, "_v3_move_y"))


func _v3_move_x(axis: Vector2) -> void:
	_left_axis = axis.x


func _v3_move_y(axis: Vector2) -> void:
	_right_axis = axis.y


func _v3_create_sounds() -> void:
	_v3_audio = AudioStreamPlayer.new()
	_v3_audio.volume_db = -9.0
	add_child(_v3_audio)
	for key in ["pickup", "drop", "complete", "reject"]:
		_v3_sounds[key] = load(SFX_FOLDER + key + ".wav") as AudioStream


func _v3_play_sound(key: String) -> void:
	if _v3_audio == null or not _v3_sounds.has(key):
		return
	var sound: AudioStream = _v3_sounds[key] as AudioStream
	if sound != null:
		_v3_audio.stop()
		_v3_audio.stream = sound
		_v3_audio.play()


func _v3_safe_rect(view: Vector2) -> Rect2:
	# Reserve a visible safe margin even inside a fitted SubViewport.
	var left: float = clampf(view.x * 0.036, 16.0, 75.0)
	var right: float = left
	var top: float = clampf(view.y * 0.028, 12.0, 38.0)
	var bottom: float = maxf(top, clampf(view.y * 0.044, 18.0, 60.0))
	# In native mobile windows add the OS cutout / gesture-bar insets,
	# converted from physical display pixels to the embedded viewport size.
	if DisplayServer.get_name() in ["Android", "iOS"]:
		var display_px: Vector2i = DisplayServer.screen_get_size()
		var usable_px: Rect2i = DisplayServer.get_display_safe_area()
		if display_px.x > 0 and display_px.y > 0 and usable_px.size.x > 0:
			left = maxf(left, float(maxi(0, usable_px.position.x)) / float(display_px.x) * view.x)
			right = maxf(right, float(maxi(0, display_px.x - usable_px.end.x)) / float(display_px.x) * view.x)
			top = maxf(top, float(maxi(0, usable_px.position.y)) / float(display_px.y) * view.y)
			bottom = maxf(bottom, float(maxi(0, display_px.y - usable_px.end.y)) / float(display_px.y) * view.y)
	# Never allow extreme OS insets to consume the gameplay region.
	left = minf(left, view.x * 0.16)
	right = minf(right, view.x * 0.16)
	top = minf(top, view.y * 0.12)
	bottom = minf(bottom, view.y * 0.12)
	return Rect2(Vector2(left, top), Vector2(maxf(1.0, view.x - left - right), maxf(1.0, view.y - top - bottom)))


func _layout_ui() -> void:
	super._layout_ui()
	if _v2_title_panel == null or _v2_counter_clip == null:
		return
	var view: Vector2 = size if size.x > 100.0 and size.y > 100.0 else get_viewport_rect().size
	_v3_safe = _v3_safe_rect(view)
	_v2_sx = _v3_safe.size.x / 1280.0
	_v2_sy = _v3_safe.size.y / 720.0
	var unit: float = minf(_v2_sx, _v2_sy)
	var bar_h: float = clampf(83.0 * unit, 42.0, 100.0)
	var margin: float = 19.0 * _v2_sx
	var gap: float = maxf(6.0, 13.0 * unit)
	var top: float = _v3_safe.position.y + 15.0 * _v2_sy
	var counter_w: float = 394.0 / 158.0 * bar_h
	var left_title: float = _v3_safe.position.x + margin + bar_h + gap
	var right_counter: float = _v3_safe.end.x - margin - counter_w
	var title_w: float = maxf(30.0, right_counter - gap - left_title)
	_v2_back.position = Vector2(_v3_safe.position.x + margin, top)
	_v2_back.size = Vector2.ONE * bar_h
	_v2_title_panel.position = Vector2(left_title, top)
	_v2_title_panel.size = Vector2(title_w, bar_h)
	_v2_title.position = Vector2(6.0, bar_h * 0.055)
	_v2_title.size = Vector2(maxf(20.0, title_w - 12.0), bar_h * 0.56)
	_v2_subtitle.position = Vector2(6.0, bar_h * 0.605)
	_v2_subtitle.size = Vector2(maxf(20.0, title_w - 12.0), bar_h * 0.34)
	_v2_subtitle.visible = true
	_v2_counter_clip.position = Vector2(right_counter, top)
	_v2_counter_clip.size = Vector2(counter_w, bar_h)
	_v2_counter.size = Vector2(1680.0, 158.0)
	var hud_scale: float = bar_h / 158.0
	_v2_counter.scale = Vector2.ONE * hud_scale
	_v2_counter.position = Vector2(-643.0 * hud_scale, 0.0)
	_grab_button.position = _v3_safe.position + Vector2(511.0 * _v2_sx, 595.0 * _v2_sy)
	_grab_button.size = Vector2(258.0 * _v2_sx, 76.0 * _v2_sy)
	_grab_button.scale = Vector2.ONE
	_grab_button.add_theme_font_size_override("font_size", maxi(11, roundi(23.0 * unit)))
	_feedback.position = _v3_safe.position + Vector2(386.0 * _v2_sx, 543.0 * _v2_sy)
	_feedback.size = Vector2(508.0 * _v2_sx, 32.0 * _v2_sy)
	_feedback.scale = Vector2.ONE
	_feedback.add_theme_font_size_override("font_size", maxi(10, roundi(17.0 * unit)))
	for stick_spec in [
		{"stick":_v3_left_stick,"center":Vector2(166.0, 623.0)},
		{"stick":_v3_right_stick,"center":Vector2(1112.0, 623.0)}
	]:
		var stick: Control = stick_spec["stick"] as Control
		if stick == null:
			continue
		var center: Vector2 = stick_spec["center"] as Vector2
		stick.scale = Vector2.ONE * minf(unit * 0.82, 1.0)
		stick.position = _v3_safe.position + Vector2(center.x * _v2_sx, center.y * _v2_sy) - 92.0 * stick.scale
	_v2_update_title()
	queue_redraw()


func _v2_update_title() -> void:
	if _v2_title == null:
		return
	var locale: String = _v2_locale()
	_v2_title.text = _t("title")
	_v2_subtitle.text = str(GUIDE_CARRY.get(locale, GUIDE_CARRY["en"])) if _carrying >= 0 else str(HELP_LINE.get(locale, HELP_LINE["en"]))
	if _v2_title_panel == null or _v2_title_panel.size.x <= 10.0:
		return
	var available: float = _v2_title_panel.size.x - 12.0
	var main_base: float = _v2_title_panel.size.y * 0.41
	_v2_title.add_theme_font_size_override("font_size", maxi(11, roundi(minf(main_base, available / (maxf(1.0, _v2_title.text.length() * 0.57))))))
	var smaller_base: float = _v2_title_panel.size.y * 0.235
	_v2_subtitle.add_theme_font_size_override("font_size", maxi(9, roundi(minf(smaller_base, available / maxf(1.0, _v2_subtitle.text.length() * 0.54)))))


func _start_level() -> void:
	# v2 already handles 4/4 rewards; replace only its initial object recipe.
	super._start_level()
	var metals: Array[String] = MAGNET_KINDS.duplicate()
	metals.shuffle()
	var picks: Array[String] = []
	for index in range(4):
		picks.append(metals[index])
	picks.append_array(OTHER_KINDS)
	picks.shuffle()
	_objects.clear()
	var start_x: float = 434.0
	var stride: float = 735.0 / 9.0
	for index in range(10):
		var kind: String = picks[index]
		_objects.append({"kind":kind, "magnetic":MAGNET_KINDS.has(kind),
			"pos":Vector2(start_x + stride * float(index), 490.0 - float(index % 3) * 2.0), "delivered":false})
	if _v3_left_stick != null:
		_v3_left_stick.call("clear_input")
	if _v3_right_stick != null:
		_v3_right_stick.call("clear_input")
	_refresh_ui()


func _refresh_ui() -> void:
	super._refresh_ui()
	if _feedback != null:
		_feedback.visible = _feedback_key != "ready" and not _level_complete


func _grab_item() -> void:
	var before: int = _carrying
	super._grab_item()
	if before < 0 and _carrying >= 0:
		_v3_play_sound("pickup")
	elif _feedback_key == "not_magnetic":
		_v3_play_sound("reject")


func _release_item() -> void:
	var before: int = _collected
	super._release_item()
	if _collected > before:
		_v3_play_sound("complete" if _collected >= 4 else "drop")
	elif _carrying < 0:
		_v3_play_sound("drop")


func _v2_speak(key: String) -> void:
	if key not in ["first", "find"]:
		super._v2_speak(key)
		return
	if not is_inside_tree() or DisplayServer.get_name() == "headless":
		return
	# v2 schedules the first prompt twice during scene startup. Avoid replay.
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _v3_last_instruction_ms < 800:
		return
	_v3_last_instruction_ms = now_ms
	var language: String = _v2_locale()
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(language)
	if voices.is_empty():
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(str(HELP_LINE.get(language, HELP_LINE["en"])), voices[0], 75, 1.0, 0.97, 0, true)


func _input(event: InputEvent) -> void:
	# Exactly one input handler for each touch: the real flight sticks.
	# Do not also run the v2's fullscreen synthetic slider handling.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_toggle_magnet()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_new_game()


func _draw() -> void:
	# The external viewport may extend underneath notches/system navigation;
	# only the safe rect receives the game, while the host owns the backdrop.
	draw_set_transform(_v3_safe.position, 0.0, Vector2(_v3_safe.size.x / 1280.0, _v3_safe.size.y / 720.0))
	_panel(Rect2(19, 121, 1242, 581), Color("091d36"), Color("5ee2fa"), 26, 3)
	# Low contrast stars and a faint nebula stay behind gameplay silhouettes.
	for index in range(45):
		var x: float = 39.0 + fmod(float(index * 131 + 19), 1200.0)
		var y: float = 145.0 + fmod(float(index * 73 + 7), 409.0)
		draw_circle(Vector2(x, y), 0.6 + float(index % 3) * 0.3, Color(0.55, 0.83, 1.0, 0.13))
	for i in range(6):
		draw_circle(Vector2(965, 311), 170.0 - float(i) * 21.0, Color(0.15, 0.28, 0.64, 0.009))
	_draw_v2_rail()
	_draw_v2_bin()
	_draw_ground_items()
	_draw_magnet()
	_draw_sparks()
	# No separate bottom panel, no divider, no v2 slider graphics.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
