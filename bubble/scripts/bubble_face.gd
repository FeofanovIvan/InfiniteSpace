extends Node2D
# MIKA_DENTAL_RESTORED_TO_V8_5_9_2_R1
class_name MikaBubbleFace
# MIKA v8.5.9.6.2: fast room dental progress, independent per tooth.
# The detailed pixel eraser (brush_at) remains for other demos, untouched.
## Bubble face V2: continuous procedural jaw plus individual paintable teeth.
## Compatible with Godot 4.7.1; no changes required to the body renderer.

signal expression_changed(id: String)
signal brushing_progress_changed(progress: float)

@export var show_preview_body: bool = true
@export var automatic_blink: bool = true
@export_range(0.0, 1.0, 0.01) var initial_jaw_open: float = 0.0

const FACE_DIR := "res://bubble/assets/face/"
const PRESET_PATH := "res://bubble/docs/expression_presets.json"
const EYE_X := 86.0
const EYE_Y := -36.0
const TEETH_X := [-46.0, -23.0, 0.0, 23.0, 46.0]
# Physical radius in the original face-local coordinate system. The complete
# rig is subsequently scaled to 0.79 by the approved BubbleBrain.
const FACE_SURFACE_RADIUS: float = 193.0
const FACE_CURVE_SHADER: Shader = preload("res://bubble/shaders/bubble_face_curvature.gdshader")

var current_expression: String = "calm"
var jaw_open: float = 0.0
var gaze := Vector2.ZERO
var presets: Dictionary = {}
var _eyes: Array[Dictionary] = []
var _mouth: Sprite2D
var _body: Sprite2D
var _cheeks: Array[Sprite2D] = []
var _jaw_root: Node2D
var _cavity: Sprite2D
var _upper_lip: Sprite2D
var _lower_jaw: Node2D
var _lower_lip: Sprite2D
var _side_lip_left: Line2D
var _side_lip_right: Line2D
var _upper_lip_clip: Polygon2D
var _lower_lip_clip: Polygon2D
var _teeth_clip: Polygon2D
var _mouth_fill: Polygon2D
var _mouth_tongue: Polygon2D
var _lip_contour: Line2D
var _upper_teeth: Node2D
var _lower_teeth: Node2D
var _plaque_layers: Array[Dictionary] = []
var _plaque_total: float = 1.0
var _plaque_removed: float = 0.0
var _blink_remaining: float = 3.2
var _blinking: bool = false
var _brush_mode: bool = false
var _surface_yaw: float = 0.0
var _mouth_nominal_scale: float = 0.48
var _curved_sprites: Array[Sprite2D] = []

func _ready() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESET_PATH))
    if parsed is Dictionary:
        presets = parsed
    _build_layers()
    set_expression(current_expression)
    set_jaw_open(initial_jaw_open)
    set_surface_heading(0.0)
    reset_plaque()

func _make_sprite(parent: Node, part: String, name_part: String, s: float = 1.0, p: Vector2 = Vector2.ZERO) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.name = name_part
    sprite.texture = load(FACE_DIR + part + ".png")
    sprite.centered = true
    sprite.scale = Vector2.ONE * s
    sprite.position = p
    parent.add_child(sprite)
    return sprite

