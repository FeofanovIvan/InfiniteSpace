extends "res://simulator_ui/action_cards/scripts/action_cards.gd"
## v124 – responsive Action Lab on top of the original drag/drop gameplay.
## This is deliberately additive: base gameplay, PNG assets and scoring are unchanged.

const V124_STAGE_DIR: String = "res://simulator_ui/action_cards/assets/stages_v124/"
const V124_UI: Dictionary = {
    "en": {"title": "ACTION LAB", "hint": "Drag Mika onto the question mark", "drag": "Move Mika to the target", "select": "Tap the target to check", "pick": "Choose a Mika below", "retry": "Try another Mika!", "great": "GREAT JOB!", "next": "NEXT"},
    "ru": {"title": "ДЕЙСТВИЯ", "hint": "Перетащи Мику на знак вопроса", "drag": "Перетащи Мику в центр", "select": "Нажми на цель для проверки", "pick": "Выбери Мику внизу", "retry": "Попробуй другую картинку!", "great": "ОТЛИЧНО!", "next": "ДАЛЬШЕ"},
    "fr": {"title": "LABO DES ACTIONS", "hint": "Glisse Mika sur le point d'interrogation", "drag": "Déplace Mika vers la cible", "select": "Touche la cible pour vérifier", "pick": "Choisis un Mika en bas", "retry": "Essaie une autre image !", "great": "BRAVO !", "next": "SUIVANT"},
    "de": {"title": "AKTIONSLABOR", "hint": "Ziehe Mika auf das Fragezeichen", "drag": "Ziehe Mika zum Ziel", "select": "Tippe zum Prüfen auf das Ziel", "pick": "Wähle unten einen Mika", "retry": "Versuche ein anderes Bild!", "great": "SUPER!", "next": "WEITER"},
    "es": {"title": "LABORATORIO DE ACCIONES", "hint": "Arrastra a Mika al signo de pregunta", "drag": "Mueve a Mika al objetivo", "select": "Toca el objetivo para comprobar", "pick": "Elige un Mika abajo", "retry": "¡Prueba otra imagen!", "great": "¡MUY BIEN!", "next": "SIGUIENTE"},
    "pt_BR": {"title": "LABORATÓRIO DE AÇÕES", "hint": "Arraste Mika para o ponto de interrogação", "drag": "Leve Mika até o alvo", "select": "Toque no alvo para conferir", "pick": "Escolha um Mika abaixo", "retry": "Tente outra imagem!", "great": "MUITO BEM!", "next": "PRÓXIMO"},
}

## The lessons remain actions in English; show localized meaning in the header.
const V124_WORDS: Dictionary = {
    "walk": {"ru": "ИДТИ", "fr": "MARCHER", "de": "GEHEN", "es": "CAMINAR", "pt_BR": "ANDAR"},
    "run": {"ru": "БЕЖАТЬ", "fr": "COURIR", "de": "LAUFEN", "es": "CORRER", "pt_BR": "CORRER"},
    "jump": {"ru": "ПРЫГАТЬ", "fr": "SAUTER", "de": "SPRINGEN", "es": "SALTAR", "pt_BR": "PULAR"},
    "sit": {"ru": "СИДЕТЬ", "fr": "S'ASSEOIR", "de": "SITZEN", "es": "SENTARSE", "pt_BR": "SENTAR"},
    "lie_down": {"ru": "ЛЕЧЬ", "fr": "S'ALLONGER", "de": "SICH HINLEGEN", "es": "ACOSTARSE", "pt_BR": "DEITAR"},
    "sleep": {"ru": "СПАТЬ", "fr": "DORMIR", "de": "SCHLAFEN", "es": "DORMIR", "pt_BR": "DORMIR"},
    "eat": {"ru": "ЕСТЬ", "fr": "MANGER", "de": "ESSEN", "es": "COMER", "pt_BR": "COMER"},
    "drink": {"ru": "ПИТЬ", "fr": "BOIRE", "de": "TRINKEN", "es": "BEBER", "pt_BR": "BEBER"},
    "read": {"ru": "ЧИТАТЬ", "fr": "LIRE", "de": "LESEN", "es": "LEER", "pt_BR": "LER"},
    "write": {"ru": "ПИСАТЬ", "fr": "ÉCRIRE", "de": "SCHREIBEN", "es": "ESCRIBIR", "pt_BR": "ESCREVER"},
    "draw": {"ru": "РИСОВАТЬ", "fr": "DESSINER", "de": "ZEICHNEN", "es": "DIBUJAR", "pt_BR": "DESENHAR"},
    "dance": {"ru": "ТАНЦЕВАТЬ", "fr": "DANSER", "de": "TANZEN", "es": "BAILAR", "pt_BR": "DANÇAR"},
    "sing": {"ru": "ПЕТЬ", "fr": "CHANTER", "de": "SINGEN", "es": "CANTAR", "pt_BR": "CANTAR"},
    "swim": {"ru": "ПЛАВАТЬ", "fr": "NAGER", "de": "SCHWIMMEN", "es": "NADAR", "pt_BR": "NADAR"},
    "fly": {"ru": "ЛЕТАТЬ", "fr": "VOLER", "de": "FLIEGEN", "es": "VOLAR", "pt_BR": "VOAR"},
    "throw": {"ru": "БРОСАТЬ", "fr": "LANCER", "de": "WERFEN", "es": "LANZAR", "pt_BR": "ARREMESSAR"},
    "catch": {"ru": "ЛОВИТЬ", "fr": "ATTRAPER", "de": "FANGEN", "es": "ATRAPAR", "pt_BR": "PEGAR"},
    "brush_teeth": {"ru": "ЧИСТИТЬ ЗУБЫ", "fr": "SE BROSSER LES DENTS", "de": "ZÄHNE PUTZEN", "es": "CEPILLARSE LOS DIENTES", "pt_BR": "ESCOVAR OS DENTES"},
    "wash_hands": {"ru": "МЫТЬ РУКИ", "fr": "SE LAVER LES MAINS", "de": "HÄNDE WASCHEN", "es": "LAVARSE LAS MANOS", "pt_BR": "LAVAR AS MÃOS"},
    "bite": {"ru": "КУСАТЬ", "fr": "MORDRE", "de": "BEISSEN", "es": "MORDER", "pt_BR": "MORDER"},
}

