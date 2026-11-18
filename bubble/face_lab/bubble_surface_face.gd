extends "res://bubble/scripts/bubble_face.gd"
## Experimental face attachment: 3D virtual ellipsoid sockets on the ORIGINAL
## shader-rendered Bubble body. Does not edit the production FaceRig.
## Positions are in the original FaceRig's 800x650 local coordinate system.

var eye_spacing: float = 86.0
var eye_height: float = -36.0
var mouth_height: float = 88.0
var eye_size: float = 1.0
var mouth_size: float = 1.0
var pitch_degrees: float = 0.0
var surface_width: float = 193.0
var surface_height: float = 205.0
var show_sockets: bool = true

const VISIBILITY_THRESHOLD: float = 0.055
var _marker_rings: Array[Line2D] = []

func _ready() -> void:
	super._ready()
	# Markers are added LAST, above the rendered eye/mouth sprites.
	# Drawing markers from this parent's _draw would place them behind the face.
	for index in range(3):
		var ring := Line2D.new()
		ring.name = "SocketEyeLeft" if index == 0 else ("SocketEyeRight" if index == 1 else "SocketMouth")
		ring.width = 2.5
		ring.antialiased = true
		ring.default_color = Color("6ffff0") if index < 2 else Color("ffce80")
		for step in range(33):
			var radians: float = TAU * float(step) / 32.0
			ring.add_point(Vector2(cos(radians), sin(radians)) * 11.0)
		ring.z_index = 3
		add_child(ring)
		_marker_rings.append(ring)
	set_surface_heading(_surface_yaw)

func set_lab_calibration(settings: Dictionary) -> void:
	eye_spacing = clampf(float(settings.get("eye_spacing", eye_spacing)), 48.0, 130.0)
	eye_height = clampf(float(settings.get("eye_height", eye_height)), -90.0, -5.0)
	mouth_height = clampf(float(settings.get("mouth_height", mouth_height)), 30.0, 130.0)
	eye_size = clampf(float(settings.get("eye_size", eye_size)), 0.60, 1.30)
	mouth_size = clampf(float(settings.get("mouth_size", mouth_size)), 0.60, 1.35)
	pitch_degrees = clampf(float(settings.get("pitch", pitch_degrees)), -35.0, 35.0)
	surface_width = clampf(float(settings.get("surface_width", surface_width)), 160.0, 230.0)
	show_sockets = bool(settings.get("show_sockets", show_sockets))
	set_surface_heading(_surface_yaw)


func _project_socket(x: float, y: float, yaw: float) -> Dictionary:
	# Each feature occupies a real point on the FRONT of a virtual ellipsoid.
	# Rotating its 3D position and normal moves it over the silhouette.
	var nx: float = clampf(x / surface_width, -0.93, 0.93)
	var ny: float = clampf(y / surface_height, -0.93, 0.93)
	var nz: float = sqrt(maxf(0.0001, 1.0 - nx * nx - ny * ny))
	var cx: float = cos(yaw)
	var sx: float = sin(yaw)
	var turned_x: float = nx * cx + nz * sx
	var turned_z: float = nz * cx - nx * sx
	var pitch: float = deg_to_rad(pitch_degrees)
	var cp: float = cos(pitch)
	var sp: float = sin(pitch)
	var turned_y: float = ny * cp - turned_z * sp
	var final_z: float = ny * sp + turned_z * cp
	return {"position": Vector2(turned_x * surface_width, turned_y * surface_height),
		"depth": final_z}


func set_surface_heading(heading_rad: float) -> void:
	_surface_yaw = wrapf(heading_rad, -PI, PI)
	# The parent FaceRig calls this method during _ready and during jaw changes.
	if _eyes.is_empty() or not is_instance_valid(_mouth):
		return
	for i in range(_eyes.size()):
		var x: float = -eye_spacing if i == 0 else eye_spacing
		var placement: Dictionary = _project_socket(x, eye_height, _surface_yaw)
		var depth: float = float(placement["depth"])
		var socket: Node2D = _eyes[i]["root"] as Node2D
		socket.position = placement["position"]
		# Project the local surface normal into view: disappear behind the body,
		# narrow naturally around the profile (without flipping the eye image).
		socket.scale = Vector2(eye_size * maxf(depth, 0.06), eye_size * clampf(0.83 + 0.17 * depth, 0.62, 1.0))
		socket.rotation = -0.07 * sin(_surface_yaw + x / surface_width)
		socket.visible = depth > VISIBILITY_THRESHOLD
	for i in range(_cheeks.size()):
		var x: float = -162.0 if i == 0 else 162.0
		var placement: Dictionary = _project_socket(x, 74.0, _surface_yaw)
		var depth: float = float(placement["depth"])
		var cheek: Sprite2D = _cheeks[i]
		cheek.position = placement["position"]
		cheek.scale = Vector2(0.55 * maxf(depth, 0.06), 0.55)
		cheek.visible = depth > 0.10 and bool(presets.get(current_expression, {}).get("blush", false))
	var mouth_socket: Dictionary = _project_socket(0.0, mouth_height, _surface_yaw)
	var mouth_depth: float = float(mouth_socket["depth"])
	var visible_from_front: bool = mouth_depth > VISIBILITY_THRESHOLD
	_mouth.position = mouth_socket["position"]
	_mouth.scale = Vector2(_mouth_nominal_scale * mouth_size * maxf(mouth_depth, 0.06), _mouth_nominal_scale * mouth_size)
	_mouth.rotation = -0.035 * sin(_surface_yaw)
	_mouth.visible = jaw_open <= 0.025 and visible_from_front
	_jaw_root.position = mouth_socket["position"]
	var jaw_blend: float = jaw_open * jaw_open * (3.0 - 2.0 * jaw_open)
	_jaw_root.scale = Vector2(lerpf(0.74, 1.0, jaw_blend) * mouth_size * maxf(mouth_depth, 0.06), mouth_size)
	_jaw_root.rotation = -0.035 * sin(_surface_yaw)
	_jaw_root.visible = jaw_open > 0.025 and visible_from_front
	for sprite in _curved_sprites:
		var material: ShaderMaterial = sprite.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("side_bend", sin(_surface_yaw) * 0.60)
	# Real overlay nodes preserve visibility even when an eye/mouth sprite covers
	# the socket center. The markers themselves rotate and hide with the face.
	if _marker_rings.size() == 3:
		var anchors: Array[Vector2] = [
			Vector2(-eye_spacing, eye_height), Vector2(eye_spacing, eye_height),
			Vector2(0.0, mouth_height)
		]
		for index in range(3):
			var projected: Dictionary = _project_socket(anchors[index].x, anchors[index].y, _surface_yaw)
			_marker_rings[index].position = projected["position"]
			_marker_rings[index].visible = show_sockets and float(projected["depth"]) > VISIBILITY_THRESHOLD
