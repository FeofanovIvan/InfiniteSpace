extends Control
## v94: an intentionally empty entry screen for approved future activities.
## No awards, learning logic, or fake success messages are implemented here.

const SpaceBG = preload("res://simulator_ui/scripts/real_space_background.gd")

@export var game_id: String = "sim_08"
@export var title_ru: String = "Действия"
@export var title_en: String = "Action Cards"
@export var description_ru: String = "Здесь появится новая учебная игра."
@export var description_en: String = "A new learning game will appear here."

var _sky: Control
var _panel: Panel
var _title: Label
var _description: Label
var _counterpart_back: Control
var _back: Button


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_STOP
    _sky = SpaceBG.new() as Control
    _sky.name = "RealSpaceAsInFlight"
    _sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_sky)
    _panel = Panel.new()
    _panel.name = "UpcomingGameInformation"
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.76, 0.89, 1.0, 0.85)
    style.border_color = Color(0.38, 0.78, 1.0, 0.95)
    style.set_border_width_all(3)
    style.set_corner_radius_all(28)
    style.shadow_color = Color(0.01, 0.1, 0.28, 0.40)
    style.shadow_size = 12
    _panel.add_theme_stylebox_override("panel", style)
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_panel)
    _title = Label.new()
    _title.name = "UpcomingGameTitle"
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title.add_theme_font_size_override("font_size", 35)
    _title.add_theme_color_override("font_color", Color("18335a"))
    _title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _panel.add_child(_title)
    _description = Label.new()
    _description.name = "UpcomingGameDescription"
    _description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _description.add_theme_font_size_override("font_size", 23)
    _description.add_theme_color_override("font_color", Color("305277"))
    _description.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _panel.add_child(_description)
    _back = Button.new()
    _back.name = "PlaceholderBackToSimulator"
    _back.text = "←"
    _back.focus_mode = Control.FOCUS_NONE
    _back.tooltip_text = "Назад в симулятор"
    _back.add_theme_font_size_override("font_size", 35)
    _back.add_theme_color_override("font_color", Color("d3f7ff"))
    var back_style := StyleBoxFlat.new()
    back_style.bg_color = Color("092344")
    back_style.border_color = Color("50ccff")
    back_style.set_corner_radius_all(19)
    back_style.set_border_width_all(3)
    _back.add_theme_stylebox_override("normal", back_style)
    var hover_style: StyleBoxFlat = back_style.duplicate() as StyleBoxFlat
    hover_style.bg_color = Color("184771")
    _back.add_theme_stylebox_override("hover", hover_style)
    _back.add_theme_stylebox_override("pressed", hover_style)
    _back.pressed.connect(_return_to_simulator)
    add_child(_back)
    var locale: String = "ru"
    var language_node: Node = get_node_or_null("/root/MobileLocale")
    if language_node != null:
        locale = str(language_node.get("language"))
    var ru: bool = locale == "ru"
    _title.text = title_ru if ru else title_en
    _description.text = description_ru if ru else description_en
    resized.connect(_layout)
    get_viewport().size_changed.connect(_layout)
    _layout()
    call_deferred("_hide_outer_back")


func _hide_outer_back() -> void:
    # The simulator shell has its own top-left back. Display ONE button only.
    var node := get_tree().root.find_child("ReturnToEducationalCards", true, false) as Control
    if node != null:
        _counterpart_back = node
        _counterpart_back.visible = false


func _exit_tree() -> void:
    if is_instance_valid(_counterpart_back):
        _counterpart_back.visible = true


func _layout() -> void:
    if _sky == null or _panel == null:
        return
    var view: Vector2 = get_viewport_rect().size
    _sky.position = Vector2.ZERO
    _sky.size = view
    var panel_w: float = minf(660.0, view.x * 0.82)
    var panel_h: float = minf(260.0, view.y * 0.50)
    _panel.position = (view - Vector2(panel_w, panel_h)) * 0.5
    _panel.size = Vector2(panel_w, panel_h)
    _title.position = Vector2(24.0, 28.0)
    _title.size = Vector2(panel_w - 48.0, 76.0)
    _description.position = Vector2(35.0, 115.0)
    _description.size = Vector2(panel_w - 70.0, maxf(60.0, panel_h - 140.0))
    _back.position = Vector2(20.0, 20.0)
    _back.size = Vector2(74.0, 62.0)


func _return_to_simulator() -> void:
    var portal: Node = get_node_or_null("/root/PlayTownPortal")
    if portal != null and portal.has_method("handle_scene_transition"):
        portal.call("handle_scene_transition", "res://education/playtown/scenes/screens/game_select_playground.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _return_to_simulator()
        get_viewport().set_input_as_handled()
