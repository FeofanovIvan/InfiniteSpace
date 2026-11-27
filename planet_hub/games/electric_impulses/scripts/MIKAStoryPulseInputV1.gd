extends "res://planet_hub/games/electric_impulses/scripts/ElectricImpulses_mika_v2_1.gd"
## Chapter 5 Story-only adapter. The original Electric Impulses scene and
## v2.1 game logic/levels are untouched in Free World and simulator.
## Godot touch-to-mouse emulation can deliver a tap twice on the same node.
## Duplicate delivery must never turn a correctly tapped 4,2 into a failure.

const STORY_TAP_DEDUP_MS: int = 170
var _story_last_node: int = -1
var _story_last_ms: int = -100000

func _tap_node_now(node_id: int) -> void:
    if _phase != "input":
        return
    var now: int = Time.get_ticks_msec()
    if node_id == _story_last_node and now - _story_last_ms <= STORY_TAP_DEDUP_MS:
        return
    # The original game excludes consecutive duplicate notes in its patterns.
    # Two extremely close copies of the SAME node are one physical press.
    _story_last_node = node_id
    _story_last_ms = now
    super._tap_node_now(node_id)
