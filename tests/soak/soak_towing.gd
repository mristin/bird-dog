extends SceneTree
## A soak test of the towing (see Tow and SeaRoute), too long to run on every
## commit: run it now and then, e.g., before a release, with
##
##     $GODOT --headless --path . -s tests/soak/soak_towing.gd -- --no-camera --no-music
##
## Fishermen tow a boat from many random points at sea, 25 to 70 km from a
## random port, to the port nearest to it, frame by frame, with the zoom of
## the cameras among the islands. The test checks that neither the towed boat
## nor the fishing boat ever goes onto the land, and that every tow ends with
## the fishing boat in the port.
##
## The options after `--`:
##
## * `--towings=N`: how many towings (40 by default),
## * `--seed=N`: the seed of the random points (by default a new one, which the
##   test prints, so that a failure can be repeated),
## * `--snapshots=DIR`: save pictures of the first four towings (the start,
##   the middle and the end) into the directory; this needs a window, so run
##   without `--headless`, e.g., with `--resolution 1920x1080 --windowed`.

## The tow pulls this fast, as in the game (see the mission screen).
const TOW_SHARE := 0.45

## The frames of the simulation, per second.
const FPS := 60.0

## A boat counts as on the land only this far inside the coast, in
## kilometres (the coastline has hairline spikes which nobody can see).
const INLAND_KM := 0.1

## The fishing boat must end the tow at most this far from the port, in
## kilometres (see the mission screen, ENTER_KM).
const IN_PORT_KM := 5.0

## A tow may take at most this long, in seconds of game time.
const MAX_SECONDS := 400.0

## How many towings get snapshots.
const SNAPSHOTS := 4

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _option(name: String, default: String) -> String:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--%s=" % name):
            return arg.get_slice("=", 1)
    return default


func _run() -> void:
    var count := int(_option("towings", "40"))
    var seed_value := int(_option("seed", str(randi())))
    var snapshots := _option("snapshots", "")
    print("Towing %d boats with the seed %d." % [count, seed_value])

    root.size = Vector2i(1920, 1080)
    var world := Node2D.new()
    root.add_child(world)
    var chart := ChartView.new()
    world.add_child(chart)
    var camera := Camera2D.new()
    world.add_child(camera)
    camera.make_current()
    if snapshots != "":
        DirAccess.make_dir_recursive_absolute(snapshots)

    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var ports := World.ports()
    var done := 0
    var frames := 0
    var attempts := 0
    while done < count and attempts < count * 10:
        attempts += 1
        var port: Port = ports[rng.randi_range(0, ports.size() - 1)]
        var start := (
            World.port_km(port)
            + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(25.0, 70.0)
        )
        # NOTE (mristin):
        # Outside the chart, nothing is land, but nothing is sea either.
        if chart.is_land(start) or not World.bounds_km().grow(-10.0).has_point(start):
            continue
        var nearest := Tow.nearest_port(start)
        var path := SeaRoute.find(start, World.port_km(nearest), IN_PORT_KM - 0.5)
        _check(path.size() >= 2, "a way from %s to %s" % [start, nearest.id])
        if path.size() < 2:
            continue
        var shots := snapshots if done < SNAPSHOTS else ""
        frames += await _tow(world, chart, camera, path, nearest, "%d" % done, shots)
        done += 1

    print("Towed %d boats in %d frames." % [done, frames])
    _check(done == count, "enough random points at sea (%d of %d)" % [done, count])
    world.free()
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## Tow a boat along the way, frame by frame; return the frames it took.
func _tow(
    world: Node2D,
    chart: ChartView,
    camera: Camera2D,
    path: PackedVector2Array,
    port: Port,
    label: String,
    snapshots: String
) -> int:
    var boat := SeaBoat.new()
    boat.z_index = 5
    world.add_child(boat)
    var helm := Helm.new(0, boat)
    helm.km = path[0]
    helm.towed = true
    var tow := Tow.new(path, port, {}, world)
    var expected := tow.length() / (Helm.BASE_KM_PER_SECOND * TOW_SHARE) * FPS
    var every := maxi(1, int(expected / 2.0))
    var frame := 0
    var on_land := 0
    while not tow.is_done() and frame < MAX_SECONDS * FPS:
        var zoom := chart.zoom_map.zoom(helm.km)
        boat.scale = Vector2.ONE * SeaView.BOAT_SCALE / zoom
        tow.pull(helm, 1.0 / FPS, Helm.BASE_KM_PER_SECOND * TOW_SHARE)
        boat.position = helm.km * ChartView.PX_PER_KM
        boat.heading = helm.heading
        tow.place(helm)
        var fisher := tow.boat.position / ChartView.PX_PER_KM
        if _inland(chart, helm.km) or _inland(chart, fisher):
            on_land += 1
            if on_land == 1:
                print("  tow %s: on the land at %s / %s" % [label, helm.km, fisher])
        if snapshots != "" and frame % every == 0:
            await _snapshot(
                camera, boat, tow, zoom, "%s/tow_%s_%d.png" % [snapshots, label, frame / every]
            )
        frame += 1

    var fisher_km := tow.boat.position / ChartView.PX_PER_KM
    var to_port := fisher_km.distance_to(World.port_km(port))
    _check(
        on_land == 0,
        "tow %s to %s stays at sea (%d frames on the land)" % [label, port.id, on_land]
    )
    _check(tow.is_done(), "tow %s to %s ends in time" % [label, port.id])
    _check(
        to_port <= IN_PORT_KM,
        "tow %s ends with the fishing boat in %s (%.1f km away)" % [label, port.id, to_port]
    )
    if snapshots != "":
        await _snapshot(
            camera,
            boat,
            tow,
            chart.zoom_map.zoom(helm.km),
            "%s/tow_%s_end.png" % [snapshots, label]
        )
    tow.finish()
    boat.queue_free()
    return frame


## Whether the point lies on the land, at least INLAND_KM from the coast in
## every direction.
func _inland(chart: ChartView, km: Vector2) -> bool:
    if not chart.is_land(km):
        return false
    for k in range(8):
        if not chart.is_land(km + Vector2.RIGHT.rotated(k * TAU / 8) * INLAND_KM):
            return false
    return true


func _snapshot(camera: Camera2D, boat: SeaBoat, tow: Tow, zoom: float, path: String) -> void:
    camera.zoom = Vector2.ONE * zoom
    camera.position = (boat.position + tow.boat.position) * 0.5
    await process_frame
    await process_frame
    root.get_texture().get_image().save_png(path)
