extends RefCounted
## Layout in visible screen space. Protected zones are screen-normalized Rect2.
## Do not bake lettering into the image; inspect active character zones every cue.
const Registry = preload("res://mika_comic_kit/scripts/comic_registry.gd")

static func normalized_protected(rects: Array, screen: Vector2) -> Array[Rect2]:
    var result: Array[Rect2] = []
    for entry in rects:
        if entry is Array and entry.size() >= 4:
            result.append(Rect2(float(entry[0])*screen.x,float(entry[1])*screen.y,float(entry[2])*screen.x,float(entry[3])*screen.y))
    return result

static func _overlap_area(a: Rect2, b: Rect2) -> float:
    var intersection: Rect2 = a.intersection(b)
    return intersection.size.x * intersection.size.y if intersection.has_area() else 0.0

static func locate(screen: Vector2, box: Vector2, preferred: String, protected: Array[Rect2], occupied: Array[Rect2] = []) -> Rect2:
    var side_margin: float = maxf(13.0,screen.x*0.04)
    var top_margin: float = maxf(12.0,screen.y*0.05)
    var available: Rect2 = Rect2(Vector2(side_margin,top_margin),screen-Vector2(side_margin*2,top_margin*2))
    var w: float = minf(box.x,available.size.x)
    var h: float = minf(box.y,available.size.y)
    var candidates: Dictionary = {
        "top_left":Vector2(available.position.x,available.position.y),
        "top_center":Vector2((screen.x-w)/2.0,available.position.y),
        "top_right":Vector2(available.end.x-w,available.position.y),
        "middle_left":Vector2(available.position.x,(screen.y-h)/2.0),
        "middle_right":Vector2(available.end.x-w,(screen.y-h)/2.0),
        "bottom_left":Vector2(available.position.x,available.end.y-h),
        "bottom_center":Vector2((screen.x-w)/2.0,available.end.y-h),
        "bottom_right":Vector2(available.end.x-w,available.end.y-h)
    }
    var best: Rect2 = Rect2(candidates.get(preferred,candidates["bottom_left"]),Vector2(w,h))
    var min_penalty: float = INF
    for name in candidates:
        var item := Rect2(candidates[name],Vector2(w,h))
        var cost: float = 0.0 if name == preferred else 6000.0
        for obstacle in protected:
            var face_area: float = _overlap_area(item,obstacle)
            if face_area > 16.0:
                cost += 10000000.0 + face_area*25.0
        for obstacle in occupied:
            var text_area: float = _overlap_area(item,obstacle)
            if text_area > 16.0:
                cost += 10000000.0 + text_area*35.0
        if cost < min_penalty:
            min_penalty = cost
            best = item
    # Grid fallback if all corners collide: prefer no faces even with a non-standard anchor.
    if min_penalty > 1000000.0:
        for yi in range(9):
            for xi in range(11):
                var pos: Vector2 = available.position + Vector2(float(xi)/10.0*maxf(0.0,available.size.x-w),float(yi)/8.0*maxf(0.0,available.size.y-h))
                var candidate := Rect2(pos,Vector2(w,h))
                var penalty := 15000.0
                for obstacle in protected:
                    var face_area: float = _overlap_area(candidate,obstacle)
                    if face_area > 16.0:
                        penalty += 10000000.0 + face_area*25.0
                for obstacle in occupied:
                    var text_area: float = _overlap_area(candidate,obstacle)
                    if text_area > 16.0:
                        penalty += 10000000.0 + text_area*35.0
                if penalty < min_penalty:
                    min_penalty = penalty
                    best = candidate
    if min_penalty >= 10000000.0:
        push_warning("MIKA Comic Kit: no safe caption position. Split cue or reduce box / protected zones.")
        return Rect2(Vector2(-1,-1), Vector2.ZERO)
    return best

static func is_unobstructed(rect: Rect2, blocked: Array[Rect2]) -> bool:
    for b in blocked:
        if _overlap_area(rect,b) > 16.0:
            return false
    return true
