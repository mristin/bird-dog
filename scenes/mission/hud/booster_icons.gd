class_name BoosterIcons
extends RefCounted

## The pictures of the boosters (see Booster), drawn in the style of the
## chart: new sails, a weather-wise fisherman (his hat and the coming wind),
## a local pilot (an anchor), the right flag (the lion of St. Mark), figs for
## the corsairs (a basket), fresh bread and water, lots of cannons, a skilled
## helmsman (the wheel), a barrel of salted fish, and strong rowers (two oars).
##
## An icon fits a circle of the given radius around its center.

const INK := Color(0.2, 0.12, 0.06)


static func draw(c: CanvasItem, effect: String, center: Vector2, radius: float) -> void:
    c.draw_set_transform(center, 0.0, Vector2.ONE * radius / 40.0)
    match effect:
        "speed":
            _sails(c)
        "weather":
            _weather(c)
        "pilot":
            _anchor(c)
        "flag":
            _flag(c)
        "figs":
            _figs(c)
        "cannons":
            _cannons(c)
        "nimble":
            _wheel(c)
        "food":
            _fish(c)
        "oars":
            _oars(c)
        _:
            _bread(c)
    c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _shape(c: CanvasItem, points: PackedVector2Array, fill: Color) -> void:
    c.draw_colored_polygon(points, fill)
    var outline := points.duplicate()
    outline.append(points[0])
    c.draw_polyline(outline, INK, 2.5, true)


## New sails, full of wind, with the wind lines behind them.
static func _sails(c: CanvasItem) -> void:
    for y in [-14.0, 0.0, 14.0]:
        c.draw_line(Vector2(-36, y), Vector2(-20, y), Color(0.4, 0.6, 0.78), 3.0, true)
    c.draw_line(Vector2(2, -34), Vector2(2, 32), INK, 3.0)
    var sail := PackedVector2Array()
    for i in range(9):
        var t := float(i) / 8.0
        sail.append(Vector2(2 + sin(t * PI) * 26, -30 + t * 52))
    sail.append(Vector2(2, 22))
    _shape(c, sail, Color(0.98, 0.96, 0.88))
    c.draw_line(Vector2(6, -6), Vector2(20, -6), Color(0.7, 0.12, 0.1), 3.0)
    _shape(
        c,
        PackedVector2Array([Vector2(-26, 24), Vector2(30, 24), Vector2(22, 34), Vector2(-18, 34)]),
        Color(0.5, 0.3, 0.14)
    )


## A fisherman's red cap and the wind he sees coming.
static func _weather(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array(
            [
                Vector2(-26, 10),
                Vector2(26, 10),
                Vector2(18, -10),
                Vector2(4, -22),
                Vector2(-14, -14)
            ]
        ),
        Color(0.72, 0.16, 0.12)
    )
    c.draw_line(Vector2(-28, 10), Vector2(28, 10), INK, 4.0)
    c.draw_arc(Vector2(-6, 22), 10, PI, TAU, 10, Color(0.4, 0.6, 0.78), 3.0, true)
    c.draw_arc(Vector2(12, 26), 8, PI, TAU, 10, Color(0.4, 0.6, 0.78), 3.0, true)
    c.draw_line(Vector2(-30, -30), Vector2(-4, -30), Color(0.4, 0.6, 0.78), 3.0)
    _shape(
        c,
        PackedVector2Array([Vector2(-4, -36), Vector2(8, -30), Vector2(-4, -24)]),
        Color(0.4, 0.6, 0.78)
    )


## An anchor: the pilot who knows the reefs.
static func _anchor(c: CanvasItem) -> void:
    var iron := Color(0.35, 0.36, 0.4)
    c.draw_arc(Vector2(0, -26), 7, 0, TAU, 14, iron, 5.0, true)
    c.draw_line(Vector2(0, -19), Vector2(0, 28), iron, 6.0)
    c.draw_line(Vector2(-16, -10), Vector2(16, -10), iron, 6.0)
    c.draw_arc(Vector2(0, 8), 24, 0.2, PI - 0.2, 16, iron, 6.0, true)
    for x in [-22.0, 22.0]:
        _shape(
            c,
            PackedVector2Array(
                [Vector2(x, 14), Vector2(x + sign(x) * 8, 4), Vector2(x - sign(x) * 2, 4)]
            ),
            iron
        )


## The red flag of Venice with the golden lion of St. Mark.
static func _flag(c: CanvasItem) -> void:
    c.draw_line(Vector2(-24, -34), Vector2(-24, 36), INK, 3.0)
    _shape(
        c,
        PackedVector2Array(
            [Vector2(-24, -32), Vector2(30, -32), Vector2(24, -16), Vector2(30, 2), Vector2(-24, 2)]
        ),
        Color(0.7, 0.14, 0.12)
    )
    c.draw_circle(Vector2(0, -15), 9, Paper.GOLD)
    c.draw_circle(Vector2(-4, -18), 2, INK)
    c.draw_line(Vector2(-8, -8), Vector2(12, -8), Paper.GOLD, 3.0)


