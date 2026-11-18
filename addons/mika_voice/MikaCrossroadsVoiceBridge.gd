extends "res://addons/mika_voice/MikaDialogVoiceBridge.gd"
## Crossroads: living-planet answer bubbles + 48-topic encyclopedia texts.
## Only voiced language changes; never rewrite translated question/answer JSON.


func attach_question_speaker(row: Control, question_text: String, locale: String) -> Button:
    return attach_phrase_speaker(row, question_text, locale, "tablet")


func attach_answer_speaker(row: Control, answer_text: String, locale: String) -> Button:
    return attach_phrase_speaker(row, answer_text, locale, "crossroads", "crossroads_planet")


func read_full_article(article_text: String, locale: String) -> bool:
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice == null:
        return false
    return bool(voice.call("speak_text", article_text, locale, "crossroads", "crossroads_planet"))


func pause_article() -> void:
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null:
        voice.call("pause")


func resume_article() -> void:
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null:
        voice.call("resume")


func stop_article() -> void:
    on_dialog_closed()
