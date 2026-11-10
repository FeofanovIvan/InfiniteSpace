#!/usr/bin/env python3
"""Static v58.5 pet port verification. Not a substitute for Godot F5."""
from pathlib import Path
import sys


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit('Usage: check_v58_5.py PROJECT')
    root=Path(sys.argv[1]).expanduser().resolve()
    menu=(root/'scripts/MikoMainMenu.gd').read_text()
    pet=(root/'education/playtown/src/features/pet/pet_home_miko.gd').read_text()
    scene=(root/'education/playtown/scenes/features/pet/pet_home_miko.tscn').read_text()
    required_menu=[
        'PlayTownPuppy_WalkingBottom',
        'TapTheRunningPuppy_ToPetHome',
        'PET_FRAMES_PATH',
        'func _advance_puppy(delta: float) -> void:',
        'func _open_pet_home() -> void:',
        '_open_game(PET_SCENE_PATH)',
        'walk_right', 'walk_left',
        'OriginalPlayTownCards_HorizontalSwipe',
        'TransparentSwipeAndTapArea',
    ]
    for token in required_menu:
        assert token in menu,token
    assert 'PetLocationLayer' not in menu, 'Old fake pet popup must be removed'
    assert 'PetLocationButton' not in menu, 'No pet store/button in top rail'
    assert 'func _load_original_catalog() -> void:' in menu
    for token in [
        'func _feed_pet() -> void:',
        'func _water_pet() -> void:',
        'func _wash_pet() -> void:',
        'func _brush_pet_teeth() -> void:',
        'func _play_with_pet() -> void:',
        'TEETH_MINIGAME_SCRIPT', 'BONE_MINIGAME_SCRIPT',
        'GameState.increase_pet_need("food")',
        'GameState.increase_pet_need("water")',
        'GameState.increase_pet_need("clean")',
    ]:
        assert token in pet,token
    assert 'or not GameState.is_shop_item_owned(' not in pet
    assert 'GameState.consume_shop_item(' not in pet
    assert 'if not GameState.has_pet_access():' not in pet
    assert 'res://education/playtown/src/features/pet/pet_home_miko.gd' in scene
    files=['assets/pet/pet_frames.tres',
           'assets/pet/pet_left_1.png', 'assets/pet/pet_right_1.png',
           'assets/pet/animation/dog_animation.tres',
           'assets/pet/animation/dog_animation.png',
           'assets/pet_home/yard_bg.jpg',
           'assets/pet_home/buttons/feed.png',
           'assets/pet_home/buttons/water.png',
           'assets/pet_home/buttons/teeth.png',
           'assets/pet_home/buttons/wash.png',
           'assets/pet_home/teeth/toothbrush.png',
           'assets/pet_home/wash/brush.png',
           'src/features/pet/pet_teeth_minigame.gd',
           'src/features/pet/pet_bone_minigame.gd',
           'audio/sfx/correct.ogg']
    for rel in files:
        p=root/'education/playtown'/rel
        assert p.is_file() and p.stat().st_size > 60, rel
        assert not p.read_bytes().startswith(b'version https://git-lfs.github.com/spec/'), rel
    print('v58.5 STATIC PASS: original puppy animation, five authentic pet actions, local assets and swipe cards')
    return 0

if __name__=='__main__':
    raise SystemExit(main())
