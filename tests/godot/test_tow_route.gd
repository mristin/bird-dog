extends SceneTree
## Check that the fishermen who tow a boat to a port (see Tow and SeaRoute)
## keep clear of the reefs and the storms, and still get out of them when the
## boat broke right there.

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var chart := ChartView.new()
    root.add_child(chart)
    var reefs: Array[Dictionary] = []
    for rock in chart.reefs:
        reefs.append({"km": rock, "radius": ChartView.REEF_KM + Tow.REEF_KM, "cost": Tow.REEF_COST})
    _check(not reefs.is_empty(), "the chart has reefs")

    # NOTE (mristin):
    # Across the rocks of Palagruža, from the west to the east.
    var west := World.to_km(42.39, 15.95)
    var east := World.to_km(42.39, 16.6)
    var straight := SeaRoute.find(west, east, 2.0)
    var around := SeaRoute.find(west, east, 2.0, reefs)
    _check(SeaRoute.km_through(straight, reefs) > 0.0, "the shortest way runs over the reefs")
    _check(around.size() >= 2, "there is a way around the reefs")
    _check(
        is_zero_approx(SeaRoute.km_through(around, reefs)),
        (
            "the fishermen keep clear of the reefs (%.1f km over them)"
            % SeaRoute.km_through(around, reefs)
        )
    )

    var from := World.to_km(42.0, 16.9)
    var to := World.to_km(42.0, 17.7)
    var storm: Array[Dictionary] = [{"km": from.lerp(to, 0.5), "radius": 18.0, "cost": 30.0}]
    _check(
        SeaRoute.km_through(SeaRoute.find(from, to, 2.0), storm) > 0.0, "the storm is in the way"
    )
    var clear := SeaRoute.find(from, to, 2.0, storm)
    _check(
        clear.size() >= 2 and is_zero_approx(SeaRoute.km_through(clear, storm)),
        "the fishermen sail around the storm"
    )

    var wreck: Vector2 = reefs[0]["km"]
    var out := SeaRoute.find(wreck, World.port_km(Tow.nearest_port(wreck)), 4.5, reefs)
    _check(out.size() >= 2, "a boat broken on a reef is towed out of it")
    _check(
        SeaRoute.km_through(out, reefs) <= 2.0 * (ChartView.REEF_KM + Tow.REEF_KM) + 2.0,
        "and leaves the reefs by a short way"
    )

    # NOTE (mristin):
    # A storm drifts across the way: the fishermen take another way from
    # where their boat is, and neither boat jumps.
    var tow := Tow.new(SeaRoute.find(from, to, 2.0), World.ports()[0], {}, root)
    tow.travelled = 10.0
    var towed_at := tow.point_at(tow.travelled)
    var rest := tow.rest()
    tow.reroute(SeaRoute.find(rest[0], to, 2.0, storm))
    _check(tow.point_at(0.0).distance_to(towed_at) < 0.01, "the towed boat stays where it is")
    _check(tow.ahead().distance_to(rest[0]) < 0.5, "and so does the fishing boat")
    _check(tow.path[-1].distance_to(to) < 2.0, "the new way still leads to the port")
    tow.finish()

    # NOTE (mristin):
    # Near Pag, a thin tip of the land stands next to the way into the port:
    # from wherever the way starts (e.g., where the fishing boat takes another
    # way), its very first stretch must stay at sea, too.
    var pag := World.port_km(World.port("pag"))
    for dx in range(-12, 13):
        for dy in [-0.4, -0.2, 0.0, 0.2]:
            var start := Vector2(-77.31 + dx * 0.1, -164.184 + dy)
            if chart.is_land(start):
                continue
            var way := SeaRoute.find(start, pag, 4.5)
            for i in range(way.size() - 1):
                _check(
                    chart.is_clear_line(way[i], way[i + 1]),
                    "the way from %s to Pag stays at sea: %s to %s" % [start, way[i], way[i + 1]]
                )

    # NOTE (mristin):
    # Off Pag, a long pull (as in the end-to-end tests, which step the game
    # by 0.2 s) takes the towed boat around a corner of the way, next to a
    # tip of the land: it follows the way (see Tow.way), around the corner,
    # never the straight line across the tip.
    var off_pag := Vector2(-77.68453, -164.2041)
    var towing := Tow.new(SeaRoute.find(off_pag, pag, 4.5), World.port("pag"), {}, root)
    var helm := Helm.new(0, SeaBoat.new())
    # NOTE (mristin):
    # The boats keep their size on the screen (see SeaView.follow); zoomed in
    # tenfold, the fishing boat sails 1.7 km ahead.
    helm.boat.scale = Vector2.ONE * 0.1
    var corners := 0
    for k in range(40):
        var before := towing.travelled
        towing.pull(helm, 0.2, Helm.BASE_KM_PER_SECOND * 0.45)
        var stretch := towing.way(before, towing.travelled)
        corners += stretch.size() - 2
        _check(stretch[-1].distance_to(helm.km) < 0.01, "the towed boat is on the way")
        for i in range(stretch.size() - 1):
            _check(
                chart.is_clear_line(stretch[i], stretch[i + 1]),
                "the pull off Pag stays at sea: %s to %s" % [stretch[i], stretch[i + 1]]
            )
    _check(corners > 0, "the long pulls go around the corners of the way")
    helm.boat.free()
    towing.finish()

    chart.free()
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)
