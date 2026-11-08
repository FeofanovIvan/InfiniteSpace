extends Node
## v108.4: attach three separate speakers to LIVE dialogue choice buttons.
## This Node is created by representative_dialog.gd, not guessed from tablet UI.
const CLOUD_SPEAKER: Script = preload("res://addons/mika_voice/MikaCloudSpeakerButton.gd")

var _dialog: Control
var _tablet: Node
var _clock: float = 0.0
var _attempts: int = 0
var _warned: bool = false
var _found: bool = false

func _ready() -> void:
    _dialog = get_parent() as Control
    if _dialog == null:
        set_process(false)
        return
    _tablet = _dialog.get_node_or_null("TranslatorTablet")
    _update_buttons()
    set_process(true)

func _process(delta: float) -> void:
    _clock += delta
    if _clock < 0.20:
        return
    _clock = 0.0
    _update_buttons()

func _current_suggestions() -> Array[String]:
    var result: Array[String] = []
    if _tablet != null and is_instance_valid(_tablet) and _tablet.has_method("get_suggestions"):
        var values: Variant = _tablet.call("get_suggestions")
        if values is Array:
            for value in values:
                result.append(str(value))
    return result

func _locale() -> String:
    if _tablet != null and is_instance_valid(_tablet) and _tablet.has_method("get_language"):
        return str(_tablet.call("get_language"))
    var loc: Node = get_node_or_null("/root/MobileLocale")
    if loc != null:
        return str(loc.get("language"))
    return "en"

func _selected() -> int:
    if _tablet != null and is_instance_valid(_tablet) and _tablet.has_method("get_selected_suggestion"):
        return int(_tablet.call("get_selected_suggestion"))
    return 0

func _visit(node: Node, result: Array[Button], suggestions: Array[String]) -> void:
    if node is Button:
        var button: Button = node as Button
        var id: String = str(button.name).to_lower()
        if not (id.contains("speaker") or id.contains("microphone") or id.contains("back")):
            var phrase: String = _get_phrase(button)
            var named: bool = id.contains("questionoption") or id.contains("question_option") or id.contains("phrasechoice") or id.contains("phrase_choice") or id.contains("hintchoice") or id.contains("hint_choice")
            var cloud: bool = button.has_method("get_phrase") or button.get_node_or_null("CloudText") is Label
            var matched: bool = suggestions.has(phrase) and not phrase.is_empty()
            if (named or cloud or matched) and not result.has(button):
                result.append(button)
                return
    for child in node.get_children():
        _visit(child, result, suggestions)

func _get_phrase(button: Button) -> String:
    if button.has_method("get_phrase"):
        var p: String = str(button.call("get_phrase")).strip_edges()
        if not p.is_empty():
            return p
    var label: Label = button.get_node_or_null("CloudText") as Label
    if label != null and not label.text.strip_edges().is_empty():
        return label.text.strip_edges()
    return button.text.strip_edges()

func _choice_buttons(suggestions: Array[String]) -> Array[Button]:
    var list: Array[Button] = []
    var area: Node = _dialog.find_child("LeftQuestionChoices", true, false)
    if area == null:
        area = _dialog.find_child("ChoicesLayout", true, false)
    if area != null:
        _visit(area, list, suggestions)
    if list.is_empty():
        _visit(_dialog, list, suggestions)
    if list.size() > 3:
        list.resize(3)
    return list

func _make_scroll() -> void:
    var dock: PanelContainer = _dialog.find_child("LeftQuestionChoices", true, false) as PanelContainer
    if dock == null:
        return
    var column: VBoxContainer = dock.find_child("ChoicesLayout", true, false) as VBoxContainer
    if column == null or column.get_parent() != dock:
        return
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.name = "MikaChoiceScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.clip_contents = true
    dock.add_child(scroll)
    column.reparent(scroll)
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _speaker_for(button: Button, index: int) -> Button:
    var parent: Node = button.get_parent()
    if parent is HBoxContainer and str(parent.name).begins_with("MikaChoiceRow_"):
        return _find_or_make_speaker(parent, index)
    if parent is VBoxContainer:
        var column: VBoxContainer = parent as VBoxContainer
        var at: int = button.get_index()
        var row: HBoxContainer = HBoxContainer.new()
        row.name = "MikaChoiceRow_%d" % index
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        row.add_theme_constant_override("separation", 13)
        column.add_child(row)
        column.move_child(row, at)
        button.reparent(row)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.size_flags_vertical = Control.SIZE_EXPAND_FILL
        return _find_or_make_speaker(row, index)
    # Safe fallback for a nonstandard dialog structure: a speaker attached
    # to the dialogue root instead of inside the text/button hitbox.
    var name: String = "MikaStandaloneCloudSpeaker_%d" % index
    var fallback: Button = _dialog.get_node_or_null(name) as Button
    if fallback == null:
        fallback = CLOUD_SPEAKER.new() as Button
        if fallback == null:
            return null
        fallback.name = name
        _dialog.add_child(fallback)
    var rect: Rect2 = button.get_global_rect()
    var screen_left: Vector2 = _dialog.global_position
    var max_right: float = _dialog.size.x * 0.5 - 52.0
    fallback.position = Vector2(minf(rect.end.x - screen_left.x + 10.0, max_right), rect.position.y - screen_left.y + maxf(0.0, (rect.size.y - 44.0) * 0.5))
    fallback.size = Vector2(44.0, 44.0)
    fallback.custom_minimum_size = Vector2(44.0, 44.0)
    return fallback

