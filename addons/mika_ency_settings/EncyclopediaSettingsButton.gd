extends Node
## MIKA Encyclopedia Settings v4.0
## Unified vertical action block; original native actions are forwarded untouched.
## This replaces the older v3 addon rather than stacking a second settings adapter.

const BUTTON_NAME: String = "MikaEncyclopediaSettingsButton"
const ENCYCLOPEDIA_SCENE: String = "res://mika_encyclopedia_v18/scenes/glossary.tscn"
const TEXTS: Dictionary = {
	"ru": "Энциклопедия", "en": "Encyclopedia", "pt": "Enciclopédia",
	"es": "Enciclopedia", "fr": "Encyclopédie", "de": "Enzyklopädie"
}
const POLICY_HINTS: Array[String] = [
	"privacy", "policy", "политик", "конфиденц", "приватност", "privacidade",
	"politica", "política", "privacidad", "confidentialité", "politique", "datenschutz", "legal"
]
const PURCHASE_HINTS: Array[String] = [
	"purchase", "purchases", "shop", "buy", "store", "покуп", "магазин", "закуп",
	"compras", "comprar", "loja", "tienda", "achat", "achats", "einkauf", "kaufen"
]
const LANGUAGE_KEYS: Array[String] = [
	"current_language", "selected_language", "language_code", "current_locale", "selected_locale",
	"_selected_language", "_current_language", "_locale", "_language", "locale", "language", "lang"
]

var _elapsed: float = 0.0
var _action_block: VBoxContainer = null
var _ency_button: BaseButton = null
var _privacy_proxy: BaseButton = null
var _purchase_proxy: BaseButton = null
var _source_policy: BaseButton = null
var _source_purchase: BaseButton = null
var _policy_color: Color = Color.WHITE
var _purchase_color: Color = Color.WHITE
var _policy_filter: int = Control.MOUSE_FILTER_STOP
var _purchase_filter: int = Control.MOUSE_FILTER_STOP
var _ency_layer: CanvasLayer = null
var _reported: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	call_deferred("_refresh")

func _exit_tree() -> void:
	_restore_sources()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.45:
		_elapsed = 0.0
		_refresh()

func _refresh() -> void:
	if not is_inside_tree() or is_instance_valid(_ency_layer):
		return
	var all_buttons: Array[BaseButton] = []
	_collect_buttons(get_tree().root, all_buttons, 0)
	var policy: BaseButton = null
	var purchase: BaseButton = null
	if is_instance_valid(_source_policy) and is_instance_valid(_source_purchase):
		if _source_policy.is_visible_in_tree() and _source_purchase.is_visible_in_tree():
			policy = _source_policy
			purchase = _source_purchase
	if policy == null or purchase == null:
		var best_score: int = -99999
		for a in all_buttons:
			if _has_hint(_describe(a).to_lower(), POLICY_HINTS):
				for b in all_buttons:
					if b == a or not _has_hint(_describe(b).to_lower(), PURCHASE_HINTS):
						continue
					var common: Node = _common_ancestor(a, b)
					if common == null:
						continue
					var distance: int = _distance(a, common) + _distance(b, common)
					if distance > 17:
						continue
					var score: int = _settings_score(a) + _settings_score(b) + 60 - distance * 6
					if a.get_parent() == b.get_parent():
						score += 15
					if score > best_score:
						best_score = score
						policy = a
						purchase = b
	if policy == null or purchase == null:
		_hide_block()
		return
	var host: Control = _find_host(policy, purchase)
	if host == null:
		_hide_block()
		return
	if policy != _source_policy or purchase != _source_purchase or not is_instance_valid(_action_block) or _action_block.get_parent() != host:
		_create_block(policy, purchase, host)
	if not is_instance_valid(_action_block):
		return
	_update_language(policy)
	_mirror_button(policy, _privacy_proxy)
	_mirror_button(purchase, _purchase_proxy)
	# Native UI may refresh the style or opacity on locale changes.
	policy.modulate = Color(policy.modulate.r, policy.modulate.g, policy.modulate.b, 0.0)
	purchase.modulate = Color(purchase.modulate.r, purchase.modulate.g, purchase.modulate.b, 0.0)
	_layout_block(policy, purchase, host, all_buttons)

