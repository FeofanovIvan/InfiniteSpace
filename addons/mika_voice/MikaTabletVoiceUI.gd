extends Node
## Additive runtime voice controls for the CURRENT tablet UI. No dialogue edits.
## This also covers Crossroads because it reuses the same TranslatorTablet.
const SPEAKER_SCRIPT: Script = preload("res://addons/mika_voice/SpeakerButton.gd")
const CLOUD_SPEAKER_SCRIPT: Script = preload("res://addons/mika_voice/MikaCloudSpeakerButton.gd")
var _tablet: Control
var _refresh_clock: float = 0.0
var _visible_before: bool = false
var _hint_button: Button

func _ready() -> void:
    _tablet = get_parent() as Control
    if _tablet == null:
        set_process(false)
        return
    set_process(true)

func _process(delta: float) -> void:
    if _tablet == null or not is_instance_valid(_tablet):
        return
    var visible_now: bool = _tablet.is_visible_in_tree()
    if not visible_now:
        if _visible_before:
            _stop_voice()
        _visible_before = false
        return
    _visible_before = true
    _refresh_clock += delta
    if _refresh_clock < 0.22:
        return
    _refresh_clock = 0.0
    _sync_selected_hint()
    _sync_chat_messages()
    _sync_three_clouds()
    _sync_crossroads_article()

func _exit_tree() -> void:
    _stop_voice()

func _stop_voice() -> void:
    var service: Node = get_node_or_null("/root/MikaVoice")
    if service != null:
        service.call("stop")

func _locale() -> String:
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    var value: String = str(mobile.get("language")) if mobile != null else "en"
    if value.is_empty() or value == "<null>":
        return "en"
    return value

func _context() -> Dictionary:
    var cursor: Node = _tablet
    while cursor != null:
        var test: String = str(cursor.name).to_lower()
        if test.contains("crossroads") or test.contains("перекр"):
            return {"role":"crossroads", "id":"crossroads_planet"}
        cursor = cursor.get_parent()
    var root: Node = _tablet.get_parent()
    var planet: String = ""
    if root != null:
        for property_info in root.get_property_list():
            if str(property_info.get("name", "")) == "_current_planet_id":
                planet = str(root.get("_current_planet_id"))
                break
    var role: String = "tablet"
    if planet.begins_with("mw_") or planet == "st_mw": role = "human"
    elif planet.begins_with("lmc_") or planet == "st_lmc": role = "fungal"
    elif planet.begins_with("smc_") or planet == "st_smc": role = "phase"
    elif planet.begins_with("ngc6822_") or planet == "st_ngc6822": role = "lizard"
    elif planet.begins_with("m31_") or planet == "st_m31": role = "magnetic"
    elif planet.begins_with("m33_") or planet == "st_m33": role = "neuron"
    return {"role":role, "id":planet}

func _speaker(owner: Control, node_name: String) -> Button:
    var old: Button = owner.get_node_or_null(node_name) as Button
    if old != null:
        return old
    var speaker: Button = SPEAKER_SCRIPT.new() as Button
    if speaker == null:
        return null
    speaker.name = node_name
    owner.add_child(speaker)
    speaker.mouse_filter = Control.MOUSE_FILTER_STOP
    return speaker

func _speak_label_text(text: String) -> String:
    var result: String = text.strip_edges()
    var colon: int = result.find(":")
    if colon >= 0 and colon <= 22:
        result = result.substr(colon + 1).strip_edges()
    return result

func _sync_selected_hint() -> void:
    var hint: Label = _tablet.find_child("SuggestedAnswer", true, false) as Label
    if hint == null or not hint.visible:
        if _hint_button != null: _hint_button.hide()
        return
    var phrase: String = _speak_label_text(hint.text)
    if phrase.is_empty():
        if _hint_button != null: _hint_button.hide()
        return
    if _hint_button == null or not is_instance_valid(_hint_button):
        _hint_button = _speaker(_tablet, "MikaSelectedHintSpeaker")
    if _hint_button == null:
        return
    var button_side: float = clampf(hint.size.y, 32.0, 42.0)
    _hint_button.position = Vector2(hint.position.x + hint.size.x - button_side, hint.position.y)
    _hint_button.size = Vector2(button_side, button_side)
    # The parent may relayout the hint; use its actual text, never a cached choice.
    _hint_button.call("configure", phrase, _locale(), "tablet")
    _hint_button.show()

