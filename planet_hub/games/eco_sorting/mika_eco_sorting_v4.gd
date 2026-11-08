extends Control
## MIKA Eco Sorting v4 — complete responsive mini-game.
## 3 bins, 15 distinct illustrated items, touch/mouse drag, bin tap,
## +1 local point per correct answer, 6 languages, replay/exit, native MIKA UI.
## No GameState or paid-crystal balance modifications.

const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const ICON: Script = preload("res://planet_hub/games/eco_sorting/eco_sort_icon_v4.gd")
const STARS: Script = preload("res://planet_hub/games/eco_sorting/eco_sort_stars_v4.gd")

const TOTAL: int = 15
const NEW_SCENE: String = "res://planet_hub/games/eco_sorting/MikaEcoSortingV4.tscn"
const BG_PATH_FILE: String = "res://planet_hub/games/eco_sorting/eco_sort_shared_background_v4.txt"
const DATA: Array[Dictionary] = [
    {"id":"plastic_bottle", "bin":0}, {"id":"paper", "bin":0},
    {"id":"glass_jar", "bin":0}, {"id":"aluminum_can", "bin":0},
    {"id":"cardboard", "bin":0}, {"id":"newspaper", "bin":0},
    {"id":"banana_peel", "bin":1}, {"id":"apple_core", "bin":1},
    {"id":"leaf", "bin":1}, {"id":"orange_peel", "bin":1},
    {"id":"coffee_grounds", "bin":1},
    {"id":"chip_bag", "bin":2}, {"id":"broken_cup", "bin":2},
    {"id":"diaper", "bin":2}, {"id":"foam_cup", "bin":2}
]
const WORDS: Dictionary = {
    "ru":{"title":"ЭКОСОРТИРОВКА","sub":"Помоги сохранить планету чистой!","help":"Перетащи предмет в корзину или выбери корзину","bin0":"ПЕРЕРАБОТКА","bin1":"ОРГАНИКА","bin2":"ОСТАЛЬНОЙ МУСОР","score":"Очки","done":"Все отходы рассортированы!","replay":"↻ Повторить","exit":"Выйти","reset":"↻ Заново","correct":"Правильно! +1","wrong":"Попробуй другую корзину","progress":"Предмет","select":"Куда это положить?"},
    "en":{"title":"ECO SORTING","sub":"Help keep the planet clean!","help":"Drag the item into a bin or tap a bin","bin0":"RECYCLING","bin1":"ORGANICS","bin2":"TRASH","score":"Score","done":"All waste sorted!","replay":"↻ Play again","exit":"Exit","reset":"↻ Restart","correct":"Correct! +1","wrong":"Try another bin","progress":"Item","select":"Which bin does it go in?"},
    "pt":{"title":"SEPARAÇÃO ECOLÓGICA","sub":"Ajude a manter o planeta limpo!","help":"Arraste o item para a lixeira ou toque nela","bin0":"RECICLÁVEIS","bin1":"ORGÂNICOS","bin2":"LIXO COMUM","score":"Pontos","done":"Todos os resíduos separados!","replay":"↻ Jogar de novo","exit":"Sair","reset":"↻ Reiniciar","correct":"Muito bem! +1","wrong":"Tente outra lixeira","progress":"Item","select":"Em qual lixeira?"},
    "es":{"title":"CLASIFICACIÓN ECOLÓGICA","sub":"¡Ayuda a mantener limpio el planeta!","help":"Arrastra el objeto o toca el contenedor","bin0":"RECICLAJE","bin1":"ORGÁNICOS","bin2":"BASURA","score":"Puntos","done":"¡Todo está clasificado!","replay":"↻ Repetir","exit":"Salir","reset":"↻ Reiniciar","correct":"¡Correcto! +1","wrong":"Prueba otro contenedor","progress":"Objeto","select":"¿Dónde lo ponemos?"},
    "fr":{"title":"TRI ÉCOLOGIQUE","sub":"Aide à garder la planète propre !","help":"Fais glisser l'objet ou touche une poubelle","bin0":"RECYCLAGE","bin1":"ORGANIQUES","bin2":"DÉCHETS","score":"Points","done":"Tous les déchets sont triés !","replay":"↻ Rejouer","exit":"Quitter","reset":"↻ Recommencer","correct":"Bravo ! +1","wrong":"Essaie une autre poubelle","progress":"Objet","select":"Dans quelle poubelle ?"},
    "de":{"title":"MÜLLTRENNUNG","sub":"Hilf mit, den Planeten sauber zu halten!","help":"Zieh den Gegenstand oder tippe auf eine Tonne","bin0":"RECYCLING","bin1":"BIOABFALL","bin2":"RESTMÜLL","score":"Punkte","done":"Alles richtig sortiert!","replay":"↻ Nochmal","exit":"Verlassen","reset":"↻ Neustart","correct":"Richtig! +1","wrong":"Versuch eine andere Tonne","progress":"Gegenstand","select":"In welche Tonne?"}
}
const ITEM_NAMES: Dictionary = {
    "ru":["Пластиковая бутылка","Лист бумаги","Стеклянная банка","Алюминиевая банка","Чистый картон","Газета","Банановая кожура","Огрызок яблока","Лист дерева","Апельсиновая кожура","Кофейная гуща","Пакет от чипсов","Разбитая чашка","Подгузник","Пенопластовый стакан"],
    "en":["Plastic bottle","Paper","Glass jar","Aluminum can","Clean cardboard","Newspaper","Banana peel","Apple core","Leaf","Orange peel","Coffee grounds","Chip bag","Broken cup","Diaper","Foam cup"],
    "pt":["Garrafa plástica","Papel","Pote de vidro","Lata de alumínio","Papelão limpo","Jornal","Casca de banana","Miolo de maçã","Folha","Casca de laranja","Borra de café","Pacote de salgadinho","Xícara quebrada","Fralda","Copo de isopor"],
    "es":["Botella de plástico","Papel","Tarro de vidrio","Lata de aluminio","Cartón limpio","Periódico","Cáscara de plátano","Corazón de manzana","Hoja","Cáscara de naranja","Posos de café","Bolsa de patatas","Taza rota","Pañal","Vaso de espuma"],
    "fr":["Bouteille plastique","Papier","Bocal en verre","Canette en aluminium","Carton propre","Journal","Peau de banane","Trognon de pomme","Feuille","Peau d'orange","Marc de café","Sachet de chips","Tasse cassée","Couche","Gobelet en mousse"],
    "de":["Plastikflasche","Papier","Glasgefäß","Aludose","Sauberer Karton","Zeitung","Bananenschale","Apfelrest","Blatt","Orangenschale","Kaffeesatz","Chipstüte","Zerbrochene Tasse","Windel","Styroporbecher"]
}
const BIN_COLORS: Array[Color] = [Color("#46a4f5"), Color("#53ca87"), Color("#a8b5c7")]

