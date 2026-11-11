extends "res://learning/src/features/counting/mika_count_pick_native_v1_1.gd"
## MIKA Pick Up a Number v1.2: count and answer from 1 to 20.
## Keeps v1.1 toolbar, scaled layout, rewards, art and original game rules.
## Voice clips 11..20 are optional; we must NEVER fall back to voice '10'.

const MIKA_MAX_PICK_NUMBER: int = 20

func _ready() -> void:
	# Parent count_pick_game._load_round() uses max_number to generate the
	# displayed product count AND the three possible answers.
	max_number = MIKA_MAX_PICK_NUMBER
	super._ready()
	set_meta("mika_pick_number_version", "v1.2-count-1-to-20")
	print("[MIKA PICK NUMBER v1.2] ACTIVE — numbers 1..20; script: ", (get_script() as Script).resource_path)

func _build_products(n: int) -> void:
	if n <= 10:
		# Preserve the exact original arrangement for the existing numbers.
		super._build_products(n)
		return
	# The original GRID_COLS only covers 1..10. Pack 11..20 in rows with
	# 4 or 5 columns while respecting the same bounds (PRODUCTS_AREA).
	var tex: Texture2D = current_product.get("texture") as Texture2D
	if tex == null:
		push_warning("Pick Number v1.2: product image is missing")
		return
	var columns: int = 4 if n <= 16 else 5
	var rows: int = ceili(float(n) / float(columns))
	var cell: float = minf(PRODUCTS_AREA.x / float(columns), PRODUCTS_AREA.y / float(rows))
	var icon: float = cell * 0.90
	var placed: int = 0
	for r in range(rows):
		var count_in_row: int = mini(columns, n - placed)
		var row_width: float = float(count_in_row) * cell
		for c in range(count_in_row):
			var rect := TextureButton.new()
			rect.texture_normal = tex
			rect.ignore_texture_size = true
			rect.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			rect.focus_mode = Control.FOCUS_NONE
			rect.position = PRODUCTS_CENTER + Vector2(
				-row_width * 0.5 + float(c) * cell + (cell - icon) * 0.5,
				-float(rows) * cell * 0.5 + float(r) * cell + (cell - icon) * 0.5
			)
			rect.size = Vector2.ONE * icon
			product_root.add_child(rect)
			placed += 1
	assert(placed == n)

func _play_number_voice(n: int) -> void:
	if n <= 10:
		super._play_number_voice(n)
		return
	if n > MIKA_MAX_PICK_NUMBER:
		return
	# Existing LanguageService.get_number_voice() clamps n to 10.
	# For 11..20 use an EXACT file if present, otherwise stay silent.
	# The recording checklist in learning/audio/ specifies the paths.
	var locale: String = str(LanguageService.learning_locale)
	if locale == "pt_BR":
		locale = "pt"
	if locale not in ["ru", "en", "pt", "es", "fr", "de"]:
		return
	var path: String = "res://learning/audio/voice/%s/numbers/number_%02d.mp3" % [locale, n]
	if not ResourceLoader.exists(path):
		return
	var clip: AudioStream = load(path) as AudioStream
	if clip != null and voice_player != null:
		voice_player.stop()
		voice_player.stream = clip
		voice_player.play()
