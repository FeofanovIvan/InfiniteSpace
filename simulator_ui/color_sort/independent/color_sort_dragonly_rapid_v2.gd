extends "res://simulator_ui/color_sort/scripts/color_sort.gd"
## Color Sort: approved Simulator header, responsive original gameplay,
## drag-only sorting, strong responsive acceleration, infinite deck, checkpoint, MikaVoice and KTS SFX.
## Never modifies the original Color Sort script or graphics.

const SHARED_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const SHARED_UI = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const ORIGINAL_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const GOOD_SFX: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const BAD_SFX: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
const PICK_SFX: AudioStream = preload("res://education/playtown/audio/sfx/connect_point.ogg")
const COIN_SFX: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
const CHECKPOINT: int = 18
# A success multiplies the speed by 1.38; seven wins reach about 8.5x.
const SPEED_GAIN_PER_SUCCESS: float = 1.38
const SPEED_LIMIT: float = 8.5
const MESSAGES: Dictionary = {
    "en": {"move": "Move into the basket", "done": "Great sorting!", "again": "Try again", "change": "Change set", "exit": "Exit", "summary": "18 shapes sorted! Choose what to do next."},
    "ru": {"move": "Перемести в корзину", "done": "Отличная сортировка!", "again": "Попробовать ещё", "change": "Сменить набор", "exit": "Выйти", "summary": "18 фигур на своих местах! Что дальше?"},
    "pt": {"move": "Mova para a cesta", "done": "Muito bem!", "again": "Tentar de novo", "change": "Trocar conjunto", "exit": "Sair", "summary": "18 formas separadas! O que fazer agora?"},
    "es": {"move": "Mueve a la cesta", "done": "¡Muy bien!", "again": "Intentar otra vez", "change": "Cambiar conjunto", "exit": "Salir", "summary": "¡18 figuras clasificadas! ¿Qué hacemos ahora?"},
    "de": {"move": "In den Korb bewegen", "done": "Gut sortiert!", "again": "Noch einmal", "change": "Set wechseln", "exit": "Verlassen", "summary": "18 Formen sortiert! Wie geht es weiter?"},
    "fr": {"move": "Déplace dans le panier", "done": "Bravo pour le tri !", "again": "Réessayer", "change": "Changer de série", "exit": "Quitter", "summary": "18 formes triées ! Que faire ensuite ?"}
}

var _ui_title_panel: Panel = null
var _ui_native_hud: Control = null
var _ui_audio: AudioStreamPlayer = null
var _ui_modal_shade: ColorRect = null
var _ui_modal_actions: HBoxContainer = null
var _ui_try_button: Button = null
var _ui_change_button: Button = null
var _ui_exit_button: Button = null
var _ui_checkpoint_progress: int = 0
var _ui_fast_streak: int = 0
var _ui_speed_multiplier: float = 1.0
var _ui_spawned_at_ms: int = 0
var _ui_pointer_down: Vector2 = Vector2.ZERO
var _ui_shape_at_press: Vector2 = Vector2.ZERO
var _ui_drag_moved: bool = false
var _ui_dialog_active: bool = false


func _ready() -> void:
    super._ready()
    # Header components exist only after the original UI creation sequence.
    _ui_layout()


