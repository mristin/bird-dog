class_name SeaBoat
extends Node2D

## A boat of the crew at sea, seen from above, as in Pirates! Gold: a planked
## wooden hull with its rail, two masts with square sails which fill with the
## wind and swing with it, a pennant in the colour of the captain on the main
## mast, and a foaming wake behind.
##
## The decorations from Master Ivan's shipyard show, too (see Decoration): the
## sail, the paint of the hull, the pennant, a figurehead at the bow,
## streamers on the yards, lanterns at the stern, and a friend on the deck who
## leans into the turns.
##
## [member heading] is in radians: 0 points north (up), and it grows clockwise.

const HULL := Color(0.4, 0.22, 0.1)
const HULL_DARK := Color(0.27, 0.14, 0.06)
const DECK := Color(0.72, 0.52, 0.3)
const PLANK := Color(0.55, 0.37, 0.19)
const SAIL := Color(0.98, 0.95, 0.86)
const SAIL_SHADE := Color(0.83, 0.77, 0.64)
const INK := Color(0.18, 0.1, 0.05)
const FOAM := Color(1, 1, 1)

## How long the wake is, in samples (one every WAKE_SECONDS).
const WAKE_SAMPLES := 24
const WAKE_SECONDS := 0.12

var heading := 0.0

## The angle of the sails relative to the boat, in radians.
var sail_angle := 0.0

## Whether the sails flap (into the wind).
var luffing := false

## How fast the boat sails, from 0 (still) to about 1 (full speed): the sails
## fill and the foam grows.
var speed_share := 0.0

## Where the wind blows to, relative to the boat, in radians (0 to the bow):
## the pennant streams that way.
var wind_to := PI

## The colour of the sails (the corsairs sail dark, the Venetian patrols red).
var sail_color := SAIL

## The colour of the captain: the pennant and the stripe on the main sail.
var color := Color(0.7, 0.12, 0.1)

## The number of the boat on the main sail, or "" for none.
var mark := ""

## The decorations of the boat, by their slot (see Decoration.SLOTS).
var decorations := {}:
    set(value):
        decorations = value
        sail_color = decorations["sail"].color if decorations.has("sail") else SAIL

## The initial of the captain, for a sail with the initial.
var initial := ""

## The kind of ship (see Ship): how many masts, how long, with oars or not;
## null for a bracera.
var ship: Ship

## What the ship flies so that everybody knows it at once: "pirate" (the
## corsairs: a black flag with a skull, and the skull on the sail), "patrol"
## (the Venetian patrols: a sheriff's star on the sail and on a badge), or ""
## for the crew's boats. A badge with the sign floats over a marked ship, so
## that the children see from afar who comes.
var emblem := ""

## How the boat turns, from -1 (left) to 1 (right): the friend on the deck
## leans into the turn.
var lean := 0.0

## Whether dolphins come to swim along when the boat sails fast (the crew's
## boats, not the corsairs).
var dolphins := false

## How much the dolphins are there, from 0 to 1: they come after a while at
## full speed, and leave when the boat slows down.
var _dolphins_shown := 0.0
var _fast_seconds := 0.0

## The wake: the positions (in the world) and the headings of the stern.
var _wake: Array[Vector2] = []
var _timer := 0.0


func _process(delta: float) -> void:
    if dolphins:
        _fast_seconds = _fast_seconds + delta if speed_share > 0.8 else 0.0
        var wanted := 1.0 if _fast_seconds > 4.0 else 0.0
        _dolphins_shown = move_toward(_dolphins_shown, wanted, delta * 0.5)
    _timer += delta
    if _timer > WAKE_SECONDS:
        _timer = 0.0
        _wake.append(global_position + Vector2(0, 50 * scale.y).rotated(heading))
        if _wake.size() > WAKE_SAMPLES:
            _wake.pop_front()
    queue_redraw()


