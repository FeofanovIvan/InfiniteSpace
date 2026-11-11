extends "res://simulator_ui/where_is_it/scripts/where_is_it.gd"
## MIKA / Where Is It? – native-style toolbar, enlarged 3D cube, sound feedback.
## Independent overlay. The original game and cube_world.gd remain untouched.

const SOUND_CORRECT = "res://learning/audio/sfx/correct.ogg"
const SOUND_WRONG = "res://learning/audio/sfx/wrong.ogg"
const SOUND_CLICK = "res://learning/audio/sfx/connect_point.ogg"
const SOUND_COMPLETE = "res://learning/audio/sfx/coin.ogg"

const INSTRUCTION = {
    "en": "Drag each word to its place around the cube",
    "ru": "Перетащи каждое слово на его место вокруг куба",
    "pt": "Arraste cada palavra para seu lugar ao redor do cubo",
    "es": "Arrastra cada palabra a su lugar alrededor del cubo",
    "fr": "Glisse chaque mot à sa place autour du cube",
    "de": "Ziehe jedes Wort an seinen Platz um den Würfel"
}

var _native_main_panel: Panel
var _native_left_panel: Panel
var _native_right_panel: Panel
var _native_undo_button: Button
var _native_round_prev: Button
var _native_round_next: Button
var _native_round_number: Label
var _native_history: Array[String] = []
var _native_rewarded: Dictionary = {}
var _native_round_history: Dictionary = {}


func _build_stage() -> void:
    super._build_stage()
    # Original top panel, back glyph, crystal counter and 3D mechanics are reused.
    # Hide only the two legacy information rails and their common middle backdrop.
    for node in stage.get_children():
        if node is Panel and node != _crystal_panel and node.position.y > 120.0 and node.position.y < 570.0:
            node.hide()
    lang_picker.hide()
    var restart: Control = stage.get_node_or_null("RestartAll") as Control
    if restart != null:
        restart.hide()
    var rot_title: Control = stage.get_node_or_null("RotateHeading") as Control
    if rot_title != null:
        rot_title.hide()
    var rot_note: Control = stage.get_node_or_null("RotateDescription") as Control
    if rot_note != null:
        rot_note.hide()

    round_label.hide()
    score_label.hide()
    instructions.hide()
    front_hint.hide()
    helper.hide()
    next_button.hide()

    # Top: back left / title with one concise subtitle / session crystals right.
    _back_button.position = Vector2(37, 34)
    _back_button.size = Vector2(69, 63)
    _crystal_panel.position = Vector2(1080, 35)
    _crystal_panel.size = Vector2(160, 60)
    heading.position = Vector2(245, 20)
    heading.size = Vector2(790, 45)
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 28)
    subtitle.position = Vector2(221, 67)
    subtitle.size = Vector2(835, 35)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.add_theme_font_size_override("font_size", 17)

    # Replace three original middle slabs with a main panel and two small tool rails.
    _native_main_panel = _panel(Rect2(184, 134, 914, 425), Color(0.029, 0.078, 0.16, 0.89), Color("54bce8"), 24)
    stage.move_child(_native_main_panel, viewport_box.get_index())
    _native_left_panel = _panel(Rect2(28, 210, 143, 240), Color(0.046, 0.125, 0.24, 0.90), Color("3d86b7"), 21)
    stage.move_child(_native_left_panel, viewport_box.get_index())
    _native_right_panel = _panel(Rect2(1109, 191, 143, 300), Color(0.046, 0.125, 0.24, 0.90), Color("3d86b7"), 21)
    stage.move_child(_native_right_panel, viewport_box.get_index())

    # More space for the actual rotating cube. No changes to the 3D model.
    viewport_box.position = Vector2(205, 146)
    viewport_box.size = Vector2(874, 398)
    view.size = Vector2i(874, 398)
    cube_world.set("orbit_distance", 10.4)
    cube_world.call("reset_view")

    # Left tools: rotate left/right, reverse/reset view.
    prev_view_button.position = Vector2(39, 240)
    prev_view_button.size = Vector2(59, 65)
    next_view_button.position = Vector2(104, 240)
    next_view_button.size = Vector2(59, 65)
    reset_view_button.position = Vector2(42, 337)
    reset_view_button.size = Vector2(116, 66)
    reset_view_button.text = "⟲"
    reset_view_button.tooltip_text = _ui("reset_view")
    reset_view_button.add_theme_font_size_override("font_size", 33)
    prev_view_button.pressed.connect(func(): _native_play_sound(SOUND_CLICK, -15.0))
    next_view_button.pressed.connect(func(): _native_play_sound(SOUND_CLICK, -15.0))
    reset_view_button.pressed.connect(func(): _native_play_sound(SOUND_CLICK, -15.0))

    # Right tools: undo the last completed placement; browse the two rounds.
    _native_undo_button = _button("↶", Rect2(1134, 218, 93, 65), Color("214d70"))
    _native_undo_button.name = "UndoLastPlacement"
    _native_undo_button.tooltip_text = "Undo / Вернуть слово"
    _native_undo_button.pressed.connect(_native_undo)
    _native_round_prev = _button("‹", Rect2(1121, 339, 56, 60), Color("21547b"))
    _native_round_prev.name = "PreviousRound"
    _native_round_prev.pressed.connect(_native_previous_round)
    _native_round_next = _button("›", Rect2(1184, 339, 56, 60), Color("21547b"))
    _native_round_next.name = "NextRound"
    _native_round_next.pressed.connect(_native_next_round)
    _native_round_number = _label("1 / 2", Vector2(1135, 412), Vector2(92, 32), 20, Color("bce9ff"))
    _native_round_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _native_round_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    feedback.position = Vector2(396, 525)
    feedback.size = Vector2(485, 29)
    feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    feedback.autowrap_mode = TextServer.AUTOWRAP_OFF
    feedback.add_theme_font_size_override("font_size", 17)
    _native_update_round_controls()


