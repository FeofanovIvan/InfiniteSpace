@tool
extends Control
# MIKA_BUBBLE_BALL_PLANET_V8_5_1
# MIKA_BUBBLE_BALL_CARD_CONNECT_V8_5_1_1
# v69: Atlas top info, transparent lower HUD backdrop.
const TopInfoPanel = preload("res://planet_hub/scripts/top_info_panel.gd")
## Planet landing hub overlay. Reuses the same lower HUD for every planet,
## while allowing different backgrounds and card visibility/content per target.

signal simulator_requested
signal flight_requested
signal representative_requested(planet_id: String)
signal story_earth_puzzle_solved
signal story_mars_word_solved
signal story_station_list_solved
signal story_talos_maze_solved
signal story_molly_tree_solved
signal story_lmc_station_sunbeam_solved
signal story_okea_solutions_solved
signal story_cela_crystals_solved
signal story_lotus_water_solved
signal story_barnard_pizza_solved
signal story_archeon_fossils_solved
signal story_runa_evolution_solved
signal story_m31_pinball_solved
signal story_m31_ball_solved
signal story_m31_pulses_solved
# MIKA_CH06_NATIVE_ROUTE_V1
signal story_ch06_math_solved
var _story_ch06_stage: String = ""
var _story_ch06_allow_return: bool = false
const CH06_MATH_ID: String = "m33__neural_math"

const ATLAS_PATH: String = "res://atlas/world_atlas.json"
const BACKGROUND_ROOT: String = "res://planet_hub/backgrounds/"
const CARD_ROOT: String = "res://planet_hub/cards/"
const CHARACTER_ROOT: String = "res://planet_hub/characters/"
const ROSTER_PATH: String = "res://planet_hub/data/representatives.json"
const MISSION_PATH: String = "res://planet_hub/data/missions.json"
const V104_GAME_DB_PATH: String = "res://planet_hub/data/planet_game_cards_v104.json"
const V107_CARD_BIOS_PATH: String = "res://planet_hub/data/representative_card_bios_v107.json"
const V104_GAME_CARD_SCRIPT: Script = preload("res://planet_hub/scripts/planet_card.gd")
const STORY_MARS_WORD_ID: String = "story__mars_trace_words"
const STORY_MARS_WORD_SCENE: String = "res://story/mars_word_trace/MarsWordTrace.tscn"
const STORY_MARS_WORD_ICON: String = "res://simulator_ui/assets/approved_icons/sim_02_write_words.png"
const STORY_TALOS_MAZE_ID: String = "lmc__fungal_paths"
const STORY_MOLLY_TREE_ID: String = "lmc__fungal_race"
const STORY_LMC_SUNBEAM_ID: String = "lmc__sunbeam_catcher"
const STORY_OKEA_SOLUTION_ID: String = "smc__solutions_lab"
const STORY_CELA_CRYSTAL_ID: String = "smc__resource_rush"
const STORY_CELA_CRYSTAL_TARGET: int = 5
const STORY_LOTUS_MOLECULE_ID: String = "smc__build_molecule"
const STORY_BARNARD_PIZZA_ID: String = "ngc6822__pizza_fraction"
const STORY_ARCHEON_FOSSIL_ID: String = "ngc6822__fossil_search"
const STORY_RUNA_EVOLUTION_ID: String = "ngc6822__evolution_order"
const STORY_RUNA_EVOLUTION_TARGET: int = 5
const STORY_M31_PINBALL_ID: String = "m31__gravity_pinball"
const STORY_M31_PINBALL_TARGET: int = 1
const STORY_M31_BALL_ID: String = "m31__roll_ball"
const STORY_M31_PULSES_ID: String = "m31__electric_pulses"
const StorySubscriptionGate: Script = preload("res://scripts/StorySubscriptionGate.gd")
const StoryProgress: Script = preload("res://scripts/StoryProgress.gd")
const V108_CARD_ARROW_SCRIPT: Script = preload("res://planet_hub/scripts/mika_card_entry_arrow.gd")
# InfiniteSpace v104: six-language planetary game preview cards

@onready var scroll: ScrollContainer = $CardScroll
@onready var card_row: HBoxContainer = $CardScroll/CardRow
@onready var representative: Control = $CardScroll/CardRow/RepresentativeCard
@onready var mission: Control = $CardScroll/CardRow/MissionCard
@onready var hud: Control = $BottomHUD

var _atlas: Dictionary = {}
var _representative_roster: Dictionary = {}
var _mission_records: Dictionary = {}
var _v104_game_database: Dictionary = {}
var _v107_card_bios: Dictionary = {}
var _v104_game_cards: Array[Control] = []
# v105.1: launch ONLY already-approved scenes from existing v104 cards.
# The v104 planet assignment table and the card creation/layout are preserved.
var _v1051_game_layer: Control
var _v1051_viewport: SubViewport
var _v1051_playing: bool = false
var _station_race_active: bool = false
var _bubble_ball_layer: Control
var _bubble_ball_card: Control
var _bubble_ball_active: bool = false
var _bubble_ball_transition: bool = false
var _bubble_ball_tween: Tween
var _mouse_scroll_drag: bool = false
var _planet_id: String = ""
var _planet_name: String = ""
var _meta: Dictionary = {}
var _background_texture: Texture2D
var _background_path: String = ""
var _is_setup: bool = false
var _story_earth_stage: String = ""
var _story_mars_stage: String = ""
var _story_station_stage: String = ""
var _story_station_finish_pending: bool = false
var _story_station_allow_return: bool = false
var _story_talos_stage: String = ""
var _story_talos_finish_pending: bool = false
var _story_talos_allow_return: bool = false
var _story_molly_stage: String = ""
var _story_molly_finish_pending: bool = false
var _story_molly_allow_return: bool = false
var _story_lmc_station_stage: String = ""
var _story_lmc_station_finish_pending: bool = false
var _story_lmc_station_allow_return: bool = false
var _story_okea_stage: String = ""
var _story_okea_finish_pending: bool = false
var _story_okea_allow_return: bool = false
var _story_cela_stage: String = ""
var _story_cela_finish_pending: bool = false
var _story_cela_allow_return: bool = false
var _story_lotus_stage: String = ""
var _story_lotus_finish_pending: bool = false
var _story_lotus_allow_return: bool = false
var _story_barnard_stage: String = ""
var _story_barnard_finish_pending: bool = false
var _story_barnard_allow_return: bool = false
var _story_archeon_stage: String = ""
var _story_archeon_finish_pending: bool = false
var _story_archeon_allow_return: bool = false
var _story_runa_stage: String = ""
var _story_runa_finish_pending: bool = false
var _story_runa_allow_return: bool = false
var _story_m31_stage: String = ""
var _story_m31_finish_pending: bool = false
var _story_m31_allow_return: bool = false
var _story_launch_pulse: Tween

var _top_info: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_load_atlas()
	_load_representative_roster()
	_load_missions()
	_v104_load_game_database()
	_v107_load_card_bios()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_is_setup = true
	if hud != null:
		hud.connect("simulator_pressed", Callable(self, "_on_simulator_pressed"))
		hud.connect("flight_pressed", Callable(self, "_on_flight_pressed"))
	_setup_representative_card_button()
	resized.connect(_layout_ui)
	MobileLocale.language_changed.connect(_bubble_ball_refresh_card)
	_top_info = TopInfoPanel.new()
	_top_info.name = "AtlasTopInformationPanel"
	_top_info.z_index = 25
	add_child(_top_info)
	_layout_ui()
	queue_redraw()

func _setup_representative_card_button() -> void:
	# Invisible input surface; the original card artwork remains unchanged.
	var open_button: Button = Button.new()
	open_button.name = "OpenRepresentativeDialog"
	open_button.flat = true
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	open_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		open_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	representative.add_child(open_button)
	open_button.pressed.connect(_on_representative_card_pressed)


func _on_representative_card_pressed() -> void:
	if not _story_ch06_stage.is_empty():
		return
	if not _story_earth_stage.is_empty() or not _story_mars_stage.is_empty() or not _story_station_stage.is_empty() or not _story_talos_stage.is_empty() or not _story_molly_stage.is_empty() or not _story_lmc_station_stage.is_empty() or not _story_okea_stage.is_empty() or not _story_cela_stage.is_empty() or not _story_lotus_stage.is_empty() or not _story_barnard_stage.is_empty() or not _story_m31_stage.is_empty():
		return
	if bool(_meta.get("inhabited", false)) and not _planet_id.is_empty():
		representative_requested.emit(_planet_id)


func get_dialog_background_path() -> String:
	return _background_path


func get_dialog_portrait_path() -> String:
	var entry: Dictionary = _representative_entry()
	var asset_name: String = String(entry.get("asset", ""))
	if not asset_name.is_empty():
		var candidate: String = CHARACTER_ROOT + asset_name
		if ResourceLoader.exists(candidate):
			return candidate
	return _resolve_first_existing([
		CARD_ROOT + _planet_id + "_representative_dialog.png",
		CARD_ROOT + _planet_id + "_representative_dialog.webp",
		CARD_ROOT + _planet_id + "_representative.png",
	])


func show_for_planet(planet_id: String, display_name: String = "", crystals: int = 0) -> void:
	_bubble_ball_force_clear()

	_planet_id = planet_id
	_story_ch06_stage = ""
	_story_ch06_allow_return = false
	_story_station_stage = ""
	_story_station_finish_pending = false
	_story_station_allow_return = false
	_story_talos_finish_pending = false
	_story_talos_allow_return = false
	_story_molly_finish_pending = false
	_story_molly_allow_return = false
	_story_lmc_station_finish_pending = false
	_story_lmc_station_allow_return = false
	_story_okea_finish_pending = false
	_story_okea_allow_return = false
	_story_cela_finish_pending = false
	_story_cela_allow_return = false
	_story_lotus_finish_pending = false
	_story_lotus_allow_return = false
	_story_barnard_finish_pending = false
	_story_barnard_allow_return = false
	_story_archeon_finish_pending = false
	_story_archeon_allow_return = false
	_story_runa_finish_pending = false
	_story_runa_allow_return = false
	_story_m31_finish_pending = false
	_story_m31_allow_return = false
	_story_m31_stage = ""
	if planet_id != "lmc_p02":
		_story_talos_stage = ""
	if planet_id != "lmc_p03":
		_story_molly_stage = ""
	if planet_id != "st_lmc":
		_story_lmc_station_stage = ""
	if planet_id != "smc_p01":
		_story_okea_stage = ""
	if planet_id != "smc_p02":
		_story_cela_stage = ""
	if planet_id != "st_smc":
		_story_lotus_stage = ""
	_story_barnard_stage = ""
	_story_archeon_stage = ""
	_story_runa_stage = ""
	if planet_id != "mw_p01":
		_story_earth_stage = ""
	if planet_id != "mw_p02":
		_story_mars_stage = ""
	_meta = _find_planet_meta(planet_id)
	_planet_name = String(_meta.get("name_ru", display_name)) if bool(_meta.get("is_station", false)) else (display_name if not display_name.is_empty() else String(_meta.get("name_ru", planet_id)))
	if hud != null:
		hud.set("crystal_count", crystals)
	if is_instance_valid(_top_info):
		_top_info.configure(_planet_id, _planet_name, _meta)
	_apply_card_content()
	_apply_story_earth_stage()
	_reload_background()
	visible = true
	modulate = Color(1,1,1,0)
	create_tween().tween_property(self, "modulate", Color(1,1,1,1), 0.18)
	_layout_ui()


func set_story_earth_stage(stage: String) -> void:
	# Restrict only this single Earth Story visit; no new scene or card system.
	if not ["", "puzzle", "launch"].has(stage):
		push_warning("Unknown Earth tutorial stage: " + stage)
		return
	_story_earth_stage = stage
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func set_story_mars_stage(stage: String) -> void:
	# Story-only lesson on Mars. Regular Mars and every other Hub stay untouched.
	if not ["", "trace", "trace_done", "launch"].has(stage):
		push_warning("Unknown Mars tutorial stage: " + stage)
		return
	_story_mars_stage = stage
	if _is_setup and stage.is_empty():
		_apply_card_content()
	elif _is_setup:
		_story_mars_ensure_trace_card()
	_apply_story_earth_stage()


