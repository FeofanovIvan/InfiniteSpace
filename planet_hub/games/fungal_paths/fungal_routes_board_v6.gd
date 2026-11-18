extends Control
## All rendered channels and Bubble motion share the EXACT same sampled curves.
## Four selectable rotors per level; 10 authored routes over 10 possible rotors.
signal junction_selected(id: int)
signal junction_rotated(id: int)
const BASE := Color("#0a2028")
const ROOT := Color("#153b3b")
const RIM := Color("#214d44")
const CHANNEL := Color("#5edbb5")
const EDGE_GLOW := Color("#a2ffcf")
const ROTOR := Color("#a9edbb")
const SELECT := Color("#fff3a6")

var centers: Array[Vector2] = []
var edges: Array[Dictionary] = []
var slots: Array[PackedInt32Array] = []
var rotations: PackedInt32Array = PackedInt32Array()
var editable: Array[int] = []
var candidate_ids: Array[int] = []
var start: int=15
var goal: int=4
var selected: int=-1
var visited_edges: Dictionary={}
var ghost_path: PackedVector2Array=PackedVector2Array()
var _radius: float=28.0
var _seed: int=0
var _clock: float=0.0

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_STOP
    resized.connect(_relayout)
    _relayout()

func _relayout() -> void:
    _radius=clampf(minf(size.x*0.0245,size.y*0.060),14.0,39.0)
    queue_redraw()

func configure(level: Dictionary) -> void:
    centers=level.get("centers",[]).duplicate()
    edges=level.get("edges",[]).duplicate(true)
    slots=level.get("slots",[]).duplicate(true)
    rotations=level.get("rotations",PackedInt32Array()).duplicate()
    editable=level.get("editable",[]).duplicate()
    candidate_ids=level.get("candidate_ids",[]).duplicate()
    start=int(level.get("start",15))
    goal=int(level.get("goal",4))
    selected=editable[0] if editable.size()>0 else -1
    visited_edges.clear()
    ghost_path=PackedVector2Array()
    _seed=int(level.get("seed",1))
    _relayout()

func point_for(id: int) -> Vector2:
    if id<0 or id>=centers.size():return Vector2.ZERO
    return Vector2(centers[id].x*size.x,centers[id].y*size.y)

func tile_radius() -> float:
    return _radius

func _slot_direction(slot: int) -> Vector2:
    return Vector2.RIGHT.rotated(-PI*0.5+TAU*float(posmod(slot,5))/5.0)

func _port_point(id: int,slot: int) -> Vector2:
    return point_for(id)+_slot_direction(slot)*_radius*0.93

func _has_port(id: int,slot: int) -> bool:
    if id<0 or id>=slots.size():return false
    for raw in slots[id]:
        if posmod(int(raw)+int(rotations[id]),5)==slot:return true
    return false

func is_edge_open(a: int,b: int) -> bool:
    for e in edges:
        var from_id: int=int(e["a"]);var to_id: int=int(e["b"])
        if ((a==from_id and b==to_id) or (a==to_id and b==from_id)) and bool(e["planned"]):
            return _has_port(from_id,int(e["pa"])) and _has_port(to_id,int(e["pb"]))
    return false

func active_neighbors(id: int) -> Array[int]:
    var result: Array[int]=[]
    for e in edges:
        if not bool(e["planned"]):continue
        var a: int=int(e["a"]);var b: int=int(e["b"])
        if id==a and is_edge_open(a,b):result.append(b)
        elif id==b and is_edge_open(a,b):result.append(a)
    return result

func path_to(from_id: int,to_id: int) -> Array[int]:
    if from_id<0 or from_id>=centers.size():return []
    var previous: Dictionary={from_id:-1}
    var queue: Array[int]=[from_id]
    var i: int=0
    while i<queue.size():
        var curr: int=queue[i]
        i+=1
        if curr==to_id:break
        for next_id in active_neighbors(curr):
            if previous.has(next_id):continue
            previous[next_id]=curr
            queue.append(next_id)
    if not previous.has(to_id):return []
    var route: Array[int]=[]
    var index: int=to_id
    while index>=0:
        route.push_front(index)
        index=int(previous[index])
    return route

func solved() -> bool:
    return path_to(start,goal).size()>1

func rotate_selected(direction: int) -> void:
    if not editable.has(selected):return
    rotations[selected]=posmod(int(rotations[selected])+direction,5)
    queue_redraw()
    junction_rotated.emit(selected)

func select_junction(id: int) -> void:
    if not editable.has(id):return
    selected=id
    queue_redraw()
    junction_selected.emit(id)

func _gui_input(event: InputEvent) -> void:
    var tapped: bool=false
    var tap: Vector2=Vector2.ZERO
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
        tapped=true;tap=event.position
    elif event is InputEventScreenTouch and event.pressed:
        tapped=true;tap=event.position
    if not tapped:return
    for id in editable:
        if tap.distance_to(point_for(id)) <= maxf(_radius*1.36,27.0):
            select_junction(id)
            accept_event()
            return