## The masts of the ship from the bow to the stern: where they stand, how
## wide their sails are, and which one is the main mast (with the pennant).
func masts() -> Array[Dictionary]:
    var count := ship.masts if ship != null else 2
    match count:
        1:
            return [{"at": Vector2(0, -6), "half": 52.0, "main": true}]
        3:
            return [
                {"at": Vector2(0, -38), "half": 30.0, "main": false},
                {"at": Vector2(0, -6), "half": 44.0, "main": true},
                {"at": Vector2(0, 26), "half": 32.0, "main": false},
            ]
    return [
        {"at": Vector2(0, -26), "half": 36.0, "main": false},
        {"at": Vector2(0, 10), "half": 46.0, "main": true},
    ]


func _draw() -> void:
    _draw_wake()
    var length := ship.length if ship != null else 1.0
    draw_set_transform(Vector2.ZERO, heading, Vector2.ONE * length)
    if _dolphins_shown > 0.0:
        _draw_dolphins()
    var t := Time.get_ticks_msec() / 1000.0
    if ship != null and ship.oars:
        _draw_oars(t)
    _draw_hull()
    var wobble := sin(t * 16.0) * 0.1 if luffing else 0.0
    var fill := 0.25 if luffing else clampf(0.35 + speed_share * 0.65, 0.35, 1.0)
    var main_at := Vector2(0, 10)
    var all := masts()
    for i in range(all.size()):
        var mast: Dictionary = all[i]
        var swing := wobble * (1.0 + 0.2 * i)
        _draw_sail(mast["at"], mast["half"], sail_angle + swing, fill, mast["main"])
        if mast["main"]:
            main_at = mast["at"]
        if i == 0:
            _draw_friend(t)
    _draw_pennant(main_at, t)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if emblem != "":
        _draw_badge(t)


## The foam behind the boat: two lines which spread and fade with their age,
## and the foam at the bow.
func _draw_wake() -> void:
    var count := _wake.size()
    if count >= 2:
        for side: float in [-1.0, 1.0]:
            var previous := Vector2.ZERO
            for i in range(count):
                var age := float(count - i) / count
                var back := Vector2.UP.rotated(heading)
                var across := back.orthogonal() * side * (8.0 + age * 40.0)
                var at := to_local(_wake[i]) + across
                if i > 0:
                    var alpha := (1.0 - age) * 0.6 * clampf(speed_share * 1.5, 0.2, 1.0)
                    draw_line(previous, at, Color(FOAM, alpha), 3.0 + (1.0 - age) * 3.0, true)
                previous = at
    if speed_share > 0.1:
        var bow := Vector2(0, -66).rotated(heading)
        for side: float in [-1.0, 1.0]:
            var spread := Vector2(side * 18, 26).rotated(heading)
            draw_line(bow, bow + spread, Color(FOAM, 0.7 * minf(1.0, speed_share)), 4.0, true)


func _hull_shape(scale: float) -> PackedVector2Array:
    var left := PackedVector2Array()
    var right := PackedVector2Array()
    var steps := 16
    for i in range(steps + 1):
        var y := lerpf(-64.0, 50.0, float(i) / steps)
        var bow := clampf((y + 64.0) / 46.0, 0.0, 1.0)
        var stern := clampf((50.0 - y) / 26.0, 0.0, 1.0)
        var half := 24.0 * sqrt(bow) * (0.72 + 0.28 * sqrt(stern))
        left.append(Vector2(-half, y) * scale)
        right.append(Vector2(half, y) * scale)
    right.reverse()
    left.append_array(right)
    return left


