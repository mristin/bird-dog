extends SceneTree
## Check that the voyages saved by older versions of the game are still
## playable (see tests/godot/voyages/README.md): the voyage played last with
## the game of chapter 1 only, as it was saved, and the same voyage saved in
## the middle of a mission.
##
## The test works on copies of the voyages in a directory of its own, never on
## the files in the repository nor on the players' saves.

const VOYAGES := "res://tests/godot/voyages"
const VOYAGE_ID := "20261110-175952"

## Sailing between two ports is longer than the straight line by this factor
## (as in test_missions.gd).
const DETOUR := 1.3

var _failures: Array[String] = []
var _session: Node
var _directory := ""


func _check(condition: bool, message: String) -> void:
    if condition:
        print("PASS ", message)
    else:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    _directory = "user://test_old_voyages_%d" % Time.get_ticks_usec()
    _session = root.get_node("Session")
    _session.saves_dir = _directory
    _session.settings_path = _directory + "/settings.cfg"

    await _check_latest_played()
    await _check_mission_in_progress()

    _session.delete_voyage(VOYAGE_ID)
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## Copy the voyage of the repository into the directory of the test and load
## it; return its data as saved.
func _load(file: String) -> Dictionary:
    var text := FileAccess.get_file_as_string("%s/%s" % [VOYAGES, file])
    var saved: Dictionary = JSON.parse_string(text)
    DirAccess.make_dir_recursive_absolute(_directory)
    var copy := FileAccess.open("%s/%s.json" % [_directory, VOYAGE_ID], FileAccess.WRITE)
    copy.store_string(text)
    copy.close()
    _check(_session.load_voyage(VOYAGE_ID), "%s: the voyage loads" % file)
    return saved


## The voyage loads as it was, opens where the crew left off, and can be
## played on through all three chapters.
func _check_latest_played() -> void:
    var file := "latest_played.json"
    var saved := _load(file)
    var crew: Node = root.get_node("Crew")
    _check(crew.players == 1 and crew.captains[0]["name"] == "Liso", "%s: with its crew" % file)
    _check(_session.ducats == int(saved["ducats"]), "%s: with its ducats" % file)
    _check(_session.owned.has("streamers"), "%s: with what the crew bought" % file)
    _check(_session.has_shipyard(), "%s: with Master Ivan's shipyard" % file)
    for mission_id in saved["missions"]:
        _check(
            MissionCatalog.by_id(mission_id) != null,
            "%s: the mission %s exists" % [file, mission_id]
        )
        _check(
            _session.stars(mission_id) == int(saved["missions"][mission_id]["stars"]),
            "%s: the stars of %s are kept" % [file, mission_id]
        )

    var missions := MissionCatalog.all()
    var next := missions[saved["missions"].size()]
    _check(next.number == 14, "%s: mission 14 comes next" % file)
    _check(_session.is_unlocked(next), "%s: mission 14 is open" % file)
    _check(not _session.is_unlocked(missions[14]), "%s: mission 15 is not open yet" % file)
    _check(not _session.is_unlocked(missions[15]), "%s: chapter 2 is not open yet" % file)
    await _check_select(1, file)

    # NOTE (mristin):
    # The crew plays on, mission by mission, into chapters 2 and 3.
    for mission in missions.slice(next.number - 1):
        _check(_session.is_unlocked(mission), "%s: %s is open in its turn" % [file, mission.id])
        var run := MissionRun.new(mission, 3)
        run.bring(_session.ducats)
        var stars := _play(run, file)
        _session.complete(mission.id, stars, run.ducats_total())
        if mission.number == 15:
            await _check_select(2, file)
        elif mission.number == 25:
            await _check_select(3, file)
    for mission in missions:
        _check(_session.is_completed(mission.id), "%s: %s is completed" % [file, mission.id])
    _check(_session.ducats > int(saved["ducats"]), "%s: the ducats grew on the way" % file)

    var reloaded := FileAccess.get_file_as_string("%s/%s.json" % [_directory, VOYAGE_ID])
    var data: Dictionary = JSON.parse_string(reloaded)
    _check(data["missions"].size() == 35, "%s: the voyage saves all thirty-five missions" % file)


