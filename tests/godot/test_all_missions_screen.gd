extends SceneTree
## Play every mission through the real mission screen, headless, with one
## player and with two: the briefing, the start port, and then port after
## port where the story points, answering every scene right, until the screen
## at the end. With two players, the crews take turns; a delivery is made by
## the boat which carries the item (the other one hands it over at sea
## first, as the players would). The precommit checks fail on any script
## error on the way.

const MISSION := preload("res://scenes/mission/mission.tscn")

## A mission must end within this many scenes.
const MAX_SCENES := 80

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _frames(count: int) -> void:
    for i in range(count):
        await process_frame


func _run() -> void:
    for mission in MissionCatalog.all():
        for players in [1, 2]:
            await _play(mission, players)

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


func _play(mission: Mission, players: int) -> void:
    var label := "%s with %d player(s)" % [mission.id, players]
    var scene: Node = MISSION.instantiate()
    scene.mission_id = mission.id
    scene.next_scene = ""
    scene.record_result = false
    scene.players = players
    root.add_child(scene)
    await _frames(2)
    scene._on_shared_action("done")
    await _frames(1)

    var run: MissionRun = scene._run
    var turn := 0
    for count in range(MAX_SCENES):
        await _answer_open(scene, run)
        if run.is_done():
            break
        var step: MissionStep = run.step()
        var targets := step.target_ports(run)
        if targets.is_empty():
            continue
        var target: Port = targets[0]
        var player := _player_for(run, step, target, turn % players)
        if player < 0:
            _check(false, "%s: nobody carries what %s needs" % [label, target.id])
            break
        turn += 1
        scene._arrive(player, target)
        await _frames(1)

    _check(run.is_done(), "%s: the mission ends" % label)
    _check(run.stars() >= 1, "%s: the crew gets stars" % label)
    scene.free()
    await _frames(1)


## Answer every scene which is open, right, until all are closed.
func _answer_open(scene: Node, run: MissionRun) -> void:
    for player in range(scene.players):
        for count in range(20):
            if not scene._busy[player] or run.is_done():
                break
            var shown: Dictionary = scene._cards[player].scene()
            var action: String = shown["buttons"][0]["action"] if shown["kind"] == "talk" else ""
            var choosing: bool = shown["kind"] == "lineup" or str(action).begins_with("answer:")
            if choosing:
                action = run.step().solution(run)
            scene._on_action(action, player)
            await _frames(1)


## The player whose boat should enter the port: the one who carries what the
## port needs (the boats hand it over first if needed), or the given one.
func _player_for(run: MissionRun, step: MissionStep, port: Port, wanted: int) -> int:
    run.active = wanted
    var item := step.wanted_item(run, port)
    if item == null:
        return wanted
    for player in range(run.holds.size()):
        if run.hold(player).cargo.has(item.id):
            run.hold(player).give_item(run.hold(wanted), item.id)
            return wanted
    return -1
