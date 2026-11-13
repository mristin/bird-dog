class_name RaceCourse
extends Node2D

## The course of a race on the chart (see RaceStep): the buoys, red and white
## with their numbers (the next one bobs, the rounded ones are grey), and the
## rival's boat.

## The buoys, in kilometres on the chart.
var buoys: Array[Vector2] = []

## The index of the next buoy of the crew; the ones before it are rounded.
var next := 0

## The scale of the marks, as the chart's (see ChartView.marker_scale).
var marker_scale := 1.0

var rival: SeaBoat


func _ready() -> void:
    z_index = 4
    rival = SeaBoat.new()
    rival.z_index = 5
    rival.scale = Vector2.ONE * SeaView.BOAT_SCALE
    rival.visible = false
    add_child(rival)


## Show the course of [param race] as it stands in [param run], or hide it.
func show_race(race: RaceStep, run: MissionRun) -> void:
    if race == null or not race.is_racing(run):
        visible = false
        return
    visible = true
    buoys = race.buoys_km()
    next = run.plan[race.id]["buoy"]
    rival.color = race.rival_color
    rival.sail_color = race.rival_sail
    var at := race.rival_at(run)
    rival.visible = not at.is_empty()
    if not at.is_empty():
        rival.position = at["km"] * ChartView.PX_PER_KM
        rival.heading = at["heading"]
        rival.speed_share = 0.8
    queue_redraw()


func _draw() -> void:
    var font := ThemeDB.fallback_font
    var t := Time.get_ticks_msec() / 1000.0
    for i in range(buoys.size()):
        var rounded := i < next
        var bob := sin(t * 3.0 + i) * 4.0 if i == next else 0.0
        var at := buoys[i] * ChartView.PX_PER_KM
        draw_set_transform(at, 0.0, Vector2.ONE * marker_scale)
        var red := Color(0.6, 0.6, 0.6) if rounded else Color(0.8, 0.12, 0.1)
        var white := Color(0.85, 0.85, 0.85) if rounded else Color(0.98, 0.96, 0.9)
        var top := Vector2(0, -20 + bob)
        draw_circle(Vector2(0, 6), 30, Color(1, 1, 1, 0.25))
        draw_colored_polygon(
            PackedVector2Array(
                [
                    top + Vector2(-16, 26),
                    top + Vector2(16, 26),
                    top + Vector2(8, 0),
                    top + Vector2(-8, 0)
                ]
            ),
            red
        )
        draw_rect(Rect2(top + Vector2(-13, 10), Vector2(26, 7)), white)
        draw_line(top, top + Vector2(0, -26), Paper.INK, 3.0, true)
        draw_circle(top + Vector2(0, -28), 5, red)
        var label := str(i + 1)
        draw_string_outline(
            font, top + Vector2(-40, 62), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 34, 8, Paper.PAPER
        )
        draw_string(
            font, top + Vector2(-40, 62), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 34, Paper.INK
        )
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
