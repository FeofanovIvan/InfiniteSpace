extends Control
const V1143_PHASE_BRIDGE: Script = preload("res://planet_hub/scripts/mika_phase_liquid_v1143_bridge.gd")
const V1084_CLOUD_SPEAKERS_SCRIPT: Script = preload("res://addons/mika_voice/MikaCloudChoiceSpeakers.gd")
# v96: original v75/v76/v93 dialogue layout; only three bottom-left choice clouds.
const CLOUD_CHOICE = preload("res://planet_hub/scripts/cloud_choice_button.gd")
# v93: original animated MagneticLiquid appears only in M31 conversations.
const MAGNETIC_CREATURE_SCENE: PackedScene = preload("res://magnetic_liquid/MagneticLiquid.tscn")
const MAGNETIC_DIALOG_IDS: Array[String] = ["m31_p03", "m31_p05", "m31_p06", "st_m31"]
## v76: clean character area and strong neon back arrow.
const BackArrowGlyph = preload("res://planet_hub/scripts/back_arrow_glyph.gd")
## v75: freestanding tablet, padded neon back button.
## v60: character LEFT HALF, full-height translator RIGHT HALF.
## No duplicate title, no inset tiny tablet; one native fullscreen chat scene.
signal return_requested
@export var planet_background: String = "":
	set(value):
		planet_background = value
		_load_background()
@onready var character: Control = $RepresentativeCharacter
@onready var hint: Control = $PhraseHint
@onready var tablet: Control = $TranslatorTablet
var _background: Texture2D
var _back_button: Button
var _setup: bool = false
var _current_planet_id: String = ""
var _v96_cloud_layer: Control
var _v96_clouds: Array[Button] = []
var _v96_selected: int = 0
var _magnetic_creature: Node2D = null

func configure_for_planet(planet_id: String, _planet_name: String, background_path: String, portrait_path: String) -> void:
	_current_planet_id = planet_id
	planet_background = background_path
	if character != null:
		character.set("portrait_path", portrait_path)
	# v93: magnetic race uses a living shader creature in the dialogue only.
	_v93_configure_magnetic_dialog(planet_id)
	if tablet != null and tablet.has_method("configure_for_world"):
		tablet.call("configure_for_world", planet_id)
	queue_redraw()

func _ready() -> void:
	call_deferred("_v1143_attach_liquid")
	call_deferred("_v1084_install_cloud_speakers")
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_background()
	_back_button = Button.new()
	_back_button.name = "BackToPlanet"
	_back_button.text = ""
	_back_button.tooltip_text = "Вернуться на планету"
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.add_theme_font_size_override("font_size", 35)
	_back_button.add_theme_color_override("font_color", Color("eafcff"))
	_back_button.add_theme_color_override("font_hover_color", Color.WHITE)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("072b53")
	style.border_color = Color("30deff")
	style.set_corner_radius_all(19)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.0, 0.66, 1.0, 0.66)
	style.shadow_size = 9
	_back_button.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("195b89")
	_back_button.add_theme_stylebox_override("hover", hover)
	_back_button.add_theme_stylebox_override("pressed", hover)
	_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(_back_button)
	_back_button.pressed.connect(_go_back)
	# Full-weight arrow is drawn as a real scalable Control, not a font glyph.
	var arrow: Control = BackArrowGlyph.new()
	arrow.name = "NeonBackArrow"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.anchor_right = 1.0
	arrow.anchor_bottom = 1.0
	_back_button.add_child(arrow)
	# The hint is integrated inside the tablet above the on-screen keyboard.
	hint.visible = false
	_v96_build_cloud_choices()
	if tablet != null and tablet.has_signal("suggestions_changed"):
		tablet.connect("suggestions_changed", Callable(self, "_v96_suggestions_changed"))
		_v96_suggestions_changed(tablet.call("get_suggestions"))
	_setup = true
	resized.connect(_layout_ui)
	_layout_ui()

