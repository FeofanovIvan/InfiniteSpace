extends "res://learning/src/features/draw_this/mika_draw_this_native_toolbar_v1_1.gd"
## MIKA_CH08_NATIVE_DRAW_LAYOUT_V2. Story-only delta over Draw It v1.1.
signal drawing_started
signal finale_finished(include_drawing: bool, drawing: Image)
const STORY_CANVAS = preload("res://learning/src/features/draw_this/MIKAStoryFreeCanvas.gd")
const COPY := {
 "ru": ["Нарисуй мир Мики", "Мы не можем показать физический мир Мики: законы физики нашего мира не позволяют нам его изобразить.\n\nНо ты можешь придумать, каким он будет, и нарисовать его так, как захочешь.", "Дальше", "Готово", "Добавить твой рисунок в PDF-комикс?", "Да", "Нет", "Полный комикс можно будет скачать на следующем экране."],
 "en": ["Draw Mika's world", "We cannot show Mika's physical world: the laws of physics in our world do not allow us to depict it.\n\nBut you can imagine what it is like and draw it any way you want.", "Next", "Done", "Add your drawing to the PDF comic?", "Yes", "No", "You can download the complete comic on the next screen."],
 "pt_BR": ["Desenhe o mundo de Mika", "Não podemos mostrar o mundo físico de Mika: as leis da física em nosso mundo não nos permitem representá-lo.\n\nMas você pode imaginar como ele é e desenhá-lo como quiser.", "Avançar", "Concluir", "Adicionar seu desenho ao quadrinho em PDF?", "Sim", "Não", "Você poderá baixar o quadrinho completo na próxima tela."],
 "es": ["Dibuja el mundo de Mika", "No podemos mostrar el mundo físico de Mika: las leyes de la física de nuestro mundo no nos permiten representarlo.\n\nPero tú puedes imaginar cómo es y dibujarlo como quieras.", "Siguiente", "Listo", "¿Añadir tu dibujo al cómic en PDF?", "Sí", "No", "Podrás descargar el cómic completo en la siguiente pantalla."],
 "fr": ["Dessine le monde de Mika", "Nous ne pouvons pas montrer le monde physique de Mika : les lois de la physique de notre monde ne nous permettent pas de le représenter.\n\nMais tu peux imaginer à quoi il ressemble et le dessiner comme tu veux.", "Suivant", "Terminé", "Ajouter ton dessin à la BD en PDF ?", "Oui", "Non", "Tu pourras télécharger toute la BD sur l’écran suivant."],
 "de": ["Zeichne Mikas Welt", "Wir können Mikas physische Welt nicht zeigen: Die Naturgesetze unserer Welt erlauben es uns nicht, sie darzustellen.\n\nAber du kannst dir vorstellen, wie sie aussieht, und sie so zeichnen, wie du möchtest.", "Weiter", "Fertig", "Deine Zeichnung zum PDF-Comic hinzufügen?", "Ja", "Nein", "Den vollständigen Comic kannst du auf dem nächsten Bildschirm herunterladen."]
}
var start_with_intro: bool = true
var _story_ui_ready := false
var _done := false
var _save_button: Button
var _save_capsule: NinePatchRect
var _paper_mask: Panel
var _paper_frame: Panel
var _paper_mask_style: StyleBoxFlat
var _intro: ColorRect
var _intro_text: Label
var _next: Button
var _confirm_layer: CanvasLayer
var _confirm: ColorRect
var _confirm_panel: Panel
var _question: Label
var _notice: Label
var _yes: Button
var _no: Button
var _drawing_snapshot: Image

func _copy() -> Array:
	var code: String = str(MobileLocale.language)
	if code.to_lower().begins_with("pt"):
		code = "pt_BR"
	else:
		code = code.to_lower().substr(0, 2)
	return COPY.get(code, COPY["en"])

