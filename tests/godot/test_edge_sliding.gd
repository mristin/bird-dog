extends SceneTree
## Sail the boats along the edge of the world (see ChartView): the edge stops
## a boat as a coast does, and a boat slides along it (see Helm), but it must
## never slide past the land which the edge cuts, nor through any other land.
## Every step of every boat must stay at sea, the whole way from where it was
## to where it is (not only where it ends).
##
## The boats start at sea near the edge, at many places along it where the
## land is near, head along
## the edge (both ways) and into it, and steer into it, away from it or not at
## all, at the frame rate of the game and at the larger steps of the
## end-to-end tests.

## The steps, in seconds: the frame rate of the game, and the steps of the
## end-to-end tests (see end2end/playthrough.gd).
const DELTAS := [1.0 / 60.0, 0.2]

## How long every boat sails, in seconds.
const SECONDS := 12.0

## How far inside the edge the boats start, in kilometres.
const INSIDE_KM := [0.3, 1.5]

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var chart := ChartView.new()
    root.add_child(chart)
    var mission: Mission = MissionCatalog.all()[0]
    var wind := SeaWind.new(mission.sea, 7)
    var bounds := World.bounds_km()
    var runs := 0
    var crossed := 0
    for inside in INSIDE_KM:
        var inner := bounds.grow(-inside)
        for i in range(41):
            var t := i / 40.0
            # NOTE (mristin):
            # Every side, with the heading along it and the heading into it.
            var sides := [
                [Vector2(lerpf(inner.position.x, inner.end.x, t), inner.position.y), 0.0],
                [Vector2(lerpf(inner.position.x, inner.end.x, t), inner.end.y), PI],
                [Vector2(inner.position.x, lerpf(inner.position.y, inner.end.y, t)), -PI / 2],
                [Vector2(inner.end.x, lerpf(inner.position.y, inner.end.y, t)), PI / 2],
            ]
            for side in sides:
                var at: Vector2 = side[0]
                if chart.is_land(at) or not _near_land(chart, at):
                    continue
                var into: float = side[1]
                for heading in [into + PI / 2, into - PI / 2, into + PI / 4, into - PI / 4, into]:
                    for steer in [-1.0, 0.0, 1.0]:
                        for delta in DELTAS:
                            runs += 1
                            var problem := _sail(chart, wind, mission, at, heading, steer, delta)
                            if problem != "":
                                crossed += 1
                                _check(
                                    false,
                                    (
                                        (
                                            "a boat from %s heading %.0f, steering %.0f, "
                                            + "every %.3f s: %s"
                                        )
                                        % [at, rad_to_deg(heading), steer, delta, problem]
                                    )
                                )
                                if crossed > 20:
                                    _finish(chart, runs)
                                    return
    _finish(chart, runs)


func _finish(chart: ChartView, runs: int) -> void:
    print("%d runs along the edge" % runs)
    chart.free()
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## Whether the land lies within a few kilometres of the point: there, the
## edge and the land form the pockets which a boat could slip through.
static func _near_land(chart: ChartView, at: Vector2) -> bool:
    for k in range(16):
        for reach in [2.0, 5.0]:
            if chart.is_land(at + Vector2.RIGHT.rotated(k * TAU / 16) * reach):
                return true
    return false


## Whether a coast runs near the point (in its cell, see ChartView): only
## there, a step could cross the land.
static func _near_coast(chart: ChartView, at: Vector2) -> bool:
    return chart._coast_cells.has(Vector2i((at / ChartView.EDGE_CELL_KM).floor()))


## Sail the boat; return what went wrong, or "".
func _sail(
    chart: ChartView,
    wind: SeaWind,
    mission: Mission,
    at: Vector2,
    heading: float,
    steer: float,
    delta: float
) -> String:
    var helm := Helm.new(0, null)
    helm.km = at
    helm.heading = wrapf(heading, -PI, PI)
    helm.speed = Helm.BASE_KM_PER_SECOND * mission.sea.speed_scale
    helm.steer = steer
    var bounds := World.bounds_km()
    for frame in range(int(SECONDS / delta)):
        var before := helm.km
        helm.sail(delta, wind, chart, mission.sea.speed_scale, 1.0)
        if not bounds.has_point(helm.km):
            return "it left the chart at %s" % helm.km
        if chart.is_land(helm.km):
            return "it stands on the land at %s" % helm.km
        # NOTE (mristin):
        # The way is clipped against the land (see ChartView.is_clear_line),
        # which does not depend on how the boat itself checks it.
        if _near_coast(chart, helm.km) and not chart.is_clear_line(before, helm.km):
            return "it crossed the land from %s to %s" % [before, helm.km]
    return ""
