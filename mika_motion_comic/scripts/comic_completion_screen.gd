class_name ComicCompletionScreen
extends Control

signal continue_pressed

const EXPORTER_SCRIPT := preload("res://mika_motion_comic/scripts/comic_pdf_exporter.gd")
const LANGUAGES := [
	["ru", "Русский"],
	["en", "English"],
	["pt_BR", "Português"],
	["es", "Español"],
	["fr", "Français"],
	["de", "Deutsch"]
]
const COPY := {
	"ru": ["Твой комикс готов", "Скачай полную историю с обеими концовками.", "Язык комикса", "Скачать PDF", "Продолжить", "Создаём PDF...", "PDF сохранён", "Не удалось создать PDF"],
	"en": ["Your comic is ready", "Download the complete story with both endings.", "Comic language", "Download PDF", "Continue", "Creating PDF...", "PDF saved", "Could not create PDF"],
	"pt_BR": ["Seu quadrinho está pronto", "Baixe a história completa com os dois finais.", "Idioma do quadrinho", "Baixar PDF", "Continuar", "Criando PDF...", "PDF salvo", "Não foi possível criar o PDF"],
	"es": ["Tu cómic está listo", "Descarga la historia completa con ambos finales.", "Idioma del cómic", "Descargar PDF", "Continuar", "Creando PDF...", "PDF guardado", "No se pudo crear el PDF"],
	"fr": ["Ta bande dessinée est prête", "Télécharge l’histoire complète avec les deux fins.", "Langue de la BD", "Télécharger le PDF", "Continuer", "Création du PDF...", "PDF enregistré", "Impossible de créer le PDF"],
	"de": ["Dein Comic ist fertig", "Lade die ganze Geschichte mit beiden Enden herunter.", "Sprache des Comics", "PDF herunterladen", "Weiter", "PDF wird erstellt...", "PDF gespeichert", "PDF konnte nicht erstellt werden"]
}

var _drawing: Image
var _panel: Panel
var _title: Label
var _subtitle: Label
var _language_label: Label
var _language: OptionButton
var _progress: ProgressBar
var _status: Label
var _download: Button
var _continue: Button
var _busy := false

func setup(drawing: Image = null) -> void:
	_drawing = drawing.duplicate() if drawing != null and not drawing.is_empty() else null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_copy()
	resized.connect(_layout)
	_layout()

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.075, 0.96)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("102d4c")
	panel_style.border_color = Color("6bd5f5")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(26)
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 16
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)
	_title = _label(34, Color.WHITE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_title)
	_subtitle = _label(20, Color("c5ddeb"))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_subtitle)
	_language_label = _label(18, Color.WHITE)
	_panel.add_child(_language_label)
	_language = OptionButton.new()
	_language.focus_mode = Control.FOCUS_NONE
	_language.add_theme_font_size_override("font_size", 19)
	for item in LANGUAGES:
		_language.add_item(str(item[1]))
		_language.set_item_metadata(_language.item_count - 1, str(item[0]))
	_panel.add_child(_language)
	_select_current_language()
	_progress = ProgressBar.new()
	_progress.min_value = 0
	_progress.max_value = 35
	_progress.value = 0
	_progress.show_percentage = false
	_progress.hide()
	_panel.add_child(_progress)
	_status = _label(15, Color("9bdff2"))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_status)
	_download = _button()
	_download.pressed.connect(_download_pdf)
	_panel.add_child(_download)
	_continue = _button()
	_continue.pressed.connect(func():
		if not _busy:
			continue_pressed.emit()
	)
	_panel.add_child(_continue)
	if MobileLocale != null and MobileLocale.has_signal("language_changed"):
		MobileLocale.language_changed.connect(func(_code: String): _apply_copy())

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _button() -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", ThemeDB.fallback_font)
	button.add_theme_font_size_override("font_size", 20)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("23557a")
	normal.border_color = Color("6bd5f5")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("2c729c")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button

func _current_copy() -> Array:
	var code := str(MobileLocale.language) if MobileLocale != null else "en"
	if code.to_lower().begins_with("pt"):
		code = "pt_BR"
	else:
		code = code.to_lower().substr(0, 2)
	return COPY.get(code, COPY["en"])

func _apply_copy() -> void:
	if _title == null:
		return
	var copy := _current_copy()
	_title.text = str(copy[0])
	_subtitle.text = str(copy[1])
	_language_label.text = str(copy[2])
	_download.text = str(copy[3])
	_continue.text = str(copy[4])
	_layout()

func _select_current_language() -> void:
	var current := str(MobileLocale.language) if MobileLocale != null else "en"
	if current.to_lower().begins_with("pt"):
		current = "pt_BR"
	else:
		current = current.to_lower().substr(0, 2)
	for index in range(_language.item_count):
		if str(_language.get_item_metadata(index)) == current:
			_language.select(index)
			return

