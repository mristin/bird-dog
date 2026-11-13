class_name RaceStep
extends MissionStep

## A race around the buoys against a rival (see DESIGN.md, "The race"): in the
## port, the rival dares the crew; "Race!" starts it from the harbour. The
## crew rounds the buoys in their order (with two boats, either one counts)
## and sails back into the harbour. The rival sails the course on his own,
## around the land; if he is back first, he gloats, a day passes, and the crew
## sails back into the harbour for a rematch, in which the rival is a bit
## slower (the edge). Losing costs time, never the mission.
##
## The state lives in run.plan[id]: "phase" ("challenge", "racing", "lost" or
## "won"), "buoy" (the next buoy of the crew), "losses", and "rival" (where he
## is, the waypoint he sails to and his way there), so that a saved mission
## continues the race where it was.

## A boat closer than this to a buoy rounds it, in kilometres.
const ROUND_KM := 4.0

## Against the wind, the rival makes this share of his beam-reach speed good
## (tacking, as the crew does).
const UPWIND := 0.4

## Losing a race costs this many days (the rematch is tomorrow).
const LOST_DAYS := 1.0

## The rival rests this long at the start, in seconds, so that the crew has
## the time to leave the harbour.
const START_SECONDS := 2.0

## The names of the buoys, as English messages, as every name (the lines mark
## them for the extractor of the translations); a course has at most four.
static var buoy_names: Array[Dictionary] = [
    MissionRun.line("Buoy 1"),
    MissionRun.line("Buoy 2"),
    MissionRun.line("Buoy 3"),
    MissionRun.line("Buoy 4"),
]

## The port where the race starts and ends.
@export var port: Port

## The rival who dares the crew (e.g., the Count).
@export var rival: Person

## The colours of the rival's boat: the hull and the sail.
@export var rival_color := Color(0.85, 0.65, 0.1)
@export var rival_sail := Color(0.98, 0.86, 0.3)

## The buoys of the course, in their order: (longitude, latitude).
@export var buoys: Array[Vector2] = []

## How fast the rival sails, as a share of the best speed of a boat.
@export var rival_share := 0.55

## Every lost race makes the rival slower by this share of his speed.
@export var edge := 0.08

## The buoys (by their index) which the rival cuts, cheating through the
## shallows: he sails straight to the buoy after it.
@export var cuts: Array[int] = []

## The objective while sailing to the race, in English, with {port}.
@export var objective := "Sail to {port} for the race!"

## What the rival says when he dares the crew, and before a rematch, in
## English.
@export var challenge: Array[String] = []
@export var rematch: Array[String] = []

## The label of the button which starts the race, in English.
@export var race_label := "Race!"

## What the crew hears when it wins, in English.
@export var won_lines: Array[String] = []

## What the crew hears when the rival is back first, and when he cheats, in
## English.
@export var lost_line := "The rival was back first! A rematch tomorrow."
@export var cut_line := "The rival cut through the shallows!"

## The buoys as ports of their own, so that the chart, the minimap and the
## arrow point to them like to a port (never entered: see [method update]).
var _buoy_ports: Array[Port] = []


func plan(run: MissionRun, _rng: RandomNumberGenerator) -> void:
    run.plan[id] = {"phase": "challenge", "buoy": 0, "losses": 0, "rival": {}}


## The buoys, in kilometres on the chart.
func buoys_km() -> Array[Vector2]:
    var result: Array[Vector2] = []
    for buoy in buoys:
        result.append(World.to_km(buoy.y, buoy.x))
    return result


## The buoy with the index as a port (see [member _buoy_ports]).
func buoy_port(index: int) -> Port:
    if _buoy_ports.size() != buoys.size():
        _buoy_ports.clear()
        for i in range(buoys.size()):
            var buoy := Port.new()
            buoy.id = "buoy_%d" % (i + 1)
            buoy.name = buoy_names[mini(i, buoy_names.size() - 1)]["text"]
            buoy.longitude = buoys[i].x
            buoy.latitude = buoys[i].y
            _buoy_ports.append(buoy)
    return _buoy_ports[index]


