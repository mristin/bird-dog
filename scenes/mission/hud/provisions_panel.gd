class_name ProvisionsPanel
extends Control

## Show the food and the water on board (see DESIGN.md, "Provisions") as a
## column of round tokens, like the cargo: one token for every ration which
## the ship stows (a gajeta one, a bracera three, see Ship.rations), each with its picture
## (a barrel of water, a loaf of bread, a wheel of cheese, ...). The crew eats
## them from the top down: the token in use empties like a clock, and an
## eaten one stays as a dashed ring. When the food runs low, the panel blinks;
## every port fills all the rations again.

## Below this share, the panel warns.
const LOW := 0.3

const INK := Color(0.2, 0.12, 0.06)
const WOOD := Color(0.6, 0.38, 0.18)
const WOOD_DARK := Color(0.42, 0.25, 0.11)
const IRON := Color(0.3, 0.3, 0.32)
const WATER := Color(0.32, 0.58, 0.8)
const CRUST := Color(0.78, 0.5, 0.2)
const CRUMB := Color(0.95, 0.78, 0.45)
const CHEESE := Color(0.97, 0.82, 0.36)
const RIND := Color(0.85, 0.6, 0.2)
const FISH := Color(0.62, 0.68, 0.74)
const FIG := Color(0.45, 0.24, 0.42)

## The pictures of the rations, from the bottom token up.
const THINGS := ["barrel", "bread", "cheese", "fish", "figs"]

## The largest token, and the room for the label at the top, in pixels.
const MAX_RADIUS := 36.0
const LABEL_HEIGHT := 40.0

var run: MissionRun

## The player whose boat the panel shows.
var player := 0


func _process(_delta: float) -> void:
    queue_redraw()


## The centres of the tokens, from the top down.
func token_places(count: int) -> Array[Vector2]:
    var places: Array[Vector2] = []
    var room := _room(count)
    for i in range(count):
        places.append(Vector2(size.x * 0.5, LABEL_HEIGHT + room * (i + 0.5)))
    return places


## The radius of the tokens: as large as they fit.
func token_radius(count: int) -> float:
    return minf(MAX_RADIUS, minf(size.x * 0.5 - 10.0, _room(count) * 0.5 - 5.0))


func _room(count: int) -> float:
    return (size.y - LABEL_HEIGHT - 10.0) / maxi(1, count)


func _draw() -> void:
    if run == null:
        return
    var hold := run.hold(player)
    var count := hold.ship.rations
    var left := run.rations_left(player)
    var low := run.provisions_share(player) < LOW
    var blink := low and int(Time.get_ticks_msec() / 400) % 2 == 0
    var paper := Paper.PAPER.lerp(Color(0.95, 0.6, 0.45), 0.6) if blink else Paper.PAPER
    draw_rect(Rect2(Vector2(6, 8), size), Color(0, 0, 0, 0.2))
    draw_rect(Rect2(Vector2.ZERO, size), Color(paper, 0.95))
    draw_rect(Rect2(Vector2.ZERO, size), Paper.INK, false, 3.0)

    var font := ThemeDB.fallback_font
    var label := tr("Food")
    draw_string(
        font,
        Vector2(4, 30),
        label,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 8,
        HandButton.fit_size(font, label, 24, size.x - 12),
        Paper.RED if low else Paper.INK
    )

    var places := token_places(count)
    var radius := token_radius(count)
    for i in range(count):
        # NOTE (mristin):
        # The top token is eaten first, the bottom one last.
        var fill := clampf(left - (count - 1 - i), 0.0, 1.0)
        _token(places[i], radius, THINGS[(count - 1 - i) % THINGS.size()], fill, low)


## A ration: a round token with its picture; the eaten part greys out like
## the hand of a clock, and an eaten token is a dashed ring.
func _token(center: Vector2, radius: float, thing: String, fill: float, low: bool) -> void:
    if fill <= 0.0:
        var dashes := 16
        for k in range(dashes):
            var start := TAU * k / dashes
            draw_arc(
                center,
                radius,
                start,
                start + TAU / dashes * 0.55,
                4,
                Color(Paper.INK, 0.35),
                2.0,
                true
            )
        return
    draw_circle(center + Vector2(2, 3), radius, Color(0, 0, 0, 0.18))
    draw_circle(center, radius, Paper.CARD)
    draw_set_transform(center, 0.0, Vector2.ONE * radius / 40.0)
    match thing:
        "barrel":
            _barrel()
        "bread":
            _bread()
        "cheese":
            _cheese()
        "fish":
            _fish()
        _:
            _figs()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if fill < 1.0:
        # NOTE (mristin):
        # The eaten part, from twelve o'clock clockwise.
        var pie := PackedVector2Array([center])
        var steps := 24
        var eaten := (1.0 - fill) * TAU
        for k in range(steps + 1):
            var angle := -PI * 0.5 + eaten * k / steps
            pie.append(center + Vector2(cos(angle), sin(angle)) * (radius + 1.0))
        if pie.size() >= 3 and eaten > 0.05:
            draw_colored_polygon(pie, Color(0.55, 0.52, 0.48, 0.78))
    var ring := Paper.RED if low and fill < 1.0 else Paper.INK
    draw_arc(center, radius, 0, TAU, 32, ring, 3.0 if low else 2.5, true)


