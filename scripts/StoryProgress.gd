extends RefCounted
## Permanent chapter progress is separate from the active run and its safe resume point.
## A restart resumes a supported phase; individual cuts, half-completed games and flight
## tweens are not serialized. Fuel/crystal storage is unchanged.

const MODE_FILE: String = "user://miko_mode.cfg"
const CHECKPOINT_FILE: String = "user://mika_story_checkpoint_v1.cfg"
const FIRST_BEAT: String = "first_page"
const KNOWN_ARCS: Array[String] = [
	"prologue", "earth", "mars", "station",
	"chapter02", "chapter02_molly", "chapter02_station", "chapter02_departure",
	"chapter03", "chapter03_okea", "chapter03_cela", "chapter03_lotus",
	"chapter04", "chapter04_archeon", "chapter04_runa", "chapter05",
	"chapter05_phasis", "chapter05_station", "chapter05_archive", "chapter06",
	"chapter06_lentis", "chapter06_gate", "chapter07", "chapter07_living_world",
	"chapter07_choice", "chapter07_return"
]
const ARC_START_BEATS: Dictionary = {
	"prologue": "first_page",
	"earth": "navigation_open",
	"mars": "mars_arrival_panels",
	"station": "station_arrival_panels",
	"chapter02": "lmc_arrived",
	"chapter02_molly": "molly_arrival_panels",
	"chapter02_station": "lmc_station_arrival_panels",
	"chapter02_departure": "lmc_station_map_smc",
	"chapter03": "smc_arrived",
	"chapter03_okea": "okea_arrival_panels",
	"chapter03_cela": "cela_arrival_panels",
	"chapter03_lotus": "lotus_arrival_panels",
	"chapter04": "barnard_arrived",
	"chapter04_archeon": "archeon_arrival_panels",
	"chapter04_runa": "runa_arrival_panels",
	"chapter05": "m31_arrived",
	"chapter05_phasis": "m31_landing_reactions",
	"chapter05_station": "m31_station_intro_panels",
	"chapter05_archive": "m31_station_after_ball_panels",
	"chapter06": "m33_arrived",
	"chapter06_lentis": "m33_lentis_panels",
	"chapter06_gate": "m33_station_arrived",
	"chapter07": "m33_crossroads_arrived",
	"chapter07_living_world": "crossroads_finale_panels",
	"chapter07_choice": "crossroads_finale_choice",
	"chapter07_return": "crossroads_ending1_returned"
}
const ARC_COMPLETE_BEATS: Dictionary = {
	"prologue": "navigation_open",
	"earth": "mars_arrival_panels",
	"mars": "station_arrival_panels",
	"station": "lmc_arrived",
	"chapter02": "molly_arrival_panels",
	"chapter02_molly": "lmc_station_arrival_panels",
	"chapter02_station": "lmc_station_map_smc",
	"chapter02_departure": "smc_arrived",
	"chapter03": "okea_arrival_panels",
	"chapter03_okea": "cela_arrival_panels",
	"chapter03_cela": "lotus_arrival_panels",
	"chapter03_lotus": "barnard_arrived",
	"chapter04": "archeon_arrival_panels",
	"chapter04_archeon": "runa_arrival_panels",
	"chapter04_runa": "m31_arrived",
	"chapter05": "m33_arrived",
	"chapter05_phasis": "m31_station_intro_panels",
	"chapter05_station": "m31_station_after_ball_panels",
	"chapter05_archive": "m33_arrived",
	"chapter06": "m33_lentis_panels",
	"chapter06_lentis": "m33_station_arrived",
	"chapter06_gate": "m33_crossroads_arrived",
	"chapter07": "crossroads_finale_panels",
	"chapter07_living_world": "crossroads_finale_choice",
	"chapter07_choice": "crossroads_ending1_returned",
	"chapter07_return": "crossroads_ending1_returned"
}
const VALID_BEATS: Array[String] = [
	"first_page", "wormhole_panel", "flight_to_earth",
	"earth_view_panels", "await_simulator_card", "inside_simulator",
	"after_simulator", "navigation_open", "navigation_earth",
	"navigation_selected", "earth_landing_panels", "earth_puzzle",
	"earth_after_puzzle_panels", "earth_launch", "earth_departure_panels",
	"earth_departed", "mars_navigation_open", "mars_navigation_target",
	"mars_navigation_selected", "mars_asteroid_approach", "mars_asteroid_stun",
	"mars_fuel_collect", "mars_fuel_absorbing", "mars_navigation_resume", "mars_arrived",
	"mars_arrival_panels", "mars_word_trace", "mars_word_done",
	"mars_story_after_word_panels", "mars_launch", "mars_departure_panels", "mars_departed",
	"free_prologue_complete", "station_arrival_panels", "station_hub_list",
	"station_hub_launch", "station_map_lmc", "station_warp_out",
	"station_final_panel", "lmc_arrived",
	# Chapter 2 / Talos opens on arrival in the Large Magellanic Cloud.
	# The individual Talos cuts and its minigame are runtime-only.
	"talos_arrival_panels", "talos_hub_maze", "talos_hub_launch",
	"talos_departure_panel", "talos_departed",
	# Molly landing starts the second durable episode; its minigame is runtime.
	"molly_arrival_panels", "molly_hub_tree", "molly_final_panel",
	"molly_hub_launch", "molly_departed",
	# LMC station landing and the post-launch hyperspace tutorial have their
	# own episode saves; the Sunbeam game and camera cuts remain runtime-only.
	"lmc_station_arrival_panels", "lmc_station_hub_sunbeam",
	"lmc_station_hub_launch", "lmc_station_departed",
	"lmc_station_map_smc", "lmc_station_warp_smc", "smc_arrived",
	# The original PDF 3-1 starts Chapter 3 at the SMC arrival. Okea landing
	# begins the next durable episode; each comic cut and each recipe is runtime.
	"smc_intro_panels", "okea_arrival_panels", "okea_hub_lab",
	"okea_after_lab_panels", "okea_hub_launch", "okea_departure_panel",
	"okea_departed",
	# Cela is the next durable landing; crystal collecting and individual PDF
	# frames are runtime beats so cold loads restart at the real planet arrival.
	"cela_arrival_panels", "cela_hub_crystals", "cela_after_crystals_panels",
	"cela_bubble_panels", "cela_hub_launch", "cela_departed",
	# Chapter 3 / Living Archive station: restore from the station's beginning.
	"lotus_arrival_panels", "lotus_hub_molecule", "lotus_after_molecule_panels",
	"lotus_hub_launch", "lotus_departure_panel", "lotus_map_barnard",
	"lotus_warp_barnard", "barnard_arrived",
	"barnard_prearrival_panels", "barnard_warp_resume", "barnard_pirate_intercept",
	"barnard_threat_panels", "barnard_pirate_escort", "barnard_pirate_landing",
	"barnard_station_panels", "barnard_station_hub_pizza",
	"barnard_escape_panel", "barnard_station_hub_launch", "barnard_station_departed",
	"archeon_arrival_panels", "archeon_hub_fossils", "archeon_after_fossils_panels",
	"archeon_hub_launch", "archeon_departure_panels", "archeon_departed",
	# Runa's original PDF4-4 / PDF4-5, five native Evolution chains,
	# followed by the unscripted next-chapter entry in Andromeda.
	"runa_arrival_panels", "runa_hub_evolution", "runa_after_evolution_panels",
	"runa_hub_launch", "runa_departed", "runa_map_andromeda",
	"runa_warp_andromeda", "m31_arrived",
	# Chapter 5 preview: transient cut-scenes and native flight, all reload at m31_arrived.
	"m31_opening_panels", "m31_lost_drift", "m31_gravity_reveal",
	"m31_gravity_pull", "m31_near_planet_panels", "m31_final_approach",
	"m31_gravity_landing", "m31_landing_reactions",
	"m31_before_pinball", "m31_pinball_preview",
	"m31_hub_pinball", "m31_after_pinball_panels", "m31_hub_launch", "m31_departed",
	# Native M31 station arrival, two original games and the WIP Triangulum handoff.
	"m31_station_intro_panels", "m31_station_hub_ball", "m31_station_after_ball_panels",
	"m31_station_hub_pulses", "m31_station_after_pulses_panels", "m31_station_hub_launch",
	"m31_station_departed", "m31_map_triangulum", "m31_warp_triangulum",
	"m33_arrived", "m33_story_preview",
	"m33_intro_panels", "m33_to_lentis", "m33_lentis_panels", "m33_hub_math", "m33_after_math_panels", "m33_hub_launch", "m33_departed", "m33_station_arrived", "m33_gate_rebus", "m33_gate_exit_panels", "m33_gate_transfer", "m33_crossroads_arrived", "crossroads_finale_panels", "crossroads_finale_choice",
	"crossroads_ending1_panels", "crossroads_ending1_returned",
	"crossroads_ending2_panels", "crossroads_ending2_note", "crossroads_ending2_draw", "crossroads_ending2_returned"
]

