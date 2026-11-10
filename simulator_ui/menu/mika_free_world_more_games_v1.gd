extends "res://simulator_ui/menu/earth_playtown_original_v1.gd"
## MIKA Free World additional games toggle v1.
## First ten approved simulator cards remain in their original 5x2 grid.
## Extra cards are accessible only after the player explicitly expands them
## in Free World. Story has no expansion and remains exactly ten cards.
## No changes to card scenes, rewards, localization service or settings UI.

const MODE_SETTINGS_PATH: String = "user://miko_mode.cfg"
const APPROVED_CARD_COUNT: int = 10
const BUTTON_TEXT: Dictionary = {
    "ru": ["↓", "↑", "Показать остальные игры", "Вернуться к 10 основным играм"],
    "en": ["↓", "↑", "Show more games", "Back to the 10 main games"],
    "fr": ["↓", "↑", "Voir les autres jeux", "Retour aux 10 jeux principaux"],
    "de": ["↓", "↑", "Weitere Spiele anzeigen", "Zurück zu den 10 Hauptspielen"],
    "es": ["↓", "↑", "Mostrar más juegos", "Volver a los 10 juegos principales"],
    "pt_BR": ["↓", "↑", "Mostrar mais jogos", "Voltar aos 10 jogos principais"]
}

var _mika_more_button: Button = null
var _mika_extra_expanded: bool = false
var _mika_is_free_world: bool = true
var _mika_more_ready: bool = false
var _mika_scroll_tween: Tween = null


func _ready() -> void:
    super._ready()
    _mika_more_button = Button.new()
    _mika_more_button.name = "FreeWorld_MoreGames_BottomRight"
    _mika_more_button.focus_mode = Control.FOCUS_NONE
    _mika_more_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _mika_more_button.add_theme_stylebox_override("normal", _mika_more_style(false))
    _mika_more_button.add_theme_stylebox_override("hover", _mika_more_style(true))
    _mika_more_button.add_theme_stylebox_override("pressed", _mika_more_style(true))
    _mika_more_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _mika_more_button.add_theme_color_override("font_color", Color("f2fbff"))
    _mika_more_button.add_theme_color_override("font_hover_color", Color.WHITE)
    _mika_more_button.add_theme_color_override("font_pressed_color", Color.WHITE)
    _mika_more_button.pressed.connect(_mika_toggle_more_games)
    # This layer already sits above the cards and is hidden while a game runs.
    # No second overlay is created over the game runner or its own Back button.
    _gesture_layer.add_child(_mika_more_button)
    _mika_more_ready = true
    MobileLocale.language_changed.connect(_mika_update_more_button)
    _mika_refresh_catalog(false)
    _reflow()


func _mika_more_style(hover: bool) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("10486a") if hover else Color(0.020, 0.105, 0.245, 0.96)
    style.border_color = Color("94f2ff") if hover else Color("26dfff")
    style.set_border_width_all(2)
    style.set_corner_radius_all(20)
    style.shadow_color = Color(0.03, 0.62, 1.0, 0.52)
    style.shadow_size = 7
    style.anti_aliasing = true
    return style


func _mika_read_mode() -> String:
    # The real SettingsLanguagePopup.gd writes this existing setting.
    # Do not invent new mode IDs or unlock Story, which is not released.
    var settings: ConfigFile = ConfigFile.new()
    if settings.load(MODE_SETTINGS_PATH) != OK:
        return "free_world"  # Existing game's default.
    return str(settings.get_value("game", "mode", "free_world"))


func _mika_refresh_catalog(preserve_expansion: bool) -> void:
    if not _mika_more_ready or not _grid_ready:
        return
    _mika_is_free_world = _mika_read_mode() == "free_world"
    if not _mika_is_free_world or not preserve_expansion:
        _mika_extra_expanded = false
    for index in range(_grid_cards.size()):
        var card: TextureButton = _grid_cards[index]
        if is_instance_valid(card):
            card.visible = index < APPROVED_CARD_COUNT or (_mika_is_free_world and _mika_extra_expanded)
    if _mika_extra_expanded:
        _gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    else:
        _gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        if _mika_scroll_tween != null and _mika_scroll_tween.is_running():
            _mika_scroll_tween.kill()
        _gallery.scroll_vertical = 0
    _mika_update_more_button()


