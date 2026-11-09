class_name TargetArrow
extends Control

## Point to the port where the crew has to go when it lies off the screen: a
## golden arrow on a ring around the middle of the screen (clear of the other
## panels), with the name of the port, so that the kids need not remember the
## clues (it is the year 1600, after all).

## The radius of the ring on which the arrow goes round, in pixels.
const RING := 380.0

## The ports where the crew can go now; the arrow points to the nearest one.
var targets: Array[Port] = []


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    if targets.is_empty():
        return
    var transform := get_viewport().get_canvas_transform()
    var screen := Rect2(Vector2.ZERO, size)
    var target: Port = null
    var at := Vector2.ZERO
    for candidate in targets:
        var candidate_at := transform * (World.port_km(candidate) * ChartView.PX_PER_KM)
        if screen.grow(-40).has_point(candidate_at):
            return
        if target == null or candidate_at.distance_to(size * 0.5) < at.distance_to(size * 0.5):
            target = candidate
            at = candidate_at

    var center := size * 0.5
    var direction := (at - center).normalized()
    var tip := center + direction * RING
    var pulse := 1.0 + 0.1 * sin(Time.get_ticks_msec() / 150.0)
    var side := direction.orthogonal()
    var arrow := PackedVector2Array(
        [
            tip + direction * 40 * pulse,
            tip + side * 30 - direction * 10,
            tip + side * 12 - direction * 10,
            tip + side * 12 - direction * 50,
            tip - side * 12 - direction * 50,
            tip - side * 12 - direction * 10,
            tip - side * 30 - direction * 10,
        ]
    )
    draw_colored_polygon(arrow, Paper.GOLD)
    var outline := arrow.duplicate()
    outline.append(arrow[0])
    draw_polyline(outline, Paper.INK, 3.0, true)

    var font := ThemeDB.fallback_font
    var label := tr(target.name)
    var at_label := tip - direction * 90 + Vector2(-150, 12)
    draw_string_outline(font, at_label, label, HORIZONTAL_ALIGNMENT_CENTER, 300, 34, 8, Paper.PAPER)
    draw_string(font, at_label, label, HORIZONTAL_ALIGNMENT_CENTER, 300, 34, Paper.RED)
    PortIcons.draw(self, target.icon, tip - direction * 90 + Vector2(0, -36), 0.5)