func _update_language() -> void:
    super._update_language()
    heading.text = _ui("title")
    var locale: String = "en"
    if language_index >= 0 and language_index < languages.size():
        locale = str(languages[language_index].get("code", "en"))
    subtitle.text = str(INSTRUCTION.get(locale, INSTRUCTION["en"]))
    reset_view_button.text = "⟲"
    reset_view_button.tooltip_text = _ui("reset_view")
    next_button.hide()


func _start_new_game() -> void:
    _native_rewarded.clear()
    _native_round_history.clear()
    _native_history.clear()
    super._start_new_game()


func _begin_round() -> void:
    _native_history.clear()
    super._begin_round()
    # Navigating between rounds must not erase already completed placements.
    var remembered: Array = _native_round_history.get(round_index, [])
    for item in remembered:
        var key: String = str(item)
        if not solved.has(key) or bool(solved[key]):
            continue
        solved[key] = true
        cube_world.call("reveal", key)
        var marker: Button = slots[key] as Button
        marker.text = _word(key)
        marker.size = Vector2(minf(170.0, maxf(90.0, float(marker.text.length() * 10 + 22))), 42)
        marker.add_theme_font_size_override("font_size", 15 if marker.text.length() > 14 else 18)
        _apply_button_style(marker, CUBE_WORLD.PALETTE[key].darkened(0.25), Color("e8faff"))
        marker.disabled = true
        (chips[key] as Button).hide()
        _native_history.append(key)
    if next_button != null:
        next_button.hide()
    _native_update_round_controls()


func _native_update_round_controls() -> void:
    if _native_round_number != null:
        _native_round_number.text = "%d / %d" % [round_index + 1, ROUNDS_TOTAL]
    if _native_round_prev != null:
        _native_round_prev.disabled = round_index <= 0
    if _native_round_next != null:
        _native_round_next.disabled = round_index >= ROUNDS_TOTAL - 1
    if _native_undo_button != null:
        _native_undo_button.disabled = _native_history.is_empty()


func _native_previous_round() -> void:
    _native_go_round(-1)


func _native_next_round() -> void:
    _native_go_round(1)


func _native_go_round(direction: int) -> void:
    var next_index: int = round_index + direction
    if next_index < 0 or next_index >= ROUNDS_TOTAL or drag_key != "":
        return
    _native_round_history[round_index] = _native_history.duplicate()
    round_index = next_index
    cube_world.call("reset_view")
    _begin_round()
    _native_play_sound(SOUND_CLICK, -12.0)


