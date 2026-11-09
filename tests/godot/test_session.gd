extends SceneTree
## Check the voyages: a new voyage is saved and listed with its captains and
## stars, the missions unlock one after the other, the best stars are kept,
## and a voyage loads again as it was saved.
##
## The test uses its own directory for the saves, never the players' saves.

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if condition:
        print("PASS ", message)
    else:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _make_session(directory: String) -> Node:
    var session: Node = load("res://scenes/session/session.gd").new()
    session.name = "TestSession"
    session.saves_dir = directory
    session.settings_path = directory + "/settings.cfg"
    root.add_child(session)
    return session


func _run() -> void:
    var directory := "user://test_saves_%d" % Time.get_ticks_usec()

    # NOTE (mristin):
    # The session uses the Crew autoload, which Godot loads for the test
    # scripts, too.
    var crew: Node = root.get_node("Crew")

    var session := _make_session(directory)
    await process_frame

    var missions := MissionCatalog.all()
    _check(missions.size() == 15, "there are fifteen missions")
    for i in range(missions.size()):
        _check(missions[i].number == i + 1, "the missions are in order (%d)" % (i + 1))
    _check(missions[-1].finale, "the last mission is the finale")

    crew.start(2)
    crew.captains[0]["name"] = "Ana"
    session.start("Test voyage")
    _check(session.voyage_name == "Test voyage", "the voyage keeps its name")

    var voyages: Array[Dictionary] = session.list()
    _check(voyages.size() == 1, "the new voyage is saved and listed")
    _check(Array(voyages[0]["captains"]) == ["Ana", "Mare"], "the list shows the captains")
    _check(session.last_id() == session.id, "the new voyage is the last one")

    _check(session.is_unlocked(missions[0]), "the first mission is unlocked")
    _check(not session.is_unlocked(missions[1]), "the second mission is locked")

    _check(session.ducats == 40, "a new voyage starts with 40 ducats in the chest")
    session.complete(missions[0].id, 2, 30)
    _check(session.ducats == 70, "the chest gets the ducats the mission earned, no more")
    _check(session.is_unlocked(missions[1]), "finishing a mission unlocks the next one")
    _check(not session.is_unlocked(missions[2]), "but not the one after it")
    session.complete(missions[0].id, 1)
    _check(session.stars(missions[0].id) == 2, "the best stars are kept")
    _check(session.ducats == 70, "the stars pay nothing")
    _check(session.yatak_gift(missions[1].id) == 10, "the yataks send 10 ducats at the start")
    _check(session.yatak_gift(missions[1].id) == 0, "but only once per mission")
    _check(session.ducats == 80, "the yataks' ducats go into the chest")
    _check(session.list()[0]["stars"] == 2, "the list counts the stars")

    var saved_id: String = session.id
    session.free()
    crew.start(1)
    var reloaded := _make_session(directory)
    await process_frame
    _check(reloaded.load_voyage(saved_id), "the voyage loads again")
    _check(reloaded.voyage_name == "Test voyage", "with its name")
    _check(crew.players == 2 and crew.captains[0]["name"] == "Ana", "with its crew")
    _check(reloaded.is_unlocked(missions[1]), "with its missions")
    _check(reloaded.ducats == 80, "with its chest")
    _check(not reloaded.has_shipyard(), "the shipyard opens only after mission 2")
    var sail: Decoration = World.decoration("sail_blue")
    _check(sail != null and sail.slot == "sail", "the shipyard has sails")
    _check(reloaded.buy_decoration(sail), "the crew buys a blue sail")
    _check(reloaded.ducats == 80 - sail.price, "the sail costs ducats of the chest")
    _check(not reloaded.buy_decoration(sail), "what is bought stays bought, and is not sold twice")
    crew.captains[0]["boat"] = {"sail": sail.id}
    reloaded.save()
    _check(reloaded.load_voyage(saved_id), "the voyage loads again with the decorations")
    _check(reloaded.owned.has(sail.id), "the crew still owns the sail")
    _check(
        World.boat_decorations(crew.captains[0]).get("sail") == sail,
        "and the captain's boat still wears it"
    )
    _check(not reloaded.load_voyage("missing"), "a missing voyage does not load")

    reloaded.delete_voyage(saved_id)
    _check(reloaded.list().is_empty(), "a deleted voyage is gone from the list")
    _check(reloaded.last_id() == "", "a deleted voyage is not the last one any more")
    _check(not reloaded.load_voyage(saved_id), "a deleted voyage does not load")

    var name_text: String = reloaded.default_name()
    _check(
        name_text.length() == 16 and name_text[4] == "-", "the default name is the date and time"
    )

    for file in DirAccess.get_files_at(directory):
        DirAccess.remove_absolute(directory + "/" + file)
    DirAccess.remove_absolute(directory)

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)
