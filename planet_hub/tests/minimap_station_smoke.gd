extends SceneTree

const MINI_MAP_SCRIPT: Script = preload("res://scripts/MiniMap.gd")
const ATLAS_SCRIPT: Script = preload("res://scripts/AtlasSystem.gd")

func _initialize() -> void:
	_assert(MINI_MAP_SCRIPT.should_draw_body({
		"name": "EarthStation", "kind": "station"
	}), "Milky Way station is hidden")
	for station_id in ["st_lmc", "st_smc", "st_ngc6822", "st_m31", "st_m33"]:
		_assert(MINI_MAP_SCRIPT.should_draw_body({
			"name": "Story Station", "kind": "station", "station_id": station_id
		}), "station is hidden: " + station_id)
	_assert(MINI_MAP_SCRIPT.should_draw_body({
		"name": "Example Planet", "kind": "planet"
	}), "planets must remain visible")
	_assert(not MINI_MAP_SCRIPT.should_draw_body({
		"name": "Moon", "kind": "moon"
	}), "moon filter regressed")
	var atlas: Node = ATLAS_SCRIPT.new()
	root.add_child(atlas)
	await process_frame
	for region_id in ["mw", "lmc", "smc", "ngc6822", "m31", "m33"]:
		_assert(atlas.set_region(region_id), "cannot load region: " + region_id)
		var stations: Array = atlas.get_navigation_bodies().filter(
			func(body: Dictionary) -> bool: return str(body.get("kind", "")) == "station")
		_assert(stations.size() == 1, "expected one navigation station in " + region_id)
		_assert(MINI_MAP_SCRIPT.should_draw_body(stations[0]), "region station is filtered: " + region_id)
	atlas.queue_free()
	print("MINIMAP_STATION_SMOKE_PASS")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MINIMAP_STATION_SMOKE_FAIL: " + message)
	quit(1)
