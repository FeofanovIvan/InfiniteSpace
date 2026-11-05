extends Control
## Direct image/panel renderer for P01-P07, X01-X10. No video files involved.
## set_panel(id,...) previews panels; set_transition(id,..., t) supports precise seek.
const Registry = preload("res://mika_comic_kit/scripts/comic_registry.gd")
const SHADER = preload("res://mika_comic_kit/shaders/comic_cover_mask.gdshader")
const IMAGE_FOLDER: String = "res://mika_comic_kit/assets/"
var assets: Dictionary = {}
var layers: Array[ColorRect] = []
var mats: Array[ShaderMaterial] = []
var cutout: TextureRect
var guide_lines: Control
var active_panel: String = "P01"
var active_transition: String = "X01"
var reduce_motion: bool = false

func _ready() -> void:
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var keys: Array[String] = ["city", "mica_balcony", "news", "disaster_red", "disaster_magenta", "conversation", "ship_front", "ship_rear", "cockpit", "cutout_demo_RGBA"]
    for key in keys:
        assets[key] = load(IMAGE_FOLDER+key+".png") as Texture2D
    for i in range(4):
        var rect := ColorRect.new()
        rect.name = "ArtworkLayer"+str(i)
        rect.color = Color.WHITE
        rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        rect.visible = false
        var material_instance := ShaderMaterial.new()
        material_instance.shader = SHADER
        rect.material = material_instance
        add_child(rect)
        layers.append(rect)
        mats.append(material_instance)
    cutout = TextureRect.new()
    cutout.name = "SeparateRGBACharacter"
    cutout.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cutout.texture = assets["cutout_demo_RGBA"]
    cutout.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    cutout.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    cutout.visible = false
    add_child(cutout)
    resized.connect(_sync_canvas)
    _sync_canvas()
    show_panel("P01")

func _sync_canvas() -> void:
    for mat in mats:
        mat.set_shader_parameter("canvas_size",size)

func register_image(key: String, texture: Texture2D) -> void:
    # Future pages: use the same panel/transition IDs with new images.
    if key.is_empty() or texture == null:
        push_error("MIKA Comic Kit requires non-empty image key and texture")
        return
    assets[key] = texture

func set_cutout_texture(subject: Texture2D) -> void:
    # P07 and X07 need a genuine alpha-cutout PNG; source artwork is not modified.
    if subject != null:
        cutout.texture = subject

func _hide() -> void:
    for layer in layers:
        layer.visible = false
    cutout.visible = false

func _art(slot: int, key: String, mask: int = 0, rect: Vector4 = Vector4(0,0,1,1), seam_x: float = 0.5, slope_value: float = 0.12, alpha: float = 1.0, zoom: float = 1.0, focus_point: Vector2 = Vector2(0.5,0.5), reveal_radius: float = 0.5, shake_value: Vector2 = Vector2.ZERO) -> void:
    var layer: ColorRect = layers[slot]
    layer.visible = alpha > 0.0001
    var shader: ShaderMaterial = mats[slot]
    shader.set_shader_parameter("picture", assets.get(key,assets["city"]))
    shader.set_shader_parameter("mask_kind",mask)
    shader.set_shader_parameter("mask_rect",rect)
    shader.set_shader_parameter("seam",seam_x)
    shader.set_shader_parameter("slope",slope_value)
    shader.set_shader_parameter("opacity",clampf(alpha,0,1))
    shader.set_shader_parameter("camera_zoom",zoom)
    shader.set_shader_parameter("focus",focus_point)
    shader.set_shader_parameter("radius",reveal_radius)
    shader.set_shader_parameter("shake_px",shake_value)

func _character(p: Vector2, scale_val: float = 1.0, alpha: float = 1.0) -> void:
    cutout.visible = true
    cutout.modulate = Color(1,1,1,clampf(alpha,0,1))
    var target_height: float = size.y * 0.70 * scale_val
    var texture_size: Vector2 = cutout.texture.get_size() if cutout.texture != null else Vector2(450,560)
    var target_width: float = target_height * texture_size.x/maxf(1.0,texture_size.y)
    cutout.size = Vector2(target_width,target_height)
    cutout.position = p * size - cutout.size*0.5