func _ready() -> void:
	super._ready()
	_mika_toolbar_layer.layer = 24
	# Keep native sky, board, back, header and tool buttons. Only replace the
	# exercise canvas with its existing story-only free-paper subclass.
	canvas_panel.remove_child(canvas)
	canvas.queue_free()
	var native_style: StyleBoxFlat = canvas_panel.get_theme_stylebox("panel") as StyleBoxFlat
	_paper_mask_style = StyleBoxFlat.new()
	_paper_mask_style.bg_color = Color.WHITE
	_paper_mask_style.anti_aliasing = true
	_paper_mask = Panel.new()
	_paper_mask.name = "StoryPaperRoundedAperture"
	_paper_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper_mask.add_theme_stylebox_override("panel", _paper_mask_style)
	_paper_mask.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	canvas_panel.add_child(_paper_mask)
	canvas = STORY_CANVAS.new() as DrawThisCanvas
	_paper_mask.add_child(canvas)
	# Draw the ORIGINAL cyan frame above the paper. Do not cover the ink.
	_paper_frame = Panel.new()
	_paper_frame.name = "StoryPaperNativeFrameOverlay"
	_paper_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style: StyleBoxFlat = native_style.duplicate() as StyleBoxFlat
	frame_style.draw_center = false
	frame_style.shadow_size = 0
	_paper_frame.add_theme_stylebox_override("panel", frame_style)
	canvas_panel.add_child(_paper_frame)
	background.show()
	background.process_mode = Node.PROCESS_MODE_ALWAYS
	sidebar.hide()
	_mika_progress.hide()
	_mika_back.show()
	_mika_subtitle.hide()
	# Replace the contents, NOT the geometry or artwork, of the native 394x158
	# crystal counter. The shared toolbar still computes its exact position.
	_mika_counter.show()
	for node_name in ["CollectedCrystal_ReferenceArt", "CounterDividerGlow", "CounterDivider", "LiveCrystalCount", "SimulatorButton", "LaunchButton"]:
		var item: CanvasItem = _mika_counter.get_node_or_null(node_name) as CanvasItem
		if item != null:
			item.hide()
	_save_capsule = _mika_counter.get_node("MidnightBlueCrystalCounter") as NinePatchRect
	_save_button = Button.new()
	_save_button.name = "StorySaveInNativeCounter"
	_save_button.flat = true
	_save_button.focus_mode = Control.FOCUS_NONE
	_save_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_save_button.mouse_filter = Control.MOUSE_FILTER_STOP
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		_save_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_save_button.add_theme_color_override(state, Color.WHITE)
	_save_button.add_theme_color_override("font_outline_color", Color("#071a37"))
	_save_button.add_theme_constant_override("outline_size", 2)
	_save_capsule.add_child(_save_button)
	_save_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_save_button.pressed.connect(_ask_save)
	_save_button.mouse_entered.connect(func(): _save_capsule.self_modulate = Color(1.0, 1.12, 1.18))
	_save_button.mouse_exited.connect(func(): _save_capsule.self_modulate = Color.WHITE)
	_save_button.button_down.connect(func(): _save_capsule.self_modulate = Color(0.76, 0.85, 0.93))
	_save_button.button_up.connect(func(): _save_capsule.self_modulate = Color.WHITE)
	_intro = ColorRect.new()
	_intro.color = Color.WHITE
	_intro.mouse_filter = Control.MOUSE_FILTER_STOP
	_mika_toolbar_root.add_child(_intro)
	_intro_text = Label.new()
	_intro_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intro_text.add_theme_color_override("font_color", Color("#182238"))
	_intro.add_child(_intro_text)
	_next = Button.new()
	_next.pressed.connect(_begin_drawing)
	_style_dialog_button(_next)
	_intro.add_child(_next)
	# A separate modal layer above the inherited toolbar and drawing canvas.
	# Explicit geometry avoids PanelContainer minimum-size/layout conflicts.
	_confirm_layer = CanvasLayer.new()
	_confirm_layer.name = "StoryDrawConfirmationLayer"
	_confirm_layer.layer = 25
	_confirm_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_confirm_layer)
	_confirm = ColorRect.new()
	_confirm.name = "StoryDrawConfirmationShade"
	_confirm.color = Color(0.02, 0.06, 0.13, 0.60)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_layer.add_child(_confirm)
	_confirm_panel = Panel.new()
	_confirm_panel.name = "StoryDrawConfirmationPanel"
	_confirm_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_panel.add_theme_stylebox_override("panel", _panel_style(Color("#102d4c"), Color("#6bd5f5"), 3, 24, true))
	_confirm.add_child(_confirm_panel)
	_question = _make_confirmation_label(Color.WHITE)
	_confirm_panel.add_child(_question)
	_notice = _make_confirmation_label(Color("#c5ddeb"))
	_confirm_panel.add_child(_notice)
	_yes = Button.new()
	_no = Button.new()
	for button in [_yes, _no]:
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		_style_dialog_button(button)
		button.add_theme_font_override("font", ThemeDB.fallback_font)
		_confirm_panel.add_child(button)
	_yes.pressed.connect(_finish.bind(true))
	_no.pressed.connect(_finish.bind(false))
	_confirm.hide()
	_intro.visible = start_with_intro
	_story_ui_ready = true
	_refresh_copy()
	_layout()

