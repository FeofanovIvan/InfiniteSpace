extends Control
## MIKA Eco Sorting v5 — endless falling waste, accelerating over time.
## 3 opaque bins; +1 local crystal for correct sorting; no round limit.
## Uses native MIKA toolbar; game panel is the background, not an overlay.

const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const STARS: Script = preload("res://planet_hub/games/eco_sorting/eco_sort_stars_v5.gd")
# Reuse the original Fungal Paths surface: same artwork, same rounded mask.
# The mycelium NETWORK is deliberately not drawn in Eco Sorting.
const FUNGAL_TERRAIN: Texture2D = preload("res://planet_hub/games/fungal_paths/assets/fungal_terrain_v7.png")
const FUNGAL_ROUND_MASK: Shader = preload("res://planet_hub/games/fungal_paths/fungal_round_mask_v8.gdshader")
const ART: String = "res://planet_hub/games/eco_sorting/art_v5/"
const BG_CONFIG: String = "res://planet_hub/games/eco_sorting/eco_sort_shared_background_v5.txt"
const VOICE_BASE: String = "res://planet_hub/games/eco_sorting/voice_v51/"
const BIN_IMAGES: Array[String] = ["bin_recycling.png", "bin_organics.png", "bin_trash.png"]
const BIN_COLORS: Array[Color] = [Color("#167be5"), Color("#18a64a"), Color("#181d27")]

# Bulbs and batteries are deliberately excluded from these THREE bins:
# both belong in a special-collection stream, not ordinary household trash.
# The two PNG resources are preserved in art_v5 for a possible fourth bin.
const OBJECTS: Array[Dictionary] = [
    {"id":"plastic_bottle", "file":"01_plastic_bottle.png", "bin":0},
    {"id":"aluminum_can", "file":"02_crushed_aluminum_can.png", "bin":0},
    {"id":"glass_bottle", "file":"03_glass_bottle.png", "bin":0},
    {"id":"newspapers", "file":"04_newspapers.png", "bin":0},
    {"id":"cardboard", "file":"05_cardboard_box.png", "bin":0},
    {"id":"milk_carton", "file":"06_milk_carton.png", "bin":0},
    {"id":"coffee_cup", "file":"07_paper_coffee_cup.png", "bin":2},
    {"id":"banana_peel", "file":"08_banana_peel.png", "bin":1},
    {"id":"apple_core", "file":"09_apple_core.png", "bin":1},
    {"id":"plastic_bag", "file":"10_plastic_bag.png", "bin":2},
    {"id":"food_can", "file":"11_metal_food_can.png", "bin":0},
    {"id":"takeout_box", "file":"14_takeout_food_container.png", "bin":2},
]

const WORDS: Dictionary = {
    "ru": {"title":"ЭКОСОРТИРОВКА", "sub":"Распределяй падающий мусор по корзинам", "help":"Перетащи предмет в корзину или коснись предмета и корзины", "restart":"↻ Заново", "bin0":"ПЕРЕРАБОТКА", "bin1":"ОРГАНИКА", "bin2":"МУСОР", "wrong":"Другая корзина!", "exit":"Выйти"},
    "en": {"title":"ECO SORTING", "sub":"Sort the falling waste into bins", "help":"Drag an item to a bin, or tap an item and then a bin", "restart":"↻ Restart", "bin0":"RECYCLING", "bin1":"ORGANICS", "bin2":"TRASH", "wrong":"Try another bin!", "exit":"Exit"},
    "pt": {"title":"SEPARAÇÃO ECOLÓGICA", "sub":"Separe os resíduos que caem nas lixeiras", "help":"Arraste um item ou toque no item e depois na lixeira", "restart":"↻ Reiniciar", "bin0":"RECICLÁVEIS", "bin1":"ORGÂNICOS", "bin2":"LIXO COMUM", "wrong":"Tente outra lixeira!", "exit":"Sair"},
    "es": {"title":"CLASIFICACIÓN ECOLÓGICA", "sub":"Separa los residuos que caen", "help":"Arrastra un objeto o toca el objeto y después el contenedor", "restart":"↻ Reiniciar", "bin0":"RECICLAJE", "bin1":"ORGÁNICOS", "bin2":"BASURA", "wrong":"¡Prueba otro contenedor!", "exit":"Salir"},
    "fr": {"title":"TRI ÉCOLOGIQUE", "sub":"Trie les déchets qui tombent", "help":"Glisse un objet ou touche l'objet puis une poubelle", "restart":"↻ Recommencer", "bin0":"RECYCLAGE", "bin1":"ORGANIQUES", "bin2":"DÉCHETS", "wrong":"Essaie une autre poubelle !", "exit":"Quitter"},
    "de": {"title":"MÜLLTRENNUNG", "sub":"Sortiere die herabfallenden Abfälle", "help":"Zieh einen Gegenstand oder tippe auf ihn und dann auf die Tonne", "restart":"↻ Neustart", "bin0":"RECYCLING", "bin1":"BIOABFALL", "bin2":"RESTMÜLL", "wrong":"Andere Tonne wählen!", "exit":"Verlassen"}
}

