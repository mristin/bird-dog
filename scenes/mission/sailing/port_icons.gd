class_name PortIcons
extends RefCounted

## The icons of the ports on the chart, in the manner of the engraved charts of
## the time: every port shows what it is known for (see Port.icon and the facts
## of the ports in DESIGN.md), e.g., the arena of Pula, the round church of
## Zadar, the salt pans of Pag or the arch of Trajan in Ancona.
##
## An icon stands on a patch of ground with its foot at the port, about 110
## pixels wide and 90 high at the scale 1; y grows downward, so the buildings
## rise to negative y.

const INK := Color(0.2, 0.12, 0.06)
const STONE := Color(0.9, 0.86, 0.76)
const STONE_DARK := Color(0.72, 0.66, 0.54)
const ROOF := Color(0.66, 0.17, 0.12)
const GREEN := Color(0.4, 0.55, 0.28)
const GREEN_DARK := Color(0.27, 0.4, 0.2)
const DARK := Color(0.28, 0.2, 0.14)
const GROUND := Color(0.82, 0.74, 0.55)
const WATER := Color(0.4, 0.6, 0.74)
const WHITE := Color(0.98, 0.97, 0.93)
const GOLD := Color(0.86, 0.64, 0.18)
const PURPLE := Color(0.56, 0.42, 0.72)
const ORANGE := Color(0.95, 0.55, 0.12)
const YELLOW := Color(0.96, 0.84, 0.25)
const COPPER := Color(0.45, 0.66, 0.58)

## The icons by name, for the tests and the editor.
const NAMES: Array[String] = [
    "arena",
    "campanile",
    "salt_eagle",
    "clock_tower",
    "nehaj",
    "salt_pans",
    "rotunda",
    "bell_figs",
    "cathedral",
    "palace",
    "lavender",
    "walled_island",
    "long_walls",
    "ragusa",
    "mimosa_fort",
    "mountain_walls",
    "corsairs",
    "amphitheatre",
    "bay_castle",
    "two_peaks",
    "oranges",
    "strait_fort",
    "trajan_arch",
    "basilica",
    "column",
    "rose_window",
    "roman_bridge",
    "cliff_castle",
    "white_rock",
    "island_campanile",
    "town",
]


## Draw the icon with its foot at the point.
static func draw(c: CanvasItem, icon: String, at: Vector2, scale := 1.0) -> void:
    c.draw_set_transform(at, 0.0, Vector2.ONE * scale)
    _shape(c, _ellipse(Vector2(0, 2), Vector2(58, 11)), GROUND, 1.5)
    match icon:
        "arena":
            _arena(c)
        "campanile":
            _campanile(c)
        "salt_eagle":
            _salt_eagle(c)
        "clock_tower":
            _clock_tower(c)
        "nehaj":
            _nehaj(c)
        "salt_pans":
            _salt_pans(c)
        "rotunda":
            _rotunda(c)
        "bell_figs":
            _bell_figs(c)
        "cathedral":
            _cathedral(c)
        "palace":
            _palace(c)
        "lavender":
            _lavender(c)
        "walled_island":
            _walled_island(c)
        "long_walls":
            _long_walls(c)
        "ragusa":
            _ragusa(c)
        "mimosa_fort":
            _mimosa_fort(c)
        "mountain_walls":
            _mountain_walls(c)
        "corsairs":
            _corsairs(c)
        "amphitheatre":
            _amphitheatre(c)
        "bay_castle":
            _bay_castle(c)
        "two_peaks":
            _two_peaks(c)
        "oranges":
            _oranges(c)
        "strait_fort":
            _strait_fort(c)
        "trajan_arch":
            _trajan_arch(c)
        "basilica":
            _basilica(c)
        "column":
            _column(c)
        "rose_window":
            _rose_window(c)
        "roman_bridge":
            _roman_bridge(c)
        "cliff_castle":
            _cliff_castle(c)
        "white_rock":
            _white_rock(c)
        "island_campanile":
            _island_campanile(c)
        _:
            _town(c)
    c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Rovinj: the old town on its island, the houses climbing the hill to the
