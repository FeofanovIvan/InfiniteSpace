extends RefCounted

const ProductCatalog := preload("res://education/playtown/src/features/shared/product_catalog.gd")
const CATEGORIES: Array[String] = ["objects", "body", "animals", "products", "shapes"]
const BODY_KEYS: Array[String] = ["head", "eye", "nose", "mouth", "ear", "hand", "foot", "finger"]
const EN_WORD_NAMES := {
	"house": "house", "table": "table", "chair": "chair", "bed": "bed", "door": "door",
	"window": "window", "lamp": "lamp", "cup": "cup", "plate": "plate", "spoon": "spoon",
	"hat": "hat", "jacket": "jacket", "dress": "dress", "tshirt": "t-shirt", "pants": "pants",
	"socks": "socks", "boots": "boots", "head": "head", "eye": "eye", "nose": "nose",
	"mouth": "mouth", "ear": "ear", "hand": "arm", "foot": "leg", "finger": "finger",
	"ball": "ball", "doll": "doll", "toy_car": "toy car", "cube": "block", "book": "book",
	"pencil": "pencil", "backpack": "backpack", "sun": "sun", "moon": "moon", "star": "star",
	"cloud": "cloud", "rain": "rain", "snow": "snow", "tree": "tree", "flower": "flower",
	"leaf": "leaf", "car": "car", "bus": "bus", "train": "train", "airplane": "airplane",
	"bicycle": "bicycle", "ship": "ship", "clock": "clock", "key": "key", "umbrella": "umbrella",
}
const EN_ANIMAL_NAMES := {
	"sea_fish": "fish", "sea_dolphin": "dolphin", "sea_whale": "whale", "sea_shark": "shark",
	"sea_octopus": "octopus", "sea_jellyfish": "jellyfish", "sea_crab": "crab",
	"sea_starfish": "starfish", "sea_seahorse": "seahorse", "sea_turtle": "sea turtle",
	"farm_cow": "cow", "farm_pig": "pig", "farm_horse": "horse", "farm_sheep": "sheep",
	"farm_goat": "goat", "farm_chicken": "chicken", "farm_duck": "duck", "farm_rabbit": "rabbit",
	"farm_cat": "cat", "farm_dog": "dog", "sky_eagle": "eagle", "sky_owl": "owl",
	"sky_parrot": "parrot", "sky_pigeon": "pigeon", "sky_sparrow": "sparrow", "sky_crow": "crow",
	"sky_seagull": "seagull", "sky_butterfly": "butterfly", "sky_bee": "bee", "sky_bat": "bat",
	"wild_bear": "bear", "wild_wolf": "wolf", "wild_fox": "fox", "wild_deer": "deer",
	"wild_squirrel": "squirrel", "wild_hedgehog": "hedgehog", "wild_hare": "hare", "wild_moose": "moose",
	"wild_boar": "wild boar", "wild_raccoon": "raccoon",
}
const PT_WORD_NAMES := {
	"house": "casa", "table": "mesa", "chair": "cadeira", "bed": "cama", "door": "porta",
	"window": "janela", "lamp": "lâmpada", "cup": "xícara", "plate": "prato", "spoon": "colher",
	"hat": "gorro", "jacket": "jaqueta", "dress": "vestido", "tshirt": "camiseta", "pants": "calça",
	"socks": "meias", "boots": "botas", "head": "cabeça", "eye": "olho", "nose": "nariz",
	"mouth": "boca", "ear": "orelha", "hand": "braço", "foot": "perna", "finger": "dedo",
	"ball": "bola", "doll": "boneca", "toy_car": "carrinho", "cube": "bloco", "book": "livro",
	"pencil": "lápis", "backpack": "mochila", "sun": "sol", "moon": "lua", "star": "estrela",
	"cloud": "nuvem", "rain": "chuva", "snow": "neve", "tree": "árvore", "flower": "flor",
	"leaf": "folha", "car": "carro", "bus": "ônibus", "train": "trem", "airplane": "avião",
	"bicycle": "bicicleta", "ship": "navio", "clock": "relógio", "key": "chave", "umbrella": "guarda-chuva",
}
const PT_ANIMAL_NAMES := {
	"sea_fish": "peixe", "sea_dolphin": "golfinho", "sea_whale": "baleia", "sea_shark": "tubarão",
	"sea_octopus": "polvo", "sea_jellyfish": "água-viva", "sea_crab": "caranguejo",
	"sea_starfish": "estrela-do-mar", "sea_seahorse": "cavalo-marinho", "sea_turtle": "tartaruga-marinha",
	"farm_cow": "vaca", "farm_pig": "porco", "farm_horse": "cavalo", "farm_sheep": "ovelha",
	"farm_goat": "cabra", "farm_chicken": "galinha", "farm_duck": "pato", "farm_rabbit": "coelho",
	"farm_cat": "gato", "farm_dog": "cachorro", "sky_eagle": "águia", "sky_owl": "coruja",
	"sky_parrot": "papagaio", "sky_pigeon": "pombo", "sky_sparrow": "pardal", "sky_crow": "corvo",
	"sky_seagull": "gaivota", "sky_butterfly": "borboleta", "sky_bee": "abelha", "sky_bat": "morcego",
	"wild_bear": "urso", "wild_wolf": "lobo", "wild_fox": "raposa", "wild_deer": "veado",
	"wild_squirrel": "esquilo", "wild_hedgehog": "ouriço", "wild_hare": "lebre", "wild_moose": "alce",
	"wild_boar": "javali", "wild_raccoon": "guaxinim",
}
const ES_WORD_NAMES := {
	"house": "casa", "table": "mesa", "chair": "silla", "bed": "cama", "door": "puerta",
	"window": "ventana", "lamp": "lámpara", "cup": "taza", "plate": "plato", "spoon": "cuchara",
	"hat": "gorro", "jacket": "chaqueta", "dress": "vestido", "tshirt": "camiseta", "pants": "pantalones",
	"socks": "calcetines", "boots": "botas", "head": "cabeza", "eye": "ojo", "nose": "nariz",
	"mouth": "boca", "ear": "oreja", "hand": "brazo", "foot": "pierna", "finger": "dedo",
	"ball": "pelota", "doll": "muñeca", "toy_car": "coche de juguete", "cube": "bloque", "book": "libro",
	"pencil": "lápiz", "backpack": "mochila", "sun": "sol", "moon": "luna", "star": "estrella",
	"cloud": "nube", "rain": "lluvia", "snow": "nieve", "tree": "árbol", "flower": "flor",
	"leaf": "hoja", "car": "coche", "bus": "autobús", "train": "tren", "airplane": "avión",
	"bicycle": "bicicleta", "ship": "barco", "clock": "reloj", "key": "llave", "umbrella": "paraguas",
}
const ES_ANIMAL_NAMES := {
	"sea_fish": "pez", "sea_dolphin": "delfín", "sea_whale": "ballena", "sea_shark": "tiburón",
	"sea_octopus": "pulpo", "sea_jellyfish": "medusa", "sea_crab": "cangrejo",
	"sea_starfish": "estrella de mar", "sea_seahorse": "caballito de mar", "sea_turtle": "tortuga marina",
	"farm_cow": "vaca", "farm_pig": "cerdo", "farm_horse": "caballo", "farm_sheep": "oveja",
	"farm_goat": "cabra", "farm_chicken": "gallina", "farm_duck": "pato", "farm_rabbit": "conejo",
	"farm_cat": "gato", "farm_dog": "perro", "sky_eagle": "águila", "sky_owl": "búho",
	"sky_parrot": "loro", "sky_pigeon": "paloma", "sky_sparrow": "gorrión", "sky_crow": "cuervo",
	"sky_seagull": "gaviota", "sky_butterfly": "mariposa", "sky_bee": "abeja", "sky_bat": "murciélago",
	"wild_bear": "oso", "wild_wolf": "lobo", "wild_fox": "zorro", "wild_deer": "ciervo",
	"wild_squirrel": "ardilla", "wild_hedgehog": "erizo", "wild_hare": "liebre", "wild_moose": "alce",
	"wild_boar": "jabalí", "wild_raccoon": "mapache",
}
const FR_WORD_NAMES := {
	"house": "maison", "table": "table", "chair": "chaise", "bed": "lit", "door": "porte",
	"window": "fenêtre", "lamp": "lampe", "cup": "tasse", "plate": "assiette", "spoon": "cuillère",
	"hat": "bonnet", "jacket": "veste", "dress": "robe", "tshirt": "t-shirt", "pants": "pantalon",
	"socks": "chaussettes", "boots": "bottes", "head": "tête", "eye": "oeil", "nose": "nez",
	"mouth": "bouche", "ear": "oreille", "hand": "bras", "foot": "jambe", "finger": "doigt",
	"ball": "balle", "doll": "poupée", "toy_car": "petite voiture", "cube": "cube", "book": "livre",
	"pencil": "crayon", "backpack": "sac à dos", "sun": "soleil", "moon": "lune", "star": "étoile",
	"cloud": "nuage", "rain": "pluie", "snow": "neige", "tree": "arbre", "flower": "fleur",
	"leaf": "feuille", "car": "voiture", "bus": "bus", "train": "train", "airplane": "avion",
	"bicycle": "vélo", "ship": "bateau", "clock": "horloge", "key": "clé", "umbrella": "parapluie",
}
const FR_ANIMAL_NAMES := {
	"sea_fish": "poisson", "sea_dolphin": "dauphin", "sea_whale": "baleine", "sea_shark": "requin",
	"sea_octopus": "poulpe", "sea_jellyfish": "méduse", "sea_crab": "crabe",
	"sea_starfish": "étoile de mer", "sea_seahorse": "hippocampe", "sea_turtle": "tortue de mer",
	"farm_cow": "vache", "farm_pig": "cochon", "farm_horse": "cheval", "farm_sheep": "mouton",
	"farm_goat": "chèvre", "farm_chicken": "poule", "farm_duck": "canard", "farm_rabbit": "lapin",
	"farm_cat": "chat", "farm_dog": "chien", "sky_eagle": "aigle", "sky_owl": "hibou",
	"sky_parrot": "perroquet", "sky_pigeon": "pigeon", "sky_sparrow": "moineau", "sky_crow": "corbeau",
	"sky_seagull": "mouette", "sky_butterfly": "papillon", "sky_bee": "abeille", "sky_bat": "chauve-souris",
	"wild_bear": "ours", "wild_wolf": "loup", "wild_fox": "renard", "wild_deer": "cerf",
	"wild_squirrel": "écureuil", "wild_hedgehog": "hérisson", "wild_hare": "lièvre", "wild_moose": "élan",
	"wild_boar": "sanglier", "wild_raccoon": "raton laveur",
}
const DE_WORD_NAMES := {
	"house": "haus", "table": "tisch", "chair": "stuhl", "bed": "bett", "door": "tür",
	"window": "fenster", "lamp": "lampe", "cup": "tasse", "plate": "teller", "spoon": "löffel",
	"hat": "mütze", "jacket": "jacke", "dress": "kleid", "tshirt": "t-shirt", "pants": "hose",
	"socks": "socken", "boots": "stiefel", "head": "kopf", "eye": "auge", "nose": "nase",
	"mouth": "mund", "ear": "ohr", "hand": "arm", "foot": "bein", "finger": "finger",
	"ball": "ball", "doll": "puppe", "toy_car": "spielzeugauto", "cube": "würfel", "book": "buch",
	"pencil": "bleistift", "backpack": "rucksack", "sun": "sonne", "moon": "mond", "star": "stern",
	"cloud": "wolke", "rain": "regen", "snow": "schnee", "tree": "baum", "flower": "blume",
	"leaf": "blatt", "car": "auto", "bus": "bus", "train": "zug", "airplane": "flugzeug",
	"bicycle": "fahrrad", "ship": "schiff", "clock": "uhr", "key": "schlüssel", "umbrella": "regenschirm",
}
const DE_ANIMAL_NAMES := {
	"sea_fish": "fisch", "sea_dolphin": "delfin", "sea_whale": "wal", "sea_shark": "hai",
	"sea_octopus": "oktopus", "sea_jellyfish": "qualle", "sea_crab": "krabbe",
	"sea_starfish": "seestern", "sea_seahorse": "seepferdchen", "sea_turtle": "meerschildkröte",
	"farm_cow": "kuh", "farm_pig": "schwein", "farm_horse": "pferd", "farm_sheep": "schaf",
	"farm_goat": "ziege", "farm_chicken": "huhn", "farm_duck": "ente", "farm_rabbit": "kaninchen",
	"farm_cat": "katze", "farm_dog": "hund", "sky_eagle": "adler", "sky_owl": "eule",
	"sky_parrot": "papagei", "sky_pigeon": "taube", "sky_sparrow": "spatz", "sky_crow": "krähe",
	"sky_seagull": "möwe", "sky_butterfly": "schmetterling", "sky_bee": "biene", "sky_bat": "fledermaus",
	"wild_bear": "bär", "wild_wolf": "wolf", "wild_fox": "fuchs", "wild_deer": "hirsch",
	"wild_squirrel": "eichhörnchen", "wild_hedgehog": "igel", "wild_hare": "hase", "wild_moose": "elch",
	"wild_boar": "wildschwein", "wild_raccoon": "waschbär",
}