func _try_place(key: String, destination: String) -> void:
    if solved.get(destination, false):
        return
    if key != destination:
        feedback.text = _ui("wrong")
        feedback.add_theme_color_override("font_color", Color("ffc48c"))
        _native_play_sound(SOUND_WRONG, -8.0)
        _native_voice(false)
        return
    solved[key] = true
    var reward_id: String = "%d:%s" % [round_index, key]
    if not _native_rewarded.has(reward_id):
        _native_rewarded[reward_id] = true
        score += 1
        _session_crystals += 1
        _crystal_amount.text = str(_session_crystals)
        GameState.add_coins(1)
    cube_world.call("reveal", key)
    var slot: Button = slots[key] as Button
    slot.text = _word(key)
    slot.size = Vector2(minf(170.0, maxf(90.0, float(slot.text.length() * 10 + 22))), 42)
    slot.add_theme_font_size_override("font_size", 15 if slot.text.length() > 14 else 18)
    _apply_button_style(slot, CUBE_WORLD.PALETTE[key].darkened(0.25), Color("e8faff"))
    slot.disabled = true
    var chip: Button = chips[key] as Button
    chip.visible = false
    selected_key = ""
    _refresh_chips()
    feedback.text = _ui("correct")
    feedback.add_theme_color_override("font_color", OK_COLOR)
    _native_history.append(key)
    _native_round_history[round_index] = _native_history.duplicate()
    _update_score()
    _native_update_round_controls()
    _native_play_sound(SOUND_CORRECT, -8.0)
    _native_voice(true)
    if _all_solved():
        feedback.text = _ui("done")
        _native_play_sound(SOUND_COMPLETE, -9.0)
        # New round is navigated via arrows, never an extra Next button.
        next_button.hide()


func _native_undo() -> void:
    if _native_history.is_empty() or drag_key != "":
        return
    var key: String = _native_history.pop_back()
    solved[key] = false
    _native_round_history[round_index] = _native_history.duplicate()
    var figure_map: Dictionary = cube_world.get("figures")
    if figure_map.has(key):
        var figure: Node = figure_map[key] as Node
        if is_instance_valid(figure):
            figure.queue_free()
        figure_map.erase(key)
    var slot: Button = slots[key] as Button
    slot.disabled = false
    slot.text = "?"
    slot.size = Vector2(52, 48)
    slot.add_theme_font_size_override("font_size", 25)
    _apply_button_style(slot, Color("163047"), CUBE_WORLD.PALETTE[key])
    var chip: Button = chips[key] as Button
    chip.visible = true
    feedback.text = _ui("pick_hint")
    _refresh_chips()
    _native_update_round_controls()
    _native_play_sound(SOUND_CLICK, -12.0)
    # Crystals are not deducted, but the same word can never award twice.


func _begin_chip_press(key: String, point: Vector2) -> void:
    super._begin_chip_press(key, point)
    _native_play_sound(SOUND_CLICK, -20.0)


func _update_slot_positions() -> void:
    if viewport_box == null:
        return
    var x0: float = viewport_box.position.x + 6.0
    var x1: float = viewport_box.position.x + viewport_box.size.x - 6.0
    var y0: float = viewport_box.position.y + 5.0
    var y1: float = viewport_box.position.y + viewport_box.size.y - 5.0
    for key in active_keys:
        var b: Button = slots[key] as Button
        if cube_world.call("is_anchor_behind_camera", key):
            b.hide()
            continue
        b.show()
        var projected: Vector2 = cube_world.call("project_key", key)
        b.position = viewport_box.position + projected - b.size * 0.5
        b.position.x = clampf(b.position.x, x0, x1 - b.size.x)
        b.position.y = clampf(b.position.y, y0, y1 - b.size.y)


func _native_play_sound(path: String, volume_db: float) -> void:
    if not ResourceLoader.exists(path):
        return
    var audio: Node = get_node_or_null("/root/SFX")
    if audio != null and audio.has_method("play_2d"):
        audio.call("play_2d", load(path) as AudioStream, get_viewport_rect().size * 0.5, volume_db)


func _native_voice(correct: bool) -> void:
    var audio: Node = get_node_or_null("/root/SFX")
    if audio == null:
        return
    var method: String = "play_praise" if correct else "play_retry"
    if audio.has_method(method):
        # Immediate playback while flight is paused; no delayed audio queue.
        audio.call(method, get_viewport_rect().size * 0.5, 0.0)
