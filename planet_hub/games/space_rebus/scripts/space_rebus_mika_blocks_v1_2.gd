extends Control
## MIKA Space Rebus Blocks v1.2 — four visible choice cards, Hint button and
## a real animated cosmic background inside the main play block. Language is
## taken from the Simulator/main menu, so there is no local language switch.

const DATA_PATH := "res://planet_hub/games/space_rebus/data/block_puzzles_mika_v1.json"
const SHARED := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD := preload("res://planet_hub/scripts/bottom_hud.gd")
const BACK_GLYPH := preload("res://simulator_ui/back_arrow_glyph.gd")
const REAL_SPACE := preload("res://simulator_ui/scripts/real_space_background.gd")
const LANGS := ["ru", "en", "pt", "es", "de", "fr"]
const VISIBLE_CHOICES := 4
const COPY := {
    "ru": ["КОСМИЧЕСКИЕ РЕБУСЫ", "Собери слово из картинок и букв", "СОБЕРИ СЛОВО", "ВЫБЕРИ КАРТОЧКУ И ПЕРЕНЕСИ В ЯЧЕЙКУ", "Всё верно!", "Попробуй изменить порядок", "ВСЕ ПЯТЬ РЕБУСОВ РЕШЕНЫ", "Нажми здесь, чтобы сыграть снова", "ПОДСКАЗКА", "ПОКАЗАТЬ СЛОВО"],
    "en": ["SPACE REBUS ADVENTURES", "Build words from pictures and letters", "BUILD THE WORD", "TAP A CARD, THEN A SLOT — OR DRAG IT", "Well done!", "Try another order", "ALL FIVE PUZZLES SOLVED", "Tap here to play again", "HINT", "SHOW WORD"],
    "pt": ["REBUS ESPACIAIS", "Monte palavras com figuras e letras", "MONTE A PALAVRA", "TOQUE NO BLOCO E NO ESPAÇO, OU ARRASTE", "Muito bem!", "Tente outra ordem", "CINCO DESAFIOS RESOLVIDOS", "Toque aqui para jogar de novo", "DICA", "MOSTRAR PALAVRA"],
    "es": ["REBUS ESPACIALES", "Forma palabras con imágenes y letras", "FORMA LA PALABRA", "TOCA UNA FICHA Y UN HUECO, O ARRASTRA", "¡Muy bien!", "Prueba otro orden", "CINCO ACERTIJOS RESUELTOS", "Toca aquí para jugar otra vez", "PISTA", "MOSTRAR PALABRA"],
    "de": ["WELTRAUM-BILDERRÄTSEL", "Baue Wörter aus Bildern und Buchstaben", "BAUE DAS WORT", "KARTE WÄHLEN UND IN EIN FELD ZIEHEN", "Sehr gut!", "Versuche eine andere Reihenfolge", "ALLE FÜNF RÄTSEL GELÖST", "Hier tippen, um neu zu starten", "HINWEIS", "WORT ZEIGEN"],
    "fr": ["RÉBUS DE L’ESPACE", "Construis des mots avec images et lettres", "CONSTRUIS LE MOT", "TOUCHE UNE CARTE PUIS UNE CASE, OU GLISSE", "Bravo !", "Essaie un autre ordre", "CINQ RÉBUS RÉSOLUS", "Touche ici pour recommencer", "INDICE", "MONTRER LE MOT"]
}

