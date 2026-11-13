extends SceneTree
## Check the races (see RaceStep and DESIGN.md, "The race"): the buoys lie in
## open water, the course takes 40 to 60 seconds to sail, a crew which sails
## the race reasonably well wins it, the rival is not far behind, and a lost
## race only costs a day and makes the rematch easier.
##
## The crew of the test is an autopilot: it follows the A* way over the sea
## (SeaRoute) to the next buoy and back to the harbour, tacks when the way
## leads into the wind, and its hands on the wheel are a little shaky (noise
## on the steering, and now and then a moment of not steering at all), so that
## the race is won by a good crew, not only by a perfect one. The game time
## runs at ten steps a second, so that every race takes a moment only.

## The seeds of the wind and the noise, per race.
const SEEDS := 4

## The step of the game time, in seconds.
const DELTA := 0.1

## A race which takes longer than this is lost by the autopilot, in seconds.
const LIMIT_SECONDS := 400.0

## The buoys keep at least this far from the land, in kilometres.
const CLEAR_KM := 3.0

## The course (from the harbour round the buoys and back), in kilometres.
const COURSE_KM := Vector2(100.0, 220.0)

## The autopilot steers toward the point of its way this far ahead, in
## kilometres.
const LOOKAHEAD_KM := 4.0

## The autopilot tacks this far off the wind, in degrees, and changes the tack
## after this many seconds.
const TACK_DEGREES := 50.0
const TACK_SECONDS := 9.0

## The autopilot finds its way anew at most this often, in seconds.
const REPLAN_SECONDS := 3.0

## The noise on the steering, and how often (per second) the hands rest.
const NOISE := 0.35
const REST_RATE := 0.08

## When the crew wins, the rival must have sailed at least this share of the
## course: a race, not a walk.
const RIVAL_SHARE_AT_FINISH := 0.45

var _failures: Array[String] = []
var _chart: ChartView


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    _chart = ChartView.new()
    root.add_child(_chart)

    var races := 0
    for mission in MissionCatalog.all():
        for step in mission.steps:
            if step is RaceStep:
                races += 1
                _check_course(mission, step)
                for seed_value in range(SEEDS):
                    _check_won(mission, step, seed_value)
                _check_lost(mission, step)
    print("races: %d" % races)
    _check(races > 0, "some mission has a race")

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## The buoys lie in open water, apart, and the course has a fair length.
func _check_course(mission: Mission, race: RaceStep) -> void:
    var label := "%s/%s" % [mission.id, race.id]
    _check(race.buoys.size() >= 2, "%s: the course has buoys" % label)
    _check(race.buoys.size() <= RaceStep.buoy_names.size(), "%s: every buoy has a name" % label)
    _check(race.port != null and race.rival != null, "%s: a port and a rival" % label)
    var kms := race.buoys_km()
    for i in range(kms.size()):
        var clear := true
        for k in range(16):
            clear = (
                clear
                and not _chart.is_land(kms[i] + Vector2.RIGHT.rotated(k * TAU / 16) * CLEAR_KM)
            )
        _check(clear, "%s: buoy %d lies in open water" % [label, i + 1])
        for j in range(i):
            _check(
                kms[i].distance_to(kms[j]) > 8.0,
                "%s: buoys %d and %d apart" % [label, j + 1, i + 1]
            )
    var course := _course_km(race)
    print("%s: the course is %.0f km" % [label, course])
    _check(
        course >= COURSE_KM.x and course <= COURSE_KM.y,
        "%s: the course is %.0f km, within %s" % [label, course, COURSE_KM]
    )
    for cut in race.cuts:
        _check(cut >= 0 and cut < race.buoys.size(), "%s: the cut buoy exists" % label)


func _course_km(race: RaceStep) -> float:
    var at := World.port_km(race.port)
    var total := 0.0
    for buoy in race.buoys_km():
        total += at.distance_to(buoy)
        at = buoy
    return total + at.distance_to(World.port_km(race.port))


