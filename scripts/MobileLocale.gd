extends Node
## Native game locale service; English default, selectable and persisted.
signal language_changed(locale: String)
const SUPPORTED: Array[String] = ["en", "ru", "fr", "de", "es", "pt_BR"]
const SETTINGS_PATH: String = "user://miko_language.cfg"
const UI_PATH: String = "res://locales/strings.json"
const INTRO_PATH: String = "res://mika_motion_comic/translations.json"
var language: String = "en"
var _strings: Dictionary = {}
var _captions: Dictionary = {}

func _ready() -> void:
    _strings = _read_json(UI_PATH)
    _captions = _read_json(INTRO_PATH)
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) == OK:
        set_language(str(config.get_value("localization", "language", "en")), false)
    else:
        # English is the authored default for this project; device locale does not override it.
        set_language("en", false)

func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}

func _normalize(value: String) -> String:
    var lower: String = value.to_lower().replace("-", "_")
    if lower.begins_with("pt"):
        return "pt_BR"
    for code in ["ru", "fr", "de", "es", "en"]:
        if lower.begins_with(code):
            return code
    return "en"

func set_language(value: String, persist: bool = true) -> void:
    var code: String = _normalize(value)
    if not SUPPORTED.has(code):
        code = "en"
    language = code
    TranslationServer.set_locale("pt_BR" if language == "pt_BR" else language)
    if persist:
        var config := ConfigFile.new()
        config.set_value("localization", "language", language)
        config.save(SETTINGS_PATH)
    language_changed.emit(language)

func t(key: String) -> String:
    var values: Dictionary = _strings.get(language, _strings.get("en", {}))
    return str(values.get(key, _strings.get("en", {}).get(key, key)))

func caption_for(cue_id: String) -> Dictionary:
    var values: Dictionary = _captions.get(language, _captions.get("en", {}))
    var answer: Variant = values.get(cue_id, {})
    return answer if answer is Dictionary else {}

func safe_rect(view: Vector2) -> Rect2:
    var margin: float = maxf(10.0, minf(view.x, view.y) * 0.020)
    var left := margin
    var right := margin
    var top := margin
    var bottom := margin
    if OS.get_name() == "Android" or OS.get_name() == "iOS":
        var screen_size: Vector2i = DisplayServer.screen_get_size()
        var safe: Rect2i = DisplayServer.get_display_safe_area()
        if screen_size.x > 0 and screen_size.y > 0 and safe.size.x > 0 and safe.size.y > 0:
            var sx: float = view.x / float(screen_size.x)
            var sy: float = view.y / float(screen_size.y)
            left = maxf(left, float(safe.position.x) * sx)
            top = maxf(top, float(safe.position.y) * sy)
            right = maxf(right, float(screen_size.x - safe.end.x) * sx)
            bottom = maxf(bottom, float(screen_size.y - safe.end.y) * sy)
    return Rect2(Vector2(left, top), Vector2(maxf(100.0, view.x-left-right), maxf(70.0, view.y-top-bottom)))