func _init_ui() -> void:
    super._init_ui()
    _ui_title_panel = Panel.new()
    _ui_title_panel.name = "ApprovedSimulatorTitlePlaque"
    _ui_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    SHARED_TOOLBAR.apply_title_style(_ui_title_panel)
    add_child(_ui_title_panel)
    title_label.reparent(_ui_title_panel, false)
    subtitle_label.reparent(_ui_title_panel, false)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title_label.clip_text = true
    subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    subtitle_label.clip_text = true
    subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    _ui_audio = AudioStreamPlayer.new()
    _ui_audio.name = "KTSColorSortSfx"
    _ui_audio.process_mode = Node.PROCESS_MODE_ALWAYS
    _ui_audio.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
    _ui_audio.volume_db = -6.0
    add_child(_ui_audio)

    # Reuse original finished dialog, but provide the agreed three decisions.
    next_button.visible = false
    _ui_modal_actions = HBoxContainer.new()
    _ui_modal_actions.name = "ColorSortCheckpointActions"
    _ui_modal_actions.add_theme_constant_override("separation", 9)
    var column: VBoxContainer = completed_panel.get_child(0) as VBoxContainer
    column.add_child(_ui_modal_actions)
    for label_key in ["again", "change", "exit"]:
        var action_button := Button.new()
        action_button.name = "Action_" + label_key
        action_button.focus_mode = Control.FOCUS_NONE
        action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        action_button.custom_minimum_size = Vector2(105, 51)
        action_button.add_theme_stylebox_override("normal", SHARED_UI.button_style(false))
        action_button.add_theme_stylebox_override("hover", SHARED_UI.button_style(true))
        action_button.add_theme_stylebox_override("pressed", SHARED_UI.button_style(true))
        action_button.add_theme_color_override("font_color", SHARED_UI.PAPER)
        action_button.add_theme_font_size_override("font_size", 16)
        _ui_modal_actions.add_child(action_button)
        if label_key == "again":
            _ui_try_button = action_button
            action_button.pressed.connect(_ui_repeat_same_set)
        elif label_key == "change":
            _ui_change_button = action_button
            action_button.pressed.connect(_ui_change_set)
        else:
            _ui_exit_button = action_button
            action_button.pressed.connect(_exit_to_simulator)

    _ui_modal_shade = ColorRect.new()
    _ui_modal_shade.name = "ColorSortCheckpointDim"
    _ui_modal_shade.color = Color(0.008, 0.020, 0.060, 0.68)
    _ui_modal_shade.mouse_filter = Control.MOUSE_FILTER_STOP
    _ui_modal_shade.visible = false
    add_child(_ui_modal_shade)
    completed_panel.visible = false

    # No separate language, New Set, Pause, Round and Score interface.
    language_select.hide()
    new_set_button.hide()
    pause_button.hide()
    round_label.hide()
    score_label.hide()
    info_label.hide()
    next_button.hide()


func _build_simulator_hud() -> void:
    super._build_simulator_hud()
    _crystal_panel.hide()
    _ui_native_hud = ORIGINAL_HUD.new() as Control
    _ui_native_hud.name = "ExactPlanetHubCrystalCounter"
    _ui_native_hud.size = Vector2(1680, 158)
    _ui_native_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_ui_native_hud)
    for n in ["SimulatorButton", "LaunchButton"]:
        var control: Control = _ui_native_hud.get_node_or_null(n) as Control
        if control != null:
            control.hide()
    _ui_native_hud.set("crystal_count", _session_crystals)

    # Prefer the simulator host's real button style when available.
    var parent_node: Node = get_parent()
    for _i in range(15):
        if parent_node == null:
            break
        if parent_node.has_method("_style_back_button"):
            for old_glyph in _back_button.get_children():
                _back_button.remove_child(old_glyph)
                old_glyph.free()
            parent_node.call("_style_back_button", _back_button)
            break
        parent_node = parent_node.get_parent()


func _ui_safe_area() -> Rect2:
    var screen := size
    if OS.get_name() not in ["Android", "iOS"]:
        return Rect2(Vector2.ZERO, screen)
    var window_size := Vector2(DisplayServer.window_get_size())
    var os_safe: Rect2i = DisplayServer.get_display_safe_area()
    if window_size.x <= 0 or window_size.y <= 0 or os_safe.size.x <= 0 or os_safe.size.y <= 0:
        return Rect2(Vector2.ZERO, screen)
    var coeff := screen / window_size
    return Rect2(Vector2(os_safe.position) * coeff, Vector2(os_safe.size) * coeff)


func _relayout() -> void:
    super._relayout()
    _ui_layout()