## church of St. Euphemia with its tall campanile and the saint on its top.
static func _island_campanile(c: CanvasItem) -> void:
    _shape(c, _ellipse(Vector2(0, 2), Vector2(56, 10)), WATER, 1.2)
    _hill(c, -50, 50, Vector2(4, -34))
    for house in [[-46, 14, 16], [-34, 14, 24], [-22, 14, 30], [24, 14, 28], [36, 14, 20]]:
        _house(c, house[0], house[1], house[2])
    _box(c, -10, -46, 26, 18, STONE)
    _roof(c, -10, -46, 26, 10)
    _box(c, 18, -86, 12, 58, STONE)
    _windows(c, 18, -80, 12, 1, 8)
    _shape(c, PackedVector2Array([Vector2(18, -86), Vector2(30, -86), Vector2(24, -104)]), COPPER)
    c.draw_line(Vector2(24, -104), Vector2(24, -112), INK, 1.5)
    c.draw_circle(Vector2(24, -114), 2.5, GOLD)


## The top of the icon (for a pennant above it), relative to its foot.
static func top(_icon: String) -> Vector2:
    return Vector2(0, -92)


# region The pieces


static func _shape(c: CanvasItem, points: PackedVector2Array, fill: Color, width := 2.0) -> void:
    c.draw_colored_polygon(points, fill)
    var outline := points.duplicate()
    outline.append(points[0])
    c.draw_polyline(outline, INK, width, true)


static func _quad(x: float, y: float, w: float, h: float) -> PackedVector2Array:
    return PackedVector2Array(
        [Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)]
    )


## A box from its top left corner.
static func _box(c: CanvasItem, x: float, y: float, w: float, h: float, fill: Color) -> void:
    _shape(c, _quad(x, y, w, h), fill)


static func _ellipse(center: Vector2, radii: Vector2, steps := 28) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(steps):
        var angle := TAU * i / steps
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    return points


## The merlons on top of a wall which ends at y.
static func _merlons(c: CanvasItem, x: float, w: float, y: float, fill: Color) -> void:
    var count := maxi(1, int(w / 8.0))
    var step := w / count
    for i in range(count):
        _box(c, x + i * step + step * 0.2, y - 5, step * 0.6, 5, fill)


static func _roof(c: CanvasItem, x: float, y: float, w: float, h: float, fill := ROOF) -> void:
    _shape(
        c,
        PackedVector2Array([Vector2(x - 2, y), Vector2(x + w + 2, y), Vector2(x + w * 0.5, y - h)]),
        fill
    )


## A row of dark windows or arches.
static func _windows(c: CanvasItem, x: float, y: float, w: float, count: int, h := 6.0) -> void:
    var step := w / count
    for i in range(count):
        var left := x + i * step + step * 0.3
        var width := step * 0.4
        c.draw_rect(Rect2(left, y, width, h), DARK)
        c.draw_circle(Vector2(left + width * 0.5, y), width * 0.5, DARK)


## A house with a red roof.
static func _house(c: CanvasItem, x: float, w: float, h: float) -> void:
    _box(c, x, -h, w, h, STONE)
    _roof(c, x, -h, w, h * 0.55)
    c.draw_rect(Rect2(x + w * 0.4, -h * 0.45, w * 0.2, h * 0.45), DARK)


## A tower; with merlons if it has no roof.
static func _tower(c: CanvasItem, x: float, w: float, h: float, roof := ROOF, base := 0.0) -> void:
    _box(c, x, base - h, w, h, STONE)
    if roof.a > 0.0:
        _roof(c, x, base - h, w, w * 1.1, roof)
    else:
        _merlons(c, x, w, base - h, STONE)
    _windows(c, x, base - h + 8, w, 1, 7)


static func _flag(c: CanvasItem, foot: Vector2, color: Color, height := 18.0) -> void:
    var top := foot + Vector2(0, -height)
    c.draw_line(foot, top, INK, 2.0, true)
    _shape(c, PackedVector2Array([top, top + Vector2(16, 4), top + Vector2(0, 9)]), color, 1.2)