func _cubic(a:Vector2,b:Vector2,c:Vector2,d:Vector2,t:float) -> Vector2:
    var inv:float=1.0-t
    return a*(inv*inv*inv)+b*(3.0*inv*inv*t)+c*(3.0*inv*t*t)+d*(t*t*t)

func _outer_curve(e:Dictionary) -> PackedVector2Array:
    var a:int=int(e["a"]);var b:int=int(e["b"])
    var da:Vector2=_slot_direction(int(e["pa"]))
    var db:Vector2=_slot_direction(int(e["pb"]))
    var p:Vector2=_port_point(a,int(e["pa"]))
    var q:Vector2=_port_point(b,int(e["pb"]))
    var span:float=p.distance_to(q)
    var ctrl_len:float=minf(span*0.31,_radius*1.72)
    var bend:float=minf(span*0.095,_radius*0.53)
    var sign_value:float=1.0 if (a*7+b*11)%2==0 else -1.0
    var perpendicular:Vector2=(q-p).orthogonal().normalized()*bend*sign_value
    var c1:Vector2=p+da*ctrl_len+perpendicular
    var c2:Vector2=q+db*ctrl_len+perpendicular
    var points:PackedVector2Array=PackedVector2Array()
    for step in range(13):
        points.append(_cubic(p,c1,c2,q,float(step)/12.0))
    return points

func edge_points(a:int,b:int) -> PackedVector2Array:
    for e in edges:
        var u:int=int(e["a"]);var v:int=int(e["b"])
        if not ((a==u and b==v) or (a==v and b==u)):
            continue
        var path:PackedVector2Array=PackedVector2Array()
        path.append(point_for(u))
        var curve:PackedVector2Array=_outer_curve(e)
        for p in curve:path.append(p)
        path.append(point_for(v))
        if a==v:
            var reversed:PackedVector2Array=PackedVector2Array()
            for i in range(path.size()-1,-1,-1):reversed.append(path[i])
            return reversed
        return path
    return PackedVector2Array()

func polyline_length(points:PackedVector2Array) -> float:
    var total:float=0.0
    for i in range(1,points.size()):
        total+=points[i-1].distance_to(points[i])
    return total

func point_on_polyline(points:PackedVector2Array,distance:float) -> Vector2:
    if points.is_empty():return Vector2.ZERO
    var remaining:float=maxf(0.0,distance)
    for i in range(1,points.size()):
        var segment:Vector2=points[i]-points[i-1]
        var span:float=segment.length()
        if remaining<=span:return points[i-1]+segment*(remaining/maxf(span,0.001))
        remaining-=span
    return points[-1]

func heading_on_polyline(points:PackedVector2Array,distance:float) -> float:
    if points.size()<2:return 0.0
    var p0:Vector2=point_on_polyline(points,maxf(0.0,distance-3.0))
    var p1:Vector2=point_on_polyline(points,distance+3.0)
    return (p1-p0).angle() if p1.distance_to(p0)>0.1 else 0.0

func probe_path(id:int) -> PackedVector2Array:
    var pts:PackedVector2Array=PackedVector2Array()
    var center:Vector2=point_for(id)
    pts.append(center)
    var port:int=0
    if id>=0 and id<slots.size() and not slots[id].is_empty():
        port=posmod(int(slots[id][0])+int(rotations[id]),5)
    pts.append(_port_point(id,port))
    return pts

func record_edge(a:int,b:int) -> void:
    visited_edges["%d:%d"%[mini(a,b),maxi(a,b)]]=true
    queue_redraw()

func set_ghost(points:PackedVector2Array) -> void:
    ghost_path=points
    queue_redraw()

func clear_ghost() -> void:
    ghost_path=PackedVector2Array()
    queue_redraw()

func _draw() -> void:
    if size.x<100 or size.y<80:return
    _draw_background()
    # Dim unused tracks give the mycelium breadth without offering false paths.
    for e in edges:
        var arc:PackedVector2Array=_outer_curve(e)
        if bool(e["planned"]):
            draw_polyline(arc,Color("#092927"),_radius*0.62,true)
            draw_polyline(arc,Color("#245a4a"),_radius*0.46,true)
            draw_polyline(arc,Color("#32735e"),_radius*0.20,true)
            if is_edge_open(int(e["a"]),int(e["b"])):
                draw_polyline(arc,Color(0.28,0.87,0.63,0.26),_radius*0.45,true)
                draw_polyline(arc,CHANNEL,_radius*0.15,true)
                draw_polyline(arc,Color(0.76,1.0,0.86,0.55),maxf(1.0,_radius*0.035),true)
        else:
            draw_polyline(arc,Color(0.16,0.39,0.35,0.38),maxf(1.0,_radius*0.080),true)
    for id in range(centers.size()):
        _draw_junction(id)
    if ghost_path.size()>1:
        draw_polyline(ghost_path,Color(0.42,0.79,0.63,0.45),_radius*0.29,true)
    for id in [start,goal]:
        var center:Vector2=point_for(id)
        var tint:Color=Color("#91ffd3") if id==start else Color("#ffd78e")
        draw_arc(center,_radius*1.18,0,TAU,44,tint,maxf(2.0,_radius*0.10),true)
    _draw_house(point_for(goal))