func set_story_station_stage(stage: String) -> void:
	# Only the canonical Milky Way station Story visit is guided.
	if not ["", "list", "list_done", "launch"].has(stage):
		push_warning("Unknown station tutorial stage: " + stage)
		return
	_story_station_stage = stage if _planet_id == "st_mw" else ""
	if stage == "list":
		_story_station_allow_return = false
		_story_station_ensure_list_card()
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func set_story_talos_stage(stage: String) -> void:
	# The exact same Planet Hub / Fungal Paths; Story only restricts actions.
	if not ["", "maze", "maze_done", "launch"].has(stage):
		push_warning("Unknown Talos Story stage: " + stage)
		return
	_story_talos_stage = stage if _planet_id == "lmc_p02" else ""
	if stage == "maze":
		_story_talos_finish_pending = false
		_story_talos_allow_return = false
		_story_talos_ensure_maze_card()
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func set_story_molly_stage(stage: String) -> void:
	# Native Grow Little Tree in the same Planet Hub. No extra scene or
	# modification to the planet's normal random 1–2 game selection.
	if not ["", "tree", "tree_done", "launch"].has(stage):
		push_warning("Unknown Molly Story stage: " + stage)
		return
	_story_molly_stage = stage if _planet_id == "lmc_p03" else ""
	if stage == "tree":
		_story_molly_finish_pending = false
		_story_molly_allow_return = false
		_story_molly_ensure_tree_card()
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func _story_molly_ensure_tree_card() -> void:
	# The existing game is part of the native catalog on another LMC planet.
	# During this teaching beat it alone appears on Molly.
	if _planet_id != "lmc_p03" or card_row.get_node_or_null("GamePreview_" + STORY_MOLLY_TREE_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_MOLLY_TREE_ID, {})
	if record.is_empty():
		push_error("Missing existing Grow Little Tree card in the native game database")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_MOLLY_TREE_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized(record.get("description", {})))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenMollyGrowTree"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_MOLLY_TREE_ID))


func set_story_lmc_station_stage(stage: String) -> void:
	# Second hyperspace lesson uses the SAME native station Hub and original
	# Catch a Sunbeam. No new station or replacement game scene is created.
	if not ["", "sunbeam", "sunbeam_done", "launch"].has(stage):
		push_warning("Unknown LMC station Story stage: " + stage)
		return
	_story_lmc_station_stage = stage if _planet_id == "st_lmc" else ""
	if stage == "sunbeam":
		_story_lmc_station_finish_pending = false
		_story_lmc_station_allow_return = false
		_story_lmc_station_ensure_sunbeam_card()
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func set_story_okea_stage(stage: String) -> void:
	# Reuse the approved Solution Lab in the ORIGINAL Okea Planet Hub.
	# Only this mandatory Story visit needs three distinct target colors.
	if not ["", "lab", "lab_done", "launch"].has(stage):
		push_warning("Unknown Okea Story stage: " + stage)
		return
	_story_okea_stage = stage if _planet_id == "smc_p01" else ""
	if stage == "lab":
		_story_okea_finish_pending = false
		_story_okea_allow_return = false
		_story_okea_ensure_solution_card()
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func set_story_cela_stage(stage: String) -> void:
	# Story-only wrapper around the EXISTING native Resource Rush game.
	# Free World still gets the ordinary randomized cards.
	if not ["", "crystals", "crystals_done", "launch"].has(stage):
		push_warning("Unknown Cela Story stage: " + stage)
		return
	_story_cela_stage = stage if _planet_id == "smc_p02" else ""
	if stage == "crystals":
		_story_cela_finish_pending = false
		_story_cela_allow_return = false
		_story_cela_ensure_crystal_card()
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func set_story_lotus_stage(stage: String) -> void:
	# One mandatory water molecule on the REAL Living Archive station hub.
	if not ["", "molecule", "molecule_done", "launch"].has(stage):
		push_warning("Unknown Lotus Story stage: " + stage)
		return
	_story_lotus_stage = stage if _planet_id == "st_smc" else ""
	if stage == "molecule":
		_story_lotus_finish_pending = false
		_story_lotus_allow_return = false
		_story_lotus_ensure_molecule_card()
		var story_card: Control = card_row.get_node_or_null("GamePreview_" + STORY_LOTUS_MOLECULE_ID) as Control
		if is_instance_valid(story_card):
			story_card.set("card_description", _v104_card_localized({"ru": "Собери H₂O — молекулу воды", "en": "Build H₂O, the water molecule", "fr": "Construis H₂O, la molécule d’eau", "de": "Baue H₂O, das Wassermolekül", "es": "Forma H₂O, la molécula del agua", "pt_BR": "Monte H₂O, a molécula de água"}))
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func set_story_barnard_stage(stage: String) -> void:
	# On the original Titan Head Hub, the child completes exactly one real
	# Pizza Fractions round. Only then do we reveal the escape and Launch.
	if not ["", "pizza", "pizza_done", "launch"].has(stage):
		push_warning("Unknown Barnard Story station stage: " + stage)
		return
	_story_barnard_stage = stage if _planet_id == "st_ngc6822" else ""
	if stage == "pizza":
		_story_barnard_finish_pending = false
		_story_barnard_allow_return = false
		var card: Control = card_row.get_node_or_null("GamePreview_" + STORY_BARNARD_PIZZA_ID) as Control
		if is_instance_valid(card):
			card.set("card_title", _v104_card_localized({
				"ru": "Подели пиццу", "en": "Share the Pizza",
				"fr": "Partage la pizza", "de": "Teile die Pizza",
				"es": "Reparte la pizza", "pt_BR": "Divida a pizza"
			}))
		else:
			push_error("Barnard Story: native Pizza Fractions card is absent on Titan Head station")
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func set_story_archeon_stage(stage: String) -> void:
	# The same native Fossil Hunt as in the simulator, temporarily configured
	# for three discoveries on Archeon. Other planets and Free World are intact.
	if not ["", "fossils", "fossils_done", "launch"].has(stage):
		push_warning("Unknown Archeon Story stage: " + stage)
		return
	_story_archeon_stage = stage if _planet_id == "ngc6822_p01" else ""
	if stage == "fossils":
		_story_archeon_finish_pending = false
		_story_archeon_allow_return = false
		_story_archeon_ensure_fossil_card()
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func _story_archeon_ensure_fossil_card() -> void:
	if _planet_id != "ngc6822_p01" or card_row.get_node_or_null("GamePreview_" + STORY_ARCHEON_FOSSIL_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_ARCHEON_FOSSIL_ID, {})
	if record.is_empty():
		push_error("Archeon Story: fossil game is missing from the existing planet catalog")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_ARCHEON_FOSSIL_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized({
		"ru": "Найди три ископаемых", "en": "Find three fossils",
		"fr": "Trouve trois fossiles", "de": "Finde drei Fossilien",
		"es": "Encuentra tres fósiles", "pt_BR": "Encontre três fósseis"
	}))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenArcheonFossilHunt"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_ARCHEON_FOSSIL_ID))


func set_story_runa_stage(stage: String) -> void:
	# Use the original Evolution Sequence on the native Runa Hub. Five real
	# completed chains advance the story; Free World keeps the endless loop.
	if not ["", "evolution", "evolution_done", "launch"].has(stage):
		push_warning("Unknown Runa Story stage: " + stage)
		return
	_story_runa_stage = stage if _planet_id == "ngc6822_p06" else ""
	if stage == "evolution":
		_story_runa_finish_pending = false
		_story_runa_allow_return = false
		_story_runa_ensure_evolution_card()
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func _story_runa_ensure_evolution_card() -> void:
	# Runa normally carries Fossil Hunt in its 1-card rotation. Insert ONLY
	# the EXISTING Evolution game while the mandatory story visit is active.
	if _planet_id != "ngc6822_p06" or card_row.get_node_or_null("GamePreview_" + STORY_RUNA_EVOLUTION_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_RUNA_EVOLUTION_ID, {})
	if record.is_empty():
		push_error("Runa Story: the native Evolution game is missing from its catalogue")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_RUNA_EVOLUTION_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized({
		"ru": "Пройди пять цепочек эволюции", "en": "Complete five evolution chains",
		"fr": "Termine cinq chaînes d’évolution", "de": "Löse fünf Evolutionsketten",
		"es": "Completa cinco cadenas evolutivas", "pt_BR": "Complete cinco sequências evolutivas"
	}))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenRunaEvolution"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_RUNA_EVOLUTION_ID))


func set_story_m31_stage(stage: String) -> void:
	# Native Phasis Pinball plus two native station minigames.
	if not ["", "pinball", "pinball_done", "launch", "ball", "ball_done", "pulses", "pulses_done", "station_launch"].has(stage):
		push_warning("Unknown Andromeda Story stage: " + stage)
		return
	var phasis: bool = _planet_id == "m31_p03" and ["", "pinball", "pinball_done", "launch"].has(stage)
	var station: bool = _planet_id == "st_m31" and ["", "ball", "ball_done", "pulses", "pulses_done", "station_launch"].has(stage)
	_story_m31_stage = stage if phasis or station else ""
	if stage in ["pinball", "ball", "pulses"]:
		_story_m31_finish_pending = false
		_story_m31_allow_return = false
		if stage == "pinball":
			_story_m31_ensure_pinball_card()
		else:
			_story_m31_ensure_station_game_card(STORY_M31_BALL_ID if stage == "ball" else STORY_M31_PULSES_ID)
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()


func _story_m31_ensure_pinball_card() -> void:
	if _planet_id != "m31_p03" or card_row.get_node_or_null("GamePreview_" + STORY_M31_PINBALL_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_M31_PINBALL_ID, {})
	if record.is_empty():
		push_error("Andromeda Story: Gravity Pinball missing from native game catalogue")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_M31_PINBALL_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized({
		"ru": "Набери хотя бы одно очко", "en": "Score at least one point",
		"fr": "Marque au moins un point", "de": "Erziele mindestens einen Punkt",
		"es": "Consigue al menos un punto", "pt_BR": "Marque pelo menos um ponto"
	}))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenM31Pinball"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_M31_PINBALL_ID))


func _story_m31_poll_pinball() -> void:
	if _story_m31_stage != "pinball" or not _v1051_playing or _story_m31_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var game_script: Script = game.get_script() as Script
		if game_script == null or game_script.resource_path.get_file() != "gravity_pinball_v23.gd":
			continue
		var arena: Node = game.get("_arena") as Node
		if is_instance_valid(arena) and int(arena.get("_crystals")) >= STORY_M31_PINBALL_TARGET:
			_story_m31_finish_pending = true
			_story_m31_stage = "pinball_done"
			_apply_story_earth_stage()
			_story_m31_finish_after_success()
		break


func _story_m31_finish_after_success() -> void:
	# Give the real success/score indicator a moment to remain visible.
	await get_tree().create_timer(1.15).timeout
	if _story_m31_stage != "pinball_done" or not _v1051_playing:
		return
	_story_m31_allow_return = true
	_v1051_return_to_cards()
	_story_m31_allow_return = false
	story_m31_pinball_solved.emit()


func _story_m31_ensure_station_game_card(game_id: String) -> void:
	if _planet_id != "st_m31" or card_row.get_node_or_null("GamePreview_" + game_id) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(game_id, {})
	if record.is_empty():
		push_error("Andromeda Story: missing native station game " + game_id)
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + game_id
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	var descriptions: Dictionary = {
		"ru": "Пройди один лабиринт" if game_id == STORY_M31_BALL_ID else "Повтори два сигнала",
		"en": "Complete one maze" if game_id == STORY_M31_BALL_ID else "Repeat two signals",
		"fr": "Termine un labyrinthe" if game_id == STORY_M31_BALL_ID else "Répète deux signaux",
		"de": "Schaffe ein Labyrinth" if game_id == STORY_M31_BALL_ID else "Wiederhole zwei Signale",
		"es": "Completa un laberinto" if game_id == STORY_M31_BALL_ID else "Repite dos señales",
		"pt_BR": "Conclua um labirinto" if game_id == STORY_M31_BALL_ID else "Repita dois sinais"
	}
	card.set("card_description", _v104_card_localized(descriptions))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenM31StationGame"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(game_id))