const SPOKEN: Dictionary = {
    "ru": "Сортируй падающий мусор. Перетаскивай предметы в корзины: синяя — переработка, зелёная — органика, чёрная — остальной мусор.",
    "en": "Sort the falling items into the correct bins. Blue is for recycling, green is for food scraps, and black is for trash.",
    "pt": "Separe os objetos que caem nas lixeiras corretas. Azul para reciclagem, verde para resíduos orgânicos e preta para lixo comum.",
    "es": "Clasifica los objetos que caen en los contenedores correctos. Azul para reciclar, verde para restos orgánicos y negro para basura.",
    "fr": "Trie les objets qui tombent dans les bonnes poubelles. Bleue pour le recyclage, verte pour les déchets organiques et noire pour le reste.",
    "de": "Sortiere die fallenden Gegenstände in die richtigen Tonnen. Blau ist für Recycling, Grün für Bioabfall und Schwarz für Restmüll."
}

const NAMES: Dictionary = {
    "ru":["Пластиковая бутылка","Алюминиевая банка","Стеклянная бутылка","Газеты","Картон","Пакет молока","Одноразовый стакан","Банановая кожура","Огрызок яблока","Пластиковый пакет","Консервная банка","Контейнер от еды"],
    "en":["Plastic bottle","Aluminum can","Glass bottle","Newspapers","Cardboard","Milk carton","Disposable coffee cup","Banana peel","Apple core","Plastic bag","Food can","Takeout food container"],
    "pt":["Garrafa plástica","Lata de alumínio","Garrafa de vidro","Jornais","Papelão","Caixa de leite","Copo descartável","Casca de banana","Miolo de maçã","Sacola plástica","Lata de alimento","Embalagem de comida"],
    "es":["Botella de plástico","Lata de aluminio","Botella de vidrio","Periódicos","Cartón","Cartón de leche","Vaso desechable","Cáscara de plátano","Corazón de manzana","Bolsa de plástico","Lata de conserva","Envase de comida"],
    "fr":["Bouteille plastique","Canette en aluminium","Bouteille en verre","Journaux","Carton","Brique de lait","Gobelet jetable","Peau de banane","Trognon de pomme","Sac plastique","Boîte de conserve","Boîte à emporter"],
    "de":["Plastikflasche","Aludose","Glasflasche","Zeitungen","Pappe","Milchkarton","Einwegbecher","Bananenschale","Apfelrest","Plastiktüte","Konservendose","Essensbehälter"]
}