func _ui_layout() -> void:
    if _ui_native_hud == null or _ui_title_panel == null or size.x < 240.0 or size.y < 220.0:
        return
    var safe: Rect2 = _ui_safe_area()
    var w: float = size.x
    var h: float = size.y
    _flight_space.position = Vector2.ZERO
    _flight_space.size = size
    var header_end: float = SHARED_TOOLBAR.relayout(size, safe, _back_button, _ui_native_hud,
            _ui_title_panel, title_label, subtitle_label)
    var narrow: bool = w < 900.0
    var margin: float = clampf(safe.size.x * 0.015, 9.0, 24.0)
    var game_top: float = maxf(safe.position.y + 47.0, header_end + clampf(h * 0.017, 6.0, 17.0))
    var footer_h: float = clampf(h * 0.076, 27.0, 58.0)
    play_top = game_top + 15.0
    play_bottom = minf(safe.end.y - footer_h, h - 30.0)
    var playable_height := maxf(110.0, play_bottom - play_top)
    basket_width = clampf(safe.size.x * (0.205 if not narrow else 0.195), 95.0, 265.0)
    var side_margin := clampf(safe.size.x * 0.016, 9.0, 26.0)
    chute_width = clampf(safe.size.x * 0.17, 95.0, 243.0)
    # Four baskets remain in the original two-by-two arrangement.
    var center_space := safe.size.x - 2.0 * (basket_width + side_margin)
    if center_space < chute_width + 30.0:
        basket_width = maxf(90.0, (safe.size.x - chute_width - 50.0) * 0.5)
    basket_height = maxf(45.0, (playable_height - 43.0) * 0.5)
    var basket_left: float = safe.position.x + side_margin
    var basket_right: float = safe.end.x - side_margin - basket_width
    basket_rects = [
        Rect2(basket_left, play_top + 7.0, basket_width, basket_height),
        Rect2(basket_left, play_top + 30.0 + basket_height, basket_width, basket_height),
        Rect2(basket_right, play_top + 7.0, basket_width, basket_height),
        Rect2(basket_right, play_top + 30.0 + basket_height, basket_width, basket_height)
    ]
    var base_speed: float = maxf(24.0, playable_height / 10.0)
    fall_speed = base_speed * _ui_speed_multiplier
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tip_label.position = Vector2(safe.position.x + margin, play_bottom + 5.0)
    tip_label.size = Vector2(maxf(45.0, safe.size.x - 2.0 * margin), 25.0)
    tip_label.add_theme_font_size_override("font_size", 13 if narrow else 17)
    tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    tip_label.visible = true
    round_label.hide()
    score_label.hide()
    language_select.hide()
    new_set_button.hide()
    pause_button.hide()
    info_label.hide()
    _crystal_panel.hide()
    _ui_modal_shade.position = Vector2.ZERO
    _ui_modal_shade.size = size
    var dialog_w: float = minf(safe.size.x - 20.0, 560.0)
    var dialog_h: float = clampf(safe.size.y * 0.43, 178.0, 260.0)
    completed_panel.position = Vector2(safe.position.x + (safe.size.x - dialog_w) * 0.5,
            safe.position.y + (safe.size.y - dialog_h) * 0.5)
    completed_panel.size = Vector2(dialog_w, dialog_h)
    _ui_modal_actions.add_theme_constant_override("separation", 4 if narrow else 12)
    for button in [_ui_try_button, _ui_change_button, _ui_exit_button]:
        button.add_theme_font_size_override("font_size", 11 if narrow else 16)
        button.custom_minimum_size = Vector2(62.0 if narrow else 105.0, 47.0)
    if active and not dragging:
        current_x = w * 0.5
    queue_redraw()


func _update_labels() -> void:
    super._update_labels()
    # The design language belongs to Settings, not to another selector.
    var texts: Dictionary = MESSAGES.get(language, MESSAGES["en"])
    tip_label.text = _t("hole")
    info_label.hide()
    round_label.hide()
    score_label.hide()
    new_set_button.hide()
    pause_button.hide()
    language_select.hide()
    completed_title.text = str(texts["done"])
    completed_body.text = str(texts["summary"])
    next_button.hide()
    if _ui_try_button != null:
        _ui_try_button.text = str(texts["again"])
        _ui_change_button.text = str(texts["change"])
        _ui_exit_button.text = str(texts["exit"])
    if _ui_native_hud != null:
        _ui_native_hud.set("crystal_count", _session_crystals)


