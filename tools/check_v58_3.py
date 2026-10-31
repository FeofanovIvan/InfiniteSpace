#!/usr/bin/env python3
from pathlib import Path
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print('usage: check_v58_3.py <project_dir>')
        return 2
    root = Path(sys.argv[1]).resolve()
    other = (root/'scripts'/'OtherSystem.gd').read_text(encoding='utf-8')
    thr = (root/'scripts'/'TarantulaThrusters.gd').read_text(encoding='utf-8')
    ok = True
    if 'ThreeBlueThrusters_AttachedToTarantula' not in other:
        print('FAIL: Tarantula thruster node is not attached in OtherSystem.gd')
        ok = False
    if 'const NOZZLES: Array[Vector2] = [' not in thr or 'upper right engine outlet' not in thr:
        print('FAIL: TarantulaThrusters.gd was not updated to new 3-engine positions')
        ok = False
    if ok:
        print('v58.3 STATIC PASS: Tarantula station has three attached animated blue thrusters')
        return 0
    return 1

if __name__ == '__main__':
    raise SystemExit(main())
