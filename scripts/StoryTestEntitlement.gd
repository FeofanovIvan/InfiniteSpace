extends RefCounted
## Debug-only QA switch. Not a purchase receipt and never trusted by a release.

const FILE_PATH: String = "user://mika_subscription_qa_only.cfg"


static func is_available() -> bool:
	return OS.is_debug_build()


static func is_active() -> bool:
	if not is_available():
		return false
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(FILE_PATH) != OK:
		return false
	return bool(cfg.get_value("qa", "subscription_enabled", false))


static func set_active(enabled: bool) -> bool:
	if not is_available():
		return false
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(FILE_PATH)
	cfg.set_value("qa", "subscription_enabled", enabled)
	return cfg.save(FILE_PATH) == OK