static func _tree(c: CanvasItem, foot: Vector2, radius: float, color := GREEN) -> void:
    c.draw_line(foot, foot + Vector2(0, -radius), DARK, 3.0, true)
    _shape(
        c,
        _ellipse(foot + Vector2(0, -radius * 1.6), Vector2(radius, radius * 0.85), 14),
        color,
        1.5
    )


static func _hill(c: CanvasItem, x0: float, x1: float, peak: Vector2, fill := GROUND) -> void:
    _shape(
        c,
        PackedVector2Array(
            [
                Vector2(x0, 0),
                Vector2(peak.x - 8, peak.y + 4),
                peak,
                Vector2(peak.x + 8, peak.y + 4),
                Vector2(x1, 0)
            ]
        ),
        fill
    )


static func _dome(c: CanvasItem, center: Vector2, radius: float, fill := STONE_DARK) -> void:
    var points := PackedVector2Array()
    for i in range(13):
        var angle := PI + PI * i / 12.0
        points.append(center + Vector2(cos(angle), sin(angle)) * radius)
    _shape(c, points, fill)
    c.draw_line(center + Vector2(0, -radius), center + Vector2(0, -radius - 8), INK, 2.0)
    c.draw_circle(center + Vector2(0, -radius - 9), 2.5, GOLD)


## A boat seen from the side, with a lateen sail.
static func _boat(c: CanvasItem, at: Vector2, sail: Color) -> void:
    _shape(
        c,
        PackedVector2Array(
            [at + Vector2(-16, 0), at + Vector2(16, 0), at + Vector2(11, 7), at + Vector2(-11, 7)]
        ),
        DARK,
        1.5
    )
    c.draw_line(at, at + Vector2(0, -24), INK, 2.0)
    _shape(
        c,
        PackedVector2Array([at + Vector2(-14, -2), at + Vector2(6, -28), at + Vector2(2, -2)]),
        sail,
        1.5
    )


## Small white heaps of salt in square pans.
static func _pans(c: CanvasItem, x: float, y: float, cols: int, rows: int) -> void:
    for row in range(rows):
        for col in range(cols):
            var at := Vector2(x + col * 15, y + row * 10)
            _shape(c, _quad(at.x, at.y + 3, 13, 6), Color(WATER, 0.8), 1.2)
    for col in range(cols):
        var at := Vector2(x + col * 15 + 6.5, y + 2)
        _shape(
            c,
            PackedVector2Array([at + Vector2(-6, 0), at + Vector2(6, 0), at + Vector2(0, -9)]),
            WHITE,
            1.2
        )


# endregion

# region The ports


## Pula: the great Roman arena, two rings of arches.
static func _arena(c: CanvasItem) -> void:
    _shape(c, _ellipse(Vector2(0, -26), Vector2(46, 26)), STONE)
    _shape(c, _ellipse(Vector2(0, -32), Vector2(30, 13)), GROUND, 1.5)
    for row in range(2):
        for i in range(9):
            var x := -38 + i * 9.5
            var y := -18 + row * 11
            var depth := sqrt(maxf(0.0, 1.0 - pow(x / 46.0, 2)))
            c.draw_rect(Rect2(x, y - 1 + (1.0 - depth) * -8, 4, 7 * depth), DARK)
    _box(c, 34, -52, 10, 16, STONE)
    _merlons(c, 34, 10, -52, STONE)


## Venice: the campanile of St. Mark with its golden angel, the domes of the
## basilica, and a gondola.
static func _campanile(c: CanvasItem) -> void:
    _box(c, -46, -30, 50, 30, STONE)
    _windows(c, -46, -20, 50, 5, 12)
    _dome(c, Vector2(-36, -30), 9)
    _dome(c, Vector2(-21, -30), 12)
    _dome(c, Vector2(-6, -30), 9)
    _box(c, 12, -76, 16, 76, Color(0.78, 0.45, 0.34))
    _box(c, 10, -86, 20, 10, STONE)
    _windows(c, 10, -84, 20, 2, 6)
    _shape(c, PackedVector2Array([Vector2(10, -86), Vector2(30, -86), Vector2(20, -104)]), COPPER)
    c.draw_circle(Vector2(20, -107), 3.0, GOLD)
    _shape(
        c,
        PackedVector2Array(
            [
                Vector2(28, -6),
                Vector2(36, 0),
                Vector2(50, 0),
                Vector2(56, -8),
                Vector2(50, -3),
                Vector2(36, -3)
            ]
        ),
        DARK,
        1.2
    )
    c.draw_line(Vector2(52, -3), Vector2(55, -16), INK, 1.5)


