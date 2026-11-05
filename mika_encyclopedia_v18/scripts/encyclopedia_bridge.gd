extends CanvasLayer
## Native entry only; does not scan the running tree or create floating buttons.
const BOOK: PackedScene = preload("res://mika_encyclopedia_v18/scenes/glossary.tscn")
var _page: Control
var _cover: Control
var _was_paused: bool = false

func _ready() -> void:
    name = "MikaEncyclopediaBridge"
    layer = 95
    process_mode = Node.PROCESS_MODE_ALWAYS

func open_encyclopedia() -> void:
    if is_instance_valid(_page):
        return
    _cover = Control.new()
    _cover.name = "MikaEncyclopediaScreenLayer"
    _cover.mouse_filter = Control.MOUSE_FILTER_STOP
    _cover.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_cover)
    _cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _cover.size = get_viewport().get_visible_rect().size
    var node: Node = BOOK.instantiate()
    if not node is Control:
        push_error("MIKA Encyclopedia: glossary.tscn must have a Control root")
        node.queue_free()
        _cover.queue_free()
        _cover = null
        return
    _page = node as Control
    _cover.add_child(_page)
    _page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _page.size = _cover.size
    _page.process_mode = Node.PROCESS_MODE_ALWAYS
    if _page.has_signal("closed"):
        _page.connect("closed", Callable(self, "_close_encyclopedia"))
    else:
        push_error("MIKA Encyclopedia: native page lacks closed signal")
    _page.call("open_glossary")
    _was_paused = get_tree().paused
    get_tree().paused = true

func _close_encyclopedia() -> void:
    if is_instance_valid(_cover):
        _cover.queue_free()
    _cover = null
    _page = null
    get_tree().paused = _was_paused