var _v124_toolbar: Panel = null
var _v124_mini_floor: ColorRect = null
var _v124_last_locale: String = ""

func _v124_locale() -> String:
    var language: String = str(MobileLocale.language)
    if language == "pt":
        language = "pt_BR"
    if not V124_UI.has(language):
        language = "en"
    return language

func _v124_text(key: String) -> String:
    var entries: Dictionary = V124_UI.get(_v124_locale(), V124_UI["en"])
    return str(entries.get(key, V124_UI["en"].get(key, "")))

func _v124_action_title() -> String:
    var slug: String = str(current_action.get("slug", ""))
    var entry: Dictionary = V124_WORDS.get(slug, {})
    return str(entry.get(_v124_locale(), current_action.get("title", ""))).to_upper()

func _load_data() -> void:
    super._load_data()
    # Use the enhanced SVGs without altering the 20 original actions or their PNGs.
    for i in range(actions.size()):
        var action: Dictionary = actions[i]
        var stage_path: String = V124_STAGE_DIR + str(action.get("slug", "")) + ".svg"
        if ResourceLoader.exists(stage_path):
            action["stage"] = stage_path
            actions[i] = action

func _build_interface() -> void:
    super._build_interface()
    _v124_toolbar = Panel.new()
    _v124_toolbar.name = "ActionLabToolbar_v124"
    _v124_toolbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _v124_toolbar.add_theme_stylebox_override("panel", _style(Color("091D3C"), Color("61D9FF"), 23, 2))
    canvas.add_child(_v124_toolbar)
    canvas.move_child(_v124_toolbar, 0)
    # Headline and lesson words are now in the TOP toolbar, not the answer panel.
    prompt_word.reparent(canvas)
    prompt_word.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt_word.clip_text = true
    game_header.clip_text = true
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.clip_text = true
    prompt_caption.visible = false
    _score_panel.visible = false
    progress_label.visible = false
    _v124_mini_floor = ColorRect.new()
    _v124_mini_floor.name = "ActionLabDropDivider_v124"
    _v124_mini_floor.color = Color("3FA5E5", 0.25)
    _v124_mini_floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage_panel.add_child(_v124_mini_floor)
    stage_panel.move_child(_v124_mini_floor, 0)
    stage_panel.add_theme_stylebox_override("panel", _style(Color(0.035, 0.102, 0.215, 0.95), Color("4BD8FB"), 27, 2))
    target_panel.add_theme_stylebox_override("panel", _style(Color("12345A"), Color("80E6FA"), 43, 3))
    _v124_last_locale = ""
    _v124_sync_language()

func _v124_sync_language() -> void:
    var language: String = _v124_locale()
    if language == _v124_last_locale:
        return
    _v124_last_locale = language
    game_header.text = _v124_text("title")
    if not current_action.is_empty():
        prompt_word.text = _v124_action_title()
        status_label.text = (_v124_text("great") + "  " + _v124_action_title()) if answer_solved else _v124_text("hint")
    next_button.text = _v124_text("next")

func _process(_delta: float) -> void:
    if _v124_toolbar != null and _v124_locale() != _v124_last_locale:
        _v124_sync_language()
        _fit_to_viewport()

