extends "res://learning/src/features/tracing/mika_word_trace_toolbar_v2_1.gd"
## Story-only variant of the real Trace Words game. Preserve its curves,
## handwriting input, pointer/touch checks, praise and familiar visual style.

signal story_word_completed(word: String)

const MARS_ICON: String = "res://assets/destinations/mars.png"
const PLANET_WORDS: Dictionary = {
	"ru": "МАРС",
	"en": "MARS",
	"fr": "MARS",
	"de": "MARS",
	"es": "MARTE",
	"pt_BR": "MARTE",
}

var _story_completed: bool = false


func _ready() -> void:
	# The word is a one-time tutorial, not a repeatable source of currency.
	coins_per_word = 0
	crystals_per_unique_word = 0
	super._ready()
	_hide_selection_controls()
	_layout_hud_controls()


func _reload_word_pool() -> void:
	# The inherited drawing engine accepts the same word-object structure.
	# No changed categories in the normal simulator's word game.
	var locale: String = str(MobileLocale.language)
	var planet_word: String = str(PLANET_WORDS.get(locale, PLANET_WORDS["en"]))
	word_objects = [{"text": planet_word, "texture": load(MARS_ICON), "voice": null}]
	word_index = 0


func _hide_selection_controls() -> void:
	for control in [category_bar, category_card, prev_button, next_button, _prev_frame, _next_frame, exit_button]:
		if is_instance_valid(control):
			control.hide()


func _layout_hud_controls() -> void:
	super._layout_hud_controls()
	if main_card == null or letter_root == null or word_icon == null:
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 100.0 or view.y < 100.0:
		return
	var safe: Vector4 = _safe_area_insets(view)
	var gap: float = clampf(view.x * 0.022, 18.0, 36.0)
	var content_left: float = safe.x + gap
	var content_right: float = view.x - safe.z - gap
	main_card.position.x = content_left
	main_card.size.x = maxf(440.0, content_right - content_left)
	var center_x: float = main_card.position.x + main_card.size.x * 0.5
	word_icon.position.x = center_x - word_icon.size.x * 0.5
	_round_panel.position.x = center_x - _round_panel.size.x * 0.5
	var new_trace_width: float = maxf(360.0, main_card.size.x - clampf(main_card.size.x * 0.11, 48.0, 112.0))
	if absf(trace_area_size.x - new_trace_width) > 1.0:
		trace_area_size.x = new_trace_width
		if not strokes.is_empty():
			_load_word(false)
	letter_root.position.x = center_x
	_hide_selection_controls()


func _on_prev_pressed() -> void:
	pass


func _on_next_pressed() -> void:
	pass


func _on_category_selected(_category: String) -> void:
	pass


func _on_exit_pressed() -> void:
	# This stage is designed to be completed, and has no category/exit arrow.
	pass


func _advance_word() -> void:
	# Called by the original complete-word praise animation.
	if _story_completed:
		return
	_story_completed = true
	story_word_completed.emit(_current_word())
