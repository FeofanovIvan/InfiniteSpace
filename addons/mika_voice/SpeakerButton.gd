extends Button
## Play-only speaker control for each independent phrase or hint.
## Add to the same HBoxContainer as the corresponding text/cloud.

@export_multiline var phrase_text: String = ""
@export var language_code: String = "en"
@export var voice_role: String = "tablet"
@export var speaker_id: String = ""


func _ready() -> void:
    custom_minimum_size = Vector2(46.0, 46.0)
    focus_mode = Control.FOCUS_NONE
    mouse_filter = Control.MOUSE_FILTER_STOP
    text = ""
    tooltip_text = "Play phrase"
    _install_style()
    if not pressed.is_connected(_play_phrase):
        pressed.connect(_play_phrase)


func configure(phrase: String, locale: String = "en", role: String = "tablet", character_id: String = "") -> void:
    phrase_text = phrase
    language_code = locale
    voice_role = role
    speaker_id = character_id


func _play_phrase() -> void:
    var service: Node = get_node_or_null("/root/MikaVoice")
    if service != null and not phrase_text.strip_edges().is_empty():
        service.call("speak_text", phrase_text, language_code, voice_role, speaker_id)


func _install_style() -> void:
    var normal: StyleBoxFlat = StyleBoxFlat.new()
    normal.bg_color = Color(0.05, 0.11, 0.18, 0.80)
    normal.border_color = Color(0.25, 0.73, 0.82, 0.85)
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(12)
    var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(0.08, 0.22, 0.33, 0.95)
    var pressed_style: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
    pressed_style.bg_color = Color(0.12, 0.36, 0.44, 0.98)
    add_theme_stylebox_override("normal", normal)
    add_theme_stylebox_override("hover", hover)
    add_theme_stylebox_override("pressed", pressed_style)
    add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _draw() -> void:
    # Draw a true vector speaker, no font/emoji dependencies or PNG assets.
    var c: Vector2 = size * 0.5
    var accent: Color = Color(0.57, 0.93, 0.97)
    var speaker: PackedVector2Array = PackedVector2Array([
        c + Vector2(-12, -5), c + Vector2(-7, -5),
        c + Vector2(-2, -10), c + Vector2(-2, 10),
        c + Vector2(-7, 5), c + Vector2(-12, 5),
    ])
    draw_colored_polygon(speaker, accent)
    draw_arc(c + Vector2(-1, 0), 11, -0.68, 0.68, 14, accent, 2.0, true)
    draw_arc(c + Vector2(-1, 0), 16, -0.65, 0.65, 14, accent, 1.7, true)
