extends "res://education/playtown/src/features/counting/mika_count_trace_native_v1.gd"
## MIKA Write a Number v2.0 — 1..20, same female-preferred TTS as Pick a Number.
## Intentionally inherits the native HUD, adaptive board and precise touch/mouse
## tracing transform from v1. No changes to the original Safe City Kids script.

const MIKA_TRACE_MAX_20: int = 20
const MIKA_NUMBER_SPEECH: Script = preload("res://education/playtown/src/features/counting/mika_count_number_tts_v1_3.gd")

var _mika_trace_speech: RefCounted = MIKA_NUMBER_SPEECH.new()

func _ready() -> void:
	# v1 disables legacy PlayTown coin payouts and awards exactly one fuel
	# crystal for each newly completed numeral in the current session.
	super._ready()
	# The original game limits the saved cursor to 1..10. Restore a completed
	# 10th number as 11 and retain progress 11..20 across visits.
	var target: int = clampi(GameState.numbers_traced, 0, MIKA_TRACE_MAX_20 - 1)
	if target != number_index:
		number_index = target
		_load_round()
	set_meta("mika_write_number_version", "v2.0-trace-1-to-20-tts")
	print("[MIKA WRITE NUMBER v2.0] ACTIVE — 1..20, original MP3 or native TTS; scene: ", scene_file_path)

func _build_products(n: int) -> void:
	if n <= 10:
		# Exact original images and spacing for 1..10.
		super._build_products(n)
		return
	if n > MIKA_TRACE_MAX_20:
		return
	var tex: Texture2D = current_product.get("texture") as Texture2D
	if tex == null:
		push_warning("MIKA Write a Number: missing product texture")
		return
	# The old GRID_COLS has entries only for 1..10; place 11..20 on a
	# responsive stage as four or five columns of original art assets.
	var columns: int = 4 if n <= 16 else 5
	var rows: int = ceili(float(n) / float(columns))
	var cell: float = minf(PRODUCTS_AREA.x / float(columns), PRODUCTS_AREA.y / float(rows))
	var icon: float = cell * 0.90
	var placed: int = 0
	for row in range(rows):
		var in_row: int = mini(columns, n - placed)
		var row_w: float = float(in_row) * cell
		for col in range(in_row):
			var picture := TextureButton.new()
			picture.texture_normal = tex
			picture.ignore_texture_size = true
			picture.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			picture.focus_mode = Control.FOCUS_NONE
			picture.position = PRODUCTS_CENTER + Vector2(
				-row_w * 0.5 + float(col) * cell + (cell - icon) * 0.5,
				-float(rows) * cell * 0.5 + float(row) * cell + (cell - icon) * 0.5
			)
			picture.size = Vector2.ONE * icon
			picture.pressed.connect(_play_number_voice.bind(n))
			product_root.add_child(picture)
			placed += 1
	assert(placed == n)

func _mika_trace_add_sheets() -> void:
	# Give two-digit figures enough white drawing space: their guide can be
	# 330 original units wide. This changes neither the coordinates nor traces.
	super._mika_trace_add_sheets()
	if _mika_trace_digit_sheet != null:
		_mika_trace_digit_sheet.position = Vector2(942.0, 264.0)
		_mika_trace_digit_sheet.size = Vector2(366.0, 347.0)

func _advance_round() -> void:
	number_index = (number_index + 1) % MIKA_TRACE_MAX_20
	_load_round()

func _on_prev_pressed() -> void:
	number_index = wrapi(number_index - 1, 0, MIKA_TRACE_MAX_20)
	_load_round()

func _on_next_pressed() -> void:
	number_index = wrapi(number_index + 1, 0, MIKA_TRACE_MAX_20)
	_load_round()

func _play_number_voice(n: int) -> void:
	# The original 1..10 audio files remain the authoritative pronunciation.
	if n <= 10:
		_mika_trace_speech.call("stop")
		super._play_number_voice(n)
		return
	if n > MIKA_TRACE_MAX_20:
		return
	var locale: String = str(LanguageService.learning_locale)
	if locale == "pt_BR":
		locale = "pt"
	if locale not in ["ru", "en", "pt", "es", "fr", "de"]:
		return
	# LanguageService.get_number_voice clamps to 10. Never call it for
	# 11..20 or it would incorrectly pronounce every one as 'ten'.
	var clip_path: String = "res://education/playtown/audio/voice/%s/numbers/number_%02d.mp3" % [locale, n]
	if ResourceLoader.exists(clip_path):
		var clip: AudioStream = load(clip_path) as AudioStream
		if clip != null and is_instance_valid(voice_player):
			_mika_trace_speech.call("stop")
			voice_player.stop()
			voice_player.stream = clip
			voice_player.play()
			return
	if is_instance_valid(voice_player):
		voice_player.stop()
	# Shared hidden texts and female-preferred OS voices used in Pick a Number.
	_mika_trace_speech.call("speak_number", n, locale)

func _exit_tree() -> void:
	_mika_trace_speech.call("stop")
	super._exit_tree()