func _build_layers() -> void:
    _body = _make_sprite(self, "preview_only/body_sphere", "PreviewBody")
    _body.visible = show_preview_body
    for side in range(2):
        var left: bool = side == 0
        var pos := Vector2(-EYE_X if left else EYE_X, EYE_Y)
        var node := Node2D.new()
        node.name = "LeftEye" if left else "RightEye"
        node.position = pos
        add_child(node)
        var items: Dictionary = {
            "root":node,
            "sclera":_make_sprite(node, "eye_sclera", "Sclera", 0.65),
            "iris":_make_sprite(node, "eye_iris", "Iris", 0.65),
            "glint":_make_sprite(node, "eye_highlights", "Glint", 0.65),
            "half":_make_sprite(node, "eye_half_lid", "HalfLid", 0.65),
            "closed":_make_sprite(node, "eye_closed", "Closed", 0.65),
            "happy":_make_sprite(node, "eye_happy", "Happy", 0.65),
            "brow":_make_sprite(node, "eyebrow_soft", "Brow", 0.66, Vector2(0, -41)),
        }
        _eyes.append(items)
    for side in range(2):
        var x := -162.0 if side == 0 else 162.0
        var cheek := _make_sprite(self, "cheek_blush", "CheekLeft" if side == 0 else "CheekRight", 0.55, Vector2(x,74))
        _cheeks.append(cheek)
    _mouth = _make_sprite(self,"mouth_smile","ClosedMouth",0.48,Vector2(0,88))
    _jaw_root = Node2D.new()
    _jaw_root.name = "ContinuousJawRig"
    _jaw_root.position = Vector2(0, 88)
    add_child(_jaw_root)
    _cavity = _make_sprite(_jaw_root, "jaw_cavity", "Cavity", 0.52)
    # MIKA_BUBBLE_SEAMLESS_DENTAL_V8_4_3
    # MIKA_BUBBLE_PNG_TOOTH_ROLLBACK_V8_4_4
    # MIKA_BUBBLE_SMOOTH_LIPS_V8_4_5: draw a coherent open-mouth cavity and lip in the same rig.
    # The legacy cavity PNG remains as a reference/closed-jaw asset,
    # but its mismatched colored rim must not compete with one lip.
    _cavity.visible = true
    _mouth_fill = Polygon2D.new()
    _mouth_fill.name = "NativeJawInterior"
    _mouth_fill.color = Color(0.19, 0.055, 0.23, 0.98)
    _mouth_fill.antialiased = true
    _jaw_root.add_child(_mouth_fill)
    _mouth_fill.visible = false
    _mouth_tongue = Polygon2D.new()
    _mouth_tongue.name = "NativeJawTongue"
    _mouth_tongue.color = Color(0.88, 0.45, 0.60, 0.94)
    _mouth_tongue.antialiased = true
    _jaw_root.add_child(_mouth_tongue)
    _mouth_tongue.visible = false
    _teeth_clip = Polygon2D.new()
    _teeth_clip.name = "NativeLipInnerMask"
    _teeth_clip.color = Color.WHITE
    _teeth_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
    _jaw_root.add_child(_teeth_clip)
    _upper_teeth = Node2D.new()
    _upper_teeth.name = "UpperTeeth"
    # Upper teeth are children of their own mask, derived from the ORIGINAL
    # upper-lip PNG alpha edge; not the synthetic replacement mouth polygon.
    _upper_lip_clip = Polygon2D.new()
    _upper_lip_clip.name = "UpperPNGTeethClip"
    _upper_lip_clip.color = Color.WHITE
    _upper_lip_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
    _jaw_root.add_child(_upper_lip_clip)
    _upper_lip_clip.add_child(_upper_teeth)
    _lower_jaw = Node2D.new()
    _lower_jaw.name = "LowerJaw"
    _jaw_root.add_child(_lower_jaw)
    _lower_teeth = Node2D.new()
    _lower_teeth.name = "LowerTeeth"
    # Lower row follows the ORIGINAL lower jaw and its lip, not a shared
    # rigid mask. This keeps every tooth and its plaque mask synchronized.
    _lower_lip_clip = Polygon2D.new()
    _lower_lip_clip.name = "LowerPNGTeethClip"
    _lower_lip_clip.color = Color.WHITE
    _lower_lip_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
    _lower_jaw.add_child(_lower_lip_clip)
    _lower_lip_clip.add_child(_lower_teeth)
    for i in range(5):
        var number: int = i+1
        var upper := _make_sprite(_upper_teeth, "teeth/upper_%d" % number, "U%d" % number,0.30,Vector2(TEETH_X[i], -26))
        _add_plaque(upper, "upper", number)
        var lower := _make_sprite(_lower_teeth, "teeth/lower_%d" % number, "L%d" % number,0.30,Vector2(TEETH_X[i], 27))
        _add_plaque(lower, "lower", number)
    _upper_lip = _make_sprite(_jaw_root, "lip_upper", "UpperLip",0.54)
    _lower_lip = _make_sprite(_lower_jaw,"lip_lower","LowerLip",0.54)
    # These old PNGs formed disconnected pieces of unequal color.
    # The continuous native lip draws above the teeth and the cavity.
    _upper_lip.visible = true
    _lower_lip.visible = true
    _lip_contour = Line2D.new()
    _lip_contour.name = "UnifiedLips"
    _lip_contour.closed = true
    _lip_contour.width = 9.0
    _lip_contour.antialiased = true
    _lip_contour.joint_mode = Line2D.LINE_JOINT_ROUND
    _lip_contour.round_precision = 10
    _lip_contour.default_color = Color(0.71, 0.43, 0.82, 1.0)
    var lip_width := Curve.new()
    lip_width.max_value = 2.0
    # Slim corners, organically fuller upper and lower centers.
    for point in [Vector2(0.0, 0.65), Vector2(0.18, 0.95),
                  Vector2(0.25, 1.36), Vector2(0.34, 0.95),
                  Vector2(0.5, 0.65), Vector2(0.66, 1.00),
                  Vector2(0.75, 1.53), Vector2(0.84, 1.00),
                  Vector2(1.0, 0.65)]:
        lip_width.add_point(point)
    _lip_contour.width_curve = lip_width
    _jaw_root.add_child(_lip_contour)
    # Hide the v8.4.3 angular one-piece outline; return to the
    # approved natural PNG lip art from v8.4.2.
    _lip_contour.visible = false
    # Side rim is behind the real upper/lower lip PNGs but in front of
    # the paintable teeth. It lives inside the SAME continuous jaw rig.
    var side_color: Color = _sample_lip_color(_upper_lip)
    _side_lip_left = _new_side_lip("LeftSideLip", side_color)
    _side_lip_right = _new_side_lip("RightSideLip", side_color)
    # Explicit relative CanvasItem ordering across mask/lower-jaw children.
    _cavity.z_index = 0
    _upper_lip_clip.z_index = 0
    _lower_jaw.z_index = 0
    _lower_lip_clip.z_index = 0
    _upper_teeth.z_index = 0
    _lower_teeth.z_index = 0
    _side_lip_left.z_index = 1
    _side_lip_right.z_index = 1
    _upper_lip.z_index = 2
    _lower_lip.z_index = 2
    _build_png_lip_clips()
    _update_side_lips(0.0)
    # Facial parts have separate curved projections; teeth/paint masks remain
    # unshaded so the approved interactive dental collision mapping is intact.
    for e in _eyes:
        for key in ["sclera", "iris", "glint", "half", "closed", "happy", "brow"]:
            _enable_curved_texture(e[key] as Sprite2D)
    for cheek in _cheeks:
        _enable_curved_texture(cheek)
    _enable_curved_texture(_mouth)

