@tool
extends Control
## Independent portrait slot. Put a transparent representative illustration at
## res://assets/representative_dialog.png to replace the temporary holo avatar.

@export var portrait_path: String = "":
    set(value):
        portrait_path = value
        _load_portrait()

var portrait: TextureRect
var _portrait_path_loaded: String = ""

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait = TextureRect.new()
    portrait.name = "ReplaceableRepresentativeArt"
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(portrait)
    _load_portrait()
    resized.connect(_relayout)
    _relayout()

func _load_portrait() -> void:
    if portrait == null:
        return
    portrait.texture = null
    _portrait_path_loaded = portrait_path
    if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
        portrait.texture = load(portrait_path) as Texture2D
    queue_redraw()

func _relayout() -> void:
    if portrait != null:
        portrait.position = Vector2.ZERO
        portrait.size = size
    queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 10.0 or h < 10.0:
        return
    var sx: float = w / 570.0
    var sy: float = h / 640.0
    var s: float = minf(sx,sy)
    # A subtle freestanding holographic pedestal, not a boxed-in character card.
    draw_arc(Vector2(w*0.50,h*0.91), w*0.35, 0.15, PI-0.15, 48, Color(0.20,0.78,1.0,0.55), 3*s, true)
    draw_line(Vector2(w*0.17,h*0.91),Vector2(w*0.83,h*0.91),Color(0.18,0.58,0.9,0.75),2*s,true)
    if portrait != null and portrait.texture != null:
        return
    # Explicitly temporary, native-drawn scientific hologram silhouette.
    # Its proportions match the portrait viewport without raster dependencies.
    var cy: float = h*0.39
    var cx: float = w*0.48
    var shoulders: PackedVector2Array = PackedVector2Array([
        Vector2(cx-174*s,h*0.86),Vector2(cx-155*s,h*0.69),
        Vector2(cx-114*s,h*0.61),Vector2(cx-58*s,h*0.575),
        Vector2(cx+57*s,h*0.575),Vector2(cx+116*s,h*0.61),
        Vector2(cx+160*s,h*0.69),Vector2(cx+179*s,h*0.86)])
    draw_colored_polygon(shoulders,Color(0.16,0.35,0.51,0.82))
    draw_polyline(shoulders,Color(0.24,0.72,1.0,0.67),3*s,true)
    draw_colored_polygon(PackedVector2Array([
        Vector2(cx-61*s,h*0.57),Vector2(cx-22*s,h*0.72),
        Vector2(cx+22*s,h*0.72),Vector2(cx+58*s,h*0.57)]),Color(0.80,0.92,0.98,0.44))
    draw_rect(Rect2(cx-18*s,h*0.69,36*s,12*s),Color(0.20,0.88,1.0,0.90))
    # Neck, dark hair, face and visor-like highlights.
    draw_rect(Rect2(cx-35*s,cy+92*s,70*s,76*s),Color(0.57,0.75,0.85,0.72))
    draw_circle(Vector2(cx,cy),101*s,Color(0.065,0.17,0.28,0.94))
    draw_circle(Vector2(cx,cy+10*s),78*s,Color(0.38,0.61,0.76,0.93))
    draw_arc(Vector2(cx,cy+10*s),82*s,0.23,PI-0.23,34,Color(0.19,0.85,1.0,0.86),3*s,true)
    draw_arc(Vector2(cx,cy+10*s),89*s,PI+0.24,TAU-0.24,34,Color(0.40,0.76,0.97,0.67),2*s,true)
    draw_line(Vector2(cx-28*s,cy+7*s),Vector2(cx-6*s,cy+7*s),Color(0.02,0.16,0.27,0.8),3*s,true)
    draw_line(Vector2(cx+8*s,cy+7*s),Vector2(cx+30*s,cy+7*s),Color(0.02,0.16,0.27,0.8),3*s,true)
    draw_arc(Vector2(cx,cy+40*s),22*s,0.35,PI-0.35,16,Color(0.05,0.24,0.37,0.75),2*s,true)
    draw_circle(Vector2(cx+85*s,cy+55*s),8*s,Color(0.15,0.89,1.0,0.85))
    var f: Font = ThemeDB.fallback_font
    draw_string(f,Vector2(cx-112*s,h*0.79),"МЕСТО ДЛЯ ПЕРСОНАЖА",HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(12,int(15*s)),Color(0.8,0.93,1.0,0.80))