## A basket of purple figs.
static func _figs(c: CanvasItem) -> void:
    for at in [
        Vector2(-14, -8), Vector2(0, -12), Vector2(14, -8), Vector2(-6, -18), Vector2(8, -20)
    ]:
        c.draw_circle(at, 9, Color(0.45, 0.24, 0.42))
        c.draw_arc(at, 9, 0, TAU, 12, INK, 1.5, true)
        c.draw_line(at + Vector2(0, -9), at + Vector2(2, -13), Color(0.3, 0.45, 0.2), 2.0)
    _shape(
        c,
        PackedVector2Array([Vector2(-30, -4), Vector2(30, -4), Vector2(22, 26), Vector2(-22, 26)]),
        Color(0.72, 0.52, 0.28)
    )
    for y in [4.0, 14.0]:
        c.draw_line(Vector2(-27, y), Vector2(27, y), Color(0.5, 0.34, 0.16), 2.0)


## A loaf of bread and a jug of water.
static func _bread(c: CanvasItem) -> void:
    var jug := PackedVector2Array()
    for i in range(9):
        var t := float(i) / 8.0
        jug.append(Vector2(14 - (6 + sin(t * PI) * 8), 30 - t * 56))
    for i in range(8, -1, -1):
        var t := float(i) / 8.0
        jug.append(Vector2(14 + (6 + sin(t * PI) * 8), 30 - t * 56))
    _shape(c, jug, Color(0.74, 0.4, 0.24))
    var loaf := PackedVector2Array()
    for i in range(16):
        var angle := TAU * i / 16
        loaf.append(Vector2(-10 + cos(angle) * 22, 16 + sin(angle) * 14))
    _shape(c, loaf, Color(0.8, 0.52, 0.22))
    for x in [-20.0, -10.0, 0.0]:
        c.draw_line(Vector2(x - 3, 8), Vector2(x + 3, 22), Color(0.96, 0.8, 0.5), 3.0)


## Two black cannons on their wooden carriages, one behind the other.
static func _cannons(c: CanvasItem) -> void:
    var iron := Color(0.16, 0.16, 0.18)
    for shift in [Vector2(-8, -12), Vector2(6, 10)]:
        var at: Vector2 = shift
        _shape(
            c,
            PackedVector2Array(
                [
                    at + Vector2(-20, 4),
                    at + Vector2(8, 4),
                    at + Vector2(10, 14),
                    at + Vector2(-22, 14)
                ]
            ),
            Color(0.55, 0.34, 0.16)
        )
        _shape(
            c,
            PackedVector2Array(
                [
                    at + Vector2(-24, -6),
                    at + Vector2(26, -2),
                    at + Vector2(26, 6),
                    at + Vector2(-24, 8)
                ]
            ),
            iron
        )
        c.draw_circle(at + Vector2(-24, 1), 6, iron)
        c.draw_circle(at + Vector2(-12, 15), 5, Color(0.42, 0.26, 0.12))
        c.draw_circle(at + Vector2(2, 15), 5, Color(0.42, 0.26, 0.12))
    c.draw_circle(Vector2(34, -12), 5, Color(0.85, 0.85, 0.85, 0.8))
    c.draw_circle(Vector2(37, -6), 4, Color(0.85, 0.85, 0.85, 0.6))


## The ship's wheel of the helmsman.
static func _wheel(c: CanvasItem) -> void:
    var wood := Color(0.55, 0.34, 0.16)
    for k in range(8):
        var spoke := Vector2.UP.rotated(k * TAU / 8)
        c.draw_line(spoke * 6, spoke * 34, wood, 5.0, true)
        c.draw_circle(spoke * 34, 4, wood)
    c.draw_arc(Vector2.ZERO, 24, 0, TAU, 32, wood, 7.0, true)
    c.draw_arc(Vector2.ZERO, 24, 0, TAU, 32, INK, 1.5, true)
    c.draw_circle(Vector2.ZERO, 8, Paper.GOLD)
    c.draw_arc(Vector2.ZERO, 8, 0, TAU, 16, INK, 2.0, true)


## A salted fish on a small barrel.
static func _fish(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array([Vector2(-22, 2), Vector2(22, 2), Vector2(18, 32), Vector2(-18, 32)]),
        Color(0.6, 0.38, 0.18)
    )
    c.draw_line(Vector2(-21, 12), Vector2(21, 12), Color(0.3, 0.3, 0.32), 3.0)
    c.draw_line(Vector2(-19, 24), Vector2(19, 24), Color(0.3, 0.3, 0.32), 3.0)
    var body := PackedVector2Array()
    for i in range(16):
        var angle := TAU * i / 16
        body.append(Vector2(-4 + cos(angle) * 24, -14 + sin(angle) * 10))
    _shape(c, body, Color(0.62, 0.68, 0.74))
    _shape(
        c,
        PackedVector2Array([Vector2(18, -14), Vector2(34, -26), Vector2(34, -2)]),
        Color(0.52, 0.58, 0.64)
    )
    c.draw_circle(Vector2(-18, -16), 2.5, INK)


## Two crossed oars.
static func _oars(c: CanvasItem) -> void:
    var wood := Color(0.62, 0.42, 0.2)
    for side in [-1.0, 1.0]:
        var a := Vector2(-30 * side, -30)
        var b := Vector2(26 * side, 26)
        c.draw_line(a, b, INK, 7.0, true)
        c.draw_line(a, b, wood, 4.5, true)
        var blade := PackedVector2Array()
        var along := (b - a).normalized()
        var across := along.orthogonal()
        for point in [
            b - along * 4, b + along * 16 + across * 8, b + along * 20, b + along * 16 - across * 8
        ]:
            blade.append(point)
        _shape(c, blade, wood)
