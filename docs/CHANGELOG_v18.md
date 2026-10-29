# Infinite Space v0.18 — Asteroids + visual polish + compact HUD

- 28 NPC instead of 43 (34.9% fewer), weighted class probabilities retained.
- Original 4 MIKO asteroid PNGs and their 36 fragment sprites copied into `asteroid_assets/`.
- `AsteroidField.gd`: spawned incoming asteroids, world-coordinate motion/turns, collision checks with Sun, all planets, Earth station, NPC, player; shattered fragments of the correct type.
- Stone asteroid drops only rocks, not collectible minerals. Collection is NOT enabled yet.
- Visual fragments persist during the current play session, settle after drifting; up to 350 are rendered/stored at once to protect mobile devices. Persistent save/load across launches is not implemented.
- MIKO black hole: new precomputed 768px cinematic accretion-disc texture (CPU procedural) with low-cost faint animated brightness. Old shader remains for reference but is not active.
- Subdued gas formations and large festive star twinkles.
- Right resource panel 188px wide, 43px high; ship icon 26px beside seven fuel segments, crystal 23px; 44px map/shop buttons.
- Asteroid collisions are geometric world-space distance checks, not full 2D rigid body physics. No damage/health, collection, or inventory yet. All impact types logged in reports.
