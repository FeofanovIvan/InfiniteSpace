extends Control
## MIKA / Solution Lab v2.1 — educational color solutions.
## Reuses the PlayTown color-mixing rules and seven recorded color voices.
## The original PlayTown color_mix_game.gd and scene are NOT changed.

const TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const UI_KIT = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const BACK_GLYPH = preload("res://simulator_ui/back_arrow_glyph.gd")
const VESSEL = preload("res://planet_hub/games/solution_lab/solution_vessel.gd")
const LAB_BACKGROUND = preload("res://planet_hub/games/solution_lab/assets/neon_liquid_planet_lab.webp")
const ACTION_GLYPH = preload("res://planet_hub/games/solution_lab/solution_action_glyph.gd")
const SUCCESS_SOUND = preload("res://education/playtown/audio/sfx/correct.ogg")
const RETRY_SOUND = preload("res://education/playtown/audio/sfx/wrong.ogg")

const BOARD_SIZE := Vector2(1500.0, 700.0)
const MIX_CENTER := Vector2(750.0, 456.0)
const REAGENTS: Array[Dictionary] = [
    {"id":"red",     "hex":"#ef3f36", "voice":0},
    {"id":"yellow",  "hex":"#f4d53b", "voice":2},
    {"id":"blue",    "hex":"#397bdc", "voice":5},
    {"id":"white",   "hex":"#f7f4e8", "voice":-1},
    {"id":"green",   "hex":"#53b653", "voice":3},
    {"id":"orange",  "hex":"#f28b2d", "voice":1},
    {"id":"purple",  "hex":"#995bd1", "voice":6},
    {"id":"black",   "hex":"#343847", "voice":-1},
    {"id":"cyan",    "hex":"#65c9e8", "voice":4},
    {"id":"pink",    "hex":"#f891b1", "voice":-1},
    {"id":"brown",   "hex":"#8d5a35", "voice":-1},
    {"id":"magenta", "hex":"#d94ca6", "voice":-1},
]
const RECIPES: Array[Dictionary] = [
    {"id":"orange", "hex":"#f28b2d", "needs":["red","yellow"]},
    {"id":"green", "hex":"#53b653", "needs":["yellow","blue"]},
    {"id":"purple", "hex":"#995bd1", "needs":["red","blue"]},
    {"id":"pink", "hex":"#f891b1", "needs":["red","white"]},
    {"id":"cyan", "hex":"#65c9e8", "needs":["blue","white"]},
    {"id":"lilac", "hex":"#d1a8f3", "needs":["purple","white"]},
    {"id":"brown", "hex":"#8d5a35", "needs":["red","yellow","blue"]},
    {"id":"peach", "hex":"#ffc294", "needs":["orange","white"]},
    {"id":"gray", "hex":"#aeb4c2", "needs":["black","white"]},
    {"id":"turquoise", "hex":"#31cbb9", "needs":["green","cyan"]},
    {"id":"mint", "hex":"#9cedc5", "needs":["green","white"]},
    {"id":"lime", "hex":"#b8e148", "needs":["green","yellow"]},
    {"id":"coral", "hex":"#ff817d", "needs":["orange","pink"]},
    {"id":"lavender", "hex":"#c7b0e9", "needs":["purple","pink"]},
    {"id":"navy", "hex":"#263f8f", "needs":["blue","black"]},
    {"id":"cream", "hex":"#fff0b4", "needs":["yellow","white"]},
    {"id":"rose", "hex":"#ec5279", "needs":["red","pink"]},
    {"id":"sky", "hex":"#a8e5f8", "needs":["cyan","white"]},
    {"id":"teal", "hex":"#198e98", "needs":["blue","green"]},
    {"id":"olive", "hex":"#9d9a49", "needs":["green","brown"]},
    {"id":"plum", "hex":"#803b80", "needs":["purple","red"]},
    {"id":"indigo", "hex":"#6548b3", "needs":["purple","blue"]},
    {"id":"apricot", "hex":"#ffca72", "needs":["orange","yellow","white"]},
    {"id":"amber", "hex":"#f7a82d", "needs":["orange","yellow"]},
    {"id":"dusty_rose", "hex":"#cc949c", "needs":["pink","brown","white"]},
    {"id":"sand", "hex":"#dec898", "needs":["brown","white","yellow"]},
    {"id":"fuchsia", "hex":"#e449a5", "needs":["red","magenta"]},
    {"id":"orchid", "hex":"#bb77d9", "needs":["purple","magenta"]},
]

