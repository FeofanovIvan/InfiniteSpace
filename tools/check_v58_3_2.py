#!/usr/bin/env python3
from pathlib import Path
import hashlib
import sys

EXPECTED_SHA256 = 'a481c281034c561bed43ea430957404de4715681710ba7c3a457b6953561a7d4'

def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent).expanduser().resolve()
    other = (root / 'scripts/OtherSystem.gd').read_text(encoding='utf-8')
    script = (root / 'scripts/TarantulaThrusters.gd').read_bytes()
    assert hashlib.sha256(script).hexdigest() == EXPECTED_SHA256, 'v58.3.2: engine script checksum mismatch'
    assert 'ThreeBlueThrusters_AttachedToTarantula' in other, 'v58.3.2: engine node is not connected'
    assert 'if _tarantula_thrusters != null:' in other, 'v58.3.2: animated update is not connected'
    for coord in ('Vector2(-615.0, -141.0)', 'Vector2(-615.0, -15.0)', 'Vector2(-615.0, 111.0)'):
        assert coord in script.decode('utf8'), 'Missing nozzle: ' + coord
    assert 'Vector2(-length_px, 0.0)' in script.decode('utf8'), 'Exhaust direction must stay -X'
    print('v58.3.2 STATIC PASS: three nozzles aligned with rear engine outlets; -X exhaust preserved')

if __name__ == '__main__':
    main()
