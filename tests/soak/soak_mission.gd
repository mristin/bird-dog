extends "res://scenes/mission/mission.gd"
## The mission screen with wandering steering instead of the bird dog, for the
## soak test (see soak_missions.gd): every boat turns now left, now right, as
## a slow wave with an occasional full turn; like a child, a boat which does
## not move (on the coast, or into the wind) turns hard for a while.

var _clock := 0.0
var _slow := [0.0, 0.0]
var _turning := [0.0, 0.0]


func _steer_of(player: int, _poses: Array) -> float:
    if _turning[player] > 0.0:
        return 1.0
    var wave := sin(_clock * 0.37 + player * 2.1) * 0.8
    if fmod(_clock + player * 13.0, 47.0) < 3.0:
        wave = 1.0
    return wave


func advance(delta: float) -> void:
    _clock += delta
    for helm in _helms:
        var player := helm.player
        _turning[player] = maxf(0.0, _turning[player] - delta)
        _slow[player] = _slow[player] + delta if helm.speed < 0.2 else 0.0
        if _slow[player] > 3.0:
            _slow[player] = 0.0
            _turning[player] = 3.0
    _process(delta)
