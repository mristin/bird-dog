class_name Tow
extends RefCounted

## Fishermen tow a boat of the crew to the nearest port (see DESIGN.md,
## "Provisions"): their TowBoat pulls it slowly along a way over the sea (see
## SeaRoute), while the crew watches. Both boats keep to the way, the fishing
## boat ahead and the towed boat behind it, and the rope follows the way
## between them, so that none of them ever crosses the land. The fishermen
## know the sea: they keep clear of the reefs and the storms, and take another
## way when a storm drifts across theirs (see [method reroute]). When the
## fishing boat reaches the port, the tow ends, and the crew enters the port.

## How far the fishing boat sails ahead of the towed boat, and where the rope
## ends at the bow of the towed boat, in pixels of the boats (at their scale).
const GAP_PX := 190.0
const BOW_PX := 84.0

## The fishermen keep this far clear of the reefs and the clouds, in
## kilometres, and a cell of the sea there costs them this many times more
## (see SeaRoute.find); they look out for the drifting clouds this often, in
## seconds.
const REEF_KM := 1.5
const CLOUD_KM := 3.0
const REEF_COST := 40.0
const STORM_COST := 30.0
const CLOUD_COST := 12.0
const LOOKOUT_SECONDS := 2.0

## The way, in kilometres.
var path := PackedVector2Array()

## How far along the way the towed boat is, in kilometres.
var travelled := 0.0

## The port at the end of the way, and what the crew hears there (a line).
var port: Port
var reason := {}

var boat: TowBoat

## How long until the fishermen look out for the storms again, in seconds.
var lookout := 0.0

## How far along the way its points lie, in kilometres.
var _along := PackedFloat32Array()

## How far ahead of the towed boat the fishing boat sails now, in kilometres
## (the boats keep their size on the screen, see SeaView.follow).
var _gap_km := 0.0


## What the fishermen keep clear of (see SeaRoute.find): the reefs, where
## the hulls break, and the clouds, the storms the most.
static func avoid(chart: ChartView, hazards: SeaHazards) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for rock in chart.reefs:
        result.append({"km": rock, "radius": ChartView.REEF_KM + REEF_KM, "cost": REEF_COST})
    for cloud in hazards.clouds():
        var cost := STORM_COST if cloud["storm"] else CLOUD_COST
        result.append({"km": cloud["km"], "radius": cloud["radius"] + CLOUD_KM, "cost": cost})
    return result


## The port closest to the point (as the crow flies).
static func nearest_port(at: Vector2) -> Port:
    var nearest: Port = null
    for candidate in World.ports():
        var distance := World.port_km(candidate).distance_to(at)
        if nearest == null or distance < World.port_km(nearest).distance_to(at):
            nearest = candidate
    return nearest


## Start the tow; the fishing boat appears in [param world].
func _init(
    the_path: PackedVector2Array, the_port: Port, the_reason: Dictionary, world: Node
) -> void:
    port = the_port
    reason = the_reason
    _follow(the_path)
    boat = TowBoat.new()
    boat.z_index = 5
    boat.heading = heading_at(0.0)
    world.add_child(boat)


func _follow(the_path: PackedVector2Array) -> void:
    path = the_path
    travelled = 0.0
    _along = PackedFloat32Array([0.0])
    var total := 0.0
    for i in range(1, path.size()):
        total += path[i - 1].distance_to(path[i])
        _along.append(total)


## Where the fishing boat is on the way, in kilometres.
func ahead() -> Vector2:
    return point_at(minf(travelled + _gap_km, length()))


## The rest of the way, from the fishing boat to the port.
func rest() -> PackedVector2Array:
    var result := PackedVector2Array([ahead()])
    for i in range(path.size()):
        if _along[i] > travelled + _gap_km:
            result.append(path[i])
    return result


## Take another way from the fishing boat on ([param tail], which starts at
## the fishing boat); the stretch between the two boats stays as it is, so
## that neither of them jumps.
func reroute(tail: PackedVector2Array) -> void:
    var way := PackedVector2Array([point_at(travelled)])
    for i in range(path.size()):
        if _along[i] > travelled and _along[i] < travelled + _gap_km:
            way.append(path[i])
    way.append_array(tail)
    _follow(way)


