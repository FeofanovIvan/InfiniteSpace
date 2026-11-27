extends Control
## Standalone six-language settings modal. Reuses MobileLocale persistence.
## Input is handled by this modal; underlying simulator/flight UI stays unchanged.

signal game_mode_selected(mode: String, restart: bool)
signal story_arc_selected(arc_id: String)

const StoryProgress: Script = preload("res://scripts/StoryProgress.gd")
const StoryArcBrowser: Script = preload("res://scripts/StoryArcBrowser.gd")
const StorySubscriptionGate: Script = preload("res://scripts/StorySubscriptionGate.gd")
const StoryModeChoiceDialog: Script = preload("res://scripts/StoryModeChoiceDialog.gd")

const CLOSE_GLYPH: Script = preload("res://simulator_ui/neon_close_glyph.gd")
const LOCALES: Array[String] = ["en", "ru", "fr", "de", "es", "pt_BR"]
const NAMES: Array[String] = ["English", "Русский", "Français", "Deutsch", "Español", "Português (BR)"]
const HEADINGS: Dictionary = {"en": "SETTINGS", "ru": "НАСТРОЙКИ", "fr": "PARAMÈTRES", "de": "EINSTELLUNGEN", "es": "AJUSTES", "pt_BR": "CONFIGURAÇÕES"}
const V104_LABELS: Dictionary = {
	"ru":{"mode":"Режим игры", "free":"Свободный мир", "story":"История", "privacy":"Политика конфиденциальности", "purchase":"Покупка", "privacy_hint":"Ссылка на политику конфиденциальности пока не настроена.", "purchase_hint":"Покупка будет доступна после подключения магазина."},
	"en":{"mode":"Game mode", "free":"Free world", "story":"Story", "privacy":"Privacy Policy", "purchase":"Purchase", "privacy_hint":"The official privacy policy link is not configured yet.", "purchase_hint":"Purchases will be available after store setup."},
	"fr":{"mode":"Mode de jeu", "free":"Monde libre", "story":"Histoire", "privacy":"Politique de confidentialité", "purchase":"Achat", "privacy_hint":"Le lien officiel vers la politique de confidentialité n’est pas encore défini.", "purchase_hint":"Les achats seront disponibles après la configuration de la boutique."},
	"de":{"mode":"Spielmodus", "free":"Freie Welt", "story":"Geschichte", "privacy":"Datenschutzerklärung", "purchase":"Kauf", "privacy_hint":"Der offizielle Datenschutzlink ist noch nicht eingerichtet.", "purchase_hint":"Käufe folgen nach der Einrichtung des Shops."},
	"es":{"mode":"Modo de juego", "free":"Mundo libre", "story":"Historia", "privacy":"Política de privacidad", "purchase":"Compra", "privacy_hint":"Aún no se ha configurado el enlace oficial de privacidad.", "purchase_hint":"Las compras estarán disponibles al configurar la tienda."},
	"pt_BR":{"mode":"Modo de jogo", "free":"Mundo livre", "story":"História", "privacy":"Política de privacidade", "purchase":"Compra", "privacy_hint":"O link oficial da política de privacidade ainda não foi configurado.", "purchase_hint":"As compras estarão disponíveis após configurar a loja."}
}
const STORY_CHOICE_LABELS: Dictionary = {
	"ru": {"title": "СЮЖЕТНОЕ ПРИКЛЮЧЕНИЕ", "question": "Хотите начать историю сначала или продолжить с сохранённого момента?", "continue": "Продолжить", "restart": "Начать сначала", "cancel": "Отмена"},
	"en": {"title": "STORY ADVENTURE", "question": "Start the story over or continue from your checkpoint?", "continue": "Continue", "restart": "Start over", "cancel": "Cancel"},
	"fr": {"title": "AVENTURE", "question": "Recommencer l’histoire ou continuer au point sauvegardé ?", "continue": "Continuer", "restart": "Recommencer", "cancel": "Annuler"},
	"de": {"title": "GESCHICHTE", "question": "Geschichte neu beginnen oder vom Speicherpunkt fortsetzen?", "continue": "Fortsetzen", "restart": "Neu beginnen", "cancel": "Abbrechen"},
	"es": {"title": "AVENTURA", "question": "¿Empezar la historia de nuevo o continuar desde el punto guardado?", "continue": "Continuar", "restart": "Empezar de nuevo", "cancel": "Cancelar"},
	"pt_BR": {"title": "AVENTURA", "question": "Recomeçar a história ou continuar do ponto salvo?", "continue": "Continuar", "restart": "Recomeçar", "cancel": "Cancelar"}
}
# Shared mode file is read by StoryProgress; Story is enabled on develop.
const LANGUAGE_LABELS: Dictionary = {"en": "Language", "ru": "Язык", "fr": "Langue", "de": "Sprache", "es": "Idioma", "pt_BR": "Idioma"}
const ARCS_LABELS: Dictionary = {"ru": "Сюжетные арки", "en": "Story arcs", "fr": "Arcs narratifs", "de": "Handlungsbögen", "es": "Arcos narrativos", "pt_BR": "Arcos da história"}

