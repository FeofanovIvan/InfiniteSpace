extends Control
## One clean PDF-derived page. Frames advance on a timer without screen taps;
## the only manual advance is the dedicated top-right Forward control.

signal sequence_completed

const PAGE_FILE: String = "res://mika_motion_comic/assets/pages/ch01_p02_story.webp"
const PAGE_THREE_FILE: String = "res://mika_motion_comic/assets/pages/ch01_p03_story.webp"
# CH01_P03_CINEMATIC_BRIDGE_V1: page 3 in two existing story beats.
const CH01_P03_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch01_p03_localized_voice.gd")
const PAGE_FOUR_FILE: String = "res://mika_motion_comic/assets/pages/ch01_p04_story.webp"
# CH01_P04_CINEMATIC_BRIDGE_V1: Mars arrival and post-MARS word lesson.
const CH01_P04_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch01_p04_localized_voice.gd")
const PAGE_FIVE_FILE: String = "res://mika_motion_comic/assets/pages/ch01_p05_story.webp"
# CH01_P05_NATIVE_BRIDGE_V1
const CH01_P05_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch01_p05_localized_voice.gd")
const PAGE_SIX_FILE: String = "res://mika_motion_comic/assets/pages/ch01_p06_story.webp"
# CH01_P06_NATIVE_BRIDGE_V1
const CH01_P06_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch01_p06_localized_voice.gd")
const PAGE_SEVEN_FILE: String = "res://mika_motion_comic/assets/pages/ch01_p07_story.webp"
# CH01_P07_NATIVE_BRIDGE_V1
const CH01_P07_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch01_p07_localized_voice.gd")
const CHAPTER_TWO_PAGE_ONE: String = "res://mika_motion_comic/assets/pages/ch02_p01_story.webp"
# CH02_P01_NATIVE_BRIDGE_V1
const CH02_P01_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch02_p01_localized_voice.gd")
const CHAPTER_TWO_PAGE_TWO: String = "res://mika_motion_comic/assets/pages/ch02_p02_story.webp"
# CH02_P02_NATIVE_BRIDGE_V1
const CH02_P02_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch02_p02_localized_voice.gd")
const CHAPTER_TWO_PAGE_THREE: String = "res://mika_motion_comic/assets/pages/ch02_p03_story.webp"
# CH02_P03_NATIVE_BRIDGE_V1
const CH02_P03_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch02_p03_localized_voice.gd")
const CHAPTER_TWO_PAGE_FOUR: String = "res://mika_motion_comic/assets/pages/ch02_p04_story.webp"
# CH02_P04_NATIVE_BRIDGE_V1
const CH02_P04_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch02_p04_localized_voice.gd")
const CHAPTER_THREE_PAGE_ONE: String = "res://mika_motion_comic/assets/pages/ch03_p01_story.webp"
# CH03_P01_NATIVE_BRIDGE_V1
const CH03_P01_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch03_p01_localized_voice.gd")
const CHAPTER_THREE_PAGE_TWO: String = "res://mika_motion_comic/assets/pages/ch03_p02_story.webp"
# CH03_P02_NATIVE_BRIDGE_V1
const CH03_P02_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch03_p02_localized_voice.gd")
const CHAPTER_THREE_PAGE_THREE: String = "res://mika_motion_comic/assets/pages/ch03_p03_story.webp"
# CH03_P03_NATIVE_BRIDGE_V1
const CH03_P03_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch03_p03_localized_voice.gd")
const CHAPTER_THREE_PAGE_FOUR: String = "res://mika_motion_comic/assets/pages/ch03_p04_story.webp"
# CH03_P04_NATIVE_BRIDGE_V1
const CH03_P04_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch03_p04_localized_voice.gd")
const CHAPTER_FOUR_PAGE_ONE: String = "res://mika_motion_comic/assets/pages/ch04_p01_story.webp"
# CH04_P01_NATIVE_BRIDGE_V1
const CH04_P01_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch04_p01_localized_voice.gd")
const CHAPTER_FOUR_PAGE_TWO: String = "res://mika_motion_comic/assets/pages/ch04_p02_story.webp"
# CH04_P02_NATIVE_BRIDGE_V1
const CH04_P02_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch04_p02_localized_voice.gd")
const CHAPTER_FOUR_PAGE_THREE: String = "res://mika_motion_comic/assets/pages/ch04_p03_story.webp"
# CH04_P03_NATIVE_BRIDGE_V1
const CH04_P03_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch04_p03_localized_voice.gd")
const CHAPTER_FOUR_PAGE_FOUR: String = "res://mika_motion_comic/assets/pages/ch04_p04_story.webp"
# CH04_P04_NATIVE_BRIDGE_V1
const CH04_P04_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch04_p04_localized_voice.gd")
const CHAPTER_FOUR_PAGE_FIVE: String = "res://mika_motion_comic/assets/pages/ch04_p05_story.webp"
# CH04_P05_NATIVE_BRIDGE_V1
const CH04_P05_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch04_p05_localized_voice.gd")
const CHAPTER_FIVE_PAGE_ONE: String = "res://mika_motion_comic/assets/pages/ch05_p01_story.webp"
# CH05_P01_NATIVE_BRIDGE_V1
const CH05_P01_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch05_p01_localized_voice.gd")
const CHAPTER_FIVE_PAGE_TWO: String = "res://mika_motion_comic/assets/pages/ch05_p02_story.webp"
# CH05_P02_NATIVE_BRIDGE_V1
const CH05_P02_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch05_p02_localized_voice.gd")
const CHAPTER_FIVE_PAGE_THREE: String = "res://mika_motion_comic/assets/pages/ch05_p03_story.webp"
# CH05_P03_NATIVE_BRIDGE_V1
const CH05_P03_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch05_p03_localized_voice.gd")
const CHAPTER_FIVE_PAGE_FOUR: String = "res://mika_motion_comic/assets/pages/ch05_p04_story.webp"
# CH05_P04_NATIVE_BRIDGE_V1
const CH05_P04_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch05_p04_localized_voice.gd")
const PAGE_SHADER: Shader = preload("res://mika_motion_comic/shaders/single_page_comic.gdshader")
const PAGE_SIZE: Vector2 = Vector2(2480.0, 3508.0)
# CH01_P02_VOICE_BRIDGE_V1 — page-localized, audio-paced story extension.
const CH01_P02_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch01_p02_localized_voice.gd")
const CH01_P02_CAMERA_START: Dictionary = {
    "wormhole": Vector3(0.500, 0.161, 0.350),
    "earth_view": Vector3(0.245, 0.417, 0.200),
    "simulator": Vector3(0.754, 0.422, 0.203),
    "earth_approach": Vector3(0.267, 0.736, 0.224),
    "earth_spaceport": Vector3(0.746, 0.734, 0.225)
}
const CH01_P02_CAMERA_END: Dictionary = {
    "wormhole": Vector3(0.529, 0.161, 0.343),
    "earth_view": Vector3(0.257, 0.423, 0.197),
    "simulator": Vector3(0.739, 0.430, 0.199),
    "earth_approach": Vector3(0.278, 0.741, 0.220),
    "earth_spaceport": Vector3(0.752, 0.744, 0.223)
}
const CAMERA: Dictionary = {
	"p82_approach": Vector3(0.180000, 0.105000, 0.155000),
	"p82_portal": Vector3(0.720000, 0.092000, 0.155000),
	"p82_entry": Vector3(0.280000, 0.283000, 0.220000),
	"p82_change": Vector3(0.760000, 0.284000, 0.220000),
	"p82_transformation": Vector3(0.310000, 0.537000, 0.264000),
	"p82_beyond": Vector3(0.780000, 0.537000, 0.264000),
	"p82_new_space": Vector3(0.520000, 0.830000, 0.308000),
	"p81_palace": Vector3(0.660000, 0.133000, 0.209000),
	"p81_mika": Vector3(0.268000, 0.340000, 0.263000),
	"p81_bubble": Vector3(0.765000, 0.366000, 0.263000),
	"p81_friends": Vector3(0.500000, 0.615000, 0.219000),
	"p81_lizard": Vector3(0.270000, 0.842000, 0.241100),
	"p81_reply": Vector3(0.745000, 0.843000, 0.241100),
	"p71_ship": Vector3(0.500000, 0.146000, 0.224609),
	"p71_cabin": Vector3(0.240000, 0.402000, 0.231445),
	"p71_flight": Vector3(0.760000, 0.395000, 0.240234),
	"p71_mika_points": Vector3(0.210000, 0.620000, 0.208984),
	"p71_thought": Vector3(0.770000, 0.710000, 0.466797),
	"p71_planet": Vector3(0.260000, 0.860000, 0.239258),
	"p72_conversation": Vector3(0.500000, 0.185000, 0.307617),
	"p72_history": Vector3(0.500000, 0.455000, 0.195312),
	"p72_magnetic": Vector3(0.250000, 0.680000, 0.200195),
	"p72_worlds": Vector3(0.750000, 0.670000, 0.198242),
	"p72_neurons": Vector3(0.250000, 0.880000, 0.189453),
	"p72_mika": Vector3(0.750000, 0.900000, 0.194336),
	"p73_guide": Vector3(0.180000, 0.120000, 0.197266),
	"p73_flower": Vector3(0.500000, 0.120000, 0.197266),
	"p73_mika_form": Vector3(0.820000, 0.120000, 0.196289),
	"p73_evolution": Vector3(0.500000, 0.350000, 0.244141),
	"p73_storm": Vector3(0.500000, 0.600000, 0.243164),
	"p73_tunnel": Vector3(0.500000, 0.860000, 0.243164),
	"p74_planet_change": Vector3(0.310000, 0.160000, 0.260742),
	"p74_mika_future": Vector3(0.780000, 0.160000, 0.260742),
	"p74_routes": Vector3(0.220000, 0.440000, 0.273438),
	"p74_gate": Vector3(0.550000, 0.440000, 0.272461),
	"p74_living_world": Vector3(0.830000, 0.440000, 0.273438),
	"p74_doors": Vector3(0.500000, 0.785000, 0.397000),
	"p61_cabin": Vector3(0.502604, 0.128795, 0.252990),
	"p61_tunnel": Vector3(0.251302, 0.353266, 0.148114),
	"p61_planet": Vector3(0.746094, 0.354186, 0.152714),
	"p61_city": Vector3(0.501302, 0.607176, 0.326587),
	"p61_meeting": Vector3(0.240885, 0.883165, 0.188592),
	"p61_chair": Vector3(0.723958, 0.883165, 0.189512),
	"p62_ancient": Vector3(0.253255, 0.130635, 0.220791),
	"p62_blueprint": Vector3(0.751302, 0.130635, 0.220791),
	"p62_station": Vector3(0.186198, 0.362925, 0.218031),
	"p62_burst": Vector3(0.524089, 0.362925, 0.218031),
	"p62_hole": Vector3(0.838542, 0.362925, 0.218031),
	"p62_mika": Vector3(0.196615, 0.620975, 0.327507),
	"p62_clocks": Vector3(0.686198, 0.627415, 0.316467),
	"p62_galaxy": Vector3(0.138021, 0.903404, 0.154554),
	"p62_eclipse": Vector3(0.388021, 0.903404, 0.154554),
	"p62_planets": Vector3(0.646484, 0.903404, 0.154554),
	"p62_meteor": Vector3(0.881510, 0.903404, 0.154554),
	"p63_network": Vector3(0.499349, 0.187672, 0.334867),
	"p63_civilizations": Vector3(0.287109, 0.513339, 0.270469),
	"p63_storm": Vector3(0.774089, 0.513339, 0.270469),
	"p63_gate": Vector3(0.294271, 0.828887, 0.301748),
	"p63_hole": Vector3(0.787760, 0.828887, 0.301748),
	"p64_council": Vector3(0.499349, 0.079577, 0.118675),
	"p64_mika": Vector3(0.236979, 0.257590, 0.216191),
	"p64_route": Vector3(0.739583, 0.266789, 0.220791),
	"p64_wake": Vector3(0.222656, 0.482981, 0.224471),
	"p64_cockpit": Vector3(0.744792, 0.505520, 0.223551),
	"p64_talk": Vector3(0.242188, 0.746090, 0.217111),
	"p64_worlds": Vector3(0.745443, 0.746090, 0.217111),
	"p64_portal": Vector3(0.499349, 0.927783, 0.103956),
	"wormhole": Vector3(0.500, 0.161, 0.350),
	"earth_view": Vector3(0.245, 0.462, 0.208),
	"simulator": Vector3(0.754, 0.462, 0.208),
	# Existing bottom two frames on the same original second page.
	"earth_approach": Vector3(0.265, 0.755, 0.185),
	"earth_spaceport": Vector3(0.740, 0.755, 0.185),
	# The third page belongs AFTER the native jigsaw, not after landing.
	# Begin with the completed puzzle artwork, then Mika and ship refuelling.
	"p03_puzzle_reveal": Vector3(0.500, 0.175, 0.315),
	"p03_mika_upset": Vector3(0.215, 0.490, 0.138),
	"p03_ship_refuel": Vector3(0.705, 0.475, 0.205),
	# Final two panels of the SAME third PDF page. These play after Launch,
	# before the native Godot ship is allowed to take off from Earth.
	"p03_earth_departure": Vector3(0.365, 0.847, 0.224),
	"p03_mars_destination": Vector3(0.840, 0.807, 0.085),
	# Fourth PDF, first three original frames. Pause at the reception desk
	# until the child traces MARS in the native word-tracing mini-game.
	"p04_mars_landing": Vector3(0.500, 0.115, 0.173),
	"p04_mika_walk": Vector3(0.264, 0.304, 0.170),
	"p04_reception": Vector3(0.754, 0.304, 0.170),
	"p04_elevator": Vector3(0.264, 0.521, 0.169),
	"p04_ai_core": Vector3(0.745, 0.527, 0.172),
	"p04_mika_orb_close": Vector3(0.460, 0.816, 0.235),
	# PDF five — all eight frames play after the child finishes the word.
	"p05_mika_orb": Vector3(0.465, 0.140, 0.208),
	"p05_mika_happy": Vector3(0.225, 0.377, 0.160),
	"p05_pink_city": Vector3(0.744, 0.377, 0.180),
	"p05_mika_shocked": Vector3(0.198, 0.628, 0.128),
	"p05_red_city": Vector3(0.510, 0.577, 0.100),
	"p05_mika_worried": Vector3(0.758, 0.637, 0.116),
	"p05_mika_sad": Vector3(0.260, 0.881, 0.163),
	"p05_mika_question": Vector3(0.735, 0.875, 0.163),
	# PDF six — leave the LAST TWO pictures for the native Hub Launch tap.
	"p06_pink_vortex": Vector3(0.218, 0.110, 0.145),
	"p06_mika_thinks": Vector3(0.713, 0.108, 0.152),
	"p06_galaxies_in_orb": Vector3(0.315, 0.290, 0.141),
	"p06_mika_smiles": Vector3(0.790, 0.297, 0.139),
	"p06_orb_whole": Vector3(0.315, 0.485, 0.164),
	"p06_bubble_elevator": Vector3(0.785, 0.490, 0.132),
	"p06_mika_bubble_runs": Vector3(0.255, 0.690, 0.165),
	"p06_ship_departure": Vector3(0.750, 0.687, 0.143),
	"p06_station_destination": Vector3(0.500, 0.889, 0.138),
	# Original seventh PDF page: six station shots before Shopping List,
	# final galaxy-window shot AFTER the hyperjump's outward dash.
	"p07_station_hangar": Vector3(0.271, 0.119, 0.176),
	"p07_mika_staff": Vector3(0.757, 0.116, 0.160),
	"p07_mika_worried": Vector3(0.335, 0.317, 0.170),
	# Aim at the professor's head first; the old Y=0.319 zoomed his torso.
	"p07_professor_arrives": Vector3(0.826, 0.272, 0.088),
	"p07_professor_talks": Vector3(0.355, 0.495, 0.150),
	"p07_ship_repair": Vector3(0.773, 0.528, 0.148),
	"p07_lmc_window": Vector3(0.500, 0.803, 0.315),
	# Chapter 2: the REAL PDF 2-1 and 2-2, one image per full page.
	# Stop just before page 2-2's final ship-departure image for the maze.
	"p21_flight_cabin": Vector3(0.347, 0.156, 0.228),
	"p21_professor_door": Vector3(0.850, 0.151, 0.091),
	# Begin with the full city on the LEFT of PDF 2-1's second row.
	"p21_ocean_city": Vector3(0.354, 0.469, 0.260),
	# The next shot HOLDS the right-hand end of the SAME camera pan.
	"p21_mika_enters": Vector3(0.586, 0.469, 0.303),
	# Start on Mika at the first city encounter; the safe frame still shows
	# the visitor on landscape screens, while portrait screens keep his FACE.
	"p21_mika_meets_fungus": Vector3(0.285, 0.788, 0.280),
	"p22_fungal_conversation": Vector3(0.492, 0.157, 0.261),
	"p22_mika_calls_bubble": Vector3(0.448, 0.509, 0.323),
	"p22_planet_departure": Vector3(0.500, 0.856, 0.232),
	# PDF 2-3: Molly/Molia. First FOUR shots on landing, cargo shot after
	# the original Grow Little Tree game is completed in the Planet Hub.
	"p23_molly_orbit": Vector3(0.207, 0.143, 0.142),
	"p23_ruins_meeting": Vector3(0.684, 0.149, 0.214),
	"p23_mika_talks": Vector3(0.230, 0.419, 0.155),
	"p23_plant_tutorial": Vector3(0.718, 0.418, 0.205),
	"p23_loading_ship": Vector3(0.489, 0.782, 0.370),
	# Original PDF 2-4: station exterior, ecological history, and meeting.
	# All NINE frames precede the existing Sunbeam mini-game.
	"p24_station_exterior": Vector3(0.175, 0.077, 0.103),
	"p24_fungal_garden": Vector3(0.301, 0.272, 0.211),
	"p24_factory": Vector3(0.780, 0.208, 0.089),
	"p24_reclaimed_city": Vector3(0.790, 0.325, 0.112),
	"p24_fungus_portrait": Vector3(0.172, 0.502, 0.158),
	"p24_meteor": Vector3(0.501, 0.469, 0.100),
	"p24_mycelium_net": Vector3(0.502, 0.634, 0.158),
	# Show Mika's ENTIRE face, ears and hand in a wider composition. Adjacent
	# source panels may remain visible; do not trim this to a tiny vertical slit.
	"p24_mika_smiles": Vector3(0.808, 0.560, 0.295),
	"p24_professor_and_fungus": Vector3(0.303, 0.865, 0.208),
	# Chapter 3 PDF 3-1. All artwork remains on ONE compressed PDF sheet.
	"p31_professor_sandwich": Vector3(0.283, 0.153, 0.230),
	"p31_fungus_and_professor": Vector3(0.583, 0.177, 0.205),
	# Okea: watery city, first contact, three adjacent lizard encounter frames,
	# and the single wide departure image (ocean world -> Cela).
	"p31_okea_city": Vector3(0.202, 0.413, 0.205),
	"p31_okea_meeting": Vector3(0.601, 0.414, 0.205),
	"p31_okea_observes": Vector3(0.208, 0.666, 0.195),
	"p31_okea_lizard_sad": Vector3(0.416, 0.667, 0.196),
	"p31_okea_lizard_talks": Vector3(0.650, 0.669, 0.196),
	"p31_okea_to_cela": Vector3(0.190, 0.879, 0.140),
	# Original PDF 3-2: ship at crystal temple, cave, lizard collecting,
	# Mika's reaction, professor's call and the wide star-fleet panorama.
	"p32_cela_temple": Vector3(0.500, 0.170, 0.290),
	"p32_cela_cave": Vector3(0.250, 0.420, 0.170),
	"p32_cela_crystals": Vector3(0.744, 0.420, 0.170),
	"p32_mika_surprised": Vector3(0.251, 0.621, 0.170),
	"p32_professor_calls": Vector3(0.746, 0.621, 0.170),
	"p32_lotus_route": Vector3(0.500, 0.853, 0.244),
	# PDF 3-3: the first three source panels; leave its LAST wide
	# crystal-archive hall for the next station episode.
	"p33_cela_bubble": Vector3(0.500, 0.166, 0.303),
	"p33_mika_encounter": Vector3(0.268, 0.473, 0.213),
	"p33_lotus_flower": Vector3(0.741, 0.473, 0.213),
	"p33_lotus_archive": Vector3(0.500, 0.807, 0.320),
	# Original PDF 3-4. The sixth ship shot belongs AFTER native Hub Launch.
	"p34_lotus_council": Vector3(0.500, 0.134, 0.214),
	"p34_liquid_phase": Vector3(0.252, 0.348, 0.165),
	"p34_crystal_phase": Vector3(0.743, 0.348, 0.165),
	"p34_phase_cavern": Vector3(0.500, 0.545, 0.183),
	# This phase prince is a tall ribbon: the face/head sits at the TOP.
	# Start at the crest, not at its belly or the bottom of the image.
	"p34_new_hero": Vector3(0.217, 0.741, 0.153),
	"p34_ship_departure": Vector3(0.695, 0.815, 0.299),
	# Fourth chapter: bathroom surprise, two pirate craft, intimidation,
	# captives and their escape. Two original A4 sheets, no extracted panels.
	"p41_professor_bath_walk": Vector3(0.251, 0.134, 0.198),
	"p41_professor_bath_rest": Vector3(0.750, 0.131, 0.197),
	"p41_phase_bath_surprise": Vector3(0.310, 0.368, 0.209),
	"p41_pirate_ships": Vector3(0.278, 0.566, 0.150),
	"p41_flagship_threat": Vector3(0.500, 0.806, 0.290),
	"p42_pirates_capture": Vector3(0.315, 0.149, 0.220),
	"p42_station_prison": Vector3(0.263, 0.399, 0.171),
	"p42_lizard_interrogates": Vector3(0.747, 0.399, 0.171),
	"p42_lizard_changes_mind": Vector3(0.262, 0.583, 0.164),
	"p42_phase_in_cage": Vector3(0.744, 0.583, 0.164),
	"p42_run_to_ship": Vector3(0.305, 0.830, 0.235),
	# PDF 4-3: one original sheet, six shots. Faces always stay in frame.
	"p43_cockpit_decision": Vector3(0.328, 0.162, 0.225),
	"p43_ship_landing": Vector3(0.267, 0.413, 0.190),
	"p43_scientist_meeting": Vector3(0.735, 0.413, 0.191),
	"p43_loading_fossils": Vector3(0.288, 0.640, 0.204),
	"p43_next_target": Vector3(0.285, 0.867, 0.195),
	"p43_space_departure": Vector3(0.773, 0.867, 0.194),
	# Original PDF 4-4, five ordered frames; preserve all faces and dinosaur heads.
	"p44_professor_studies_fossil": Vector3(0.308, 0.171, 0.252),
	"p44_professor_realization": Vector3(0.216, 0.418, 0.155),
	"p44_dinosaur_dna": Vector3(0.727, 0.419, 0.161),
	"p44_ancient_dinosaurs": Vector3(0.295, 0.653, 0.247),
	"p44_ancient_meteorite": Vector3(0.293, 0.895, 0.178),
	# Original PDF 4-5: four museum shots, WHITE evolution strip, then
	# precisely two held-back frames that play after five real game rounds.
	"p45_ruins_entrance": Vector3(0.269, 0.135, 0.222),
	"p45_museum_walk": Vector3(0.779, 0.156, 0.252),
	"p45_professor_handshake": Vector3(0.273, 0.422, 0.250),
	"p45_evolution_display": Vector3(0.744, 0.436, 0.231),
	"p45_white_evolution": Vector3(0.280, 0.651, 0.107),
	"p45_scientists_farewell": Vector3(0.277, 0.858, 0.232),
	# Anchor the upper edge of the narrow silhouette panel. In landscape the
	# safety crop is width-limited; centering vertically clipped its head.
	"p45_shadow_of_origin": Vector3(0.772, 0.805, 0.225),
	# Page 5-1: face-first framing; never zoom onto the professor's body.
	"p51_cabin_alarm": Vector3(0.500, 0.169, 0.286),
	"p51_ship_lost": Vector3(0.296, 0.431, 0.195),
	"p51_gravity_world": Vector3(0.778, 0.427, 0.197),
	"p51_mika_frightened": Vector3(0.183, 0.634, 0.196),
	"p51_lizard_frightened": Vector3(0.493, 0.629, 0.203),
	"p51_pyramid_landing": Vector3(0.818, 0.634, 0.205),
	"p51_magnetic_creatures": Vector3(0.500, 0.857, 0.226),
	# Page 5-2: lead to the native Gravity Pinball lesson in patch B.
	"p52_mika_earpiece": Vector3(0.178, 0.145, 0.210),
	"p52_magnetic_hall": Vector3(0.666, 0.147, 0.230),
	"p52_mika_meets_magnetic": Vector3(0.241, 0.471, 0.340),
	"p52_portal_discovery": Vector3(0.762, 0.474, 0.336),
	"p52_mika_talks": Vector3(0.255, 0.851, 0.181),
	"p52_ship_departure": Vector3(0.718, 0.850, 0.181),
	# Exact two original new PDF sheets: first two frames -> Roll Ball;
	# rest of page 5-3 + first three of 5-4 -> Electric Impulses.
	"p53_archive_hall": Vector3(0.290, 0.169, 0.290),
	"p53_mika_console": Vector3(0.785, 0.168, 0.290),
	"p53_volcanic_city": Vector3(0.270, 0.468, 0.238),
	"p53_evacuating_ships": Vector3(0.759, 0.469, 0.235),
	"p53_gravity_anomaly": Vector3(0.500, 0.803, 0.330),
	"p54_galaxy_network": Vector3(0.500, 0.134, 0.222),
	"p54_species_meet": Vector3(0.267, 0.388, 0.222),
	"p54_pulse_signal": Vector3(0.759, 0.388, 0.222),
	"p54_black_hole": Vector3(0.295, 0.640, 0.222),
	"p54_mika_farewell": Vector3(0.790, 0.642, 0.220),
	"p54_ship_departure": Vector3(0.500, 0.881, 0.194)
}
const FRAME_SECONDS: Dictionary = {
	"p82_approach": 5.0,
	"p82_portal": 6.0,
	"p82_entry": 5.0,
	"p82_change": 5.0,
	"p82_transformation": 6.0,
	"p82_beyond": 6.0,
	"p82_new_space": 8.0,
	"p81_palace": 6.0,
	"p81_mika": 5.0,
	"p81_bubble": 5.0,
	"p81_friends": 8.0,
	"p81_lizard": 5.0,
	"p81_reply": 6.0,
	"p71_ship": 5,
	"p71_cabin": 5,
	"p71_flight": 4,
	"p71_mika_points": 5,
	"p71_thought": 6,
	"p71_planet": 5,
	"p72_conversation": 6,
	"p72_history": 7,
	"p72_magnetic": 5,
	"p72_worlds": 5,
	"p72_neurons": 5,
	"p72_mika": 4,
	"p73_guide": 5,
	"p73_flower": 5,
	"p73_mika_form": 5,
	"p73_evolution": 7,
	"p73_storm": 6,
	"p73_tunnel": 7,
	"p74_planet_change": 6,
	"p74_mika_future": 5,
	"p74_routes": 5,
	"p74_gate": 4,
	"p74_living_world": 5,
	"p74_doors": 6,
	"p61_cabin": 5.0,
	"p61_tunnel": 4.0,
	"p61_planet": 4.5,
	"p61_city": 6.0,
	"p61_meeting": 5.0,
	"p61_chair": 5.0,
	"p62_ancient": 5.0,
	"p62_blueprint": 5.0,
	"p62_station": 5.0,
	"p62_burst": 4.5,
	"p62_hole": 4.5,
	"p62_mika": 4.0,
	"p62_clocks": 6.0,
	"p62_galaxy": 4.0,
	"p62_eclipse": 4.0,
	"p62_planets": 4.0,
	"p62_meteor": 4.0,
	"p63_network": 6.0,
	"p63_civilizations": 5.0,
	"p63_storm": 5.0,
	"p63_gate": 5.0,
	"p63_hole": 5.0,
	"p64_council": 5.0,
	"p64_mika": 5.0,
	"p64_route": 5.0,
	"p64_wake": 5.5,
	"p64_cockpit": 5.0,
	"p64_talk": 5.0,
	"p64_worlds": 5.0,
	"p64_portal": 5.0,
	"wormhole": 4.0, "earth_view": 4.5, "simulator": 4.5,
	"earth_approach": 4.5, "earth_spaceport": 5.0,
	"p03_puzzle_reveal": 3.6, "p03_mika_upset": 4.5, "p03_ship_refuel": 5.5,
	"p03_earth_departure": 4.8, "p03_mars_destination": 4.5,
	"p04_mars_landing": 4.6, "p04_mika_walk": 4.2, "p04_reception": 5.2,
	"p04_elevator": 3.9, "p04_ai_core": 4.8, "p04_mika_orb_close": 4.8,
	"p05_mika_orb": 4.7, "p05_mika_happy": 3.4, "p05_pink_city": 5.3,
	"p05_mika_shocked": 3.5, "p05_red_city": 4.5, "p05_mika_worried": 3.8,
	"p05_mika_sad": 4.1, "p05_mika_question": 4.3,
	"p06_pink_vortex": 4.5, "p06_mika_thinks": 4.0,
	"p06_galaxies_in_orb": 4.5, "p06_mika_smiles": 4.0,
	"p06_orb_whole": 4.6, "p06_bubble_elevator": 4.3,
	"p06_mika_bubble_runs": 5.0,
	"p06_ship_departure": 4.8, "p06_station_destination": 5.0,
	"p07_station_hangar": 5.0, "p07_mika_staff": 4.6,
	"p07_mika_worried": 4.8, "p07_professor_arrives": 3.8,
	"p07_professor_talks": 5.1, "p07_ship_repair": 5.3,
	"p07_lmc_window": 6.2,
	"p21_flight_cabin": 5.0, "p21_professor_door": 4.3,
	"p21_ocean_city": 5.6, "p21_mika_enters": 4.2,
	"p21_mika_meets_fungus": 5.1, "p22_fungal_conversation": 5.1,
	"p22_mika_calls_bubble": 5.2, "p22_planet_departure": 6.1,
	"p23_molly_orbit": 4.6, "p23_ruins_meeting": 5.0,
	"p23_mika_talks": 4.8, "p23_plant_tutorial": 5.7,
	"p23_loading_ship": 6.2,
	"p24_station_exterior": 7.2, "p24_fungal_garden": 5.1,
	"p24_factory": 4.8, "p24_reclaimed_city": 5.1,
	"p24_fungus_portrait": 4.8, "p24_meteor": 4.5,
	"p24_mycelium_net": 4.6, "p24_mika_smiles": 5.0,
	"p24_professor_and_fungus": 6.5,
	"p31_professor_sandwich": 5.5,
	"p31_fungus_and_professor": 6.9,
	"p31_okea_city": 5.1, "p31_okea_meeting": 6.2,
	"p31_okea_observes": 4.8, "p31_okea_lizard_sad": 6.1,
	"p31_okea_lizard_talks": 6.1, "p31_okea_to_cela": 7.2,
	"p32_cela_temple": 6.0, "p32_cela_cave": 5.3,
	"p32_cela_crystals": 5.6, "p32_mika_surprised": 4.9,
	"p32_professor_calls": 5.5, "p32_lotus_route": 6.6,
	"p33_cela_bubble": 6.1, "p33_mika_encounter": 5.7,
	"p33_lotus_flower": 6.0, "p33_lotus_archive": 6.6,
	"p34_lotus_council": 7.0, "p34_liquid_phase": 5.4,
	"p34_crystal_phase": 5.5, "p34_phase_cavern": 6.0,
	"p34_new_hero": 6.3, "p34_ship_departure": 7.0,
	"p41_professor_bath_walk": 5.0, "p41_professor_bath_rest": 4.5,
	"p41_phase_bath_surprise": 6.4, "p41_pirate_ships": 6.1,
	"p41_flagship_threat": 6.0, "p42_pirates_capture": 6.1,
	"p42_station_prison": 4.8, "p42_lizard_interrogates": 5.3,
	"p42_lizard_changes_mind": 5.3, "p42_phase_in_cage": 5.2,
	"p42_run_to_ship": 7.0,
	"p43_cockpit_decision": 6.8, "p43_ship_landing": 5.0,
	"p43_scientist_meeting": 6.0, "p43_loading_fossils": 6.8,
	"p43_next_target": 5.4, "p43_space_departure": 5.6,
	"p44_professor_studies_fossil": 7.0,
	"p44_professor_realization": 5.7, "p44_dinosaur_dna": 5.3,
	"p44_ancient_dinosaurs": 7.5, "p44_ancient_meteorite": 6.9,
	"p45_ruins_entrance": 5.7, "p45_museum_walk": 6.4,
	"p45_professor_handshake": 6.3, "p45_evolution_display": 6.5,
	"p45_white_evolution": 7.0,
	"p45_scientists_farewell": 6.7, "p45_shadow_of_origin": 7.1,
	"p51_cabin_alarm": 6.0, "p51_ship_lost": 4.5,
	"p51_gravity_world": 5.3, "p51_mika_frightened": 4.5,
	"p51_lizard_frightened": 4.4, "p51_pyramid_landing": 5.0,
	"p51_magnetic_creatures": 6.3,
	"p52_mika_earpiece": 5.1, "p52_magnetic_hall": 5.8,
	"p52_mika_meets_magnetic": 5.5, "p52_portal_discovery": 6.2, # Native Pinball Hub begins after this panel.
	"p52_mika_talks": 5.1, "p52_ship_departure": 6.0,
	"p53_archive_hall": 5.0, "p53_mika_console": 5.3,
	"p53_volcanic_city": 5.4, "p53_evacuating_ships": 5.4, "p53_gravity_anomaly": 6.0,
	"p54_galaxy_network": 6.0, "p54_species_meet": 5.5, "p54_pulse_signal": 5.7,
	"p54_black_hole": 6.0, "p54_mika_farewell": 5.1, "p54_ship_departure": 6.0
}
const LOWER_PANEL_END: Dictionary = {
	"earth_approach": Vector2(0.270, 0.815),
	"earth_spaceport": Vector2(0.735, 0.815)
}
const PAGE_THREE_CAMERA_END: Dictionary = {
	# A small inward zoom carries the assembled picture into the comic.
	"p03_puzzle_reveal": Vector3(0.500, 0.175, 0.265),
	# Move within each tilted panel, keeping its white gutters offscreen.
	"p03_mika_upset": Vector3(0.215, 0.590, 0.138),
	"p03_ship_refuel": Vector3(0.705, 0.595, 0.205),
	"p03_earth_departure": Vector3(0.327, 0.861, 0.224),
	"p03_mars_destination": Vector3(0.840, 0.905, 0.085)
}
const PAGE_FOUR_CAMERA_END: Dictionary = {
	"p04_mars_landing": Vector3(0.535, 0.120, 0.162),
	"p04_mika_walk": Vector3(0.271, 0.317, 0.164),
	"p04_reception": Vector3(0.740, 0.317, 0.163),
	# Dolly toward Mika's EYES, not down the elevator cabin to his boots.
	"p04_elevator": Vector3(0.218, 0.476, 0.090),
	"p04_ai_core": Vector3(0.742, 0.548, 0.163),
	"p04_mika_orb_close": Vector3(0.331, 0.802, 0.164)
}
const PAGE_FIVE_CAMERA_END: Dictionary = {
	"p05_mika_orb": Vector3(0.348, 0.151, 0.139),
	"p05_mika_happy": Vector3(0.213, 0.371, 0.133),
	"p05_pink_city": Vector3(0.744, 0.385, 0.166),
	"p05_mika_shocked": Vector3(0.197, 0.650, 0.112),
	"p05_red_city": Vector3(0.513, 0.595, 0.092),
	"p05_mika_worried": Vector3(0.734, 0.673, 0.100),
	"p05_mika_sad": Vector3(0.255, 0.903, 0.137),
	"p05_mika_question": Vector3(0.735, 0.899, 0.137)
}
const PAGE_SIX_CAMERA_END: Dictionary = {
	"p06_pink_vortex": Vector3(0.216, 0.122, 0.139),
	"p06_mika_thinks": Vector3(0.625, 0.136, 0.116),
	"p06_galaxies_in_orb": Vector3(0.310, 0.292, 0.119),
	"p06_mika_smiles": Vector3(0.765, 0.299, 0.113),
	"p06_orb_whole": Vector3(0.340, 0.490, 0.138),
	# Zoom into BOTH Mika and Bubble inside the lift, not their feet.
	"p06_bubble_elevator": Vector3(0.759, 0.459, 0.094),
	"p06_mika_bubble_runs": Vector3(0.306, 0.666, 0.108),
	# Ship stays at the centre as the camera moves closer.
	"p06_ship_departure": Vector3(0.735, 0.688, 0.108),
	"p06_station_destination": Vector3(0.510, 0.895, 0.116)
}
const PAGE_SEVEN_CAMERA_END: Dictionary = {
	"p07_station_hangar": Vector3(0.315, 0.120, 0.163),
	"p07_mika_staff": Vector3(0.728, 0.104, 0.133),
	"p07_mika_worried": Vector3(0.260, 0.320, 0.136),
	"p07_professor_arrives": Vector3(0.841, 0.268, 0.075),
	# Pan toward his FACE, while keeping his hair above the crop's top edge.
	"p07_professor_talks": Vector3(0.402, 0.492, 0.116),
	# Close in on the PROFESSOR'S welding, not on the ship's landing gear.
	"p07_ship_repair": Vector3(0.779, 0.541, 0.115),
	# One continuous last panel: Mika and Professor -> LMC through window.
	"p07_lmc_window": Vector3(0.505, 0.780, 0.225)
}
const CHAPTER_TWO_CAMERA_END: Dictionary = {
	"p21_flight_cabin": Vector3(0.404, 0.162, 0.205),
	"p21_professor_door": Vector3(0.851, 0.122, 0.075),
	# Pan right ACROSS the original PDF sheet toward Mika in the city.
	# A slight zoom OUT lets the thin portrait frame fit beside the city.
	"p21_ocean_city": Vector3(0.586, 0.469, 0.303),
	# Move IN toward Mika's eyes and mouth, not right toward the visitor:
	# the old 0.514 focus cut Mika's face out of this first-city close-up.
	"p21_mika_meets_fungus": Vector3(0.270, 0.787, 0.205),
	"p22_fungal_conversation": Vector3(0.563, 0.158, 0.216),
	"p22_mika_calls_bubble": Vector3(0.563, 0.511, 0.262),
	# The last frame moves toward the ship on the upper-right horizon.
	"p22_planet_departure": Vector3(0.612, 0.840, 0.195)
}
const CHAPTER_TWO_THREE_CAMERA_END: Dictionary = {
	# A controlled close-up stays within each artwork and keeps heads visible.
	"p23_molly_orbit": Vector3(0.207, 0.153, 0.127),
	"p23_ruins_meeting": Vector3(0.757, 0.191, 0.166),
	"p23_mika_talks": Vector3(0.205, 0.411, 0.130),
	# The LEFT side holds Mika's whole face; the representative and the
	# highlighted plant remain visible on the right at the same time.
	"p23_plant_tutorial": Vector3(0.714, 0.423, 0.165),
	# Keep the professor's hair AND Mika handing over the cargo in frame.
	"p23_loading_ship": Vector3(0.515, 0.777, 0.347)
}
const CHAPTER_TWO_FOUR_CAMERA_END: Dictionary = {
	# Horizontal sweep across the ENTIRE original orbital station, not an
	# inert close-up of its centre that hides both ends.
	"p24_station_exterior": Vector3(0.825, 0.077, 0.094),
	"p24_fungal_garden": Vector3(0.310, 0.285, 0.187),
	"p24_factory": Vector3(0.819, 0.210, 0.080),
	"p24_reclaimed_city": Vector3(0.809, 0.330, 0.099),
	# The fungal representative's EYES remain the anchor, never the feet.
	"p24_fungus_portrait": Vector3(0.177, 0.510, 0.134),
	"p24_meteor": Vector3(0.507, 0.470, 0.088),
	"p24_mycelium_net": Vector3(0.512, 0.643, 0.136),
	# Keep Mika's ears, eyes, and raised hand in the single portrait shot.
	"p24_mika_smiles": Vector3(0.810, 0.550, 0.260),
	# Original WIDE final frame: one continuous pan professor -> fungus.
	"p24_professor_and_fungus": Vector3(0.703, 0.865, 0.200)
}
const CHAPTER_THREE_CAMERA_END: Dictionary = {
	# A small dolly back retains the professor's eyes AND his sandwich.
	"p31_professor_sandwich": Vector3(0.295, 0.155, 0.232),
	# The next shot pans across the ONE original image, from the fungal
	# passenger on the left to the professor on the right.
	"p31_fungus_and_professor": Vector3(0.847, 0.170, 0.205),
	# Camera stays at head-height, even if the neighbouring PDF frame leaks
	# into a wide viewport. Slide across adjacent frames instead of cutting.
	"p31_okea_city": Vector3(0.344, 0.414, 0.205),
	"p31_okea_meeting": Vector3(0.832, 0.413, 0.205),
	"p31_okea_observes": Vector3(0.258, 0.666, 0.195),
	"p31_okea_lizard_sad": Vector3(0.555, 0.674, 0.196),
	"p31_okea_lizard_talks": Vector3(0.833, 0.666, 0.196),
	"p31_okea_to_cela": Vector3(0.815, 0.878, 0.140)
}
const CHAPTER_THREE_TWO_CAMERA_END: Dictionary = {
	# Stay on the actual actors, not the empty entrance or their feet.
	"p32_cela_temple": Vector3(0.767, 0.166, 0.252),
	"p32_cela_cave": Vector3(0.385, 0.422, 0.165),
	"p32_cela_crystals": Vector3(0.722, 0.403, 0.145),
	"p32_mika_surprised": Vector3(0.224, 0.603, 0.140),
	"p32_professor_calls": Vector3(0.742, 0.600, 0.144),
	"p32_lotus_route": Vector3(0.732, 0.851, 0.222)
}
const CHAPTER_THREE_THREE_CAMERA_END: Dictionary = {
	# Keep Mika's entire face on the LEFT and the lizard in the bubble on
	# the RIGHT at the same time, including narrow portrait phones.
	"p33_cela_bubble": Vector3(0.590, 0.166, 0.270),
	"p33_mika_encounter": Vector3(0.320, 0.468, 0.179),
	"p33_lotus_flower": Vector3(0.741, 0.470, 0.180),
	"p33_lotus_archive": Vector3(0.500, 0.814, 0.282)
}
const CHAPTER_THREE_FOUR_CAMERA_END: Dictionary = {
	"p34_lotus_council": Vector3(0.650, 0.132, 0.201),
	"p34_liquid_phase": Vector3(0.340, 0.350, 0.154),
	"p34_crystal_phase": Vector3(0.705, 0.353, 0.154),
	"p34_phase_cavern": Vector3(0.555, 0.541, 0.158),
	# Gently tighten around the upper crest, preserving its silhouette.
	"p34_new_hero": Vector3(0.226, 0.716, 0.112),
	"p34_ship_departure": Vector3(0.702, 0.804, 0.245)
}
const CHAPTER_FOUR_CAMERA_END: Dictionary = {
	# Keep the professor's face and the fluid guest inside the tub frame.
	"p41_professor_bath_walk": Vector3(0.349, 0.125, 0.177),
	"p41_professor_bath_rest": Vector3(0.685, 0.133, 0.176),
	"p41_phase_bath_surprise": Vector3(0.733, 0.368, 0.177),
	# Sweep from first dark attacker across the pair to Mika's little ship.
	"p41_pirate_ships": Vector3(0.758, 0.566, 0.137),
	"p41_flagship_threat": Vector3(0.520, 0.791, 0.240),
	"p42_pirates_capture": Vector3(0.748, 0.149, 0.217),
	"p42_station_prison": Vector3(0.365, 0.399, 0.155),
	"p42_lizard_interrogates": Vector3(0.676, 0.395, 0.151),
	"p42_lizard_changes_mind": Vector3(0.326, 0.588, 0.152),
	"p42_phase_in_cage": Vector3(0.680, 0.580, 0.152),
	"p42_run_to_ship": Vector3(0.712, 0.828, 0.224),
	"p43_cockpit_decision": Vector3(0.702, 0.162, 0.210),
	"p43_ship_landing": Vector3(0.296, 0.412, 0.166),
	"p43_scientist_meeting": Vector3(0.665, 0.401, 0.166),
	"p43_loading_fossils": Vector3(0.714, 0.641, 0.193),
	"p43_next_target": Vector3(0.336, 0.870, 0.182),
	"p43_space_departure": Vector3(0.751, 0.870, 0.182),
	"p44_professor_studies_fossil": Vector3(0.662, 0.161, 0.228),
	"p44_professor_realization": Vector3(0.253, 0.408, 0.143),
	"p44_dinosaur_dna": Vector3(0.686, 0.418, 0.151),
	"p44_ancient_dinosaurs": Vector3(0.704, 0.653, 0.234),
	"p44_ancient_meteorite": Vector3(0.702, 0.893, 0.170),
	"p45_ruins_entrance": Vector3(0.326, 0.139, 0.210),
	"p45_museum_walk": Vector3(0.728, 0.159, 0.236),
	"p45_professor_handshake": Vector3(0.350, 0.430, 0.229),
	"p45_evolution_display": Vector3(0.704, 0.441, 0.218),
	"p45_white_evolution": Vector3(0.750, 0.650, 0.104),
	"p45_scientists_farewell": Vector3(0.320, 0.858, 0.221),
	"p45_shadow_of_origin": Vector3(0.746, 0.805, 0.215)
}
const CHAPTER_FIVE_CAMERA_END: Dictionary = {
	# Preserve faces and ship while tracking between adjacent panels.
	"p51_cabin_alarm": Vector3(0.565, 0.164, 0.276),
	"p51_ship_lost": Vector3(0.270, 0.427, 0.188),
	"p51_gravity_world": Vector3(0.765, 0.429, 0.185),
	"p51_mika_frightened": Vector3(0.199, 0.622, 0.180),
	"p51_lizard_frightened": Vector3(0.502, 0.625, 0.183),
	"p51_pyramid_landing": Vector3(0.816, 0.633, 0.194),
	"p51_magnetic_creatures": Vector3(0.520, 0.855, 0.212),
	"p52_mika_earpiece": Vector3(0.197, 0.145, 0.198),
	"p52_magnetic_hall": Vector3(0.685, 0.148, 0.220),
	"p52_mika_meets_magnetic": Vector3(0.272, 0.471, 0.314),
	"p52_portal_discovery": Vector3(0.738, 0.470, 0.306),
	# After the real Pinball: a quiet farewell. Glide right on the same row
	# rather than cutting between PDF 5-2's neighbouring last two panels.
	"p52_mika_talks": Vector3(0.269, 0.848, 0.181),
	"p52_ship_departure": Vector3(0.743, 0.851, 0.202),
	# PDF 5-3, archive: approach the central pyramid, then the display / hands.
	"p53_archive_hall": Vector3(0.323, 0.153, 0.192),
	"p53_mika_console": Vector3(0.808, 0.174, 0.134),
	# History lesson: lateral reveal over the city, then track the evacuation ship.
	"p53_volcanic_city": Vector3(0.296, 0.467, 0.174),
	"p53_evacuating_ships": Vector3(0.734, 0.458, 0.152),
	# Grave event: tighten gently on the anomaly without losing the funnel.
	"p53_gravity_anomaly": Vector3(0.500, 0.789, 0.290),
	# PDF 5-4: read the network as a slow scan rather than zooming to one orb.
	"p54_galaxy_network": Vector3(0.531, 0.137, 0.208),
	# Across the alien meeting, settle near the shared hands / small entity.
	"p54_species_meet": Vector3(0.291, 0.387, 0.172),
	# The signal is a schematic: minimal breathing zoom only (no fake orbit).
	"p54_pulse_signal": Vector3(0.756, 0.385, 0.168),
	# Quiet danger: almost imperceptible approach to the black hole.
	"p54_black_hole": Vector3(0.313, 0.644, 0.185),
	# Farewell is about two faces: slide toward the magnetic companion.
	"p54_mika_farewell": Vector3(0.812, 0.637, 0.127),
	# Release: pull back to see the whole ship departing, not another zoom in.
	"p54_ship_departure": Vector3(0.510, 0.879, 0.206)
}
# The second panel is already visible at the edge of the previous PDF crop.
# Continue moving the SAME camera over the SAME sheet, without a hard cut.
const CONTINUOUS_PANS: Dictionary = {
	"p04_mika_walk": "p04_reception",
	"p04_elevator": "p04_ai_core",
	"p03_mika_upset": "p03_ship_refuel",
	"p03_earth_departure": "p03_mars_destination",
	"earth_view": "simulator",
	"earth_approach": "earth_spaceport",
	# Chapter 5: these are adjacent panels on the SAME original PDF sheet.
	# Move continuously across their row, but CUT at scene/row changes.
	"p51_mika_frightened": "p51_lizard_frightened",
	"p51_lizard_frightened": "p51_pyramid_landing",
	"p52_mika_earpiece": "p52_magnetic_hall",
	"p52_mika_meets_magnetic": "p52_portal_discovery",
	"p52_mika_talks": "p52_ship_departure",
	"p53_archive_hall": "p53_mika_console",
	"p53_volcanic_city": "p53_evacuating_ships",
	"p54_species_meet": "p54_pulse_signal",
	"p54_black_hole": "p54_mika_farewell",
	"p31_professor_sandwich": "p31_fungus_and_professor",
	"p31_okea_city": "p31_okea_meeting",
	"p31_okea_observes": "p31_okea_lizard_sad",
	"p31_okea_lizard_sad": "p31_okea_lizard_talks",
	"p32_cela_cave": "p32_cela_crystals",
	"p32_mika_surprised": "p32_professor_calls",
	"p33_mika_encounter": "p33_lotus_flower",
	"p34_liquid_phase": "p34_crystal_phase",
	"p43_next_target": "p43_space_departure",
	"p44_professor_realization": "p44_dinosaur_dna",
	"p45_ruins_entrance": "p45_museum_walk",
	"p45_professor_handshake": "p45_evolution_display",
	"p45_scientists_farewell": "p45_shadow_of_origin"
}
const CONTINUOUS_PAN_HANDOFF_SECONDS: float = 1.35
# The last Phasis farewell/departure pair needs a longer physical slide.
# The other row-to-row/cross-page cuts remain cuts.
const CONTINUOUS_PAN_SECONDS: Dictionary = {
    "p52_ship_departure": 2.10,
    "simulator": 0.65,
    "earth_spaceport": 0.80,
    "p03_ship_refuel": 0.72,
    "p03_mars_destination": 0.72,
    "p04_reception": 0.42,
    "p04_ai_core": 0.42
}
const PANEL_MAX_WIDTH: Dictionary = {
	"p03_puzzle_reveal": 0.910,
	"p03_mika_upset": 0.345,
	"p03_ship_refuel": 0.530,
	"p03_earth_departure": 0.635,
	"p03_mars_destination": 0.225,
	"p04_mars_landing": 0.915,
	"p04_mika_walk": 0.455,
	"p04_reception": 0.455,
	"p04_elevator": 0.455, "p04_ai_core": 0.455,
	"p04_mika_orb_close": 0.865,
	"p05_mika_orb": 0.900, "p05_mika_happy": 0.450, "p05_pink_city": 0.520,
	"p05_mika_shocked": 0.300, "p05_red_city": 0.300, "p05_mika_worried": 0.305,
	"p05_mika_sad": 0.465, "p05_mika_question": 0.465,
	"p06_pink_vortex": 0.390, "p06_mika_thinks": 0.495,
	"p06_galaxies_in_orb": 0.580, "p06_mika_smiles": 0.365,
	"p06_orb_whole": 0.580, "p06_bubble_elevator": 0.365,
	"p06_mika_bubble_runs": 0.468, "p06_ship_departure": 0.468,
	"p06_station_destination": 0.915
}

