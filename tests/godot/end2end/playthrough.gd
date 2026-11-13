extends "res://tests/godot/end2end/menus.gd"
## Play the whole game, from the start to the end and once more after a
## restart, as players do, much faster than in real time, and check its
## contracts all the way (see contracts.gd): a property-based test, whose
## random choices come from a seed. The tests test_one_player.gd and
## test_two_players.gd play it with one and with two captains (see
## [member players]).
##
## New players start at the language select, start a voyage, name it, choose
## how many sail, create their captains and watch how to steer. Then they
## play every mission of every chapter, one after the other: they sail with
## the keys (see captain_bot.gd), answer the people in the ports, pick the
## right one in the line-ups (and now and then a wrong one), shop at the
## merchants, run errands, hand over goods when the boats meet, and read the
## end of every mission. They click the buttons with the mouse (and sometimes
## press the keys), and take detours on their way: they watch how to steer
## again, visit Master Ivan's shipyard, look at the other chapters, play a
## mission again, leave a mission and continue it later, open the chart, and
## start the game again in another language, so that the voyage goes through
## every language of the game.
##
## At the end, every mission must be completed with its stars, the last one
## must say that the voyage ends, and the mission select must show them all.
## Then the game starts again (as if quit and started): the language and the
## voyage must come back from the disk as they were, and the players start a
## new voyage, which keeps its own progress, play its first missions, and go
## back to the first voyage.
##
## The test runs the game [constant DEFAULT_TIME_SCALE] times faster than the
## fixed frame rate (with which the tests run) gives, and sails the boats
## [constant DEFAULT_SUBSTEPS] more steps on every frame, as the soak test
## does. Pass `-- --seed=<n>` to try other choices, `-- --time-scale=<x>` and
## `-- --substeps=<n>` for another speed, `-- --missions=<n>` to play only the
## first missions, and `-- --new-voyage-missions=<n>` for more missions of the
## new voyage.
##
## Not a test itself (its name does not start with test_): the tests extend
## it. It keeps its voyages and settings in a directory of its own (see
## [method _directory]), so that it leaves the player's alone.


func _run() -> void:
    var seed_value := int(_argument("seed", str(DEFAULT_SEED)))
    _time_scale = float(_argument("time-scale", str(DEFAULT_TIME_SCALE)))
    _substeps = int(_argument("substeps", str(DEFAULT_SUBSTEPS)))
    _missions_to_play = int(_argument("missions", str(MissionCatalog.all().size())))
    _missions_to_play = clampi(_missions_to_play, 1, MissionCatalog.all().size())
    _new_voyage_missions = int(_argument("new-voyage-missions", str(DEFAULT_NEW_VOYAGE_MISSIONS)))
    print(
        (
            "%d captain(s), seed %d, the time %.1f times faster with %d more steps, %d missions"
            % [players, seed_value, _time_scale, _substeps, _missions_to_play]
        )
    )
    _tracing = "--trace" in OS.get_cmdline_user_args()
    _rng.seed = seed_value
    # NOTE (mristin):
    # The missions draw their winds and hazards from the global generator.
    seed(seed_value)
    Engine.time_scale = _time_scale

    var directory := _directory()
    _clean(directory)
    DirAccess.make_dir_recursive_absolute(directory)
    var session := _session()
    session.saves_dir = directory.path_join("saves")
    session.settings_path = directory.path_join("settings.cfg")
    _language_node().settings_path = directory.path_join("settings.cfg")
    session.id = ""
    session.missions = {}
    session.mission_in_progress = {}
    _crew().start(1)

    _languages.assign(_language_node().codes())
    _languages.shuffle()
    # NOTE (mristin):
    # Shuffle with our own generator, so that the seed decides.
    for i in range(_languages.size() - 1, 0, -1):
        var j := _rng.randi_range(0, i)
        var swap := _languages[i]
        _languages[i] = _languages[j]
        _languages[j] = swap
    _next_language = _languages[0]
    print("The languages, in order: %s" % [_languages])

    var started := Time.get_ticks_msec()
    change_scene_to_file(LANGUAGE_SELECT)
    await _frames(3)
    _check(_name(current_scene) == "language_select", "the game starts with the language select")
    _voyage_intent = "new"
    await _drive(_first_done)
    await _check_the_end()

    await _restart()
    _phase = "second"
    await _drive(_second_done)
    _check_second()

    _phase = "back"
    await _back_to_the_first()

    Keys.release_all()
    Engine.time_scale = 1.0
    for violation in _contracts.violations():
        _check(false, "the contract is broken: %s" % violation)
    var seen := _seen.keys()
    seen.sort()
    print("Seen: %s" % [seen])
    print(
        (
            (
                "Played %d missions, answered %d scenes (%d wrong), bought %d, ran %d errands, "
                + "handed over %d times, in %.0f s of the game, %.1f s in all, "
                + "with %d checks of the contracts"
            )
            % [
                _missions_played,
                _scenes_answered,
                _wrong_answers,
                _bought,
                _errands,
                _handed_over,
                _clock,
                (Time.get_ticks_msec() - started) / 1000.0,
                _contracts.checks(),
            ]
        )
    )

    _clean(directory)
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


