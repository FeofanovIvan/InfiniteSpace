# Infinite Space v0.14 — Milky Way region + MIKO black hole

## New fixed world landmarks
- One colorful Milky Way gas-and-dust band, centered on world coordinate `(6900, -3100)` and spanning about `8000 × 4000` game units. Authored offline by a seeded procedural algorithm and stored in a **single 2048×1024 RGBA PNG** (`assets/cosmic/milky_way_2048.png`), so runtime generation is unnecessary. Image remains anchored in absolute world space.
- One MIKO Black Hole 2D (source: supplied `Miko_BlackHole_Full_NEW` archive). Located at **`(6500, -2950)`**, well outside Neptune's orbital radius of 1950. Accretion disk shader remains animated and approximates gravitational lensing using the canvas screen texture. Approximate displayed diameter **405 game pixels**, not meant to represent real physical scale.
- No new destination was added to the children's navigation/autopilot menu. All 8 planets and the planet-station overlays, the six original autoplay destinations and the docking station remain unchanged.
- On mobile, the galactic band is rendered as **one texture quad** only when near the scene; no realtime CPU FBM, no large GPU particle system. The black-hole effect is hidden when offscreen.

## Temporary test navigation
- Purple **diamond** in the round mini-map points to the distant black hole, even if off the chart. Tapping it pans **only the camera**, not the ship.
- Desktop **B** focuses the camera on the black hole for quick testing, without moving the ship.
- To hide the secret location from children, set `DEBUG_SHOW_BLACK_HOLE_ON_MAP: bool = false` in `scripts/Main.gd`. That also disables the B shortcut; the black hole remains in world coordinates.
- The existing yellow viewport footprint, map tap-to-camera, joystick, stop/autopilot, ship position and logs are unchanged.

## Testing on Mac
1. From the project's root run `python3 tools/check_v14.py`.
2. Run `bash tools/verify_project.command` for Godot's headless parser and save diagnostic log. If it fails, share the `reports/Godot_Preflight_*.log` file.
3. Launch F5. Tap the mini-map's purple diamond or press B to view the black hole and galactic band. Verify the galaxy doesn't move independently from its world position if you pan away and back.
4. Start joystick movement: the main camera should smoothly return to the ship. Choosing a planet autopilot goal should still work.

**Artistic note:** A broad galactic streak next to the Solar System is a visual game-location abstraction. It is not an accurate representation of the Milky Way as seen from the Sun, nor is the screen-lensing shader a physical simulation.
