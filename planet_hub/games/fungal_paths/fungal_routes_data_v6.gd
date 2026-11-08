extends RefCounted
## Ten authored continuous routes, ten eligible junctions, four random turns.
## All coordinates are normalized; visual/touch geometry lives in the board.
const ATLAS_PATH: String = "res://planet_hub/games/fungal_paths/data/route_bank_v6.json"
const SLOT_COUNT: int = 5

static func _key(a: int, b: int) -> String:
    return "%d:%d" % [mini(a,b),maxi(a,b)]

static func _port_for(direction: Vector2, occupied: PackedInt32Array) -> int:
    var best: int = -1
    var best_score: float = -INF
    for port in range(SLOT_COUNT):
        if occupied.has(port): continue
        var axis: Vector2 = Vector2.RIGHT.rotated(-PI*0.5 + TAU*float(port)/5.0)
        var match_score: float = direction.normalized().dot(axis)
        if match_score > best_score:
            best_score = match_score
            best = port
    return best

static func make(seed_value: int) -> Dictionary:
    var atlas_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_PATH))
    if not atlas_raw is Dictionary: return {}
    var atlas: Dictionary = atlas_raw
    var coords: Array[Vector2] = []
    for raw in atlas.get("centers", []):
        coords.append(Vector2(float(raw[0]),float(raw[1])))
    var main_edges: Array[Vector2i] = []
    for item in atlas.get("base_links", []):
        main_edges.append(Vector2i(int(item[0]),int(item[1])))
    var bank: Array = atlas.get("route_bank", [])
    if bank.size() != 10 or coords.size() != 30: return {}
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var route_id: int = rng.randi_range(0, bank.size()-1)
    var route: Array[int] = []
    for index in bank[route_id]: route.append(int(index))
    var start: int = int(atlas.get("start",15))
    var goal: int = int(atlas.get("goal",4))
    if route.size() < 10 or route[0] != start or route[-1] != goal: return {}
    var candidate_ids: Array[int] = []
    for id in atlas.get("turn_candidates", []): candidate_ids.append(int(id))
    var eligible: Array[int] = []
    for idx in range(2,route.size()-1):
        if candidate_ids.has(route[idx]): eligible.append(route[idx])
    if eligible.size() < 4: return {}
    # Use a seeded Fisher-Yates to make the level reproducible.
    eligible.sort()
    for j in range(eligible.size()-1,0,-1):
        var k: int = rng.randi_range(0,j)
        var temp: int = eligible[j]
        eligible[j] = eligible[k]
        eligible[k] = temp
    var editable: Array[int] = eligible.slice(0,4)
    editable.sort()
    var adj: Dictionary = {}
    for i in range(coords.size()): adj[i]=[]
    for e in main_edges:
        (adj[e.x] as Array).append(e.y)
        (adj[e.y] as Array).append(e.x)
    var planned: Dictionary = {}
    var visited: Dictionary = {}
    var origin: Dictionary = {}
    for id in route:
        visited[id]=true
        origin[id]=id
    for index in range(route.size()-1):
        planned[_key(route[index],route[index+1])]=true
    # Attach short and long side arms without constructing shortcuts to the goal.
    # Never attach a new side branch through one of four editable junctions.
    var queue: Array[int] = route.duplicate()
    for i in range(queue.size()-1,0,-1):
        var j: int = rng.randi_range(0,i)
        var swap: int = queue[i]
        queue[i]=queue[j]
        queue[j]=swap
    var at: int=0
    while at<queue.size():
        var parent: int = queue[at]
        at+=1
        var ns: Array = (adj[parent] as Array).duplicate()
        for i in range(ns.size()-1,0,-1):
            var j: int = rng.randi_range(0,i)
            var tmp: Variant=ns[i]; ns[i]=ns[j];ns[j]=tmp
        for next_value in ns:
            var next: int=int(next_value)
            if visited.has(next):continue
            if editable.has(parent):continue
            planned[_key(parent,next)]=true
            visited[next]=true
            origin[next]=origin[parent]
            queue.append(next)
    # Include any remaining peripheral nodes only as dormant decorative strands.
    # Add occasional local loops on ONE branch, not bypasses between route roots.
    var loops: int=0
    for pair in main_edges:
        if loops >= 3:break
        var a: int=pair.x;var b: int=pair.y
        var key: String=_key(a,b)
        if planned.has(key) or not (visited.has(a) and visited.has(b)):continue
        if not route.has(a) and not route.has(b) and origin[a]==origin[b]:
            if rng.randf()<0.60:
                planned[key]=true
                loops+=1
    # Allocate a distinct five-directional socket for every atlas edge.
    var slots: Array[PackedInt32Array] = []
    var used_slots: Array[PackedInt32Array] = []
    for i in range(coords.size()):
        slots.append(PackedInt32Array())
        used_slots.append(PackedInt32Array())
    var edges: Array[Dictionary] = []
    for e in main_edges:
        var a: int=e.x;var b: int=e.y
        var pa: int=_port_for(coords[b]-coords[a],used_slots[a])
        var pb: int=_port_for(coords[a]-coords[b],used_slots[b])
        if pa<0 or pb<0:return {}
        var x: PackedInt32Array=used_slots[a];x.append(pa);used_slots[a]=x
        x=used_slots[b];x.append(pb);used_slots[b]=x
        var on: bool=planned.has(_key(a,b))
        edges.append({"a":a,"b":b,"pa":pa,"pb":pb,"planned":on})
        if on:
            x=slots[a];x.append(pa);slots[a]=x
            x=slots[b];x.append(pb);slots[b]=x
    var turns: PackedInt32Array=PackedInt32Array()
    turns.resize(coords.size())
    # Try random nonzero rotations; with a tree-rooted network the selected
    # four interruptions must keep the goal initially unreachable.
    var valid: bool=false
    for attempt in range(32):
        for id in editable:
            turns[id]=rng.randi_range(1,4)
        if not _can_reach(edges,slots,turns,start,goal):
            valid=true
            break
    if not valid: return {}
    return {"centers":coords,"edges":edges,"slots":slots,"rotations":turns,
        "route":route,"route_id":route_id,"editable":editable,
        "candidate_ids":candidate_ids,"start":start,"goal":goal,"seed":seed_value}

static func _can_reach(edges: Array[Dictionary],slots: Array[PackedInt32Array],turns: PackedInt32Array,start: int,goal: int) -> bool:
    var seen: Dictionary={start:true}
    var queue: Array[int]=[start]
    var k: int=0
    while k<queue.size():
        var curr: int=queue[k];k+=1
        if curr==goal:return true
        for e in edges:
            if not e["planned"]:continue
            var a: int=int(e["a"]);var b: int=int(e["b"])
            if curr!=a and curr!=b:continue
            var aslot: int=int(e["pa"]);var bslot: int=int(e["pb"])
            var open_a: bool=false;var open_b: bool=false
            for s in slots[a]:
                if posmod(int(s)+int(turns[a]),5)==aslot:open_a=true
            for s in slots[b]:
                if posmod(int(s)+int(turns[b]),5)==bslot:open_b=true
            if not (open_a and open_b):continue
            var nxt: int=b if curr==a else a
            if not seen.has(nxt):
                seen[nxt]=true;queue.append(nxt)
    return false