func _story_m31_poll_station_tasks() -> void:
	if not ["ball", "pulses"].has(_story_m31_stage) or not _v1051_playing or _story_m31_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var native_script: Script = game.get_script() as Script
		if native_script == null:
			continue
		var native_file: String = native_script.resource_path.get_file()
		var solved: bool = false
		if _story_m31_stage == "ball" and native_file == "mika_roll_ball_result_popup_v2_4_1.gd":
			solved = bool(game.get("completed"))
		elif _story_m31_stage == "pulses" and native_file in ["ElectricImpulses_mika_v2_1.gd", "MIKAStoryPulseInputV1.gd"]:
			# Genuine first level, two DIFFERENT correct pressed notes in order.
			# The script cannot advance Story merely on an attempted tap.
			solved = (int(game.get("_level")) == 0
				and str(game.get("_phase")) == "level_done"
				and int(game.get("_input_step")) == 2
				and (game.get("_sequence") as Array).size() == 2)
		if solved:
			var finished_task: String = _story_m31_stage
			_story_m31_finish_pending = true
			_story_m31_stage = finished_task + "_done"
			_apply_story_earth_stage()
			_story_m31_finish_station_success(finished_task)
		break


func _story_m31_finish_station_success(finished_task: String) -> void:
	await get_tree().create_timer(1.10).timeout
	if _story_m31_stage != finished_task + "_done" or not _v1051_playing:
		return
	_story_m31_allow_return = true
	_v1051_return_to_cards()
	_story_m31_allow_return = false
	if finished_task == "ball":
		story_m31_ball_solved.emit()
	else:
		story_m31_pulses_solved.emit()


func _story_lotus_ensure_molecule_card() -> void:
	if _planet_id != "st_smc" or card_row.get_node_or_null("GamePreview_" + STORY_LOTUS_MOLECULE_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_LOTUS_MOLECULE_ID, {})
	if record.is_empty():
		push_error("Original Build a Molecule missing from native station catalogue")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_LOTUS_MOLECULE_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized({"ru": "Собери воду H₂O: два атома водорода и один кислорода", "en": "Build water H₂O: two hydrogens and one oxygen", "fr": "Construis H₂O : deux hydrogènes et un oxygène", "de": "Baue H₂O: zwei Wasserstoff- und ein Sauerstoffatom", "es": "Forma H₂O: dos hidrógenos y un oxígeno", "pt_BR": "Monte H₂O: dois hidrogênios e um oxigênio"}))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenLotusWaterMolecule"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized({"ru": "Собери молекулу H₂O", "en": "Build the H₂O molecule", "fr": "Construis la molécule H₂O", "de": "Baue das H₂O-Molekül", "es": "Forma la molécula H₂O", "pt_BR": "Monte a molécula H₂O"})
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_LOTUS_MOLECULE_ID))


func _story_cela_ensure_crystal_card() -> void:
	if _planet_id != "smc_p02" or card_row.get_node_or_null("GamePreview_" + STORY_CELA_CRYSTAL_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_CELA_CRYSTAL_ID, {})
	if record.is_empty():
		push_error("Original Resource Rush game missing from native planet catalogue")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_CELA_CRYSTAL_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	# The same original card/illustration; only the Story mission description
	# asks for five pickups and is localized in the user's six languages.
	card.set("card_title", _v104_card_localized({"ru": "Собери кристаллы", "en": "Collect Crystals", "fr": "Ramasse les cristaux", "de": "Sammle Kristalle", "es": "Recoge cristales", "pt_BR": "Colete cristais"}))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized({"ru": "Помоги Мике собрать 5 кристаллов", "en": "Help Mika collect 5 crystals", "fr": "Aide Mika à ramasser 5 cristaux", "de": "Hilf Mika, 5 Kristalle zu sammeln", "es": "Ayuda a Mika a recoger 5 cristales", "pt_BR": "Ajude Mika a coletar 5 cristais"}))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenCelaResourceRush"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized({"ru": "Собрать 5 кристаллов", "en": "Collect 5 crystals", "fr": "Ramasser 5 cristaux", "de": "5 Kristalle sammeln", "es": "Recoger 5 cristales", "pt_BR": "Coletar 5 cristais"})
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_CELA_CRYSTAL_ID))


func _story_okea_ensure_solution_card() -> void:
	if _planet_id != "smc_p01" or card_row.get_node_or_null("GamePreview_" + STORY_OKEA_SOLUTION_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_OKEA_SOLUTION_ID, {})
	if record.is_empty():
		push_error("Original Solution Lab game missing from native planet catalogue")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_OKEA_SOLUTION_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized(record.get("description", {})))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenOkeaSolutionLab"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_OKEA_SOLUTION_ID))


func _story_lmc_station_ensure_sunbeam_card() -> void:
	if _planet_id != "st_lmc" or card_row.get_node_or_null("GamePreview_" + STORY_LMC_SUNBEAM_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_LMC_SUNBEAM_ID, {})
	if record.is_empty():
		push_error("Missing existing Catch a Sunbeam card in the native planet-game database")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_LMC_SUNBEAM_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized(record.get("description", {})))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenStationSunbeamRefuel"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_LMC_SUNBEAM_ID))


func _story_talos_ensure_maze_card() -> void:
	# Preserve the original random-card system outside this teaching visit.
	if _planet_id != "lmc_p02" or card_row.get_node_or_null("GamePreview_" + STORY_TALOS_MAZE_ID) != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get(STORY_TALOS_MAZE_ID, {})
	if record.is_empty():
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_TALOS_MAZE_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized(record.get("description", {})))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenTalosFungalMaze"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_TALOS_MAZE_ID))


func _story_station_ensure_list_card() -> void:
	# Station normally lists this game already. Keep the mandatory Story card
	# available even if the native 1–2-card rotation changes in a future build.
	if _planet_id != "st_mw" or card_row.get_node_or_null("GamePreview_mw__shopping_list") != null:
		return
	var record: Dictionary = _v104_game_database.get("games", {}).get("mw__shopping_list", {})
	if record.is_empty():
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_mw__shopping_list"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized(record.get("title", {})))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized(record.get("description", {})))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", str(record.get("image_path", "")))
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenExistingGame"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized(record.get("title", {}))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind("mw__shopping_list"))


func _process(_delta: float) -> void:
	_story_barnard_poll_pizza()
	_story_runa_poll_evolution()
	_story_m31_poll_pinball()
	_story_m31_poll_station_tasks()
	_story_talos_poll_maze()
	_story_molly_poll_tree()
	_story_lmc_station_poll_sunbeam()
	_story_okea_poll_solutions()
	_story_cela_poll_crystals()
	_story_lotus_poll_water()
	# Existing Shopping List has no win signal. Watch its real game_over flag,
	# then show its native success overlay briefly before returning to Hub.
	if _story_station_stage != "list" or not _v1051_playing or _story_station_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "shopping_product_bg_v1.gd":
			continue
		if bool(game.get("game_over")):
			_story_station_finish_pending = true
			_story_station_stage = "list_done"
			_apply_story_earth_stage()
			_story_station_finish_after_success()
		break


func _story_runa_poll_evolution() -> void:
	if _story_runa_stage != "evolution" or not _v1051_playing or _story_runa_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "evolution_sequence_fossil_valley_v22.gd":
			continue
		# A point is awarded ONLY after a correctly placed missing animal.
		# The native game automatically shuffles through its five chains.
		if int(game.get("_score")) >= STORY_RUNA_EVOLUTION_TARGET:
			_story_runa_finish_pending = true
			_story_runa_stage = "evolution_done"
			_apply_story_earth_stage()
			_story_runa_finish_after_success()
		break


func _story_runa_finish_after_success() -> void:
	# Show the fifth genuine success frame before the 1-second auto-repeat.
	await get_tree().create_timer(0.72).timeout
	if _story_runa_stage != "evolution_done" or not _v1051_playing:
		return
	_story_runa_allow_return = true
	_v1051_return_to_cards()
	_story_runa_allow_return = false
	story_runa_evolution_solved.emit()


func _story_barnard_poll_pizza() -> void:
	if _story_barnard_stage != "pizza" or not _v1051_playing or _story_barnard_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "pizza_fraction_game.gd":
			continue
		# Count the game's REAL successful fraction, not a click or a timer.
		# Its native score increases only after the requested slices fit.
		if int(game.get("score")) >= 1:
			_story_barnard_finish_pending = true
			_story_barnard_stage = "pizza_done"
			_apply_story_earth_stage()
			_story_barnard_finish_after_success()
		break


func _story_barnard_finish_after_success() -> void:
	# Keep the first completed pizza and its praise on screen briefly.
	await get_tree().create_timer(1.8).timeout
	if _story_barnard_stage != "pizza_done" or not _v1051_playing:
		return
	_story_barnard_allow_return = true
	_v1051_return_to_cards()
	_story_barnard_allow_return = false
	story_barnard_pizza_solved.emit()


func _story_talos_poll_maze() -> void:
	if _story_talos_stage != "maze" or not _v1051_playing or _story_talos_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "fungal_art_game_v7.gd":
			continue
		if bool(game.get("_finished")):
			_story_talos_finish_pending = true
			_story_talos_stage = "maze_done"
			_apply_story_earth_stage()
			_story_talos_finish_after_success()
		break


func _story_molly_poll_tree() -> void:
	if _story_molly_stage != "tree" or not _v1051_playing or _story_molly_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "grow_little_tree.gd":
			continue
		if bool(game.get("_finished")) and bool(game.get("_won")):
			_story_molly_finish_pending = true
			_story_molly_stage = "tree_done"
			_apply_story_earth_stage()
			_story_molly_finish_after_success()
		break


func _story_lmc_station_poll_sunbeam() -> void:
	if _story_lmc_station_stage != "sunbeam" or not _v1051_playing or _story_lmc_station_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "catch_sunbeam_art_v54.gd":
			continue
		# The native game is normally infinite. Its FIRST full battery is
		# precisely 15 hits / 50 energy, and completes this one Story mission.
		if int(game.get("_cycles")) >= 1 and str(game.get("_phase")) == "charged":
			_story_lmc_station_finish_pending = true
			_story_lmc_station_stage = "sunbeam_done"
			_apply_story_earth_stage()
			_story_lmc_station_finish_after_success()
		break


func _story_okea_poll_solutions() -> void:
	if _story_okea_stage != "lab" or not _v1051_playing or _story_okea_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "solution_lab.gd":
			continue
		# Native Solution Lab shuffles all 28 target recipes without repeats.
		# Its _crystals increments on a CORRECT mixture and immediately starts
		# the next random target; three wins therefore mean three DISTINCT colors.
		if int(game.get("_crystals")) >= 3:
			_story_okea_finish_pending = true
			_story_okea_stage = "lab_done"
			_apply_story_earth_stage()
			_story_okea_finish_after_success()
		break


func _story_okea_finish_after_success() -> void:
	# Let the third color's native success animation and praise play first.
	await get_tree().create_timer(1.20).timeout
	if _story_okea_stage != "lab_done" or not _v1051_playing:
		return
	_story_okea_allow_return = true
	_v1051_return_to_cards()
	_story_okea_allow_return = false
	story_okea_solutions_solved.emit()


func _story_cela_poll_crystals() -> void:
	if _story_cela_stage != "crystals" or not _v1051_playing or _story_cela_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "resource_rush_native_v1.gd":
			continue
		# Count the real native collected crystals, not HUD text or taps.
		if int(game.get("player_score")) >= STORY_CELA_CRYSTAL_TARGET:
			_story_cela_finish_pending = true
			_story_cela_stage = "crystals_done"
			_apply_story_earth_stage()
			_story_cela_finish_after_success()
		break


func _story_cela_finish_after_success() -> void:
	await get_tree().create_timer(1.18).timeout
	if _story_cela_stage != "crystals_done" or not _v1051_playing:
		return
	_story_cela_allow_return = true
	_v1051_return_to_cards()
	_story_cela_allow_return = false
	story_cela_crystals_solved.emit()


func _story_lotus_poll_water() -> void:
	if _story_lotus_stage != "molecule" or not _v1051_playing or _story_lotus_finish_pending:
		return
	if not is_instance_valid(_v1051_viewport):
		return
	for game in _v1051_viewport.get_children():
		var script: Script = game.get_script() as Script
		if script == null or script.resource_path.get_file() != "MoleculeBuilder.gd":
			continue
		var model: Dictionary = game.get("_model") as Dictionary
		if str(model.get("id", "")) == "water" and bool(game.get("_completed")):
			_story_lotus_finish_pending = true
			_story_lotus_stage = "molecule_done"
			_apply_story_earth_stage()
			_story_lotus_finish_after_success()
		break


func _story_lotus_finish_after_success() -> void:
	# The original water-success sound / praise gets time to play first.
	await get_tree().create_timer(1.25).timeout
	if _story_lotus_stage != "molecule_done" or not _v1051_playing:
		return
	_story_lotus_allow_return = true
	_v1051_return_to_cards()
	_story_lotus_allow_return = false
	story_lotus_water_solved.emit()


