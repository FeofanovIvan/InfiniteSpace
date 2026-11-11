extends "res://simulator_ui/action_cards/scripts/action_cards.gd"
## MIKA / Action Lab: independent v5 — whole choice card follows the pointer.
## SVG hints are hidden. Only the CENTRAL square question card gets
## a translucent violet film under the big question mark.
## The five bottom image choices stay as before; the dragged ghost carries a full card.
## After a correct drop the card dissolves, leaving Mika in the center.

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

var _v124_last_locale: String = ""


const V125_SPEAKER_SCRIPT: Script = preload("res://addons/mika_voice/SpeakerButton.gd")
const V125_CORRECT_SOUND: AudioStream = preload("res://learning/audio/sfx/correct.ogg")
const V125_WRONG_SOUND: AudioStream = preload("res://learning/audio/sfx/wrong.ogg")

var _v125_speaker: Button
var _v125_voice_locale: String = ""


const BRANCH_ADVANCE_DELAY: float = 1.65
var _branch_title: Panel = null
var _branch_question_film: Panel = null
var _branch_stable_frame_style: StyleBoxFlat = null
var _branch_stable_frame_rect: Rect2 = Rect2()
var _branch_frame_inset: float = 4.0
var _branch_frame_ready: bool = false
var _branch_round_serial: int = 0

# Visual drag card is a child of the original ghost, so the ORIGINAL touch and
# mouse handling (hit testing, input indices, selection) remains untouched.
var _branch_drag_card: Panel = null
var _branch_drag_image: TextureRect = null
var _branch_drag_index: int = -1
var _branch_success_card: Panel = null
var _branch_success_tween: Tween = null
var _branch_drag_texture: Texture2D = null


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

# The original Action Cards game can replace the target's StyleBox while a
# choice is being dragged. Its interaction state must NEVER resize/repaint
# the visible central question card; the purple film needs the same geometry.
func _branch_keep_question_frame_stable() -> void:
    if not _branch_frame_ready or target_panel == null:
        return
    if target_panel.position != _branch_stable_frame_rect.position:
        target_panel.position = _branch_stable_frame_rect.position
    if target_panel.size != _branch_stable_frame_rect.size:
        target_panel.size = _branch_stable_frame_rect.size
    if target_panel.scale != Vector2.ONE:
        target_panel.scale = Vector2.ONE
    if target_panel.rotation != 0.0:
        target_panel.rotation = 0.0
    if target_panel.pivot_offset != Vector2.ZERO:
        target_panel.pivot_offset = Vector2.ZERO
    if _branch_stable_frame_style != null and target_panel.get_theme_stylebox("panel") != _branch_stable_frame_style:
        target_panel.add_theme_stylebox_override("panel", _branch_stable_frame_style)
    if _branch_question_film != null:
        var card_inset: float = _branch_frame_inset
        var inner_edge: float = maxf(1.0, _branch_stable_frame_rect.size.x - 2.0 * card_inset)
        _branch_question_film.position = Vector2(card_inset, card_inset)
        _branch_question_film.size = Vector2(inner_edge, inner_edge)
        if _branch_question_film.scale != Vector2.ONE:
            _branch_question_film.scale = Vector2.ONE

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

# Create a faithful copy of the lower square/rounded choice card. Both this
# panel and its image are non-interactive; the original ghost still tracks touch.
func _branch_setup_drag_card() -> void:
    if ghost == null or _branch_drag_card != null:
        return
    _branch_drag_card = Panel.new()
    _branch_drag_card.name = "ActionLab_WholeChoiceDragging_v5"
    _branch_drag_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _branch_drag_card.visible = false
    ghost.add_child(_branch_drag_card)
    _branch_drag_image = TextureRect.new()
    _branch_drag_image.name = "OriginalMikaImage"
    _branch_drag_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _branch_drag_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _branch_drag_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _branch_drag_image.anchor_left = 0.0
    _branch_drag_image.anchor_top = 0.0
    _branch_drag_image.anchor_right = 1.0
    _branch_drag_image.anchor_bottom = 1.0
    _branch_drag_image.offset_left = 5.0
    _branch_drag_image.offset_top = 4.0
    _branch_drag_image.offset_right = -5.0
    _branch_drag_image.offset_bottom = -4.0
    _branch_drag_card.add_child(_branch_drag_image)