# MIKA_STORY_ACTIVE_ROUTE_V1: current-run state is separate from permanent unlocks.
const LOCAL_STORY_ROUTES: Dictionary = {
	"m33_crossroads_arrived": {"region": "crossroads", "target": "crossroads_core", "guide": "ch07_living_world", "keep_selected": false},
	# MIKA_CH06_NATIVE_ROUTE_V1
	"m33_to_lentis": {"region": "m33", "target": "m33_p04", "guide": "ch06_lentis", "keep_selected": false},
	"m33_departed": {"region": "m33", "target": "st_m33", "guide": "ch06_gate", "keep_selected": false},
	"free_prologue_complete": {"region": "mw", "target": "st_mw", "guide": "station", "keep_selected": true},
	"lmc_arrived": {"region": "lmc", "target": "lmc_p02", "guide": "talos", "keep_selected": false},
	"talos_departed": {"region": "lmc", "target": "lmc_p03", "guide": "molly", "keep_selected": false},
	"molly_departed": {"region": "lmc", "target": "st_lmc", "guide": "station", "keep_selected": true},
	"smc_arrived": {"region": "smc", "target": "smc_p01", "guide": "okea", "keep_selected": false},
	"okea_departed": {"region": "smc", "target": "smc_p02", "guide": "cela", "keep_selected": false},
	"cela_departed": {"region": "smc", "target": "st_smc", "guide": "lotus", "keep_selected": true},
	"barnard_station_departed": {"region": "ngc6822", "target": "ngc6822_p01", "guide": "archeon", "keep_selected": false},
	"archeon_departed": {"region": "ngc6822", "target": "ngc6822_p06", "guide": "runa", "keep_selected": false},
	"m31_departed": {"region": "m31", "target": "st_m31", "guide": "station", "keep_selected": true}
}
const GALAXY_STORY_ROUTES: Dictionary = {
	"station_map_lmc": {"region": "mw", "target": "lmc"},
	"lmc_station_map_smc": {"region": "lmc", "target": "smc"},
	"lotus_map_barnard": {"region": "smc", "target": "ngc6822"},
	"runa_map_andromeda": {"region": "ngc6822", "target": "m31"},
	"m31_map_triangulum": {"region": "m31", "target": "m33"}
}
# Restartable points; in-progress animation/minigame state is intentionally excluded.
const SAFE_RESUME_ANCHORS: Dictionary = {
	"crossroads_ending2_panels": ["crossroads", "crossroads_core"],
	"crossroads_ending2_note": ["crossroads", "crossroads_core"],
	"crossroads_ending2_draw": ["crossroads", "crossroads_core"],
	"crossroads_ending2_returned": ["m33", "m33_p04"],
	"crossroads_ending1_panels": ["crossroads", "crossroads_core"],
	"crossroads_ending1_returned": ["m33", "m33_p04"],
	"m33_crossroads_arrived": ["crossroads", "crossroads_core"],
	"crossroads_finale_panels": ["crossroads", "crossroads_core"],
	"crossroads_finale_choice": ["crossroads", "crossroads_core"],
	"m33_lentis_panels": ["m33", "m33_p04"],
	"m33_hub_math": ["m33", "m33_p04"],
	"m33_after_math_panels": ["m33", "m33_p04"],
	"m33_hub_launch": ["m33", "m33_p04"],
	"m33_departed": ["m33", "m33_p04"],
	"m33_station_arrived": ["m33", "st_m33"],
	"m33_gate_rebus": ["m33", "st_m33"],
	"m33_gate_exit_panels": ["m33", "st_m33"],
	"m33_gate_transfer": ["m33", "st_m33"],
	"earth_landing_panels": ["mw", "mw_p01"],
	"earth_puzzle": ["mw", "mw_p01"],
	"earth_after_puzzle_panels": ["mw", "mw_p01"],
	"earth_launch": ["mw", "mw_p01"],
	"mars_arrival_panels": ["mw", "Mars"],
	"mars_word_trace": ["mw", "Mars"],
	"mars_word_done": ["mw", "Mars"],
	"mars_story_after_word_panels": ["mw", "Mars"],
	"mars_launch": ["mw", "Mars"],
	"free_prologue_complete": ["mw", "Mars"],
	"station_arrival_panels": ["mw", "st_mw"],
	"station_hub_list": ["mw", "st_mw"],
	"station_hub_launch": ["mw", "st_mw"],
	"station_map_lmc": ["mw", "st_mw"],
	"talos_arrival_panels": ["lmc", "lmc_p02"],
	"talos_hub_maze": ["lmc", "lmc_p02"],
	"talos_hub_launch": ["lmc", "lmc_p02"],
	"talos_departed": ["lmc", "lmc_p02"],
	"molly_arrival_panels": ["lmc", "lmc_p03"],
	"molly_hub_tree": ["lmc", "lmc_p03"],
	"molly_final_panel": ["lmc", "lmc_p03"],
	"molly_hub_launch": ["lmc", "lmc_p03"],
	"molly_departed": ["lmc", "lmc_p03"],
	"lmc_station_arrival_panels": ["lmc", "st_lmc"],
	"lmc_station_hub_sunbeam": ["lmc", "st_lmc"],
	"lmc_station_hub_launch": ["lmc", "st_lmc"],
	"lmc_station_map_smc": ["lmc", "st_lmc"],
	"okea_arrival_panels": ["smc", "smc_p01"],
	"okea_hub_lab": ["smc", "smc_p01"],
	"okea_after_lab_panels": ["smc", "smc_p01"],
	"okea_hub_launch": ["smc", "smc_p01"],
	"okea_departed": ["smc", "smc_p01"],
	"cela_arrival_panels": ["smc", "smc_p02"],
	"cela_hub_crystals": ["smc", "smc_p02"],
	"cela_after_crystals_panels": ["smc", "smc_p02"],
	"cela_bubble_panels": ["smc", "smc_p02"],
	"cela_hub_launch": ["smc", "smc_p02"],
	"cela_departed": ["smc", "smc_p02"],
	"lotus_arrival_panels": ["smc", "st_smc"],
	"lotus_hub_molecule": ["smc", "st_smc"],
	"lotus_after_molecule_panels": ["smc", "st_smc"],
	"lotus_hub_launch": ["smc", "st_smc"],
	"lotus_map_barnard": ["smc", "st_smc"],
	"barnard_station_panels": ["ngc6822", "st_ngc6822"],
	"barnard_station_hub_pizza": ["ngc6822", "st_ngc6822"],
	"barnard_escape_panel": ["ngc6822", "st_ngc6822"],
	"barnard_station_hub_launch": ["ngc6822", "st_ngc6822"],
	"barnard_station_departed": ["ngc6822", "st_ngc6822"],
	"archeon_arrival_panels": ["ngc6822", "ngc6822_p01"],
	"archeon_hub_fossils": ["ngc6822", "ngc6822_p01"],
	"archeon_after_fossils_panels": ["ngc6822", "ngc6822_p01"],
	"archeon_hub_launch": ["ngc6822", "ngc6822_p01"],
	"archeon_departed": ["ngc6822", "ngc6822_p01"],
	"runa_arrival_panels": ["ngc6822", "ngc6822_p06"],
	"runa_hub_evolution": ["ngc6822", "ngc6822_p06"],
	"runa_after_evolution_panels": ["ngc6822", "ngc6822_p06"],
	"runa_hub_launch": ["ngc6822", "ngc6822_p06"],
	"runa_map_andromeda": ["ngc6822", "ngc6822_p06"],
	"m31_landing_reactions": ["m31", "m31_p03"],
	"m31_hub_pinball": ["m31", "m31_p03"],
	"m31_after_pinball_panels": ["m31", "m31_p03"],
	"m31_hub_launch": ["m31", "m31_p03"],
	"m31_departed": ["m31", "m31_p03"],
	"m31_station_intro_panels": ["m31", "st_m31"],
	"m31_station_hub_ball": ["m31", "st_m31"],
	"m31_station_after_ball_panels": ["m31", "st_m31"],
	"m31_station_hub_pulses": ["m31", "st_m31"],
	"m31_station_after_pulses_panels": ["m31", "st_m31"],
	"m31_station_hub_launch": ["m31", "st_m31"],
	"m31_map_triangulum": ["m31", "st_m31"]
}
const EXTRA_SAFE_RESUME_BEATS: Array[String] = ["navigation_earth", "navigation_selected", "mars_navigation_open", "mars_navigation_target", "mars_navigation_resume", "m33_intro_panels", "m33_to_lentis", "m33_crossroads_arrived"]