func _story_lmc_station_finish_after_success() -> void:
	await get_tree().create_timer(1.08).timeout
	if _story_lmc_station_stage != "sunbeam_done" or not _v1051_playing:
		return
	_story_lmc_station_allow_return = true
	_v1051_return_to_cards()
	_story_lmc_station_allow_return = false
	story_lmc_station_sunbeam_solved.emit()


func _story_molly_finish_after_success() -> void:
	# Show the native victory state, then run the original fifth comic panel.
	await get_tree().create_timer(1.35).timeout
	if _story_molly_stage != "tree_done" or not _v1051_playing:
		return
	_story_molly_allow_return = true
	_v1051_return_to_cards()
	_story_molly_allow_return = false
	story_molly_tree_solved.emit()


func _story_talos_finish_after_success() -> void:
	# Let the existing Fungal Paths success panel play, then return to Hub.
	await get_tree().create_timer(1.35).timeout
	if _story_talos_stage != "maze_done" or not _v1051_playing:
		return
	_story_talos_allow_return = true
	_v1051_return_to_cards()
	_story_talos_allow_return = false
	story_talos_maze_solved.emit()


func _story_station_finish_after_success() -> void:
	await get_tree().create_timer(1.25).timeout
	if _story_station_stage != "list_done" or not _v1051_playing:
		return
	_story_station_allow_return = true
	_v1051_return_to_cards()
	_story_station_allow_return = false
	story_station_list_solved.emit()


func _story_mars_ensure_trace_card() -> void:
	if _planet_id != "mw_p02" or _story_mars_stage.is_empty():
		return
	if card_row.get_node_or_null("GamePreview_" + STORY_MARS_WORD_ID) != null:
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_" + STORY_MARS_WORD_ID
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized({"ru": "Обведи слово", "en": "Trace the word", "fr": "Trace le mot", "de": "Schreibe das Wort", "es": "Traza la palabra", "pt_BR": "Contorne a palavra"}))
	card.set("card_subtitle", _v104_card_localized({"ru": "МАРС", "en": "MARS", "fr": "MARS", "de": "MARS", "es": "MARTE", "pt_BR": "MARTE"}))
	card.set("card_description", _v104_card_localized({"ru": "Обведи буквы названия планеты Марс.", "en": "Trace the letters in MARS.", "fr": "Trace les lettres de MARS.", "de": "Schreibe die Buchstaben MARS.", "es": "Traza las letras de MARTE.", "pt_BR": "Contorne as letras de MARTE."}))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", STORY_MARS_WORD_ICON)
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var hit: Button = Button.new()
	hit.name = "OpenMarsStoryWord"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = _v104_card_localized({"ru": "МАРС", "en": "MARS", "fr": "MARS", "de": "MARS", "es": "MARTE", "pt_BR": "MARTE"})
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(_v1051_open_existing_game.bind(STORY_MARS_WORD_ID))


func _apply_story_earth_stage() -> void:
	if not _is_setup:
		return
	if _story_launch_pulse != null and _story_launch_pulse.is_running():
		_story_launch_pulse.kill()
	var simulator_button: Button = hud.get("sim_button") as Button
	var launch_button: Button = hud.get("flight_button") as Button
	var story_restricted: bool = not _story_earth_stage.is_empty() or not _story_mars_stage.is_empty() or not _story_station_stage.is_empty() or not _story_talos_stage.is_empty() or not _story_molly_stage.is_empty() or not _story_lmc_station_stage.is_empty() or not _story_okea_stage.is_empty() or not _story_cela_stage.is_empty() or not _story_lotus_stage.is_empty() or not _story_barnard_stage.is_empty() or not _story_archeon_stage.is_empty() or not _story_runa_stage.is_empty() or not _story_m31_stage.is_empty() or not _story_ch06_stage.is_empty()
	if simulator_button != null:
		# Keep the real Hub HUD in place; disable the action during Story.
		simulator_button.visible = true
		simulator_button.disabled = story_restricted
		simulator_button.modulate = Color.WHITE if not simulator_button.disabled else Color(1.0, 1.0, 1.0, 0.48)
	if launch_button != null:
		launch_button.visible = true
		launch_button.disabled = _story_earth_stage == "puzzle" or (not _story_mars_stage.is_empty() and _story_mars_stage != "launch") or (not _story_station_stage.is_empty() and _story_station_stage != "launch") or (not _story_talos_stage.is_empty() and _story_talos_stage != "launch") or (not _story_molly_stage.is_empty() and _story_molly_stage != "launch") or (not _story_lmc_station_stage.is_empty() and _story_lmc_station_stage != "launch") or (not _story_okea_stage.is_empty() and _story_okea_stage != "launch") or (not _story_cela_stage.is_empty() and _story_cela_stage != "launch") or (not _story_lotus_stage.is_empty() and _story_lotus_stage != "launch") or (not _story_barnard_stage.is_empty() and _story_barnard_stage != "launch") or (not _story_archeon_stage.is_empty() and _story_archeon_stage != "launch") or (not _story_runa_stage.is_empty() and _story_runa_stage != "launch") or (not _story_m31_stage.is_empty() and not ["launch", "station_launch"].has(_story_m31_stage)) or _story_ch06_stage in ["math", "math_done"]
		launch_button.modulate = Color.WHITE if not launch_button.disabled else Color(1.0, 1.0, 1.0, 0.48)
	if (_story_earth_stage == "launch" or _story_mars_stage == "launch" or _story_station_stage == "launch" or _story_talos_stage == "launch" or _story_molly_stage == "launch" or _story_lmc_station_stage == "launch" or _story_okea_stage == "launch" or _story_cela_stage == "launch" or _story_lotus_stage == "launch" or _story_barnard_stage == "launch" or _story_archeon_stage == "launch" or _story_runa_stage == "launch" or _story_m31_stage in ["launch", "station_launch"] or _story_ch06_stage == "launch") and launch_button != null:
		_story_launch_pulse = create_tween().set_loops()
		_story_launch_pulse.tween_property(launch_button, "modulate", Color(1.0, 0.76, 0.42, 0.55), 0.48).set_trans(Tween.TRANS_SINE)
		_story_launch_pulse.tween_property(launch_button, "modulate", Color.WHITE, 0.48).set_trans(Tween.TRANS_SINE)
	if story_restricted:
		for child in card_row.get_children():
			if child is Control:
				child.visible = (_story_earth_stage == "puzzle" and str(child.name) == "GamePreview_mw__puzzles") or (["trace", "trace_done"].has(_story_mars_stage) and str(child.name) == "GamePreview_" + STORY_MARS_WORD_ID) or (_story_station_stage == "list" and str(child.name) == "GamePreview_mw__shopping_list") or (_story_talos_stage == "maze" and str(child.name) == "GamePreview_" + STORY_TALOS_MAZE_ID) or (_story_molly_stage == "tree" and str(child.name) == "GamePreview_" + STORY_MOLLY_TREE_ID) or (_story_lmc_station_stage == "sunbeam" and str(child.name) == "GamePreview_" + STORY_LMC_SUNBEAM_ID) or (_story_okea_stage == "lab" and str(child.name) == "GamePreview_" + STORY_OKEA_SOLUTION_ID) or (_story_cela_stage == "crystals" and str(child.name) == "GamePreview_" + STORY_CELA_CRYSTAL_ID) or (_story_lotus_stage == "molecule" and str(child.name) == "GamePreview_" + STORY_LOTUS_MOLECULE_ID) or (_story_barnard_stage == "pizza" and str(child.name) == "GamePreview_" + STORY_BARNARD_PIZZA_ID) or (_story_archeon_stage == "fossils" and str(child.name) == "GamePreview_" + STORY_ARCHEON_FOSSIL_ID) or (_story_runa_stage == "evolution" and str(child.name) == "GamePreview_" + STORY_RUNA_EVOLUTION_ID) or (_story_m31_stage == "pinball" and str(child.name) == "GamePreview_" + STORY_M31_PINBALL_ID) or (_story_m31_stage == "ball" and str(child.name) == "GamePreview_" + STORY_M31_BALL_ID) or (_story_m31_stage == "pulses" and str(child.name) == "GamePreview_" + STORY_M31_PULSES_ID) or (_story_ch06_stage == "math" and str(child.name) == "GamePreview_" + CH06_MATH_ID)
				if str(child.name) == "GamePreview_" + STORY_MARS_WORD_ID:
					var story_hit: Button = child.get_node_or_null("OpenMarsStoryWord") as Button
					if story_hit != null:
						story_hit.disabled = _story_mars_stage != "trace"
		scroll.scroll_horizontal = 0
	_layout_ui()

func hide_hub(animate: bool = true) -> void:
	_bubble_ball_force_clear()

	if not visible:
		return
	if animate:
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color(1,1,1,0), 0.12)
		await tw.finished
	visible = false

func _load_atlas() -> void:
	_atlas.clear()
	if not FileAccess.file_exists(ATLAS_PATH):
		return
	var text := FileAccess.get_file_as_string(ATLAS_PATH)
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_atlas = parsed

func _find_planet_meta(planet_id: String) -> Dictionary:
	var systems: Array = _atlas.get("systems", [])
	for system_data in systems:
		if not (system_data is Dictionary):
			continue
		for planet in system_data.get("planets", []):
			if planet is Dictionary and String(planet.get("id", "")) == planet_id:
				var result: Dictionary = planet.duplicate(true)
				result["system_id"] = String(system_data.get("id", ""))
				result["system_name_ru"] = String(system_data.get("name_ru", ""))
				return result
		var station: Variant = system_data.get("station", null)
		if station is Dictionary and String(station.get("id", "")) == planet_id:
			var result: Dictionary = station.duplicate(true)
			result["inhabited"] = bool(station.get("accessible", true))
			result["is_station"] = true
			result["unique"] = "Изучи устройство станции и познакомься с её экипажем."
			result["system_id"] = String(system_data.get("id", ""))
			result["system_name_ru"] = String(system_data.get("name_ru", ""))
			return result
	return {}

func _load_representative_roster() -> void:
	_representative_roster.clear()
	if not FileAccess.file_exists(ROSTER_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROSTER_PATH))
	if parsed is Dictionary:
		var assignments: Variant = parsed.get("assignments", {})
		if assignments is Dictionary:
			_representative_roster = assignments

func _load_missions() -> void:
	_mission_records.clear()
	if not FileAccess.file_exists(MISSION_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MISSION_PATH))
	if parsed is Dictionary:
		var records: Variant = parsed.get("missions", {})
		if records is Dictionary:
			_mission_records = records

func _mission_entry() -> Dictionary:
	var record: Variant = _mission_records.get(_planet_id, {})
	if record is Dictionary and bool(record.get("enabled", false)):
		return record
	return {}

func _localized_mission_field(record: Dictionary, field: String, default_text: String = "") -> String:
	var value: Variant = record.get(field, default_text)
	if value is Dictionary:
		var language: String = "ru" if Engine.is_editor_hint() else MobileLocale.language
		return str(value.get(language, value.get("ru", value.get("en", default_text))))
	return str(value)

func _input(event: InputEvent) -> void:
	# ScrollContainer already handles touch swipes; support mouse dragging too.
	# No scrollbar is displayed on mobile or desktop.
	if _v1051_playing or not visible or not is_instance_valid(scroll):
		_mouse_scroll_drag = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_scroll_drag = scroll.get_global_rect().has_point(event.position)
		else:
			_mouse_scroll_drag = false
	elif event is InputEventMouseMotion and _mouse_scroll_drag and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		scroll.scroll_horizontal = maxi(0, scroll.scroll_horizontal - roundi(event.relative.x))

func _representative_entry() -> Dictionary:
	var entry: Variant = _representative_roster.get(_planet_id, {})
	return entry if entry is Dictionary else {}

func _resolve_first_existing(paths: Array[String]) -> String:
	for path in paths:
		if not String(path).is_empty() and ResourceLoader.exists(path):
			return path
	return ""

func _v85_shared_empty_background_path(planet_id: String) -> String:
	# Map is data driven and only used on catalogued uninhabited worlds.
	if not FileAccess.file_exists("res://planet_hub/data/uninhabited_shared_backgrounds.json"):
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://planet_hub/data/uninhabited_shared_backgrounds.json"))
	if not (parsed is Dictionary):
		return ""
	var mapping: Variant = parsed.get("planet_to_background", {})
	if not (mapping is Dictionary) or not mapping.has(planet_id):
		return ""
	var number: int = int(mapping.get(planet_id, 0))
	if number < 1 or number > 13:
		return ""
	return "res://planet_hub/backgrounds/shared_uninhabited/%02d.png" % number


