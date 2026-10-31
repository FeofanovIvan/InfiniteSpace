extends Node2D
@export var back_scene_path: String = "res://education/playtown/scenes/world/city_world.tscn"
@export var buy_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var wrong_sound: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
const STAR_TEXTURE := "res://education/playtown/assets/ui/star.png"
const HOME_TEXTURE := "res://education/playtown/assets/pet_home/buttons/home.png"
const SHELF_TEXTURE := "res://education/playtown/assets/shop/shelf.png"
const PUPPY_TEXTURE := "res://education/playtown/assets/shop/card_puppy.png"
const PET_PRICE := 300
const PUPPY_ASPECT := 662.0 / 1134.0
const SHELF_ASPECT := 1009.0 / 901.0
const SHOP_ITEMS := [
	{"id": "collar", "texture": "res://education/playtown/assets/shop/card_collar.png", "price": 50, "aspect": 663.0 / 819.0},
	{"id": "toothpaste", "texture": "res://education/playtown/assets/shop/card_toothpaste.png", "price": 70, "aspect": 663.0 / 917.0},
	{"id": "shampoo", "texture": "res://education/playtown/assets/shop/card_shampoo.png", "price": 60, "aspect": 663.0 / 982.0},
	{"id": "bone", "texture": "res://education/playtown/assets/shop/card_bone.png", "price": 40, "aspect": 663.0 / 980.0},
	{"id": "bed", "texture": "res://education/playtown/assets/shop/card_bed.png", "price": 120, "aspect": 663.0 / 911.0},
	{"id": "house", "texture": "res://education/playtown/assets/shop/card_house.png", "price": 150, "aspect": 663.0 / 974.0},
	{"id": "water", "texture": "res://education/playtown/assets/shop/card_water.png", "price": 45, "aspect": 663.0 / 917.0},
	{"id": "food", "texture": "res://education/playtown/assets/shop/card_food.png", "price": 80, "aspect": 663.0 / 975.0},
]
const BG_COLOR := Color(0.42, 0.66, 0.32)
const PILL_COLOR := Color(0.98, 0.97, 0.94)
const PRICE_TEXT_COLOR := Color(1, 1, 1)
const PRICE_OUTLINE_COLOR := Color(0.15, 0.35, 0.05)
const PRICE_FLASH_COLOR := Color(1.0, 0.16, 0.16)
const GOLD_TEXT := Color(0.25, 0.18, 0.05)
const SMALL_BAR_TOP := 0.76
const SMALL_BAR_BOTTOM := 0.95
const PUPPY_BAR_TOP := 0.82
const PUPPY_BAR_BOTTOM := 0.965
const ROW_Y_FRAC := [0.40, 0.665]
const COL_X_FRAC := [0.185, 0.395, 0.605, 0.815]
const ITEMS_PER_ROW := 4
const CARD_H_FRAC := 0.25
var bg: ColorRect
var star_pill: Panel
var star_icon: TextureRect
var score_label: Label
var home_btn: TextureButton
var puppy_card: TextureRect
var puppy_btn: Button
var puppy_price_label: Label
var shelf_rect: TextureRect
var item_cards: Array = []
var item_buttons: Array = []
var item_price_labels: Array = []
var consumables_bought_this_visit: Dictionary = {}
var locked_item_material: ShaderMaterial
var sfx_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var popup_blur: TextureRect
var popup_dim: ColorRect
var popup_card_display: TextureRect
var popup_price_label: Label
var popup_buy_btn: Button
var popup_back_btn: Button
var popup_tween: Tween
var popup_open: bool = false
var popup_kind: String = ""
var popup_item_index: int = -1
var popup_source_pos: Vector2
var popup_source_size: Vector2
var popup_target_pos: Vector2
var popup_target_size: Vector2
var popup_bottom_ui_h: float = 180.0
func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	locked_item_material = _make_grayscale_material()
	_build_background()
	_build_hud()
	_build_puppy_panel()
	_build_shelf()
	_build_popup()
	AccessService.preview_pet_access_changed.connect(_on_preview_pet_access_changed)
	GameState.coin_balance_changed.connect(_on_coin_balance_changed)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_all()
	call_deferred("_play_voice_prompt")