## A run of the mission, right at the start of the race (the challenge
## accepted).
func _start(mission: Mission, race: RaceStep, seed_value: int) -> MissionRun:
    var run := MissionRun.new(mission, seed_value)
    run.step_index = mission.steps.find(race)
    var scene: Variant = race.arrive(run, race.port)
    _check(
        scene != null and race.solution(run) == "race", "%s: the rival dares the crew" % mission.id
    )
    race.act(run, "race")
    _check(race.is_racing(run), "%s: the race is on" % mission.id)
    return run


## The autopilot sails the race; it must win.
func _check_won(mission: Mission, race: RaceStep, seed_value: int) -> void:
    var label := "%s/%s (seed %d)" % [mission.id, race.id, seed_value]
    var run := _start(mission, race, seed_value)
    var wind := SeaWind.new(mission.sea, seed_value + 1)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value * 7919 + 13
    var helm := Helm.new(0, null)
    helm.fit(run.hold().ship, run.bag)
    var port_km := World.port_km(race.port)
    var departure := _chart.departure(port_km, port_km, ChartView.leaving_heading(race.port, null))
    helm.km = departure["km"]
    helm.heading = departure["heading"]

    var way := PackedVector2Array()
    var goal := Vector2.INF
    var tack := 1.0
    var tack_left := TACK_SECONDS
    var rest_left := 0.0
    var left_port := false
    var seconds := 0.0
    var replan := 0.0
    while seconds < LIMIT_SECONDS:
        seconds += DELTA
        wind.update(DELTA)
        var state: Dictionary = run.plan[race.id]
        var target: Vector2 = (
            race.buoys_km()[state["buoy"]] if state["buoy"] < race.buoys.size() else port_km
        )
        replan -= DELTA
        if target != goal or (replan <= 0.0 and _off_way(helm.km, way)):
            # NOTE (mristin):
            # The way is found anew at most every few seconds, so that a boat
            # pushed off its way by the coast does not search all the time.
            goal = target
            way = SeaRoute.find(helm.km, goal, 1.5)
            replan = REPLAN_SECONDS
        var aim := _aim(helm.km, way, goal)
        var wanted := (aim - helm.km).angle() + PI / 2
        if wind.is_into_wind(wanted) or _off_wind(wanted, wind) < TACK_DEGREES:
            tack_left -= DELTA
            if tack_left <= 0.0:
                tack = -tack
                tack_left = TACK_SECONDS
            wanted = deg_to_rad(wind.from_degrees + tack * TACK_DEGREES)
        var turn := wrapf(wanted - helm.heading, -PI, PI)
        helm.steer = clampf(turn * 2.5, -1.0, 1.0) + rng.randf_range(-NOISE, NOISE)
        if rest_left > 0.0:
            rest_left -= DELTA
            helm.steer = 0.0
        elif rng.randf() < REST_RATE * DELTA:
            rest_left = 1.0
        helm.steer = clampf(helm.steer, -1.0, 1.0)
        helm.sail(DELTA, wind, _chart, mission.sea.speed_scale, 1.0)

        var events := race.update(run, [helm.km], DELTA, mission.sea.speed_scale, wind)
        if events["lost"]:
            break
        left_port = left_port or helm.km.distance_to(port_km) > 9.0
        if left_port and helm.km.distance_to(port_km) < 5.0 and race.arrive(run, race.port) != null:
            break
    var won := race.is_done(run)
    var rival_at := race.rival_at(run)
    print(
        (
            "%s: %s after %.0f s, buoy %d of %d"
            % [
                label,
                "won" if won else "lost",
                seconds,
                run.plan[race.id]["buoy"],
                race.buoys.size()
            ]
        )
    )
    _check(won, "%s: a good crew wins the race (in %.0f s)" % [label, seconds])
    if won:
        var done := _rival_progress(run, race)
        _check(
            done >= RIVAL_SHARE_AT_FINISH,
            "%s: the rival is not far behind (%.0f%% of his course)" % [label, done * 100.0]
        )
    _check(seconds >= 25.0, "%s: the race takes a while (%.0f s)" % [label, seconds])