## Trieste: the salt pans of the Habsburgs and their yellow flag.
static func _salt_eagle(c: CanvasItem) -> void:
    _pans(c, -50, -20, 4, 2)
    _tower(c, 16, 18, 46)
    _house(c, 36, 16, 20)
    _flag(c, Vector2(25, -66), YELLOW, 20)
    c.draw_circle(Vector2(33, -82), 2.5, INK)


## Rijeka: the clock tower with its onion dome.
static func _clock_tower(c: CanvasItem) -> void:
    _house(c, -48, 22, 24)
    _house(c, 26, 22, 22)
    _box(c, -11, -62, 22, 62, STONE)
    c.draw_circle(Vector2(0, -48), 7, WHITE)
    c.draw_arc(Vector2(0, -48), 7, 0, TAU, 16, INK, 1.5, true)
    c.draw_line(Vector2(0, -48), Vector2(0, -53), INK, 1.5)
    c.draw_line(Vector2(0, -48), Vector2(4, -48), INK, 1.5)
    _shape(
        c,
        PackedVector2Array(
            [
                Vector2(-11, -62),
                Vector2(11, -62),
                Vector2(8, -70),
                Vector2(0, -84),
                Vector2(-8, -70)
            ]
        ),
        COPPER
    )


## Senj: the square fortress of Nehaj on its hill.
static func _nehaj(c: CanvasItem) -> void:
    _hill(c, -56, 56, Vector2(0, -26))
    _box(c, -24, -70, 48, 46, STONE)
    _merlons(c, -24, 48, -70, STONE)
    for x in [-14.0, 6.0]:
        _windows(c, x, -58, 8, 1, 7)
        _windows(c, x, -40, 8, 1, 7)
    _flag(c, Vector2(0, -75), ROOF, 16)
    _house(c, -52, 16, 16)
    _house(c, 36, 16, 16)


## Pag: the salt pans of Venice, with a little church.
static func _salt_pans(c: CanvasItem) -> void:
    _pans(c, -52, -22, 5, 2)
    _box(c, 26, -40, 22, 26, STONE)
    _roof(c, 26, -40, 22, 12)
    _box(c, 38, -58, 8, 20, STONE)
    _roof(c, 38, -58, 8, 8)


## Zadar: the round church of St. Donatus and its bell tower.
static func _rotunda(c: CanvasItem) -> void:
    _box(c, -40, -48, 40, 48, STONE)
    _shape(c, _ellipse(Vector2(-20, -48), Vector2(20, 6)), STONE_DARK, 1.5)
    _box(c, -30, -62, 20, 14, STONE)
    _shape(c, _ellipse(Vector2(-20, -62), Vector2(10, 3)), STONE_DARK, 1.5)
    _windows(c, -40, -36, 40, 3, 10)
    _tower(c, 14, 16, 70)
    _house(c, 34, 18, 18)


## Grebaštica: a little chapel with its bell, a fig tree and stone walls.
static func _bell_figs(c: CanvasItem) -> void:
    _box(c, -30, -30, 32, 30, STONE)
    _roof(c, -30, -30, 32, 14)
    _shape(
        c,
        PackedVector2Array(
            [Vector2(-8, -34), Vector2(8, -34), Vector2(8, -50), Vector2(0, -56), Vector2(-8, -50)]
        ),
        STONE
    )
    c.draw_rect(Rect2(-4, -49, 8, 11), DARK)
    _shape(
        c,
        PackedVector2Array([Vector2(-3, -40), Vector2(3, -40), Vector2(2, -47), Vector2(-2, -47)]),
        GOLD,
        1.0
    )
    _tree(c, Vector2(30, 0), 13, GREEN_DARK)
    for i in range(4):
        c.draw_circle(Vector2(24 + i * 4, -22 + (i % 2) * 5), 2.2, PURPLE)
    for y in [-4.0, -9.0]:
        c.draw_line(Vector2(-54, y), Vector2(-34, y), INK, 2.0, true)


