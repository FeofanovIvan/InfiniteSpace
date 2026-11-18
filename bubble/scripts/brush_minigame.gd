extends Control
## Interactive teeth cleaning demo. No dependency on Infinity Space autoloads.
## Cursor/touch toothbrush erases real alpha data from ten separate tooth masks.

const FACE_SCENE: PackedScene = preload("res://bubble/scenes/bubble_face.tscn")
const COMPLETE_THRESHOLD: float = 0.92

var face: MikaBubbleFace
var brush: Sprite2D
var active: bool = false
var dragging: bool = false
var last_tip: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var progress_bar: ProgressBar
var description: Label
var status: Label
var stage: String = "opening"
var _complete_once: bool = false

func _ready() -> void:
    _build()
    _begin()

func _label(parent: Node, value: String, font_size: int, color: Color = Color("#e7f3ff")) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    parent.add_child(label)
    return label

func _button(parent: Node, value: String, action: Callable) -> Button:
    var btn := Button.new()
    btn.text = value
    btn.custom_minimum_size = Vector2(260,50)
    btn.pressed.connect(action)
    parent.add_child(btn)
    return btn

func _build() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#10172E")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    # Left decorative stage
    var board := PanelContainer.new()
    board.position = Vector2(35,113)
    board.custom_minimum_size = Vector2(790,665)
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#202C56")
    s.border_color = Color("#6076B5")
    s.set_border_width_all(2)
    s.set_corner_radius_all(22)
    board.add_theme_stylebox_override("panel",s)
    add_child(board)
    var title := _label(self,"BUBBLE / BRUSH LAB",29)
    title.position = Vector2(38,20)
    var subtitle := _label(self,"Плавная челюсть + интерактивная чистка 10 зубов",18,Color("#a7c8fa"))
    subtitle.position = Vector2(39,65)
    face = FACE_SCENE.instantiate()
    face.name = "BubbleFace"
    face.position = Vector2(428,420)
    face.scale = Vector2.ONE * 1.17
    add_child(face)
    face.brushing_progress_changed.connect(_on_progress)
    brush = Sprite2D.new()
    brush.name = "Toothbrush"
    brush.texture = load("res://bubble/assets/toothbrush.png")
    brush.scale = Vector2.ONE * 0.73
    brush.position = Vector2(714,590)
    brush.z_index = 20
    add_child(brush)
    var panel := PanelContainer.new()
    panel.position = Vector2(854,115)
    panel.custom_minimum_size = Vector2(457,660)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#222B50")
    style.border_color = Color("#5669AD")
    style.set_border_width_all(2)
    style.set_corner_radius_all(20)
    style.content_margin_left = 24
    style.content_margin_right = 24
    style.content_margin_top = 26
    style.content_margin_bottom = 26
    panel.add_theme_stylebox_override("panel",style)
    add_child(panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation",18)
    panel.add_child(col)
    _label(col,"ЧИСТИМ ЗУБЫ",25)
    description = _label(col,"Баббл открывает рот…",18)
    _label(col,"Прогресс очистки",18)
    progress_bar = ProgressBar.new()
    progress_bar.max_value = 100.0
    progress_bar.value = 0.0
    progress_bar.show_percentage = true
    progress_bar.custom_minimum_size = Vector2(390,30)
    col.add_child(progress_bar)
    status = _label(col,"0 / 10 зубов • цель 92%",17)
    _label(col,"1. Возьми щётку справа от Баббла.",16)
    _label(col,"2. Води щетинками по налёту.",16)
    _label(col,"3. Очисти верхние и нижние зубы.",16)
    _button(col,"Начать заново",Callable(self,"_begin"))
    _button(col,"Вернуться в комнату Баббла",Callable(self,"_go_playroom"))
    _button(col,"Конструктор эмоций",Callable(self,"_go_face_studio"))
    _label(col,"Мышь и касания поддерживаются.",15,Color("#b3c2ee"))
    _label(col,"Челюсть анимируется непрерывно.",15,Color("#b3c2ee"))
    _label(col,"Только Godot 4.7.1 · без Homebrew",15,Color("#b3c2ee"))

func _begin() -> void:
    active = false
    dragging = false
    _complete_once = false
    stage = "opening"
    face.set_expression("calm")
    face.set_jaw_open(0.0)
    face.reset_plaque()
    brush.position = Vector2(715,590)
    brush.visible = true
    progress_bar.value = 0.0
    description.text = "Баббл открывает рот…"
    status.text = "0% • очисти не менее 92% налёта"
    var tween := create_tween()
    tween.tween_method(Callable(face,"set_jaw_open"),0.0,1.0,0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await tween.finished
    if not is_inside_tree() or stage != "opening":
        return
    stage = "brushing"
    active = true
    description.text = "Перемещай щётку по зубам Баббла"

func _go_playroom() -> void:
    get_tree().change_scene_to_file("res://bubble/scenes/interaction_playroom.tscn")

func _go_face_studio() -> void:
    get_tree().change_scene_to_file("res://bubble/scenes/face_studio.tscn")

func _on_progress(value: float) -> void:
    if not is_instance_valid(progress_bar):
        return
    progress_bar.value = value*100.0
    status.text = "Очищено: %d%% • цель 92%%" % int(round(value*100.0))
    if stage == "brushing" and value >= COMPLETE_THRESHOLD and not _complete_once:
        _complete()

func _complete() -> void:
    active = false
    _complete_once = true
    dragging = false
    stage = "done"
    brush.visible = false
    description.text = "Отлично! Все зубки почти чистые!"
    status.text = "Успех — налёт удалён!"
    var tween := create_tween()
    tween.tween_method(Callable(face,"set_jaw_open"),face.jaw_open,0.0,0.55).set_trans(Tween.TRANS_SINE)
    await tween.finished
    if is_inside_tree() and stage == "done":
        face.set_expression("happy")
        face.blink()

func _input(event: InputEvent) -> void:
    if not active:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _touch_begin(event.position)
        else:
            dragging = false
    elif event is InputEventMouseMotion and dragging:
        _touch_move(event.position)
    elif event is InputEventScreenTouch:
        if event.pressed:
            _touch_begin(event.position)
        else:
            dragging = false
    elif event is InputEventScreenDrag and dragging:
        _touch_move(event.position)

func _touch_begin(pointer: Vector2) -> void:
    var rect := Rect2(brush.position - Vector2(120,40),Vector2(240,80))
    if not rect.has_point(pointer):
        return
    dragging = true
    drag_offset = pointer-brush.position
    last_tip = _brush_tip()
    get_viewport().set_input_as_handled()

func _touch_move(pointer: Vector2) -> void:
    var target: Vector2 = pointer-drag_offset
    var stage_rect := Rect2(Vector2(40,120),Vector2(780,650))
    target.x = clampf(target.x, stage_rect.position.x+40,stage_rect.end.x-10)
    target.y = clampf(target.y, stage_rect.position.y+5,stage_rect.end.y-15)
    brush.position = target
    var new_tip := _brush_tip()
    if new_tip.distance_to(last_tip) >= 2.0:
        var travel: float = new_tip.distance_to(last_tip)
        var steps: int = mini(28, maxi(1, int(ceil(travel/5.0))))
        var prev := last_tip
        for i in range(1,steps+1):
            var pt: Vector2 = last_tip.lerp(new_tip,float(i)/float(steps))
            face.brush_at(pt,12.0)
            prev = pt
            if not active:
                break
        if active:
            face.set_gaze(Vector2(clampf((new_tip.x-face.position.x)/220.0,-0.8,0.8),0.3))
    last_tip = new_tip
    get_viewport().set_input_as_handled()

func _brush_tip() -> Vector2:
    # Bristle zone sits near left edge of illustrated toothbrush.
    return brush.global_position+Vector2(-96,0)