func _reload_background() -> void:
	_background_texture = null
	_background_path = ""
	## v85: 13 shared backgrounds for 24 uninhabited worlds; never override inhabited worlds.
	if _meta.has("inhabited") and not bool(_meta.get("inhabited", true)) and not bool(_meta.get("is_station", false)):
		var shared_path: String = _v85_shared_empty_background_path(_planet_id)
		if not shared_path.is_empty() and ResourceLoader.exists(shared_path):
			var shared_texture: Texture2D = load(shared_path) as Texture2D
			if shared_texture != null:
				_background_path = shared_path
				_background_texture = shared_texture
				queue_redraw()
				return
	var system_id: String = String(_meta.get("system_id", ""))
	var bg_path: String = _resolve_first_existing([
		BACKGROUND_ROOT + _planet_id + ".png",
		BACKGROUND_ROOT + _planet_id + ".jpg",
		BACKGROUND_ROOT + _planet_id + ".webp",
		BACKGROUND_ROOT + system_id + ".png" if bool(_meta.get("is_station", false)) else "",
		BACKGROUND_ROOT + system_id + ".jpg" if bool(_meta.get("is_station", false)) else "",
		BACKGROUND_ROOT + "default.png" if bool(_meta.get("is_station", false)) else "",
	])
	if not bg_path.is_empty():
		_background_path = bg_path
		_background_texture = load(bg_path) as Texture2D
	queue_redraw()

func _station_description(station_id: String) -> String:
	match station_id:
		"st_mw":
			return "Дальняя ремонтная верфь: космическая станция для обслуживания и ремонта кораблей во внешней части Солнечной системы."
		"st_lmc":
			return "Лабораторный корабль «Тарантул»: исследовательская станция, расположенная в свободном космическом пространстве."
		"st_smc":
			return "Живой архив: станция в глубоком космосе, окружённая необычной атмосферной дымкой."
		"st_ngc6822":
			return "Голова Титана: удалённый космический порт среди астероидов и окружающих его колец."
		"st_m31":
			return "Перевёрнутая пирамида: отдельная загадочная конструкция во внешнем секторе галактики."
		"st_m33":
			return "Последние врата: межгалактический переход во внешнем секторе перед Перекрёстком миров."
		_:
			return "Исследуй станцию и узнай, как она устроена."

func _apply_card_content() -> void:
	var inhabited: bool = bool(_meta.get("inhabited", false))
	if representative != null:
		representative.visible = inhabited
		var is_station: bool = bool(_meta.get("is_station", false))
		representative.set("card_title", _planet_name)
		# A location card, not an identity card: do not display character names.
		representative.set("card_subtitle", _planet_name)
		var rep_text: String = String(_meta.get("unique", ""))
		if is_station:
			rep_text = _station_description(_planet_id)
		elif rep_text.is_empty():
			rep_text = "Познакомься с этим миром и узнай, кто здесь живёт."
		representative.set("card_description", rep_text)
		representative.set("card_subtitle", "")
		# v107: names and one short, canonical v106 sentence. Existing portraits and layout stay.
		var v107_person: Dictionary = _v107_card_bios.get(_planet_id, {})
		if not v107_person.is_empty():
			var v107_name: String = _v104_card_localized(v107_person.get("name", {}))
			var v107_bio: String = _v104_card_localized(v107_person.get("bio", {}))
			if not v107_name.is_empty():
				representative.set("card_title", v107_name)
			if not v107_bio.is_empty():
				representative.set("card_description", v107_bio)
		var portrait_path: String = get_dialog_portrait_path()
		var portrait_name: String = portrait_path.get_file()
		var humanoid: bool = portrait_name.begins_with("05_human_") or portrait_name.begins_with("06_human_") or portrait_name.begins_with("01_reptile_") or portrait_name.begins_with("02_reptile_")
		representative.set("image_fit_mode", "portrait_top" if humanoid else "contain")
		representative.set("image_path", portrait_path)
		_v108_ensure_entry_arrow(representative, true)
	if mission != null:
		var assignment: Dictionary = _mission_entry()
		# A mission card is absent unless an explicit enabled DB row exists.
		mission.visible = not assignment.is_empty()
		if mission.visible:
			var is_station: bool = bool(_meta.get("is_station", false))
			var default_title: String = "Задание станции" if is_station else "Задание планеты"
			mission.set("card_title", _localized_mission_field(assignment, "title", default_title))
			mission.set("card_subtitle", _localized_mission_field(assignment, "subtitle", _planet_name))
			mission.set("card_description", _localized_mission_field(assignment, "description"))
			var image: String = _localized_mission_field(assignment, "image", "")
			if not image.is_empty() and not ResourceLoader.exists(image):
				image = ""
			mission.set("image_path", image)
	_v104_refresh_game_cards()
	_layout_ui()

func _visible_cards() -> Array[Control]:
	var cards: Array[Control] = []
	for child in card_row.get_children():
		if child is Control and child.visible:
			cards.append(child)
	return cards

func _layout_ui() -> void:
	if not _is_setup:
		return
	var sw: float = size.x
	var sh: float = size.y
	if sw < 200 or sh < 180:
		return
	var scale_ui: float = minf(sh / 864.0, sw / 1450.0)
	scale_ui = clampf(scale_ui, 0.40, 2.0)
	var bottom_h: float = 158.0 * (sh / 864.0)
	hud.position = Vector2(0, sh - bottom_h)
	hud.size = Vector2(sw, bottom_h)
	# Compact top panel lies inside mobile-safe bounds.
	var top_safe: Rect2 = MobileLocale.safe_rect(Vector2(sw, sh))
	var top_h: float = clampf(sh * 0.105, 49.0, 108.0)
	var top_w: float = minf(top_safe.size.x * 0.94, 1490.0)
	if is_instance_valid(_top_info):
		_top_info.position = Vector2(top_safe.position.x + (top_safe.size.x - top_w) * 0.5, top_safe.position.y + 2.0)
		_top_info.size = Vector2(top_w, top_h)
	var cards: Array[Control] = _visible_cards()
	var card_w: float = 430.0 * scale_ui
	# v72: cards centered between top info and bottom HUD.
	# v72: content region is NOT the full screen. Keep clear of both panels.
	var cards_top: float = top_safe.position.y + 2.0 + top_h + maxf(8.0, 12.0 * scale_ui)
	var cards_bottom: float = minf(hud.position.y, top_safe.end.y) - maxf(8.0, 12.0 * scale_ui)
	var card_region_h: float = maxf(70.0, cards_bottom - cards_top)
	var card_h: float = minf(540.0 * scale_ui, maxf(66.0, card_region_h - 4.0 * scale_ui))
	var gap: float = 46.0 * scale_ui
	var count: int = cards.size()
	var row_w: float = float(count) * card_w + float(maxi(0, count - 1)) * gap
	card_row.add_theme_constant_override("separation", int(gap))
	for child in card_row.get_children():
		if child is Control:
			child.custom_minimum_size = Vector2(card_w, card_h)
	card_row.custom_minimum_size = Vector2(row_w, card_h)
	var scroll_h: float = minf(card_region_h, card_h + 4.0 * scale_ui)
	var scroll_y: float = cards_top + maxf(0.0, (card_region_h - scroll_h) * 0.5)
	scroll.position = Vector2(maxf(12 * scale_ui, (sw - row_w) * 0.5), scroll_y)
	scroll.size = Vector2(minf(row_w, sw - 24 * scale_ui), scroll_h)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	queue_redraw()

func _draw() -> void:
	var sw: float = size.x
	var sh: float = size.y
	if sw < 2 or sh < 2:
		return
	if _background_texture != null:
		var ts: Vector2 = _background_texture.get_size()
		var scale_cover: float = maxf(sw / ts.x, sh / ts.y)
		var crop_size: Vector2 = Vector2(sw, sh) / scale_cover
		var src: Rect2 = Rect2((ts - crop_size) * 0.5, crop_size)
		draw_texture_rect_region(_background_texture, Rect2(Vector2.ZERO, size), src)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("061527"))
		for n in range(18):
			var fy: float = float(n) / 18.0
			draw_rect(Rect2(0, fy * sh, sw, sh / 18 + 1), Color(0.016 + fy * 0.018, 0.075 + fy * 0.012, 0.15 + fy * 0.035, 0.42))
		var r: RandomNumberGenerator = RandomNumberGenerator.new()
		r.seed = hash(_planet_id)
		for i in range(175):
			var pt: Vector2 = Vector2(r.randf_range(0, sw), r.randf_range(0, sh * 0.86))
			draw_circle(pt, r.randf_range(0.5, 1.5), Color(0.57, 0.8, 1, r.randf_range(0.2, 0.8)))
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(40, 58), _planet_name if not _planet_name.is_empty() else "Планета", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.75, 0.9, 1.0, 0.8))
	draw_rect(Rect2(0, 0, sw, sh), Color(0.0, 0.03, 0.08, 0.18))

func _on_simulator_pressed() -> void:
	if not _story_ch06_stage.is_empty():
		return
	if not _story_earth_stage.is_empty() or not _story_mars_stage.is_empty() or not _story_station_stage.is_empty() or not _story_talos_stage.is_empty() or not _story_molly_stage.is_empty() or not _story_lmc_station_stage.is_empty() or not _story_okea_stage.is_empty() or not _story_cela_stage.is_empty() or not _story_lotus_stage.is_empty() or not _story_barnard_stage.is_empty() or not _story_m31_stage.is_empty():
		return
	simulator_requested.emit()

func _on_flight_pressed() -> void:
	if _story_ch06_stage in ["math", "math_done"]:
		return
	if _story_earth_stage == "puzzle" or (not _story_mars_stage.is_empty() and _story_mars_stage != "launch") or (not _story_station_stage.is_empty() and _story_station_stage != "launch") or (not _story_talos_stage.is_empty() and _story_talos_stage != "launch") or (not _story_molly_stage.is_empty() and _story_molly_stage != "launch") or (not _story_lmc_station_stage.is_empty() and _story_lmc_station_stage != "launch") or (not _story_okea_stage.is_empty() and _story_okea_stage != "launch") or (not _story_cela_stage.is_empty() and _story_cela_stage != "launch") or (not _story_lotus_stage.is_empty() and _story_lotus_stage != "launch") or (not _story_barnard_stage.is_empty() and _story_barnard_stage != "launch") or (not _story_m31_stage.is_empty() and not ["launch", "station_launch"].has(_story_m31_stage)):
		return
	flight_requested.emit()

func _v107_load_card_bios() -> void:
	_v107_card_bios.clear()
	if not FileAccess.file_exists(V107_CARD_BIOS_PATH):
		push_warning("Missing representative card biographies: " + V107_CARD_BIOS_PATH)
		return
	var v107_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(V107_CARD_BIOS_PATH))
	if v107_data is Dictionary:
		var v107_records: Variant = v107_data.get("characters", {})
		if v107_records is Dictionary:
			_v107_card_bios = v107_records


func _v104_load_game_database() -> void:
	_v104_game_database.clear()
	if not FileAccess.file_exists(V104_GAME_DB_PATH):
		push_warning("Missing game cards catalog: " + V104_GAME_DB_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(V104_GAME_DB_PATH))
	if parsed is Dictionary:
		_v104_game_database = parsed


func _v104_card_localized(value: Variant) -> String:
	if not (value is Dictionary):
		return str(value)
	var lang: String = "ru" if Engine.is_editor_hint() else MobileLocale.language
	return str(value.get(lang,value.get("en","")))


func _v104_card_status(code: String) -> String:
	var lang: String = "ru" if Engine.is_editor_hint() else MobileLocale.language
	var names: Dictionary = {
		"ru":{"ready":"Играть", "embedded_learning":"Основа готова", "adapt":"Нужна адаптация", "missing":"В разработке"},
		"en":{"ready":"Play", "embedded_learning":"Source available", "adapt":"Needs adaptation", "missing":"In development"},
		"fr":{"ready":"Jouer", "embedded_learning":"Base disponible", "adapt":"À adapter", "missing":"En développement"},
		"de":{"ready":"Spielen", "embedded_learning":"Vorlage vorhanden", "adapt":"Anpassung nötig", "missing":"In Entwicklung"},
		"es":{"ready":"Jugar", "embedded_learning":"Base disponible", "adapt":"Por adaptar", "missing":"En desarrollo"},
		"pt_BR":{"ready":"Jogar", "embedded_learning":"Base disponível", "adapt":"Precisa adaptar", "missing":"Em desenvolvimento"}
	}
	var localized: Dictionary = names.get(lang,names["en"])
	return str(localized.get(code,localized["missing"]))


