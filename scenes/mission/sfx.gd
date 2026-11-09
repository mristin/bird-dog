class_name Sfx
extends Node

## The sound effects of a mission, made by the code (so there are no sound
## files to find and license): a crash on the reefs and the cliffs, coins for
## the ducats, thunder in the storm clouds, the cannons which scare away the
## corsairs, and the church bell of the celebrations (the bell of Grebaštica
## rings again!).
##
## A sound is synthesized once, when it is first played, and kept. The sounds
## are quiet when the music is muted (M, see the Music autoload).

const RATE := 22050

## How many sounds can play at once.
const VOICES := 4

static var _cache := {}

var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
    for i in range(VOICES):
        var player := AudioStreamPlayer.new()
        player.volume_db = -6.0
        add_child(player)
        _players.append(player)


func play(sound: String) -> void:
    var music := get_node_or_null("/root/Music")
    if music != null and music.is_muted():
        return
    var stream := stream_of(sound)
    if stream == null:
        return
    for player in _players:
        if not player.playing:
            player.stream = stream
            player.play()
            return


## The sound, synthesized on the first call; null for an unknown one.
static func stream_of(sound: String) -> AudioStreamWAV:
    if not _cache.has(sound):
        var samples: PackedFloat32Array
        match sound:
            "crash":
                samples = _crash()
            "coins":
                samples = _coins()
            "thunder":
                samples = _thunder()
            "bell":
                samples = _bell()
            "cannon":
                samples = _cannon()
            _:
                return null
        _cache[sound] = _wav(samples)
    return _cache[sound]


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
    var peak := 0.001
    for sample in samples:
        peak = maxf(peak, absf(sample))
    var data := PackedByteArray()
    data.resize(samples.size() * 2)
    for i in range(samples.size()):
        data.encode_s16(i * 2, int(clampf(samples[i] / peak * 0.8, -1.0, 1.0) * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.data = data
    return stream


## A boat on the rocks: a burst of noise, darkened, over a low thump.
static func _crash() -> PackedFloat32Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = 1
    var samples := PackedFloat32Array()
    var low := 0.0
    for i in range(int(RATE * 0.6)):
        var t := float(i) / RATE
        low += (rng.randf_range(-1.0, 1.0) - low) * 0.25
        var thump := sin(TAU * 55.0 * t) * exp(-t * 10.0)
        samples.append(low * exp(-t * 7.0) + thump * 0.8)
    return samples


## Three bright pings of coins.
static func _coins() -> PackedFloat32Array:
    var samples := PackedFloat32Array()
    for i in range(int(RATE * 0.5)):
        var t := float(i) / RATE
        var sample := 0.0
        for k in range(3):
            var start := k * 0.07
            if t >= start:
                var age := t - start
                var pitch := 2600.0 + k * 350.0
                sample += (
                    (sin(TAU * pitch * age) + 0.5 * sin(TAU * pitch * 1.5 * age)) * exp(-age * 28.0)
                )
        samples.append(sample)
    return samples


## A long, low rumble: brown noise which swells and fades.
static func _thunder() -> PackedFloat32Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = 2
    var samples := PackedFloat32Array()
    var brown := 0.0
    var low := 0.0
    for i in range(int(RATE * 2.6)):
        var t := float(i) / RATE
        brown = (brown + rng.randf_range(-1.0, 1.0) * 0.1) * 0.995
        low += (brown - low) * 0.08
        var envelope := minf(1.0, t / 0.15) * exp(-t * 1.3)
        samples.append(low * envelope)
    return samples


## Two cannon shots: a sharp crack of noise over a deep boom, which rolls away.
static func _cannon() -> PackedFloat32Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = 3
    var samples := PackedFloat32Array()
    var low := 0.0
    for i in range(int(RATE * 1.6)):
        var t := float(i) / RATE
        var sample := 0.0
        for start in [0.0, 0.35]:
            if t >= start:
                var age: float = t - start
                low += (rng.randf_range(-1.0, 1.0) - low) * 0.05
                var crack := rng.randf_range(-1.0, 1.0) * exp(-age * 40.0)
                var boom := sin(TAU * (48.0 - age * 20.0) * age) * exp(-age * 4.0)
                sample += crack * 0.6 + boom + low * exp(-age * 3.0) * 1.5
        samples.append(sample)
    return samples


## A church bell: the inharmonic partials of a bell, each fading at its pace.
static func _bell() -> PackedFloat32Array:
    var partials := [
        [0.5, 0.6, 1.2],
        [1.0, 1.0, 2.0],
        [1.19, 0.5, 2.5],
        [1.5, 0.4, 3.0],
        [2.0, 0.3, 4.0],
        [2.5, 0.2, 5.0],
        [3.0, 0.15, 6.0]
    ]
    var samples := PackedFloat32Array()
    for i in range(int(RATE * 3.5)):
        var t := float(i) / RATE
        var sample := 0.0
        for partial in partials:
            sample += sin(TAU * 330.0 * partial[0] * t) * partial[1] * exp(-t * partial[2] * 0.5)
        samples.append(sample * minf(1.0, t / 0.005))
    return samples