func _enable_curved_texture(sprite: Sprite2D) -> void:
    var mat := ShaderMaterial.new()
    mat.shader = FACE_CURVE_SHADER
    mat.set_shader_parameter("curve_strength", 0.12)
    sprite.material = mat
    _curved_sprites.append(sprite)

func _sphere_point(x: float, yaw: float) -> Vector2:
    # x stores the face-local frontal x coordinate; the return value is
    # projected x and outward-facing depth on a spherical surface.
    var phi: float = asin(clampf(x / FACE_SURFACE_RADIUS, -0.985, 0.985))
    var angle: float = phi + yaw
    return Vector2(FACE_SURFACE_RADIUS * sin(angle), cos(angle))

func _depth_width(base_x: float, depth: float) -> float:
    # Exactly 1.0 at front, compressed at profile, never mirrored or negative.
    var original_depth: float = sqrt(maxf(0.0001, 1.0 - pow(base_x / FACE_SURFACE_RADIUS, 2.0)))
    return clampf(maxf(0.0, depth) / original_depth, 0.045, 1.20)

func set_surface_heading(heading_rad: float) -> void:
    # Project every eye, cheek and lip independently around the same curved
    # body. The back hemisphere occludes individual features. This replaces
    # the former flat Face parent that shrank and then disappeared at 90deg.
    _surface_yaw = wrapf(heading_rad, -PI, PI)
    if _eyes.is_empty() or not is_instance_valid(_mouth):
        return
    for i in range(_eyes.size()):
        var base_x: float = -EYE_X if i == 0 else EYE_X
        var p: Vector2 = _sphere_point(base_x, _surface_yaw)
        var depth: float = p.y
        var root: Node2D = _eyes[i]["root"] as Node2D
        root.position = Vector2(p.x, EYE_Y + (1.0 - maxf(depth, 0.0)) * 2.8)
        # The pupil/eyelid remain internally animated by the existing rig.
        # Only horizontal projection is controlled here: blink's scale.y stays.
        root.scale.x = _depth_width(base_x, depth)
        root.rotation = -0.065 * sin(_surface_yaw + asin(base_x / FACE_SURFACE_RADIUS))
        root.visible = depth > 0.065
    for i in range(_cheeks.size()):
        var cheek_x: float = -162.0 if i == 0 else 162.0
        var cp: Vector2 = _sphere_point(cheek_x, _surface_yaw)
        var cheek: Sprite2D = _cheeks[i]
        cheek.position = Vector2(cp.x, 74.0 + 3.0 * (1.0 - cp.y))
        cheek.scale = Vector2(0.55 * _depth_width(cheek_x, cp.y), 0.55)
        cheek.visible = bool(presets.get(current_expression, {}).get("blush", false)) and cp.y > 0.11
    var center: Vector2 = _sphere_point(0.0, _surface_yaw)
    var mouth_width: float = _depth_width(0.0, center.y)
    _mouth.position = Vector2(center.x, 88.0 + (1.0 - center.y) * 3.0)
    _mouth.scale = Vector2(_mouth_nominal_scale * mouth_width, _mouth_nominal_scale)
    _mouth.rotation = -0.04 * sin(_surface_yaw)
    # Visibility and alpha derive from the same continuous jaw value.
    _apply_continuous_mouth_visibility(center.y)
    _jaw_root.position = Vector2(center.x, 88.0 + (1.0 - center.y) * 3.0)
    var jaw_eased: float = jaw_open * jaw_open * (3.0 - 2.0 * jaw_open)
    _jaw_root.scale = Vector2(lerpf(0.74, 1.0, jaw_eased) * mouth_width, 1.0)
    _jaw_root.rotation = -0.04 * sin(_surface_yaw)
    # Jaw visibility was set together with closed-mouth alpha above.
    # Local UV curvature makes the eye/mouth texture bend slightly within
    # each feature as well as following the sphere's larger geometry.
    for sprite in _curved_sprites:
        var mat: ShaderMaterial = sprite.material as ShaderMaterial
        if mat != null:
            mat.set_shader_parameter("side_bend", sin(_surface_yaw) * 0.60)