# MIKA_PLANET_ROUTE_AND_BACK_V1
# Match the *working simulator*'s v115.1+24 scene resolution without
# modifying the simulator or the planet/mission assignment table.
const _MIKA_SIM_PLANET_CATALOG: String = "res://simulator_ui/data/temp_planet_cards_v1151p24.json"
var _mika_planet_candidates: Dictionary = {}
var _mika_planet_candidates_loaded: bool = false


func _mika_read_planet_candidates() -> void:
	if _mika_planet_candidates_loaded:
		return
	_mika_planet_candidates_loaded = true
	if not FileAccess.file_exists(_MIKA_SIM_PLANET_CATALOG):
		push_warning("MIKA: shared 24-game simulator catalog missing")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_MIKA_SIM_PLANET_CATALOG))
	if not (parsed is Dictionary):
		push_warning("MIKA: shared 24-game simulator catalog invalid")
		return
	var entries: Variant = parsed.get("entries", [])
	if not (entries is Array) or entries.size() != 24:
		push_warning("MIKA: shared simulator catalog is not the expected 24-game list")
		return
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var game_id: String = str(entry.get("id", ""))
		if not game_id.is_empty():
			_mika_planet_candidates[game_id] = entry.get("scene_candidates", [])


func _mika_planet_scene(game_id: String, record: Dictionary) -> String:
	_mika_read_planet_candidates()
	# The Bubble Ball card uses a dedicated existing handler, not this router.
	if not _mika_planet_candidates.has(game_id):
		return ""
	# This installed scene is intentionally prioritized by the working simulator.
	if game_id == "lmc__fungal_paths":
		var fungal: String = "res://planet_hub/games/fungal_paths/FungalPathsArtwork.tscn"
		if ResourceLoader.exists(fungal) and load(fungal) is PackedScene:
			return fungal
	var candidates: Array[String] = []
	var preferred: String = str(record.get("source_scene", ""))
	if preferred.begins_with("res://"):
		candidates.append(preferred)
	var raw: Variant = _mika_planet_candidates[game_id]
	if raw is Array:
		for candidate in raw:
			var path: String = str(candidate)
			if path.begins_with("res://") and not candidates.has(path):
				candidates.append(path)
	for scene_path in candidates:
		if ResourceLoader.exists(scene_path):
			return scene_path
	return ""


func _mika_is_game_exit_button(button: BaseButton) -> bool:
	var script: Script = button.get_script() as Script
	if script != null and script.resource_path.get_file() == "game_exit_button.gd":
		return true
	var name_lower: String = str(button.name).to_lower()
	return (
		name_lower in ["back", "exit", "home", "backbutton", "exitbutton", "homebutton", "back_button", "exit_button", "home_button"]
		or name_lower.ends_with("nativeback") or name_lower.ends_with("toolbarback")
		or name_lower.ends_with("sharedback") or name_lower.ends_with("backbutton")
		or name_lower.ends_with("back_button") or name_lower.ends_with("exitbutton")
		or name_lower.ends_with("exit_button") or name_lower.ends_with("home_button")
		or name_lower.begins_with("returnto")
	)



func _mika_bind_game_exit(instance: Node) -> void:
	if _story_ch06_stage in ["math", "math_done"]:
		return
	if _story_station_stage == "list" or _story_talos_stage == "maze" or _story_molly_stage == "tree" or _story_lmc_station_stage == "sunbeam" or _story_okea_stage == "lab" or _story_cela_stage == "crystals" or _story_lotus_stage == "molecule" or _story_archeon_stage == "fossils" or _story_runa_stage == "evolution" or _story_m31_stage in ["ball", "pulses"]:
		return
	var return_callback: Callable = Callable(self, "_v1051_return_to_cards")
	if instance.has_signal("back_requested") and not instance.is_connected("back_requested", return_callback):
		instance.connect("back_requested", return_callback, CONNECT_DEFERRED)
	var pending: Array[Node] = [instance]
	var inspected: int = 0
	while not pending.is_empty() and inspected < 2500:
		var node: Node = pending.pop_back()
		inspected += 1
		if node is BaseButton:
			var candidate: BaseButton = node as BaseButton
			if candidate.is_visible_in_tree() and _mika_is_game_exit_button(candidate):
				# Preserve its original handler, but always provide a reliable
				# fallback to the *current planet*, not a legacy scene selector.
				if not candidate.pressed.is_connected(return_callback):
					candidate.pressed.connect(return_callback, CONNECT_DEFERRED)
		for child in node.get_children():
			pending.append(child)
	# No host Back exists: leave the game's own controls visible.


func _mika_refresh_game_exit() -> void:
	if not _v1051_playing or not is_instance_valid(_v1051_viewport):
		return
	for instance in _v1051_viewport.get_children():
		_mika_bind_game_exit(instance)
		break


func _v104_refresh_game_cards() -> void:
	for old_card in _v104_game_cards:
		if is_instance_valid(old_card):
			card_row.remove_child(old_card)
			old_card.queue_free()
	_v104_game_cards.clear()
	if _v104_game_database.is_empty() or _planet_id.is_empty():
		return
	var by_planet: Dictionary = _v104_game_database.get("planet_cards", {})
	var game_records: Dictionary = _v104_game_database.get("games", {})
	var game_ids: Array = by_planet.get(_planet_id, [])
	# Use the native planet catalogue in BOTH modes. The v3.9 override
	# incorrectly replaced these 1–2 planet-specific games with three.
	var story_games_locked: bool = StorySubscriptionGate.paywall_active()
	for game_id_value in game_ids:
		var game_id: String = str(game_id_value)
		var record: Dictionary = game_records.get(game_id, {})
		var mika_scene: String = _mika_planet_scene(game_id, record)
		var mika_enabled: bool = not mika_scene.is_empty()
		if record.is_empty():
			continue
		var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
		card.name = "GamePreview_" + game_id
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.set("card_title",_v104_card_localized(record.get("title", {})))
		card.set("card_subtitle", "" if mika_enabled else _v104_card_status(str(record.get("source_status", "missing"))))
		card.set("card_description",_v104_card_localized(record.get("description", {})))
		card.set("accent",Color("55cdff"))
		if story_games_locked:
			# Preserve the genuine Planet Hub card and its click target.
			# Conversation/representative and Bubble Ball cards remain untouched.
			card.modulate = Color(0.43, 0.46, 0.52, 0.90)
		card.set("image_fit_mode","contain")
		var card_image: String = str(record.get("image_path", ""))
		if not card_image.is_empty():
			card.set("image_path", card_image)
			card.set("art_bay_enabled", true)
		card_row.add_child(card)
		if mika_enabled:
			_v108_ensure_entry_arrow(card, false)
		_v104_game_cards.append(card)
		var hint: Label = card.get_node_or_null("ImagePlaceholder") as Label
		if hint != null:
			hint.text = "✦"
			hint.add_theme_font_size_override("font_size",42)
		# The exact existing card is clickable ONLY when its validated game exists.
		# The hit area is transparent, like the existing RepresentativeCard overlay.
		var scene_path: String = mika_scene
		if story_games_locked or (mika_enabled and not scene_path.is_empty() and ResourceLoader.exists(scene_path)):
			var hit: Button = Button.new()
			hit.name = "OpenExistingGame"
			hit.flat = true
			hit.focus_mode = Control.FOCUS_NONE
			hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			hit.tooltip_text = _v104_card_localized(record.get("title", {}))
			for state in ["normal", "hover", "pressed", "disabled", "focus"]:
				hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
			card.add_child(hit)
			hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hit.pressed.connect(_v1051_open_existing_game.bind(game_id))
	_bubble_ball_make_card()
	_mika_station_race_add_card()



# One reusable Bubble Ball card on every mapped EMPTY world. The original
# V104 planet-card layout and card-size formulas remain entirely unchanged.
const _BALL_TITLE: Dictionary = {
	"ru":"Прогулка с Бабблом", "en":"Walk with Bubble", "fr":"Promenade avec Bubble",
	"de":"Spaziergang mit Bubble", "es":"Paseo con Bubble", "pt_BR":"Passeio com Bubble"
}
const _BALL_DESC: Dictionary = {
	"ru":"Брось мяч и посмотри, куда полетит Баббл.",
	"en":"Throw a ball and watch Bubble chase it.",
	"fr":"Lance la balle et regarde Bubble la suivre.",
	"de":"Wirf den Ball und sieh Bubble hinterherlaufen.",
	"es":"Lanza la pelota y mira a Bubble seguirla.",
	"pt_BR":"Jogue a bola e veja Bubble correr atrás dela."
}

func _bubble_ball_text(values: Dictionary) -> String:
	return str(values.get(str(MobileLocale.language),values.get("en","")))

func _bubble_ball_allowed(id: String) -> bool:
	if bool(_meta.get("inhabited",false)) or bool(_meta.get("is_station",false)):
		return false
	var file_name: String = "res://planet_hub/data/uninhabited_shared_backgrounds.json"
	if not FileAccess.file_exists(file_name):
		return false
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(file_name))
	if not (loaded is Dictionary):
		return false
	var mapped: Dictionary = loaded.get("planet_to_background",{})
	return mapped.has(id)

func _bubble_ball_refresh_card(_unused_code: String = "") -> void:
	if not is_instance_valid(_bubble_ball_card):
		return
	_bubble_ball_card.set("card_title",_bubble_ball_text(_BALL_TITLE))
	_bubble_ball_card.set("card_description",_bubble_ball_text(_BALL_DESC))
	var hit: Button = _bubble_ball_card.get_node_or_null("OpenBubbleBall") as Button
	if hit != null:
		hit.tooltip_text = _bubble_ball_text(_BALL_TITLE)

func _bubble_ball_make_card() -> void:
	# Reuse the existing v104 common__pet_walk card instead of creating a
	# second, unconnected "Play with Bubble" card. This is what users click.
	_bubble_ball_card = null
	if not _bubble_ball_allowed(_planet_id):
		return
	var card: Control = card_row.get_node_or_null("GamePreview_common__pet_walk") as Control
	if card == null:
		push_warning("Bubble Ball: existing Walk with Bubble card not found")
		return
	_bubble_ball_card = card
	card.set("card_title", _bubble_ball_text(_BALL_TITLE))
	card.set("card_subtitle", "")
	card.set("card_description", _bubble_ball_text(_BALL_DESC))
	card.set("image_fit_mode", "contain")
	card.set("image_path", "res://bubble/ball_play/assets/ball_card.png")
	card.set("art_bay_enabled", true)
	# The DB marks this old placeholder launch_enabled=false. Install the
	# click area explicitly, independent of that placeholder status.
	_v108_ensure_entry_arrow(card, false)
	var existing: Button = card.get_node_or_null("OpenExistingGame") as Button
	if existing != null:
		existing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		existing.queue_free()
	var hit: Button = card.get_node_or_null("OpenBubbleBall") as Button
	if hit == null:
		hit = Button.new()
		hit.name = "OpenBubbleBall"
		hit.text = ""
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		card.add_child(hit)
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hit.pressed.connect(_bubble_ball_open)
	hit.tooltip_text = _bubble_ball_text(_BALL_TITLE)
	# Keep this hit area above internal artwork and the decorative arrow.
	card.move_child(hit, card.get_child_count() - 1)

func _bubble_ball_open() -> void:
	if _bubble_ball_active or _bubble_ball_transition or _v1051_playing:
		return
	if not _bubble_ball_allowed(_planet_id):
		return
	var scene: PackedScene = load("res://bubble/ball_play/ball_play.tscn") as PackedScene
	if scene == null:
		push_error("MIKA Bubble Ball scene missing")
		return
	var game: Control = scene.instantiate() as Control
	if game == null:
		return
	game.call("configure_planet",_planet_id,_background_path)
	game.name = "BubbleBallOnCurrentPlanet"
	game.z_index = 110
	game.modulate.a = 0.0
	add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.connect("exit_requested",Callable(self,"_bubble_ball_close"))
	_bubble_ball_layer = game
	_bubble_ball_active = true
	_bubble_ball_transition = true
	game.call("set_input_enabled",false)
	var tw: Tween = create_tween()
	_bubble_ball_tween = tw
	tw.set_parallel(true)
	tw.tween_property(scroll,"modulate:a",0.0,0.24)
	tw.tween_property(hud,"modulate:a",0.0,0.24)
	if is_instance_valid(_top_info):
		tw.tween_property(_top_info,"modulate:a",0.0,0.24)
	tw.tween_property(game,"modulate:a",1.0,0.32).set_delay(0.10)
	tw.chain().tween_callback(Callable(self,"_bubble_ball_finish_open"))

