class_name SeaHazards
extends Node2D

## What happens at sea besides the wind (see DESIGN.md, section 9): the storm
## clouds, the corsairs, the Venetian patrols, and the floating barrels and
## chests with ducats. The mission's SeaConditions decide which of them come
## and how many. None of them hurts anyone: the corsairs take 20 ducats (or
## what there is on board; a day, if there is nothing), the Venetian patrols 10
## as a bribe, since they are no friends of the haiduks (half a day, if there
## is nothing), and the clouds only slow the boats down. No ship chases a boat
## for long: after 10 to 15 seconds, or once it took its toll, it roams away.
## The patrols hunt the corsairs for a while, and the corsairs flee from them.
## The corsairs fly a black flag with a skull, the patrols a sheriff's star
## (see SeaBoat.emblem).
##
## The mission screen calls [method update] every frame while sailing, asks
## [method speed_factor] and [method gust] for every boat, and shows the
## messages of [signal said] as toasts.

## Something happened to the boat of the player which the player should read,
## e.g., "+12 ducats!".
signal said(text: String, player: int)

## Something should sound (see Sfx): "coins", "crash", "thunder", "cannon".
signal sounded(sound: String)

## The Venetian patrols keep to the waters of Venice: closer than this to a
## Venetian port, in kilometres (Venice holds ports all along the coast). The
## corsairs sail everywhere.
const PATROL_WATERS_KM := 120.0

## The corsairs take this many ducats (or all on board, if fewer).
const CORSAIR_LOOT := 20

## The patrols take this many ducats as a bribe (or all on board, if fewer).
const BRIBE := 10

## The corsairs flee from a patrol closer than this, in kilometres.
const PATROL_REPEL_KM := 35.0

## A fleeing corsair keeps fleeing until the patrol is farther than this, in
## kilometres; then it roams away from the patrol for a while (see
## [constant FLED_SECONDS]) before it may chase a boat again. Without this,
## a corsair which chases a boat near a patrol only turns at the edge of
## [constant PATROL_REPEL_KM] and comes right back.
const PATROL_SAFE_KM := 50.0

## How long a corsair which escaped a patrol roams away from it (from, to; in
## seconds).
const FLED_SECONDS := Vector2(20.0, 30.0)

## A fleeing corsair plans its way to one of this many points on a circle
## around the patrol (see [method _plan_flight]), at most this far around the
## circle from straight away (in degrees, so that it never sails back past
## the patrol) ...
const FLEE_DIRECTIONS := 16
const FLEE_SPREAD_DEGREES := 75.0

## ... this far from the patrol, in kilometres (beyond
## [constant PATROL_SAFE_KM], so that it sails on along the way while it
## roams away afterwards).
const FLEE_GOAL_KM := 70.0

## A* plans the ways to at most this many of the most promising points (until
## the next one can't be faster), and the corsair takes the fastest of them
## with the wind.
const FLEE_ROUTES := 3

## The grid of the flight is this coarse, in kilometres (see SeaRoute.find):
## a corsair does not need the narrow channels, but has to plan quickly.
const FLEE_CELL_KM := 2.5
const FLEE_MARGINS_KM: Array[float] = [25.0, 60.0]

## The way of the flight keeps out of the circle around the patrol where
## the corsair is now (it never comes closer): sailing through it costs this
## many times more.
const FLEE_AVOID_COST := 8.0

## The corsair plans its flight in the background (see [method _plan_flight])
## and takes the way this many seconds later, waiting for it only if it is
## not ready yet; meanwhile it flees straight away from the patrol. A fixed
## delay, so that the corsair does the same at any frame rate and in the
## headless tests.
const FLEE_PLAN_SECONDS := 0.25

## The corsair plans its flight anew when the patrol moved this far since,
## in kilometres, or when its way leads toward the patrol, but at most once
## in this many seconds.
const FLEE_REPLAN_KM := 10.0
const FLEE_REPLAN_SECONDS := 1.0

## A ship following a way heads to the first point of it farther than this,
## in kilometres.
const WAYPOINT_KM := 2.0

## A ship looks this far ahead for the land, in kilometres, in this many
## steps (so that it sees a thin tip of the land, too); it turns along the
## coast by these angles (the side it wants to go to first, in degrees)
## instead of running aground.
const LOOK_AHEAD_KM := 0.6
const LOOK_AHEAD_STEPS := 4
const ALONG_COAST_DEGREES: Array[float] = [20.0, 40.0, 60.0, 80.0, 100.0, 130.0, 160.0, 180.0]

