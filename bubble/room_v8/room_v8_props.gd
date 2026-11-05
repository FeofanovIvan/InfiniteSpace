extends Node2D
## Visual room v8 bridge for the EXISTING Bubble Care scene.
## NEVER instantiates BubbleWalker; preserves the approved character and face rig.
# MIKA_ROOM_V8_2_FEED_FLIGHT
const ROOT := "res://bubble/room_v8/"
const FX_SCRIPT := preload("res://bubble/room_v8/CareObjectFX.gd")
const KEYS: Array[String] = ["shower", "grooming", "feeder", "drinker", "bed"]
const MAP: Dictionary = {"shower":"shower", "mirror":"grooming", "food":"feeder", "water":"drinker", "bed":"bed"}
var stations: Dictionary = {}
var effect_nodes: Dictionary = {}
var debug_zones: bool = false

func _ready() -> void:
    var geo_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "world_geometry.json"))
    var zones_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "interaction_zones.json"))
    if not (geo_raw is Dictionary) or not (zones_raw is Dictionary):
        push_error("Bubble room v8: invalid geometry JSON")
        return
    var geos: Dictionary = geo_raw.get("stations", {})
    var zones: Dictionary = zones_raw.get("stations", {})
    for key in KEYS:
        if not geos.has(key) or not zones.has(key):
            push_error("Bubble room v8: station missing: " + key)
            continue
        var g: Dictionary = geos[key]
        var zone: Dictionary = zones[key]
        var parent := Node2D.new()
        parent.name = key.capitalize() + "Station"
        add_child(parent)
        var tex: Texture2D = load(ROOT + "assets/" + key + ".png")
        if tex == null:
            push_error("Bubble room v8 texture missing: " + key)
            continue
        var pos := Vector2(float(g["position"][0]), float(g["position"][1]))
        var s := float(g["scale"])
        var sprite := Sprite2D.new()
        sprite.name = "Object"
        sprite.texture = tex
        sprite.centered = false
        sprite.position = pos
        sprite.scale = Vector2.ONE * s
        sprite.z_index = 3
        parent.add_child(sprite)
        var fx: Node2D = FX_SCRIPT.new()
        fx.name = "FX"
        fx.set("station_kind", key)
        fx.position = pos
        fx.scale = Vector2.ONE * s
        fx.z_index = 5
        parent.add_child(fx)
        var a: Array = zone["action_local"]
        var m: Array = zone.get("mouth_contact_local", a)
        fx.call("set_action_anchors", Vector2(float(a[0]), float(a[1])), Vector2(float(m[0]), float(m[1])))
        effect_nodes[key] = fx
        # Front layers contain ONLY the real front rim; original full overlays
        # incorrectly occluded Bubble inside a pod/shower.
        if key == "shower" or key == "bed" or key == "feeder":
            var front: Texture2D = load(ROOT + "assets/" + key + "_lip.png")
            if front != null:
                var lip := Sprite2D.new()
                lip.name = "ForegroundLip"
                lip.texture = front
                lip.centered = false
                lip.position = pos
                lip.scale = Vector2.ONE * s
                lip.z_index = 12 if key != "feeder" else 6
                parent.add_child(lip)
        stations[key] = g

func station_for_action(id: String) -> String:
    return str(MAP.get(id, ""))

func point(action_id: String, which: String) -> Vector2:
    var station: String = station_for_action(action_id)
    if not stations.has(station):
        return Vector2(836.0, 600.0)
    var g: Dictionary = stations[station]
    var p: Array = g.get(which, g["approach"])
    return Vector2(float(p[0]), float(p[1]))

func zoom(action_id: String) -> float:
    var key := station_for_action(action_id)
    if not stations.has(key):
        return 1.7
    return float(stations[key]["zoom"])

func blocked_rects() -> Array[Rect2]:
    var result: Array[Rect2] = []
    for key in KEYS:
        if not stations.has(key):
            continue
        var r: Array = stations[key]["blocking_rect"]
        result.append(Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])))
    return result

func set_action_fx(action_id: String, enabled: bool) -> void:
    var key := station_for_action(action_id)
    if not effect_nodes.has(key):
        return
    var fx: Node2D = effect_nodes[key]
    if enabled:
        if key == "feeder" or not bool(fx.get("active")):
            fx.call("perform_action")
    else:
        fx.call("stop_action")

func stop_all_fx() -> void:
    for key in effect_nodes:
        # Drinker's stream is driven continuously, independently of "active".
        effect_nodes[key].call("stop_action")

func feeding_phase() -> String:
    if not effect_nodes.has("feeder"):
        return "empty"
    return str(effect_nodes["feeder"].get("_feed_phase"))

func set_debug_zones(visible_now: bool) -> void:
    debug_zones = visible_now
    queue_redraw()

func _draw() -> void:
    if not debug_zones:
        return
    for key in KEYS:
        if not stations.has(key):
            continue
        var g: Dictionary = stations[key]
        var ap := Vector2(float(g["approach"][0]), float(g["approach"][1]))
        var action := Vector2(float(g["activity"][0]), float(g["activity"][1]))
        var mouth := Vector2(float(g["mouth"][0]), float(g["mouth"][1]))
        if key == "shower" or key == "bed":
            var side: float = -48.0 if key == "shower" else 52.0
            var top_y: float = minf(ap.y,action.y)-82.0
            var lift := Vector2(ap.x+side*0.48,top_y+18.0)
            var cruise := Vector2(action.x+side*0.22,top_y)
            draw_polyline(PackedVector2Array([ap,lift,cruise,action]), Color(1.0,0.70,0.18,0.96), 2.8, true)
            draw_circle(lift,5.0,Color(1.0,0.74,0.34,0.94),true)
            draw_circle(cruise,5.0,Color(1.0,0.74,0.34,0.94),true)
        else:
            draw_line(ap, action, Color(1.0, 0.65, 0.24, 0.90), 2.5, true)
        draw_circle(ap, 8.0, Color(1.0, 0.59, 0.19, 0.95), true)
        draw_circle(action, 7.0, Color(0.19, 1.0, 0.92, 0.98), true)
        if mouth.distance_to(action) > 2.0:
            draw_line(action, mouth, Color(0.86, 0.65, 1.0, 0.75), 1.8, true)
            draw_circle(mouth, 5.0, Color(0.86, 0.65, 1.0, 0.9), true)