static func local_story_route(beat: String) -> Dictionary:
	return LOCAL_STORY_ROUTES.get(beat, {}) as Dictionary

static func galaxy_story_route(beat: String) -> Dictionary:
	return GALAXY_STORY_ROUTES.get(beat, {}) as Dictionary

static func safe_resume_anchor(beat: String) -> Array:
	return SAFE_RESUME_ANCHORS.get(beat, []) as Array

static func _is_safe_resume(beat: String) -> bool:
	return VALID_BEATS.has(beat) and (ARC_START_BEATS.values().has(beat) or SAFE_RESUME_ANCHORS.has(beat) or EXTRA_SAFE_RESUME_BEATS.has(beat))

static var _runtime_story_beat: String = ""
static var _runtime_replay_beat: String = ""


# MIKA_CH06_CH07_ARC_CHECKPOINTS_V1: both ending branches share one final entry.
static func _chapter_checkpoint_for(beat: String) -> String:
	if beat in ["crossroads_ending1_returned", "crossroads_ending2_returned"]:
		return "crossroads_ending1_returned"
	if beat in ["crossroads_ending1_panels", "crossroads_ending2_panels", "crossroads_ending2_note", "crossroads_ending2_draw"]:
		return "crossroads_finale_choice"
	# Convert legacy per-frame saves to the nearest previously reached chapter
	# start. Only the chapter boundary is restored after a cold launch.
	var index: int = VALID_BEATS.find(beat)
	if index < 0:
		return FIRST_BEAT
	var chapter_beat: String = FIRST_BEAT
	for arc_id in KNOWN_ARCS:
		var candidate: String = str(ARC_START_BEATS[arc_id])
		if VALID_BEATS.find(candidate) <= index:
			chapter_beat = candidate
	return chapter_beat

