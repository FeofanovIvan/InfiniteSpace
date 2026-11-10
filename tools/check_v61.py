#!/usr/bin/env python3
"""Static v61 regression checks; no runtime Godot in packaging environment."""
from pathlib import Path
import hashlib,sys

def check(root):
    root=Path(root)
    a=root/'planet_hub/assets/planet_bottom_panel.png'
    b=(root/'planet_hub/scripts/bottom_hud.gd').read_text(encoding='utf8')
    c=(root/'planet_hub/scripts/planet_hub_overlay.gd').read_text(encoding='utf8')
    assert a.is_file()
    assert hashlib.sha256(a.read_bytes()).hexdigest() == '8b68011b6abddf416bf142d2ba41ead18fa14e1adfa8811b7c44f4960d1722a7', 'Source artwork modified'
    assert 'draw_texture_rect(PANEL_ART, target, false)' in b
    assert 'size.y / (ART_STRIP_BOTTOM - ART_STRIP_TOP)' in b
    assert 'const CRYSTAL_ART: Texture2D = preload("res://asteroid_assets/fragments/04_blue/crystal_wedge.png")' in b
    assert 'count_label.add_theme_color_override("font_color", Color.WHITE)' in b
    assert 'CrystalCount' in b and 'set(value)' in b
    assert 'signal simulator_pressed' in b and 'signal flight_pressed' in b
    assert 'var bottom_h: float = 158.0 * (sh / 864.0)' in c
    assert 'var bottom_h: float = 142.0 * scale_ui' not in c
    assert (root/'planet_hub/scripts/representative_dialog.gd').is_file(), 'v60.1.1 base missing'
    print('V61 STATIC PASS: original PNG, unwarped center, native crystal, white count, signals')

if __name__=='__main__':
    check(Path(sys.argv[1]) if len(sys.argv)>1 else Path.cwd())