func _bubble_ball_finish_open() -> void:
	if not is_instance_valid(_bubble_ball_layer):
		return
	scroll.hide()
	hud.hide()
	if is_instance_valid(_top_info):
		_top_info.hide()
	_bubble_ball_layer.call("set_input_enabled",true)
	_bubble_ball_transition = false

func _bubble_ball_close() -> void:
	if not _bubble_ball_active or _bubble_ball_transition:
		return
	if not is_instance_valid(_bubble_ball_layer):
		_bubble_ball_force_clear()
		return
	_bubble_ball_transition = true
	_bubble_ball_layer.call("set_input_enabled",false)
	scroll.show()
	hud.show()
	scroll.modulate.a = 0.0
	hud.modulate.a = 0.0
	if is_instance_valid(_top_info):
		_top_info.show()
		_top_info.modulate.a = 0.0
	var tw: Tween = create_tween()
	_bubble_ball_tween = tw
	tw.set_parallel(true)
	tw.tween_property(scroll,"modulate:a",1.0,0.24)
	tw.tween_property(hud,"modulate:a",1.0,0.24)
	if is_instance_valid(_top_info):
		tw.tween_property(_top_info,"modulate:a",1.0,0.24)
	tw.tween_property(_bubble_ball_layer,"modulate:a",0.0,0.22)
	tw.chain().tween_callback(Callable(self,"_bubble_ball_finish_close"))

func _bubble_ball_finish_close() -> void:
	if is_instance_valid(_bubble_ball_layer):
		_bubble_ball_layer.queue_free()
	_bubble_ball_layer = null
	_bubble_ball_active = false
	_bubble_ball_transition = false
	_layout_ui()

func _bubble_ball_force_clear() -> void:
	if _bubble_ball_tween != null and _bubble_ball_tween.is_running():
		_bubble_ball_tween.kill()
	if is_instance_valid(_bubble_ball_layer):
		_bubble_ball_layer.queue_free()
	_bubble_ball_layer = null
	_bubble_ball_active = false
	_bubble_ball_transition = false
	scroll.show()
	hud.show()
	scroll.modulate.a = 1.0
	hud.modulate.a = 1.0
	if is_instance_valid(_top_info):
		_top_info.show()
		_top_info.modulate.a = 1.0

# v105.1 uses the SAME full-screen SubViewport technique as MikoMainMenu.
# This is a hidden game-runner, not a new PlanetHub card, selector or menu.

func _v1051_setup_runner() -> void:
	if is_instance_valid(_v1051_game_layer):
		return
	_v1051_game_layer = Control.new()
	_v1051_game_layer.name = "ExistingPlanetGameRunner"
	_v1051_game_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_v1051_game_layer.clip_contents = true
	_v1051_game_layer.visible = false
	_v1051_game_layer.z_index = 100
	add_child(_v1051_game_layer)
	_v1051_game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dark: ColorRect = ColorRect.new()
	dark.name = "FullscreenGameBackdrop"
	dark.color = Color("061225")
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_v1051_game_layer.add_child(dark)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var container: SubViewportContainer = SubViewportContainer.new()
	container.name = "ExistingGameInputForwarding"
	container.stretch = true
	container.stretch_shrink = 1
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	_v1051_game_layer.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_v1051_viewport = SubViewport.new()
	_v1051_viewport.name = "ExistingPlanetGameViewport"
	_v1051_viewport.handle_input_locally = true
	_v1051_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(_v1051_viewport)
	# MIKA_PLANET_NATIVE_BACK_ONLY_V2
	# Planet games own their Back controls. The hub adds NO Back widget.
	var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
	if portal != null and portal.has_signal("game_finished"):
		portal.connect("game_finished", _v1051_return_to_cards)