## A patrol hunts a corsair closer than this, in kilometres.
const PATROL_HUNT_KM := 30.0

## A ship chases a boat of the players for a while (from, to; in seconds),
## then gives up and roams away; a patrol hunts a corsair a bit longer.
const CHASE_SECONDS := Vector2(10.0, 15.0)
const HUNT_SECONDS := Vector2(15.0, 25.0)

## How fast the corsairs and the patrols sail, as a share of the best speed of
## a boat (before the wind).
const CORSAIR_SPEED_SHARE := 0.6375
const PATROL_SPEED_SHARE := 0.5625

## With cannons on board, the corsairs turn and flee closer than this, in
## kilometres.
const CANNON_KM := 20.0

## Two boats closer than this keep the corsairs away, in kilometres.
const TOGETHER_KM := 8.0

## A ship closer than this to a boat catches it, in kilometres.
const CATCH_KM := 2.5

## With fewer ducats on board than this, the corsairs and the patrols take
## time instead.
const MIN_LOOT := 1

## A boat closer than this to a barrel picks it up, in kilometres.
const PICK_KM := 3.0

## The corsairs chase a boat closer than this, in kilometres.
const CHASE_KM := 30.0

## The hazards appear this far from the boats (out of sight), in kilometres.
const SPAWN_KM := Vector2(48.0, 62.0)

## Farther than this, a hazard is forgotten, in kilometres.
const FORGET_KM := 110.0

## The ships are this large on the chart at the zoom of 1; they keep their
## size on the screen while the cameras zoom in (see ChartView.marker_scale).
const SHIP_SCALE := 1.2

var _sea: SeaConditions
var _chart: ChartView
var _wind: SeaWind
var _run: MissionRun
var _rng := RandomNumberGenerator.new()


## A flight of a corsair planned in the background (see
## [method _plan_flight]): from where, from which patrol and with which wind
## (copies, so that the task touches nothing the game changes meanwhile), and
## the way, once the task is done.
class Flight:
    extends RefCounted
    var km: Vector2
    var patrol: Vector2
    var wind_from: float
    var wind_intensity: int
    var route := PackedVector2Array()
    var task := -1
    var age := 0.0


var _clouds: Array[StormCloud] = []
var _ships: Array[Dictionary] = []
var _loot: Array[FloatingLoot] = []

var _cloud_count := 0
var _cloud_timer := 5.0
var _corsair_timer := 60.0
var _patrol_timer := 90.0
var _loot_timer := 3.0
var _center := Vector2.ZERO


func setup(
    sea: SeaConditions, chart: ChartView, wind: SeaWind, run: MissionRun, seed_value: int
) -> void:
    _sea = sea
    _chart = chart
    _wind = wind
    _run = run
    _rng.seed = seed_value
    SeaRoute.prepare()
    _cloud_count = _rng.randi_range(sea.clouds.x, sea.clouds.y)


## How fast a boat at the point sails, as a share: half inside a cloud, a
## third inside a storm.
func speed_factor(km: Vector2) -> float:
    var factor := 1.0
    for cloud in _clouds:
        if cloud.contains(km):
            factor = minf(factor, 0.35 if cloud.storm else 0.5)
    return factor


## The clouds and the storms now: [{"km": Vector2, "radius": float, "storm":
## bool}] (e.g., for the fishermen who tow a boat around them, see Tow).
func clouds() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for cloud in _clouds:
        result.append({"km": cloud.km, "radius": cloud.radius_km, "storm": cloud.storm})
    return result


func in_cloud(km: Vector2) -> bool:
    for cloud in _clouds:
        if cloud.contains(km):
            return true
    return false


## A push off course for a boat at the point, in radians for this frame.
func gust(km: Vector2, delta: float) -> float:
    var strength := 0.0
    for cloud in _clouds:
        if cloud.contains(km):
            strength = maxf(strength, 1.1 if cloud.storm else 0.5)
    return sin(Time.get_ticks_msec() / 700.0 + km.x) * strength * delta


