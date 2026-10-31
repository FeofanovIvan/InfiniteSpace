extends Node2D

enum PlayMode { FREE, DEMO, GUIDE }

const BACKGROUND_TEXTURE: Texture2D = preload("res://education/playtown/assets/background/character_select_bg.jpg")
const SONGS_PATH := "res://education/playtown/data/piano/songs.json"
const SONG_LOCALIZATIONS_PATH := "res://education/playtown/data/piano/song_localizations.json"
const NOTE_DISPLAY := {
	"C4": "C", "Cs4": "C♯", "D4": "D", "Ds4": "D♯", "E4": "E", "F4": "F",
	"Fs4": "F♯", "G4": "G", "Gs4": "G♯", "A4": "A", "As4": "A♯", "B4": "B", "C5": "C"
}
const LOCAL_TEXT := {
	"song": {"ru": "Песня", "en": "Song", "pt": "Música", "es": "Canción", "fr": "Chanson", "de": "Lied"},
	"listen": {"ru": "Послушать", "en": "Listen", "pt": "Ouvir", "es": "Escuchar", "fr": "Écouter", "de": "Anhören"},
	"learn": {"ru": "Учить", "en": "Learn", "pt": "Aprender", "es": "Aprender", "fr": "Apprendre", "de": "Lernen"},
	"stop": {"ru": "Стоп", "en": "Stop", "pt": "Parar", "es": "Parar", "fr": "Arrêter", "de": "Stopp"},
	"listen_hint": {"ru": "Слушай и смотри на клавиши", "en": "Listen and watch the keys", "pt": "Ouça e observe as teclas", "es": "Escucha y mira las teclas", "fr": "Écoute et regarde les touches", "de": "Höre zu und beobachte die Tasten"},
	"learn_hint": {"ru": "Нажми подсвеченную клавишу", "en": "Press the highlighted key", "pt": "Pressione a tecla iluminada", "es": "Pulsa la tecla iluminada", "fr": "Appuie sur la touche éclairée", "de": "Drücke die leuchtende Taste"},
	"finished": {"ru": "Отлично!", "en": "Well done!", "pt": "Muito bem!", "es": "¡Muy bien!", "fr": "Bravo !", "de": "Super!"}
}

var background: TextureRect
var tint: ColorRect
var keyboard_panel: Panel
var keyboard: PianoKeyboard
var exit_button: GameExitButton
var note_label: Label
var music_label: Label
var lyrics_label: RichTextLabel
var side_panel: Panel
var song_title: Label
var song_selector: OptionButton
var listen_button: Button
var learn_button: Button
var progress_label: Label
var mode_label: Label
var note_tween: Tween
var songs: Array = []
var song_localizations: Dictionary = {}
var selected_song: Dictionary = {}
var mode := PlayMode.FREE
var event_index := 0
var demo_elapsed_ms := 0.0
var current_line := ""
var current_syllable := ""
var lyric_font_size := 30
var guide_transitioning := false


func _ready() -> void:
	_load_songs()
	_load_song_localizations()
	_build_ui()
	_fill_song_selector()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _process(delta: float) -> void:
	if mode != PlayMode.DEMO or selected_song.is_empty():
		return
	demo_elapsed_ms += delta * 1000.0
	var events: Array = selected_song.get("events", [])
	var time_scale := _playback_time_scale()
	while event_index < events.size() and float(events[event_index].get("startMs", 0)) * time_scale <= demo_elapsed_ms:
		var event: Dictionary = events[event_index]
		keyboard.set_guide_note("")
		keyboard.set_demo_note(String(event.get("note", "")))
		keyboard.play_demo_note(String(event.get("note", "")), float(event.get("durationMs", 600)) * time_scale)
		_show_event(event, event_index + 1)
		event_index += 1
	# In listen mode the visual cue starts together with the sound.
	if event_index >= events.size():
		var total_duration := float(selected_song.get("totalDurationMs", 0)) * time_scale
		if demo_elapsed_ms >= total_duration + 350.0:
			_finish_song()


