extends SceneTree
## Check the waters of the patrols (see SeaConditions.patrol_powers): the
## Venetian patrols keep to the waters of Venice, and in chapter 3 the
## Habsburg patrols, with the eagle, to the waters of the Habsburgs; a sea
## without the Habsburgs among its powers has no patrols near Rijeka.

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
    var mission: Mission = MissionCatalog.all()[0]
    var off_rijeka := World.port_km(World.port("rijeka")) + Vector2(0, 8)
    var off_venice := World.port_km(World.port("venice")) + Vector2(8, 8)

    var venetian: SeaConditions = load("res://data/world/seas/bura_kvarner.tres")
    var hazards := _hazards(venetian, mission, chart)
    _check(hazards._patrol_power(off_venice) == "venice", "Venice patrols its waters")
    _check(
        hazards._patrol_power(off_rijeka) != "habsburgs", "no Habsburg patrols in chapters 1 and 2"
    )

    var both: SeaConditions = venetian.duplicate()
    both.patrol_powers = ["venice", "habsburgs"]
    hazards = _hazards(both, mission, chart)
    _check(hazards._patrol_power(off_venice) == "venice", "Venice still patrols its waters")
    _check(hazards._patrol_power(off_rijeka) == "habsburgs", "the Habsburgs patrol off Rijeka")
    var eagle := hazards._add_ship("patrol", off_rijeka)
    _check(eagle["boat"].emblem == "eagle", "a Habsburg patrol flies the eagle")
    _check(eagle["power"] == "habsburgs", "a Habsburg patrol belongs to the Habsburgs")
    var star := hazards._add_ship("patrol", off_venice)
    _check(star["boat"].emblem == "patrol", "a Venetian patrol flies the star")

    var chapter_three := 0
    for each in MissionCatalog.of_chapter(3):
        chapter_three += 1
        _check(
            each.sea.patrol_powers.has("habsburgs"),
            "%s: the Habsburgs patrol in chapter 3" % each.id
        )
    for chapter in [1, 2]:
        for each in MissionCatalog.of_chapter(chapter):
            _check(
                not each.sea.patrol_powers.has("habsburgs"),
                "%s: no Habsburg patrols before chapter 3" % each.id
            )
    print("chapter 3 missions: %d" % chapter_three)

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


func _hazards(sea: SeaConditions, mission: Mission, chart: ChartView) -> SeaHazards:
    var hazards := SeaHazards.new()
    var run := MissionRun.new(mission, 1)
    hazards.setup(sea, chart, SeaWind.new(sea, 1), run, 1)
    root.add_child(hazards)
    return hazards