var _puzzles: Dictionary = {}
var _deck: Array = []
var _locale: String = "en"
var _level: int = 0
var _earned: int = 0
var _settled: bool = false
var _solved: bool = false
var _finished: bool = false
var _success_delay: float = 0.0
var _wrong_delay: float = 0.0
var _elapsed: float = 0.0
var _cards: Array = []
var _required: Array = []
var _slots: Array = []
var _choice_rects: Array[Rect2] = []
var _slot_rects: Array[Rect2] = []
var _hint_rect: Rect2 = Rect2()
var _replay_rect: Rect2 = Rect2()
var _stage: Rect2 = Rect2()
var _show_hint: bool = false
var _stage_space_holder: Control
var _stage_space: Control
var _active_card: int = -1
var _drag_start: Vector2 = Vector2.ZERO
var _drag_at: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _font: Font
var _textures: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _header_layer: CanvasLayer
var _header_root: Control
var _toolbar_back: Button
var _toolbar_hud: Control
var _toolbar_title_panel: Panel
var _toolbar_title: Label
var _toolbar_subtitle: Label
var _host: Node = null
var _host_back: Control = null
var _host_back_visible: bool = false
var _sfx: AudioStreamPlayer


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_STOP
    _rng.randomize()
    _font = ThemeDB.fallback_font
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    if raw is Dictionary:
        _puzzles = raw
    _detect_locale()
    _build_header()
    _build_stage_background()
    _sfx = AudioStreamPlayer.new()
    _sfx.name = "OriginalSpaceRebusPositiveNegativeSfx"
    _sfx.process_mode = Node.PROCESS_MODE_ALWAYS
    _sfx.bus = "SFX"
    add_child(_sfx)
    _host = _find_simulator_host()
    if _host != null:
        var candidate: Variant = _host.get("_game_back")
        if candidate is Control:
            _host_back = candidate as Control
            _host_back_visible = _host_back.visible
            _host_back.hide()
            _host_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _start_game(true)
    get_viewport().size_changed.connect(_relayout)
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        mobile.connect("language_changed", Callable(self, "_on_mobile_language_changed"))
    _relayout()



func _build_stage_background() -> void:
    _stage_space_holder = Control.new()
    _stage_space_holder.name = "RebusCosmicStageHolder"
    _stage_space_holder.clip_contents = true
    _stage_space_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _stage_space_holder.z_index = -8
    add_child(_stage_space_holder)
    _stage_space = REAL_SPACE.new() as Control
    _stage_space.name = "RebusCosmicStageBackground"
    _stage_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _stage_space.z_index = -8
    _stage_space_holder.add_child(_stage_space)
    _stage_space.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _exit_tree() -> void:
    _settle_rewards()
    if is_instance_valid(_host_back):
        _host_back.visible = _host_back_visible
        _host_back.mouse_filter = Control.MOUSE_FILTER_STOP


func _find_simulator_host() -> Node:
    var walker: Node = get_parent()
    for _i in range(24):
        if walker == null:
            break
        if walker.has_method("_return_to_cards"):
            return walker
        walker = walker.get_parent()
    return null


func _settle_rewards() -> void:
    if _settled:
        return
    _settled = true
    if _earned > 0 and is_instance_valid(_host) and _host.has_signal("crystals_earned"):
        _host.emit_signal("crystals_earned", mini(_earned, 50))


func _on_back_pressed() -> void:
    _settle_rewards()
    if is_instance_valid(_host):
        _host.call("_return_to_cards")
    else:
        get_tree().change_scene_to_file("res://scenes/main.tscn")


func _detect_locale() -> void:
    var chosen := "en"
    var service: Node = get_node_or_null("/root/LanguageService")
    if service != null:
        var value: Variant = service.get("learning_locale")
        if value != null:
            chosen = str(value)
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if not LANGS.has(chosen) and mobile != null:
        chosen = str(mobile.get("language"))
    chosen = chosen.replace("pt_BR", "pt")
    _locale = chosen if LANGS.has(chosen) else "en"


func _on_mobile_language_changed(_new_locale: String) -> void:
    # Preserve the active educational language unless it actually changes.
    var prev: String = _locale
    _detect_locale()
    if prev != _locale:
        _start_game(false)
        _relayout()