func _load_songs() -> void:
	var file := FileAccess.open(SONGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		songs = parsed.get("songs", [])


func _load_song_localizations() -> void:
	var file := FileAccess.open(SONG_LOCALIZATIONS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		song_localizations = parsed


func _build_ui() -> void:
	background = TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -20
	add_child(background)
	tint = ColorRect.new()
	tint.color = Color(0.93, 0.88, 1.0, 0.72)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.z_index = -10
	add_child(tint)
	keyboard_panel = Panel.new()
	keyboard_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff4d6"), Color("#d99b35")))
	add_child(keyboard_panel)
	keyboard = PianoKeyboard.new()
	keyboard.note_played.connect(_on_note_played)
	keyboard.user_note_played.connect(_on_user_note_played)
	keyboard_panel.add_child(keyboard)
	exit_button = GameExitButton.new()
	exit_button.pressed.connect(_go_back)
	add_child(exit_button)
	music_label = Label.new()
	music_label.text = "♪   ♫   ♪"
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	music_label.add_theme_color_override("font_color", Color("#7749c8"))
	music_label.add_theme_color_override("font_outline_color", Color.WHITE)
	music_label.add_theme_constant_override("outline_size", 7)
	music_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(music_label)
	note_label = Label.new()
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note_label.add_theme_color_override("font_color", Color("#ff8a1f"))
	note_label.add_theme_color_override("font_outline_color", Color.WHITE)
	note_label.add_theme_constant_override("outline_size", 8)
	note_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(note_label)
	lyrics_label = RichTextLabel.new()
	lyrics_label.bbcode_enabled = true
	lyrics_label.fit_content = false
	lyrics_label.scroll_active = false
	lyrics_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lyrics_label)
	side_panel = Panel.new()
	side_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff8e4"), Color("#9b65cf")))
	add_child(side_panel)
	song_title = Label.new()
	song_title.text = _text("song")
	song_title.visible = false
	song_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	song_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	song_title.add_theme_color_override("font_color", Color("#5d337c"))
	side_panel.add_child(song_title)
	song_selector = OptionButton.new()
	song_selector.focus_mode = Control.FOCUS_NONE
	song_selector.fit_to_longest_item = false
	song_selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	song_selector.item_selected.connect(_on_song_selected)
	_style_selector(song_selector)
	side_panel.add_child(song_selector)
	listen_button = Button.new()
	listen_button.focus_mode = Control.FOCUS_NONE
	listen_button.pressed.connect(_on_listen_pressed)
	_style_action_button(listen_button, Color("#8b5bd1"))
	side_panel.add_child(listen_button)
	learn_button = Button.new()
	learn_button.focus_mode = Control.FOCUS_NONE
	learn_button.pressed.connect(_on_learn_pressed)
	_style_action_button(learn_button, Color("#55ae54"))
	side_panel.add_child(learn_button)
	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color", Color("#6b4627"))
	side_panel.add_child(progress_label)
	mode_label = Label.new()
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_label.add_theme_color_override("font_color", Color("#6c5b74"))
	side_panel.add_child(mode_label)
	_update_button_texts()


func _fill_song_selector() -> void:
	for song_value in songs:
		var song: Dictionary = song_value
		song_selector.add_item("♫  %s" % _localized_song_title(song))
	if not songs.is_empty():
		selected_song = songs[0]
		song_selector.select(0)
		_show_song_ready()


func _layout() -> void:
	var view := get_viewport_rect().size
	var safe := _safe_area_insets(view)
	var scale_factor := minf(view.x / 1536.0, view.y / 768.0)
	var margin := clampf(minf(view.x, view.y) * 0.03, 14.0, 38.0)
	var left := safe.x + margin
	var right := view.x - safe.z - margin
	var top := safe.y + margin
	var bottom := view.y - safe.w - margin
	background.position = Vector2.ZERO
	background.size = view
	tint.position = Vector2.ZERO
	tint.size = view
	var side_width := clampf(view.x * 0.26, 280.0, 410.0)
	var side_height := clampf(view.y * 0.255, 142.0, 205.0)
	side_panel.position = Vector2(right - side_width, top)
	side_panel.size = Vector2(side_width, side_height)
	exit_button.position = Vector2(left, top)
	exit_button.size = Vector2.ONE * clampf(82.0 * scale_factor, 58.0, 96.0)
	var music_width := clampf(view.x * 0.32, 250.0, 520.0)
	music_label.position = Vector2(view.x * 0.5 - music_width * 0.5, top - 8.0)
	music_label.size = Vector2(music_width, view.y * 0.12)
	music_label.add_theme_font_size_override("font_size", int(clampf(54.0 * scale_factor, 30.0, 68.0)))
	var note_width := music_width * 0.26
	note_label.position = Vector2(music_label.position.x - note_width - margin * 0.25, top - 5.0)
	note_label.size = Vector2(note_width, view.y * 0.12)
	note_label.add_theme_font_size_override("font_size", int(clampf(68.0 * scale_factor, 38.0, 86.0)))
	var min_keyboard_top := maxf(top + side_height + margin * 0.5, view.y * 0.30)
	var full_keyboard_width := maxf(1.0, right - left)
	var desired_keyboard_height := maxf(view.y * 0.52, full_keyboard_width / 8.0 * 2.5)
	desired_keyboard_height = minf(desired_keyboard_height, view.y * 0.64)
	var keyboard_height := minf(desired_keyboard_height, maxf(1.0, bottom - min_keyboard_top))
	var panel_top := bottom - keyboard_height
	var lyrics_top := top + view.y * 0.105
	lyrics_label.position = Vector2(left, lyrics_top)
	lyrics_label.size = Vector2(full_keyboard_width, maxf(1.0, panel_top - lyrics_top - margin * 0.18))
	lyric_font_size = int(clampf(31.0 * scale_factor, 19.0, 38.0))
	_refresh_lyrics()
	keyboard_panel.position = Vector2(left, panel_top)
	keyboard_panel.size = Vector2(full_keyboard_width, keyboard_height)
	var inner := clampf(keyboard_panel.size.y * 0.05, 9.0, 22.0)
	keyboard.position = Vector2(inner, inner)
	keyboard.size = keyboard_panel.size - Vector2.ONE * inner * 2.0
	_layout_side_panel(scale_factor)


func _layout_side_panel(scale_factor: float) -> void:
	var padding := clampf(side_panel.size.x * 0.055, 10.0, 20.0)
	var width := side_panel.size.x - padding * 2.0
	var selector_h := clampf(side_panel.size.y * 0.31, 42.0, 62.0)
	var button_h := clampf(side_panel.size.y * 0.27, 38.0, 54.0)
	var gap := clampf(side_panel.size.y * 0.045, 5.0, 10.0)
	var y := padding
	song_selector.position = Vector2(padding, y)
	song_selector.size = Vector2(width, selector_h)
	song_selector.add_theme_font_size_override("font_size", int(clampf(21.0 * scale_factor, 14.0, 24.0)))
	var song_popup := song_selector.get_popup()
	song_popup.add_theme_font_size_override("font_size", int(clampf(24.0 * scale_factor, 18.0, 28.0)))
	song_popup.add_theme_constant_override("v_separation", int(clampf(15.0 * scale_factor, 9.0, 18.0)))
	song_popup.min_size = Vector2(
		clampf(maxf(width * 1.18, get_viewport_rect().size.x * 0.30), 310.0, 540.0),
		0.0
	)
	y += selector_h + gap
	var half_width := (width - gap) * 0.5
	listen_button.position = Vector2(padding, y)
	listen_button.size = Vector2(half_width, button_h)
	listen_button.add_theme_font_size_override("font_size", int(clampf(20.0 * scale_factor, 14.0, 23.0)))
	learn_button.position = Vector2(padding + half_width + gap, y)
	learn_button.size = Vector2(half_width, button_h)
	learn_button.add_theme_font_size_override("font_size", int(clampf(20.0 * scale_factor, 14.0, 23.0)))
	y += button_h + gap * 0.35
	progress_label.position = Vector2(padding, y)
	progress_label.size = Vector2(width * 0.28, maxf(1.0, side_panel.size.y - y - padding))
	progress_label.add_theme_font_size_override("font_size", int(clampf(19.0 * scale_factor, 14.0, 22.0)))
	mode_label.position = Vector2(padding + width * 0.29, y)
	mode_label.size = Vector2(width * 0.71, maxf(1.0, side_panel.size.y - y - padding))
	mode_label.add_theme_font_size_override("font_size", int(clampf(16.0 * scale_factor, 11.0, 18.0)))


func _on_song_selected(index: int) -> void:
	_stop_playback()
	if index >= 0 and index < songs.size():
		selected_song = songs[index]
		_show_song_ready()


func _on_listen_pressed() -> void:
	if mode == PlayMode.DEMO:
		_stop_playback()
	else:
		_start_demo()


func _on_learn_pressed() -> void:
	if mode == PlayMode.GUIDE:
		_stop_playback()
	else:
		_start_guide()


func _start_demo() -> void:
	if selected_song.is_empty():
		return
	_stop_playback()
	mode = PlayMode.DEMO
	event_index = 0
	demo_elapsed_ms = 0.0
	keyboard.set_interactive(false)
	mode_label.text = _text("listen_hint")
	_update_button_texts()


func _start_guide() -> void:
	if selected_song.is_empty():
		return
	_stop_playback()
	mode = PlayMode.GUIDE
	guide_transitioning = false
	event_index = 0
	keyboard.set_interactive(true)
	mode_label.text = _text("learn_hint")
	var events: Array = selected_song.get("events", [])
	if not events.is_empty():
		var first_event: Dictionary = events[0]
		keyboard.set_guide_note(String(first_event.get("note", "")))
		_show_event(first_event, 1)
	_update_button_texts()


func _stop_playback() -> void:
	mode = PlayMode.FREE
	event_index = 0
	demo_elapsed_ms = 0.0
	guide_transitioning = false
	keyboard.clear_guidance()
	keyboard.set_interactive(true)
	keyboard.stop_all_audio()
	mode_label.text = ""
	progress_label.text = ""
	_update_button_texts()


func _on_user_note_played(note: String) -> void:
	if mode != PlayMode.GUIDE or selected_song.is_empty() or guide_transitioning:
		return
	var events: Array = selected_song.get("events", [])
	if event_index >= events.size():
		return
	var expected: Dictionary = events[event_index]
	if note != String(expected.get("note", "")):
		return
	event_index += 1
	if event_index >= events.size():
		_finish_song()
		return
	var next_event: Dictionary = events[event_index]
	var next_note := String(next_event.get("note", ""))
	if next_note == note:
		# A repeated note needs a fresh visual cue instead of one continuous
		# highlight, otherwise a child may think one press completed both notes.
		guide_transitioning = true
		keyboard.set_guide_note("")
		await get_tree().create_timer(0.16).timeout
		if mode != PlayMode.GUIDE or event_index >= events.size():
			guide_transitioning = false
			return
		var still_expected: Dictionary = events[event_index]
		keyboard.set_guide_note(String(still_expected.get("note", "")))
		guide_transitioning = false
	else:
		keyboard.set_guide_note(next_note)
	_show_event(next_event, event_index + 1)


func _playback_time_scale() -> float:
	return maxf(0.25, float(selected_song.get("playbackTimeScale", 1.0)))


func _on_note_played(note: String) -> void:
	note_label.text = NOTE_DISPLAY.get(note, note)
	note_label.modulate.a = 1.0
	note_label.scale = Vector2(0.78, 0.78)
	note_label.pivot_offset = note_label.size * 0.5
	if note_tween:
		note_tween.kill()
	note_tween = create_tween()
	note_tween.tween_property(note_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	note_tween.tween_interval(0.45)
	note_tween.tween_property(note_label, "modulate:a", 0.0, 0.24)
	note_tween.tween_callback(func() -> void:
		note_label.text = ""
		note_label.modulate.a = 1.0
	)


func _show_event(event: Dictionary, progress: int) -> void:
	current_line = _localized_song_line(selected_song, event)
	current_syllable = String(event.get("lyricSyllable", "")) if _piano_locale() == "en" else ""
	if current_line.is_empty():
		current_line = _localized_song_title(selected_song)
	var events: Array = selected_song.get("events", [])
	progress_label.text = "%d / %d" % [progress, events.size()]
	_refresh_lyrics()


func _show_song_ready() -> void:
	current_line = _localized_song_title(selected_song)
	current_syllable = ""
	progress_label.text = ""
	mode_label.text = ""
	_refresh_lyrics()


func _finish_song() -> void:
	mode = PlayMode.FREE
	keyboard.clear_guidance()
	keyboard.set_interactive(true)
	current_line = _text("finished")
	current_syllable = "★"
	mode_label.text = _text("finished")
	progress_label.text = "✓"
	_refresh_lyrics()
	_update_button_texts()


func _refresh_lyrics() -> void:
	if lyrics_label == null:
		return
	var syllable_size := int(round(lyric_font_size * 1.15))
	var text := "[center][color=#56366e][font_size=%d]%s[/font_size][/color]" % [lyric_font_size, current_line]
	if not current_syllable.is_empty():
		text += "\n[color=#f27b24][font_size=%d][b]%s[/b][/font_size][/color]" % [syllable_size, current_syllable]
	text += "[/center]"
	lyrics_label.text = text


func _update_button_texts() -> void:
	if listen_button == null or learn_button == null:
		return
	listen_button.text = "■  " + _text("stop") if mode == PlayMode.DEMO else "▶  " + _text("listen")
	learn_button.text = "■  " + _text("stop") if mode == PlayMode.GUIDE else "★  " + _text("learn")


func _text(key: String) -> String:
	var locale := _piano_locale()
	var entries: Dictionary = LOCAL_TEXT.get(key, {})
	return String(entries.get(locale, entries.get("en", key)))


func _piano_locale() -> String:
	var locale := String(String(LanguageService.interface_locale).strip_edges().to_lower().replace("-", "_").split("_")[0])
	return locale if locale in ["en", "ru", "pt", "es", "fr", "de"] else "en"


func _localized_song_data(song: Dictionary) -> Dictionary:
	var locale_pack: Dictionary = song_localizations.get(_piano_locale(), {})
	return locale_pack.get(String(song.get("id", "")), {})


func _localized_song_title(song: Dictionary) -> String:
	var localized := _localized_song_data(song)
	return String(localized.get("title", song.get("title", "Song")))


func _localized_song_line(song: Dictionary, event: Dictionary) -> String:
	if _piano_locale() == "en":
		return String(event.get("lyricLine", ""))
	var localized := _localized_song_data(song)
	var lines: Array = localized.get("lines", [])
	var phrase_index := int(event.get("phrase", 0)) - 1
	if phrase_index >= 0 and phrase_index < lines.size():
		return String(lines[phrase_index])
	return ""


func _go_back() -> void:
	_stop_playback()
	SFX.transition_to_scene("res://education/playtown/scenes/screens/game_select_playground.tscn")


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(5)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.22, 0.10, 0.04, 0.28)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


func _style_selector(selector: OptionButton) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#f6e9ff") if state != "pressed" else Color("#ead4fb")
		style.border_color = Color("#9b65cf")
		style.set_border_width_all(3)
		style.set_corner_radius_all(16)
		style.content_margin_left = 14.0
		style.content_margin_right = 34.0
		selector.add_theme_stylebox_override(state, style)
	selector.add_theme_color_override("font_color", Color("#56366e"))
	selector.add_theme_color_override("font_hover_color", Color("#56366e"))
	selector.add_theme_color_override("font_pressed_color", Color("#56366e"))
	_style_song_popup(selector.get_popup())


func _style_song_popup(popup: PopupMenu) -> void:
	popup.transparent_bg = true
	popup.add_theme_color_override("font_color", Color("#56366e"))
	popup.add_theme_color_override("font_hover_color", Color("#56366e"))
	popup.add_theme_color_override("font_pressed_color", Color("#56366e"))
	popup.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.55))
	popup.add_theme_constant_override("outline_size", 1)
	popup.add_theme_constant_override("item_start_padding", 18)
	popup.add_theme_constant_override("item_end_padding", 18)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#fff8e7")
	panel.border_color = Color("#9b65cf")
	panel.set_border_width_all(4)
	panel.set_corner_radius_all(22)
	panel.content_margin_left = 10.0
	panel.content_margin_right = 10.0
	panel.content_margin_top = 10.0
	panel.content_margin_bottom = 10.0
	panel.shadow_color = Color(0.18, 0.08, 0.24, 0.28)
	panel.shadow_size = 12
	panel.shadow_offset = Vector2(0.0, 7.0)
	popup.add_theme_stylebox_override("panel", panel)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#ffd76d")
	hover.border_color = Color("#f0a52d")
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(14)
	hover.content_margin_left = 8.0
	hover.content_margin_right = 8.0
	popup.add_theme_stylebox_override("hover", hover)

	var separator := StyleBoxLine.new()
	separator.color = Color("#ddc5ed")
	separator.thickness = 2
	popup.add_theme_stylebox_override("separator", separator)


func _style_action_button(button: Button, color: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color if state != "pressed" else color.darkened(0.16)
		style.border_color = color.darkened(0.27)
		style.set_border_width_all(3)
		style.set_corner_radius_all(18)
		style.shadow_color = Color(0.20, 0.10, 0.04, 0.22)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0.0, 4.0)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)


func _safe_area_insets(viewport_size: Vector2) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0:
		return Vector4.ZERO
	var scale := viewport_size / window_size
	return Vector4(
		maxf(0.0, safe_rect.position.x * scale.x),
		maxf(0.0, safe_rect.position.y * scale.y),
		maxf(0.0, (window_size.x - safe_rect.end.x) * scale.x),
		maxf(0.0, (window_size.y - safe_rect.end.y) * scale.y)
	)
