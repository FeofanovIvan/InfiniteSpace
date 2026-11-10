extends "res://planet_hub/games/ice_planet/IcePlanetSurvivalV41.gd"
## MIKA Ice Planet v4.2: larger initial safe area, no translucent stage fill,
## matching pale-blue horizontal joystick rails, multilingual spoken feedback.
## v4.1 continuous survival, actual spherical rotation and solar escalations stay.

const STICK_V42: Script = preload("res://planet_hub/games/ice_planet/IcePlanetHorizontalStickV42.gd")
const CRYSTAL_CHIME: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const WARNING_CHIME: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")

const BEGIN_SAFE_HALF_WIDTH: float = 0.2325 # v4.1 was 0.155: exactly +50%.
const FIRST_SHRINK_AFTER_POINTS: int = 4
const HALF_WIDTH_LOSS_PER_LEVEL: float = 0.022

const SPEECH: Dictionary = {
    "ru": {
        "intro": "Удерживай живой океан в зелёной зоне. Левым джойстиком двигай планету, правым вращай её. За пять безопасных секунд получишь кристалл!",
        "crystal": "Кристалл получен! Солнце ускоряется!",
        "heat": "Слишком жарко! Отодвинь планету!",
        "ice": "Слишком холодно! Приблизь планету к Солнцу!",
        "lost": "Океан погиб. Попробуй ещё раз!"
    },
    "en": {
        "intro": "Keep the living ocean in the green zone. Move the planet with the left joystick and rotate it with the right one. Earn a crystal for five safe seconds!",
        "crystal": "Crystal earned! The Sun is speeding up!",
        "heat": "Too hot! Move the planet away!",
        "ice": "Too cold! Move the planet closer to the Sun!",
        "lost": "The ocean was lost. Try again!"
    },
    "pt": {
        "intro": "Mantenha o oceano na zona verde. Mova o planeta com o controle esquerdo e gire com o direito. Ganhe um cristal a cada cinco segundos seguros!",
        "crystal": "Cristal conquistado! O Sol está acelerando!",
        "heat": "Muito quente! Afaste o planeta!",
        "ice": "Muito frio! Aproxime o planeta do Sol!",
        "lost": "O oceano se perdeu. Tente novamente!"
    },
    "es": {
        "intro": "Mantén el océano en la zona verde. Mueve el planeta con el control izquierdo y gíralo con el derecho. ¡Gana un cristal por cada cinco segundos seguros!",
        "crystal": "¡Cristal conseguido! ¡El Sol se acelera!",
        "heat": "¡Demasiado calor! ¡Aleja el planeta!",
        "ice": "¡Demasiado frío! ¡Acerca el planeta al Sol!",
        "lost": "El océano se ha perdido. ¡Inténtalo de nuevo!"
    },
    "de": {
        "intro": "Halte den Ozean in der grünen Zone. Bewege den Planeten mit dem linken Joystick und drehe ihn mit dem rechten. Für fünf sichere Sekunden gibt es einen Kristall!",
        "crystal": "Kristall erhalten! Die Sonne wird schneller!",
        "heat": "Zu heiß! Bewege den Planeten weiter weg!",
        "ice": "Zu kalt! Bringe den Planeten näher an die Sonne!",
        "lost": "Der Ozean ist verloren. Versuch es noch einmal!"
    },
    "fr": {
        "intro": "Garde l'océan dans la zone verte. Déplace la planète avec le joystick gauche et fais-la tourner avec le droit. Gagne un cristal toutes les cinq secondes sûres !",
        "crystal": "Cristal gagné ! Le Soleil accélère !",
        "heat": "Trop chaud ! Éloigne la planète !",
        "ice": "Trop froid ! Rapproche la planète du Soleil !",
        "lost": "L'océan est perdu. Réessaie !"
    }
}

var _v42_sfx: AudioStreamPlayer
var _v42_intro_played: bool = false
var _v42_danger_announced: bool = false
var _v42_warning_cooldown: float = 0.0