const WORDS: Dictionary = {
    "ru":{"title":"Лаборатория растворов","subtitle":"Получи раствор нужного цвета","goal":"ПОЛУЧИ РАСТВОР ЭТОГО ЦВЕТА","mix":"СМЕШАЙ КОМПОНЕНТЫ","drag":"Нажми на колбу или перетащи её к центральной пробирке","next":"Добавь следующий раствор","used":"Этот раствор уже добавлен","great":"Отлично! Раствор готов!","retry":"Попробуй смешать другие цвета","new":"Следующий цвет","restart":"Перезапуск","components":"КОМПОНЕНТЫ"},
    "en":{"title":"Solution Lab","subtitle":"Make a solution of the target color","goal":"MAKE A SOLUTION THIS COLOR","mix":"MIX THE INGREDIENTS","drag":"Tap a flask or drag it to the central flask","next":"Add the next solution","used":"This solution is already added","great":"Great! Solution ready!","retry":"Try mixing different colors","new":"Next Color","restart":"Restart","components":"INGREDIENTS"},
    "pt":{"title":"Laboratório de Soluções","subtitle":"Crie uma solução da cor indicada","goal":"FAÇA UMA SOLUÇÃO DESTA COR","mix":"MISTURE OS INGREDIENTES","drag":"Toque num frasco ou arraste-o até o centro","next":"Adicione outra solução","used":"Esta solução já foi adicionada","great":"Ótimo! Solução pronta!","retry":"Tente misturar outras cores","new":"Próxima cor","restart":"Reiniciar","components":"INGREDIENTES"},
    "es":{"title":"Laboratorio de Soluciones","subtitle":"Crea una solución del color indicado","goal":"PREPARA UNA SOLUCIÓN DE ESTE COLOR","mix":"MEZCLA LOS INGREDIENTES","drag":"Toca un frasco o arrástralo al centro","next":"Añade otra solución","used":"Esta solución ya está añadida","great":"¡Genial! ¡Solución lista!","retry":"Prueba a mezclar otros colores","new":"Siguiente color","restart":"Reiniciar","components":"INGREDIENTES"},
    "de":{"title":"Lösungslabor","subtitle":"Mische eine Lösung in der Zielfarbe","goal":"MISCH EINE LÖSUNG IN DIESER FARBE","mix":"MISCH DIE ZUTATEN","drag":"Tippe auf einen Kolben oder ziehe ihn zur Mitte","next":"Füge die nächste Lösung hinzu","used":"Diese Lösung wurde schon hinzugefügt","great":"Super! Die Lösung ist fertig!","retry":"Versuche andere Farben","new":"Nächste Farbe","restart":"Neustart","components":"ZUTATEN"},
    "fr":{"title":"Laboratoire de solutions","subtitle":"Prépare une solution de la couleur cible","goal":"PRÉPARE UNE SOLUTION DE CETTE COULEUR","mix":"MÉLANGE LES INGRÉDIENTS","drag":"Touche un flacon ou glisse-le au centre","next":"Ajoute une autre solution","used":"Cette solution est déjà ajoutée","great":"Bravo ! Solution réussie !","retry":"Essaie d’autres couleurs","new":"Couleur suivante","restart":"Recommencer","components":"INGRÉDIENTS"}
}
const COLORS: Dictionary = {
    "red":["красный","red","vermelho","rojo","rot","rouge"],
    "yellow":["жёлтый","yellow","amarelo","amarillo","gelb","jaune"],
    "blue":["синий","blue","azul","azul","blau","bleu"],
    "white":["белый","white","branco","blanco","weiß","blanc"],
    "green":["зелёный","green","verde","verde","grün","vert"],
    "orange":["оранжевый","orange","laranja","naranja","orange","orange"],
    "purple":["фиолетовый","purple","roxo","morado","violett","violet"],
    "black":["чёрный","black","preto","negro","schwarz","noir"],
    "cyan":["голубой","light blue","azul-claro","celeste","hellblau","bleu clair"],
    "pink":["розовый","pink","rosa","rosa","rosa","rose"],
    "brown":["коричневый","brown","marrom","marrón","braun","marron"],
    "magenta":["пурпурный","magenta","magenta","magenta","magenta","magenta"],
    "lilac":["сиреневый","lilac","lilás","lila","flieder","lilas"],
    "gray":["серый","gray","cinza","gris","grau","gris"],
    "peach":["персиковый","peach","pêssego","melocotón","pfirsich","pêche"],
    "turquoise":["бирюзовый","turquoise","turquesa","turquesa","türkis","turquoise"],
    "mint":["мятный","mint","menta","menta","mintgrün","menthe"],
    "lime":["лаймовый","lime","verde-lima","verde lima","limettengrün","vert citron"],
    "coral":["коралловый","coral","coral","coral","koralle","corail"],
    "lavender":["лавандовый","lavender","lavanda","lavanda","lavendel","lavande"],
    "navy":["тёмно-синий","navy blue","azul-marinho","azul marino","marineblau","bleu marine"],
    "cream":["кремовый","cream","creme","crema","creme","crème"],
    "rose":["малиново-розовый","rose","rosa escuro","rosa oscuro","rosarot","rose vif"],
    "sky":["небесно-голубой","sky blue","azul-céu","azul cielo","himmelblau","bleu ciel"],
    "teal":["сине-зелёный","teal","verde-azulado","verde azulado","blaugrün","bleu sarcelle"],
    "olive":["оливковый","olive","oliva","oliva","olivgrün","olive"],
    "plum":["сливовый","plum","ameixa","ciruela","pflaume","prune"],
    "indigo":["индиго","indigo","índigo","índigo","indigo","indigo"],
    "apricot":["абрикосовый","apricot","damasco","albaricoque","aprikose","abricot"],
    "amber":["янтарный","amber","âmbar","ámbar","bernstein","ambre"],
    "dusty_rose":["пепельно-розовый","dusty rose","rosa antigo","rosa empolvado","altrosa","vieux rose"],
    "sand":["песочный","sand","areia","arena","sand","sable"],
    "fuchsia":["фуксия","fuchsia","fúcsia","fucsia","fuchsia","fuchsia"],
    "orchid":["орхидейный","orchid","orquídea","orquídea","orchidee","orchidée"]
}
const LANG_ORDER := ["ru","en","pt","es","de","fr"]

