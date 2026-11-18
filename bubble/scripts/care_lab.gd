extends Control
## F6 preview for 4 new care animations.
@onready var bubble: MikaBubbleCare = $Bubble
@onready var background: Node2D = $Background
var index: int = 0
const KEYS: Array[String] = ["eat","drink","brush_teeth","bath"]
const TITLES: Array[String] = ["Еда из миски","Питьё из миски","Чистка зубов","Купание в ванне"]
var auto_mode: bool = true
var _cooldown: float = 0.0
func _ready() -> void:
    get_viewport().size_changed.connect(_layout)
    _layout()
    var panel := VBoxContainer.new()
    panel.position = Vector2(22,24)
    panel.add_theme_constant_override("separation",12)
    add_child(panel)
    var label := Label.new()
    label.text = "БАББЛ  /  УХОД (4 ДЕЙСТВИЯ)"
    label.add_theme_font_size_override("font_size",23)
    panel.add_child(label)
    for i in range(4):
        var b := Button.new()
        b.text = TITLES[i]
        b.custom_minimum_size = Vector2(220,48)
        b.pressed.connect(_select.bind(i))
        panel.add_child(b)
    var auto := CheckButton.new()
    auto.text = "Автоматически"
    auto.button_pressed = true
    auto.toggled.connect(func(value: bool) -> void: auto_mode = value)
    panel.add_child(auto)
    var initial: int = KEYS.find(bubble.initial_action)
    _select(maxi(initial, 0))
func _layout() -> void:
    var size: Vector2 = get_viewport_rect().size
    bubble.position = Vector2(size.x*0.64, size.y*0.49)
    bubble.scale = Vector2.ONE * clampf(minf(size.x/1600.0,size.y/900.0)*0.78,0.48,0.83)
    background.queue_redraw()
func _select(i: int) -> void:
    index = i
    _cooldown = 0.0
    bubble.start_care(KEYS[index])
func _process(delta: float) -> void:
    bubble.advance(delta)
    if auto_mode and bubble.has_finished:
        _cooldown += delta
        if _cooldown >= 1.35:
            _select((index+1)%4)
