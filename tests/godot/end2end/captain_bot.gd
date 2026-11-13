extends RefCounted
## Sail one boat of a mission as a player does without a camera, for the
## end-to-end tests (see playthrough.gd): only with the keys of the player
## (A and D for the first boat, Left and Right for the second; see
## Helm.read_steer), along the way which the navigator finds (see
## navigator.gd) to the nearest port the chart points to (or to the port of
## an errand, now and then), and around the buoys of a race. The second boat
## sails along with the first, and both stop for food and water on the way.
##
## In a race against the wind, the boat tacks: it beats at [constant
## BEAT_DEGREES] off the wind, now on one side, now on the other, as long as
## the way allows. Otherwise it sails straight into the wind, slowly: the
## clock of the mission counts the kilometres sailed, not the time, so that
## tacking would only cost days.
## A boat which does not get on finds a new way, and at last turns hard for a
## while, as a child would.
##
## Not a test itself (its name does not start with test_), it is preloaded by
## the tests.

const Keys := preload("res://tests/godot/end2end/keys.gd")
const Navigator := preload("res://tests/godot/end2end/navigator.gd")

## The keys of the players: left and right.
const KEYS: Array = [[KEY_A, KEY_D], [KEY_LEFT, KEY_RIGHT]]

## The way ends this close to a port, in kilometres: the boat enters it at
## five (see the mission screen, ENTER_KM).
const ENTER_KM := 4.0

## The way by sea is about this much longer than the straight line, and the
## boat keeps this much food in reserve, in kilometres of sailing (see
## [method _stop_for_food]).
const DETOUR := 1.35
const RESERVE_KM := 40.0

## Closer to the wind than this, the boat beats instead, in degrees.
const NO_GO_DEGREES := 40.0
const BEAT_DEGREES := 52.0

## The helm does not turn for a heading off by less than this, in degrees.
const DEAD_DEGREES := 6.0

## A boat which moved less than this in [constant STUCK_SECONDS] of sailing
## gets a new way, in kilometres; twice in a row, it turns hard for a while.
const STUCK_KM := 1.5
const STUCK_SECONDS := 6.0

## The player whose boat the bot sails (0 or 1).
var player := 0

## The mission screen.
var mission: Node

## The bot of the other boat to sail along with (the second boat follows the
## first: together, both sail faster and the corsairs keep away), or null.
var leader: RefCounted = null

## Whether the bot sails to the ports of the errands it carries, too.
var errands := true

## The problems the bot ran into (e.g., no way to a port).
var failures: Array[String] = []

## How many ways the bot found, and how many times it got stuck.
var plans := 0
var stuck := 0
var plan_ms := 0

var _nav: Navigator
var _probe: Navigator
var _chosen := {}
var _way_len := 0.0
var _tack := 1.0
var _tack_seconds := 0.0
var _watch_seconds := 0.0
var _watch_from := Vector2.INF
var _hard_seconds := 0.0
var _stuck_in_row := 0
var _replan_seconds := 0.0
var _rng: RandomNumberGenerator


func _init(the_mission: Node, the_player: int, rng: RandomNumberGenerator) -> void:
    mission = the_mission
    player = the_player
    _rng = rng
    _nav = Navigator.new(mission._chart)
    _probe = Navigator.new(mission._chart)
    _tack = 1.0 if _rng.randf() < 0.5 else -1.0


func _helm() -> Helm:
    return mission._helms[player]