func _row_message_text(row: Node) -> String:
    for panel in row.get_children():
        if panel is PanelContainer:
            for label in panel.get_children():
                if label is Label:
                    return (label as Label).text
                if label is RichTextLabel:
                    return (label as RichTextLabel).get_parsed_text()
    return ""

func _sync_chat_messages() -> void:
    var messages: Node = _tablet.find_child("Messages", true, false)
    if messages == null:
        return
    var context: Dictionary = _context()
    for row in messages.get_children():
        if not (row is HBoxContainer):
            continue
        var phrase: String = _row_message_text(row)
        if phrase.is_empty():
            continue
        var is_child: bool = row.get_child_count() > 0 and not (row.get_child(0) is PanelContainer)
        var role: String = "tablet" if is_child else str(context.get("role", "tablet"))
        var speaker: Button = _speaker(row as Control, "MikaMessageSpeaker")
        if speaker != null:
            speaker.call("configure", phrase, _locale(), role, str(context.get("id", "")))

func _visible_control_text(node: Control) -> String:
    if node is Button:
        var caption: String = (node as Button).text.strip_edges()
        if caption.length() >= 2 and not caption.is_valid_int(): return caption
    for child in node.get_children():
        if child is Label:
            var caption: String = (child as Label).text.strip_edges()
            if not caption.is_empty(): return caption
    return (node as Button).text.strip_edges() if node is Button else ""

# v108.2: locate the three *existing* choices at runtime; do not require
# particular GDScript source-code markers in the user's dialogue files.
func _cloud_candidates(dialog_root: Node, suggestions: Array[String]) -> Array[Button]:
    var result: Array[Button] = []
    # Prefer the actual choice panel; it may live in different dialogue versions.
    var choice_area: Node = dialog_root.find_child("LeftQuestionChoices", true, false)
    if choice_area == null:
        choice_area = dialog_root.find_child("ChoicesLayout", true, false)
    if choice_area is CanvasItem and not (choice_area as CanvasItem).visible:
        return result
    var search_root: Node = choice_area if choice_area != null else dialog_root
    for node in search_root.find_children("*", "Button", true, false):
        var button: Button = node as Button
        if button == null or not button.visible:
            continue
        var low: String = String(button.name).to_lower()
        if low.contains("speaker") or low.contains("microphone") or low.contains("back"):
            continue
        var has_cloud_text: bool = button.find_child("CloudText", true, false) is Label
        var option_named: bool = low.contains("questionoption") or low.contains("question_option") or low.contains("phrasechoice") or low.contains("phrase_choice") or low.contains("hintchoice") or low.contains("hint_choice")
        var has_phrase_method: bool = button.has_method("get_phrase")
        var candidate_text: String = _cloud_button_phrase(button)
        var matches_phrase: bool = suggestions.has(candidate_text) and not candidate_text.is_empty()
        if not (has_cloud_text or option_named or has_phrase_method or matches_phrase):
            continue
        if not result.has(button):
            result.append(button)
    # Keep tree order (top to bottom in the existing VBoxContainer).
    return result

func _cloud_button_phrase(cloud: Button) -> String:
    if cloud.has_method("get_phrase"):
        var from_method: String = str(cloud.call("get_phrase")).strip_edges()
        if not from_method.is_empty():
            return from_method
    var cloud_label: Label = cloud.find_child("CloudText", true, false) as Label
    if cloud_label != null and not cloud_label.text.strip_edges().is_empty():
        return cloud_label.text.strip_edges()
    return _visible_control_text(cloud)

# The three cloud phrases and their speakers have distinct clickable regions.
# Put each pair in its own HBox; long text increases that row's height.
# The VBox scrolls INSIDE the existing choice dock instead of spilling into
# the character or the tablet (also works for the Crossroads dialogue).
func _ensure_cloud_scroll(dialog_root: Node) -> VBoxContainer:
    var dock: PanelContainer = dialog_root.find_child("LeftQuestionChoices", true, false) as PanelContainer
    if dock == null:
        return null
    var column: VBoxContainer = dock.find_child("ChoicesLayout", true, false) as VBoxContainer
    if column == null:
        return null
    var scroller: ScrollContainer = dock.get_node_or_null("MikaChoiceScroll") as ScrollContainer
    if scroller == null:
        scroller = ScrollContainer.new()
        scroller.name = "MikaChoiceScroll"
        scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
        scroller.clip_contents = true
        scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
        scroller.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
        dock.add_child(scroller)
        column.reparent(scroller)
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    # Reserve the scrollbar width so wrapped lines never extend behind it.
    if scroller.size.x >= 170.0:
        column.custom_minimum_size.x = maxf(145.0, scroller.size.x - 18.0)
    return column