func _v93_configure_magnetic_dialog(planet_id: String) -> void:
	# Four inhabited M31 dialogue targets, all magnetic in representatives.json.
	# Never replace PlanetHub cards, previews or any other race portrait.
	var magnetic: bool = MAGNETIC_DIALOG_IDS.has(planet_id)
	if character != null:
		character.visible = not magnetic
	if magnetic:
		if not is_instance_valid(_magnetic_creature):
			_magnetic_creature = MAGNETIC_CREATURE_SCENE.instantiate() as Node2D
			if _magnetic_creature == null:
				push_error("MagneticLiquid: cannot instantiate the scene")
				if character != null:
					character.visible = true
				return
			_magnetic_creature.name = "LiveMagneticRepresentative_M31"
			_magnetic_creature.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(_magnetic_creature)
		if is_instance_valid(_magnetic_creature):
			_magnetic_creature.visible = true
			_magnetic_creature.set_process(true)
			_magnetic_creature.call("set_form", 0)
			_magnetic_creature.call("set_agitation", 0.18)
			_magnetic_creature.call("clear_magnetic_focus")
			_v93_layout_magnetic_creature()
			# Keep the tablet keyboard and the back arrow in front of the creature.
			if tablet != null:
				tablet.move_to_front()
			if _back_button != null:
				_back_button.move_to_front()
	elif is_instance_valid(_magnetic_creature):
		_magnetic_creature.visible = false
		_magnetic_creature.set_process(false)


func _v93_layout_magnetic_creature() -> void:
	if not is_instance_valid(_magnetic_creature) or character == null:
		return
	# The uploaded scene has a 512x512 transparent local canvas, centered at 0.
	# Scale into the existing LEFT character area and never cover the tablet.
	var area: Vector2 = character.size
	var diameter: float = minf(area.x * 0.88, area.y * 0.84)
	_magnetic_creature.scale = Vector2.ONE * (diameter / 512.0)
	_magnetic_creature.position = character.position + area * Vector2(0.50, 0.52)


func _v96_build_cloud_choices() -> void:
	# Independently sized clouds overlay ONLY the bottom of the left character slot.
	_v96_cloud_layer = Control.new()
	_v96_cloud_layer.name = "BottomLeftDialogueChoiceClouds"
	_v96_cloud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_v96_cloud_layer)
	for i in range(3):
		var bubble: Button = CLOUD_CHOICE.new()
		bubble.name = "DialoguePhrase_%d" % i
		bubble.visible = false
		bubble.pressed.connect(_v96_choice_pressed.bind(i))
		_v96_cloud_layer.add_child(bubble)
		_v96_clouds.append(bubble)
	_v96_cloud_layer.visible = false


func _v96_suggestions_changed(available: Array) -> void:
	_v96_selected = 0
	_v96_cloud_layer.visible = not available.is_empty()
	for i in range(_v96_clouds.size()):
		var bubble: Button = _v96_clouds[i]
		bubble.visible = i < available.size()
		if bubble.visible:
			bubble.call("set_phrase", str(available[i]))
		bubble.set("chosen", bubble.visible and i == 0)
	_v96_layout_cloud_choices()
	_v96_cloud_layer.move_to_front()
	if tablet != null:
		tablet.move_to_front()
	if _back_button != null:
		_back_button.move_to_front()


func _v96_choice_pressed(index: int) -> void:
	if index < 0 or index >= _v96_clouds.size() or not _v96_clouds[index].visible:
		return
	_v96_selected = index
	# Picking a cloud only changes the next-letter hint. The child must type.
	if tablet != null:
		tablet.call("select_suggestion", index)
	for i in range(_v96_clouds.size()):
		_v96_clouds[i].set("chosen", _v96_clouds[i].visible and i == index)


func _v96_layout_cloud_choices() -> void:
	# v98: every oval is centered and sized to its measured phrase.
	# Dialogue buttons remain on the LOWER HALF of the character's area.
	if _v96_cloud_layer == null or size.x < 180.0 or size.y < 180.0:
		return
	var safe: Rect2 = _safe_rect()
	var half: float = safe.size.x * 0.50
	var h: float = safe.size.y
	_v96_cloud_layer.position = safe.position
	_v96_cloud_layer.size = Vector2(half, h)
	var available: float = maxf(80.0, half - clampf(half * 0.068, 24.0, 48.0))
	var basic_height: float = clampf(h * 0.098, 52.0, 70.0)
	var font_px: int = clampi(roundi(h * 0.031), 14, 22)
	var gap: float = clampf(h * 0.013, 7.0, 13.0)
	var shown: Array[Button] = []
	var dimensions: Array[Vector2] = []
	var total_height: float = 0.0
	for bubble in _v96_clouds:
		if not bubble.visible:
			continue
		var ideal: Vector2 = bubble.call("suggested_size", available, font_px, basic_height)
		shown.append(bubble)
		dimensions.append(ideal)
		total_height += ideal.y
	if shown.is_empty():
		return
	total_height += gap * float(shown.size() - 1)
	var y: float = h * 0.971 - total_height
	for i in range(shown.size()):
		var bubble: Button = shown[i]
		var ideal: Vector2 = dimensions[i]
		# Same X axis for all labels and frames: no offset/drift per slot.
		bubble.position = Vector2(roundf((half - ideal.x) * 0.5), roundf(y))
		bubble.size = ideal
		bubble.queue_redraw()
		y += ideal.y + gap