func _branch_refresh_drag_card_geometry() -> void:
    if _branch_drag_card == null or _branch_drag_index < 0 or _branch_drag_index >= OPTIONS_COUNT:
        return
    var tile: Control = option_panels[_branch_drag_index] as Control
    if tile == null:
        return
    # Keep the card larger than the old Mika-only ghost but below the top bar.
    var side: Vector2 = tile.size
    _branch_drag_card.size = side
    var lift: float = maxf(42.0, side.y * 0.62)
    _branch_drag_card.position = (ghost.size - side) * 0.5 - Vector2(0.0, lift)
    var current_style: StyleBox = tile.get_theme_stylebox("panel")
    if current_style != null:
        _branch_drag_card.add_theme_stylebox_override("panel", current_style.duplicate() as StyleBox)

func _branch_hide_drag_card() -> void:
    if _branch_drag_card != null:
        _branch_drag_card.visible = false
    if ghost != null:
        ghost.self_modulate = Color.WHITE
    _branch_drag_index = -1
    _branch_drag_texture = null

func _branch_cleanup_success_card() -> void:
    if is_instance_valid(_branch_success_card):
        _branch_success_card.queue_free()
    _branch_success_card = null
    _branch_success_tween = null

func _branch_cancel_success_card() -> void:
    if is_instance_valid(_branch_success_tween):
        _branch_success_tween.kill()
    _branch_cleanup_success_card()

func _branch_make_success_card(texture: Texture2D, start_global: Vector2, start_size: Vector2) -> void:
    if texture == null or canvas == null or target_panel == null:
        if win_sprite != null:
            win_sprite.modulate = Color.WHITE
        return
    _branch_cancel_success_card()
    var target_global: Vector2 = target_panel.global_position
    # The overlay lives in canvas-space. No new hit-test/touch interception.
    var global_to_canvas: Transform2D = canvas.get_global_transform().affine_inverse()
    var start_pos: Vector2 = global_to_canvas * start_global
    var end_pos: Vector2 = global_to_canvas * target_global
    var end_size: Vector2 = target_panel.size
    _branch_success_card = Panel.new()
    _branch_success_card.name = "ActionLab_DisappearingWholeCard_v5"
    _branch_success_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _branch_success_card.position = start_pos
    _branch_success_card.size = start_size
    if _branch_drag_card != null:
        var frame_style: StyleBox = _branch_drag_card.get_theme_stylebox("panel")
        if frame_style != null:
            _branch_success_card.add_theme_stylebox_override("panel", frame_style.duplicate() as StyleBox)
    var character: TextureRect = TextureRect.new()
    character.name = "MikaFromChoice"
    character.texture = texture
    character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    character.mouse_filter = Control.MOUSE_FILTER_IGNORE
    character.anchor_left = 0.0
    character.anchor_top = 0.0
    character.anchor_right = 1.0
    character.anchor_bottom = 1.0
    character.offset_left = 5.0
    character.offset_top = 4.0
    character.offset_right = -5.0
    character.offset_bottom = -4.0
    _branch_success_card.add_child(character)
    canvas.add_child(_branch_success_card)
    if win_sprite != null:
        # Preserve the existing successful Mika sprite at the target.
        win_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
        win_sprite.visible = true
    # Pause-proof tween: simulator runs with paused flight scene.
    _branch_success_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _branch_success_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    _branch_success_tween.tween_property(_branch_success_card, "position", end_pos, 0.18)
    _branch_success_tween.parallel().tween_property(_branch_success_card, "size", end_size, 0.18)
    _branch_success_tween.tween_property(_branch_success_card, "modulate:a", 0.0, 0.25)
    if win_sprite != null:
        _branch_success_tween.parallel().tween_property(win_sprite, "modulate:a", 1.0, 0.25)
    _branch_success_tween.tween_callback(Callable(self, "_branch_cleanup_success_card"))

