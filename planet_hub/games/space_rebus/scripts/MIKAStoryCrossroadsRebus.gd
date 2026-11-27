extends "res://planet_hub/games/space_rebus/scripts/space_rebus_mika_blocks_v1_3_2.gd"
## Same native game; only the instanced Story challenge uses the special deck.
signal story_crossroads_solved
const CROSSROADS_NAMES: Script = preload("res://scripts/MIKACrossroadsNames.gd")
var _ch06_emitted: bool = false

func _detect_locale() -> void:
	_locale = CROSSROADS_NAMES.locale(str(MobileLocale.language))

func _start_game(reset_score: bool) -> void:
	if _ch06_emitted:
		return
	_puzzles = {_locale: [CROSSROADS_NAMES.puzzle(_locale)]}
	super._start_game(reset_score)

func _ready() -> void:
	super._ready()
	# A mandatory puzzle cannot be skipped through the ordinary game exit.
	if is_instance_valid(_toolbar_back):
		_toolbar_back.disabled = true
		_toolbar_back.hide()

func _on_back_pressed() -> void:
	pass

func _advance_after_success() -> void:
	if not _solved or _ch06_emitted:
		return
	# Parent process calls this only after the native praise and success delay.
	_ch06_emitted = true
	_success_delay = 0.0
	story_crossroads_solved.emit()
