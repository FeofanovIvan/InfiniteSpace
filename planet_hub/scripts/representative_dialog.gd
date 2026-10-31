@tool
extends Control
signal return_requested
## Planet representative conversation screen.
## Same OPTIONAL planet background as PlanetHub, with no lower HUD.

@export var planet_background: String = "":
    set(value):
        planet_background = value
        _load_background()

@onready var character: Control = $RepresentativeCharacter
@onready var hint: Control = $PhraseHint
@onready var tablet: Control = $TranslatorTablet

var _background: Texture2D
var _back_button: Button
var _caption: Label
var _setup: bool = false
var _current_planet_id: String = ""
var _current_planet_name: String = ""

func configure_for_planet(planet_id: String, planet_name: String, background_path: String, portrait_path: String) -> void:
    _current_planet_id = planet_id
    _current_planet_name = planet_name
    planet_background = background_path
    if _caption != null:
        _caption.text = planet_name.to_upper() + "  /  ПРЕДСТАВИТЕЛЬ"
    if character != null:
        character.set("portrait_path", portrait_path)
    if tablet != null:
        tablet.set("representative_name", "Представитель: " + planet_name)
        tablet.set("representative_role", "Первый контакт · учебный переводчик")
        var title_label: Label = tablet.get_node_or_null("RepresentativeName") as Label
        if title_label != null:
            title_label.text = "Представитель: " + planet_name
        var role_label: Label = tablet.get_node_or_null("RepresentativeRole") as Label
        if role_label != null:
            role_label.text = "Первый контакт · учебный переводчик"
        tablet.call("reset_exercise")
    queue_redraw()


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _load_background()
    _back_button = Button.new()
    _back_button.name = "BackToPlanet"
    _back_button.text = "←  НАЗАД"
    _back_button.focus_mode = Control.FOCUS_NONE
    _back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _back_button.add_theme_font_size_override("font_size",23)
    _back_button.add_theme_color_override("font_color",Color("f6fbff"))
    _back_button.add_theme_color_override("font_hover_color",Color.WHITE)
    _apply_back_style()
    add_child(_back_button)
    _back_button.pressed.connect(_go_back)
    _caption = Label.new()
    _caption.text = "ПРЕДСТАВИТЕЛЬ ПЛАНЕТЫ"
    _caption.add_theme_color_override("font_color",Color("b6e8ff"))
    _caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_caption)
    tablet.progress_changed.connect(_on_progress_changed)
    _setup = true
    resized.connect(_layout_ui)
    _layout_ui()
    queue_redraw()

func _apply_back_style() -> void:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.013,0.092,0.19,0.94)
    style.border_color = Color("46baff")
    style.set_border_width_all(2)
    style.set_corner_radius_all(11)
    style.shadow_color = Color(0.02,0.46,0.9,0.3)
    style.shadow_size = 5
    _back_button.add_theme_stylebox_override("normal",style)
    var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
    hover.bg_color = Color("174e84")
    _back_button.add_theme_stylebox_override("hover",hover)
    _back_button.add_theme_stylebox_override("pressed",hover)
    _back_button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())

func _load_background() -> void:
    _background = null
    if not planet_background.is_empty() and ResourceLoader.exists(planet_background):
        _background = load(planet_background) as Texture2D
    queue_redraw()

func _layout_ui() -> void:
    if not _setup or size.x < 100 or size.y < 100:
        return
    var sw: float = size.x
    var sh: float = size.y
    var s: float = minf(sw/1728.0, sh/864.0)
    var x0: float = (sw-1670*s)*0.5
    var y0: float = (sh-864*s)*0.5
    _back_button.position = Vector2(x0+8*s,y0+17*s)
    _back_button.size = Vector2(170*s,67*s)
    _back_button.add_theme_font_size_override("font_size",maxi(13,int(23*s)))
    _caption.position = Vector2(x0+220*s,y0+24*s)
    _caption.size = Vector2(560*s,52*s)
    _caption.add_theme_font_size_override("font_size",maxi(14,int(22*s)))
    character.position = Vector2(x0+22*s,y0+138*s)
    character.size = Vector2(565*s,650*s)
    hint.position = Vector2(x0+406*s,y0+250*s)
    hint.size = Vector2(395*s,186*s)
    tablet.position = Vector2(x0+845*s,y0+65*s)
    tablet.size = Vector2(800*s,730*s)
    queue_redraw()

func _on_progress_changed(characters: int) -> void:
    hint.progress = characters

func _go_back() -> void:
    # Never change the main Godot scene: returning must preserve the ship,
    # the crystal tank, the current system and the underlying planet hub.
    if not Engine.is_editor_hint():
        return_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
    if not Engine.is_editor_hint() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _go_back()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 5.0 or h < 5.0:
        return
    if _background != null:
        var ts: Vector2 = _background.get_size()
        var factor: float = maxf(w/ts.x,h/ts.y)
        var used: Vector2 = Vector2(w,h)/factor
        draw_texture_rect_region(_background,Rect2(Vector2.ZERO,size),Rect2((ts-used)*0.5,used))
    else:
        # A lightweight native starfield. Replace background_planet.png later.
        draw_rect(Rect2(Vector2.ZERO,size),Color("061629"))
        var random: RandomNumberGenerator = RandomNumberGenerator.new()
        random.seed = 2412
        for i in range(230):
            var p: Vector2 = Vector2(random.randf_range(0,w),random.randf_range(0,h))
            draw_circle(p,random.randf_range(0.35,1.5),Color(0.68,0.86,1,random.randf_range(0.2,0.7)))
        for i in range(18):
            var yy: float = h*0.48+float(i)*h*0.032
            draw_line(Vector2(0,yy),Vector2(w,yy),Color(0.08,0.36,0.57,0.07),1.2,true)
    # Soft vignette improves text legibility while preserving the world backdrop.
    draw_rect(Rect2(Vector2.ZERO,size),Color(0.004,0.014,0.042,0.30))
