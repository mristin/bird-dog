class_name FloatingLoot
extends Node2D

## A barrel or a small chest floating on the water, with ducats inside (see
## DESIGN.md, section 10). It bobs on the waves; a boat which sails over it
## picks it up.

## Where it floats, in kilometres.
var km := Vector2.ZERO

## How many ducats are inside.
var ducats := 10

## Whether it is a chest (more ducats) or a barrel.
var chest := false


func _process(_delta: float) -> void:
    position = km * ChartView.PX_PER_KM
    queue_redraw()


func _draw() -> void:
    var t := Time.get_ticks_msec() / 1000.0 + km.x
    var bob := Vector2(0, sin(t * 2.4) * 3.0)
    var tilt := sin(t * 1.7) * 0.15
    draw_arc(Vector2.ZERO, 22, 0, TAU, 20, Color(1, 1, 1, 0.35), 3.0, true)
    draw_set_transform(bob, tilt, Vector2.ONE)
    if chest:
        draw_rect(Rect2(-16, -10, 32, 20), Color(0.5, 0.3, 0.14))
        draw_rect(Rect2(-16, -10, 32, 7), Color(0.6, 0.38, 0.18))
        draw_rect(Rect2(-16, -10, 32, 20), PortIcons.INK, false, 2.0)
        draw_rect(Rect2(-3, -5, 6, 7), Paper.GOLD)
        draw_circle(Vector2(0, -14), 4, Paper.GOLD)
    else:
        draw_rect(Rect2(-12, -15, 24, 30), Color(0.62, 0.42, 0.22))
        for y in [-9.0, 9.0]:
            draw_line(Vector2(-12, y), Vector2(12, y), PortIcons.INK, 2.5)
        draw_rect(Rect2(-12, -15, 24, 30), PortIcons.INK, false, 2.0)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
