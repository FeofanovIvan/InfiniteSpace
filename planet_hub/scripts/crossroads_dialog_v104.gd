extends Control
## v104.4: transparent four-button toolbar with tablet-aligned margins and readable labels.
## v104.3 bounded Living World storm and dropdown are unchanged.
## Crossroads reuses the ORIGINAL RepresentativeDialog.tscn,
## its TranslatorTablet, six-language keyboard, cloud choices and back button.
## This wrapper adds only topic selection + the living planet on the left.
signal return_requested

const LIBRARY_PATH: String = "res://planet_hub/data/crossroads_v120_encyclopedia.json"
# MIKA_CROSSROADS_V120_CONTENT_ONLY_EXISTING_UI
const ORIGINAL_DIALOGUE: PackedScene = preload("res://planet_hub/scenes/representative_dialog.tscn")
const CROSSROADS_ENGINE: Script = preload("res://planet_hub/scripts/crossroads_engine_v104_1.gd")
const SKY_SCRIPT: Script = preload("res://simulator_ui/scripts/real_space_background.gd")
const LIVING_WORLD_SCENE: PackedScene = preload("res://living_world_storm_2d/living_world_storm_2d.tscn")
const LANGUAGES: Array[String] = ["ru", "en", "fr", "de", "es", "pt_BR"]

var _library: Dictionary = {}
var _dialog: Control
var _tablet: Control
var _sky: Control
var _planet: Node2D
var _engine: RefCounted
var _panel: PanelContainer
var _planet_clip: Control
var _toolbar: PanelContainer
var _group_row: HBoxContainer
var _back_slot: Control
var _original_back: Button
var _expanded: bool = false
var _drag_mouse: bool = false
var _drag_touch_index: int = -1
var _drag_distance: float = 0.0
var _suppress_topic_click: bool = false
var _topic_scroll: ScrollContainer
var _topic_list: VBoxContainer
var _locale: String = "en"
var _group_id: String = "care"
var _topic_id: String = ""
var _toolbar_rect: Rect2 = Rect2()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	if FileAccess.file_exists(LIBRARY_PATH):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(LIBRARY_PATH))
		if data is Dictionary:
			_library = data
	if _library.is_empty():
		push_error("Crossroads encyclopedia missing: " + LIBRARY_PATH)
		return
	_engine = CROSSROADS_ENGINE.new() as RefCounted
	_engine.call("configure", _library)
	_dialog = ORIGINAL_DIALOGUE.instantiate() as Control
	_dialog.name = "OriginalPlanetRepresentativeDialog_Reused"
	_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dialog)
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.connect("return_requested", Callable(self, "_on_original_back_pressed"))
	_tablet = _dialog.get_node_or_null("TranslatorTablet") as Control
	if _tablet == null or not _tablet.has_method("configure_for_world"):
		push_error("Original six-language TranslatorTablet is unavailable")
		return
	# The original v96.1 tablet delegates all replies to a RefCounted engine.
	# Inject encyclopedia content: do NOT replace its design or controls.
	_tablet.set("_v96_engine", _engine)
	# Data engine only. Existing phrase blocks, their selected colors and speakers are untouched.
	_tablet.connect("message_sent", Callable(self, "_v120_defer_sync"))
	_sky = SKY_SCRIPT.new() as Control
	_sky.name = "OriginalProceduralCosmos"
	_sky.process_mode = Node.PROCESS_MODE_ALWAYS
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialog.add_child(_sky)
	_dialog.move_child(_sky, 0) # sky over its old static backing, under tablet
	_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_planet_clip = Control.new()
	_planet_clip.name = "LivingWorld_ClippedToLeftHalf"
	_planet_clip.clip_contents = true
	_planet_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialog.add_child(_planet_clip)
	_dialog.move_child(_planet_clip, 1)
	_planet = LIVING_WORLD_SCENE.instantiate() as Node2D
	if _planet != null:
		_planet.name = "LivingPlanet_FillsLeftHalf"
		_planet.process_mode = Node.PROCESS_MODE_ALWAYS
		_planet_clip.add_child(_planet)
		_planet.call("set_mood", "listening")
		_planet.call("set_storm_state", "communicating")
	var existing_character: Control = _dialog.get_node_or_null("RepresentativeCharacter") as Control
	if existing_character != null:
		existing_character.visible = false
	_build_topic_picker()
	var loc: Node = get_node_or_null("/root/MobileLocale")
	if loc != null and loc.has_signal("language_changed"):
		loc.connect("language_changed", Callable(self, "_on_locale_changed"))
	_locale = str(loc.get("language")) if loc != null else "en"
	if not LANGUAGES.has(_locale):
		_locale = "en"
	resized.connect(_layout)
	_refresh_groups()
	_select_topic(_find_first_topic("care"), true)
	_layout()
	_set_runtime_active(false)

