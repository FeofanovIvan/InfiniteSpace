extends Node2D
class_name RotatingSun2D

const SUN_BODY_SHADER: Shader = preload("res://solar/sun/sun_body.gdshader")
const SUN_CORONA_SHADER: Shader = preload("res://solar/sun/sun_corona.gdshader")
const SUN_TEXTURE: Texture2D = preload("res://solar/sun/sun_surface_1536x768.png")
const SUN_FLOW: Texture2D = preload("res://solar/sun/sun_plasma_flow_512x256.png")

var _surface_diameter: float = 186.0
var _corona_diameter: float = 300.0
var _rotation_seconds: float = 28.0
var _differential: float = 0.28
var _activity: float = 0.26
var _tint: Color = Color.WHITE
var _corona_strength: float = 0.85

var _corona: ColorRect
var _surface: ColorRect
var _corona_mat: ShaderMaterial
var _surface_mat: ShaderMaterial

func _ready() -> void:
	_build_once()
	_apply_visuals()

func set_surface_diameter(px: float) -> void:
	_surface_diameter = maxf(48.0, px)
	if is_node_ready():
		_apply_visuals()

func set_corona_diameter(px: float) -> void:
	_corona_diameter = maxf(_surface_diameter + 10.0, px)
	if is_node_ready():
		_apply_visuals()

func set_rotation_period(seconds: float) -> void:
	_rotation_seconds = maxf(4.0, absf(seconds))
	if _surface_mat != null:
		_surface_mat.set_shader_parameter("rotation_seconds", _rotation_seconds)

func set_activity(value: float) -> void:
	_activity = clampf(value, 0.0, 1.0)
	if _surface_mat != null:
		_surface_mat.set_shader_parameter("activity", _activity)

func set_differential(value: float) -> void:
	_differential = clampf(value, 0.0, 0.40)
	if _surface_mat != null:
		_surface_mat.set_shader_parameter("differential", _differential)

func set_corona_strength(value: float) -> void:
	_corona_strength = clampf(value, 0.0, 2.0)
	if _corona_mat != null:
		_corona_mat.set_shader_parameter("corona_strength", _corona_strength)

func set_tint(color: Color) -> void:
	_tint = color
	if is_node_ready():
		_apply_tint()

func _build_once() -> void:
	if _corona != null and _surface != null:
		return
	_corona = ColorRect.new()
	_corona.name = "Corona"
	_corona.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corona_mat = ShaderMaterial.new()
	_corona_mat.shader = SUN_CORONA_SHADER
	_corona.material = _corona_mat
	add_child(_corona)

	_surface = ColorRect.new()
	_surface.name = "Surface"
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface_mat = ShaderMaterial.new()
	_surface_mat.shader = SUN_BODY_SHADER
	_surface_mat.set_shader_parameter("surface_tex", SUN_TEXTURE)
	_surface_mat.set_shader_parameter("plasma_flow", SUN_FLOW)
	_surface.material = _surface_mat
	add_child(_surface)

func _apply_visuals() -> void:
	if _corona == null or _surface == null:
		return
	_corona.size = Vector2.ONE * _corona_diameter
	_corona.position = -_corona.size * 0.5
	_corona_mat.set_shader_parameter("solar_radius", _surface_diameter / _corona_diameter)
	_corona_mat.set_shader_parameter("corona_strength", _corona_strength)
	_surface.size = Vector2.ONE * _surface_diameter
	_surface.position = -_surface.size * 0.5
	_surface_mat.set_shader_parameter("rotation_seconds", _rotation_seconds)
	_surface_mat.set_shader_parameter("differential", _differential)
	_surface_mat.set_shader_parameter("activity", _activity)
	_apply_tint()

func _apply_tint() -> void:
	if _corona == null or _surface == null:
		return
	var surface_tint: Color = Color(
		clampf(0.72 + _tint.r * 0.45, 0.0, 1.0),
		clampf(0.58 + _tint.g * 0.40, 0.0, 1.0),
		clampf(0.48 + _tint.b * 0.25, 0.0, 1.0),
		1.0
	)
	var corona_tint: Color = Color(
		clampf(0.65 + _tint.r * 0.50, 0.0, 1.0),
		clampf(0.40 + _tint.g * 0.45, 0.0, 1.0),
		clampf(0.18 + _tint.b * 0.35, 0.0, 1.0),
		1.0
	)
	_surface.modulate = surface_tint
	_corona.modulate = corona_tint