func _play_current_instruction() -> void:
	pass
func _process(_delta: float) -> void:
	pass
func _settle_mika_drawing_rewards() -> void:
	pass
func _v100_hide_host_back() -> void:
	pass
func _v100_restore_host_back() -> void:
	pass
func _exit_game() -> void:
	if _story_ui_ready and not _intro.visible:
		_ask_save()

func _on_draw_language_changed(_code: String) -> void:
	if _story_ui_ready:
		_refresh_copy()
		_layout()

func _refresh_copy() -> void:
	var c: Array = _copy()
	_mika_title.text = c[0]
	_intro_text.text = c[1]
	_next.text = c[2]
	_save_button.text = c[3]
	_save_button.tooltip_text = c[3]
	_question.text = c[4]
	_yes.text = c[5]
	_no.text = c[6]
	_notice.text = c[7]

func _make_confirmation_label(tint: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	label.add_theme_color_override("font_color", tint)
	return label

func _style_dialog_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _mika_back.get_theme_stylebox(state))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)

func _layout() -> void:
	if not _story_ui_ready:
		super._layout()
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x <= 110.0 or view.y <= 140.0:
		return
	background.position = Vector2.ZERO
	background.size = view
	_mika_toolbar_root.size = view
	var insets: Vector4 = _safe_area_insets(view)
	var safe := Rect2(Vector2(insets.x, insets.y), view - Vector2(insets.x + insets.z, insets.y + insets.w))
	# EXACT native Draw It v1.1 shared header and body geometry.
	var header_bottom: float = MIKA_SHARED_DRAW_TOOLBAR.relayout(view, safe, _mika_back, _mika_counter, _mika_title_panel, _mika_title, _mika_subtitle)
	_mika_subtitle.hide()
	_mika_title.position = Vector2(6.0, 0.0)
	_mika_title.size = Vector2(maxf(32.0, _mika_title_panel.size.x - 12.0), _mika_title_panel.size.y)
	var header: float = _mika_title_panel.size.y
	var title_px: int = _mika_title.get_theme_font_size("font_size")
	var title_font: Font = _mika_title.get_theme_font("font")
	while title_px > 8 and title_font.get_string_size(_mika_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_px).x > _mika_title.size.x - 8.0:
		title_px -= 1
	_mika_title.add_theme_font_size_override("font_size", title_px)
	var save_px: int = 39
	var save_font: Font = _save_button.get_theme_font("font")
	while save_px > 10 and save_font.get_string_size(_save_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, save_px).x > _save_capsule.size.x * 0.84:
		save_px -= 1
	_save_button.add_theme_font_size_override("font_size", save_px)
	var edge_x: float = safe.size.x * 0.018
	var gap_y: float = safe.size.y * 0.018
	var bottom: float = safe.end.y - gap_y
	var body_size := Vector2(safe.size.x - edge_x * 2.0, bottom - header_bottom - gap_y)
	if body_size.x <= 45.0 or body_size.y <= 65.0:
		return
	outer_panel.position = Vector2(safe.position.x + edge_x, header_bottom + gap_y)
	outer_panel.size = body_size
	# Only difference from native layout: no lesson strip, so paper occupies
	# the entire interior. All three original tools remain OVER the paper.
	var pad: float = minf(body_size.x, body_size.y) * 0.022
	var paper := Rect2(Vector2.ONE * pad, body_size - Vector2.ONE * pad * 2.0)
	canvas_panel.position = paper.position
	canvas_panel.size = paper.size
	var canvas_inset: float = maxf(3.0, minf(paper.size.x, paper.size.y) * 0.012)
	var native_style: StyleBoxFlat = canvas_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var inner_radius: int = maxi(0, native_style.corner_radius_top_left - ceili(canvas_inset))
	_paper_mask_style.set_corner_radius_all(inner_radius)
	_paper_mask.position = Vector2.ONE * canvas_inset
	_paper_mask.size = paper.size - Vector2.ONE * canvas_inset * 2.0
	canvas.set("corner_radius", float(inner_radius))
	canvas.position = Vector2.ZERO
	canvas.size = _paper_mask.size
	_paper_frame.position = Vector2.ZERO
	_paper_frame.size = paper.size
	# Original compact v1.1 bottom-right tool stack; no new tool geometry.
	var short_side: float = minf(paper.size.x, paper.size.y)
	var tool_size: float = minf(paper.size.y * 0.13, paper.size.x * 0.11)
	var tool_margin: float = short_side * 0.022
	var tool_gap: float = tool_size * 0.12
	var tools: Array[Button] = [color_button, eraser_button, clear_button]
	var icons: Array[Control] = [palette_icon, eraser_icon, clear_icon]
	var bottom_right: Vector2 = paper.position + paper.size - Vector2.ONE * (tool_size + tool_margin)
	for i in range(tools.size()):
		var button: Button = tools[i]
		var icon_node: Control = icons[i]
		button.position = bottom_right - Vector2(0.0, float(i) * (tool_size + tool_gap))
		button.size = Vector2.ONE * tool_size
		icon_node.position = Vector2.ONE * tool_size * 0.09
		icon_node.size = Vector2.ONE * tool_size * 0.82
	# Reuse v1.1's actual adaptive pencil popover and seven native textures.
	_layout_palette()
	_intro.size = view
	_intro_text.position = safe.position + safe.size * Vector2(0.10, 0.10)
	_intro_text.size = safe.size * Vector2(0.80, 0.65)
	_intro_text.add_theme_font_size_override("font_size", maxi(14, roundi(minf(safe.size.y * 0.047, safe.size.x / 32.0))))
	_next.size = Vector2(safe.size.x * 0.25, header)
	_next.position = safe.position + safe.size * Vector2(0.375, 0.82)
	_next.add_theme_font_size_override("font_size", maxi(12, roundi(header * 0.35)))
	_layout_confirmation(view, safe)

