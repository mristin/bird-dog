class_name Helm
extends RefCounted

## One boat of the crew at sea, steered by one player: where it is, where it
## heads and how fast it sails. The mission screen moves it every frame and
## places its SeaBoat on the chart.

## The best speed of a boat, in kilometres per second, before the speed scale
## of the mission.
const BASE_KM_PER_SECOND := 6.75

## How fast a boat turns at full steering, in degrees per second.
const TURN_DEGREES := 50.625

## With oars, a boat sails into the wind at least this share of its best speed.
const OARS_SHARE := 0.6

## A skilled helmsman (see Booster) makes the boat turn this much quicker.
const HELMSMAN := 1.6

## The player who steers the boat (0 or 1).
var player := 0

## How quickly the boat turns and how fast it sails, as shares (the kind of
## ship and the boosters, see Ship), and whether its crew rows (oars).
var turn_factor := 1.0
var speed_factor := 1.0
var oars := false

## Whether fishermen tow the boat to a port (see TowBoat): it does not steer.
var towed := false

## Where the boat is, in kilometres on the chart.
var km := Vector2.ZERO

## Where the boat heads, in radians: 0 points north, clockwise.
var heading := 0.0

## The speed, in kilometres per second.
var speed := 0.0

## The steering of the player, from -1 (left) to 1 (right).
var steer := 0.0

## The boat on the chart.
var boat: SeaBoat

## Where the boat ran ashore in the last frame, or INF.
var hit_land := Vector2.INF

## No new damage before this many seconds have passed (one rock, one damage).
var bump_cooldown := 0.0

## The side to which the boat slid along the coast last (1 right, -1 left).
var _slide_side := 1.0


func _init(the_player: int, the_boat: SeaBoat) -> void:
    player = the_player
    boat = the_boat


## Fit the boat to its kind of ship (see Ship) and to the boosters of the
## crew: a skilled helmsman turns quicker, strong rowers row into the wind.
func fit(ship: Ship, bag: BoosterBag) -> void:
    turn_factor = ship.turn * (HELMSMAN if bag.has_effect("nimble") else 1.0)
    speed_factor = ship.speed
    oars = ship.oars or bag.has_effect("oars")


## Where the boat is, as plain data for the save; [param left] is the port it
## left last (null for none).
func to_data(left: Port) -> Dictionary:
    return {"x": km.x, "y": km.y, "heading": heading, "left": left.id if left != null else ""}


## Restore the boat from [method to_data]; return the port it left last.
func restore(data: Dictionary) -> Port:
    km = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
    heading = float(data.get("heading", 0.0))
    return World.port(str(data.get("left", "")))


## The steering of a player: from the keyboard if a key is held (for testing
## without a camera), otherwise from the bird dog.
static func read_steer(player: int, poses: Array) -> float:
    var keys: Array = [[KEY_A, KEY_D], [KEY_LEFT, KEY_RIGHT]][player]
    if Input.is_physical_key_pressed(keys[0]):
        return -1.0
    if Input.is_physical_key_pressed(keys[1]):
        return 1.0
    if player < poses.size():
        return float(poses[player]["steer"])
    return 0.0


## Turn and sail for a frame; return how far the boat sailed, in kilometres.
##
## [param boost] multiplies the speed (e.g., sailing together, or hungry);
## [param anchor] and [param leash]: the boat may not sail farther than the
## leash from the anchor (the other boat), so that the crew stays together.
func sail(
    delta: float,
    wind: SeaWind,
    chart: ChartView,
    speed_scale: float,
    boost: float,
    anchor: Variant = null,
    leash := INF
) -> float:
    heading = wrapf(heading + steer * deg_to_rad(TURN_DEGREES) * turn_factor * delta, -PI, PI)
    var by_wind := wind.speed_factor(heading)
    if oars:
        by_wind = maxf(by_wind, OARS_SHARE)
    var target := BASE_KM_PER_SECOND * speed_scale * by_wind * boost * speed_factor
    speed = lerpf(speed, target, 1.0 - exp(-delta / 3.0))

    var next := km + Vector2.UP.rotated(heading) * speed * delta
    if anchor != null:
        var from: Vector2 = anchor
        if next.distance_to(from) > leash and next.distance_to(from) > km.distance_to(from):
            # NOTE (mristin):
            # Too far from the other boat: the boat may only sail along the
            # leash, not away from it.
            next = from + (next - from).normalized() * maxf(leash, km.distance_to(from))
    hit_land = Vector2.INF
    if chart.is_land(next) or chart.crosses_land(km, next):
        next = _slide(next, chart, delta, target)
        if next == km:
            return 0.0
    var sailed := km.distance_to(next)
    km = next
    return sailed


## The boat runs onto the coast at [param blocked]: it slides along the coast
## instead of stopping, so that a novice sailor keeps most of the way (see
## DESIGN.md, "The coasts never hurt"). It takes the free direction closest to
## its heading, keeps the speed which goes along the coast, and its bow turns
## gently along the coast. Only running nearly head-on stops it, and then it
## keeps some way on, to sail off at once when it turns away from the coast.
func _slide(blocked: Vector2, chart: ChartView, delta: float, target: float) -> Vector2:
    var step := km.distance_to(blocked)
    for degrees in [15.0, 30.0, 45.0, 60.0, 75.0]:
        # NOTE (mristin):
        # Prefer the side to which the player steers, otherwise the side of
        # the last slide, so that a boat in a pocket of the coast keeps turning
        # one way until it is out, instead of zig-zagging in place.
        var first := signf(steer) if steer != 0.0 else _slide_side
        for side: float in [first, -first]:
            var angle := deg_to_rad(degrees) * side
            var along := Vector2.UP.rotated(heading + angle)
            var keep := cos(angle)
            var candidate := km + along * step * keep
            if chart.is_land(candidate) or chart.crosses_land(km, candidate):
                continue
            _slide_side = side
            speed *= lerpf(1.0, keep, minf(1.0, delta * 4.0))
            heading = wrapf(heading + angle * minf(1.0, delta * 1.5), -PI, PI)
            # NOTE (mristin):
            # A steep run onto the coast at speed counts as running ashore (only
            # the cliffs hurt, see ChartView.is_cliff).
            if degrees >= 60.0 and speed > BASE_KM_PER_SECOND * 0.3:
                hit_land = blocked
            return candidate
    # NOTE (mristin):
    # Head-on: the boat stays where it is, but keeps some way on, so that it
    # sails off at once when its bow turns to the open water (a boat in a
    # pocket of the coast would turn past the way out otherwise).
    if speed > BASE_KM_PER_SECOND * 0.3:
        hit_land = blocked
    speed = minf(speed, target * 0.4)
    return km


## Place the boat on the chart, with its sail set to the wind.
func place(wind: SeaWind) -> void:
    boat.position = km * ChartView.PX_PER_KM
    boat.heading = heading
    # NOTE (mristin):
    # The square sails stand across the boat when the wind blows from behind,
    # and swing round (at most about 60 degrees) as the wind comes from the side.
    var wind_to := wrapf(deg_to_rad(wind.from_degrees) + PI - heading, -PI, PI)
    boat.sail_angle = clampf(wind_to * 0.5, -1.05, 1.05)
    boat.luffing = wind.is_into_wind(heading) and not towed
    boat.wind_to = wind_to
    boat.speed_share = clampf(speed / BASE_KM_PER_SECOND, 0.0, 1.5)
    boat.lean = lerpf(boat.lean, steer, 0.1)