func _draw_hull() -> void:
    var hull := _hull_shape(1.0)
    var shadow := PackedVector2Array()
    for point in hull:
        shadow.append(point + Vector2(7, 9).rotated(-heading))
    draw_colored_polygon(shadow, Color(0, 0, 0, 0.22))
    var paint: Decoration = decorations.get("hull")
    draw_colored_polygon(hull, paint.color if paint != null else HULL)
    if paint != null and paint.pattern == "band":
        var band := hull.duplicate()
        band.append(hull[0])
        draw_polyline(band, paint.color_2, 7.0, true)

    var deck := _hull_shape(0.8)
    draw_colored_polygon(deck, DECK)
    for x: float in [-12.0, -6.0, 0.0, 6.0, 12.0]:
        draw_line(Vector2(x, -42 + absf(x) * 1.2), Vector2(x, 38), PLANK, 1.5, true)

    # NOTE (mristin):
    # The quarterdeck at the stern, a hatch and the bowsprit.
    draw_rect(Rect2(-17, 26, 34, 14), HULL)
    draw_rect(Rect2(-17, 26, 34, 14), INK, false, 1.5)
    draw_rect(Rect2(-7, -8, 14, 10), HULL_DARK)
    draw_line(Vector2(0, -64), Vector2(0, -84), HULL_DARK, 4.0, true)

    var rail := hull.duplicate()
    rail.append(hull[0])
    draw_polyline(rail, INK, 3.0, true)
    var inner := deck.duplicate()
    inner.append(deck[0])
    draw_polyline(inner, HULL_DARK, 1.5, true)
    if decorations.has("lanterns"):
        var glow := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 300.0)
        for x: float in [-15.0, 15.0]:
            draw_circle(Vector2(x, 44), 11, Color(1.0, 0.85, 0.4, 0.3 * glow))
            draw_circle(Vector2(x, 44), 5, Color(1.0, 0.85, 0.4, glow))
            draw_arc(Vector2(x, 44), 5, 0, TAU, 10, INK, 1.2, true)
    if decorations.has("figurehead"):
        _draw_figurehead(decorations["figurehead"])


## A square sail on its yard, seen from above: it bellies forward with the
## wind, shaded inside, with its seams.
func _draw_sail(mast: Vector2, half: float, angle: float, fill: float, main: bool) -> void:
    var across := Vector2.RIGHT.rotated(angle)
    var forward := Vector2.UP.rotated(angle)
    var depth := 26.0 * fill

    var sail := PackedVector2Array()
    var shade := PackedVector2Array()
    var steps := 12
    for i in range(steps + 1):
        var u := lerpf(-1.0, 1.0, float(i) / steps)
        sail.append(mast + across * half * u + forward * depth * (1.0 - u * u))
    for i in range(steps, -1, -1):
        var u := lerpf(-1.0, 1.0, float(i) / steps)
        sail.append(mast + across * half * u * 1.04 - forward * 3.0)
        shade.append(mast + across * half * u * 0.96 + forward * depth * 0.35 * (1.0 - u * u))
    for i in range(steps + 1):
        var u := lerpf(-1.0, 1.0, float(i) / steps)
        shade.append(mast + across * half * u * 1.0 - forward * 2.0)

    # NOTE (mristin):
    # The rigging from the ends of the yard to the rail.
    for side: float in [-1.0, 1.0]:
        var end := mast + across * half * side
        draw_line(end, Vector2(side * 20.0, mast.y + 14.0), Color(INK, 0.6), 1.2, true)

    _fill(sail, sail_color)
    _fill(shade, sail_color.darkened(0.15))
    var pattern: Decoration = decorations.get("sail")
    if main and emblem != "":
        draw_set_transform(
            mast.rotated(heading) * _length(), heading + angle, Vector2.ONE * _length()
        )
        _draw_sign(Vector2(0, -depth * 0.5), minf(depth * 0.55, half * 0.5), emblem)
        draw_set_transform(Vector2.ZERO, heading, Vector2.ONE * _length())
    elif main and pattern != null and pattern.pattern != "plain":
        _draw_sail_pattern(pattern, mast, angle, half, depth)
    elif main:
        var stripe := PackedVector2Array()
        for i in range(steps + 1):
            var u := lerpf(-1.0, 1.0, float(i) / steps)
            stripe.append(mast + across * half * u + forward * depth * 0.62 * (1.0 - u * u))
        for i in range(steps, -1, -1):
            var u := lerpf(-1.0, 1.0, float(i) / steps)
            stripe.append(mast + across * half * u + forward * depth * 0.5 * (1.0 - u * u))
        draw_polyline(stripe, color, 4.0, true)
    for u: float in [-0.5, 0.0, 0.5]:
        draw_line(
            mast + across * half * u,
            mast + across * half * u + forward * depth * (1.0 - u * u),
            Color(SAIL_SHADE.darkened(0.15), 0.8),
            1.2,
            true
        )
    var outline := sail.duplicate()
    outline.append(sail[0])
    draw_polyline(outline, INK, 2.0, true)
    draw_line(mast - across * half * 1.08, mast + across * half * 1.08, HULL_DARK, 4.0, true)
    draw_circle(mast, 4.5, HULL_DARK)
    if decorations.has("streamers"):
        _draw_streamers(decorations["streamers"], mast, across, half)

    if main and mark != "":
        var font := ThemeDB.fallback_font
        var at := mast + forward * depth * 0.55
        draw_set_transform(
            at.rotated(heading) * _length(), heading + angle, Vector2.ONE * _length()
        )
        draw_string(font, Vector2(-20, 9), mark, HORIZONTAL_ALIGNMENT_CENTER, 40, 26, color)
        draw_set_transform(Vector2.ZERO, heading, Vector2.ONE * _length())


