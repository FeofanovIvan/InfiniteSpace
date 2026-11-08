extends RefCounted
## Fungal Paths v5: one small solvable puzzle. Logic is independent of artwork.
## Coordinates are normalized within the rectangular game board.
const CENTERS: Array[Vector2] = [
    Vector2(0.085,0.55), Vector2(0.235,0.32), Vector2(0.385,0.54),
    Vector2(0.525,0.31), Vector2(0.660,0.54), Vector2(0.805,0.32),
    Vector2(0.930,0.55), Vector2(0.385,0.86), Vector2(0.665,0.86)
]
const LINKS: Array[Vector2i] = [
    Vector2i(0,1), Vector2i(1,2), Vector2i(2,3),
    Vector2i(3,4), Vector2i(4,5), Vector2i(5,6),
    Vector2i(2,7), Vector2i(4,8)
]
const PORT_COUNT: int = 5

static func make(seed_value: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var ports: Array[PackedInt32Array] = []
    for i in range(CENTERS.size()):
        ports.append(PackedInt32Array())
    var links: Array[Dictionary] = []
    for link in LINKS:
        var a: int = link.x
        var b: int = link.y
        var pa: int = _closest_free_side(CENTERS[b]-CENTERS[a],ports[a])
        var pb: int = _closest_free_side(CENTERS[a]-CENTERS[b],ports[b])
        var a_sides:PackedInt32Array=ports[a]
        a_sides.append(pa)
        ports[a]=a_sides
        var b_sides:PackedInt32Array=ports[b]
        b_sides.append(pb)
        ports[b]=b_sides
        links.append({"a":a,"b":b,"pa":pa,"pb":pb})
    var rotations := PackedInt32Array()
    rotations.resize(CENTERS.size())
    for i in range(CENTERS.size()):
        rotations[i]=0
    # Five selectable sections (1..5). The first starts connected so Bubble
    # visibly explores at least the start corridor immediately after loading.
    # Sections 2..5 need rotation; every challenge has a verified solution
    # at orientation 0 for all sections.
    rotations[1] = 0
    for i in range(2,6):
        rotations[i] = rng.randi_range(1,4)
    rotations[7] = 0
    rotations[8] = 0
    return {"centers":CENTERS.duplicate(),"links":links,"ports":ports,
        "rotations":rotations,"start":0,"goal":6,"seed":seed_value}

static func _closest_free_side(direction: Vector2, used: PackedInt32Array) -> int:
    var best:int=-1
    var lowest:float=INF
    var unit:Vector2=direction.normalized()
    for p in range(PORT_COUNT):
        if used.has(p):continue
        var d:Vector2=Vector2.RIGHT.rotated(-PI*0.5+TAU*float(p)/5.0)
        var score:float=1.0-unit.dot(d)
        if score<lowest:
            lowest=score
            best=p
    return best