func _begin_drag(index: int, pointer_point: Vector2, kind: String, pointer_index: int) -> void:
    super._begin_drag(index, pointer_point, kind, pointer_index)
    _branch_keep_question_frame_stable()
    if not drag_active or index < 0 or index >= OPTIONS_COUNT:
        return
    _branch_drag_index = index
    _branch_drag_texture = option_images[index].get("texture") as Texture2D
    _branch_setup_drag_card()
    if _branch_drag_card != null and _branch_drag_image != null:
        _branch_drag_image.texture = _branch_drag_texture
        _branch_refresh_drag_card_geometry()
        _branch_drag_card.visible = true
        # self_modulate affects the ghost image only, NOT the child card.
        # The card stays attached to the original touch-controlled ghost.
        ghost.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
    status_label.text = _v124_text("drag")

func _finish_drag(point: Vector2) -> void:
    var was_dragging: bool = drag_active
    var on_target: bool = was_dragging and _is_over_target(point)
    var did_move: bool = drag_has_moved
    super._finish_drag(point)
    _branch_hide_drag_card()
    _branch_keep_question_frame_stable()
    if was_dragging and not on_target and not answer_solved:
        status_label.text = _v124_text("drag" if did_move else "select")

func _on_target_input(event: InputEvent) -> void:
    var was_unselected: bool = selected_index < 0
    super._on_target_input(event)
    _branch_keep_question_frame_stable()
    if was_unselected and not answer_solved:
        status_label.text = _v124_text("pick")

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

func _v125_refresh_speaker() -> void:
    if _v125_speaker == null or current_action.is_empty():
        return
    _v125_voice_locale = _v124_locale()
    var action_word: String = _v124_action_title().to_lower()
    _v125_speaker.call("configure", action_word, _v125_voice_locale, "tablet", "action_lab")

func _v125_speak_action() -> void:
    if not is_inside_tree() or current_action.is_empty() or answer_solved:
        return
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null and voice.has_method("speak_text"):
        voice.call("speak_text", _v124_action_title().to_lower(), _v124_locale(), "tablet", "action_lab")

func _build_interface() -> void:
    super._build_interface()
    # Keep the base's starfield, drag machinery, options and crystal rewards.
    prompt_caption.visible = false
    progress_label.visible = false
    _score_panel.visible = false
    prompt_word.reparent(stage_panel)
    prompt_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    prompt_word.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt_word.clip_text = true
    prompt_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    game_header.clip_text = true
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.clip_text = true
    status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    _branch_title = Panel.new()
    _branch_title.name = "IndependentNeon_TitleBar"
    _branch_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _branch_title.add_theme_stylebox_override("panel", _style(Color("09203E"), Color("6DE3FF"), 22, 3))
    canvas.add_child(_branch_title)
    canvas.move_child(_branch_title, 0)

    # A single translucent violet layer belongs to the CENTRAL square card.
    # Keep all five lower image choices and their existing styles untouched.
    _branch_stable_frame_style = _style(Color("0D284A"), Color("86E4FC"), 28, 3) as StyleBoxFlat
    _branch_question_film = Panel.new()
    _branch_question_film.name = "ActionLab_CenterVioletGlass_v3"
    _branch_question_film.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var violet_style: StyleBoxFlat = StyleBoxFlat.new()
    violet_style.bg_color = Color(0.60, 0.38, 0.86, 0.19)
    violet_style.set_corner_radius_all(24)
    _branch_question_film.add_theme_stylebox_override("panel", violet_style)
    target_panel.add_child(_branch_question_film)

    # Hide the base game stage renderer permanently: no SVG, no hint artwork.
    # Do not delete existing shared assets from the user's project.
    stage_art.visible = false
    stage_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if question_label.get_parent() != target_panel:
        question_label.reparent(target_panel, false)
    question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    question_label.add_theme_color_override("font_color", Color("FFFFFF"))
    question_label.add_theme_color_override("font_outline_color", Color("093250"))
    question_label.add_theme_constant_override("outline_size", 4)
    target_panel.move_child(_branch_question_film, target_panel.get_child_count() - 2)
    target_panel.move_child(question_label, target_panel.get_child_count() - 1)

    _v125_speaker = V125_SPEAKER_SCRIPT.new() as Button
    _v125_speaker.name = "IndependentNeon_SpeakAction"
    _v125_speaker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _v125_speaker.tooltip_text = "Replay the action"
    stage_panel.add_child(_v125_speaker)
    _v125_voice_locale = ""
    _v124_last_locale = ""
    _v124_sync_language()
    next_button.visible = false
    next_button.disabled = true
    next_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _branch_setup_drag_card()
    _fit_to_viewport()