## The pennant on the top of the main mast, waving in the wind.
func _draw_pennant(mast: Vector2, t: float) -> void:
    var points := PackedVector2Array()
    var back := Vector2.UP.rotated(wind_to)
    var side := back.orthogonal()
    var steps := 6
    for i in range(steps + 1):
        var u := float(i) / steps
        var wave := sin(t * 9.0 - u * 5.0) * 4.0 * u
        points.append(mast + back * u * 34.0 + side * (5.0 * (1.0 - u) + wave))
    for i in range(steps, -1, -1):
        var u := float(i) / steps
        var wave := sin(t * 9.0 - u * 5.0) * 4.0 * u
        points.append(mast + back * u * 34.0 + side * (-5.0 * (1.0 - u) + wave))
    var flag: Decoration = decorations.get("flag")
    if emblem != "" or (flag != null and flag.pattern != "plain"):
        _draw_flag(mast, t, back, side, flag)
        return
    draw_colored_polygon(points, flag.color if flag != null else color)
    var outline := points.duplicate()
    outline.append(points[0])
    draw_polyline(outline, INK, 1.5, true)


## A square flag on the main mast, waving in the wind, with its pattern (see
## Decoration) or the sign of the pirates or of the patrol. The flag is drawn
## in its own frame: x along the flag (from the mast), y across it.
func _draw_flag(mast: Vector2, t: float, back: Vector2, side: Vector2, flag: Decoration) -> void:
    var long := 40.0 if emblem != "" else 34.0
    var wide := 26.0 if emblem != "" else 22.0
    var steps := 6
    var top := PackedVector2Array()
    var bottom := PackedVector2Array()
    for i in range(steps + 1):
        var u := float(i) / steps
        var wave := side * sin(t * 8.0 - u * 4.0) * 3.0 * u
        top.append(mast + back * u * long + side * wide * 0.5 + wave)
        bottom.append(mast + back * u * long - side * wide * 0.5 + wave)
    var cloth := top.duplicate()
    for i in range(steps, -1, -1):
        cloth.append(bottom[i])
    var ground := Color(0.08, 0.07, 0.07)
    if emblem == "patrol":
        ground = Color(0.12, 0.2, 0.5)
    elif flag != null:
        ground = flag.color
    _fill(cloth, ground)

    # NOTE (mristin):
    # The pattern lies in the frame of the flag, at its middle.
    var middle := mast + back * long * 0.5 + side * sin(t * 8.0 - 2.0) * 1.5
    var frame_angle := back.angle()
    draw_set_transform(
        middle.rotated(heading) * _length(), heading + frame_angle, Vector2.ONE * _length()
    )
    if emblem != "":
        _draw_sign(Vector2.ZERO, wide * 0.42, emblem)
    else:
        _draw_flag_pattern(flag, long, wide)
    draw_set_transform(Vector2.ZERO, heading, Vector2.ONE * _length())
    var outline := cloth.duplicate()
    outline.append(cloth[0])
    draw_polyline(outline, INK, 1.5, true)
    draw_circle(mast, 3.0, HULL_DARK)


