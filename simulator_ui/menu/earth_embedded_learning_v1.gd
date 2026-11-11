extends "res://simulator_ui/menu/simulator_grid_5x2_v1.gd"
## Embedded Earth learning games, without a second Back overlay.
## The installed simulator grid/card order/scrolling is inherited unchanged.
## The original games own their visual controls, interactions, and voice/audio.

const EARTH_GAMES: Dictionary = {
    "mw__puzzles": "res://learning/scenes/features/puzzle/puzzle_game.tscn",
    "mw__animal_habitat": "res://learning/scenes/features/animal_habitat/animal_habitat_game.tscn",
    "mw__shopping_list": "res://learning/scenes/features/grocery/grocery_game.tscn",
    "mw__product_count": "res://learning/scenes/features/product_count/product_count_game.tscn",
}

var _original_earth_id: String = ""

func _v1151p24_open_card(game_id: String) -> void:
    super._v1151p24_open_card(game_id)
    if not EARTH_GAMES.has(game_id) or not _playing:
        return
    _original_earth_id = game_id
    # The embedded game's own exit button calls SFX.transition_to_scene(). The portal
    # sends the user back to their caller's card grid instead of leaving MIKA.
    var bridge: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if bridge != null and bridge.has_method("start_game"):
        bridge.call("start_game", str(EARTH_GAMES[game_id]))
    # A second MIKA wrapper button must never cover the embedded game's exit.
    _game_back.hide()
    # One embedded button calls reload_current_scene() for Try Again. Inside
    # a SubViewport that would reload the SHIP. Rewire at the host boundary,
    # leaving the original Grocery script and its button drawing untouched.
    if game_id == "mw__shopping_list":
        _configure_embedded_grocery_replay()

func _configure_embedded_grocery_replay() -> void:
    if _game_viewport.get_child_count() == 0:
        return
    var game: Node = _game_viewport.get_child(_game_viewport.get_child_count() - 1)
    var again: Button = game.get("again_button") as Button
    if again == null:
        return
    var old_callable: Callable = Callable(game, "_restart_game")
    if again.pressed.is_connected(old_callable):
        again.pressed.disconnect(old_callable)
    again.pressed.connect(_replay_grocery_within_viewport.bind(game))

func _replay_grocery_within_viewport(game: Node) -> void:
    if not is_instance_valid(game) or not game.is_inside_tree():
        return
    if _original_earth_id != "mw__shopping_list" or not _playing:
        return
    game.set("game_over", false)
    for prop in ["win_overlay", "error_flash", "basket_error_mark"]:
        var control: CanvasItem = game.get(prop) as CanvasItem
        if is_instance_valid(control):
            control.hide()
    game.call("_create_shopping_list")
    game.call("_spawn_products")
    game.call("_layout_for_viewport")
    game.call_deferred("_play_intro")

func _return_to_cards() -> void:
    super._return_to_cards()
    _original_earth_id = ""
    if is_instance_valid(_game_back):
        _game_back.show()
