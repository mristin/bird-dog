extends SceneTree
## Drive the mission screen headless, without a window, with two players: the
## briefing for both, sailing with the hazards, a port (with its merchant) in
## the half of the player who entered while the other sails on, towing when
## the food runs out, and the meeting at sea with an exchange of the cargo.
## The precommit checks fail on any script error.

const MISSION := preload("res://scenes/mission/mission.tscn")

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
    var session: Node = root.get_node("Session")
    session.ducats = 100
    var scene: Node = MISSION.instantiate()
    scene.mission_id = "corsairs_of_ulcinj"
    scene.next_scene = ""
    scene.record_result = false
    scene.players = 2
    root.add_child(scene)
    await _frames(2)

    _check(scene._all_paused, "the mission starts with the briefing for both")
    scene._on_shared_action("done")
    await _frames(2)
    _check(
        scene._busy[0] and scene._busy[1], "after the briefing, both crews are in the start port"
    )
    var start: Array = scene._port_scenes[0]["buttons"]
    _check(start.size() == 4 and start[1]["action"] == "shop", "the start port has a merchant")
    _check(start[3]["action"] == "bay", "from Kotor, the crew can sail on to Herceg Novi")
    scene._on_action("leave", 0)
    scene._on_action("leave", 1)
    await _frames(2)
    _check(not scene._busy[0] and not scene._busy[1], "then both set sail")
    _check(not scene._all_paused, "after the briefing, the crew sails")
    _check(scene._views.size() == 2, "every player has a half of the screen")

    # NOTE (mristin):
    # Sail for a while with every hazard, so that they all get updated.
    scene._hazards._cloud_count = 2
    scene._hazards._cloud_timer = 0.0
    scene._hazards._corsair_timer = 0.0
    scene._hazards._loot_timer = 0.0
    scene._helms[0].km = World.port_km(World.port("kotor")) + Vector2(-30, 25)
    scene._helms[1].km = World.port_km(World.port("kotor")) + Vector2(-60, 60)
    scene._met = true
    await _frames(120)

    var run: MissionRun = scene._run
    scene._arrive(0, World.port("ulcinj"))
    await _frames(1)
    _check(scene._busy[0] and not scene._busy[1], "the port opens only for the player who entered")
    var buttons: Array = scene._port_scenes[0]["buttons"]
    _check(buttons.size() >= 2 and buttons[1]["action"] == "shop", "the port has a merchant")
    scene._on_action("shop", 0)
    await _frames(1)
    _check(scene._cards[0].scene()["kind"] == "shop", "the merchant shows the stall")
    var before := run.bag.purse()
    scene._on_action("buy:0", 0)
    await _frames(1)
    _check(run.bag.purse() < before, "buying costs ducats")
    scene._on_action("close_shop", 0)
    await _frames(1)
    _check(scene._cards[0].scene()["kind"] == "talk", "closing the stall returns to the port")
    _check(buttons.size() == 3 and buttons[2]["action"] == "errand", "the port has work")
    scene._on_action("errand", 0)
    await _frames(1)
    var offer: Dictionary = scene._offers[0]
    _check(not offer.is_empty(), "the local offers an errand")
    scene._on_action("errand_yes", 0)
    await _frames(1)
    _check(
        run.errands.size() == 1 and run.hold(0).cargo.has(offer["item"]), "the boat takes the goods"
    )
    scene._on_action(buttons[0]["action"], 0)
    await _frames(2)
    if scene._busy[0]:
        scene._resume(0)
    var ducats_before := run.hold(0).ducats
    scene._arrive(0, World.port(offer["port"]))
    await _frames(1)
    _check(run.errands.is_empty(), "the errand is done in its port")
    _check(run.hold(0).ducats == ducats_before + offer["reward"], "and the boat is paid")
    scene._resume(0)

    run.hold(1).provisions = 0.0
    await _frames(2)
    _check(scene._helms[1].towed, "without food, fishermen tow the boat")
    _check(scene._tows[1] != null, "their boat sails ahead, with the rope")
    var towed_from: Vector2 = scene._helms[1].km
    await _frames(30)
    _check(scene._helms[1].km != towed_from, "the fishermen tow the boat slowly to a port")
    for frame in range(60 * 120):
        if not scene._helms[1].towed:
            break
        await process_frame
    _check(scene._busy[1] and run.hold(1).provisions > 0.0, "the towed boat arrives in the port")
    scene._resume(1)

    run.hold(0).cargo.append("sail")
    run.hold(0).ducats = 40
    run.hold(0).spent = 0
    run.hold(1).ducats = 0
    run.hold(1).spent = 0
    scene._met = false
    # NOTE (mristin):
    # A gajeta stows a single ration: the first boat may have been towed to a
    # port while the second was towed; both sail on with full rations.
    for i in range(2):
        if scene._busy[i]:
            scene._resume(i)
        run.hold(i).provisions = run.hold(i).max_provisions
    var open_sea := World.to_km(41.6, 18.6)
    scene._helms[0].km = open_sea
    scene._helms[1].km = open_sea + Vector2(1, 1)
    await _frames(2)
    _check(scene._exchange != null, "the boats meet at sea")
    scene._on_exchange("item:0:sail")
    scene._on_exchange("ducats:0")
    _check(run.hold(1).cargo.has("sail"), "the first boat hands over the sail")
    _check(run.hold(1).ducats == 10, "and ten ducats")
    scene._on_exchange("close")
    await _frames(2)
    _check(not scene._all_paused, "after the meeting, the boats sail on")

    # NOTE (mristin):
    # The play-tests found boats which left Herceg Novi back into the bay, to
    # Kotor (after the bay button), and boats which left Corfu and Ulcinj onto
    # the reefs or the land. Such ports send every boat one way, whichever way
    # it came in, clear of the land and the reefs.
    var one_way := World.ports().filter(func(port: Port) -> bool: return port.leave_heading >= 0.0)
    _check(one_way.size() >= 3, "Herceg Novi, Corfu and Ulcinj send the boats one way")
    for port: Port in one_way:
        var wanted := deg_to_rad(port.leave_heading)
        scene._entry_headings[0] = wanted + PI
        scene._launch(port, 0)
        var helm: Helm = scene._helms[0]
        _check(
            (
                is_equal_approx(helm.heading, wanted)
                and scene._chart.is_clear_ahead(helm.km, wanted, 12.0)
            ),
            "a boat leaves %s the way the port sends it, clear of the land and the reefs" % port.id
        )

    scene._ask_to_leave()
    await _frames(1)
    _check(scene._all_paused and scene._leave_dialog != null, "Esc asks before leaving")
    scene._leave_dialog._cancel()
    await _frames(1)
    _check(not scene._all_paused, "and the crew sails on after 'no'")

    for sound in ["crash", "coins", "thunder", "bell"]:
        var stream := Sfx.stream_of(sound)
        _check(stream != null and stream.data.size() > 1000, "the sound %s is made" % sound)

    scene.free()
    await _check_saving(session)

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


