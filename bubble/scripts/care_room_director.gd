extends Node2D
# MIKA_PLAYTOWN_DENTAL_WIRING_FIX_V8_5_9_9
# MIKA_PLAYTOWN_NATIVE_DENTAL_V8_5_9_8
# MIKA_DENTAL_RESTORED_TO_V8_5_9_2_R1
# v8.5.9.4: memoized bristle contact in ORIGINAL texture-local pixels.
# Ellipse geometry is cached per original imported PlayTown PNG.
## MIKA Bubble Room: actions on the right, auto-walk inside polygon, smooth 2D camera,
## preserved procedural body, interactive scrub/teeth and manual joystick mode.
## Designed for Godot 4.7.1; no installation or upgrading code here.

const ART_SIZE := Vector2(1672.0, 941.0)
const PLAYTOWN_TEETH_ADAPTER = preload("res://bubble/scripts/room_playtown_teeth_v8598.gd")
var _mika_playtown_teeth: Node2D = null
const JOYSTICK_SCRIPT := preload("res://bubble/scripts/room_joystick.gd")
const CONTEXT_ACTION_SCRIPT := preload("res://bubble/scripts/care_context_stop.gd")
const FACE_SCENE := preload("res://bubble/scenes/bubble_face.tscn")
# MIKA_ROOM_V8_INTEGRATION
# MIKA_ROOM_V8_2_FEED_FLIGHT
# MIKA_FEED_ONLY_EXISTING_FX_V83_1
# MIKA_FEED_ABSORPTION_V8_3_4
const FEED_ABSORPTION_SCRIPT = preload("res://bubble/room_v8/feed_absorption_fx.gd")
# MIKA_BUBBLE_WATER_GAS_V8_3_7
const WATER_ABSORPTION_SCRIPT = preload("res://bubble/room_v8/water_absorption_fx.gd")
# MIKA_FEED_GAS_SAME_BUBBLE_V8_3_8
# MIKA_BUBBLE_CONTINUOUS_SHOWER_V8_3_9
# MIKA_BUBBLE_ADAPTIVE_SHOWER_V8_3_9_2
# MIKA_BUBBLE_LIVE_DENTAL_V8_4_0
# MIKA_BUBBLE_NATIVE_DENTAL_V8_4_1
# MIKA_BUBBLE_FACERIG_DENTAL_V8_4_2
# MIKA_BUBBLE_SEAMLESS_DENTAL_V8_4_3
# MIKA_BUBBLE_PNG_TOOTH_ROLLBACK_V8_4_4
# MIKA_BUBBLE_SMOOTH_LIPS_V8_4_5
# MIKA_BUBBLE_CAMERA_SYNC_MOUTH_V8_4_6
# MIKA_BUBBLE_SEAMLESS_SLEEP_V8_4_7
# MIKA_BUBBLE_ALWAYS_FRONT_SLEEP_V8_4_7_1
# MIKA_BUBBLE_CARE_HUD_V8_4_8
# MIKA_BUBBLE_ICONS_FIRST_CARD_V8_4_9_2
# MIKA_BUBBLE_CARE_MAIN_HUD_V8_5_0
# MIKA_CARE_TOOLS_STOP_SOUND_V8_5_9
const ROOM_GAS_ONLY_SCRIPT = preload("res://bubble/scripts/gas_cloud.gd")
const WALK_SPEED := 255.0
const ACCELERATION := 850.0
const BRAKE_ACCELERATION := 1120.0
const DEAD_ZONE := 0.17
# All choices correspond to the approved FaceRig, plus six combinations made
# from the SAME eye/mouth/brow assets (no new unrelated face textures).
const ROOM_EMOTIONS: Array[String] = [
	"calm", "happy", "excited", "curious", "surprised", "shy", "sad",
	"scared", "annoyed", "sleepy", "sleeping", "playful", "uncomfortable",
	"content", "strained", "embarrassed", "relieved", "proud", "thoughtful",
	"delighted", "dreamy", "mischievous", "attentive"
]

var ZONES: Array[Dictionary] = [
	{"id":"shower", "name":"Душ", "button":"Принять душ", "point":Vector2(395,495), "radius":112.0, "action":"bath", "zoom":1.80, "seconds":-1.0},
	{"id":"mirror", "name":"Зеркало", "button":"Почистить зубы", "point":Vector2(586,489), "radius":104.0, "action":"brush_teeth", "zoom":1.90, "seconds":-1.0},
	{"id":"food", "name":"Кормушка", "button":"Покормить", "point":Vector2(830,487), "radius":113.0, "action":"eat", "zoom":1.57, "seconds":7.0},
	{"id":"water", "name":"Поилка", "button":"Попоить", "point":Vector2(1070,487), "radius":112.0, "action":"drink", "zoom":1.57, "seconds":5.7},
	{"id":"bed", "name":"Лежанка", "button":"Отправить спать", "point":Vector2(1275,495), "radius":115.0, "action":"sleep", "zoom":1.48, "seconds":-1.0}
]

@onready var stage: Node2D = $Stage
@onready var camera: Camera2D = $Camera2D
@onready var avatar: Node2D = $Stage/BubbleAnchor
@onready var bubble: MikaBubbleBrain = $Stage/BubbleAnchor/Bubble
@onready var walk_area = $Stage/WalkArea
@onready var room_v8: Node2D = $Stage/RoomPropsV8
@onready var zone_visual: Node2D = $Stage/ZoneVisual
@onready var shower_fx: MikaBubbleShowerFX = $Stage/ShowerFX
@onready var water_fx: MikaBubbleDrinkerFX = $Stage/DrinkerFX
@onready var feeder_fx: MikaBubbleFeederFX = $Stage/FeederFX
@onready var scrub_mask: MikaRoomScrubMask = $Stage/BubbleAnchor/ScrubMask

var _hud: Control
var _joystick
var _context_use_action: Control
var _care_sound: AudioStreamPlayer
var _action_buttons: Dictionary = {}
var _use_button: Button
var _status: Label
var _title: Label
var _hint: Label
var _debug_button: Button
var _turn_180_button: Button
var _turn_360_button: Button
var _emotion_button: Button
var _progress: ProgressBar
var _focus_dim: ColorRect
var _focus_face: MikaBubbleFace
var _tool: Sprite2D
var _tool_dragging: bool = false
var _drag_offset := Vector2.ZERO
var _last_tip := Vector2.ZERO
var _tool_mode: String = ""
var _focus_finished: bool = false

var _base_zoom: float = 1.0
var _camera_to := ART_SIZE * 0.5
var _zoom_to: float = 1.0
var _world_position := Vector2(830.0, 690.0)
var _v8_inside: bool = false
var _v8_enter_tween: Tween
var _v8_leave_from: Vector2 = Vector2.ZERO
var _v8_leave_t: float = 0.0
const V8_EXIT_SECONDS: float = 1.40
const V8_ENTRY_SECONDS: float = 1.68
var _v8_flight_t: float = 0.0
var _v8_flight_start: Vector2 = Vector2.ZERO
var _v8_flight_end: Vector2 = Vector2.ZERO
var _v8_flight_kind: String = ""
var _v8_entry_heading: float = 0.0
var _v8_exit_heading: float = 0.0
var _v8_action_queued: String = ""
var _v8_care_clock: float = 0.0
var _v8_eating: bool = false
const FEED_LIFT_SECONDS: float = 0.76
const FEED_LOWER_SECONDS: float = 0.68
const WATER_LIFT_SECONDS: float = 0.72
const WATER_LOWER_SECONDS: float = 0.64
const POST_FEED_GAS_DURATION: float = 3.55
const POST_FEED_TURN_DURATION: float = 1.15
var _feed_motion_t: float = 0.0
var _feed_motion_from: Vector2 = Vector2.ZERO
var _feed_motion_to: Vector2 = Vector2.ZERO
var _feed_station_point: Vector2 = Vector2.ZERO
var _feed_absorption_fx: Node2D = null
var _water_station_point: Vector2 = Vector2.ZERO
var _water_motion_t: float = 0.0
var _water_motion_from: Vector2 = Vector2.ZERO
var _water_absorption_fx: Node2D = null
var _post_feed_gas_t: float = 0.0
var _post_feed_turn_t: float = 0.0
var _post_feed_cloud: Node2D = null
var _velocity := Vector2.ZERO
var _facing: float = 0.0
var _last_heading: float = 0.0
var _turn_left: float = 0.0
var _turn_cooldown: float = 0.0
var _movement_action: String = ""
var _nearest: String = ""
var _mode: String = "free" # free, approach, focus, care
var _target_id: String = ""
var _route: Array[Vector2] = []
var _focus_delay: float = 0.0
var _dental_turn_from: float = 0.0
var _dental_turn_elapsed: float = 0.0
var _dental_close_elapsed: float = -1.0
var _dental_camera_retreat: bool = false
const DENTAL_TURN_SECONDS: float = 0.70
const DENTAL_CAMERA_APPROACH_SECONDS: float = 1.60
const BED_SLEEP_SECONDS: float = 5.0
const BED_FRONT_Z: int = 13
const BED_NORMAL_Z: int = BED_FRONT_Z
var _bed_opaque_mix: float = 0.0
var _bed_opaque_target: float = 0.0
const DENTAL_MOUTH_OPEN_DELAY: float = 0.12
const DENTAL_MOUTH_OPEN_SECONDS: float = 0.35
const DENTAL_MOUTH_CLOSE_DELAY: float = 0.14
const DENTAL_MOUTH_CLOSE_SECONDS: float = 0.32
var _action_left: float = -1.0
var _debug: bool = false
# Explicit turns use an UNWRAPPED heading. lerp_angle() alone would turn a
# requested 360° into 0°, because both orientations are equivalent mod TAU.
var _manual_turn_from: float = 0.0
var _manual_turn_delta: float = 0.0
var _manual_turn_time: float = 0.0
var _manual_turn_duration: float = 0.0
var _emotion_index: int = 0
var _idle_look_seconds: float = 0.0