var _locale: String = "en"
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _deck: Array[Dictionary] = []
var _index: int = 0
var _score: int = 0
var _locked: bool = false
var _won: bool = false
var _dragging: bool = false
var _drag_pointer: int = -99
var _drag_start: Vector2 = Vector2.ZERO
var _tile_origin: Vector2 = Vector2.ZERO
var _host_back: Control
var _backdrop: Control
var _bg_texture: TextureRect
var _stage: Panel
var _header: Panel
var _back: Button
var _hud: Control
var _title: Label
var _subtitle: Label
var _instruction: Label
var _progress: Label
var _status: Label
var _item_tile: Panel
var _item_icon: Control
var _item_name: Label
var _item_hint: Label
var _bins: Array[Button] = []
var _bin_icons: Array[Control] = []
var _bin_names: Array[Label] = []
var _reset: Button
var _victory_shade: ColorRect
var _victory_panel: Panel
var _victory_title: Label
var _victory_score: Label
var _victory_repeat: Button
var _victory_exit: Button
var _next_timer: Timer
var _status_timer: Timer
var _sfx: AudioStreamPlayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_PASS
    _rng.randomize()
    _make_view()
    _make_audio()
    _read_locale()
    _start_round()
    _translate()
    resized.connect(_layout_game)
    get_viewport().size_changed.connect(_layout_game)
    var service: Node = get_node_or_null("/root/MobileLocale")
    if service != null and service.has_signal("language_changed"):
        service.connect("language_changed", _on_language_changed)
    _find_host_back()
    _layout_game()
    call_deferred("_layout_game")

