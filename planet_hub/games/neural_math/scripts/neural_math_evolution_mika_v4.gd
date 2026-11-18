extends "res://planet_hub/games/neural_math/scripts/neural_math_evolution_mika_v3.gd"
## MIKA Neural Math v4: real flight sky ONLY inside safe rounded stage,
## native TTS instruction with bundled English audio fallback, quiet SFX.
## No change to generated problems, modes, scoring, cards or answer logic.

const AUDIO_DIR := "res://planet_hub/games/neural_math/audio_v4/"
const INSTRUCTIONS := {
	"en": "Place the card in the empty space.",
	"ru": "Помести карточку в пустую ячейку.",
	"pt": "Coloque a carta no espaço vazio.",
	"es": "Coloca la tarjeta en el espacio vacío.",
	"de": "Lege die Karte in das leere Feld.",
	"fr": "Place la carte dans la case vide."
}

var _v4_outer: ColorRect
var _v4_sfx: AudioStreamPlayer
var _v4_voice: AudioStreamPlayer
var _v4_sounds: Dictionary = {}
var _v4_spoken: bool = false


func _ready() -> void:
	super._ready()
	# The root is a full-screen Control; fill ONLY the outside with native void.
	# _sky is inherited from v3 and is repositioned to the board in _layout.
	_v4_outer = ColorRect.new()
	_v4_outer.name = "NeuralMathOuterVoidNotSpace"
	_v4_outer.color = INK
	_v4_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_v4_outer.z_index = -30
	add_child(_v4_outer)
	_v4_outer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_v4_sfx = AudioStreamPlayer.new()
	_v4_sfx.name = "NeuralMathInteractionSounds"
	_v4_sfx.volume_db = -11.0
	_v4_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_v4_sfx)
	_v4_voice = AudioStreamPlayer.new()
	_v4_voice.name = "NeuralMathInstructionVoiceFallback"
	_v4_voice.volume_db = -3.0
	_v4_voice.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_v4_voice)
	for key in ["select", "correct", "wrong", "next"]:
		_v4_sounds[key] = load(AUDIO_DIR + key + ".wav") as AudioStream
	_v4_voice.stream = load(AUDIO_DIR + "place_card_en.wav") as AudioStream
	_layout()
	# Run after scene instantiation; never activate TTS during headless smoke.
	call_deferred("_v4_speak_instruction")


func _layout() -> void:
	# Temporarily hide the inherited sky reference from v3's full-screen
	# assignment. It must be resized ONCE, only to the actual stage rectangle.
	var actual_sky: Control = _sky
	_sky = null
	super._layout()
	_sky = actual_sky
	if _v4_outer != null:
		_v4_outer.position = Vector2.ZERO
		_v4_outer.size = _view
	if _sky != null:
		_sky.position = _stage.position
		_sky.size = _stage.size
		_sky.clip_contents = true
		_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sky.z_index = -20
	queue_redraw()


func _v4_play(key: String) -> void:
	if _v4_sfx == null or DisplayServer.get_name() == "headless":
		return
	var effect: AudioStream = _v4_sounds.get(key) as AudioStream
	if effect == null:
		return
	_v4_sfx.stop()
	_v4_sfx.stream = effect
	_v4_sfx.play()


func _v4_speak_instruction() -> void:
	if not is_inside_tree() or DisplayServer.get_name() == "headless":
		return
	var language: String = _locale if INSTRUCTIONS.has(_locale) else "en"
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(language)
	if not voices.is_empty():
		_v4_voice.stop()
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(str(INSTRUCTIONS[language]), voices[0], 75, 0.93, 1.0, 0, true)
	else:
		# Guaranteed offline fallback, no network and no audio dependencies.
		if _v4_voice != null and _v4_voice.stream != null:
			_v4_voice.stop()
			_v4_voice.play()
	_v4_spoken = true


func _language_changed(value: String) -> void:
	super._language_changed(value)
	call_deferred("_v4_speak_instruction")


func _choose_mode(mode: int) -> void:
	var old_mode: int = _mode
	super._choose_mode(mode)
	if mode >= 0 and mode <= 2 and old_mode != mode:
		call_deferred("_v4_speak_instruction")


func _new_round() -> void:
	super._new_round()
	if _v4_sfx != null:
		_v4_play("next")


func _handle_press(pointer: int, point: Vector2) -> void:
	var before_selected: int = _selected
	super._handle_press(pointer, point)
	if _selected >= 0 and _selected != before_selected and _active_pointer == pointer:
		_v4_play("select")


func _try_answer(index: int) -> void:
	var was_locked: bool = _correct_lock
	if was_locked or index < 0 or index >= _options.size():
		return
	var correct: bool = _options[index] == _correct_answer
	super._try_answer(index)
	if not was_locked:
		_v4_play("correct" if correct else "wrong")


func _exit_tree() -> void:
	if DisplayServer.get_name() != "headless" and _v4_spoken:
		DisplayServer.tts_stop()
	super._exit_tree()


func _v4_corner_mask(corner: Vector2, circle_center: Vector2, start_angle: float, end_angle: float, radius: float) -> void:
	# Parent is drawn over the z=-20 sky. Opaque quarter-corner wedges
	# remove its rectangular pixels outside the same rounded stage outline.
	var pts := PackedVector2Array([corner])
	for i in range(21):
		var theta: float = lerpf(start_angle, end_angle, float(i) / 20.0)
		pts.append(circle_center + Vector2.from_angle(theta) * radius)
	draw_colored_polygon(pts, INK)


func _draw() -> void:
	if _stage.size.x > 58.0 and _stage.size.y > 58.0:
		var x: float = _stage.position.x
		var y: float = _stage.position.y
		var right: float = _stage.end.x
		var bottom: float = _stage.end.y
		var radius: float = minf(26.0, minf(_stage.size.x, _stage.size.y) * 0.18)
		_v4_corner_mask(Vector2(x,y), Vector2(x+radius,y+radius), -PI, -PI * 0.5, radius)
		_v4_corner_mask(Vector2(right,y), Vector2(right-radius,y+radius), -PI * 0.5, 0.0, radius)
		_v4_corner_mask(Vector2(right,bottom), Vector2(right-radius,bottom-radius), 0.0, PI * 0.5, radius)
		_v4_corner_mask(Vector2(x,bottom), Vector2(x+radius,bottom-radius), PI * 0.5, PI, radius)
	# v3 draws the border, numbers, fractions and five cards as before.
	super._draw()
