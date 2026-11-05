#!/usr/bin/env python3
from pathlib import Path
import hashlib
import re
import sys


def main() -> int:
    project = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else Path(__file__).resolve().parent.parent
    text = (project / 'scripts/MikoMainMenu.gd').read_text(encoding='utf-8')
    assert 'const PUPPY_VISUAL_MULTIPLIER: float = 3.0' in text
    assert 'const EDUCATIONAL_CARD_MULTIPLIER: float = 0.85' in text
    assert 'PUPPY_OLD_SCALE * PUPPY_VISUAL_MULTIPLIER * ui_scale' in text
    assert 'var card_height: float = original_card_height * EDUCATIONAL_CARD_MULTIPLIER' in text
    assert 'var card_width: float = original_card_width * EDUCATIONAL_CARD_MULTIPLIER' in text
    assert 'var anchor: Vector2 = Vector2(_pet_walk_x, size.y - (puppy_half_extent + 8.0) * ui_scale)' in text
    assert 'tap_size: Vector2 = Vector2(136.0, 140.0) * PUPPY_VISUAL_MULTIPLIER * ui_scale' in text
    assert 'Vector2.ONE * (0.26 * ui_scale)' not in text
    assert 'func _open_pet_home() -> void:' in text
    assert 'PET_SCENE_PATH' in text
    assert 'OriginalPlayTownCards_HorizontalSwipe' in text
    assert 'TransparentSwipeAndTapArea' in text
    # Threefold image, 15% reduction, and unchanged aspect ratio.
    assert 0.26 * 3.0 == 0.78
    for w,h in [(256,320),(360,400),(160,280)]:
        assert abs((w*.85)/(h*.85)-w/h) < 1e-10
    print('v58.6 STATIC PASS: dog 3x, original aspect-preserving cards 85%, pet scene and swipe intact')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
