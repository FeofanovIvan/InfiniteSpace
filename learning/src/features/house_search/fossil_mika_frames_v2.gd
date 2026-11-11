extends RefCounted
## Use Resource Rush MIKA sheets already in the game; no new character artwork.
## A small generated JSON identifies the actual files/layout in this local project.

const MANIFEST_PATH := "res://learning/src/features/house_search/fossil_mika_sheets_v2.json"

static func make_frames() -> SpriteFrames:
    var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
    if file == null:
        push_error("Fossil Hunt: Resource Rush MIKA sheet manifest is missing")
        return null
    var data: Variant = JSON.parse_string(file.get_as_text())
    if not (data is Dictionary):
        push_error("Fossil Hunt: invalid MIKA frame manifest")
        return null
    var animations: Dictionary = data.get("animations", {})
    var result := SpriteFrames.new()
    if result.has_animation("default"):
        result.remove_animation("default")
    for anim in ["walk_down", "walk_up", "walk_right", "walk_left"]:
        if not animations.has(anim):
            push_error("Fossil Hunt: no MIKA animation " + anim)
            return null
        var descriptor: Dictionary = animations[anim]
        var texture: Texture2D = load(str(descriptor.get("path", ""))) as Texture2D
        if texture == null:
            push_error("Fossil Hunt: MIKA sprite sheet failed loading: " + str(descriptor.get("path", "")))
            return null
        var cols: int = maxi(1, int(descriptor.get("cols", 2)))
        var rows: int = maxi(1, int(descriptor.get("rows", 2)))
        var total: int = maxi(1, int(descriptor.get("frames", 4)))
        var cell_size: Vector2 = texture.get_size() / Vector2(cols, rows)
        result.add_animation(anim)
        result.set_animation_speed(anim, 6.0)
        result.set_animation_loop(anim, true)
        for i in range(mini(total, cols * rows)):
            var cell := AtlasTexture.new()
            cell.atlas = texture
            cell.region = Rect2(Vector2(float(i % cols), float(floori(float(i) / float(cols)))) * cell_size, cell_size)
            result.add_frame(anim, cell)
    return result

static func walk_frame_height() -> float:
    var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
    if file == null:
        return 400.0
    var data: Variant = JSON.parse_string(file.get_as_text())
    if not (data is Dictionary):
        return 400.0
    return maxf(1.0, float(data.get("cell_height", 400.0)))

static func mirror_left() -> bool:
    var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
    if file == null:
        return false
    var data: Variant = JSON.parse_string(file.get_as_text())
    return bool(data.get("mirror_left", false)) if data is Dictionary else false