static func read_mode() -> String:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(MODE_FILE) != OK:
		return "story"
	return "free_world" if str(cfg.get_value("game", "mode", "story")) == "free_world" else "story"

static func write_mode(mode: String) -> bool:
	if mode != "story" and mode != "free_world":
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(MODE_FILE)
	cfg.set_value("game", "mode", mode)
	if mode == "free_world":
		_runtime_story_beat = ""
		_runtime_replay_beat = ""
		# Free World never carries an unfinished chapter replay. Re-entering
		# Story resumes the latest durable chapter, not a hidden replay lane.
		finish_replay()
	var result: int = cfg.save(MODE_FILE)
	if result != OK:
		push_warning("Could not save game mode: " + str(result))
	return result == OK

static func read_beat() -> String:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CHECKPOINT_FILE) != OK:
		return FIRST_BEAT
	var section: String = "replay" if bool(cfg.get_value("replay", "active", false)) else "story"
	var current: String = _runtime_replay_beat if section == "replay" else _runtime_story_beat
	if VALID_BEATS.has(current):
		return current
	var resume_beat: String = str(cfg.get_value(section, "resume_beat", ""))
	if _is_safe_resume(resume_beat):
		return resume_beat
	var beat: String = str(cfg.get_value(section, "beat", FIRST_BEAT))
	if beat in ["crossroads_ending1_returned", "crossroads_ending2_returned"]:
		return beat
	return _chapter_checkpoint_for(beat)