## The pattern of a flag from the shipyard or a merchant, around the middle
## of the flag (x along it).
func _draw_flag_pattern(flag: Decoration, long: float, wide: float) -> void:
    var ink := flag.color_2
    var half := Vector2(long, wide) * 0.5
    match flag.pattern:
        "checks":
            # NOTE (mristin):
            # The red and white checks (the "šahovnica").
            var cell := Vector2(long / 5.0, wide / 4.0)
            for i in range(5):
                for j in range(4):
                    if (i + j) % 2 == 0:
                        draw_rect(Rect2(-half + Vector2(i * cell.x, j * cell.y), cell), ink)
        "stripes":
            for j in [1, 3]:
                draw_rect(Rect2(-half.x, -half.y + j * wide / 5.0, long, wide / 5.0), ink)
        "sun":
            for k in range(8):
                var ray := Vector2.UP.rotated(k * TAU / 8)
                draw_line(ray * 6.0, ray * 10.0, ink, 2.0)
            draw_circle(Vector2.ZERO, 5.0, ink)
        "star":
            _star(Vector2.ZERO, 9.0, 4.0, 5, ink)
        "moon":
            draw_circle(Vector2(-2, 0), 8.0, ink)
            draw_circle(Vector2(1, -1), 7.0, flag.color)
            _star(Vector2(7, 0), 3.5, 1.5, 5, ink)
        "cross":
            draw_rect(Rect2(-half.x, -wide * 0.12, long, wide * 0.24), ink)
            draw_rect(Rect2(-long * 0.22, -half.y, long * 0.18, wide), ink)
        "lion":
            draw_circle(Vector2.ZERO, 7.0, ink)
            draw_circle(Vector2(-2, -2), 1.5, INK)
            draw_line(Vector2(-6, 6), Vector2(8, 6), ink, 2.0)


## A star with [param points] points, around the centre.
func _star(center: Vector2, outer: float, inner: float, points: int, fill: Color) -> void:
    var star := PackedVector2Array()
    for k in range(points * 2):
        var radius := outer if k % 2 == 0 else inner
        star.append(center + Vector2.UP.rotated(k * PI / points) * radius)
    draw_colored_polygon(star, fill)


## The sign of a marked ship, at the centre with the given radius: the skull
## and the crossed bones of the pirates, or the six-pointed sheriff's star of
## the patrol.
func _draw_sign(center: Vector2, radius: float, kind: String) -> void:
    var r := radius / 10.0
    if kind == "pirate":
        var bone := Color(0.96, 0.94, 0.88)
        for d: float in [-1.0, 1.0]:
            var a := center + Vector2(-9, -7 * d) * r
            var b := center + Vector2(9, 7 * d) * r
            draw_line(a, b, bone, 2.6 * r, true)
            draw_circle(a, 1.8 * r, bone)
            draw_circle(b, 1.8 * r, bone)
        draw_circle(center + Vector2(0, -1.5) * r, 5.5 * r, bone)
        draw_rect(Rect2(center + Vector2(-3, 2.5) * r, Vector2(6, 3.5) * r), bone)
        draw_circle(center + Vector2(-2.2, -2) * r, 1.6 * r, Color(0.08, 0.07, 0.07))
        draw_circle(center + Vector2(2.2, -2) * r, 1.6 * r, Color(0.08, 0.07, 0.07))
    else:
        var gold := Color(0.98, 0.78, 0.22)
        var star := PackedVector2Array()
        for k in range(12):
            var radius_k := 10.0 if k % 2 == 0 else 5.2
            star.append(center + Vector2.UP.rotated(k * PI / 6) * radius_k * r)
        draw_colored_polygon(star, gold)
        var outline := star.duplicate()
        outline.append(star[0])
        draw_polyline(outline, INK, 1.2 * r, true)
        for k in range(6):
            draw_circle(center + Vector2.UP.rotated(k * PI / 3) * 10.0 * r, 1.5 * r, gold)
        draw_circle(center, 2.6 * r, Color(0.12, 0.2, 0.5))


