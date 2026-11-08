extends Node2D
## Fully playable four-part Bubble interactions, preserving previous 31 action and face presets.
## Modes: food/water, scrub in shower, gas, throw/fetch cosmic ball; teeth uses existing 10-tooth scene.
const MODE_FEED := "feed"
const MODE_DRINK := "drink"
const MODE_SHOWER := "shower"
const MODE_GAS := "gas"
const MODE_FETCH := "fetch"
const FLOOR_Y: float = 730.0

@onready var bubble: MikaBubbleBrain = $Bubble
@onready var shower: MikaShowerPlay = $Shower
@onready var gas_fx: Node2D = $GasFX
@onready var ball: MikaCosmoBall = $CosmoBall
@onready var hud: CanvasLayer = $HUD

var mode: String = MODE_SHOWER
var stage_rect := Rect2(355.0,95.0,1225.0,735.0)
var status: Label
var instructions: Label
var progress: ProgressBar
var mode_button: OptionButton
var planet_button: OptionButton
var sponge: Sprite2D
var sponge_drag: bool = false
var sponge_offset: Vector2 = Vector2.ZERO
var sponge_last: Vector2 = Vector2.ZERO
var ball_aim: bool = false
var aim_position: Vector2 = Vector2.ZERO
var fetch_state: String = "waiting"
var fetch_home: Vector2 = Vector2(705,555)
var target_after_throw: Vector2 = Vector2.ZERO
var _pickup_timer: float = 0.0
var _gas_started: bool = false
var _time: float = 0.0
var _completing: bool = false

func _ready() -> void:
    _make_ui()
    sponge = Sprite2D.new()
    sponge.texture = preload("res://bubble/assets/interaction/soft_sponge.png")
    sponge.scale = Vector2.ONE * 0.58
    sponge.z_index = 20
    add_child(sponge)
    shower.cleaning_progress.connect(_on_cleaning_progress)
    shower.cleaning_completed.connect(_shower_done)
    ball.ready_to_fetch.connect(_ball_stopped)
    bubble.auto_return_idle = false
    bubble.external_motion_control = true
    _switch_mode(MODE_SHOWER)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,Vector2(1600,900)),Color("#101B37"))
    # Stage background: spaceship care cabin, suitable for any of the four actions.
    draw_rect(stage_rect,Color("#1C3158"),true)
    for i in range(16):
        var x: float = 380.0 + float(i)*77.0
        draw_line(Vector2(x,96),Vector2(x,810),Color(0.50,0.72,1.0,0.055),1.0)
    draw_rect(Rect2(360,100,1210,710),Color(0.5,0.72,1.0,0.20),false,3.0)
    draw_line(Vector2(356,FLOOR_Y),Vector2(1580,FLOOR_Y),Color(.38,.73,.93,.6),4.0,true)
    draw_rect(Rect2(356,FLOOR_Y,1224,100),Color(0.05,0.11,0.24,0.49))
    for i in range(9):
        var xx: float = 432.0+float(i)*129.0
        draw_circle(Vector2(xx,76),2.3,Color(.63,.92,1.0,.45))
    if mode in [MODE_FEED, MODE_DRINK]:
        _draw_bowl()
    if mode == MODE_FETCH and ball_aim:
        draw_dashed_line(ball.position,aim_position,Color(.43,.97,.98,.85),3.0,16.0)
        draw_circle(aim_position,11.0,Color(.35,.95,.88,.22))

func _draw_bowl() -> void:
    var p := Vector2(1145,700)
    draw_circle(p+Vector2(0,36),76,Color(.07,.07,.26,.30))
    draw_colored_polygon(PackedVector2Array([p+Vector2(-78,-2),p+Vector2(78,-2),p+Vector2(59,52),p+Vector2(-57,52)]),Color("#6454B9"))
    draw_ellipse_placeholder(p)

func draw_ellipse_placeholder(p: Vector2) -> void:
    draw_arc(p,74.0,0,TAU,44,Color(.80,.72,1.0),6.0,true)
    if mode == MODE_FEED:
        for i in range(14):
            var x: float = -49.0+float((i*19)%100)
            var y: float = -14.0+float((i*13)%25)
            draw_circle(p+Vector2(x,y),6.0,Color(.95,.69,.32,1.0))
    else:
        draw_circle(p,52,Color(.25,.78,.98,.53))
        for i in range(3):
            draw_arc(p,18.0+float(i)*12.0,0,TAU,42,Color(.68,.96,1.0,.38),1.8,true)

