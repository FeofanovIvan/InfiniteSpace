#!/usr/bin/env python3
"""Legacy entrypoint for users whose terminal commands still reference check_v24."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().with_name('check_v25.py')), run_name='__main__')
