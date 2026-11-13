extends SceneTree
## Look at every decoration on every ship, rendered (it needs a window, not
## --headless): a decoration which the crew bought (in Master Ivan's shipyard
## or from a merchant, see Booster) must show on the boat, so the boat with it
## must not be pixel identical to the boat without it, at sea (where a boat
## keeps its size on the screen whatever the zoom, see SeaView), on the
## mission select and in the shipyard; and no two decorations of the same
## place may look the same.
##
##     $GODOT --path . --script tests/render/test_decorations_show.gd -- --no-camera --no-music
##
## Pass `-- --shots=<dir>` to save the boats which look like the plain one.

## The scales of the boat: at sea, on the mission select and in the shipyard.
const SCALES := {"at sea": SeaView.BOAT_SCALE, "on the missions": 0.75, "in the shipyard": 2.6}

## Pixels count as different if a channel differs by more than this, and a
## decoration shows if at least this many pixels differ.
const CHANNEL := 0.04
const PIXELS := 6

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
    var decorations := _decorations()
    print("%d decorations on %d ships" % [decorations.size(), World.ships().size()])
    for ship in World.ships():
        for where in SCALES:
            await _compare(ship, where, SCALES[where], decorations)
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## Every decoration which a crew can buy: in the shipyard, and from the
## merchants.
func _decorations() -> Array[Decoration]:
    var result: Array[Decoration] = []
    result.assign(World.decorations())
    for booster in World.boosters():
        if booster.decoration != null and not result.has(booster.decoration):
            result.append(booster.decoration)
    return result


## A boat in a viewport of its own, with the decoration (or none).
func _stage(ship: Ship, scale: float, decoration: Decoration) -> SubViewport:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(Vector2(220, 300) * maxf(1.0, scale))
    viewport.transparent_bg = false
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var sea := ColorRect.new()
    sea.color = ChartView.SEA
    sea.size = Vector2(viewport.size)
    viewport.add_child(sea)
    var boat := SeaBoat.new()
    boat.position = Vector2(viewport.size) * 0.5
    boat.scale = Vector2.ONE * scale
    boat.ship = ship
    boat.speed_share = 0.6
    boat.sail_angle = 0.4
    boat.initial = "L"
    if decoration != null:
        boat.decorations = {decoration.slot: decoration}
    viewport.add_child(boat)
    boat.set_process(false)
    return viewport


## Render the plain boat and the boat with every decoration in the same frame
## (the streamers wave and the lanterns glow with the time), and compare.
func _compare(ship: Ship, where: String, scale: float, decorations: Array[Decoration]) -> void:
    var plain := _stage(ship, scale, null)
    var twin := _stage(ship, scale, null)
    var empty := _stage(ship, scale, null)
    empty.get_child(1).visible = false
    var stages: Array[SubViewport] = []
    for decoration in decorations:
        stages.append(_stage(ship, scale, decoration))
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var plain_image := plain.get_texture().get_image()
    # NOTE (mristin):
    # The pictures are rendered (the boat shows on the sea), and two plain
    # boats are the same, so that a difference is the decoration's.
    var boat_pixels := _differ(plain_image, empty.get_texture().get_image())
    _check(boat_pixels > 200, "the %s shows %s (%d pixels)" % [ship.id, where, boat_pixels])
    var noise := _differ(plain_image, twin.get_texture().get_image())
    _check(
        noise < PIXELS, "two plain %s are the same %s (%d pixels differ)" % [ship.id, where, noise]
    )
    var images: Array[Image] = []
    for stage in stages:
        images.append(stage.get_texture().get_image())
    for i in range(decorations.size()):
        var decoration := decorations[i]
        var changed := _differ(plain_image, images[i])
        _check(
            changed >= PIXELS,
            (
                "the %s with %s (%s) %s looks like the plain one (%d pixels differ)"
                % [ship.id, decoration.id, decoration.slot, where, changed]
            )
        )
        if changed < PIXELS and _shots != "":
            images[i].save_png("%s/%s_%s_%s.png" % [_shots, ship.id, decoration.id, scale])
        for j in range(i + 1, decorations.size()):
            if decorations[j].slot != decoration.slot:
                continue
            var apart := _differ(images[i], images[j])
            _check(
                apart >= PIXELS,
                (
                    "the %s with %s looks like with %s %s (%d pixels differ)"
                    % [ship.id, decoration.id, decorations[j].id, where, apart]
                )
            )
    plain.free()
    twin.free()
    empty.free()
    for stage in stages:
        stage.free()


## How many pixels of the two pictures differ.
func _differ(a: Image, b: Image) -> int:
    var count := 0
    for y in range(a.get_height()):
        for x in range(a.get_width()):
            var p := a.get_pixel(x, y)
            var q := b.get_pixel(x, y)
            if absf(p.r - q.r) > CHANNEL or absf(p.g - q.g) > CHANNEL or absf(p.b - q.b) > CHANNEL:
                count += 1
    return count