func _cloud_line_count(content: String, usable_width: float, label: Label) -> int:
    var font_size: int = 21
    var font: Font = label.get_theme_font("font")
    var result: int = 0
    if font == null:
        return maxi(1, ceili(float(content.length()) * 13.0 / maxf(50.0, usable_width)))
    var space_width: float = font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    for paragraph in content.split("\n", true):
        result += 1
        var line_width: float = 0.0
        for token in paragraph.split(" ", false):
            var word_width: float = font.get_string_size(token, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
            var width_with_space: float = word_width + (space_width if line_width > 0.0 else 0.0)
            if line_width > 0.0 and line_width + width_with_space > usable_width:
                result += 1
                line_width = word_width
            else:
                line_width += width_with_space
            # A very long unspaced token must also wrap inside the label.
            if line_width > usable_width:
                result += maxi(0, ceili(line_width / usable_width) - 1)
                line_width = fmod(line_width, usable_width)
    return maxi(1, result)


func _make_cloud_row(cloud: Button, column: VBoxContainer) -> HBoxContainer:
    var current: HBoxContainer = cloud.get_parent() as HBoxContainer
    if current != null and String(current.name).begins_with("MikaChoiceRow_"):
        return current
    # The original cloud remains the SAME Button object, with its original
    # pressed connection, chosen state, three-option semantics and CloudText.
    if cloud.get_parent() != column:
        return null
    var original_index: int = cloud.get_index()
    var row: HBoxContainer = HBoxContainer.new()
    row.name = "MikaChoiceRow_" + String(cloud.name)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    row.add_theme_constant_override("separation", 13)
    column.add_child(row)
    column.move_child(row, original_index)
    cloud.reparent(row)
    cloud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cloud.size_flags_vertical = Control.SIZE_EXPAND_FILL
    return row


func _cloud_row_speaker(cloud: Button, row: HBoxContainer) -> Button:
    var speaker: Button = row.get_node_or_null("MikaCloudSpeaker") as Button
    if speaker == null:
        speaker = cloud.get_node_or_null("MikaCloudSpeaker") as Button
        if speaker != null and not speaker.has_method("set_selected"):
            cloud.remove_child(speaker)
            speaker.queue_free()
            speaker = null
        elif speaker != null:
            speaker.reparent(row)
    if speaker == null:
        speaker = CLOUD_SPEAKER_SCRIPT.new() as Button
        if speaker == null:
            return null
        speaker.name = "MikaCloudSpeaker"
        row.add_child(speaker)
    # Fixed-size circular target; a real sibling, never overlaid on the text.
    speaker.custom_minimum_size = Vector2(42.0, 42.0)
    speaker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    speaker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    speaker.mouse_filter = Control.MOUSE_FILTER_STOP
    return speaker


# v108.4: cloud speakers are now installed directly by the dialogue root.
# Do not search/reparent choice buttons from the tablet side.
func _sync_three_clouds() -> void:
    pass


func _sync_crossroads_article() -> void:
    if str(_context().get("role")) != "crossroads":
        return
    var dialog_root: Node = _tablet.get_parent()
    if dialog_root == null:
        return
    for node in dialog_root.find_children("*", "RichTextLabel", true, false):
        var label: RichTextLabel = node as RichTextLabel
        if label == null or not label.is_visible_in_tree(): continue
        var lower_name: String = str(label.name).to_lower()
        if not (lower_name.contains("article") or lower_name.contains("encyclop")): continue
        var text_to_read: String = label.get_parsed_text().strip_edges()
        if text_to_read.is_empty(): continue
        var parent_control: Control = label.get_parent() as Control
        if parent_control == null: continue
        var speaker: Button = _speaker(parent_control,"MikaArticleSpeaker")
        if speaker == null: continue
        speaker.position = Vector2(maxf(0.0,parent_control.size.x - 50.0), 4.0)
        speaker.size = Vector2(42,42)
        speaker.call("configure",text_to_read,_locale(),"crossroads","crossroads_planet")