func _fit_to_viewport() -> void:
    if canvas == null or stage_panel == null or target_panel == null:
        return
    var viewport: Vector2 = size
    if viewport.x < 10.0 or viewport.y < 10.0:
        viewport = get_viewport_rect().size
    if viewport.x < 10.0 or viewport.y < 10.0:
        return
    canvas.scale = Vector2.ONE
    canvas.position = Vector2.ZERO
    canvas.size = viewport
    _sky.position = Vector2.ZERO
    _sky.size = viewport

    var w: float = viewport.x
    var h: float = viewport.y
    var s: float = clampf(minf(w / 1280.0, h / 720.0), 0.50, 1.55)
    var pad: float = maxf(9.0, w * 0.021)
    var gap: float = maxf(6.0, 9.0 * s)
    var top_y: float = maxf(6.0, 11.0 * s)
    var toolbar_h: float = clampf(h * 0.114, 55.0 * s, 93.0 * s)

    # Native simulator toolbar: independent arrow, centered title and crystals.
    var back_w: float = 75.0 * s
    _back_button.position = Vector2(pad, top_y)
    _back_button.size = Vector2(back_w, toolbar_h)
    _back_button.add_theme_stylebox_override("normal", _style(Color("071B37"), Color("5EDCFC"), 19, 3))
    _back_button.add_theme_stylebox_override("hover", _style(Color("153958"), Color("B4F3FF"), 19, 3))
    _back_button.add_theme_stylebox_override("pressed", _style(Color("204A69"), Color("D9FBFF"), 19, 3))
    var counter_w: float = 190.0 * s
    var counter_h: float = toolbar_h * 0.81
    var counter_x: float = w - pad - counter_w
    _crystal_panel.position = Vector2(counter_x, top_y + (toolbar_h - counter_h) * 0.5)
    _crystal_panel.size = Vector2(counter_w, counter_h)
    _crystal_panel.add_theme_stylebox_override("panel", _style(Color("0B2445"), Color("4CCDF4"), 24, 2))
    _crystal_icon.position = Vector2(10.0 * s, 7.0 * s)
    _crystal_icon.size = Vector2(60.0 * s, maxf(5.0, counter_h - 14.0 * s))
    _crystal_label.position = Vector2(83.0 * s, 1.0 * s)
    _crystal_label.size = Vector2(maxf(14.0, counter_w - 91.0 * s), counter_h - 2.0 * s)
    _crystal_label.add_theme_font_size_override("font_size", maxi(18, roundi(30.0 * s)))

    var title_x: float = pad + back_w + 12.0 * s
    var title_w: float = maxf(110.0, counter_x - title_x - 13.0 * s)
    if _branch_title != null:
        _branch_title.position = Vector2(title_x, top_y)
        _branch_title.size = Vector2(title_w, toolbar_h)
    game_header.position = Vector2(title_x + 14.0 * s, top_y + 4.0 * s)
    game_header.size = Vector2(maxf(15.0, title_w - 28.0 * s), toolbar_h * 0.49)
    game_header.add_theme_font_size_override("font_size", maxi(14, roundi((23.0 if game_header.text.length() > 17 else 30.0) * s)))
    status_label.position = Vector2(title_x + 13.0 * s, top_y + toolbar_h * 0.50)
    status_label.size = Vector2(maxf(15.0, title_w - 26.0 * s), toolbar_h * 0.42)
    status_label.add_theme_font_size_override("font_size", maxi(11, roundi(16.0 * s)))

    # Five separate tiles. No common bottom bar or block.
    var bottom_space: float = clampf(h * 0.205, 92.0 * s, 165.0 * s)
    var bottom_y: float = h - bottom_space - pad
    var tile_gap: float = maxf(6.0, 10.0 * s)
    var row_pad: float = maxf(8.0, 18.0 * s)
    var content_w: float = w - pad * 2.0
    var tile_w: float = (content_w - 2.0 * row_pad - 4.0 * tile_gap) / 5.0
    var tile_h: float = minf(bottom_space * 0.90, tile_w * 1.08)
    var tiles_y: float = bottom_y + (bottom_space - tile_h) * 0.5
    for i in range(OPTIONS_COUNT):
        var tile: Panel = option_panels[i]
        tile.position = Vector2(pad + row_pad + float(i) * (tile_w + tile_gap), tiles_y)
        tile.size = Vector2(tile_w, tile_h)
        tile.add_theme_stylebox_override("panel", _option_style(i == selected_index and not answer_solved))
        option_images[i].position = Vector2(5.0 * s, 4.0 * s)
        option_images[i].size = Vector2(maxf(1.0, tile_w - 10.0 * s), maxf(1.0, tile_h - 8.0 * s))

    # Stage stops above the five choice cards.
    var main_y: float = top_y + toolbar_h + gap
    var main_h: float = maxf(150.0 * s, tiles_y - main_y - gap)
    stage_panel.position = Vector2(pad, main_y)
    stage_panel.size = Vector2(content_w, main_h)
    stage_panel.add_theme_stylebox_override("panel", _style(Color("102C51"), Color("48CEF6"), 24, 2))
    var edge: float = maxf(8.0, 11.0 * s)
    var caption_h: float = clampf(main_h * 0.14, 30.0 * s, 54.0 * s)
    var between: float = maxf(5.0, 9.0 * s)
    var available_h: float = maxf(25.0, main_h - 2.0 * edge - caption_h - between)
    var available_w: float = maxf(25.0, content_w - 2.0 * edge)
    var side: float = minf(minf(available_h, available_w), 470.0 * s)
    var square_x: float = (content_w - side) * 0.5
    var square_y: float = edge + maxf(0.0, (available_h - side) * 0.18)
    target_panel.position = Vector2(square_x, square_y)
    target_panel.size = Vector2(side, side)
    # The visible frame has ONE permanent geometry and ONE permanent style.
    _branch_stable_frame_rect = Rect2(target_panel.position, target_panel.size)
    _branch_frame_inset = maxf(3.0, 4.0 * s)
    _branch_frame_ready = true
    _branch_keep_question_frame_stable()
    var inset: float = maxf(5.0 * s, side * 0.035)
    var inner_size: float = maxf(1.0, side - 2.0 * inset)
    stage_art.visible = false
    question_label.position = Vector2(inset * 0.4, inset * 0.2)
    question_label.size = Vector2(side - inset * 0.8, side - inset * 0.4)
    question_label.add_theme_font_size_override("font_size", maxi(44, roundi(side * 0.72)))

    var word_y: float = square_y + side + between
    var speaker_size: float = minf(47.0 * s, caption_h)
    var label_gap: float = 9.0 * s
    var label_w: float = minf(content_w * 0.50, 470.0 * s)
    var group_w: float = label_w + label_gap + speaker_size
    var word_x: float = (content_w - group_w) * 0.5
    prompt_word.position = Vector2(word_x, word_y)
    prompt_word.size = Vector2(label_w, caption_h)
    prompt_word.add_theme_font_size_override("font_size", maxi(13, roundi((22.0 if prompt_word.text.length() > 13 else 30.0) * s)))
    if _v125_speaker != null:
        _v125_speaker.position = Vector2(word_x + label_w + label_gap, word_y + (caption_h - speaker_size) * 0.5)
        _v125_speaker.size = Vector2(speaker_size, speaker_size)
        _v125_speaker.queue_redraw()

    var win_side: float = side * 0.90
    win_sprite.position = Vector2(square_x + (side - win_side) * 0.5, square_y + (side - win_side) * 0.5)
    win_sprite.size = Vector2(win_side, win_side)
    win_sprite.pivot_offset = win_sprite.size * 0.5
    next_button.visible = false
    ghost.size = Vector2(maxf(58.0, tile_w * 0.86), maxf(62.0, tile_h * 1.08))
    _branch_refresh_drag_card_geometry()
    _branch_keep_question_frame_stable()