func _build_header() -> void:
    _header_layer = CanvasLayer.new()
    _header_layer.name = "MikaSpaceRebusSharedHeaderLayer"
    _header_layer.layer = 4
    add_child(_header_layer)
    _header_root = Control.new()
    _header_root.name = "MikaSpaceRebusHeaderLayout"
    _header_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header_layer.add_child(_header_root)
    _toolbar_back = Button.new()
    _toolbar_back.name = "MikaSpaceRebusToolbarBack"
    _toolbar_back.text = ""
    _toolbar_back.focus_mode = Control.FOCUS_NONE
    _toolbar_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _toolbar_back.add_theme_stylebox_override("normal", _skin(Color("#091c39"), Color("#5fe9ff"), 19, 2))
    _toolbar_back.add_theme_stylebox_override("hover", _skin(Color("#164066"), Color("#bbf8ff"), 19, 2))
    _toolbar_back.add_theme_stylebox_override("pressed", _skin(Color("#1b5070"), Color("#e3ffff"), 19, 2))
    _toolbar_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _toolbar_back.pressed.connect(_on_back_pressed)
    _header_root.add_child(_toolbar_back)
    var glyph: Control = BACK_GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _toolbar_back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _toolbar_hud = HUD.new() as Control
    _toolbar_hud.name = "OriginalMIKACrystalCounter"
    _toolbar_hud.size = Vector2(1680.0, 158.0)
    _toolbar_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _header_root.add_child(_toolbar_hud)
    var sim: Control = _toolbar_hud.get_node_or_null("SimulatorButton") as Control
    var flight: Control = _toolbar_hud.get_node_or_null("LaunchButton") as Control
    if sim != null: sim.hide()
    if flight != null: flight.hide()
    _toolbar_hud.set("crystal_count", 0)
    _toolbar_title_panel = Panel.new()
    _toolbar_title_panel.name = "MIKARebusSharedTitle"
    _toolbar_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    SHARED.apply_title_style(_toolbar_title_panel)
    _header_root.add_child(_toolbar_title_panel)
    _toolbar_title = _header_label(Color("#effdff"))
    _toolbar_subtitle = _header_label(Color("#b5e4f5"))
    _toolbar_title_panel.add_child(_toolbar_title)
    _toolbar_title_panel.add_child(_toolbar_subtitle)


func _header_label(color: Color) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.clip_text = true
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", Color("#07152b"))
    label.add_theme_constant_override("outline_size", 2)
    return label


func _skin(fill: Color, border: Color, radius: int, thick: int = 2) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.anti_aliasing = true
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(thick)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(0.10, 0.45, 0.9, 0.18)
    style.shadow_size = 5
    return style


func _copy(index: int) -> String:
    var captions: Array = COPY.get(_locale, COPY["en"])
    return str(captions[index])


func _start_game(reset_score: bool) -> void:
    if reset_score:
        _earned = 0
        _settled = false
    _deck = _puzzles.get(_locale, [])
    _level = 0
    _show_hint = false
    _finished = _deck.is_empty()
    if not _finished:
        _start_puzzle()
    if _toolbar_hud != null:
        _toolbar_hud.set("crystal_count", _earned)
    _relayout()


func _start_puzzle() -> void:
    _solved = false
    _finished = false
    _success_delay = 0.0
    _wrong_delay = 0.0
    _active_card = -1
    _dragging = false
    _show_hint = false
    var puzzle: Dictionary = _current()
    # Godot JSON may deserialize numbers as floating-point Variants. Normalize
    # every required source ID before validation (card source IDs are ints).
    _required = []
    for source_id in puzzle.get("required", []):
        _required.append(int(source_id))
    var source_cards: Array = puzzle.get("pieces", []).duplicate(true)
    var keep_ids: Array = []
    for source_id in _required:
        if not keep_ids.has(int(source_id)):
            keep_ids.append(int(source_id))
    for original_index in range(source_cards.size()):
        if keep_ids.size() >= VISIBLE_CHOICES:
            break
        if not keep_ids.has(original_index):
            keep_ids.append(original_index)
    keep_ids.sort()
    _cards = []
    for original_index in keep_ids:
        var card: Dictionary = source_cards[int(original_index)].duplicate(true)
        card["source_id"] = int(original_index)
        _cards.append(card)
    _cards.shuffle()
    _slots.clear()
    for _i in range(_required.size()):
        _slots.append(-1)
    queue_redraw()


func _current() -> Dictionary:
    if _level < 0 or _level >= _deck.size():
        return {}
    return _deck[_level]