var _locale: String = "en"
var _background: TextureRect
var _back: Button
var _native_counter: Control
var _header: Panel
var _header_title: Label
var _header_subtitle: Label
var _shell: Panel
var _board: Control
var _target_title: Label
var _target_name: Label
var _target_chip: Panel
var _ingredient_title: Label
var _ingredient_count: Label
var _indicators: Array[Panel] = []
var _cards: Array[Panel] = []
var _button_labels: Array[Label] = []
var _vessels: Array[Node2D] = []
var _card_labels: Array[Label] = []
var _mixer: Node2D
var _status: Label
var _new_button: Button
var _reset_button: Button
var _sfx: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _queue: Array[int] = []
var _rng := RandomNumberGenerator.new()
var _host_back_buttons: Array[Button] = []
var _host_back_visibility: Array[bool] = []
var _cursor: int = 0
var _recipe_index: int = -1
var _selected: Array[String] = []
var _mixed_color: Color = Color.WHITE
var _mixed_fill: float = 0.0
var _crystals: int = 0
var _locked: bool = false
var _tracking: int = -1
var _touch_index: int = -1
var _drag_touch: bool = false
var _pointer_origin: Vector2 = Vector2.ZERO
var _ghost: Node2D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    _build_ui()
    _read_language()
    get_viewport().size_changed.connect(_layout)
    _layout()
    call_deferred("_layout")
    # Runner back arrows live OUTSIDE the game SubViewport. Show this game's
    # native toolbar back arrow and hide only the corresponding runner overlay.
    call_deferred("_claim_toolbar_navigation")
    _new_round()