var _locale: String = "en"
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _elapsed: float = 0.0
var _spawn_time: float = 0.0
var _falling: Array[Dictionary] = []
var _next_object_id: int = 1
var _picked_object_id: int = -1
var _drag_object_id: int = -1
var _drag_pointer: int = -99
var _drag_start: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_origin: Vector2 = Vector2.ZERO
var _drag_moved: bool = false
var _recent_index: int = -1
var _last_stage_size: Vector2 = Vector2.ZERO
var _fall_top: float = 55.0
var _fall_bottom: float = 230.0
var _image_side: float = 83.0
var _field_left: float = 50.0
var _field_right: float = 800.0
var _host_back: Control
var _backdrop: Control
var _bg_texture: TextureRect
var _stage: Panel
var _fungal_stage_bg: TextureRect
var _header: Panel
var _back: Button
var _hud: Control
var _title: Label
var _subtitle: Label
var _hint: Label
var _reset: Button
var _status: Label
var _status_life: float = 0.0
var _bins: Array[Button] = []
var _bin_icons: Array[TextureRect] = []
var _bin_labels: Array[Label] = []
var _sfx: AudioStreamPlayer
var _instruction_player: AudioStreamPlayer
var _crystal_count: int = 0
var _tts_active: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_PASS
    _rng.randomize()
    _build_game()
    _make_audio()
    _read_locale()
    _translate()
    resized.connect(_layout_game)
    get_viewport().size_changed.connect(_layout_game)
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        mobile.connect("language_changed", _on_language_changed)
    _find_host_back()
    _layout_game()
    _restart()
    call_deferred("_layout_game")
    call_deferred("_speak_instruction")

func _build_game() -> void:
    _backdrop = STARS.new() as Control
    _backdrop.name = "EcoSpaceBackground"
    add_child(_backdrop)
    _bg_texture = TextureRect.new()
    _bg_texture.name = "ProjectSharedCosmicBackground"
    _bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _bg_texture.modulate.a = 0.70
    _backdrop.add_child(_bg_texture)
    _load_project_background()

    _stage = Panel.new()
    _stage.name = "EcoSortingAdaptiveMiddleBlock"
    _stage.clip_contents = true
    _stage.mouse_filter = Control.MOUSE_FILTER_PASS
    # The original Fungal Paths terrain is INSIDE the rounded stage.
    # The panel base is opaque and BELOW the artwork, never a blue veil over items.
    var backing: StyleBoxFlat = _style(Color("#10222e"), Color("#49759f"), 24, 2)
    _stage.add_theme_stylebox_override("panel", backing)
    add_child(_stage)
    _fungal_stage_bg = TextureRect.new()
    _fungal_stage_bg.name = "FungalPathsTerrainBackground"
    _fungal_stage_bg.texture = FUNGAL_TERRAIN
    _fungal_stage_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _fungal_stage_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _fungal_stage_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var fungal_mask: ShaderMaterial = ShaderMaterial.new()
    fungal_mask.shader = FUNGAL_ROUND_MASK
    _fungal_stage_bg.material = fungal_mask
    # First child, behind all falling objects and sorting controls.
    _stage.add_child(_fungal_stage_bg)

    _header = Panel.new()
    _header.name = "EcoSortingNativeTitle"
    _header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_header)
    add_child(_header)
    _title = _label(_header, Color("#f6feff"))
    _subtitle = _label(_header, Color("#b7e7ee"))
    _back = _button(self, "EcoSortingBack", _exit_to_cards)
    var glyph: Control = GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _hud = HUD.new() as Control
    _hud.name = "NativeCrystalCounter"
    _hud.size = Vector2(1680.0, 158.0)
    add_child(_hud)
    for key in ["sim_button", "flight_button"]:
        var action: Button = _hud.get(key) as Button
        if action != null:
            action.disabled = true
            action.hide()
    _set_crystal_count(0)
    _hud.show()

    _hint = _label(_stage, Color("#daeffe"))
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _status = _label(_stage, Color("#ffdf9b"))
    _reset = _button(_stage, "EcoSortingRestart", _restart)
    for i in range(3):
        var idx: int = i
        var bin: Button = _button(_stage, "EcoBin" + str(i), func() -> void: _tap_bin(idx))
        var normal: Color = BIN_COLORS[i]
        bin.add_theme_stylebox_override("normal", _style(normal, normal.lightened(0.27), 20, 3))
        bin.add_theme_stylebox_override("hover", _style(normal.lightened(0.10), Color.WHITE, 20, 3))
        bin.add_theme_stylebox_override("pressed", _style(normal.darkened(0.12), Color.WHITE, 20, 3))
        bin.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        _bins.append(bin)
        var art: TextureRect = TextureRect.new()
        art.name = "CategorySymbol"
        art.texture = load(ART + BIN_IMAGES[i]) as Texture2D
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bin.add_child(art)
        _bin_icons.append(art)
        var caption: Label = _label(bin, Color.WHITE)
        caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _bin_labels.append(caption)

