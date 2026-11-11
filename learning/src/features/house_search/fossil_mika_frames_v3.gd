extends RefCounted
## Non-destructive character atlas reader. v3 metadata is selected by
## scanning the user's installed Resource Rush PNGs, not by guessing 2x2.
const MANIFEST := "res://learning/src/features/house_search/fossil_mika_sheets_v3.json"

static func _data() -> Dictionary:
    if not FileAccess.file_exists(MANIFEST):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
    return parsed if parsed is Dictionary else {}

static func make_frames() -> SpriteFrames:
    var data := _data()
    var animations: Dictionary = data.get("animations", {})
    var frames := SpriteFrames.new()
    if frames.has_animation(&"default"):
        frames.remove_animation(&"default")
    for anim in ["walk_down", "walk_up", "walk_right", "walk_left"]:
        var row: Dictionary = animations.get(anim, {})
        var texture := load(str(row.get("path", ""))) as Texture2D
        if texture == null:
            push_error("Fossil Hunt: missing Resource Rush sheet for " + anim)
            return null
        var cells: Array = row.get("regions", [])
        if cells.size() < 4:
            push_error("Fossil Hunt: fewer than 4 isolated MIKA frames for " + anim)
            return null
        frames.add_animation(anim)
        frames.set_animation_loop(anim, true)
        frames.set_animation_speed(anim, 6.0)
        for rect_data in cells.slice(0, 4):
            var q: Array = rect_data
            if q.size() != 4:
                return null
            var atlas := AtlasTexture.new()
            atlas.atlas = texture
            atlas.region = Rect2(float(q[0]), float(q[1]), float(q[2]), float(q[3]))
            frames.add_frame(anim, atlas)
    return frames

static func walk_frame_height() -> float:
    return maxf(1.0, float(_data().get("cell_height", 400.0)))

static func mirror_left() -> bool:
    return bool(_data().get("mirror_left", false))
