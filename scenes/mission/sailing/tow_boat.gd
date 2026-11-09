class_name TowBoat
extends Node2D

## A small fishing boat which tows a boat of the crew to a port when the food
## runs out or the hull breaks (see DESIGN.md, "Provisions"), seen from above
## like the other boats: a little hull with a red lateen sail, a fisherman at
## the oars and an old one at the tiller, a heap of nets and a basket of fish,
## and the tow rope back to the crew's boat. The tow is slow on purpose: the
## crew watches, a little bored ("z z z" rises from their boat), and learns to
## stop in a port in time.
##
## [member heading] is in radians: 0 points north (up), and it grows clockwise.

const HULL := Color(0.46, 0.3, 0.16)
const HULL_DARK := Color(0.3, 0.18, 0.08)
const DECK := Color(0.7, 0.54, 0.34)
const SAIL := Color(0.78, 0.3, 0.18)
const INK := Color(0.18, 0.1, 0.05)
const ROPE := Color(0.86, 0.74, 0.5)
const SKIN := Color(0.86, 0.66, 0.5)
const NET := Color(0.45, 0.5, 0.42)

## The stern, where the rope is tied, in pixels behind the middle of the boat.
const STERN_PX := 34.0

var heading := 0.0

## The rope, from the bow of the towed boat to the stern of this one, in the
## coordinates of the parent (the world): it follows the way over the sea
## (see Tow), so that it never crosses the land.
var rope := PackedVector2Array()

## Where the towed boat is, in the coordinates of the parent, for the "z z z".
var towed_at := Vector2.ZERO


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    var t := Time.get_ticks_msec() / 1000.0
    _draw_rope()
    draw_set_transform(Vector2.ZERO, heading, Vector2.ONE)
    _draw_wake(t)
    _draw_hull()
    _draw_crew(t)
    _draw_sail(t)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _draw_snores(t)


## The rope from the bow of the towed boat to the stern, along the way.
func _draw_rope() -> void:
    if rope.size() < 2:
        return
    var points := PackedVector2Array()
    for point in rope:
        points.append(to_local(point))
    draw_polyline(points, Color(0, 0, 0, 0.25), 5.0, true)
    draw_polyline(points, ROPE, 3.0, true)


func _draw_wake(t: float) -> void:
    for i in range(4):
        var age := fmod(t * 0.8 + i * 0.25, 1.0)
        var back := Vector2(0, 40 + age * 40)
        draw_arc(
            back, 10 + age * 18, PI * 0.15, PI * 0.85, 8, Color(1, 1, 1, 0.5 * (1.0 - age)), 2.0
        )


func _draw_hull() -> void:
    var hull := PackedVector2Array()
    for i in range(13):
        var y := lerpf(-38.0, 34.0, i / 12.0)
        var bow := clampf((y + 38.0) / 26.0, 0.0, 1.0)
        hull.append(Vector2(-15.0 * sqrt(bow), y))
    for i in range(12, -1, -1):
        var y := lerpf(-38.0, 34.0, i / 12.0)
        var bow := clampf((y + 38.0) / 26.0, 0.0, 1.0)
        hull.append(Vector2(15.0 * sqrt(bow), y))
    var shadow := PackedVector2Array()
    for point in hull:
        shadow.append(point + Vector2(5, 7).rotated(-heading))
    draw_colored_polygon(shadow, Color(0, 0, 0, 0.22))
    draw_colored_polygon(hull, HULL)
    var deck := PackedVector2Array()
    for point in hull:
        deck.append(point * 0.78)
    draw_colored_polygon(deck, DECK)
    var outline := hull.duplicate()
    outline.append(hull[0])
    draw_polyline(outline, INK, 2.0, true)

    # NOTE (mristin):
    # A heap of nets at the bow, and a basket of fish behind the mast.
    for k in range(5):
        draw_circle(Vector2(-4 + k * 2.0, -20 + (k % 2) * 3.0), 5.0, NET)
    for x in [-4.0, 0.0, 4.0, 8.0]:
        draw_line(Vector2(x - 6, -24), Vector2(x - 2, -14), Color(INK, 0.4), 1.0)
    draw_circle(Vector2(6, 2), 5.0, Color(0.7, 0.52, 0.28))
    for k in range(3):
        draw_circle(Vector2(4 + k * 2.0, 1 + k), 1.6, Color(0.75, 0.8, 0.85))


## The fisherman at the oars, pulling slowly, and the old one at the tiller.
func _draw_crew(t: float) -> void:
    var pull := sin(t * 2.2) * 0.45
    for side: float in [-1.0, 1.0]:
        var lock := Vector2(side * 13.0, 8)
        var blade := lock + Vector2(side * 28.0, 0).rotated(-pull * side)
        draw_line(lock, blade, HULL_DARK, 2.5, true)
        draw_line(blade, blade + (blade - lock).normalized() * 8.0, DECK, 5.0, true)
    draw_circle(Vector2(0, 12), 6.0, Color(0.3, 0.38, 0.55))
    draw_circle(Vector2(0, 10 - pull * 3.0), 4.0, SKIN)
    draw_circle(Vector2(0, 9 - pull * 3.0), 3.0, Color(0.72, 0.16, 0.12))
    draw_line(Vector2(0, 28), Vector2(sin(t * 0.7) * 5.0, 36), HULL_DARK, 3.0, true)
    draw_circle(Vector2(0, 25), 5.5, Color(0.42, 0.36, 0.3))
    draw_circle(Vector2(0, 24), 3.6, SKIN)
    draw_circle(Vector2(0, 23), 2.6, Color(0.95, 0.95, 0.92))


## The red lateen sail of a Dalmatian fishing boat, on its long slanted yard.
func _draw_sail(t: float) -> void:
    var swing := 0.5 + sin(t * 0.9) * 0.08
    var mast := Vector2(0, -8)
    var yard := Vector2.UP.rotated(swing)
    var a := mast + yard * 30.0
    var b := mast - yard * 22.0
    var belly := yard.orthogonal() * 12.0
    var sail := PackedVector2Array([a, a.lerp(b, 0.5) + belly, b, mast + Vector2(0, 14)])
    draw_colored_polygon(sail, SAIL)
    var outline := sail.duplicate()
    outline.append(sail[0])
    draw_polyline(outline, INK, 1.5, true)
    draw_line(a, b, HULL_DARK, 2.5, true)
    draw_circle(mast, 2.5, HULL_DARK)


## The crew of the towed boat is bored: "z z z" rises from it.
func _draw_snores(t: float) -> void:
    var font := ThemeDB.fallback_font
    var at := to_local(towed_at)
    for i in range(3):
        var age := fmod(t * 0.45 + i / 3.0, 1.0)
        var spot := at + Vector2(30 + age * 30 + sin(age * 9.0) * 6.0, -40 - age * 70)
        var size := int(18 + age * 16)
        var color := Color(1, 1, 1, 0.9 * (1.0 - age))
        draw_string_outline(
            font, spot, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(INK, 0.6 * (1.0 - age))
        )
        draw_string(font, spot, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