# Safe INSETS inside each original PDF panel. Moving/zooming must never reveal
# another panel, its white gutter, or a neighbouring scene. Positions are
# normalized to the full A4 source, verified against the three original PDFs.
const PANEL_SAFE_BOUNDS: Dictionary = {
	"p82_approach": Rect2(0.023000, 0.016000, 0.389000, 0.155000),
	"p82_portal": Rect2(0.402000, 0.016000, 0.575000, 0.155000),
	"p82_entry": Rect2(0.023000, 0.178000, 0.460000, 0.220000),
	"p82_change": Rect2(0.482000, 0.178000, 0.495000, 0.220000),
	"p82_transformation": Rect2(0.023000, 0.405000, 0.536000, 0.264000),
	"p82_beyond": Rect2(0.553000, 0.405000, 0.424000, 0.264000),
	"p82_new_space": Rect2(0.023000, 0.676000, 0.954000, 0.308000),
	"p81_palace": Rect2(0.028600, 0.020000, 0.942900, 0.209000),
	"p81_mika": Rect2(0.028600, 0.238400, 0.464000, 0.263000),
	"p81_bubble": Rect2(0.507000, 0.238400, 0.464000, 0.263000),
	"p81_friends": Rect2(0.028600, 0.510000, 0.942900, 0.219000),
	"p81_lizard": Rect2(0.028600, 0.738700, 0.464000, 0.241100),
	"p81_reply": Rect2(0.507000, 0.738700, 0.464000, 0.241100),
	"p71_ship": Rect2(0.028646, 0.021484, 0.941406, 0.224609),
	"p71_cabin": Rect2(0.028646, 0.265625, 0.416667, 0.231445),
	"p71_flight": Rect2(0.477865, 0.258789, 0.492188, 0.240234),
	"p71_mika_points": Rect2(0.028646, 0.511719, 0.505208, 0.208984),
	"p71_thought": Rect2(0.563802, 0.512695, 0.406250, 0.466797),
	"p71_planet": Rect2(0.028646, 0.740234, 0.494792, 0.239258),
	"p72_conversation": Rect2(0.029948, 0.022461, 0.937500, 0.307617),
	"p72_history": Rect2(0.031250, 0.356445, 0.934896, 0.195312),
	"p72_magnetic": Rect2(0.032552, 0.572266, 0.433594, 0.200195),
	"p72_worlds": Rect2(0.516927, 0.572266, 0.449219, 0.198242),
	"p72_neurons": Rect2(0.031250, 0.789062, 0.450521, 0.189453),
	"p72_mika": Rect2(0.520833, 0.785156, 0.445312, 0.194336),
	"p73_guide": Rect2(0.023438, 0.016602, 0.305990, 0.197266),
	"p73_flower": Rect2(0.346354, 0.016602, 0.305990, 0.197266),
	"p73_mika_form": Rect2(0.669271, 0.017578, 0.305990, 0.196289),
	"p73_evolution": Rect2(0.023438, 0.226562, 0.951823, 0.244141),
	"p73_storm": Rect2(0.023438, 0.482422, 0.951823, 0.243164),
	"p73_tunnel": Rect2(0.023438, 0.740234, 0.951823, 0.243164),
	"p74_planet_change": Rect2(0.040365, 0.029297, 0.529948, 0.260742),
	"p74_mika_future": Rect2(0.604167, 0.029297, 0.354167, 0.260742),
	"p74_routes": Rect2(0.041667, 0.308594, 0.351562, 0.273438),
	"p74_gate": Rect2(0.427083, 0.308594, 0.235677, 0.272461),
	"p74_living_world": Rect2(0.699219, 0.308594, 0.257812, 0.273438),
	"p74_doors": Rect2(0.007000, 0.598000, 0.986000, 0.397000),
	"p61_cabin": Rect2(0.022135, 0.012879, 0.954427, 0.252990),
	"p61_tunnel": Rect2(0.022135, 0.279669, 0.454427, 0.148114),
	"p61_planet": Rect2(0.539062, 0.278749, 0.437500, 0.152714),
	"p61_city": Rect2(0.023438, 0.448942, 0.953125, 0.326587),
	"p61_meeting": Rect2(0.023438, 0.795768, 0.437500, 0.188592),
	"p61_chair": Rect2(0.510417, 0.794848, 0.466146, 0.189512),
	"p62_ancient": Rect2(0.028646, 0.020239, 0.449219, 0.220791),
	"p62_blueprint": Rect2(0.532552, 0.020239, 0.437500, 0.220791),
	"p62_station": Rect2(0.028646, 0.253910, 0.315104, 0.218031),
	"p62_burst": Rect2(0.389323, 0.253910, 0.269531, 0.218031),
	"p62_hole": Rect2(0.707031, 0.253910, 0.263021, 0.218031),
	"p62_mika": Rect2(0.026042, 0.485741, 0.367188, 0.327507),
	"p62_clocks": Rect2(0.398438, 0.496780, 0.570312, 0.316467),
	"p62_galaxy": Rect2(0.028646, 0.826127, 0.218750, 0.154554),
	"p62_eclipse": Rect2(0.273438, 0.826127, 0.229167, 0.154554),
	"p62_planets": Rect2(0.537760, 0.826127, 0.217448, 0.154554),
	"p62_meteor": Rect2(0.792969, 0.826127, 0.177083, 0.154554),
	"p63_network": Rect2(0.028646, 0.020239, 0.941406, 0.334867),
	"p63_civilizations": Rect2(0.028646, 0.378105, 0.516927, 0.270469),
	"p63_storm": Rect2(0.578125, 0.378105, 0.391927, 0.270469),
	"p63_gate": Rect2(0.028646, 0.678013, 0.531250, 0.301748),
	"p63_hole": Rect2(0.605469, 0.678013, 0.364583, 0.301748),
	"p64_council": Rect2(0.028646, 0.020239, 0.941406, 0.118675),
	"p64_mika": Rect2(0.028646, 0.156394, 0.428385, 0.216191),
	"p64_route": Rect2(0.509115, 0.156394, 0.460938, 0.220791),
	"p64_wake": Rect2(0.028646, 0.392824, 0.428385, 0.224471),
	"p64_cockpit": Rect2(0.519531, 0.393744, 0.450521, 0.223551),
	"p64_talk": Rect2(0.028646, 0.637534, 0.427083, 0.217111),
	"p64_worlds": Rect2(0.520833, 0.637534, 0.449219, 0.217111),
	"p64_portal": Rect2(0.028646, 0.875805, 0.941406, 0.103956),
	"p04_mars_landing": Rect2(0.034, 0.025, 0.934, 0.169),
	"p04_mika_walk": Rect2(0.035, 0.216, 0.473, 0.184),
	"p04_reception": Rect2(0.531, 0.216, 0.434, 0.184),
	"p04_elevator": Rect2(0.035, 0.424, 0.470, 0.207),
	"p04_ai_core": Rect2(0.531, 0.424, 0.434, 0.207),
	"p04_mika_orb_close": Rect2(0.035, 0.663, 0.930, 0.308),
	"p05_mika_orb": Rect2(0.028, 0.024, 0.944, 0.226),
	"p05_mika_happy": Rect2(0.030, 0.273, 0.406, 0.217),
	"p05_pink_city": Rect2(0.464, 0.273, 0.507, 0.217),
	"p05_mika_shocked": Rect2(0.030, 0.511, 0.345, 0.226),
	"p05_red_city": Rect2(0.400, 0.511, 0.259, 0.226),
	# Mika leans OUT of the city panel and over the internal slanted border.
	"p05_mika_worried": Rect2(0.624, 0.511, 0.347, 0.226),
	"p05_mika_sad": Rect2(0.030, 0.764, 0.466, 0.207),
	"p05_mika_question": Rect2(0.525, 0.764, 0.447, 0.207),
	"p06_pink_vortex": Rect2(0.029, 0.025, 0.379, 0.171),
	"p06_mika_thinks": Rect2(0.432, 0.025, 0.537, 0.171),
	"p06_galaxies_in_orb": Rect2(0.029, 0.215, 0.577, 0.163),
	"p06_mika_smiles": Rect2(0.629, 0.215, 0.339, 0.163),
	"p06_orb_whole": Rect2(0.029, 0.398, 0.577, 0.190),
	"p06_bubble_elevator": Rect2(0.629, 0.398, 0.339, 0.190),
	"p06_mika_bubble_runs": Rect2(0.029, 0.610, 0.432, 0.179),
	"p06_ship_departure": Rect2(0.482, 0.610, 0.487, 0.179),
	"p06_station_destination": Rect2(0.029, 0.809, 0.941, 0.162),
	"p07_station_hangar": Rect2(0.040, 0.026, 0.472, 0.188),
	"p07_mika_staff": Rect2(0.537, 0.026, 0.424, 0.188),
	"p07_mika_worried": Rect2(0.039, 0.230, 0.645, 0.176),
	"p07_professor_arrives": Rect2(0.710, 0.230, 0.250, 0.176),
	"p07_professor_talks": Rect2(0.039, 0.428, 0.511, 0.199),
	"p07_ship_repair": Rect2(0.578, 0.428, 0.383, 0.199),
	"p07_lmc_window": Rect2(0.039, 0.645, 0.922, 0.322),
	"p21_flight_cabin": Rect2(0.027, 0.023, 0.673, 0.273),
	"p21_professor_door": Rect2(0.737, 0.023, 0.239, 0.273),
	# This is intentionally ONE panoramic row: city on the left, walking Mika
	# on the right, including the page's original narrow white frame divider.
	"p21_ocean_city": Rect2(0.027, 0.315, 0.948, 0.309),
	"p21_mika_enters": Rect2(0.027, 0.315, 0.948, 0.309),
	"p21_mika_meets_fungus": Rect2(0.027, 0.628, 0.948, 0.344),
	"p22_fungal_conversation": Rect2(0.027, 0.025, 0.950, 0.286),
	"p22_mika_calls_bubble": Rect2(0.027, 0.334, 0.950, 0.379),
	"p22_planet_departure": Rect2(0.027, 0.743, 0.950, 0.229),
	"p23_molly_orbit": Rect2(0.027, 0.019, 0.359, 0.255),
	"p23_ruins_meeting": Rect2(0.409, 0.020, 0.562, 0.255),
	"p23_mika_talks": Rect2(0.025, 0.291, 0.411, 0.265),
	"p23_plant_tutorial": Rect2(0.452, 0.291, 0.528, 0.265),
	"p23_loading_ship": Rect2(0.026, 0.590, 0.948, 0.387),
	"p24_station_exterior": Rect2(0.023, 0.019, 0.950, 0.113),
	"p24_fungal_garden": Rect2(0.022, 0.158, 0.565, 0.227),
	"p24_factory": Rect2(0.610, 0.157, 0.366, 0.097),
	"p24_reclaimed_city": Rect2(0.611, 0.268, 0.364, 0.116),
	"p24_fungus_portrait": Rect2(0.022, 0.411, 0.300, 0.324),
	"p24_meteor": Rect2(0.350, 0.411, 0.306, 0.117),
	"p24_mycelium_net": Rect2(0.350, 0.545, 0.306, 0.190),
	# Mika is deliberately NOT clamped to a narrow portrait panel. In portrait
	# orientation the camera can reveal neighbouring panels to keep his face.
	"p24_professor_and_fungus": Rect2(0.023, 0.754, 0.953, 0.224),
	# Page 3-2 gutters: use each pair as ONE horizontal tracking shot.
	"p32_cela_temple": Rect2(0.028, 0.031, 0.944, 0.281),
	"p32_cela_cave": Rect2(0.028, 0.326, 0.944, 0.179),
	"p32_cela_crystals": Rect2(0.028, 0.326, 0.944, 0.179),
	"p32_mika_surprised": Rect2(0.028, 0.524, 0.944, 0.179),
	"p32_professor_calls": Rect2(0.028, 0.524, 0.944, 0.179),
	"p32_lotus_route": Rect2(0.028, 0.729, 0.944, 0.242),
	"p33_cela_bubble": Rect2(0.028, 0.031, 0.944, 0.293),
	"p33_mika_encounter": Rect2(0.028, 0.348, 0.944, 0.261),
	"p33_lotus_flower": Rect2(0.028, 0.348, 0.944, 0.261),
	"p33_lotus_archive": Rect2(0.029, 0.629, 0.943, 0.341),
	"p34_lotus_council": Rect2(0.029, 0.028, 0.942, 0.221),
	"p34_liquid_phase": Rect2(0.029, 0.257, 0.942, 0.184),
	"p34_crystal_phase": Rect2(0.029, 0.257, 0.942, 0.184),
	"p34_phase_cavern": Rect2(0.249, 0.455, 0.491, 0.191),
	"p34_new_hero": Rect2(0.029, 0.657, 0.365, 0.313),
	"p34_ship_departure": Rect2(0.414, 0.657, 0.557, 0.313),
	"p41_professor_bath_walk": Rect2(0.029, 0.027, 0.464, 0.220),
	"p41_professor_bath_rest": Rect2(0.515, 0.027, 0.455, 0.220),
	"p41_phase_bath_surprise": Rect2(0.030, 0.259, 0.939, 0.221),
	"p41_pirate_ships": Rect2(0.030, 0.493, 0.939, 0.157),
	"p41_flagship_threat": Rect2(0.030, 0.660, 0.939, 0.310),
	"p42_pirates_capture": Rect2(0.030, 0.029, 0.939, 0.238),
	"p42_station_prison": Rect2(0.029, 0.282, 0.467, 0.190),
	"p42_lizard_interrogates": Rect2(0.514, 0.282, 0.456, 0.190),
	"p42_lizard_changes_mind": Rect2(0.029, 0.485, 0.467, 0.193),
	"p42_phase_in_cage": Rect2(0.514, 0.485, 0.456, 0.193),
	"p42_run_to_ship": Rect2(0.029, 0.690, 0.941, 0.279),
	"p43_cockpit_decision": Rect2(0.030, 0.028, 0.940, 0.268),
	"p43_ship_landing": Rect2(0.030, 0.309, 0.472, 0.205),
	"p43_scientist_meeting": Rect2(0.520, 0.309, 0.450, 0.205),
	"p43_loading_fossils": Rect2(0.030, 0.530, 0.940, 0.221),
	"p43_next_target": Rect2(0.030, 0.765, 0.535, 0.207),
	"p43_space_departure": Rect2(0.586, 0.765, 0.384, 0.207),
	"p44_professor_studies_fossil": Rect2(0.024, 0.018, 0.952, 0.305),
	"p44_professor_realization": Rect2(0.024, 0.337, 0.395, 0.170),
	"p44_dinosaur_dna": Rect2(0.440, 0.333, 0.535, 0.174),
	"p44_ancient_dinosaurs": Rect2(0.024, 0.523, 0.952, 0.262),
	"p44_ancient_meteorite": Rect2(0.024, 0.797, 0.952, 0.191),
	"p45_ruins_entrance": Rect2(0.023, 0.019, 0.524, 0.235),
	"p45_museum_walk": Rect2(0.575, 0.019, 0.400, 0.287),
	"p45_professor_handshake": Rect2(0.024, 0.276, 0.502, 0.296),
	"p45_evolution_display": Rect2(0.542, 0.310, 0.433, 0.260),
	"p45_white_evolution": Rect2(0.024, 0.594, 0.952, 0.122),
	"p45_scientists_farewell": Rect2(0.024, 0.732, 0.522, 0.250),
	"p45_shadow_of_origin": Rect2(0.570, 0.739, 0.405, 0.243),
	# Allow an adjacent panel on small screens rather than trim faces/heads.
	"p51_cabin_alarm": Rect2(0.020, 0.020, 0.960, 0.294),
	"p51_ship_lost": Rect2(0.020, 0.325, 0.955, 0.202),
	"p51_gravity_world": Rect2(0.020, 0.325, 0.955, 0.202),
	"p51_mika_frightened": Rect2(0.020, 0.530, 0.956, 0.210),
	"p51_lizard_frightened": Rect2(0.020, 0.530, 0.956, 0.210),
	"p51_pyramid_landing": Rect2(0.020, 0.530, 0.956, 0.210),
	"p51_magnetic_creatures": Rect2(0.020, 0.744, 0.957, 0.235),
	"p52_mika_earpiece": Rect2(0.020, 0.020, 0.958, 0.243),
	"p52_magnetic_hall": Rect2(0.020, 0.020, 0.958, 0.243),
	"p52_mika_meets_magnetic": Rect2(0.020, 0.278, 0.958, 0.429),
	"p52_portal_discovery": Rect2(0.020, 0.278, 0.958, 0.429),
	"p52_mika_talks": Rect2(0.020, 0.722, 0.958, 0.254),
	"p52_ship_departure": Rect2(0.020, 0.722, 0.958, 0.254),
	"p53_archive_hall": Rect2(0.018, 0.014, 0.560, 0.317),
	"p53_mika_console": Rect2(0.595, 0.014, 0.386, 0.317),
	"p53_volcanic_city": Rect2(0.018, 0.340, 0.505, 0.258),
	"p53_evacuating_ships": Rect2(0.537, 0.340, 0.446, 0.258),
	"p53_gravity_anomaly": Rect2(0.018, 0.611, 0.965, 0.378),
	"p54_galaxy_network": Rect2(0.018, 0.012, 0.965, 0.245),
	"p54_species_meet": Rect2(0.018, 0.266, 0.495, 0.242),
	"p54_pulse_signal": Rect2(0.528, 0.266, 0.454, 0.242),
	"p54_black_hole": Rect2(0.018, 0.520, 0.566, 0.240),
	"p54_mika_farewell": Rect2(0.597, 0.520, 0.386, 0.240),
	"p54_ship_departure": Rect2(0.018, 0.771, 0.965, 0.216)
}

