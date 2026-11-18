extends Node
## InfiniteSpace / MIKA — shared system-TTS service.
## Autoload name: MikaVoice. Godot 4.7.1.
## Uses the OS/browser synthesizer; does not send text over game network.

signal speech_started(full_text: String, role: String)
signal speech_completed(full_text: String, role: String)
signal speech_stopped
signal speech_unavailable(locale: String)

const MAX_SEGMENT_CHARS: int = 240

# Distinct gentle timbres; never sacrifice intelligibility.
const ROLE_PRESETS: Dictionary = {
    "tablet": {"pitch": 1.00, "rate": 0.88, "index": 0},
    "human": {"pitch": 1.00, "rate": 0.93, "index": 0},
    "lizard": {"pitch": 0.91, "rate": 0.92, "index": 1},
    "fungal": {"pitch": 1.06, "rate": 0.82, "index": 2},
    "phase": {"pitch": 1.10, "rate": 0.88, "index": 1},
    "magnetic": {"pitch": 0.88, "rate": 0.84, "index": 2},
    "neuron": {"pitch": 1.05, "rate": 0.96, "index": 1},
    "bubl": {"pitch": 1.10, "rate": 0.85, "index": 2},
    "neyri": {"pitch": 1.04, "rate": 0.88, "index": 1},
    "plasma": {"pitch": 1.13, "rate": 0.96, "index": 2},
    "network": {"pitch": 0.97, "rate": 0.89, "index": 1},
    "feron": {"pitch": 1.08, "rate": 0.93, "index": 2},
    "crossroads": {"pitch": 0.95, "rate": 0.79, "index": 0},
}

# These are pronunciation cues for *English letter names*, not phonics.
# Passing a single 'A' to system TTS often reads it as the article /ə/.
const EN_LETTER_NAMES: Dictionary = {
    "A": "ay", "B": "bee", "C": "see", "D": "dee", "E": "ee",
    "F": "eff", "G": "gee", "H": "aitch", "I": "eye", "J": "jay",
    "K": "kay", "L": "ell", "M": "em", "N": "en", "O": "oh",
    "P": "pee", "Q": "cue", "R": "ar", "S": "ess", "T": "tee",
    "U": "you", "V": "vee", "W": "double you", "X": "ex", "Y": "why",
    "Z": "zee",
}
const EN_SPECIAL_KEYS: Dictionary = {
    " ": "space", ".": "period", ",": "comma", "?": "question mark",
    "!": "exclamation mark", "'": "apostrophe", "-": "hyphen",
}

var enabled: bool = true
var pronounce_keys: bool = true
var volume: int = 75
var user_rate_scale: float = 1.0

var _segments: Array[String] = []
var _segment_index: int = 0
var _active_utterance_id: int = -1
var _next_utterance_id: int = 1000
var _reading: bool = false
var _paused: bool = false
var _full_text: String = ""
var _role: String = "tablet"
var _voice_id: String = ""
var _pitch: float = 1.0
var _rate: float = 1.0
var _session_id: int = 0


func _ready() -> void:
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return
    DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, Callable(self, "_on_tts_started"))
    DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, Callable(self, "_on_tts_ended"))
    DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, Callable(self, "_on_tts_canceled"))


func has_voice(locale: String = "en") -> bool:
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return false
    return not _voices_for_locale(locale).is_empty()


## Use for a hint, an NPC bubble, a Crossroads answer, or a whole article.
## speaker_id is an existing stable character ID (e.g. npc_mars_01), not a new lore identity.
func speak_text(full_text: String, locale: String = "en", role: String = "tablet", speaker_id: String = "") -> bool:
    stop()
    if not enabled or full_text.strip_edges().is_empty():
        return false
    var voice: String = _voice_for(locale, role, speaker_id)
    if voice.is_empty():
        speech_unavailable.emit(locale)
        return false
    _segments = _chunk_text(full_text)
    if _segments.is_empty():
        return false
    _segment_index = 0
    _full_text = full_text
    _role = role
    _voice_id = voice
    var preset: Dictionary = ROLE_PRESETS.get(role, ROLE_PRESETS["tablet"])
    _pitch = clampf(float(preset.get("pitch", 1.0)), 0.5, 1.5)
    _rate = clampf(float(preset.get("rate", 0.9)) * user_rate_scale, 0.4, 1.6)
    _reading = true
    _paused = false
    _play_next_segment(_session_id)
    return true


## Call from an individual on-screen key's handler ONLY when the player inserts
## that key; do not connect to TextEdit.text_changed or auto-completion.
func speak_key(key: String, locale: String = "en") -> bool:
    if not enabled or not pronounce_keys:
        return false
    var spoken: String = _key_pronunciation(key, locale)
    if spoken.is_empty():
        return false
    return speak_text(spoken, locale, "tablet")


func pause() -> void:
    if _reading and not _paused:
        _paused = true
        DisplayServer.tts_pause()