static func _main_checkpoint_from_config(cfg: ConfigFile) -> String:
	# Older builds stored all final chapters under m33_arrived. Prefer the
	# actual durable main resume phase, not the replay lane or high-water mark.
	var resume: String = str(cfg.get_value("story", "resume_beat", ""))
	if _is_safe_resume(resume) and VALID_BEATS.find(resume) >= VALID_BEATS.find("m33_arrived"):
		return _chapter_checkpoint_for(resume)
	var beat: String = str(cfg.get_value("story", "beat", FIRST_BEAT))
	return _chapter_checkpoint_for(beat)

static func read_main_beat() -> String:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CHECKPOINT_FILE) != OK:
		return FIRST_BEAT
	return _main_checkpoint_from_config(cfg)

static func _saved_ending_return(cfg: ConfigFile) -> String:
	# Do not infer completion from linear beat order: ending 2 comes after
	# ending 1 in VALID_BEATS, but the two are mutually exclusive branches.
	var selected: String = str(cfg.get_value("ending", "selected", ""))
	if selected == "ending_1":
		return "crossroads_ending1_returned"
	if selected == "ending_2":
		return "crossroads_ending2_returned"
	for key in ["resume_beat", "active_beat", "beat"]:
		var saved: String = str(cfg.get_value("story", key, ""))
		if saved in ["crossroads_ending1_returned", "crossroads_ending2_returned"]:
			return saved
	return ""