func _add_plaque(tooth: Sprite2D, row: String, number: int) -> void:
    var mask := Sprite2D.new()
    mask.name = "Plaque"
    mask.texture = load(FACE_DIR + "teeth/plaque_%s_%d.png" % [row, number])
    tooth.add_child(mask)
    _plaque_layers.append({"node":mask, "base":mask.texture.get_image().duplicate(),"image":null,"texture":null})

func set_preview_body_visible(enabled: bool) -> void:
    show_preview_body = enabled
    if is_instance_valid(_body):
        _body.visible = enabled

func set_expression(id: String) -> void:
    if not presets.has(id):
        push_warning("Unknown Bubble expression: " + id)
        return
    current_expression = id
    var item: Dictionary = presets[id]
    var eyes_type: String = str(item.get("eyes","open"))
    var brow_type: String = str(item.get("brow","soft"))
    var mouth_type: String = str(item.get("mouth","smile"))
    for i in range(_eyes.size()):
        var e: Dictionary = _eyes[i]
        var closed: bool = eyes_type == "closed" or (eyes_type == "wink" and i == 1)
        var happy: bool = eyes_type == "happy"
        e["sclera"].visible = not closed and not happy
        e["iris"].visible = not closed and not happy
        e["glint"].visible = not closed and not happy
        e["half"].visible = eyes_type == "half"
        e["closed"].visible = closed
        e["happy"].visible = happy
        e["brow"].texture = load(FACE_DIR + "eyebrow_" + brow_type + ".png")
    for cheek in _cheeks:
        cheek.visible = bool(item.get("blush",false))
    if item.has("gaze"):
        var dest: Array = item["gaze"]
        set_gaze(Vector2(float(dest[0]),float(dest[1])))
    else:
        set_gaze(Vector2.ZERO)
    _update_closed_mouth(mouth_type)
    set_surface_heading(_surface_yaw)
    expression_changed.emit(id)