func _make_audio() -> void:
    _sfx = AudioStreamPlayer.new()
    _sfx.name = "EcoSortingEffects"
    add_child(_sfx)
    if AudioServer.get_bus_index("SFX") >= 0:
        _sfx.bus = "SFX"
    _instruction_player = AudioStreamPlayer.new()
    _instruction_player.name = "EcoInstructionVoice"
    add_child(_instruction_player)
    if AudioServer.get_bus_index("Voice") >= 0:
        _instruction_player.bus = "Voice"
    elif AudioServer.get_bus_index("SFX") >= 0:
        _instruction_player.bus = "SFX"

func _speak_instruction() -> void:
    if _instruction_player == null or not is_inside_tree():
        return
    _instruction_player.stop()
    if _tts_active:
        DisplayServer.tts_stop()
        _tts_active = false
    # Use the platform's natural voice when its language is available.
    # A packaged audio recording is the fallback for all six locales.
    var language: String = "pt" if _locale == "pt" else _locale
    var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(language)
    if not voices.is_empty():
        DisplayServer.tts_speak(str(SPOKEN.get(_locale, SPOKEN["en"])), voices[0], 80, 1.0, 0.96, 0, true)
        _tts_active = true
        return
    var fallback: String = VOICE_BASE + "instruction_" + _locale + ".ogg"
    var stream: AudioStream = load(fallback) as AudioStream
    if stream != null:
        _instruction_player.stream = stream
        _instruction_player.play()

func _set_crystal_count(value: int) -> void:
    _crystal_count = maxi(0, value)
    if _hud != null:
        _hud.set("crystal_count", _crystal_count)

func _play_sound(path: String) -> void:
    if ResourceLoader.exists(path):
        var loaded: Resource = load(path)
        if loaded is AudioStream:
            _sfx.stream = loaded as AudioStream
            _sfx.play()

func _load_project_background() -> void:
    if not FileAccess.file_exists(BG_CONFIG):
        return
    var address: String = FileAccess.get_file_as_string(BG_CONFIG).strip_edges()
    if address.begins_with("res://") and ResourceLoader.exists(address):
        var resource: Resource = load(address)
        if resource is Texture2D:
            _bg_texture.texture = resource as Texture2D

func _label(parent: Node, color: Color) -> Label:
    var result: Label = Label.new()
    result.mouse_filter = Control.MOUSE_FILTER_IGNORE
    result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result.clip_text = true
    result.add_theme_color_override("font_color", color)
    parent.add_child(result)
    return result

func _button(parent: Node, control_name: String, callback: Callable) -> Button:
    var result: Button = Button.new()
    result.name = control_name
    result.focus_mode = Control.FOCUS_NONE
    result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    result.add_theme_stylebox_override("normal", KIT.button_style(false))
    result.add_theme_stylebox_override("hover", KIT.button_style(true))
    result.add_theme_stylebox_override("pressed", KIT.button_style(true))
    result.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    result.add_theme_color_override("font_color", Color.WHITE)
    result.pressed.connect(callback)
    parent.add_child(result)
    return result

func _style(bg: Color, border: Color, radius: int, stroke: int) -> StyleBoxFlat:
    var result: StyleBoxFlat = StyleBoxFlat.new()
    result.bg_color = bg
    result.border_color = border
    result.set_border_width_all(stroke)
    result.set_corner_radius_all(radius)
    return result

func _read_locale() -> void:
    _locale = "en"
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null:
        _locale = str(mobile.get("language")).to_lower().get_slice("_", 0).get_slice("-", 0)
    elif get_node_or_null("/root/LanguageService") != null:
        var service: Node = get_node_or_null("/root/LanguageService")
        _locale = str(service.get("learning_locale")).to_lower().get_slice("_", 0).get_slice("-", 0)
    if not WORDS.has(_locale):
        _locale = "en"

