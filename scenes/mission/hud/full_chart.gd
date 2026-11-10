class_name FullChart
extends Control

## The chart of the whole Adriatic over the whole screen, shown with the C key
## (see DESIGN.md, "The chart"): every port with its name, the ports where the
## mission leads (red rings) and where the errands go (blue rings), and the
## boats, so that the crew gets its bearings. The game
## waits meanwhile.

## The chart takes the whole height of the screen, between the title on the
## left and the legend on the right; this much paper on its sides holds the
## names of the ports at the edges (e.g., Rimini and Preveza).
const CHART := Rect2(360, 16, 1200, 1048)
const PAPER_MARGIN := 130.0
const SIDE := 320.0

var chart: Minimap

## Whether the game waited before the chart opened.
var paused_before := false

## The minimap whose targets, errands, boats and marks the chart shows; the
## chart follows it while open, so that a target which changes in a port (a
## task done, an errand taken) shows at once.
var _source: Minimap


## Open the chart on the layer with what the minimap shows.
static func open(layer: Node, minimap: Minimap, was_paused: bool) -> FullChart:
    var full := FullChart.new()
    full.paused_before = was_paused
    layer.add_child(full)
    full.copy_from(minimap)
    return full


## Close the chart; return whether the game waited before it opened.
func close() -> bool:
    queue_free()
    return paused_before


func _init() -> void:
    position = Vector2.ZERO
    size = Vector2(1920, 1080)
    mouse_filter = Control.MOUSE_FILTER_STOP
    chart = Minimap.new()
    chart.labels = true
    chart.paper_margin = PAPER_MARGIN
    chart.position = CHART.position
    chart.size = CHART.size
    chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(chart)


func _process(_delta: float) -> void:
    if is_instance_valid(_source):
        copy_from(_source)


## Show what the small minimap of the view shows.
func copy_from(minimap: Minimap) -> void:
    _source = minimap
    chart.boats = minimap.boats
    chart.visited = minimap.visited
    chart.targets = minimap.targets
    chart.errand_ports = minimap.errand_ports
    chart.marks = minimap.marks


func _draw() -> void:
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
    draw_multiline_string(
        font,
        Vector2(20, 120),
        tr("The chart of the Adriatic"),
        HORIZONTAL_ALIGNMENT_CENTER,
        SIDE,
        52,
        -1,
        Paper.PAPER
    )

    # NOTE (mristin):
    # The legend on the right, one entry under the other.
    var x := size.x - SIDE - 10
    var y := 160.0
    var entries := [
        ["ring", ChartView.TARGET_COLOR, tr("Where the mission leads")],
        ["ring", ChartView.ERRAND_COLOR, tr("Where the deliveries go")],
    ]
    for entry in entries:
        var at := Vector2(x + 16, y - 12)
        if entry[0] == "ring":
            draw_arc(at, 13, 0, TAU, 24, entry[1], 4.0, true)
        else:
            draw_circle(at, 7, entry[1])
        draw_multiline_string(
            font,
            Vector2(x + 46, y),
            entry[2],
            HORIZONTAL_ALIGNMENT_LEFT,
            SIDE - 46,
            32,
            -1,
            Paper.PAPER
        )
        y += 120.0
    draw_multiline_string(
        font,
        Vector2(x, size.y - 80),
        tr("C closes the chart"),
        HORIZONTAL_ALIGNMENT_LEFT,
        SIDE,
        32,
        -1,
        Paper.PAPER
    )
