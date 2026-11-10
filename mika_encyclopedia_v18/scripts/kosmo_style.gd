extends RefCounted
## Shared palette and minimal, consistent style tokens for the child-facing encyclopedia.

const INK: Color = Color("#0a1a36")
const BASE: Color = Color("#102448")
const SURFACE: Color = Color("#132a4d")
const CARD: Color = Color("#163051")
const TEXT: Color = Color("#f6f9ff")
const MUTED: Color = Color("#b7c8df")
const CYAN: Color = Color("#75e2f2")
const GOLD: Color = Color("#ffda86")

const ACCENTS: Dictionary = {
	"planets": Color("#69dcea"),
	"stations": Color("#b2a1fd"),
	"races": Color("#8de8b7"),
	"characters": Color("#ffba92"),
	"science": Color("#ffda86"),
	"terms": Color("#fba7cc")
}

const NAMES: Dictionary = {
	"planets": "Планеты", "stations": "Космостанции",
	"races": "Жители миров", "characters": "Друзья Мики",
	"science": "Почемучка", "terms": "Космоштуки"
}

const ICONS: Dictionary = {
	"planets": "◌", "stations": "⌂", "races": "✦",
	"characters": "♡", "science": "✧", "terms": "⚙"
}

const TILE_IMAGES: Dictionary = {
	"planets": "res://mika_encyclopedia_v18/assets/worlds/m33_p03.jpg",
	"stations": "res://mika_encyclopedia_v18/assets/stations/station_02.jpg",
	"races": "res://mika_encyclopedia_v18/assets/races/phase_group.jpg",
	"characters": "res://mika_encyclopedia_v18/assets/races/human_group.jpg",
	"science": "res://mika_encyclopedia_v18/assets/worlds/m33_p04.jpg",
	"terms": "res://mika_encyclopedia_v18/assets/technology/translator_tablet.jpg"
}

const TEASERS: Dictionary = {
	"planets": "Миры, горы, льды и океаны",
	"stations": "Необычные дома среди звёзд",
	"races": "Кто живёт на других планетах?",
	"characters": "Знакомься с исследователями",
	"science": "Ответы на большие «почему?»",
	"terms": "Корабли, приборы и энергия"
}

static func tint(key: String) -> Color:
	return ACCENTS.get(key, CYAN)


static func box(color: Color, radius: int = 20, outline: Color = Color.TRANSPARENT, border_px: int = 0, padding_px: int = 16) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = padding_px
	style.content_margin_right = padding_px
	style.content_margin_top = padding_px
	style.content_margin_bottom = padding_px
	if border_px > 0:
		style.border_color = outline
		style.border_width_left = border_px
		style.border_width_right = border_px
		style.border_width_top = border_px
		style.border_width_bottom = border_px
	return style


# Navigation uses the EXACT inverse-wing geometry and pastel palette from the
# real planet_hub HUD (source: bottom_hud.gd); these PNGs are native nine-patches
# assembled from its existing bezier points, not arbitrary rounded buttons.
const BACK_NORMAL: Texture2D = preload("res://mika_encyclopedia_v18/assets/ui/mika_back_normal.png")
const BACK_HOVER: Texture2D = preload("res://mika_encyclopedia_v18/assets/ui/mika_back_hover.png")
const BACK_PRESSED: Texture2D = preload("res://mika_encyclopedia_v18/assets/ui/mika_back_pressed.png")
const FORWARD_NORMAL: Texture2D = preload("res://mika_encyclopedia_v18/assets/ui/mika_forward_normal.png")
const FORWARD_HOVER: Texture2D = preload("res://mika_encyclopedia_v18/assets/ui/mika_forward_hover.png")
const FORWARD_PRESSED: Texture2D = preload("res://mika_encyclopedia_v18/assets/ui/mika_forward_pressed.png")


static func _wing(texture: Texture2D, forward: bool) -> StyleBoxTexture:
	var wing: StyleBoxTexture = StyleBoxTexture.new()
	wing.texture = texture
	wing.texture_margin_left = 18.0
	wing.texture_margin_right = 18.0
	wing.texture_margin_top = 18.0
	wing.texture_margin_bottom = 18.0
	wing.content_margin_left = 13.0 if forward else 25.0
	wing.content_margin_right = 25.0 if forward else 13.0
	wing.content_margin_top = 6.0
	wing.content_margin_bottom = 6.0
	return wing


static func apply_navigation(button: Button, forward: bool = false) -> void:
	var normal: Texture2D = FORWARD_NORMAL if forward else BACK_NORMAL
	var hovered: Texture2D = FORWARD_HOVER if forward else BACK_HOVER
	var pressed: Texture2D = FORWARD_PRESSED if forward else BACK_PRESSED
	button.add_theme_stylebox_override("normal", _wing(normal, forward))
	button.add_theme_stylebox_override("hover", _wing(hovered, forward))
	button.add_theme_stylebox_override("pressed", _wing(pressed, forward))
	button.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 17, Color("c9f7ff"), 2, 9))
	button.add_theme_stylebox_override("disabled", _wing(normal, forward))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("092a42"))
	button.add_theme_color_override("font_disabled_color", Color("233d52"))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


# Secondary controls match the blue outline, dark matte plates of MIKA's HUD.
static func apply_secondary(button: Button, accent: Color = CYAN) -> void:
	button.add_theme_stylebox_override("normal", box(Color("061d39"), 14, accent.darkened(0.24), 1, 9))
	button.add_theme_stylebox_override("hover", box(Color("153c57"), 14, accent, 2, 9))
	button.add_theme_stylebox_override("pressed", box(Color("05233a"), 14, accent, 2, 9))
	button.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 14, Color("c9f7ff"), 2, 9))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, TEXT)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
