extends Control
## Interactive gallery: each L/P/X ID is a real Godot element, not a static screenshot.
const Registry = preload("res://mika_comic_kit/scripts/comic_registry.gd")
const Layout = preload("res://mika_comic_kit/scripts/comic_layout.gd")
const StageScene = preload("res://mika_comic_kit/scenes/ComicStage.tscn")
const ItemScene = preload("res://mika_comic_kit/scenes/ComicTextItem.tscn")
const Ink: Color = Color("231638")
const BG: Color = Color("13172f")
const Purple: Color = Color("6d4ad9")

var selected_group: String = "lettering"
var selected_id: String = "L01"
var preview_holder: PanelContainer
var stage
var display_item
var stage_frame
var hint: Label
var progress: HSlider
var aspect_option: OptionButton
var play_button: Button
var playing: bool = false
var current_ratio: float = 16.0/9.0
var animated_time: float = 0.0
var sidebar: VBoxContainer
var item_buttons: Dictionary = {}
var small_label: Label

func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = BG
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var titlebar := PanelContainer.new()
    titlebar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    titlebar.offset_bottom = 62
    titlebar.add_theme_stylebox_override("panel",_style(Color("211939"),0,0))
    add_child(titlebar)
    var title_h := HBoxContainer.new()
    title_h.add_theme_constant_override("separation",22)
    titlebar.add_child(title_h)
    title_h.add_child(_header("MIKA  /  COMIC ELEMENT LIBRARY",22,Color.WHITE))
    title_h.add_spacer(false)
    var page_button := Button.new()
    page_button.text="▶  PAGE 01 · 71s INTRO"
    page_button.pressed.connect(func():get_tree().change_scene_to_file("res://mika_comic_kit/page01/Page01LibraryDemo.tscn"))
    title_h.add_child(page_button)
    var row := HBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.offset_top = 70
    row.offset_bottom = -12
    row.add_theme_constant_override("separation",12)
    add_child(row)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size=Vector2(256,0)
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    row.add_child(scroll)
    sidebar=VBoxContainer.new()
    sidebar.add_theme_constant_override("separation",6)
    sidebar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    scroll.add_child(sidebar)
    for group_data in [["LETTERING  L01–L12","lettering"],["PANEL COMPOSITIONS  P01–P07","panels"],["TRANSITIONS  X01–X10","transitions"]]:
        sidebar.add_child(_header(str(group_data[0]),13,Color("cbb6fb")))
        for id in Registry.all_ids(str(group_data[1])):
            var entry: Dictionary = Registry.catalog().get(str(group_data[1]),{}).get(id,{})
            var b := Button.new()
            b.text = id + "  " + str(entry.get("name", entry.get("semantic", "Comic element")))
            b.alignment = HORIZONTAL_ALIGNMENT_LEFT
            b.custom_minimum_size=Vector2(234,35)
            b.pressed.connect(_select.bind(str(group_data[1]),id))
            sidebar.add_child(b)
            item_buttons[id]=b
    var column := VBoxContainer.new()
    column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    column.size_flags_vertical=Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation",8)
    row.add_child(column)
    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation",8)
    column.add_child(controls)
    controls.add_child(_header("LANDSCAPE COVER",13,Color("cbb6fb")))
    aspect_option = OptionButton.new()
    for name in ["16:9 · YouTube", "21:9 · Ultrawide", "4:3 · Tablet", "20:9 · Phone", "16:10 · Laptop"]:
        aspect_option.add_item(name)
    aspect_option.item_selected.connect(_aspect_changed)
    controls.add_child(aspect_option)
    var reduced := CheckBox.new()
    reduced.text="Reduce motion"
    reduced.toggled.connect(func(flag: bool):stage.reduce_motion=flag)
    controls.add_child(reduced)
    preview_holder=PanelContainer.new()
    preview_holder.add_theme_stylebox_override("panel",_style(Color("302847"),3,18))
    preview_holder.size_flags_vertical=Control.SIZE_EXPAND_FILL
    preview_holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    column.add_child(preview_holder)
    stage_frame=Control.new()
    stage_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
    preview_holder.add_child(stage_frame)
    stage_frame.resized.connect(_frame_changed)
    stage = StageScene.instantiate()
    stage_frame.add_child(stage)
    stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
    var foot := HBoxContainer.new()
    column.add_child(foot)
    play_button=Button.new()
    play_button.text="▶ PLAY"
    play_button.pressed.connect(_toggle_play)
    foot.add_child(play_button)
    progress=HSlider.new()
    progress.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    progress.min_value=0.0
    progress.max_value=1.0
    progress.step=0.001
    progress.value_changed.connect(_seek)
    foot.add_child(progress)
    small_label=_header("0%",12,Color.WHITE)
    foot.add_child(small_label)
    hint=_header("",16,Color("f8eaf9"))
    hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    hint.custom_minimum_size=Vector2(0,48)
    column.add_child(hint)
    get_viewport().size_changed.connect(_frame_changed)
    _select("lettering","L01")
    _frame_changed()