## The badge which floats over a marked ship, upright whatever the heading: a
## black disc with the skull for the pirates, a blue one with the golden star
## for the patrol. It bobs a little, so that it catches the eye.
func _draw_badge(t: float) -> void:
    var at := Vector2(0, -118 - sin(t * 3.0) * 4.0)
    var ground := Color(0.08, 0.07, 0.07) if emblem == "pirate" else Color(0.12, 0.2, 0.5)
    var rim := Color(0.96, 0.94, 0.88) if emblem == "pirate" else Color(0.98, 0.78, 0.22)
    draw_line(at + Vector2(0, 30), Vector2(0, -60), Color(INK, 0.5), 2.0, true)
    draw_circle(at + Vector2(3, 4), 30, Color(0, 0, 0, 0.3))
    draw_circle(at, 30, ground)
    draw_arc(at, 30, 0, TAU, 32, rim, 4.0, true)
    _draw_sign(at, 15.0, emblem)


## Oars along both sides, sweeping together.
func _draw_oars(t: float) -> void:
    var sweep := sin(t * 5.0) * 0.35 * clampf(speed_share * 1.5, 0.2, 1.0)
    for y: float in [-30.0, -12.0, 6.0, 24.0]:
        for side: float in [-1.0, 1.0]:
            var lock := Vector2(side * 20.0, y)
            var blade := lock + Vector2(side * 30.0, 0).rotated(-sweep * side)
            draw_line(lock, blade, HULL_DARK, 3.0, true)
            draw_line(blade, blade + (blade - lock).normalized() * 9.0, PLANK, 6.0, true)


func _length() -> float:
    return ship.length if ship != null else 1.0


## The pattern on the main sail, drawn in the frame of the sail: x across the
## yard, -y the way the sail bellies.
func _draw_sail_pattern(
    sail: Decoration, mast: Vector2, angle: float, half: float, depth: float
) -> void:
    draw_set_transform(mast.rotated(heading) * _length(), heading + angle, Vector2.ONE * _length())
    var middle := Vector2(0, -depth * 0.55)
    var ink := sail.color_2
    match sail.pattern:
        "stripes":
            for u: float in [-0.66, -0.22, 0.22, 0.66]:
                var x := u * half
                draw_line(Vector2(x, -1), Vector2(x, -depth * (1.0 - u * u) + 1), ink, 7.0)
        "sun":
            for k in range(8):
                var ray := Vector2.UP.rotated(k * TAU / 8)
                draw_line(middle + ray * 8, middle + ray * 12, ink, 2.0)
            draw_circle(middle, 7, ink)
        "star":
            var star := PackedVector2Array()
            for k in range(10):
                var radius := 10.0 if k % 2 == 0 else 4.0
                star.append(middle + Vector2.UP.rotated(k * PI / 5) * radius)
            draw_colored_polygon(star, ink)
        "gull":
            draw_polyline(
                PackedVector2Array(
                    [
                        middle + Vector2(-14, -2),
                        middle + Vector2(-6, 3),
                        middle + Vector2(0, -1),
                        middle + Vector2(6, 3),
                        middle + Vector2(14, -2)
                    ]
                ),
                ink,
                3.0,
                true
            )
        "initial":
            var font := ThemeDB.fallback_font
            draw_string(
                font, middle + Vector2(-15, 9), initial, HORIZONTAL_ALIGNMENT_CENTER, 30, 24, ink
            )
        "cross":
            draw_line(middle + Vector2(-12, 0), middle + Vector2(12, 0), ink, 5.0)
            draw_line(middle + Vector2(0, -10), middle + Vector2(0, 10), ink, 5.0)
        "rose":
            for k in range(8):
                var ray := Vector2.UP.rotated(k * TAU / 8) * (12.0 if k % 2 == 0 else 7.0)
                var side := ray.orthogonal().normalized() * 2.5
                draw_colored_polygon(
                    PackedVector2Array([middle + side, middle + ray, middle - side]), ink
                )
            draw_circle(middle, 3, sail.color)
    draw_set_transform(Vector2.ZERO, heading, Vector2.ONE * _length())