func _create_block(policy: BaseButton, purchase: BaseButton, host: Control) -> void:
	_restore_sources()
	if is_instance_valid(_action_block):
		_action_block.queue_free()
	_action_block = VBoxContainer.new()
	_action_block.name = "MikaSettingsActionsVertical"
	_action_block.mouse_filter = Control.MOUSE_FILTER_PASS
	_action_block.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(_action_block)
	_ency_button = _duplicate_button(policy, "MikaEncyclopediaSettingsButton")
	_privacy_proxy = _duplicate_button(policy, "MikaPrivacyPolicyProxy")
	_purchase_proxy = _duplicate_button(purchase, "MikaPurchaseProxy")
	if _ency_button == null or _privacy_proxy == null or _purchase_proxy == null:
		_action_block.queue_free()
		_action_block = null
		return
	_action_block.add_child(_ency_button)
	_action_block.add_child(_privacy_proxy)
	_action_block.add_child(_purchase_proxy)
	_ency_button.pressed.connect(_open_encyclopedia)
	# Emit the original signals, so existing Privacy Policy and Purchase actions are preserved.
	_privacy_proxy.pressed.connect(_trigger_policy)
	_purchase_proxy.pressed.connect(_trigger_purchase)
	_source_policy = policy
	_source_purchase = purchase
	_policy_color = policy.modulate
	_purchase_color = purchase.modulate
	_policy_filter = policy.mouse_filter
	_purchase_filter = purchase.mouse_filter
	policy.modulate = Color(_policy_color.r, _policy_color.g, _policy_color.b, 0.0)
	purchase.modulate = Color(_purchase_color.r, _purchase_color.g, _purchase_color.b, 0.0)
	policy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	purchase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _reported:
		print("[MIKA Encyclopedia v4] Encyclopedia / Privacy Policy / Purchase vertical block ready")
		_reported = true

func _duplicate_button(source: BaseButton, name_for_copy: String) -> BaseButton:
	var copy: Node = source.duplicate(0)
	if not (copy is BaseButton):
		return null
	var button: BaseButton = copy as BaseButton
	button.name = name_for_copy
	button.set_meta("mika_ency_v4_proxy", true)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.visible = true
	button.modulate = source.modulate
	button.set_script(null)
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _restore_sources() -> void:
	if is_instance_valid(_source_policy):
		_source_policy.modulate = _policy_color
		_source_policy.mouse_filter = _policy_filter
	if is_instance_valid(_source_purchase):
		_source_purchase.modulate = _purchase_color
		_source_purchase.mouse_filter = _purchase_filter
	_source_policy = null
	_source_purchase = null

func _trigger_policy() -> void:
	if is_instance_valid(_source_policy):
		_source_policy.pressed.emit()

func _trigger_purchase() -> void:
	if is_instance_valid(_source_purchase):
		_source_purchase.pressed.emit()

func _hide_block() -> void:
	if is_instance_valid(_action_block):
		_action_block.visible = false

func _layout_block(policy: BaseButton, purchase: BaseButton, host: Control, buttons: Array[BaseButton]) -> void:
	var host_rect: Rect2 = host.get_global_rect()
	var a: Rect2 = policy.get_global_rect()
	var b: Rect2 = purchase.get_global_rect()
	if a.size.x < 20.0 or a.size.y < 18.0 or b.size.x < 20.0 or b.size.y < 18.0:
		_hide_block()
		return
	var footprint: Rect2 = a.merge(b)
	var gap: float = clampf(minf(a.size.y, b.size.y) * 0.20, 7.0, 13.0)
	var height: float = maxf(a.size.y, b.size.y)
	var width: float = maxf(a.size.x, b.size.x)
	var inset: float = 9.0
	width = minf(width, host_rect.size.x - 2.0 * inset)
	height = minf(height, (host_rect.size.y - 2.0 * inset - gap * 2.0) / 3.0)
	if width < 100.0 or height < 24.0:
		_hide_block()
		return
	var block_h: float = height * 3.0 + gap * 2.0
	var center_x: float = footprint.get_center().x
	var desired_left: float = center_x - width * 0.5
	var left: float = clampf(desired_left, host_rect.position.x + inset, host_rect.end.x - width - inset)
	var positions: Array[Vector2] = [
		Vector2(left, footprint.end.y - block_h),
		Vector2(left, footprint.position.y - height - gap),
		Vector2(left, footprint.end.y + gap),
		Vector2(host_rect.get_center().x - width * 0.5, footprint.end.y - block_h),
		Vector2(host_rect.get_center().x - width * 0.5, host_rect.end.y - block_h - inset)
	]
	var chosen: Rect2 = Rect2(Vector2(left, host_rect.position.y + inset), Vector2(width, block_h))
	var best_penalty: float = INF
	for origin in positions:
		var bounded: Vector2 = Vector2(
			clampf(origin.x, host_rect.position.x + inset, host_rect.end.x - width - inset),
			clampf(origin.y, host_rect.position.y + inset, host_rect.end.y - block_h - inset)
		)
		var trial: Rect2 = Rect2(bounded, Vector2(width, block_h))
		var penalty: float = trial.position.distance_to(origin) * 0.2
		for other in buttons:
			if other == policy or other == purchase or other == _ency_button or other == _privacy_proxy or other == _purchase_proxy:
				continue
			var blocking: Rect2 = other.get_global_rect().grow(3.0)
			if trial.intersects(blocking):
				var overlap: Rect2 = trial.intersection(blocking)
				penalty += overlap.size.x * overlap.size.y
		if penalty < best_penalty:
			best_penalty = penalty
			chosen = trial
	# One container controls ALL dimensions, order and gaps. No per-button offsets.
	var inverse_transform: Transform2D = host.get_global_transform().affine_inverse()
	var local_start: Vector2 = inverse_transform * chosen.position
	var local_end: Vector2 = inverse_transform * chosen.end
	var local_width: float = absf(local_end.x - local_start.x)
	var local_height: float = absf(local_end.y - local_start.y)
	var y_scale: float = local_height / block_h
	_action_block.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_action_block.position = Vector2(minf(local_start.x, local_end.x), minf(local_start.y, local_end.y))
	_action_block.size = Vector2(local_width, local_height)
	_action_block.add_theme_constant_override("separation", int(round(gap * y_scale)))
	for item in [_ency_button, _privacy_proxy, _purchase_proxy]:
		item.custom_minimum_size = Vector2(local_width, height * y_scale)
		item.size_flags_vertical = Control.SIZE_EXPAND_FILL
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_block.visible = true