## Šibenik: the cathedral of St. James with its stone dome.
static func _cathedral(c: CanvasItem) -> void:
    _box(c, -40, -40, 80, 40, STONE)
    _shape(c, PackedVector2Array([Vector2(-40, -40), Vector2(-28, -54), Vector2(-16, -40)]), STONE)
    _shape(c, PackedVector2Array([Vector2(16, -40), Vector2(28, -54), Vector2(40, -40)]), STONE)
    _box(c, -12, -56, 24, 16, STONE)
    _dome(c, Vector2(0, -56), 14)
    c.draw_circle(Vector2(-28, -26), 5, DARK)
    for i in range(7):
        c.draw_circle(Vector2(-34 + i * 11, -8), 2.5, DARK)


## Split: the palace of Diocletian with its arcades and its bell tower.
static func _palace(c: CanvasItem) -> void:
    _box(c, -54, -30, 108, 30, STONE)
    _windows(c, -54, -20, 108, 9, 12)
    _merlons(c, -54, 108, -30, STONE)
    _tower(c, -8, 16, 74)
    _box(c, 36, -44, 14, 14, STONE)
    _box(c, -50, -44, 14, 14, STONE)


## Hvar: the theatre of the arsenal and the lavender fields.
static func _lavender(c: CanvasItem) -> void:
    _box(c, -50, -36, 50, 36, STONE)
    _windows(c, -50, -14, 50, 3, 14)
    _windows(c, -50, -30, 50, 4, 7)
    _roof(c, -50, -36, 50, 12)
    _tower(c, -22, 12, 58)
    for row in range(3):
        for i in range(5):
            var at := Vector2(10 + i * 9 + row * 3, -6 - row * 10)
            c.draw_line(at, at + Vector2(0, -8), GREEN_DARK, 2.0)
            c.draw_circle(at + Vector2(0, -9), 3, PURPLE)


## Korčula: the round walled town on its peninsula, and a ship on the stocks.
static func _walled_island(c: CanvasItem) -> void:
    _shape(c, _ellipse(Vector2(-12, -18), Vector2(40, 18)), STONE)
    _merlons(c, -44, 64, -30, STONE)
    for x in [-50.0, 22.0]:
        _box(c, x, -36, 12, 30, STONE)
        _merlons(c, x, 12, -36, STONE)
    _tower(c, -18, 14, 66)
    _house(c, -38, 16, 30)
    _house(c, 0, 16, 34)
    _shape(
        c,
        PackedVector2Array([Vector2(36, -12), Vector2(58, -12), Vector2(54, -4), Vector2(40, -4)]),
        DARK,
        1.5
    )
    for x in [40.0, 47.0, 54.0]:
        c.draw_line(Vector2(x, -12), Vector2(x - 2, -22), DARK, 1.5)


## Ston: the longest walls of Ragusa, climbing the hill, and the salt pans.
static func _long_walls(c: CanvasItem) -> void:
    _hill(c, -40, 56, Vector2(20, -70))
    var walls := PackedVector2Array(
        [
            Vector2(-30, -6),
            Vector2(-6, -30),
            Vector2(6, -44),
            Vector2(20, -70),
            Vector2(34, -48),
            Vector2(48, -10)
        ]
    )
    c.draw_polyline(walls, STONE_DARK, 7.0, true)
    c.draw_polyline(walls, INK, 1.5, true)
    for point in walls:
        _box(c, point.x - 4, point.y - 9, 8, 10, STONE)
    _pans(c, -58, -18, 2, 2)