## How far the nearest ship ("corsair", "patrol") or barrel ("loot") is from
## the point, in kilometres; INF for none.
func nearest(kind: String, km: Vector2) -> float:
    var best := INF
    if kind == "loot":
        for loot in _loot:
            best = minf(best, loot.km.distance_to(km))
        return best
    for ship in _ships:
        if ship["kind"] == kind:
            best = minf(best, ship["km"].distance_to(km))
    return best


## What the minimap shows: [{"km", "kind" ("cloud", "corsair", "patrol",
## "loot"), "radius"}].
func marks() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for cloud in _clouds:
        result.append({"km": cloud.km, "kind": "cloud", "radius": cloud.radius_km})
    for ship in _ships:
        result.append({"km": ship["km"], "kind": ship["kind"], "radius": 0.0})
    for loot in _loot:
        result.append({"km": loot.km, "kind": "loot", "radius": 0.0})
    return result


func update(delta: float, helms: Array[Helm], targets: Array[Port]) -> void:
    var center := Vector2.ZERO
    for helm in helms:
        center += helm.km / helms.size()
    var together := helms.size() > 1 and helms[0].km.distance_to(helms[1].km) < TOGETHER_KM
    _center = center

    _update_clouds(delta, center)
    _update_ships(delta, helms, center, together)
    _update_loot(delta, helms, center, targets)


# region Clouds


func _update_clouds(delta: float, center: Vector2) -> void:
    for cloud in _clouds.duplicate():
        cloud.drift(delta, _wind)
        if cloud.is_gone() or cloud.km.distance_to(center) > FORGET_KM:
            _clouds.erase(cloud)
            cloud.queue_free()
    _cloud_timer -= delta
    if _cloud_timer > 0.0 or _clouds.size() >= _cloud_count:
        return
    _cloud_timer = _rng.randf_range(15.0, 35.0)

    # NOTE (mristin):
    # A cloud comes from upwind, so that it drifts toward the crew.
    var upwind := -_wind.blows_to().rotated(_rng.randf_range(-0.9, 0.9))
    var cloud := StormCloud.new()
    cloud.storm = _sea.storms and _rng.randf() < 0.5
    cloud.km = center + upwind * _rng.randf_range(35.0, 50.0)
    cloud.radius_km = _rng.randf_range(14.0, 22.0) * (1.5 if cloud.storm else 1.0)
    cloud.life = _rng.randf_range(60.0, 180.0)
    cloud.z_index = 8
    cloud.setup(_rng.randi())
    cloud.flashed.connect(_on_flash.bind(cloud))
    add_child(cloud)
    _clouds.append(cloud)


## Lightning in a cloud near the crew rumbles.
func _on_flash(cloud: StormCloud) -> void:
    if cloud.km.distance_to(_center) < 70.0:
        sounded.emit("thunder")


# endregion

# region Corsairs and patrols


func _sea_point(center: Vector2, distance: Vector2) -> Variant:
    for attempt in range(12):
        var point := (
            center
            + Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(distance.x, distance.y)
        )
        if not _chart.is_land(point):
            return point
    return null


## Whether a ship of the kind may sail at the point: the corsairs everywhere,
## the patrols in the waters of Venice.
func _in_waters(kind: String, point: Vector2) -> bool:
    if kind == "corsair":
        return true
    for port in World.ports():
        var distance := World.port_km(port).distance_to(point)
        if distance < PATROL_WATERS_KM and port.power != null and port.power.id == "venice":
            return true
    return false


func _spawn_ship(kind: String, center: Vector2) -> void:
    var point: Variant = _sea_point(center, SPAWN_KM)
    if point == null or not _in_waters(kind, point):
        return
    _add_ship(kind, point)


## Put a ship of the kind ("corsair", "patrol") on the sea at the point, in
## kilometres, and return it (the tests place the ships with it, too).
func _add_ship(kind: String, point: Vector2) -> Dictionary:
    var boat := SeaBoat.new()
    boat.z_index = 5
    boat.scale = Vector2.ONE * SHIP_SCALE * _chart.marker_scale
    if kind == "corsair":
        boat.sail_color = Color(0.2, 0.18, 0.17)
        boat.color = Color(0.1, 0.08, 0.06)
        boat.emblem = "pirate"
    else:
        boat.sail_color = Color(0.72, 0.2, 0.14)
        boat.color = Paper.GOLD
        boat.emblem = "patrol"
    add_child(boat)
    var ship := {
        "kind": kind,
        "km": point,
        "heading": _rng.randf() * TAU,
        "boat": boat,
        "fleeing": false,
        "fled_from": Vector2.ZERO,
        "route": PackedVector2Array(),
        "planned_from": Vector2.INF,
        "replan": 0.0,
        "flight": null,
    }
    _roam_away(ship, Vector2.ZERO, 0.0)
    _ships.append(ship)
    return ship