func _ready() -> void:
	stage.position = Vector2.ZERO
	stage.scale = Vector2.ONE
	# The avatar is ALWAYS above the bed front lip (z=12). Never
	# change its drawing order when an animation state changes.
	avatar.z_index = BED_FRONT_Z
	camera.make_current()
	camera.position = Vector2(836.0, 440.0)
	# Coordinates come from the separate v8 station PNGs, not old painted wall.
	# The existing liquid Bubble, face, movement/turn system stay untouched.
	for z in ZONES:
		var action_id: String = str(z["id"])
		z["point"] = room_v8.call("point", action_id, "approach")
		z["focus"] = room_v8.call("point", action_id, "focus")
		z["activity_point"] = room_v8.call("point", action_id, "activity")
		z["mouth_point"] = room_v8.call("point", action_id, "mouth")
		z["zoom"] = room_v8.call("zoom", action_id)
	walk_area.set_v8_forbidden(room_v8.call("blocked_rects"))
	# Original FX were painted onto the OLD monolithic background. Keep their
	# controller APIs for care logic, but never draw them at obsolete positions.
	shower_fx.visible = false
	water_fx.visible = false
	feeder_fx.visible = false
	_world_position = walk_area.nearest_point(_world_position)
	avatar.position = _world_position
	zone_visual.set("zones", ZONES)
	bubble.external_motion_control = true
	bubble.auto_return_idle = false
	shower_fx.allow_switch_click = false
	water_fx.allow_switch_click = false
	feeder_fx.allow_switch_click = false
	shower_fx.set_process_unhandled_key_input(false)
	water_fx.set_process_unhandled_key_input(false)
	feeder_fx.set_process_unhandled_key_input(false)
	shower_fx.set_shower_on(false)
	water_fx.set_fountain_on(true)
	feeder_fx.clear_bowl()
	scrub_mask.progress_changed.connect(_update_progress)
	scrub_mask.completed.connect(_on_care_completed)
	_build_hud()
	get_viewport().size_changed.connect(_layout)
	_layout()
	bubble.play_action("idle")
	_update_nearest()
	process_priority = 150

func _make_style(fill: Color, edge: Color, radius: int = 17) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style

func _make_button(text_value: String) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.94,0.98,1.0))
	btn.add_theme_stylebox_override("normal", _make_style(Color(0.08,0.15,0.32,0.91), Color(0.38,0.72,0.95,0.66)))
	btn.add_theme_stylebox_override("hover", _make_style(Color(0.14,0.29,0.48,0.98), Color(0.76,0.92,1.0,1.0)))
	btn.add_theme_stylebox_override("pressed", _make_style(Color(0.19,0.43,0.53,0.98), Color(0.86,1.0,1.0,1.0)))
	btn.add_theme_stylebox_override("disabled", _make_style(Color(0.05,0.11,0.18,0.6), Color(0.26,0.40,0.48,0.3)))
	return btn

func _new_label(text_value: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _care_button_label(action_id: String) -> String:
	match action_id:
		"shower": return "Душ"
		"mirror": return "Почистить зубы"
		"food": return "Покормить"
		"water": return "Попоить"
		"bed": return "Спать"
	return action_id

func _care_button_icon(action_id: String) -> String:
	match action_id:
		"mirror": return "tooth"
		"bed": return "sleep"
	return action_id

func _decorate_care_button(button: Button, action_id: String) -> void:
	# One actual Button with icon and text inside its clickable area.
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var inner := HBoxContainer.new()
	inner.name = "IconAndText"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 7)
	button.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icon := TextureRect.new()
	icon.name = "ActivityIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load("res://bubble/ui/care_icons/" + _care_button_icon(action_id) + ".svg") as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	inner.add_child(icon)
	button.tooltip_text = _care_button_label(action_id)

func _set_manual_care_stop(enabled: bool) -> void:
	if not is_instance_valid(_context_use_action):
		return
	_context_use_action.call("set_stop_active", enabled)
	_context_use_action.call("set_action_available", enabled)

func _care_play_sound(sound_name: String, pitch: float = 1.0) -> void:
	if not is_instance_valid(_care_sound):
		return
	var path: String = "res://education/playtown/audio/sfx/" + sound_name
	if not ResourceLoader.exists(path):
		return
	_care_sound.stop()
	_care_sound.stream = load(path) as AudioStream
	_care_sound.pitch_scale = pitch
	_care_sound.play()

func _on_context_use_pressed(_action_mode: String) -> void:
	if _mode == "care" and _target_id in ["shower", "mirror"] and not _focus_finished:
		_care_play_sound("connect_point.ogg", 0.78)
		_stop_care(true)
		return
	if _mode == "free" and _nearest != "":
		_request_action(_nearest)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "OverlayHUD"
	add_child(layer)
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hud)
	_focus_dim = ColorRect.new()
	_focus_dim.color = Color(0.04,0.07,0.15,0.57)
	_focus_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_dim.visible = false
	_hud.add_child(_focus_dim)
	_focus_face = FACE_SCENE.instantiate() as MikaBubbleFace
	_focus_face.name = "DentalCloseup"
	_focus_face.show_preview_body = true
	_focus_face.automatic_blink = true
	_focus_face.visible = false
	_hud.add_child(_focus_face)
	_focus_face.brushing_progress_changed.connect(_update_progress)
	_joystick = JOYSTICK_SCRIPT.new()
	_joystick.name = "RightJoystick"
	_hud.add_child(_joystick)
	_context_use_action = CONTEXT_ACTION_SCRIPT.new() as Control
	_context_use_action.name = "LeftContextAction_FlightOriginal"
	_hud.add_child(_context_use_action)
	_context_use_action.call("set_action_mode", "use")
	_context_use_action.call("set_stop_active", false)
	_context_use_action.call("set_action_available", false)
	_context_use_action.connect("action_requested", Callable(self, "_on_context_use_pressed"))
	_use_button = _make_button("ИСПОЛЬЗОВАТЬ")
	_use_button.pressed.connect(_use_or_cancel)
	_use_button.visible = false
	# The legacy rectangular Use Button remains a state holder, not on screen.
	_title = _new_label("БАББЛ · КОМНАТА УХОДА", 22, Color(0.95,0.99,1))
	_hud.add_child(_title)
	_status = _new_label("Выбери действие справа или двигай Баббла джойстиком", 19, Color(0.94,0.99,1))
	_hud.add_child(_status)
	_hint = _new_label("WASD / стрелки · E — рядом с объектом · Esc — назад", 16, Color(0.88,0.96,1))
	_hud.add_child(_hint)
	for z in ZONES:
		var id: String = str(z["id"])
		var btn := _make_button("")
		_decorate_care_button(btn, id)
		btn.pressed.connect(_request_action.bind(id))
		_hud.add_child(btn)
		_action_buttons[id] = btn
	_turn_180_button = _make_button("↶ 180°")
	_turn_180_button.pressed.connect(_start_manual_turn.bind(PI))
	_turn_180_button.add_theme_font_size_override("font_size", 17)
	# _turn_180_button is retained only for legacy state; no UI node mounted.
	_turn_360_button = _make_button("↻ 360°")
	_turn_360_button.pressed.connect(_start_manual_turn.bind(TAU))
	_turn_360_button.add_theme_font_size_override("font_size", 17)
	# _turn_360_button is retained only for legacy state; no UI node mounted.
	_emotion_button = _make_button("ЭМОЦИИ 1/23")
	_emotion_button.add_theme_font_size_override("font_size", 15)
	_emotion_button.pressed.connect(_next_room_emotion)
	# _emotion_button is retained only for legacy state; no UI node mounted.
	_debug_button = _make_button("F3 · Границы")
	_debug_button.add_theme_font_size_override("font_size",15)
	_debug_button.pressed.connect(_toggle_debug)
	# Keep F3 debugging in code without displaying a debug button.
	_progress = ProgressBar.new()
	# MIKA_CARE_PROGRESS_CAPSULE_V8_5_9_2
	# Curved dark capsule with a softly glowing multicolor fill.
	var progress_track: StyleBoxFlat = StyleBoxFlat.new()
	progress_track.bg_color = Color("071b37")
	progress_track.border_color = Color("54bbdf")
	progress_track.set_border_width_all(2)
	progress_track.set_corner_radius_all(14)
	progress_track.shadow_color = Color(0.06, 0.53, 0.87, 0.34)
	progress_track.shadow_size = 5
	_progress.add_theme_stylebox_override("background", progress_track)
	# Rounded RGBA nine-patch: curved LEFT and RIGHT caps even at 10%/100%.
	# Former GradientTexture2D had square corners despite a rounded background.
	var progress_fill: StyleBoxTexture = StyleBoxTexture.new()
	progress_fill.texture = load("res://bubble/assets/interaction/care_progress_fill_rounded.png") as Texture2D
	# Keep cap pixels intact; stretch only the middle across responsive widths.
	progress_fill.texture_margin_left = 16.0
	progress_fill.texture_margin_right = 16.0
	progress_fill.texture_margin_top = 8.0
	progress_fill.texture_margin_bottom = 8.0
	# Prevent nine-patch borders from changing Control minimum size.
	progress_fill.set_content_margin_all(0.0)
	_progress.add_theme_stylebox_override("fill", progress_fill)
	_progress.min_value = 0.0
	_progress.max_value = 100.0
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.visible = false
	_hud.add_child(_progress)
	_tool = Sprite2D.new()
	_tool.visible = false
	_tool.z_index = 25
	_hud.add_child(_tool)
	# Quiet reusable sound player: existing PlayTown clips only.
	_care_sound = AudioStreamPlayer.new()
	_care_sound.name = "BubbleCareShortSounds"
	_care_sound.volume_db = -13.0
	add_child(_care_sound)
	# Gameplay can keep updating these labels/preview controls, but the
	# player sees only the clean redesigned interface.
	_title.hide()
	_status.hide()
	_hint.hide()
	_turn_180_button.hide()
	_turn_360_button.hide()
	_emotion_button.hide()
	_debug_button.hide()

