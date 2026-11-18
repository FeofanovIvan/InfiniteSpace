extends RefCounted
# MIKA station racing campaign: six sequential victories, no crystals.
const SAVE_PATH: String = "user://mika_station_race_campaign_v1.cfg"
const ORDER: Array[String] = ["st_mw", "st_lmc", "st_smc", "st_ngc6822", "st_m31", "st_m33"]
const SYSTEMS: Array[String] = ["mw", "lmc", "smc", "ngc6822", "m31", "m33"]
const NAMES: Array[String] = ["Milky Way", "Large Magellanic Cloud", "Small Magellanic Cloud", "Barnard", "Andromeda", "Triangulum"]

static func _load() -> ConfigFile:
    var config := ConfigFile.new()
    config.load(SAVE_PATH)
    return config

static func stage_index(station: String) -> int:
    return ORDER.find(station)

static func next_unfinished() -> int:
    var config := _load()
    for i in range(ORDER.size()):
        if not bool(config.get_value("wins", ORDER[i], false)):
            return i
    return ORDER.size()

static func is_unlocked(station: String) -> bool:
    var i := stage_index(station)
    return i >= 0 and i <= next_unfinished()

static func target_for(requested: String) -> String:
    var i := stage_index(requested)
    if i < 0:
        return ORDER[0]
    return ORDER[mini(i, next_unfinished())] if next_unfinished() < ORDER.size() else requested

static func system_for(station: String) -> String:
    var i := stage_index(station)
    return SYSTEMS[i] if i >= 0 else "mw"

static func name_for(station: String) -> String:
    var i := stage_index(station)
    return NAMES[i] if i >= 0 else station

static func difficulty_for(station: String) -> String:
    var i := stage_index(station)
    if i <= 1:
        return "easy"
    if i <= 3:
        return "normal"
    return "hard"

static func speed_multiplier(station: String) -> float:
    return 1.0 + maxf(0.0, float(stage_index(station))) * 0.055

static func record_win(station: String, seconds: float) -> Dictionary:
    var i := stage_index(station)
    if i < 0 or seconds <= 0.0:
        return {}
    var config := _load()
    var previous := float(config.get_value("best_wins", station, 0.0))
    if previous <= 0.0 or seconds < previous:
        config.set_value("best_wins", station, seconds)
    config.set_value("wins", station, true)
    if i == ORDER.size() - 1:
        config.set_value("campaign", "trophy_unlocked", true)
    var error := config.save(SAVE_PATH)
    if error != OK:
        push_error("MIKA race campaign save failed: %s" % error)
    return {"next": ORDER[i + 1] if i + 1 < ORDER.size() else "", "best": float(config.get_value("best_wins", station, seconds)), "prize": i == ORDER.size() - 1, "saved": error == OK}

static func best_win(station: String) -> float:
    return float(_load().get_value("best_wins", station, 0.0))