## The clouds drift with the wind: now and then, the fishermen look out, and
## take another way to within [param near_km] of the port if a cloud drifted
## across theirs and a clearer way exists.
func look_out(delta: float, chart: ChartView, hazards: SeaHazards, near_km: float) -> void:
    lookout -= delta
    if lookout > 0.0:
        return
    lookout = LOOKOUT_SECONDS
    var places := avoid(chart, hazards)
    var ahead_way := rest()
    var through := SeaRoute.km_through(ahead_way, places)
    if through <= 0.0:
        return
    var tail := SeaRoute.find(ahead_way[0], World.port_km(port), near_km, places)
    if tail.size() >= 2 and SeaRoute.km_through(tail, places) < through - 1.0:
        reroute(tail)


## The length of the way, in kilometres.
func length() -> float:
    return _along[-1]


## The point of the way at the distance along it, in kilometres.
func point_at(distance: float) -> Vector2:
    var at := clampf(distance, 0.0, length())
    for i in range(1, path.size()):
        if _along[i] >= at:
            var part := _along[i] - _along[i - 1]
            var share := (at - _along[i - 1]) / part if part > 0.0 else 1.0
            return path[i - 1].lerp(path[i], share)
    return path[-1]


## Where the way heads at the distance along it, as a heading (0 north,
## clockwise): along the next couple of kilometres, so that the boats do not
## twitch at every cell of the grid.
func heading_at(distance: float) -> float:
    var here := point_at(distance)
    var ahead := point_at(distance + 2.0)
    if ahead.distance_to(here) < 0.01:
        ahead = here + (here - point_at(distance - 2.0))
    return (ahead - here).angle() + PI / 2


## Pull the boat of the helm along the way at the speed (kilometres per
## second); return how far it went, in kilometres.
func pull(helm: Helm, delta: float, km_per_second: float) -> float:
    _gap_km = GAP_PX * helm.boat.scale.x / ChartView.PX_PER_KM
    var before := travelled
    travelled = minf(travelled + km_per_second * delta, maxf(0.0, length() - _gap_km))
    helm.km = point_at(travelled)
    var smoothing := 1.0 - exp(-delta * 3.0)
    helm.heading = lerp_angle(helm.heading, heading_at(travelled), smoothing)
    boat.heading = lerp_angle(boat.heading, heading_at(travelled + _gap_km), smoothing)
    var moved := travelled - before
    helm.speed = moved / maxf(delta, 0.0001)
    return moved


## Whether the fishing boat reached the port at the end of the way.
func is_done() -> bool:
    return travelled + _gap_km >= length() - 0.01


## The fishing boat sails ahead of the towed boat on the way; the rope runs
## from its stern along the way to the bow of the towed boat.
func place(helm: Helm) -> void:
    var towed := helm.boat
    _gap_km = GAP_PX * towed.scale.x / ChartView.PX_PER_KM
    var bow_km := BOW_PX * towed.scale.x / ChartView.PX_PER_KM
    var stern_km := TowBoat.STERN_PX * towed.scale.x / ChartView.PX_PER_KM
    var ahead := minf(travelled + _gap_km, length())
    boat.scale = towed.scale
    boat.position = point_at(ahead) * ChartView.PX_PER_KM
    boat.towed_at = towed.position

    var bow := towed.position + Vector2.UP.rotated(helm.heading) * BOW_PX * towed.scale.x
    var rope := PackedVector2Array([bow])
    var from := travelled + bow_km
    var to := ahead - stern_km
    for i in range(path.size()):
        if _along[i] > from and _along[i] < to:
            rope.append(path[i] * ChartView.PX_PER_KM)
    var stern := Vector2.DOWN.rotated(boat.heading) * TowBoat.STERN_PX * towed.scale.x
    rope.append(boat.position + stern)
    boat.rope = rope


## The fishermen let go of the rope and sail home.
func finish() -> void:
    boat.queue_free()
