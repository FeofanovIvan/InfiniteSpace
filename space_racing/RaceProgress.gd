extends RefCounted
## Persist personal records per station and difficulty in user://.
const SAVE_PATH: String = "user://mika_space_racing_v8.cfg"
const FIRST_STATION: String = "mw_station"
const STATION_ORDER: Array[String] = ["mw_station", "lmc_station", "smc_station", "barnard_station", "andromeda_station", "triangulum_station"]

static func _read() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	return cfg

static func best_lap(station_id: String, difficulty: String = "normal") -> float:
	var cfg := _read()
	return float(cfg.get_value("best_laps", station_id + ":" + difficulty, 0.0))

static func record_lap(station_id: String, difficulty: String, seconds: float) -> float:
	var cfg := _read()
	var key: String = station_id + ":" + difficulty
	var old: float = float(cfg.get_value("best_laps", key, 0.0))
	if seconds > 0.0 and (old <= 0.0 or seconds < old):
		cfg.set_value("best_laps", key, seconds)
		cfg.save(SAVE_PATH)
		return seconds
	return old

static func complete_race(station_id: String) -> void:
	var cfg := _read()
	cfg.set_value("completed", station_id, true)
	cfg.save(SAVE_PATH)

static func is_unlocked(station_id: String) -> bool:
	if station_id == FIRST_STATION:
		return true
	var idx: int = STATION_ORDER.find(station_id)
	if idx <= 0:
		return false
	var cfg := _read()
	return bool(cfg.get_value("completed", STATION_ORDER[idx - 1], false))