## The mission select opens on the chapter of the newest open mission.
func _check_select(chapter: int, file: String) -> void:
    var select: Node = load("res://scenes/mission_select/mission_select.tscn").instantiate()
    select.next_scene = ""
    root.add_child(select)
    await process_frame
    _check(select._chapter == chapter, "%s: the missions open on chapter %d" % [file, chapter])
    var cards: int = select._grid.get_child_count()
    _check(
        cards == MissionCatalog.of_chapter(chapter).size(),
        "%s: chapter %d shows its %d missions" % [file, chapter, cards]
    )
    select.free()


## The mission saved in the middle by the old game goes on where it was, both
## headless and on the mission screen, and can be finished.
func _check_mission_in_progress() -> void:
    var file := "latest_played_mission_in_progress.json"
    var saved := _load(file)
    var progress: Dictionary = saved["mission_in_progress"]
    _check(_session.progress_of() == "the_witnesses", "%s: mission 14 is in progress" % file)
    _check(_session.progress_fits(1), "%s: for one boat" % file)

    var mission := MissionCatalog.by_id("the_witnesses")
    var run := MissionRun.new(mission, 1)
    _check(run.restore(_session.mission_in_progress["run"]), "%s: the mission goes on" % file)
    _check(run.step_index == int(progress["run"]["step"]), "%s: at the step where it was" % file)
    _check(
        run.cargo.has("witness_leke") and run.cargo.has("witness_mustafa"),
        "%s: with the witnesses on board" % file
    )
    _check(is_equal_approx(run.days, float(progress["run"]["days"])), "%s: with its days" % file)
    _check(_play(run, file) >= 1, "%s: and is finished" % file)

    # NOTE (mristin):
    # On the mission screen, as when the crew chooses "Continue the mission".
    _session.current_mission = mission.id
    _session.resume_mission = true
    var screen: Node = load("res://scenes/mission/mission.tscn").instantiate()
    screen.next_scene = ""
    screen.players = 1
    root.add_child(screen)
    for i in range(3):
        await process_frame
    var resumed: MissionRun = screen._run
    _check(resumed.step_index == int(progress["run"]["step"]), "%s: the screen continues it" % file)
    _check(resumed.cargo.has("witness_mustafa"), "%s: the screen has the witnesses" % file)
    _check(not _session.resume_mission, "%s: the screen took the mission in progress" % file)
    screen.free()


## Play the rest of a mission as a good crew (as test_missions.gd does);
## return the stars.
func _play(run: MissionRun, file: String) -> int:
    var stars := [0]
    run.finished.connect(func(given: int) -> void: stars[0] = given)
    if run.step_index == 0 and run.days == 0.0:
        run.begin()
    var port := run.mission.start_port
    for turn in range(200):
        if run.is_done():
            break
        var step := run.step()
        var scene: Variant = step.opening(run)
        if scene == null:
            scene = step.arrive(run, port)
        if scene == null:
            var targets := step.target_ports(run)
            if targets.is_empty():
                break
            var next := targets[0]
            var km := World.port_km(port).distance_to(World.port_km(next))
            run.pass_days(km * DETOUR / 100.0)
            port = next
            if step is RaceStep and step.is_racing(run) and not World.ports().has(next):
                var buoy: Array[Vector2] = [World.port_km(next)]
                step.update(run, buoy, 0.0, 0.0)
                continue
            scene = step.arrive(run, port)
        for count in range(20):
            if scene == null:
                break
            var action: String = step.solution(run)
            if action == "":
                action = scene["buttons"][0]["action"]
            if action == "leave":
                break
            scene = step.act(run, action)
        run.advance()
    _check(run.is_done(), "%s: %s is played to the end" % [file, run.mission.id])
    return stars[0]