## How much of his course the rival sailed, from 0 to 1 (as the crow flies
## between his waypoints).
static func _rival_progress(run: MissionRun, race: RaceStep) -> float:
    var rival: Dictionary = run.plan[race.id]["rival"]
    var points: Array[Vector2] = [World.port_km(race.port)]
    points.append_array(race._rival_waypoints())
    var total := 0.0
    var done := 0.0
    var leg: int = rival["leg"]
    for i in range(1, points.size()):
        var length := points[i - 1].distance_to(points[i])
        total += length
        if i - 1 < leg:
            done += length
        elif i - 1 == leg:
            var at := Vector2(rival["x"], rival["y"])
            done += maxf(0.0, length - at.distance_to(points[i]))
    return done / maxf(total, 0.001)


## Whether the boat strayed from its way, so that the way is found anew.
static func _off_way(at: Vector2, way: PackedVector2Array) -> bool:
    if way.size() < 2:
        return true
    var best := INF
    for point in way:
        best = minf(best, point.distance_to(at))
    return best > 6.0


## The point of the way to steer to: the first one at least
## [constant LOOKAHEAD_KM] ahead of the closest one, or the goal.
static func _aim(at: Vector2, way: PackedVector2Array, goal: Vector2) -> Vector2:
    if way.size() < 2:
        return goal
    var closest := 0
    for i in range(way.size()):
        if way[i].distance_to(at) < way[closest].distance_to(at):
            closest = i
    for i in range(closest, way.size()):
        if way[i].distance_to(at) >= LOOKAHEAD_KM:
            return way[i]
    return goal


## How far the heading is off the wind, in degrees (0 is right into it).
static func _off_wind(heading: float, wind: SeaWind) -> float:
    return absf(wrapf(rad_to_deg(heading) - wind.from_degrees, -180.0, 180.0))


## A crew which does not sail loses: the rival is back first, a day passes,
## the chart points to the harbour for the rematch, and in the rematch the
## rival is slower.
func _check_lost(mission: Mission, race: RaceStep) -> void:
    var label := "%s/%s" % [mission.id, race.id]
    var run := _start(mission, race, 1)
    var speed := mission.sea.speed_scale
    var first := _rival_seconds(run, race, speed)
    _check(race.phase(run) == "lost", "%s: the rival wins against an idle crew" % label)
    _check(is_equal_approx(run.days, RaceStep.LOST_DAYS), "%s: a lost race costs a day" % label)
    _check(run.plan[race.id]["losses"] == 1, "%s: the loss is counted" % label)
    _check(not race.is_done(run), "%s: a lost race is not the end" % label)
    var targets := race.target_ports(run)
    _check(targets.size() == 1 and targets[0] == race.port, "%s: back to the harbour" % label)
    var scene: Variant = race.arrive(run, race.port)
    _check(scene != null and race.solution(run) == "race", "%s: the rival offers a rematch" % label)
    race.act(run, "race")
    var second := _rival_seconds(run, race, speed)
    _check(
        second > first,
        "%s: the rival is slower in the rematch (%.0f s, then %.0f s)" % [label, first, second]
    )
    print(
        "%s: the rival sails the course in %.0f s, the rematch in %.0f s" % [label, first, second]
    )

    # NOTE (mristin):
    # A race saved in the middle goes on where it was (the plan is plain data).
    var saved := _start(mission, race, 3)
    race.update(saved, [], 4.0, speed)
    var data: Dictionary = JSON.parse_string(JSON.stringify(saved.to_data()))
    var loaded := MissionRun.new(mission, 3)
    _check(loaded.restore(data), "%s: a race in progress loads" % label)
    var before: Dictionary = race.rival_at(saved)
    var after: Dictionary = race.rival_at(loaded)
    _check(
        not after.is_empty() and after["km"].distance_to(before["km"]) < 0.01,
        "%s: the rival is where he was" % label
    )
    race.update(loaded, [], 0.5, speed)
    _check(race.is_racing(loaded), "%s: the loaded race goes on" % label)


## Let the rival sail alone until he is back; return how long it took.
static func _rival_seconds(run: MissionRun, race: RaceStep, speed: float) -> float:
    var seconds := 0.0
    while race.is_racing(run) and seconds < LIMIT_SECONDS * 3.0:
        race.update(run, [], 0.5, speed)
        seconds += 0.5
    return seconds
