class_name Chest
extends RefCounted


## The chest of the crew (see DESIGN.md, section 10): a wooden chest with its
## lid open, and the ducats piling up in it, more coins for more ducats.
static func draw(canvas: CanvasItem, foot: Vector2, ducats: int) -> void:
    var font := ThemeDB.fallback_font
    var wood := Color(0.52, 0.32, 0.15)
    var iron := Color(0.3, 0.3, 0.32)
    var lid := PackedVector2Array(
        [
            foot + Vector2(-60, -64),
            foot + Vector2(60, -64),
            foot + Vector2(52, -104),
            foot + Vector2(-52, -104)
        ]
    )
    canvas.draw_colored_polygon(lid, wood.darkened(0.2))
    lid.append(lid[0])
    canvas.draw_polyline(lid, Paper.INK, 3.0, true)

    # NOTE (mristin):
    # The coins: one for every ten ducats, up to a heap of thirty.
    var coins := mini(30, int(ceil(ducats / 10.0)))
    for i in range(coins):
        var row := i / 8
        var at := foot + Vector2(-46 + (i % 8) * 13 + (row % 2) * 6, -62 - row * 7)
        canvas.draw_circle(at, 9, Paper.GOLD)
        canvas.draw_arc(at, 9, 0, TAU, 12, Paper.INK, 1.5, true)
    var box := Rect2(foot + Vector2(-62, -64), Vector2(124, 64))
    canvas.draw_rect(box, wood)
    for x in [-40.0, 0.0, 40.0]:
        canvas.draw_line(foot + Vector2(x, -64), foot + Vector2(x, 0), wood.darkened(0.25), 2.0)
    canvas.draw_rect(Rect2(foot + Vector2(-62, -40), Vector2(124, 8)), iron)
    canvas.draw_rect(Rect2(foot + Vector2(-8, -48), Vector2(16, 20)), Paper.GOLD)
    canvas.draw_rect(box, Paper.INK, false, 3.0)
    var text := Grammar.format(canvas.tr("{ducats} {ducats|ducat|ducats}"), {"ducats": ducats})
    canvas.draw_string(
        font, foot + Vector2(80, -24), text, HORIZONTAL_ALIGNMENT_LEFT, 200, 34, Paper.INK
    )
