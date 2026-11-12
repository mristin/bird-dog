class_name SeaWind
extends RefCounted

## The wind at sea: which wind blows, from where and how strongly, and when it
## changes, following the SeaConditions of the mission (see DESIGN.md, "The
## view at sea"). A change is announced [constant WARNING_SECONDS] ahead.

const WARNING_SECONDS := 5.0

## No boat sails closer to the wind than this, in degrees on either side.
const NO_GO_DEGREES := 35.0

## A weather-wise fisherman on board announces the change this early.
const FISHERMAN_SECONDS := 20.0

## 0 light, 1 fresh, 2 strong.
## How early a change of the wind is announced, in seconds.
var warning_seconds := WARNING_SECONDS

var intensity := 1

## The name of the wind, e.g., "maestral".
var name := "maestral"

## Where the wind blows from, in degrees: 0 is north, 90 east.
var from_degrees := 315.0

## The wind which comes next, and in how many seconds.
var next: WindChance = null
var next_intensity := 1
var seconds_to_change := 60.0

var _sea: SeaConditions
var _rng := RandomNumberGenerator.new()


func _init(sea: SeaConditions, seed_value: int) -> void:
    _sea = sea
    _rng.seed = seed_value
    var first := _pick()
    name = first.name
    from_degrees = first.from_degrees
    intensity = _pick_intensity(first)
    _plan_next()


func _pick() -> WindChance:
    var total := 0.0
    for wind in _sea.winds:
        total += wind.weight
    var roll := _rng.randf() * total
    for wind in _sea.winds:
        roll -= wind.weight
        if roll <= 0.0:
            return wind
    return _sea.winds[0]


func _pick_intensity(wind: WindChance) -> int:
    var weights := [wind.intensities.x, wind.intensities.y, wind.intensities.z]
    var total: float = weights[0] + weights[1] + weights[2]
    var roll := _rng.randf() * maxf(total, 1e-3)
    for i in range(3):
        roll -= weights[i]
        if roll <= 0.0:
            return i
    return 1


func _plan_next() -> void:
    next = _pick()
    next_intensity = _pick_intensity(next)
    seconds_to_change = _rng.randf_range(_sea.change_seconds.x, _sea.change_seconds.y)


## Whether a change is announced.
func is_changing() -> bool:
    return seconds_to_change <= warning_seconds


func update(delta: float) -> void:
    seconds_to_change -= delta
    if seconds_to_change <= 0.0:
        name = next.name
        from_degrees = next.from_degrees
        intensity = next_intensity
        _plan_next()


## Where the wind blows to, as a unit vector on the screen (y points south).
func blows_to() -> Vector2:
    return Vector2.UP.rotated(deg_to_rad(from_degrees + 180.0))


## The speed of a boat for its heading (radians, 0 north, clockwise), relative
## to the best point of sail, as in DESIGN.md, "Steering and sailing".
func speed_factor(heading: float) -> float:
    return factor(heading, from_degrees, intensity)


## [method speed_factor] for a wind from [param wind_from] (degrees) of the
## [param wind_intensity]; static, so that it can be used on a copy of the
## wind in the background (see SeaHazards._plan_flight).
static func factor(heading: float, wind_from: float, wind_intensity: int) -> float:
    var off := absf(wrapf(rad_to_deg(heading) - wind_from, -180.0, 180.0))
    var by_point := 0.85
    if off < 35.0:
        by_point = 0.25
    elif off < 70.0:
        by_point = 0.5
    elif off < 110.0:
        by_point = 0.8
    elif off < 150.0:
        by_point = 1.0
    return by_point * [0.7, 1.0, 1.3][wind_intensity]


## Whether a boat with the heading sails right into the wind (its sail flaps).
func is_into_wind(heading: float) -> bool:
    return absf(wrapf(rad_to_deg(heading) - from_degrees, -180.0, 180.0)) < NO_GO_DEGREES