var _veil: ColorRect
var _panel: Panel
var _title: Label
var _subtitle: Label
var _close: Button
var _buttons: Array[Button] = []
var _v104_mode_title: Label
var _v104_free: Button
var _v104_story: Button
var _v104_arcs: Button
var _v104_privacy: Button
var _v104_purchase: Button
var _v104_info: Label
var _story_choice: CanvasLayer
var _story_browser: Control

func _ready() -> void:
	call_deferred("_mika_ency_v21_attach")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_veil = ColorRect.new()
	_veil.color = Color(0.0, 0.015, 0.05, 0.76)
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.gui_input.connect(_veil_input)
	_panel = Panel.new()
	_panel.name = "LanguageSettingsNeonPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _style(Color("061c38"), Color("26dfff"), 24))
	add_child(_panel)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_color_override("font_color", Color("f3fbff"))
	_panel.add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.add_theme_color_override("font_color", Color("74ceff"))
	_panel.add_child(_subtitle)
	_close = Button.new()
	_close.text = ""
	_close.focus_mode = Control.FOCUS_NONE
	_close.add_theme_stylebox_override("normal", _style(Color("061c38"), Color("26dfff"), 14))
	_close.add_theme_stylebox_override("hover", _style(Color("103e63"), Color("a6eeff"), 14))
	_close.add_theme_stylebox_override("pressed", _style(Color("174b70"), Color("a6eeff"), 14))
	_close.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_close.pressed.connect(close_settings)
	_panel.add_child(_close)
	var close_glyph: Control = CLOSE_GLYPH.new()
	close_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_close.add_child(close_glyph)
	close_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(LOCALES.size()):
		var b: Button = Button.new()
		b.name = "Language_" + LOCALES[i]
		b.text = NAMES[i]
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.pressed.connect(_select_language.bind(LOCALES[i]))
		_panel.add_child(b)
		_buttons.append(b)
	_v104_build_extras()
	_story_browser = StoryArcBrowser.new() as Control
	_story_browser.name = "UnlockedStoryArcArchive"
	add_child(_story_browser)
	_story_browser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_browser.arc_chosen.connect(_v104_arc_chosen)
	resized.connect(_layout)
	MobileLocale.language_changed.connect(_refresh_locale)
	_refresh_locale(MobileLocale.language)
	_layout()

func _style(bg: Color, outline: Color, radius: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = outline
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.04, 0.64, 1.0, 0.24)
	s.shadow_size = 5
	return s

func _veil_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_settings()
	elif event is InputEventScreenTouch and event.pressed:
		close_settings()

func _select_language(code: String) -> void:
	MobileLocale.set_language(code)

func _refresh_locale(_language: String) -> void:
	if _title == null:
		return
	_title.text = str(HEADINGS.get(MobileLocale.language, HEADINGS["en"]))
	_subtitle.text = str(LANGUAGE_LABELS.get(MobileLocale.language, LANGUAGE_LABELS["en"]))
	for i in range(_buttons.size()):
		var button: Button = _buttons[i]
		var selected: bool = LOCALES[i] == MobileLocale.language
		button.add_theme_stylebox_override("normal", _style(Color("0d4671") if selected else Color("082644"), Color("83f5ff") if selected else Color("2475ad"), 14))
		button.add_theme_stylebox_override("hover", _style(Color("15577b"), Color("83f5ff"), 14))
		button.add_theme_stylebox_override("pressed", _style(Color("15577b"), Color("83f5ff"), 14))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.add_theme_color_override("font_color", Color("ffffff") if selected else Color("c7e9ff"))
	_v104_refresh_extras()