func _relayout() -> void:
    var view: Vector2 = get_viewport_rect().size
    if view.x < 100 or view.y < 100 or _toolbar_back == null:
        return
    _header_root.size = view
    _toolbar_title.text = _copy(0)
    _toolbar_subtitle.text = _copy(1)
    var safe: Rect2 = _safe_rect(view)
    var header_bottom: float = SHARED.relayout(view, safe, _toolbar_back, _toolbar_hud, _toolbar_title_panel, _toolbar_title, _toolbar_subtitle)
    var margin: float = clampf(safe.size.x * 0.012, 7.0, 23.0)
    var top: float = header_bottom + clampf(safe.size.y * 0.018, 6.0, 17.0)
    var bottom: float = safe.end.y - clampf(safe.size.y * 0.016, 6.0, 18.0)
    _stage = Rect2(Vector2(safe.position.x + margin, top), Vector2(maxf(90, safe.size.x - margin * 2.0), maxf(90, bottom - top)))
    _slot_rects.clear()
    _choice_rects.clear()
    var required_count: int = _slots.size()
    var box_gap: float = clampf(_stage.size.x * 0.018, 5.0, 24.0)
    var total_width: float = _stage.size.x * 0.87
    var slot_w: float = minf(_stage.size.x * 0.225, (total_width - box_gap * maxf(0, required_count - 1)) / maxf(1, required_count))
    var slot_h: float = _stage.size.y * 0.235
    var slot_start: float = _stage.get_center().x - (slot_w * required_count + box_gap * (required_count - 1)) * 0.5
    for index in range(required_count):
        _slot_rects.append(Rect2(slot_start + float(index) * (slot_w + box_gap), _stage.position.y + _stage.size.y * 0.30, slot_w, slot_h))
    var choice_margin: float = _stage.size.x * 0.055
    var gap: float = clampf(_stage.size.x * 0.014, 6.0, 20.0)
    var visible_cards: int = maxi(1, _cards.size())
    var card_w: float = (_stage.size.x - 2.0 * choice_margin - float(visible_cards - 1) * gap) / float(visible_cards)
    var card_h: float = _stage.size.y * 0.26
    for index in range(visible_cards):
        _choice_rects.append(Rect2(_stage.position.x + choice_margin + float(index) * (card_w + gap), _stage.position.y + _stage.size.y * 0.658, card_w, card_h))
    _hint_rect = Rect2(_stage.end.x - clampf(_stage.size.x * 0.16, 96.0, 172.0), _stage.position.y + _stage.size.y * 0.036, clampf(_stage.size.x * 0.14, 88.0, 160.0), clampf(_stage.size.y * 0.095, 32.0, 54.0))
    _replay_rect = Rect2(_stage.get_center().x - _stage.size.x * 0.20, _stage.position.y + _stage.size.y * 0.63, _stage.size.x * 0.40, _stage.size.y * 0.18)
    if _stage_space_holder != null:
        var stage_inner: Rect2 = _stage.grow(-maxf(3.0, _stage.size.y * 0.014))
        _stage_space_holder.position = stage_inner.position
        _stage_space_holder.size = stage_inner.size
        if _stage_space != null:
            _stage_space.position = Vector2.ZERO
            _stage_space.size = stage_inner.size
            _stage_space.modulate = Color(1.0, 1.0, 1.0, 0.95)
    queue_redraw()


func _safe_rect(view: Vector2) -> Rect2:
    if not OS.has_feature("mobile"):
        return Rect2(Vector2.ZERO, view)
    var size_px: Vector2 = Vector2(DisplayServer.window_get_size())
    var physical: Rect2i = DisplayServer.get_display_safe_area()
    if size_px.x < 1 or size_px.y < 1 or physical.size.x < 1 or physical.size.y < 1:
        return Rect2(Vector2.ZERO, view)
    var s: Vector2 = view / size_px
    return Rect2(Vector2(physical.position) * s, Vector2(physical.size) * s)


func _process(delta: float) -> void:
    _elapsed += delta
    if _wrong_delay > 0.0:
        _wrong_delay = maxf(0.0, _wrong_delay - delta)
        if _wrong_delay == 0.0:
            queue_redraw()
    if _success_delay > 0.0:
        _success_delay -= delta
        if _success_delay <= 0.0:
            _level += 1
            if _level >= _deck.size():
                _finished = true
                _solved = false
                _active_card = -1
                queue_redraw()
            else:
                _start_puzzle()