func _layout() -> void:
	if _panel == null:
		return
	var view := size
	if view.x < 160.0 or view.y < 160.0:
		return
	var panel_size := Vector2(minf(view.x * 0.88, 760.0), minf(view.y * 0.88, 680.0))
	_panel.position = (view - panel_size) * 0.5
	_panel.size = panel_size
	var pad := maxf(18.0, panel_size.x * 0.07)
	var inner_w := panel_size.x - pad * 2.0
	_title.position = Vector2(pad, panel_size.y * 0.055)
	_title.size = Vector2(inner_w, panel_size.y * 0.11)
	_title.add_theme_font_size_override("font_size", maxi(22, roundi(minf(panel_size.y * 0.064, inner_w / 19.0))))
	_subtitle.position = Vector2(pad, panel_size.y * 0.17)
	_subtitle.size = Vector2(inner_w, panel_size.y * 0.13)
	_subtitle.add_theme_font_size_override("font_size", maxi(14, roundi(panel_size.y * 0.032)))
	_language_label.position = Vector2(pad, panel_size.y * 0.325)
	_language_label.size = Vector2(inner_w, panel_size.y * 0.06)
	_language.position = Vector2(pad, panel_size.y * 0.39)
	_language.size = Vector2(inner_w, panel_size.y * 0.09)
	_progress.position = Vector2(pad, panel_size.y * 0.505)
	_progress.size = Vector2(inner_w, maxf(10.0, panel_size.y * 0.025))
	_status.position = Vector2(pad, panel_size.y * 0.535)
	_status.size = Vector2(inner_w, panel_size.y * 0.09)
	_download.position = Vector2(pad, panel_size.y * 0.64)
	_download.size = Vector2(inner_w, panel_size.y * 0.12)
	_continue.position = Vector2(pad, panel_size.y * 0.79)
	_continue.size = Vector2(inner_w, panel_size.y * 0.12)

func _download_pdf() -> void:
	if _busy:
		return
	_busy = true
	_download.disabled = true
	_continue.disabled = true
	_language.disabled = true
	_progress.value = 0
	_progress.show()
	_status.text = str(_current_copy()[5])
	await get_tree().process_frame
	var exporter: ComicPdfExporter = EXPORTER_SCRIPT.new()
	exporter.progress_changed.connect(func(done: int, total: int):
		_progress.max_value = total
		_progress.value = done
	)
	var user_path: String = await exporter.export_pdf(_selected_language(), _drawing, get_tree())
	if user_path.is_empty():
		_status.text = "%s: %s" % [_current_copy()[7], exporter.last_error]
	else:
		var published_path := _publish_pdf(user_path)
		_status.text = "%s\n%s" % [_current_copy()[6], published_path]
		if OS.get_name() not in ["Android", "iOS"]:
			OS.shell_show_in_file_manager(published_path)
	_progress.hide()
	_busy = false
	_download.disabled = false
	_continue.disabled = false
	_language.disabled = false

func _selected_language() -> String:
	return str(_language.get_item_metadata(_language.selected))

func _publish_pdf(user_path: String) -> String:
	var source := ProjectSettings.globalize_path(user_path)
	if OS.get_name() == "iOS":
		return source
	if OS.get_name() == "Android":
		var android_result := _publish_android_download(source, user_path.get_file())
		if not android_result.is_empty():
			return android_result
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if downloads.is_empty():
		return source
	var target := downloads.path_join(user_path.get_file())
	if DirAccess.copy_absolute(source, target) == OK:
		return target
	return source

func _publish_android_download(source: String, file_name: String) -> String:
	var runtime: Object = Engine.get_singleton("AndroidRuntime")
	if runtime == null:
		return ""
	var BuildVersion = JavaClassWrapper.wrap("android.os.Build$VERSION")
	if BuildVersion == null or int(BuildVersion.SDK_INT) < 29:
		return ""
	var ContentValues = JavaClassWrapper.wrap("android.content.ContentValues")
	var MediaColumns = JavaClassWrapper.wrap("android.provider.MediaStore$MediaColumns")
	var Downloads = JavaClassWrapper.wrap("android.provider.MediaStore$Downloads")
	var Environment = JavaClassWrapper.wrap("android.os.Environment")
	var values = ContentValues.ContentValues()
	values.put(MediaColumns.DISPLAY_NAME, file_name)
	values.put(MediaColumns.MIME_TYPE, "application/pdf")
	values.put(MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
	var resolver = runtime.getApplicationContext().getContentResolver()
	var uri = resolver.insert(Downloads.EXTERNAL_CONTENT_URI, values)
	if uri == null:
		return ""
	var stream = resolver.openOutputStream(uri)
	if stream == null:
		return ""
	stream.write(FileAccess.get_file_as_bytes(source))
	stream.flush()
	stream.close()
	var exception = JavaClassWrapper.get_exception()
	if exception != null:
		push_warning("Could not publish comic PDF to Android Downloads: " + str(exception))
		return ""
	return "Downloads/" + file_name