func _update_ships(delta: float, helms: Array[Helm], center: Vector2, together: bool) -> void:
    if _sea.corsairs:
        _corsair_timer -= delta
        if _corsair_timer <= 0.0:
            _corsair_timer = _rng.randf_range(36.0, 72.0)
            if _count("corsair") < _sea.corsair_count:
                _spawn_ship("corsair", center)
    if _sea.patrols:
        _patrol_timer -= delta
        if _patrol_timer <= 0.0:
            _patrol_timer = _rng.randf_range(48.0, 90.0)
            if _count("patrol") < _sea.patrol_count:
                _spawn_ship("patrol", center)

    for ship in _ships.duplicate():
        _steer_ship(ship, delta, helms, together)
        if ship["km"].distance_to(center) > FORGET_KM:
            _drop_flight(ship)
            _ships.erase(ship)
            ship["boat"].queue_free()


func _exit_tree() -> void:
    # NOTE (mristin):
    # Every task of the pool must be waited for, also when the mission ends.
    for ship in _ships:
        _drop_flight(ship)


func _count(kind: String) -> int:
    var count := 0
    for ship in _ships:
        count += 1 if ship["kind"] == kind else 0
    return count


func _steer_ship(ship: Dictionary, delta: float, helms: Array[Helm], together: bool) -> void:
    var nearest: Helm = helms[0]
    for helm in helms:
        if helm.km.distance_to(ship["km"]) < nearest.km.distance_to(ship["km"]):
            nearest = helm
    var to_boat: Vector2 = nearest.km - ship["km"]
    ship["leaving"] = maxf(0.0, ship["leaving"] - delta)
    var corsair: bool = ship["kind"] == "corsair"

    # NOTE (mristin):
    # What a ship does, the first which applies: a corsair flees from a patrol
    # near it, whatever else it did (also in the middle of a chase), until it
    # is safely away, and then roams away from the patrol for a while; a
    # patrol hunts a corsair near it, for a while; a ship which took its toll,
    # gave up a chase or a hunt roams away for a while; else it chases the
    # boat of a player near it, for a while. The corsairs don't dare to come
    # close to two boats sailing together.
    var patrol: Variant = null
    ship["replan"] = maxf(0.0, ship["replan"] - delta)
    if corsair:
        var wary := PATROL_SAFE_KM if ship["fleeing"] else PATROL_REPEL_KM
        patrol = _nearest_of(ship, "patrol", wary)
        if patrol != null:
            if not ship["fleeing"]:
                ship["fleeing"] = true
                ship["chase"] = 0.0
                ship["route"] = PackedVector2Array()
            ship["fled_from"] = patrol
            # NOTE (mristin):
            # The patrol sails, too: the corsair plans anew when its way does
            # not lead away from where the patrol is now.
            var ahead := _route_ahead(ship)
            var moved: float = ship["planned_from"].distance_to(patrol)
            var astray: bool = (
                not ahead.is_empty() and (ahead[0] - ship["km"]).dot(ship["km"] - patrol) < 0.0
            )
            if astray:
                # NOTE (mristin):
                # Straight away from the patrol until the new way is planned.
                ship["route"] = PackedVector2Array()
            var flight: Flight = ship["flight"]
            if flight != null:
                flight.age += delta
                if flight.age >= FLEE_PLAN_SECONDS:
                    _take_flight(ship)
            elif ship["replan"] <= 0.0 and (ahead.is_empty() or astray or moved > FLEE_REPLAN_KM):
                _start_flight(ship, patrol)
        elif ship["fleeing"]:
            # NOTE (mristin):
            # Safely away, the corsair sails on along its way for a while.
            ship["fleeing"] = false
            if ship["flight"] != null:
                _take_flight(ship)
            var route: PackedVector2Array = ship["route"]
            _roam_away(
                ship,
                ship["km"] - ship["fled_from"],
                _rng.randf_range(FLED_SECONDS.x, FLED_SECONDS.y)
            )
            ship["route"] = route
    var prey: Variant = null
    if not corsair and ship["leaving"] <= 0.0:
        prey = _nearest_of(ship, "corsair", PATROL_HUNT_KM)
    var wanted: float = ship["heading"]
    var turning := 1.5
    var chasing := false
    if patrol != null:
        var ahead := _route_ahead(ship)
        if ahead.is_empty():
            wanted = (ship["km"] - patrol).angle() + PI / 2
        else:
            wanted = (ahead[0] - ship["km"]).angle() + PI / 2
        turning = 3.0
    elif prey != null:
        wanted = (prey - ship["km"]).angle() + PI / 2
        ship["hunt"] += delta
        if ship["hunt"] > ship["hunt_limit"]:
            _roam_away(ship, ship["km"] - prey, _rng.randf_range(20.0, 30.0))
    elif ship["leaving"] > 0.0:
        var ahead := _route_ahead(ship)
        if ahead.is_empty():
            wanted = ship["roam"]
        else:
            wanted = (ahead[0] - ship["km"]).angle() + PI / 2
            ship["roam"] = wanted
    elif corsair and together:
        wanted = (-to_boat).angle() + PI / 2
    elif to_boat.length() < CHASE_KM:
        chasing = true
        wanted = to_boat.angle() + PI / 2
        ship["chase"] += delta
        if corsair and _run.bag.has_effect("cannons") and to_boat.length() < CANNON_KM:
            # NOTE (mristin):
            # Boom! The cannons scare the corsairs away for a good while.
            chasing = false
            _roam_away(ship, -to_boat, 30.0)
            sounded.emit("cannon")
            said.emit(tr("Boom! Your cannons scare the corsairs away!"), nearest.player)
        elif ship["chase"] > ship["chase_limit"]:
            chasing = false
            _roam_away(ship, -to_boat, _rng.randf_range(20.0, 30.0))
    else:
        ship["chase"] = 0.0
    ship["heading"] = lerp_angle(ship["heading"], wanted, 1.0 - exp(-delta * turning))

    var share := CORSAIR_SPEED_SHARE if corsair else PATROL_SPEED_SHARE
    var speed := (
        Helm.BASE_KM_PER_SECOND * _sea.speed_scale * _wind.speed_factor(ship["heading"]) * share
    )
    # NOTE (mristin):
    # The step after a turn along the coast is longer if the ship sails
    # better with the wind then; the land is checked for the longest step.
    var longest_step := Helm.BASE_KM_PER_SECOND * _sea.speed_scale * share * 1.3 * delta
    var free := _free_heading(ship["km"], ship["heading"], wanted, longest_step)
    if free != ship["heading"]:
        # NOTE (mristin):
        # The land is ahead: the ship turns along the coast instead of
        # running aground, to the side where it wants to go.
        ship["heading"] = free
        ship["roam"] = free
        speed = (Helm.BASE_KM_PER_SECOND * _sea.speed_scale * _wind.speed_factor(free) * share)
    var next: Vector2 = ship["km"] + Vector2.UP.rotated(ship["heading"]) * speed * delta
    if _chart.is_land(next):
        # NOTE (mristin):
        # A sliver of the land thinner than the look-out sees: turn along it
        # by the step itself.
        next = ship["km"]
        var side := 1.0 if angle_difference(ship["heading"], wanted) >= 0.0 else -1.0
        for degrees in ALONG_COAST_DEGREES:
            var turned := false
            for sign in [side, -side]:
                var candidate: float = ship["heading"] + sign * deg_to_rad(degrees)
                var step := Vector2.UP.rotated(candidate) * speed * delta
                if not _chart.is_land(ship["km"] + step):
                    ship["heading"] = candidate
                    ship["roam"] = candidate
                    next = ship["km"] + step
                    turned = true
                    break
            if turned:
                break
    ship["km"] = next
    var boat: SeaBoat = ship["boat"]
    boat.position = ship["km"] * ChartView.PX_PER_KM
    boat.heading = ship["heading"]
    boat.scale = Vector2.ONE * SHIP_SCALE * _chart.marker_scale
    boat.speed_share = 0.8
    var wind_to := wrapf(deg_to_rad(_wind.from_degrees) + PI - ship["heading"], -PI, PI)
    boat.sail_angle = clampf(wind_to * 0.5, -1.05, 1.05)
    boat.wind_to = wind_to

    if chasing and to_boat.length() < CATCH_KM:
        # NOTE (mristin):
        # Having taken their toll, they sail off somewhere, anywhere.
        _roam_away(ship, Vector2.RIGHT.rotated(_rng.randf() * TAU), 25.0)
        _caught(ship["kind"], nearest)


