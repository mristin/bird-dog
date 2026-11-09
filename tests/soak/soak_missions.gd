extends SceneTree
## A soak test, too long to run on every commit: run it now and then, e.g.,
## before a release, with
##
##     $GODOT --headless --path . -s tests/soak/soak_missions.gd -- --no-camera --no-music
##
## Every mission sails for minutes of game time with one player and with two,
## with wandering steering (see soak_mission.gd); the scenes of the ports and
## the meetings at sea are answered as they come. The test checks that no boat
## gets stuck for long, that the hazards do not pile up, that the objects in
## memory do not keep growing, and (by the output) that no script error
## happens.

const SOAK := preload("res://tests/soak/soak_mission.gd")

## The simulated time of every mission, in seconds, and the step.
const SECONDS := 240.0
const STEP := 0.2

## A boat which moved less than this in a window of WINDOW seconds, while it
## was at sea, counts as stuck; STUCK_WINDOWS such windows in a row fail.
const WINDOW := 30.0
const MOVED_KM := 1.0
const STUCK_WINDOWS := 3

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
    for mission in MissionCatalog.all():
        for players in [1, 2]:
            await _soak(mission, players)
    var grown := Performance.get_monitor(Performance.OBJECT_COUNT) - objects
    print("The objects grew by %d over all the missions." % grown)
    _check(grown < 5000, "the objects keep growing (%d)" % grown)

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


func _soak(mission: Mission, players: int) -> void:
    var label := "%s with %d player(s)" % [mission.id, players]
    var scene: Node = SOAK.new()
    scene.mission_id = mission.id
    scene.next_scene = ""
    scene.record_result = false
    scene.players = players
    root.add_child(scene)
    await process_frame
    scene._on_shared_action("done")

    var last: Array[Vector2] = []
    var stuck: Array[int] = []
    for helm in scene._helms:
        last.append(helm.km)
        stuck.append(0)
    var most_hazards := 0
    var ports := 0
    var steps_per_window := int(WINDOW / STEP)
    for step in range(int(SECONDS / STEP)):
        ports += _answer(scene)
        scene.advance(STEP)
        most_hazards = maxi(most_hazards, scene._hazards.get_child_count())
        if step % steps_per_window == steps_per_window - 1:
            for helm in scene._helms:
                var moved: float = helm.km.distance_to(last[helm.player])
                var sailing: bool = not scene._busy[helm.player]
                stuck[helm.player] = stuck[helm.player] + 1 if sailing and moved < MOVED_KM else 0
                _check(stuck[helm.player] < STUCK_WINDOWS, "%s: boat %d is stuck at %s" % [label, helm.player + 1, helm.km])
                last[helm.player] = helm.km
        if step % 10 == 0:
            await process_frame
    print("%s: %d scenes, at most %d hazards, %.1f days" % [label, ports, most_hazards, scene._run.days])
    _check(most_hazards < 40, "%s: the hazards pile up (%d)" % [label, most_hazards])
    scene.free()
    await process_frame


## Close what is open, as the players would; return how many scenes it was.
func _answer(scene: Node) -> int:
    var count := 0
    if scene._exchange != null:
        scene._on_exchange("close")
    for player in range(scene.players):
        for tries in range(10):
            if not scene._busy[player] or scene._run.is_done():
                break
            var shown: Dictionary = scene._cards[player].scene()
            var action := "leave"
            if shown["kind"] == "lineup" or (shown["kind"] == "talk" and str(shown["buttons"][0]["action"]).begins_with("answer:")):
                action = scene._run.step().solution(scene._run)
            elif shown["kind"] == "talk":
                action = shown["buttons"][0]["action"]
            scene._on_action(action, player)
            count += 1
    return count