func _draw() -> void:
    var view: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, view), Color("#040d20"))
    if _stage.size.x < 80.0:
        return
    draw_circle(Vector2(view.x * 0.14, view.y * 0.47), minf(view.x, view.y) * 0.38, Color(0.15, 0.07, 0.29, 0.12))
    draw_circle(Vector2(view.x * 0.84, view.y * 0.67), minf(view.x, view.y) * 0.29, Color(0.04, 0.22, 0.35, 0.09))
    _rounded(_stage, Color("#142b50"), Color("#63c9e8"), 25, 3)
    var inner: Rect2 = _stage.grow(-maxf(3.0, _stage.size.y * 0.014))
    _rounded(inner, Color(0.02, 0.05, 0.13, 0.42), Color(0.16, 0.38, 0.62, 0.55), 20, 1)
    var scale: float = minf(_stage.size.x / 1150.0, _stage.size.y / 570.0)
    var heading_y: float = _stage.position.y + _stage.size.y * 0.117
    var heading_font: int = maxi(15, roundi(clampf(28.0 * scale, 15.0, 31.0)))
    _center(_copy(2), Rect2(_stage.position.x + 16.0, heading_y - heading_font, _stage.size.x - 32.0, heading_font * 1.25), heading_font, Color("#e9fbff"))
    var badge_font: int = maxi(10, roundi(16.0 * scale))
    _rounded(_hint_rect, Color("#18365a"), Color("#5ed7ec"), 11, 2)
    _center(_copy(8), _hint_rect, maxi(12, roundi(badge_font * 1.15)), Color("#d6ffff"))
    if _finished:
        _center(_copy(6), Rect2(_stage.position.x + 8, _stage.position.y + _stage.size.y * 0.31, _stage.size.x - 16, 48.0), maxi(15, roundi(heading_font * 0.85)), Color("#96f7c6"))
        _rounded(_replay_rect, Color("#1d5875"), Color("#8df4ff"), 18, 3)
        _center(_copy(7), _replay_rect, maxi(12, roundi(20.0 * scale)), Color.WHITE)
        return
    if _deck.is_empty():
        return
    var progress: String = "%d / %d" % [_level + 1, _deck.size()]
    _left(progress, Vector2(_stage.position.x + _stage.size.x * 0.044, _stage.position.y + _stage.size.y * 0.08), maxi(11, roundi(15.0 * scale)), Color("#9bdcff"))
    var prompt: String = str(_current().get("hint", ""))
    _center(prompt, Rect2(_stage.position.x + _stage.size.x * 0.06, _stage.position.y + _stage.size.y * 0.16, _stage.size.x * 0.88, _stage.size.y * 0.08), maxi(11, roundi(17.0 * scale)), Color("#b6d9ef"))
    if _show_hint:
        var hint_rect := Rect2(_stage.position.x + _stage.size.x * 0.27, _stage.position.y + _stage.size.y * 0.215, _stage.size.x * 0.46, _stage.size.y * 0.075)
        _rounded(hint_rect, Color(0.08, 0.22, 0.34, 0.82), Color("#91efff"), 14, 2)
        _center(str(_current().get("answer", "")), hint_rect, maxi(12, roundi(20.0 * scale)), Color("#f2ffff"))
    var slot_count: int = _slot_rects.size()
    for n in range(slot_count):
        var rect: Rect2 = _slot_rects[n]
        var is_full: bool = int(_slots[n]) >= 0
        _rounded(rect, Color("#1d385e") if not is_full else Color("#274d6e"), Color("#61bed6") if not is_full else Color("#85f0cb"), 17, 2)
        if is_full:
            var index: int = int(_slots[n])
            if index >= 0 and index < _cards.size():
                _draw_piece(_cards[index], rect.grow(-minf(rect.size.x, rect.size.y) * 0.05), true)
        else:
            _center(str(n + 1), rect, maxi(16, roundi(31.0 * scale)), Color(0.58, 0.76, 0.90, 0.43))
    var prev: String = _assembled_word()
    if _solved:
        _center(_copy(4) + "  " + str(_current().get("answer", "")), Rect2(_stage.position.x, _stage.position.y + _stage.size.y * 0.55, _stage.size.x, _stage.size.y * 0.11), maxi(14, roundi(25.0 * scale)), Color("#93ffd8"))
    elif _wrong_delay > 0.0:
        _center(_copy(5), Rect2(_stage.position.x, _stage.position.y + _stage.size.y * 0.56, _stage.size.x, _stage.size.y * 0.10), maxi(12, roundi(20.0 * scale)), Color("#ffd5a1"))
    elif not prev.is_empty():
        _center(prev, Rect2(_stage.position.x, _stage.position.y + _stage.size.y * 0.56, _stage.size.x, _stage.size.y * 0.10), maxi(13, roundi(23.0 * scale)), Color("#b8edfb"))
    if not _solved:
        for index in range(_choice_rects.size()):
            var rect: Rect2 = _choice_rects[index]
            var is_used: bool = _slots.has(index)
            var active: bool = _active_card == index
            _rounded(rect, Color("#173857") if not active else Color("#3e5a7a"), Color("#4fb8de") if not active else Color("#f4d47b"), 16, 3 if active else 2)
            if not is_used:
                _draw_piece(_cards[index], rect.grow(-minf(rect.size.x, rect.size.y) * 0.07), false)
            else:
                _center("✓", rect, maxi(22, roundi(31.0 * scale)), Color("#7ce7b8"))
        _center(_copy(3), Rect2(_stage.position.x, _stage.position.y + _stage.size.y * 0.94, _stage.size.x, _stage.size.y * 0.05), maxi(10, roundi(15.0 * scale)), Color("#89b2d2"))
        if _dragging and _active_card >= 0 and _active_card < _cards.size():
            var drag_rect := Rect2(_drag_at - Vector2(_choice_rects[0].size.x, _choice_rects[0].size.y) * 0.43, _choice_rects[0].size * 0.86)
            _rounded(drag_rect, Color("#29496a"), Color("#f9e69a"), 12, 2)
            _draw_piece(_cards[_active_card], drag_rect.grow(-5.0), false)


