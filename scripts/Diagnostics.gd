extends RefCounted
## Portable JSONL flight diagnostics. Written to user://reports/ on all platforms.
## On macOS the collect_reports.command script copies this folder and engine
## logs into a shareable ZIP inside the project's own reports/ directory.

var _file_path: String = ""
var _enabled: bool = false


func start() -> void:
	var reports_path: String = ProjectSettings.globalize_path("user://reports")
	var status: Error = DirAccess.make_dir_recursive_absolute(reports_path)
	if status != OK:
		push_warning("Could not make diagnostics directory: %s (%d)" % [reports_path, status])
		return
	var time_string: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	_file_path = "user://reports/flight_%s_%d.jsonl" % [time_string, OS.get_process_id()]
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write diagnostics file (%d)" % FileAccess.get_open_error())
		return
	file.close()
	_enabled = true
	write("session_start", {
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"os": OS.get_name(),
		"viewport": get_viewport_description(),
		"project_name": ProjectSettings.get_setting("application/config/name", "Infinite Space")
	})
	print("INFINITE SPACE REPORTS: ", reports_path)


func get_viewport_description() -> String:
	return "%s x %s" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]


func write(event_type: String, details: Dictionary = {}) -> void:
	if not _enabled:
		return
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify({
		"time_utc": Time.get_datetime_string_from_system(true, true),
		"event": event_type,
		"data": details
	}))
	file.close()