func _open_encyclopedia() -> void:
	if is_instance_valid(_ency_layer):
		return
	if not ResourceLoader.exists(ENCYCLOPEDIA_SCENE):
		push_error("MIKA Encyclopedia: scene not found: " + ENCYCLOPEDIA_SCENE)
		return
	var packed: PackedScene = load(ENCYCLOPEDIA_SCENE) as PackedScene
	if packed == null:
		push_error("MIKA Encyclopedia: cannot load PackedScene: " + ENCYCLOPEDIA_SCENE)
		return
	var scene: Node = packed.instantiate()
	if scene == null:
		return
	_ency_layer = CanvasLayer.new()
	_ency_layer.name = "MikaEncyclopediaSceneOverlay"
	_ency_layer.layer = 100
	_ency_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_ency_layer)
	var surface: Control = Control.new()
	surface.name = "FullScreenEncyclopedia"
	surface.mouse_filter = Control.MOUSE_FILTER_STOP
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ency_layer.add_child(surface)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.006, 0.013, 0.028, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	surface.add_child(bg)
	surface.add_child(scene)
	# MIKA Encyclopedia v5.2: locale and native back navigation
	if scene.has_method("set_locale"):
		var game_lang: String = _find_locale(_source_policy) if is_instance_valid(_source_policy) else TranslationServer.get_locale()
		scene.call("set_locale", game_lang)
	if scene.has_signal("closed"):
		scene.connect("closed", Callable(self, "_close_encyclopedia"))
	# MIKA Encyclopedia v5.0: locale and native back navigation
	if scene.has_method("set_locale"):
		var game_lang: String = _find_locale(_source_policy) if is_instance_valid(_source_policy) else TranslationServer.get_locale()
		scene.call("set_locale", game_lang)
	if scene.has_signal("closed"):
		scene.connect("closed", Callable(self, "_close_encyclopedia"))
	if scene is Control:
		var page: Control = scene as Control
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page.mouse_filter = Control.MOUSE_FILTER_STOP
	# New scene owns all Back navigation.

func _close_encyclopedia() -> void:
	if is_instance_valid(_ency_layer):
		_ency_layer.queue_free()
	_ency_layer = null

func _collect_buttons(node: Node, output: Array[BaseButton], depth: int) -> void:
	if depth > 32:
		return
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return
	if node is BaseButton and not node.get_meta("mika_ency_v4_proxy", false):
		if node.name != BUTTON_NAME and not node.get_meta("mika_ency_settings_v3", false) and not node.get_meta("mika_ency_settings_v31", false):
			output.append(node as BaseButton)
	for child in node.get_children():
		_collect_buttons(child, output, depth + 1)

func _describe(button: BaseButton) -> String:
	var parts: Array[String] = [button.name, button.tooltip_text]
	if button is Button:
		parts.append((button as Button).text)
	elif button is LinkButton:
		parts.append((button as LinkButton).text)
	_collect_labels(button, parts, 0)
	return " ".join(parts)

func _collect_labels(node: Node, parts: Array[String], depth: int) -> void:
	if depth >= 3:
		return
	for child in node.get_children():
		if child is Label:
			parts.append((child as Label).text)
		elif child is RichTextLabel:
			parts.append((child as RichTextLabel).text)
		else:
			_collect_labels(child, parts, depth + 1)

