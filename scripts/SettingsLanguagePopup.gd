extends Control
## Standalone six-language settings modal. Reuses MobileLocale persistence.
## Input is handled by this modal; underlying simulator/flight UI stays unchanged.

const CLOSE_GLYPH: Script = preload("res://simulator_ui/neon_close_glyph.gd")
const PRIVACY_POLICY_URL: String = "https://mika.playtownkids.app/privacy/"
const LOCALES: Array[String] = ["en", "ru", "fr", "de", "es", "pt_BR"]
const NAMES: Array[String] = ["English", "Русский", "Français", "Deutsch", "Español", "Português (BR)"]
const HEADINGS: Dictionary = {"en": "SETTINGS", "ru": "НАСТРОЙКИ", "fr": "PARAMÈTRES", "de": "EINSTELLUNGEN", "es": "AJUSTES", "pt_BR": "CONFIGURAÇÕES"}
const V104_LABELS: Dictionary = {
	"ru":{"mode":"Режим игры", "free":"Свободный мир", "story":"Сюжет (скоро)", "privacy":"Политика конфиденциальности", "purchase":"Полная версия", "purchase_hint":"Покупка полной версии появится после 10 бесплатных минут."},
	"en":{"mode":"Game mode", "free":"Free world", "story":"Story (coming soon)", "privacy":"Privacy Policy", "purchase":"Full game", "purchase_hint":"The full-game purchase appears after 10 free minutes."},
	"fr":{"mode":"Mode de jeu", "free":"Monde libre", "story":"Histoire (bientôt)", "privacy":"Politique de confidentialité", "purchase":"Jeu complet", "purchase_hint":"L’achat du jeu complet apparaît après 10 minutes gratuites."},
	"de":{"mode":"Spielmodus", "free":"Freie Welt", "story":"Geschichte (bald)", "privacy":"Datenschutzerklärung", "purchase":"Vollversion", "purchase_hint":"Der Kauf der Vollversion erscheint nach 10 kostenlosen Minuten."},
	"es":{"mode":"Modo de juego", "free":"Mundo libre", "story":"Historia (próximamente)", "privacy":"Política de privacidad", "purchase":"Juego completo", "purchase_hint":"La compra del juego completo aparece después de 10 minutos gratis."},
	"pt_BR":{"mode":"Modo de jogo", "free":"Mundo livre", "story":"História (em breve)", "privacy":"Política de privacidade", "purchase":"Jogo completo", "purchase_hint":"A compra do jogo completo aparece após 10 minutos grátis."}
}
const V104_MODE_CONFIG: String = "user://miko_mode.cfg"
const AUDIO_CONFIG_PATH: String = "user://miko_audio.cfg"
# InfiniteSpace v104: Free world default; the story mode is not released.
const LANGUAGE_LABELS: Dictionary = {"en": "Language", "ru": "Язык", "fr": "Langue", "de": "Sprache", "es": "Idioma", "pt_BR": "Idioma"}
const VOLUME_LABELS: Dictionary = {"en": "Volume", "ru": "Громкость", "fr": "Volume", "de": "Lautstärke", "es": "Volumen", "pt_BR": "Volume"}

var _veil: ColorRect
var _panel: Panel
var _title: Label
var _subtitle: Label
var _close: Button
var _buttons: Array[Button] = []
var _v104_mode_title: Label
var _v104_free: Button
var _v104_story: Button
var _v104_privacy: Button
var _v104_purchase: Button
var _v104_info: Label
var _volume_title: Label
var _volume_slider: HSlider
var _volume_value: Label

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
	_build_audio_settings()
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
	var h: float = minf(690.0, safe.size.y - 14.0)
	var s: float = clampf(minf(w / 670.0, h / 690.0), 0.35, 1.0)
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
	var mode_w: float = (w-margin*2.0-gap)/2.0
	_v104_free.position = Vector2(margin, 326.0*s)
	_v104_free.size = Vector2(mode_w, 70.0*s)
	_v104_story.position = Vector2(margin+mode_w+gap, 326.0*s)
	_v104_story.size = Vector2(mode_w, 70.0*s)
	_v104_privacy.position = Vector2(margin, 418.0*s)
	_v104_privacy.size = Vector2(w-margin*2.0, 62.0*s)
	_v104_purchase.position = Vector2(margin, 494.0*s)
	_v104_purchase.size = Vector2(w-margin*2.0, 62.0*s)
	_volume_title.position = Vector2(margin, 562.0*s)
	_volume_title.size = Vector2(150.0*s, 38.0*s)
	_volume_title.add_theme_font_size_override("font_size", maxi(12, roundi(18.0*s)))
	_volume_slider.position = Vector2(margin + 155.0*s, 562.0*s)
	_volume_slider.size = Vector2(maxf(80.0*s, w-margin*2.0-230.0*s), 38.0*s)
	_volume_value.position = Vector2(w-margin-68.0*s, 562.0*s)
	_volume_value.size = Vector2(68.0*s, 38.0*s)
	_volume_value.add_theme_font_size_override("font_size", maxi(12, roundi(17.0*s)))
	_v104_info.position = Vector2(margin, 614.0*s)
	_v104_info.size = Vector2(w-margin*2.0, 58.0*s)
	_v104_info.add_theme_font_size_override("font_size", maxi(11,roundi(15.0*s)))
	for button in [_v104_free, _v104_story, _v104_privacy, _v104_purchase]:
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
	_v104_story.disabled = true
	_v104_story.mouse_default_cursor_shape = Control.CURSOR_ARROW
	_v104_story.add_theme_stylebox_override("disabled",_style(Color("09213c"),Color("355a78"),16))
	_v104_story.add_theme_color_override("font_disabled_color",Color("7893ab"))
	_v104_privacy = _v104_extra_button()
	_v104_purchase = _v104_extra_button()
	_v104_privacy.pressed.connect(_v104_open_privacy)
	_v104_purchase.pressed.connect(_v104_open_purchase)
	_v104_info = Label.new()
	_v104_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v104_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_v104_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v104_info.add_theme_color_override("font_color",Color("f3cf82"))
	_panel.add_child(_v104_info)

