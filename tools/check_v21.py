from pathlib import Path
import struct
p = Path(__file__).resolve().parents[1]
files = ["assets/bridge/bridge_cockpit.png", "assets/bridge/simulator_console.png", "assets/bridge/shop_console.png", "assets/ui/bridge_back.png", "assets/ui/bridge_settings.png"]
for f in files:
    path=p/f
    assert path.exists(), f
    data=path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f
    w,h=struct.unpack(">II", data[16:24])
    assert w > 100 and h > 100, (f,w,h)
bridge=(p/"scripts/MikoMainMenu.gd").read_text()
main=(p/"scripts/Main.gd").read_text()
for term in ["SIMULATOR_TEXTURE", "SHOP_TEXTURE", "BRIDGE_TEXTURE", "set_stats", "close_menu", "_open_simulator", "_open_shop", "_open_settings", "_back_to_hub", "CHAR_DIR", "miko.png"]:
    assert term in bridge,term
assert "main_menu.set_stats(status_hud.crystal_count, 0, 0.0)" in main
assert "main_menu.open_menu(get_viewport_rect().size)" in main
assert "get_tree().paused = true" in main
assert "main_menu.closed.connect(_on_modal_closed)" in main
for f in ["MikoMainMenu.gd", "Main.gd"]:
    for i,line in enumerate((p/"scripts"/f).read_text().splitlines(),1):
        prefix=line[:len(line)-len(line.lstrip())]
        assert " " not in prefix, (f,i,"mixed indentation")
print("OK: v0.21 bridge sources, images, characters slots, navigation, resources")