## The heading closest to [param heading] in which a ship at [param km] does
## not run onto the land right ahead (see [constant LOOK_AHEAD_KM]), nor with
## its next step of [param step_km], turning
## first to the side of [param wanted]; [param heading] itself if the sea is
## open, or if the ship is caught all around.
func _free_heading(km: Vector2, heading: float, wanted: float, step_km: float) -> float:
    if _is_clear_ahead(km, heading, step_km):
        return heading
    var side := 1.0 if angle_difference(heading, wanted) >= 0.0 else -1.0
    for degrees in ALONG_COAST_DEGREES:
        for sign in [side, -side]:
            var candidate: float = heading + sign * deg_to_rad(degrees)
            if _is_clear_ahead(km, candidate, step_km):
                return candidate
    return heading


## Whether there is no land within [constant LOOK_AHEAD_KM] ahead of a ship
## at [param km] in the heading, nor at its next step ([param step_km]).
func _is_clear_ahead(km: Vector2, heading: float, step_km: float) -> bool:
    var direction := Vector2.UP.rotated(heading)
    if _chart.is_land(km + direction * step_km):
        return false
    for step in range(1, LOOK_AHEAD_STEPS + 1):
        if _chart.is_land(km + direction * LOOK_AHEAD_KM * step / LOOK_AHEAD_STEPS):
            return false
    return true


