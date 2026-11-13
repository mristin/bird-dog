extends "res://tests/godot/end2end/driver.gd"
## The menus of the game, as the players of the end-to-end tests go through
## them (see playthrough.gd): the language, the voyages, the name of a voyage,
## the captains, how to steer, the missions and the shipyard, with detours.
##
## Not a test itself (its name does not start with test_): the tests extend
## it.

# region The menus


## Do one thing on the screen: a detour, or what leads on.
func _act(screen: Node) -> void:
    match _name(screen):
        "language_select":
            await _act_language(screen)
        "session_select":
            await _act_voyages(screen)
        "session_name":
            await _act_voyage_name(screen)
        "player_count":
            await _act_player_count(screen)
        "captain_creator":
            await _act_captains(screen)
        "instruction":
            await _act_instruction(screen)
        "mission_select":
            await _act_missions(screen)
        "shipyard":
            await _act_shipyard(screen)
        _:
            _check(false, "%s: the bot does not know the screen %s" % [_phase, _name(screen)])
            change_scene_to_file(LANGUAGE_SELECT)
            await _frames(3)


## Esc asks whether to quit; the players stay (once in a phase).
func _try_to_quit(screen: Node) -> bool:
    if not _detour("Esc on %s" % _name(screen), 0.0):
        return false
    await _key(KEY_ESCAPE)
    var dialogs := get_nodes_in_group(ConfirmDialog.GROUP)
    _check(dialogs.size() == 1, "%s: Esc asks whether to quit on %s" % [_phase, _name(screen)])
    if dialogs.is_empty():
        return true
    _contracts.check_screen(screen, "%s %s, asked to quit" % [_phase, _name(screen)])
    if _rng.randf() < 0.5:
        await _click(_button(screen, tr("No, stay")), "No, stay")
    else:
        await _key(KEY_ESCAPE)
    await _frames(2)
    _check(
        get_nodes_in_group(ConfirmDialog.GROUP).is_empty() and current_scene == screen,
        "%s: the players stay on %s" % [_phase, _name(screen)]
    )
    return true


func _act_language(screen: Node) -> void:
    var codes: Array[String] = _language_node().codes()
    var code: String = _next_language if _next_language in codes else _pick(codes)
    var index := codes.find(code)
    var saved := _saved_language()
    if saved != "":
        _check(
            screen._highlight == codes.find(saved),
            "%s: the language select marks the saved language %s" % [_phase, saved]
        )
    if index < 10 and _rng.randf() < 0.25:
        await _key(KEY_0 if index == 9 else (KEY_1 + index) as Key)
    else:
        await _click(screen._cards[index], "the language %s" % code)
    if await _leaves(screen, "the language %s" % code):
        _check(_language_node().current() == code, "%s: the game speaks %s" % [_phase, code])
        _check(_saved_language() == code, "%s: the language %s is saved" % [_phase, code])
        _languages_seen[code] = true
        _next_language = ""


func _saved_language() -> String:
    var settings := ConfigFile.new()
    if settings.load(_language_node().settings_path) != OK:
        return ""
    return str(settings.get_value("general", "language", ""))


func _act_voyages(screen: Node) -> void:
    if await _try_to_quit(screen):
        return
    var session := _session()
    var voyages: Array = session.list()
    if not voyages.is_empty() and _detour("delete, but keep", 0.1):
        var delete: HandButton = _pick(
            Contracts.active_buttons(screen).filter(
                func(b: HandButton) -> bool: return b.symbol == "trash"
            )
        )
        await _click(delete, "Delete")
        _check(
            get_nodes_in_group(ConfirmDialog.GROUP).size() == 1, "%s: Delete asks first" % _phase
        )
        _contracts.check_screen(screen, "%s session_select, asked to delete" % _phase)
        await _click(_button(screen, tr("No, keep it")), "No, keep it")
        await _frames(2)
        _check(session.list().size() == voyages.size(), "%s: No keeps the voyage" % _phase)
        return
    match _voyage_intent:
        "new":
            await _click(_button(screen, tr("New voyage")), "New voyage")
            await _leaves(screen, "New voyage")
        "continue":
            _check(
                not voyages.is_empty() and session.last_id() != "",
                "%s: the voyages offer to continue the last one" % _phase
            )
            await _click(_button(screen, tr("Continue")), "Continue")
            await _leaves(screen, "Continue")
        _:
            var name := ""
            for voyage in voyages:
                if voyage["id"] == _voyage_intent:
                    name = voyage["name"]
            var card := _button(screen, name)
            if session.last_id() == _voyage_intent:
                card = _button(screen, tr("Continue"))
            _check(card != null, "%s: the voyages show the voyage %s" % [_phase, name])
            await _click(card, "the voyage %s" % name)
            await _leaves(screen, "the voyage %s" % name)
            _check(session.id == _voyage_intent, "%s: the voyage %s goes on" % [_phase, name])