func _layout() -> void:
	if _panel == null:
		return
	var view: Vector2 = get_viewport_rect().size
	if view.x < 180 or view.y < 180:
		return
	var safe: Rect2 = MobileLocale.safe_rect(view)
	var w: float = minf(670.0, safe.size.x - 14.0)
	var h: float = minf(650.0, safe.size.y - 14.0)
	var s: float = clampf(minf(w / 670.0, h / 650.0), 0.35, 1.0)
	_panel.position = safe.position + (safe.size - Vector2(w, h)) * 0.5
	_panel.size = Vector2(w, h)
	_title.position = Vector2(33.0*s, 12.0*s)
	_title.size = Vector2(w - 100.0*s, 46.0*s)
	_title.add_theme_font_size_override("font_size", maxi(15, roundi(28.0*s)))
	_subtitle.position = Vector2(24.0*s, 68.0*s)
	_subtitle.size = Vector2(w - 48.0*s, 28.0*s)
	_subtitle.add_theme_font_size_override("font_size", maxi(13, roundi(20.0*s)))
	_close.position = Vector2(w - 56.0*s, 10.0*s)
	_close.size = Vector2.ONE * (43.0*s)
	var margin: float = 25.0*s
	var gap: float = 11.0*s
	var cell_w: float = (w - margin*2.0 - gap*2.0)/3.0
	for i in range(_buttons.size()):
		var b: Button = _buttons[i]
		b.position = Vector2(margin + float(i%3)*(cell_w+gap), 108.0*s + float(i/3)*82.0*s)
		b.size = Vector2(cell_w, 68.0*s)
		b.add_theme_font_size_override("font_size", maxi(11, roundi(18.0*s)))
	_v104_mode_title.position = Vector2(margin, 287.0*s)
	_v104_mode_title.size = Vector2(w-margin*2.0, 35.0*s)
	_v104_mode_title.add_theme_font_size_override("font_size", maxi(14,roundi(20.0*s)))
	var mode_w: float = (w-margin*2.0-gap*2.0)/3.0
	_v104_free.position = Vector2(margin, 326.0*s)
	_v104_free.size = Vector2(mode_w, 70.0*s)
	_v104_story.position = Vector2(margin+mode_w+gap, 326.0*s)
	_v104_story.size = Vector2(mode_w, 70.0*s)
	_v104_arcs.position = Vector2(margin+(mode_w+gap)*2.0, 326.0*s)
	_v104_arcs.size = Vector2(mode_w, 70.0*s)
	_v104_privacy.position = Vector2(margin, 418.0*s)
	_v104_privacy.size = Vector2(w-margin*2.0, 62.0*s)
	_v104_purchase.position = Vector2(margin, 494.0*s)
	_v104_purchase.size = Vector2(w-margin*2.0, 62.0*s)
	_v104_info.position = Vector2(margin, 572.0*s)
	_v104_info.size = Vector2(w-margin*2.0, 60.0*s)
	_v104_info.add_theme_font_size_override("font_size", maxi(11,roundi(15.0*s)))
	for button in [_v104_free, _v104_story, _v104_arcs, _v104_privacy, _v104_purchase]:
		button.add_theme_font_size_override("font_size", maxi(12,roundi(18.0*s)))

func _v104_extra_button() -> Button:
	var b: Button = Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _style(Color("133c60"),Color("58c5ed"),16))
	b.add_theme_stylebox_override("hover", _style(Color("19557c"),Color("94e5fc"),16))
	b.add_theme_stylebox_override("pressed", _style(Color("216284"),Color("94e5fc"),16))
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	b.add_theme_color_override("font_color",Color("f0faff"))
	_panel.add_child(b)
	return b

func _v104_build_extras() -> void:
	_v104_mode_title = Label.new()
	_v104_mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v104_mode_title.add_theme_color_override("font_color",Color("96dcff"))
	_panel.add_child(_v104_mode_title)
	_v104_free = _v104_extra_button()
	_v104_free.pressed.connect(_v104_choose_free)
	_v104_story = _v104_extra_button()
	_v104_story.pressed.connect(_v104_choose_story)
	_v104_arcs = _v104_extra_button()
	_v104_arcs.pressed.connect(_v104_choose_arcs)
	_v104_privacy = _v104_extra_button()
	_v104_purchase = _v104_extra_button()
	_v104_privacy.name = "MikaSettingsPrivacyPolicy"
	_v104_purchase.name = "MikaSettingsSubscriptionPurchase"
	_v104_privacy.pressed.connect(_v104_unconfigured.bind("privacy_hint"))
	_v104_purchase.pressed.connect(_v104_show_subscription)
	_v104_info = Label.new()
	_v104_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v104_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_v104_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v104_info.add_theme_color_override("font_color",Color("f3cf82"))
	_panel.add_child(_v104_info)

