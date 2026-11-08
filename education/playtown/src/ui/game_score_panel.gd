class_name GameScorePanel
extends Panel

const STAR_ICON: Texture2D = preload("res://education/playtown/assets/ui/star.png")

var score_icon: TextureRect
var score_label: Label


func _ready() -> void:
	if not GameState.coin_balance_changed.is_connected(_on_coin_balance_changed):
		GameState.coin_balance_changed.connect(_on_coin_balance_changed)
	_on_coin_balance_changed(GameState.get_coin_balance())
	_layout_contents()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", _style())
	score_icon = TextureRect.new()
	score_icon.texture = STAR_ICON
	score_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	score_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	score_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(score_icon)
	score_label = Label.new()
	score_label.text = "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.clip_text = true
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_label.add_theme_color_override("font_color", Color("#5e3b1f"))
	score_label.add_theme_color_override("font_outline_color", Color.WHITE)
	score_label.add_theme_constant_override("outline_size", 4)
	add_child(score_label)
	resized.connect(_layout_contents)


func set_score(_value: Variant) -> void:
	score_label.text = str(GameState.get_coin_balance())


func _on_coin_balance_changed(balance: int) -> void:
	score_label.text = str(balance)


func _layout_contents() -> void:
	var padding := maxf(6.0, size.y * 0.10)
	var icon_side := maxf(1.0, size.y - padding * 2.0)
	score_icon.position = Vector2(padding, padding)
	score_icon.size = Vector2.ONE * icon_side
	var label_left := padding + icon_side + maxf(4.0, size.y * 0.05)
	score_label.position = Vector2(label_left, 0.0)
	score_label.size = Vector2(maxf(1.0, size.x - label_left - padding), size.y)
	score_label.add_theme_font_size_override("font_size", int(clampf(size.y * 0.46, 20.0, 46.0)))


func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff4d1")
	style.border_color = Color("#d89b35")
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.32, 0.18, 0.08, 0.22)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 5.0)
	return style