var _artwork: ColorRect
var _material: ShaderMaterial
var _page_two_texture: Texture2D
var _page_three_texture: Texture2D
var _page_four_texture: Texture2D
var _page_five_texture: Texture2D
var _page_six_texture: Texture2D
var _page_seven_texture: Texture2D
var _ch02_page_one_texture: Texture2D
var _ch02_page_two_texture: Texture2D
var _ch02_page_three_texture: Texture2D
var _ch02_page_four_texture: Texture2D
var _ch03_page_one_texture: Texture2D
var _ch03_page_two_texture: Texture2D
var _ch03_page_three_texture: Texture2D
var _ch03_page_four_texture: Texture2D
var _ch04_page_one_texture: Texture2D
var _ch04_page_two_texture: Texture2D
var _ch04_page_three_texture: Texture2D
var _ch04_page_four_texture: Texture2D
var _ch04_page_five_texture: Texture2D
var _ch05_page_one_texture: Texture2D
var _ch05_page_two_texture: Texture2D
var _ch05_page_three_texture: Texture2D
var _ch05_page_four_texture: Texture2D
# MIKA_CH06_NATIVE_ROUTE_V1
var _ch06_texture: Texture2D
var _ch06_page: String = ""
var _ch01_p02_bridge: Node
var _ch01_p03_bridge: Node
var _ch01_p04_bridge: Node
var _ch01_p05_bridge: Node
var _ch01_p06_bridge: Node
var _ch01_p07_bridge: Node
var _ch02_p01_bridge: Node
var _ch02_p02_bridge: Node
var _ch02_p03_bridge: Node
var _ch02_p04_bridge: Node
var _ch03_p01_bridge: Node
var _ch03_p02_bridge: Node
var _ch03_p03_bridge: Node
var _ch03_p04_bridge: Node
var _ch04_p01_bridge: Node
var _ch04_p02_bridge: Node
var _ch04_p03_bridge: Node
var _ch04_p04_bridge: Node
var _ch04_p05_bridge: Node
var _ch05_p01_bridge: Node
var _ch05_p02_bridge: Node
var _ch05_p03_bridge: Node
var _ch05_p04_bridge: Node
# CH08_FINALE_NATIVE_BRIDGE_V1
const CH08_FINALE_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch08_finale_localized_voice.gd")
var _ch08_finale_bridge: Node
# CH08_P01_NATIVE_BRIDGE_V1
const CH08_P01_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch08_p01_localized_voice.gd")
var _ch08_p01_bridge: Node
# CH07_P03_NATIVE_BRIDGE_V1
const CH07_P03_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch07_p03_localized_voice.gd")
var _ch07_p03_bridge: Node
# CH07_P02_NATIVE_BRIDGE_V1
const CH07_P02_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch07_p02_localized_voice.gd")
var _ch07_p02_bridge: Node
# CH07_P01_NATIVE_BRIDGE_V1
const CH07_P01_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch07_p01_localized_voice.gd")
var _ch07_p01_bridge: Node
# CH06_P04_NATIVE_BRIDGE_V1
const CH06_P04_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch06_p04_localized_voice.gd")
var _ch06_p04_bridge: Node
# CH06_P03_NATIVE_BRIDGE_V1
const CH06_P03_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch06_p03_localized_voice.gd")
var _ch06_p03_bridge: Node
# CH06_P02_NATIVE_BRIDGE_V1
const CH06_P02_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch06_p02_localized_voice.gd")
var _ch06_p02_bridge: Node
# CH06_P01_NATIVE_BRIDGE_V1
const CH06_P01_BRIDGE: Script = preload("res://mika_motion_comic/scripts/ch06_p01_localized_voice.gd")
var _ch06_p01_bridge: Node
var _ch01_p02_auto_advance: bool = false
var _sequence: Array[String] = []
var _index: int = 0
var _elapsed: float = 0.0
var _is_playing: bool = false
var _continuous_camera_active: bool = false
var _continuous_camera_from: Vector3 = Vector3.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	visible = false
	_artwork = ColorRect.new()
	_artwork.name = "PageTwoSingleCompressedSheet"
	_artwork.color = Color.WHITE
	_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_artwork)
	_material = ShaderMaterial.new()
	_material.shader = PAGE_SHADER
	# The game can run directly from Terminal before Godot's editor has
	# imported this added WebP. A preload() would fail script compilation.
	# Decode the original sheet in memory in that case; exported builds may
	# instead use the engine's already imported texture.
	var page_texture: Texture2D = null
	if FileAccess.file_exists(PAGE_FILE):
		var sheet: Image = Image.new()
		var source_bytes: PackedByteArray = FileAccess.get_file_as_bytes(PAGE_FILE)
		if not source_bytes.is_empty() and sheet.load_webp_from_buffer(source_bytes) == OK:
			page_texture = ImageTexture.create_from_image(sheet)
	if page_texture == null:
		page_texture = load(PAGE_FILE) as Texture2D
	if page_texture == null:
		push_error("MIKA Story: could not open page two image: " + PAGE_FILE)
		return
	_page_two_texture = page_texture
	_ch01_p02_bridge = CH01_P02_BRIDGE.new() as Node
	add_child(_ch01_p02_bridge)
	_ch01_p02_bridge.call("attach_player", self)
	_ch01_p03_bridge = CH01_P03_BRIDGE.new() as Node
	add_child(_ch01_p03_bridge)
	_ch01_p03_bridge.call("attach_player", self)
	_ch01_p04_bridge = CH01_P04_BRIDGE.new() as Node
	add_child(_ch01_p04_bridge)
	_ch01_p04_bridge.call("attach_player", self)
	_ch01_p05_bridge = CH01_P05_BRIDGE.new() as Node
	add_child(_ch01_p05_bridge)
	_ch01_p05_bridge.call("attach_player", self)
	_ch01_p05_bridge.call("release_texture")
	_ch01_p06_bridge = CH01_P06_BRIDGE.new() as Node
	add_child(_ch01_p06_bridge)
	_ch01_p06_bridge.call("attach_player", self)
	_ch01_p06_bridge.call("release_texture")
	_ch01_p07_bridge = CH01_P07_BRIDGE.new() as Node
	add_child(_ch01_p07_bridge)
	_ch01_p07_bridge.call("attach_player", self)
	_ch01_p07_bridge.call("release_texture")
	_ch02_p01_bridge = CH02_P01_BRIDGE.new() as Node
	add_child(_ch02_p01_bridge)
	_ch02_p01_bridge.call("attach_player", self)
	_ch02_p01_bridge.call("release_texture")
	_ch02_p02_bridge = CH02_P02_BRIDGE.new() as Node
	add_child(_ch02_p02_bridge)
	_ch02_p02_bridge.call("attach_player", self)
	_ch02_p02_bridge.call("release_texture")
	_ch02_p03_bridge = CH02_P03_BRIDGE.new() as Node
	add_child(_ch02_p03_bridge)
	_ch02_p03_bridge.call("attach_player", self)
	_ch02_p03_bridge.call("release_texture")
	_ch02_p04_bridge = CH02_P04_BRIDGE.new() as Node
	add_child(_ch02_p04_bridge)
	_ch02_p04_bridge.call("attach_player", self)
	_ch02_p04_bridge.call("release_texture")
	_ch03_p01_bridge = CH03_P01_BRIDGE.new() as Node
	add_child(_ch03_p01_bridge)
	_ch03_p01_bridge.call("attach_player", self)
	_ch03_p01_bridge.call("release_texture")
	_ch03_p02_bridge = CH03_P02_BRIDGE.new() as Node
	add_child(_ch03_p02_bridge)
	_ch03_p02_bridge.call("attach_player", self)
	_ch03_p02_bridge.call("release_texture")
	_ch03_p03_bridge = CH03_P03_BRIDGE.new() as Node
	add_child(_ch03_p03_bridge)
	_ch03_p03_bridge.call("attach_player", self)
	_ch03_p03_bridge.call("release_texture")
	_ch03_p04_bridge = CH03_P04_BRIDGE.new() as Node
	add_child(_ch03_p04_bridge)
	_ch03_p04_bridge.call("attach_player", self)
	_ch03_p04_bridge.call("release_texture")
	_ch04_p01_bridge = CH04_P01_BRIDGE.new() as Node
	add_child(_ch04_p01_bridge)
	_ch04_p01_bridge.call("attach_player", self)
	_ch04_p01_bridge.call("release_texture")
	_ch04_p02_bridge = CH04_P02_BRIDGE.new() as Node
	add_child(_ch04_p02_bridge)
	_ch04_p02_bridge.call("attach_player", self)
	_ch04_p02_bridge.call("release_texture")
	_ch04_p03_bridge = CH04_P03_BRIDGE.new() as Node
	add_child(_ch04_p03_bridge)
	_ch04_p03_bridge.call("attach_player", self)
	_ch04_p03_bridge.call("release_texture")
	_ch04_p04_bridge = CH04_P04_BRIDGE.new() as Node
	add_child(_ch04_p04_bridge)
	_ch04_p04_bridge.call("attach_player", self)
	_ch04_p04_bridge.call("release_texture")
	_ch04_p05_bridge = CH04_P05_BRIDGE.new() as Node
	add_child(_ch04_p05_bridge)
	_ch04_p05_bridge.call("attach_player", self)
	_ch04_p05_bridge.call("release_texture")
	_ch05_p01_bridge = CH05_P01_BRIDGE.new() as Node
	add_child(_ch05_p01_bridge)
	_ch05_p01_bridge.call("attach_player", self)
	_ch05_p01_bridge.call("release_texture")
	_ch05_p02_bridge = CH05_P02_BRIDGE.new() as Node
	add_child(_ch05_p02_bridge)
	_ch05_p02_bridge.call("attach_player", self)
	_ch05_p02_bridge.call("release_texture")
	_ch05_p03_bridge = CH05_P03_BRIDGE.new() as Node
	add_child(_ch05_p03_bridge)
	_ch05_p03_bridge.call("attach_player", self)
	_ch05_p03_bridge.call("release_texture")
	_ch05_p04_bridge = CH05_P04_BRIDGE.new() as Node
	add_child(_ch05_p04_bridge)
	_ch05_p04_bridge.call("attach_player", self)
	_ch05_p04_bridge.call("release_texture")
	_ch08_finale_bridge = CH08_FINALE_BRIDGE.new() as Node
	add_child(_ch08_finale_bridge)
	_ch08_finale_bridge.call("attach_player", self)
	_ch08_finale_bridge.call("release_texture")
	_ch08_p01_bridge = CH08_P01_BRIDGE.new() as Node
	add_child(_ch08_p01_bridge)
	_ch08_p01_bridge.call("attach_player", self)
	_ch08_p01_bridge.call("release_texture")
	_ch07_p03_bridge = CH07_P03_BRIDGE.new() as Node
	add_child(_ch07_p03_bridge)
	_ch07_p03_bridge.call("attach_player", self)
	_ch07_p03_bridge.call("release_texture")
	_ch07_p02_bridge = CH07_P02_BRIDGE.new() as Node
	add_child(_ch07_p02_bridge)
	_ch07_p02_bridge.call("attach_player", self)
	_ch07_p02_bridge.call("release_texture")
	_ch07_p01_bridge = CH07_P01_BRIDGE.new() as Node
	add_child(_ch07_p01_bridge)
	_ch07_p01_bridge.call("attach_player", self)
	_ch07_p01_bridge.call("release_texture")
	_ch06_p04_bridge = CH06_P04_BRIDGE.new() as Node
	add_child(_ch06_p04_bridge)
	_ch06_p04_bridge.call("attach_player", self)
	_ch06_p04_bridge.call("release_texture")
	_ch06_p03_bridge = CH06_P03_BRIDGE.new() as Node
	add_child(_ch06_p03_bridge)
	_ch06_p03_bridge.call("attach_player", self)
	_ch06_p03_bridge.call("release_texture")
	_ch06_p02_bridge = CH06_P02_BRIDGE.new() as Node
	add_child(_ch06_p02_bridge)
	_ch06_p02_bridge.call("attach_player", self)
	_ch06_p02_bridge.call("release_texture")
	_ch06_p01_bridge = CH06_P01_BRIDGE.new() as Node
	add_child(_ch06_p01_bridge)
	_ch06_p01_bridge.call("attach_player", self)
	_ch06_p01_bridge.call("release_texture")
	var localized_page: Texture2D = _ch01_p02_bridge.call("selected_texture") as Texture2D
	if localized_page != null:
		_page_two_texture = localized_page
	_material.set_shader_parameter("artwork", _page_two_texture)
	_material.set_shader_parameter("page_aspect", PAGE_SIZE.x / PAGE_SIZE.y)
	_artwork.material = _material
	resized.connect(_update_camera)
	_update_camera()