func _update_closed_mouth(mouth_type: String) -> void:
    if not is_instance_valid(_mouth):
        return
    _mouth.texture = load(FACE_DIR + "mouth_" + mouth_type + ".png")
    _mouth_nominal_scale = 0.61 if mouth_type in ["open","big_smile"] else 0.48

func _sample_lip_color(lip: Sprite2D) -> Color:
    # Sample the original approved lavender lip asset, rather than choosing a
    # mismatched hardcoded shade for the lateral connecting line.
    if lip.texture == null:
        return Color(0.70, 0.48, 0.82, 0.98)
    var img: Image = lip.texture.get_image()
    if img == null or img.is_empty():
        return Color(0.70, 0.48, 0.82, 0.98)
    var total := Color(0.0, 0.0, 0.0, 0.0)
    var count: float = 0.0
    for y in range(0, img.get_height(), 7):
        for x in range(0, img.get_width(), 7):
            var c: Color = img.get_pixel(x, y)
            if c.a > 0.35:
                total += Color(c.r, c.g, c.b, 0.0)
                count += 1.0
    if count < 1.0:
        return Color(0.70, 0.48, 0.82, 0.98)
    return Color(total.r/count, total.g/count, total.b/count, 0.98)

func _new_side_lip(part_name: String, tint: Color) -> Line2D:
    var line := Line2D.new()
    line.name = part_name
    line.width = 5.4
    line.default_color = tint
    line.antialiased = true
    line.joint_mode = Line2D.LINE_JOINT_ROUND
    line.begin_cap_mode = Line2D.LINE_CAP_ROUND
    line.end_cap_mode = Line2D.LINE_CAP_ROUND
    _jaw_root.add_child(line)
    return line

func _update_side_lips(open_eased: float) -> void:
    if not is_instance_valid(_side_lip_left) or not is_instance_valid(_side_lip_right):
        return
    # The anchors meet the genuine upper/lower PNG endpoints. The curved
    # segments stretch with the SAME lower-jaw motion, not separate animation.
    var top_y: float = lerpf(-11.0, -27.0, open_eased)
    var bottom_y: float = lerpf(-25.0, 49.0, open_eased)
    for side in range(2):
        var direction: float = -1.0 if side == 0 else 1.0
        var line: Line2D = _side_lip_left if side == 0 else _side_lip_right
        var p := PackedVector2Array()
        for i in range(13):
            var u: float = float(i) / 12.0
            var y: float = lerpf(top_y, bottom_y, u)
            var bow: float = sin(PI * u) * 7.0 * open_eased
            var x: float = direction * (61.0 + bow)
            p.append(Vector2(x, y))
        line.points = p
        # Fade the small sides as the original mouth closes. Their stroke is
        # always below both lip PNGs and never drawn on top of the enamel.
        line.modulate.a = smoothstep(0.03, 0.30, jaw_open)

func _apply_continuous_mouth_visibility(front_depth: float) -> void:
    if not is_instance_valid(_mouth) or not is_instance_valid(_jaw_root):
        return
    # Old rig snapped visibility at 0.025 jaw opening: it looked like a new
    # frame. Blend the closed-mouth expression and original open jaw instead.
    var blend: float = smoothstep(0.015, 0.25, jaw_open)
    _mouth.modulate.a = 1.0 - blend
    _jaw_root.modulate.a = blend
    var frontal: bool = front_depth > 0.07
    _mouth.visible = frontal and blend < 0.999
    _jaw_root.visible = frontal and blend > 0.001