func _build_ui() -> void:
    _header = Panel.new()
    _header.name = "MIKANativeCyanTitle"
    _header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_header)
    add_child(_header)
    _header_title = _label("", 30, Color.WHITE, _header)
    _header_subtitle = _label("", 15, Color("#9de9ff"), _header)
    _back = Button.new()
    _back.name = "BackToMinigames"
    _back.focus_mode = Control.FOCUS_NONE
    _back.add_theme_stylebox_override("normal", UI_KIT.button_style())
    _back.add_theme_stylebox_override("hover", UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("pressed", UI_KIT.button_style(true))
    _back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _back.pressed.connect(_go_back)
    _back.disabled = false
    _back.visible = true
    _back.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_back)
    var arrow: Control = BACK_GLYPH.new() as Control
    arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back.add_child(arrow)
    arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _native_counter = HUD.new() as Control
    _native_counter.name = "MIKANativeCrystalCounter"
    _native_counter.size = Vector2(1680,158)
    add_child(_native_counter)
    for prop in ["sim_button", "flight_button"]:
        var b: Button = _native_counter.get(prop) as Button
        if b != null:
            b.disabled = true
            b.hide()
    _native_counter.set("crystal_count", 0)

    _shell = Panel.new()
    _shell.name = "SolutionLabMainStage"
    _shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _shell.clip_contents = true
    # Retain the approved cyan outline, but make the main stage fully clear.
    # The laboratory artwork now fills ONLY the safe-area stage, not the HUD.
    var transparent_stage: StyleBoxFlat = UI_KIT.stage_style()
    transparent_stage.bg_color = Color(0.0, 0.0, 0.0, 0.0)
    _shell.add_theme_stylebox_override("panel", transparent_stage)
    add_child(_shell)

    _background = TextureRect.new()
    _background.name = "LaboratoryArtworkInsideStage"
    _background.texture = LAB_BACKGROUND
    _background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    # The shader applies aspect-correct cover cropping itself. This leaves
    # rect UV in [0,1], allowing pixel-accurate rounded corner clipping.
    _background.stretch_mode = TextureRect.STRETCH_SCALE
    _background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # The original stage has rounded corners. Keep the moving responsive
    # artwork INSIDE that curve; clipping by Control alone is rectangular.
    var round_clip: Shader = Shader.new()
    round_clip.code = """
shader_type canvas_item;
uniform vec2 rect_dimensions = vec2(1500.0, 700.0);
uniform vec2 source_dimensions = vec2(1846.0, 852.0);
uniform float corner_radius = 33.0;
void fragment() {
    vec2 half_rect = max(rect_dimensions * 0.5, vec2(1.0));
    vec2 pixel = UV * rect_dimensions;
    vec2 delta = abs(pixel - half_rect) - (half_rect - vec2(corner_radius));
    float sdf = length(max(delta, vec2(0.0))) + min(max(delta.x, delta.y), 0.0) - corner_radius;
    // Aspect-correct center cover without warping artwork proportions.
    vec2 source_size = max(source_dimensions, vec2(1.0));
    float cover_factor = max(rect_dimensions.x / source_size.x, rect_dimensions.y / source_size.y);
    vec2 visible_uv = rect_dimensions / (source_size * cover_factor);
    vec2 image_uv = (UV - vec2(0.5)) * visible_uv + vec2(0.5);
    vec4 sample_color = texture(TEXTURE, image_uv);
    COLOR = vec4(sample_color.rgb, sample_color.a * (1.0 - smoothstep(-1.0, 1.0, sdf)));
}
"""
    var clip_material: ShaderMaterial = ShaderMaterial.new()
    clip_material.shader = round_clip
    clip_material.set_shader_parameter("source_dimensions", LAB_BACKGROUND.get_size())
    _background.material = clip_material
    _shell.add_child(_background)
    _board = Control.new()
    _board.name = "ScalableLaboratoryWorktop"
    _board.size = BOARD_SIZE
    _board.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _shell.add_child(_board)

    # Main worktop: symmetrical outer margins, 3x2 reagent cards on both sides,
    # clear central lane and deliberate vertical spacing between header, goal and ingredients.
    var goal := _panel("TargetSolution", Vector2(526, 24), Vector2(448, 118), _board)
    _target_title = _label("", 21, Color("#b4ebff"), goal)
    _target_title.position = Vector2(14, 8)
    _target_title.size = Vector2(420, 30)
    _target_chip = _panel("TargetColor", Vector2(28, 51), Vector2(91, 49), goal)
    _target_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _target_name = _label("", 25, Color.WHITE, goal)
    _target_name.position = Vector2(130, 46)
    _target_name.size = Vector2(300, 60)

    _ingredient_title = _label("", 19, Color("#b4ebff"), _board)
    _ingredient_title.position = Vector2(544, 164)
    _ingredient_title.size = Vector2(412, 32)
    for i in range(3):
        var dot := _panel("Ingredient_%d" % i, Vector2(634.0 + float(i) * 78.0, 210), Vector2(58, 56), _board)
        dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _indicators.append(dot)
    _ingredient_count = _label("0 / 2", 18, Color.WHITE, _board)
    _ingredient_count.position = Vector2(663, 273)
    _ingredient_count.size = Vector2(174, 30)

    # The central flask is now BELOW the ingredient row and is rendered with
    # the same filled mask + transparent glass as all twelve side vessels.
    _mixer = VESSEL.new() as Node2D
    _mixer.name = "CentralMaskedSolutionFlask"
    _board.add_child(_mixer)
    _mixer.position = MIX_CENTER
    _mixer.call("configure", 0, Color.WHITE, 0.0)
    var mixer_scale: float = float(_mixer.call("fit_scale", 210.0, 235.0))
    _mixer.scale = Vector2.ONE * mixer_scale

    _status = _label("", 21, Color("#d8f6ff"), _board)
    _status.position = Vector2(480, 582)
    _status.size = Vector2(540, 33)
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _reset_button = _make_button(Vector2(556, 626), Vector2(183, 54))
    _reset_button.name = "RestartSolutionButton"
    _reset_button.pressed.connect(_restart_same)
    _new_button = _make_button(Vector2(761, 626), Vector2(214, 54))
    _new_button.name = "NextColorButton"
    _new_button.pressed.connect(_new_round)
    _button_labels.append(_action_button_content(_reset_button, true))
    _button_labels.append(_action_button_content(_new_button, false))

    for i in range(REAGENTS.size()):
        var column: int = i % 2
        var row: int = int(i / 2) % 3
        var on_right: bool = i >= 6
        var x: float = (1112.0 if on_right else 26.0) + float(column) * 185.0
        var y: float = 126.0 + float(row) * 175.0
        var card := _panel("Reagent_%s" % str(REAGENTS[i].id), Vector2(x,y), Vector2(175,156), _board)
        card.add_theme_stylebox_override("panel", _card_style())
        card.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var vessel: Node2D = VESSEL.new() as Node2D
        card.add_child(vessel)
        vessel.call("configure", i % 5, Color(str(REAGENTS[i].hex)), 0.79)
        vessel.scale = Vector2.ONE * float(vessel.call("fit_scale", 105.0, 100.0))
        vessel.position = Vector2(87.5, 60.0)
        var name := _label("", 17, Color.WHITE, card)
        name.position = Vector2(8, 119)
        name.size = Vector2(159, 28)
        _cards.append(card)
        _vessels.append(vessel)
        _card_labels.append(name)

    _ghost = VESSEL.new() as Node2D
    _ghost.name = "DragPreview"
    _ghost.scale = Vector2.ONE * 0.24
    _ghost.z_index = 80
    _ghost.visible = false
    _board.add_child(_ghost)

    _sfx = AudioStreamPlayer.new()
    _sfx.name = "LabSound"
    _sfx.volume_db = -8.0
    add_child(_sfx)
    _voice_player = AudioStreamPlayer.new()
    _voice_player.name = "RecordedColorVoice"
    if AudioServer.get_bus_index("VOICE") >= 0:
        _voice_player.bus = "VOICE"
    add_child(_voice_player)

