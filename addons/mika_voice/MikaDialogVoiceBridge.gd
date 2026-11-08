extends Node
## Add this node under representative_dialog.tscn's existing UI root, then call
## attach_phrase_speaker() for each dynamically created chat/hint row.
## A speaker press must NOT select the hint, submit text, or change tutor logic.

const SPEAKER_SCRIPT: Script = preload("res://addons/mika_voice/SpeakerButton.gd")


func attach_phrase_speaker(row: Control, text_to_say: String, locale: String = "en", role: String = "tablet", speaker_id: String = "") -> Button:
    if row == null:
        return null
    var button: Button = Button.new()
    button.set_script(SPEAKER_SCRIPT)
    row.add_child(button)
    button.call("configure", text_to_say, locale, role, speaker_id)
    return button


func update_speaker(button: Button, text_to_say: String, locale: String, role: String = "tablet", speaker_id: String = "") -> void:
    if button != null and button.has_method("configure"):
        button.call("configure", text_to_say, locale, role, speaker_id)


func on_keyboard_character_inserted(character: String, locale: String = "en") -> void:
    # Call only from the same handler that actually inserts a typed character.
    # Ignore ctrl/backspace/send and language/layout switching keys.
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null:
        voice.call("speak_key", character, locale)


func on_dialog_closed() -> void:
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null:
        voice.call("stop")