func _build_png_lip_clips() -> void:
    _upper_lip_clip.polygon = _clip_from_real_lip(_upper_lip, true)
    _lower_lip_clip.polygon = _clip_from_real_lip(_lower_lip, false)

func _clip_from_real_lip(lip: Sprite2D, is_upper: bool) -> PackedVector2Array:
    var boundary := PackedVector2Array()
    var texture: Texture2D = lip.texture
    if texture == null:
        push_error("Bubble dental: original lip PNG is missing")
        return boundary
    var img: Image = texture.get_image()
    if img == null or img.is_empty():
        push_error("Bubble dental: lip PNG cannot be read")
        return boundary
    var w: int = img.get_width()
    var h: int = img.get_height()
    # Rendered lip PNGs cover about +/-60 units, with a small shape margin.
    # The mask clips tooth enamel on the INTERNAL side of each real lip edge.
    var half_width: float = 60.0
    var columns: int = 60
    var fallback_y: float = -31.0 if is_upper else 57.0
    for step in range(columns + 1):
        var x: float = -half_width + 2.0 * float(step)
        var pixel_x: int = clampi(int(round((x - lip.position.x) / lip.scale.x + float(w) * 0.5)), 0, w - 1)
        var edge_pixel: int = -1 if is_upper else h
        for py in range(h):
            if img.get_pixel(pixel_x, py).a >= 0.38:
                if is_upper:
                    edge_pixel = maxi(edge_pixel, py)  # bottom of upper lip
                else:
                    edge_pixel = mini(edge_pixel, py)  # top of lower lip
        var lip_y: float = fallback_y
        if (is_upper and edge_pixel >= 0) or (not is_upper and edge_pixel < h):
            lip_y = lip.position.y + (float(edge_pixel) - float(h) * 0.5) * lip.scale.y
        # Thin inward bleed so no enamel can cross the visible PNG lip line.
        var inner_y: float = lip_y + (1.1 if is_upper else -1.1)
        boundary.append(Vector2(x, inner_y))
    if is_upper:
        boundary.append(Vector2(half_width, 92.0))
        boundary.append(Vector2(-half_width, 92.0))
    else:
        boundary.append(Vector2(half_width, -92.0))
        boundary.append(Vector2(-half_width, -92.0))
    return boundary

func _update_native_mouth_shape(open_eased: float) -> void:
    if not is_instance_valid(_teeth_clip) or not is_instance_valid(_lip_contour):
        return
    # All mouth parts are CHILDREN OF ContinuousJawRig, so they track the
    # original face position, yaw and liquid body with zero new animation clip.
    var stretch: float = lerpf(0.087, 1.0, open_eased)
    var offset_y: float = lerpf(-18.0, 0.0, open_eased)
    var mouth_outline := PackedVector2Array()
    var inner_clip := PackedVector2Array()
    for i in range(25):
        var u: float = float(i) / 24.0
        var x: float = lerpf(-70.0, 70.0, u)
        var side: float = pow(absf(x) / 70.0, 2.2)
        var top_y: float = -41.0 + 17.0 * side
        mouth_outline.append(Vector2(x, offset_y + top_y * stretch))
        var inner_x: float = x * 0.88
        inner_clip.append(Vector2(inner_x, offset_y + (top_y + 7.5) * stretch))
    for i in range(25):
        var u: float = float(i) / 24.0
        var x: float = lerpf(70.0, -70.0, u)
        var side: float = pow(absf(x) / 70.0, 2.2)
        var bottom_y: float = 63.0 - 23.0 * side
        mouth_outline.append(Vector2(x, offset_y + bottom_y * stretch))
        var inner_x: float = x * 0.88
        inner_clip.append(Vector2(inner_x, offset_y + (bottom_y - 9.0) * stretch))
    _mouth_fill.polygon = mouth_outline
    _lip_contour.points = mouth_outline
    _lip_contour.width = lerpf(5.0, 9.0, open_eased)
    _teeth_clip.polygon = inner_clip
    # A soft tongue inside the same silhouette, not a second mouth.
    var tongue := PackedVector2Array()
    var tongue_y: float = offset_y + 47.0 * stretch
    for j in range(33):
        var a: float = TAU * float(j) / 32.0
        tongue.append(Vector2(cos(a) * 36.0, tongue_y + sin(a) * 10.0 * stretch))
    _mouth_tongue.polygon = tongue
    _mouth_tongue.visible = open_eased > 0.3