## Where the boat should go now: {"km", "near", "port"}, where it should
## come within "near" kilometres of "km" (a port, or a buoy of a race); {} if
## nowhere. The boat keeps its choice while it stays one of the candidates
## (see [method _candidates]), and chooses the closest by sea otherwise; it
## stops for food and water on the way if it must (see [method
## _stop_for_food]).
func destination() -> Dictionary:
    var at := _helm().km
    if (
        leader != null
        and not mission._busy[leader.player]
        and not mission._helms[leader.player].towed
    ):
        var led: Dictionary = leader.destination()
        if not led.is_empty():
            if not led.get("racing", false):
                var food_stop := _stop_for_food(at, led["km"])
                if food_stop != null:
                    return {"km": World.port_km(food_stop), "near": ENTER_KM, "port": food_stop}
            return led
    var candidates := _candidates()
    if candidates.is_empty():
        _chosen = {}
        return {}
    var kept := false
    for candidate in candidates:
        if not _chosen.is_empty() and candidate["km"].distance_to(_chosen["km"]) < 0.01:
            kept = true
    if not kept or _chosen.get("food", false):
        _chosen = {}
        var best_km := INF
        for candidate in candidates:
            var km := _way_km(at, candidate)
            # NOTE (mristin):
            # An errand is worth only a short detour.
            if candidate.get("errand", false):
                km *= 2.0
            if km < best_km:
                best_km = km
                _chosen = candidate
        if _chosen.is_empty():
            _chosen = candidates[0]
    var racing: bool = _chosen.get("racing", false)
    if not racing:
        var stop := _stop_for_food(at, _chosen["km"])
        if stop != null:
            return {"km": World.port_km(stop), "near": ENTER_KM, "port": stop, "food": true}
    return _chosen


## Where the boat could go: the ports (or the buoy of a race) which the chart
## points to, and the ports of the errands which the boat carries cargo for.
func _candidates() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var run: MissionRun = mission._run
    var step := run.step()
    if step == null:
        return result
    var race := step as RaceStep
    var racing := race != null and race.is_racing(run)
    for port in step.target_ports(run):
        # NOTE (mristin):
        # A buoy of a race is rounded within its radius; a port is entered.
        var buoy := racing and not World.ports().has(port)
        (
            result
            . append(
                {
                    "km": World.port_km(port),
                    "near": RaceStep.ROUND_KM - 1.0 if buoy else ENTER_KM,
                    "port": port,
                    "racing": racing,
                }
            )
        )
    if errands and not racing:
        var cargo := run.hold(player).cargo
        for errand in run.errands:
            var port: Port = World.port(str(errand.get("port", "")))
            if port != null and cargo.has(errand.get("item", "")):
                result.append(
                    {"km": World.port_km(port), "near": ENTER_KM, "port": port, "errand": true}
                )
    return result


## How long the way by sea from [param at] to the candidate is, in
## kilometres; INF if there is none.
func _way_km(at: Vector2, candidate: Dictionary) -> float:
    if not _probe.plan(at, candidate["km"], candidate["near"]):
        return INF
    var km := 0.0
    for i in range(_probe.path.size() - 1):
        km += _probe.path[i].distance_to(_probe.path[i + 1])
    return km


## The port to stop at for food and water on the way to [param target], or
## null if the food lasts there: the port which makes the way the shortest,
## among those which the food reaches, and closer to the target than the boat.
func _stop_for_food(at: Vector2, target: Vector2) -> Port:
    var run: MissionRun = mission._run
    var food_km: float = run.hold(player).provisions * mission.KM_PER_DAY
    if food_km > at.distance_to(target) * DETOUR + RESERVE_KM:
        return null
    var best: Port = null
    var best_km := INF
    for port in World.ports():
        var km := World.port_km(port)
        if port == mission._left[player] or at.distance_to(km) * DETOUR > food_km:
            continue
        if km.distance_to(target) > at.distance_to(target) - ENTER_KM:
            continue
        var way := at.distance_to(km) + km.distance_to(target)
        if way < best_km:
            best_km = way
            best = port
    if best == null and food_km < at.distance_to(target) * DETOUR:
        # NOTE (mristin):
        # No port on the way: back to the nearest one, rather than be towed.
        for port in World.ports():
            var km := World.port_km(port)
            if port != mission._left[player] and at.distance_to(km) < best_km:
                best_km = at.distance_to(km)
                best = port
    return best


