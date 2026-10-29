# Infinite Space v0.20 — clean black hole and ship menu button

- The MIKO menu ship is baked into `assets/ui/miko_ship_menu_circle.png` as one 256x256 RGBA asset. The HUD uses a fixed 42x42 TextureButton (no oversized nested TextureRect).
- The black hole uses a new isolated semi-transparent accretion disk sprite, not the old flat concentric rings. It has an irregular turbulent disk, strongly black event-horizon region and warped upper arc. Image-based visual from a new generated draft with the background isolated.
- The black-hole display shader now changes brightness by only 0.6%; no simulated rotation of the artwork, so it doesn't look like a spinning flat sign.
- All other files from v0.19 retained, including 14 NPC, four simultaneous asteroids, planet orbit logic, UI and reports.
- Note: this is a stylised astronomical visual; gravitational lensing is part of the artwork, not a physical light-ray tracer.
- To replace it with a future hand-painted image, keep a transparent RGBA PNG at `blackhole2d/textures/black_hole_cinematic.png` and the same aspect ratio, or adjust diameter_px.