func _make_view() -> void:
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
    TOOLBAR.apply_title_style(_stage)
    add_child(_stage)
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
    _hud.name = "EcoSortingNativeCounter"
    _hud.size = Vector2(1680.0, 158.0)
    add_child(_hud)
    for key in ["sim_button", "flight_button"]:
        var action: Button = _hud.get(key) as Button
        if action != null:
            action.disabled = true
            action.hide()
    _instruction = _label(_stage, Color("#d7f0ff"))
    _instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _progress = _label(_stage, Color("#b7e1f2"))
    _progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _status = _label(_stage, Color("#eafdfc"))
    _item_tile = Panel.new()
    _item_tile.name = "DraggableItemCard"
    _item_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _item_tile.z_index = 15
    _item_tile.add_theme_stylebox_override("panel", _style(Color("#e0f5ff"), Color("#5fc9eb"), 22, 3))
    _stage.add_child(_item_tile)
    _item_icon = ICON.new() as Control
    _item_icon.name = "CurrentWastePicture"
    _item_tile.add_child(_item_icon)
    _item_name = _label(_item_tile, Color("#163b63"))
    _item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _item_hint = _label(_stage, Color("#acd8e7"))
    for i in range(3):
        var index: int = i
        var bin: Button = _button(_stage, "EcoBin" + str(i), func() -> void: _submit_to_bin(index))
        bin.add_theme_stylebox_override("normal", _style(Color(BIN_COLORS[i], 0.23), BIN_COLORS[i], 19, 3))
        bin.add_theme_stylebox_override("hover", _style(Color(BIN_COLORS[i], 0.43), BIN_COLORS[i], 19, 4))
        bin.add_theme_stylebox_override("pressed", _style(Color(BIN_COLORS[i], 0.56), Color("#ffffff"), 19, 4))
        bin.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        _bins.append(bin)
        var icon: Control = ICON.new() as Control
        icon.set("kind", ["bin_recycle", "bin_organics", "bin_trash"][i])
        bin.add_child(icon)
        _bin_icons.append(icon)
        var text: Label = _label(bin, Color("#f6ffff"))
        text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _bin_names.append(text)
    _reset = _button(_stage, "EcoSortingRestart", _start_round)
    _next_timer = Timer.new()
    _next_timer.one_shot = true
    _next_timer.wait_time = 0.35
    _next_timer.timeout.connect(_next_item)
    add_child(_next_timer)
    _status_timer = Timer.new()
    _status_timer.one_shot = true
    _status_timer.wait_time = 1.1
    _status_timer.timeout.connect(_clear_status)
    add_child(_status_timer)
    _create_victory_modal()

