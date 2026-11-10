extends "res://education/playtown/src/features/tilt_maze/mika_roll_ball_ui_v1.gd"
## MIKA Roll the Ball v1.1: sensor diagnostic bridge only.
## The maze, movement physics, touchscreen, keyboard, HUD and exit behaviour
## are inherited unchanged from the approved v1 source.
## Android hardware sensors are enabled by project.godot (the critical fix).

var _mika_test_sensor_active: bool = false
var _mika_test_sensor: Vector3 = Vector3.ZERO
var _mika_sensor_missing_seconds: float = 0.0
var _mika_sensor_warning_sent: bool = false


func _read_sensor_vector() -> Vector3:
    # Headless QA uses this injection to exercise the unchanged native movement
    # without pretending a Mac can supply an Android/iOS accelerometer.
    if _mika_test_sensor_active:
        return _mika_test_sensor

    var sensed: Vector3 = super._read_sensor_vector()
    if OS.get_name() in ["Android", "iOS"]:
        if sensed.length() > 1.0:
            _mika_sensor_missing_seconds = 0.0
        else:
            _mika_sensor_missing_seconds += get_physics_process_delta_time()
            if _mika_sensor_missing_seconds >= 3.0 and not _mika_sensor_warning_sent:
                _mika_sensor_warning_sent = true
                push_warning("ROLL THE BALL: gravity/accelerometer reads zero. Re-export the game for Android/iOS with project sensors enabled; touch controls remain available.")
    return sensed
