# Infinite Space v0.19 — Compact Flight HUD and Lower Traffic

- NPC limit: 28 -> 14, with existing ten weighted roles unchanged.
- Asteroid concurrent cap: 14 -> 4. Initial wave: 5 -> 1. Spawning interval: 3–5.2s -> 12–20.8s. Crystal drops and collisions are unchanged.
- Compact 126-unit fuel panel: 7 short colored bars and a blue crystal icon, no ship art and no numeric count.
- Player ship sprite used as the small circular top-down main-menu button (replaces store); global-flight button stays above it.
- New accessible but intentionally nonfunctional MIKO main-menu overlay, closed with X. Flight resumes on closing.
- The former white airplane icon is no longer used on the galactic map either.
- Historical shop module is kept on disk for future work, but cannot be opened from the flight HUD.
- No changes to autopilot, ship movement, landing, solar system, or camera.
- Tests are source/static only unless verified on user's Godot runtime.
