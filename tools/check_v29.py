#!/usr/bin/env python3
"""v0.29: structural checks (not a Godot F5 runtime substitute)."""
from pathlib import Path
import re
P = Path(__file__).resolve().parent.parent
scripts = P/'scripts'
main = (scripts/'Main.gd').read_text()
npc = (scripts/'NpcTraffic.gd').read_text()
fx = (scripts/'PlayerJumpFX.gd').read_text()
visual = (scripts/'NpcJumpVisual.gd').read_text()
motion = (scripts/'HyperjumpMotion.gd').read_text()
checks = {
    'NPC and player use the same renderer': all([
        'NpcJumpVisual.draw_charge(self, screen,' in npc,
        'NpcJumpVisual.draw_charge(self, _screen,' in fx,
        'NpcJumpVisual.draw_dash(self, screen,' in npc,
        'NpcJumpVisual.draw_dash(self, _screen,' in fx,
        'NpcJumpVisual.draw_jump_cloud(self,' in npc,
        'NpcJumpVisual.draw_jump_cloud(self,' in fx,
        'NpcJumpVisual.dash_ship_scale(t)' in npc,
        'NpcJumpVisual.dash_ship_scale(departure_progress)' in main,
        'NpcJumpVisual.dash_ship_scale(arrival_progress)' in main,
    ]),
    'NPC and player use shared dash speed and radius': all([
        'HyperjumpMotion.dash_speed(t)' in npc,
        'HyperjumpMotion.dash_speed(departure_progress)' in main,
        'HyperjumpMotion.dash_speed(arrival_progress)' in main,
        'HyperjumpMotion.exit_world(_warp_direction)' in main,
        'HyperjumpMotion.arrival_world(_warp_direction)' in main,
        'OUTER_JUMP_RADIUS: float = 2500.0' in motion,
    ]),
    'jump stages: cruise, charge, dash, absence, arrive': all(f'"{step}":' in main for step in ['cruise','charge','dash_out','transit','dash_in']),
    'dedicated visual is no longer used': 'update_warp(' not in main and 'end_warp(' not in main,
    'no player dissolve or shrink': 'ship.modulate.a = 1.0 - departure_progress' not in main and 'lerpf(1.0, 0.12, departure_progress)' not in main,
    'same HUD preserved': all(item in main for item in ['RightJoystick','LeftContextAction','TopRightDestinationPicker','Fuel_Crystals_Galaxy_MikoMenu']),
    'shared drawing primitives present': all(s in visual for s in ('draw_arc(', 'draw_line(', 'draw_circle(', 'dash_ship_scale')),
    'intro shader fix preserved': 'return;' not in (P/'mika_motion_comic/shaders/comic_layer.gdshader').read_text(),
}
for key, value in checks.items():
    print(('PASS' if value else 'FAIL'),key)
assert all(checks.values()), 'One or more structural checks failed'
print('NOTE: Visual playback / full Godot parsing still require F5 on Mac.')
