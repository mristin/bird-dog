class_name CargoIcons
extends RefCounted

## The pictures of what a boat carries (see Item.icon): the bell, a sack of
## salt, the medicine, a letter, a sealed answer, an amphora of oil, a sail, a
## jar of honey, the ledger, timber, oranges, a basket, a rope; and a passenger
## (or a witness) as a small round portrait. An icon fits a circle of the given
## radius around its center.

const INK := Color(0.2, 0.12, 0.06)


static func draw(c: CanvasItem, item: Item, center: Vector2, radius: float) -> void:
    if item.person != null and item.person.portrait != null:
        _portrait(c, item.person.portrait, center, radius)
        return
    c.draw_set_transform(center, 0.0, Vector2.ONE * radius / 40.0)
    match item.icon:
        "bell":
            _bell(c)
        "sack":
            _sack(c)
        "bottle":
            _bottle(c)
        "letter":
            _letter(c, false)
        "sealed":
            _letter(c, true)
        "amphora":
            _amphora(c)
        "sail":
            _sail(c)
        "jar":
            _jar(c)
        "book":
            _book(c)
        "timber":
            _timber(c)
        "oranges":
            _basket(c, true)
        "basket":
            _basket(c, false)
        "rope":
            _rope(c)
        _:
            _barrel(c)
    c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _shape(c: CanvasItem, points: PackedVector2Array, fill: Color) -> void:
    c.draw_colored_polygon(points, fill)
    var outline := points.duplicate()
    outline.append(points[0])
    c.draw_polyline(outline, INK, 2.5, true)


## A passenger: the face from their portrait, in a golden ring.
static func _portrait(c: CanvasItem, texture: Texture2D, center: Vector2, radius: float) -> void:
    var texture_size := texture.get_size()
    # NOTE (mristin):
    # The face sits in the upper part of the costume plates.
    var side := texture_size.x * 0.42
    var source := Rect2(texture_size.x * 0.3, texture_size.y * 0.06, side, side)
    c.draw_circle(center, radius, Paper.PAPER)
    c.draw_texture_rect_region(
        texture,
        Rect2(center - Vector2(radius, radius) * 0.8, Vector2(radius, radius) * 1.6),
        source
    )
    c.draw_arc(center, radius, 0, TAU, 32, Paper.GOLD, 4.0, true)


static func _bell(c: CanvasItem) -> void:
    var bronze := Color(0.78, 0.58, 0.25)
    _shape(
        c,
        PackedVector2Array(
            [
                Vector2(-8, -28),
                Vector2(8, -28),
                Vector2(14, -10),
                Vector2(18, 16),
                Vector2(28, 24),
                Vector2(-28, 24),
                Vector2(-18, 16),
                Vector2(-14, -10)
            ]
        ),
        bronze
    )
    c.draw_line(Vector2(-22, 16), Vector2(22, 16), Color(0.55, 0.38, 0.14), 3.0)
    c.draw_circle(Vector2(0, 30), 6, Color(0.55, 0.38, 0.14))
    c.draw_arc(Vector2(0, -32), 6, PI, TAU, 8, INK, 3.0)
    c.draw_line(Vector2(-6, -18), Vector2(-10, 10), Color(1, 0.9, 0.6, 0.7), 3.0)


static func _sack(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array(
            [
                Vector2(-24, 30),
                Vector2(24, 30),
                Vector2(26, 10),
                Vector2(16, -18),
                Vector2(8, -24),
                Vector2(-8, -24),
                Vector2(-16, -18),
                Vector2(-26, 10)
            ]
        ),
        Color(0.85, 0.77, 0.58)
    )
    _shape(
        c,
        PackedVector2Array(
            [Vector2(-8, -24), Vector2(8, -24), Vector2(12, -34), Vector2(-12, -34)]
        ),
        Color(0.85, 0.77, 0.58)
    )
    c.draw_line(Vector2(-9, -25), Vector2(9, -25), Color(0.55, 0.3, 0.15), 3.0)
    _shape(
        c, PackedVector2Array([Vector2(-12, 2), Vector2(12, 2), Vector2(0, -12)]), Color(1, 1, 1)
    )


static func _bottle(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array(
            [
                Vector2(-6, -34),
                Vector2(6, -34),
                Vector2(6, -18),
                Vector2(20, -6),
                Vector2(20, 30),
                Vector2(-20, 30),
                Vector2(-20, -6),
                Vector2(-6, -18)
            ]
        ),
        Color(0.35, 0.55, 0.45)
    )
    c.draw_rect(Rect2(-7, -40, 14, 8), Color(0.6, 0.4, 0.2))
    c.draw_rect(Rect2(-14, 0, 28, 18), Color(0.97, 0.94, 0.85))
    c.draw_line(Vector2(0, 3), Vector2(0, 15), Paper.RED, 3.0)
    c.draw_line(Vector2(-6, 9), Vector2(6, 9), Paper.RED, 3.0)


static func _letter(c: CanvasItem, sealed: bool) -> void:
    _shape(
        c,
        PackedVector2Array(
            [Vector2(-30, -20), Vector2(30, -20), Vector2(30, 22), Vector2(-30, 22)]
        ),
        Color(0.97, 0.93, 0.8)
    )
    c.draw_polyline(
        PackedVector2Array([Vector2(-30, -20), Vector2(0, 4), Vector2(30, -20)]), INK, 2.0, true
    )
    if sealed:
        c.draw_circle(Vector2(0, 6), 9, Paper.RED)
        c.draw_arc(Vector2(0, 6), 9, 0, TAU, 14, INK, 1.5, true)
    else:
        for y in [8.0, 15.0]:
            c.draw_line(Vector2(-20, y), Vector2(20, y), Color(INK, 0.5), 1.5)


