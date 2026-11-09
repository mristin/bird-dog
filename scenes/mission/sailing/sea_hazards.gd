class_name SeaHazards
extends Node2D

## What happens at sea besides the wind (see DESIGN.md, section 9): the storm
## clouds, the corsairs, the Venetian patrols, and the floating barrels and
## chests with ducats. The mission's SeaConditions decide which of them come
## and how many. None of them hurts anyone: the corsairs take all the ducats on
## board (a day, if there are none), the Venetian patrols take half of them as
## a bribe, since they are no friends of the haiduks (half a day, if there are
## none), and the clouds only slow the boats down. The corsairs fly a black
## flag with a skull, the patrols a sheriff's star (see SeaBoat.emblem).
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

## The patrols take this share of the ducats on board as a bribe.
const BRIBE_SHARE := 0.5

## With cannons on board, the corsairs turn and flee closer than this, in
## kilometres.
const CANNON_KM := 20.0

## Two boats closer than this keep the corsairs away, in kilometres.
const TOGETHER_KM := 8.0

## A ship closer than this to a boat catches it, in kilometres.
const CATCH_KM := 2.5

## With fewer ducats on board than this, the corsairs and the patrols take
## time instead.
const MIN_LOOT := 2

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

var _clouds: Array[StormCloud] = []
var _ships: Array[Dictionary] = []
var _loot: Array[FloatingLoot] = []

var _cloud_count := 0
var _cloud_timer := 5.0
var _corsair_timer := 20.0
var _patrol_timer := 30.0
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
    _ships.append(
        {"kind": kind, "km": point, "heading": _rng.randf() * TAU, "boat": boat, "leaving": 0.0}
    )


func _update_ships(delta: float, helms: Array[Helm], center: Vector2, together: bool) -> void:
    if _sea.corsairs:
        _corsair_timer -= delta
        if _corsair_timer <= 0.0:
            _corsair_timer = _rng.randf_range(12.0, 24.0)
            if _count("corsair") < _sea.corsair_count:
                _spawn_ship("corsair", center)
    if _sea.patrols:
        _patrol_timer -= delta
        if _patrol_timer <= 0.0:
            _patrol_timer = _rng.randf_range(16.0, 30.0)
            if _count("patrol") < _sea.patrol_count:
                _spawn_ship("patrol", center)

    for ship in _ships.duplicate():
        _steer_ship(ship, delta, helms, together)
        if ship["km"].distance_to(center) > FORGET_KM:
            _ships.erase(ship)
            ship["boat"].queue_free()


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

    # NOTE (mristin):
    # The corsairs don't dare to come close to two boats sailing together;
    # a ship which took its toll sails away for a while.
    var chasing: bool = ship["leaving"] <= 0.0 and to_boat.length() < CHASE_KM
    if ship["kind"] == "corsair" and together:
        chasing = false
    if (
        ship["kind"] == "corsair"
        and _run.bag.has_effect("cannons")
        and to_boat.length() < CANNON_KM
        and ship["leaving"] <= 0.0
    ):
        # NOTE (mristin):
        # Boom! The cannons scare the corsairs away for a good while.
        ship["leaving"] = 30.0
        chasing = false
        sounded.emit("cannon")
        said.emit(tr("Boom! Your cannons scare the corsairs away!"), nearest.player)
    var wanted: float = ship["heading"]
    if chasing:
        wanted = to_boat.angle() + PI / 2
    elif ship["leaving"] > 0.0 or (ship["kind"] == "corsair" and together):
        wanted = (-to_boat).angle() + PI / 2
    ship["heading"] = lerp_angle(ship["heading"], wanted, 1.0 - exp(-delta * 1.5))

    var share := 0.85 if ship["kind"] == "corsair" else 0.75
    var speed := (
        Helm.BASE_KM_PER_SECOND * _sea.speed_scale * _wind.speed_factor(ship["heading"]) * share
    )
    var next: Vector2 = ship["km"] + Vector2.UP.rotated(ship["heading"]) * speed * delta
    if not _chart.is_land(next):
        ship["km"] = next
    else:
        ship["heading"] += PI * 0.5
    var boat: SeaBoat = ship["boat"]
    boat.position = ship["km"] * ChartView.PX_PER_KM
    boat.heading = ship["heading"]
    boat.scale = Vector2.ONE * SHIP_SCALE * _chart.marker_scale
    boat.speed_share = 0.8
    var wind_to := wrapf(deg_to_rad(_wind.from_degrees) + PI - ship["heading"], -PI, PI)
    boat.sail_angle = clampf(wind_to * 0.5, -1.05, 1.05)
    boat.wind_to = wind_to

    if chasing and to_boat.length() < CATCH_KM:
        ship["leaving"] = 25.0
        _caught(ship["kind"], nearest)


## A ship of the kind caught the boat of the helm: the corsairs take all the
## ducats on board, the patrol half of them as a bribe.
func _caught(kind: String, helm: Helm) -> void:
    var hold := _run.hold(helm.player)
    if kind == "corsair":
        if _run.bag.use_effect("figs"):
            said.emit(tr("The corsairs take your figs and sail away happily."), helm.player)
        elif hold.on_board() >= MIN_LOOT:
            var stolen := hold.steal()
            said.emit(
                Grammar.format(
                    tr("The corsairs took all your ducats: {ducats}!"), {"ducats": stolen}
                ),
                helm.player
            )
        else:
            _run.pass_days(1.0)
            said.emit(tr("The corsairs caught you! Their toll costs a day."), helm.player)
    elif _run.bag.has_effect("flag"):
        said.emit(tr("The Venetian patrol salutes your flag and lets you pass."), helm.player)
    elif hold.on_board() >= MIN_LOOT:
        var bribe := hold.steal(BRIBE_SHARE)
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
    add_child(loot)
    _loot.append(loot)

# endregion
