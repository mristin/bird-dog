extends SceneTree
## Look at the edge of the world, rendered (it needs a window, not
## --headless): the chart ends at its bounds, and beyond them the world is
## black (see ChartView). A boat sails to the edge, at many places along it
## and in the corners, with one captain and with two; every pixel of the view
## which shows a point beyond the bounds must be black, except for the boat
## itself.
##
##     $GODOT --path . --script tests/render/test_edge_of_the_world.gd -- --no-camera --no-music
##
## Pass `-- --shots=<dir>` to save the pictures with problems.

const MISSION := preload("res://scenes/mission/mission.tscn")

## How far inside the bounds the boat stands, in kilometres.
const INSIDE_KM := [0.6, 3.0]

## A pixel counts as black when no channel is brighter than this.
const BLACK := 0.06

## The boat and its wake may stand over the black, this far around the
## boat, in pixels of the screen.
const BOAT_PX := 70.0

## A pixel within this many pixels of the edge may blend the two (smoothing).
const EDGE_PX := 2.0

var _failures: Array[String] = []
var _shots := ""


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shots="):
            _shots = arg.trim_prefix("--shots=")
            DirAccess.make_dir_recursive_absolute(_shots)
    _check(DisplayServer.get_name() != "headless", "the test renders in a window, not headless")
    for players in [1, 2]:
        await _look(players)
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## The places to look from: along every side of the bounds, at sea, and in
## the corners (or the closest sea to them).
func _places(chart: ChartView) -> Array[Vector2]:
    var bounds := World.bounds_km()
    var result: Array[Vector2] = []
    for inside in INSIDE_KM:
        var inner := bounds.grow(-inside)
        var steps := 24
        for i in range(steps + 1):
            var t := float(i) / steps
            for at in [
                Vector2(lerpf(inner.position.x, inner.end.x, t), inner.position.y),
                Vector2(lerpf(inner.position.x, inner.end.x, t), inner.end.y),
                Vector2(inner.position.x, lerpf(inner.position.y, inner.end.y, t)),
                Vector2(inner.end.x, lerpf(inner.position.y, inner.end.y, t)),
            ]:
                if not chart.is_land(at):
                    result.append(at)
    return result


func _look(players: int) -> void:
    var scene: Node = MISSION.instantiate()
    scene.mission_id = "bell_of_grebastica"
    scene.next_scene = ""
    scene.record_result = false
    scene.players = players
    root.add_child(scene)
    await process_frame
    scene._on_shared_action("done")
    for i in range(players):
        scene._on_action("leave", i)
    await process_frame
    # NOTE (mristin):
    # The world stands still meanwhile, and the HUD hides: only the chart is
    # looked at.
    scene.set_process(false)
    scene._hazards.visible = false
    for view in scene._views:
        view.show_hud(false)
    var places := _places(scene._chart)
    print("%d captain(s): %d places along the edge" % [players, places.size()])
    var bad_places := 0
    for at in places:
        for helm in scene._helms:
            helm.km = at + Vector2(helm.player * 0.3, 0.0)
            helm.heading = (World.bounds_km().get_center() - at).angle() + PI / 2
        scene._place_boats(true)
        # NOTE (mristin):
        # The boats jump from place to place: their wakes would trail
        # across the chart.
        for helm in scene._helms:
            helm.boat._wake.clear()
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        for view in scene._views:
            var problem := _problem(view, scene._helms[view.player])
            if problem != "":
                bad_places += 1
                _check(
                    false,
                    "%d captain(s), the view %d at %s: %s" % [players, view.player + 1, at, problem]
                )
                if _shots != "" and bad_places <= 12:
                    view.viewport.get_texture().get_image().save_png(
                        "%s/edge_%d_%d_%d.png" % [_shots, players, view.player + 1, bad_places]
                    )
    scene.free()
    await process_frame


## What is wrong in the view: a pixel beyond the bounds which is not black;
## "" if none.
func _problem(view: SeaView, helm: Helm) -> String:
    var image := view.viewport.get_texture().get_image()
    var to_world := view.viewport.get_canvas_transform().affine_inverse()
    var to_screen := view.viewport.get_canvas_transform()
    var bounds := World.bounds_km()
    var bounds_px := Rect2(bounds.position * ChartView.PX_PER_KM, bounds.size * ChartView.PX_PER_KM)
    var boat: Vector2 = to_screen * helm.boat.position
    var wrong := 0
    var example := ""
    var scale := float(image.get_width()) / view.viewport.size.x
    for y in range(0, view.viewport.size.y, 6):
        for x in range(0, view.viewport.size.x, 6):
            var pixel := Vector2(x, y)
            var world: Vector2 = to_world * pixel
            # NOTE (mristin):
            # The distance outside the bounds, in pixels of the screen.
            var outside := (
                maxf(
                    maxf(bounds_px.position.x - world.x, world.x - bounds_px.end.x),
                    maxf(bounds_px.position.y - world.y, world.y - bounds_px.end.y)
                )
                * view.zoom
            )
            if outside <= EDGE_PX or pixel.distance_to(boat) < BOAT_PX:
                continue
            var color := image.get_pixel(int(x * scale), int(y * scale))
            if color.r > BLACK or color.g > BLACK or color.b > BLACK:
                wrong += 1
                if example == "":
                    example = "%s at %s (%.0f px beyond the edge)" % [color, pixel, outside]
    if wrong == 0:
        return ""
    return "%d pixels beyond the edge are not black, e.g., %s" % [wrong, example]
