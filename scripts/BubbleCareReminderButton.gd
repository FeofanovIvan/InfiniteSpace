extends Button
## Bubble Care indicator in the *existing* upper-right flight rail.
## Trial cycle: 180 seconds of real flight + five red pulses.
## Change REMINDER_SECONDS after playtesting, not the game-state machinery.
signal reminder_ready

const REMINDER_SECONDS: float = 180.0
const PULSE_PERIOD: float = 0.72
const PULSES_BEFORE_CARD: int = 5
const BODY: Texture2D = preload("res://bubble/assets/face/preview_only/body_sphere.png")
const EYE: Texture2D = preload("res://bubble/assets/face/eye_sclera.png")
const MOUTH: Texture2D = preload("res://bubble/assets/face/mouth_smile.png")

var _flight_active: bool = false
var _elapsed: float = 0.0
var _pulse_elapsed: float = 0.0
var _pulses: int = 0
var _notified: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	queue_redraw()

func set_flight_active(active: bool) -> void:
	_flight_active = active

func reset_clock() -> void:
	_elapsed = 0.0
	_pulse_elapsed = 0.0
	_pulses = 0
	_notified = false
	queue_redraw()

func _process(delta: float) -> void:
	if not _flight_active:
		return
	_elapsed += maxf(0.0, delta)
	if _elapsed >= REMINDER_SECONDS:
		_pulse_elapsed += maxf(0.0, delta)
		_pulses = maxi(_pulses, floori(_pulse_elapsed / PULSE_PERIOD))
		if _pulses >= PULSES_BEFORE_CARD and not _notified:
			_notified = true
			reminder_ready.emit()
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.47
	var progress: float = clampf(_elapsed / REMINDER_SECONDS, 0.0, 1.0)
	var pulse: float = 0.0
	if progress >= 1.0:
		pulse = 0.5 + 0.5 * sin(_pulse_elapsed * TAU / PULSE_PERIOD)
	var blue: Color = Color("06426e")
	var red: Color = Color("c52240")
	var bg: Color = blue.lerp(red, progress)
	draw_circle(center, radius, Color(0.02, 0.08, 0.15, 0.88))
	draw_circle(center, radius - 1.7, bg.lightened(0.16 * pulse))
	# Circular elapsed-time sweep, then an animated red halo.
	var sweep: Color = Color("4deaff").lerp(Color("ff6c7a"), progress)
	if progress > 0.001:
		draw_arc(center, radius - 2.3, -PI * 0.5, -PI * 0.5 + TAU * progress,
			48, sweep, maxf(2.2, radius * 0.11), true)
	if progress >= 1.0:
		draw_arc(center, radius - 2.0, 0.0, TAU, 48,
			Color(1.0, 0.40, 0.50, 0.30 + 0.70 * pulse), 2.5 + pulse * 2.0, true)
	# Reuse the REAL Bubble face assets. No emoji or second species icon.
	var r: float = radius * 0.70
	draw_texture_rect(BODY, Rect2(center - Vector2.ONE * r, Vector2.ONE * (r * 2.0)), false)
	var eye_sz: Vector2 = Vector2(r * 0.43, r * 0.48)
	draw_texture_rect(EYE, Rect2(center + Vector2(-r * 0.50, -r * 0.30), eye_sz), false)
	draw_texture_rect(EYE, Rect2(center + Vector2(r * 0.10, -r * 0.30), eye_sz), false)
	draw_texture_rect(MOUTH, Rect2(center + Vector2(-r * 0.35, r * 0.16),
		Vector2(r * 0.75, r * 0.31)), false)
