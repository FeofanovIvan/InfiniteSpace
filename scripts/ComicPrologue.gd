extends CanvasLayer
## Adapter for the supplied silent motion-comic intro.
## Keeps the old Main.gd interface: begin(), begin_space_sequence(), finish().

signal comic_completed
signal panels_completed
signal forward_requested
signal skipped

## Single-page experiment. The previous nine-image player remains at
## res://mika_motion_comic/scenes/MotionComicIntro.tscn for instant rollback.
const MotionComicIntroScene: PackedScene = preload("res://mika_motion_comic/scenes/SinglePageComicIntro.tscn")
const StoryPageTwoPanelsScript: Script = preload("res://mika_motion_comic/scripts/story_page_two_panels.gd")
const FORWARD_LABELS: Dictionary = {"ru": "Следующий кадр", "en": "Next scene", "fr": "Scène suivante", "de": "Nächste Szene", "es": "Escena siguiente", "pt_BR": "Próxima cena"}

var _root: Control
var _intro: Control
var _panels: Control
var _skip: Button
var _mode: String = "idle"
var _view_size: Vector2 = Vector2(1280.0, 720.0)

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "MotionComicRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_intro = MotionComicIntroScene.instantiate() as Control
	_intro.name = "SuppliedMotionComicIntro"
	_intro.set("autoplay", false)
	_intro.set("show_lettering", false)
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_intro)
	_intro.finished.connect(_on_intro_finished)
	_panels = StoryPageTwoPanelsScript.new() as Control
	_panels.name = "ChapterOnePageTwoEventPanels"
	_root.add_child(_panels)
	_panels.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panels.sequence_completed.connect(_on_panels_finished)
	_skip = Button.new()
	_skip.name = "StoryForward"
	_skip.text = "▶"
	_skip.tooltip_text = str(FORWARD_LABELS.get(MobileLocale.language, FORWARD_LABELS["en"]))
	_skip.add_theme_font_size_override("font_size", 40)
	_skip.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.14, 0.26, 0.94)
	style.border_color = Color(0.16, 0.87, 1.0, 0.96)
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	_skip.add_theme_stylebox_override("normal", style)
	_skip.add_theme_stylebox_override("hover", style)
	_skip.add_theme_stylebox_override("pressed", style)
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_skip.pressed.connect(_request_forward)
	_root.add_child(_skip)
	get_viewport().size_changed.connect(_layout)
	MobileLocale.language_changed.connect(_update_locale)
	visible = false
	_layout()

func begin() -> void:
	visible = true
	_mode = "comic"
	_intro.visible = true
	_panels.end_sequence()
	_skip.visible = true
	_layout()
	if _intro.has_method("restart"):
		_intro.call("restart")
	elif _intro.has_method("play"):
		_intro.call("play")
	set_process_unhandled_input(true)

func begin_space_sequence() -> void:
	visible = true
	_mode = "space"
	_intro.visible = false
	_panels.end_sequence()
	_skip.visible = true

func show_panels(panel_ids: Array) -> void:
	visible = true
	_mode = "panels"
	_intro.visible = false
	_panels.begin_sequence(panel_ids)
	_skip.visible = true
	_layout()
	set_process_unhandled_input(true)

func finish() -> void:
	_mode = "idle"
	visible = false
	_skip.visible = false
	_panels.end_sequence()
	if _intro.has_method("stop"):
		_intro.call("stop")
	set_process_unhandled_input(false)

func _request_skip() -> void:
	if _mode == "idle":
		return
	finish()
	skipped.emit()

func _request_forward() -> void:
	match _mode:
		"comic":
			if _intro.has_method("stop"):
				_intro.call("stop")
			_on_intro_finished()
		"panels":
			_panels.advance_panel()
		"space":
			forward_requested.emit()

func _on_intro_finished() -> void:
	if _mode != "comic":
		return
	_mode = "space"
	_intro.visible = false
	comic_completed.emit()

func _on_panels_finished() -> void:
	if _mode != "panels":
		return
	_mode = "space"
	panels_completed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if _mode != "idle" and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_request_skip()
			get_viewport().set_input_as_handled()

func _update_locale(_locale: String) -> void:
	_skip.tooltip_text = str(FORWARD_LABELS.get(MobileLocale.language, FORWARD_LABELS["en"]))

func _layout() -> void:
	if not is_instance_valid(_root):
		return
	_view_size = get_viewport().get_visible_rect().size
	var button_side: float = clampf(_view_size.y * 0.105, 64.0, 84.0)
	_skip.size = Vector2(button_side * 1.05, button_side)
	var safe: Rect2 = MobileLocale.safe_rect(_view_size)
	_skip.position = Vector2(safe.end.x - _skip.size.x - 12.0, safe.position.y + 12.0)