# region The missions


## Play the mission until it is left: the boats sail on their own (see
## captain_bot.gd), and the players answer what shows.
func _play_mission(mission: Node) -> void:
    var run: MissionRun = mission._run
    var id: String = mission._mission.id
    var tag := "%s %s" % [_phase, id]
    var bots: Array = []
    for i in range(mission.players):
        var bot = CaptainBot.new(mission, i, _rng)
        bot.errands = _rng.randf() < 0.5
        if i > 0:
            bot.leader = bots[0]
        bots.append(bot)
    _check(mission.players == players, "%s: %d boat(s) sail" % [tag, players])

    var leave_at := INF
    var leave_key := "%s left a mission" % _phase
    var may_leave: bool = _missions_played > 0 and not _seen.has(leave_key)
    if may_leave and (_rng.randf() < LEAVE_CHANCE or _completed_count() >= 3):
        leave_at = _rng.randf_range(20.0, 120.0)
    var instance := mission.get_instance_id()
    var started := _clock
    var frame := 0
    var shown := {}
    var ended_at := -1.0
    var wrong_this_mission := false
    var stars_before: int = _session().stars(id)
    var completed_before: bool = _session().is_completed(id)
    var stars := 0
    var finale_text := ""
    while current_scene == mission and is_instance_valid(mission):
        frame += 1
        var playing := _clock - started
        var complete := Contracts.end_screen(mission)
        if complete != null:
            if ended_at < 0.0:
                ended_at = _clock
                stars = complete.stars
                for bot in bots:
                    bot.stop()
                var button: HandButton = complete.find_children("*", "HandButton", true, false)[0]
                finale_text = button.text
                print(
                    (
                        "%s: done on day %.1f of %.1f with %d stars in %.0f s"
                        % [tag, run.days, mission._mission.clock_days, stars, playing]
                    )
                )
                _contracts.check_screen(complete, "%s, the end" % tag)
            elif _clock - ended_at > _rng.randf_range(1.0, 4.0) and not _here.has("ended"):
                _here["ended"] = true
                var button: HandButton = complete.find_children("*", "HandButton", true, false)[0]
                await _click(button, "the button at the end of %s" % id)
        elif mission._leave_dialog != null:
            await _answer_leave(mission, tag)
        elif mission._full_chart != null:
            if _rng.randf() < 0.1:
                await _key(KEY_C if _rng.randf() < 0.5 else KEY_ESCAPE)
                _check(mission._full_chart == null, "%s: the chart closes" % tag)
        elif mission._exchange != null:
            await _exchange(mission, tag)
        elif mission._shared_card.visible:
            if _stable(shown, mission._shared_card):
                await _answer(mission, mission._shared_card, -1, tag, false)
        else:
            for i in range(mission.players):
                var card: StoryCard = mission._cards[i]
                if card.visible and _stable(shown, card) and not run.is_done():
                    var wrong := not wrong_this_mission and _rng.randf() < WRONG_CHANCE
                    if await _answer(mission, card, i, tag, wrong):
                        wrong_this_mission = true
            for bot in bots:
                bot.tick(_time_scale / 60.0)
            if playing > leave_at and not mission._busy.has(true):
                leave_at = INF
                _seen[leave_key] = true
                _here["leave"] = true
                await _key(KEY_ESCAPE)
                _check(mission._leave_dialog != null, "%s: Esc asks whether to leave" % tag)
            elif not mission._busy.has(true) and _rng.randf() < 0.002:
                if _rng.randf() < 0.5:
                    await _key(KEY_C)
                    _check(mission._full_chart != null, "%s: C opens the chart" % tag)
                    _seen["%s the chart" % _phase] = true
                else:
                    await _key(KEY_ESCAPE)
                    _here["stay"] = true
            elif _substeps > 0 and not mission._all_paused and current_scene == mission:
                # NOTE (mristin):
                # The boats sail on, as the soak test lets them: more steps of
                # the mission in this frame, each with the keys of the bots.
                for k in range(_substeps):
                    if run.is_done() or mission._all_paused:
                        break
                    mission._process(_time_scale / 60.0)
                    _clock += _time_scale / 60.0
                    for bot in bots:
                        bot.tick(_time_scale / 60.0)
            if playing > MISSION_SECONDS and not _here.has("left"):
                _check(false, "%s: the captains did not finish in %d s" % [tag, MISSION_SECONDS])
                _here["left"] = true
                mission._leave_now()
            if _tracing and frame % 300 == 0:
                _trace(mission, bots, tag)
        if frame % CHECK_EVERY == 0 and is_instance_valid(mission) and current_scene == mission:
            _contracts.check_mission(mission, tag)
        await _frames(1)

    for bot in bots:
        bot.stop()
        for failure in bot.failures.slice(0, 5):
            print("NOTE ", failure)
    Keys.release_all()
    _contracts.forget(instance)
    if ended_at < 0.0:
        _check(_here.has("leave") or _here.has("left"), "%s: the mission ends or is left" % tag)
        _check(
            not _session().mission_in_progress.is_empty(),
            "%s: the mission left is saved to continue it" % tag
        )
        _resume = "yes" if _rng.randf() < 0.7 else "no"
        return
    _missions_played += 1
    var session := _session()
    _check(session.is_completed(id), "%s: the voyage records the mission as completed" % tag)
    _check(
        session.stars(id) == maxi(stars, stars_before),
        "%s: the voyage keeps the best stars: %d" % [tag, session.stars(id)]
    )
    _check(session.mission_in_progress.is_empty(), "%s: no mission is in progress anymore" % tag)
    var mission_data: Mission = MissionCatalog.by_id(id)
    if mission_data.finale:
        var last := mission_data.chapter >= MissionCatalog.chapters().size()
        var expected: String = (
            tr("The end of the voyage") if last else tr("On to the next chapter!")
        )
        _check(
            finale_text == expected, "%s: the end says '%s': '%s'" % [tag, expected, finale_text]
        )
        _seen["%s the end of chapter %d" % [_phase, mission_data.chapter]] = true
    if _phase == "first" and not completed_before:
        _finished[id] = stars