func _on_language_changed(_new_language: String) -> void:
    _read_locale()
    _translate()
    _layout_game()
    _speak_instruction()

func _tr(key: String) -> String:
    return str((WORDS.get(_locale, WORDS["en"]) as Dictionary).get(key, key))

func _translate() -> void:
    _title.text = _tr("title")
    _subtitle.text = _tr("sub")
    _hint.text = _tr("help")
    _reset.text = _tr("restart")
    _back.tooltip_text = _tr("exit")
    for i in range(3):
        _bin_labels[i].text = _tr("bin" + str(i))
        _bins[i].tooltip_text = _tr("bin" + str(i))
    for record in _falling:
        var index_value: int = int(record["source_index"])
        var sprite: TextureRect = record["view"] as TextureRect
        if sprite != null:
            var item_names: Array = NAMES.get(_locale, NAMES["en"])
            sprite.tooltip_text = str(item_names[index_value])

func _restart() -> void:
    for entry in _falling:
        var obj: TextureRect = entry["view"] as TextureRect
        if obj != null and is_instance_valid(obj):
            obj.queue_free()
    _falling.clear()
    _elapsed = 0.0
    _spawn_time = 0.0
    _next_object_id = 1
    _recent_index = -1
    _picked_object_id = -1
    _drag_object_id = -1
    _drag_pointer = -99
    _drag_moved = false
    _status_life = 0.0
    _status.text = ""
    _set_crystal_count(0)
    _spawn_one()

func _choose_source() -> int:
    var index_value: int = _rng.randi_range(0, OBJECTS.size() - 1)
    for tries in range(5):
        if index_value != _recent_index:
            break
        index_value = _rng.randi_range(0, OBJECTS.size() - 1)
    _recent_index = index_value
    return index_value

func _spawn_one() -> void:
    if _falling.size() >= 7 or _stage.size.x < 200.0:
        return
    var source_index: int = _choose_source()
    var data: Dictionary = OBJECTS[source_index]
    var tex: Texture2D = load(ART + str(data["file"])) as Texture2D
    if tex == null:
        return
    var node: TextureRect = TextureRect.new()
    node.name = "FallingWaste" + str(_next_object_id)
    node.texture = tex
    node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    node.z_index = 5
    _stage.add_child(node)
    var left_edge: float = _field_left
    var right_edge: float = maxf(left_edge, _field_right - _image_side)
    var x: float = _rng.randf_range(left_edge, right_edge)
    # Avoid spawning on top of another very new item.
    for attempt in range(7):
        var clear: bool = true
        for other in _falling:
            if float(other["y"]) < _fall_top + _image_side and absf(float(other["x"]) - x) < _image_side * 0.9:
                clear = false
                break
        if clear:
            break
        x = _rng.randf_range(left_edge, right_edge)
    var y: float = _fall_top - _image_side
    var entry: Dictionary = {"id":_next_object_id, "source_index":source_index, "category":int(data["bin"]), "view":node, "x":x, "y":y}
    _next_object_id += 1
    _falling.append(entry)
    _update_visual(entry)
    var label_names: Array = NAMES.get(_locale, NAMES["en"])
    node.tooltip_text = str(label_names[source_index])

func _update_visual(entry: Dictionary) -> void:
    var sprite: TextureRect = entry["view"] as TextureRect
    if sprite == null or not is_instance_valid(sprite):
        return
    sprite.position = Vector2(float(entry["x"]), float(entry["y"]))
    sprite.size = Vector2(_image_side, _image_side)
    sprite.modulate = Color.WHITE if int(entry["id"]) != _picked_object_id else Color("#d0faff")

