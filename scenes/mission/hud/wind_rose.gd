class_name WindRose
extends Control

## Show the wind at a glance (see DESIGN.md, "The view at sea"): a rose with an
## arrow where the wind blows to, its name, and its strength (the colour and
## the thickness of the arrow, and the dots). Before a change, the arrow
## wobbles and the name of the coming wind shows.

const _STRENGTH_COLORS := [Color(0.25, 0.6, 0.3), Color(0.85, 0.65, 0.15), Color(0.85, 0.35, 0.1)]

var wind: SeaWind

## Where the player's boat heads, in radians (0 is north, clockwise), or null
## to show no boat: the rose then marks the boat and the directions into the
## wind, where no boat can sail (see DESIGN.md, "Tacking").
var heading: Variant = null


## The names of the winds, translated.
func _wind_name(wind_name: String) -> String:
    var names := {
        "bura": tr("Bura"),
        "jugo": tr("Jugo"),
        "maestral": tr("Maestral"),
        "tramontana": tr("Tramontana"),
        "levant": tr("Levant"),
        "lebic": tr("Lebić"),
        "ostro": tr("Oštro"),
        "pulenat": tr("Pulenat"),
    }
    return names.get(wind_name, wind_name)


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    if wind == null:
        return
    var font := ThemeDB.fallback_font
    var center := Vector2(size.x * 0.5, 120)
    var radius := 95.0
    draw_circle(center, radius + 8, Color(Paper.PAPER, 0.95))
    draw_arc(center, radius + 8, 0, TAU, 64, Paper.INK, 4.0, true)
    draw_arc(center, radius - 6, 0, TAU, 64, Color(Paper.INK, 0.35), 2.0, true)
    for entry in [
        ["N", Vector2.UP], ["E", Vector2.RIGHT], ["S", Vector2.DOWN], ["W", Vector2.LEFT]
    ]:
        var at: Vector2 = center + entry[1] * (radius - 22)
        draw_string(
            font, at + Vector2(-20, 10), entry[0], HORIZONTAL_ALIGNMENT_CENTER, 40, 26, Paper.INK
        )

    if heading != null:
        _draw_no_go(center, radius)

    var direction := wind.blows_to()
    if wind.is_changing():
        direction = direction.rotated(sin(Time.get_ticks_msec() / 90.0) * 0.35)
    var color: Color = _STRENGTH_COLORS[wind.intensity]
    var width := 10.0 + 6.0 * wind.intensity
    var tip := center + direction * (radius - 10)
    var tail := center - direction * (radius - 30)
    draw_line(tail, tip - direction * 30, Paper.INK, width + 5, true)
    draw_line(tail, tip - direction * 30, color, width, true)
    var side := direction.orthogonal()
    var head := PackedVector2Array(
        [tip, tip - direction * 40 + side * 24, tip - direction * 40 - side * 24]
    )
    draw_colored_polygon(head, color)
    var outline := head.duplicate()
    outline.append(head[0])
    draw_polyline(outline, Paper.INK, 3.0, true)

    var label := _wind_name(wind.name)
    draw_string_outline(
        font, Vector2(0, 265), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 38, 8, Paper.PAPER
    )
    draw_string(font, Vector2(0, 265), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 38, Paper.INK)
    for i in range(3):
        var dot := Vector2(size.x * 0.5 + (i - 1) * 30, 290)
        draw_circle(dot, 10, color if i <= wind.intensity else Color(Paper.INK, 0.2))
        draw_arc(dot, 10, 0, TAU, 20, Paper.INK, 2.0, true)

    if wind.is_changing():
        var coming := tr("{wind} is coming!").format({"wind": _wind_name(wind.next.name)})
        draw_string_outline(
            font, Vector2(0, 340), coming, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, 8, Paper.PAPER
        )
        draw_string(
            font, Vector2(0, 340), coming, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Paper.RED
        )


## The directions into the wind, where no boat can sail, as a red wedge, and
## the player's boat as a marker on the rim, red while it heads into the wind.
func _draw_no_go(center: Vector2, radius: float) -> void:
    var wedge := PackedVector2Array([center])
    var steps := 12
    for i in range(steps + 1):
        var share := float(i) / steps
        var degrees := wind.from_degrees + SeaWind.NO_GO_DEGREES * (2.0 * share - 1.0)
        wedge.append(center + Vector2.UP.rotated(deg_to_rad(degrees)) * (radius - 4))
    draw_colored_polygon(wedge, Color(Paper.RED, 0.18))
    var into := wind.is_into_wind(heading)
    var out := Vector2.UP.rotated(heading)
    var tip := center + out * (radius + 22)
    var side := out.orthogonal()
    var marker := PackedVector2Array([tip, tip - out * 22 + side * 11, tip - out * 22 - side * 11])
    draw_colored_polygon(marker, Paper.RED if into else Paper.GOLD)
    marker.append(marker[0])
    draw_polyline(marker, Paper.INK, 2.5, true)
