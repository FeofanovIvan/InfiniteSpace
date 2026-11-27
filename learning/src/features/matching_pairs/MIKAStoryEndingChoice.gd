extends "res://learning/src/features/matching_pairs/mika_matching_pairs_session_cap_v3_2.gd"
## Story-only presentation using the real Matching Pairs scene and door assets.
## MIKA_CH07_PAIRS_ENDING_V2 — one native round, then choose the last two doors.
## The free game and ending consequences remain unchanged.
signal ending_selected(ending_id: String)
const ENDING_DOOR: Script = preload("res://learning/src/features/matching_pairs/MIKAEndingDoor.gd")
const LEFT_ART: Texture2D = preload("res://learning/assets/matching_pairs/story_endings/ending_1.png")
const RIGHT_ART: Texture2D = preload("res://learning/assets/matching_pairs/story_endings/ending_2.png")
const ENDING_COPY: Dictionary = {
    "ru": ["Выбери концовку", "Не переживай, ты всегда можешь вернуться и выбрать другую.", "Войти"],
    "en": ["Choose your ending", "Don't worry, you can always come back and choose another.", "Enter"],
    "pt": ["Escolha o final", "Não se preocupe, você sempre pode voltar e escolher outro.", "Entrar"],
    "es": ["Elige el final", "No te preocupes, siempre puedes volver y elegir otro.", "Entrar"],
    "fr": ["Choisis la fin", "Ne t'inquiète pas, tu peux toujours revenir et en choisir une autre.", "Entrer"],
    "de": ["Wähle dein Ende", "Keine Sorge, du kannst immer zurückkommen und ein anderes Ende wählen.", "Eintreten"]
}
var _ending_phase: bool = false
var _ending_selected_index: int = -1
var _ending_enter: Button
var _ending_switching: bool = false

func _build_ui() -> void:
    super._build_ui()
    _ending_enter = Button.new()
    _ending_enter.name = "MIKAEnterEnding"
    _ending_enter.focus_mode = Control.FOCUS_NONE
    _ending_enter.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _ending_enter.add_theme_stylebox_override("normal", MIKA_UI_KIT.button_style())
    _ending_enter.add_theme_stylebox_override("hover", MIKA_UI_KIT.button_style(true))
    _ending_enter.add_theme_stylebox_override("pressed", MIKA_UI_KIT.button_style(true))
    _ending_enter.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _ending_enter.pressed.connect(_confirm_ending)
    ui_layer.add_child(_ending_enter)
    _ending_enter.hide()

func _ending_apply_copy() -> void:
    if not _ending_phase or not is_instance_valid(_mika_header_label):
        return
    var code: String = str(MobileLocale.language).to_lower().get_slice("_", 0).get_slice("-", 0)
    var copy: Array = ENDING_COPY.get(code, ENDING_COPY["en"])
    _mika_header_label.text = str(copy[0])
    _mika_header_subtitle.text = str(copy[1])
    if is_instance_valid(_ending_enter):
        _ending_enter.text = str(copy[2])

func _mika_on_language_changed(locale: String) -> void:
    if not _ending_phase:
        super._mika_on_language_changed(locale)
        return
    _ending_apply_copy()
    _layout()

func _layout() -> void:
    if _ending_phase:
        _ending_apply_copy()
    super._layout()
    if not is_instance_valid(_mika_header_title):
        return
    _ending_apply_copy()
    # Keep the mandatory story round on this screen.
    _mika_header_back.hide()
    _mika_header_back.disabled = true
    if not _ending_phase:
        return
    # Native toolbar plaque, now with its own existing subtitle visible.
    var width: float = _mika_header_title.size.x
    var height: float = _mika_header_title.size.y
    _mika_header_label.position = Vector2(6.0, height * 0.03)
    _mika_header_label.size = Vector2(maxf(24.0, width - 12.0), height * 0.45)
    _mika_header_label.add_theme_font_size_override("font_size", maxi(10, int(height * 0.32)))
    _mika_header_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _mika_header_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _mika_header_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _mika_header_subtitle.position = Vector2(8.0, height * 0.49)
    _mika_header_subtitle.size = Vector2(maxf(24.0, width - 16.0), height * 0.47)
    _mika_header_subtitle.add_theme_font_size_override("font_size", maxi(8, int(height * 0.18)))
    _mika_header_subtitle.show()
    _layout_doors(false)