func _create_flight_controls() -> void:
    # Original flight joystick's input behavior and hit testing; only the
    # drawn horizontal guide differs. BOTH are visually identical.
    _flight_left = STICK_V42.new() as Control
    _flight_left.name = "IcePlanetMoveStick_PaleBlueHorizontal"
    _flight_left.z_index = 50
    add_child(_flight_left)
    _flight_left.connect("direction_changed", Callable(self, "_on_left_stick"))
    _flight_right = STICK_V42.new() as Control
    _flight_right.name = "IcePlanetSpinStick_PaleBlueHorizontal"
    _flight_right.z_index = 50
    add_child(_flight_right)
    _flight_right.connect("direction_changed", Callable(self, "_on_right_stick"))

func _ready() -> void:
    super._ready()
    _v42_sfx = AudioStreamPlayer.new()
    _v42_sfx.name = "IcePlanetLocalizedFeedbackSFX"
    _v42_sfx.volume_db = -11.0
    add_child(_v42_sfx)
    call_deferred("_v42_intro")

func _green_bounds() -> Vector2:
    # Levels unlock only after four WHOLE safe points (seconds). Each later
    # crystal narrows the zone again; no shrink at game start or during retry.
    var level: int = 0
    if _total_safe_ticks >= FIRST_SHRINK_AFTER_POINTS:
        level = maxi(1, _earned_crystals)
    var half_width: float = maxf(MIN_SAFE_HALF_WIDTH, BEGIN_SAFE_HALF_WIDTH - float(level) * HALF_WIDTH_LOSS_PER_LEVEL)
    return Vector2(SAFE_CENTER - half_width, SAFE_CENTER + half_width)

func _draw() -> void:
    # Actual shared flight-space scene stays fully visible. Keep the approved
    # cyan outline, but remove both the stage's blue wash and its shadow.
    if _stage_rect.size.x <= 0.0:
        return
    var frame: StyleBoxFlat = MIKA_UI.stage_style()
    frame.bg_color = Color.TRANSPARENT
    frame.shadow_color = Color.TRANSPARENT
    frame.shadow_size = 0
    frame.border_color = Color("5cdfff", 0.94)
    draw_style_box(frame, _stage_rect)
    draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
    _draw_climate_bar()
    _draw_ocean_vapor_and_ice()
    _draw_sun_flare_trails()
    _draw_temperature_gauge()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _restart_survival() -> void:
    _v42_danger_announced = false
    _v42_warning_cooldown = 0.0
    super._restart_survival()

func _process(delta: float) -> void:
    if _v42_warning_cooldown > 0.0:
        _v42_warning_cooldown = maxf(0.0, _v42_warning_cooldown - delta)
    super._process(delta)

func _advance_survival(delta: float) -> void:
    # The normal v4.1 tick/crystal/death loop remains authoritative.
    super._advance_survival(delta)
    if _survival_lost:
        return
    var limits: Vector2 = _green_bounds()
    var outside: bool = _actual_distance < limits.x or _actual_distance > limits.y
    if not outside:
        _v42_danger_announced = false
    elif not _v42_danger_announced and _danger_tick_progress >= 2.0 and _v42_warning_cooldown <= 0.0:
        _v42_danger_announced = true
        _v42_warning_cooldown = 6.0
        _v42_sound(false)
        _v42_speak("heat" if _actual_distance < limits.x else "ice")

func _award_crystal() -> void:
    super._award_crystal()
    _v42_sound(true)
    if _earned_crystals == 1 or _earned_crystals % 3 == 0:
        _v42_speak("crystal")

func _lose_planet() -> void:
    super._lose_planet()
    _v42_sound(false)
    _v42_speak("lost")

func _v42_intro() -> void:
    if _v42_intro_played or not is_inside_tree():
        return
    _v42_intro_played = true
    _v42_speak("intro")

func _v42_sound(positive: bool) -> void:
    if _test_no_persistent_awards or _v42_sfx == null:
        return
    _v42_sfx.stop()
    _v42_sfx.stream = CRYSTAL_CHIME if positive else WARNING_CHIME
    _v42_sfx.play()

func _v42_speak(key: String) -> void:
    if _test_no_persistent_awards or not is_inside_tree():
        return
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice == null or not voice.has_method("speak_text"):
        return
    var language: String = _interface_lang.substr(0, 2)
    var dictionary: Dictionary = SPEECH.get(language, SPEECH["en"])
    var sentence: String = str(dictionary.get(key, ""))
    if not sentence.is_empty():
        voice.call("speak_text", sentence, "pt_BR" if language == "pt" else language, "phase")