func _prepare_page_three() -> void:
	# Keep the additional PDF sheet out of GPU memory until its first frame.
	if _page_three_texture != null:
		return
	if _ch01_p03_bridge != null:
		_page_three_texture = _ch01_p03_bridge.call("selected_texture") as Texture2D
	if _page_three_texture != null:
		return
	if FileAccess.file_exists(PAGE_THREE_FILE):
		var third_page: Image = Image.new()
		if third_page.load_webp_from_buffer(FileAccess.get_file_as_bytes(PAGE_THREE_FILE)) == OK:
			_page_three_texture = ImageTexture.create_from_image(third_page)
	if _page_three_texture == null:
		_page_three_texture = load(PAGE_THREE_FILE) as Texture2D
	if _page_three_texture == null:
		push_error("MIKA Story: could not open page three image: " + PAGE_THREE_FILE)


func _prepare_page_four() -> void:
	if _page_four_texture != null:
		return
	if _ch01_p04_bridge != null:
		_page_four_texture = _ch01_p04_bridge.call("selected_texture") as Texture2D
	if _page_four_texture != null:
		return
	if FileAccess.file_exists(PAGE_FOUR_FILE):
		var fourth_page: Image = Image.new()
		if fourth_page.load_webp_from_buffer(FileAccess.get_file_as_bytes(PAGE_FOUR_FILE)) == OK:
			_page_four_texture = ImageTexture.create_from_image(fourth_page)
	if _page_four_texture == null:
		_page_four_texture = load(PAGE_FOUR_FILE) as Texture2D
	if _page_four_texture == null:
		push_error("MIKA Story: could not open page four image: " + PAGE_FOUR_FILE)


