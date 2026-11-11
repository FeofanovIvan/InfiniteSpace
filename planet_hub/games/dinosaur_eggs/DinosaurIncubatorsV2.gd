extends Control
## MIKA Dinosaur Eggs — six-laboratory-incubator first playable prototype.
## Each incubator starts with 3 mixed eggs, capacity 4. Sort by shell colour.
## This replaces only the scene's script; original DinosaurEggs.gd is retained.

const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const BOARD: Script = preload("res://planet_hub/games/dinosaur_eggs/DinosaurIncubatorsBoardV2.gd")
const LAB_WALL_V22: Texture2D = preload("res://planet_hub/games/dinosaur_eggs/assets/lab_metal_background_v22.png")

const WORDS: Dictionary = {
    "ru": {"title":"ЯЙЦА ДИНОЗАВРОВ", "sub":"Переложи яйца в инкубаторы нужного цвета"},
    "en": {"title":"DINOSAUR EGGS", "sub":"Move each egg to its colour incubator"},
    "pt": {"title":"OVOS DE DINOSSAURO", "sub":"Coloque cada ovo na incubadora de sua cor"},
    "es": {"title":"HUEVOS DE DINOSAURIO", "sub":"Coloca cada huevo en su incubadora de color"},
    "fr": {"title":"ŒUFS DE DINOSAURE", "sub":"Range les œufs dans l’incubateur de leur couleur"},
    "de": {"title":"DINOSAURIEREIER", "sub":"Lege jedes Ei in den Inkubator seiner Farbe"}
}

var _title_panel: Panel
var _title: Label
var _subtitle: Label
var _back: Button
var _crystals: Control
var _stage: Panel
var _lab_background: ColorRect
var _board: Control
var _host_back: Control
var _locale: String = "en"


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    _stage = Panel.new()
    _stage.name = "SixIncubatorLaboratoryStage"
    _stage.clip_contents = true
    _stage.mouse_filter = Control.MOUSE_FILTER_PASS
    _stage.add_theme_stylebox_override("panel", KIT.stage_style())
    add_child(_stage)

    _lab_background = ColorRect.new()
    _lab_background.name = "DinoLaboratoryRoundedCoverBackgroundV22"
    _lab_background.color = Color.WHITE
    _lab_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _stage.add_child(_lab_background)
    var shader: Shader = Shader.new()
    shader.code = """
shader_type canvas_item;
uniform sampler2D background_tex : source_color, filter_linear;
uniform vec2 background_px = vec2(1671.0, 941.0);
uniform vec2 block_px = vec2(1280.0, 720.0);
uniform float corner_px = 30.0;
void fragment() {
    vec2 p = UV * block_px;
    float scale_cover = max(block_px.x / background_px.x, block_px.y / background_px.y);
    vec2 sampled_uv = (p - block_px * 0.5) / (background_px * scale_cover) + vec2(0.5);
    vec4 pixel = texture(background_tex, sampled_uv);
    float corner = min(corner_px, min(block_px.x, block_px.y) * 0.5);
    vec2 q = abs(p - block_px * 0.5) - (block_px * 0.5 - vec2(corner));
    float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner;
    pixel.a *= 1.0 - smoothstep(-1.3, 0.9, d);
    COLOR = pixel;
}
"""
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("background_tex", LAB_WALL_V22)
    material.set_shader_parameter("background_px", LAB_WALL_V22.get_size())
    _lab_background.material = material

    _board = BOARD.new() as Control
    _board.name = "SixIncubatorsWithExistingMIKAEggArt"
    _board.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _stage.add_child(_board)
    _board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _board.connect("crystals_changed", _on_crystals_changed)

    _title_panel = Panel.new()
    _title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_title_panel)
    add_child(_title_panel)
    _title = Label.new()
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _title.clip_text = true
    _title_panel.add_child(_title)
    _subtitle = Label.new()
    _subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _subtitle.clip_text = true
    _title_panel.add_child(_subtitle)

    _back = Button.new()
    _back.name = "DinosaurEggsNativeBack"
    _back.focus_mode = Control.FOCUS_NONE
    _back.add_theme_stylebox_override("normal", KIT.button_style(false))
    _back.add_theme_stylebox_override("hover", KIT.button_style(true))
    _back.add_theme_stylebox_override("pressed", KIT.button_style(true))
    _back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _back.pressed.connect(_exit_to_cards)
    add_child(_back)
    var glyph: Control = GLYPH.new() as Control
    _back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE

    _crystals = HUD.new() as Control
    _crystals.name = "NativeDinosaurEggCrystalCounter"
    _crystals.size = Vector2(1680.0, 158.0)
    add_child(_crystals)
    for node_name in ["SimulatorButton", "LaunchButton"]:
        var action: Control = _crystals.get_node_or_null(node_name) as Control
        if action != null:
            action.hide()
    _crystals.set("crystal_count", 0)
    _read_locale()
    var language: Node = get_node_or_null("/root/MobileLocale")
    if language != null and language.has_signal("language_changed"):
        language.connect("language_changed", _on_locale)
    var service: Node = get_node_or_null("/root/LanguageService")
    if service != null and service.has_signal("language_changed"):
        service.connect("language_changed", _on_locale)
    _translate()
    _find_host_back()
    resized.connect(_relayout)
    get_viewport().size_changed.connect(_relayout)
    _relayout()
    call_deferred("_relayout")