## The mission in progress is saved in the ports, and the crew continues it
## where it left off.
func _check_saving(session: Node) -> void:
    var directory := "user://test_mission_saves_%d" % Time.get_ticks_usec()
    session.saves_dir = directory
    session.settings_path = directory + "/settings.cfg"
    session.start("Test voyage")

    var first: Node = MISSION.instantiate()
    first.mission_id = "bell_of_grebastica"
    first.next_scene = ""
    first.players = 1
    root.add_child(first)
    await _frames(2)
    first._on_shared_action("done")
    await _frames(2)
    first._on_action("leave", 0)
    await _frames(2)
    # NOTE (mristin):
    # The route of the trail is drawn anew for every mission; its first port.
    var trail_port := World.port(first._run.plan["trail"]["route"][0])
    first._helms[0].km = World.port_km(trail_port) + Vector2(-20, 10)
    first._run.hold(0).cargo.append("goods_wine")
    first._arrive(0, trail_port)
    await _frames(1)
    var days: float = first._run.days
    _check(session.progress_of() == "bell_of_grebastica", "a port saves the mission in progress")
    first.free()

    _check(session.load_voyage(session.id), "the voyage loads with the mission in progress")
    session.resume_mission = true
    var second: Node = MISSION.instantiate()
    second.mission_id = "bell_of_grebastica"
    second.next_scene = ""
    second.players = 1
    root.add_child(second)
    await _frames(2)
    var run: MissionRun = second._run
    _check(not second._all_paused, "the crew continues at sea, without the briefing")
    _check(absf(run.days - days) < 0.01, "with the days of the mission")
    _check(run.hold(0).cargo.has("goods_wine"), "with the cargo")
    _check(run.plan["trail"]["index"] == 1, "with the trail where it was")
    _check(second._views[0].minimap.visited.has(trail_port.id), "with the visited ports")
    second.free()

    _check(session.load_voyage(session.id), "the voyage loads again")
    _check(not session.progress_fits(2), "a mission of one boat does not fit two players")
    session.resume_mission = true
    var third: Node = MISSION.instantiate()
    third.mission_id = "bell_of_grebastica"
    third.next_scene = ""
    third.players = 2
    root.add_child(third)
    await _frames(2)
    _check(third._all_paused and third._run.days < 0.01, "two players start the mission anew")
    third.free()

    session.delete_voyage(session.id)
