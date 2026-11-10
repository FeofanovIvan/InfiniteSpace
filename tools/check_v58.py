#!/usr/bin/env python3
from pathlib import Path
import json
r=Path(__file__).resolve().parent.parent
project=(r/'project.godot').read_text()
main=(r/'scripts/Main.gd').read_text()
menu=(r/'scripts/MikoMainMenu.gd').read_text()
portal=(r/'scripts/PlayTownPortal.gd').read_text()
cat=json.loads((r/'education/playtown_catalog.json').read_text())
assert len(cat)==19
assert not any(x['id']=='scooter_race' for x in cat)
for x in cat:
    for key in ['scene','texture']:
        p=r/'education/playtown'/x[key]
        assert p.is_file(),str(p)
        assert not p.read_bytes().startswith(b'version https://git-lfs.github.com/spec/v1'),str(p)
for name in ['GameState','SFX','AccessService','BillingService','LanguageService','PlayTownPortal']:
    assert name+'="*res://' in project,name
assert 'main_menu.crystals_earned.connect(_on_educational_crystals_earned)' in main
assert 'func _on_educational_crystals_earned(units: int) -> void:' in main
assert '_on_fuel_collected(units)' in main
assert 'ScrollContainer.new()' in menu
assert 'SubViewportContainer.new()' in menu
assert 'crystals_earned.emit(gained)' in menu
assert 'SimulatorConsole' not in menu
assert 'UpgradeShopConsole' not in menu
assert 'OriginalMikoCharacter' not in menu
assert 'signal game_finished' in portal
s=(r/'education/playtown/src/core/sound_service.gd').read_text()
assert 'portal.call("handle_scene_transition", scene_path)' in s
print('v58 STATIC PASS: 19 copied Play Town games, original LFS textures, horizontal gallery, reward bridge')
