@tool
extends Control
## Separate interactive translator/tablet. All frames, keyboard keys and
## bubbles are native Godot controls. No background screenshot is embedded.
## Example exercise: press P, R, I, V, E, T -> displayed Cyrillic "Привет".

signal progress_changed(character_count: int)
signal message_sent(phrase: String)

@export var representative_name: String = "Представитель Земли"
@export var representative_role: String = "Учёный Земного Союза"
@export var target_phrase: String = "Привет"
@export var key_sequence: String = "PRIVET"

var _message_scroll: ScrollContainer
var _messages: VBoxContainer
var _name_label: Label
var _role_label: Label
var _input_label: Label
var _status_label: Label
var _send_button: Button
var _reset_button: Button
var _voice_button: Button
var _key_rows: Array = []
var _key_buttons: Dictionary = {}
var _typed_count: int = 0
var _completed: bool = false
var _entered: String = ""

const LAYOUT_ROWS: Array = [
    ["Q","W","E","R","T","Y","U","I","O","P"],
    ["A","S","D","F","G","H","J","K","L"],
    ["Z","X","C","V","B","N","M","⌫"]
]

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    _name_label = _label("RepresentativeName", representative_name, 23, Color("eef9ff"))
    _role_label = _label("RepresentativeRole", representative_role, 16, Color("9ec6e4"))
    _message_scroll = ScrollContainer.new()
    _message_scroll.name = "ChatHistory"
    _message_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _message_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    _message_scroll.clip_contents = true
    add_child(_message_scroll)
    _messages = VBoxContainer.new()
    _messages.name = "Messages"
    _messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _messages.add_theme_constant_override("separation", 12)
    _message_scroll.add_child(_messages)
    _input_label = _label("TypedText", "", 27, Color("062441"))
    _status_label = _label("TypingStatus", "", 15, Color("91cdec"))
    _voice_button = _make_button("VoiceButton", "▶", false)
    _voice_button.tooltip_text = "Озвучивание — следующий этап разработки"
    _voice_button.pressed.connect(_on_voice_pressed)
    for row_values in LAYOUT_ROWS:
        var buttons: Array = []
        for key in row_values:
            var key_button: Button = _make_button("Key_" + key, str(key), true)
            key_button.pressed.connect(_on_key_pressed.bind(str(key)))
            if key == "⌫":
                key_button.tooltip_text = "Удалить последнюю букву"
            else:
                _key_buttons[str(key)] = key_button
            buttons.append(key_button)
        _key_rows.append(buttons)
    _reset_button = _make_button("ResetExercise", "ЗАНОВО", true)
    _reset_button.pressed.connect(reset_exercise)
    _send_button = _make_button("SendMessage", "➤  ОТПРАВИТЬ", true)
    _send_button.pressed.connect(_on_send)
    resized.connect(_relayout)
    reset_exercise()
    _relayout()

func _label(node_name: String, value: String, font_px: int, color_value: Color) -> Label:
    var label: Label = Label.new()
    label.name = node_name
    label.text = value
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_px)
    label.add_theme_color_override("font_color", color_value)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.clip_text = true
    add_child(label)
    return label

