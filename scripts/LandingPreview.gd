extends Control
## v38: placeholder ONLY. No teleport, landing physics, animation or surface scene.
signal closed

var _background: ColorRect
var _title: Label
var _target: Label
var _empty_note: Label
var _back: Button
var _target_name_en: String = ""


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = false
    _background = ColorRect.new()
    _background.color = Color(0.006, 0.022, 0.048, 0.98)
    _background.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_background)
    _title = Label.new()
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.add_theme_font_size_override("font_size", 30)
    _title.add_theme_color_override("font_color", Color(0.78, 0.94, 1.0))
    _title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_title)
    _target = Label.new()
    _target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _target.add_theme_font_size_override("font_size", 21)
    _target.add_theme_color_override("font_color", Color(0.56, 0.79, 0.95))
    _target.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_target)
    _empty_note = Label.new()
    _empty_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _empty_note.add_theme_font_size_override("font_size", 16)
    _empty_note.add_theme_color_override("font_color", Color(0.54, 0.70, 0.81))
    _empty_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_empty_note)
    _back = Button.new()
    _back.focus_mode = Control.FOCUS_NONE
    _back.custom_minimum_size = Vector2(205, 54)
    _back.pressed.connect(close_preview)
    add_child(_back)
    MobileLocale.language_changed.connect(_on_language_changed)
    _on_language_changed(MobileLocale.language)


func resize_preview(view: Vector2) -> void:
    size = view
    if _background == null:
        return
    _background.position = Vector2.ZERO
    _background.size = view
    var safe: Rect2 = MobileLocale.safe_rect(view)
    var center_x: float = safe.position.x + safe.size.x * 0.5
    var center_y: float = safe.position.y + safe.size.y * 0.46
    var line_width: float = minf(safe.size.x - 24.0, 550.0)
    _title.position = Vector2(center_x - line_width * 0.5, center_y - 90.0)
    _title.size = Vector2(line_width, 48.0)
    _target.position = Vector2(center_x - line_width * 0.5, center_y - 34.0)
    _target.size = Vector2(line_width, 42.0)
    _empty_note.position = Vector2(center_x - line_width * 0.5, center_y + 18.0)
    _empty_note.size = Vector2(line_width, 34.0)
    var button_width: float = minf(205.0, safe.size.x - 30.0)
    _back.position = Vector2(center_x - button_width * 0.5, minf(safe.end.y - 64.0, center_y + 84.0))
    _back.size = Vector2(button_width, 54.0)


func open_preview(planet_name_en: String) -> void:
    _target_name_en = planet_name_en
    _on_language_changed(MobileLocale.language)
    resize_preview(get_viewport_rect().size)
    visible = true


func close_preview() -> void:
    if not visible:
        return
    visible = false
    closed.emit()


func _on_language_changed(_code: String) -> void:
    if _title == null:
        return
    _title.text = MobileLocale.t("landing_title")
    _target.text = MobileLocale.t("planet_" + _target_name_en) if _target_name_en != "" else ""
    if _target_name_en != "" and _target.text == "planet_" + _target_name_en:
        _target.text = _target_name_en
    _empty_note.text = MobileLocale.t("landing_empty")
    _back.text = MobileLocale.t("back_to_flight")


func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        close_preview()
        get_viewport().set_input_as_handled()
