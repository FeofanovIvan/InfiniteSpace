# InfiniteSpace v66 — pastel mirrored HUD without graphic backgrounds

Base: installed v65 (planet HUD unchanged since v64). Modified script: `planet_hub/scripts/bottom_hud.gd` only.

- Center: midnight blue `#03142b` rounded rectangular counter with cyan border, actual shard `res://asteroid_assets/fragments/04_blue/crystal_wedge.png` and large white live crystal count.
- Left simulator: softly blue `#cbeaf4` outward rounded wing with inward taper and cyan outline; helmet icon and live 6-language label.
- Right launch: softly beige `#edddc8` mirrored wing; spaceship icon and live 6-language label.
- Touch/hover/press state preserved; Buttons retain `simulator_pressed` and `flight_pressed` signals; no bitmap background.
- Adapts width and screen height; button left and right anchors remain at screen edges; resource counter remains centered.
- No changes to missions, landing, backgrounds, representatives, crystals, gameplay, language DB, or auto-pilot.

Source Git blob: `1e8a41c045277621483db913fe203d6777f8705c`, Target Git blob: `dc6f981f120c9dbd82a603367c2171579c9ab72a`.

Godot runtime F5 unavailable in build environment; verify on Mac.
