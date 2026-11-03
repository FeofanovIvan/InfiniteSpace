extends RefCounted
## Conservative, offline typo-tolerant dialogue validator.
## Case, punctuation and accidental spaces are free; short messages, digits,
## negations and ambiguous question intents must not silently change meaning.

const NO_MATCH: int = 999
const NEGATORS := ["not", "no", "never", "don't", "dont", "cannot",
	"не", "нет", "нельзя", "никак", "без", "ни",
	"nicht", "kein", "keine", "nein",
	"non", "pas", "jamais",
	"no", "nunca", "sin",
	"não", "nao", "nunca", "sem"]

static func normalize(value: String) -> String:
	var result: String = value.to_lower().strip_edges()
	for mark in ["!", "?", ".", ",", ";", ":", "¡", "¿", "…", "«", "»",
		"\"", "“", "”", "‘", "’", "'", "—", "–", "-", "\t", "\n", "\r", "(", ")"]:
		result = result.replace(mark, " ")
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.strip_edges()

static func _no_space(value: String) -> String:
	return normalize(value).replace(" ", "")

static func _has_digits(value: String) -> bool:
	for i in range(value.length()):
		var c: String = value.substr(i, 1)
		if c >= "0" and c <= "9":
			return true
	return false

static func _negative_set(value: String) -> bool:
	var tokens: Array = normalize(value).split(" ", false)
	for token in tokens:
		if NEGATORS.has(token):
			return true
	return false

static func _budget(length: int) -> int:
	if length < 5:
		return 0
	if length < 10:
		return 1
	if length < 25:
		return 2
	return 3

static func score(typed: String, reference: String) -> int:
	var cleaned_input: String = normalize(typed)
	var cleaned_reference: String = normalize(reference)
	if cleaned_input.is_empty() or cleaned_reference.is_empty():
		return NO_MATCH
	if cleaned_input == cleaned_reference:
		return 0
	var a: String = cleaned_input.replace(" ", "")
	var b: String = cleaned_reference.replace(" ", "")
	if a == b:
		return 0
	if _has_digits(a) or _has_digits(b):
		return NO_MATCH
	if _negative_set(cleaned_input) != _negative_set(cleaned_reference):
		return NO_MATCH
	var allowed: int = _budget(mini(a.length(), b.length()))
	if allowed == 0 or absi(a.length() - b.length()) > allowed:
		return NO_MATCH
	# Optimal string-alignment edit distance: deletion, insertion,
	# substitution and one adjacent-letter transposition.
	var before_previous: Array[int] = []
	var previous: Array[int] = []
	for j in range(b.length() + 1):
		previous.append(j)
	for i in range(1, a.length() + 1):
		var current: Array[int] = [i]
		var smallest: int = current[0]
		for j in range(1, b.length() + 1):
			var replace_cost: int = 0 if a.substr(i - 1, 1) == b.substr(j - 1, 1) else 1
			var distance: int = mini(previous[j] + 1,
				mini(current[j - 1] + 1, previous[j - 1] + replace_cost))
			if i > 1 and j > 1 and before_previous.size() > j - 2:
				if a.substr(i - 1, 1) == b.substr(j - 2, 1) and a.substr(i - 2, 1) == b.substr(j - 1, 1):
					distance = mini(distance, before_previous[j - 2] + 1)
			current.append(distance)
			smallest = mini(smallest, distance)
		if smallest > allowed:
			return NO_MATCH
		before_previous = previous
		previous = current
	var found: int = previous[b.length()]
	return found if found <= allowed else NO_MATCH

static func matches(typed: String, candidates: Array) -> bool:
	for item in candidates:
		if score(typed, str(item)) != NO_MATCH:
			return true
	return false