## The rest of the ship's way: the points it has reached (closer than
## [constant WAYPOINT_KM]) are dropped.
func _route_ahead(ship: Dictionary) -> PackedVector2Array:
    var route: PackedVector2Array = ship["route"]
    while not route.is_empty() and route[0].distance_to(ship["km"]) < WAYPOINT_KM:
        route.remove_at(0)
    ship["route"] = route
    return route


## How long a ship sails the way, in seconds at the speed of 1 (with the
## wind on every leg, see SeaWind.factor).
static func _sailing_time(
    from: Vector2, route: PackedVector2Array, wind_from: float, wind_intensity: int
) -> float:
    var time := 0.0
    var at := from
    for point in route:
        var heading := (point - at).angle() + PI / 2
        time += (
            at.distance_to(point) / maxf(SeaWind.factor(heading, wind_from, wind_intensity), 0.05)
        )
        at = point
    return time


## Start planning the flight of the corsair from the patrol at
## [param patrol] in the background (see [constant FLEE_PLAN_SECONDS]).
func _start_flight(ship: Dictionary, patrol: Vector2) -> void:
    var flight := Flight.new()
    flight.km = ship["km"]
    flight.patrol = patrol
    flight.wind_from = _wind.from_degrees
    flight.wind_intensity = _wind.intensity
    flight.task = WorkerThreadPool.add_task(_plan_flight.bind(flight), false, "corsair flight")
    ship["flight"] = flight
    ship["planned_from"] = patrol
    ship["replan"] = FLEE_REPLAN_SECONDS


## Take the planned flight (waiting for it if it is not ready yet).
func _take_flight(ship: Dictionary) -> void:
    var flight: Flight = ship["flight"]
    WorkerThreadPool.wait_for_task_completion(flight.task)
    ship["flight"] = null
    ship["route"] = flight.route


## Forget the flight being planned, if any (the task is waited for).
func _drop_flight(ship: Dictionary) -> void:
    var flight: Flight = ship["flight"]
    if flight != null:
        WorkerThreadPool.wait_for_task_completion(flight.task)
        ship["flight"] = null