func _make_grayscale_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float gray = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray), source.a) * COLOR;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material
func _build_background() -> void:
	bg = ColorRect.new()
	bg.color = BG_COLOR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
func _build_hud() -> void:
	star_pill = GameScorePanel.new()
	add_child(star_pill)
	star_icon = (star_pill as GameScorePanel).score_icon
	score_label = (star_pill as GameScorePanel).score_label
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.add_theme_color_override("font_color", GOLD_TEXT)
	home_btn = TextureButton.new()
	home_btn.texture_normal = load(HOME_TEXTURE)
	home_btn.ignore_texture_size = true
	home_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	home_btn.pressed.connect(_on_home_pressed)
	add_child(home_btn)
func _build_puppy_panel() -> void:
	puppy_card = TextureRect.new()
	puppy_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	puppy_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	puppy_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(puppy_card)
	puppy_btn = _make_invisible_button()
	puppy_btn.pressed.connect(_on_puppy_card_tapped)
	add_child(puppy_btn)
	puppy_price_label = _make_price_label()
	add_child(puppy_price_label)
func _build_shelf() -> void:
	shelf_rect = TextureRect.new()
	shelf_rect.texture = load(SHELF_TEXTURE)
	shelf_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shelf_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shelf_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shelf_rect)
	for slot in range(SHOP_ITEMS.size()):
		var card := TextureRect.new()
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card)
		item_cards.append(card)
		var btn := _make_invisible_button()
		btn.pressed.connect(_on_item_card_tapped.bind(slot))
		add_child(btn)
		item_buttons.append(btn)
		var lbl := _make_price_label()
		lbl.add_theme_font_size_override("font_size", 28)
		add_child(lbl)
		item_price_labels.append(lbl)
func _build_popup() -> void:
	popup_blur = TextureRect.new()
	popup_blur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	popup_blur.stretch_mode = TextureRect.STRETCH_SCALE
	popup_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_blur.visible = false
	popup_blur.modulate = Color(1, 1, 1, 0)
	add_child(popup_blur)
	popup_dim = ColorRect.new()
	popup_dim.color = Color(0, 0, 0, 1)
	popup_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_dim.visible = false
	popup_dim.modulate = Color(1, 1, 1, 0)
	add_child(popup_dim)
	popup_card_display = TextureRect.new()
	popup_card_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	popup_card_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	popup_card_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_card_display.visible = false
	add_child(popup_card_display)
	popup_price_label = _make_price_label()
	popup_price_label.visible = false
	add_child(popup_price_label)
	popup_buy_btn = _make_text_button(LanguageService.get_ui_text("buy"), Color(0.30, 0.62, 0.28))
	popup_buy_btn.pressed.connect(_on_popup_buy_pressed)
	popup_buy_btn.visible = false
	add_child(popup_buy_btn)
	popup_back_btn = _make_text_button(LanguageService.get_ui_text("back"), Color(0.55, 0.55, 0.58))
	popup_back_btn.pressed.connect(_close_popup)
	popup_back_btn.visible = false
	add_child(popup_back_btn)
func _make_invisible_button() -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, empty)
	return btn
func _make_price_label() -> Label:
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_color", PRICE_TEXT_COLOR)
	lbl.add_theme_color_override("font_outline_color", PRICE_OUTLINE_COLOR)
	lbl.add_theme_constant_override("outline_size", 5)
	return lbl
func _make_text_button(text: String, base_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = base_color
	sb_normal.set_corner_radius_all(18)
	sb_normal.shadow_color = Color(0, 0, 0, 0.25)
	sb_normal.shadow_size = 6
	sb_normal.shadow_offset = Vector2(0, 3)
	sb_normal.content_margin_left = 10
	sb_normal.content_margin_right = 10
	sb_normal.content_margin_top = 6
	sb_normal.content_margin_bottom = 6
	var sb_hover: StyleBoxFlat = sb_normal.duplicate()
	sb_hover.bg_color = base_color.lightened(0.12)
	var sb_pressed: StyleBoxFlat = sb_normal.duplicate()
	sb_pressed.bg_color = base_color.darkened(0.12)
	var sb_disabled: StyleBoxFlat = sb_normal.duplicate()
	sb_disabled.bg_color = base_color.darkened(0.35)
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_normal)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.7))
	btn.add_theme_font_size_override("font_size", 26)
	return btn