## Print what the boats do, to find out why a mission takes long.
func _trace(mission: Node, bots: Array, tag: String) -> void:
    var run: MissionRun = mission._run
    var parts: Array[String] = []
    for bot in bots:
        var helm: Helm = mission._helms[bot.player]
        var where: Dictionary = bot.destination()
        (
            parts
            . append(
                (
                    "boat %d at %s to %s, speed %.1f, busy %s, towed %s, food %.1f"
                    % [
                        bot.player + 1,
                        helm.km.round(),
                        where["port"].id if where.has("port") else "-",
                        helm.speed,
                        mission._busy[bot.player],
                        helm.towed,
                        run.hold(bot.player).provisions,
                    ]
                )
            )
        )
    print(
        (
            "TRACE %s day %.2f, step %s, paused %s, exchange %s: %s"
            % [
                tag,
                run.days,
                run.step().id if run.step() != null else "-",
                mission._all_paused,
                mission._exchange != null,
                "; ".join(parts),
            ]
        )
    )


## Whether the card shows the same scene for a while, as a player reads it
## before answering.
func _stable(shown: Dictionary, card: StoryCard) -> bool:
    var key := Contracts.shown_key(card)
    var last: Dictionary = shown.get(card.get_instance_id(), {})
    if last.get("key", "") != key:
        shown[card.get_instance_id()] = {"key": key, "at": _clock + _rng.randf_range(0.2, 2.0)}
        return false
    return _clock >= float(last["at"])


