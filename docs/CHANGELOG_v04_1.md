# Infinite Space v0.4.1 — GDScript parser fix

- Fixed `scripts/DistantEvents.gd` in `_draw()` around original line 93. The nested `pow(maxf(sin(...)))` call in v0.4 was missing one closing parenthesis.
- Extracted `twinkle_phase` into its own typed `float` variable to make the expression simpler and more robust.
- `Main.gd` preload failure was a consequence of the invalid imported script; no changes to the camera, ship, minimap, joystick, reports or distant-event behavior were needed.
- Static source and ZIP integrity checks were run. Godot runtime verification was not available in this environment.