func _layout() -> void:
	var vs := get_viewport_rect().size
	bg.position = Vector2.ZERO
	bg.size = vs
	if popup_blur:
		popup_blur.position = Vector2.ZERO
		popup_blur.size = vs
	if popup_dim:
		popup_dim.position = Vector2.ZERO
		popup_dim.size = vs
	var pill_h: float = clampf(vs.y * 0.09, 56.0, 96.0)
	var pill_w: float = pill_h * 2.5
	star_pill.position = Vector2(vs.x * 0.025, vs.y * 0.025)
	star_pill.size = Vector2(pill_w, pill_h)
	star_icon.position = Vector2(pill_h * 0.16, pill_h * 0.16)
	star_icon.size = Vector2(pill_h * 0.68, pill_h * 0.68)
	score_label.position = Vector2(pill_h * 0.92, 0.0)
	score_label.size = Vector2(pill_w - pill_h * 0.92 - pill_h * 0.15, pill_h)
	score_label.add_theme_font_size_override("font_size", int(pill_h * 0.42))
	var home_size: float = clampf(vs.y * 0.11, 64.0, 110.0)
	home_btn.size = Vector2(home_size, home_size)
	home_btn.position = Vector2(vs.x - home_size - vs.x * 0.025, vs.y * 0.02)
	var left_col_w: float = vs.x * 0.30
	var top_y: float = pill_h + vs.y * 0.06
	var avail_h: float = vs.y - top_y - vs.y * 0.04
	var puppy_h: float = avail_h
	var puppy_w: float = puppy_h * PUPPY_ASPECT
	if puppy_w > left_col_w * 0.92:
		puppy_w = left_col_w * 0.92
		puppy_h = puppy_w / PUPPY_ASPECT
	var puppy_pos := Vector2((left_col_w - puppy_w) * 0.5, top_y + (avail_h - puppy_h) * 0.5)
	puppy_card.position = puppy_pos
	puppy_card.size = Vector2(puppy_w, puppy_h)
	puppy_btn.position = puppy_pos
	puppy_btn.size = Vector2(puppy_w, puppy_h)
	var pbar_top: float = puppy_pos.y + puppy_h * PUPPY_BAR_TOP
	var pbar_bot: float = puppy_pos.y + puppy_h * PUPPY_BAR_BOTTOM
	puppy_price_label.position = Vector2(puppy_pos.x + puppy_w * 0.40, pbar_top)
	puppy_price_label.size = Vector2(puppy_w * 0.50, pbar_bot - pbar_top)
	_update_puppy_price_font()
	var shelf_x0: float = left_col_w + vs.x * 0.02
	var shelf_avail_w: float = vs.x * 0.975 - shelf_x0
	var shelf_w: float = shelf_avail_w
	var shelf_h: float = shelf_w / SHELF_ASPECT
	var shelf_max_h: float = avail_h * 0.90
	if shelf_h > shelf_max_h:
		shelf_h = shelf_max_h
		shelf_w = shelf_h * SHELF_ASPECT
	var shelf_pos := Vector2(shelf_x0 + (shelf_avail_w - shelf_w) * 0.5, top_y + (avail_h - shelf_h) * 0.5)
	shelf_rect.position = shelf_pos
	shelf_rect.size = Vector2(shelf_w, shelf_h)
	var card_h: float = shelf_h * CARD_H_FRAC
	for slot in range(SHOP_ITEMS.size()):
		var row: int = slot / ITEMS_PER_ROW
		var col: int = slot % ITEMS_PER_ROW
		var aspect: float = SHOP_ITEMS[slot]["aspect"]
		var card_w: float = card_h * aspect
		var cx: float = shelf_pos.x + shelf_w * COL_X_FRAC[col]
		var cy: float = shelf_pos.y + shelf_h * ROW_Y_FRAC[row]
		var card: TextureRect = item_cards[slot]
		var cpos := Vector2(cx - card_w * 0.5, cy - card_h * 0.5)
		card.position = cpos
		card.size = Vector2(card_w, card_h)
		item_buttons[slot].position = cpos
		item_buttons[slot].size = Vector2(card_w, card_h)
		var bar_top: float = cpos.y + card_h * SMALL_BAR_TOP
		var bar_bot: float = cpos.y + card_h * SMALL_BAR_BOTTOM
		var lbl: Label = item_price_labels[slot]
		lbl.position = Vector2(cpos.x + card_w * 0.40, bar_top)
		lbl.size = Vector2(card_w * 0.50, bar_bot - bar_top)
		lbl.add_theme_font_size_override("font_size", int(clampf((bar_bot - bar_top) * 0.5, 12.0, 28.0)))
	if popup_open:
		_recompute_popup_target()
		popup_card_display.position = popup_target_pos
		popup_card_display.size = popup_target_size
		_refresh_popup_content()