func _act_voyage_name(screen: Node) -> void:
    var keyboard: NameKeyboard = screen._keyboard
    if not _here.has("letters"):
        _here["letters"] = _rng.randi_range(0, 8)
        _here["typed"] = 0
    var keys := Contracts.active_buttons(keyboard).filter(
        func(b: HandButton) -> bool: return b.title.length() == 1 or b.text == tr("Space")
    )
    if int(_here["typed"]) < int(_here["letters"]):
        _here["typed"] = int(_here["typed"]) + 1
        if _rng.randf() < 0.1:
            await _click(_button(keyboard, tr("Delete")), "Delete in the name")
        else:
            await _click(_pick(keys), "a key of the voyage's name")
        return
    var typed := keyboard.typed_name()
    await _click(_button(keyboard, tr("OK")), "OK for the voyage's name")
    if typed.strip_edges() == "":
        _here["letters"] = int(_here["letters"]) + 1
        return
    if await _leaves(screen, "OK for the voyage's name"):
        _check(
            _session().voyage_name == typed.strip_edges(),
            "%s: the voyage is named '%s': '%s'" % [_phase, typed, _session().voyage_name]
        )


func _act_player_count(screen: Node) -> void:
    if await _try_to_quit(screen):
        return
    if _rng.randf() < 0.3:
        await _key(KEY_1 if players == 1 else KEY_2)
    else:
        var cards := Contracts.active_buttons(screen).filter(
            func(b: HandButton) -> bool: return b.title == str(players)
        )
        _check(cards.size() == 1, "%s: one card for %d captain(s)" % [_phase, players])
        if not cards.is_empty():
            await _click(cards[0], "%d captain(s)" % players)
    if await _leaves(screen, "%d captain(s)" % players):
        _check(_crew().players == players, "%s: %d captain(s) sail" % [_phase, players])


func _act_captains(screen: Node) -> void:
    var panels: Array = screen._panels
    for panel: CaptainPanel in panels:
        if panel._keyboard.visible:
            # NOTE (mristin):
            # Typing the name: a few letters, then OK.
            var key := "letters %d" % panel.player
            if not _here.has(key):
                _here[key] = _rng.randi_range(0, 7)
            if int(_here[key]) > 0:
                _here[key] = int(_here[key]) - 1
                var letters := Contracts.active_buttons(panel._keyboard).filter(
                    func(b: HandButton) -> bool: return b.title.length() == 1
                )
                await _click(_pick(letters), "a letter of the captain's name")
            else:
                _here.erase(key)
                await _click(_button(panel._keyboard, tr("OK")), "OK for the captain's name")
                if panel._keyboard.visible:
                    _here[key] = 1
            return
    for panel: CaptainPanel in panels:
        var key := "tries %d" % panel.player
        if not _here.has(key):
            _here[key] = _rng.randi_range(0, 10)
        if panel.is_ready():
            continue
        if int(_here[key]) > 0:
            _here[key] = int(_here[key]) - 1
            var buttons := Contracts.active_buttons(panel).filter(
                func(b: HandButton) -> bool: return b != panel._ready_button
            )
            await _click(_pick(buttons), "a button of the captain %d" % (panel.player + 1))
            return
        await _click(panel._ready_button, "Ready for the captain %d" % (panel.player + 1))
        return
    if await _leaves(screen, "Ready of all the captains", 6.0):
        for i in range(players):
            _check(
                str(_crew().captains[i].get("name", "")) != "",
                "%s: the captain %d has a name" % [_phase, i + 1]
            )


func _act_instruction(screen: Node) -> void:
    # NOTE (mristin):
    # The first time, the players watch it all; later, they skip it.
    var watch_all := not _seen.has("watched how to steer")
    if watch_all:
        _seen["watched how to steer"] = true
        var until := _clock + 400.0
        while current_scene == screen and _clock < until:
            await _frames(10)
            if current_scene == screen:
                _contracts.check_screen(screen, "%s instruction" % _phase)
        _check(current_scene != screen, "%s: how to steer ends on its own" % _phase)
        return
    await _wait(_rng.randf_range(0.5, 8.0))
    await _key(KEY_SPACE)
    await _leaves(screen, "Space in how to steer")


func _act_missions(screen: Node) -> void:
    _check_unlocked(screen)
    if not get_nodes_in_group(ConfirmDialog.GROUP).is_empty():
        await _answer_continue(screen)
        return
    if await _try_to_quit(screen):
        return
    var next := _next_mission()
    if next == null or await _missions_detour(screen, next):
        return
    var chosen := next
    if (
        _phase == "first"
        and _completed_count() > 2
        and not _seen.has("first mission again")
        and _resume == ""
        and _rng.randf() < 0.1
    ):
        _seen["first mission again"] = true
        chosen = _missions()[0]
    await _choose_mission(screen, chosen)