## The way of a corsair at [param km] which flees from the patrol at
## [param patrol]: to one of the points around the patrol,
## [constant FLEE_GOAL_KM] away from it and not too far around from straight
## away (see [constant FLEE_SPREAD_DEGREES]), the one reached the fastest
## with the wind (into the wind, a ship is slow, so the corsair rather flees
## across or before it), by sea around the islands and the capes, and out of
## the patrol's way (A*, see SeaRoute.find). Empty if there is no way by sea
## which never comes closer to the patrol (e.g., only around an island past
## the patrol); then the corsair flees straight away from the patrol, along
## the coasts.
##
## It runs in the background (see [method _start_flight]), so it only reads
## the land, which does not change, and the copies in [param flight].
func _plan_flight(flight: Flight) -> void:
    var km := flight.km
    var patrol := flight.patrol
    var distance := km.distance_to(patrol)
    var away := (km - patrol).angle()
    var goals: Array[Dictionary] = []
    for i in range(FLEE_DIRECTIONS):
        var around := TAU * i / FLEE_DIRECTIONS
        if absf(angle_difference(around, away)) > deg_to_rad(FLEE_SPREAD_DEGREES):
            continue
        var goal := patrol + Vector2.RIGHT.rotated(around) * FLEE_GOAL_KM
        if _chart.is_land(goal):
            continue
        # NOTE (mristin):
        # A guess, as the crow flies; the way closer to the patrol costs
        # more, as it does on the grid.
        var guess := _sailing_time(
            km, PackedVector2Array([goal]), flight.wind_from, flight.wind_intensity
        )
        var closest := Geometry2D.get_closest_point_to_segment(patrol, km, goal)
        if closest.distance_to(patrol) < distance - FLEE_CELL_KM:
            guess *= FLEE_AVOID_COST
        goals.append({"km": goal, "guess": guess})
    goals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["guess"] < b["guess"])

    var avoid: Array[Dictionary] = [
        {"km": patrol, "radius": distance - FLEE_CELL_KM, "cost": FLEE_AVOID_COST}
    ]
    var best := PackedVector2Array()
    var best_time := INF
    for goal in goals.slice(0, FLEE_ROUTES):
        if goal["guess"] >= best_time:
            break
        var route := SeaRoute.find(
            km, goal["km"], 2.0 * FLEE_CELL_KM, avoid, FLEE_CELL_KM, FLEE_MARGINS_KM, false
        )
        if route.size() < 2:
            continue
        route.remove_at(0)
        if not _keeps_away(route, patrol, distance - FLEE_CELL_KM):
            continue
        route = _straighten(km, route, patrol)
        var time := _sailing_time(km, route, flight.wind_from, flight.wind_intensity)
        if time < best_time:
            best_time = time
            best = route
    flight.route = best


## Whether all the points of the way are at least [param km] from the patrol.
func _keeps_away(route: PackedVector2Array, patrol: Vector2, km: float) -> bool:
    for point in route:
        if point.distance_to(patrol) < km:
            return false
    return true


## The way on the grid, straightened: it zig-zags in steps of 45 degrees,
## so the corsair skips the points as long as the straight way to a later one
## stays at sea and does not come closer to the patrol at [param patrol] (the
## farthest point first, so that in the open sea one check is enough).
func _straighten(km: Vector2, route: PackedVector2Array, patrol: Vector2) -> PackedVector2Array:
    var result := PackedVector2Array()
    var at := km
    var i := 0
    while i < route.size():
        var reach := route.size() - 1
        while reach > i and not _is_flight_leg(at, route[reach], patrol):
            reach -= 1
        result.append(route[reach])
        at = route[reach]
        i = reach + 1
    return result


## Whether the corsair can flee straight from a to b: at sea, and never
## closer to the patrol on the way than at a.
func _is_flight_leg(a: Vector2, b: Vector2, patrol: Vector2) -> bool:
    var closest := Geometry2D.get_closest_point_to_segment(patrol, a, b)
    return closest.distance_to(patrol) >= a.distance_to(patrol) - 0.5 and _chart.is_clear_line(a, b)


## The ship gives up what it does and roams away from [param away] (a
## direction) for [param seconds], in a heading a bit to one side, so that the
## ships don't all leave the same way; then it may chase again, for a new
## while.
func _roam_away(ship: Dictionary, away: Vector2, seconds: float) -> void:
    ship["leaving"] = seconds
    ship["roam"] = away.angle() + PI / 2 + _rng.randf_range(-0.6, 0.6)
    ship["chase"] = 0.0
    ship["chase_limit"] = _rng.randf_range(CHASE_SECONDS.x, CHASE_SECONDS.y)
    ship["hunt"] = 0.0
    ship["hunt_limit"] = _rng.randf_range(HUNT_SECONDS.x, HUNT_SECONDS.y)
    ship["route"] = PackedVector2Array()


