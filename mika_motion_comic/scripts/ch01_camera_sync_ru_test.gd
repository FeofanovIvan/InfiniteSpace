extends Control
## Isolated CH01 camera-first diagnostic: RU page 3 after puzzle.
## No Main.gd, hub, saved games, or other comic pages are involved.

const PanelPlayer: Script = preload("res://mika_motion_comic/scripts/story_page_two_panels.gd")
var _player: Control
var _status: Label
var _events: Array[String] = []

func _ready() -> void:
    name = "CH01_SYNC_V22_RUSSIAN_CAMERA_TEST"
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var locale: Node = get_node_or_null("/root/MobileLocale")
    if locale != null:
        locale.set("language", "ru")
    _player = PanelPlayer.new() as Control
    _player.name = "IsolatedP03PostPuzzlePlayer"
    _player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_player)
    _status = Label.new()
    _status.name = "SyncEventStatus"
    _status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _status.add_theme_font_size_override("font_size", 18)
    _status.add_theme_color_override("font_color", Color(1, 0.92, 0.46))
    _status.add_theme_color_override("font_shadow_color", Color.BLACK)
    _status.position = Vector2(16, 20)
    _status.z_index = 100
    _status.text = "CH01 v2.2 RU independent diagnostic — preparing"
    add_child(_status)
    call_deferred("_start_post_puzzle")

func _start_post_puzzle() -> void:
    var bridge: Node = _player.get("_ch01_p03_bridge") as Node
    if bridge == null:
        push_error("CH01 v2.2 diagnostic: missing P03 modular bridge")
        _status.text = "ERROR: P03 bridge missing"
        return
    bridge.connect("sync_event", Callable(self, "_on_sync_event"))
    _player.begin_sequence(["p03_puzzle_reveal", "p03_mika_upset", "p03_ship_refuel"])

func _on_sync_event(event_name: String, line_id: String, details: String) -> void:
    _events.append("%s | %s" % [line_id, event_name])
    if _events.size() > 5:
        _events.pop_front()
    _status.text = "CH01 v2.2 RU | " + "    ".join(PackedStringArray(_events))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        get_tree().quit()
