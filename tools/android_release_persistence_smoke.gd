extends SceneTree
## Verifies gameplay and Android access persistence while restoring the user's
## original user:// files byte-for-byte before exiting.

const GAME_SAVE := "user://miko_playtown_save_game.cfg"
const ACCESS_SAVE := "user://miko_playtown_access_state.cfg"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("ANDROID_PERSISTENCE_FAIL: " + message)


func _run() -> void:
	var game_backup := _backup(GAME_SAVE)
	var access_backup := _backup(ACCESS_SAVE)
	_test_game_state()
	_test_access_state()
	_restore(GAME_SAVE, game_backup)
	_restore(ACCESS_SAVE, access_backup)
	print("Android release persistence smoke: ", "PASS" if _failures == 0 else "%d FAILED" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_game_state() -> void:
	var state_script := load("res://learning/src/core/game_state.gd") as Script
	_check(state_script != null, "game-state persistence script compiles")
	if state_script == null:
		return
	var writer: Node = state_script.new()
	writer.set("total_coins", 321)
	writer.set("letters_traced", 7)
	writer.set("words_traced", 5)
	writer.set("numbers_traced", 9)
	writer.set("selected_character", "boy")
	writer.set("main_player_pos", Vector2(123.5, -44.25))
	writer.set("has_main_player_pos", true)
	writer.set("pet_owned", true)
	writer.set("shop_item_stock", {"food": 2})
	writer.call("save_game")
	var reader: Node = state_script.new()
	reader.call("load_game")
	_check(int(reader.get("total_coins")) == 321, "crystal/coin balance survives restart")
	_check(int(reader.get("letters_traced")) == 7 and int(reader.get("words_traced")) == 5 and int(reader.get("numbers_traced")) == 9,
		"mini-game progress survives restart")
	_check(str(reader.get("selected_character")) == "boy", "selected character survives restart")
	_check(bool(reader.get("has_main_player_pos")) and (reader.get("main_player_pos") as Vector2).is_equal_approx(Vector2(123.5, -44.25)),
		"free-flight position survives restart")
	_check(bool(reader.get("pet_owned")) and int((reader.get("shop_item_stock") as Dictionary).get("food", 0)) == 2,
		"Bubble ownership and consumable stock survive restart")
	writer.free()
	reader.free()


func _test_access_state() -> void:
	var access_script := load("res://learning/src/core/access_service.gd") as Script
	_check(access_script != null, "access-state persistence script compiles")
	if access_script == null:
		return
	var writer: Node = access_script.new()
	writer.set("preview_started", true)
	writer.set("preview_elapsed_seconds", 487.25)
	writer.set("full_game_owned", true)
	writer.call("_save_state")
	var reader: Node = access_script.new()
	reader.call("_load_state")
	_check(bool(reader.get("preview_started")), "preview-start state survives restart")
	_check(is_equal_approx(float(reader.get("preview_elapsed_seconds")), 487.25), "active-play elapsed time survives restart")
	_check(bool(reader.get("full_game_owned")), "verified permanent entitlement survives offline restart")
	writer.free()
	reader.free()


func _backup(path: String) -> Dictionary:
	return {
		"exists": FileAccess.file_exists(path),
		"bytes": FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray(),
	}


func _restore(path: String, backup: Dictionary) -> void:
	if bool(backup.get("exists", false)):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(backup.get("bytes", PackedByteArray()))
	else:
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute)