func _prepare_page_five() -> void:
	if _page_five_texture != null:
		return
	if _ch01_p05_bridge != null:
		_page_five_texture = _ch01_p05_bridge.call("selected_texture") as Texture2D
		if _page_five_texture != null:
			return
	if FileAccess.file_exists(PAGE_FIVE_FILE):
		var fifth_page: Image = Image.new()
		if fifth_page.load_webp_from_buffer(FileAccess.get_file_as_bytes(PAGE_FIVE_FILE)) == OK:
			_page_five_texture = ImageTexture.create_from_image(fifth_page)
	if _page_five_texture == null:
		_page_five_texture = load(PAGE_FIVE_FILE) as Texture2D
	if _page_five_texture == null:
		push_error("MIKA Story: could not open page five image: " + PAGE_FIVE_FILE)


func _prepare_page_six() -> void:
	if _page_six_texture != null:
		return
	if _ch01_p06_bridge != null:
		_page_six_texture = _ch01_p06_bridge.call("selected_texture") as Texture2D
		if _page_six_texture != null:
			return
	if FileAccess.file_exists(PAGE_SIX_FILE):
		var sixth_page: Image = Image.new()
		if sixth_page.load_webp_from_buffer(FileAccess.get_file_as_bytes(PAGE_SIX_FILE)) == OK:
			_page_six_texture = ImageTexture.create_from_image(sixth_page)
	if _page_six_texture == null:
		_page_six_texture = load(PAGE_SIX_FILE) as Texture2D
	if _page_six_texture == null:
		push_error("MIKA Story: could not open page six image: " + PAGE_SIX_FILE)


func _prepare_page_seven() -> void:
	if _page_seven_texture != null:
		return
	if _ch01_p07_bridge != null:
		_page_seven_texture = _ch01_p07_bridge.call("selected_texture") as Texture2D
		if _page_seven_texture != null:
			return
	if FileAccess.file_exists(PAGE_SEVEN_FILE):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(PAGE_SEVEN_FILE)) == OK:
			_page_seven_texture = ImageTexture.create_from_image(sheet)
	if _page_seven_texture == null:
		_page_seven_texture = load(PAGE_SEVEN_FILE) as Texture2D
	if _page_seven_texture == null:
		push_error("MIKA Story: could not open page seven image: " + PAGE_SEVEN_FILE)


func _prepare_chapter_two_page(one: bool) -> void:
	var path: String = CHAPTER_TWO_PAGE_ONE if one else CHAPTER_TWO_PAGE_TWO
	if one and _ch02_page_one_texture != null:
		return
	if one and _ch02_p01_bridge != null:
		_ch02_page_one_texture = _ch02_p01_bridge.call("selected_texture") as Texture2D
		if _ch02_page_one_texture != null:
			return
	if not one and _ch02_page_two_texture != null:
		return
	if not one and _ch02_p02_bridge != null:
		_ch02_page_two_texture = _ch02_p02_bridge.call("selected_texture") as Texture2D
		if _ch02_page_two_texture != null:
			return
	var result: Texture2D = null
	if FileAccess.file_exists(path):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			result = ImageTexture.create_from_image(sheet)
	if result == null:
		result = load(path) as Texture2D
	if result == null:
		push_error("MIKA Story: could not open chapter-two comic image: " + path)
	if one:
		_ch02_page_one_texture = result
	else:
		_ch02_page_two_texture = result


func _prepare_chapter_two_page_three() -> void:
	if _ch02_page_three_texture != null:
		return
	if _ch02_p03_bridge != null:
		_ch02_page_three_texture = _ch02_p03_bridge.call("selected_texture") as Texture2D
		if _ch02_page_three_texture != null:
			return
	if FileAccess.file_exists(CHAPTER_TWO_PAGE_THREE):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(CHAPTER_TWO_PAGE_THREE)) == OK:
			_ch02_page_three_texture = ImageTexture.create_from_image(sheet)
	if _ch02_page_three_texture == null:
		_ch02_page_three_texture = load(CHAPTER_TWO_PAGE_THREE) as Texture2D
	if _ch02_page_three_texture == null:
		push_error("MIKA Story: missing original PDF 2-3 artwork: " + CHAPTER_TWO_PAGE_THREE)


func _prepare_chapter_two_page_four() -> void:
	if _ch02_page_four_texture != null:
		return
	if _ch02_p04_bridge != null:
		_ch02_page_four_texture = _ch02_p04_bridge.call("selected_texture") as Texture2D
		if _ch02_page_four_texture != null:
			return
	if FileAccess.file_exists(CHAPTER_TWO_PAGE_FOUR):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(CHAPTER_TWO_PAGE_FOUR)) == OK:
			_ch02_page_four_texture = ImageTexture.create_from_image(sheet)
	if _ch02_page_four_texture == null:
		_ch02_page_four_texture = load(CHAPTER_TWO_PAGE_FOUR) as Texture2D
	if _ch02_page_four_texture == null:
		push_error("MIKA Story: missing original PDF 2-4 artwork: " + CHAPTER_TWO_PAGE_FOUR)


func _prepare_chapter_three_page_one() -> void:
	if _ch03_page_one_texture != null:
		return
	if _ch03_p01_bridge != null:
		_ch03_page_one_texture = _ch03_p01_bridge.call("selected_texture") as Texture2D
		if _ch03_page_one_texture != null:
			return
	if FileAccess.file_exists(CHAPTER_THREE_PAGE_ONE):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(CHAPTER_THREE_PAGE_ONE)) == OK:
			_ch03_page_one_texture = ImageTexture.create_from_image(sheet)
	if _ch03_page_one_texture == null:
		_ch03_page_one_texture = load(CHAPTER_THREE_PAGE_ONE) as Texture2D
	if _ch03_page_one_texture == null:
		push_error("MIKA Story: missing original PDF 3-1 artwork: " + CHAPTER_THREE_PAGE_ONE)


func _prepare_chapter_three_page(path: String, second: bool) -> void:
	if second and _ch03_page_two_texture != null:
		return
	if not second and _ch03_page_three_texture != null:
		return
	if second and _ch03_p02_bridge != null:
		_ch03_page_two_texture = _ch03_p02_bridge.call("selected_texture") as Texture2D
		if _ch03_page_two_texture != null:
			return
	if not second and _ch03_p03_bridge != null:
		_ch03_page_three_texture = _ch03_p03_bridge.call("selected_texture") as Texture2D
		if _ch03_page_three_texture != null:
			return
	var result: Texture2D = null
	if FileAccess.file_exists(path):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			result = ImageTexture.create_from_image(sheet)
	if result == null:
		result = load(path) as Texture2D
	if result == null:
		push_error("MIKA Story: missing original chapter-three PDF artwork: " + path)
	if second:
		_ch03_page_two_texture = result
	else:
		_ch03_page_three_texture = result


func _prepare_chapter_three_page_four() -> void:
	if _ch03_page_four_texture != null:
		return
	if _ch03_p04_bridge != null:
		_ch03_page_four_texture = _ch03_p04_bridge.call("selected_texture") as Texture2D
		if _ch03_page_four_texture != null:
			return
	if FileAccess.file_exists(CHAPTER_THREE_PAGE_FOUR):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(CHAPTER_THREE_PAGE_FOUR)) == OK:
			_ch03_page_four_texture = ImageTexture.create_from_image(sheet)
	if _ch03_page_four_texture == null:
		_ch03_page_four_texture = load(CHAPTER_THREE_PAGE_FOUR) as Texture2D
	if _ch03_page_four_texture == null:
		push_error("MIKA Story: missing original PDF 3-4 artwork: " + CHAPTER_THREE_PAGE_FOUR)


func _prepare_chapter_four_page(two: bool) -> void:
	if two and _ch04_page_two_texture != null:
		return
	if two and _ch04_p02_bridge != null:
		_ch04_page_two_texture = _ch04_p02_bridge.call("selected_texture") as Texture2D
		if _ch04_page_two_texture != null:
			return
	if not two and _ch04_page_one_texture != null:
		return
	if not two and _ch04_p01_bridge != null:
		_ch04_page_one_texture = _ch04_p01_bridge.call("selected_texture") as Texture2D
		if _ch04_page_one_texture != null:
			return
	var path: String = CHAPTER_FOUR_PAGE_TWO if two else CHAPTER_FOUR_PAGE_ONE
	var result: Texture2D = null
	if FileAccess.file_exists(path):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			result = ImageTexture.create_from_image(sheet)
	if result == null:
		result = load(path) as Texture2D
	if result == null:
		push_error("MIKA Story: missing original chapter-four PDF artwork: " + path)
	if two:
		_ch04_page_two_texture = result
	else:
		_ch04_page_one_texture = result


func _prepare_chapter_four_page_three() -> void:
	if _ch04_page_three_texture != null:
		return
	if _ch04_p03_bridge != null:
		_ch04_page_three_texture = _ch04_p03_bridge.call("selected_texture") as Texture2D
		if _ch04_page_three_texture != null:
			return
	if FileAccess.file_exists(CHAPTER_FOUR_PAGE_THREE):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(CHAPTER_FOUR_PAGE_THREE)) == OK:
			_ch04_page_three_texture = ImageTexture.create_from_image(sheet)
	if _ch04_page_three_texture == null:
		_ch04_page_three_texture = load(CHAPTER_FOUR_PAGE_THREE) as Texture2D
	if _ch04_page_three_texture == null:
		push_error("MIKA Story: missing original PDF 4-3 artwork: " + CHAPTER_FOUR_PAGE_THREE)


func _prepare_chapter_four_later_page(four: bool) -> void:
	if four and _ch04_page_four_texture != null:
		return
	if four and _ch04_p04_bridge != null:
		_ch04_page_four_texture = _ch04_p04_bridge.call("selected_texture") as Texture2D
		if _ch04_page_four_texture != null:
			return
	if not four and _ch04_page_five_texture != null:
		return
	if not four and _ch04_p05_bridge != null:
		_ch04_page_five_texture = _ch04_p05_bridge.call("selected_texture") as Texture2D
		if _ch04_page_five_texture != null:
			return
	var path: String = CHAPTER_FOUR_PAGE_FOUR if four else CHAPTER_FOUR_PAGE_FIVE
	var result: Texture2D = null
	if FileAccess.file_exists(path):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			result = ImageTexture.create_from_image(sheet)
	if result == null:
		result = load(path) as Texture2D
	if result == null:
		push_error("MIKA Story: missing original chapter-four PDF artwork: " + path)
	if four:
		_ch04_page_four_texture = result
	else:
		_ch04_page_five_texture = result


func _prepare_chapter_five_page(one: bool) -> void:
	var path: String = CHAPTER_FIVE_PAGE_ONE if one else CHAPTER_FIVE_PAGE_TWO
	if (one and _ch05_page_one_texture != null) or (not one and _ch05_page_two_texture != null):
		return
	if one and _ch05_p01_bridge != null:
		_ch05_page_one_texture = _ch05_p01_bridge.call("selected_texture") as Texture2D
		if _ch05_page_one_texture != null:
			return
	if not one and _ch05_p02_bridge != null:
		_ch05_page_two_texture = _ch05_p02_bridge.call("selected_texture") as Texture2D
		if _ch05_page_two_texture != null:
			return
	# Direct WebP decode: no compile-time preload before the first Godot import.
	var texture: Texture2D = null
	if FileAccess.file_exists(path):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			texture = ImageTexture.create_from_image(sheet)
	if texture == null:
		texture = load(path) as Texture2D
	if texture == null:
		push_error("MIKA Story: missing Chapter 5 PDF artwork " + path)
	if one:
		_ch05_page_one_texture = texture
	else:
		_ch05_page_two_texture = texture


func _prepare_chapter_five_later_page(three: bool) -> void:
	var path: String = CHAPTER_FIVE_PAGE_THREE if three else CHAPTER_FIVE_PAGE_FOUR
	if (three and _ch05_page_three_texture != null) or (not three and _ch05_page_four_texture != null):
		return
	if three and _ch05_p03_bridge != null:
		_ch05_page_three_texture = _ch05_p03_bridge.call("selected_texture") as Texture2D
		if _ch05_page_three_texture != null:
			return
	if not three and _ch05_p04_bridge != null:
		_ch05_page_four_texture = _ch05_p04_bridge.call("selected_texture") as Texture2D
		if _ch05_page_four_texture != null:
			return
	var texture: Texture2D = null
	if FileAccess.file_exists(path):
		var sheet: Image = Image.new()
		if sheet.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			texture = ImageTexture.create_from_image(sheet)
	if texture == null:
		texture = load(path) as Texture2D
	if texture == null:
		push_error("MIKA Story: missing original Chapter 5 PDF page: " + path)
	if three:
		_ch05_page_three_texture = texture
	else:
		_ch05_page_four_texture = texture


func _prepare_panel_artwork(panel_id: String) -> void:
	if _ch08_finale_bridge != null and bool(_ch08_finale_bridge.call("handles", panel_id)):
		return # localized whole page is owned by the shared bridge
	if panel_id.begins_with("p81_") and _ch08_p01_bridge != null:
		return # localized whole page is owned by the shared bridge
	if panel_id.begins_with("p73_") and _ch07_p03_bridge != null:
		return # localized whole page is owned by the shared bridge
	if panel_id.begins_with("p72_") and _ch07_p02_bridge != null:
		return # localized whole page is owned by the shared bridge
	if panel_id.begins_with("p71_") and _ch07_p01_bridge != null:
		return # localized whole page is owned by the shared bridge
	if panel_id.begins_with("p64_") and _ch06_p04_bridge != null:
		return # localized whole page is owned by the shared bridge
	if panel_id.begins_with("p63_") and _ch06_p03_bridge != null:
		return # localized whole page is owned by the shared bridge
	if panel_id.begins_with("p62_") and _ch06_p02_bridge != null:
		return # localized whole page is owned by the shared bridge
	if panel_id.begins_with("p61_") and _ch06_p01_bridge != null:
		return # localized whole page is owned by the shared bridge
	if _ch06_is_panel(panel_id):
		_ch06_prepare(panel_id)
		return
	# Decode at the PAGE boundary, not all PDFs at the start of a long story.
	# A single A4 WebP is ~35 MB once decoded; mobile should hold only one.
	if panel_id.begins_with("p03_"):
		_prepare_page_three()
	elif panel_id.begins_with("p04_"):
		_prepare_page_four()
	elif panel_id.begins_with("p05_"):
		_prepare_page_five()
	elif panel_id.begins_with("p06_"):
		_prepare_page_six()
	elif panel_id.begins_with("p07_"):
		_prepare_page_seven()
	elif panel_id.begins_with("p21_"):
		_prepare_chapter_two_page(true)
	elif panel_id.begins_with("p22_"):
		_prepare_chapter_two_page(false)
	elif panel_id.begins_with("p23_"):
		_prepare_chapter_two_page_three()
	elif panel_id.begins_with("p24_"):
		_prepare_chapter_two_page_four()
	elif panel_id.begins_with("p31_"):
		_prepare_chapter_three_page_one()
	elif panel_id.begins_with("p32_"):
		_prepare_chapter_three_page(CHAPTER_THREE_PAGE_TWO, true)
	elif panel_id.begins_with("p33_"):
		_prepare_chapter_three_page(CHAPTER_THREE_PAGE_THREE, false)
	elif panel_id.begins_with("p34_"):
		_prepare_chapter_three_page_four()
	elif panel_id.begins_with("p41_"):
		_prepare_chapter_four_page(false)
	elif panel_id.begins_with("p42_"):
		_prepare_chapter_four_page(true)
	elif panel_id.begins_with("p43_"):
		_prepare_chapter_four_page_three()
	elif panel_id.begins_with("p44_"):
		_prepare_chapter_four_later_page(true)
	elif panel_id.begins_with("p45_"):
		_prepare_chapter_four_later_page(false)
	elif panel_id.begins_with("p51_"):
		_prepare_chapter_five_page(true)
	elif panel_id.begins_with("p52_"):
		_prepare_chapter_five_page(false)
	elif panel_id.begins_with("p53_"):
		_prepare_chapter_five_later_page(true)
	elif panel_id.begins_with("p54_"):
		_prepare_chapter_five_later_page(false)