func _draw_background() -> void:
    var layers:int=36
    for i in range(layers):
        var tone:float=float(i)/float(layers)
        var c:Color=Color(0.026+tone*0.027,0.12+tone*0.061,0.135+tone*0.047,1.0)
        draw_rect(Rect2(0,size.y*tone,size.x,size.y/float(layers)+1.0),c)
    # Embedded colonies: transparent radial growth rings and tiny spore lights.
    var rng:=RandomNumberGenerator.new()
    rng.seed=905113
    for group in range(9):
        var pt:Vector2=Vector2(rng.randf_range(0.04,0.96)*size.x,rng.randf_range(0.05,0.95)*size.y)
        var radius:float=_radius*rng.randf_range(2.9,6.2)
        for ring in range(4):
            draw_arc(pt,radius*(0.3+float(ring)*0.32),0,TAU,40,Color(0.18,0.48,0.36,0.055),_radius*0.085,true)
    for i in range(360):
        var p:Vector2=Vector2(rng.randf()*size.x,rng.randf()*size.y)
        var strength:float=rng.randf_range(0.055,0.20)
        draw_circle(p,rng.randf_range(0.45,1.8)*_radius/27.0,Color(0.52,1.0,0.72,strength))
    # Hairlike gossamer filaments, purely decorative, never navigated.
    for i in range(85):
        var p:Vector2=Vector2(rng.randf()*size.x,rng.randf()*size.y)
        var direction:Vector2=Vector2.RIGHT.rotated(rng.randf_range(-PI,PI))
        var d:float=rng.randf_range(7.0,40.0)*_radius/28.0
        draw_line(p,p+direction*d,Color(0.20,0.68,0.52,0.10),maxf(0.5,_radius*0.015),true)

func _draw_junction(id:int) -> void:
    var center:Vector2=point_for(id)
    var editable_now:bool=editable.has(id)
    var any_candidate:bool=candidate_ids.has(id)
    var rot_radius:float=_radius*(1.05 if editable_now else 0.85)
    var fill:Color=Color("#173b38") if not editable_now else Color("#205d51")
    if id==selected:fill=Color("#426c53")
    draw_circle(center,rot_radius+_radius*0.23,Color(0.02,0.12,0.15,0.95))
    draw_circle(center,rot_radius,fill)
    if editable_now:
        draw_arc(center,rot_radius+_radius*0.13,0,TAU,34,SELECT if id==selected else ROTOR,maxf(2.0,_radius*0.097),true)
    elif any_candidate:
        draw_arc(center,rot_radius+_radius*0.09,0,TAU,22,Color(0.32,0.70,0.55,0.50),maxf(1.0,_radius*0.045),true)
    # Open sockets are the ACTUAL internal tunnels used for Bubble movement.
    for raw in slots[id]:
        var port:int=posmod(int(raw)+int(rotations[id]),5)
        var endpoint:Vector2=_port_point(id,port)
        draw_line(center,endpoint,Color("#0d3433"),_radius*0.45,true)
        draw_line(center,endpoint,Color("#35886e"),_radius*0.27,true)
        draw_line(center,endpoint,EDGE_GLOW,_radius*0.095,true)
        draw_circle(endpoint,_radius*0.10,Color("#6fdabb"))
    draw_circle(center,_radius*0.26,Color("#0d3533"))
    draw_circle(center,_radius*0.14,Color("#a5fad2"))
    if editable_now:
        # Four prominent interaction markers; static nodes have no controls.
        var num:int=editable.find(id)+1
        var anchor:Vector2=center+Vector2(_radius*0.58,-_radius*0.96)
        draw_circle(anchor,_radius*0.29,Color("#efc46f"))
        var font:Font=get_theme_default_font()
        draw_string(font,anchor+Vector2(-_radius*0.10,_radius*0.12),str(num),HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(10,roundi(_radius*0.44)),Color("#182b31"))

func _draw_house(p:Vector2) -> void:
    var s:float=_radius
    var roof:PackedVector2Array=PackedVector2Array([p+Vector2(-0.35*s,-0.05*s),p+Vector2(0,-0.48*s),p+Vector2(0.35*s,-0.05*s)])
    draw_colored_polygon(roof,Color("#efc976"))
    draw_rect(Rect2(p+Vector2(-0.25*s,-0.05*s),Vector2(0.50*s,0.43*s)),Color("#ffd995"))
    draw_rect(Rect2(p+Vector2(-0.065*s,0.12*s),Vector2(0.13*s,0.26*s)),Color("#456456"))
