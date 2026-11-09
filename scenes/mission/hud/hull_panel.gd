class_name HullPanel
extends Control

## Show how sound the hull is (see DESIGN.md, "Reefs"): a little ship from the
## side, which gets cracks and patches as the reefs and the cliffs damage it,
## and a bar which starts full and empties with the damage. When the hull is
## badly damaged, the panel blinks; when it breaks, the crew is towed to a
## port. On the right, the ducats earned in the mission, as a stack of coins.

## Above this damage, the panel warns.
const BAD := 70.0

const INK := Color(0.2, 0.12, 0.06)
const HULL := Color(0.5, 0.3, 0.14)
const HULL_DARK := Color(0.36, 0.2, 0.09)
const PLANK := Color(0.64, 0.42, 0.22)
const SAIL := Color(0.97, 0.94, 0.85)

var run: MissionRun

## The player whose boat the panel shows.
var player := 0


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    if run == null:
        return
    var health := 100.0 - run.hold(player).damage
    var bad := run.hold(player).damage >= BAD
    var blink := bad and int(Time.get_ticks_msec() / 400) % 2 == 0
    var paper := Paper.PAPER.lerp(Color(0.95, 0.6, 0.45), 0.6) if blink else Paper.PAPER
    draw_rect(Rect2(Vector2(6, 8), size), Color(0, 0, 0, 0.2))
    draw_rect(Rect2(Vector2.ZERO, size), Color(paper, 0.95))
    draw_rect(Rect2(Vector2.ZERO, size), Paper.INK, false, 3.0)

    _draw_ship(Vector2(62, size.y - 14))

    var font := ThemeDB.fallback_font
    var line := tr("Hull") if not bad else tr("Careful! Reefs!")
    draw_string(
        font,
        Vector2(122, 34),
        line,
        HORIZONTAL_ALIGNMENT_LEFT,
        size.x - 132,
        HandButton.fit_size(font, line, 26, size.x - 132),
        Paper.RED if bad else Paper.INK
    )
    # NOTE (mristin):
    # The bar ends well before the coins, so that the hull and the ducats
    # stay apart.
    var bar := Rect2(122, 46, size.x - 270, 24)
    draw_rect(bar, Color(INK, 0.15))
    var color := Color(0.3, 0.6, 0.25).lerp(
        Color(0.85, 0.65, 0.15), clampf((100.0 - health) / 50.0, 0.0, 1.0)
    )
    if health < 30.0:
        color = Paper.RED
    var filled := Rect2(bar.position, Vector2(bar.size.x * health / 100.0, bar.size.y))
    draw_rect(filled, color)
    draw_rect(Rect2(filled.position, Vector2(filled.size.x, 6)), Color(1, 1, 1, 0.25))
    for i in range(1, 4):
        var x := bar.position.x + bar.size.x * i / 4.0
        draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(INK, 0.35), 1.5)
    draw_rect(bar, Paper.INK, false, 2.0)

    _draw_coins(Vector2(size.x - 104, size.y - 22))
    draw_string(
        font,
        Vector2(size.x - 72, size.y - 26),
        str(run.hold(player).on_board()),
        HORIZONTAL_ALIGNMENT_LEFT,
        70,
        34,
        Paper.INK
    )


## A small ship from the side: the planked hull, the mast and a lateen sail;
## cracks and patches show the damage.
func _draw_ship(foot: Vector2) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    var rock := sin(t * 1.8) * 0.04
    draw_set_transform(foot, rock, Vector2.ONE)
    draw_line(Vector2(-48, 2), Vector2(48, 2), Color(0.4, 0.6, 0.75), 4.0)
    var hull := PackedVector2Array(
        [Vector2(-46, -24), Vector2(46, -28), Vector2(36, -2), Vector2(-34, -2)]
    )
    draw_colored_polygon(hull, HULL)
    for y in [-18.0, -11.0]:
        draw_line(Vector2(-42, y), Vector2(42, y - 3), PLANK, 2.0)
    draw_line(Vector2(-46, -24), Vector2(46, -28), HULL_DARK, 4.0)
    var outline := hull.duplicate()
    outline.append(hull[0])
    draw_polyline(outline, INK, 2.0, true)
    draw_line(Vector2(0, -26), Vector2(0, -66), INK, 3.0)
    var sail := PackedVector2Array([Vector2(-30, -30), Vector2(18, -70), Vector2(4, -30)])
    draw_colored_polygon(sail, SAIL)
    sail.append(sail[0])
    draw_polyline(sail, INK, 1.5, true)
    draw_colored_polygon(
        PackedVector2Array([Vector2(0, -66), Vector2(14, -62), Vector2(0, -58)]), Paper.RED
    )

    # NOTE (mristin):
    # A crack for every fifth of damage, and a patch over the older ones.
    var cracks := int(run.hold(player).damage / 20.0)
    for i in range(cracks):
        var x := -30 + i * 15
        if i < cracks - 1:
            draw_rect(Rect2(x - 5, -20, 11, 9), PLANK.lightened(0.2))
            draw_rect(Rect2(x - 5, -20, 11, 9), INK, false, 1.0)
        draw_polyline(
            PackedVector2Array(
                [Vector2(x, -22), Vector2(x + 4, -15), Vector2(x - 1, -10), Vector2(x + 3, -4)]
            ),
            Color(0.1, 0.06, 0.03),
            2.0
        )
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A little stack of gold ducats.
func _draw_coins(foot: Vector2) -> void:
    for i in range(3):
        var center := foot + Vector2(0, -i * 7)
        draw_colored_polygon(_coin(center), Paper.GOLD.darkened(0.15))
        draw_colored_polygon(_coin(center + Vector2(0, -3)), Paper.GOLD)
        var rim := _coin(center + Vector2(0, -3))
        rim.append(rim[0])
        draw_polyline(rim, INK, 1.5, true)
    draw_arc(foot + Vector2(0, -17), 7, 0, TAU, 12, Color(INK, 0.4), 1.2, true)


func _coin(center: Vector2) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(16):
        var angle := TAU * i / 16
        points.append(center + Vector2(cos(angle) * 17, sin(angle) * 6))
    return points
