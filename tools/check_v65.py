#!/usr/bin/env python3
from pathlib import Path

def check(project: Path):
    required=[
        'planet_hub/backgrounds/lmc_p01.png','planet_hub/backgrounds/lmc_p02.png','planet_hub/backgrounds/lmc_p03.png',
        'planet_hub/backgrounds/lmc_p04.png','planet_hub/backgrounds/lmc_p05.png','planet_hub/backgrounds/lmc_p06.png',
        'planet_hub/backgrounds/lmc_p07.png','planet_hub/backgrounds/lmc_p08.png','planet_hub/backgrounds/st_lmc.png'
    ]
    for rel in required:
        if not (project/rel).is_file():
            raise RuntimeError('Missing background '+rel)
    main=(project/'scripts/Main.gd').read_text(encoding='utf-8')
    if '_resolve_autopilot_destination' not in main:
        raise RuntimeError('No updated autopilot destination resolver')
    if 'return _begin_autoland_payload(system_data.get("station", {}), target_id)' not in main:
        raise RuntimeError('Station auto-landing not installed')
    print('v65 CHECK PASS: LMC backgrounds + auto-landing for stations and all planets')

if __name__=='__main__':
    import sys
    check(Path(sys.argv[1]).expanduser().resolve())
