extends RefCounted
## Canonical place name: no road-junction renaming. Shared by map and story rebus.
const NAME: Dictionary = {
	"ru": "Перекрёсток миров", "en": "Crossroads of Worlds",
	"pt": "Encruzilhada de mundos", "es": "Cruce de mundos",
	"fr": "Carrefour des mondes", "de": "Kreuzung der Welten"
}
const PARTS: Dictionary = {
	"ru": ["ПЕРЕКРЁСТОК", " МИРОВ"],
	"en": ["CROSSROADS", " OF", " WORLDS"],
	"pt": ["ENCRUZILHADA", " DE", " MUNDOS"],
	"es": ["CRUCE", " DE", " MUNDOS"],
	"fr": ["CARREFOUR", " DES", " MONDES"],
	"de": ["KREUZUNG", " DER", " WELTEN"]
}
const HINT: Dictionary = {
	"ru": "Как называется место, где соединяются миры?",
	"en": "What is the place where worlds meet called?",
	"pt": "Como se chama o lugar onde os mundos se encontram?",
	"es": "¿Cómo se llama el lugar donde se encuentran los mundos?",
	"fr": "Comment s'appelle le lieu où les mondes se rencontrent ?",
	"de": "Wie heißt der Ort, an dem die Welten zusammentreffen?"
}
const EXTRA: Dictionary = {
	"ru": ["ЛУНА", "ЗВЕЗДА"], "en": ["MOON", "STAR"],
	"pt": ["LUA", "ESTRELA"], "es": ["LUNA", "ESTRELLA"],
	"fr": ["LUNE", "ÉTOILE"], "de": ["MOND", "STERN"]
}
const ART: String = "res://planet_hub/games/space_rebus/assets/story_ch06/"
static func locale(code: String) -> String:
	var key: String = "pt" if code.begins_with("pt") else code
	return key if NAME.has(key) else "en"

static func display_name(code: String) -> String:
	return str(NAME[locale(code)])

static func puzzle(code: String) -> Dictionary:
	var key: String = locale(code)
	var parts: Array = PARTS[key]
	var pieces: Array = []
	var required: Array = []
	for i in range(parts.size()):
		var value: String = str(parts[i])
		var asset: String = ""
		if i == 0:
			asset = ART + "connected_worlds.webp"
		elif i == parts.size() - 1:
			asset = ART + "worlds.webp"
		pieces.append({"type": "text" if asset.is_empty() else "object", "label": value.strip_edges(), "value": value, "asset": asset, "op": "add"})
		required.append(i)
	var extra: Array = EXTRA[key]
	for i in range(extra.size()):
		pieces.append({"type": "object", "label": extra[i], "value": extra[i], "asset": "res://learning/assets/learning_objects/" + ("moon.webp" if i == 0 else "star.webp"), "op": "add"})
	return {"id": "ch06_crossroads_" + key, "answer": display_name(key).to_upper(), "hint": HINT[key], "required": required, "pieces": pieces}
