extends RefCounted
## Continuous organic hyphal web: connected spanning tree + anastomotic loops
## + real blind tips, all passages permanently open. No gaps/bridges.

const CORE_COUNT: int = 106
const MOUTH_COUNT: int = 7

static func make(seed_value: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var points := PackedVector2Array()
    var links: Array[Dictionary] = []
    var entrances: Array[int] = []
    var exits: Array[int] = []
    var tries: int = 0
    while points.size() < CORE_COUNT and tries < 13000:
        tries += 1
        var x: float = rng.randf_range(0.075, 0.925)
        var y: float = rng.randf_range(0.095, 0.905)
        # Uneven rhizomorphic density, not a uniform lattice.
        var modulation: float = 0.52 + 0.48 * sin(13.5 * x + 3.7 * sin(y * 13.0))
        if rng.randf() > modulation * 0.80 + 0.20:
            continue
        var p := Vector2(x, y)
        var valid: bool = true
        for old in points:
            if Vector2((p.x-old.x) * 1.25, p.y-old.y).length_squared() < 0.036 * 0.036:
                valid = false
                break
        if valid:
            points.append(p)
    # Every vertex is attached to an earlier one. This guarantees one component.
    for i in range(1, points.size()):
        var near: int = 0
        var best: float = INF
        for j in range(i):
            var d: float = _distance(points[i], points[j])
            if d < best:
                near = j
                best = d
        _add_link(links, i, near, "normal", rng)
    # Hyphal fusions create cycles and alternate routes without any missing link.
    for i in range(points.size()):
        var near_list: Array[Dictionary] = []
        for j in range(points.size()):
            if i == j or _has_link(links, i, j):
                continue
            var dist: float = _distance(points[i], points[j])
            if dist < 0.165:
                near_list.append({"id":j,"dist":dist})
        near_list.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a["dist"]) < float(b["dist"]))
        for k in range(mini(3, near_list.size())):
            var j: int = int(near_list[k]["id"])
            if _degree(links, i) < 5 and _degree(links, j) < 6 and rng.randf() < 0.44:
                _add_link(links, i, j, "normal", rng)
    # Seven real openings on each side, all attached to the same connected web.
    for k in range(MOUTH_COUNT):
        var yy: float = 0.115 + float(k) * 0.128 + rng.randf_range(-0.014, 0.014)
        var li: int = points.size()
        points.append(Vector2(0.024, yy))
        entrances.append(li)
        var attach_left: int = _closest_core(points, Vector2(0.080, yy))
        _add_link(links, li, attach_left, "mouth", rng)
        var ri: int = points.size()
        points.append(Vector2(0.976, yy + rng.randf_range(-0.013, 0.013)))
        exits.append(ri)
        var attach_right: int = _closest_core(points, Vector2(0.920, yy))
        _add_link(links, ri, attach_right, "mouth", rng)
    # Blind endings are real traversable fibers (walker turns back at the end).
    for k in range(43):
        var parent: int = rng.randi_range(0, CORE_COUNT - 1)
        var direction: Vector2 = Vector2.from_angle(rng.randf_range(-PI, PI))
        var tip: Vector2 = points[parent] + direction * rng.randf_range(0.027, 0.084)
        tip.x = clampf(tip.x, 0.04, 0.96)
        tip.y = clampf(tip.y, 0.06, 0.94)
        points.append(tip)
        _add_link(links, parent, points.size() - 1, "tip", rng)
    return {"nodes":points,"edges":links,"entrances":entrances,"exits":exits,"seed":seed_value,
        "start":entrances[rng.randi_range(0, entrances.size()-1)]}

static func _closest_core(points: PackedVector2Array, p: Vector2) -> int:
    var best_id: int = 0
    var best: float = INF
    for i in range(mini(CORE_COUNT,points.size())):
        var d: float = _distance(points[i],p)
        if d < best:
            best=d
            best_id=i
    return best_id

static func _distance(a: Vector2, b: Vector2) -> float:
    return Vector2((a.x-b.x)*1.20, a.y-b.y).length()

static func _degree(edges: Array[Dictionary], id: int) -> int:
    var count: int = 0
    for edge in edges:
        if int(edge["a"]) == id or int(edge["b"]) == id:
            count += 1
    return count

static func _has_link(edges: Array[Dictionary], a: int, b: int) -> bool:
    for edge in edges:
        if (int(edge["a"]) == a and int(edge["b"]) == b) or (int(edge["a"]) == b and int(edge["b"]) == a):
            return true
    return false

static func _add_link(edges: Array[Dictionary], a: int, b: int, kind: String, rng: RandomNumberGenerator) -> void:
    if a == b or _has_link(edges,a,b):
        return
    edges.append({"a":a,"b":b,"kind":kind,
        "bend":rng.randf_range(-0.17,0.17),"grain":rng.randf_range(0.0,TAU)})