func _layout() -> void:
	var size := get_viewport_rect().size
	_base_zoom = maxf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	if _mode == "free" or _mode == "approach":
		_zoom_to = _base_zoom
		if _mode == "free":
			camera.zoom = Vector2.ONE * _base_zoom
			camera.position = Vector2(836.0, 440.0)
	elif _target_id != "":
		_zoom_to = _base_zoom * (5.2 if _target_id == "mirror" else float(_zone(_target_id)["zoom"]))
	if _hud == null:
		return
	_hud.size = size
	_focus_dim.position = Vector2.ZERO
	_focus_dim.size = size
	_title.position = Vector2(24,18)
	_title.size = Vector2(600,38)
	_status.position = Vector2(24,60)
	_status.size = Vector2(maxf(350.0,size.x-340.0),33)
	_hint.position = Vector2(24,102)
	_hint.size = Vector2(730,30)
	var panel_width := 248.0
	var panel_x := size.x - panel_width - 17.0
	var panel_y := 88.0
	for i in range(ZONES.size()):
		var btn: Button = _action_buttons[str(ZONES[i]["id"])]
		btn.position = Vector2(panel_x,panel_y+float(i)*61.0)
		btn.size = Vector2(panel_width,53.0)
	_debug_button.position = Vector2(panel_x, panel_y + 312.0)
	_debug_button.size = Vector2(panel_width,42.0)
	# Small preview controls stay on the LEFT, clear of the right joystick.
	var preview_width: float = minf(164.0, maxf(100.0, size.x * 0.39))
	_turn_180_button.position = Vector2(24.0, size.y - 340.0)
	_turn_180_button.size = Vector2(preview_width, 44.0)
	_turn_360_button.position = Vector2(24.0, size.y - 292.0)
	_turn_360_button.size = Vector2(preview_width, 44.0)
	_emotion_button.position = Vector2(24.0, size.y - 244.0)
	_emotion_button.size = Vector2(preview_width, 44.0)
	_joystick.position = Vector2(size.x-199.0,size.y-207.0)
	_use_button.position = Vector2(27.0,size.y-135.0)
	_use_button.size = Vector2(231,72)
	# Center the wash/teeth progress capsule above the scene.
	var progress_w: float = clampf(size.x * 0.46, 190.0, 630.0)
	var progress_h: float = clampf(size.y * 0.032, 18.0, 28.0)
	_progress.position = Vector2((size.x - progress_w) * 0.5, maxf(14.0, size.y * 0.055))
	_progress.size = Vector2(progress_w, progress_h)
	_focus_face.position = Vector2(size.x*0.44,size.y*0.53)
	_focus_face.scale = Vector2.ONE * clampf(size.y / 800.0,0.67,1.22)
	# v8.4.8: place activity panel on the right joystick's centre axis.
	# The left circle mirrors its physical size and lower-screen margin.
	var side_margin: float = maxf(8.0, size.x - (_joystick.position.x + _joystick.size.x))
	_context_use_action.position = Vector2(side_margin, _joystick.position.y)
	_context_use_action.scale = _joystick.scale
	var actions_axis_x: float = _joystick.position.x + _joystick.size.x * 0.5
	# Square actions follow the REAL simulator-hub Back button scale.
	# All five icons remain clickable within the same square hit areas.
	var hub_scale: float = minf(size.y / 864.0, size.x / 1680.0)
	var desired_side: float = 158.0 * hub_scale * 0.60
	var activity_gap: float = clampf(size.y * 0.012, 5.0, 12.0)
	var max_side: float = maxf(25.0, (_joystick.position.y - 38.0 - 4.0 * activity_gap) / 5.0)
	var activity_side: float = maxf(25.0, minf(desired_side, max_side))
	var activities_stack: float = 5.0 * activity_side + 4.0 * activity_gap
	var max_top: float = maxf(8.0, _joystick.position.y - activities_stack - 16.0)
	var activities_top: float = minf(max_top, maxf(8.0, size.y * 0.43 - activities_stack * 0.5))
	for i in range(ZONES.size()):
		var activity: Button = _action_buttons[str(ZONES[i]["id"])]
		activity.size = Vector2.ONE * activity_side
		var activity_icon: TextureRect = activity.get_node_or_null("IconAndText/ActivityIcon") as TextureRect
		if activity_icon != null:
			activity_icon.custom_minimum_size = Vector2.ONE * (activity_side * 0.61)
		activity.position = Vector2(actions_axis_x - activity_side * 0.5,
			activities_top + float(i) * (activity_side + activity_gap))
	if not _tool_dragging:
		_reset_tool_position()

func _reset_tool_position() -> void:
	var size := get_viewport_rect().size
	_tool.position = Vector2(size.x * (0.71 if _tool_mode == "teeth" else 0.28),size.y*0.74)

func _zone(id: String) -> Dictionary:
	for z in ZONES:
		if str(z["id"]) == id: return z
	return {}

func _keyboard_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): d.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): d.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): d.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): d.y += 1.0
	return d.normalized()

func _physics_process(delta: float) -> void:
	# Water/gas v8.3.7: dispatch before old food_lower/other elif blocks.
	# This avoids depending on their order or indentation in user patches.
	if _mode in ["food_lower", "food_gas", "food_turn", "water_lift", "water_lower"] or (_target_id == "water" and _mode == "care"):
		_advance_water_gas(delta)
		_velocity = Vector2.ZERO
		_update_avatar(delta)
		return

	_turn_180_button.visible = false
	_turn_360_button.visible = false
	_emotion_button.visible = false
	if _manual_turn_duration > 0.0 and _mode == "free":
		_advance_manual_turn(delta)
		_update_nearest()
		_update_avatar(delta)
		return
	if _mode == "free":
		var d: Vector2 = _joystick.direction
		if d.length() <= DEAD_ZONE:
			d = _keyboard_dir()
		_move_in_room(d,delta)
		_update_idle_turn(delta, d)
		_update_nearest()
	elif _mode == "approach":
		_follow_route(delta)
	elif _mode == "food_lift":
		_feed_motion_t = minf(_feed_motion_t + delta / FEED_LIFT_SECONDS, 1.0)
		avatar.position = _feed_motion_from.lerp(_feed_motion_to, _v8_smooth(_feed_motion_t))
		if _feed_motion_t >= 1.0:
			avatar.position = _feed_station_point
			_begin_care_action()
	elif _mode == "food_lower":
		_feed_motion_t = minf(_feed_motion_t + delta / FEED_LOWER_SECONDS, 1.0)
		avatar.position = _feed_motion_from.lerp(_world_position, _v8_smooth(_feed_motion_t))
		if _feed_motion_t >= 1.0:
			avatar.position = _world_position
			_feed_set_solid(false)
			_finish_care()
			if _v8_action_queued != "":
				var next_food_action: String = _v8_action_queued
				_v8_action_queued = ""
				call_deferred("_request_action", next_food_action)
	elif _mode == "platform_enter":
		_v8_flight_t = minf(_v8_flight_t + delta / V8_ENTRY_SECONDS, 1.0)
		avatar.position = _v8_flight_path(_v8_flight_start, _v8_flight_end, _v8_flight_t, _v8_flight_kind)
		if _v8_flight_kind == "shower":
			_v8_adapt_shower_heading(_v8_flight_t, true)
		elif _v8_flight_kind == "bed":
			_v8_bed_heading(_v8_flight_t, true)
		if _v8_flight_t >= 1.0:
			avatar.position = _v8_flight_end
			_begin_care_action()
	elif _mode == "returning":
		_v8_leave_t = minf(_v8_leave_t + delta / V8_EXIT_SECONDS, 1.0)
		avatar.position = _v8_flight_path(_v8_leave_from, _world_position, _v8_leave_t, _v8_flight_kind)
		if _v8_flight_kind == "shower":
			_v8_adapt_shower_heading(_v8_leave_t, false)
		elif _v8_flight_kind == "bed":
			_v8_bed_heading(_v8_leave_t, false)
		if _v8_leave_t >= 1.0:
			_mode = "free"
			_joystick.visible = true
			avatar.position = _world_position
			if _v8_flight_kind == "bed":
				avatar.z_index = BED_NORMAL_Z
				_bed_set_solid(false)
				bubble.set_room_sleep_pose(false)
				bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
			else:
				bubble.play_action("idle")
			if _v8_action_queued != "":
				var next_id: String = _v8_action_queued
				_v8_action_queued = ""
				call_deferred("_request_action", next_id)
	elif _mode == "focus":
		if _target_id == "mirror":
			_advance_dental_turn(delta)
		_focus_delay -= delta
		if _focus_delay <= 0.0:
			_begin_care()
	elif _mode == "care":
		_v8_update_station_care(delta)
		if _action_left >= 0.0:
			_action_left -= delta
			if _action_left <= 0.0:
				_finish_care()

	if _mode != "free" and _mode != "approach":
		_velocity = Vector2.ZERO
	_update_avatar(delta)

