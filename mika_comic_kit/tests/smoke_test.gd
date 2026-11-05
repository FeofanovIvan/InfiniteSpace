extends SceneTree
## In terminal after installing Godot 4.7.1:
## godot --headless --path . --editor --import
## godot --headless --path . --script res://mika_comic_kit/tests/smoke_test.gd
const Registry = preload("res://mika_comic_kit/scripts/comic_registry.gd")
const Factory = preload("res://mika_comic_kit/scripts/comic_factory.gd")

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var root := Control.new()
    root.size=Vector2(1280,720)
    get_root().add_child(root)
    var errors: int=0
    for id in Registry.all_ids("lettering"):
        var item = Factory.make_text(id,"MIKA says hello!",Vector2(630,180))
        if item == null:
            errors+=1
            continue
        root.add_child(item)
        item.set_home(Vector2(70,60))
        item.seek_entrance(0.7)
        item.queue_redraw()
        root.remove_child(item)
        item.free()
    for id in Registry.all_ids("panels"):
        var stage=Factory.make_panel(id)
        if stage == null:
            errors+=1
            continue
        stage.size=Vector2(1280,720)
        root.add_child(stage)
        stage.show_panel(id)
        root.remove_child(stage)
        stage.free()
    for id in Registry.all_ids("transitions"):
        var stage=Factory.make_transition(id)
        if stage == null:
            errors+=1
            continue
        stage.size=Vector2(1280,720)
        root.add_child(stage)
        for q in [0.0,0.25,0.5,0.75,1.0]:
            Factory.seek_transition(stage,id,q)
        root.remove_child(stage)
        stage.free()
    root.queue_free()
    if errors>0:
        push_error("MIKA COMIC KIT smoke test errors: " + str(errors))
        quit(1)
    else:
        print("MIKA COMIC KIT: ALL 29 COMPONENT IDs CREATED OK")
        quit(0)