func _v104_refresh_extras() -> void:
	if _v104_mode_title == null:
		return
	var words: Dictionary = V104_LABELS.get(MobileLocale.language,V104_LABELS["en"])
	_v104_mode_title.text = str(words.get("mode","Game mode"))
	_v104_free.text = str(words.get("free","Free world"))
	_v104_story.text = str(words.get("story","Story"))
	_v104_arcs.text = str(ARCS_LABELS.get(MobileLocale.language, ARCS_LABELS["en"]))
	_v104_privacy.text = str(words.get("privacy","Privacy Policy"))
	_v104_purchase.text = StorySubscriptionGate.word("buy")
	var current_mode: String = StoryProgress.read_mode()
	_v104_free.add_theme_stylebox_override("normal",_style(Color("b26a2a"),Color("ffd36e"),16) if current_mode == "free_world" else _style(Color("133c60"),Color("58c5ed"),16))
	_v104_story.add_theme_stylebox_override("normal",_style(Color("b26a2a"),Color("ffd36e"),16) if current_mode == "story" else _style(Color("133c60"),Color("58c5ed"),16))

func _v104_choose_free() -> void:
	if not StoryProgress.write_mode("free_world"):
		return
	_v104_info.text = ""
	close_settings()
	game_mode_selected.emit("free_world", false)

func _v104_choose_story() -> void:
	var labels: Dictionary = STORY_CHOICE_LABELS.get(MobileLocale.language, STORY_CHOICE_LABELS["en"])
	if is_instance_valid(_story_choice):
		return
	_story_choice = StoryModeChoiceDialog.new() as CanvasLayer
	_story_choice.name = "StoryContinueOrRestart"
	add_child(_story_choice)
	_story_choice.call("configure_choice", str(labels["title"]), str(labels["question"]), str(labels["continue"]), str(labels["restart"]), str(labels["cancel"]))
	_story_choice.connect("subscribe_requested", _v104_story_dialog_choice.bind(false))
	_story_choice.connect("restart_requested", _v104_story_dialog_choice.bind(true))
	_story_choice.connect("dismissed", _v104_close_story_dialog)

func _v104_choose_arcs() -> void:
	if is_instance_valid(_story_browser):
		_story_browser.open_browser()

func _v104_arc_chosen(arc_id: String) -> void:
	close_settings()
	story_arc_selected.emit(arc_id)

func _v104_close_story_dialog() -> void:
	if is_instance_valid(_story_choice):
		_story_choice.queue_free()
	_story_choice = null


func _v104_story_dialog_choice(restart: bool) -> void:
	_v104_close_story_dialog()
	_v104_enter_story(restart)

func _v104_enter_story(restart: bool) -> void:
	if restart and not StoryProgress.restart_story():
		return
	if not StoryProgress.write_mode("story"):
		return
	close_settings()
	game_mode_selected.emit("story", restart)

func _v104_unconfigured(key: String) -> void:
	var words: Dictionary = V104_LABELS.get(MobileLocale.language,V104_LABELS["en"])
	_v104_info.text = str(words.get(key,"Not configured yet"))


func _v104_show_subscription() -> void:
	StorySubscriptionGate.show_notice(self, "station")

func open_settings() -> void:
	visible = true
	_v104_refresh_extras()
	_layout()
	# MIKA_ENC_V572_SYNC_SETTINGS
	var enc_actions: Node = get_node_or_null("/root/MikaEncyclopediaSettingsButton")
	if enc_actions != null and enc_actions.has_method("refresh_now"):
		enc_actions.call("refresh_now")

func close_settings() -> void:
	_v104_close_story_dialog()
	if is_instance_valid(_story_browser):
		_story_browser.close_browser()
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_instance_valid(_story_browser) and _story_browser.visible:
			_story_browser.close_browser()
		else:
			close_settings()
		get_viewport().set_input_as_handled()

func _mika_ency_v21_attach() -> void:
	if get_node_or_null("MikaNativeEncyclopediaEntryHook") != null:
		return
	var helper_script: Script = load("res://mika_encyclopedia_v18/scripts/native_settings_entry.gd") as Script
	if helper_script == null:
		push_error("MIKA Encyclopedia: native Settings helper missing")
		return
	var helper: Node = helper_script.new() as Node
	if helper == null:
		push_error("MIKA Encyclopedia: cannot instantiate Settings helper")
		return
	helper.name = "MikaNativeEncyclopediaEntryHook"
	add_child(helper)