## Dubrovnik: the walls with the round tower of Minčeta and the flag of
## Libertas.
static func _ragusa(c: CanvasItem) -> void:
    _box(c, -50, -34, 100, 34, STONE)
    _merlons(c, -50, 100, -34, STONE)
    _shape(c, _quad(-46, -62, 24, 30), STONE)
    _shape(c, _ellipse(Vector2(-34, -62), Vector2(12, 4)), STONE_DARK, 1.5)
    _merlons(c, -46, 24, -62, STONE)
    _house(c, -10, 16, 46)
    _house(c, 10, 18, 42)
    _tower(c, 32, 12, 60)
    _flag(c, Vector2(-34, -66), WHITE, 22)
    c.draw_string(
        ThemeDB.fallback_font, Vector2(-33, -81), "L", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ROOF
    )


## Herceg Novi: the fortress at the gate of the bay, and the mimosa.
static func _mimosa_fort(c: CanvasItem) -> void:
    _hill(c, -56, 40, Vector2(-10, -38))
    _box(c, -34, -66, 46, 30, STONE)
    _merlons(c, -34, 46, -66, STONE)
    _tower(c, -16, 12, 42, Color(0, 0, 0, 0), -36)
    _tree(c, Vector2(40, 0), 12, YELLOW)
    for i in range(6):
        c.draw_circle(Vector2(33 + (i % 3) * 6, -24 + (i / 3) * 6), 2.0, GOLD)


## Kotor: the walls which climb the mountain, and St. Tryphon below.
static func _mountain_walls(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array([Vector2(-58, 0), Vector2(0, -96), Vector2(58, 0)]),
        Color(0.7, 0.66, 0.56)
    )
    c.draw_polyline(
        PackedVector2Array(
            [
                Vector2(-34, -10),
                Vector2(-14, -46),
                Vector2(-6, -70),
                Vector2(0, -92),
                Vector2(10, -64),
                Vector2(22, -40),
                Vector2(36, -10)
            ]
        ),
        STONE,
        5.0,
        true
    )
    c.draw_polyline(
        PackedVector2Array(
            [
                Vector2(-34, -10),
                Vector2(-14, -46),
                Vector2(-6, -70),
                Vector2(0, -92),
                Vector2(10, -64),
                Vector2(22, -40),
                Vector2(36, -10)
            ]
        ),
        INK,
        1.5,
        true
    )
    _box(c, -26, -30, 48, 30, STONE)
    _tower(c, -20, 10, 46)
    _tower(c, 8, 10, 46)
    _windows(c, -26, -14, 48, 4, 8)


## Ulcinj: the fortress on its rock, an olive tree, and a corsair ship.
static func _corsairs(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array([Vector2(-50, 0), Vector2(-44, -28), Vector2(-10, -34), Vector2(4, 0)]),
        STONE_DARK
    )
    _box(c, -42, -60, 34, 28, STONE)
    _merlons(c, -42, 34, -60, STONE)
    _tower(c, -30, 10, 36, Color(0, 0, 0, 0), -32)
    _tree(c, Vector2(18, 0), 10, Color(0.55, 0.62, 0.42))
    _boat(c, Vector2(42, -4), DARK)


## Durrës: the Roman amphitheatre and a Venetian tower.
static func _amphitheatre(c: CanvasItem) -> void:
    var outer := PackedVector2Array()
    for i in range(15):
        var angle := PI + PI * i / 14.0
        outer.append(Vector2(-12, 0) + Vector2(cos(angle) * 42, sin(angle) * 34))
    _shape(c, outer, STONE)
    for row in range(3):
        for i in range(7):
            var x := -48 + i * 12 + row * 3
            c.draw_rect(Rect2(x, -26 + row * 9, 4, 6), DARK)
    _tower(c, 34, 16, 62, Color(0, 0, 0, 0))


## Vlorë: the castle of Kanina on its hill, and the island of Sazan in the bay.
static func _bay_castle(c: CanvasItem) -> void:
    _hill(c, -58, 30, Vector2(-16, -48))
    _box(c, -34, -74, 36, 26, STONE)
    _merlons(c, -34, 36, -74, STONE)
    _house(c, 8, 16, 18)
    _shape(c, _ellipse(Vector2(46, -2), Vector2(14, 6)), Color(0.66, 0.6, 0.48), 1.5)
    _tree(c, Vector2(46, -4), 5, GREEN_DARK)


