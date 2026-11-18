extends Control
## Vector art for recognisable items, including a three-bin symbol set.
var kind: String = "paper"
var shade: Color = Color("#e1f4ff")

func set_item_kind(value: String) -> void:
    kind = value
    queue_redraw()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func _draw() -> void:
    var center: Vector2 = size * 0.5
    var k: float = minf(size.x, size.y) / 112.0
    if k <= 0.0:
        return
    draw_set_transform(center, 0.0, Vector2.ONE * k)
    match kind:
        "paper", "newspaper":
            draw_rect(Rect2(-29.0, -40.0, 58.0, 80.0), Color("#f2f9ff"), true)
            draw_rect(Rect2(-29.0, -40.0, 58.0, 80.0), Color("#396eb5"), false, 3.0)
            for i in range(5):
                var y: float = -22.0 + float(i) * 13.0
                draw_line(Vector2(-19.0, y), Vector2(18.0, y), Color("#6b91b6"), 3.0, true)
        "plastic_bottle":
            draw_rect(Rect2(-11.0, -43.0, 22.0, 12.0), Color("#ceeaff"), true)
            draw_rect(Rect2(-19.0, -30.0, 38.0, 68.0), Color("#b2e4ff"), true)
            draw_rect(Rect2(-19.0, -30.0, 38.0, 68.0), Color("#298ac0"), false, 3.0)
            draw_rect(Rect2(-20.0, 0.0, 40.0, 15.0), Color("#1f83bc"), true)
        "glass_jar":
            draw_rect(Rect2(-29.0, -32.0, 58.0, 69.0), Color(0.55, 0.94, 0.89, 0.70), true)
            draw_rect(Rect2(-30.0, -40.0, 60.0, 10.0), Color("#bdcbd5"), true)
            draw_rect(Rect2(-29.0, -32.0, 58.0, 69.0), Color("#54d9d1"), false, 3.0)
            draw_line(Vector2(-14.0, -22.0), Vector2(-14.0, 26.0), Color(0.94, 1.0, 1.0, 0.8), 5.0, true)
        "aluminum_can":
            draw_rect(Rect2(-21.0, -36.0, 42.0, 72.0), Color("#cbd9e9"), true)
            draw_rect(Rect2(-23.0, -39.0, 46.0, 9.0), Color("#f2f7ff"), true)
            draw_rect(Rect2(-23.0, 29.0, 46.0, 9.0), Color("#a5bed1"), true)
            draw_rect(Rect2(-20.0, -10.0, 40.0, 26.0), Color("#4b99dc"), true)
        "cardboard":
            draw_rect(Rect2(-37.0, -25.0, 74.0, 61.0), Color("#c78b48"), true)
            draw_rect(Rect2(-37.0, -25.0, 74.0, 61.0), Color("#825127"), false, 3.0)
            draw_line(Vector2(-37.0, -25.0), Vector2(0.0, -41.0), Color("#ffd69a"), 4.0)
            draw_line(Vector2(37.0, -25.0), Vector2(0.0, -41.0), Color("#ffd69a"), 4.0)
            draw_line(Vector2(0.0, -41.0), Vector2(0.0, 36.0), Color("#9e6330"), 3.0)
        "banana_peel":
            draw_arc(Vector2(-2.0, -5.0), 34.0, 0.05, 2.7, 40, Color("#ffdc63"), 12.0, true)
            draw_line(Vector2(-28.0, 17.0), Vector2(-39.0, 38.0), Color("#ffe68d"), 10.0, true)
            draw_line(Vector2(23.0, 19.0), Vector2(38.0, 30.0), Color("#ffd544"), 10.0, true)
        "apple_core":
            draw_circle(Vector2(0.0, 0.0), 29.0, Color("#e7e9ac"))
            draw_circle(Vector2(-24.0, -22.0), 18.0, Color("#f77a72"))
            draw_circle(Vector2(23.0, 20.0), 18.0, Color("#f77a72"))
            draw_line(Vector2(1.0, -29.0), Vector2(6.0, -43.0), Color("#825435"), 5.0, true)
            draw_circle(Vector2(14.0, -40.0), 9.0, Color("#63d99b"))
        "leaf":
            draw_colored_polygon(PackedVector2Array([Vector2(-40.0, 15.0), Vector2(-5.0, -43.0), Vector2(36.0, -28.0), Vector2(27.0, 28.0), Vector2(-10.0, 40.0)]), Color("#6cd895"))
            draw_line(Vector2(-29.0, 29.0), Vector2(27.0, -23.0), Color("#287e58"), 4.0, true)
        "orange_peel":
            draw_arc(Vector2(0.0, -9.0), 34.0, 0.1, 2.8, 32, Color("#ffa844"), 15.0, true)
            draw_arc(Vector2(0.0, -9.0), 20.0, 0.2, 2.7, 32, Color("#ffd17f"), 3.0, true)
        "coffee_grounds":
            draw_rect(Rect2(-30.0, 4.0, 60.0, 30.0), Color("#a36d51"), true)
            draw_arc(Vector2(0.0, 3.0), 30.0, 0.0, PI, 30, Color("#6a3c30"), 8.0, true)
            for i in range(10):
                var xx: float = float((i * 19) % 53) - 26.0
                var yy: float = float((i * 11) % 18) + 7.0
                draw_circle(Vector2(xx, yy), 3.0, Color("#5d3929"))
        "chip_bag":
            draw_colored_polygon(PackedVector2Array([Vector2(-26.0, -38.0), Vector2(28.0, -35.0), Vector2(34.0, 36.0), Vector2(-35.0, 34.0)]), Color("#dc78d2"))
            draw_rect(Rect2(-27.0, -9.0, 54.0, 26.0), Color("#ffd36c"), true)
            draw_circle(Vector2(0.0, 4.0), 10.0, Color("#b96931"))
        "broken_cup":
            draw_colored_polygon(PackedVector2Array([Vector2(-32.0, -24.0), Vector2(6.0, -24.0), Vector2(-2.0, -10.0), Vector2(22.0, -4.0), Vector2(13.0, 30.0), Vector2(-23.0, 30.0)]), Color("#dfb0dc"))
            draw_line(Vector2(-1.0, -23.0), Vector2(-5.0, 26.0), Color("#875899"), 3.0)
            draw_arc(Vector2(23.0, 0.0), 21.0, -1.4, 1.3, 24, Color("#c58fcc"), 7.0)
        "diaper":
            draw_colored_polygon(PackedVector2Array([Vector2(-38.0, -15.0), Vector2(38.0, -15.0), Vector2(26.0, 34.0), Vector2(-26.0, 34.0)]), Color("#e9eaff"))
            draw_rect(Rect2(-38.0, -16.0, 76.0, 17.0), Color("#83a9e8"), true)
            draw_circle(Vector2(0.0, 15.0), 12.0, Color("#a4cae9"))
        "foam_cup":
            draw_colored_polygon(PackedVector2Array([Vector2(-33.0, -30.0), Vector2(33.0, -30.0), Vector2(19.0, 37.0), Vector2(-19.0, 37.0)]), Color("#e8ecf0"))
            draw_rect(Rect2(-36.0, -38.0, 72.0, 11.0), Color("#cedde8"), true)
            draw_line(Vector2(-22.0, -5.0), Vector2(21.0, -5.0), Color("#a3bacc"), 3.0)
        "bin_recycle":
            draw_arc(Vector2.ZERO, 29.0, -1.1, 4.1, 40, Color("#73c4ff"), 8.0, true)
            draw_line(Vector2(21.0, -28.0), Vector2(36.0, -21.0), Color("#73c4ff"), 7.0, true)
        "bin_organics":
            draw_colored_polygon(PackedVector2Array([Vector2(-33.0, 10.0), Vector2(-7.0, -30.0), Vector2(32.0, -20.0), Vector2(25.0, 25.0), Vector2(-15.0, 30.0)]), Color("#77e2aa"))
            draw_line(Vector2(-24.0, 22.0), Vector2(21.0, -16.0), Color("#266e50"), 4.0)
        "bin_trash":
            draw_rect(Rect2(-25.0, -24.0, 50.0, 59.0), Color("#c5d0df"), true)
            draw_rect(Rect2(-32.0, -34.0, 64.0, 10.0), Color("#edf3fa"), true)
            draw_line(Vector2(-10.0, -12.0), Vector2(-10.0, 25.0), Color("#7b8ca3"), 4.0)
            draw_line(Vector2(10.0, -12.0), Vector2(10.0, 25.0), Color("#7b8ca3"), 4.0)
        _:
            draw_circle(Vector2.ZERO, 30.0, Color("#a1d8ef"))
    draw_set_transform(Vector2.ZERO)