func _release_previous_page(previous_id: String, current_id: String) -> void:
	if _ch08_finale_bridge != null and bool(_ch08_finale_bridge.call("handles", previous_id)) and not bool(_ch08_finale_bridge.call("handles", current_id)):
		_ch08_finale_bridge.call("stop_sequence")
		_ch08_finale_bridge.call("release_texture")
	if previous_id.begins_with("p81_") and not current_id.begins_with("p81_") and _ch08_p01_bridge != null:
		_ch08_p01_bridge.call("stop_sequence")
		_ch08_p01_bridge.call("release_texture")
	if previous_id.begins_with("p73_") and not current_id.begins_with("p73_") and _ch07_p03_bridge != null:
		_ch07_p03_bridge.call("stop_sequence")
		_ch07_p03_bridge.call("release_texture")
	if previous_id.begins_with("p72_") and not current_id.begins_with("p72_") and _ch07_p02_bridge != null:
		_ch07_p02_bridge.call("stop_sequence")
		_ch07_p02_bridge.call("release_texture")
	if previous_id.begins_with("p71_") and not current_id.begins_with("p71_") and _ch07_p01_bridge != null:
		_ch07_p01_bridge.call("stop_sequence")
		_ch07_p01_bridge.call("release_texture")
	if previous_id.begins_with("p64_") and not current_id.begins_with("p64_") and _ch06_p04_bridge != null:
		_ch06_p04_bridge.call("stop_sequence")
		_ch06_p04_bridge.call("release_texture")
	if previous_id.begins_with("p63_") and not current_id.begins_with("p63_") and _ch06_p03_bridge != null:
		_ch06_p03_bridge.call("stop_sequence")
		_ch06_p03_bridge.call("release_texture")
	if previous_id.begins_with("p62_") and not current_id.begins_with("p62_") and _ch06_p02_bridge != null:
		_ch06_p02_bridge.call("stop_sequence")
		_ch06_p02_bridge.call("release_texture")
	if previous_id.begins_with("p61_") and not current_id.begins_with("p61_") and _ch06_p01_bridge != null:
		_ch06_p01_bridge.call("stop_sequence")
		_ch06_p01_bridge.call("release_texture")
	if _ch06_is_panel(previous_id) and not _ch06_is_panel(current_id):
		_ch06_texture = null
		_ch06_page = ""
	if previous_id.begins_with("p03_") and not current_id.begins_with("p03_"):
		_page_three_texture = null
		if _ch01_p03_bridge != null:
			_ch01_p03_bridge.call("release_texture")
	elif previous_id.begins_with("p04_") and not current_id.begins_with("p04_"):
		_page_four_texture = null
		if _ch01_p04_bridge != null:
			_ch01_p04_bridge.call("release_texture")
	elif previous_id.begins_with("p05_") and not current_id.begins_with("p05_"):
		_page_five_texture = null
		if _ch01_p05_bridge != null:
			_ch01_p05_bridge.call("release_texture")
	elif previous_id.begins_with("p06_") and not current_id.begins_with("p06_"):
		_page_six_texture = null
		if _ch01_p06_bridge != null:
			_ch01_p06_bridge.call("release_texture")
	elif previous_id.begins_with("p07_") and not current_id.begins_with("p07_"):
		_page_seven_texture = null
		if _ch01_p07_bridge != null:
			_ch01_p07_bridge.call("release_texture")
	elif previous_id.begins_with("p21_") and not current_id.begins_with("p21_"):
		_ch02_page_one_texture = null
		if _ch02_p01_bridge != null:
			_ch02_p01_bridge.call("release_texture")
	elif previous_id.begins_with("p22_") and not current_id.begins_with("p22_"):
		_ch02_page_two_texture = null
		if _ch02_p02_bridge != null:
			_ch02_p02_bridge.call("release_texture")
	elif previous_id.begins_with("p23_") and not current_id.begins_with("p23_"):
		_ch02_page_three_texture = null
		if _ch02_p03_bridge != null:
			_ch02_p03_bridge.call("release_texture")
	elif previous_id.begins_with("p24_") and not current_id.begins_with("p24_"):
		_ch02_page_four_texture = null
		if _ch02_p04_bridge != null:
			_ch02_p04_bridge.call("release_texture")
	elif previous_id.begins_with("p31_") and not current_id.begins_with("p31_"):
		_ch03_page_one_texture = null
		if _ch03_p01_bridge != null:
			_ch03_p01_bridge.call("release_texture")
	elif previous_id.begins_with("p32_") and not current_id.begins_with("p32_"):
		_ch03_page_two_texture = null
		if _ch03_p02_bridge != null:
			_ch03_p02_bridge.call("release_texture")
	elif previous_id.begins_with("p33_") and not current_id.begins_with("p33_"):
		_ch03_page_three_texture = null
		if _ch03_p03_bridge != null:
			_ch03_p03_bridge.call("release_texture")
	elif previous_id.begins_with("p34_") and not current_id.begins_with("p34_"):
		_ch03_page_four_texture = null
		if _ch03_p04_bridge != null:
			_ch03_p04_bridge.call("release_texture")
	elif previous_id.begins_with("p41_") and not current_id.begins_with("p41_"):
		_ch04_page_one_texture = null
		if _ch04_p01_bridge != null:
			_ch04_p01_bridge.call("release_texture")
	elif previous_id.begins_with("p42_") and not current_id.begins_with("p42_"):
		_ch04_page_two_texture = null
		if _ch04_p02_bridge != null:
			_ch04_p02_bridge.call("release_texture")
	elif previous_id.begins_with("p43_") and not current_id.begins_with("p43_"):
		_ch04_page_three_texture = null
		if _ch04_p03_bridge != null:
			_ch04_p03_bridge.call("release_texture")
	elif previous_id.begins_with("p44_") and not current_id.begins_with("p44_"):
		_ch04_page_four_texture = null
		if _ch04_p04_bridge != null:
			_ch04_p04_bridge.call("release_texture")
	elif previous_id.begins_with("p45_") and not current_id.begins_with("p45_"):
		_ch04_page_five_texture = null
		if _ch04_p05_bridge != null:
			_ch04_p05_bridge.call("release_texture")
	elif previous_id.begins_with("p51_") and not current_id.begins_with("p51_"):
		_ch05_page_one_texture = null
		if _ch05_p01_bridge != null:
			_ch05_p01_bridge.call("release_texture")
	elif previous_id.begins_with("p52_") and not current_id.begins_with("p52_"):
		_ch05_page_two_texture = null
		if _ch05_p02_bridge != null:
			_ch05_p02_bridge.call("release_texture")
	elif previous_id.begins_with("p53_") and not current_id.begins_with("p53_"):
		_ch05_page_three_texture = null
		if _ch05_p03_bridge != null:
			_ch05_p03_bridge.call("release_texture")
	elif previous_id.begins_with("p54_") and not current_id.begins_with("p54_"):
		_ch05_page_four_texture = null
		if _ch05_p04_bridge != null:
			_ch05_p04_bridge.call("release_texture")

func begin_sequence(panels: Array) -> void:
	_sequence.clear()
	for panel_value in panels:
		var panel_id: String = str(panel_value)
		if CAMERA.has(panel_id):
			_sequence.append(panel_id)
		else:
			push_error("Unknown page-two panel: " + panel_id)
	_index = 0
	_elapsed = 0.0
	_continuous_camera_active = false
	_is_playing = not _sequence.is_empty()
	visible = not _sequence.is_empty()
	if not _sequence.is_empty():
		_prepare_panel_artwork(_sequence[0])
	if _ch01_p02_bridge != null:
		_ch01_p02_bridge.call("begin_sequence", _sequence)
	if _ch01_p03_bridge != null:
		_ch01_p03_bridge.call("begin_sequence", _sequence)
	if _ch01_p04_bridge != null:
		_ch01_p04_bridge.call("begin_sequence", _sequence)
	if _ch01_p05_bridge != null:
		_ch01_p05_bridge.call("begin_sequence", _sequence)
	if _ch01_p06_bridge != null:
		_ch01_p06_bridge.call("begin_sequence", _sequence)
	if _ch01_p07_bridge != null:
		_ch01_p07_bridge.call("begin_sequence", _sequence)
	if _ch02_p01_bridge != null:
		_ch02_p01_bridge.call("begin_sequence", _sequence)
	if _ch02_p02_bridge != null:
		_ch02_p02_bridge.call("begin_sequence", _sequence)
	if _ch02_p03_bridge != null:
		_ch02_p03_bridge.call("begin_sequence", _sequence)
	if _ch02_p04_bridge != null:
		_ch02_p04_bridge.call("begin_sequence", _sequence)
	if _ch03_p01_bridge != null:
		_ch03_p01_bridge.call("begin_sequence", _sequence)
	if _ch03_p02_bridge != null:
		_ch03_p02_bridge.call("begin_sequence", _sequence)
	if _ch03_p03_bridge != null:
		_ch03_p03_bridge.call("begin_sequence", _sequence)
	if _ch03_p04_bridge != null:
		_ch03_p04_bridge.call("begin_sequence", _sequence)
	if _ch04_p01_bridge != null:
		_ch04_p01_bridge.call("begin_sequence", _sequence)
	if _ch04_p02_bridge != null:
		_ch04_p02_bridge.call("begin_sequence", _sequence)
	if _ch04_p03_bridge != null:
		_ch04_p03_bridge.call("begin_sequence", _sequence)
	if _ch04_p04_bridge != null:
		_ch04_p04_bridge.call("begin_sequence", _sequence)
	if _ch04_p05_bridge != null:
		_ch04_p05_bridge.call("begin_sequence", _sequence)
	if _ch05_p01_bridge != null:
		_ch05_p01_bridge.call("begin_sequence", _sequence)
	if _ch05_p02_bridge != null:
		_ch05_p02_bridge.call("begin_sequence", _sequence)
	if _ch05_p03_bridge != null:
		_ch05_p03_bridge.call("begin_sequence", _sequence)
	if _ch05_p04_bridge != null:
		_ch05_p04_bridge.call("begin_sequence", _sequence)
	if _ch08_finale_bridge != null:
		_ch08_finale_bridge.call("begin_sequence", _sequence)
	if _ch08_p01_bridge != null:
		_ch08_p01_bridge.call("begin_sequence", _sequence)
	if _ch07_p03_bridge != null:
		_ch07_p03_bridge.call("begin_sequence", _sequence)
	if _ch07_p02_bridge != null:
		_ch07_p02_bridge.call("begin_sequence", _sequence)
	if _ch07_p01_bridge != null:
		_ch07_p01_bridge.call("begin_sequence", _sequence)
	if _ch06_p04_bridge != null:
		_ch06_p04_bridge.call("begin_sequence", _sequence)
	if _ch06_p03_bridge != null:
		_ch06_p03_bridge.call("begin_sequence", _sequence)
	if _ch06_p02_bridge != null:
		_ch06_p02_bridge.call("begin_sequence", _sequence)
	if _ch06_p01_bridge != null:
		_ch06_p01_bridge.call("begin_sequence", _sequence)
	_update_camera()
	if _sequence.is_empty():
		sequence_completed.emit()

func end_sequence() -> void:
	if _ch08_finale_bridge != null:
		_ch08_finale_bridge.call("stop_sequence")
		_ch08_finale_bridge.call("release_texture")
	if _ch08_p01_bridge != null:
		_ch08_p01_bridge.call("stop_sequence")
		_ch08_p01_bridge.call("release_texture")
	if _ch07_p03_bridge != null:
		_ch07_p03_bridge.call("stop_sequence")
		_ch07_p03_bridge.call("release_texture")
	if _ch07_p02_bridge != null:
		_ch07_p02_bridge.call("stop_sequence")
		_ch07_p02_bridge.call("release_texture")
	if _ch07_p01_bridge != null:
		_ch07_p01_bridge.call("stop_sequence")
		_ch07_p01_bridge.call("release_texture")
	if _ch06_p04_bridge != null:
		_ch06_p04_bridge.call("stop_sequence")
		_ch06_p04_bridge.call("release_texture")
	if _ch06_p03_bridge != null:
		_ch06_p03_bridge.call("stop_sequence")
		_ch06_p03_bridge.call("release_texture")
	if _ch06_p02_bridge != null:
		_ch06_p02_bridge.call("stop_sequence")
		_ch06_p02_bridge.call("release_texture")
	if _ch06_p01_bridge != null:
		_ch06_p01_bridge.call("stop_sequence")
		_ch06_p01_bridge.call("release_texture")
	_ch06_texture = null
	_ch06_page = ""
	if _ch01_p02_bridge != null:
		_ch01_p02_bridge.call("stop_sequence")
	if _ch01_p03_bridge != null:
		_ch01_p03_bridge.call("stop_sequence")
		_ch01_p03_bridge.call("release_texture")
	if _ch01_p04_bridge != null:
		_ch01_p04_bridge.call("stop_sequence")
		_ch01_p04_bridge.call("release_texture")
	if _ch01_p05_bridge != null:
		_ch01_p05_bridge.call("stop_sequence")
		_ch01_p05_bridge.call("release_texture")
	if _ch01_p06_bridge != null:
		_ch01_p06_bridge.call("stop_sequence")
		_ch01_p06_bridge.call("release_texture")
	if _ch01_p07_bridge != null:
		_ch01_p07_bridge.call("stop_sequence")
		_ch01_p07_bridge.call("release_texture")
	if _ch02_p01_bridge != null:
		_ch02_p01_bridge.call("stop_sequence")
		_ch02_p01_bridge.call("release_texture")
	if _ch02_p02_bridge != null:
		_ch02_p02_bridge.call("stop_sequence")
		_ch02_p02_bridge.call("release_texture")
	if _ch02_p03_bridge != null:
		_ch02_p03_bridge.call("stop_sequence")
		_ch02_p03_bridge.call("release_texture")
	if _ch02_p04_bridge != null:
		_ch02_p04_bridge.call("stop_sequence")
		_ch02_p04_bridge.call("release_texture")
	if _ch03_p01_bridge != null:
		_ch03_p01_bridge.call("stop_sequence")
		_ch03_p01_bridge.call("release_texture")
	if _ch03_p02_bridge != null:
		_ch03_p02_bridge.call("stop_sequence")
		_ch03_p02_bridge.call("release_texture")
	if _ch03_p03_bridge != null:
		_ch03_p03_bridge.call("stop_sequence")
		_ch03_p03_bridge.call("release_texture")
	if _ch03_p04_bridge != null:
		_ch03_p04_bridge.call("stop_sequence")
		_ch03_p04_bridge.call("release_texture")
	if _ch04_p01_bridge != null:
		_ch04_p01_bridge.call("stop_sequence")
		_ch04_p01_bridge.call("release_texture")
	if _ch04_p02_bridge != null:
		_ch04_p02_bridge.call("stop_sequence")
		_ch04_p02_bridge.call("release_texture")
	if _ch04_p03_bridge != null:
		_ch04_p03_bridge.call("stop_sequence")
		_ch04_p03_bridge.call("release_texture")
	if _ch04_p04_bridge != null:
		_ch04_p04_bridge.call("stop_sequence")
		_ch04_p04_bridge.call("release_texture")
	if _ch04_p05_bridge != null:
		_ch04_p05_bridge.call("stop_sequence")
		_ch04_p05_bridge.call("release_texture")
	if _ch05_p01_bridge != null:
		_ch05_p01_bridge.call("stop_sequence")
		_ch05_p01_bridge.call("release_texture")
	if _ch05_p02_bridge != null:
		_ch05_p02_bridge.call("stop_sequence")
		_ch05_p02_bridge.call("release_texture")
	if _ch05_p03_bridge != null:
		_ch05_p03_bridge.call("stop_sequence")
		_ch05_p03_bridge.call("release_texture")
	if _ch05_p04_bridge != null:
		_ch05_p04_bridge.call("stop_sequence")
		_ch05_p04_bridge.call("release_texture")
	visible = false
	_sequence.clear()
	_index = 0
	_elapsed = 0.0
	_is_playing = false
	_continuous_camera_active = false
	if _material != null and _page_two_texture != null:
		_material.set_shader_parameter("artwork", _page_two_texture)
	_page_three_texture = null
	_page_four_texture = null
	_page_five_texture = null
	_page_six_texture = null
	_page_seven_texture = null
	_ch02_page_one_texture = null
	_ch02_page_two_texture = null
	_ch02_page_three_texture = null
	_ch02_page_four_texture = null
	_ch03_page_one_texture = null
	_ch03_page_two_texture = null
	_ch03_page_three_texture = null
	_ch03_page_four_texture = null
	_ch04_page_one_texture = null
	_ch04_page_two_texture = null
	_ch04_page_three_texture = null
	_ch04_page_four_texture = null
	_ch04_page_five_texture = null
	_ch05_page_one_texture = null
	_ch05_page_two_texture = null
	_ch05_page_three_texture = null
	_ch05_page_four_texture = null

func advance_panel() -> void:
	if _ch08_finale_bridge != null and bool(_ch08_finale_bridge.call("intercept_advance")):
		return
	if not _sequence.is_empty() and _index >= 0 and _index < _sequence.size():
		var ru_bridge: Node = _ru_active_bridge(_sequence[_index])
		# Automatic playback must wait for the current line. A user pressing the
		# forward button is an explicit skip: panel_advanced() stops that clip and
		# starts the next panel's camera-first sequence.
		if _ch01_p02_auto_advance and ru_bridge != null and not bool(ru_bridge.call("ru_panel_done")):
			return

	if not visible or _sequence.is_empty():
		return
	if _index + 1 < _sequence.size():
		var previous_id: String = _sequence[_index]
		var next_id: String = _sequence[_index + 1]
		# MIKA_CH06_CH07_COMIC_FLOW_V2 — preserve continuous movement on one PDF sheet.
		var same_comic_page: bool = _ch06_is_panel(previous_id) and _ch06_is_panel(next_id) and previous_id.substr(0, 3) == next_id.substr(0, 3)
		_continuous_camera_active = _material != null and (str(CONTINUOUS_PANS.get(previous_id, "")) == next_id or same_comic_page)
		if _continuous_camera_active:
			# Capture the rendered camera, including portrait crop corrections.
			var previous_focus: Vector2 = _material.get_shader_parameter("focus") as Vector2
			_continuous_camera_from = Vector3(previous_focus.x, previous_focus.y, float(_material.get_shader_parameter("crop_height")))
		_index += 1
		_elapsed = 0.0
		_prepare_panel_artwork(_sequence[_index])
		if _ch01_p02_bridge != null:
			_ch01_p02_bridge.call("panel_advanced", previous_id, _sequence[_index], not _ch01_p02_auto_advance)
		if _ch01_p03_bridge != null:
			_ch01_p03_bridge.call("panel_advanced", previous_id, _sequence[_index], not _ch01_p02_auto_advance)
		if _ch01_p04_bridge != null:
			_ch01_p04_bridge.call("panel_advanced", previous_id, _sequence[_index], not _ch01_p02_auto_advance)
		if _ch01_p05_bridge != null:
			if next_id.begins_with("p05_") and not previous_id.begins_with("p05_"):
				_ch01_p05_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p05_"):
				_ch01_p05_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch01_p06_bridge != null:
			if next_id.begins_with("p06_") and not previous_id.begins_with("p06_"):
				_ch01_p06_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p06_"):
				_ch01_p06_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch01_p07_bridge != null:
			if next_id.begins_with("p07_") and not previous_id.begins_with("p07_"):
				_ch01_p07_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p07_"):
				_ch01_p07_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch02_p01_bridge != null:
			if next_id.begins_with("p21_") and not previous_id.begins_with("p21_"):
				_ch02_p01_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p21_"):
				_ch02_p01_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch02_p02_bridge != null:
			if next_id.begins_with("p22_") and not previous_id.begins_with("p22_"):
				_ch02_p02_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p22_"):
				_ch02_p02_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch02_p03_bridge != null:
			if next_id.begins_with("p23_") and not previous_id.begins_with("p23_"):
				_ch02_p03_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p23_"):
				_ch02_p03_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch02_p04_bridge != null:
			if next_id.begins_with("p24_") and not previous_id.begins_with("p24_"):
				_ch02_p04_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p24_"):
				_ch02_p04_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch03_p01_bridge != null:
			if next_id.begins_with("p31_") and not previous_id.begins_with("p31_"):
				_ch03_p01_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p31_"):
				_ch03_p01_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch03_p02_bridge != null:
			if next_id.begins_with("p32_") and not previous_id.begins_with("p32_"):
				_ch03_p02_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p32_"):
				_ch03_p02_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch03_p03_bridge != null:
			if next_id.begins_with("p33_") and not previous_id.begins_with("p33_"):
				_ch03_p03_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p33_"):
				_ch03_p03_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch03_p04_bridge != null:
			if next_id.begins_with("p34_") and not previous_id.begins_with("p34_"):
				_ch03_p04_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p34_"):
				_ch03_p04_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch04_p01_bridge != null:
			if next_id.begins_with("p41_") and not previous_id.begins_with("p41_"):
				_ch04_p01_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p41_"):
				_ch04_p01_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch04_p02_bridge != null:
			if next_id.begins_with("p42_") and not previous_id.begins_with("p42_"):
				_ch04_p02_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p42_"):
				_ch04_p02_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch04_p03_bridge != null:
			if next_id.begins_with("p43_") and not previous_id.begins_with("p43_"):
				_ch04_p03_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p43_"):
				_ch04_p03_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch04_p04_bridge != null:
			if next_id.begins_with("p44_") and not previous_id.begins_with("p44_"):
				_ch04_p04_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p44_"):
				_ch04_p04_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch04_p05_bridge != null:
			if next_id.begins_with("p45_") and not previous_id.begins_with("p45_"):
				_ch04_p05_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p45_"):
				_ch04_p05_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch05_p01_bridge != null:
			if next_id.begins_with("p51_") and not previous_id.begins_with("p51_"):
				_ch05_p01_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p51_"):
				_ch05_p01_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch05_p02_bridge != null:
			if next_id.begins_with("p52_") and not previous_id.begins_with("p52_"):
				_ch05_p02_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p52_"):
				_ch05_p02_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch05_p03_bridge != null:
			if next_id.begins_with("p53_") and not previous_id.begins_with("p53_"):
				_ch05_p03_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p53_"):
				_ch05_p03_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch05_p04_bridge != null:
			if next_id.begins_with("p54_") and not previous_id.begins_with("p54_"):
				_ch05_p04_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p54_"):
				_ch05_p04_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch08_finale_bridge != null:
			if bool(_ch08_finale_bridge.call("handles", next_id)) and not bool(_ch08_finale_bridge.call("handles", previous_id)):
				_ch08_finale_bridge.call("begin_sequence", [next_id])
			elif bool(_ch08_finale_bridge.call("handles", previous_id)):
				_ch08_finale_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch08_p01_bridge != null:
			if next_id.begins_with("p81_") and not previous_id.begins_with("p81_"):
				_ch08_p01_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p81_"):
				_ch08_p01_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch07_p03_bridge != null:
			if next_id.begins_with("p73_") and not previous_id.begins_with("p73_"):
				_ch07_p03_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p73_"):
				_ch07_p03_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch07_p02_bridge != null:
			if next_id.begins_with("p72_") and not previous_id.begins_with("p72_"):
				_ch07_p02_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p72_"):
				_ch07_p02_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch07_p01_bridge != null:
			if next_id.begins_with("p71_") and not previous_id.begins_with("p71_"):
				_ch07_p01_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p71_"):
				_ch07_p01_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch06_p04_bridge != null:
			if next_id.begins_with("p64_") and not previous_id.begins_with("p64_"):
				_ch06_p04_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p64_"):
				_ch06_p04_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch06_p03_bridge != null:
			if next_id.begins_with("p63_") and not previous_id.begins_with("p63_"):
				_ch06_p03_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p63_"):
				_ch06_p03_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch06_p02_bridge != null:
			if next_id.begins_with("p62_") and not previous_id.begins_with("p62_"):
				_ch06_p02_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p62_"):
				_ch06_p02_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		if _ch06_p01_bridge != null:
			if next_id.begins_with("p61_") and not previous_id.begins_with("p61_"):
				_ch06_p01_bridge.call("begin_sequence", [next_id])
			elif previous_id.begins_with("p61_"):
				_ch06_p01_bridge.call("panel_advanced", previous_id, next_id, not _ch01_p02_auto_advance)
		_update_camera()
		_release_previous_page(previous_id, _sequence[_index])
		return
	end_sequence()
	sequence_completed.emit()