## Corfu: the old fortress on its two peaks.
static func _two_peaks(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array(
            [Vector2(-56, 0), Vector2(-34, -62), Vector2(-14, -38), Vector2(6, -70), Vector2(36, 0)]
        ),
        Color(0.7, 0.66, 0.56)
    )
    _box(c, -42, -76, 16, 16, STONE)
    _merlons(c, -42, 16, -76, STONE)
    _box(c, -2, -84, 16, 16, STONE)
    _merlons(c, -2, 16, -84, STONE)
    c.draw_polyline(
        PackedVector2Array([Vector2(-48, -20), Vector2(-14, -36), Vector2(26, -20)]),
        STONE,
        4.0,
        true
    )
    _tower(c, 38, 12, 52)
    _dome(c, Vector2(44, -64), 7, ROOF)


## Parga: the little Venetian castle on its hill, and an orange tree.
static func _oranges(c: CanvasItem) -> void:
    _hill(c, -58, 26, Vector2(-16, -46))
    _box(c, -34, -72, 34, 26, STONE)
    _merlons(c, -34, 34, -72, STONE)
    _house(c, -50, 14, 16)
    _tree(c, Vector2(38, 0), 14, GREEN_DARK)
    for i in range(7):
        c.draw_circle(Vector2(30 + (i % 4) * 5, -28 + (i / 4) * 8 - (i % 2) * 3), 2.6, ORANGE)


## Preveza: the fortress at the narrow strait, with the minaret of the town
## where the kadı holds court.
static func _strait_fort(c: CanvasItem) -> void:
    _box(c, -52, -32, 44, 32, STONE)
    _merlons(c, -52, 44, -32, STONE)
    _shape(c, _quad(-6, -14, 14, 14), Color(WATER, 0.9), 1.5)
    _box(c, 12, -32, 40, 32, STONE)
    _merlons(c, 12, 40, -32, STONE)
    _box(c, 26, -82, 8, 50, WHITE)
    _box(c, 23, -70, 14, 4, WHITE)
    _shape(
        c, PackedVector2Array([Vector2(26, -82), Vector2(34, -82), Vector2(30, -96)]), COPPER, 1.5
    )
    _dome(c, Vector2(-30, -32), 12)


## Ancona: the arch of Trajan above the harbour.
static func _trajan_arch(c: CanvasItem) -> void:
    _box(c, -36, -8, 72, 8, STONE_DARK)
    _box(c, -30, -64, 60, 56, STONE)
    _box(c, -34, -76, 68, 12, STONE)
    c.draw_rect(Rect2(-12, -46, 24, 38), DARK)
    c.draw_circle(Vector2(0, -46), 12, DARK)
    for x in [-26.0, -18.0, 18.0, 26.0]:
        c.draw_line(Vector2(x, -64), Vector2(x, -8), INK, 2.0)
    c.draw_rect(Rect2(-6, -88, 12, 12), GOLD)
    c.draw_rect(Rect2(-6, -88, 12, 12), INK, false, 1.5)


## Bari: the basilica of St. Nicholas with its two towers.
static func _basilica(c: CanvasItem) -> void:
    _box(c, -30, -46, 60, 46, STONE)
    _roof(c, -30, -46, 60, 18, STONE_DARK)
    c.draw_circle(Vector2(0, -32), 7, DARK)
    c.draw_rect(Rect2(-6, -18, 12, 18), DARK)
    for x in [-48.0, 30.0]:
        _box(c, x, -66, 18, 66, STONE)
        _windows(c, x, -56, 18, 1, 8)
        _windows(c, x, -36, 18, 1, 8)


## Brindisi: the Roman column at the end of the Via Appia.
static func _column(c: CanvasItem) -> void:
    _box(c, -12, -10, 24, 10, STONE_DARK)
    _box(c, -6, -82, 12, 72, STONE)
    for x in [-3.0, 0.0, 3.0]:
        c.draw_line(Vector2(x, -80), Vector2(x, -12), STONE_DARK, 1.0)
    _box(c, -11, -90, 22, 8, STONE)
    _house(c, -50, 18, 22)
    _house(c, 28, 20, 24)