static func all(locale: String = "ru", category: String = "objects") -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	if category == "products":
		for product in ProductCatalog.all(locale):
			resolved.append({
				"key": "food_%s" % product.key,
				"category": category,
				"texture": product.texture,
				"text": product.name,
				"voice": product.voice,
			})
		return _suitable_words(resolved)
	if category == "animals":
		if locale not in ["ru", "en", "pt", "es", "fr", "de"]:
			return resolved
		for animal in _animals():
			var animal_text := String(animal.text)
			if locale == "en":
				animal_text = String(EN_ANIMAL_NAMES.get(animal.key, animal.key))
			elif locale == "pt":
				animal_text = String(PT_ANIMAL_NAMES.get(animal.key, animal.key))
			elif locale == "es":
				animal_text = String(ES_ANIMAL_NAMES.get(animal.key, animal.key))
			elif locale == "fr":
				animal_text = String(FR_ANIMAL_NAMES.get(animal.key, animal.key))
			elif locale == "de":
				animal_text = String(DE_ANIMAL_NAMES.get(animal.key, animal.key))
			resolved.append({
				"key": "animal_%s" % animal.key,
				"category": category,
				"texture": load("res://education/playtown/assets/animal_habitat/animals/%s.webp" % animal.key),
				"text": animal_text,
				"voice": load("res://education/playtown/audio/voice/%s/animals/%s.mp3" % [locale, animal.key]),
			})
		return _suitable_words(resolved)
	if category == "shapes":
		if locale not in ["ru", "en", "pt", "es", "fr", "de"]:
			return resolved
		for shape in _shapes():
			resolved.append({
				"key": "shape_%s" % shape.key,
				"category": category,
				"texture": load("res://education/playtown/assets/learning_objects/shapes/%s.svg" % shape.key),
				"text": LanguageService.get_shape_name(shape.key, locale).to_lower(),
				"voice": LanguageService.get_shape_voice(shape.key, locale),
			})
		return resolved
	for entry in _raw():
		var is_body: bool = BODY_KEYS.has(String(entry.key))
		if (category == "body") != is_body:
			continue
		var locales: Dictionary = entry.locales
		if not locales.has(locale):
			continue
		var localized: Dictionary = locales[locale]
		resolved.append({
			"key": entry.key,
			"category": category,
			"texture": entry.texture,
			"text": localized.text,
			"voice": localized.voice,
		})
	return resolved


