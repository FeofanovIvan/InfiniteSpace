extends CanvasLayer
## Adapter for the supplied silent motion-comic intro.
## Keeps the old Main.gd interface: begin(), begin_space_sequence(), finish().

signal comic_completed
signal skipped

const MotionComicIntroScene: PackedScene = preload("res://mika_motion_comic/scenes/MotionComicIntro.tscn")

var _root: Control
var _intro: Control
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
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_intro)
	_intro.finished.connect(_on_intro_finished)
	_skip = Button.new()
	_skip.name = "SkipIntro"
	_skip.text = "»"
	_skip.tooltip_text = MobileLocale.t("skip")
	_skip.add_theme_font_size_override("font_size", 36)
	_skip.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.12, 0.23, 0.63)
	style.border_color = Color(0.48, 0.85, 1.0, 0.65)
	style.set_border_width_all(2)
	style.set_corner_radius_all(26)
	_skip.add_theme_stylebox_override("normal", style)
	_skip.add_theme_stylebox_override("hover", style)
	_skip.add_theme_stylebox_override("pressed", style)
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.pressed.connect(_request_skip)
	_root.add_child(_skip)
	get_viewport().size_changed.connect(_layout)
	MobileLocale.language_changed.connect(_update_locale)
	visible = false
	_layout()

func begin() -> void:
	visible = true
	_mode = "comic"
	_intro.visible = true
	_skip.visible = true
	_layout()
	if _intro.has_method("restart"):
		_intro.call("restart")
	elif _intro.has_method("play"):
		_intro.call("play")
	set_process_unhandled_input(true)

func begin_space_sequence() -> void:
	_mode = "space"
	_intro.visible = false
	_skip.visible = true

func finish() -> void:
	_mode = "idle"
	visible = false
	_skip.visible = false
	if _intro.has_method("stop"):
		_intro.call("stop")
	set_process_unhandled_input(false)

func _request_skip() -> void:
	if _mode == "idle":
		return
	finish()
	skipped.emit()

func _on_intro_finished() -> void:
	if _mode != "comic":
		return
	_mode = "space"
	_intro.visible = false
	comic_completed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if _mode != "idle" and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_request_skip()
			get_viewport().set_input_as_handled()

func _update_locale(_locale: String) -> void:
	_skip.tooltip_text = MobileLocale.t("skip")

func _layout() -> void:
	if not is_instance_valid(_root):
		return
	_view_size = get_viewport().get_visible_rect().size
	_root.position = Vector2.ZERO
	_root.size = _view_size
	if is_instance_valid(_intro):
		_intro.position = Vector2.ZERO
		_intro.size = _view_size
	_skip.size = Vector2(55.0, 52.0)
	var safe: Rect2 = MobileLocale.safe_rect(_view_size)
	_skip.position = Vector2(safe.end.x - _skip.size.x - 6.0, safe.position.y + 6.0)