func _update_idle_turn(delta: float, input_dir: Vector2) -> void:
	# Never fight the joystick, scripted routes, or a deliberate 180/360 turn.
	if input_dir.length() > DEAD_ZONE or _velocity.length() > 10.0:
		_idle_look_seconds = 0.0
		bubble.set_room_turn_activity(0.0)
		return
	_idle_look_seconds += delta
	if _idle_look_seconds < 1.65:
		return
	# Look at the player after a short delay. A tiny ongoing sway prevents a
	# mannequin pose, without an endless full-body spinning carousel.
	var sway: float = 0.07 * sin((_idle_look_seconds - 1.65) * 0.63)
	sway += 0.025 * sin(_idle_look_seconds * 0.39)
	var error: float = wrapf(sway - _facing, -PI, PI)
	_facing = lerp_angle(_facing, sway, 1.0 - exp(-1.55 * delta))
	bubble.set_room_heading(_facing)
	bubble.set_room_turn_activity(clampf(absf(error) * 0.23, 0.0, 0.35))

func _start_manual_turn(angle_rad: float) -> void:
	if _mode != "free":
		return
	_joystick.clear_input()
	_velocity = Vector2.ZERO
	_idle_look_seconds = 0.0
	bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
	# Preserve the real current heading, including non-cardinal orientations.
	_manual_turn_from = _facing
	_manual_turn_delta = angle_rad
	_manual_turn_time = 0.0
	_manual_turn_duration = 1.45 if absf(angle_rad) <= PI + 0.001 else 3.1
	bubble.set_room_emotion("playful" if absf(angle_rad) <= PI + 0.001 else "excited", _manual_turn_duration + 0.4)
	_status.text = "Разворот Баббла: %d°" % int(round(rad_to_deg(angle_rad)))
	_hint.text = "Лицо → профиль → спина → профиль → лицо" if absf(angle_rad) > PI + 0.1 else "Лицо → профиль → спина"
	_turn_180_button.disabled = true
	_turn_360_button.disabled = true

func _advance_manual_turn(delta: float) -> void:
	_manual_turn_time += delta
	var u: float = clampf(_manual_turn_time / _manual_turn_duration, 0.0, 1.0)
	# Smoothstep preserves the sign and COMPLETE angular distance, including
	# passing through 180° instead of snapping to the equivalent 0° at 360°.
	var ease: float = u * u * (3.0 - 2.0 * u)
	var new_heading: float = _manual_turn_from + _manual_turn_delta * ease
	var steer: float = new_heading - _facing
	_facing = new_heading
	bubble.set_room_heading(_facing)
	bubble.set_room_turn_activity(sin(PI * u) if u < 1.0 else 0.0)
	bubble.set_room_locomotion("idle", 0.0, 0.0, steer)
	if u >= 1.0:
		_manual_turn_duration = 0.0
		_manual_turn_time = 0.0
		_last_heading = wrapf(_facing, -PI, PI)
		_turn_180_button.disabled = false
		_turn_360_button.disabled = false
		_status.text = "Разворот завершён · Баббл готов гулять"
		_hint.text = "WASD / стрелки · E — действие · F12 — снимок"

func _next_room_emotion() -> void:
	if _mode != "free":
		return
	_emotion_index = (_emotion_index + 1) % ROOM_EMOTIONS.size()
	var emotion_id: String = ROOM_EMOTIONS[_emotion_index]
	bubble.set_room_emotion(emotion_id, 5.5)
	var label: String = emotion_id
	var rig: MikaBubbleFace = bubble.get_face()
	if rig != null:
		var item: Dictionary = rig.presets.get(emotion_id, {})
		label = str(item.get("label", emotion_id))
	_emotion_button.text = "ЭМОЦИЯ %d/%d" % [_emotion_index + 1, ROOM_EMOTIONS.size()]
	_status.text = "Эмоция Баббла: " + label

func _move_in_room(input_vector: Vector2, delta: float) -> void:
	# Moving with the joystick naturally resumes after an explicit turn.
	var active: bool = input_vector.length() > DEAD_ZONE
	var wanted := input_vector.normalized() * WALK_SPEED * minf(input_vector.length(),1.0) if active else Vector2.ZERO
	_velocity = _velocity.move_toward(wanted, (ACCELERATION if active else BRAKE_ACCELERATION) * delta)
	if _velocity.length() < 1.4: _velocity = Vector2.ZERO
	var previous_pos: Vector2 = _world_position
	if not _velocity.is_zero_approx():
		_world_position = walk_area.try_step(_world_position, _velocity * delta)
	avatar.position = _world_position
	_choose_motion(_velocity, delta, _world_position.distance_to(previous_pos))

func _choose_motion(v: Vector2, delta: float, traveled: float) -> void:
	# No discrete turn-scene replacement in the care room. One liquid body,
	# continuous satellite springs and gait phase, even on a 180° turn.
	if v.length_squared() < 180.0:
		bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
		_movement_action = ""
		return
	var target: float = atan2(v.x, v.y)
	var steer: float = wrapf(target - _last_heading, -PI, PI)
	_last_heading = target
	_facing = lerp_angle(_facing, target, 1.0 - exp(-6.2 * delta))
	var next: String = "walk_forward"
	if absf(v.x) > absf(v.y) * 1.1:
		next = "strafe_right" if v.x > 0.0 else "strafe_left"
	elif v.y < 0.0:
		next = "walk_backward"
	bubble.set_room_locomotion(next, clampf(v.length() / WALK_SPEED, 0.0, 1.0), traveled, steer)
	bubble.set_room_heading(_facing)
	_movement_action = next

func _update_avatar(delta: float) -> void:
	var depth := clampf((_world_position.y-460.0)/380.0,0.0,1.0)
	var target_scale := lerpf(0.28,0.405,depth)
	var s := lerpf(avatar.scale.x,target_scale,1.0-exp(-4.5*delta))
	avatar.scale = Vector2.ONE*s
	# Face orientation belongs to bubble_movement.gd. Do not override its
	# transform or alpha here: the old direction-based alpha hid both eyes.

func _process(delta: float) -> void:
	_bed_update_opacity(delta)
	var zoom_lerp: float = 1.0-exp(-3.0*delta)
	var z := lerpf(camera.zoom.x,_zoom_to,zoom_lerp)
	camera.zoom = Vector2.ONE*maxf(0.01,z)
	# Follow the mouth only during approach/cleaning, never during retreat.
	if _target_id == "mirror" and _mode in ["focus", "care"] and not _dental_camera_retreat:
		_camera_to = _mirror_focus_point()
	if _dental_close_elapsed >= 0.0:
		_advance_dental_close(delta)
	var desired := _clamp_camera(_camera_to,z)
	camera.position = camera.position.lerp(desired,1.0-exp(-2.6*delta))

func _clamp_camera(point: Vector2, zoom_value: float) -> Vector2:
	var half_visible: Vector2 = get_viewport_rect().size/(maxf(zoom_value,0.01)*2.0)
	var x := ART_SIZE.x*0.5 if half_visible.x>=ART_SIZE.x*0.5 else clampf(point.x,half_visible.x,ART_SIZE.x-half_visible.x)
	var y := ART_SIZE.y*0.5 if half_visible.y>=ART_SIZE.y*0.5 else clampf(point.y,half_visible.y,ART_SIZE.y-half_visible.y)
	return Vector2(x,y)

func _valid_segment(from: Vector2, to: Vector2) -> bool:
	for i in range(1,31):
		if not walk_area.is_walkable(from.lerp(to,float(i)/30.0)):
			return false
	return true

func _build_route(goal: Vector2) -> void:
	_route.clear()
	if not _valid_segment(_world_position,goal):
		var middle: Vector2 = walk_area.nearest_point(Vector2(836.0,565.0))
		if _valid_segment(_world_position,middle) and _valid_segment(middle,goal):
			_route.append(middle)
		else:
			var safe: Vector2 = walk_area.nearest_point((_world_position+goal)*0.5)
			if _valid_segment(_world_position,safe) and _valid_segment(safe,goal):
				_route.append(safe)
	_route.append(goal)

func _follow_route(delta: float) -> void:
	if _route.is_empty():
		_start_camera_focus()
		return
	var goal: Vector2 = _route[0]
	var offset: Vector2 = goal-_world_position
	if offset.length() < 12.0:
		# Avoid the last 0-12px positional snap before an adaptive shower flight.
		if _target_id in ["shower", "bed"] and _route.size() == 1:
			_route.remove_at(0)
			_velocity = Vector2.ZERO
			_start_camera_focus()
			return
		_world_position = goal
		avatar.position = goal
		_route.remove_at(0)
		_velocity = Vector2.ZERO
		if _route.is_empty():
			_start_camera_focus()
		return
	var direction := offset.normalized()
	var desired_speed := WALK_SPEED * clampf(offset.length()/90.0,0.35,1.0)
	_move_in_room(direction*desired_speed/WALK_SPEED,delta)
	if _velocity.length_squared() < 5.0:
		_world_position = walk_area.nearest_point(_world_position)