func _process(delta: float) -> void:
    if _stage == null or _stage.size.x < 200.0:
        return
    var step: float = minf(delta, 0.065)
    _elapsed += step
    # Increasing difficulty while remaining playable; the game never ends.
    var ramp: float = 1.0 + minf(_elapsed / 85.0, 2.1)
    var distance: float = maxf(160.0, _fall_bottom - _fall_top)
    var velocity: float = distance / 5.8 * ramp
    var spawn_interval: float = maxf(0.68, 2.3 - _elapsed * 0.013)
    _spawn_time += step
    if _spawn_time >= spawn_interval:
        _spawn_time = 0.0
        _spawn_one()
    for n in range(_falling.size() - 1, -1, -1):
        var entry: Dictionary = _falling[n]
        if int(entry["id"]) == _drag_object_id:
            continue
        entry["y"] = float(entry["y"]) + velocity * step
        if float(entry["y"]) >= _fall_bottom - _image_side * 0.25:
            _despawn(n)
        else:
            _falling[n] = entry
            _update_visual(entry)
    if _status_life > 0.0:
        _status_life -= step
        if _status_life <= 0.0:
            _status.text = ""

func _despawn(index_value: int) -> void:
    if index_value < 0 or index_value >= _falling.size():
        return
    var entry: Dictionary = _falling[index_value]
    var id_value: int = int(entry["id"])
    if _picked_object_id == id_value:
        _picked_object_id = -1
    if _drag_object_id == id_value:
        _drag_object_id = -1
        _drag_pointer = -99
    var obj: Control = entry["view"] as Control
    if obj != null and is_instance_valid(obj):
        obj.queue_free()
    _falling.remove_at(index_value)

func _find_index(id_value: int) -> int:
    for i in range(_falling.size()):
        if int(_falling[i]["id"]) == id_value:
            return i
    return -1

func _tap_bin(bin_id: int) -> void:
    if _picked_object_id >= 0:
        _sort_object(_picked_object_id, bin_id)

func _sort_object(id_value: int, bin_id: int) -> void:
    var index_value: int = _find_index(id_value)
    if index_value < 0 or bin_id < 0 or bin_id >= 3:
        return
    if int(_falling[index_value]["category"]) == bin_id:
        _despawn(index_value)
        _set_crystal_count(_crystal_count + 1)
        _play_sound("res://learning/audio/sfx/correct.ogg")
    else:
        _status.text = _tr("wrong")
        _status_life = 0.85
        _play_sound("res://learning/audio/sfx/error.ogg")
        _picked_object_id = -1
        if _drag_object_id == id_value:
            _drag_object_id = -1
            _drag_pointer = -99
        # Wrong answers do not finish the game or award points.

func _object_at(screen_position: Vector2) -> int:
    # Use stage-local coordinate for consistent touch/mouse mapping.
    for n in range(_falling.size() - 1, -1, -1):
        var entry: Dictionary = _falling[n]
        var view: TextureRect = entry["view"] as TextureRect
        if view != null and is_instance_valid(view):
            if view.get_global_rect().grow(6.0).has_point(screen_position):
                return int(entry["id"])
    return -1

func _pointer_down(at: Vector2, pointer: int) -> void:
    if _drag_object_id >= 0:
        return
    var chosen: int = _object_at(at)
    if chosen < 0:
        return
    var idx: int = _find_index(chosen)
    if idx < 0:
        return
    var sprite: TextureRect = _falling[idx]["view"] as TextureRect
    if sprite == null:
        return
    _drag_object_id = chosen
    _picked_object_id = chosen
    _drag_pointer = pointer
    _drag_start = at
    _drag_offset = at - sprite.global_position
    _drag_origin = Vector2(float(_falling[idx]["x"]), float(_falling[idx]["y"]))
    _drag_moved = false
    sprite.z_index = 16
    _update_visual(_falling[idx])

func _pointer_move(at: Vector2, pointer: int) -> void:
    if _drag_object_id < 0 or pointer != _drag_pointer:
        return
    var idx: int = _find_index(_drag_object_id)
    if idx < 0:
        return
    if at.distance_to(_drag_start) >= 9.0:
        _drag_moved = true
    if not _drag_moved:
        return
    var local: Vector2 = at - _stage.global_position - _drag_offset
    var entry: Dictionary = _falling[idx]
    entry["x"] = clampf(local.x, 6.0, maxf(6.0, _stage.size.x - _image_side - 6.0))
    entry["y"] = clampf(local.y, 6.0, maxf(6.0, _stage.size.y - _image_side - 6.0))
    _falling[idx] = entry
    _update_visual(entry)