func _safe_rect(view: Vector2) -> Rect2:
	var mobile: Node = get_node_or_null("/root/MobileLocale")
	if mobile != null and mobile.has_method("safe_rect"):
		var candidate: Variant = mobile.call("safe_rect", view)
		if candidate is Rect2:
			return candidate
	return Rect2(Vector2.ZERO, view)

func _set_runtime_active(active: bool) -> void:
	if _sky != null:
		_sky.process_mode = Node.PROCESS_MODE_ALWAYS if active else Node.PROCESS_MODE_DISABLED
	if _planet != null:
		_planet.call("set_paused", not active)
		_planet.process_mode = Node.PROCESS_MODE_ALWAYS if active else Node.PROCESS_MODE_DISABLED

func _style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("9d6328") if selected else Color("143553")
	style.border_color = Color("f5cf75") if selected else Color("57b8e5")
	style.set_border_width_all(2)
	style.set_corner_radius_all(13)
	style.set_content_margin_all(5)
	return style

func _topic_button(caption: String, selected: bool, font_px: int) -> Button:
	var button := Button.new()
	button.text = caption
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = 48.0
	button.add_theme_font_size_override("font_size", font_px)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(selected))
	button.add_theme_stylebox_override("hover", _style(selected))
	button.add_theme_stylebox_override("pressed", _style(selected))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

func _build_topic_picker() -> void:
	# One programmatic panel contains the ORIGINAL back arrow and 3 equal-height tabs.
	# Reparenting the existing BackToPlanet keeps its original signal and behavior.
	_toolbar = PanelContainer.new()
	_toolbar.name = "CrossroadsOneRow_ToolbarAndOriginalBack"
	_toolbar.mouse_filter = Control.MOUSE_FILTER_PASS
	# No common frame, shadow, dark rectangle or exterior border: only four
	# independent buttons remain visible, still laid out as one HBoxContainer.
	_toolbar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_dialog.add_child(_toolbar)
	_group_row = HBoxContainer.new()
	_group_row.name = "BackAndThreeTopics_EqualHeightEqualGaps"
	_group_row.add_theme_constant_override("separation", 11)
	_group_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_group_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_toolbar.add_child(_group_row)
	_back_slot = Control.new()
	_back_slot.name = "OriginalBackButtonSlot"
	_back_slot.custom_minimum_size = Vector2(60, 48)
	_back_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_group_row.add_child(_back_slot)
	_original_back = _dialog.get_node_or_null("BackToPlanet") as Button
	if _original_back != null:
		_original_back.reparent(_back_slot)
		_original_back.add_theme_stylebox_override("normal", _style(false))
		_original_back.add_theme_stylebox_override("hover", _style(false))
		_original_back.add_theme_stylebox_override("pressed", _style(false))
		_original_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		_original_back.add_theme_font_size_override("font_size", 28)
		_original_back.custom_minimum_size = Vector2.ZERO
		_back_slot.resized.connect(_arrange_original_back)
	else:
		push_error("Crossroads: original BackToPlanet button was not found")
	# The dropdown is a separate overlay below the top bar (not a second tab bar).
	_panel = PanelContainer.new()
	_panel.name = "TouchTopicList_OnlyWhenSectionIsOpen"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.035, 0.10, 0.19, 0.97)
	base.border_color = Color("509ac1")
	base.set_border_width_all(2)
	base.set_corner_radius_all(16)
	base.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", base)
	_dialog.add_child(_panel)
	_topic_scroll = ScrollContainer.new()
	_topic_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_topic_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_topic_scroll.follow_focus = false
	_topic_scroll.scroll_deadzone = 9
	_topic_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_topic_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(_topic_scroll)
	_topic_scroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
	_topic_list = VBoxContainer.new()
	_topic_list.add_theme_constant_override("separation", 7)
	_topic_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_topic_scroll.add_child(_topic_list)


