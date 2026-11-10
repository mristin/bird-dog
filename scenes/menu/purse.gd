class_name Purse
extends RefCounted


## The ducats of the crew (see DESIGN.md, section 10): a leather purse, tied at
## the neck, with the ducats spilling out beside it, more coins for more
## ducats. There is no chest at home: the crew carries all its ducats on board.
static func draw(canvas: CanvasItem, foot: Vector2, ducats: int) -> void:
    var font := ThemeDB.fallback_font
    var leather := Color(0.55, 0.33, 0.16)

    # NOTE (mristin):
    # The coins: one for every ten ducats, up to a heap of twenty, in rows
    # which get shorter towards the top.
    var coins := mini(20, int(ceil(ducats / 10.0)))
    var row := 0
    var in_row := 0
    var row_size := 6
    for i in range(coins):
        if in_row == row_size:
            row += 1
            in_row = 0
            row_size = maxi(1, row_size - 1)
        var at := foot + Vector2(-16 + in_row * 15 + row * 7, -9 - row * 8)
        canvas.draw_circle(at, 9, Paper.GOLD)
        canvas.draw_arc(at, 9, 0, TAU, 12, Paper.INK, 1.5, true)
        in_row += 1

    # The purse, left of the coins: a round bag with a gathered neck and a cord.
    var body := PackedVector2Array()
    for k in range(25):
        # From the top right, down around the bottom, up to the top left.
        var angle := -PI * 0.3 + PI * 1.6 * k / 24.0
        body.append(foot + Vector2(-58, -40) + Vector2(cos(angle), sin(angle)) * 38)
    body.append(foot + Vector2(-68, -84))
    body.append(foot + Vector2(-48, -84))
    canvas.draw_colored_polygon(body, leather)
    body.append(body[0])
    canvas.draw_polyline(body, Paper.INK, 3.0, true)
    canvas.draw_line(foot + Vector2(-74, -74), foot + Vector2(-42, -74), Paper.GOLD, 5.0, true)
    canvas.draw_line(foot + Vector2(-74, -74), foot + Vector2(-42, -74), Paper.INK, 1.5, true)

    var text := Grammar.format(canvas.tr("{ducats} {ducats|ducat|ducats}"), {"ducats": ducats})
    canvas.draw_string(
        font, foot + Vector2(80, -24), text, HORIZONTAL_ALIGNMENT_LEFT, 200, 34, Paper.INK
    )