## Otranto: the cathedral of the great mosaic, with its rose window, and the
## sun which rises here first in Italy.
static func _rose_window(c: CanvasItem) -> void:
    for i in range(10):
        var ray := Vector2.UP.rotated(-PI * 0.5 + PI * i / 9.0)
        c.draw_line(Vector2(36, -48) + ray * 16, Vector2(36, -48) + ray * 24, GOLD, 2.5, true)
    c.draw_circle(Vector2(36, -48), 13, GOLD)
    _box(c, -40, -50, 56, 50, STONE)
    _roof(c, -40, -50, 56, 18, STONE_DARK)
    c.draw_circle(Vector2(-12, -32), 10, WHITE)
    for i in range(8):
        var spoke := Vector2.UP.rotated(i * TAU / 8)
        c.draw_line(Vector2(-12, -32), Vector2(-12, -32) + spoke * 10, INK, 1.2)
    c.draw_arc(Vector2(-12, -32), 10, 0, TAU, 20, INK, 2.0, true)
    c.draw_rect(Rect2(-17, -14, 10, 14), DARK)


## Any other town: a tower with a red roof between two houses.
static func _town(c: CanvasItem) -> void:
    _house(c, -40, 22, 22)
    _house(c, 18, 22, 20)
    _tower(c, -8, 16, 56)


## Rimini: the Roman bridge of Tiberius with its five arches, and the town
## behind it.
static func _roman_bridge(c: CanvasItem) -> void:
    _house(c, -44, 20, 30)
    _tower(c, -18, 14, 56)
    _house(c, 20, 22, 26)
    _box(c, -54, -30, 108, 14, STONE)
    for i in range(5):
        var x := -44.0 + i * 22.0
        c.draw_rect(Rect2(x, -16, 12, 16), WATER)
        c.draw_circle(Vector2(x + 6, -16), 6, WATER)
        c.draw_arc(Vector2(x + 6, -16), 6, PI, TAU, 8, INK, 1.5, true)
    c.draw_line(Vector2(-54, -30), Vector2(54, -30), INK, 2.0)


## Ortona: the castle of the Aragonese high on its cliff over the sea, and the
## dome of the church of St. Thomas.
static func _cliff_castle(c: CanvasItem) -> void:
    _shape(
        c,
        PackedVector2Array([Vector2(-58, 0), Vector2(-54, -40), Vector2(-8, -46), Vector2(-4, 0)]),
        Color(0.7, 0.66, 0.56)
    )
    for y in [-34.0, -24.0, -14.0]:
        c.draw_line(Vector2(-54, y), Vector2(-8, y + 2), Color(INK, 0.5), 1.5)
    _box(c, -50, -74, 38, 28, STONE)
    _merlons(c, -50, 38, -74, STONE)
    _tower(c, -58, 12, 82, STONE_DARK)
    _box(c, 8, -40, 36, 40, STONE)
    _dome(c, Vector2(26, -44), 14, COPPER)
    c.draw_line(Vector2(26, -58), Vector2(26, -70), INK, 2.0)
    c.draw_line(Vector2(21, -65), Vector2(31, -65), INK, 2.0)


## Vieste: the tall white rock of Pizzomunno on the beach, and the white town
## on the cape of the Gargano.
static func _white_rock(c: CanvasItem) -> void:
    _hill(c, -58, 2, Vector2(-28, -44))
    _house(c, -48, 18, 20)
    _house(c, -26, 18, 30)
    _tower(c, -6, 10, 50, STONE_DARK)
    _shape(
        c,
        PackedVector2Array(
            [Vector2(22, 0), Vector2(26, -60), Vector2(34, -84), Vector2(42, -62), Vector2(46, 0)]
        ),
        WHITE
    )
    for y in [-60.0, -40.0, -20.0]:
        c.draw_line(Vector2(28, y), Vector2(42, y + 4), Color(INK, 0.35), 1.5)

# endregion