func _request_action(id: String) -> void:
	if _zone(id).is_empty(): return
	if _target_id == "food" and _mode in ["food_lift", "care", "food_lower", "food_gas", "food_turn"]:
		_v8_action_queued = id
		if _mode in ["food_lift", "care"]:
			_feed_begin_lower()
		return
	# Never teleport out of the shower/pod when another station is selected.
	if _mode == "returning":
		_v8_action_queued = id
		return
	if _target_id == "water" and _mode in ["water_lift", "care", "water_lower"]:
		_v8_action_queued = id
		if _mode != "water_lower":
			_water_begin_lower()
		return
	if _mode == "platform_enter" or (_mode == "care" and _v8_inside):
		_v8_action_queued = id
		_stop_care(false)
		return
	_manual_turn_duration = 0.0
	_idle_look_seconds = 0.0
	bubble.set_room_turn_activity(0.0)
	# The free-room Bubble is already the correct persistent actor.
	if not (id == "mirror" and _mode == "free"):
		_stop_care(false)
	avatar.position = _world_position
	_mode = "free"
	_target_id = id
	if id == "bed":
		_bed_set_solid(true)
	_mode = "approach"
	_context_use_action.call("set_action_available", false)
	_joystick.clear_input()
	_joystick.visible = false
	_use_button.visible = true
	_use_button.text = "ОТМЕНА"
	_status.text = "Баббл идёт: " + str(_zone(id)["name"])
	_hint.text = "Подход к объекту · Esc — отменить"
	_camera_to = Vector2(836.0, 440.0)
	_zoom_to = _base_zoom
	# Two access modes: nearby E/use enters from the CURRENT position;
	# distant HUD buttons walk from the CURRENT position and only then fly.
	if id in ["shower", "bed"] and _world_position.distance_to(_zone(id)["point"]) <= float(_zone(id)["radius"]) + 18.0:
		_route.clear()
		_start_camera_focus()
	else:
		_build_route(_zone(id)["point"])
	_highlight_buttons()

func _mirror_focus_point() -> Vector2:
	# Follow the *actual* live jaw; never aim camera at an avatar-relative forehead point.
	var rig: MikaBubbleFace = bubble.get_face()
	if is_instance_valid(rig):
		var jaw: Node2D = rig.get_node_or_null("ContinuousJawRig") as Node2D
		if jaw != null:
			return jaw.global_position
	return bubble.to_global(Vector2(0.0, 68.0))

func _start_camera_focus() -> void:
	_velocity = Vector2.ZERO
	_mode = "focus"
	if _target_id == "mirror":
		zone_visual.visible = false
		zone_visual.set("nearby_id", "")
	# Feeder and fountain are approached from the FRONT of the equipment:
	# Bubble's back faces the player while it eats or drinks.
	var care_heading: float = PI if _target_id == "food" or _target_id == "water" else 0.0
	# Keep the *actual* incoming heading until the continuous shower flight.
	if _target_id not in ["shower", "mirror", "bed"]:
		_facing = care_heading
		_last_heading = care_heading
		bubble.set_room_heading(care_heading)
	else:
		_last_heading = _facing
	_turn_left = 0.0
	_focus_delay = DENTAL_CAMERA_APPROACH_SECONDS if _target_id == "mirror" else (0.0 if _target_id in ["shower", "bed"] else 0.90)
	if _target_id in ["shower", "mirror", "bed"]:
		bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
	else:
		bubble.play_action("idle")
	if _target_id == "mirror":
		_dental_turn_from = _facing
		_dental_turn_elapsed = 0.0
		_dental_close_elapsed = -1.0
		_dental_camera_retreat = false
	_movement_action = ""
	var zone: Dictionary = _zone(_target_id)
	var target_point: Vector2 = zone["point"]
	_camera_to = zone["focus"]
	_zoom_to = _base_zoom*float(zone["zoom"])
	if _target_id == "mirror":
		_camera_to = _mirror_focus_point()
		_zoom_to = _base_zoom * 5.2
		_status.text = "Камера приближается: зубы Баббла"
		_hint.text = "Баббл покажет зубы, затем можно чистить"
	else:
		_status.text = "Камера приближается: " + str(zone["name"])
		_hint.text = "Выбранное действие начнётся после приближения"

func _advance_dental_close(delta: float) -> void:
	_dental_close_elapsed += delta
	var t: float = _v8_smooth(clampf(
		(_dental_close_elapsed - DENTAL_MOUTH_CLOSE_DELAY) / DENTAL_MOUTH_CLOSE_SECONDS,
		0.0, 1.0))
	# Holding the starting pose for 0.14s gives visible camera pullback.
	bubble.set_mouth_open(1.0 - t)
	if _dental_close_elapsed >= DENTAL_MOUTH_CLOSE_DELAY + DENTAL_MOUTH_CLOSE_SECONDS + 0.20:
		# The existing FaceRig's smoothing has almost finished closing.
		bubble.set_mouth_open(-1.0)
		_dental_close_elapsed = -1.0

func _advance_dental_turn(delta: float) -> void:
	_dental_turn_elapsed = minf(_dental_turn_elapsed + delta, DENTAL_TURN_SECONDS)
	var t: float = clampf(_dental_turn_elapsed / DENTAL_TURN_SECONDS, 0.0, 1.0)
	var eased: float = _v8_smooth(t)
	var new_heading: float = lerp_angle(_dental_turn_from, 0.0, eased)
	var steer: float = wrapf(new_heading - _facing, -PI, PI)
	_facing = new_heading
	_last_heading = new_heading
	bubble.set_room_heading(new_heading)
	bubble.set_room_turn_activity(sin(PI * t) * 0.28)
	bubble.set_room_locomotion("idle", 0.0, 0.0, steer)
	# Native jaw opens DURING the camera approach instead of on a new animation frame.
	# Start from the original face. Ease the existing mouth open for
	# most of the camera approach; no discrete frame or second actor.
	# The camera continues moving after this ~0.35s opening.
	# The current FaceRig crossfades lips in response to jaw_open.
	var opening: float = _v8_smooth(clampf(
		(_dental_turn_elapsed - DENTAL_MOUTH_OPEN_DELAY) / DENTAL_MOUTH_OPEN_SECONDS,
		0.0, 1.0))
	bubble.set_mouth_open(opening)
	if t >= 1.0:
		bubble.set_room_turn_activity(0.0)

func _begin_care() -> void:
	if _target_id == "food":
		_mode = "food_lift"
		_feed_motion_from = avatar.position
		_feed_motion_t = 0.0
		var mouth_contact: Vector2 = _zone("food")["mouth_point"]
		# Align the approximate mouth with the already-installed purple bowl.
		var mouth_offset: float = (bubble.position.y + 88.0 * 0.79) * avatar.scale.y
		var desired_y: float = mouth_contact.y - mouth_offset
		var floor_y: float = _world_position.y
		desired_y = clampf(desired_y, floor_y - 64.0, floor_y - 14.0)
		_feed_station_point = Vector2(_world_position.x, desired_y)
		_feed_motion_to = _feed_station_point
		_status.text = "Баббл немного приподнимается к кормушке"
		_hint.text = "Ожидаем заполнения штатной миски"
		bubble.play_action("idle")
		bubble.set_room_heading(PI)
		_feed_set_solid(true)
		return

	if _target_id == "water":
		_mode = "water_lift"
		_water_motion_from = avatar.position
		_water_motion_t = 0.0
		# Actual fountain contact is stored in the existing room station data.
		var fountain_contact: Vector2 = _zone("water")["mouth_point"]
		var body_center: Vector2 = bubble.to_global(Vector2.ZERO)
		var rise: float = clampf(body_center.y - fountain_contact.y, 14.0, 34.0)
		_water_station_point = Vector2(lerpf(_world_position.x, fountain_contact.x, 0.55), _world_position.y - rise)
		if bubble.current_action != "idle":
			bubble.play_action("idle")
		bubble.set_room_heading(PI)
		_status.text = "Баббл плавно приближается к поилке"
		_hint.text = "Вода поступает из работающего фонтана"
		return

	if _target_id == "shower" or _target_id == "bed":
		# Approach stays on the walkable floor; then visibly lift OVER the lip.
		_mode = "platform_enter"
		_v8_inside = true
		_v8_flight_kind = _target_id
		if _target_id == "bed":
			avatar.z_index = BED_FRONT_Z
			bubble.set_room_sleep_pose(false)
		# Sample the live actor pose at the actual moment flight starts.
		_v8_flight_start = avatar.position
		if _target_id in ["shower", "bed"]:
			_v8_entry_heading = _facing
		_v8_flight_end = _zone(_target_id)["activity_point"]
		_v8_flight_t = 0.0
		if _target_id in ["shower", "bed"]:
			# Keep springs, FaceRig and procedural body evolving continuously.
			bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
		else:
			bubble.play_action("float")
		_status.text = "Баббл подлетает к платформе"
		_hint.text = "Взлёт → над бортиком → плавное приземление"
		return
	_begin_care_action()

func _v8_smooth(u: float) -> float:
	var t: float = clampf(u, 0.0, 1.0)
	return t*t*(3.0-2.0*t)

