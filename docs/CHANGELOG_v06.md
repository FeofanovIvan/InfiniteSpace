# Infinite Space v0.6 — Anchored Nebulae & Solar System

- Replaced time-recreated plasma formations with fixed deterministic sparse grid objects (2048-world-unit sky cells, seed by cell coordinate).
- Centers jitter by at most 7%; with max 1010×525 rectangles and rotated corners the minimum adjacent-center distance is >1761 px, so adjacent gas objects cannot overlap.
- Non-circular warped filaments, ragged walls and ion streams; <=3% brightness breathing; silhouettes and world positions stay stationary.
- Imported **original user-provided** MIKO Sun shaders/textures and MIKO Planet2D Earth shaders/textures from ZIPs, without redrawing them.
- Sun stationary at world origin. Earth rotates on its axis while orbiting Sun once every 150 seconds at radius 430 game world units.
- Spawn ship at (325,95), nearby Earth; main camera remains free-pan / smoothly follow on movement.
- Navigation map draws Sun, Earth, ship and camera center (no star background markers). Default map zoom adjusted to show the solar orbit.
- Added diagnostics for solar system and existing plasma count.

**Note:** orbital timings and distances are deliberately stylized for a children's exploration game; they are not astronomical-scale physics. Runtime graphics require Godot 4.x GL Compatibility; test on Android for performance.
