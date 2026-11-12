class_name Minimap
extends Control

## Show the whole Adriatic small in a corner, with the boats, so that the
## players always know where they are; the port where the crew has to go
## has a blinking red ring, and the ports of the errands have blue rings
## (the same colours as on the sea, see ChartView.TARGET_COLOR). The large
## chart (see FullChart) shows the names of the ports, too.

## How far a name moves down (or up) from its dot, in its font size, where the
## names crowd; the first free place wins.
const LABEL_SHIFTS: Array[float] = [
    0.0, 0.6, -0.6, 1.2, -1.2, 1.8, -1.8, 2.4, -2.4, 3.0, -3.0, 3.6, -3.6
]

## The boats: [{"km": Vector2, "heading": float, "color": Color}, ...].
var boats: Array[Dictionary] = []

## The ports which the crew visited (only remembered for the save; the chart
## shows just where to go next, so that the targets stand out).
var visited := {}

## The ports where the crew can go now.
var targets: Array[Port] = []

## The ports which the crew's errands go to.
var errand_ports: Array[Port] = []

## The clouds, the ships and the barrels at sea (see SeaHazards.marks).
var marks: Array[Dictionary] = []

## Whether the ports show their names (on the large chart, see FullChart).
var labels := false

## The margin of paper left and right of the sea, for the names of the ports
## at the edges (on the large chart), in pixels.
var paper_margin := 0.0

var _polygons: Array[PackedVector2Array] = []
var _frame := Rect2()
var _sea := Rect2()
var _scale := 1.0
var _origin := Vector2.ZERO
var _overlay: Control


func _ready() -> void:
    var bounds := World.bounds_km()
    _scale = minf((size.x - 20 - paper_margin * 2.0) / bounds.size.x, (size.y - 20) / bounds.size.y)
    _origin = (
        Vector2(10, 10)
        - bounds.position * _scale
        + ((size - Vector2(20, 20) - bounds.size * _scale) * 0.5)
    )
    # NOTE (mristin):
    # The frame of the chart: the whole control, or, for the large chart, the
    # sea of the chart with a margin of paper on the sides (the chart is taller
    # than wide), where the names at the edges fit.
    _sea = Rect2(Vector2.ZERO, size)
    _frame = _sea
    if labels:
        _sea = Rect2(_origin + bounds.position * _scale, bounds.size * _scale)
        _frame = _sea.grow_individual(paper_margin, 0, paper_margin, 0)
    for polygon in World.chart()["polygons"]:
        var points := PackedVector2Array()
        for point in polygon:
            points.append(_origin + Vector2(point[0], point[1]) * _scale)
        _polygons.append(points)

    # NOTE (mristin):
    # The coasts are drawn once (Godot keeps them); only the things which
    # move are drawn again every frame, on an overlay.
    _overlay = Control.new()
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.size = size
    _overlay.draw.connect(_draw_overlay)
    add_child(_overlay)


func _process(_delta: float) -> void:
    _overlay.queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(_frame.position + Vector2(6, 8), _frame.size), Color(0, 0, 0, 0.25))
    draw_rect(_frame, Paper.PAPER)
    draw_rect(_sea, ChartView.SEA)
    for points in _polygons:
        draw_colored_polygon(points, ChartView.LAND)


func _draw_overlay() -> void:
    var canvas := _overlay
    for port in World.ports():
        var at := _origin + World.port_km(port) * _scale
        canvas.draw_circle(at, 4.0, ChartView.COAST)
    var pulse := 1.0 + 0.2 * sin(Time.get_ticks_msec() / 200.0)
    for mark in marks:
        var at: Vector2 = _origin + mark["km"] * _scale
        match mark["kind"]:
            "cloud":
                canvas.draw_circle(
                    at, maxf(4.0, mark["radius"] * _scale), Color(0.3, 0.32, 0.38, 0.6)
                )
            "corsair":
                canvas.draw_circle(at, 5.0, Color(0.08, 0.07, 0.07))
                canvas.draw_arc(at, 5.0, 0, TAU, 12, Color(0.96, 0.94, 0.88), 1.5, true)
            "patrol":
                canvas.draw_circle(at, 5.0, Color(0.12, 0.2, 0.5))
                canvas.draw_arc(at, 5.0, 0, TAU, 12, Color(0.98, 0.78, 0.22), 1.5, true)
            "loot":
                canvas.draw_circle(at, 3.0, Paper.GOLD)
            "rival":
                canvas.draw_circle(at, 7.0, Color(0.15, 0.4, 0.2))
                canvas.draw_arc(at, 9.0, 0, TAU, 16, Paper.INK, 2.0, true)
    for port in errand_ports:
        canvas.draw_arc(
            _origin + World.port_km(port) * _scale,
            9.0,
            0,
            TAU,
            20,
            ChartView.ERRAND_COLOR,
            3.0,
            true
        )
    # NOTE (mristin):
    # The red ring of a target stays outside the blue ring of an errand,
    # so that both show when they go to the same port.
    for target in targets:
        var at := _origin + World.port_km(target) * _scale
        canvas.draw_arc(at, 16.0 * pulse, 0, TAU, 24, ChartView.TARGET_COLOR, 4.0, true)
        canvas.draw_arc(at, 16.0 * pulse, 0, TAU, 24, Paper.INK, 1.5, true)
    if labels:
        _draw_labels(canvas)
    for boat in boats:
        var at: Vector2 = _origin + boat["km"] * _scale
        canvas.draw_circle(at, 9.0 * pulse, Color(1, 1, 1, 0.8))
        canvas.draw_circle(at, 6.0, boat["color"])
        canvas.draw_line(at, at + Vector2.UP.rotated(boat["heading"]) * 18, Paper.INK, 3.0, true)
    if _sea != _frame:
        canvas.draw_rect(_sea, Color(Paper.INK, 0.5), false, 2.0)
    canvas.draw_rect(_frame, Paper.INK, false, 4.0)