## The figurehead at the bow, under the bowsprit.
func _draw_figurehead(figure: Decoration) -> void:
    # NOTE (mristin):
    # The figurehead is drawn larger than life, so that it shows at sea.
    draw_set_transform(
        Vector2(0, -64).rotated(heading) * _length(), heading, Vector2.ONE * _length() * 1.9
    )
    var at := Vector2(0, -4)
    var fill := figure.color
    match figure.pattern:
        "dolphin":
            draw_colored_polygon(
                PackedVector2Array(
                    [
                        at + Vector2(0, -12),
                        at + Vector2(6, -2),
                        at + Vector2(4, 8),
                        at + Vector2(-4, 8),
                        at + Vector2(-6, -2)
                    ]
                ),
                fill
            )
            draw_colored_polygon(
                PackedVector2Array([at + Vector2(-8, 8), at + Vector2(8, 8), at + Vector2(0, 4)]),
                fill.darkened(0.2)
            )
        "lion":
            draw_circle(at, 9, fill.darkened(0.15))
            draw_circle(at, 6, fill)
        "gull":
            draw_polyline(
                PackedVector2Array(
                    [
                        at + Vector2(-12, 2),
                        at + Vector2(-4, -4),
                        at + Vector2(0, 0),
                        at + Vector2(4, -4),
                        at + Vector2(12, 2)
                    ]
                ),
                fill,
                4.0,
                true
            )
            draw_circle(at, 3, figure.color_2)
        "mermaid":
            # NOTE (mristin):
            # Her tail curls back to the bow, her arms reach forward, and her
            # golden hair streams over her shoulders.
            draw_colored_polygon(
                PackedVector2Array(
                    [
                        at + Vector2(-4, -2),
                        at + Vector2(4, -2),
                        at + Vector2(3, 6),
                        at + Vector2(0, 11),
                        at + Vector2(-3, 6)
                    ]
                ),
                fill
            )
            draw_colored_polygon(
                PackedVector2Array(
                    [at + Vector2(0, 10), at + Vector2(-6, 15), at + Vector2(6, 15)]
                ),
                fill.darkened(0.2)
            )
            draw_line(at + Vector2(-3, -3), at + Vector2(-5, -10), figure.color_2, 1.6, true)
            draw_line(at + Vector2(3, -3), at + Vector2(5, -10), figure.color_2, 1.6, true)
            draw_circle(at + Vector2(0, -6), 3.6, Color(0.9, 0.7, 0.25))
            draw_circle(at + Vector2(0, -7), 2.6, figure.color_2)
        "goat":
            draw_circle(at, 6, fill)
            draw_arc(at + Vector2(-5, -4), 5, PI, PI * 1.8, 6, figure.color_2, 2.5)
            draw_arc(at + Vector2(5, -4), 5, PI * 1.2, TAU, 6, figure.color_2, 2.5)
    draw_circle(at, 1.5, INK)
    draw_set_transform(Vector2.ZERO, heading, Vector2.ONE * _length())


## Colourful ribbons hanging from the yard, waving in the wind.
func _draw_streamers(streamers: Decoration, mast: Vector2, across: Vector2, half: float) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    var back := Vector2.UP.rotated(wind_to)
    for k in range(5):
        var u := lerpf(-0.9, 0.9, k / 4.0)
        var start := mast + across * half * u
        var wave := back.orthogonal() * sin(t * 8.0 + k) * 3.0
        var ribbon := streamers.color if k % 2 == 0 else streamers.color_2
        draw_line(start, start + back * 12.0 + wave, ribbon, 3.0, true)