func _layout_confirmation(view: Vector2, safe: Rect2) -> void:
	_confirm.position = Vector2.ZERO
	_confirm.size = view
	var panel_w: float = minf(safe.size.x * 0.82, 820.0)
	var panel_h: float = minf(safe.size.y * 0.66, 420.0)
	var panel_size := Vector2(panel_w, panel_h)
	_confirm_panel.position = safe.get_center() - panel_size * 0.5
	_confirm_panel.size = panel_size
	var pad: float = panel_w * 0.065
	var text_w: float = panel_w - pad * 2.0
	_question.position = Vector2(pad, panel_h * 0.065)
	_question.size = Vector2(text_w, panel_h * 0.37)
	_question.add_theme_font_size_override("font_size", maxi(10, roundi(minf(panel_h * 0.077, text_w / 25.0))))
	_notice.position = Vector2(pad, panel_h * 0.45)
	_notice.size = Vector2(text_w, panel_h * 0.22)
	_notice.add_theme_font_size_override("font_size", maxi(9, roundi(minf(panel_h * 0.051, text_w / 38.0))))
	var button_gap: float = panel_w * 0.045
	var button_w: float = (text_w - button_gap) * 0.5
	var button_h: float = panel_h * 0.21
	for button in [_yes, _no]:
		button.size = Vector2(button_w, button_h)
		button.add_theme_font_size_override("font_size", maxi(10, roundi(minf(button_h * 0.45, button_w * 0.19))))
	_yes.position = Vector2(pad, panel_h * 0.74)
	_no.position = Vector2(pad + button_w + button_gap, panel_h * 0.74)

func _begin_drawing() -> void:
	_intro.hide()
	drawing_started.emit()
func _ask_save() -> void:
	if _done or _confirm.visible:
		return
	canvas._end_stroke()
	palette_panel.hide()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for button in [color_button, eraser_button, clear_button, _save_button, _mika_back]:
		button.disabled = true
	_drawing_snapshot = _capture_drawing()
	_layout()
	_confirm.show()
func _finish(include_drawing: bool) -> void:
	if _done:
		return
	_done = true
	finale_finished.emit(include_drawing, _drawing_snapshot if include_drawing else null)

func _capture_drawing() -> Image:
	var viewport_image := get_viewport().get_texture().get_image()
	if viewport_image == null or viewport_image.is_empty():
		return null
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return null
	var rect := canvas.get_global_rect()
	var scale := Vector2(viewport_image.get_width() / viewport_size.x, viewport_image.get_height() / viewport_size.y)
	var crop := Rect2i(
		maxi(0, floori(rect.position.x * scale.x)),
		maxi(0, floori(rect.position.y * scale.y)),
		mini(viewport_image.get_width(), ceili(rect.size.x * scale.x)),
		mini(viewport_image.get_height(), ceili(rect.size.y * scale.y))
	)
	if crop.position.x + crop.size.x > viewport_image.get_width():
		crop.size.x = viewport_image.get_width() - crop.position.x
	if crop.position.y + crop.size.y > viewport_image.get_height():
		crop.size.y = viewport_image.get_height() - crop.position.y
	return viewport_image.get_region(crop) if crop.size.x > 0 and crop.size.y > 0 else null