func _make_button(node_name: String, value: String, strong: bool) -> Button:
    var button: Button = Button.new()
    button.name = node_name
    button.text = value
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_font_size_override("font_size", 23 if strong else 19)
    button.add_theme_color_override("font_color", Color("f2faff"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    add_child(button)
    return button

func _button_style(button: Button, highlighted: bool = false, variant: String = "key") -> void:
    var base: StyleBoxFlat = StyleBoxFlat.new()
    base.set_corner_radius_all(8)
    base.set_border_width_all(2)
    if variant == "send":
        base.bg_color = Color("0566d6") if not button.disabled else Color("193f61")
        base.border_color = Color("39d6ff") if not button.disabled else Color("396d8b")
    elif variant == "small":
        base.bg_color = Color("0a395f")
        base.border_color = Color("2e83b6")
    elif highlighted:
        base.bg_color = Color("d97918")
        base.border_color = Color("ffe695")
        base.shadow_color = Color(1.0,0.46,0.10,0.78)
        base.shadow_size = 7
    else:
        base.bg_color = Color("0a335f")
        base.border_color = Color("246eaa")
    button.add_theme_stylebox_override("normal",base)
    var hover: StyleBoxFlat = base.duplicate() as StyleBoxFlat
    hover.bg_color = base.bg_color.lightened(0.22)
    button.add_theme_stylebox_override("hover",hover)
    var pressed: StyleBoxFlat = base.duplicate() as StyleBoxFlat
    pressed.bg_color = base.bg_color.darkened(0.22)
    button.add_theme_stylebox_override("pressed",pressed)
    button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
    var disabled_style: StyleBoxFlat = base.duplicate() as StyleBoxFlat
    disabled_style.bg_color = Color("142e4b")
    disabled_style.border_color = Color("284c6f")
    button.add_theme_stylebox_override("disabled",disabled_style)
    button.add_theme_color_override("font_disabled_color",Color("6f94b0"))

func reset_exercise() -> void:
    if _messages == null:
        return
    _entered = ""
    _typed_count = 0
    _completed = false
    for child in _messages.get_children():
        _messages.remove_child(child)
        child.queue_free()
    _add_bubble("Привет!", "Hello!", false)
    _status_label.text = "Ввод с подсказкой · латиница → русский"
    _refresh_entry()

func _add_bubble(message: String, translated: String, sent_by_player: bool) -> void:
    var row: HBoxContainer = HBoxContainer.new()
    row.name = "PlayerMessage" if sent_by_player else "RepresentativeMessage"
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 5)
    var spacer: Control = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if sent_by_player:
        row.add_child(spacer)
    var bubble: PanelContainer = PanelContainer.new()
    bubble.name = "MessageBubble"
    var panel_style: StyleBoxFlat = StyleBoxFlat.new()
    panel_style.bg_color = Color("104e83") if sent_by_player else Color("385a80")
    panel_style.border_color = Color("37baff") if sent_by_player else Color("6b9ac6")
    panel_style.set_border_width_all(1)
    panel_style.set_corner_radius_all(14)
    panel_style.content_margin_left = 18
    panel_style.content_margin_right = 18
    panel_style.content_margin_top = 10
    panel_style.content_margin_bottom = 10
    bubble.add_theme_stylebox_override("panel",panel_style)
    var content: VBoxContainer = VBoxContainer.new()
    content.add_theme_constant_override("separation", 4)
    var original: Label = Label.new()
    original.text = message
    original.add_theme_color_override("font_color",Color.WHITE)
    original.add_theme_font_size_override("font_size",21)
    content.add_child(original)
    var translation: Label = Label.new()
    translation.text = translated
    translation.add_theme_color_override("font_color",Color("b8d7f0"))
    translation.add_theme_font_size_override("font_size",16)
    content.add_child(translation)
    bubble.add_child(content)
    row.add_child(bubble)
    if not sent_by_player:
        row.add_child(spacer)
    _messages.add_child(row)
    _messages.queue_sort()
    if not Engine.is_editor_hint():
        call_deferred("_scroll_to_latest")

func _scroll_to_latest() -> void:
    if is_instance_valid(_message_scroll):
        _message_scroll.scroll_vertical = int(_message_scroll.get_v_scroll_bar().max_value)

func _on_key_pressed(key: String) -> void:
    if key == "⌫":
        _delete_last()
    else:
        _type_letter(key)

func _type_letter(key: String) -> void:
    if _completed or _typed_count >= target_phrase.length():
        return
    var expected: String = key_sequence.substr(_typed_count,1).to_upper()
    if key.to_upper() != expected:
        _status_label.text = "Следующая клавиша: " + expected
        return
    _typed_count += 1
    _entered = target_phrase.substr(0,_typed_count)
    _status_label.text = "Отлично! Продолжай" if _typed_count < target_phrase.length() else "Фраза набрана — можно отправлять!"
    _refresh_entry()

func _delete_last() -> void:
    if _completed or _typed_count == 0:
        return
    _typed_count -= 1
    _entered = target_phrase.substr(0,_typed_count)
    _status_label.text = "Последний символ удалён"
    _refresh_entry()

func _refresh_entry() -> void:
    if _input_label == null:
        return
    _input_label.text = (_entered + "│") if not _completed else "Сообщение отправлено ✓"
    _send_button.disabled = (_typed_count != target_phrase.length()) or _completed
    _button_style(_send_button,false,"send")
    _button_style(_reset_button,false,"small")
    _button_style(_voice_button,false,"small")
    var expected_key: String = ""
    if not _completed and _typed_count < key_sequence.length():
        expected_key = key_sequence.substr(_typed_count,1).to_upper()
    for key in _key_buttons.keys():
        _button_style(_key_buttons[key],str(key)==expected_key)
    for row in _key_rows:
        for key_button in row:
            key_button.disabled = _completed
    progress_changed.emit(_typed_count)

func _on_send() -> void:
    if _completed or _typed_count != target_phrase.length():
        return
    _add_bubble(target_phrase,"Сообщение отправлено",true)
    _add_bubble("Рада знакомству!","Nice to meet you!",false)
    _completed = true
    _status_label.text = "Диалог начат · нажми «Заново» для повторения"
    _refresh_entry()
    message_sent.emit(target_phrase)

func _on_voice_pressed() -> void:
    if Engine.is_editor_hint():
        return
    var dialog: AcceptDialog = AcceptDialog.new()
    dialog.title = "Озвучивание"
    dialog.dialog_text = "Здесь позже будет воспроизведение речи представителя планеты."
    add_child(dialog)
    dialog.confirmed.connect(dialog.queue_free)
    dialog.canceled.connect(dialog.queue_free)
    dialog.popup_centered(Vector2i(430,175))

func _unhandled_key_input(event: InputEvent) -> void:
    if Engine.is_editor_hint() or not visible:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_BACKSPACE:
            _delete_last()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            _on_send()
            get_viewport().set_input_as_handled()
        elif event.unicode > 0:
            var value: String = char(event.unicode).to_upper()
            if value.length() == 1 and "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(value):
                _type_letter(value)
                get_viewport().set_input_as_handled()

func _relayout() -> void:
    if _messages == null:
        return
    var w: float = size.x
    var h: float = size.y
    var s: float = minf(w/800.0,h/730.0)
    var inset: float = 39.0*s
    var inner_width: float = w-2*inset
    _name_label.position = Vector2(inset+64*s,31*s)
    _name_label.size = Vector2(inner_width-160*s,35*s)
    _name_label.add_theme_font_size_override("font_size",maxi(14,int(23*s)))
    _role_label.position = Vector2(inset+64*s,70*s)
    _role_label.size = Vector2(inner_width-170*s,25*s)
    _role_label.add_theme_font_size_override("font_size",maxi(11,int(16*s)))
    _voice_button.position = Vector2(w-93*s,55*s)
    _voice_button.size = Vector2(47*s,43*s)
    _voice_button.add_theme_font_size_override("font_size",maxi(12,int(18*s)))
    var keyboard_top: float = h-257*s
    _message_scroll.position = Vector2(inset,120*s)
    _message_scroll.size = Vector2(inner_width, maxf(60*s,keyboard_top-234*s))
    _messages.custom_minimum_size.x = inner_width-12*s
    _input_label.position = Vector2(inset+19*s, keyboard_top-100*s)
    _input_label.size = Vector2(inner_width-38*s,61*s)
    _input_label.add_theme_font_size_override("font_size",maxi(16,int(27*s)))
    _status_label.position = Vector2(inset+13*s,keyboard_top-39*s)
    _status_label.size = Vector2(inner_width-26*s,31*s)
    _status_label.add_theme_font_size_override("font_size",maxi(10,int(15*s)))
    var key_gap: float = 6*s
    var key_height: float = 47*s
    for ridx in range(_key_rows.size()):
        var row: Array = _key_rows[ridx]
        var count: int = row.size()
        var key_width: float = (inner_width-key_gap*9)/10.0
        var total_width: float = float(count)*key_width + float(count-1)*key_gap
        var start_x: float = inset+(inner_width-total_width)*0.5
        var key_y: float = keyboard_top+(ridx*55)*s
        for idx in range(count):
            var button: Button = row[idx]
            button.position = Vector2(start_x+idx*(key_width+key_gap), key_y)
            button.size = Vector2(key_width,key_height)
            button.add_theme_font_size_override("font_size",maxi(13,int(22*s)))
    var bottom_y: float = keyboard_top+166*s
    _reset_button.position = Vector2(inset,bottom_y)
    _reset_button.size = Vector2(135*s,51*s)
    _reset_button.add_theme_font_size_override("font_size",maxi(11,int(18*s)))
    _send_button.position = Vector2(inset+152*s,bottom_y)
    _send_button.size = Vector2(inner_width-152*s,51*s)
    _send_button.add_theme_font_size_override("font_size",maxi(12,int(19*s)))
    queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 8 or h < 8:
        return
    var s: float = minf(w/800.0,h/730.0)
    var frame: PackedVector2Array = PackedVector2Array([
        Vector2(44*s,5*s),Vector2(w-44*s,5*s),Vector2(w-5*s,43*s),
        Vector2(w-5*s,h-42*s),Vector2(w-43*s,h-5*s),Vector2(44*s,h-5*s),
        Vector2(5*s,h-43*s),Vector2(5*s,44*s)])
    draw_colored_polygon(frame,Color("152338"))
    var outline: PackedVector2Array = frame.duplicate()
    outline.append(frame[0])
    draw_polyline(outline,Color(0.02,0.40,0.92,0.3),12*s,true)
    draw_polyline(outline,Color("579fc8"),3.0*s,true)
    var inner: Rect2 = Rect2(24*s,21*s,w-48*s,h-43*s)
    draw_rect(inner,Color("06152b"))
    draw_rect(inner,Color(0.05,0.62,1.0,0.83),false,2*s)
    # Native monitor, avatar status, input monitor and keyboard recess.
    draw_rect(Rect2(37*s,113*s,w-74*s,h-370*s),Color("06162d"))
    draw_rect(Rect2(37*s,113*s,w-74*s,h-370*s),Color(0.08,0.48,0.8,0.60),false,2*s)
    draw_rect(Rect2(36*s,h-360*s,w-72*s,71*s),Color("d4effb"))
    draw_rect(Rect2(36*s,h-360*s,w-72*s,71*s),Color(0.25,0.79,1,0.89),false,2*s)
    draw_rect(Rect2(34*s,h-265*s,w-68*s,222*s),Color("071b34"))
    draw_line(Vector2(48*s,108*s),Vector2(w-48*s,108*s),Color(0.18,0.66,1.0,0.63),2*s,true)
    draw_line(Vector2(60*s,h-21*s),Vector2(w-60*s,h-21*s),Color(0.18,0.71,1.0,0.72),3*s,true)
    draw_circle(Vector2(75*s,68*s),22*s,Color(0.07,0.39,0.67,0.82))
    draw_arc(Vector2(75*s,68*s),15*s,0,TAU,32,Color("7ad8ff"),2*s,true)
    draw_line(Vector2(60*s,68*s),Vector2(90*s,68*s),Color("7ad8ff"),1.5*s,true)
    draw_line(Vector2(75*s,54*s),Vector2(75*s,83*s),Color("7ad8ff"),1.5*s,true)
