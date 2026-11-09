extends SceneTree
## Check how far the cameras zoom in at sea (see ChartZoom): not at all on the
## open sea and along a straight coast, a lot among the islands of Zadar and
## Šibenik, and the most in the narrow Pašman channel. And a measure must be
## quick, since the mission measures every boat five times a second.

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
    var zoom_map := chart.zoom_map

    var places := {
        "the open sea": [43.0, 15.0],
        "the sea off Bari": [41.2, 16.95],
        "the sea off Ancona": [43.68, 13.6],
        "Zadar": [44.115, 15.225],
        "Šibenik": [43.70, 15.80],
        "the Pašman channel": [43.93, 15.43],
    }
    var zooms := {}
    for place in places:
        var km := World.to_km(places[place][0], places[place][1])
        _check(not chart.is_land(km), "%s lies at sea" % place)
        zooms[place] = zoom_map.zoom(km)
        print("%s: zoom %.2f, %s" % [place, zooms[place], zoom_map.measure(km)])

    _check(is_equal_approx(zooms["the open sea"], 1.0), "the open sea does not zoom in")
    _check(zooms["the sea off Bari"] < 1.2, "a straight coast hardly zooms in (Bari)")
    _check(zooms["the sea off Ancona"] < 1.2, "a straight coast hardly zooms in (Ancona)")
    _check(zooms["Zadar"] > 2.0, "the islands of Zadar zoom in")
    _check(zooms["Šibenik"] > 1.5, "the islands of Šibenik zoom in")
    _check(zooms["the Pašman channel"] > 3.5, "the Pašman channel zooms in the most")
    _check(zooms["the Pašman channel"] > zooms["Zadar"], "a narrow channel zooms in more")

    var started := Time.get_ticks_usec()
    var count := 50
    for i in range(count):
        zoom_map.zoom(World.to_km(43.93, 15.43) + Vector2(i * 0.1, 0))
    var per_measure_ms := (Time.get_ticks_usec() - started) / 1000.0 / count
    print("a measure in the Pašman channel takes %.2f ms" % per_measure_ms)
    _check(per_measure_ms < 8.0, "a measure is quick (%.2f ms)" % per_measure_ms)

    chart.free()
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)