func _v8_flight_path(start: Vector2, finish: Vector2, ratio: float, station_kind: String) -> Vector2:
	# Shower: a single cubic Bezier with one global easing curve, not
	# three independently restarted movement clips. Both endpoints
	# are sampled at runtime (nearby access and distant button).
	# A single monotone cubic curve, starting at the live Bubble position.
	# No segmented takeoff/stop/restart and no upward overshoot at the rim.
	if station_kind == "bed":
		var t: float = _v8_smooth(ratio)
		var q: float = 1.0 - t
		var c1: Vector2 = Vector2(lerpf(start.x, finish.x, 0.30) - 17.0,
			lerpf(start.y, finish.y, 0.30) - 8.0)
		var c2: Vector2 = Vector2(lerpf(start.x, finish.x, 0.76) - 6.0,
			lerpf(start.y, finish.y, 0.79) - 4.0)
		return start * (q*q*q) + c1 * (3.0*q*q*t) + c2 * (3.0*q*t*t) + finish * (t*t*t)
	if station_kind == "shower":
		var t: float = _v8_smooth(ratio)
		var inv: float = 1.0 - t
		var upper_y: float = minf(start.y, finish.y) - 70.0
		var c1: Vector2 = Vector2(lerpf(start.x, finish.x, 0.26), lerpf(start.y, upper_y, 0.91))
		var c2: Vector2 = Vector2(lerpf(start.x, finish.x, 0.78), lerpf(finish.y, upper_y, 0.84))
		return start * (inv * inv * inv) + c1 * (3.0 * inv * inv * t) + c2 * (3.0 * inv * t * t) + finish * (t * t * t)
	# Other stations: keep their existing entry/exit choreography.
	# Three distinct segments; do NOT move through a vertical front wall.
	# The sprite foreground contains just the physical lip, not a whole prop.
	var side: float = -48.0 if station_kind == "shower" else 52.0
	var top_y: float = minf(start.y,finish.y)-82.0
	var takeoff: Vector2 = Vector2(start.x+side*0.48,top_y+18.0)
	var cruise: Vector2 = Vector2(finish.x+side*0.22,top_y)
	if ratio < 0.38:
		return start.lerp(takeoff,_v8_smooth(ratio/0.38))
	if ratio < 0.65:
		return takeoff.lerp(cruise,_v8_smooth((ratio-0.38)/0.27))
	return cruise.lerp(finish,_v8_smooth((ratio-0.65)/0.35))

func _v8_adapt_shower_heading(fraction: float, entering: bool) -> void:
	# Keep the very same liquid body and FaceRig through a natural turn.
	var t: float = _v8_smooth(clampf((fraction - 0.38) / 0.62, 0.0, 1.0)) if entering else _v8_smooth(clampf(fraction / 0.50, 0.0, 1.0))
	var from_heading: float = _v8_entry_heading if entering else _v8_exit_heading
	var toward: float = 0.0 if entering else PI
	var heading: float = lerp_angle(from_heading, toward, t)
	var steer: float = wrapf(heading - _facing, -PI, PI)
	_facing = heading
	_last_heading = heading
	bubble.set_room_heading(heading)
	bubble.set_room_turn_activity(sin(PI * t) if t > 0.0 and t < 1.0 else 0.0)
	bubble.set_room_locomotion("idle", 0.0, 0.0, steer)

func _v8_bed_heading(fraction: float, entering: bool) -> void:
	# A turn is part of the same living body's continuous spring motion.
	# Entry turns inside the bed; exit gradually turns towards the floor.
	var t: float = _v8_smooth(clampf(
		(fraction - 0.50) / 0.50 if entering else (fraction - 0.12) / 0.56,
		0.0, 1.0))
	var initial: float = _v8_entry_heading if entering else _v8_exit_heading
	var target: float = 0.0 if entering else PI
	var heading: float = lerp_angle(initial, target, t)
	var steer: float = wrapf(heading - _facing, -PI, PI)
	_facing = heading
	_last_heading = heading
	bubble.set_room_heading(heading)
	bubble.set_room_turn_activity(0.42 * sin(PI * t))
	bubble.set_room_locomotion("idle", 0.0, 0.0, steer)

func _bed_set_solid(enabled: bool) -> void:
	# Never pop the shader opacity during the approach->sleep transition.
	# This sets a goal, updated continuously by _process() on the SAME actor.
	_bed_opaque_target = 1.0 if enabled else 0.0

func _bed_update_opacity(delta: float) -> void:
	var old_mix: float = _bed_opaque_mix
	_bed_opaque_mix = move_toward(_bed_opaque_mix, _bed_opaque_target, delta * 2.8)
	# Touch the material only while the bed blend is active. This preserves
	# existing feeding/water shader behavior outside a bed transition.
	if _bed_opaque_mix <= 0.0 and _bed_opaque_target <= 0.0 and old_mix <= 0.0:
		return
	if not is_instance_valid(bubble._actor):
		return
	var surface: CanvasItem = bubble._actor.get_node_or_null("Body/Surface") as CanvasItem
	if surface != null and surface.material is ShaderMaterial:
		(surface.material as ShaderMaterial).set_shader_parameter("meal_opaque", _bed_opaque_mix)

func _begin_care_action() -> void:
	_mode = "care"
	_tool_mode = ""
	_tool_dragging = false
	_action_left = BED_SLEEP_SECONDS if _target_id == "bed" else (-1.0 if _target_id == "food" else float(_zone(_target_id)["seconds"]))
	_v8_care_clock = 0.0
	_v8_eating = false
	_status.text = "Баббл: " + str(_zone(_target_id)["button"])
	room_v8.call("set_action_fx", _target_id, true)
	# Do not force a new face pose at the dental transition.
	if _target_id != "mirror":
		bubble.clear_expression_override()
	if _target_id == "food" or _target_id == "water":
		_facing = PI
		_last_heading = PI
		bubble.set_room_heading(PI)
	# Food starts only after the feeder is FILLED, not during dispensing.
	if _target_id == "shower":
		# No replacement or idle-timer restart after crossing the rim.
		bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
		bubble.set_room_turn_activity(0.0)
	elif _target_id == "mirror":
		# Preserve the renderer, spring state, current face and jaw.
		bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
		bubble.set_room_turn_activity(0.0)
	elif _target_id == "bed":
		# Keep one living movement renderer, no play_action("sleep").
		bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
		bubble.set_room_turn_activity(0.0)
	elif _target_id == "water":
		if bubble.current_action != "idle":
			bubble.play_action("idle")
	else:
		bubble.play_action("idle" if _target_id == "food" else str(_zone(_target_id)["action"]))
	_use_button.text = "ЗАВЕРШИТЬ"
	match _target_id:
		"shower":
			shower_fx.set_shower_on(true)
			scrub_mask.start_scrubbing()
			_tool_mode = "shower"
			_show_tool("res://education/playtown/assets/pet_home/wash/brush.png",0.37)
			_progress.value = 0
			_progress.visible = true
			_hint.text = "Води губкой по пене на Баббле, заполняя шкалу мытья"
		"mirror":
			# This is a care interaction, not a selected-world hotspot.
			zone_visual.visible = false
			# One Bubble, one existing FaceRig. The old overlay nodes are never created.
			_tool_mode = "teeth_rig"
			_focus_dim.visible = false
			_focus_face.visible = false
			# Keep expression from previous frame; mouth override handles jaw.
			# Keep the heading achieved by the continuous approach.
			var rig: MikaBubbleFace = bubble.get_face()
			if is_instance_valid(rig):
				rig.reset_plaque()
			# Jaw is already open from _advance_dental_turn: no restart.
			_camera_to = _mirror_focus_point()
			_zoom_to = _base_zoom * 5.2
			_show_tool("res://education/playtown/assets/pet_home/teeth/toothbrush.png",0.31)
			_progress.value = 0.0
			_progress.visible = true
			_hint.text = "Чистим настоящие зубы Баббла — без зубных накладок"
		"food":
			# Old monolithic FeederFX is hidden; the v8 feeder owns the ONLY bowl.
			_hint.text = "Корм в миске → Баббл ест спиной → миска пустеет"
		"water":
			# The fountain in room_v8 always runs, even outside care mode.
			_hint.text = "Баббл пьёт спиной · фонтан работает постоянно"
		"bed":
			avatar.z_index = BED_FRONT_Z
			_bed_set_solid(true)
			bubble.set_room_sleep_pose(true)
			_status.text = "Баббл спит — 5 секунд"
			_hint.text = "Спокойный сон · через 5 секунд Баббл проснётся и выйдет"
	# Only manually scrubbed bath and dental actions are stoppable.
	var manual: bool = _target_id in ["shower", "mirror"] and _tool_mode in ["shower", "teeth"]
	_set_manual_care_stop(manual)
	_care_play_sound("connect_point.ogg")
	_highlight_buttons()

func _v8_update_station_care(delta: float) -> void:
	_v8_care_clock += delta
	if _target_id == "food":
		var phase: String = str(room_v8.call("feeding_phase"))
		avatar.position = _feed_station_point
		_feed_update_absorption(phase)
		bubble.set_room_heading(PI)
		if phase == "filling":
			_hint.text = "Кормушка наполняет существующую миску · Баббл ждёт"
		elif phase == "eating":
			if not _v8_eating:
				_v8_eating = true
				# Never use the generic eat effect; it has its own bowl.
				bubble.play_action("idle")
				_feed_set_solid(true)
				_hint.text = "Баббл ест из штатной миски · корм постепенно исчезает"
			var chew: float = 0.5 + 0.5 * sin(_v8_care_clock * 9.4)
			avatar.position = _feed_station_point + Vector2(0.0, -2.5 * chew)
		elif phase == "clearing":
			_hint.text = "Баббл заканчивает · миска опустошается"
		elif phase == "empty" and _v8_eating:
			_feed_begin_lower()
	elif _target_id == "water":
		avatar.position = _world_position + Vector2(0.0, -3.5 - 3.0 * (0.5 + 0.5 * sin(_v8_care_clock * 7.8)))

