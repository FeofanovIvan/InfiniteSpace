# Infinite Space v0.11 — Picture Navigation & MIKO Station

- Removed the old text-based planet/station menu. One large circular destination preview opens a 3×3 grid of illustrated target thumbnails. No reading required.
- Planet thumbnails were rendered once from the actual MIKO V3 equirectangular surface assets (PNG for inexpensive mobile rendering).
- Replaced schematic Earth station with Miko_Station_Full_NEW `station2d/orbital_station_2d.tscn` and its original module textures/shader/rotation.
- Clicking/tapping a location on the small solar map smoothly flies the MAIN camera to those world coordinates; ship stays at its original address. The small map cannot be dragged.
- Main camera center is marked by a yellow SQUARE on the map; ship remains a round cyan dot. Removed the top-right camera-return button and the old mini-map sight button.
- Joystick continues to return camera smoothly to the moving ship, while autopilot retains the large square STOP control.
- All eight MIKO V3 planets, solar orbits, persistent plasma, diagnostic logs, controls and autopilot targets are retained.
- No use of nine extra SubViewports or planet scene instances in UI.

## Controls

Tap the large planet picture at top right. Tap a small planet/station thumbnail to fly there automatically. Tap STOP to cancel. Tap a point on the solar chart to send the CAMERA there (ship does not move). Resume joystick flight to fly camera back smoothly to ship.

## Source assets

Station meshes/textures/scripts provided in Miko_Station_Full_NEW(1).zip. The Module archive is a subset of the same station files. MIKO planet UI previews are derived from textures in MIKO_SOLAR_SYSTEM_2D_V3_GODOT.