func set_jaw_open(amount: float) -> void:
    jaw_open = clampf(amount,0.0,1.0)
    if not is_instance_valid(_jaw_root):
        return
    var eased: float = jaw_open * jaw_open * (3.0 - 2.0 * jaw_open)
    # Never swap mouth frames at 2.5% opening.
    # The existing set_surface_heading() call below crossfades both.
    # Jaw is one smooth continuous animation — no texture frame switching.
    _cavity.scale = Vector2(0.52, lerpf(0.045,0.52,eased))
    _cavity.position.y = lerpf(-18.0,0.0,eased)
    _lower_jaw.position.y = lerpf(-94.0,0.0,eased)
    # Lower teeth inherit the animated LowerJaw transform directly.
    _upper_teeth.position.y = lerpf(34.0,0.0,eased)
    _upper_teeth.modulate.a = clampf((jaw_open-0.10)/0.25,0.0,1.0)
    _lower_teeth.modulate.a = _upper_teeth.modulate.a
    # MIKA_BUBBLE_FACERIG_DENTAL_V8_4_2
    # Follow the original PNG lip curves with the ACTUAL face-rig teeth.
    # Upper lip arcs upward at center; lower lip arcs downward at center.
    # All plaque PNGs remain children of the original tooth Sprite2Ds.
    for i in range(5):
        var side: float = pow(absf(float(TEETH_X[i])) / 46.0, 2.0)
        var upper: Node2D = _upper_teeth.get_node_or_null("U%d" % (i + 1)) as Node2D
        var lower: Node2D = _lower_teeth.get_node_or_null("L%d" % (i + 1)) as Node2D
        if upper != null:
            # Return to the original short, rounded PNG tooth: no stretching.
            # 10 percent UP relative to the approved v8.4.2 jaw arc.
            var old_upper_y: float = -26.0 + eased * 8.0 * side
            upper.position.y = old_upper_y * (1.0 + 0.10 * eased)
            # Only widen the ORIGINAL PNG enough for a near-zero gap.
            upper.scale = Vector2(lerpf(0.30, 0.38, eased), 0.30)
        if lower != null:
            # 15 percent DOWN on outer teeth, 10 percent on neighbours,
            # and 5 percent on the middle tooth. Keep the old arc.
            var old_lower_y: float = 27.0 + eased * (28.0 - 20.0 * side)
            var offset_ratio: float = 0.05 if i == 2 else (0.15 if i == 0 or i == 4 else 0.10)
            lower.position.y = old_lower_y * (1.0 + offset_ratio * eased)
            lower.scale = Vector2(lerpf(0.30, 0.38, eased), 0.30)
    _upper_lip.position.y = lerpf(28.0,0.0,eased)
    _upper_lip_clip.position.y = _upper_lip.position.y
    _lower_lip.position.y = lerpf(5.0,0.0,eased)
    _lower_lip_clip.position.y = _lower_lip.position.y
    _update_side_lips(eased)
    # Shape opening is preserved during a surface turn by reprojecting jaw.
    set_surface_heading(_surface_yaw)

func animate_jaw(target: float, duration: float = 0.45) -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_method(Callable(self,"set_jaw_open"), jaw_open, clampf(target,0.0,1.0), duration)

func set_brushing_mode(enabled: bool) -> void:
    _brush_mode = enabled
    if enabled:
        set_expression("calm")
        animate_jaw(1.0,0.55)
    else:
        animate_jaw(0.0,0.45)

