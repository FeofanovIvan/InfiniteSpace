extends "res://education/playtown/src/features/tracing/mika_word_trace_native_v1.gd"
## Trace Words UI recovery and the same header as Trace Letters.
## Drawing is raised above the space background and both glass panels.
## The game displays earnings for THIS session only (starts at zero).
## Rewards are credited to ship fuel ONCE when the game is closed.

const SHARED_TRACE_TOOLBAR := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const NEON_WORD_GUIDES := preload("res://education/playtown/src/features/tracing/mika_neon_trace_hints_v12.gd")

@export var crystals_per_unique_word: int = 1

var _session_word_keys_v2: Dictionary = {}
var _rewards_settled_v2: bool = false
var _original_sim_back_v2: BaseButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _session_earned = 0
    super._ready()
    SHARED_TRACE_TOOLBAR.apply_title_style(_title_panel)
    _brighten_game_panels()
    # The original Simulator Back button lives outside this SubViewport and
    # should be hidden while this game uses the same native icon inside.
    var host: Node = _find_simulator_host()
    if host != null:
        _original_sim_back_v2 = host.get_node_or_null("PlayTownOriginalGameRunner/ReturnToEducationalCards") as BaseButton
        if is_instance_valid(_original_sim_back_v2):
            _original_sim_back_v2.hide()
    if _round_panel != null:
        _round_panel.hide() # Do not duplicate the new header counter.
    # The same glowing checkpoints used in Trace Letters; original audio,
    # word selection and trace validity remain untouched.
    var old_hints: Node2D = hint_drawer
    if old_hints != null and is_instance_valid(old_hints):
        letter_root.remove_child(old_hints)
        old_hints.queue_free()
    hint_drawer = NEON_WORD_GUIDES.new()
    hint_drawer.game = self
    hint_drawer.name = "NeonWordTraceHints"
    letter_root.add_child(hint_drawer)
    _update_dot_limit()
    _update_score()
    _layout_hud_controls()

func _bright_style(border: Color, transparent_fill: Color, radius: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.anti_aliasing = true
    box.bg_color = transparent_fill
    box.border_color = border
    box.set_border_width_all(3)
    box.set_corner_radius_all(radius)
    box.shadow_color = Color(0.20, 0.66, 1.0, 0.36)
    box.shadow_size = 12
    box.shadow_offset = Vector2.ZERO
    return box

func _brighten_game_panels() -> void:
    # Brighter, luminous pale-blue glass as in the approved letter-trace tile.
    # z=0 is behind the actual word lines, but above background with z=-25.
    if main_card != null:
        main_card.z_index = 0
        main_card.add_theme_stylebox_override("panel", _bright_style(Color("#82ebff"), Color(0.09, 0.24, 0.47, 0.82), 34))
    if category_card != null:
        category_card.z_index = 0
        category_card.add_theme_stylebox_override("panel", _bright_style(Color("#71dcff"), Color(0.09, 0.21, 0.44, 0.84), 30))
    if _sky != null:
        _sky.z_index = -25
    if letter_root != null:
        letter_root.z_index = 8

func _load_word(play_voice: bool = true) -> void:
    super._load_word(play_voice)
    # Word line z indexes are -2/-1/1 inside their own Node2D. Raise their
    # PARENT in the overall scene, otherwise pale backgrounds hide the traces.
    if letter_root != null:
        letter_root.z_index = 8
    for outline in outline_lines:
        if outline != null and is_instance_valid(outline):
            (outline as Line2D).default_color = Color("#67dfff")
            (outline as Line2D).antialiased = true
            (outline as Line2D).round_precision = 24
    for body in body_lines:
        if body != null and is_instance_valid(body):
            (body as Line2D).default_color = Color("#e9fbff")
            (body as Line2D).antialiased = true
            (body as Line2D).round_precision = 24
    for fill in fill_lines:
        if fill != null and is_instance_valid(fill):
            (fill as Line2D).default_color = Color("#78e5ff")
            (fill as Line2D).antialiased = true
            (fill as Line2D).round_precision = 24
    if hint_drawer != null:
        hint_drawer.queue_redraw()

func _set_score_text(balance: int) -> void:
    # Leave historical PlayTown coin balance out of this game's UI.
    if score_label != null:
        score_label.text = str(balance)
    _update_score()

func _update_score() -> void:
    if _native_hub != null:
        _native_hub.set("crystal_count", _session_earned)
    if _round_label != null:
        var loc: String = _current_locale()
        _round_label.text = "%s: +%d" % [WORD_TEXTS[loc][2], _session_earned]

func _finish_word() -> void:
    # Preserve sounds and progress, but DON'T add PlayTown coins: the host
    # automatically converts every coin into ship fuel, causing double credit.
    letter_done = true
    tracing = false
    SFX.play_praise(get_viewport_rect().size * 0.5, 1.0)
    _play_sfx(coin_sound)
    _play_word_voice()
    if word_index >= GameState.words_traced:
        GameState.set_words_traced(word_index + 1)
    var key: String = str(LanguageService.current_locale) + ":" + str(word_objects[word_index].get("key", _current_word()))
    if not _session_word_keys_v2.has(key):
        _session_word_keys_v2[key] = true
        _session_earned += maxi(0, crystals_per_unique_word)
    _update_score()
    if celebrate_tween != null:
        celebrate_tween.kill()
    celebrate_tween = create_tween()
    celebrate_tween.tween_interval(1.0)
    celebrate_tween.tween_property(letter_root, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    celebrate_tween.tween_property(letter_root, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    celebrate_tween.tween_callback(_advance_word)

func _on_exit_pressed() -> void:
    _settle_word_rewards_v2()
    SFX.transition_to_scene(exit_scene_path)

func _settle_word_rewards_v2() -> void:
    if _rewards_settled_v2:
        return
    _rewards_settled_v2 = true
    if _session_earned <= 0:
        return
    var host: Node = _find_simulator_host()
    if host != null and host.has_signal("crystals_earned"):
        # Main._on_fuel_collected enforces FUEL_CAPACITY, including upgrades.
        host.emit_signal("crystals_earned", _session_earned)
        _sync_real_fuel_to_simulator_v2(host)
    else:
        # Standalone PlayTown test outside InfiniteSpace.
        GameState.add_coins(_session_earned)

func _sync_real_fuel_to_simulator_v2(host: Node) -> void:
    var walk: Node = host.get_parent()
    for i in range(8):
        if walk == null:
            break
        var actual: Variant = walk.get("_fuel_units")
        if actual is int or actual is float:
            if host.has_method("set_stats"):
                host.call("set_stats", maxi(0, floori(float(actual) + 0.001)), 0, 0.0)
            return
        walk = walk.get_parent()

func _exit_tree() -> void:
    # Covers host closing the SubViewport directly. Idempotent by guard above.
    _settle_word_rewards_v2()
    if is_instance_valid(_original_sim_back_v2):
        _original_sim_back_v2.show()

func _layout_hud_controls() -> void:
    super._layout_hud_controls()
    if _native_back_button == null or _native_hub == null or _title_panel == null:
        return
    var view: Vector2 = get_viewport_rect().size
    if view.x < 100.0 or view.y < 100.0:
        return
    var insets: Vector4 = _safe_area_insets(view)
    var safe := Rect2(Vector2(insets.x, insets.y), view - Vector2(insets.x + insets.z, insets.y + insets.w))
    SHARED_TRACE_TOOLBAR.relayout(view, safe, _native_back_button, _native_hub, _title_panel, _title_label, _subtitle_label)