func _claim_toolbar_navigation() -> void:
    # Planet Hub and Simulator mount mini-games in a SubViewport, but render
    # their own Back buttons OUTSIDE the SubViewport. Those would otherwise
    # appear at the wrong location or duplicate our correctly aligned button.
    if not is_inside_tree():
        return
    var host_root: Node = get_tree().root
    for node_name in ["ReturnToExistingPlanetCards", "ReturnToEducationalCards"]:
        for item in host_root.find_children(node_name, "Button", true, false):
            var host_button: Button = item as Button
            if host_button == null or host_button == _back:
                continue
            if _host_back_buttons.has(host_button):
                continue
            if not host_button.is_visible_in_tree():
                continue
            _host_back_buttons.append(host_button)
            _host_back_visibility.append(host_button.visible)
            host_button.hide()

func _exit_tree() -> void:
    for i in range(_host_back_buttons.size()):
        var button: Button = _host_back_buttons[i]
        if is_instance_valid(button):
            button.visible = _host_back_visibility[i]
    _host_back_buttons.clear()
    _host_back_visibility.clear()

func _label(value: String, font_size: int, tint: Color, parent: Node) -> Label:
    var l := Label.new()
    l.text = value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", tint)
    l.add_theme_color_override("font_outline_color", Color("#06152d"))
    l.add_theme_constant_override("outline_size", 2)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    l.clip_text = true
    parent.add_child(l)
    return l

func _panel(node_name: String, pos: Vector2, panel_size: Vector2, parent: Node) -> Panel:
    var panel := Panel.new()
    panel.name = node_name
    panel.position = pos
    panel.size = panel_size
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.028, 0.13, 0.27, 0.94)
    style.border_color = Color("#5be5ff")
    style.set_border_width_all(2)
    style.set_corner_radius_all(20)
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)
    return panel

func _card_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.065,0.19,0.33,0.91)
    style.border_color = Color(0.35,0.84,1.0,0.75)
    style.set_border_width_all(2)
    style.set_corner_radius_all(20)
    style.shadow_color = Color(0.02,0.50,0.79,0.23)
    style.shadow_size = 4
    return style

func _make_button(pos: Vector2, button_size: Vector2) -> Button:
    var b := Button.new()
    b.position = pos
    b.size = button_size
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_stylebox_override("normal", UI_KIT.button_style())
    b.add_theme_stylebox_override("hover", UI_KIT.button_style(true))
    b.add_theme_stylebox_override("pressed", UI_KIT.button_style(true))
    b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    b.add_theme_font_size_override("font_size", 18)
    _board.add_child(b)
    return b

func _action_button_content(button: Button, restart: bool) -> Label:
    button.text = ""
    var glyph: Control = ACTION_GLYPH.new() as Control
    glyph.set("restart", restart)
    glyph.size = Vector2(32,32)
    glyph.position = Vector2(12, (button.size.y - 32.0) * 0.5) if restart else Vector2(button.size.x - 44.0, (button.size.y - 32.0) * 0.5)
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    button.add_child(glyph)
    var caption := _label("", 17, Color.WHITE, button)
    caption.position = Vector2(47, 0) if restart else Vector2(8, 0)
    caption.size = Vector2(button.size.x - 57.0, button.size.y) if restart else Vector2(button.size.x - 58.0, button.size.y)
    return caption

func _safe_area() -> Rect2:
    var viewport_size: Vector2 = size
    if OS.get_name() not in ["Android", "iOS"]:
        return Rect2(Vector2.ZERO, viewport_size)
    var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
    var safe: Rect2i = DisplayServer.get_display_safe_area()
    if window_size.x < 50.0 or window_size.y < 50.0 or safe.size.x < 50:
        return Rect2(Vector2.ZERO, viewport_size)
    return Rect2(Vector2(safe.position) * (viewport_size / window_size), Vector2(safe.size) * (viewport_size / window_size))

func _layout() -> void:
    if _board == null or size.x < 260.0 or size.y < 220.0:
        return
    var safe: Rect2 = _safe_area()
    var header_bottom: float = TOOLBAR.relayout(size, safe, _back, _native_counter, _header, _header_title, _header_subtitle)
    var margin: float = clampf(safe.size.x * 0.015, 8.0, 26.0)
    var gap: float = clampf(safe.size.y * 0.015, 5.0, 14.0)
    var board_height: float = maxf(125.0, safe.end.y - header_bottom - gap - margin)
    _shell.position = Vector2(safe.position.x + margin, header_bottom + gap)
    _shell.size = Vector2(maxf(220.0, safe.size.x - margin * 2.0), board_height)
    # No full-screen image and no blue film: only the rounded stage is filled.
    _background.position = Vector2(3.0, 3.0)
    _background.size = (_shell.size - Vector2(6.0, 6.0)).max(Vector2.ONE)
    var crop_material: ShaderMaterial = _background.material as ShaderMaterial
    if crop_material != null:
        crop_material.set_shader_parameter("rect_dimensions", _background.size)
    var s: float = minf((_shell.size.x - 14.0) / BOARD_SIZE.x, (_shell.size.y - 14.0) / BOARD_SIZE.y)
    s = maxf(0.08, s)
    _board.scale = Vector2.ONE * s
    _board.position = (_shell.size - BOARD_SIZE * s) * 0.5