func resume() -> void:
    if _reading and _paused:
        _paused = false
        DisplayServer.tts_resume()
        if _active_utterance_id == -1:
            _play_next_segment(_session_id)


func stop() -> void:
    _session_id += 1
    var was_reading: bool = _reading
    _reading = false
    _paused = false
    _segments.clear()
    _segment_index = 0
    _active_utterance_id = -1
    if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        DisplayServer.tts_stop()
    if was_reading:
        speech_stopped.emit()


func is_reading() -> bool:
    return _reading


func is_paused() -> bool:
    return _paused


func _play_next_segment(session_id: int) -> void:
    if session_id != _session_id or not _reading or _paused:
        return
    if _segment_index >= _segments.size():
        var completed: String = _full_text
        var completed_role: String = _role
        _reading = false
        _active_utterance_id = -1
        _segments.clear()
        speech_completed.emit(completed, completed_role)
        return
    _next_utterance_id += 1
    _active_utterance_id = _next_utterance_id
    DisplayServer.tts_speak(_segments[_segment_index], _voice_id, volume, _pitch, _rate, _active_utterance_id, true)


func _on_tts_started(utterance_id: int) -> void:
    if _reading and utterance_id == _active_utterance_id and _segment_index == 0:
        speech_started.emit(_full_text, _role)


func _on_tts_ended(utterance_id: int) -> void:
    if not _reading or utterance_id != _active_utterance_id:
        return
    _segment_index += 1
    _active_utterance_id = -1
    call_deferred("_play_next_segment", _session_id)


func _on_tts_canceled(utterance_id: int) -> void:
    if _reading and utterance_id == _active_utterance_id:
        stop()


func _voice_for(locale: String, role: String, speaker_id: String) -> String:
    var voices: PackedStringArray = _voices_for_locale(locale)
    if voices.is_empty():
        return ""
    var preset: Dictionary = ROLE_PRESETS.get(role, ROLE_PRESETS["tablet"])
    var index: int = int(preset.get("index", 0))
    if not speaker_id.is_empty():
        index += posmod(speaker_id.hash(), voices.size())
    return voices[posmod(index, voices.size())]


func _voices_for_locale(locale: String) -> PackedStringArray:
    var language: String = locale.replace("-", "_").get_slice("_", 0).to_lower()
    var matches: PackedStringArray = PackedStringArray()
    if language.is_empty():
        language = "en"
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return matches
    var all_voices: Array[Dictionary] = DisplayServer.tts_get_voices()
    var target_region: String = locale.replace("-", "_").to_lower()
    # Prefer an exact regional variant when available (especially pt_BR).
    for info in all_voices:
        var info_locale: String = str(info.get("language", "")).replace("-", "_").to_lower()
        if info_locale == target_region and not str(info.get("id", "")).is_empty():
            matches.append(str(info.get("id", "")))
    if not matches.is_empty():
        return matches
    return DisplayServer.tts_get_voices_for_language(language)


func _key_pronunciation(key: String, locale: String) -> String:
    if key.is_empty():
        return ""
    var language: String = locale.replace("-", "_").get_slice("_", 0).to_lower()
    if language == "en":
        if EN_SPECIAL_KEYS.has(key):
            return str(EN_SPECIAL_KEYS[key])
        if key.length() != 1:
            return ""
        var capital: String = key.to_upper()
        if EN_LETTER_NAMES.has(capital):
            if capital == "Z" and (locale.to_lower().contains("gb") or locale.to_lower().contains("uk")):
                return "zed"
            return str(EN_LETTER_NAMES[capital])
        if key >= "0" and key <= "9":
            return key
        return ""
    # Non-English languages: the synth's own alphabet pronunciation is preferable
    # to forcing an English transcription onto Portuguese, French, etc.
    if key.length() != 1:
        return ""
    match language:
        "ru":
            if key == " ": return "пробел"
            if key == "?": return "вопросительный знак"
            return "буква " + key
        "fr":
            if key == " ": return "espace"
            return "lettre " + key
        "de":
            if key == " ": return "Leerzeichen"
            return "Buchstabe " + key
        "es":
            if key == " ": return "espacio"
            return "letra " + key
        "pt":
            if key == " ": return "espaço"
            return "letra " + key
        _:
            return key


func _chunk_text(source: String) -> Array[String]:
    var result: Array[String] = []
    var flat: String = source.replace("\r", " ").replace("\n", " ").replace("\t", " ").strip_edges()
    var current: String = ""
    for word in flat.split(" ", false):
        if word.length() > MAX_SEGMENT_CHARS:
            if not current.is_empty():
                result.append(current)
                current = ""
            var offset: int = 0
            while offset < word.length():
                result.append(word.substr(offset, MAX_SEGMENT_CHARS))
                offset += MAX_SEGMENT_CHARS
            continue
        if current.is_empty():
            current = word
        elif current.length() + word.length() + 1 > MAX_SEGMENT_CHARS:
            result.append(current)
            current = word
        else:
            current += " " + word
    if not current.is_empty():
        result.append(current)
    return result
