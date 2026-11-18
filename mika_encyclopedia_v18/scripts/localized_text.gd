extends RefCounted
## Encyclopedia v1.8 / InfiniteSpace language adapter. The app is the locale authority.
const FILE: String = "res://mika_encyclopedia_v18/data/ui_localizations.json"
const LOCALES: Array = ["ru", "en", "fr", "de", "es", "pt_BR"]
const SHORT_NAMES: Array = ["RU", "EN", "FR", "DE", "ES", "PT-BR"]
static var _language: String = "ru"
static var _loaded: bool = false
static var _dictionary: Dictionary = {}

static func _mobile_locale() -> Node:
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("MobileLocale")

static func load_saved() -> void:
    if _loaded:
        return
    _loaded = true
    if FileAccess.file_exists(FILE):
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
        if parsed is Dictionary:
            var translations: Variant = (parsed as Dictionary).get("translations", {})
            if translations is Dictionary:
                _dictionary = translations

static func current_language() -> String:
    load_saved()
    var mobile: Node = _mobile_locale()
    if mobile != null:
        var code: String = str(mobile.get("language"))
        if LOCALES.has(code):
            return code
    return _language

static func language_index() -> int:
    return maxi(0, LOCALES.find(current_language()))

static func set_language(code: String) -> void:
    load_saved()
    if not LOCALES.has(code):
        return
    _language = code
    var mobile: Node = _mobile_locale()
    if mobile != null and mobile.has_method("set_language") and str(mobile.get("language")) != code:
        mobile.call("set_language", code)

static func text(key: String) -> String:
    load_saved()
    var code: String = current_language()
    var localized: Dictionary = _dictionary.get(code, {})
    var russian: Dictionary = _dictionary.get("ru", {})
    return str(localized.get(key, russian.get(key, key)))