func _read_language() -> void:
    var language: String = "en"
    var service: Node = get_node_or_null("/root/LanguageService")
    if service != null:
        language = str(service.get("learning_locale")).to_lower()
        if language.is_empty() or language == "null" or language == "<null>":
            language = str(service.get("interface_locale")).to_lower()
        if service.has_signal("language_changed") and not service.is_connected("language_changed", Callable(self, "_language_changed")):
            service.connect("language_changed", Callable(self, "_language_changed"))
    _locale = language.substr(0,2)
    if not WORDS.has(_locale):
        _locale = "en"
    _refresh_language()

func _language_changed(_new_locale: String) -> void:
    _read_language()
    if _recipe_index >= 0:
        _speak_target()

func _w(key: String) -> String:
    var section: Dictionary = WORDS.get(_locale, WORDS["en"])
    return str(section.get(key, key))

func _color_name(id: String) -> String:
    var names: Array = COLORS.get(id, [id,id,id,id,id,id])
    var index: int = LANG_ORDER.find(_locale)
    return str(names[maxi(0,index)])

func _refresh_language() -> void:
    if _header_title == null:
        return
    _header_title.text = _w("title")
    _header_subtitle.text = _w("subtitle")
    _target_title.text = _w("goal")
    _target_title.add_theme_font_size_override("font_size", 17 if _target_title.text.length() > 28 else 21)
    _ingredient_title.text = _w("components")
    _button_labels[0].text = _w("restart")
    _button_labels[1].text = _w("new")
    for caption in _button_labels:
        caption.add_theme_font_size_override("font_size", 14 if caption.text.length() > 13 else 17)
    for i in range(_card_labels.size()):
        _card_labels[i].text = _color_name(str(REAGENTS[i].id)).capitalize()
    if _recipe_index >= 0:
        _target_name.text = _color_name(str(RECIPES[_recipe_index].id)).to_upper()
    _set_status("drag")
    _layout()

func _new_round() -> void:
    if _locked:
        return
    if _cursor >= _queue.size():
        _queue.clear()
        for i in range(RECIPES.size()):
            _queue.append(i)
        # Fisher-Yates with a per-session randomized generator: both the
        # opening target and every Next Color are randomly selected.
        # A bag visits all 28 recipes before reusing any one of them.
        for i in range(_queue.size() - 1, 0, -1):
            var j: int = _rng.randi_range(0, i)
            var temporary: int = _queue[i]
            _queue[i] = _queue[j]
            _queue[j] = temporary
        if _queue.size() > 1 and _queue[0] == _recipe_index:
            var swap_with: int = _rng.randi_range(1, _queue.size() - 1)
            var temporary: int = _queue[0]
            _queue[0] = _queue[swap_with]
            _queue[swap_with] = temporary
        _cursor = 0
    _recipe_index = _queue[_cursor]
    _cursor += 1
    _restart_same()
    var recipe: Dictionary = RECIPES[_recipe_index]
    _target_name.text = _color_name(str(recipe.id)).to_upper()
    _target_chip.add_theme_stylebox_override("panel", _swatch_style(Color(str(recipe.hex))))
    var needs: Array = recipe.needs
    for i in range(_indicators.size()):
        var item: Panel = _indicators[i]
        item.visible = i < needs.size()
        if item.visible:
            item.add_theme_stylebox_override("panel", _swatch_style(_reagent_color(str(needs[i]))))
    _ingredient_count.text = "0 / %d" % needs.size()
    call_deferred("_speak_target")

func _restart_same() -> void:
    if _locked or _recipe_index < 0:
        return
    _selected.clear()
    _mixed_color = Color.WHITE
    _mixed_fill = 0.0
    _mixer.call("configure", 0, Color.WHITE, 0.0)
    _ghost.visible = false
    _tracking = -1
    _touch_index = -1
    for card in _cards:
        card.add_theme_stylebox_override("panel", _card_style())
    _ingredient_count.text = "0 / %d" % (RECIPES[_recipe_index].needs as Array).size()
    _set_status("drag")