func show_panel(id: String, image_a: String = "city", image_b: String = "mica_balcony", image_c: String = "disaster_magenta") -> void:
    _hide()
    active_panel = id
    match id:
        "P01":
            _art(0,image_a,0,Vector4(),0.5,0.0,1.0,1.04)
        "P02":
            _art(0,image_a)
            _art(1,image_b,2,Vector4(),0.54,-0.12)
        "P03":
            _art(0,image_a)
            _art(1,image_b,2,Vector4(),0.53,0.13)
        "P04":
            _art(0,image_a)
            _art(1,image_b,3,Vector4(0.59,0.08,0.35,0.45))
        "P05":
            _art(0,image_a,3,Vector4(0,0,1,0.33))
            _art(1,image_b,3,Vector4(0,0.34,1,0.33))
            _art(2,image_c,3,Vector4(0,0.68,1,0.32))
        "P06":
            _art(0,image_a)
            _art(1,image_b,3,Vector4(0.08,0.11,0.48,0.49))
            _art(2,image_c,3,Vector4(0.51,0.42,0.43,0.48))
        "P07":
            _art(0,image_a)
            _art(1,image_b,3,Vector4(0.49,0.15,0.45,0.69))
            _character(Vector2(0.49,0.55),0.85)
        _:
            _art(0,image_a)

static func _smooth(q: float) -> float:
    var t := clampf(q,0.0,1.0)
    return t*t*(3.0-2.0*t)

func show_transition(id: String, q: float, image_a: String = "city", image_b: String = "mica_balcony", image_c: String = "disaster_red") -> void:
    active_transition = id
    _hide()
    var t: float = _smooth(q)
    var disturbance: Vector2 = Vector2.ZERO
    match id:
        "X01":
            _art(0,image_a)
            _art(1,image_b,3,Vector4(1.0-t,0,t,1))
        "X02":
            _art(0,image_a)
            _art(1,image_b,2,Vector4(),1.09-t*0.62,-0.16)
        "X03":
            _art(0,image_a)
            _art(1,image_b,3,Vector4(0,0,1,t*0.5))
            _art(2,image_c,3,Vector4(0,1.0-t*0.5,1,t*0.5))
        "X04":
            _art(0,image_a,0,Vector4(),0.5,0.0,1.0,lerpf(1.0,1.23,t))
            _art(1,image_b,0,Vector4(),0.5,0.0,t*t,lerpf(1.14,1.0,t))
        "X05":
            # Source and target share central focus; cut at the moving object's position.
            if q < 0.5:
                _art(0,image_a,0,Vector4(),0.5,0.0,1.0,lerpf(1.0,1.11,t))
            else:
                _art(0,image_b,0,Vector4(),0.5,0.0,1.0,lerpf(0.91,1.0,t),Vector2(0.5,0.5))
        "X06":
            _art(0,image_a)
            _art(1,image_b,4,Vector4(),0.5,0.0,1.0,1.0,Vector2(0.5,0.5),t*0.8)
        "X07":
            _art(0,image_a)
            _art(1,image_b,3,Vector4(0.40,0.10,0.56,0.78))
            _character(Vector2(0.97-t*0.5,0.54),0.6+0.3*t)
        "X08":
            _art(0,image_a,0,Vector4(),0.5,0.0,1.0,lerpf(1.00,1.14,t),Vector2(0.50+0.05*t,0.5))
            _character(Vector2(0.50+0.18*t,0.56),0.68)
        "X09":
            if q < 0.44:
                _art(0,image_a)
            else:
                if not reduce_motion:
                    var strength: float = 11.0*(1.0-t)
                    disturbance = Vector2(sin(q*67.0)*strength,cos(q*79.0)*strength)
                _art(0,image_b,0,Vector4(),0.5,0.0,1.0,1.08,Vector2(0.5,0.5),0.5,disturbance)
        "X10":
            _art(0,image_a)
            _art(1,image_b,0,Vector4(),0.5,0.0,t)
        _:
            _art(0,image_a)
