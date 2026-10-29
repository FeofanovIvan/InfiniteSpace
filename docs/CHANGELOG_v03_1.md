# Infinite Space v0.3.1 — GDScript parser fix

- `scripts/MiniMap.gd`, line 149: `origin_relative` now has explicit `Vector2` type.
- Fixes: `Cannot infer the type of "origin_relative" variable because the value doesn't have a set type.`
- No changes to the starfield, ship, controls, or navigation behavior.
- Intended for Godot 4.x. No Godot runtime available in the build environment, so open in editor and check errors after importing.
