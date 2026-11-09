class_name CloudShade
extends Control

## Darken the edges of the view while a boat is inside a storm cloud (see
## DESIGN.md, section 9): the crew sees less around the boat.

## How much of the shade to show, from 0 to 1.
var amount := 0.0

var _shown := 0.0


func _process(delta: float) -> void:
    _shown = lerpf(_shown, amount, 1.0 - exp(-delta * 3.0))
    queue_redraw()


func _draw() -> void:
    if _shown < 0.01:
        return
    var steps := 10
    for i in range(steps):
        var share := float(i) / steps
        var inset := size * 0.5 * share * 0.7
        var rect := Rect2(inset, size - inset * 2.0)
        draw_rect(rect, Color(0.15, 0.17, 0.22, 0.09 * _shown), false, size.y * 0.035)