## The friend on the deck (a cat, a parrot, a dog or a goat), leaning into the
## turns, seen from above.
func _draw_friend(t: float) -> void:
    var friend: Decoration = decorations.get("friend")
    if friend == null:
        return
    var at := Vector2(lean * 6.0, 16 + sin(t * 3.0) * 1.0)
    var fill := friend.color
    match friend.pattern:
        "cat":
            draw_circle(at, 6, fill)
            draw_circle(at + Vector2(0, -7), 4, fill)
            draw_colored_polygon(
                PackedVector2Array(
                    [at + Vector2(-4, -9), at + Vector2(-2, -13), at + Vector2(-1, -9)]
                ),
                fill
            )
            draw_colored_polygon(
                PackedVector2Array(
                    [at + Vector2(4, -9), at + Vector2(2, -13), at + Vector2(1, -9)]
                ),
                fill
            )
            draw_line(at + Vector2(0, 5), at + Vector2(-lean * 6.0 + 5, 13), fill, 2.0, true)
        "parrot":
            draw_circle(at, 5, fill)
            draw_colored_polygon(
                PackedVector2Array([at + Vector2(-5, 0), at + Vector2(5, 0), at + Vector2(0, 12)]),
                friend.color_2
            )
            draw_circle(at + Vector2(0, -5), 3, fill)
        "dog":
            draw_colored_polygon(_ellipse_points(at, Vector2(5, 8)), fill)
            draw_circle(at + Vector2(0, -9), 4, fill)
            draw_circle(at + Vector2(-4, -9), 2, friend.color_2)
            draw_circle(at + Vector2(4, -9), 2, friend.color_2)
        "goat":
            draw_colored_polygon(_ellipse_points(at, Vector2(6, 8)), fill)
            draw_circle(at + Vector2(0, -9), 4, fill)
            draw_line(at + Vector2(-2, -12), at + Vector2(-5, -15), friend.color_2, 2.0)
            draw_line(at + Vector2(2, -12), at + Vector2(5, -15), friend.color_2, 2.0)
    draw_circle(at + Vector2(0, -7), 1.0, INK)


func _ellipse_points(center: Vector2, radii: Vector2) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(12):
        var angle := TAU * i / 12
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    return points


## Fill a polygon, unless it is degenerate (a sail seen exactly edge-on): the
## renderer could not triangulate it and would complain.
func _fill(points: PackedVector2Array, color: Color) -> void:
    if Geometry2D.triangulate_polygon(points).is_empty():
        return
    draw_colored_polygon(points, color)


## Two dolphins leaping along the bow, in the frame of the boat: each comes
## out of the water, arcs, and dives again, one after the other.
func _draw_dolphins() -> void:
    var t := Time.get_ticks_msec() / 1000.0
    for i in range(2):
        var side := -1.0 if i == 0 else 1.0
        var phase := fmod(t * 0.6 + i * 0.5, 1.0)
        var up := sin(phase * PI)
        var at := Vector2(side * (44.0 + 6.0 * up), -40.0 - phase * 40.0)
        var alpha := _dolphins_shown * clampf(up * 1.6, 0.0, 1.0)
        if alpha <= 0.02:
            continue
        var grey := Color(0.42, 0.5, 0.58, alpha)
        var scale := 0.8 + 0.4 * up
        var body := PackedVector2Array()
        for k in range(12):
            var angle := TAU * k / 12
            body.append(at + Vector2(cos(angle) * 5.0, sin(angle) * 14.0) * scale)
        draw_colored_polygon(body, grey)
        draw_colored_polygon(
            PackedVector2Array(
                [
                    at + Vector2(-6, 14) * scale,
                    at + Vector2(6, 14) * scale,
                    at + Vector2(0, 9) * scale
                ]
            ),
            grey
        )
        draw_line(at, at + Vector2(side * 4.0, 2.0) * scale, Color(0.3, 0.36, 0.42, alpha), 2.5)
        draw_arc(
            at + Vector2(0, 16), 10.0 * (1.0 - up), 0, TAU, 12, Color(1, 1, 1, alpha * 0.6), 2.0
        )