func _build_audio_settings() -> void:
	_volume_title = Label.new()
	_volume_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_volume_title.add_theme_color_override("font_color", Color("96dcff"))
	_panel.add_child(_volume_title)
	_volume_slider = HSlider.new()
	_volume_slider.name = "MasterVolume"
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 1.0
	_volume_slider.value_changed.connect(_on_volume_changed)
	_panel.add_child(_volume_slider)
	_volume_value = Label.new()
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_volume_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_volume_value.add_theme_color_override("font_color", Color("f0faff"))
	_panel.add_child(_volume_value)
	var config := ConfigFile.new()
	var saved_volume := 100.0
	if config.load(AUDIO_CONFIG_PATH) == OK:
		saved_volume = clampf(float(config.get_value("audio", "master_percent", 100.0)), 0.0, 100.0)
	_volume_slider.set_value_no_signal(saved_volume)
	_apply_master_volume(saved_volume)
	_refresh_volume_text(saved_volume)

func _on_volume_changed(value: float) -> void:
	_apply_master_volume(value)
	_refresh_volume_text(value)
	var config := ConfigFile.new()
	config.set_value("audio", "master_percent", clampf(value, 0.0, 100.0))
	if config.save(AUDIO_CONFIG_PATH) != OK:
		push_warning("Could not persist audio volume")

func _apply_master_volume(value: float) -> void:
	var percent := clampf(value, 0.0, 100.0)
	var master_index := AudioServer.get_bus_index("Master")
	if master_index >= 0:
		AudioServer.set_bus_volume_db(master_index, linear_to_db(percent / 100.0) if percent > 0.0 else -80.0)
	var voice_service := get_node_or_null("/root/MikaVoice")
	if voice_service != null:
		voice_service.set("volume", roundi(percent))

func _refresh_volume_text(value: float) -> void:
	if _volume_value != null:
		_volume_value.text = "%d%%" % roundi(value)

func _v104_refresh_extras() -> void:
	if _v104_mode_title == null:
		return
	var words: Dictionary = V104_LABELS.get(MobileLocale.language,V104_LABELS["en"])
	_v104_mode_title.text = str(words.get("mode","Game mode"))
	_v104_free.text = str(words.get("free","Free world"))
	_v104_story.text = str(words.get("story","Story (coming soon)"))
	_v104_privacy.text = str(words.get("privacy","Privacy Policy"))
	_v104_purchase.text = str(words.get("purchase","Purchase"))
	_v104_free.add_theme_stylebox_override("normal",_style(Color("b26a2a"),Color("ffd36e"),16))
	if _volume_title != null:
		_volume_title.text = str(VOLUME_LABELS.get(MobileLocale.language, VOLUME_LABELS["en"]))

func _v104_choose_free() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("game","mode","free_world")
	var result: int = config.save(V104_MODE_CONFIG)
	if result != OK:
		push_warning("Could not persist free-world mode: " + str(result))
	_v104_info.text = ""

func _v104_unconfigured(key: String) -> void:
	var words: Dictionary = V104_LABELS.get(MobileLocale.language,V104_LABELS["en"])
	_v104_info.text = str(words.get(key,"Not configured yet"))

func _v104_open_privacy() -> void:
	OS.shell_open(PRIVACY_POLICY_URL)

func _v104_open_purchase() -> void:
	close_settings()
	AccessService.show_purchase_options()

func open_settings() -> void:
	visible = true
	_layout()
	# MIKA_ENC_V572_SYNC_SETTINGS
	var enc_actions: Node = get_node_or_null("/root/MikaEncyclopediaSettingsButton")
	if enc_actions != null and enc_actions.has_method("refresh_now"):
		enc_actions.call("refresh_now")

func close_settings() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
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
