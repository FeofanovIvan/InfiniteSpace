extends Control
## Reuses the original 71-second silent movie; all captions now come from L IDs.
const ItemScene = preload("res://mika_comic_kit/scenes/ComicTextItem.tscn")
const Layout = preload("res://mika_comic_kit/scripts/comic_layout.gd")
const CUES_PATH: String = "res://mika_comic_kit/page01/page01_cues.json"
@onready var intro = $OriginalIntro
@onready var text_layer: Control = $TextLayer
var timeline: Array = []
var active_id: String = ""
var active_item
var is_paused: bool = false

func _ready() -> void:
    intro.show_lettering = false
    intro.autoplay = true
    var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(CUES_PATH))
    if decoded is Dictionary:
        timeline = decoded.get("cues", [])
    resized.connect(_refresh_layout)
    set_process(true)
    _refresh_layout()

func _refresh_layout() -> void:
    if active_item != null and is_instance_valid(active_item):
        active_item.queue_free()
        active_item = null
    active_id = ""
    _update_overlay()

func _process(_delta: float) -> void:
    _update_overlay()

func _update_overlay() -> void:
    if intro == null or text_layer == null:
        return
    var seconds: float = intro.get_playhead()
    var current: Dictionary = {}
    for cue in timeline:
        if seconds >= float(cue.get("start",0.0)) and seconds < float(cue.get("end",0.0)):
            current = cue
            break
    if current.is_empty():
        if active_item != null:
            active_item.visible = false
        active_id = ""
        return
    if active_id != str(current.get("id","")) or active_item == null:
        if active_item != null:
            active_item.queue_free()
        active_item = ItemScene.instantiate()
        text_layer.add_child(active_item)
        active_id = str(current.get("id",""))
        var ui_scale: float = minf(size.x/1280.0,size.y/720.0)
        var dimensions: Array = current.get("preferred_size",[610,155])
        var preferred: Vector2 = Vector2(float(dimensions[0]),float(dimensions[1]))*ui_scale
        var protected: Array[Rect2] = Layout.normalized_protected(current.get("protected_zones",[]),size)
        var result: Rect2 = Layout.locate(size,preferred,str(current.get("anchor","bottom_left")),protected)
        if result.size.x <= 0.0:
            active_item.visible = false
            return
        # Draw the cloud first, then its text. Text stays screen-stable during camera shake.
        active_item.configure(str(current.get("style_id","L02")),str(current.get("text","")),str(current.get("secondary","")),result.size,Vector2(-1000,-1000),ui_scale)
        active_item.set_home(result.position)
        active_item.visible = true
    var into: float = seconds-float(current["start"])
    var remaining: float = float(current["end"])-seconds
    active_item.seek_entrance(into/0.38)
    active_item.modulate.a *= clampf(remaining/0.28,0.0,1.0)

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed:
        return
    if event.keycode == KEY_SPACE:
        is_paused = not is_paused
        if is_paused: intro.pause()
        else: intro.resume()
    elif event.keycode == KEY_R:
        intro.restart()
    elif event.keycode == KEY_LEFT:
        intro.seek(intro.get_playhead()-5.0)
    elif event.keycode == KEY_RIGHT:
        intro.seek(intro.get_playhead()+5.0)
    elif event.keycode == KEY_ESCAPE:
        get_tree().change_scene_to_file("res://mika_comic_kit/demo/CatalogDemo.tscn")