# A completed branch is distinct from the historical high-water mark.
static func completed_ending_beat() -> String:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CHECKPOINT_FILE) != OK:
		return ""
	return _saved_ending_return(cfg)


static func _history_index(cfg: ConfigFile) -> int:
	var furthest: int = 0
	for key in ["beat", "active_beat", "resume_beat", "furthest_beat"]:
		furthest = maxi(furthest, VALID_BEATS.find(str(cfg.get_value("story", key, FIRST_BEAT))))
	return furthest

static func _main_reached(beat: String) -> bool:
	var first: int = VALID_BEATS.find(beat)
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	return first >= 0 and _history_index(cfg) >= first

static func arc_for_beat(beat: String) -> String:
	var checkpoint: String = _chapter_checkpoint_for(beat)
	for arc_id in KNOWN_ARCS:
		if str(ARC_START_BEATS[arc_id]) == checkpoint:
			return arc_id
	return "prologue"

static func current_arc() -> String:
	return arc_for_beat(read_beat())

static func save_beat(beat: String) -> bool:
	if not VALID_BEATS.has(beat):
		push_warning("Unknown story checkpoint: " + beat)
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	var section: String = "replay" if bool(cfg.get_value("replay", "active", false)) else "story"
	if section == "replay":
		_runtime_replay_beat = beat
	else:
		_runtime_story_beat = beat
	# Historical high-water mark never decreases, even in an older replay.
	var furthest_index: int = maxi(_history_index(cfg), VALID_BEATS.find(beat))
	cfg.set_value("story", "furthest_beat", VALID_BEATS[furthest_index])
	if section == "replay":
		cfg.set_value("replay", "arc", arc_for_beat(beat))
	# Keep the active run's last phase and last restartable phase in its own lane.
	# Do not overwrite the historical chapter checkpoint for intermediate beats.
	cfg.set_value("story", "active_state_schema", 1)
	cfg.set_value(section, "active_beat", beat)
	if _is_safe_resume(beat):
		cfg.set_value(section, "resume_beat", beat)
	if ARC_START_BEATS.values().has(beat):
		cfg.set_value("story", "schema", 1)
		cfg.set_value(section, "beat", beat)
	if section == "replay" and ARC_START_BEATS.values().has(beat):
		# Replaying an earlier section must never erase progress. But if the
		# child actually reaches a NEW chapter for the first time, unlock it.
		var main_checkpoint: String = _main_checkpoint_from_config(cfg)
		if VALID_BEATS.find(beat) > VALID_BEATS.find(main_checkpoint):
			cfg.set_value("story", "beat", beat)
			cfg.set_value("story", "resume_beat", beat)
			cfg.set_value("story", "active_beat", beat)
	# Both finale branches are durable; a finished replay becomes the active ending.
	if beat in ["crossroads_ending1_returned", "crossroads_ending2_returned"]:
		cfg.set_value("ending", "selected", "ending_2" if beat == "crossroads_ending2_returned" else "ending_1")
		cfg.set_value("ending", "mika_onboard", beat == "crossroads_ending1_returned")
		cfg.set_value("ending", "crew_lead", "companions" if beat == "crossroads_ending2_returned" else "mika")
		cfg.set_value("arcs", "chapter06_completed", true)
		cfg.set_value("story", "active_beat", beat)
		cfg.set_value("story", "resume_beat", beat)
		cfg.set_value("story", "beat", beat)
		cfg.set_value("arcs", "chapter07_choice_completed", true)
		cfg.set_value("arcs", "chapter07_return_unlocked", true)
		if cfg.has_section("replay"):
			cfg.erase_section("replay")
		_runtime_story_beat = beat
		_runtime_replay_beat = ""
	var result: int = cfg.save(CHECKPOINT_FILE)
	if result != OK:
		push_warning("Could not save story checkpoint: " + str(result))
	return result == OK

