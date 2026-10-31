#!/usr/bin/env python3
from pathlib import Path
import sys

def main() -> int:
    if len(sys.argv) != 2:
        print('usage: check_v58_3_1.py <project_dir>')
        return 2
    root = Path(sys.argv[1]).resolve()
    other = (root/'scripts'/'OtherSystem.gd').read_text(encoding='utf-8')
    thr = (root/'scripts'/'TarantulaThrusters.gd').read_text(encoding='utf-8')
    ok = True
    if 'ThreeBlueThrusters_AttachedToTarantula' not in other:
        print('FAIL: Tarantula thruster node is not attached in OtherSystem.gd')
        ok = False
    for token in ['Vector2(-552.0, -138.0)', 'Vector2(-566.0, 0.0)', 'Vector2(-552.0, 142.0)']:
        if token not in thr:
            print('FAIL: missing corrected rear-engine coordinate:', token)
            ok = False
    if 'var tip: Vector2 = nozzle + Vector2(-length_px, 0.0)' not in thr:
        print('FAIL: plume direction is not set to rear / left side')
        ok = False
    if ok:
        print('v58.3.1 STATIC PASS: Tarantula thrusters moved to the rear three engines')
        return 0
    return 1

if __name__ == '__main__':
    raise SystemExit(main())
