extends Control
## Standalone interactive preview for all six races plus one station.
## Run: godot --path . res://planet_hub/tests/representative_dialog_preview.tscn
## F1...F6: representative of each race. F7: magnetic science station.
## Escape/back arrow returns to this preview's default Earth representative.

const DIALOG := preload("res://planet_hub/scenes/representative_dialog.tscn")
const WORLDS_PATH := "res://planet_hub/data/dialogue_worlds.json"
const ROSTER_PATH := "res://planet_hub/data/representatives.json"
const REPRESENTATIVE_PATH := "res://planet_hub/characters/"
const BACKGROUND_PATH := "res://planet_hub/backgrounds/"
const TEST_WORLDS := [
	"mw_p01", "lmc_p02", "smc_p01", "ngc6822_p01",
	"m31_p03", "m33_p01", "st_m31"
]
var _dialog: Control
var _roster: Dictionary = {}
var _worlds: Dictionary = {}
var _current: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var roster_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROSTER_PATH))
	if roster_variant is Dictionary:
		_roster = roster_variant.get("assignments", {})
	var worlds_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORLDS_PATH))
	if worlds_variant is Dictionary:
		_worlds = worlds_variant.get("worlds", {})
	_dialog = DIALOG.instantiate() as Control
	add_child(_dialog)
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.connect("return_requested", Callable(self, "_return_to_earth"))
	resized.connect(_resize_dialog)
	_resize_dialog()
	_show_world(0)

func _resize_dialog() -> void:
	if _dialog != null:
		_dialog.size = size

func _existing_asset(paths: Array[String]) -> String:
	for path in paths:
		if ResourceLoader.exists(path):
			return path
	return ""

func _show_world(index: int) -> void:
	_current = index
	var world_id: String = TEST_WORLDS[index]
	var info: Dictionary = _worlds.get(world_id, {})
	var representative: Dictionary = _roster.get(world_id, {})
	var asset: String = str(representative.get("asset", ""))
	var portrait: String = _existing_asset([REPRESENTATIVE_PATH + asset]) if not asset.is_empty() else ""
	var background: String = _existing_asset([
		BACKGROUND_PATH + world_id + ".png",
		BACKGROUND_PATH + world_id + ".jpg",
		BACKGROUND_PATH + world_id + ".webp"
	])
	var name: String = str(info.get("name", {}).get("ru", world_id))
	_dialog.call("configure_for_planet", world_id, name, background, portrait)
	get_window().title = "Мика • диалог • " + name + "  |  F1–F6: расы; F7: станция"

func _return_to_earth() -> void:
	_show_world(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	for i in range(TEST_WORLDS.size()):
		if event.keycode == KEY_F1 + i:
			_show_world(i)
			get_viewport().set_input_as_handled()
			return
