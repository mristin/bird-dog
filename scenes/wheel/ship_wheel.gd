class_name ShipWheel
extends RefCounted

## Draw a ship's wheel of polished wood and brass on any canvas item.
##
## The wheel has eight turned spokes with handles, brass bands where the spokes
## meet the rim, a brass hub with a small compass rose, and a rope wrapped
## around the king spoke (the one on top when the rudder is straight). The
## middle stays open, so that the player's face shows through it.

const SPOKES := 8

const WOOD_DARK := Color(0.33, 0.18, 0.08)
const WOOD := Color(0.56, 0.32, 0.14)
const WOOD_LIGHT := Color(0.74, 0.47, 0.24)
const WOOD_HIGHLIGHT := Color(0.95, 0.75, 0.5)
const BRASS_DARK := Color(0.55, 0.38, 0.1)
const BRASS := Color(0.84, 0.64, 0.24)
const BRASS_LIGHT := Color(1.0, 0.88, 0.55)
const ROPE := Color(0.86, 0.76, 0.55)
const ROPE_DARK := Color(0.6, 0.5, 0.33)


## Draw the wheel with its rim at [param radius] around [param center],
## turned by [param angle] (in radians, clockwise on the screen).
static func draw(
    canvas: CanvasItem, center: Vector2, radius: float, angle: float, alpha := 1.0
) -> void:
    for i in range(SPOKES):
        var direction := Vector2.UP.rotated(angle + i * TAU / SPOKES)
        _draw_spoke(canvas, center, radius, direction, alpha, i == 0)

    _draw_rim(canvas, center, radius, angle, alpha)
    _draw_hub(canvas, center, radius, angle, alpha)


static func _c(color: Color, alpha: float) -> Color:
    return Color(color, color.a * alpha)


static func _draw_spoke(
    canvas: CanvasItem, center: Vector2, r: float, direction: Vector2, alpha: float, is_king: bool
) -> void:
    var side := direction.orthogonal()

    # The shaft tapers from the hub to the rim.
    var shaft := PackedVector2Array(
        [
            center + direction * r * 0.18 + side * r * 0.05,
            center + direction * r * 0.98 + side * r * 0.032,
            center + direction * r * 0.98 - side * r * 0.032,
            center + direction * r * 0.18 - side * r * 0.05,
        ]
    )
    var colors := PackedColorArray(
        [_c(WOOD_LIGHT, alpha), _c(WOOD, alpha), _c(WOOD_DARK, alpha), _c(WOOD, alpha)]
    )
    canvas.draw_polygon(shaft, colors)

    # The turned handle beyond the rim: a neck, a bulb, a neck and a knob.
    var beads := [[1.13, 0.045], [1.22, 0.07], [1.31, 0.045], [1.39, 0.062]]
    canvas.draw_line(
        center + direction * r * 1.0, center + direction * r * 1.38, _c(WOOD, alpha), r * 0.05, true
    )
    for bead in beads:
        var middle: Vector2 = center + direction * r * bead[0]
        var radius: float = r * bead[1]
        canvas.draw_circle(middle, radius, _c(WOOD_DARK, alpha))
        canvas.draw_circle(middle - side * radius * 0.12, radius * 0.8, _c(WOOD, alpha))
        canvas.draw_circle(
            middle - side * radius * 0.35 - direction * radius * 0.25,
            radius * 0.3,
            _c(WOOD_HIGHLIGHT, alpha * 0.55)
        )

    # The rope around the king spoke shows where straight ahead is.
    if is_king:
        for k in range(7):
            var t := 1.1 + k * 0.045
            var middle := center + direction * r * t
            var color := ROPE if k % 2 == 0 else ROPE_DARK
            canvas.draw_line(
                middle - side * r * 0.075 - direction * r * 0.02,
                middle + side * r * 0.075 + direction * r * 0.02,
                _c(color, alpha),
                r * 0.035,
                true
            )


static func _draw_rim(
    canvas: CanvasItem, center: Vector2, r: float, angle: float, alpha: float
) -> void:
    var segments := 96

    canvas.draw_arc(center, r, 0, TAU, segments, _c(WOOD_DARK, alpha), r * 0.17, true)
    canvas.draw_arc(center, r, 0, TAU, segments, _c(WOOD, alpha), r * 0.12, true)

    # The grain runs along the rim.
    for offset in [-0.035, 0.0, 0.03]:
        canvas.draw_arc(
            center,
            r * (1.0 + offset),
            angle,
            angle + TAU,
            segments,
            _c(WOOD_DARK, alpha * 0.35),
            maxf(1.0, r * 0.008),
            true
        )

    # The brass bands where the spokes meet the rim.
    for i in range(SPOKES):
        var direction := Vector2.UP.rotated(angle + i * TAU / SPOKES)
        var side := direction.orthogonal()
        var middle := center + direction * r
        var band := PackedVector2Array(
            [
                middle - direction * r * 0.095 - side * r * 0.035,
                middle + direction * r * 0.095 - side * r * 0.035,
                middle + direction * r * 0.095 + side * r * 0.035,
                middle - direction * r * 0.095 + side * r * 0.035,
            ]
        )
        (
            canvas
            . draw_polygon(
                band,
                PackedColorArray(
                    [
                        _c(BRASS_DARK, alpha),
                        _c(BRASS_DARK, alpha),
                        _c(BRASS_LIGHT, alpha),
                        _c(BRASS, alpha),
                    ]
                )
            )
        )


static func _draw_hub(
    canvas: CanvasItem, center: Vector2, r: float, angle: float, alpha: float
) -> void:
    canvas.draw_circle(center, r * 0.21, _c(BRASS_DARK, alpha))
    canvas.draw_circle(center, r * 0.185, _c(BRASS, alpha))
    canvas.draw_circle(center + Vector2(-0.04, -0.05) * r, r * 0.12, _c(BRASS_LIGHT, alpha * 0.45))

    # A small engraved compass rose.
    for i in range(4):
        var direction := Vector2.UP.rotated(angle + i * PI / 2)
        var side := direction.orthogonal()
        var long := r * (0.15 if i == 0 else 0.12)
        (
            canvas
            . draw_colored_polygon(
                PackedVector2Array(
                    [
                        center + direction * long,
                        center + side * r * 0.03,
                        center - side * r * 0.03,
                    ]
                ),
                _c(BRASS_DARK, alpha)
            )
        )
    canvas.draw_circle(center, r * 0.035, _c(BRASS_LIGHT, alpha))
    canvas.draw_circle(center, r * 0.018, _c(BRASS_DARK, alpha))