func _feed_update_absorption(phase: String) -> void:
	# Feeder's existing FX owns the real bowl, pellet generation and _fill.
	# We only visualize the pellets disappearing from THAT bowl during eating.
	var existing_fx: Variant = room_v8.get("effect_nodes")
	if not (existing_fx is Dictionary):
		return
	var feeder_node: Node2D = existing_fx.get("feeder") as Node2D
	if not is_instance_valid(feeder_node):
		return
	if not is_instance_valid(_feed_absorption_fx):
		_feed_absorption_fx = FEED_ABSORPTION_SCRIPT.new() as Node2D
		_feed_absorption_fx.name = "FeedAbsorptionVisualOnly"
		_feed_absorption_fx.z_index = 8 # Bubble=7, feeding rim=6
		stage.add_child(_feed_absorption_fx)
	# Coordinates are taken from the ORIGINAL feeder sprite / FX transform:
	# the purple bowl is centered on local x=215, y~302.
	var bowl: Vector2 = _feed_absorption_fx.to_local(feeder_node.to_global(Vector2(215.0, 302.0)))
	var interior: Vector2 = _feed_absorption_fx.to_local(bubble.to_global(Vector2.ZERO))
	var actual_fill: float = float(feeder_node.get("_fill"))
	_feed_absorption_fx.call("sample", phase == "eating", actual_fill, bowl, interior, avatar.scale.x)

func _advance_water_gas(delta: float) -> void:
	if _mode == "food_lower":
		_feed_motion_t = minf(_feed_motion_t + delta / FEED_LOWER_SECONDS, 1.0)
		avatar.position = _feed_motion_from.lerp(_world_position, _v8_smooth(_feed_motion_t))
		if _feed_motion_t >= 1.0:
			avatar.position = _world_position
			_feed_set_solid(false)
			_start_post_feed_gas()
	elif _mode == "food_gas":
		# The single living Bubble remains the SAME actor from feeding.
		_post_feed_gas_t = minf(_post_feed_gas_t + delta, POST_FEED_GAS_DURATION)
		avatar.position = _world_position
		bubble.set_room_heading(PI)
		if is_instance_valid(_post_feed_cloud):
			_post_feed_cloud.call("update_phase", true, clampf(_post_feed_gas_t / 3.35, 0.0, 1.14), 1.0)
		if _post_feed_gas_t >= POST_FEED_GAS_DURATION:
			_clear_post_feed_gas()
			_mode = "food_turn"
			_post_feed_turn_t = 0.0
	elif _mode == "food_turn":
		# Smooth back -> front turn on the SAME mesh and face rig.
		_post_feed_turn_t = minf(_post_feed_turn_t + delta / POST_FEED_TURN_DURATION, 1.0)
		avatar.position = _world_position
		_facing = PI + PI * _v8_smooth(_post_feed_turn_t)
		_last_heading = _facing
		bubble.set_room_heading(_facing)
		bubble.set_room_turn_activity(sin(PI * _post_feed_turn_t))
		if _post_feed_turn_t >= 1.0:
			bubble.set_room_turn_activity(0.0)
			_facing = 0.0
			_last_heading = 0.0
			bubble.set_room_heading(0.0)
			_finish_care()
			if _v8_action_queued != "":
				var after_gas: String = _v8_action_queued
				_v8_action_queued = ""
				call_deferred("_request_action", after_gas)
	elif _mode == "water_lift":
		_water_motion_t = minf(_water_motion_t + delta / WATER_LIFT_SECONDS, 1.0)
		avatar.position = _water_motion_from.lerp(_water_station_point, _v8_smooth(_water_motion_t))
		if _water_motion_t >= 1.0:
			avatar.position = _water_station_point
			_begin_care_action()
	elif _mode == "water_lower":
		_water_motion_t = minf(_water_motion_t + delta / WATER_LOWER_SECONDS, 1.0)
		avatar.position = _water_motion_from.lerp(_world_position, _v8_smooth(_water_motion_t))
		if _water_motion_t >= 1.0:
			avatar.position = _world_position
			_finish_care()
			if _v8_action_queued != "":
				var after_water: String = _v8_action_queued
				_v8_action_queued = ""
				call_deferred("_request_action", after_water)
	elif _target_id == "water" and _mode == "care":
		_v8_update_station_care(delta)
		var breathe: float = 1.7 * (0.5 + 0.5 * sin(_v8_care_clock * 6.7))
		avatar.position = _water_station_point + Vector2(0.0, -breathe)
		bubble.set_room_heading(PI)
		_water_update_absorption(delta)
		if _action_left >= 0.0:
			_action_left -= delta
			if _action_left <= 0.0:
				_water_begin_lower()

func _water_update_absorption(delta: float) -> void:
	# The v8 fountain owns its single, permanently running water stream.
	var fx_nodes: Variant = room_v8.get("effect_nodes")
	if not (fx_nodes is Dictionary):
		return
	var fountain_node: Node2D = fx_nodes.get("drinker") as Node2D
	if not is_instance_valid(fountain_node):
		return
	if not is_instance_valid(_water_absorption_fx):
		_water_absorption_fx = WATER_ABSORPTION_SCRIPT.new() as Node2D
		_water_absorption_fx.name = "FountainWaterAbsorptionOnly"
		_water_absorption_fx.z_index = 8
		stage.add_child(_water_absorption_fx)
	# Sample existing fountain particle location, never draw a second stream.
	var from_fountain: Vector2 = _water_absorption_fx.to_local(fountain_node.to_global(Vector2(180.0, 206.0)))
	var inside_bubble: Vector2 = _water_absorption_fx.to_local(bubble.to_global(Vector2(0.0, 6.0)))
	_water_absorption_fx.call("sample", true, delta, from_fountain, inside_bubble, avatar.scale.x)

func _water_begin_lower() -> void:
	if _target_id != "water" or _mode == "water_lower":
		return
	_mode = "water_lower"
	_water_motion_from = avatar.position
	_water_motion_t = 0.0
	if is_instance_valid(_water_absorption_fx):
		_water_absorption_fx.call("stop_emitting")
	if bubble.current_action != "idle":
		bubble.play_action("idle")
	_hint.text = "Баббл плавно опускается после питья · фонтан работает"

func _start_post_feed_gas() -> void:
	if _target_id != "food":
		return
	_mode = "food_gas"
	_post_feed_gas_t = 0.0
	_facing = PI
	_last_heading = PI
	# Never call bubble.play_action("gas") here. That creates a second BODY.
	# Attach only the original gas_cloud.gd renderer to the CURRENT actor.
	_clear_post_feed_gas()
	var living_visual: Node2D = bubble._actor as Node2D
	if is_instance_valid(living_visual):
		_post_feed_cloud = ROOM_GAS_ONLY_SCRIPT.new() as Node2D
		_post_feed_cloud.name = "AfterFeedingGasOnly"
		_post_feed_cloud.position = Vector2(64.0, -64.0)
		_post_feed_cloud.rotation = PI * 0.5
		_post_feed_cloud.z_index = 1
		living_visual.add_child(_post_feed_cloud)
		_post_feed_cloud.call("update_phase", true, 0.0, 1.14)
	bubble.set_room_heading(PI)
	_status.text = "Баббл закончил есть"
	_hint.text = "Выпускает газ, оставаясь спиной, затем поворачивается"

func _clear_post_feed_gas() -> void:
	if is_instance_valid(_post_feed_cloud):
		_post_feed_cloud.call("update_phase", false, 1.0, 1.0)
		_post_feed_cloud.queue_free()
	_post_feed_cloud = null

func _feed_set_solid(enabled: bool) -> void:
	if not is_instance_valid(bubble._actor):
		return
	var surface: CanvasItem = bubble._actor.get_node_or_null("Body/Surface") as CanvasItem
	if surface == null:
		return
	if surface.material is ShaderMaterial:
		(surface.material as ShaderMaterial).set_shader_parameter("meal_opaque", 0.0)

func _feed_begin_lower() -> void:
	if _target_id != "food" or _mode == "food_lower":
		return
	_mode = "food_lower"
	_feed_motion_from = avatar.position
	_feed_motion_t = 0.0
	room_v8.call("set_action_fx", "food", false)
	bubble.play_action("idle")
	_feed_set_solid(true)
	_hint.text = "Баббл плавно опускается после кормления"

func _show_tool(path: String, scale_value: float) -> void:
	_tool.texture = load(path)
	_tool.scale = Vector2.ONE * scale_value
	_tool.visible = true
	_reset_tool_position()
	if _tool_mode == "teeth_rig" and path.get_file() == "toothbrush.png":
		# The real PlayTown mini-game owns its own texture, touch and eraser.
		# Hide the former MIKA sprite and all former dental contacts.
		_tool.visible = false
		if not is_instance_valid(_mika_playtown_teeth):
			_mika_playtown_teeth = PLAYTOWN_TEETH_ADAPTER.new()
			_mika_playtown_teeth.name = "BubblePlayTownTeeth"
			_hud.add_child(_mika_playtown_teeth)
			_mika_playtown_teeth.progress_changed.connect(_update_progress)
			_mika_playtown_teeth.completed.connect(_on_care_completed)
		_mika_playtown_teeth_begin()

func _update_progress(value: float) -> void:
	if _mode != "care" or _focus_finished: return
	_progress.value = value*100.0
	if _target_id == "mirror" and value>=0.92:
		_on_care_completed()