func _create_victory_modal() -> void:
    _victory_shade = ColorRect.new()
    _victory_shade.name = "EcoVictoryOverlay"
    _victory_shade.color = Color(0.005, 0.021, 0.07, 0.87)
    _victory_shade.mouse_filter = Control.MOUSE_FILTER_STOP
    _victory_shade.z_index = 35
    _stage.add_child(_victory_shade)
    _victory_panel = Panel.new()
    _victory_panel.name = "EcoVictoryDialog"
    TOOLBAR.apply_title_style(_victory_panel)
    _victory_shade.add_child(_victory_panel)
    _victory_title = _label(_victory_panel, Color("#f8ffff"))
    _victory_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _victory_score = _label(_victory_panel, Color("#a8f5dc"))
    _victory_repeat = _button(_victory_panel, "EcoReplay", _start_round)
    _victory_exit = _button(_victory_panel, "EcoExit", _exit_to_cards)
    _victory_shade.hide()

func _label(parent: Node, color: Color) -> Label:
    var label: Label = Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.clip_text = true
    label.add_theme_color_override("font_color", color)
    parent.add_child(label)
    return label

func _button(parent: Node, name_value: String, click: Callable) -> Button:
    var button: Button = Button.new()
    button.name = name_value
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_stylebox_override("normal", KIT.button_style(false))
    button.add_theme_stylebox_override("hover", KIT.button_style(true))
    button.add_theme_stylebox_override("pressed", KIT.button_style(true))
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.add_theme_color_override("font_color", Color("#f9fdff"))
    button.pressed.connect(click)
    parent.add_child(button)
    return button

