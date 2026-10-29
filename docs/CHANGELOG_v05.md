# v0.5 — Distant Procedural Plasma

- Added `scripts/FarPlasma.gd`, `shaders/far_plasma.gdshader`.
- Procedural volumetric-looking gas haze, filament wisps and ionized rings.
- Two very distant parallax levels, deterministic wrapped sector positions.
- A pooled maximum of seven shader rectangles; no particles, textures, spritesheets, or imported animations.
- Placed behind existing procedural starfield, comets, ship and controls.
- Diagnostics: `far_plasma_ready` and periodic `plasma_visible` count.
- Preserved camera return, dragging, joystick, map and reports from v0.4.3.
- Engine runtime validation: to be completed on a Godot installation.