func _v1051_open_existing_game(game_id: String) -> void:
	if not _story_ch06_stage.is_empty() and (_story_ch06_stage != "math" or game_id != CH06_MATH_ID):
		return
	if not _story_barnard_stage.is_empty() and (_story_barnard_stage != "pizza" or game_id != STORY_BARNARD_PIZZA_ID):
		return
	if not _story_archeon_stage.is_empty() and (_story_archeon_stage != "fossils" or game_id != STORY_ARCHEON_FOSSIL_ID):
		return
	if not _story_runa_stage.is_empty() and (_story_runa_stage != "evolution" or game_id != STORY_RUNA_EVOLUTION_ID):
		return
	if not _story_m31_stage.is_empty():
		var required_game: String = ""
		match _story_m31_stage:
			"pinball": required_game = STORY_M31_PINBALL_ID
			"ball": required_game = STORY_M31_BALL_ID
			"pulses": required_game = STORY_M31_PULSES_ID
		if game_id != required_game:
			return
	if StorySubscriptionGate.paywall_active():
		StorySubscriptionGate.show_notice(self, "game")
		return
	if not _story_earth_stage.is_empty() and (_story_earth_stage != "puzzle" or game_id != "mw__puzzles"):
		return
	var mars_trace: bool = game_id == STORY_MARS_WORD_ID and _planet_id == "mw_p02" and _story_mars_stage == "trace"
	if not _story_mars_stage.is_empty() and not mars_trace:
		return
	if not _story_station_stage.is_empty() and (_story_station_stage != "list" or game_id != "mw__shopping_list"):
		return
	if not _story_talos_stage.is_empty() and (_story_talos_stage != "maze" or game_id != STORY_TALOS_MAZE_ID):
		return
	if not _story_molly_stage.is_empty() and (_story_molly_stage != "tree" or game_id != STORY_MOLLY_TREE_ID):
		return
	if not _story_lmc_station_stage.is_empty() and (_story_lmc_station_stage != "sunbeam" or game_id != STORY_LMC_SUNBEAM_ID):
		return
	if not _story_okea_stage.is_empty() and (_story_okea_stage != "lab" or game_id != STORY_OKEA_SOLUTION_ID):
		return
	if not _story_cela_stage.is_empty() and (_story_cela_stage != "crystals" or game_id != STORY_CELA_CRYSTAL_ID):
		return
	if not _story_lotus_stage.is_empty() and (_story_lotus_stage != "molecule" or game_id != STORY_LOTUS_MOLECULE_ID):
		return
	if _v1051_playing or _planet_id.is_empty():
		return
	var games: Dictionary = _v104_game_database.get("games", {})
	var record: Dictionary = games.get(game_id, {})
	var scene_path: String = STORY_MARS_WORD_SCENE if mars_trace else _mika_planet_scene(game_id, record)
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("Planet game scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_warning("Planet game could not load: " + scene_path)
		return
	var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
	if portal == null or bool(portal.get("active")):
		push_warning("Cannot start planet game: EmbeddedGamePortal is busy or missing")
		return
	if not is_instance_valid(_v1051_game_layer):
		_v1051_setup_runner()
	var instance: Node = packed.instantiate()
	if instance == null:
		return
	if _story_ch06_stage == "math":
		var story_math: Script = load("res://planet_hub/games/neural_math/scripts/MIKAStoryNeuralMathCH06.gd") as Script
		if story_math == null:
			instance.queue_free()
			push_error("CH06: story math script missing")
			return
		instance.set_script(story_math)
		if not instance.has_signal("story_answer_solved"):
			instance.queue_free()
			push_error("CH06: cannot attach story math to native scene")
			return
		instance.connect("story_answer_solved", Callable(self, "_ch06_math_completed"), CONNECT_DEFERRED)
	if _story_m31_stage == "pulses":
		# The regular Electric Impulses scene is unchanged. Its Story-only
		# subclass protects against a touch being delivered again as a synthetic
		# mouse click, and retains 1..4 numeric-key input in the SubViewport.
		var story_pulses_script: Script = load("res://planet_hub/games/electric_impulses/scripts/MIKAStoryPulseInputV1.gd") as Script
		if story_pulses_script == null:
			push_error("Andromeda Story: scoped pulse input script missing")
			instance.queue_free()
			return
		instance.set_script(story_pulses_script)
		if instance.get_script() != story_pulses_script:
			push_error("Andromeda Story: could not attach scoped input handler")
			instance.queue_free()
			return
	if _story_archeon_stage == "fossils":
		# Must be set BEFORE _ready(): this creates exactly three goal slots and
		# three real targets in the existing randomized ten-fossil cave.
		instance.set("story_required_fossils", 3)
		if instance.has_signal("story_fossils_completed"):
			instance.connect("story_fossils_completed", Callable(self, "_story_archeon_fossils_completed"), CONNECT_DEFERRED)
		else:
			push_error("Archeon Story: existing Fossil Hunt has no completion signal")
			instance.queue_free()
			return
	if _story_earth_stage == "puzzle":
		instance.set("story_mission_key", "spaceport_mission")
		if instance.has_signal("story_puzzle_completed"):
			instance.connect("story_puzzle_completed", Callable(self, "_story_earth_puzzle_completed"), CONNECT_DEFERRED)
		else:
			push_error("Existing Earth puzzle has no Story completion signal")
			instance.queue_free()
			return
	if mars_trace:
		if instance.has_signal("story_word_completed"):
			instance.connect("story_word_completed", Callable(self, "_story_mars_word_completed"), CONNECT_DEFERRED)
		else:
			push_error("Mars Story Trace Words has no completion signal")
			instance.queue_free()
			return
	var lang: Node = get_node_or_null("/root/LanguageService")
	if lang != null and lang.has_method("set_locale"):
		var locale: String = str(MobileLocale.language)
		lang.call("set_locale", "pt" if locale == "pt_BR" else locale, false)
	_mouse_scroll_drag = false
	_v1051_playing = true
	scroll.hide()
	hud.hide()
	if is_instance_valid(_top_info):
		_top_info.hide()
	_v1051_game_layer.show()
	_v1051_game_layer.move_to_front()
	portal.call("start_game", scene_path)
	_v1051_viewport.add_child(instance)
	if _story_lotus_stage == "molecule":
		# The native simulator game's shuffled 20-molecule queue is untouched
		# OUTSIDE this story visit. Here only the original H₂O molecule is taught.
		var water: Dictionary = {}
		for candidate in instance.get("_molecules") as Array:
			if candidate is Dictionary and str(candidate.get("id", "")) == "water":
				water = candidate
				break
		if water.is_empty():
			push_error("Lotus Story: water (H₂O) missing from original Molecule Builder")
		else:
			instance.set("_queue", [water])
			instance.set("_round", 0)
			instance.call("_go_to_round")
		for property_name in ["_native_back", "_restart_button", "_previous_button", "_next_button", "_forward_button"]:
			var game_button: BaseButton = instance.get(property_name) as BaseButton
			if is_instance_valid(game_button):
				game_button.hide()
				game_button.disabled = true
		instance.set_process_unhandled_key_input(false)
	if _story_barnard_stage == "pizza":
		# Real native pizza mechanics/voice; no premature Back in the guided arc.
		var native_pizza_back: BaseButton = instance.get("home_button") as BaseButton
		if is_instance_valid(native_pizza_back):
			native_pizza_back.hide()
			native_pizza_back.disabled = true
		instance.set_process_unhandled_key_input(false)
	if _story_archeon_stage == "fossils":
		var fossil_back: BaseButton = instance.get("_native_back") as BaseButton
		if is_instance_valid(fossil_back):
			fossil_back.hide()
			fossil_back.disabled = true
		instance.set_process_unhandled_key_input(false)
	if _story_runa_stage == "evolution":
		var evolution_back: BaseButton = instance.get("_back") as BaseButton
		if is_instance_valid(evolution_back):
			evolution_back.hide()
			evolution_back.disabled = true
		instance.set_process_unhandled_key_input(false)
	if _story_m31_stage == "pinball":
		# Native arena remains unchanged; suppress Back and Escape until one point.
		var pinball_back: BaseButton = instance.get("_back") as BaseButton
		if is_instance_valid(pinball_back):
			pinball_back.hide()
			pinball_back.disabled = true
		instance.set_process_unhandled_key_input(false)
	if _story_m31_stage in ["ball", "pulses"]:
		# Only UI exits are suppressed; actual ball physics / signal taps remain.
		for field_name in ["_mika_back", "exit_button", "_back_button"]:
			var original_exit: BaseButton = instance.get(field_name) as BaseButton
			if is_instance_valid(original_exit):
				original_exit.hide()
				original_exit.disabled = true
		# Pulse script owns keys 1..8/Space and has NO Escape/Reset/Back
		# shortcuts. Don't silence those inputs: the child may enter 4,2 by keys.
		instance.set_process_unhandled_key_input(_story_m31_stage == "pulses")
	if _story_station_stage == "list":
		# The child must finish this original shopping game: no Back/Retry.
		for property_name in ["home_button", "back_button", "again_button"]:
			var native_button: BaseButton = instance.get(property_name) as BaseButton
			if is_instance_valid(native_button):
				native_button.hide()
	if _story_talos_stage == "maze":
		# The original maze and victory dialog remain, but Back/Exit/Replay
		# cannot abandon the required Story task.
		for property_name in ["_back", "_win_exit", "_win_replay"]:
			var maze_button: BaseButton = instance.get(property_name) as BaseButton
			if is_instance_valid(maze_button):
				maze_button.hide()
	if _story_molly_stage == "tree":
		# Preserve all native planting interactions. Only the premature exit
		# is disabled; winning will automatically return to the Hub.
		var native_back: BaseButton = instance.get("_back") as BaseButton
		if is_instance_valid(native_back):
			native_back.hide()
		var named_back: BaseButton = instance.get_node_or_null("GrowTreeBack") as BaseButton
		if is_instance_valid(named_back):
			named_back.hide()
		instance.set_process_unhandled_key_input(false)
	if _story_lmc_station_stage == "sunbeam":
		# Keep the original animated flowers and Reset available, but the
		# Story mission must fill one battery before it may be left.
		var sunbeam_back: BaseButton = instance.get("_back") as BaseButton
		if is_instance_valid(sunbeam_back):
			sunbeam_back.hide()
		instance.set_process_unhandled_key_input(false)
	if _story_okea_stage == "lab":
		# A required three-color lesson cannot be skipped using the game's
		# own Back arrow or Escape shortcut; free-flight Lab is untouched.
		var lab_back: BaseButton = instance.get("_back") as BaseButton
		if is_instance_valid(lab_back):
			lab_back.hide()
		instance.set_process_unhandled_key_input(false)
	if _story_cela_stage == "crystals":
		# Resource Rush movement and rival continue untouched. An exit is only
		# allowed after five actual Mika pickups, never from Back / Escape.
		var rush_exit: BaseButton = instance.get("exit_button") as BaseButton
		if is_instance_valid(rush_exit):
			rush_exit.hide()
			rush_exit.disabled = true
		instance.set_process_unhandled_key_input(false)
	# MIKA_PLANET_STORY_V1_SHARED_ENTRY
	if _story_earth_stage.is_empty() and _story_mars_stage.is_empty() and _story_station_stage.is_empty() and _story_talos_stage.is_empty() and _story_molly_stage.is_empty() and _story_lmc_station_stage.is_empty() and _story_okea_stage.is_empty() and _story_cela_stage.is_empty() and _story_lotus_stage.is_empty() and _story_barnard_stage.is_empty() and _story_archeon_stage.is_empty() and _story_runa_stage.is_empty() and _story_m31_stage.is_empty() and _story_ch06_stage.is_empty():
		var story_overlay: CanvasLayer = load("res://planet_hub/game_stories/planet_story_overlay_v1.gd").new() as CanvasLayer
		story_overlay.set("game_id", game_id)
		instance.add_child(story_overlay)
	_mika_bind_game_exit(instance)
	call_deferred("_mika_refresh_game_exit")


func _v1051_return_to_cards() -> void:
	if _story_ch06_stage in ["math", "math_done"] and not _story_ch06_allow_return:
		return
	if ["pizza", "pizza_done"].has(_story_barnard_stage) and not _story_barnard_allow_return:
		return
	if ["fossils", "fossils_done"].has(_story_archeon_stage) and not _story_archeon_allow_return:
		return
	if ["evolution", "evolution_done"].has(_story_runa_stage) and not _story_runa_allow_return:
		return
	if ["pinball", "pinball_done", "ball", "ball_done", "pulses", "pulses_done"].has(_story_m31_stage) and not _story_m31_allow_return:
		return
	if ["list", "list_done"].has(_story_station_stage) and not _story_station_allow_return:
		return
	if ["maze", "maze_done"].has(_story_talos_stage) and not _story_talos_allow_return:
		return
	if ["tree", "tree_done"].has(_story_molly_stage) and not _story_molly_allow_return:
		return
	if ["sunbeam", "sunbeam_done"].has(_story_lmc_station_stage) and not _story_lmc_station_allow_return:
		return
	if ["lab", "lab_done"].has(_story_okea_stage) and not _story_okea_allow_return:
		return
	if ["crystals", "crystals_done"].has(_story_cela_stage) and not _story_cela_allow_return:
		return
	if ["molecule", "molecule_done"].has(_story_lotus_stage) and not _story_lotus_allow_return:
		return
	if _station_race_active:
		_mika_station_race_close()
		return
	if not _v1051_playing:
		return
	_v1051_playing = false
	var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
	if portal != null:
		portal.call("stop_game")
	if is_instance_valid(_v1051_viewport):
		for instance in _v1051_viewport.get_children():
			_v1051_viewport.remove_child(instance)
			instance.queue_free()
	_v1051_game_layer.hide()
	scroll.show()
	hud.show()
	if is_instance_valid(_top_info):
		_top_info.show()
	_apply_story_earth_stage()
	_layout_ui()


func _story_archeon_fossils_completed() -> void:
	if _story_archeon_stage != "fossils" or not _v1051_playing or _story_archeon_finish_pending:
		return
	_story_archeon_finish_pending = true
	_story_archeon_stage = "fossils_done"
	_story_archeon_allow_return = true
	_v1051_return_to_cards()
	_story_archeon_allow_return = false
	story_archeon_fossils_solved.emit()


func _story_mars_word_completed(_word: String) -> void:
	if _story_mars_stage != "trace" or not _v1051_playing:
		return
	_v1051_return_to_cards()
	_story_mars_stage = "trace_done"
	_apply_story_earth_stage()
	story_mars_word_solved.emit()


func _story_earth_puzzle_completed(puzzle_key: String) -> void:
	if _story_earth_stage != "puzzle" or puzzle_key != "spaceport_mission":
		return
	_v1051_return_to_cards()
	story_earth_puzzle_solved.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if _story_ch06_stage in ["math", "math_done"]:
		return
	if _story_earth_stage == "puzzle" or ["list", "list_done"].has(_story_station_stage) or ["maze", "maze_done"].has(_story_talos_stage) or ["tree", "tree_done"].has(_story_molly_stage) or ["sunbeam", "sunbeam_done"].has(_story_lmc_station_stage) or ["crystals", "crystals_done"].has(_story_cela_stage) or ["molecule", "molecule_done"].has(_story_lotus_stage) or ["pizza", "pizza_done"].has(_story_barnard_stage) or ["fossils", "fossils_done"].has(_story_archeon_stage) or ["evolution", "evolution_done"].has(_story_runa_stage) or ["pinball", "pinball_done"].has(_story_m31_stage):
		return
	if _v1051_playing and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_v1051_return_to_cards()
		get_viewport().set_input_as_handled()


# v108-existing-card-voice -- no new cards or buttons that launch scenes.
func _v108_ensure_entry_arrow(card: Control, is_representative: bool) -> void:
	if card == null or card.get_node_or_null("MikaEntryArrow") != null:
		return
	var arrow: Control = V108_CARD_ARROW_SCRIPT.new() as Control
	if arrow == null:
		return
	arrow.set("representative_mode", is_representative)
	card.add_child(arrow)

# MIKA_STATION_RACING_NATIVE_V2 — separate game session, no educational portal.
func _mika_station_race_add_card() -> void:
	if not bool(_meta.get("is_station", false)):
		return
	if not _planet_id in ["st_mw", "st_lmc", "st_smc", "st_ngc6822", "st_m31", "st_m33"]:
		return
	if not ResourceLoader.exists("res://space_racing/SpaceRace.tscn"):
		push_warning("Space Racing scene not installed")
		return
	var card: Control = V104_GAME_CARD_SCRIPT.new() as Control
	card.name = "GamePreview_station__space_race"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set("card_title", _v104_card_localized({"ru":"Космические гонки", "en":"Space Racing", "fr":"Course spatiale", "de":"Weltraumrennen", "es":"Carrera espacial", "pt_BR":"Corrida espacial"}))
	card.set("card_subtitle", "")
	card.set("card_description", _v104_card_localized({"ru":"Три круга против четырёх соперников.", "en":"Three laps against four rivals.", "fr":"Trois tours contre quatre adversaires.", "de":"Drei Runden gegen vier Gegner.", "es":"Tres vueltas contra cuatro rivales.", "pt_BR":"Três voltas contra quatro rivais."}))
	card.set("accent", Color("55cdff"))
	card.set("image_fit_mode", "contain")
	card.set("image_path", "res://planet_hub/cards/game_icons/station__space_race.png")
	card.set("art_bay_enabled", true)
	card_row.add_child(card)
	_v104_game_cards.append(card)
	_v108_ensure_entry_arrow(card, false)
	var button: Button = Button.new()
	button.name = "OpenStationRace"
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = str(card.get("card_title"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_mika_station_race_open)


func _mika_station_race_open() -> void:
	if _v1051_playing or _station_race_active or not bool(_meta.get("is_station", false)):
		return
	var scene_path: String = "res://space_racing/SpaceRace.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("Station Racing scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return
	if not is_instance_valid(_v1051_game_layer):
		_v1051_setup_runner()
	if not is_instance_valid(_v1051_viewport) or _v1051_viewport.get_child_count() != 0:
		return
	var instance: Node = packed.instantiate()
	if instance == null or not instance.has_signal("exit_requested"):
		if instance != null:
			instance.queue_free()
		push_error("Station Racing: invalid game scene or missing exit_requested")
		return
	instance.connect("exit_requested", Callable(self, "_mika_station_race_close"), CONNECT_DEFERRED)
	# RaceSession.take() consumes this before the game first frame.
	get_tree().root.set_meta("mika_race_session_v8", {
		"planet": _planet_id,
		"system": str(_meta.get("system_id", "mw")),
		"difficulty": "normal",
		"embedded": true,
		"return_scene": "res://scenes/main.tscn"
	})
	_mouse_scroll_drag = false
	_station_race_active = true
	_v1051_playing = true
	scroll.hide()
	hud.hide()
	if is_instance_valid(_top_info):
		_top_info.hide()
	_v1051_game_layer.show()
	_v1051_game_layer.move_to_front()
	_v1051_viewport.add_child(instance)


func _mika_station_race_close() -> void:
	if not _station_race_active:
		return
	_station_race_active = false
	_v1051_playing = false
	if get_tree().root.has_meta("mika_race_session_v8"):
		get_tree().root.remove_meta("mika_race_session_v8")
	if is_instance_valid(_v1051_viewport):
		for instance in _v1051_viewport.get_children():
			_v1051_viewport.remove_child(instance)
			instance.queue_free()
	_v1051_game_layer.hide()
	scroll.show()
	hud.show()
	if is_instance_valid(_top_info):
		_top_info.show()
	_layout_ui()


func set_story_ch06_stage(stage: String) -> void:
	if not stage in ["", "math", "launch"]:
		push_error("CH06: invalid hub stage")
		return
	_story_ch06_stage = stage if _planet_id == "m33_p04" else ""
	_story_ch06_allow_return = false
	if stage.is_empty() and _is_setup:
		_apply_card_content()
	_apply_story_earth_stage()
	if _story_ch06_stage == "math":
		var card: Control = card_row.get_node_or_null("GamePreview_" + CH06_MATH_ID) as Control
		if card == null or card.get_node_or_null("OpenExistingGame") == null:
			push_error("CH06: native Neural Math card is not launchable")

func _ch06_math_completed() -> void:
	if _story_ch06_stage != "math" or not _v1051_playing:
		return
	_story_ch06_stage = "math_done"
	_story_ch06_allow_return = true
	_v1051_return_to_cards()
	_story_ch06_allow_return = false
	story_ch06_math_solved.emit()