func _pointer_up(at: Vector2, pointer: int) -> void:
    if _drag_object_id < 0 or pointer != _drag_pointer:
        return
    var released_id: int = _drag_object_id
    _drag_object_id = -1
    _drag_pointer = -99
    var idx: int = _find_index(released_id)
    if idx < 0:
        return
    var sprite: TextureRect = _falling[idx]["view"] as TextureRect
    if sprite != null:
        sprite.z_index = 5
    if _drag_moved:
        for i in range(3):
            if _bins[i].get_global_rect().has_point(at):
                _sort_object(released_id, i)
                break
        # Wrong or abandoned drag: return object to the falling lane.
        idx = _find_index(released_id)
        if idx >= 0:
            var entry: Dictionary = _falling[idx]
            entry["x"] = _drag_origin.x
            entry["y"] = _drag_origin.y
            _falling[idx] = entry
        _picked_object_id = -1
    # A tap keeps the object selected; tapping a bin then sorts it.
    idx = _find_index(released_id)
    if idx >= 0:
        _update_visual(_falling[idx])

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _pointer_down(touch.position, touch.index)
        else:
            _pointer_up(touch.position, touch.index)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        _pointer_move(drag.position, drag.index)
    elif event is InputEventMouseButton:
        var button: InputEventMouseButton = event
        if button.button_index == MOUSE_BUTTON_LEFT:
            if button.pressed:
                _pointer_down(button.position, -1)
            else:
                _pointer_up(button.position, -1)
    elif event is InputEventMouseMotion:
        var movement: InputEventMouseMotion = event
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _pointer_move(movement.position, -1)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _exit_to_cards()
        get_viewport().set_input_as_handled()

func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view)
    var screen_size: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if screen_size.x <= 0.0 or screen_size.y <= 0.0 or safe.size.x < 30:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(safe.position) * (view / screen_size), Vector2(safe.size) * (view / screen_size))

func _layout_game() -> void:
    if _backdrop == null:
        return
    var screen: Vector2 = size
    if screen.x < 210.0 or screen.y < 180.0:
        return
    _backdrop.position = Vector2.ZERO
    _backdrop.size = screen
    _bg_texture.position = Vector2.ZERO
    _bg_texture.size = screen
    var safe: Rect2 = _safe_area(screen)
    var header_end: float = TOOLBAR.relayout(screen, safe, _back, _hud, _header, _title, _subtitle)
    _hud.show()
    var side: float = clampf(safe.size.x * 0.017, 8.0, 27.0)
    var top_gap: float = clampf(safe.size.y * 0.012, 4.0, 12.0)
    var top: float = header_end + top_gap
    _stage.position = Vector2(safe.position.x + side, top)
    _stage.size = Vector2(maxf(195.0, safe.size.x - side * 2.0), maxf(155.0, safe.end.y - top - side))
    _layout_stage()