func _arrange_original_back() -> void:
	# RepresentativeDialog may relayout its button; keep it centered in the slot.
	if _original_back == null or _back_slot == null:
		return
	_original_back.position = Vector2.ZERO
	_original_back.size = _back_slot.size


func _process(_delta: float) -> void:
	# The unmodified original dialogue can resize its Back button when a hint
	# changes. Enforce the toolbar slot without touching that original script.
	if not visible or _original_back == null or _back_slot == null:
		return
	if _toolbar != null and _toolbar_rect.size.x > 0.0:
		if _toolbar.position.distance_to(_toolbar_rect.position) > 0.5 or _toolbar.size.distance_to(_toolbar_rect.size) > 0.5:
			_toolbar.position = _toolbar_rect.position
			_toolbar.size = _toolbar_rect.size
	if _original_back.position != Vector2.ZERO or _original_back.size.distance_to(_back_slot.size) > 0.5:
		_arrange_original_back()


func _set_topic_list_open(value: bool) -> void:
	_expanded = value
	_panel.visible = value
	if value:
		_topic_scroll.scroll_vertical = 0
	_refresh_groups()
	# The original cloud hints remain visible; list is bounded above them.


func _input(event: InputEvent) -> void:
	if not visible or not _expanded or _topic_scroll == null:
		_drag_mouse = false
		_drag_touch_index = -1
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_mouse = _topic_scroll.get_global_rect().has_point(event.position)
			_drag_distance = 0.0
			_suppress_topic_click = false
		else:
			_drag_mouse = false
	elif event is InputEventMouseMotion and _drag_mouse and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_drag_distance += absf(event.relative.y)
		if _drag_distance >= 9.0:
			_suppress_topic_click = true
		_topic_scroll.scroll_vertical = maxi(0, _topic_scroll.scroll_vertical - roundi(event.relative.y))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed and _drag_touch_index < 0 and _topic_scroll.get_global_rect().has_point(event.position):
			_drag_touch_index = event.index
			_drag_distance = 0.0
			_suppress_topic_click = false
		elif not event.pressed and event.index == _drag_touch_index:
			_drag_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _drag_touch_index:
		_drag_distance += absf(event.relative.y)
		if _drag_distance >= 9.0:
			_suppress_topic_click = true
		_topic_scroll.scroll_vertical = maxi(0, _topic_scroll.scroll_vertical - roundi(event.relative.y))
		get_viewport().set_input_as_handled()


func _localized(value: Variant) -> String:
	if value is Dictionary:
		return str(value.get(_locale, value.get("en", "")))
	return str(value)

func _find_first_topic(group_id: String) -> String:
	for topic in _library.get("topics", []):
		if topic is Dictionary and str(topic.get("group", "")) == group_id:
			return str(topic.get("id", ""))
	return ""

func _select_group(group_id: String) -> void:
	# Tapping a group reveals its own 16 topics; tapping again closes it.
	if group_id == _group_id:
		_set_topic_list_open(not _expanded)
		return
	_group_id = group_id
	_refresh_topics()
	_set_topic_list_open(true)
	# Changing a category does NOT choose its first topic automatically.
	# The child's typed chat stays unchanged until they choose a topic.


func _refresh_groups() -> void:
	# Back remains first and is never reconstructed or disconnected.
	for child in _group_row.get_children():
		if child == _back_slot:
			continue
		_group_row.remove_child(child)
		child.queue_free()
	for group in _library.get("groups", []):
		if not (group is Dictionary):
			continue
		var gid: String = str(group.get("id", ""))
		var expanded_here: bool = gid == _group_id and _expanded
		var arrow: String = "  ▴" if expanded_here else "  ▾"
		var b: Button = _topic_button(_localized(group.get("label", {})) + arrow, expanded_here, 21)
		b.name = "TopicSection_" + gid
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_stretch_ratio = 1.0
		b.pressed.connect(_select_group.bind(gid))
		_group_row.add_child(b)
	# A language switch can change label width; fit font after rebuilding tabs.
	call_deferred("_layout")

func _fit_section_font(button: Button, available_width: float, preferred_px: int) -> int:
	# Exact font metrics (including the arrow) instead of crude character counts.
	# Favor large single-line labels; shorten the font only where necessary.
	var font: Font = button.get_theme_font("font")
	if font == null:
		return preferred_px
	for px in range(preferred_px, 12, -1):
		if font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x <= available_width - 16.0:
			return px
	# On narrow phones the button may use two wrapped lines, never overflow.
	return 13