func _rounded(rect: Rect2, fill: Color, outline: Color, rad: int, stroke: int) -> void:
    if rect.size.x < 1.0 or rect.size.y < 1.0:
        return
    var style: StyleBoxFlat = _skin(fill, outline, rad, stroke)
    style.shadow_size = 0
    draw_style_box(style, rect)


func _center(value: String, rect: Rect2, size_px: int, color: Color) -> void:
    if _font == null or rect.size.x < 2:
        return
    var px: int = maxi(8, size_px)
    while px > 8 and _font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > rect.size.x * 0.96:
        px -= 1
    var width: float = _font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
    draw_string(_font, Vector2(rect.get_center().x - width * 0.5, rect.get_center().y + float(px) * 0.36), value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


func _left(value: String, pos: Vector2, size_px: int, color: Color) -> void:
    if _font != null:
        draw_string(_font, pos + Vector2(0.0, float(size_px) * 0.4), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)


func _draw_piece(piece: Dictionary, rect: Rect2, placed: bool) -> void:
    var label: String = str(piece.get("label", ""))
    var op: String = str(piece.get("op", "add"))
    var kind: String = str(piece.get("type", "text"))
    var icon_path: String = str(piece.get("asset", ""))
    var sz: float = minf(rect.size.x, rect.size.y)
    var label_px: int = maxi(11, roundi(clampf(sz * 0.21, 11.0, 25.0)))
    if kind == "object" and not icon_path.is_empty():
        var tex: Texture2D = _get_texture(icon_path)
        if tex != null:
            var im_box := Rect2(rect.position + Vector2(rect.size.x * 0.13, rect.size.y * 0.02), Vector2(rect.size.x * 0.74, rect.size.y * 0.67))
            var ts: Vector2 = tex.get_size()
            if ts.x > 0 and ts.y > 0:
                var ratio: float = minf(im_box.size.x / ts.x, im_box.size.y / ts.y)
                var fitted: Vector2 = ts * ratio
                draw_texture_rect(tex, Rect2(im_box.get_center() - fitted * 0.5, fitted), false)
        _center(label, Rect2(rect.position.x, rect.position.y + rect.size.y * 0.70, rect.size.x, rect.size.y * 0.25), label_px, Color("#eafaff"))
    else:
        var text_color: Color = Color("#ffadbb") if op == "remove" else (Color("#8bffe0") if op == "replace" else Color("#e5f6ff"))
        _center(label, rect, maxi(13, roundi(clampf(sz * 0.36, 13.0, 35.0))), text_color)
    if placed and (op == "remove" or op == "replace"):
        draw_line(Vector2(rect.position.x + 3.0, rect.end.y - 7.0), Vector2(rect.end.x - 3.0, rect.end.y - 7.0), Color("#f47fa3") if op == "remove" else Color("#7aeaca"), 3.0)


func _get_texture(path: String) -> Texture2D:
    if _textures.has(path):
        return _textures[path]
    var resource: Texture2D = null
    if ResourceLoader.exists(path):
        resource = load(path) as Texture2D
    _textures[path] = resource
    return resource


func _assembled_word() -> String:
    var assembled: String = ""
    for card_index in _slots:
        var i: int = int(card_index)
        if i < 0 or i >= _cards.size():
            continue
        var piece: Dictionary = _cards[i]
        var op: String = str(piece.get("op", "add"))
        var value: String = str(piece.get("value", ""))
        if op == "add":
            assembled += value
        elif op == "remove":
            if assembled.ends_with(value) and not value.is_empty():
                assembled = assembled.substr(0, assembled.length() - value.length())
        elif op == "replace":
            var old: String = str(piece.get("from", ""))
            if not old.is_empty():
                var pos: int = assembled.find(old) if str(piece.get("where", "last")) == "first" else assembled.rfind(old)
                if pos >= 0:
                    assembled = assembled.substr(0, pos) + value + assembled.substr(pos + old.length())
    return assembled


func _all_filled() -> bool:
    for card_index in _slots:
        if int(card_index) < 0:
            return false
    return not _slots.is_empty()


func _check_solution() -> void:
    if _solved or not _all_filled():
        return
    # Compare each slot with its source ID explicitly; do not compare a
    # reconstructed Array against raw JSON (which can hold float values).
    var correct_order: bool = _slots.size() == _required.size()
    if correct_order:
        for slot_index in range(_required.size()):
            var card_index: int = int(_slots[slot_index])
            if card_index < 0 or card_index >= _cards.size():
                correct_order = false
                break
            if int(_cards[card_index].get("source_id", -1)) != int(_required[slot_index]):
                correct_order = false
                break
    var formed_word: String = _assembled_word()
    var expected_word: String = str(_current().get("answer", ""))
    if correct_order and formed_word == expected_word:
        _solved = true
        _earned = mini(50, _earned + 1)
        _toolbar_hud.set("crystal_count", _earned)
        _play_audio(true)
        _success_delay = 1.10
    else:
        _wrong_delay = 1.15
        _play_audio(false)
    queue_redraw()


func _play_audio(ok: bool) -> void:
    if _sfx == null:
        return
    var path: String = "res://planet_hub/games/space_rebus/audio/ui/correct.wav" if ok else "res://planet_hub/games/space_rebus/audio/ui/wrong.wav"
    if ResourceLoader.exists(path):
        _sfx.stream = load(path) as AudioStream
        _sfx.play()


func _put(slot_index: int, card_index: int) -> void:
    if _solved or _finished or slot_index < 0 or slot_index >= _slots.size() or card_index < 0 or card_index >= _cards.size():
        return
    for i in range(_slots.size()):
        if i != slot_index and int(_slots[i]) == card_index:
            _slots[i] = -1
    _slots[slot_index] = card_index
    _active_card = -1
    _dragging = false
    _check_solution()
    queue_redraw()


func _handle_press(pos: Vector2) -> void:
    if _hint_rect.has_point(pos):
        _show_hint = not _show_hint
        queue_redraw()
        return
    if _finished:
        if _replay_rect.has_point(pos):
            _start_game(false)
        return
    if _solved:
        return
    for i in range(_slot_rects.size()):
        if _slot_rects[i].has_point(pos):
            if _active_card >= 0:
                _put(i, _active_card)
            elif int(_slots[i]) >= 0:
                _slots[i] = -1
                _wrong_delay = 0.0
                queue_redraw()
            return
    for i in range(_choice_rects.size()):
        if _choice_rects[i].has_point(pos) and not _slots.has(i):
            _active_card = i
            _dragging = false
            _drag_start = pos
            _drag_at = pos
            queue_redraw()
            return


func _handle_motion(pos: Vector2) -> void:
    if _active_card < 0 or _solved:
        return
    _drag_at = pos
    _dragging = _dragging or _drag_start.distance_to(pos) > 10.0
    queue_redraw()


func _handle_release(pos: Vector2) -> void:
    if _active_card < 0:
        return
    if _dragging:
        for i in range(_slot_rects.size()):
            if _slot_rects[i].has_point(pos):
                _put(i, _active_card)
                break
    _dragging = false
    queue_redraw()


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed:
                _handle_press(mouse.position)
            else:
                _handle_release(mouse.position)
            accept_event()
    elif event is InputEventMouseMotion:
        if _active_card >= 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _handle_motion((event as InputEventMouseMotion).position)
            accept_event()
    elif event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            _handle_press(touch.position)
        else:
            _handle_release(touch.position)
        accept_event()
    elif event is InputEventScreenDrag:
        _handle_motion((event as InputEventScreenDrag).position)
        accept_event()