func _fit_to_viewport() -> void:
    if canvas == null:
        return
    var view: Vector2 = size
    if view.x < 10.0 or view.y < 10.0:
        view = get_viewport_rect().size
    if view.x < 10.0 or view.y < 10.0:
        return
    canvas.scale = Vector2.ONE
    canvas.position = Vector2.ZERO
    canvas.size = view
    _sky.position = Vector2.ZERO
    _sky.size = view
    var w: float = view.x
    var h: float = view.y
    var s: float = clampf(minf(w / 1280.0, h / 720.0), 0.48, 1.60)
    var pad: float = maxf(10.0, w * 0.021)
    var toolbar_y: float = maxf(7.0, 9.0 * s)
    var toolbar_h: float = clampf(h * 0.12, 60.0 * s, 94.0 * s)
    var panel_y: float = toolbar_y + toolbar_h + 12.0 * s
    var panel_h: float = maxf(160.0, h - panel_y - 10.0 * s)
    var panel_w: float = w - pad * 2.0

    if _v124_toolbar != null:
        _v124_toolbar.position = Vector2(pad, toolbar_y)
        _v124_toolbar.size = Vector2(panel_w, toolbar_h)

    _back_button.position = Vector2(pad + 10.0 * s, toolbar_y + 9.0 * s)
    _back_button.size = Vector2(62.0 * s, maxf(42.0 * s, toolbar_h - 18.0 * s))
    _back_button.add_theme_stylebox_override("normal", _style(Color("09223D"), Color("64DEFF"), 17, 2))
    _back_button.add_theme_stylebox_override("hover", _style(Color("194768"), Color("C8F8FF"), 17, 2))
    _back_button.add_theme_stylebox_override("pressed", _style(Color("265A83"), Color("E2FFFF"), 17, 2))
    _crystal_panel.position = Vector2(w - pad - 166.0 * s, toolbar_y + 9.0 * s)
    _crystal_panel.size = Vector2(166.0 * s, toolbar_h - 18.0 * s)
    _crystal_panel.add_theme_stylebox_override("panel", _style(Color("0C284A"), Color("64DEFF"), 20, 2))
    _crystal_icon.position = Vector2(9.0 * s, 7.0 * s)
    _crystal_icon.size = Vector2(47.0 * s, maxf(31.0 * s, toolbar_h - 31.0 * s))
    _crystal_label.position = Vector2(63.0 * s, 0.0)
    _crystal_label.size = Vector2(96.0 * s, toolbar_h - 18.0 * s)
    _crystal_label.add_theme_font_size_override("font_size", maxi(18, roundi(29.0 * s)))

    var title_x: float = pad + 89.0 * s
    var title_w: float = maxf(100.0, w - pad - 169.0 * s - title_x - 4.0 * s)
    game_header.position = Vector2(title_x, toolbar_y + 5.0 * s)
    game_header.size = Vector2(title_w * 0.46, toolbar_h * 0.48)
    game_header.add_theme_font_size_override("font_size", maxi(13, roundi((20.0 if game_header.text.length() > 15 else 27.0) * s)))
    prompt_word.position = Vector2(title_x + title_w * 0.47, toolbar_y + 4.0 * s)
    prompt_word.size = Vector2(title_w * 0.51, toolbar_h * 0.48)
    prompt_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_word.add_theme_font_size_override("font_size", maxi(13, roundi((18.0 if prompt_word.text.length() > 14 else 28.0) * s)))
    status_label.position = Vector2(title_x, toolbar_y + toolbar_h * 0.50)
    status_label.size = Vector2(title_w, toolbar_h * 0.38)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", maxi(12, roundi(18.0 * s)))

    stage_panel.position = Vector2(pad, panel_y)
    stage_panel.size = Vector2(panel_w, panel_h)
    var tile_gap: float = maxf(5.0, 11.0 * s)
    var horizontal_pad: float = maxf(10.0, 23.0 * s)
    var tile_w: float = maxf(39.0, (panel_w - horizontal_pad * 2.0 - 4.0 * tile_gap) / 5.0)
    var tile_h: float = minf(tile_w * 0.79, maxf(74.0 * s, panel_h * 0.255))
    var images_y: float = panel_y + panel_h - tile_h - 10.0 * s
    for i in range(OPTIONS_COUNT):
        var tile: Panel = option_panels[i]
        tile.position = Vector2(pad + horizontal_pad + float(i) * (tile_w + tile_gap), images_y)
        tile.size = Vector2(tile_w, tile_h)
        tile.add_theme_stylebox_override("panel", _option_style(i == selected_index and not answer_solved))
        option_images[i].position = Vector2(5.0 * s, 4.0 * s)
        option_images[i].size = Vector2(maxf(1.0, tile_w - 10.0 * s), maxf(1.0, tile_h - 8.0 * s))

    var target_h: float = clampf(panel_h * 0.245, 65.0 * s, 147.0 * s)
    var target_w: float = clampf(panel_w * 0.16, 102.0 * s, 214.0 * s)
    var target_top: float = images_y - target_h - 16.0 * s
    var target_local_y: float = target_top - panel_y
    target_panel.position = Vector2((panel_w - target_w) * 0.5, target_local_y)
    target_panel.size = Vector2(target_w, target_h)
    question_label.position = Vector2.ZERO
    question_label.size = target_panel.size
    question_label.add_theme_font_size_override("font_size", maxi(29, roundi(91.0 * s)))
    win_sprite.position = target_panel.position + Vector2(-6.0 * s, -5.0 * s)
    win_sprite.size = target_panel.size + Vector2(12.0 * s, 10.0 * s)
    win_sprite.pivot_offset = win_sprite.size * 0.5
    if _v124_mini_floor != null:
        _v124_mini_floor.position = Vector2(panel_w * 0.25, target_local_y - 12.0 * s)
        _v124_mini_floor.size = Vector2(panel_w * 0.5, maxf(1.0, 2.0 * s))

    # Preserve the original SVG aspect ratio. Shrink it when screens are short.
    var available_svg_h: float = maxf(42.0 * s, target_local_y - 34.0 * s)
    var svg_w: float = minf(minf(panel_w * 0.77, 745.0 * s), available_svg_h * 3.5)
    stage_art.position = Vector2((panel_w - svg_w) * 0.5, 17.0 * s)
    stage_art.size = Vector2(svg_w, svg_w / 3.5)
    stage_art.queue_redraw()

    next_button.position = Vector2(w - pad - 165.0 * s, target_top + (target_h - 55.0 * s) * 0.5)
    next_button.size = Vector2(151.0 * s, 55.0 * s)
    next_button.add_theme_font_size_override("font_size", maxi(12, roundi(19.0 * s)))
    ghost.size = Vector2(maxf(75.0, tile_w * 0.86), maxf(75.0, tile_h * 1.15))

