class_name HandMarker
extends RefCounted

## Draw a detected hand while steering, as the same symbol as the hand cursor
## of the menus (a ring with a seagull, see HandCursor) and of the same size,
## whatever the size of the hand in the picture.
##
## A raised hand (above the head line) is green and pulses gently; a hand which
## is down is white and calm.

const RAISED := Color(0.3, 0.95, 0.4)
const DOWN := Color(1, 1, 1)
const BACKING := Color(0.08, 0.15, 0.3, 0.7)


static func draw(
    canvas: CanvasItem, center: Vector2, raised: bool, radius := HandCursor.RADIUS
) -> void:
    var color := RAISED if raised else DOWN
    var pulse := 1.0
    if raised:
        pulse = 1.0 + 0.06 * sin(Time.get_ticks_msec() / 120.0)
    var r := radius * pulse

    canvas.draw_circle(center, r, Color(color, 0.25 if raised else 0.1))
    canvas.draw_arc(center, r, 0, TAU, 40, BACKING, 9.0, true)
    canvas.draw_arc(center, r, 0, TAU, 40, Color(color, 0.95 if raised else 0.75), 5.0, true)
    if raised:
        canvas.draw_arc(center, r + 12.0, 0, TAU, 40, Color(color, 0.35), 5.0, true)
    var scale := radius / HandCursor.RADIUS
    HandCursor.draw_gull(canvas, center + Vector2(0, -3) * scale, 2.4 * scale, color, BACKING)