func _refresh_all() -> void:
	score_label.text = str(GameState.get_coin_balance())
	if GameState.pet_owned:
		puppy_card.texture = load(PUPPY_TEXTURE)
		puppy_card.material = locked_item_material
		puppy_price_label.text = "✓"
	elif AccessService.has_preview_pet_access():
		puppy_card.texture = load(PUPPY_TEXTURE)
		puppy_card.material = null
		puppy_price_label.text = LanguageService.get_ui_text("trial")
	else:
		puppy_card.texture = load(PUPPY_TEXTURE)
		puppy_card.material = null
		puppy_price_label.text = str(PET_PRICE)
	_update_puppy_price_font()
	var accessories_locked := not GameState.has_pet_access()
	for slot in range(SHOP_ITEMS.size()):
		var data: Dictionary = SHOP_ITEMS[slot]
		item_buttons[slot].disabled = accessories_locked
		var unavailable := _is_item_unavailable_this_visit(data)
		item_cards[slot].material = locked_item_material if accessories_locked or unavailable else null
		if unavailable:
			item_cards[slot].texture = load(data["texture"])
			item_price_labels[slot].text = "✓"
		else:
			item_cards[slot].texture = load(data["texture"])
			item_price_labels[slot].text = str(data["price"])
func _update_puppy_price_font() -> void:
	var is_trial := not GameState.pet_owned and AccessService.has_preview_pet_access()
	var size_factor := 0.36 if is_trial else 0.55
	var max_size := 32.0 if is_trial else 46.0
	puppy_price_label.add_theme_font_size_override("font_size", int(clampf(puppy_price_label.size.y * size_factor, 12.0, max_size)))
func _is_item_unavailable_this_visit(data: Dictionary) -> bool:
	var item_id := String(data["id"])
	if GameState.is_shop_item_consumable(item_id):
		return bool(consumables_bought_this_visit.get(item_id, false))
	return GameState.is_shop_item_owned(item_id)
func _on_puppy_card_tapped() -> void:
	if popup_open:
		return
	_open_popup("pet", -1, puppy_card)
func _on_item_card_tapped(slot: int) -> void:
	if popup_open or not GameState.has_pet_access():
		return
	_open_popup("item", slot, item_cards[slot])