func _find_or_make_speaker(row: HBoxContainer, index: int) -> Button:
    var speaker: Button = row.get_node_or_null("MikaCloudSpeaker") as Button
    if speaker != null and not speaker.has_method("set_selected"):
        row.remove_child(speaker)
        speaker.queue_free()
        speaker = null
    if speaker == null:
        # v108.2 may have installed a button INSIDE the cloud. Move it
        # to this separate right-hand column rather than making a duplicate.
        for child in row.get_children():
            if child is Button and child.get_node_or_null("MikaCloudSpeaker") != null:
                var old: Button = child.get_node("MikaCloudSpeaker") as Button
                if old != null and old.has_method("set_selected"):
                    old.reparent(row)
                    speaker = old
                elif old != null:
                    old.queue_free()
                break
    if speaker == null:
        speaker = CLOUD_SPEAKER.new() as Button
        if speaker == null:
            return null
        speaker.name = "MikaCloudSpeaker"
        row.add_child(speaker)
    speaker.custom_minimum_size = Vector2(44.0, 44.0)
    speaker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    speaker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    speaker.mouse_filter = Control.MOUSE_FILTER_STOP
    return speaker

func _line_count(phrase: String, width: float, label: Label) -> int:
    var font: Font = label.get_theme_font("font")
    var font_size: int = clampi(label.get_theme_font_size("font_size"), 12, 22)
    if font == null:
        return maxi(1, ceili(float(phrase.length()) * 13.0 / maxf(width, 40.0)))
    var lines: int = 0
    var space: float = font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    for para in phrase.split("\n", true):
        lines += 1
        var used: float = 0.0
        for token in para.split(" ", false):
            var word: float = font.get_string_size(token, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
            if used > 0.0 and used + space + word > width:
                lines += 1
                used = word
            else:
                used += (space if used > 0.0 else 0.0) + word
            if used > width:
                lines += maxi(0, ceili(used / width) - 1)
                used = fmod(used, width)
    return maxi(1, lines)

func _adapt_height(button: Button, phrase: String) -> void:
    var label: Label = button.get_node_or_null("CloudText") as Label
    if label == null:
        button.clip_text = true
        return
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.clip_text = true
    var row: HBoxContainer = button.get_parent() as HBoxContainer
    if row == null:
        return
    var available: float = row.size.x
    if available < 100.0:
        var dock: Control = _dialog.find_child("LeftQuestionChoices", true, false) as Control
        available = dock.size.x if dock != null else 350.0
    var cloud_width: float = maxf(108.0, available - 13.0 - 44.0 - 18.0)
    var text_width: float = maxf(65.0, cloud_width * 0.82 - 9.0)
    var count: int = _line_count(phrase, text_width, label)
    var required: float = maxf(79.0, ceilf((float(count) * 28.0 + 11.0) / 0.67))
    button.custom_minimum_size.y = required
    row.custom_minimum_size.y = required

func _update_buttons() -> void:
    if _dialog == null or not is_instance_valid(_dialog) or not _dialog.is_visible_in_tree():
        return
    var suggestions: Array[String] = _current_suggestions()
    var choices: Array[Button] = _choice_buttons(suggestions)
    if choices.is_empty():
        _attempts += 1
        if _attempts > 25 and not _warned:
            push_warning("MIKA v108.4: speech cloud choices were not found. The visible dialogue structure must be checked.")
            _warned = true
        return
    if not _found:
        _make_scroll()
        _found = true
    var selected: int = _selected()
    for i in range(mini(3, choices.size())):
        var cloud: Button = choices[i]
        var phrase: String = _get_phrase(cloud)
        if phrase.is_empty() and i < suggestions.size():
            phrase = suggestions[i]
        var speaker: Button = _speaker_for(cloud, i)
        if speaker == null:
            continue
        if cloud.get_parent() is HBoxContainer:
            var row: HBoxContainer = cloud.get_parent() as HBoxContainer
            row.visible = cloud.visible
            # CloudChoiceButton resets text layout on resize. Use only min
            # sizes, never write its live label position every frame.
            _adapt_height(cloud, phrase)
        speaker.call("configure", phrase, _locale(), "tablet")
        speaker.call("set_selected", i == selected)
        speaker.visible = cloud.visible and not phrase.is_empty()
    for node in _dialog.get_children():
        if node is Button and str(node.name).begins_with("MikaStandaloneCloudSpeaker_"):
            (node as Button).move_to_front()