func _load_background() -> void:
	_background = null
	if not planet_background.is_empty() and ResourceLoader.exists(planet_background):
		_background = load(planet_background) as Texture2D
	queue_redraw()

func _layout_ui() -> void:
	if not _setup or size.x < 200 or size.y < 140:
		return
	var safe: Rect2 = _safe_rect()
	var w: float = safe.size.x
	var h: float = safe.size.y
	var split: float = safe.position.x + w * 0.50
	character.position = safe.position + Vector2(8, h * 0.025)
	character.size = Vector2(w * 0.50 - 16, h * 0.965)
	_v93_layout_magnetic_creature()
	# A real self-contained tablet, bounded to the right half, almost full-height.
	var frame_margin: float = clampf(h * 0.019, 10.0, 24.0)
	var tablet_left: float = split + clampf(w * 0.011, 8.0, 22.0)
	tablet.position = Vector2(tablet_left, safe.position.y + frame_margin)
	tablet.size = Vector2(safe.end.x - tablet_left - frame_margin, h - 2.0 * frame_margin)
	var back_margin: float = clampf(minf(w, h) * 0.034, 18.0, 34.0)
	var back_size: float = clampf(h * 0.098, 53.0, 82.0)
	_back_button.position = safe.position + Vector2(back_margin, back_margin)
	_back_button.size = Vector2(back_size, back_size)
	_v96_layout_cloud_choices()
	_back_button.move_to_front()
	queue_redraw()

func _safe_rect() -> Rect2:
	var mobile: Node = get_node_or_null("/root/MobileLocale")
	if mobile != null and mobile.has_method("safe_rect"):
		var candidate: Variant = mobile.call("safe_rect", size)
		if candidate is Rect2:
			return candidate
	return Rect2(Vector2.ZERO, size)

func _go_back() -> void:
	if not Engine.is_editor_hint():
		return_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_go_back()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 5 or h < 5:
		return
	if _background != null:
		var ts: Vector2 = _background.get_size()
		var factor: float = maxf(w / ts.x, h / ts.y)
		var crop: Vector2 = Vector2(w, h) / factor
		draw_texture_rect_region(_background, Rect2(Vector2.ZERO, size), Rect2((ts - crop) * 0.5, crop))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("06192d"))
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = 2412
		for i in range(150):
			var p: Vector2 = Vector2(random.randf_range(0, w * 0.5), random.randf_range(0, h))
			draw_circle(p, random.randf_range(0.3, 1.2), Color(0.66, 0.85, 1.0, random.randf_range(0.15, 0.50)))
	# The representative stands directly over the actual planet background.


# v1084-direct-cloud-speakers: the dialogue owns its three speaker controls.
# Preserve the existing clouds, their selection handlers, and dialogue rules.
func _v1084_install_cloud_speakers() -> void:
	if get_node_or_null("MikaDirectCloudSpeakers") != null:
		return
	var bridge: Node = V1084_CLOUD_SPEAKERS_SCRIPT.new() as Node
	if bridge != null:
		bridge.name = "MikaDirectCloudSpeakers"
		add_child(bridge)


# MIKA v114.3: guarantee live liquid when phase dialogue opens
func _v1143_attach_liquid() -> void:
	var existing: Node = get_node_or_null("MikaPhaseDialogueBridge")
	if existing != null:
		if existing.get_script() == V1143_PHASE_BRIDGE:
			existing.set_process(true)
			existing.call_deferred("sync_now")
			return
		# Previous v113 bridge: detach and free, without changing any other child.
		remove_child(existing)
		existing.queue_free()
	var bridge: Node = V1143_PHASE_BRIDGE.new()
	bridge.name = "MikaPhaseDialogueBridge"
	bridge.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bridge)
	bridge.call_deferred("sync_now")
