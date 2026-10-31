extends RefCounted

const PT_NAMES := {
	"apple": "Maçã", "banana": "Banana", "orange": "Laranja", "pear": "Pera",
	"grapes": "Uva", "strawberry": "Morango", "watermelon": "Melancia",
	"carrot": "Cenoura", "tomato": "Tomate", "cucumber": "Pepino",
	"potato": "Batata", "onion": "Cebola", "cabbage": "Repolho",
	"broccoli": "Brócolis", "milk": "Leite", "cheese": "Queijo",
	"yogurt": "Iogurte", "butter": "Manteiga", "bread": "Pão", "rice": "Arroz",
	"pasta": "Macarrão", "egg": "Ovo", "flour": "Farinha", "chicken": "Frango",
	"fish": "Peixe", "meat": "Carne", "juice": "Suco", "water": "Água",
	"cookies": "Biscoito", "chocolate": "Chocolate",
}
const ES_NAMES := {
	"apple": "Manzana", "banana": "Plátano", "orange": "Naranja", "pear": "Pera",
	"grapes": "Uvas", "strawberry": "Fresa", "watermelon": "Sandía",
	"carrot": "Zanahoria", "tomato": "Tomate", "cucumber": "Pepino",
	"potato": "Papa", "onion": "Cebolla", "cabbage": "Repollo",
	"broccoli": "Brócoli", "milk": "Leche", "cheese": "Queso",
	"yogurt": "Yogur", "butter": "Mantequilla", "bread": "Pan", "rice": "Arroz",
	"pasta": "Pasta", "egg": "Huevo", "flour": "Harina", "chicken": "Pollo",
	"fish": "Pescado", "meat": "Carne", "juice": "Jugo", "water": "Agua",
	"cookies": "Galleta", "chocolate": "Chocolate",
}
const FR_NAMES := {
	"apple": "Pomme", "banana": "Banane", "orange": "Orange", "pear": "Poire",
	"grapes": "Raisins", "strawberry": "Fraise", "watermelon": "Pastèque",
	"carrot": "Carotte", "tomato": "Tomate", "cucumber": "Concombre",
	"potato": "Pomme de terre", "onion": "Oignon", "cabbage": "Chou",
	"broccoli": "Brocoli", "milk": "Lait", "cheese": "Fromage",
	"yogurt": "Yaourt", "butter": "Beurre", "bread": "Pain", "rice": "Riz",
	"pasta": "Pâtes", "egg": "Oeuf", "flour": "Farine", "chicken": "Poulet",
	"fish": "Poisson", "meat": "Viande", "juice": "Jus", "water": "Eau",
	"cookies": "Biscuits", "chocolate": "Chocolat",
}
const DE_NAMES := {
	"apple": "Apfel", "banana": "Banane", "orange": "Orange", "pear": "Birne",
	"grapes": "Trauben", "strawberry": "Erdbeere", "watermelon": "Wassermelone",
	"carrot": "Karotte", "tomato": "Tomate", "cucumber": "Gurke",
	"potato": "Kartoffel", "onion": "Zwiebel", "cabbage": "Kohl",
	"broccoli": "Brokkoli", "milk": "Milch", "cheese": "Käse",
	"yogurt": "Joghurt", "butter": "Butter", "bread": "Brot", "rice": "Reis",
	"pasta": "Nudeln", "egg": "Ei", "flour": "Mehl", "chicken": "Hähnchen",
	"fish": "Fisch", "meat": "Fleisch", "juice": "Saft", "water": "Wasser",
	"cookies": "Kekse", "chocolate": "Schokolade",
}

static func all(locale: String = "ru") -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	for entry in _raw():
		var locales: Dictionary = entry.locales
		if not locales.has(locale):
			continue
		var localized: Dictionary = locales[locale]
		resolved.append({
			"key": entry.key,
			"name": localized.text,
			"texture": entry.texture,
			"voice": localized.voice,
		})
	return resolved


static func _raw() -> Array[Dictionary]:
	return [
		_item("apple", "Apple", "Яблоко"),
		_item("banana", "Banana", "Банан"),
		_item("orange", "Orange", "Апельсин"),
		_item("pear", "Pear", "Груша"),
		_item("grapes", "Grapes", "Виноград"),
		_item("strawberry", "Strawberry", "Клубника"),
		_item("watermelon", "Watermelon", "Арбуз"),
		_item("carrot", "Carrot", "Морковь"),
		_item("tomato", "Tomato", "Помидор"),
		_item("cucumber", "Cucumber", "Огурец"),
		_item("potato", "Potato", "Картофель"),
		_item("onion", "Onion", "Лук"),
		_item("cabbage", "Cabbage", "Капуста"),
		_item("broccoli", "Broccoli", "Брокколи"),
		_item("milk", "Milk", "Молоко"),
		_item("cheese", "Cheese", "Сыр"),
		_item("yogurt", "Yogurt", "Йогурт"),
		_item("butter", "Butter", "Масло"),
		_item("bread", "Bread", "Хлеб"),
		_item("rice", "Rice", "Рис"),
		_item("pasta", "Pasta", "Макароны"),
		_item("egg", "Egg", "Яйцо"),
		_item("flour", "Flour", "Мука"),
		_item("chicken", "Chicken", "Курица"),
		_item("fish", "Fish", "Рыба"),
		_item("meat", "Meat", "Мясо"),
		_item("juice", "Juice", "Сок"),
		_item("water", "Water", "Вода"),
		_item("cookies", "Cookies", "Печенье"),
		_item("chocolate", "Chocolate", "Шоколад"),
	]


static func _item(key: String, name_en: String, name_ru: String) -> Dictionary:
	return {
		"key": key,
		"texture": load("res://education/playtown/assets/grocery/products_v2/%s.webp" % key),
		"locales": {
			"en": {
				"text": name_en,
				"voice": load("res://education/playtown/audio/voice/en/food/%s.mp3" % key),
			},
			"ru": {
				"text": name_ru,
				"voice": load("res://education/playtown/audio/voice/ru/food/%s.ogg" % key),
			},
			"pt": {
				"text": String(PT_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/pt/food/%s.mp3" % key),
			},
			"es": {
				"text": String(ES_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/es/food/%s.mp3" % key),
			},
			"fr": {
				"text": String(FR_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/fr/food/%s.mp3" % key),
			},
			"de": {
				"text": String(DE_NAMES.get(key, key)),
				"voice": load("res://education/playtown/audio/voice/de/food/%s.mp3" % key),
			},
		},
	}
