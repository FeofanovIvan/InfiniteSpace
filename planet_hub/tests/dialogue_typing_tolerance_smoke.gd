extends SceneTree
## godot --headless --path . --script res://planet_hub/tests/dialogue_typing_tolerance_smoke.gd
const Matcher = preload("res://planet_hub/scripts/dialogue_input_matcher.gd")
const Engine = preload("res://planet_hub/scripts/dialogue_engine.gd")
const SAVE_PATH := "user://miko_dialogue_progress.json"
var failures: int = 0

func _check(value: bool, message: String) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	var existed: bool = FileAccess.file_exists(SAVE_PATH)
	var original: String = FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
	_run()
	if existed:
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(original)
			file.close()
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Typing tolerance smoke: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(0 if failures == 0 else 1)

func _run() -> void:
	_check(Matcher.matches("  HELLO!!! ", ["Hello!"]), "capital letters and extra punctuation")
	_check(Matcher.matches(" H E L L O ", ["Hello!"]), "stray spaces between letters")
	_check(Matcher.matches("h e llo", ["Hello!"]), "missing/extra spaces inside short greeting")
	_check(Matcher.matches("Helo!", ["Hello!"]), "one omitted letter in greeting")
	_check(Matcher.matches("Helelo!", ["Hello!"]), "one duplicated letter in greeting")
	_check(Matcher.matches("Hlelo!", ["Hello!"]), "adjacent transposition in greeting")
	_check(Matcher.matches(" TELL  ME ABOUT YOUR PLNET  !!!", ["Tell me about your planet."]), "typo inside long question")
	_check(not Matcher.matches("Ho", ["Hi!"]), "very short greetings are not guessed")
	_check(not Matcher.matches("4", ["3"]), "math values never guessed")
	_check(not Matcher.matches("4 + 2 = 6", ["4 + 3 = 6"]), "numbers in equations never altered")
	_check(not Matcher.matches("I do not like it", ["I do like it"]), "negation must not be dropped")
	_check(not Matcher.matches("NO", ["Go"]), "short negative is not softened")
	_check(not Matcher.matches("What do you eat?", ["What is your name?"]), "different intents not confused")
	var e: RefCounted = Engine.new()
	e.call("begin", "m31_p03", "en")
	_check(bool(e.call("accept", "  hELo!!! ").get("accepted", false)), "engine accepts forgiving greeting")
	_check(str(e.get("stage")) == "choose", "engine advances only after recognized greeting")
	var wrong: Dictionary = e.call("accept", "This question is not in your library")
	_check(not bool(wrong.get("accepted", true)), "unknown input is rejected")
	var question: Dictionary = e.call("accept", "Tell me about your specise.")
	_check(bool(question.get("accepted", false)), "misordered letters in race question accepted")
	var e2: RefCounted = Engine.new()
	e2.call("begin", "m33_p01", "ru")
	_check(bool(e2.call("accept", "  ПРИВЕТ!!! ").get("accepted", false)), "Russian greeting ignores case/punctuation")
	var ru_question: Dictionary = e2.call("accept", "РАССКАЖИ  ОБ  ЭТОМ МИРЕ!!!")
	_check(bool(ru_question.get("accepted", false)), "Russian world question ignores case/spaces")
	var e3: RefCounted = Engine.new()
	e3.call("begin", "mw_p01", "en")
	e3.call("accept", "Hello")
	var math: Dictionary = e3.call("accept", "Can you teach me something?")
	_check(bool(math.get("accepted", false)) and str(e3.get("stage")) == "math", "enter simple math quiz")
	var options: Array = math.get("choices", [])
	var answer: String = str(options[0])
	_check(not bool(e3.call("accept", str(int(answer) + 1)).get("accepted", true)), "wrong math answer is not accepted")
	_check(bool(e3.call("accept", " " + answer + "!! ").get("accepted", false)), "correct number with punctuation accepted")