func _make_ui() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(18,18)
    panel.custom_minimum_size = Vector2(312,0)
    var style := StyleBoxFlat.new()
    style.bg_color=Color(.035,.07,.14,.97)
    style.border_color=Color(.31,.65,.82,.65)
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    style.set_content_margin_all(15)
    panel.add_theme_stylebox_override("panel",style)
    hud.add_child(panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation",11)
    panel.add_child(col)
    _label(col,"БАББЛ • ИГРОВАЯ КОМНАТА",21,Color("#B5EDFF"))
    _label(col,"Мимика + уход + газ + космо-мяч",14,Color("#BBD4F5"))
    _label(col,"Выбери занятие:",16)
    mode_button = OptionButton.new()
    mode_button.custom_minimum_size=Vector2(274,44)
    for title in ["Душ и мытьё", "Еда из миски", "Питьё из миски", "Пук Баббла", "Космо-мяч — принеси"]:
        mode_button.add_item(title)
    mode_button.item_selected.connect(_select_mode)
    col.add_child(mode_button)
    _button(col,"Открыть чистку зубов",Callable(self,"_open_teeth"))
    _button(col,"Повторить действие",Callable(self,"_restart_mode"))
    _label(col,"Поверхность для мячика:",15)
    planet_button=OptionButton.new()
    planet_button.add_item("Твёрдая планета — отскоки")
    planet_button.add_item("Воздушная планета — парение")
    planet_button.custom_minimum_size.y=43
    planet_button.item_selected.connect(_change_planet)
    col.add_child(planet_button)
    progress = ProgressBar.new()
    progress.max_value=100
    progress.value=0
    progress.custom_minimum_size=Vector2(273,27)
    col.add_child(progress)
    status=_label(col,"",16,Color("#A6FADE"))
    status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    status.custom_minimum_size.y=72
    instructions=_label(col,"",16,Color("#D6E6FF"))
    instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    instructions.custom_minimum_size.y=128
    _label(col,"Godot 4.7.1 • без обновлений",13,Color("#88B4D4"))
    _button(col,"Каталог 31 движения + 17 эмоций",Callable(self,"_open_unified"))

func _label(parent: Node, text: String, size: int, color: Color=Color("#E6F3FF")) -> Label:
    var l:=Label.new()
    l.text=text
    l.add_theme_color_override("font_color",color)
    l.add_theme_font_size_override("font_size",size)
    parent.add_child(l)
    return l

func _button(parent: Node, title: String, call: Callable) -> Button:
    var b:=Button.new()
    b.text=title
    b.custom_minimum_size.y=43
    b.pressed.connect(call)
    parent.add_child(b)
    return b

func _select_mode(index: int) -> void:
    var ids: Array[String] = [MODE_SHOWER,MODE_FEED,MODE_DRINK,MODE_GAS,MODE_FETCH]
    _switch_mode(ids[index])

func _switch_mode(id: String) -> void:
    mode=id
    sponge_drag=false
    ball_aim=false
    _completing=false
    _gas_started=false
    shower.end_shower()
    gas_fx.call("set_state",false,0.0,Vector2.ZERO)
    progress.visible=id==MODE_SHOWER
    sponge.visible=id==MODE_SHOWER
    ball.visible=id==MODE_FETCH
    bubble.external_motion_control=true
    bubble.scale=Vector2.ONE*(0.70 if id!=MODE_FETCH else 0.52)
    bubble.position=Vector2(965,535) if id!=MODE_FETCH else fetch_home
    fetch_state="waiting"
    match id:
        MODE_SHOWER:
            bubble.play_action("bath")
            shower.start_at(bubble.position)
            sponge.position=Vector2(1352,663)
            progress.value=0
            status.text="Душ работает. Баббл расслабился."
            instructions.text="1. Возьми жёлтую губку справа.\n2. Проводи по тёмным пятнам на теле.\n3. Очисти не менее 93% загрязнений."
        MODE_FEED:
            bubble.play_action("eat")
            status.text="Баббл кушает из миски."
            instructions.text="Рот и тело двигаются вместе. Нажми «Повторить действие», чтобы покормить ещё раз."
        MODE_DRINK:
            bubble.play_action("drink")
            status.text="Баббл пьёт воду из миски."
            instructions.text="Баббл наклоняется и делает короткие глотательные движения."
        MODE_GAS:
            bubble.play_action("gas")
            _gas_started=true
            status.text="Баббл накапливает газ…"
            instructions.text="Наблюдай: напряжение → выделение газа → смущение → облегчение. Нажми «Повторить» для нового пука."
        MODE_FETCH:
            bubble.play_action("idle")
            ball.reset_at(Vector2(531,674),planet_button.selected==1)
            fetch_state="waiting"
            status.text="Баббл ждёт броска космо-мяча."
            instructions.text="Возьми космо-мяч слева от Баббла. Потяни к точке броска и отпусти. Он отскочит от пола или зависнет в воздухе."
    queue_redraw()

func _restart_mode() -> void:
    _switch_mode(mode)

func _change_planet(_idx: int) -> void:
    if mode==MODE_FETCH:
        _switch_mode(MODE_FETCH)

func _open_teeth() -> void:
    get_tree().change_scene_to_file("res://bubble/scenes/brush_minigame.tscn")

func _open_unified() -> void:
    get_tree().change_scene_to_file("res://bubble/scenes/unified_lab.tscn")

func _on_cleaning_progress(ratio: float) -> void:
    progress.value=ratio*100.0
    if mode==MODE_SHOWER and not _completing:
        status.text="Очищено: %d%% / цель 93%%"%int(ratio*100.0)

func _shower_done() -> void:
    if mode!=MODE_SHOWER or _completing:
        return
    _completing=true
    sponge.visible=false
    bubble.play_action("wave")
    bubble.set_expression("happy")
    status.text="Баббл чистый и довольный!"
    instructions.text="Поздравляем! Грязь удалена движениями губки, а не по таймеру."

func _ball_stopped() -> void:
    if mode!=MODE_FETCH or fetch_state!="flying":
        return
    fetch_state="chasing"
    bubble.play_action("accelerate")
    bubble.set_expression("excited")
    status.text="Баббл бежит к мячу!"

func _process(delta: float) -> void:
    _time+=delta
    if mode==MODE_GAS:
        var p:float=bubble.get_progress()
        gas_fx.call("set_state",true,p,bubble.position+Vector2(120,82))
        if p>=.38 and p<.80:
            status.text="Пфф! Баббл испускает газ!"
        elif bubble.finished:
            status.text="Бабблу стало легче!"
    if mode!=MODE_FETCH:
        return
    match fetch_state:
        "chasing":
            var target:Vector2=Vector2(ball.position.x-18.0,fetch_home.y)
            bubble.position=bubble.position.move_toward(target,340.0*delta)
            if bubble.finished: bubble.play_action("accelerate")
            if absf(bubble.position.x-target.x)<53.0:
                fetch_state="picked"
                _pickup_timer=0.0
                bubble.play_action("contract")
                bubble.set_expression("happy")
                status.text="Мяч пойман. Баббл подбирает его."
        "picked":
            _pickup_timer+=delta
            ball.set_carried(bubble.position+Vector2(49.0,-55.0))
            if _pickup_timer>0.55:
                fetch_state="returning"
                bubble.play_action("turn_move_left")
                status.text="Баббл несёт мяч обратно!"
        "returning":
            bubble.position=bubble.position.move_toward(fetch_home,280.0*delta)
            ball.set_carried(bubble.position+Vector2(49.0,-55.0))
            if bubble.finished: bubble.play_action("accelerate")
            if bubble.position.distance_to(fetch_home)<12.0:
                fetch_state="delivered"
                ball.reset_at(Vector2(527,673),planet_button.selected==1)
                bubble.play_action("wave")
                bubble.set_expression("happy")
                status.text="Баббл принёс мяч! Можно бросить снова."
                instructions.text="Перетащи мяч и отпусти для следующего броска."
        _:
            pass

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if event.pressed:
            _touch_down(event.position)
        else:
            _touch_up(event.position)
    elif event is InputEventMouseMotion:
        _touch_move(event.position)
    elif event is InputEventScreenTouch:
        if event.pressed: _touch_down(event.position)
        else: _touch_up(event.position)
    elif event is InputEventScreenDrag:
        _touch_move(event.position)

func _touch_down(point:Vector2) -> void:
    if mode==MODE_SHOWER and sponge.visible and point.distance_to(sponge.position)<90.0:
        sponge_drag=true
        sponge_offset=point-sponge.position
        sponge_last=sponge.position
        get_viewport().set_input_as_handled()
    elif mode==MODE_FETCH and fetch_state in ["waiting","delivered"] and point.distance_to(ball.position)<74.0:
        ball_aim=true
        aim_position=point
        get_viewport().set_input_as_handled()

func _touch_move(point:Vector2) -> void:
    if mode==MODE_SHOWER and sponge_drag:
        var next:Vector2=point-sponge_offset
        next.x=clampf(next.x,stage_rect.position.x+30,stage_rect.end.x-30)
        next.y=clampf(next.y,stage_rect.position.y+40,stage_rect.end.y-30)
        var dist:float=next.distance_to(sponge_last)
        sponge.position=next
        if dist>=1.5:
            var steps:int=clampi(int(ceil(dist/12.0)),1,32)
            for i in range(1,steps+1):
                var p:Vector2=sponge_last.lerp(next,float(i)/float(steps))
                shower.scrub(p,dist/float(steps))
                if not shower.running: break
        sponge_last=next
        get_viewport().set_input_as_handled()
    elif mode==MODE_FETCH and ball_aim:
        aim_position=Vector2(clampf(point.x,480.0,1510.0),clampf(point.y,320.0,690.0))
        queue_redraw()
        get_viewport().set_input_as_handled()

func _touch_up(point:Vector2) -> void:
    if sponge_drag:
        sponge_drag=false
        get_viewport().set_input_as_handled()
    if mode==MODE_FETCH and ball_aim:
        ball_aim=false
        var target:Vector2=Vector2(clampf(point.x,570.0,1480.0),clampf(point.y,360.0,690.0))
        if planet_button.selected==0: target.y=685.0
        ball.launch_to(target)
        fetch_state="flying"
        status.text="Космо-мяч летит!"
        instructions.text="Подожди приземления или зависания: Баббл автоматически отправится за ним."
        queue_redraw()
        get_viewport().set_input_as_handled()
