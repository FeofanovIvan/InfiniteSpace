extends "res://addons/mika_ency_reader/galaxy_navigation_v573.gd"
## Encyclopedia v5.8: only labels; inherits approved geometry, input,
## responsive layout, live background and map-galaxy illustrations.
## Russian source and five localized interfaces share the same JSON keys.

func _section_title(section: String) -> String:
    return _ui("category_" + section)
