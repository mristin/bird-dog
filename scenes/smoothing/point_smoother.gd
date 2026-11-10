class_name PointSmoother
extends RefCounted

## Smooth points on the screen which follow the body (the hands, the head), so
## that they neither jitter nor lag.
##
## The detections jitter by a few pixels even when the player holds still, and
## they come only 15 to 30 times per second. We therefore smooth strongly while
## a point moves slowly (it stands calm), and follow quickly while it moves fast
## (it does not lag behind a real move).
##
## Points are matched by a key (e.g., the id of a tracked hand) with
## [method update_keyed], or, if they have no ids, to the nearest point of the
## previous frame with [method update].

## The time constant of the smoothing at rest, in seconds.
var calm_seconds := 0.25

## The time constant of the smoothing at fast moves, in seconds.
var fast_seconds := 0.05

## At this speed (in pixels per second) and above, we follow fast.
var fast_speed := 1800.0

## A point farther than this from all the previous points (in pixels) is new.
var match_distance := 250.0

## Within this distance of the smoothed point (in pixels), a target barely
## moves it: the jitter of a hand which holds still stays out (0 for none).
var dead_zone := 0.0

var _points: Array[Vector2] = []
var _keyed := {}


## Smooth the points of this frame (without ids) and return them in the same order.
func update(targets: Array[Vector2], delta: float) -> Array[Vector2]:
    var result: Array[Vector2] = []
    var used := {}
    for target in targets:
        var best := -1
        var best_distance := match_distance
        for i in range(_points.size()):
            var distance := _points[i].distance_to(target)
            if not used.has(i) and distance < best_distance:
                best = i
                best_distance = distance
        if best < 0:
            result.append(target)
        else:
            used[best] = true
            result.append(_step(_points[best], target, delta))
    _points = result
    return result


## Smooth the points of this frame given by their keys; forget the keys which
## are gone. Return the smoothed points by their keys.
func update_keyed(targets: Dictionary, delta: float) -> Dictionary:
    var result := {}
    for key in targets:
        var target: Vector2 = targets[key]
        if _keyed.has(key):
            result[key] = _step(_keyed[key], target, delta)
        else:
            result[key] = target
    _keyed = result
    return result


func _step(previous: Vector2, target: Vector2, delta: float) -> Vector2:
    if dead_zone > 0.0:
        # NOTE (mristin):
        # Only the part of the move beyond the dead zone counts, so the point
        # stands still against the jitter, yet follows a real move smoothly.
        var offset := target - previous
        var beyond := maxf(0.0, offset.length() - dead_zone)
        target = previous + offset.limit_length(beyond)
    var speed := previous.distance_to(target) / maxf(delta, 1e-3)
    var fast := clampf(speed / fast_speed, 0.0, 1.0)
    var seconds := lerpf(calm_seconds, fast_seconds, fast)
    return previous.lerp(target, 1.0 - exp(-delta / maxf(seconds, 1e-3)))