func _style(bg: Color, line: Color, radius: int, thickness: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = line
    style.set_border_width_all(thickness)
    style.set_corner_radius_all(radius)
    return style

func _load_project_background() -> void:
    if not FileAccess.file_exists(BG_PATH_FILE):
        return
    var source: String = FileAccess.get_file_as_string(BG_PATH_FILE).strip_edges()
    if source.begins_with("res://") and ResourceLoader.exists(source):
        var tex: Resource = load(source)
        if tex is Texture2D:
            _bg_texture.texture = tex as Texture2D

func _make_audio() -> void:
    _sfx = AudioStreamPlayer.new()
    _sfx.name = "EcoSortingEffects"
    add_child(_sfx)
    if AudioServer.get_bus_index("SFX") != -1:
        _sfx.bus = "SFX"

func _sound(path: String) -> void:
    if ResourceLoader.exists(path):
        var resource: Resource = load(path)
        if resource is AudioStream:
            _sfx.stream = resource as AudioStream
            _sfx.play()

func _read_locale() -> void:
    _locale = "en"
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null:
        _locale = str(mobile.get("language")).to_lower().get_slice("_", 0).get_slice("-", 0)
    elif get_node_or_null("/root/LanguageService") != null:
        var svc: Node = get_node_or_null("/root/LanguageService")
        _locale = str(svc.get("learning_locale")).to_lower().get_slice("_", 0).get_slice("-", 0)
    if not WORDS.has(_locale):
        _locale = "en"

func _on_language_changed(_language: String) -> void:
    _read_locale()
    _translate()
    _layout_game()

func _t(key: String) -> String:
    return str((WORDS.get(_locale, WORDS["en"]) as Dictionary).get(key, key))

func _translate() -> void:
    _title.text = _t("title")
    _subtitle.text = _t("sub")
    _instruction.text = _t("help")
    _item_hint.text = _t("select")
    _reset.text = _t("reset")
    _back.tooltip_text = _t("exit")
    for i in range(3):
        _bin_names[i].text = _t("bin" + str(i))
        _bins[i].tooltip_text = _t("bin" + str(i))
    _victory_title.text = _t("done")
    _victory_repeat.text = _t("replay")
    _victory_exit.text = _t("exit")
    _update_readout()
    _update_item_visual()

func _item_name_localized(index_value: int) -> String:
    if index_value < 0 or index_value >= DATA.size():
        return ""
    var kind_value: String = str(_deck[index_value].get("id", ""))
    for i in range(DATA.size()):
        if str(DATA[i].get("id", "")) == kind_value:
            var labels: Array = ITEM_NAMES.get(_locale, ITEM_NAMES["en"])
            return str(labels[i])
    return kind_value

func _start_round() -> void:
    _next_timer.stop()
    _status_timer.stop()
    _deck.clear()
    for entry in DATA:
        _deck.append(entry.duplicate())
    _deck.shuffle()
    _index = 0
    _score = 0
    _locked = false
    _won = false
    _dragging = false
    _drag_pointer = -99
    _victory_shade.hide()
    _status.text = ""
    _item_tile.show()
    _item_tile.modulate = Color.WHITE
    _hud.set("crystal_count", 0)
    _update_item_visual()
    _update_readout()
    _layout_game()

func _update_item_visual() -> void:
    if _index >= _deck.size() or _item_icon == null:
        return
    _item_icon.set("kind", str(_deck[_index]["id"]))
    _item_icon.queue_redraw()
    _item_name.text = _item_name_localized(_index)

func _update_readout() -> void:
    if _progress == null:
        return
    _progress.text = _t("progress") + " " + str(mini(_index + 1, TOTAL)) + "/" + str(TOTAL) + "   ·   " + _t("score") + ": " + str(_score)
    if _hud != null:
        _hud.set("crystal_count", _score)
    if _victory_score != null:
        _victory_score.text = _t("score") + ": " + str(_score) + "/" + str(TOTAL)

func _submit_to_bin(index_value: int) -> void:
    if _locked or _won or _index >= _deck.size():
        return
    _dragging = false
    _item_tile.position = _tile_origin
    if int(_deck[_index]["bin"]) != index_value:
        _status.text = _t("wrong")
        _status.add_theme_color_override("font_color", Color("#ffd9a7"))
        _status_timer.start()
        _sound("res://education/playtown/audio/sfx/error.ogg")
        return
    _status_timer.stop()
    _status.text = _t("correct")
    _status.add_theme_color_override("font_color", Color("#b7ffd8"))
    _sound("res://education/playtown/audio/sfx/correct.ogg")
    _score += 1
    _index += 1
    _locked = true
    _update_readout()
    _item_tile.modulate.a = 0.60
    _next_timer.start()

func _next_item() -> void:
    if _won:
        return
    _locked = false
    _item_tile.modulate = Color.WHITE
    _item_tile.position = _tile_origin
    _status.text = ""
    if _index >= TOTAL:
        _win_round()
        return
    _update_item_visual()
    _update_readout()

func _clear_status() -> void:
    if not _locked:
        _status.text = ""

func _win_round() -> void:
    _won = true
    _locked = true
    _dragging = false
    _victory_shade.show()
    _update_readout()
    _sound("res://education/playtown/audio/sfx/bonus_wheel_win.mp3")

func _safe_rect(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view)
    var pixels: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if pixels.x <= 0.0 or pixels.y <= 0.0 or safe.size.x < 30:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(safe.position) * (view / pixels), Vector2(safe.size) * (view / pixels))

func _layout_game() -> void:
    if _backdrop == null:
        return
    var view: Vector2 = size
    if view.x < 210.0 or view.y < 170.0:
        return
    _backdrop.position = Vector2.ZERO
    _backdrop.size = view
    _bg_texture.position = Vector2.ZERO
    _bg_texture.size = view
    var safe: Rect2 = _safe_rect(view)
    var header_end: float = TOOLBAR.relayout(view, safe, _back, _hud, _header, _title, _subtitle)
    var side: float = clampf(safe.size.x * 0.015, 7.0, 25.0)
    var gap: float = clampf(safe.size.y * 0.016, 5.0, 16.0)
    var y: float = header_end + gap
    _stage.position = Vector2(safe.position.x + side, y)
    _stage.size = Vector2(maxf(180.0, safe.size.x - side * 2.0), maxf(125.0, safe.end.y - y - side))
    _layout_stage()