func _start_new_set() -> void:
    _ui_checkpoint_progress = 0
    _ui_fast_streak = 0
    _ui_speed_multiplier = 1.0
    _ui_dialog_active = false
    super._start_new_set()
    if _ui_modal_shade != null:
        _ui_modal_shade.hide()
    if completed_panel != null:
        completed_panel.hide()
    _ui_layout()


func _ui_refill_deck() -> void:
    deck.clear()
    for _i in range(3):
        for target in targets:
            deck.append(target.duplicate())
    deck.shuffle()
    spawned = 0


func _spawn_next() -> void:
    if _ui_dialog_active:
        return
    if deck.is_empty() or spawned >= deck.size():
        _ui_refill_deck()
    if deck.is_empty():
        return
    current_shape = deck[spawned].duplicate()
    spawned += 1
    current_x = size.x * 0.5
    current_y = play_top + 67.0
    active = true
    dragging = false
    drag_pointer = -1
    spawn_wait = 0.0
    _ui_spawned_at_ms = Time.get_ticks_msec()
    _update_labels()
    _ui_speak_current_shape()


func _ui_speak_current_shape() -> void:
    if current_shape.is_empty():
        return
    var speaker: Node = get_node_or_null("/root/MikaVoice")
    if speaker == null or not speaker.has_method("speak_text"):
        return
    var shape_key: String = str(current_shape.get("shape", ""))
    var color_key: String = str(current_shape.get("color", ""))
    var shapes: Dictionary = SHAPE_NAMES.get(language, SHAPE_NAMES["en"])
    var colors: Dictionary = COLOR_NAMES.get(language, COLOR_NAMES["en"])
    # Two independent concepts avoids adjective gender mismatch across locales.
    var phrase: String = "%s. %s." % [str(shapes.get(shape_key, shape_key)), str(colors.get(color_key, color_key))]
    var locale: String = "pt_BR" if language == "pt" else language
    speaker.call("speak_text", phrase, locale, "tablet")


func _ui_speak_move_hint() -> void:
    var speaker: Node = get_node_or_null("/root/MikaVoice")
    if speaker == null or not speaker.has_method("speak_text"):
        return
    var locale: String = "pt_BR" if language == "pt" else language
    speaker.call("speak_text", str(MESSAGES.get(language, MESSAGES["en"])["move"]), locale, "tablet")


func _ui_play_sound(sound: AudioStream) -> void:
    if _ui_audio == null or sound == null:
        return
    _ui_audio.stop()
    _ui_audio.stream = sound
    _ui_audio.play()


func _ui_feedback_voice(correct_answer: bool) -> void:
    var service: Node = get_node_or_null("/root/SFX")
    if service == null:
        return
    if correct_answer and service.has_method("play_praise"):
        service.call("play_praise", Vector2.ZERO, 0.3)
    elif not correct_answer and service.has_method("play_retry"):
        service.call("play_retry", Vector2.ZERO, 0.2)


func _ui_base_fall_speed() -> float:
    # Match the initial velocity used by the approved responsive layout.
    return maxf(24.0, maxf(110.0, play_bottom - play_top) / 10.0)


func _ui_accelerate_after_success() -> void:
    # Every successful drop counts, regardless of how long it took.
    _ui_fast_streak = mini(_ui_fast_streak + 1, 32)
    _ui_speed_multiplier = minf(SPEED_LIMIT, pow(SPEED_GAIN_PER_SUCCESS, float(_ui_fast_streak)))
    fall_speed = _ui_base_fall_speed() * _ui_speed_multiplier
    # A quick game needs new pieces quickly, too. Avoid zero-time spawns.
    spawn_wait = clampf(0.60 / _ui_speed_multiplier, 0.14, 0.60)


func _ui_reset_pace() -> void:
    # Missing a falling piece / failing a drop immediately restores base speed.
    _ui_fast_streak = 0
    _ui_speed_multiplier = 1.0
    fall_speed = _ui_base_fall_speed()