func _has_hint(value: String, hints: Array[String]) -> bool:
	for hint in hints:
		if value.contains(hint):
			return true
	return false

func _settings_score(node: Node) -> int:
	var score: int = 0
	var current: Node = node
	for i in range(12):
		if current == null:
			break
		var name_lower: String = current.name.to_lower()
		if name_lower.contains("setting") or name_lower.contains("настрой"):
			score += 9
		if name_lower.contains("language") or name_lower.contains("locale"):
			score += 3
		var script: Script = current.get_script() as Script
		if script != null and script.resource_path.to_lower().contains("settingslanguagepopup"):
			score += 20
		current = current.get_parent()
	return score

func _common_ancestor(a: Node, b: Node) -> Node:
	var current: Node = a
	for i in range(22):
		if current == null:
			break
		if _distance(b, current) <= 20:
			return current
		current = current.get_parent()
	return null

func _distance(node: Node, ancestor: Node) -> int:
	var cursor: Node = node
	for i in range(32):
		if cursor == null:
			break
		if cursor == ancestor:
			return i
		cursor = cursor.get_parent()
	return 999

func _find_host(policy: BaseButton, purchase: BaseButton) -> Control:
	var current: Node = _common_ancestor(policy, purchase)
	var best: Control = null
	while current != null:
		if current is Control and not (current is Container):
			var parent_control: Control = current as Control
			var rect: Rect2 = parent_control.get_global_rect()
			if rect.size.x >= 140.0 and rect.size.y >= 165.0:
				if rect.grow(5.0).encloses(policy.get_global_rect()) and rect.grow(5.0).encloses(purchase.get_global_rect()):
					best = parent_control
					break
		if current is Window or current is CanvasLayer:
			break
		current = current.get_parent()
	return best

func _update_language(policy: BaseButton) -> void:
	var language: String = _find_locale(policy)
	var title: String = str(TEXTS.get(language, TEXTS["en"]))
	_set_title(_ency_button, title)

func _mirror_button(source: BaseButton, target: BaseButton) -> void:
	if not is_instance_valid(target):
		return
	if source is Button and target is Button:
		(target as Button).text = (source as Button).text
	elif source is LinkButton and target is LinkButton:
		(target as LinkButton).text = (source as LinkButton).text
	target.tooltip_text = source.tooltip_text
	_mirror_child_labels(source, target, 0)

func _mirror_child_labels(source: Node, target: Node, depth: int) -> void:
	if depth >= 5:
		return
	var source_children: Array[Node] = source.get_children()
	var target_children: Array[Node] = target.get_children()
	for i in range(mini(source_children.size(), target_children.size())):
		var a: Node = source_children[i]
		var b: Node = target_children[i]
		if a is Label and b is Label:
			(b as Label).text = (a as Label).text
		elif a is RichTextLabel and b is RichTextLabel:
			(b as RichTextLabel).text = (a as RichTextLabel).text
		else:
			_mirror_child_labels(a, b, depth + 1)

func _find_locale(button: BaseButton) -> String:
	var node: Node = button
	for i in range(12):
		if node == null:
			break
		for key in LANGUAGE_KEYS:
			for property in node.get_property_list():
				if str(property.get("name", "")) == key:
					var candidate: String = _normalize_locale(str(node.get(key)))
					if not candidate.is_empty():
						return candidate
		node = node.get_parent()
	var fallback: String = _normalize_locale(TranslationServer.get_locale())
	return fallback if not fallback.is_empty() else "en"

func _normalize_locale(value: String) -> String:
	var s: String = value.strip_edges().to_lower().replace("_", "-")
	if s.begins_with("ru") or s == "russian" or s == "русский":
		return "ru"
	if s.begins_with("en") or s == "english":
		return "en"
	if s.begins_with("pt") or s.contains("portugu"):
		return "pt"
	if s.begins_with("es") or s.contains("españ") or s == "spanish":
		return "es"
	if s.begins_with("fr") or s == "french" or s == "français":
		return "fr"
	if s.begins_with("de") or s == "german" or s == "deutsch":
		return "de"
	return ""

func _set_title(node: Node, value: String) -> void:
	if node is Button:
		(node as Button).text = value
		(node as Button).tooltip_text = value
	elif node is LinkButton:
		(node as LinkButton).text = value
		(node as LinkButton).tooltip_text = value
	elif node is Control:
		(node as Control).tooltip_text = value
	_set_child_label(node, value, 0)

func _set_child_label(node: Node, value: String, depth: int) -> bool:
	if depth >= 5:
		return false
	for child in node.get_children():
		if child is Label:
			(child as Label).text = value
			return true
		if child is RichTextLabel:
			(child as RichTextLabel).text = value
			return true
		if _set_child_label(child, value, depth + 1):
			return true
	return false
