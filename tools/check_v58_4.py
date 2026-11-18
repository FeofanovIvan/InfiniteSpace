#!/usr/bin/env python3
from pathlib import Path
import sys

def main() -> int:
    if len(sys.argv) != 2:
        print('usage: check_v58_4.py <project_dir>')
        return 2
    root = Path(sys.argv[1]).resolve()
    text = (root/'scripts'/'MikoMainMenu.gd').read_text(encoding='utf-8')
    required = [
        'PetLocationButton',
        'func _open_pet_location() -> void:',
        'func _find_pet_texture_path(root_path: String) -> String:',
        'PetLocationLayer',
        '_pet_button.size = Vector2.ONE * 52.0 * scale'
    ]
    missing = [s for s in required if s not in text]
    if missing:
        print('FAIL: missing markers:', ', '.join(missing))
        return 1
    print('v58.4 STATIC PASS: smaller buttons and pet location button are present')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