func _layout_stage() -> void:
    var width: float = _stage.size.x
    var height: float = _stage.size.y
    # Match the Fungal Paths image-cover and rounded clipping on each resize.
    # Inset preserves the native panel outline on every device.
    var inset: float = 2.5
    _fungal_stage_bg.position = Vector2(inset, inset)
    _fungal_stage_bg.size = Vector2(maxf(1.0, width - inset * 2.0), maxf(1.0, height - inset * 2.0))
    var fungal_mask: ShaderMaterial = _fungal_stage_bg.material as ShaderMaterial
    if fungal_mask != null:
        fungal_mask.set_shader_parameter("panel_size", _fungal_stage_bg.size)
        fungal_mask.set_shader_parameter("corner_radius", minf(21.0, _fungal_stage_bg.size.y * 0.15))
    var margin: float = clampf(height * 0.030, 8.0, 22.0)
    var inner_width: float = minf(width - margin * 2.0, 1420.0)
    var left: float = (width - inner_width) * 0.5
    var title_height: float = clampf(height * 0.10, 24.0, 44.0)
    var button_h: float = clampf(height * 0.10, 33.0, 47.0)
    var button_w: float = clampf(inner_width * 0.20, 104.0, 175.0)
    _hint.position = Vector2(left + 8.0, margin)
    _hint.size = Vector2(maxf(45.0, inner_width - button_w - 26.0), title_height)
    _hint.add_theme_font_size_override("font_size", maxi(11, mini(19, roundi(height * 0.038))))
    _reset.position = Vector2(left + inner_width - button_w, margin)
    _reset.size = Vector2(button_w, button_h)
    _reset.add_theme_font_size_override("font_size", maxi(11, mini(20, roundi(height * 0.042))))
    var bin_gap: float = clampf(inner_width * 0.022, 8.0, 24.0)
    var bin_h: float = clampf(height * 0.30, 70.0, 184.0)
    var bin_y: float = height - margin - bin_h
    var bin_w: float = (inner_width - bin_gap * 2.0) / 3.0
    for i in range(3):
        var bin: Button = _bins[i]
        bin.position = Vector2(left + float(i) * (bin_w + bin_gap), bin_y)
        bin.size = Vector2(bin_w, bin_h)
        var icon_side: float = minf(bin_h * 0.66, bin_w * 0.40)
        _bin_icons[i].position = Vector2((bin_w - icon_side) * 0.5, bin_h * 0.04)
        _bin_icons[i].size = Vector2(icon_side, icon_side)
        _bin_labels[i].position = Vector2(6.0, bin_h * 0.70)
        _bin_labels[i].size = Vector2(bin_w - 12.0, bin_h * 0.25)
        _bin_labels[i].add_theme_font_size_override("font_size", maxi(10, mini(24, roundi(minf(bin_w * 0.067, bin_h * 0.16)))))
    _fall_top = margin + maxf(button_h, title_height) + 5.0
    _fall_bottom = maxf(_fall_top + 65.0, bin_y - 5.0)
    _image_side = clampf(minf(inner_width * 0.115, (_fall_bottom - _fall_top) * 0.35), 41.0, 112.0)
    _field_left = left + margin
    _field_right = left + inner_width - margin
    _status.position = Vector2(left + inner_width * 0.30, bin_y - 27.0)
    _status.size = Vector2(inner_width * 0.40, 24.0)
    _status.add_theme_font_size_override("font_size", maxi(11, mini(18, roundi(height * 0.036))))
    # Preserve normalized positions when resized from one landscape aspect to another.
    if _last_stage_size.x > 0.0 and _last_stage_size.y > 0.0:
        var rx: float = width / _last_stage_size.x
        var ry: float = height / _last_stage_size.y
        for index_value in range(_falling.size()):
            var entry: Dictionary = _falling[index_value]
            entry["x"] = float(entry["x"]) * rx
            entry["y"] = float(entry["y"]) * ry
            _falling[index_value] = entry
            _update_visual(entry)
    _last_stage_size = Vector2(width, height)

func _find_host_back() -> void:
    var ancestor: Node = get_parent()
    while ancestor != null:
        for key in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var old_back: Control = ancestor.get_node_or_null(key) as Control
            if old_back != null:
                _host_back = old_back
                _host_back.hide()
                return
        ancestor = ancestor.get_parent()

func _exit_tree() -> void:
    if _tts_active:
        DisplayServer.tts_stop()
        _tts_active = false
    if is_instance_valid(_host_back):
        _host_back.show()

func _exit_to_cards() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "res://")
        return
    var ancestor: Node = get_parent()
    for i in range(16):
        if ancestor == null:
            break
        if ancestor.has_method("_v1051_return_to_cards"):
            ancestor.call("_v1051_return_to_cards")
            return
        if ancestor.has_method("_return_to_cards"):
            ancestor.call("_return_to_cards")
            return
        ancestor = ancestor.get_parent()
    var fallback: String = "res://scenes/main.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)