## Answer the scene of the card ([param player] -1 for the whole screen):
## the right answer, or with [param wrong] a wrong one if there is one; the
## buttons of the port now and then. Return whether the answer was wrong.
func _answer(mission: Node, card: StoryCard, player: int, tag: String, wrong: bool) -> bool:
    var run: MissionRun = mission._run
    var scene := card.scene()
    var buttons: Array = scene.get("buttons", [])
    var actions: Array[String] = []
    for entry in buttons:
        actions.append(str(entry["action"]))
    var controls := card.controls()
    var step := run.step()
    var solution := step.solution(run) if step != null else ""
    var action := ""
    var was_wrong := false
    var key := "%s %d" % [tag, player]
    match scene["kind"]:
        "lineup":
            var count: int = scene["candidates"].size()
            action = solution
            if wrong and count > 1:
                var right := int(solution.get_slice(":", 1))
                action = "pick:%d" % ((right + _rng.randi_range(1, count - 1)) % count)
                was_wrong = true
        "shop":
            var offers: Array = scene["offers"]
            var affordable: Array[int] = []
            for i in range(offers.size()):
                if scene["reasons"][i] == "":
                    affordable.append(i)
            action = "close_shop"
            if (
                not affordable.is_empty()
                and _rng.randf() < BUY_CHANCE
                and int(_here.get(key + " buys", 0)) < 2
            ):
                _here[key + " buys"] = int(_here.get(key + " buys", 0)) + 1
                action = "buy:%d" % _pick(affordable)
                _bought += 1
        _:
            action = actions[0]
            if solution in actions:
                action = solution
                if wrong and solution.begins_with("answer:"):
                    var others := actions.filter(
                        func(a: String) -> bool: return a.begins_with("answer:") and a != solution
                    )
                    if not others.is_empty():
                        action = _pick(others)
                        was_wrong = true
            elif "errand_yes" in actions:
                action = "errand_yes" if _rng.randf() < 0.7 else "close_shop"
                _errands += 1 if action == "errand_yes" else 0
            elif "shop" in actions and _rng.randf() < SHOP_CHANCE and not _here.has(key + " shop"):
                _here[key + " shop"] = true
                action = "shop"
            elif (
                "errand" in actions
                and _rng.randf() < ERRAND_CHANCE
                and not _here.has(key + " errand")
            ):
                _here[key + " errand"] = true
                action = "errand"
            elif "bay" in actions and _rng.randf() < 0.15:
                action = "bay"
            if action == "leave" or action == actions[0]:
                _here.erase(key + " shop")
                _here.erase(key + " errand")
    var index := -1
    if action.begins_with("buy:"):
        index = buttons.size() + int(action.get_slice(":", 1))
    elif action.begins_with("pick:"):
        index = int(action.get_slice(":", 1))
    else:
        index = actions.find(action)
    _check(index >= 0 and index < controls.size(), "%s: the scene offers %s" % [tag, action])
    if index < 0 or index >= controls.size():
        return false
    var chosen := [""]
    var on_chosen := func(given: String) -> void: chosen[0] = given
    card.action_chosen.connect(on_chosen)
    var view := Vector2.ZERO
    if player >= 0:
        view = mission._views[player].position
    _seen["%s scene %s" % [_phase, action.get_slice(":", 0)]] = true
    await _click(controls[index], "'%s' in %s" % [action, tag], view)
    if card.action_chosen.is_connected(on_chosen):
        card.action_chosen.disconnect(on_chosen)
    _check(chosen[0] == action, "%s: the click chooses %s: %s" % [tag, action, chosen[0]])
    _scenes_answered += 1
    if was_wrong:
        _wrong_answers += 1
        _seen["%s wrong %s" % [_phase, scene["kind"]]] = true
    return was_wrong


