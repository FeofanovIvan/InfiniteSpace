extends "res://scripts/ActionButton.gd"
## Original main-flight round action button, now holds rocket launch.
## The original _draw_landing() spacecraft icon is reused in the circle.
signal hold_started
signal hold_released
signal hold_cancelled

var _enabled: bool = true
var _held: bool = false


func _ready() -> void:
    super._ready()
    # Keep main action button in its original blank-circle mode, then add ship.
    interaction_available = false
    queue_redraw()


func set_enabled(enabled: bool) -> void:
    if _held:
        _cancel_hold()
    _enabled = enabled
    queue_redraw()


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        _cancel_hold()


func _begin_hold() -> void:
    if not _enabled or _held or not is_visible_in_tree():
        return
    _held = true
    _pressed_visual = true
    hold_started.emit()
    queue_redraw()


func _end_hold() -> void:
    if not _held:
        return
    _held = false
    _pressed_visual = false
    hold_released.emit()
    queue_redraw()


func _cancel_hold() -> void:
    _touch_id = -1
    _mouse_down = false
    if _held:
        _held = false
        hold_cancelled.emit()
    _pressed_visual = false
    queue_redraw()


func _input(event: InputEvent) -> void:
    if not _enabled or not is_visible_in_tree():
        return
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed and _touch_id < 0 and _in_circle(touch.position):
            _touch_id = touch.index
            _begin_hold()
            get_viewport().set_input_as_handled()
        elif not touch.pressed and touch.index == _touch_id:
            _touch_id = -1
            _end_hold()  # releasing anywhere launches at current spring strength
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index != MOUSE_BUTTON_LEFT:
            return
        if mouse.pressed and not _mouse_down and _in_circle(mouse.position):
            _mouse_down = true
            _begin_hold()
            get_viewport().set_input_as_handled()
        elif not mouse.pressed and _mouse_down:
            _mouse_down = false
            _end_hold()
            get_viewport().set_input_as_handled()


func _draw() -> void:
    # Render ACTUAL ActionButton base rings, not a new lookalike.
    super._draw()
    # Use the genuine flight-scene land/ship pictogram; no new assets.
    _draw_landing(size * 0.5)
    if not _enabled:
        draw_circle(size * 0.5, 66.0, Color(0.01, 0.05, 0.10, 0.52))
