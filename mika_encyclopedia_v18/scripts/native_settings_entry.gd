extends Node
## Direct hook owned by the actual SettingsLanguagePopup.gd instance.
## Inserts a child Button in Settings, never a floating button in the main viewport.
const BOOK_LABELS: Dictionary = {
	"ru": "Энциклопедия", "en": "Encyclopedia", "fr": "Encyclopédie",
	"de": "Enzyklopädie", "es": "Enciclopedia", "pt_BR": "Enciclopédia"
}
const MODE_LABELS: Array[String] = ["game mode", "game_mode", "gamemode", "play mode", "play_mode", "режим игры", "modo de juego", "modo de jogo", "mode de jeu", "spielmodus"]
const PURCHASE_LABELS: Array[String] = ["purchase", "покуп", "compras", "achat", "kauf", "buy"]
const PALACE_LABELS: Array[String] = ["palace", "дворец", "palais", "palácio", "palacio", "palast"]
var _host: Node
var _button: Button
var _attempts: int = 0

func _ready() -> void:
	return # MIKA Encyclopedia v3.2: disable obsolete native_settings_entry
	name = "MikaNativeEncyclopediaEntryHook"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_host = get_parent()
	set_process(true)
	var locale: Node = get_node_or_null("/root/MobileLocale")
	if locale != null and locale.has_signal("language_changed"):
		locale.connect("language_changed", _refresh_label)
	call_deferred("_try_insert")

func _process(_delta: float) -> void:
	return # MIKA Encyclopedia v3.2: disable obsolete native_settings_entry
	if is_instance_valid(_button):
		set_process(false)
		return
	if not _settings_visible():
		return
	_attempts += 1
	if _attempts % 8 == 0:
		_try_insert()
	if _attempts == 64 and _insert_in_native_settings_list():
		push_warning("MIKA Encyclopedia: Game Mode anchor not found; entry added to native Settings list. Verify position.")
		return
	if _attempts == 240:
		push_error("MIKA Encyclopedia: Settings UI has no suitable container. Share scripts/SettingsLanguagePopup.gd for exact placement.")

func _refresh_label(_code: String = "") -> void:
	if not is_instance_valid(_button):
		return
	var mobile: Node = get_node_or_null("/root/MobileLocale")
	var code: String = "ru"
	if mobile != null:
		code = str(mobile.get("language"))
	_button.text = str(BOOK_LABELS.get(code, BOOK_LABELS["ru"]))
	_button.tooltip_text = _button.text

func _signature(target: Control) -> String:
	var result: String = str(target.name).to_lower() + " " + str(target.tooltip_text).to_lower()
	if target is Button:
		result += " " + (target as Button).text.to_lower()
	elif target is Label:
		result += " " + (target as Label).text.to_lower()
	elif target is OptionButton:
		result += " " + (target as OptionButton).text.to_lower()
	return result

func _contains_any(value: String, terms: Array[String]) -> bool:
	for word: String in terms:
		if value.contains(word):
			return true
	return false

func _gather(scope: Node, out: Array[Control], depth: int = 0) -> void:
	if depth > 12 or out.size() > 2000:
		return
	if scope is Control:
		out.append(scope as Control)
	for child: Node in scope.get_children():
		if child == self:
			continue
		_gather(child, out, depth + 1)

func _style_like(target: Button, source: Control) -> void:
	if source is Button:
		var original: Button = source as Button
		target.theme = original.theme
		target.theme_type_variation = original.theme_type_variation
		target.custom_minimum_size = original.custom_minimum_size
		target.size_flags_horizontal = original.size_flags_horizontal
		for key: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			if original.has_theme_stylebox_override(key):
				target.add_theme_stylebox_override(key, original.get_theme_stylebox(key).duplicate())
		for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			if original.has_theme_color_override(key):
				target.add_theme_color_override(key, original.get_theme_color(key))
		for key: String in ["font_size"]:
			if original.has_theme_font_size_override(key):
				target.add_theme_font_size_override(key, original.get_theme_font_size(key))
	else:
		target.custom_minimum_size.y = maxf(48.0, source.custom_minimum_size.y)
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target.add_theme_font_size_override("font_size", 19)
		var normal: StyleBoxFlat = StyleBoxFlat.new()
		normal.bg_color = Color("#0d2844")
		normal.border_color = Color("#53d9f0")
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(12)
		target.add_theme_stylebox_override("normal", normal)
		var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#174b70")
		target.add_theme_stylebox_override("hover", hover)