func _start_new_round() -> void:
    # The native v3.1 round: five pairs, ten doors. The subclass is identical
    # to the native octagonal door until art is assigned to the last two.
    if _ending_phase:
        return
    _m33_wrong_streak = 0
    input_locked = true
    first_door = null
    round_number += 1
    for old_door in doors:
        if is_instance_valid(old_door):
            old_door.queue_free()
    doors.clear()
    var available: Array = SYMBOL_POOL.duplicate(true)
    available.shuffle()
    var pairs: Array[Dictionary] = []
    for index in range(5):
        pairs.append(available[index])
        pairs.append(available[index].duplicate())
    pairs.shuffle()
    for symbol in pairs:
        var door: MatchingDoor = ENDING_DOOR.new() as MatchingDoor
        door.configure(symbol["kind"], symbol["color"])
        door.selected.connect(_on_door_selected)
        door.modulate.a = 0.0
        add_child(door)
        doors.append(door)
    _layout_doors(false)
    for index in range(doors.size()):
        var door: MatchingDoor = doors[index]
        var tween: Tween = create_tween()
        tween.tween_interval(float(index) * 0.045)
        tween.tween_property(door, "modulate:a", 1.0, 0.18)
    input_locked = false

func _begin_ending_choice() -> void:
    if _ending_phase or doors.size() != 2:
        return
    input_locked = true
    _ending_phase = true
    first_door = null
    _ending_selected_index = -1
    _ending_switching = false
    # Keep exactly the two surviving door nodes. No additional round, no
    # replacing them with a separate scene, no extra match or free crystal.
    voice_player.stop()
    if _m33_action_voice != null:
        _m33_action_voice.stop_feedback()
    for index in range(2):
        var door: MatchingDoor = doors[index]
        door.set_revealed(false, false)
        door.call("set_ending_art", LEFT_ART if index == 0 else RIGHT_ART)
    _ending_enter.hide()
    _layout()
    input_locked = false

func _layout_doors(animated: bool) -> void:
    if not _ending_phase:
        # The native match handler calls layout immediately after removing a
        # pair. At two remaining doors, the choice layout owns their positions.
        if doors.size() != 2:
            super._layout_doors(animated)
        return
    if doors.size() != 2 or _mika_stage_bounds.size.x < 70.0:
        return
    var area: Rect2 = _mika_stage_bounds.grow(-maxf(8.0, _mika_stage_bounds.size.y * 0.035))
    var gap: float = clampf(area.size.x * 0.055, 12.0, 60.0)
    var button_h: float = clampf(area.size.y * 0.13, 32.0, 66.0)
    var top_space: float = area.size.y * 0.025
    var room_h: float = maxf(30.0, area.size.y - button_h - top_space - 12.0)
    var door_w: float = minf((area.size.x - gap) * 0.5, room_h * 600.0 / 606.0)
    var door_h: float = door_w * 606.0 / 600.0
    var start: Vector2 = Vector2(area.get_center().x - door_w - gap * 0.5, area.position.y + top_space + (room_h - door_h) * 0.5)
    for i in range(2):
        doors[i].size = Vector2(door_w, door_h)
        doors[i].pivot_offset = doors[i].size * 0.5
        doors[i].position = start + Vector2(i * (door_w + gap), 0.0)
    if is_instance_valid(_ending_enter):
        var button_w: float = minf(area.size.x * 0.55, maxf(110.0, door_w * 0.85))
        _ending_enter.size = Vector2(button_w, button_h)
        _ending_enter.position = Vector2(area.get_center().x - button_w * 0.5, area.end.y - button_h)
        _ending_enter.add_theme_font_size_override("font_size", maxi(13, int(button_h * 0.40)))

func _on_door_selected(door: MatchingDoor) -> void:
    if input_locked or _ending_switching or not doors.has(door):
        return
    if not _ending_phase:
        # Existing selection, comparison, audio, error handling, score and
        # disappearance animation — only intercept after the fourth match.
        await super._on_door_selected(door)
        if is_inside_tree() and not input_locked and doors.size() == 2:
            _begin_ending_choice()
        return
    var index: int = doors.find(door)
    if index == _ending_selected_index:
        return
    input_locked = true
    _ending_switching = true
    _ending_enter.hide()
    if _ending_selected_index >= 0:
        door_close_player.stop()
        door_close_player.play()
        await doors[_ending_selected_index].set_revealed(false)
        if not is_inside_tree():
            return
    door_open_player.stop()
    door_open_player.play()
    await door.set_revealed(true)
    if not is_inside_tree():
        return
    _ending_selected_index = index
    _ending_switching = false
    input_locked = false
    _ending_enter.show()

func _confirm_ending() -> void:
    if not _ending_phase or input_locked or _ending_switching or _ending_selected_index < 0:
        return
    # The final decision callback is intentionally not implemented here.
    # No saved choice, crew changes, travel or end-of-story completion yet.
    ending_selected.emit("ending_1" if _ending_selected_index == 0 else "ending_2")

func _play_instruction() -> void:
    if not _ending_phase:
        super._play_instruction()

func _go_home() -> void:
    # The regular Back must not change the main scene during the story finale.
    pass