func _layout_stage() -> void:
    var width: float = _stage.size.x
    var height: float = _stage.size.y
    var pad: float = clampf(minf(width, height) * 0.034, 7.0, 23.0)
    var content_width: float = minf(width - pad * 2.0, 1360.0)
    var left: float = (width - content_width) * 0.5
    var top_h: float = clampf(height * 0.09, 24.0, 43.0)
    var font: int = maxi(11, mini(21, roundi(height * 0.049)))
    _instruction.position = Vector2(left, pad)
    _instruction.size = Vector2(content_width * 0.67, top_h)
    _instruction.add_theme_font_size_override("font_size", font)
    _progress.position = Vector2(left + content_width * 0.67, pad)
    _progress.size = Vector2(content_width * 0.33, top_h)
    _progress.add_theme_font_size_override("font_size", maxi(10, font - 1))
    var bin_gap: float = clampf(content_width * 0.02, 6.0, 25.0)
    var bin_height: float = clampf(height * 0.285, 75.0, 188.0)
    var bins_y: float = height - pad - bin_height
    var bin_width: float = (content_width - bin_gap * 2.0) / 3.0
    for i in range(3):
        var bin: Button = _bins[i]
        bin.position = Vector2(left + float(i) * (bin_width + bin_gap), bins_y)
        bin.size = Vector2(bin_width, bin_height)
        var icon_h: float = bin_height * 0.56
        var icon_size: float = minf(bin_width * 0.27, icon_h)
        _bin_icons[i].position = Vector2((bin_width - icon_size) * 0.5, bin_height * 0.08)
        _bin_icons[i].size = Vector2(icon_size, icon_size)
        _bin_icons[i].queue_redraw()
        _bin_names[i].position = Vector2(5.0, bin_height * 0.58)
        _bin_names[i].size = Vector2(bin_width - 10.0, bin_height * 0.30)
        _bin_names[i].add_theme_font_size_override("font_size", maxi(11, mini(24, roundi(minf(bin_width * 0.065, bin_height * 0.17)))))
    var usable_top: float = pad + top_h + pad * 0.20
    var usable_height: float = bins_y - usable_top
    var tile_h: float = clampf(usable_height * 0.74, 62.0, 220.0)
    var tile_w: float = minf(content_width * 0.32, tile_h * 1.10)
    tile_w = maxf(tile_w, 90.0)
    var tile_y: float = usable_top + maxf(0.0, (usable_height - tile_h - clampf(height * 0.055, 17.0, 32.0)) * 0.5)
    _tile_origin = Vector2(left + (content_width - tile_w) * 0.5, tile_y)
    if not _dragging:
        _item_tile.position = _tile_origin
    _item_tile.size = Vector2(tile_w, tile_h)
    _item_icon.position = Vector2(tile_w * 0.25, tile_h * 0.025)
    _item_icon.size = Vector2(tile_w * 0.50, tile_h * 0.65)
    _item_icon.queue_redraw()
    _item_name.position = Vector2(7.0, tile_h * 0.67)
    _item_name.size = Vector2(tile_w - 14.0, tile_h * 0.28)
    _item_name.add_theme_font_size_override("font_size", maxi(10, mini(20, roundi(minf(tile_w * 0.12, tile_h * 0.105)))))
    var hint_y: float = minf(bins_y - 31.0, tile_y + tile_h + 3.0)
    _item_hint.position = Vector2(left + content_width * 0.22, hint_y)
    _item_hint.size = Vector2(content_width * 0.56, clampf(height * 0.058, 16.0, 32.0))
    _item_hint.add_theme_font_size_override("font_size", maxi(10, mini(16, roundi(height * 0.033))))
    _reset.position = Vector2(left, bins_y - clampf(height * 0.095, 35.0, 49.0) - 6.0)
    _reset.size = Vector2(minf(176.0, content_width * 0.20), clampf(height * 0.095, 35.0, 49.0))
    _reset.add_theme_font_size_override("font_size", maxi(11, mini(18, roundi(height * 0.04))))
    _status.position = Vector2(left + content_width * 0.71, bins_y - clampf(height * 0.093, 34.0, 45.0) - 6.0)
    _status.size = Vector2(content_width * 0.29, clampf(height * 0.093, 34.0, 45.0))
    _status.add_theme_font_size_override("font_size", maxi(10, mini(18, roundi(height * 0.039))))
    _layout_victory()