func _try_insert() -> void:
	if is_instance_valid(_button) or _host == null or not is_inside_tree():
		return
	# Check the native Settings popup, then its direct owner, not the entire scene tree.
	var scope: Node = _host
	for _depth: int in range(4):
		var found: Array[Control] = []
		_gather(scope, found)
		var mode: Control = null
		var purchase: Control = null
		var palace: Control = null
		for control: Control in found:
			if control == _host and _depth > 0:
				continue
			var sig: String = _signature(control)
			if mode == null and _contains_any(sig, MODE_LABELS):
				mode = control
			if purchase == null and _contains_any(sig, PURCHASE_LABELS):
				purchase = control
			if palace == null and _contains_any(sig, PALACE_LABELS):
				palace = control
		if _insert_at(mode, purchase, palace, found):
			return
		if scope.get_parent() == null:
			break
		scope = scope.get_parent()

func _insert_at(mode: Control, purchase: Control, palace: Control, controls: Array[Control]) -> bool:
	var anchor: Control = mode
	var target_container: Container = null
	# If the label is nested inside a row, insert after that row.
	if anchor != null:
		var current: Control = anchor
		var first_container: Container = null
		for _i: int in range(6):
			var parent: Node = current.get_parent()
			if parent is Container:
				if first_container == null:
					first_container = parent as Container
				# The actual vertical list, not the contents of a horizontal row.
				if parent is VBoxContainer:
					target_container = parent as Container
					anchor = current
					break
			if parent is Control:
				current = parent as Control
			else:
				break
		if target_container == null and first_container != null:
			target_container = first_container
			anchor = mode
	# Fallback: put the new entry immediately ahead of Purchase and Palace.
	if target_container == null and purchase != null:
		var purchase_row: Control = purchase
		for _i: int in range(4):
			if purchase_row.get_parent() is Container:
				target_container = purchase_row.get_parent() as Container
				anchor = null
				break
			if purchase_row.get_parent() is Control:
				purchase_row = purchase_row.get_parent() as Control
			else:
				break
		purchase = purchase_row
	if target_container == null:
		return false
	if target_container.has_node("MikaEncyclopediaSettingsButton"):
		_button = target_container.get_node("MikaEncyclopediaSettingsButton") as Button
		set_process(false)
		return true
	_button = Button.new()
	_button.name = "MikaEncyclopediaSettingsButton"
	_button.focus_mode = Control.FOCUS_ALL
	_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_like(_button, mode if mode != null else (purchase if purchase != null else target_container))
	target_container.add_child(_button)
	var index: int = -1
	if anchor != null:
		index = anchor.get_index() + 1
	elif purchase != null and purchase.get_parent() == target_container:
		index = purchase.get_index()
	if index >= 0:
		target_container.move_child(_button, index)
	_refresh_label()
	_button.pressed.connect(_open_book)
	set_process(false)
	return true

func _open_book() -> void:
	var bridge: Node = get_node_or_null("/root/MikaEncyclopediaBridge")
	if bridge == null:
		push_error("MIKA Encyclopedia: MikaEncyclopediaBridge is missing")
		return
	bridge.call("open_encyclopedia")

func _insert_in_native_settings_list() -> bool:
	# Fallback stays inside the Settings popup. It never creates an overlay.
	# Only use an existing vertical stack with several children.
	var found: Array[Control] = []
	_gather(_host, found)
	var selected: VBoxContainer = null
	var best_score: int = -1
	for control: Control in found:
		if not control is VBoxContainer:
			continue
		var vbox: VBoxContainer = control as VBoxContainer
		var items: int = 0
		var buttons: int = 0
		for child: Node in vbox.get_children():
			if child is Control:
				items += 1
			if child is BaseButton:
				buttons += 1
		if items < 3:
			continue
		var score: int = buttons * 10 + mini(items, 8)
		if score > best_score:
			best_score = score
			selected = vbox
	if selected == null:
		return false
	_button = Button.new()
	_button.name = "MikaEncyclopediaSettingsButton"
	_button.focus_mode = Control.FOCUS_ALL
	_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var template: Control = selected
	for child: Node in selected.get_children():
		if child is Button:
			template = child as Control
			break
	_style_like(_button, template)
	selected.add_child(_button)
	selected.move_child(_button, mini(2, selected.get_child_count() - 1))
	_refresh_label()
	_button.pressed.connect(_open_book)
	set_process(false)
	return true

func _settings_visible() -> bool:
	if _host == null:
		return false
	if _host is CanvasItem:
		return (_host as CanvasItem).is_visible_in_tree()
	if _host is Window:
		return (_host as Window).visible
	return true