func _refresh_topics() -> void:
	for child in _topic_list.get_children():
		_topic_list.remove_child(child)
		child.queue_free()
	for topic in _library.get("topics", []):
		if not (topic is Dictionary) or str(topic.get("group", "")) != _group_id:
			continue
		var tid: String = str(topic.get("id", ""))
		var b: Button = _topic_button(_localized(topic.get("title", {})), tid == _topic_id, 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 54.0
		b.pressed.connect(_on_topic_button_pressed.bind(tid))
		_topic_list.add_child(b)
	# v120: new content entries inside the SAME existing dropdown, not a new UI.
	var resume_text: String = str(_engine.call("get_resume_label"))
	if not resume_text.is_empty():
		var resume: Button = _topic_button(resume_text, false, 16)
		resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resume.custom_minimum_size.y = 54.0
		resume.pressed.connect(_v120_resume_route)
		_topic_list.add_child(resume)
	for route_id in _engine.call("get_route_ids_for_group", _group_id):
		var route: Button = _topic_button(str(_engine.call("get_route_label", str(route_id))), false, 16)
		route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		route.custom_minimum_size.y = 54.0
		route.pressed.connect(_v120_start_route.bind(str(route_id)))
		_topic_list.add_child(route)

func _on_topic_button_pressed(topic_id: String) -> void:
	if _suppress_topic_click:
		return
	_select_topic(topic_id, true)


func _select_topic(topic_id: String, close_dropdown: bool = true) -> void:
	_topic_id = topic_id
	_engine.call("set_topic", topic_id)
	_refresh_topics()
	if close_dropdown:
		_set_topic_list_open(false)
	if _tablet != null:
		# Only the three ORIGINAL clouds change. The child must type himself.
		_tablet.call("_v96_set_choices", _engine.call("get_choices"))
		# Original dialogue repositions clouds when choices change.
		call_deferred("_layout")


func _on_locale_changed(new_locale: String) -> void:
	_locale = new_locale if LANGUAGES.has(new_locale) else "en"
	_engine.call("set_locale", _locale)
	_refresh_groups()
	_refresh_topics()
	# Original tablet listens to MobileLocale and rebuilds its own keyboard.
	# Do not overwrite or redraw any of its controls.

func _layout() -> void:
	if _dialog == null or _panel == null or _planet_clip == null or _toolbar == null:
		return
	var view: Vector2 = size
	if view.x < 250.0 or view.y < 200.0:
		return
	# ONE full-screen procedural sky. No extra shade/texture under planet.
	var safe: Rect2 = _safe_rect(view)
	var half: float = view.x * 0.50
	var safe_half: float = safe.size.x * 0.50
	_planet_clip.position = Vector2.ZERO
	_planet_clip.size = Vector2(half, view.y)
	if _planet != null:
		# IMPORTANT: storms occupy 2.05x the disc, not just the disc diameter.
		# Limit the whole square animation footprint to 80% left-half width
		# and 56% screen height, so even mist/lightning never hit the clip edge.
		var full_effect_size: float = minf(half * 0.80, view.y * 0.56)
		var disc_diameter: float = full_effect_size / 2.05
		_planet.position = Vector2(half * 0.50, view.y * 0.42)
		# StormWorld clamps its core diameter to >= 110 px; scale the entire
		# scene below that limit so tiny/portrait viewports still never crop FX.
		_planet.call("update_diameter", maxf(110.0, disc_diameter))
		_planet.scale = Vector2.ONE * minf(1.0, disc_diameter / 110.0)
	# Align top buttons with the top inset of the original tablet bezel,
	# instead of hugging the upper screen edge. The arrow shares the same
	# horizontal inset from the left edge as the tablet's visible frame.
	var tablet_origin_y: float = _tablet.position.y if _tablet != null else 0.0
	var inset: float = clampf(safe.size.y * 0.040, 22.0, 36.0)
	var bar_top: float = maxf(safe.position.y, tablet_origin_y) + clampf(safe.size.y * 0.040, 24.0, 44.0)
	var button_height: float = clampf(view.y * 0.095, 60.0, 86.0)
	_toolbar_rect = Rect2(Vector2(safe.position.x + inset, bar_top), Vector2(maxf(210.0, safe_half - inset * 2.0), button_height))
	_toolbar.position = _toolbar_rect.position
	_toolbar.size = _toolbar_rect.size
	_back_slot.custom_minimum_size = Vector2(clampf(safe_half * 0.09, 53.0, 74.0), button_height)
	if _original_back != null:
		_original_back.add_theme_font_size_override("font_size", clampi(roundi(button_height * 0.41), 25, 34))
	var gaps: float = 3.0 * float(_group_row.get_theme_constant("separation"))
	var group_width: float = maxf(55.0, (_toolbar.size.x - _back_slot.custom_minimum_size.x - gaps) / 3.0)
	var preferred_font: int = clampi(roundi(view.y * 0.028), 18, 23)
	for group_node in _group_row.get_children():
		var group_button: Button = group_node as Button
		if group_button != null:
			group_button.custom_minimum_size.y = button_height
			group_button.add_theme_font_size_override("font_size", _fit_section_font(group_button, group_width, preferred_font))
	_arrange_original_back()
	# Topic list opens below the single bar and ends near mid-screen,
	# entirely ABOVE the question clouds. No permanently visible topic row.
	var list_top: float = _toolbar.position.y + _toolbar.size.y + 8.0
	var list_bottom: float = minf(safe.end.y, safe.position.y + safe.size.y * 0.595)
	_panel.position = Vector2(safe.position.x + inset, list_top)
	_panel.size = Vector2(_toolbar.size.x, maxf(56.0, list_bottom - list_top))
	var original_clouds: Control = _dialog.get_node_or_null("LeftQuestionChoices") as Control
	if original_clouds != null:
		original_clouds.position = Vector2(safe.position.x + maxf(24.0, safe_half * 0.07), safe.position.y + safe.size.y * 0.710)
		original_clouds.size = Vector2(safe_half * 0.86, safe.size.y * 0.275)
		var column: Node = original_clouds.get_node_or_null("ChoicesLayout")
		if column != null:
			for child in column.get_children():
				var cloud_button: Button = child as Button
				if cloud_button != null:
					cloud_button.custom_minimum_size = Vector2(0.0, clampf(view.y * 0.080, 48.0, 64.0))
	# Keep the dropdown on top of the animation but NOT on the tablet/questions.
	_panel.move_to_front()
	_toolbar.move_to_front()
	_arrange_original_back()


func open_dialog() -> void:
	if _dialog == null or _tablet == null:
		return
	var loc: Node = get_node_or_null("/root/MobileLocale")
	_on_locale_changed(str(loc.get("language")) if loc != null else "en")
	# Open fresh in the ORIGINAL tablet; its own UI and keyboard remain intact.
	_engine.call("set_topic", _topic_id)
	_tablet.set("_v96_engine", _engine)
	_tablet.call("configure_for_world", "crossroads_core")
	visible = true
	_set_runtime_active(true)
	_set_topic_list_open(false)
	_layout()

func _on_original_back_pressed() -> void:
	visible = false
	_set_runtime_active(false)
	return_requested.emit()


# v120: only route commands / topic selection synchronization; no drawing or layout.
func _v120_defer_sync(_typed: String) -> void:
	call_deferred("_v120_sync_topic")

func _v120_sync_topic() -> void:
	if _engine == null or _topic_list == null:
		return
	var new_topic: String = str(_engine.call("get_topic_id"))
	if new_topic.is_empty() or new_topic == _topic_id:
		return
	_topic_id = new_topic
	var new_group: String = str(_engine.call("get_group_id"))
	if not new_group.is_empty():
		_group_id = new_group
	_refresh_groups()
	_refresh_topics()

func _v120_display_route() -> void:
	_topic_id = str(_engine.call("get_topic_id"))
	_group_id = str(_engine.call("get_group_id"))
	_refresh_groups()
	_refresh_topics()
	_set_topic_list_open(false)
	# Reset only existing chat content and hints; original controls stay in place.
	if _tablet != null:
		_tablet.call("configure_for_world", "crossroads_core")

func _v120_start_route(route_id: String) -> void:
	if _suppress_topic_click:
		return
	if bool(_engine.call("start_route", route_id)):
		_v120_display_route()

func _v120_resume_route() -> void:
	if _suppress_topic_click:
		return
	if bool(_engine.call("resume_route")):
		_v120_display_route()
