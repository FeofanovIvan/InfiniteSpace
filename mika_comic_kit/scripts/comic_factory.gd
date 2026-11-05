extends RefCounted
## Production API. Choose a stable ID and receive an actual Godot Control.
## Example: var balloon = ComicFactory.make_text("L03", "The Crossroads!", Vector2(600,160))
##          some_screen_space_layer.add_child(balloon)
const Registry = preload("res://mika_comic_kit/scripts/comic_registry.gd")
const TEXT_SCENE = preload("res://mika_comic_kit/scenes/ComicTextItem.tscn")
const STAGE_SCENE = preload("res://mika_comic_kit/scenes/ComicStage.tscn")

static func make_text(id: String, text: String, dimensions: Vector2 = Vector2(520,160), secondary: String = "", ui_scale: float = 1.0) -> Control:
    if not Registry.catalog().get("lettering",{}).has(id):
        push_error("MIKA Comic Kit: undefined lettering ID " + id)
        return null
    var item = TEXT_SCENE.instantiate()
    item.configure(id,text,secondary,dimensions,Vector2(-1000,-1000),ui_scale)
    return item

static func make_panel(id: String, image_a: String = "city", image_b: String = "mica_balcony", image_c: String = "disaster_magenta") -> Control:
    if not Registry.catalog().get("panels",{}).has(id):
        push_error("MIKA Comic Kit: undefined panel ID " + id)
        return null
    var stage = STAGE_SCENE.instantiate()
    # Defer until after stage enters the tree and builds its shader layers.
    stage.ready.connect(func(): stage.show_panel(id,image_a,image_b,image_c),CONNECT_ONE_SHOT)
    return stage

static func make_transition(id: String, from_key: String = "city", to_key: String = "mica_balcony") -> Control:
    if not Registry.catalog().get("transitions",{}).has(id):
        push_error("MIKA Comic Kit: undefined transition ID " + id)
        return null
    var stage = STAGE_SCENE.instantiate()
    stage.ready.connect(func():stage.show_transition(id,0.0,from_key,to_key),CONNECT_ONE_SHOT)
    return stage

static func seek_transition(stage: Control, id: String, progress: float, from_key: String = "city", to_key: String = "mica_balcony") -> void:
    stage.show_transition(id,clampf(progress,0,1),from_key,to_key)
