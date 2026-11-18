extends RefCounted
## MIKA Pick Up a Number: 60-language-slot native OS TTS fallback.
## Only a temporary alternative to real number_11...number_20.mp3 files.

const DATA_PATH: String = "res://learning/audio/voice/mika_number_tts_11_20.json"

# Godot returns voice name/id/language but does not expose gender metadata.
# Prefer known female voice NAMES when present, otherwise use the device's
# installed voice for that language and a slightly raised pitch.
const FEMALE_VOICE_HINTS: Dictionary = {
    "ru": ["milena", "katya", "irina", "oksana", "anna", "alena", "elena", "marina", "tatyana", "female"],
    "en": ["samantha", "ava", "allison", "victoria", "karen", "moira", "tessa", "fiona", "susan", "zira", "hazel", "serena", "female"],
    "pt": ["luciana", "joana", "heloisa", "helena", "maria", "catarina", "female"],
    "es": ["monica", "mónica", "paulina", "lucia", "lucía", "paloma", "soledad", "maría", "female"],
    "fr": ["amelie", "amélie", "aurelie", "aurélie", "marie", "celine", "céline", "audrey", "hortense", "female"],
    "de": ["anna", "petra", "vicki", "helena", "katja", "sandra", "monika", "female"]
}

var _spoken_text: Dictionary = {}
var _voice_ids: Dictionary = {}
var did_speak: bool = false

func _init() -> void:
    if not FileAccess.file_exists(DATA_PATH):
        push_warning("MIKA TTS: missing number words: " + DATA_PATH)
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    if parsed is Dictionary:
        _spoken_text = (parsed as Dictionary).get("spoken_text", {})

func _lang(locale: String) -> String:
    if locale == "pt_BR" or locale.begins_with("pt"):
        return "pt"
    var code: String = locale.to_lower().substr(0, 2)
    if code in ["ru", "en", "es", "fr", "de"]:
        return code
    return ""

func _voice_for(locale: String) -> String:
    var lang: String = _lang(locale)
    if lang.is_empty():
        return ""
    if _voice_ids.has(lang):
        return str(_voice_ids[lang])
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        _voice_ids[lang] = ""
        return ""
    var allowed: PackedStringArray = DisplayServer.tts_get_voices_for_language(lang)
    if allowed.is_empty():
        _voice_ids[lang] = ""
        push_warning("MIKA TTS: no installed voice for language " + lang)
        return ""
    var chosen: String = allowed[0]
    var hints: Array = FEMALE_VOICE_HINTS.get(lang, [])
    var voices: Array[Dictionary] = DisplayServer.tts_get_voices()
    for hint in hints:
        for voice in voices:
            var voice_id: String = str(voice.get("id", ""))
            var voice_name: String = str(voice.get("name", "")).to_lower()
            if allowed.has(voice_id) and voice_name.contains(str(hint)):
                chosen = voice_id
                _voice_ids[lang] = chosen
                return chosen
    _voice_ids[lang] = chosen
    return chosen

func speak_number(number: int, locale: String) -> bool:
    if number < 11 or number > 20:
        return false
    var lang: String = _lang(locale)
    if not _spoken_text.has(lang):
        return false
    var texts: Array = _spoken_text[lang]
    var index: int = number - 11
    if index < 0 or index >= texts.size():
        return false
    var voice_id: String = _voice_for(lang)
    if voice_id.is_empty():
        return false
    var spoken: String = str(texts[index])
    if spoken.is_empty():
        return false
    # OS-level speech also works while the Godot SceneTree is paused.
    DisplayServer.tts_speak(spoken, voice_id, 75, 1.08, 0.88, 0, true)
    did_speak = true
    return true

func stop() -> void:
    if did_speak and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        DisplayServer.tts_stop()
        did_speak = false