static func restart_story() -> bool:
	# A new run rewinds the story, not permanent achievements.
	# Preserve the main checkpoint and play from the beginning in the replay lane.
	_runtime_story_beat = ""
	_runtime_replay_beat = ""
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	var historical: int = _history_index(cfg)
	cfg.set_value("story", "furthest_beat", VALID_BEATS[historical])
	if historical == 0:
		cfg.set_value("story", "beat", FIRST_BEAT)
		cfg.set_value("story", "active_beat", FIRST_BEAT)
		cfg.set_value("story", "resume_beat", FIRST_BEAT)
		if cfg.has_section("replay"):
			cfg.erase_section("replay")
		return cfg.save(CHECKPOINT_FILE) == OK
	_runtime_replay_beat = FIRST_BEAT
	cfg.set_value("replay", "active", true)
	cfg.set_value("replay", "arc", "prologue")
	cfg.set_value("replay", "beat", FIRST_BEAT)
	cfg.set_value("replay", "active_beat", FIRST_BEAT)
	cfg.set_value("replay", "resume_beat", FIRST_BEAT)
	return cfg.save(CHECKPOINT_FILE) == OK


static func unlock_region(region_id: String) -> bool:
	# Galaxy visibility is saved when its story launch tutorial reaches the
	# map. The chapter entry itself unlocks only on ARRIVAL in that galaxy.
	if not ["lmc", "smc", "ngc6822", "m31", "m33", "crossroads"].has(region_id):
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	cfg.set_value("regions", region_id + "_unlocked", true)
	return cfg.save(CHECKPOINT_FILE) == OK


static func is_region_unlocked(region_id: String) -> bool:
	if not ["lmc", "smc", "ngc6822", "m31", "m33", "crossroads"].has(region_id):
		return false
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CHECKPOINT_FILE) != OK:
		return false
	var milestones: Dictionary = {
		"lmc": "station_map_lmc", "smc": "lmc_station_map_smc",
		"ngc6822": "lotus_map_barnard", "m31": "runa_map_andromeda",
		"m33": "m31_map_triangulum", "crossroads": "m33_crossroads_arrived"
	}
	var milestone: String = str(milestones.get(region_id, ""))
	var milestone_index: int = VALID_BEATS.find(milestone)
	return bool(cfg.get_value("regions", region_id + "_unlocked", false)) or (milestone_index >= 0 and _history_index(cfg) >= milestone_index)


static func story_bubble_joined() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CHECKPOINT_FILE) != OK:
		return false
	return bool(cfg.get_value("story", "bubble_joined", false)) or _history_index(cfg) >= VALID_BEATS.find("station_arrival_panels")


static func mark_story_bubble_joined() -> bool:
	# Called once after the native takeoff from Mars, never before the encounter.
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	cfg.set_value("story", "bubble_joined", true)
	var result: int = cfg.save(CHECKPOINT_FILE)
	if result != OK:
		push_warning("Could not save Bubble's story unlock: " + str(result))
	return result == OK


static func story_bubble_intro_done() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CHECKPOINT_FILE) != OK:
		return false
	return bool(cfg.get_value("story", "bubble_intro_done", false))


