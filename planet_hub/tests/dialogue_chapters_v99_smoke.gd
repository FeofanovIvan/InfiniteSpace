extends SceneTree
## Test v99 chapter 3/4 additions without altering UI or existing child progress.
## godot --headless --path . --script res://planet_hub/tests/dialogue_chapters_v99_smoke.gd

const EngineScript = preload("res://planet_hub/scripts/dialogue_engine.gd")
const SAVE_PATH := "user://miko_dialogue_progress.json"
const LANGS := ["ru", "en", "fr", "de", "es", "pt_BR"]
const SAMPLES := {
	"human": "mw_p01",
	"mold": "lmc_p02",
	"phase": "smc_p01",
	"reptile": "ngc6822_p01",
	"magnetic": "m31_p03",
	"neural": "m33_p01"
}
var failures: int = 0
var _words: Dictionary = {}
var _base: Dictionary = {}
var _new: Dictionary = {}

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func _read(path: String) -> Dictionary:
	var obj: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return obj if obj is Dictionary else {}

func _restore_save(existed: bool, original: String) -> void:
	if existed:
		var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(original)
			f.close()
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _reset() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _initialize() -> void:
	var existed: bool = FileAccess.file_exists(SAVE_PATH)
	var original: String = FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
	_reset()
	_verify()
	_restore_save(existed, original)
	print("Four-chapter adventures smoke: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(0 if failures == 0 else 1)

func _open_adventure(world: String, lang: String) -> Dictionary:
	var engine: RefCounted = EngineScript.new()
	var opening: Dictionary = engine.call("begin", world, lang)
	if opening.get("choices", []).size() != 3:
		_check(false, "three greeting options: " + world + " " + lang)
		return {}
	var greeting: Dictionary = engine.call("accept", str(opening["choices"][1]))
	_check(bool(greeting.get("accepted", false)), "recognized greeting: " + world + " " + lang)
	var question: String = str(_words["topics"]["world"][lang][0])
	var intro: Dictionary = engine.call("accept", question)
	_check(str(engine.get("stage")) == "story" and intro.get("choices", []).size() == 3, "world story: " + world + " " + lang)
	if intro.get("choices", []).size() != 3:
		return {}
	var adventure: Dictionary = engine.call("accept", str(intro["choices"][0]))
	_check(bool(adventure.get("accepted", false)) and str(engine.get("stage")) == "story_adventure" and adventure.get("choices", []).size() == 3, "adventure opened: " + world + " " + lang)
	return {"engine": engine, "adventure": adventure}

func _verify() -> void:
	_words = _read("res://planet_hub/data/dialogue_phrases.json")
	_base = _read("res://planet_hub/data/dialogue_adventures.json")
	_new = _read("res://planet_hub/data/dialogue_adventures_v99.json")
	_check(_new.get("races", {}).size() == 6, "all six races have new chapters")
	for race in SAMPLES:
		var first: Array = _base.get("races", {}).get(race, [])
		var addition: Array = _new.get("races", {}).get(race, [])
		_check(first.size() == 2 and addition.size() == 2, "two existing plus two new: " + race)
		if first.size() != 2 or addition.size() != 2:
			continue
		_check(str(addition[0].get("follows", "")) == str(first[1].get("id", "")), "chapter 3 connected to chapter 2: " + race)
		_check(str(addition[1].get("follows", "")) == str(addition[0].get("id", "")), "chapter 4 connected to chapter 3: " + race)
		for episode in addition:
			_check(episode.get("choices", []).size() == 3 and episode.get("outcomes", []).size() == 3 and episode.get("callbacks", []).size() == 3, "three options, endings and callbacks: " + race)
			for lang in LANGS:
				_check(not str(episode.get("intro", {}).get(lang, "")).is_empty(), "full intro in "+lang+" "+race)
				for section in ["choices","outcomes","callbacks"]:
					for part in episode.get(section, []):
						_check(not str(part.get(lang, "")).is_empty(), "full " + section + " in " + lang + " " + race)
	var walkthroughs: int = 0
	for race in SAMPLES:
		var world: String = str(SAMPLES[race])
		for lang in LANGS:
			_reset()
			var prior_choice: int = -1
			for chapter in range(4):
				var opened: Dictionary = _open_adventure(world, lang)
				if opened.is_empty():
					break
				var engine: RefCounted = opened["engine"]
				var step: Dictionary = opened["adventure"]
				_check(int(engine.get("_active_adventure_index")) == chapter, "chapter order " + str(chapter + 1) + " " + race + " " + lang)
				if chapter >= 2:
					var expected: String = str(_new["races"][race][chapter-2]["callbacks"][prior_choice][lang])
					_check(str(step.get("npc", "")).contains(expected), "callback remembers actual previous choice " + race + " " + lang + " chapter " + str(chapter+1))
				var options: Array = step.get("choices", [])
				if options.size() != 3:
					break
				_check(str(engine.call("get_hint", 1)) == str(options[1]), "chosen hint unchanged "+lang)
				var unknown: Dictionary = engine.call("accept", "qzx irrelevant unintelligible")
				_check(not bool(unknown.get("accepted", true)) and int(engine.get("_active_adventure_index")) == chapter, "unrecognized words don't progress")
				var chosen: int = [1, 2, 0, 1][chapter]
				var result: Dictionary = engine.call("accept", str(options[chosen]))
				_check(bool(result.get("accepted", false)) and str(engine.get("stage")) == "choose", "all three branch indices can progress: " + race + " " + lang)
				var mem: Dictionary = engine.get("_state").get("character_adventures", {})
				var saved: Dictionary = mem.get(str(engine.call("_adventure_memory_key")), {})
				_check(int(saved.get("completed", 0)) == chapter+1 and int(saved.get("last_choice", -1)) == chosen, "chapter and choice saved: " + race + " " + lang)
				prior_choice = chosen
			var last: Dictionary = _open_adventure(world, lang)
			if not last.is_empty():
				_check(int(last["engine"].get("_active_adventure_index")) == 0, "replay after four full chapters, not two: " + race + " " + lang)
			walkthroughs += 1
	_check(walkthroughs == 36, "36 four-chapter walkthroughs, 144 chapters")
	# Upgrade a profile that replayed v98 two-chapter episodes multiple times:
	# it must reach new chapter 3, not silently skip to chapter 4.
	_reset()
	var old: RefCounted = EngineScript.new()
	old.call("begin", "mw_p01", "en")
	var key: String = str(old.call("_adventure_memory_key"))
	var save: Dictionary = {
		"locations": {},
		"personal_asked": [],
		"character_adventures": {}
	}
	save["character_adventures"][key] = {"completed": 7, "last_episode": 1, "last_choice": 2, "history": [{"episode": 1, "choice": 2}]}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(save))
		file.close()
	var upgraded: Dictionary = _open_adventure("mw_p01", "en")
	if not upgraded.is_empty():
		var e: RefCounted = upgraded["engine"]
		_check(int(e.get("_active_adventure_index")) == 2, "v98 repeated sessions migrate to chapter 3")
		var record: Dictionary = e.get("_state").get("character_adventures", {}).get(key, {})
		_check(int(record.get("legacy_completed_v98", 0)) == 7, "legacy completion count preserved")
		_check(int(record.get("completed", -1)) == 2 and str(record.get("chapter_set", "")) == "v99", "v99 migration is idempotent")
		_check(str(upgraded["adventure"].get("npc", "")).contains(str(_new["races"]["human"][0]["callbacks"][2]["en"])), "migration keeps previous choice callback")
	# Skipping a chapter must not consume a new episode.
	_reset()
	var skip: Dictionary = _open_adventure("smc_p01", "en")
	if not skip.is_empty():
		var e: RefCounted = skip["engine"]
		var done: Dictionary = e.call("accept", "Skip")
		_check(bool(done.get("accepted", false)) and str(e.get("stage")) == "choose", "can skip without mandatory quest")
		_check(e.get("_state").get("character_adventures", {}).is_empty(), "skipping does not create memory or count chapter")