func _process(delta: float) -> void:
	if not _is_playing or not visible or _sequence.is_empty():
		return
	if _ch06_p01_bridge != null and bool(_ch06_p01_bridge.call("is_active_for", _sequence[_index])):
		_ch06_p01_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch06_p01_bridge.call("camera_committed", delta)
		if float(_ch06_p01_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch06_p02_bridge != null and bool(_ch06_p02_bridge.call("is_active_for", _sequence[_index])):
		_ch06_p02_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch06_p02_bridge.call("camera_committed", delta)
		if float(_ch06_p02_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch06_p03_bridge != null and bool(_ch06_p03_bridge.call("is_active_for", _sequence[_index])):
		_ch06_p03_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch06_p03_bridge.call("camera_committed", delta)
		if float(_ch06_p03_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch06_p04_bridge != null and bool(_ch06_p04_bridge.call("is_active_for", _sequence[_index])):
		_ch06_p04_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch06_p04_bridge.call("camera_committed", delta)
		if float(_ch06_p04_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch07_p01_bridge != null and bool(_ch07_p01_bridge.call("is_active_for", _sequence[_index])):
		_ch07_p01_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch07_p01_bridge.call("camera_committed", delta)
		if float(_ch07_p01_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch07_p02_bridge != null and bool(_ch07_p02_bridge.call("is_active_for", _sequence[_index])):
		_ch07_p02_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch07_p02_bridge.call("camera_committed", delta)
		if float(_ch07_p02_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch07_p03_bridge != null and bool(_ch07_p03_bridge.call("is_active_for", _sequence[_index])):
		_ch07_p03_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch07_p03_bridge.call("camera_committed", delta)
		if float(_ch07_p03_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch08_p01_bridge != null and bool(_ch08_p01_bridge.call("is_active_for", _sequence[_index])):
		_ch08_p01_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch08_p01_bridge.call("camera_committed", delta)
		if float(_ch08_p01_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch08_finale_bridge != null and bool(_ch08_finale_bridge.call("is_active_for", _sequence[_index])):
		_ch08_finale_bridge.call("tick_before_camera", delta)
		_update_camera()
		_ch08_finale_bridge.call("camera_committed", delta)
		if float(_ch08_finale_bridge.call("frame_duration", _sequence[_index], 1.0)) <= 0.0:
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	if _ch06_is_panel(str(_sequence[_index])):
		_elapsed += delta
		_update_camera()
		if _elapsed >= float(FRAME_SECONDS[_sequence[_index]]):
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	var ru_bridge: Node = _ru_active_bridge(_sequence[_index])
	if ru_bridge != null:
		ru_bridge.call("tick_before_camera", delta)
		_update_camera()
		ru_bridge.call("camera_committed", delta)
		if bool(ru_bridge.call("ru_panel_done")):
			_ch01_p02_auto_advance = true
			advance_panel()
			_ch01_p02_auto_advance = false
		return
	_elapsed += delta
	# CH01_CAMERA_FIRST_V21: parent owns camera/voice sequence, not child _process.
	var camera_first_bridge: Node = null
	var camera_first_panel: String = _sequence[_index]
	if _ch01_p02_bridge != null and bool(_ch01_p02_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch01_p02_bridge
	elif _ch01_p03_bridge != null and bool(_ch01_p03_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch01_p03_bridge
	elif _ch01_p04_bridge != null and bool(_ch01_p04_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch01_p04_bridge
	elif _ch01_p05_bridge != null and bool(_ch01_p05_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch01_p05_bridge
	elif _ch01_p06_bridge != null and bool(_ch01_p06_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch01_p06_bridge
	elif _ch01_p07_bridge != null and bool(_ch01_p07_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch01_p07_bridge
	elif _ch02_p01_bridge != null and bool(_ch02_p01_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch02_p01_bridge
	elif _ch02_p02_bridge != null and bool(_ch02_p02_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch02_p02_bridge
	elif _ch02_p03_bridge != null and bool(_ch02_p03_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch02_p03_bridge
	elif _ch02_p04_bridge != null and bool(_ch02_p04_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch02_p04_bridge
	elif _ch03_p01_bridge != null and bool(_ch03_p01_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch03_p01_bridge
	elif _ch03_p02_bridge != null and bool(_ch03_p02_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch03_p02_bridge
	elif _ch03_p03_bridge != null and bool(_ch03_p03_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch03_p03_bridge
	elif _ch03_p04_bridge != null and bool(_ch03_p04_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch03_p04_bridge
	elif _ch04_p01_bridge != null and bool(_ch04_p01_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch04_p01_bridge
	elif _ch04_p02_bridge != null and bool(_ch04_p02_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch04_p02_bridge
	elif _ch04_p03_bridge != null and bool(_ch04_p03_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch04_p03_bridge
	elif _ch04_p04_bridge != null and bool(_ch04_p04_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch04_p04_bridge
	elif _ch04_p05_bridge != null and bool(_ch04_p05_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch04_p05_bridge
	elif _ch05_p01_bridge != null and bool(_ch05_p01_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch05_p01_bridge
	elif _ch05_p02_bridge != null and bool(_ch05_p02_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch05_p02_bridge
	elif _ch05_p03_bridge != null and bool(_ch05_p03_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch05_p03_bridge
	elif _ch05_p04_bridge != null and bool(_ch05_p04_bridge.call("is_active_for", camera_first_panel)):
		camera_first_bridge = _ch05_p04_bridge
	if camera_first_bridge != null:
		camera_first_bridge.call("tick_before_camera", delta)
	# P04 voice is authoritative for elapsed time in both separated comic beats.
	if _ch01_p04_bridge != null:
		_elapsed = float(_ch01_p04_bridge.call("sync_elapsed", _sequence[_index], _elapsed))
	# CH01_P02_P03_AUDIO_CLOCK_V12: sync both post-game comic pages to MP3.
	var current_panel: String = _sequence[_index]
	if _ch01_p02_bridge != null:
		_elapsed = float(_ch01_p02_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch01_p03_bridge != null:
		_elapsed = float(_ch01_p03_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch01_p05_bridge != null:
		_elapsed = float(_ch01_p05_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch01_p06_bridge != null:
		_elapsed = float(_ch01_p06_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch01_p07_bridge != null:
		_elapsed = float(_ch01_p07_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch02_p01_bridge != null:
		_elapsed = float(_ch02_p01_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch02_p02_bridge != null:
		_elapsed = float(_ch02_p02_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch02_p03_bridge != null:
		_elapsed = float(_ch02_p03_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch02_p04_bridge != null:
		_elapsed = float(_ch02_p04_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch03_p01_bridge != null:
		_elapsed = float(_ch03_p01_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch03_p02_bridge != null:
		_elapsed = float(_ch03_p02_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch03_p03_bridge != null:
		_elapsed = float(_ch03_p03_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch03_p04_bridge != null:
		_elapsed = float(_ch03_p04_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch04_p01_bridge != null:
		_elapsed = float(_ch04_p01_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch04_p02_bridge != null:
		_elapsed = float(_ch04_p02_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch04_p03_bridge != null:
		_elapsed = float(_ch04_p03_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch04_p04_bridge != null:
		_elapsed = float(_ch04_p04_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch04_p05_bridge != null:
		_elapsed = float(_ch04_p05_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch05_p01_bridge != null:
		_elapsed = float(_ch05_p01_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch05_p02_bridge != null:
		_elapsed = float(_ch05_p02_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch05_p03_bridge != null:
		_elapsed = float(_ch05_p03_bridge.call("sync_elapsed", current_panel, _elapsed))
	if _ch05_p04_bridge != null:
		_elapsed = float(_ch05_p04_bridge.call("sync_elapsed", current_panel, _elapsed))
	if camera_first_bridge != null or _continuous_camera_active or CH01_P02_CAMERA_END.has(_sequence[_index]) or LOWER_PANEL_END.has(_sequence[_index]) or PAGE_THREE_CAMERA_END.has(_sequence[_index]) or PAGE_FOUR_CAMERA_END.has(_sequence[_index]) or PAGE_FIVE_CAMERA_END.has(_sequence[_index]) or PAGE_SIX_CAMERA_END.has(_sequence[_index]) or PAGE_SEVEN_CAMERA_END.has(_sequence[_index]) or CHAPTER_TWO_CAMERA_END.has(_sequence[_index]) or CHAPTER_TWO_THREE_CAMERA_END.has(_sequence[_index]) or CHAPTER_TWO_FOUR_CAMERA_END.has(_sequence[_index]) or CHAPTER_THREE_CAMERA_END.has(_sequence[_index]) or CHAPTER_THREE_TWO_CAMERA_END.has(_sequence[_index]) or CHAPTER_THREE_THREE_CAMERA_END.has(_sequence[_index]) or CHAPTER_THREE_FOUR_CAMERA_END.has(_sequence[_index]) or CHAPTER_FOUR_CAMERA_END.has(_sequence[_index]) or CHAPTER_FIVE_CAMERA_END.has(_sequence[_index]):
		_update_camera()
	# Only after the shader was updated may the next audio be unlocked.
	if camera_first_bridge != null:
		camera_first_bridge.call("camera_committed", delta)
	var frame_duration: float = float(FRAME_SECONDS.get(_sequence[_index], 4.5))
	if _ch01_p02_bridge != null:
		frame_duration = float(_ch01_p02_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch01_p03_bridge != null:
		frame_duration = float(_ch01_p03_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch01_p04_bridge != null:
		frame_duration = float(_ch01_p04_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch01_p05_bridge != null:
		frame_duration = float(_ch01_p05_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch01_p06_bridge != null:
		frame_duration = float(_ch01_p06_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch01_p07_bridge != null:
		frame_duration = float(_ch01_p07_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch02_p01_bridge != null:
		frame_duration = float(_ch02_p01_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch02_p02_bridge != null:
		frame_duration = float(_ch02_p02_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch02_p03_bridge != null:
		frame_duration = float(_ch02_p03_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch02_p04_bridge != null:
		frame_duration = float(_ch02_p04_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch03_p01_bridge != null:
		frame_duration = float(_ch03_p01_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch03_p02_bridge != null:
		frame_duration = float(_ch03_p02_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch03_p03_bridge != null:
		frame_duration = float(_ch03_p03_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch03_p04_bridge != null:
		frame_duration = float(_ch03_p04_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch04_p01_bridge != null:
		frame_duration = float(_ch04_p01_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch04_p02_bridge != null:
		frame_duration = float(_ch04_p02_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch04_p03_bridge != null:
		frame_duration = float(_ch04_p03_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch04_p04_bridge != null:
		frame_duration = float(_ch04_p04_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch04_p05_bridge != null:
		frame_duration = float(_ch04_p05_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch05_p01_bridge != null:
		frame_duration = float(_ch05_p01_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch05_p02_bridge != null:
		frame_duration = float(_ch05_p02_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch05_p03_bridge != null:
		frame_duration = float(_ch05_p03_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _ch05_p04_bridge != null:
		frame_duration = float(_ch05_p04_bridge.call("frame_duration", _sequence[_index], frame_duration))
	if _elapsed >= frame_duration:
		_ch01_p02_auto_advance = true
		advance_panel()
		_ch01_p02_auto_advance = false


func _talos_city_pan_target_x() -> float:
	# On landscape, include the city AND the right-hand walking panel.
	# On portrait devices, pan farther right so Mika remains in the viewport.
	var viewport_ratio: float = size.x / maxf(1.0, size.y)
	var portrait_weight: float = clampf((1.75 - viewport_ratio) / 1.27, 0.0, 1.0)
	return lerpf(0.586, 0.840, portrait_weight)

func _update_camera() -> void:
	if _material == null:
		return
	if size.x > 1.0 and size.y > 1.0:
		_material.set_shader_parameter("viewport_aspect", size.x / size.y)
	if _sequence.is_empty():
		return
	var panel_id: String = _sequence[_index]
	if _ch06_p01_bridge != null and bool(_ch06_p01_bridge.call("is_active_for", panel_id)):
		var p61_texture: Texture2D = _ch06_p01_bridge.call("selected_texture") as Texture2D
		var p61_shot: Vector3 = _ch06_p01_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p61_texture != null:
			_material.set_shader_parameter("artwork", p61_texture)
			_material.set_shader_parameter("focus", Vector2(p61_shot.x, p61_shot.y))
			_material.set_shader_parameter("crop_height", p61_shot.z)
			return
	if _ch06_p02_bridge != null and bool(_ch06_p02_bridge.call("is_active_for", panel_id)):
		var p62_texture: Texture2D = _ch06_p02_bridge.call("selected_texture") as Texture2D
		var p62_shot: Vector3 = _ch06_p02_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p62_texture != null:
			_material.set_shader_parameter("artwork", p62_texture)
			_material.set_shader_parameter("focus", Vector2(p62_shot.x, p62_shot.y))
			_material.set_shader_parameter("crop_height", p62_shot.z)
			return
	if _ch06_p03_bridge != null and bool(_ch06_p03_bridge.call("is_active_for", panel_id)):
		var p63_texture: Texture2D = _ch06_p03_bridge.call("selected_texture") as Texture2D
		var p63_shot: Vector3 = _ch06_p03_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p63_texture != null:
			_material.set_shader_parameter("artwork", p63_texture)
			_material.set_shader_parameter("focus", Vector2(p63_shot.x, p63_shot.y))
			_material.set_shader_parameter("crop_height", p63_shot.z)
			return
	if _ch06_p04_bridge != null and bool(_ch06_p04_bridge.call("is_active_for", panel_id)):
		var p64_texture: Texture2D = _ch06_p04_bridge.call("selected_texture") as Texture2D
		var p64_shot: Vector3 = _ch06_p04_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p64_texture != null:
			_material.set_shader_parameter("artwork", p64_texture)
			_material.set_shader_parameter("focus", Vector2(p64_shot.x, p64_shot.y))
			_material.set_shader_parameter("crop_height", p64_shot.z)
			return
	if _ch07_p01_bridge != null and bool(_ch07_p01_bridge.call("is_active_for", panel_id)):
		var p71_texture: Texture2D = _ch07_p01_bridge.call("selected_texture") as Texture2D
		var p71_shot: Vector3 = _ch07_p01_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p71_texture != null:
			_material.set_shader_parameter("artwork", p71_texture)
			_material.set_shader_parameter("focus", Vector2(p71_shot.x, p71_shot.y))
			_material.set_shader_parameter("crop_height", p71_shot.z)
			return
	if _ch07_p02_bridge != null and bool(_ch07_p02_bridge.call("is_active_for", panel_id)):
		var p72_texture: Texture2D = _ch07_p02_bridge.call("selected_texture") as Texture2D
		var p72_shot: Vector3 = _ch07_p02_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p72_texture != null:
			_material.set_shader_parameter("artwork", p72_texture)
			_material.set_shader_parameter("focus", Vector2(p72_shot.x, p72_shot.y))
			_material.set_shader_parameter("crop_height", p72_shot.z)
			return
	if _ch07_p03_bridge != null and bool(_ch07_p03_bridge.call("is_active_for", panel_id)):
		var p73_texture: Texture2D = _ch07_p03_bridge.call("selected_texture") as Texture2D
		var p73_shot: Vector3 = _ch07_p03_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p73_texture != null:
			_material.set_shader_parameter("artwork", p73_texture)
			_material.set_shader_parameter("focus", Vector2(p73_shot.x, p73_shot.y))
			_material.set_shader_parameter("crop_height", p73_shot.z)
			return
	if _ch08_p01_bridge != null and bool(_ch08_p01_bridge.call("is_active_for", panel_id)):
		var p81_texture: Texture2D = _ch08_p01_bridge.call("selected_texture") as Texture2D
		var p81_shot: Vector3 = _ch08_p01_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p81_texture != null:
			_material.set_shader_parameter("artwork", p81_texture)
			_material.set_shader_parameter("focus", Vector2(p81_shot.x, p81_shot.y))
			_material.set_shader_parameter("crop_height", p81_shot.z)
			return
	if _ch08_finale_bridge != null and bool(_ch08_finale_bridge.call("is_active_for", panel_id)):
		var p82_texture: Texture2D = _ch08_finale_bridge.call("selected_texture") as Texture2D
		var p82_shot: Vector3 = _ch08_finale_bridge.call("camera_state", panel_id, _elapsed, size, false, Vector3.ZERO)
		if p82_texture != null:
			_material.set_shader_parameter("artwork", p82_texture)
			_material.set_shader_parameter("focus", Vector2(p82_shot.x, p82_shot.y))
			_material.set_shader_parameter("crop_height", p82_shot.z)
			return
	if _ch06_is_panel(panel_id):
		_ch06_draw_camera(panel_id)
		return
	var ru_bridge: Node = _ru_active_bridge(panel_id)
	if ru_bridge != null:
		var ru_texture: Texture2D = ru_bridge.call("selected_texture") as Texture2D
		var ru_shot: Vector3 = ru_bridge.call("camera_state", panel_id, 0.0, size, false, Vector3.ZERO)
		if ru_texture != null:
			_material.set_shader_parameter("artwork", ru_texture)
		_material.set_shader_parameter("focus", Vector2(ru_shot.x, ru_shot.y))
		_material.set_shader_parameter("crop_height", ru_shot.z)
		return
	var artwork: Texture2D = _page_two_texture
	if panel_id.begins_with("p03_"):
		artwork = _page_three_texture
	elif panel_id.begins_with("p04_"):
		artwork = _page_four_texture
	elif panel_id.begins_with("p05_"):
		artwork = _page_five_texture
	elif panel_id.begins_with("p06_"):
		artwork = _page_six_texture
	elif panel_id.begins_with("p07_"):
		artwork = _page_seven_texture
	elif panel_id.begins_with("p21_"):
		artwork = _ch02_page_one_texture
	elif panel_id.begins_with("p22_"):
		artwork = _ch02_page_two_texture
	elif panel_id.begins_with("p23_"):
		artwork = _ch02_page_three_texture
	elif panel_id.begins_with("p24_"):
		artwork = _ch02_page_four_texture
	elif panel_id.begins_with("p31_"):
		artwork = _ch03_page_one_texture
	elif panel_id.begins_with("p32_"):
		artwork = _ch03_page_two_texture
	elif panel_id.begins_with("p33_"):
		artwork = _ch03_page_three_texture
	elif panel_id.begins_with("p34_"):
		artwork = _ch03_page_four_texture
	elif panel_id.begins_with("p41_"):
		artwork = _ch04_page_one_texture
	elif panel_id.begins_with("p42_"):
		artwork = _ch04_page_two_texture
	elif panel_id.begins_with("p43_"):
		artwork = _ch04_page_three_texture
	elif panel_id.begins_with("p44_"):
		artwork = _ch04_page_four_texture
	elif panel_id.begins_with("p45_"):
		artwork = _ch04_page_five_texture
	elif panel_id.begins_with("p51_"):
		artwork = _ch05_page_one_texture
	elif panel_id.begins_with("p52_"):
		artwork = _ch05_page_two_texture
	elif panel_id.begins_with("p53_"):
		artwork = _ch05_page_three_texture
	elif panel_id.begins_with("p54_"):
		artwork = _ch05_page_four_texture
	if artwork != null:
		_material.set_shader_parameter("artwork", artwork)
	var camera: Vector3 = CH01_P02_CAMERA_START.get(panel_id, CAMERA[_sequence[_index]])
	var focus: Vector2 = Vector2(camera.x, camera.y)
	var crop_height: float = camera.z
	# These two original wide PDF frames need a sideways *pan* on portrait
	# phones: no portrait crop can show both distant actors at once.
	var molly_portrait_weight: float = clampf((1.45 - size.x / maxf(size.y, 1.0)) / 0.80, 0.0, 1.0)
	if panel_id == "p23_plant_tutorial":
		focus.x = lerpf(focus.x, 0.594, molly_portrait_weight)
	elif panel_id == "p23_loading_ship":
		focus.x = lerpf(focus.x, 0.215, molly_portrait_weight)
	elif panel_id == "p24_professor_and_fungus":
		focus.x = lerpf(focus.x, 0.232, molly_portrait_weight)
	elif panel_id == "p24_station_exterior":
		focus.x = lerpf(focus.x, 0.060, molly_portrait_weight)
	# Portrait phone cameras must use a WIDER page crop to show the face,
	# not just Mika's ear, a sandwich or a purple forehead. These two chapter
	# openers intentionally include neighbouring artwork when needed.
	if panel_id in ["p24_mika_smiles", "p31_professor_sandwich", "p31_fungus_and_professor"]:
		var page_aspect: float = PAGE_SIZE.x / PAGE_SIZE.y
		var screen_aspect: float = maxf(0.38, size.x / maxf(1.0, size.y))
		var minimum_sheet_width: float = 0.225 if panel_id == "p24_mika_smiles" else 0.208
		crop_height = maxf(crop_height, minimum_sheet_width * page_aspect / screen_aspect)
	var page_camera_end: Dictionary = {}
	if CH01_P02_CAMERA_END.has(panel_id):
		page_camera_end = CH01_P02_CAMERA_END
	elif PAGE_THREE_CAMERA_END.has(panel_id):
		page_camera_end = PAGE_THREE_CAMERA_END
	elif PAGE_FOUR_CAMERA_END.has(panel_id):
		page_camera_end = PAGE_FOUR_CAMERA_END
	elif PAGE_FIVE_CAMERA_END.has(panel_id):
		page_camera_end = PAGE_FIVE_CAMERA_END
	elif PAGE_SIX_CAMERA_END.has(panel_id):
		page_camera_end = PAGE_SIX_CAMERA_END
	elif PAGE_SEVEN_CAMERA_END.has(panel_id):
		page_camera_end = PAGE_SEVEN_CAMERA_END
	elif CHAPTER_TWO_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_TWO_CAMERA_END
	elif CHAPTER_TWO_THREE_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_TWO_THREE_CAMERA_END
	elif CHAPTER_TWO_FOUR_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_TWO_FOUR_CAMERA_END
	elif CHAPTER_THREE_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_THREE_CAMERA_END
	elif CHAPTER_THREE_TWO_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_THREE_TWO_CAMERA_END
	elif CHAPTER_THREE_THREE_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_THREE_THREE_CAMERA_END
	elif CHAPTER_THREE_FOUR_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_THREE_FOUR_CAMERA_END
	elif CHAPTER_FOUR_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_FOUR_CAMERA_END
	elif CHAPTER_FIVE_CAMERA_END.has(panel_id):
		page_camera_end = CHAPTER_FIVE_CAMERA_END
	if LOWER_PANEL_END.has(panel_id) or page_camera_end.has(panel_id):
		var duration: float = float(FRAME_SECONDS[panel_id])
		if _ch01_p02_bridge != null and CH01_P02_CAMERA_END.has(panel_id):
			duration = float(_ch01_p02_bridge.call("visual_duration", panel_id, duration))
		var handoff_seconds: float = float(CONTINUOUS_PAN_SECONDS.get(panel_id, CONTINUOUS_PAN_HANDOFF_SECONDS))
		var motion_elapsed: float = maxf(0.0, _elapsed - handoff_seconds) if _continuous_camera_active else _elapsed
		var motion_duration: float = maxf(0.01, duration - handoff_seconds) if _continuous_camera_active else duration
		var t: float = clampf(motion_elapsed / motion_duration, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		if page_camera_end.has(panel_id):
			var target: Vector3 = page_camera_end[panel_id]
			# Wide-screen crops reach the side panels' safe width limit much sooner
			# than portrait crops. Let each view have a restrained visible move:
			# ~8-15% on phones, ~8-18% on landscape; don't force a giant phone zoom.
			if panel_id.begins_with("p53_") or panel_id.begins_with("p54_"):
				var screen_ratio: float = size.x / maxf(size.y, 1.0)
				var wide_weight: float = clampf((screen_ratio - 0.85) / 0.80, 0.0, 1.0)
				target.z = lerpf(camera.z * (1.09 if panel_id == "p54_ship_departure" else 0.89), target.z, wide_weight)
				if panel_id != "p54_ship_departure" and PANEL_SAFE_BOUNDS.has(panel_id):
					# On 19.5:9 screens the panel itself, not the authored zoom,
					# may constrain BOTH endpoints to the very same crop height.
					# Finish a little INSIDE that limit so motion survives.
					var shot_frame: Rect2 = PANEL_SAFE_BOUNDS[panel_id]
					var possible_start: float = minf(camera.z, minf(shot_frame.size.y, shot_frame.size.x * (PAGE_SIZE.x / PAGE_SIZE.y) / screen_ratio))
					var minimum_zoom_ratio: float = 0.95 if panel_id == "p54_pulse_signal" else 0.96 if panel_id == "p54_galaxy_network" else 0.89
					target.z = minf(target.z, possible_start * minimum_zoom_ratio)
			if panel_id == "p21_ocean_city":
				target.x = _talos_city_pan_target_x()
			elif panel_id == "p23_plant_tutorial":
				target.x = lerpf(target.x, 0.816, molly_portrait_weight)
			elif panel_id == "p23_loading_ship":
				target.x = lerpf(target.x, 0.684, molly_portrait_weight)
			elif panel_id == "p24_professor_and_fungus":
				target.x = lerpf(target.x, 0.793, molly_portrait_weight)
			elif panel_id == "p24_station_exterior":
				target.x = lerpf(target.x, 0.940, molly_portrait_weight)
			focus = focus.lerp(Vector2(target.x, target.y), t)
			crop_height = lerpf(crop_height, target.z, t)
			if panel_id in ["p24_mika_smiles", "p31_professor_sandwich", "p31_fungus_and_professor"]:
				var page_aspect: float = PAGE_SIZE.x / PAGE_SIZE.y
				var screen_aspect: float = maxf(0.38, size.x / maxf(1.0, size.y))
				crop_height = maxf(crop_height, (0.225 if panel_id == "p24_mika_smiles" else 0.208) * page_aspect / screen_aspect)
		else:
			focus = focus.lerp(LOWER_PANEL_END[panel_id], t)
			# Keep the angled page gutter out even on extra-wide landscape phones.
			crop_height = minf(crop_height, 0.455 * (PAGE_SIZE.x / PAGE_SIZE.y) / maxf(1.0, size.x / maxf(1.0, size.y)))
	if panel_id == "p21_mika_enters":
		# No cut, blur, or fresh zoom after the preceding rightward pan:
		# simply hold its exact final framing until the following panel.
		focus = Vector2(_talos_city_pan_target_x(), 0.469)
		crop_height = 0.303
	# The second row of page three has a narrow, tilted left frame. On
	# ultra-wide screens crop deeper instead of revealing the neighboring frame.
	if PANEL_MAX_WIDTH.has(panel_id):
		var frame_width: float = float(PANEL_MAX_WIDTH[panel_id])
		crop_height = minf(crop_height, frame_width * (PAGE_SIZE.x / PAGE_SIZE.y) / maxf(1.0, size.x / maxf(1.0, size.y)))
	if PANEL_SAFE_BOUNDS.has(panel_id):
		# A focus coordinate alone is not a crop guarantee: the shader clamps to
		# the whole PDF, which used to show unrelated gutters/adjacent panels.
		var safe_frame: Rect2 = PANEL_SAFE_BOUNDS[panel_id]
		# The shader uses the actual aspect on portrait screens, so the row
		# pan must use it too (otherwise it would stop LEFT of walking Mika).
		var view_aspect: float = maxf(0.2, size.x / maxf(1.0, size.y)) if panel_id == "p21_ocean_city" or panel_id == "p21_mika_enters" or panel_id.begins_with("p43_") or panel_id.begins_with("p44_") or panel_id.begins_with("p45_") or panel_id.begins_with("p51_") or panel_id.begins_with("p52_") or panel_id.begins_with("p53_") or panel_id.begins_with("p54_") else maxf(1.0, size.x / maxf(1.0, size.y))
		var width_to_height: float = view_aspect / (PAGE_SIZE.x / PAGE_SIZE.y)
		crop_height = minf(crop_height, minf(safe_frame.size.y, safe_frame.size.x / width_to_height))
		var crop_width: float = crop_height * width_to_height
		focus.x = clampf(focus.x, safe_frame.position.x + crop_width * 0.5, safe_frame.end.x - crop_width * 0.5)
		focus.y = clampf(focus.y, safe_frame.position.y + crop_height * 0.5, safe_frame.end.y - crop_height * 0.5)
	var active_handoff: float = float(CONTINUOUS_PAN_SECONDS.get(panel_id, CONTINUOUS_PAN_HANDOFF_SECONDS))
	if _continuous_camera_active and _elapsed < active_handoff:
		# Begin at the exact final camera of the prior frame and glide to the
		# new frame's opening position. Its own face-to-face pan follows next.
		var handoff_t: float = clampf(_elapsed / active_handoff, 0.0, 1.0)
		handoff_t = handoff_t * handoff_t * (3.0 - 2.0 * handoff_t)
		focus = Vector2(_continuous_camera_from.x, _continuous_camera_from.y).lerp(focus, handoff_t)
		crop_height = lerpf(_continuous_camera_from.z, crop_height, handoff_t)
	# CH01_LINE_CLIP_CAMERA_BRIDGE_V2 — the single clip and its frame own the camera.
	if _ch01_p02_bridge != null and _ch01_p02_bridge.call("is_active_for", panel_id):
		var p02_line_camera: Vector3 = _ch01_p02_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p02_line_camera.x, p02_line_camera.y)
		crop_height = p02_line_camera.z
	if _ch01_p03_bridge != null and panel_id.begins_with("p03_"):
		var p03_shot: Vector3 = _ch01_p03_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p03_shot.x, p03_shot.y)
		crop_height = p03_shot.z
	if _ch01_p04_bridge != null and panel_id.begins_with("p04_"):
		var p04_shot: Vector3 = _ch01_p04_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p04_shot.x, p04_shot.y)
		crop_height = p04_shot.z
	if _ch01_p05_bridge != null and _ch01_p05_bridge.call("is_active_for", panel_id):
		var p05_shot: Vector3 = _ch01_p05_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p05_shot.x, p05_shot.y)
		crop_height = p05_shot.z
	if _ch01_p06_bridge != null and _ch01_p06_bridge.call("is_active_for", panel_id):
		var p06_shot: Vector3 = _ch01_p06_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p06_shot.x, p06_shot.y)
		crop_height = p06_shot.z
	if _ch01_p07_bridge != null and _ch01_p07_bridge.call("is_active_for", panel_id):
		var p07_shot: Vector3 = _ch01_p07_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p07_shot.x, p07_shot.y)
		crop_height = p07_shot.z
	if _ch02_p01_bridge != null and _ch02_p01_bridge.call("is_active_for", panel_id):
		var p21_shot: Vector3 = _ch02_p01_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p21_shot.x, p21_shot.y)
		crop_height = p21_shot.z
	if _ch02_p02_bridge != null and _ch02_p02_bridge.call("is_active_for", panel_id):
		var p22_shot: Vector3 = _ch02_p02_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p22_shot.x, p22_shot.y)
		crop_height = p22_shot.z
	if _ch02_p03_bridge != null and _ch02_p03_bridge.call("is_active_for", panel_id):
		var p23_shot: Vector3 = _ch02_p03_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p23_shot.x, p23_shot.y)
		crop_height = p23_shot.z
	if _ch02_p04_bridge != null and _ch02_p04_bridge.call("is_active_for", panel_id):
		var p24_shot: Vector3 = _ch02_p04_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p24_shot.x, p24_shot.y)
		crop_height = p24_shot.z
	if _ch03_p01_bridge != null and _ch03_p01_bridge.call("is_active_for", panel_id):
		var p31_shot: Vector3 = _ch03_p01_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p31_shot.x, p31_shot.y)
		crop_height = p31_shot.z
	if _ch03_p02_bridge != null and _ch03_p02_bridge.call("is_active_for", panel_id):
		var p32_shot: Vector3 = _ch03_p02_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p32_shot.x, p32_shot.y)
		crop_height = p32_shot.z
	if _ch03_p03_bridge != null and _ch03_p03_bridge.call("is_active_for", panel_id):
		var p33_shot: Vector3 = _ch03_p03_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p33_shot.x, p33_shot.y)
		crop_height = p33_shot.z
	if _ch03_p04_bridge != null and _ch03_p04_bridge.call("is_active_for", panel_id):
		var p34_shot: Vector3 = _ch03_p04_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p34_shot.x, p34_shot.y)
		crop_height = p34_shot.z
	if _ch04_p01_bridge != null and _ch04_p01_bridge.call("is_active_for", panel_id):
		var p41_shot: Vector3 = _ch04_p01_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p41_shot.x, p41_shot.y)
		crop_height = p41_shot.z
	if _ch04_p02_bridge != null and _ch04_p02_bridge.call("is_active_for", panel_id):
		var p42_shot: Vector3 = _ch04_p02_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p42_shot.x, p42_shot.y)
		crop_height = p42_shot.z
	if _ch04_p03_bridge != null and _ch04_p03_bridge.call("is_active_for", panel_id):
		var p43_shot: Vector3 = _ch04_p03_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p43_shot.x, p43_shot.y)
		crop_height = p43_shot.z
	if _ch04_p04_bridge != null and _ch04_p04_bridge.call("is_active_for", panel_id):
		var p44_shot: Vector3 = _ch04_p04_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p44_shot.x, p44_shot.y)
		crop_height = p44_shot.z
	if _ch04_p05_bridge != null and _ch04_p05_bridge.call("is_active_for", panel_id):
		var p45_shot: Vector3 = _ch04_p05_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p45_shot.x, p45_shot.y)
		crop_height = p45_shot.z
	if _ch05_p01_bridge != null and _ch05_p01_bridge.call("is_active_for", panel_id):
		var p51_shot: Vector3 = _ch05_p01_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p51_shot.x, p51_shot.y)
		crop_height = p51_shot.z
	if _ch05_p02_bridge != null and _ch05_p02_bridge.call("is_active_for", panel_id):
		var p52_shot: Vector3 = _ch05_p02_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p52_shot.x, p52_shot.y)
		crop_height = p52_shot.z
	if _ch05_p03_bridge != null and _ch05_p03_bridge.call("is_active_for", panel_id):
		var p53_shot: Vector3 = _ch05_p03_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p53_shot.x, p53_shot.y)
		crop_height = p53_shot.z
	if _ch05_p04_bridge != null and _ch05_p04_bridge.call("is_active_for", panel_id):
		var p54_shot: Vector3 = _ch05_p04_bridge.call("camera_state", panel_id, _elapsed, size, _continuous_camera_active, _continuous_camera_from)
		focus = Vector2(p54_shot.x, p54_shot.y)
		crop_height = p54_shot.z
	_material.set_shader_parameter("focus", focus)
	_material.set_shader_parameter("crop_height", crop_height)


# RU V3.0: only the current page bridge may own the visible camera.
func _ru_active_bridge(panel_id: String) -> Node:
	for bridge in [_ch01_p02_bridge, _ch01_p03_bridge, _ch01_p04_bridge]:
		if is_instance_valid(bridge) and bool(bridge.call("is_ru_sequence", panel_id)):
			return bridge as Node
	return null


func _ch06_is_panel(panel_id: String) -> bool:
	return panel_id.begins_with("p61_") or panel_id.begins_with("p62_") or panel_id.begins_with("p63_") or panel_id.begins_with("p64_") or panel_id.begins_with("p71_") or panel_id.begins_with("p72_") or panel_id.begins_with("p73_") or panel_id.begins_with("p74_") or panel_id.begins_with("p81_") or panel_id.begins_with("p82_")

func _ch06_prepare(panel_id: String) -> void:
	var page: String = panel_id.substr(1, 2)
	if _ch06_page == page and _ch06_texture != null:
		return
	_ch06_texture = null
	_ch06_page = page
	var path: String = "res://mika_motion_comic/assets/pages/ch0%s_p0%s_story.webp" % [page.substr(0, 1), page.substr(1, 1)]
	if FileAccess.file_exists(path):
		var image: Image = Image.new()
		if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			_ch06_texture = ImageTexture.create_from_image(image)
	if _ch06_texture == null and ResourceLoader.exists(path):
		_ch06_texture = ResourceLoader.load(path) as Texture2D
	if _ch06_texture == null:
		push_error("CH06 page missing: " + path)

func _ch06_draw_camera(panel_id: String) -> void:
	_ch06_prepare(panel_id)
	if _ch06_texture == null:
		return
	# MIKA_CH06_CH07_COMIC_FLOW_V2: the entire PDF page remains the artwork.
	# The camera is allowed to cross the panel borders; only the PAGE is bounded.
	_material.set_shader_parameter("artwork", _ch06_texture)
	var frame: Rect2 = PANEL_SAFE_BOUNDS[panel_id]
	var shot: Vector3 = CAMERA[panel_id]
	var ratio: float = PAGE_SIZE.x / PAGE_SIZE.y
	var aspect: float = maxf(0.01, size.x / maxf(1.0, size.y))
	var duration: float = float(FRAME_SECONDS[panel_id])
	var handoff: float = minf(CONTINUOUS_PAN_HANDOFF_SECONDS, duration * 0.32) if _continuous_camera_active else 0.0
	var t: float = clampf((_elapsed - handoff) / maxf(0.1, duration - handoff), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	var page_max_h: float = minf(1.0, ratio / aspect)
	var fit: float = minf(frame.size.y, frame.size.x * ratio / aspect)
	# Start a little wider than the panel-only crop: focus on the art, not on
	# filling the screen with the isolated rectangle. Nearby art is allowed.
	var h: float = minf(page_max_h, fit * 1.18)
	if not panel_id in ["p62_clocks", "p64_route", "p62_blueprint", "p62_planets"]:
		h *= lerpf(1.0, 0.94, t)
	# Both clocks remain in a single shot; keep the existing composition.
	# Full-width reunion: keep all six friends in the same shot. Adjacent art may be visible.
	if panel_id == "p81_friends":
		h = minf(page_max_h, frame.size.x * ratio / aspect * 1.01)
	var w: float = h * aspect / ratio
	var focus: Vector2 = Vector2(shot.x, shot.y)
	if panel_id in ["p72_history", "p73_evolution", "p73_tunnel", "p81_palace", "p82_new_space"]:
		var travel: float = maxf(0.0, (frame.size.x - w) * 0.5)
		focus.x = lerpf(frame.get_center().x - travel, frame.get_center().x + travel, t)
	elif panel_id == "p71_thought":
		focus.y = lerpf(frame.position.y + h * 0.5, shot.y, t)
	# The actual rendered focus is stored by advance_panel(). Smoothly glide
	# from that exact shot before starting the new panel's own small motion.
	focus = Vector2(clampf(focus.x, w * 0.5, 1.0 - w * 0.5), clampf(focus.y, h * 0.5, 1.0 - h * 0.5))
	if _continuous_camera_active and handoff > 0.0 and _elapsed < handoff:
		var u: float = clampf(_elapsed / handoff, 0.0, 1.0)
		u = u * u * (3.0 - 2.0 * u)
		focus = Vector2(_continuous_camera_from.x, _continuous_camera_from.y).lerp(focus, u)
		h = lerpf(_continuous_camera_from.z, h, u)
	# Keep sampling inside the full page, including after a viewport resize.
	h = clampf(h, 0.001, page_max_h)
	w = h * aspect / ratio
	focus = Vector2(clampf(focus.x, w * 0.5, 1.0 - w * 0.5), clampf(focus.y, h * 0.5, 1.0 - h * 0.5))
	_material.set_shader_parameter("focus", focus)
	_material.set_shader_parameter("crop_height", h)

# MIKA_CH07_ENDING_CHOICE_V1

# MIKA_CH08_ENDING_ONE_V1

# MIKA_CH08_ENDING_TWO_V1