func _mika_update_more_button(_locale: String = "") -> void:
    if _mika_more_button == null:
        return
    # In Story this is hidden and can never be clicked even if previously open.
    _mika_more_button.visible = _mika_is_free_world and _grid_cards.size() > APPROVED_CARD_COUNT
    var translated: Array = BUTTON_TEXT.get(str(MobileLocale.language), BUTTON_TEXT["en"])
    _mika_more_button.text = str(translated[1] if _mika_extra_expanded else translated[0])
    _mika_more_button.tooltip_text = str(translated[3] if _mika_extra_expanded else translated[2])


func open_menu(view: Vector2) -> void:
    super.open_menu(view)
    # Reset to ten games on each new simulator visit; read mode from Settings.
    _mika_refresh_catalog(false)
    _reflow()


func _mika_toggle_more_games() -> void:
    if not _mika_more_ready or not _mika_is_free_world or _playing:
        return
    _mika_extra_expanded = not _mika_extra_expanded
    _mika_refresh_catalog(true)
    if _mika_extra_expanded:
        # Reveal third row smoothly; from there native vertical scroll works.
        call_deferred("_mika_scroll_to_first_extra")
    _reflow()


func _mika_scroll_to_first_extra() -> void:
    await get_tree().process_frame
    if not is_inside_tree() or not _mika_extra_expanded or _grid_cards.size() <= APPROVED_CARD_COUNT:
        return
    var first_extra: TextureButton = _grid_cards[APPROVED_CARD_COUNT]
    if not is_instance_valid(first_extra):
        return
    var limit: int = maxi(0, roundi(_strip.size.y - _gallery.size.y))
    var target: int = clampi(roundi(first_extra.position.y - 8.0), 0, limit)
    if target <= 0:
        return
    if _mika_scroll_tween != null and _mika_scroll_tween.is_running():
        _mika_scroll_tween.kill()
    _mika_scroll_tween = create_tween()
    _mika_scroll_tween.tween_property(_gallery, "scroll_vertical", target, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _reflow() -> void:
    super._reflow()
    if not _mika_more_ready or not is_instance_valid(_gesture_layer):
        return
    # Button lives in gallery coordinates, next to the bottom-right card.
    # Proportional sizing keeps the same finger-sized target on narrow screens.
    var side: float = clampf(minf(_gesture_layer.size.x, _gesture_layer.size.y) * 0.115, 46.0, 68.0)
    var gap: float = clampf(side * 0.14, 6.0, 10.0)
    _mika_more_button.size = Vector2(side, side)
    _mika_more_button.position = Vector2(
        maxf(0.0, _gesture_layer.size.x - side - gap),
        maxf(0.0, _gesture_layer.size.y - side - gap)
    )
    _mika_more_button.add_theme_font_size_override("font_size", maxi(22, roundi(side * 0.49)))
    _mika_more_button.move_to_front()


func _input(event: InputEvent) -> void:
    # Grid gestures are global _input events. Do not let a click on the
    # floating button also open the last game card beneath it.
    if _mika_more_ready and _mika_more_button.visible and not _playing:
        var pointer: Vector2 = Vector2(-10000.0, -10000.0)
        var has_position: bool = false
        if event is InputEventMouse:
            pointer = (event as InputEventMouse).position
            has_position = true
        elif event is InputEventScreenTouch:
            pointer = (event as InputEventScreenTouch).position
            has_position = true
        elif event is InputEventScreenDrag:
            pointer = (event as InputEventScreenDrag).position
            has_position = true
        if has_position and _mika_more_button.get_global_rect().has_point(pointer):
            return
    super._input(event)
