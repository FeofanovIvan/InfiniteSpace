extends Control
## Standalone face and jaw preview studio (Godot 4.7.1).

const FACE_SCENE: PackedScene = preload("res://bubble/scenes/bubble_face.tscn")
const PRESETS_PATH := "res://bubble/docs/expression_presets.json"

var face: MikaBubbleFace
var emotion_dropdown: OptionButton
var jaw_slider: HSlider
var gaze_x: HSlider
var gaze_y: HSlider
var status: Label
var _emotions: Array[String] = []

func _ready() -> void:
    get_viewport().set_input_as_handled()
    _build_layout()

func _make_label(parent: Node, value: String, size: int = 18) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color("#eaf4ff"))
    parent.add_child(label)
    return label

func _slider(parent: Node, title: String, initial: float, left: float = -1.0, right: float = 1.0) -> HSlider:
    _make_label(parent,title,17)
    var slider := HSlider.new()
    slider.min_value = left
    slider.max_value = right
    slider.step = 0.01
    slider.value = initial
    slider.custom_minimum_size = Vector2(400, 30)
    parent.add_child(slider)
    return slider

func _build_layout() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#101631")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var heading := _make_label(self, "BUBBLE / FACE STUDIO     •     Godot 4.7.1", 29)
    heading.position = Vector2(40, 25)
    var sub := _make_label(self, "Глаза, улыбки, челюсть, 17 эмоций", 18)
    sub.position = Vector2(42, 70)

    face = FACE_SCENE.instantiate()
    face.name = "BubbleFacePreview"
    face.position = Vector2(420, 415)
    face.scale = Vector2.ONE * 1.0
    add_child(face)

    var right_panel := PanelContainer.new()
    right_panel.position = Vector2(760, 104)
    right_panel.custom_minimum_size = Vector2(494, 650)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#222B50")
    style.border_color = Color("#5669AD")
    style.set_border_width_all(2)
    style.set_corner_radius_all(22)
    style.content_margin_left = 26
    style.content_margin_right = 26
    style.content_margin_top = 24
    style.content_margin_bottom = 24
    right_panel.add_theme_stylebox_override("panel", style)
    add_child(right_panel)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    right_panel.add_child(stack)
    _make_label(stack, "КОНСТРУКТОР ЛИЦА", 23)
    _make_label(stack, "Эмоция", 17)
    emotion_dropdown = OptionButton.new()
    emotion_dropdown.custom_minimum_size = Vector2(400, 40)
    stack.add_child(emotion_dropdown)
    var presets: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESETS_PATH))
    if presets is Dictionary:
        for id in presets.keys():
            _emotions.append(str(id))
            emotion_dropdown.add_item(str(presets[id].get("label",id)))
    emotion_dropdown.item_selected.connect(_on_emotion)
    jaw_slider = _slider(stack,"Открывание челюсти",0.0,0.0,1.0)
    jaw_slider.value_changed.connect(_on_jaw)
    gaze_x = _slider(stack,"Взгляд: влево / вправо",0.0)
    gaze_y = _slider(stack,"Взгляд: вверх / вниз",0.0)
    gaze_x.value_changed.connect(_on_gaze)
    gaze_y.value_changed.connect(_on_gaze)

    var tools := HBoxContainer.new()
    tools.add_theme_constant_override("separation",12)
    stack.add_child(tools)
    var blink_btn := Button.new()
    blink_btn.text = "Моргнуть"
    blink_btn.custom_minimum_size = Vector2(135,44)
    blink_btn.pressed.connect(func(): face.blink())
    tools.add_child(blink_btn)
    var reset := Button.new()
    reset.text = "Сброс"
    reset.custom_minimum_size = Vector2(135,44)
    reset.pressed.connect(_reset)
    tools.add_child(reset)
    var clean_btn := Button.new()
    clean_btn.text = "Перейти к чистке зубов"
    clean_btn.custom_minimum_size = Vector2(395,48)
    clean_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://bubble/scenes/brush_minigame.tscn"))
    stack.add_child(clean_btn)
    status = _make_label(stack,"calm · jaw_open = 0.00",15)
    _make_label(stack,"Это набор слоёв: эмоции без 17 отдельных спрайтов.",15)
    _make_label(stack,"Непрерывное раскрытие челюсти и 10 зубов.",15)

func _on_emotion(index: int) -> void:
    if index >= 0 and index < _emotions.size():
        face.set_expression(_emotions[index])
        _refresh_status()
func _on_jaw(amount: float) -> void:
    face.set_jaw_open(amount)
    _refresh_status()
func _on_gaze(_value: float) -> void:
    face.set_gaze(Vector2(gaze_x.value,gaze_y.value))
func _reset() -> void:
    emotion_dropdown.select(0)
    jaw_slider.value = 0.0
    gaze_x.value = 0.0
    gaze_y.value = 0.0
    face.set_expression("calm")
    face.set_jaw_open(0.0)
    face.set_gaze(Vector2.ZERO)
    _refresh_status()
func _refresh_status() -> void:
    status.text = "%s  •  jaw_open = %.2f" % [face.current_expression,face.jaw_open]