func phase(run: MissionRun) -> String:
    return run.plan[id]["phase"]


func is_racing(run: MissionRun) -> bool:
    return phase(run) == "racing"


## The objective of the moment: to the race, round a buoy, or to the finish.
func _objective(run: MissionRun) -> Dictionary:
    var state: Dictionary = run.plan[id]
    if state["phase"] != "racing":
        return MissionRun.line(objective, {"port": port.name})
    if state["buoy"] < buoys.size():
        return MissionRun.line(
            "Round buoy {number} of {count}!", {"number": state["buoy"] + 1, "count": buoys.size()}
        )
    return MissionRun.line("Back to {port}, to the finish!", {"port": port.name})


func start(run: MissionRun) -> void:
    run.set_clue(_objective(run))


func arrive(run: MissionRun, arrived: Port) -> Variant:
    if arrived.id != port.id:
        return null
    var state: Dictionary = run.plan[id]
    match state["phase"]:
        "challenge", "lost":
            var said: Array = []
            for text in challenge if state["phase"] == "challenge" else rematch:
                said.append(MissionRun.line(text))
            return MissionStep.talk(rival, said, MissionRun.line(race_label), "race")
        "racing":
            if state["buoy"] < buoys.size():
                return null
            state["phase"] = "won"
            var lines: Array = []
            for text in won_lines:
                lines.append(MissionRun.line(text))
            return MissionStep.talk(rival, lines, MissionRun.line("Hooray!"))
    return null


func act(run: MissionRun, action: String) -> Variant:
    if action != "race":
        return null
    var state: Dictionary = run.plan[id]
    var at := World.port_km(port)
    state["phase"] = "racing"
    state["buoy"] = 0
    state["rival"] = {"x": at.x, "y": at.y, "leg": 0, "way": [], "rest": START_SECONDS}
    run.set_clue(_objective(run))
    return null


## How fast the rival sails toward [param heading] (radians, 0 north) in the
## wind, as a share of the best speed of a boat: he feels the wind like the
## crew (a light wind is slow, a beam reach fast), and against the wind he
## tacks, too, and makes [constant UPWIND] of his way good. Without a wind (the
## tests of the rival alone), as in a fresh breeze on a beam reach.
static func wind_share(heading: float, wind: SeaWind) -> float:
    if wind == null:
        return 0.8
    var share := SeaWind.factor(heading, wind.from_degrees, wind.intensity)
    if wind.is_into_wind(heading):
        var beam := SeaWind.factor(
            deg_to_rad(wind.from_degrees + 90.0), wind.from_degrees, wind.intensity
        )
        share = UPWIND * beam
    return share


## The waypoints of the rival: the buoys he does not cut, then the harbour.
func _rival_waypoints() -> Array[Vector2]:
    var result: Array[Vector2] = []
    var kms := buoys_km()
    for i in range(kms.size()):
        if not cuts.has(i):
            result.append(kms[i])
    result.append(World.port_km(port))
    return result


## The race goes on for [param delta] seconds: the boats at [param boats]
## (kilometres) round the next buoy when they are close to it, and the rival
## sails his share of the best speed of a boat (in the [param speed_scale] of
## the mission), in the [param wind] (see [method wind_share]; null for a
## steady breeze). Return what happened: {"rounded": the number of
## the buoy rounded (from 1) or 0, "cut": whether the rival just cut a buoy,
## "lost": whether the rival was back first}.
func update(
    run: MissionRun, boats: Array[Vector2], delta: float, speed_scale: float, wind: SeaWind = null
) -> Dictionary:
    var events := {"rounded": 0, "cut": false, "lost": false}
    var state: Dictionary = run.plan[id]
    if state["phase"] != "racing":
        return events
    if state["buoy"] < buoys.size():
        var next := buoys_km()[state["buoy"]]
        for at in boats:
            if at.distance_to(next) < ROUND_KM:
                state["buoy"] += 1
                events["rounded"] = state["buoy"]
                run.set_clue(_objective(run))
                break
    _sail_rival(run, delta, speed_scale, wind, events)
    return events