func _layout_victory() -> void:
    var w: float = _stage.size.x
    var h: float = _stage.size.y
    _victory_shade.position = Vector2.ZERO
    _victory_shade.size = _stage.size
    var dialog_w: float = minf(w * 0.86, 650.0)
    var dialog_h: float = minf(h * 0.85, 310.0)
    _victory_panel.position = Vector2((w - dialog_w) * 0.5, (h - dialog_h) * 0.5)
    _victory_panel.size = Vector2(dialog_w, dialog_h)
    _victory_title.position = Vector2(20.0, dialog_h * 0.08)
    _victory_title.size = Vector2(dialog_w - 40.0, dialog_h * 0.34)
    _victory_title.add_theme_font_size_override("font_size", maxi(16, mini(30, roundi(dialog_h * 0.098))))
    _victory_score.position = Vector2(20.0, dialog_h * 0.46)
    _victory_score.size = Vector2(dialog_w - 40.0, dialog_h * 0.13)
    _victory_score.add_theme_font_size_override("font_size", maxi(13, mini(24, roundi(dialog_h * 0.07))))
    var b_gap: float = clampf(dialog_w * 0.025, 8.0, 20.0)
    var b_width: float = (dialog_w - 60.0 - b_gap) * 0.5
    for i in range(2):
        var b: Button = [_victory_repeat, _victory_exit][i]
        b.position = Vector2(30.0 + float(i) * (b_width + b_gap), dialog_h * 0.70)
        b.size = Vector2(b_width, maxf(32.0, dialog_h * 0.17))
        b.add_theme_font_size_override("font_size", maxi(11, mini(22, roundi(dialog_h * 0.065))))

func _handle_pointer_down(pos: Vector2, pointer: int) -> void:
    if _won or _locked or _dragging:
        return
    if _item_tile.get_global_rect().has_point(pos):
        _dragging = true
        _drag_pointer = pointer
        _drag_start = pos
        _item_tile.modulate = Color(1.0, 1.0, 1.0, 0.91)

func _handle_pointer_move(pos: Vector2, pointer: int) -> void:
    if not _dragging or pointer != _drag_pointer:
        return
    _item_tile.position = _tile_origin + pos - _drag_start

func _handle_pointer_up(pos: Vector2, pointer: int) -> void:
    if not _dragging or pointer != _drag_pointer:
        return
    var distance: float = pos.distance_to(_drag_start)
    _dragging = false
    _drag_pointer = -99
    _item_tile.modulate = Color.WHITE
    _item_tile.position = _tile_origin
    if distance < 12.0:
        return
    for i in range(3):
        if _bins[i].get_global_rect().has_point(pos):
            _submit_to_bin(i)
            return

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _handle_pointer_down(touch.position, touch.index)
        else:
            _handle_pointer_up(touch.position, touch.index)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        _handle_pointer_move(drag.position, drag.index)
    elif event is InputEventMouseButton:
        var button: InputEventMouseButton = event
        if button.button_index == MOUSE_BUTTON_LEFT:
            if button.pressed:
                _handle_pointer_down(button.position, -1)
            else:
                _handle_pointer_up(button.position, -1)
    elif event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _handle_pointer_move(motion.position, -1)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _exit_to_cards()
        get_viewport().set_input_as_handled()

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
    if is_instance_valid(_host_back):
        _host_back.show()

func _exit_to_cards() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
    var portal: Node = get_node_or_null("/root/PlayTownPortal")
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
    var fallback: String = "res://education/playtown/scenes/screens/game_select_playground.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)