static func _amphora(c: CanvasItem) -> void:
    var clay := Color(0.74, 0.42, 0.24)
    var body := PackedVector2Array()
    for i in range(9):
        var t := float(i) / 8.0
        body.append(Vector2(-(6 + sin(t * PI) * 16), 34 - t * 60))
    for i in range(8, -1, -1):
        var t := float(i) / 8.0
        body.append(Vector2(6 + sin(t * PI) * 16, 34 - t * 60))
    _shape(c, body, clay)
    c.draw_arc(Vector2(-12, -24), 7, PI * 0.5, PI * 1.5, 8, INK, 3.0)
    c.draw_arc(Vector2(12, -24), 7, -PI * 0.5, PI * 0.5, 8, INK, 3.0)
    c.draw_line(Vector2(-16, 0), Vector2(16, 0), Color(0.55, 0.62, 0.25), 4.0)


static func _sail(c: CanvasItem) -> void:
    c.draw_line(Vector2(-4, -34), Vector2(-4, 34), INK, 3.0)
    _shape(
        c,
        PackedVector2Array([Vector2(-2, -30), Vector2(28, 26), Vector2(-2, 26)]),
        Color(0.98, 0.95, 0.86)
    )
    c.draw_line(Vector2(4, 0), Vector2(14, 18), Color(INK, 0.4), 1.5)


static func _jar(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array(
            [Vector2(-20, -16), Vector2(20, -16), Vector2(24, 28), Vector2(-24, 28)]
        ),
        Color(0.92, 0.66, 0.2)
    )
    _shape(
        c,
        PackedVector2Array(
            [Vector2(-22, -26), Vector2(22, -26), Vector2(22, -16), Vector2(-22, -16)]
        ),
        Color(0.9, 0.85, 0.75)
    )
    c.draw_line(Vector2(-22, -21), Vector2(22, -21), Paper.RED, 2.0)
    c.draw_circle(Vector2(0, 8), 7, Color(1, 0.85, 0.3))


static func _book(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array(
            [Vector2(-26, -30), Vector2(24, -30), Vector2(24, 30), Vector2(-26, 30)]
        ),
        Color(0.45, 0.2, 0.12)
    )
    c.draw_rect(Rect2(24, -26, 6, 52), Color(0.95, 0.9, 0.78))
    c.draw_rect(Rect2(-14, -14, 26, 16), Paper.GOLD)
    c.draw_line(Vector2(-20, 14), Vector2(18, 14), Paper.GOLD, 2.0)


static func _barrel(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array(
            [
                Vector2(-20, -30),
                Vector2(20, -30),
                Vector2(26, 0),
                Vector2(20, 30),
                Vector2(-20, 30),
                Vector2(-26, 0)
            ]
        ),
        Color(0.6, 0.38, 0.18)
    )
    for y in [-16.0, 16.0]:
        c.draw_line(Vector2(-24, y), Vector2(24, y), Color(0.3, 0.3, 0.32), 4.0)


## Three logs, stacked, with their rings showing.
static func _timber(c: CanvasItem) -> void:
    var bark := Color(0.5, 0.32, 0.16)
    var wood := Color(0.86, 0.68, 0.42)
    for at in [Vector2(-14, 14), Vector2(14, 14), Vector2(0, -10)]:
        _shape(
            c,
            PackedVector2Array(
                [
                    at + Vector2(-26, -11),
                    at + Vector2(10, -11),
                    at + Vector2(10, 11),
                    at + Vector2(-26, 11)
                ]
            ),
            bark
        )
        c.draw_circle(at + Vector2(10, 0), 11, wood)
        c.draw_arc(at + Vector2(10, 0), 11, 0, TAU, 16, INK, 2.5, true)
        c.draw_arc(at + Vector2(10, 0), 5, 0, TAU, 12, bark, 1.5, true)


## A woven basket, empty or full of oranges.
static func _basket(c: CanvasItem, oranges: bool) -> void:
    if oranges:
        for at in [
            Vector2(-14, -8), Vector2(0, -14), Vector2(14, -8), Vector2(-6, -2), Vector2(8, -2)
        ]:
            c.draw_circle(at, 10, Color(0.96, 0.55, 0.12))
            c.draw_arc(at, 10, 0, TAU, 14, INK, 2.0, true)
        c.draw_line(Vector2(0, -24), Vector2(6, -30), Color(0.3, 0.55, 0.2), 4.0)
    else:
        c.draw_arc(Vector2(0, -2), 24, PI, TAU, 16, INK, 4.0, true)
    var weave := Color(0.82, 0.62, 0.32)
    _shape(
        c,
        PackedVector2Array([Vector2(-28, -2), Vector2(28, -2), Vector2(20, 28), Vector2(-20, 28)]),
        weave
    )
    for y in [6.0, 14.0, 22.0]:
        c.draw_line(Vector2(-26 + (y + 2) * 0.27, y), Vector2(26 - (y + 2) * 0.27, y), INK, 1.5)


## A coiled rope.
static func _rope(c: CanvasItem) -> void:
    var hemp := Color(0.8, 0.66, 0.4)
    for radius in [26.0, 18.0, 10.0]:
        c.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, INK, 9.0, true)
        c.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, hemp, 6.0, true)
    c.draw_line(Vector2(26, 0), Vector2(30, 26), INK, 9.0)
    c.draw_line(Vector2(26, 0), Vector2(30, 26), hemp, 6.0)