func _sail_rival(
    run: MissionRun, delta: float, speed_scale: float, wind: SeaWind, events: Dictionary
) -> void:
    var state: Dictionary = run.plan[id]
    var rival_state: Dictionary = state["rival"]
    rival_state["rest"] = maxf(0.0, float(rival_state.get("rest", 0.0)) - delta)
    if rival_state["rest"] > 0.0:
        return
    var share := rival_share * maxf(0.3, 1.0 - edge * state["losses"])
    var speed := Helm.BASE_KM_PER_SECOND * speed_scale * share
    var left := delta  # In seconds: the speed changes with the heading.
    var waypoints := _rival_waypoints()
    while left > 0.0:
        var leg: int = rival_state["leg"]
        if leg >= waypoints.size():
            _lose(run)
            events["lost"] = true
            return
        var at := Vector2(rival_state["x"], rival_state["y"])
        var way: Array = rival_state["way"]
        if way.is_empty():
            way = _way(at, waypoints[leg])
            rival_state["way"] = way
            if cuts.has(_buoy_of_leg(leg) - 1):
                events["cut"] = true
        var goal := Vector2(way[0][0], way[0][1])
        var distance := at.distance_to(goal)
        var km_per_second := speed * wind_share((goal - at).angle() + PI / 2, wind)
        if distance > left * km_per_second:
            at += (goal - at) / maxf(distance, 0.001) * left * km_per_second
            left = 0.0
        else:
            at = goal
            left -= distance / maxf(km_per_second, 0.001)
            way.pop_front()
            if way.is_empty():
                rival_state["leg"] = leg + 1
        rival_state["x"] = at.x
        rival_state["y"] = at.y


## The index of the buoy (or the harbour, after the last buoy) which the leg
## of the rival goes to.
func _buoy_of_leg(leg: int) -> int:
    var count := 0
    for i in range(buoys.size()):
        if cuts.has(i):
            continue
        if count == leg:
            return i
        count += 1
    return buoys.size()


## The way of the rival from [param from] to [param to] around the land, as
## plain data for the save: [[x, y], ...].
static func _way(from: Vector2, to: Vector2) -> Array:
    var path := SeaRoute.find(from, to, 1.5)
    var way: Array = []
    for i in range(1, path.size()):
        way.append([path[i].x, path[i].y])
    way.append([to.x, to.y])
    return way


func _lose(run: MissionRun) -> void:
    var state: Dictionary = run.plan[id]
    state["phase"] = "lost"
    state["losses"] += 1
    run.pass_days(LOST_DAYS)
    run.set_clue(_objective(run))


## Where the rival is, in kilometres, and where he heads (radians, 0 north),
## or {} if he does not race now.
func rival_at(run: MissionRun) -> Dictionary:
    var state: Dictionary = run.plan[id]
    if state["phase"] != "racing" or state["rival"].is_empty():
        return {}
    var rival_state: Dictionary = state["rival"]
    var at := Vector2(rival_state["x"], rival_state["y"])
    var heading := 0.0
    var way: Array = rival_state["way"]
    if not way.is_empty():
        var goal := Vector2(way[0][0], way[0][1])
        if goal.distance_to(at) > 0.001:
            heading = (goal - at).angle() + PI / 2
    return {"km": at, "heading": heading}


func target_ports(run: MissionRun) -> Array[Port]:
    var state: Dictionary = run.plan[id]
    if state["phase"] == "racing" and state["buoy"] < buoys.size():
        return [buoy_port(state["buoy"])]
    return [port]


func solution(run: MissionRun) -> String:
    return "race" if phase(run) in ["challenge", "lost"] else ""


func is_done(run: MissionRun) -> bool:
    return phase(run) == "won"