## The boats met at sea: hand over a few things, and check that the crew
## keeps what it has, then sail on.
func _exchange(mission: Node, tag: String) -> void:
    var card: ExchangeCard = mission._exchange
    if not _here.has("exchange"):
        _here["exchange"] = _rng.randi_range(0, 3)
        _seen["%s met at sea" % _phase] = true
        await _frames(1)
        _contracts.check_screen(card, "%s, the meeting at sea" % tag)
        return
    var run: MissionRun = mission._run
    var buttons := Contracts.active_buttons(card)
    var close := _button(card, tr("Sail on!"))
    var gives := buttons.filter(func(b: HandButton) -> bool: return b != close)
    if int(_here["exchange"]) > 0 and not gives.is_empty():
        _here["exchange"] = int(_here["exchange"]) - 1
        var before := _holdings(run)
        await _click(_pick(gives), "a hand-over at sea")
        await _frames(1)
        _check(
            _holdings(run) == before,
            "%s: handing over keeps what the crew has: %s, then %s" % [tag, before, _holdings(run)]
        )
        _handed_over += 1
        _contracts.check_screen(mission._exchange, "%s, the meeting at sea" % tag)
        return
    _here.erase("exchange")
    await _click(close, "Sail on! at sea")


## What the whole crew has: the ducats, the food and the water, and the
## cargo, as a text to compare.
func _holdings(run: MissionRun) -> String:
    var cargo: Array = []
    var food := 0.0
    for i in range(run.holds.size()):
        cargo.append_array(run.hold(i).cargo)
        food += run.hold(i).provisions
    cargo.sort()
    return "%d ducats, %.3f days of food, %s" % [run.ducats_total(), food, cargo]


## The question whether to leave the mission: yes, when the players want to
## leave it; no, otherwise.
func _answer_leave(mission: Node, tag: String) -> void:
    var dialog: ConfirmDialog = mission._leave_dialog
    await _frames(1)
    _contracts.check_screen(dialog, "%s, asked to leave" % tag)
    var leave: bool = _here.has("leave")
    _here.erase("leave")
    _here.erase("stay")
    if leave:
        _here["left"] = true
        print("%s: leave the mission on day %.1f" % [tag, mission._run.days])
        await _click(_button(dialog, tr("Yes, leave")), "Yes, leave")
    elif _rng.randf() < 0.5:
        await _click(_button(dialog, tr("No, sail on")), "No, sail on")
        _check(mission._leave_dialog == null, "%s: the crew sails on" % tag)
    else:
        await _key(KEY_ESCAPE)
        _check(mission._leave_dialog == null, "%s: Esc sails on" % tag)
    _seen["%s asked to leave a mission" % _phase] = true


# endregion

# region The end and the restart