func _shape(points: PackedVector2Array, fill: Color, width := 2.0) -> void:
    draw_colored_polygon(points, fill)
    var outline := points.duplicate()
    outline.append(points[0])
    draw_polyline(outline, INK, width, true)


static func _ellipse(center: Vector2, radii: Vector2, from := 0.0, to := TAU) -> PackedVector2Array:
    var points := PackedVector2Array()
    var steps := 20
    for i in range(steps + 1):
        var angle := lerpf(from, to, float(i) / steps)
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    return points


## A barrel of water with iron hoops and the water shining at the top.
func _barrel() -> void:
    var body := PackedVector2Array()
    for i in range(11):
        var t := float(i) / 10.0
        body.append(Vector2(-15 - sin(t * PI) * 5, 24 - t * 48))
    for i in range(10, -1, -1):
        var t := float(i) / 10.0
        body.append(Vector2(15 + sin(t * PI) * 5, 24 - t * 48))
    _shape(body, WOOD)
    for x in [-8.0, 0.0, 8.0]:
        draw_line(Vector2(x, 22), Vector2(x * 1.15, -22), WOOD_DARK, 1.5)
    for y in [14.0, -14.0]:
        draw_line(Vector2(-19, y), Vector2(19, y), IRON, 4.0)
    _shape(_ellipse(Vector2(0, -24), Vector2(15, 5)), WOOD_DARK, 1.5)
    draw_colored_polygon(_ellipse(Vector2(0, -24), Vector2(12, 3.5)), WATER)


## A round loaf of bread with its scored crust.
func _bread() -> void:
    _shape(_ellipse(Vector2(0, 4), Vector2(28, 19)), CRUST)
    draw_colored_polygon(_ellipse(Vector2(-6, -3), Vector2(16, 8)), CRUMB.lerp(CRUST, 0.4))
    for x in [-12.0, 0.0, 12.0]:
        draw_line(Vector2(x - 5, -8), Vector2(x + 5, 12), CRUMB, 3.0)


## A wheel of cheese with a wedge cut out.
func _cheese() -> void:
    _shape(
        PackedVector2Array([Vector2(-26, -8), Vector2(26, -8), Vector2(26, 14), Vector2(-26, 14)]),
        RIND
    )
    _shape(_ellipse(Vector2(0, 14), Vector2(26, 8), 0.0, PI), RIND, 1.5)
    _shape(_ellipse(Vector2(0, -8), Vector2(26, 8)), CHEESE)
    _shape(
        PackedVector2Array([Vector2(0, -8), Vector2(26, -8), Vector2(16, -2)]),
        CHEESE.darkened(0.15),
        1.2
    )
    for hole in [Vector2(-12, -9), Vector2(-4, -6), Vector2(7, -11)]:
        draw_circle(hole, 2.0, RIND)


## A salted fish.
func _fish() -> void:
    var body := _ellipse(Vector2(-4, 0), Vector2(24, 11))
    _shape(body, FISH)
    _shape(
        PackedVector2Array([Vector2(18, 0), Vector2(32, -12), Vector2(32, 12)]), FISH.darkened(0.15)
    )
    draw_circle(Vector2(-18, -3), 3.0, INK)
    for x in [-8.0, 0.0, 8.0]:
        draw_arc(Vector2(x, 0), 8, -0.8, 0.8, 6, Color(INK, 0.5), 1.5, true)


## A handful of figs.
func _figs() -> void:
    for at in [Vector2(-12, 6), Vector2(10, 6), Vector2(0, -10)]:
        draw_circle(at, 13, FIG)
        draw_arc(at, 13, 0, TAU, 16, INK, 1.5, true)
        draw_line(at + Vector2(0, -13), at + Vector2(3, -19), Color(0.3, 0.45, 0.2), 2.5)
