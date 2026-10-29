extends Control
## Demo-only keyboard controls: Space pause/play, R replay, Left/Right seek 5 sec, Esc quit.
@onready var intro: MikaMotionComicIntro = $MotionComicIntro

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    match key_event.keycode:
        KEY_SPACE:
            if intro.playing:
                intro.pause()
            else:
                intro.resume()
            get_viewport().set_input_as_handled()
        KEY_R:
            intro.restart()
            get_viewport().set_input_as_handled()
        KEY_LEFT:
            intro.seek(intro.get_playhead() - 5.0)
            get_viewport().set_input_as_handled()
        KEY_RIGHT:
            intro.seek(intro.get_playhead() + 5.0)
            get_viewport().set_input_as_handled()
        KEY_ESCAPE:
            get_tree().quit()