func _process(delta: float) -> void:
    _branch_keep_question_frame_stable()
    if _branch_title != null and _v124_locale() != _v124_last_locale:
        _v124_sync_language()
        _fit_to_viewport()
    if _v125_speaker != null and _v125_voice_locale != _v124_locale():
        _v125_refresh_speaker()


func _start_next_round() -> void:
    _branch_cancel_success_card()
    _branch_hide_drag_card()
    if win_sprite != null:
        win_sprite.modulate = Color.WHITE
    _branch_round_serial += 1
    super._start_next_round()
    if actions.is_empty():
        return
    prompt_word.text = _v124_action_title()
    status_label.text = _v124_text("hint")
    next_button.text = _v124_text("next")
    _v125_refresh_speaker()
    _fit_to_viewport()
    _branch_keep_question_frame_stable()
    target_panel.visible = true
    if _branch_question_film != null:
        _branch_question_film.visible = true
    question_label.visible = true
    # Always keep SVG stage artwork out of the scene for every new round.
    stage_art.visible = false
    next_button.visible = false
    next_button.disabled = true
    call_deferred("_v125_speak_action")


func _check_answer(index: int) -> void:
    if answer_solved or index < 0 or index >= candidate_actions.size():
        return
    var chosen: Dictionary = candidate_actions[index]
    if str(chosen.get("id", "")) == str(current_action.get("id", "")):
        _finish_correct()
    else:
        _branch_keep_question_frame_stable()
        status_label.text = _v124_text("retry")
        status_label.add_theme_color_override("font_color", GOLD)
        option_panels[index].add_theme_stylebox_override("panel", _style(Color("422743"), Color("FFA7BE"), 23, 3))
        selected_index = -1
        SFX.play_2d(V125_WRONG_SOUND, get_viewport_rect().size * 0.5, -7.0)
        SFX.play_retry(get_viewport_rect().size * 0.5, 0.0)