static func mark_story_bubble_intro_done() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	cfg.set_value("story", "bubble_intro_done", true)
	return cfg.save(CHECKPOINT_FILE) == OK


static func story_station_navigation_used() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(CHECKPOINT_FILE) != OK:
		return false
	return bool(cfg.get_value("story", "station_navigation_used", false))


static func mark_story_station_navigation_used() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	cfg.set_value("story", "station_navigation_used", true)
	return cfg.save(CHECKPOINT_FILE) == OK


static func known_arcs() -> Array[String]:
	return KNOWN_ARCS.duplicate()


static func latest_unlocked_arc() -> String:
	# Independent of the replay position and active menu selection.
	var latest: String = "prologue"
	for arc_id in KNOWN_ARCS:
		if is_unlocked(arc_id):
			latest = arc_id
	return latest


static func is_unlocked(arc_id: String) -> bool:
	if arc_id == "prologue":
		return true
	if not KNOWN_ARCS.has(arc_id):
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	if arc_id == "chapter07_return":
		return not _saved_ending_return(cfg).is_empty()
	return bool(cfg.get_value("arcs", arc_id + "_unlocked", false)) or _main_reached(str(ARC_START_BEATS[arc_id]))


static func is_completed(arc_id: String) -> bool:
	if not KNOWN_ARCS.has(arc_id):
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	if arc_id in ["chapter07_choice", "chapter07_return"]:
		return not _saved_ending_return(cfg).is_empty()
	return bool(cfg.get_value("arcs", arc_id + "_completed", false)) or _main_reached(str(ARC_COMPLETE_BEATS[arc_id]))


static func unlock_arc(arc_id: String) -> bool:
	if not KNOWN_ARCS.has(arc_id):
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	cfg.set_value("arcs", arc_id + "_unlocked", true)
	return cfg.save(CHECKPOINT_FILE) == OK


static func complete_arc(arc_id: String) -> bool:
	if not KNOWN_ARCS.has(arc_id):
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	cfg.set_value("arcs", arc_id + "_unlocked", true)
	cfg.set_value("arcs", arc_id + "_completed", true)
	return cfg.save(CHECKPOINT_FILE) == OK


static func begin_replay(arc_id: String) -> bool:
	if not is_unlocked(arc_id):
		return false
	if arc_id == "chapter07_return":
		var ending_cfg: ConfigFile = ConfigFile.new()
		ending_cfg.load(CHECKPOINT_FILE)
		var returned: String = _saved_ending_return(ending_cfg)
		if returned.is_empty():
			return false
		# Returning to the completed main game must retain the chosen ending.
		# save_beat already clears the replay lane for a completed finale.
		return save_beat(returned)
	if arc_id == latest_unlocked_arc() and arc_for_beat(read_main_beat()) == arc_id:
		# Return to the current main checkpoint. Older unlocked episodes replay
		# in their own lane without rewinding permanent story progression.
		_runtime_story_beat = ""
		return finish_replay()
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	_runtime_story_beat = ""
	_runtime_replay_beat = str(ARC_START_BEATS[arc_id])
	cfg.set_value("replay", "active", true)
	cfg.set_value("replay", "arc", arc_id)
	cfg.set_value("replay", "beat", str(ARC_START_BEATS[arc_id]))
	cfg.set_value("replay", "active_beat", str(ARC_START_BEATS[arc_id]))
	cfg.set_value("replay", "resume_beat", str(ARC_START_BEATS[arc_id]))
	return cfg.save(CHECKPOINT_FILE) == OK


static func is_replaying() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	return bool(cfg.get_value("replay", "active", false))


static func finish_replay() -> bool:
	_runtime_replay_beat = ""
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	if cfg.has_section("replay"):
		cfg.erase_section("replay")
	return cfg.save(CHECKPOINT_FILE) == OK

# MIKA_CH06_CROSSROADS_GATE_V1

# MIKA_CH07_ENDING_CHOICE_V1

# MIKA_CH08_ENDING_ONE_V1

# MIKA_CH08_ENDING_TWO_V1
static func mika_onboard() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(CHECKPOINT_FILE)
	return bool(cfg.get_value("ending", "mika_onboard", true))

static func crew_lead() -> String:
	return "mika" if mika_onboard() else "companions"
