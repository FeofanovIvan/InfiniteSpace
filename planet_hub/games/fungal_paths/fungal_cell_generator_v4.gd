extends RefCounted
## Small, child-readable connected pentagon cells. Every level has a solution.
## Logical positions are normalized and share coordinates with future background art.
const CENTERS: Array[Vector2] = [
    Vector2(0.165, 0.315), Vector2(0.428, 0.310), Vector2(0.690, 0.315),
    Vector2(0.305, 0.720), Vector2(0.565, 0.720), Vector2(0.825, 0.710)
]
const CORNERS: Array[Vector2] = [
    Vector2(0.0, -0.127), Vector2(0.076, -0.043),
    Vector2(0.049, 0.110), Vector2(-0.049, 0.110), Vector2(-0.076, -0.043)
]

static func make(seed_value: int) -> Dictionary:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed_value
    var nodes: PackedVector2Array = PackedVector2Array()
    var edges: Array[Dictionary] = []
    var cells: Array[PackedInt32Array] = []
    for ci in range(CENTERS.size()):
        var center: Vector2 = CENTERS[ci] + Vector2(rng.randf_range(-0.010,0.010),rng.randf_range(-0.015,0.015))
        var ids: PackedInt32Array = PackedInt32Array()
        for corner in CORNERS:
            ids.append(nodes.size())
            nodes.append(center + corner)
        cells.append(ids)
        for k in range(5):
            _add_edge(edges,ids[k],ids[(k+1)%5],"cell")
    # Fixed corridors make the main route readable; extra connections add choices.
    var corridors: Array[Vector2i] = [
        Vector2i(_id(0,1),_id(1,4)),Vector2i(_id(1,1),_id(2,4)),
        Vector2i(_id(3,1),_id(4,4)),Vector2i(_id(4,1),_id(5,4)),
        Vector2i(_id(0,2),_id(3,0)),Vector2i(_id(1,3),_id(3,0)),
        Vector2i(_id(1,2),_id(4,0)),Vector2i(_id(2,3),_id(4,0)),
        Vector2i(_id(2,2),_id(5,0))
    ]
    for link in corridors:
        _add_edge(edges,link.x,link.y,"corridor")
    # A few optional cross-corridors keep repeated rounds different but solvable.
    if rng.randf() > 0.4:
        _add_edge(edges,_id(0,3),_id(3,4),"corridor")
    if rng.randf() > 0.4:
        _add_edge(edges,_id(3,2),_id(4,3),"corridor")
    if rng.randf() > 0.4:
        _add_edge(edges,_id(2,3),_id(5,4),"corridor")
    var entrances: Array[int] = []
    var exits: Array[int] = []
    for item in [
        {"p":Vector2(0.035,0.283),"to":_id(0,4)},
        {"p":Vector2(0.055,0.744),"to":_id(3,4)}
    ]:
        var index: int = nodes.size()
        nodes.append(item["p"])
        entrances.append(index)
        _add_edge(edges,index,int(item["to"]),"entrance")
    for item in [
        {"p":Vector2(0.945,0.277),"to":_id(2,1)},
        {"p":Vector2(0.967,0.492),"to":_id(2,2)},
        {"p":Vector2(0.956,0.747),"to":_id(5,1)}
    ]:
        var index: int = nodes.size()
        nodes.append(item["p"])
        exits.append(index)
        _add_edge(edges,index,int(item["to"]),"exit")
    # Three short side branches are visible, but they do not clutter the cells.
    for item in [
        {"p":Vector2(0.115,0.073),"to":_id(0,0)},
        {"p":Vector2(0.725,0.075),"to":_id(2,0)},
        {"p":Vector2(0.615,0.952),"to":_id(4,2)}
    ]:
        var index: int = nodes.size()
        nodes.append(item["p"])
        _add_edge(edges,index,int(item["to"]),"tip")
    return {"nodes":nodes,"edges":edges,"cells":cells,
        "entrances":entrances,"exits":exits,
        "start":entrances[rng.randi_range(0,entrances.size()-1)],
        "goal":exits[rng.randi_range(0,exits.size()-1)],"seed":seed_value}

static func _id(cell: int, corner: int) -> int:
    return cell*5+corner

static func _add_edge(edges: Array[Dictionary], a: int, b: int, kind: String) -> void:
    edges.append({"a":a,"b":b,"kind":kind})