func _open_popup(kind: String, index: int, source_control: Control) -> void:
	popup_open = true
	popup_kind = kind
	popup_item_index = index
	popup_source_pos = source_control.position
	popup_source_size = source_control.size
	var blur_tex := _capture_blur_texture()
	if blur_tex:
		popup_blur.texture = blur_tex
	popup_blur.visible = true
	popup_blur.modulate = Color(1, 1, 1, 0)
	popup_dim.visible = true
	popup_dim.modulate = Color(1, 1, 1, 0)
	popup_card_display.texture = source_control.texture
	popup_card_display.material = source_control.material
	popup_card_display.position = popup_source_pos
	popup_card_display.size = popup_source_size
	popup_card_display.visible = true
	popup_card_display.modulate = Color(1, 1, 1, 1)
	popup_price_label.visible = true
	popup_price_label.modulate = Color(1, 1, 1, 0)
	popup_buy_btn.visible = true
	popup_buy_btn.modulate = Color(1, 1, 1, 0)
	popup_back_btn.visible = true
	popup_back_btn.modulate = Color(1, 1, 1, 0)
	_recompute_popup_target()
	if popup_tween and popup_tween.is_valid():
		popup_tween.kill()
	popup_tween = create_tween()
	popup_tween.set_parallel(true)
	popup_tween.tween_property(popup_blur, "modulate:a", 1.0, 0.35)
	popup_tween.tween_property(popup_dim, "modulate:a", 0.55, 0.35)
	popup_tween.tween_property(popup_card_display, "position", popup_target_pos, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	popup_tween.tween_property(popup_card_display, "size", popup_target_size, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	popup_tween.chain().tween_callback(_show_popup_controls)
func _recompute_popup_target() -> void:
	var vs := get_viewport_rect().size
	var aspect: float = 1.0
	if popup_source_size.y > 0.0:
		aspect = popup_source_size.x / popup_source_size.y
	var bottom_ui_h: float = clampf(vs.y * 0.20, 150.0, 220.0)
	var max_card_h: float = (vs.y - bottom_ui_h) * 0.92
	var target_h: float = min(vs.y * 0.55, max_card_h)
	var target_w: float = target_h * aspect
	if target_w > vs.x * 0.6:
		target_w = vs.x * 0.6
		target_h = target_w / aspect
	popup_target_size = Vector2(target_w, target_h)
	var block_h: float = target_h + bottom_ui_h
	var top: float = (vs.y - block_h) * 0.5
	popup_target_pos = Vector2((vs.x - target_w) * 0.5, top)
	popup_bottom_ui_h = bottom_ui_h
func _show_popup_controls() -> void:
	_refresh_popup_content()
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(popup_price_label, "modulate:a", 1.0, 0.2)
	fade.tween_property(popup_buy_btn, "modulate:a", 1.0, 0.2)
	fade.tween_property(popup_back_btn, "modulate:a", 1.0, 0.2)
func _refresh_popup_content() -> void:
	var owned := false
	var preview_pet := false
	var price := 0
	if popup_kind == "pet":
		preview_pet = not GameState.pet_owned and AccessService.has_preview_pet_access()
		owned = GameState.pet_owned or preview_pet
		price = PET_PRICE
	else:
		var data: Dictionary = SHOP_ITEMS[popup_item_index]
		owned = _is_item_unavailable_this_visit(data)
		price = data["price"]
	popup_price_label.add_theme_color_override("font_color", PRICE_TEXT_COLOR)
	popup_price_label.text = (LanguageService.get_ui_text("included_in_preview") if preview_pet else (LanguageService.get_ui_text("owned") if owned else str(price)))
	popup_price_label.add_theme_font_size_override("font_size", 34)
	var vs := get_viewport_rect().size
	var card_bottom: float = popup_target_pos.y + popup_target_size.y
	var label_w: float = clampf(vs.x * 0.4, 220.0, 420.0)
	var row_y: float = card_bottom + 14.0
	popup_price_label.position = Vector2((vs.x - label_w) * 0.5, row_y)
	popup_price_label.size = Vector2(label_w, 46.0)
	var btn_gap: float = 24.0
	var btn_h: float = 64.0
	var btn_w: float = clampf(vs.x * 0.16, 140.0, 220.0)
	var max_total_w: float = vs.x * 0.9
	if btn_w * 2.0 + btn_gap > max_total_w:
		btn_w = max((max_total_w - btn_gap) * 0.5, 60.0)
	var btn_y: float = row_y + 54.0
	popup_buy_btn.visible = not owned
	popup_buy_btn.disabled = owned
	if owned:
		popup_back_btn.position = Vector2((vs.x - btn_w) * 0.5, btn_y)
		popup_back_btn.size = Vector2(btn_w, btn_h)
	else:
		var total_w: float = btn_w * 2.0 + btn_gap
		var row_x: float = (vs.x - total_w) * 0.5
		popup_buy_btn.position = Vector2(row_x, btn_y)
		popup_buy_btn.size = Vector2(btn_w, btn_h)
		popup_back_btn.position = Vector2(row_x + btn_w + btn_gap, btn_y)
		popup_back_btn.size = Vector2(btn_w, btn_h)
func _close_popup() -> void:
	if not popup_open:
		return
	popup_open = false
	if popup_tween and popup_tween.is_valid():
		popup_tween.kill()
	popup_tween = create_tween()
	popup_tween.set_parallel(true)
	popup_tween.tween_property(popup_card_display, "position", popup_source_pos, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	popup_tween.tween_property(popup_card_display, "size", popup_source_size, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	popup_tween.tween_property(popup_blur, "modulate:a", 0.0, 0.25)
	popup_tween.tween_property(popup_dim, "modulate:a", 0.0, 0.25)
	popup_tween.tween_property(popup_price_label, "modulate:a", 0.0, 0.15)
	popup_tween.tween_property(popup_buy_btn, "modulate:a", 0.0, 0.15)
	popup_tween.tween_property(popup_back_btn, "modulate:a", 0.0, 0.15)
	popup_tween.chain().tween_callback(_hide_popup_nodes)
func _hide_popup_nodes() -> void:
	popup_blur.visible = false
	popup_dim.visible = false
	popup_card_display.visible = false
	popup_price_label.visible = false
	popup_buy_btn.visible = false
	popup_back_btn.visible = false
	_refresh_all()
func _capture_blur_texture() -> ImageTexture:
	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		return null
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 0 or h <= 0:
		return null
	var small_w: int = max(1, int(w / 14.0))
	var small_h: int = max(1, int(h / 14.0))
	img.resize(small_w, small_h, Image.INTERPOLATE_BILINEAR)
	img.resize(w, h, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(img)
func _on_popup_buy_pressed() -> void:
	var success := false
	if popup_kind == "pet":
		success = GameState.buy_pet(PET_PRICE)
	else:
		if not GameState.has_pet_access():
			return
		var data: Dictionary = SHOP_ITEMS[popup_item_index]
		success = GameState.buy_shop_item(data["id"], data["price"])
	if success:
		_play_sfx(buy_sound)
		if popup_kind == "pet":
			popup_card_display.texture = load(PUPPY_TEXTURE)
			popup_card_display.material = locked_item_material
		else:
			var data: Dictionary = SHOP_ITEMS[popup_item_index]
			if GameState.is_shop_item_consumable(String(data["id"])):
				consumables_bought_this_visit[data["id"]] = true
			popup_card_display.texture = load(data["texture"])
			popup_card_display.material = locked_item_material
		_refresh_all()
		_refresh_popup_content()
	else:
		_play_sfx(wrong_sound)
		_flash_price_red()
func _flash_price_red() -> void:
	var lbl := popup_price_label
	var base_pos: Vector2 = lbl.position
	var color_tw := create_tween()
	color_tw.tween_method(func(c): lbl.add_theme_color_override("font_color", c), PRICE_TEXT_COLOR, PRICE_FLASH_COLOR, 0.08)
	color_tw.tween_method(func(c): lbl.add_theme_color_override("font_color", c), PRICE_FLASH_COLOR, PRICE_TEXT_COLOR, 0.14)
	color_tw.tween_method(func(c): lbl.add_theme_color_override("font_color", c), PRICE_TEXT_COLOR, PRICE_FLASH_COLOR, 0.08)
	color_tw.tween_method(func(c): lbl.add_theme_color_override("font_color", c), PRICE_FLASH_COLOR, PRICE_TEXT_COLOR, 0.14)
	var shake_tw := create_tween()
	shake_tw.tween_property(lbl, "position:x", base_pos.x - 10.0, 0.05)
	shake_tw.tween_property(lbl, "position:x", base_pos.x + 10.0, 0.05)
	shake_tw.tween_property(lbl, "position:x", base_pos.x - 7.0, 0.05)
	shake_tw.tween_property(lbl, "position:x", base_pos.x, 0.05)
func _on_home_pressed() -> void:
	if popup_open:
		return
	SFX.transition_to_scene(back_scene_path)
func _on_preview_pet_access_changed(_available: bool) -> void:
	if popup_open:
		_close_popup()
	_refresh_all()
func _on_coin_balance_changed(balance: int) -> void:
	score_label.text = str(balance)
func _play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()
func _play_voice_prompt() -> void:
	var stream := LanguageService.get_ui_voice("pet_shop_intro")
	if stream:
		voice_player.stream = stream
		voice_player.play()
