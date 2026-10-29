# v0.22 — Miko / Moon / Larger giants / Rare asteroids

1. Original Miko character PNG now included and automatically loaded by bridge hub.
2. Moon sprite orbits the MOVING Earth, not the fixed screen origin.
3. Gas giants resized; main planet orbital radii and periods unchanged.
4. One asteroid at a time; 60–120 second spawn attempts, first 40–65 seconds.
5. Rare cinematic solar flybys use a deterministic curved path. These are visual, not true gravity.
6. Legacy statically checked v19 and navigation conditions updated to reflect the new design.
7. Regression check: `python3 tools/check_v22.py`; actual rendering and parser test require Godot.
