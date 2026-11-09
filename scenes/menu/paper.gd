class_name Paper
extends RefCounted

## The look of the menus: warm paper, darker toward the edges like an old map,
## with ink, madder red and gold.

const PAPER := Color(0.95, 0.89, 0.76)
const PAPER_DARK := Color(0.84, 0.74, 0.56)
const CARD := Color(0.99, 0.95, 0.86)
const INK := Color(0.2, 0.12, 0.06)
const RED := Color(0.62, 0.11, 0.11)
const GOLD := Color(0.86, 0.64, 0.18)


## Fill the canvas item with the paper and its double ink frame.
static func draw(canvas: CanvasItem, size: Vector2) -> void:
    canvas.draw_rect(Rect2(Vector2.ZERO, size), PAPER_DARK)
    var steps := 12
    for i in range(steps):
        var t := float(i) / steps
        var inset := Vector2(60, 40) * (1.0 - t) * 1.5
        canvas.draw_rect(Rect2(inset, size - inset * 2.0), PAPER_DARK.lerp(PAPER, t))
    canvas.draw_rect(Rect2(Vector2(30, 30), size - Vector2(60, 60)), Color(INK, 0.6), false, 3.0)
    canvas.draw_rect(Rect2(Vector2(42, 42), size - Vector2(84, 84)), Color(INK, 0.35), false, 1.5)
