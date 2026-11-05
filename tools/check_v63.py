#!/usr/bin/env python3
from pathlib import Path
import json,sys
root=Path(sys.argv[1]) if len(sys.argv)>1 else Path.cwd()
a=(root/'planet_hub/scripts/bottom_hud.gd').read_text()
b=(root/'planet_hub/scripts/planet_card.gd').read_text()
c=(root/'planet_hub/scripts/planet_hub_overlay.gd').read_text()
t=json.loads((root/'locales/strings.json').read_text())
assert 'PANEL_ART' not in a and 'planet_bottom_panel.png' not in a
assert 'draw_colored_polygon' in a and 'MobileLocale.language_changed.connect' in a
assert 'CRYSTAL_ART' in a and 'planet_depart' in a and 'planet_simulator' in a
assert 'portrait_top' in b and 'AtlasTexture.new()' in b and '"contain"' in b
assert 'representative.set("card_subtitle", _planet_name)' in c
assert not (root/'planet_hub/assets/planet_bottom_panel.png').exists()
for code in ['en','ru','fr','de','es','pt_BR']:
    assert t[code]['planet_simulator'] and t[code]['planet_depart']
print('v63 STATIC PASS: procedural panel, locale 6/6, character crop modes, old PNG removed')
