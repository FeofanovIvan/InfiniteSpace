extends Node
## Optional declarative wiring for fixed encyclopedia labels.
## Add as a child Node, set Button + Label/RichTextLabel paths in Inspector.

@export var source_label: NodePath
@export var speaker_button: NodePath
@export var language_code: String = "en"
@export var voice_role: String = "crossroads"
@export var speaker_id: String = "crossroads_planet"


func _ready() -> void:
    var button: Button = get_node_or_null(speaker_button) as Button
    if button != null and not button.pressed.is_connected(_read_label):
        button.pressed.connect(_read_label)


func _read_label() -> void:
    var label: Node = get_node_or_null(source_label)
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if label == null or voice == null:
        return
    var plain: String = ""
    if label is RichTextLabel:
        plain = (label as RichTextLabel).get_parsed_text()
    elif label is Label:
        plain = (label as Label).text
    elif label is TextEdit:
        plain = (label as TextEdit).text
    if not plain.is_empty():
        voice.call("speak_text", plain, language_code, voice_role, speaker_id)