## Steer for a frame of [param delta] seconds of the game.
func tick(delta: float) -> void:
    var helm := _helm()
    if mission._busy[player] or mission._all_paused or helm.towed:
        _steer(0.0)
        _watch_from = Vector2.INF
        _nav.forget()
        return
    var where := destination()
    if where.is_empty():
        _steer(0.0)
        return
    var at := helm.km
    _replan_seconds -= delta
    if not _nav.follows(at, where["km"]) and _replan_seconds <= 0.0:
        plans += 1
        var started := Time.get_ticks_msec()
        var found := _nav.plan(at, where["km"], where["near"])
        _way_len = 0.0
        for k in range(_nav.path.size() - 1):
            _way_len += _nav.path[k].distance_to(_nav.path[k + 1])
        plan_ms += Time.get_ticks_msec() - started
        if not found:
            # NOTE (mristin):
            # Head straight for it meanwhile, and try again in a while.
            _replan_seconds = 3.0
            failures.append(
                (
                    "%s: no way by sea for the boat %d from %s to %s"
                    % [mission._mission.id, player + 1, at, where["port"].id]
                )
            )
    _check_stuck(at, delta)
    if _hard_seconds > 0.0:
        _hard_seconds -= delta
        _steer(_tack)
        return
    var aim := _nav.aim(at)
    var wanted := _heading_to(aim - at)
    wanted = _beat(wanted, delta, at, aim)
    var off := rad_to_deg(wrapf(wanted - helm.heading, -PI, PI))
    if absf(off) < DEAD_DEGREES:
        _steer(0.0)
    else:
        _steer(signf(off))


## Beat against the wind in a race: a heading too close to the wind becomes a tack at
## [constant BEAT_DEGREES] off it, on the side of the last tack while the
## water ahead is free and the tack still gains, else on the other side.
func _beat(wanted: float, delta: float, at: Vector2, aim: Vector2) -> float:
    var wind: SeaWind = mission._wind
    var helm := _helm()
    var race := (mission._run as MissionRun).step() as RaceStep
    if helm.oars or race == null or not race.is_racing(mission._run):
        return wanted
    var from := deg_to_rad(wind.from_degrees)
    var off := rad_to_deg(wrapf(wanted - from, -PI, PI))
    if absf(off) >= NO_GO_DEGREES:
        return wanted
    _tack_seconds += delta
    var tack := wrapf(from + deg_to_rad(BEAT_DEGREES) * _tack, -PI, PI)
    var ahead := at + Vector2.UP.rotated(tack) * 4.0
    var side := absf(rad_to_deg(wrapf(tack - _heading_to(aim - at), -PI, PI)))
    if _tack_seconds > 8.0 and (not Navigator.is_sea(ahead) or side > 80.0):
        _tack = -_tack
        _tack_seconds = 0.0
        tack = wrapf(from + deg_to_rad(BEAT_DEGREES) * _tack, -PI, PI)
    if not Navigator.clear(at, at + Vector2.UP.rotated(tack) * 3.0):
        return wanted
    return tack


func _check_stuck(at: Vector2, delta: float) -> void:
    if _watch_from == Vector2.INF:
        _watch_from = at
        _watch_seconds = 0.0
        return
    _watch_seconds += delta
    if _watch_seconds < STUCK_SECONDS:
        return
    if at.distance_to(_watch_from) < STUCK_KM:
        stuck += 1
        _stuck_in_row += 1
        _nav.forget()
        if _stuck_in_row >= 2:
            _hard_seconds = 3.0
            _tack = -_tack
    else:
        _stuck_in_row = 0
    _watch_from = at
    _watch_seconds = 0.0


## The heading (0 north, clockwise) of the direction.
static func _heading_to(direction: Vector2) -> float:
    return atan2(direction.x, -direction.y)


func _steer(value: float) -> void:
    var keys: Array = KEYS[player]
    Keys.hold(keys[0], value < 0.0)
    Keys.hold(keys[1], value > 0.0)


## Let go of the keys.
func stop() -> void:
    _steer(0.0)
