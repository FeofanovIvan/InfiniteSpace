extends "res://planet_hub/games/neural_math/scripts/neural_math_evolution_mika_v5.gd"
## CH06 only. This script is attached to the native scene instance BEFORE _ready().
## No changes to the free game's scene or original scripts.
signal story_answer_solved
var _ch06_answered: bool = false
var _ch06_emitted: bool = false
var _ch06_hold: float = 0.0

func _candidate() -> Dictionary:
	# Only one-digit addition/subtraction with the RESULT missing.
	var a: int = _rng.randi_range(1, 4)
	var b: int = _rng.randi_range(1, 4)
	var op: String = "+" if _rng.randi_range(0, 1) == 0 else "−"
	if op == "−":
		a = _rng.randi_range(2, 9)
		b = _rng.randi_range(1, a - 1)
	return {"a": a, "b": b, "c": a + b if op == "+" else a - b, "den": 1, "op": op, "missing": 4}

func _choose_mode(mode: int) -> void:
	if mode == 0 and not _ch06_answered:
		super._choose_mode(0)

func _ready() -> void:
	super._ready()
	for i in range(_mode_buttons.size()):
		if i != 0:
			_mode_buttons[i].hide()
			_mode_buttons[i].disabled = true
	if is_instance_valid(_back):
		_back.hide()
		_back.disabled = true
	if is_instance_valid(_restart):
		_restart.hide()
		_restart.disabled = true
	set_process_unhandled_key_input(false)

func _try_answer(index: int) -> void:
	if _ch06_answered or _correct_lock or index < 0 or index >= _options.size():
		return
	var correct: bool = _mode == 0 and _options[index] == _correct_answer
	super._try_answer(index)
	if correct and _correct_lock:
		_ch06_answered = true
		_ch06_hold = 0.0
		for button in _mode_buttons:
			button.disabled = true

func _process(delta: float) -> void:
	if not _ch06_answered:
		super._process(delta)
		return
	# Hold the real solved board and preserve its existing praise/SFX.
	# Passing zero prevents the native auto-next from starting another equation.
	super._process(0.0)
	_ch06_hold += delta
	var speaking: bool = (_v4_voice != null and _v4_voice.playing) or (_m33_action_voice != null and _m33_action_voice.is_playing())
	if not _ch06_emitted and _ch06_hold >= 1.1 and not speaking:
		_ch06_emitted = true
		story_answer_solved.emit()

func _return_to_cards() -> void:
	# The Hub owns the Story-only completion, never the native exit button.
	pass

func _restart_game() -> void:
	# No way to erase the single solved equation mid-feedback.
	if not _ch06_answered:
		super._restart_game()