func _reset_deck() -> void:
    # Shuffle all 20 actions without resetting progress: endless randomized cycles.
    round_pool.clear()
    for action in actions:
        round_pool.append(action)
    round_pool.shuffle()
    if round_pool.size() > 1:
        var previous: String = str(current_action.get("id", ""))
        var last: int = round_pool.size() - 1
        if str(round_pool[last].get("id", "")) == previous:
            var temp: Variant = round_pool[last]
            round_pool[last] = round_pool[0]
            round_pool[0] = temp

func _start_next_round() -> void:
    super._start_next_round()
    if actions.is_empty():
        return
    prompt_word.text = _v124_action_title()
    status_label.text = _v124_text("hint")
    next_button.text = _v124_text("next")
    _fit_to_viewport()

func _begin_drag(index: int, pointer_point: Vector2, kind: String, pointer_index: int) -> void:
    super._begin_drag(index, pointer_point, kind, pointer_index)
    status_label.text = _v124_text("drag")

func _finish_drag(point: Vector2) -> void:
    var was_dragging: bool = drag_active
    var on_target: bool = was_dragging and _is_over_target(point)
    var did_move: bool = drag_has_moved
    super._finish_drag(point)
    if was_dragging and not on_target and not answer_solved:
        status_label.text = _v124_text("drag" if did_move else "select")

func _on_target_input(event: InputEvent) -> void:
    var was_unselected: bool = selected_index < 0
    super._on_target_input(event)
    if was_unselected and not answer_solved:
        status_label.text = _v124_text("pick")

func _check_answer(index: int) -> void:
    if answer_solved or index < 0 or index >= candidate_actions.size():
        return
    var candidate: Dictionary = candidate_actions[index]
    if str(candidate.get("id", "")) == str(current_action.get("id", "")):
        _finish_correct()
    else:
        status_label.text = _v124_text("retry")
        status_label.add_theme_color_override("font_color", GOLD)
        option_panels[index].add_theme_stylebox_override("panel", _style(Color("422743"), Color("FFA7BE"), 23, 3))
        selected_index = -1

func _finish_correct() -> void:
    super._finish_correct()
    status_label.text = _v124_text("great") + "  " + _v124_action_title()
    next_button.text = _v124_text("next")

func _next_pressed() -> void:
    if answer_solved:
        _start_next_round()

func _return_to_simulator() -> void:
    # Never jump to the unrelated PlayTown city. Return to THIS game's gallery.
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "")
        return
    var ancestor: Node = get_parent()
    for _i in range(7):
        if ancestor == null:
            break
        if ancestor.has_method("_return_to_cards"):
            ancestor.call("_return_to_cards")
            return
        ancestor = ancestor.get_parent()
    push_warning("Action Lab: could not locate the simulator gallery")