## The question whether to continue the mission which the players left.
func _answer_continue(screen: Node) -> void:
    _check(_resume != "", "%s: the mission select asks only after leaving a mission" % _phase)
    var yes := _resume == "yes"
    _seen["%s continue a mission: %s" % [_phase, _resume]] = true
    _resume = ""
    if _rng.randf() < 0.3:
        await _key(KEY_ENTER if yes else KEY_ESCAPE)
    else:
        var text := tr("Yes, continue") if yes else tr("No, start anew")
        await _click(_button(screen, text), text)
    await _leaves(screen, "the answer whether to continue")


## Take a detour from the mission select before the [param next] mission;
## return whether the players took one.
func _missions_detour(screen: Node, next: Mission) -> bool:
    # NOTE (mristin):
    # The voyage goes through every language: it starts the game again in the
    # next one now and then.
    if _phase == "first" and _language_due():
        print("Start the game again in %s before %s" % [_next_language, next.id])
        _voyage_intent = "continue"
        change_scene_to_file(LANGUAGE_SELECT)
        await _frames(3)
    elif _detour("chapters", 0.1):
        var tabs: Array = screen._tabs
        await _click(_pick(tabs), "a chapter")
    elif _detour("how to steer", 0.03):
        await _click(_button(screen, tr("How to steer")), "How to steer")
        await _leaves(screen, "How to steer")
    elif _session().has_shipyard() and _detour("shipyard", 0.1):
        await _click(_button(screen, tr("Ivan's shipyard")), "Ivan's shipyard")
        await _leaves(screen, "Ivan's shipyard")
    elif _completed_count() > 0 and _detour("voyages", 0.03):
        _voyage_intent = "continue"
        await _click(_button(screen, tr("Voyages")), "Voyages")
        await _leaves(screen, "Voyages")
    elif _phase == "first" and _completed_count() > 1 and _detour("save and load", 0.02):
        await _key(KEY_F5)
        await _key(KEY_F6)
        await _frames(3)
    else:
        return false
    return true


## Whether the voyage should go on in the next language now: the languages
## are spread evenly over the missions.
func _language_due() -> bool:
    var switched := _languages_seen.size()
    if switched >= _languages.size():
        return false
    var every := maxf(1.0, float(_missions_to_play) / _languages.size())
    if _completed_count() < int(switched * every):
        return false
    _next_language = _languages[switched]
    return true


## Every mission is open exactly when it is the first or the one before it
## is completed, and the cards show the stars of the voyage.
func _check_unlocked(screen: Node) -> void:
    var session := _session()
    var missions := _missions()
    for i in range(missions.size()):
        var open: bool = session.is_unlocked(missions[i])
        var expected: bool = i == 0 or session.is_completed(missions[i - 1].id)
        _check(
            open == expected,
            "%s: %s is open exactly after the one before" % [_phase, missions[i].id]
        )
    for card in screen._grid.get_children():
        if card is MissionCard and not card.is_queued_for_deletion():
            var mission: Mission = null
            for each in MissionCatalog.of_chapter(screen._chapter):
                if MissionCatalog.number_in_chapter(each) == card.number:
                    mission = each
            if mission != null:
                _check(
                    card.locked != session.is_unlocked(mission),
                    "%s: the card of %s shows whether it is open" % [_phase, mission.id]
                )
                _check(
                    card.stars == session.stars(mission.id),
                    "%s: the card of %s shows its stars" % [_phase, mission.id]
                )


func _choose_mission(screen: Node, mission: Mission) -> void:
    if screen._chapter != mission.chapter:
        await _click(screen._tabs[mission.chapter - 1], "the chapter %d" % mission.chapter)
        await _frames(2)
    var card: MissionCard = null
    for each in screen._grid.get_children():
        if (
            each is MissionCard
            and not each.is_queued_for_deletion()
            and each.number == MissionCatalog.number_in_chapter(mission)
        ):
            card = each
    _check(card != null and not card.locked, "%s: the card of %s is open" % [_phase, mission.id])
    if card == null:
        return
    await _click(card, "the mission %s" % mission.id)
    await _frames(2)
    if get_nodes_in_group(ConfirmDialog.GROUP).is_empty():
        await _leaves(screen, "the mission %s" % mission.id)


func _act_shipyard(screen: Node) -> void:
    var dialogs := get_nodes_in_group(ConfirmDialog.GROUP)
    if not dialogs.is_empty():
        _contracts.check_screen(screen, "%s shipyard, asked" % _phase)
        var buttons := Contracts.active_buttons(dialogs[0])
        await _click(_pick(buttons), "an answer in the shipyard")
        return
    if not _here.has("tries"):
        _here["tries"] = _rng.randi_range(1, 8)
    if int(_here["tries"]) > 0:
        _here["tries"] = int(_here["tries"]) - 1
        var buttons := Contracts.active_buttons(screen).filter(
            func(b: HandButton) -> bool: return b.text != tr("Back to the missions")
        )
        await _click(_pick(buttons), "a button of the shipyard")
        return
    await _click(_button(screen, tr("Back to the missions")), "Back to the missions")
    await _leaves(screen, "Back to the missions")

# endregion
