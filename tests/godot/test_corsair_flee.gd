extends SceneTree
## Check headless that a corsair always flees from a Venetian patrol, also in
## the middle of a chase, and that it flees well (see SeaHazards._steer_ship
## and SeaHazards._plan_flight): a corsair chases the player, who sails to a
## patrol for safety, in many cases with a different wind and different
## distances, in the open sea and among the islands. Once the corsair comes
## closer to the patrol than SeaHazards.PATROL_REPEL_KM:
##
## * it never sails toward the patrol (the patrol may come closer, though),
## * it never runs aground, but turns along the coasts,
## * it is safely away (farther than [constant SAFE_KM]) soon,
## * it never catches the player meanwhile, and
## * it keeps away from the patrol for a while afterwards.
##
## The test has its own numbers for "safely away" and "a while", so that it
## fails if SeaHazards gives up the flight too early.
##
## The play-tests found corsairs which only turned at the edge of
## PATROL_REPEL_KM and came right back, chasing the player along the patrol,
## which crawled into the wind and which stuttered along the coasts.

const MISSION := preload("res://scenes/mission/mission.tscn")

## With the right flag, the patrols let the boat pass, so that the ducats on
## board go only to the corsairs.
const RIGHT_FLAG := preload("res://data/world/boosters/right_flag.tres")

## The places where the cases sail: in the open sea, and among the islands
## (offsets from the ports, in kilometres).
const PLACES: Array[Dictionary] = [
    {"port": "kotor", "offset": Vector2(-90, 40)},
    {"port": "hvar", "offset": Vector2(0, 12)},
    {"port": "korcula", "offset": Vector2(-10, 15)},
]

## How many cases sail at every place.
const CASES_PER_PLACE := 14

## How long every case sails at most, in seconds.
const SECONDS := 80.0

## A fleeing corsair is safely away (farther than this from the patrol, in
## kilometres) in this many seconds at the latest ...
const SAFE_KM := 45.0
const ESCAPE_SECONDS := 60.0

## ... and keeps out of SeaHazards.PATROL_REPEL_KM around the place where
## the patrol was then for this many seconds.
const KEEP_AWAY_SECONDS := 15.0

## A ship needs this long to turn around, in seconds.
const TURN_SECONDS := 1.5

## A fleeing corsair heads at most this far off the way straight away from
## the patrol, in degrees: 90 is alongside the patrol; a bit more is fine for
## a moment, since the patrol sails, too, and the corsair needs a moment to
## plan anew and turn.
const MAX_OFF_DEGREES := 100.0

## A corsair with the coast straight away from the patrol (closer than this,
## in kilometres) can only turn along the coast; then it heads at most this
## far off, in degrees.
const CORNERED_KM := 3.0
const MAX_OFF_CORNERED_DEGREES := 120.0

## A case tries this many times to place the ships at sea.
const PLACING_TRIES := 40