static func category_icon_path(category: String) -> String:
	match category:
		"body": return "res://education/playtown/assets/learning_objects/hand.webp"
		"animals": return "res://education/playtown/assets/animal_habitat/animals/farm_dog.webp"
		"products": return "res://education/playtown/assets/grocery/products_v2/apple.webp"
		"shapes": return "res://education/playtown/assets/learning_objects/shapes/triangle.svg"
		_: return "res://education/playtown/assets/learning_objects/table.webp"


static func _suitable_words(entries: Array[Dictionary]) -> Array[Dictionary]:
	var suitable: Array[Dictionary] = []
	for entry in entries:
		var text := String(entry.text)
		if text.contains(" ") or text.contains("-") or text.length() > 12:
			continue
		suitable.append(entry)
	return suitable


static func _raw() -> Array[Dictionary]:
	return [
		_item("house", "дом"),
		_item("table", "стол"),
		_item("chair", "стул"),
		_item("bed", "кровать"),
		_item("door", "дверь"),
		_item("window", "окно"),
		_item("lamp", "лампа"),
		_item("cup", "чашка"),
		_item("plate", "тарелка"),
		_item("spoon", "ложка"),
		_item("hat", "шапка"),
		_item("jacket", "куртка"),
		_item("dress", "платье"),
		_item("tshirt", "футболка"),
		_item("pants", "брюки"),
		_item("socks", "носки"),
		_item("boots", "ботинки"),
		_item("head", "голова"),
		_item("eye", "глаз"),
		_item("nose", "нос"),
		_item("mouth", "рот"),
		_item("ear", "ухо"),
		_item("hand", "рука"),
		_item("foot", "нога"),
		_item("finger", "палец"),
		_item("ball", "мяч"),
		_item("doll", "кукла"),
		_item("toy_car", "машинка"),
		_item("cube", "кубик"),
		_item("book", "книга"),
		_item("pencil", "карандаш"),
		_item("backpack", "рюкзак"),
		_item("sun", "солнце"),
		_item("moon", "луна"),
		_item("star", "звезда"),
		_item("cloud", "облако"),
		_item("rain", "дождь"),
		_item("snow", "снег"),
		_item("tree", "дерево"),
		_item("flower", "цветок"),
		_item("leaf", "лист"),
		_item("car", "машина"),
		_item("bus", "автобус"),
		_item("train", "поезд"),
		_item("airplane", "самолёт"),
		_item("bicycle", "велосипед"),
		_item("ship", "корабль"),
		_item("clock", "часы"),
		_item("key", "ключ"),
		_item("umbrella", "зонт"),
	]


