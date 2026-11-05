extends Control
## Open voice_demo.tscn after Autoload installation. Press buttons to test.

var _bridge: Node
var _crossroads: Node
var _status: Label


func _ready() -> void:
    _bridge = load("res://addons/mika_voice/MikaDialogVoiceBridge.gd").new()
    _crossroads = load("res://addons/mika_voice/MikaCrossroadsVoiceBridge.gd").new()
    add_child(_bridge)
    add_child(_crossroads)
    var body: VBoxContainer = VBoxContainer.new()
    body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    body.add_theme_constant_override("separation", 12)
    add_child(body)
    _add_phrase_row(body, "Hello! How are you?", "en", "tablet", _bridge)
    _add_phrase_row(body, "I am from another planet.", "en", "lizard", _bridge)
    _add_phrase_row(body, "Гравитация притягивает предметы друг к другу.", "ru", "crossroads", _crossroads)
    _add_phrase_row(body, "A água pode ser líquida, sólida ou gasosa.", "pt_BR", "crossroads", _crossroads)
    var keys: HBoxContainer = HBoxContainer.new()
    body.add_child(keys)
    for letter in ["A", "B", "C", " ", "?"]:
        var key_button: Button = Button.new()
        key_button.text = "SPACE" if letter == " " else letter
        key_button.custom_minimum_size = Vector2(55, 45)
        keys.add_child(key_button)
        key_button.pressed.connect(_on_key.bind(letter))
    var stop_button: Button = Button.new()
    stop_button.text = "STOP"
    body.add_child(stop_button)
    stop_button.pressed.connect(_on_stop)
    _status = Label.new()
    body.add_child(_status)
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null:
        voice.speech_unavailable.connect(_on_unavailable)
        _status.text = "TTS ready" if bool(voice.call("has_voice", "en")) else "No English system voice installed"
    else:
        _status.text = "Autoload MikaVoice is missing"


func _add_phrase_row(parent: VBoxContainer, phrase: String, locale: String, role: String, bridge: Node) -> void:
    var row: HBoxContainer = HBoxContainer.new()
    parent.add_child(row)
    var caption: Label = Label.new()
    caption.text = phrase
    caption.custom_minimum_size.x = 620
    row.add_child(caption)
    bridge.call("attach_phrase_speaker", row, phrase, locale, role)


func _on_key(key: String) -> void:
    _bridge.call("on_keyboard_character_inserted", key, "en")


func _on_stop() -> void:
    _bridge.call("on_dialog_closed")


func _on_unavailable(locale: String) -> void:
    _status.text = "TTS unavailable for " + locale