## The ducats on board of the player's boat.
const DUCATS := 100

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    # NOTE (mristin):
    # The mission draws its wind at random; every case sets its own.
    seed(1)
    var scene: Node = MISSION.instantiate()
    scene.mission_id = "corsairs_of_ulcinj"
    scene.next_scene = ""
    scene.record_result = false
    scene.players = 1
    root.add_child(scene)
    await process_frame
    await process_frame
    scene._on_shared_action("done")
    await process_frame
    scene._on_action("leave", 0)
    await process_frame

    # NOTE (mristin):
    # The test sails the ships itself, frame by frame, so that the mission
    # neither steers the boat nor spawns other ships.
    scene.process_mode = Node.PROCESS_MODE_DISABLED

    scene._run.bag.boosters.append(RIGHT_FLAG)
    var met := 0
    for place in PLACES:
        var base: Vector2 = World.port_km(World.port(place["port"])) + place["offset"]
        _check(not scene._chart.is_land(base), "%s: the place is at sea" % place["port"])
        for case in range(CASES_PER_PLACE):
            if _sail_case(scene, base, "%s, case %d" % [place["port"], case], case):
                met += 1
    # NOTE (mristin):
    # In a few cases, the ships can't be placed at sea, or the corsair gives
    # up the chase before it meets the patrol; most must meet it, though.
    _check(
        met >= PLACES.size() * CASES_PER_PLACE * 3 / 4,
        "in most cases, the corsair chases the player up to the patrol (%d did)" % met
    )
    scene.free()

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## Sail one case; return whether the corsair met the patrol.
func _sail_case(scene: Node, base: Vector2, name: String, case: int) -> bool:
    var hazards: SeaHazards = scene._hazards
    var chart: ChartView = scene._chart
    var helm: Helm = scene._helms[0]
    var helms: Array[Helm] = [helm]

    for ship in hazards._ships:
        ship["boat"].queue_free()
    hazards._ships.clear()
    hazards._corsair_timer = INF
    hazards._patrol_timer = INF
    hazards._rng.seed = case

    # NOTE (mristin):
    # The player between the patrol and the corsair, all at sea; the straight
    # way between them may cross an island, as in the game.
    var rng := RandomNumberGenerator.new()
    rng.seed = case
    hazards._wind.from_degrees = rng.randf_range(0.0, 360.0)
    hazards._wind.intensity = rng.randi_range(0, 2)
    var patrol_km := Vector2.INF
    var corsair_km := Vector2.INF
    for attempt in range(PLACING_TRIES):
        var way := Vector2.RIGHT.rotated(rng.randf() * TAU)
        patrol_km = base + way * rng.randf_range(30.0, 50.0)
        corsair_km = base - way * rng.randf_range(5.0, 20.0)
        if not chart.is_land(patrol_km) and not chart.is_land(corsair_km):
            break
        patrol_km = Vector2.INF
    if patrol_km == Vector2.INF:
        return false
    helm.km = base
    var hold := hazards._run.hold(0)
    hold.ducats = DUCATS
    hold.spent = 0
    var patrol := hazards._add_ship("patrol", patrol_km)
    var corsair := hazards._add_ship("corsair", corsair_km)
    corsair["heading"] = (base - corsair_km).angle() + PI / 2

    var delta := 1.0 / 60.0
    var speed := Helm.BASE_KM_PER_SECOND * hazards._sea.speed_scale * 0.8
    # The seconds since the corsair met the patrol, and since it escaped from
    # it (at the point where the patrol was then); -1 for not yet.
    var since_met := -1.0
    var since_escaped := -1.0
    var escaped_from := Vector2.ZERO
    var errors: Array[String] = []
    for frame in range(int(SECONDS / delta)):
        # NOTE (mristin):
        # The player sails to the patrol and stays by it (sliding along the
        # coasts, as the boats do).
        var to_patrol: Vector2 = patrol["km"] - helm.km
        if to_patrol.length() > 3.0:
            var step := to_patrol.normalized() * speed * delta
            if not chart.is_land(helm.km + step):
                helm.km += step
        var before: Vector2 = corsair["km"]
        var ducats_before := hold.ducats
        hazards._update_ships(delta, helms, helm.km, false)
        if not hazards._ships.has(corsair) or not hazards._ships.has(patrol):
            break

        var t := frame * delta
        var distance: float = corsair["km"].distance_to(patrol["km"])
        if since_met < 0.0 and distance < SeaHazards.PATROL_REPEL_KM:
            since_met = 0.0
        elif since_met >= 0.0:
            since_met += delta
        if since_met < 0.0:
            continue

        if since_escaped > KEEP_AWAY_SECONDS:
            break
        if hold.ducats < ducats_before:
            errors.append("at %.1f s, the corsair caught the player by the patrol" % t)
        if corsair["km"] == before:
            errors.append("at %.1f s, the corsair ran aground" % t)

        if since_escaped < 0.0:
            if distance > SAFE_KM:
                since_escaped = 0.0
                escaped_from = patrol["km"]
            elif since_met > ESCAPE_SECONDS:
                errors.append("after %.0f s, the corsair is still near the patrol" % since_met)
                break
            elif since_met > TURN_SECONDS:
                var away: float = (corsair["km"] - patrol["km"]).angle() + PI / 2
                var off := rad_to_deg(absf(angle_difference(corsair["heading"], away)))
                var ahead: Vector2 = corsair["km"] + Vector2.UP.rotated(away) * CORNERED_KM
                var cornered := not chart.is_clear_line(corsair["km"], ahead)
                if off > (MAX_OFF_CORNERED_DEGREES if cornered else MAX_OFF_DEGREES):
                    var text := "at %.1f s, %.1f km from the patrol, the corsair sails toward it"
                    errors.append(text % [t, distance] + " (%.0f° off)" % off)
        else:
            since_escaped += delta
            if corsair["km"].distance_to(escaped_from) < SeaHazards.PATROL_REPEL_KM:
                errors.append("at %.1f s, the corsair came back to the patrol it had escaped" % t)

    if since_met < 0.0:
        return false
    _check(since_escaped >= 0.0, "%s: the corsair escapes the patrol" % name)
    # NOTE (mristin):
    # One message per case is enough; the ship does the same wrong thing for
    # many frames in a row.
    _check(errors.is_empty(), "%s: %s" % [name, errors[0] if not errors.is_empty() else ""])
    return true