func _swatch_style(tint: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = tint
    style.border_color = Color.WHITE
    style.set_border_width_all(4)
    style.set_corner_radius_all(18)
    style.shadow_color = tint.darkened(0.30)
    style.shadow_size = 7
    return style

func _reagent_color(id: String) -> Color:
    for entry in REAGENTS:
        if str(entry.id) == id:
            return Color(str(entry.hex))
    return Color.WHITE

func _input(event: InputEvent) -> void:
    if _locked:
        return
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and _tracking < 0:
            _start_tracking(touch.position, true, touch.index)
        elif not touch.pressed:
            _finish_tracking(touch.position, true, touch.index)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if _tracking >= 0 and _drag_touch and drag.index == _touch_index:
            _move_tracking(drag.position)
    elif event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed and _tracking < 0:
                _start_tracking(mouse.position, false, -1)
            elif not mouse.pressed:
                _finish_tracking(mouse.position, false, -1)
    elif event is InputEventMouseMotion and _tracking >= 0 and not _drag_touch:
        _move_tracking((event as InputEventMouseMotion).position)

func _board_point(p: Vector2) -> Vector2:
    return _board.get_global_transform_with_canvas().affine_inverse() * p

func _start_tracking(pos: Vector2, is_touch: bool, index: int) -> void:
    var p: Vector2 = _board_point(pos)
    for i in range(_cards.size()-1,-1,-1):
        if Rect2(_cards[i].position, _cards[i].size).has_point(p):
            _tracking = i
            _drag_touch = is_touch
            _touch_index = index
            _pointer_origin = p
            _ghost.visible = false
            get_viewport().set_input_as_handled()
            return

func _move_tracking(pos: Vector2) -> void:
    if _tracking < 0:
        return
    var point: Vector2 = _board_point(pos)
    if point.distance_to(_pointer_origin) >= 14.0:
        var paint: Dictionary = REAGENTS[_tracking]
        _ghost.call("configure", _tracking % 5, Color(str(paint.hex)), 0.78)
        var ghost_scale: float = float(_ghost.call("fit_scale", 140.0, 155.0))
        _ghost.scale = Vector2.ONE * ghost_scale
        _ghost.position = point
        _ghost.visible = true
    get_viewport().set_input_as_handled()

func _finish_tracking(pos: Vector2, is_touch: bool, index: int) -> void:
    if _tracking < 0 or _drag_touch != is_touch or (is_touch and index != _touch_index):
        return
    var reagent_index: int = _tracking
    var end_point: Vector2 = _board_point(pos)
    var traveled: float = end_point.distance_to(_pointer_origin)
    _tracking = -1
    _touch_index = -1
    _ghost.visible = false
    get_viewport().set_input_as_handled()
    # A short tap pours immediately. A drag must reach the middle flask.
    if traveled < 30.0 or end_point.distance_to(MIX_CENTER) < 160.0:
        _pour_reagent(reagent_index)

func _pour_reagent(index: int) -> void:
    if _locked or _recipe_index < 0 or index < 0 or index >= REAGENTS.size():
        return
    var reagent: Dictionary = REAGENTS[index]
    var id: String = str(reagent.id)
    if _selected.has(id):
        _set_status("used")
        return
    _locked = true
    _speak_color(id, int(reagent.voice), false)
    var pour_vessel: Node2D = VESSEL.new() as Node2D
    pour_vessel.name = "AnimatedPouringReagent"
    pour_vessel.z_index = 20
    _board.add_child(pour_vessel)
    pour_vessel.call("configure", index % 5, Color(str(reagent.hex)), 0.79)
    var vessel_scale: float = float(pour_vessel.call("fit_scale", 105.0, 100.0))
    pour_vessel.scale = Vector2.ONE * vessel_scale
    pour_vessel.position = _cards[index].position + Vector2(87.5,60.0)
    var from_left: bool = index < 6
    var angle: float = 52.0 if from_left else -52.0
    # The opening moves onto the mixer's x axis when tilted. The stream then
    # falls STRAIGHT DOWN; it must never connect two off-axis points diagonally.
    var neck_y: float = float(pour_vessel.call("half_height")) * 0.94
    var neck_shift: float = neck_y * sin(deg_to_rad(angle))
    var destination := Vector2(MIX_CENTER.x - neck_shift, MIX_CENTER.y - 253.0)
    var incoming := create_tween().set_parallel(true)
    incoming.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    incoming.tween_property(pour_vessel,"position",destination,0.37)
    incoming.tween_property(pour_vessel,"rotation_degrees",angle,0.37)
    await incoming.finished
    var pouring_neck: Vector2 = pour_vessel.transform * Vector2(0.0, -neck_y / vessel_scale)
    var pour_x: float = MIX_CENTER.x
    var mixer_lip_y: float = MIX_CENTER.y - float(_mixer.call("half_height")) + 7.0
    var stream := Line2D.new()
    stream.name = "VerticalLiquidStream"
    stream.width = 8.0
    stream.default_color = Color(str(reagent.hex))
    stream.begin_cap_mode = Line2D.LINE_CAP_ROUND
    stream.end_cap_mode = Line2D.LINE_CAP_ROUND
    stream.points = PackedVector2Array([Vector2(pour_x, pouring_neck.y + 7.0), Vector2(pour_x, mixer_lip_y)])
    stream.z_index = 30
    _board.add_child(stream)
    var from_color: Color = _mixed_color
    var to_color: Color = _reagent_color(id) if _selected.is_empty() else _mixed_color.lerp(_reagent_color(id),0.5)
    var new_ids: Array[String] = _selected.duplicate()
    new_ids.append(id)
    var recipe: Dictionary = RECIPES[_recipe_index]
    if _matches(new_ids,recipe.needs):
        to_color = Color(str(recipe.hex))
    var to_fill: float = minf(0.80, (float(new_ids.size())/float((recipe.needs as Array).size()))*0.80)
    var t := create_tween()
    t.tween_method(Callable(self,"_mix_progress").bind(from_color,to_color,_mixed_fill,to_fill),0.0,1.0,0.56)
    await t.finished
    _mixed_color = to_color
    _mixed_fill = to_fill
    _mixer.call("configure",0,_mixed_color,_mixed_fill)
    stream.queue_free()
    pour_vessel.queue_free()
    _selected.append(id)
    _ingredient_count.text = "%d / %d" % [_selected.size(),(recipe.needs as Array).size()]
    var used_style := _card_style()
    used_style.border_color = Color("#ffda73")
    _cards[index].add_theme_stylebox_override("panel",used_style)
    if _selected.size() < (recipe.needs as Array).size():
        _locked = false
        _set_status("next")
    elif _matches(_selected,recipe.needs):
        await _success()
    else:
        await _wrong_mix()

func _mix_progress(t: float, before: Color, after: Color, initial: float, target: float) -> void:
    var color: Color = before.lerp(after,t)
    var amount: float = lerpf(initial,target,t)
    _mixer.call("configure",0,color,amount)

func _matches(picks: Array, needs: Array) -> bool:
    if picks.size() != needs.size():
        return false
    var a: Array[String] = []
    var b: Array[String] = []
    for v in picks:
        a.append(str(v))
    for v in needs:
        b.append(str(v))
    a.sort()
    b.sort()
    return a == b

func _success() -> void:
    var recipe: Dictionary = RECIPES[_recipe_index]
    _mixer.call("configure",0,Color(str(recipe.hex)),0.80)
    _set_status("great")
    _play_sfx(SUCCESS_SOUND)
    _crystals += 1
    _native_counter.set("crystal_count",_crystals)
    var game_state: Node = get_node_or_null("/root/GameState")
    if game_state != null and game_state.has_method("add_coins"):
        game_state.call("add_coins",1)
    var pop := create_tween()
    var previous_scale: Vector2 = _mixer.scale
    pop.tween_property(_mixer,"scale",previous_scale*1.08,0.18)
    pop.tween_property(_mixer,"scale",previous_scale,0.21)
    await pop.finished
    await get_tree().create_timer(0.95).timeout
    _locked = false
    _new_round()

func _wrong_mix() -> void:
    _set_status("retry")
    _play_sfx(RETRY_SOUND)
    await get_tree().create_timer(1.0).timeout
    _locked = false
    _restart_same()

func _play_sfx(audio: AudioStream) -> void:
    _sfx.stop()
    _sfx.stream = audio
    _sfx.play()

func _set_status(key: String) -> void:
    if _status == null:
        return
    _status.text = _w(key)
    _status.add_theme_color_override("font_color", Color("#ffe49a") if key == "used" or key == "retry" else Color("#d8f6ff"))

func _speak_target() -> void:
    if _recipe_index < 0 or not is_inside_tree():
        return
    var recipe: Dictionary = RECIPES[_recipe_index]
    var id: String = str(recipe.id)
    # Existing PlayTown voice clips are kept; new shades fall back to MikaVoice.
    var voice_idx: int = -1
    for reagent in REAGENTS:
        if str(reagent.id) == id:
            voice_idx = int(reagent.voice)
            break
    _speak_color(id,voice_idx,true)

func _speak_color(id: String, voice_index: int, target: bool) -> void:
    var service: Node = get_node_or_null("/root/LanguageService")
    if voice_index >= 0 and service != null and service.has_method("get_color_voice"):
        var recorded: Variant = service.call("get_color_voice",voice_index)
        if recorded is AudioStream:
            var voice: Node = get_node_or_null("/root/MikaVoice")
            if voice != null and voice.has_method("stop"):
                voice.call("stop")
            _voice_player.stop()
            _voice_player.stream = recorded as AudioStream
            _voice_player.play()
            return
    _voice_player.stop()
    var tts: Node = get_node_or_null("/root/MikaVoice")
    if tts == null or not tts.has_method("speak_text"):
        return
    var color: String = _color_name(id)
    var phrase: String = color
    if target:
        match _locale:
            "ru": phrase = "Получи раствор цвета: " + color
            "pt": phrase = "Prepare uma solução da cor " + color
            "es": phrase = "Prepara una solución de color " + color
            "de": phrase = "Stelle eine Lösung in dieser Farbe her: " + color
            "fr": phrase = "Prépare une solution de couleur " + color
            _: phrase = "Make a solution this color: " + color
    tts.call("speak_text",phrase,"pt_BR" if _locale == "pt" else _locale,"phase")

func _go_back() -> void:
    var portal: Node = get_node_or_null("/root/PlayTownPortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "")
        return
    var parent_node: Node = get_parent()
    for i in range(16):
        if parent_node == null:
            break
        if parent_node.has_method("_v1051_return_to_cards"):
            parent_node.call("_v1051_return_to_cards")
            return
        if parent_node.has_method("_return_to_cards"):
            parent_node.call("_return_to_cards")
            return
        parent_node = parent_node.get_parent()
    var fallback := "res://education/playtown/scenes/screens/game_select_school.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _go_back()
        get_viewport().set_input_as_handled()

func debug_recipe_valid(recipe_id: String, picks: Array) -> bool:
    for recipe in RECIPES:
        if str(recipe.id) == recipe_id:
            return _matches(picks,recipe.needs)
    return false
