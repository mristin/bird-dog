extends SceneTree
## Check the names of the ports on the large chart (see FullChart and
## Minimap.label_boxes), in English and in the drafts of every translation:
## every name stands inside the frame of the chart, and no two names overlap.
## The chart is checked as it is without a mission, and with every port as the
## target of the mission in turn (its name is larger), together with an errand.

const Samples := preload("res://tests/godot/samples.gd")

var _failures: Array[String] = []
var _language := ""


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append("%s: %s" % [_language, message])


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var chart := FullChart.new()
    root.add_child(chart)
    await process_frame
    var minimap: Minimap = chart.chart
    var ports := World.ports()

    for code in Samples.codes():
        _language = code
        var translation := Samples.load_drafts(code, "chart_labels")
        TranslationServer.set_locale(code)
        minimap.targets = []
        minimap.errand_ports = []
        _check_labels(minimap, "without a mission")
        for i in range(ports.size()):
            minimap.targets = [ports[i]]
            minimap.errand_ports = [ports[(i + 7) % ports.size()]]
            _check_labels(minimap, "with the target %s" % ports[i].id)
        if translation != null:
            TranslationServer.remove_translation(translation)

    for failure in _failures:
        print("FAIL ", failure)
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


func _check_labels(minimap: Minimap, where: String) -> void:
    var frame := minimap.frame()
    var labels := minimap.label_boxes()
    for i in range(labels.size()):
        var box: Rect2 = labels[i]["box"]
        _check(
            frame.encloses(box),
            "%s: the name '%s' stands outside the chart" % [where, labels[i]["text"]]
        )
        for j in range(i + 1, labels.size()):
            _check(
                not box.intersects(labels[j]["box"]),
                (
                    "%s: the names '%s' and '%s' overlap"
                    % [where, labels[i]["text"], labels[j]["text"]]
                )
            )