func _on_care_completed() -> void:
	if is_instance_valid(_mika_playtown_teeth):
		_mika_playtown_teeth.stop(true)
	if _mode != "care" or _focus_finished: return
	_focus_finished = true
	_set_manual_care_stop(false)
	_care_play_sound("correct.ogg", 1.06)
	_tool.visible = false
	_tool_dragging = false
	_progress.value = 100.0
	_status.text = "Отлично! Баббл доволен"
	_hint.text = "Уход завершён. Камера вернётся к общему виду"
	_action_left = 1.3
	if _target_id == "shower":
		scrub_mask.stop_scrubbing()
		shower_fx.set_shower_on(false)
	elif _target_id == "mirror":
		# Camera pulls away first; then the SAME mouth closes rapidly
		# after a short delay, still within the camera movement.
		_dental_camera_retreat = true
		_dental_close_elapsed = 0.0
		_camera_to = Vector2(836.0, 440.0)
		_zoom_to = _base_zoom
		bubble.set_room_emotion("happy", 1.8)

func _stop_care(reset_camera: bool = true) -> void:
	if is_instance_valid(_mika_playtown_teeth):
		_mika_playtown_teeth.stop()
	_set_manual_care_stop(false)

	_clear_post_feed_gas()
	if is_instance_valid(_feed_absorption_fx):
		_feed_absorption_fx.call("stop_immediately")
	if is_instance_valid(_water_absorption_fx):
		_water_absorption_fx.call("stop_immediately")
	if _target_id == "water" and _mode in ["water_lift", "care"]:
		_water_begin_lower()
		return
	if _target_id == "food" and _mode in ["food_lift", "care"]:
		_feed_begin_lower()
		return

	if _v8_enter_tween != null and _v8_enter_tween.is_running():
		_v8_enter_tween.kill()
	var retreat: bool = _v8_inside and avatar.position.distance_to(_world_position) > 4.0
	if retreat:
		_v8_leave_from = avatar.position
		_v8_leave_t = 0.0
		_v8_exit_heading = _facing
	_v8_inside = false
	if retreat:
		_v8_flight_kind = _target_id
		if _target_id in ["shower", "bed"]:
			# Do not restart the animation at the exit point either.
			bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
		else:
			bubble.play_action("float")
	if _target_id == "mirror" and not _dental_camera_retreat:
		_dental_camera_retreat = true
		_dental_close_elapsed = 0.0
	if _target_id == "bed":
		bubble.set_room_sleep_pose(false)
		if not retreat:
			avatar.z_index = BED_NORMAL_Z
			_bed_set_solid(false)
	room_v8.call("stop_all_fx")
	# The target is hidden only while brushing teeth.
	zone_visual.visible = true
	_manual_turn_duration = 0.0
	_idle_look_seconds = 0.0
	bubble.set_room_turn_activity(0.0)
	_turn_180_button.disabled = false
	_turn_360_button.disabled = false
	shower_fx.set_shower_on(false)
	scrub_mask.stop_scrubbing()
	feeder_fx.clear_bowl()
	_tool_mode = ""
	_tool.visible = false
	_tool_dragging = false
	_focus_face.visible = false
	# Preserve live mouth until retreat timing closes it, including
	# manual exit; other care modes retain their original reset.
	if not _dental_camera_retreat or _dental_close_elapsed < 0.0:
		bubble.set_mouth_open(-1.0)
	_focus_dim.visible = false
	_progress.visible = false
	_progress.value = 0.0
	_focus_finished = false
	_action_left = -1.0
	_route.clear()
	_velocity = Vector2.ZERO
	_turn_left = 0.0
	_target_id = ""
	_context_use_action.call("set_action_available", false)
	_mode = "returning" if retreat else "free"
	_joystick.visible = not retreat
	_joystick.clear_input()
	if not retreat:
		avatar.position = _world_position
		if _target_id not in ["mirror", "bed"]:
			bubble.play_action("idle")
		else:
			bubble.set_room_locomotion("idle", 0.0, 0.0, 0.0)
	_movement_action = ""
	if reset_camera:
		_camera_to = Vector2(836.0, 440.0)
		_zoom_to = _base_zoom
	_use_button.visible = false
	_status.text = "Выбери действие справа или двигай Баббла джойстиком"
	_hint.text = "WASD / стрелки · E — рядом с объектом · Esc — назад"
	_nearest = ""
	_update_nearest()
	_highlight_buttons()

func _finish_care() -> void:
	_stop_care(true)

func _highlight_buttons() -> void:
	for z in ZONES:
		var id: String = str(z["id"])
		var b: Button = _action_buttons[id]
		b.modulate = Color(0.71,1.0,0.96) if id == _target_id else Color.WHITE

func _update_nearest() -> void:
	if _mode != "free": return
	var id := ""
	var distance := INF
	for z in ZONES:
		var d: float = _world_position.distance_to(z["point"])
		if d < float(z["radius"]) and d < distance:
			distance = d
			id = str(z["id"])
	if _nearest == id:
		_context_use_action.call("set_action_available", id != "")
		return
	_nearest = id
	zone_visual.set("nearby_id",id)
	zone_visual.queue_redraw()
	_use_button.visible = id != ""
	_use_button.text = "ИСПОЛЬЗОВАТЬ"
	_context_use_action.call("set_action_available", id != "")

func _use_or_cancel() -> void:
	if _mode == "free":
		if _nearest != "": _request_action(_nearest)
	else:
		_stop_care(true)

func _toggle_debug() -> void:
	_debug = not _debug
	walk_area.set_debug(_debug)
	room_v8.call("set_debug_zones", _debug)
	zone_visual.set("debug_visible",_debug)
	zone_visual.queue_redraw()
	_debug_button.text = "F3 · Границы: вкл" if _debug else "F3 · Границы: выкл"

func _capture_bubble_screenshot() -> void:
	var folder: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if folder.is_empty():
		folder = OS.get_user_data_dir()
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
	var path: String = folder.path_join("BubbleRoom_" + stamp + ".png")
	var image: Image = get_viewport().get_texture().get_image()
	var result: Error = image.save_png(path)
	if result == OK:
		_status.text = "Скриншот сохранён: " + path
	else:
		_status.text = "Не удалось сохранить скриншот: " + str(result)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE and _mode != "free":
		_stop_care(true)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_Q and _mode == "free":
		_start_manual_turn(PI)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_R and _mode == "free":
		_start_manual_turn(TAU)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_T and _mode == "free":
		_next_room_emotion()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F3:
		_toggle_debug()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F12:
		_capture_bubble_screenshot()
		get_viewport().set_input_as_handled()
	elif (event.keycode == KEY_E or event.keycode == KEY_ENTER) and _mode == "free":
		_use_or_cancel()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if _tool_mode == "teeth_rig":
		return # PlayTown owns dental touch, drag and erasing.
	if _mode != "care" or _tool_mode == "" or _focus_finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_begin_drag(event.position)
		else:
			_tool_dragging = false
	elif event is InputEventMouseMotion and _tool_dragging:
		_move_tool(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_try_begin_drag(event.position)
		else:
			_tool_dragging = false
	elif event is InputEventScreenDrag and _tool_dragging:
		_move_tool(event.position)

func _try_begin_drag(screen_position: Vector2) -> void:
	if not _tool.visible: return
	if _tool.texture == null: return
	# The PlayTown tools are long: grab anywhere inside the actual sprite.
	var local_point: Vector2 = _tool.get_global_transform_with_canvas().affine_inverse() * screen_position
	var half_size: Vector2 = _tool.texture.get_size() * 0.5
	if absf(local_point.x) > half_size.x or absf(local_point.y) > half_size.y: return
	_tool_dragging = true
	_drag_offset = screen_position - _tool.position
	_last_tip = _tool_tip()
	get_viewport().set_input_as_handled()

func _tool_tip() -> Vector2:
	if _tool.texture == null:
		return _tool.position
	var tex_size: Vector2 = _tool.texture.get_size()
	if _tool_mode == "shower":
		return _tool.position + Vector2(-tex_size.x * 0.28, tex_size.y * 0.18) * _tool.scale.x
	return _tool.position

func _move_tool(screen_position: Vector2) -> void:
	# Dental movement is handled by the ORIGINAL PlayTown pet minigame.
	# Retain the original MIKA shower scrub implementation unchanged.
	if _tool_mode == "teeth_rig":
		return
	var sz := get_viewport_rect().size
	var next := screen_position - _drag_offset
	_tool.position = next.clamp(Vector2(25,125), sz-Vector2(35,35))
	var tip := _tool_tip()
	var travel := tip.distance_to(_last_tip)
	if travel > 1.5:
		var steps := mini(30,maxi(1,int(ceil(travel/6.0))))
		for i in range(1,steps+1):
			var point := _last_tip.lerp(tip,float(i)/float(steps))
			if _tool_mode == "shower":
				var local_pt: Vector2 = avatar.get_global_transform_with_canvas().affine_inverse()*point
				scrub_mask.scrub_at(local_pt,travel/float(steps)*3.0)
			if _focus_finished: break
	_last_tip = tip
	get_viewport().set_input_as_handled()

# Start the exact PlayTown pet dental minigame on Bubble's close-up face.

func _mika_playtown_teeth_begin() -> void:
	if not is_instance_valid(_mika_playtown_teeth):
		push_error("[MIKA DENTAL v8.5.9.9] PlayTown adapter not created")
		return
	var live_face: MikaBubbleFace = bubble.get_face()
	if not is_instance_valid(live_face):
		push_error("[MIKA DENTAL v8.5.9.9] Bubble live FaceRig missing")
		return
	print("[MIKA DENTAL v8.5.9.9] CONNECTED teeth_rig -> PlayTown -> live Bubble FaceRig")
	_mika_playtown_teeth.begin_with_bubble(live_face)