## The end of the first voyage: every mission completed with its stars, in
## every language, and the mission select shows them all open.
func _check_the_end() -> void:
    var session := _session()
    _first_voyage = session.id
    var select := current_scene
    _check(_name(select) == "mission_select", "the end of the voyage shows the missions")
    for mission in _missions().slice(0, _missions_to_play):
        var stars: int = session.stars(mission.id)
        _check(
            stars >= 1 and stars <= 3,
            "the mission %s is completed with stars: %d" % [mission.id, stars]
        )
    if _missions_to_play == _missions().size():
        _check(
            _seen.has("first the end of chapter %d" % MissionCatalog.chapters().size()),
            "the last mission ends the voyage"
        )
        for chapter in MissionCatalog.chapters():
            _check(
                select._chapter_unlocked(chapter.number), "the chapter %d is open" % chapter.number
            )
        for language in _languages:
            _check(_languages_seen.has(language), "the voyage went through %s" % language)
    _check(_crew().players == players, "%d captain(s) sail in the voyage" % players)
    for screen in [
        "language_select",
        "session_select",
        "session_name",
        "player_count",
        "captain_creator",
        "instruction",
        "mission_select",
        "mission",
    ]:
        _check(_seen.has("first %s" % screen), "the players saw the screen %s" % screen)
    if session.has_shipyard():
        _check(_seen.has("first shipyard"), "the players saw the shipyard")


## Start the game again, as if quit and started: what the voyage keeps must
## come back from the disk as it was, and the language, too.
func _restart() -> void:
    var session := _session()
    var before: Dictionary = session.to_data()
    before.erase("updated")
    # NOTE (mristin):
    # The disk keeps the numbers as floats, and the keys in any order.
    var saved := JSON.stringify(JSON.parse_string(JSON.stringify(before)), "", true)
    var language: String = _language_node().current()
    session.id = ""
    session.voyage_name = ""
    session.missions = {}
    session.ducats = 0
    session.owned.clear()
    session.mission_in_progress = {}
    _crew().start(1)
    # NOTE (mristin):
    # The game speaks the saved language again at the start (see Languages).
    TranslationServer.set_locale(_language_node().SOURCE_LANGUAGE)
    _check(_saved_language() == language, "the language %s is saved" % language)
    TranslationServer.set_locale(_saved_language())
    _check(session.last_id() == _first_voyage, "the voyage is the last one")
    _check(session.load_voyage(_first_voyage), "the voyage loads from the disk")
    var after: Dictionary = session.to_data()
    after.erase("updated")
    var loaded := JSON.stringify(JSON.parse_string(JSON.stringify(after)), "", true)
    _check(
        loaded == saved, "the voyage comes back from the disk as it was:\n%s\n%s" % [saved, loaded]
    )
    session.id = ""
    _voyage_intent = "new"
    _next_language = ""
    change_scene_to_file(LANGUAGE_SELECT)
    await _frames(3)
    _screen = null


## The new voyage: its own crew and progress, and the first voyage kept as it
## was.
func _check_second() -> void:
    var session := _session()
    _second_voyage = session.id
    _check(_second_voyage != "" and _second_voyage != _first_voyage, "a new voyage starts")
    _check(_crew().players == players, "%d captain(s) sail in the new voyage" % players)
    for i in range(_missions().size()):
        var id := _missions()[i].id
        _check(
            session.is_completed(id) == (i < _new_voyage_missions),
            "the new voyage completed only its first missions: %s" % id
        )
    var first: Variant = session.read(_first_voyage)
    _check(first != null, "the first voyage is still there")
    if first != null:
        for id in _finished:
            _check(
                int(first["missions"].get(id, {}).get("stars", 0)) >= int(_finished[id]),
                "the first voyage keeps its stars of %s" % id
            )
    for screen in ["session_select", "session_name", "player_count", "captain_creator"]:
        _check(_seen.has("second %s" % screen), "the players saw the screen %s again" % screen)


## Go back to the first voyage through the voyages, and find it as it was.
func _back_to_the_first() -> void:
    var select := current_scene
    _voyage_intent = _first_voyage
    await _click(_button(select, tr("Voyages")), "Voyages")
    await _leaves(select, "Voyages")
    await _drive(
        func() -> bool:
            return _name(current_scene) == "mission_select" and _session().id == _first_voyage
    )
    var session := _session()
    for id in _finished:
        _check(
            session.stars(id) >= int(_finished[id]),
            "back in the first voyage, %s keeps its stars" % id
        )
    _check(_next_mission() == null, "back in the first voyage, every mission is completed")
    _contracts.check_screen(current_scene, "back mission_select")

# endregion