func _style(color:Color,border:int,radius:int) -> StyleBoxFlat:
    var box:=StyleBoxFlat.new()
    box.bg_color=color
    box.set_corner_radius_all(radius)
    if border>0:
        box.set_border_width_all(border)
        box.border_color=Color("e6a7f5")
    return box

func _header(s:String,font_px:int,c:Color) -> Label:
    var label:=Label.new()
    label.text=s
    label.add_theme_font_size_override("font_size",font_px)
    label.add_theme_color_override("font_color",c)
    label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    return label

func _frame_changed() -> void:
    if stage_frame==null or stage==null:
        return
    var available: Vector2 = stage_frame.size - Vector2(14,14)
    if available.x<5 or available.y<5:
        return
    var fit:float=minf(available.x/current_ratio,available.y)
    stage.size=Vector2(fit*current_ratio,fit)
    stage.position=(stage_frame.size-stage.size)*0.5
    _refresh()

func _aspect_changed(index:int) -> void:
    var ratios: Array[float]=[16.0/9.0,21.0/9.0,4.0/3.0,20.0/9.0,16.0/10.0]
    current_ratio=ratios[index]
    _frame_changed()

func _select(group:String,id:String) -> void:
    selected_group=group
    selected_id=id
    playing=false
    animated_time=0.0
    if progress!=null:
        progress.set_value_no_signal(0.0)
    if play_button!=null:
        play_button.text="▶ PLAY"
    for k in item_buttons:
        item_buttons[k].modulate=Color("ffe2ff") if k==id else Color("9ca2bd")
    _refresh()

func _seek(value:float) -> void:
    animated_time=value
    _refresh()

func _toggle_play() -> void:
    playing=not playing
    play_button.text="Ⅱ PAUSE" if playing else "▶ PLAY"
    set_process(true)

func _process(delta:float) -> void:
    if playing:
        animated_time += delta/2.2
        if animated_time>=1.0:
            animated_time=0.0
        progress.set_value_no_signal(animated_time)
        _refresh()

func _refresh() -> void:
    if stage==null or stage.size.x<5:
        return
    if display_item!=null and is_instance_valid(display_item) and (selected_group!="lettering" or display_item.element_id!=selected_id):
        display_item.queue_free()
        display_item=null
    var detail:Dictionary=Registry.catalog().get(selected_group,{}).get(selected_id,{})
    var color_data: String = ""
    if selected_group=="lettering":
        color_data = "    ·    Font " + str(detail.get("font_id","F02")) + "    ·    Fill " + str(detail.get("fill_color_id","C02")) + "    ·    Text " + str(detail.get("text_color_id","C01"))
    hint.text=selected_id+"  ·  "+str(detail.get("name",""))+color_data+"\n"+str(detail.get("semantic",detail.get("godot_strategy","")))
    if progress!=null:
        progress.editable=selected_group!="panels"
    if small_label!=null:
        small_label.text=str(int(animated_time*100.0))+"%"
    if selected_group=="lettering":
        stage.show_panel("P01","city")
        var samples:Dictionary={
            "L01":["A world above the clouds.",""],
            "L02":["What's happening?",""],
            "L03":["The Crossroads of Worlds",""],
            "L04":["EMERGENCY!","Chronostorm approaching!"],
            "L05":["INCOMING TRANSMISSION","Time and space are shifting."],
            "L06":["I think I heard something...",""],
            "L07":["Could it be real?",""],
            "L08":["AAAAAH!",""],
            "L09":["WHOOSH!",""],
            "L10":["AERELIA","A WORLD ABOVE THE CLOUDS"],
            "L11":["AERELIA · YEAR 2180",""],
            "L12":["Mika! Can you hear me?","(OFFSCREEN)"]
        }
        var texts:Array=samples.get(selected_id,["Hello!",""])
        if display_item!=null and is_instance_valid(display_item):
            display_item.seek_entrance(animated_time)
            return
        display_item=ItemScene.instantiate()
        stage.add_child(display_item)
        var scale_factor:float=minf(stage.size.x/1280.0,stage.size.y/720.0)
        var rect_size:Vector2=Vector2(510,175)*scale_factor
        if selected_id in ["L10"]:
            rect_size=Vector2(730,215)*scale_factor
        if selected_id in ["L08"]:
            rect_size=Vector2(440,230)*scale_factor
        if selected_id in ["L11"]:
            rect_size=Vector2(480,95)*scale_factor
        display_item.configure(selected_id,str(texts[0]),str(texts[1]),rect_size,Vector2(-1000,-1000),scale_factor)
        var protect: Array[Rect2]=Layout.normalized_protected([[0.40,0.21,0.22,0.43]],stage.size)
        var result:Rect2=Layout.locate(stage.size,rect_size,"bottom_left",protect)
        display_item.set_home(result.position)
        display_item.seek_entrance(animated_time)
    elif selected_group=="panels":
        if selected_id=="P03":
            stage.show_panel(selected_id,"disaster_red","disaster_magenta")
        else:
            stage.show_panel(selected_id,"city","mica_balcony","disaster_magenta")
    else:
        stage.show_transition(selected_id,animated_time,"city","mica_balcony")
