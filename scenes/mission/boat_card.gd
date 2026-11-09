class_name BoatCard
extends HandButton

## A boat in a harbour, seen from the side, as a button of a line-up: its hull,
## its lateen sail (the sail of the Dalmatian boats) in its colour, with
## patches if it has them.

var boat: Boat


func _draw() -> void:
    super()
    if boat == null:
        return
    var water_y := size.y * 0.72
    draw_rect(Rect2(8, water_y, size.x - 16, size.y * 0.16), Color(ChartView.SEA, 0.7))
    var hull := PackedVector2Array(
        [
            Vector2(size.x * 0.12, water_y - 40),
            Vector2(size.x * 0.88, water_y - 40),
            Vector2(size.x * 0.78, water_y + 6),
            Vector2(size.x * 0.22, water_y + 6),
        ]
    )
    draw_colored_polygon(hull, boat.hull_color)
    var outline := hull.duplicate()
    outline.append(hull[0])
    draw_polyline(outline, Paper.INK, 3.0, true)

    var mast_x := size.x * 0.5
    draw_line(Vector2(mast_x, water_y - 40), Vector2(mast_x, size.y * 0.12), Paper.INK, 6.0, true)
    var sail := PackedVector2Array(
        [
            Vector2(size.x * 0.2, water_y - 60),
            Vector2(size.x * 0.8, size.y * 0.1),
            Vector2(mast_x + 10, water_y - 52),
        ]
    )
    draw_colored_polygon(sail, boat.sail_color)
    var sail_outline := sail.duplicate()
    sail_outline.append(sail[0])
    draw_polyline(sail_outline, Paper.INK, 3.0, true)
    if boat.patched:
        var patch_color := boat.sail_color.darkened(0.35)
        for spot in [Vector2(0.42, 0.42), Vector2(0.56, 0.3), Vector2(0.5, 0.52)]:
            var at := Vector2(size.x * spot.x, size.y * spot.y)
            draw_rect(Rect2(at, Vector2(26, 20)), patch_color)
            draw_rect(Rect2(at, Vector2(26, 20)), Paper.INK, false, 2.0)
