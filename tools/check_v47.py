#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parent.parent
foreign=(root/'scripts/ForeignTraffic.gd').read_text()
main=(root/'scripts/Main.gd').read_text()
npc=(root/'scripts/NpcTraffic.gd').read_text()
assert 'const HOME_SYSTEM: String = "smc"' in foreign
assert all(('"'+mode+'"' in foreign) for mode in ['approach','hover','landing','docked','takeoff','depart','align_jump','charge','dash','waiting'])
assert 'image.rotation = forward.angle()' in foreign
assert '1 if index == 1 else 2 + index % 3' in foreign
assert 'forward * HyperjumpMotion.dash_speed(t)' in foreign
assert 'item["world"] = _anchor(item, ports)' in foreign
assert 'image.rotation = outward.angle()' in foreign
assert '_turn_nose(image, towards' in foreign
assert 'var nose_forward: Vector2 = Vector2.from_angle(_ship_heading - PI * 0.5)' in main
assert 'var arrival_nose: Vector2 = Vector2.from_angle(_ship_heading - PI * 0.5)' in main
assert 'heading_error < 0.015' in main
assert 'v47: verify nose alignment before accelerating into hyperspace' in npc
assert 'heading_error < 0.015' in npc
assert not any(s.startswith('\t') for s in foreign.splitlines() if s.strip())
print('check_v47: PASS (static; Godot runtime still needs F5)')