func _read_locale() -> void:
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    var service: Node = get_node_or_null("/root/LanguageService")
    var candidate: String = "en"
    if mobile != null:
        candidate = str(mobile.get("language"))
    elif service != null:
        candidate = str(service.get("interface_locale"))
    candidate = candidate.to_lower().get_slice("_", 0).get_slice("-", 0)
    _locale = candidate if WORDS.has(candidate) else "en"


func _on_locale(_value: String) -> void:
    _read_locale()
    _translate()
    _relayout()


func _translate() -> void:
    var lang: Dictionary = WORDS.get(_locale, WORDS["en"])
    _title.text = str(lang["title"])
    _subtitle.text = str(lang["sub"])
    if _board != null:
        _board.set("locale", _locale)
        _board.queue_redraw()


func _on_crystals_changed(count: int) -> void:
    if _crystals != null:
        _crystals.set("crystal_count", count)


func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view)
    var window: Vector2 = Vector2(DisplayServer.window_get_size())
    var os_safe: Rect2i = DisplayServer.get_display_safe_area()
    if window.x <= 1.0 or window.y <= 1.0 or os_safe.size.x <= 1 or os_safe.size.y <= 1:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(os_safe.position) * (view / window), Vector2(os_safe.size) * (view / window))


func _relayout() -> void:
    if _stage == null or _back == null or size.x < 280.0 or size.y < 175.0:
        return
    var safe: Rect2 = _safe_area(size)
    var bottom_of_header: float = TOOLBAR.relayout(size, safe, _back, _crystals, _title_panel, _title, _subtitle)
    var margin: float = clampf(safe.size.x * 0.012, 6.0, 22.0)
    var stage_top: float = bottom_of_header + clampf(safe.size.y * 0.012, 4.0, 13.0)
    _stage.position = Vector2(safe.position.x + margin, stage_top)
    _stage.size = Vector2(maxf(180.0, safe.size.x - 2.0 * margin), maxf(100.0, safe.end.y - stage_top - margin))
    # Background fills the ENTIRE rounded game block. Shader performs
    # cover-cropping and alpha-clipping along the actual rounded corners.
    var border: float = 3.0
    _lab_background.position = Vector2.ONE * border
    _lab_background.size = _stage.size - Vector2.ONE * (border * 2.0)
    var shader_mat: ShaderMaterial = _lab_background.material as ShaderMaterial
    shader_mat.set_shader_parameter("block_px", _lab_background.size)
    shader_mat.set_shader_parameter("corner_px", clampf(minf(_stage.size.x, _stage.size.y) * 0.052, 18.0, 33.0))
    # Keep only a tiny spacing for neon outer border; leave layout to the board.
    _board.position = Vector2.ONE * 4.0
    _board.size = _stage.size - Vector2.ONE * 8.0
    _board.queue_redraw()


func _find_host_back() -> void:
    var ancestor: Node = get_parent()
    while ancestor != null:
        for identifier in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var existing: Control = ancestor.get_node_or_null(identifier) as Control
            if existing != null:
                _host_back = existing
                _host_back.hide()
                return
        ancestor = ancestor.get_parent()


func _exit_to_cards() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "res://")
        return
    get_tree().change_scene_to_file("res://scenes/main.tscn")


func _exit_tree() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
