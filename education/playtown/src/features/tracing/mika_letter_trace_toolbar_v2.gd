extends "res://education/playtown/src/features/tracing/mika_letter_trace_v1_2_1.gd"
## Trace Letters header standardization: native back, native HUD and a single
## shared title plaque. Crystal counter is per-run, never the current fuel tank.

const SHARED_TRACE_TOOLBAR := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")

func _ready() -> void:
    super._ready()
    SHARED_TRACE_TOOLBAR.apply_title_style(_title_panel)
    if _round_count != null:
        _round_count.hide() # Same reward is shown in the original counter above.
    _relayout_native()

func _update_score() -> void:
    # Called by the inherited tracing logic, including during construction.
    # No dependency on ship balance: 0 on entry, +1 per new traced letter.
    if _native_hub != null:
        _native_hub.set("crystal_count", _earned)
    if _round_count != null:
        var locale: String = str(MobileLocale.language)
        if not CAPTIONS.has(locale):
            locale = "en"
        _round_count.text = "%s: +%d" % [CAPTIONS[locale][3], _earned]

func _relayout_native() -> void:
    super._relayout_native()
    if _native_back_button == null or _native_hub == null or _title_panel == null:
        return
    var view: Vector2 = get_viewport_rect().size
    var safe: Rect2 = _safe_rect()
    SHARED_TRACE_TOOLBAR.relayout(view, safe, _native_back_button, _native_hub, _title_panel, _title, _instructions)