func _choose_basket(index: int) -> void:
    # Only a RELEASE of a real drag may call this method. A tap on a basket
    # is handled by _press_at() below and never arrives here.
    if _ui_dialog_active or not active or paused or complete or index < 0 or index >= targets.size():
        return
    var count_before: int = scored
    super._choose_basket(index)
    if scored > count_before:
        _ui_play_sound(GOOD_SFX)
        _ui_feedback_voice(true)
        _ui_checkpoint_progress += 1
        _ui_accelerate_after_success()
        if _ui_checkpoint_progress >= CHECKPOINT:
            call_deferred("_ui_show_checkpoint")
    else:
        # A wrong dragged choice is also a sign to make the next attempt easier.
        _ui_reset_pace()
        _ui_play_sound(BAD_SFX)
        _ui_feedback_voice(false)


func _on_missed() -> void:
    super._on_missed()
    _ui_reset_pace()
    spawn_wait = 0.65
    _ui_play_sound(BAD_SFX)


func _press_at(point: Vector2, pointer: int) -> void:
    if point.y < play_top or point.y > play_bottom:
        return
    if point.distance_to(Vector2(current_x, current_y)) <= 58.0:
        _ui_pointer_down = point
        _ui_shape_at_press = Vector2(current_x, current_y)
        _ui_drag_moved = false
        dragging = true
        drag_pointer = pointer
        hovered_bin = -1
        _ui_play_sound(PICK_SFX)
        return
    if _basket_at(point) >= 0:
        # Tap only: do not move, score, consume, or change the falling shape.
        _show_feedback(str(MESSAGES.get(language, MESSAGES["en"])["move"]), true)
        _ui_speak_move_hint()
        queue_redraw()


func _move_drag(point: Vector2) -> void:
    if point.distance_to(_ui_pointer_down) >= 13.0:
        _ui_drag_moved = true
    if not _ui_drag_moved:
        return
    super._move_drag(point)


func _release_at(point: Vector2, pointer: int) -> void:
    if not dragging or pointer != drag_pointer:
        return
    if not _ui_drag_moved and point.distance_to(_ui_pointer_down) < 13.0:
        dragging = false
        drag_pointer = -1
        hovered_bin = -1
        current_x = _ui_shape_at_press.x
        current_y = _ui_shape_at_press.y
        _show_feedback(str(MESSAGES.get(language, MESSAGES["en"])["move"]), true)
        _ui_speak_move_hint()
        queue_redraw()
        return
    super._release_at(point, pointer)
    drag_pointer = -1


func _ui_show_checkpoint() -> void:
    if _ui_dialog_active or _ui_checkpoint_progress < CHECKPOINT:
        return
    _ui_dialog_active = true
    complete = true
    active = false
    dragging = false
    hovered_bin = -1
    _ui_modal_shade.show()
    completed_panel.show()
    move_child(_ui_modal_shade, get_child_count() - 1)
    move_child(completed_panel, get_child_count() - 1)
    _ui_play_sound(COIN_SFX)
    _update_labels()
    queue_redraw()


func _ui_repeat_same_set() -> void:
    _ui_play_sound(PICK_SFX)
    _ui_dialog_active = false
    _ui_checkpoint_progress = 0
    _ui_fast_streak = 0
    _ui_speed_multiplier = 1.0
    paused = false
    complete = false
    active = false
    dragging = false
    scored = 0
    missed = 0
    basket_counts = [0, 0, 0, 0]
    _ui_refill_deck()
    _ui_modal_shade.hide()
    completed_panel.hide()
    effects.clear()
    spawn_wait = 0.2
    _ui_layout()
    _update_labels()


func _ui_change_set() -> void:
    _ui_play_sound(PICK_SFX)
    _start_new_set()


func _draw_background() -> void:
    var w: float = size.x
    var h: float = size.y
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.024, 0.060, 0.13), true)
    # The agreed Simulator stage style, no redundant score bar below the header.
    var bg_rect := Rect2(Vector2(12.0, play_top - 14.0),
            Vector2(maxf(1.0, w - 24.0), maxf(1.0, play_bottom - play_top + 35.0)))
    draw_style_box(SHARED_UI.stage_style(), bg_rect)
    _draw_glow(Vector2(w * 0.11, h * 0.32), 205, Color("285fb0"), 0.05)
    _draw_glow(Vector2(w * 0.88, h * 0.70), 205, Color("1a7a9b"), 0.05)