func set_gaze(direction: Vector2) -> void:
    gaze = direction.clamp(Vector2(-1.0,-1.0),Vector2(1.0,1.0))
    for e in _eyes:
        var shift := Vector2(gaze.x * 8.0,gaze.y * 7.0)
        e["iris"].position = shift
        e["glint"].position = shift

func blink() -> void:
    if _blinking:
        return
    _blinking = true
    for e in _eyes:
        var root: Node2D = e["root"]
        var t := create_tween()
        t.tween_property(root,"scale:y",0.06,0.09).set_trans(Tween.TRANS_SINE)
        t.tween_property(root,"scale:y",1.0,0.14).set_trans(Tween.TRANS_BACK)
    await get_tree().create_timer(0.26).timeout
    _blinking = false

func reset_plaque() -> void:
    _plaque_total = 0.0
    _plaque_removed = 0.0
    for item in _plaque_layers:
        var img: Image = item["base"].duplicate()
        var tex: ImageTexture = ImageTexture.create_from_image(img)
        item["image"] = img
        item["texture"] = tex
        var node: Sprite2D = item["node"]
        node.texture = tex
        for y in range(img.get_height()):
            for x in range(img.get_width()):
                _plaque_total += img.get_pixel(x,y).a
    brushing_progress_changed.emit(0.0)

func get_brushing_progress() -> float:
    return clampf(_plaque_removed / maxf(1.0,_plaque_total),0.0,1.0)

# MIKA v8.5.9.6.2: shower-style room dental scrubbing. One update per
# movement instead of dozens of per-pixel ImageTexture uploads per frame.
# Start each dental session with fully visible plaque masks.
# Older per-tooth fade logic changed Sprite2D.modulate.a, even when their
# underlying PNG image alpha was intact. Reset that layer without replacing
# the project's installed reset_plaque() implementation.
func brush_at(global_point: Vector2, brush_radius: float = 14.0) -> float:
    if jaw_open < 0.85:
        return get_brushing_progress()
    var changed_total: float = 0.0
    for item in _plaque_layers:
        var plaque: Sprite2D = item["node"]
        var img: Image = item["image"]
        var pixel_center: Vector2 = plaque.to_local(global_point) + Vector2(img.get_width(),img.get_height())*0.5
        var scl: float = maxf(plaque.global_transform.get_scale().x,0.01)
        var radius: float = brush_radius/scl
        if pixel_center.x < -radius or pixel_center.y < -radius or pixel_center.x > img.get_width()+radius or pixel_center.y > img.get_height()+radius:
            continue
        var min_x: int = maxi(0, int(floor(pixel_center.x-radius)))
        var max_x: int = mini(img.get_width()-1,int(ceil(pixel_center.x+radius)))
        var min_y: int = maxi(0, int(floor(pixel_center.y-radius)))
        var max_y: int = mini(img.get_height()-1,int(ceil(pixel_center.y+radius)))
        var locally_changed: bool = false
        for py in range(min_y,max_y+1):
            for px in range(min_x,max_x+1):
                var distance: float = Vector2(float(px),float(py)).distance_to(pixel_center)
                if distance >= radius:
                    continue
                var c: Color = img.get_pixel(px,py)
                if c.a < 0.002:
                    continue
                var falloff: float = clampf((radius-distance)/maxf(1.0,radius*0.7),0.0,1.0)
                var old_alpha: float = c.a
                c.a *= 1.0 - 0.89*falloff
                changed_total += old_alpha-c.a
                img.set_pixel(px,py,c)
                locally_changed = true
        if locally_changed:
            var texture: ImageTexture = item["texture"]
            texture.update(img)
    if changed_total > 0.0:
        _plaque_removed += changed_total
        brushing_progress_changed.emit(get_brushing_progress())
    return get_brushing_progress()

func _process(delta: float) -> void:
    if not automatic_blink or _blinking or current_expression in ["sleeping","uncomfortable","strained"]:
        return
    _blink_remaining -= delta
    if _blink_remaining <= 0.0:
        _blink_remaining = randf_range(2.6,5.8)
        blink()