func _finish_correct() -> void:
    if answer_solved:
        return
    # Capture the full card BEFORE the base game hides its drag ghost.
    var animated: bool = _branch_drag_card != null and _branch_drag_card.visible and drag_has_moved
    var from_pos: Vector2 = Vector2.ZERO
    var from_size: Vector2 = Vector2.ZERO
    var image: Texture2D = _branch_drag_texture
    if animated:
        from_pos = _branch_drag_card.global_position
        from_size = _branch_drag_card.size
    super._finish_correct()
    if not answer_solved:
        return
    status_label.text = _v124_text("great") + "  " + _v124_action_title()
    stage_art.visible = false
    target_panel.visible = false
    next_button.visible = false
    next_button.disabled = true
    SFX.play_2d(V125_CORRECT_SOUND, get_viewport_rect().size * 0.5, -5.0)
    SFX.play_praise(get_viewport_rect().size * 0.5, 0.0)
    if animated and image != null:
        _branch_make_success_card(image, from_pos, from_size)
    var serial: int = _branch_round_serial
    _branch_advance(serial)


func _branch_advance(serial: int) -> void:
    await get_tree().create_timer(BRANCH_ADVANCE_DELAY, true).timeout
    if not is_inside_tree() or serial != _branch_round_serial or not answer_solved:
        return
    _start_next_round()

# Do not stop the flight-level UI from resetting while leaving this mini-game.
func _exit_tree() -> void:
    _branch_cancel_success_card()
    if ghost != null:
        ghost.self_modulate = Color.WHITE