## The position of the nearest other ship of the kind closer than
## [param within_km] to the ship, in kilometres, or null.
func _nearest_of(ship: Dictionary, kind: String, within_km: float) -> Variant:
    var nearest: Variant = null
    var best := within_km
    for other in _ships:
        if is_same(other, ship) or other["kind"] != kind:
            continue
        var distance: float = other["km"].distance_to(ship["km"])
        if distance < best:
            best = distance
            nearest = other["km"]
    return nearest


## A ship of the kind caught the boat of the helm: the corsairs take
## [constant CORSAIR_LOOT] ducats, the patrol [constant BRIBE] as a bribe (or
## what there is on board).
func _caught(kind: String, helm: Helm) -> void:
    var hold := _run.hold(helm.player)
    if kind == "corsair":
        if _run.bag.use_effect("figs"):
            said.emit(tr("The corsairs take your figs and sail away happily."), helm.player)
        elif hold.on_board() >= MIN_LOOT:
            var stolen := hold.steal(CORSAIR_LOOT)
            said.emit(
                Grammar.format(
                    tr("The corsairs took {ducats} {ducats|ducat|ducats}!"), {"ducats": stolen}
                ),
                helm.player
            )
        else:
            _run.pass_days(1.0)
            said.emit(tr("The corsairs caught you! Their toll costs a day."), helm.player)
    elif _run.bag.has_effect("flag"):
        said.emit(tr("The Venetian patrol salutes your flag and lets you pass."), helm.player)
    elif hold.on_board() >= MIN_LOOT:
        var bribe := hold.steal(BRIBE)
        # NOTE (mristin):
        # The patrols are no friends of the haiduks: they want a bribe.
        var text := tr("A Venetian patrol! They take a bribe of {ducats} {ducats|ducat|ducats}.")
        said.emit(Grammar.format(text, {"ducats": bribe}), helm.player)
    else:
        _run.pass_days(0.5)
        said.emit(tr("A Venetian patrol! The inspection costs half a day."), helm.player)


# endregion

# region Barrels and chests


func _update_loot(delta: float, helms: Array[Helm], center: Vector2, targets: Array[Port]) -> void:
    for loot in _loot.duplicate():
        # NOTE (mristin):
        # Like the boats, the barrels keep their size on the screen while the
        # cameras zoom in.
        loot.scale = Vector2.ONE * _chart.marker_scale
        for helm in helms:
            if helm.km.distance_to(loot.km) < PICK_KM:
                _run.hold(helm.player).ducats += loot.ducats
                sounded.emit("coins")
                said.emit(
                    Grammar.format(tr("+{ducats} {ducats|ducat|ducats}!"), {"ducats": loot.ducats}),
                    helm.player
                )
                _loot.erase(loot)
                loot.queue_free()
                break
        if is_instance_valid(loot) and loot.km.distance_to(center) > FORGET_KM:
            _loot.erase(loot)
            loot.queue_free()

    _loot_timer -= delta
    if _loot_timer > 0.0 or _loot.size() >= mini(_sea.barrels, 3):
        return
    _loot_timer = _rng.randf_range(12.0, 25.0)

    # NOTE (mristin):
    # The barrels float a little off the way to the target, so that a detour
    # pays.
    var point: Variant = null
    if not targets.is_empty():
        var target := World.port_km(targets[0])
        var along := center.lerp(target, _rng.randf_range(0.25, 0.75))
        var side := (target - center).normalized().orthogonal() * _rng.randf_range(-20.0, 20.0)
        if not _chart.is_land(along + side) and (along + side).distance_to(center) > 15.0:
            point = along + side
    if point == null:
        point = _sea_point(center, Vector2(20.0, 45.0))
    if point == null:
        return
    var loot := FloatingLoot.new()
    loot.km = point
    loot.chest = _rng.randf() < 0.25
    loot.ducats = _rng.randi_range(12, 15) if loot.chest else _rng.randi_range(5, 10)
    loot.z_index = 3
    loot.scale = Vector2.ONE * _chart.marker_scale
    add_child(loot)
    _loot.append(loot)

# endregion