static func _item(key: String, text_ru: String) -> Dictionary:
	return {
		"key": key,
		"texture": load("res://education/playtown/assets/learning_objects/%s.webp" % key),
		"locales": {
			"en": {
				"text": String(EN_WORD_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/en/words/%s.mp3" % key),
			},
			"ru": {
				"text": text_ru,
				"voice": load("res://education/playtown/audio/voice/ru/words/%s.ogg" % key),
			},
			"pt": {
				"text": String(PT_WORD_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/pt/words/%s.mp3" % key),
			},
			"es": {
				"text": String(ES_WORD_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/es/words/%s.mp3" % key),
			},
			"fr": {
				"text": String(FR_WORD_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/fr/words/%s.mp3" % key),
			},
			"de": {
				"text": String(DE_WORD_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/de/words/%s.mp3" % key),
			},
		},
	}


static func _shapes() -> Array[Dictionary]:
	return [
		{"key": "circle", "text": "круг"},
		{"key": "square", "text": "квадрат"},
		{"key": "triangle", "text": "треугольник"},
		{"key": "diamond", "text": "ромб"},
		{"key": "star", "text": "звезда"},
	]


static func _animals() -> Array[Dictionary]:
	return [
		{"key": "sea_fish", "text": "рыба"},
		{"key": "sea_dolphin", "text": "дельфин"},
		{"key": "sea_whale", "text": "кит"},
		{"key": "sea_shark", "text": "акула"},
		{"key": "sea_octopus", "text": "осьминог"},
		{"key": "sea_jellyfish", "text": "медуза"},
		{"key": "sea_crab", "text": "краб"},
		{"key": "sea_starfish", "text": "морская звезда"},
		{"key": "sea_seahorse", "text": "морской конёк"},
		{"key": "sea_turtle", "text": "морская черепаха"},
		{"key": "farm_cow", "text": "корова"},
		{"key": "farm_pig", "text": "свинья"},
		{"key": "farm_horse", "text": "лошадь"},
		{"key": "farm_sheep", "text": "овца"},
		{"key": "farm_goat", "text": "коза"},
		{"key": "farm_chicken", "text": "курица"},
		{"key": "farm_duck", "text": "утка"},
		{"key": "farm_rabbit", "text": "кролик"},
		{"key": "farm_cat", "text": "кошка"},
		{"key": "farm_dog", "text": "собака"},
		{"key": "sky_eagle", "text": "орёл"},
		{"key": "sky_owl", "text": "сова"},
		{"key": "sky_parrot", "text": "попугай"},
		{"key": "sky_pigeon", "text": "голубь"},
		{"key": "sky_sparrow", "text": "воробей"},
		{"key": "sky_crow", "text": "ворона"},
		{"key": "sky_seagull", "text": "чайка"},
		{"key": "sky_butterfly", "text": "бабочка"},
		{"key": "sky_bee", "text": "пчела"},
		{"key": "sky_bat", "text": "летучая мышь"},
		{"key": "wild_bear", "text": "медведь"},
		{"key": "wild_wolf", "text": "волк"},
		{"key": "wild_fox", "text": "лиса"},
		{"key": "wild_deer", "text": "олень"},
		{"key": "wild_squirrel", "text": "белка"},
		{"key": "wild_hedgehog", "text": "ёж"},
		{"key": "wild_hare", "text": "заяц"},
		{"key": "wild_moose", "text": "лось"},
		{"key": "wild_boar", "text": "кабан"},
		{"key": "wild_raccoon", "text": "енот"},
	]