## The names of the ports beside their dots; the targets and the errands in
## bold colours, so that the crew finds them at once.
func _draw_labels(canvas: Control) -> void:
    var font := ThemeDB.fallback_font
    for label in label_boxes():
        var box: Rect2 = label["box"]
        var font_size: int = label["size"]
        var color: Color = label["color"]
        var baseline := box.position.y + font_size * 0.8
        if label["moved"]:
            var end := Vector2(box.position.x if label["east"] else box.end.x, box.get_center().y)
            canvas.draw_line(label["at"], end, Color(color, 0.7), 1.5, true)
        canvas.draw_string_outline(
            font,
            Vector2(box.position.x, baseline),
            label["text"],
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            font_size,
            6,
            Color(Paper.PAPER, 0.9)
        )
        canvas.draw_string(
            font,
            Vector2(box.position.x, baseline),
            label["text"],
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            font_size,
            color
        )


## Where the names of the ports stand: {"port", "text", "size", "color",
## "at" (the dot of the port), "box" (the name), "east" (the name stands right
## of its dot), "moved" (the name moved away from its dot, with a line to it)},
## in the order of their importance (see tests/godot/test_chart_labels.gd).
func label_boxes() -> Array[Dictionary]:
    var font := ThemeDB.fallback_font
    var result: Array[Dictionary] = []
    var placed: Array[Rect2] = []
    for port in _ports_by_importance():
        var at := _origin + World.port_km(port) * _scale
        var text := tr(port.name)
        var color := ChartView.COAST
        var font_size := 20
        if targets.has(port):
            color = ChartView.TARGET_COLOR
            font_size = 30
        elif errand_ports.has(port):
            color = ChartView.ERRAND_COLOR
            font_size = 26
        # NOTE (mristin):
        # The names of the ports on the eastern coast stand to the right, on
        # the land; those on the western coast to the left.
        var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
        var east := port.longitude > 15.5 - (port.latitude - 41.0) * 0.9
        # The names of the targets stand clear of their red rings.
        var gap := 24.0 if targets.has(port) else 16.0
        var baseline := at.y + font_size * 0.35
        # NOTE (mristin):
        # Where the ports crowd (e.g., Šibenik and Grebaštica), a name moves
        # down or up until it is free, and as the last resort to the other
        # side of its dot; a short line leads to its port.
        var box := Rect2()
        var found := false
        var natural := east
        for side: bool in [east, not east]:
            var left := at.x + gap if side else at.x - gap - width
            for shift in LABEL_SHIFTS:
                var moved := Rect2(
                    left, baseline - font_size * 0.8 + shift * font_size, width, font_size
                )
                if not found and _is_free(moved, placed):
                    box = moved
                    found = true
                    east = side
        if not found:
            var left := at.x + gap if east else at.x - gap - width
            box = Rect2(left, baseline - font_size * 0.8, width, font_size)
        placed.append(box)
        (
            result
            . append(
                {
                    "port": port,
                    "text": text,
                    "size": font_size,
                    "color": color,
                    "at": at,
                    "box": box,
                    "east": east,
                    "moved":
                    east != natural or absf(box.position.y + font_size * 0.8 - baseline) > 1.0,
                }
            )
        )
    return result


## Whether a name may stand in the box: inside the frame of the chart, and
## clear of the names placed before.
func _is_free(box: Rect2, placed: Array[Rect2]) -> bool:
    if not _frame.encloses(box):
        return false
    for other in placed:
        if other.intersects(box):
            return false
    return true


## The frame of the chart, in the coordinates of the control: the sea and, for
## the large chart, the margin of paper on its sides, where the names fit.
func frame() -> Rect2:
    return _frame


## The ports, the targets first, then the errands, then the rest, so that the
## important names get their place first.
func _ports_by_importance() -> Array[Port]:
    var result: Array[Port] = []
    for port in targets + errand_ports + World.ports():
        if not result.has(port):
            result.append(port)
    return result
