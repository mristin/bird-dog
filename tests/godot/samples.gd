extends RefCounted
## What the tests of the texts and of the layout go through (see
## test_text_fit.gd and test_dialogue_layout.gd): every language of the game,
## and every scene of every mission as a good crew meets them.


## Every language of the game (translations/languages.json), or only those given
## with --only=<code>[,<code>...].
static func codes() -> Array[String]:
    var codes: Array[String] = []
    var listing: Array = JSON.parse_string(
        FileAccess.get_file_as_string("res://translations/languages.json")
    )
    for language in listing:
        codes.append(str(language["code"]))
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--only="):
            var only := arg.trim_prefix("--only=").split(",")
            codes.assign(codes.filter(func(code: String) -> bool: return code in only))
    return codes


## Load the translation with its drafts (the fuzzy marks removed), as the game
## does with --drafts; null for English. [param tag] keeps the files of the
## tests which run at the same time apart.
static func load_drafts(code: String, tag: String) -> Translation:
    if code == "en":
        return null
    var lines := PackedStringArray()
    for line in FileAccess.get_file_as_string("res://translations/%s.po" % code).split("\n"):
        if not (line.begins_with("#,") and "fuzzy" in line):
            lines.append(line)
    var path := "user://%s_%s.po" % [tag, code]
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string("\n".join(lines))
    file.close()
    var translation := AddressedTranslation.new(load(path))
    TranslationServer.add_translation(translation)
    return translation


## Every scene of the mission as a good crew meets it: {"scene", "port"}, with
## the port where it is shown. A scene on the arrival in a port (and the start
## of the mission) carries the buttons of the port, as on the mission screen
## (see PortScene.add_buttons); a wrong port says so.
static func scenes(mission: Mission) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var run := MissionRun.new(mission, 5)
    run.begin()
    var port := mission.start_port
    var start := MissionStep.talk(
        null,
        [MissionRun.line("Fair winds, captain! Do you need anything before you set sail?")],
        MissionRun.line("Set sail!")
    )
    PortScene.add_buttons(start, port, run)
    result.append({"scene": start, "port": port})
    for turn in range(100):
        if run.is_done():
            break
        var step := run.step()
        var scene: Variant = step.opening(run)
        var arrival := false
        if scene == null:
            scene = step.arrive(run, port)
            arrival = true
        if scene == null:
            var targets := step.target_ports(run)
            if targets.is_empty():
                break
            if step is RaceStep and step.is_racing(run) and not World.ports().has(targets[0]):
                # NOTE (mristin):
                # A buoy of a race is rounded, never entered.
                var buoy: Array[Vector2] = [World.port_km(targets[0])]
                step.update(run, buoy, 0.0, 0.0)
                continue
            var wrong := MissionStep.talk(
                null,
                [MissionRun.line("This is the wrong port, captain!"), run.clue],
                MissionRun.line("Goodbye!")
            )
            PortScene.add_buttons(wrong, port, run)
            result.append({"scene": wrong, "port": port})
            port = targets[0]
            scene = step.arrive(run, port)
            arrival = true
        for count in range(20):
            if scene == null:
                break
            var shown: Dictionary = scene.duplicate(true)
            if arrival and shown["kind"] == "talk":
                PortScene.add_buttons(shown, port, run)
            arrival = false
            result.append({"scene": shown, "port": port})
            var action: String
            if scene["kind"] == "lineup" or scene["buttons"].size() > 1:
                action = step.solution(run)
            else:
                action = scene["buttons"][0]["action"]
            if action == "leave":
                break
            scene = run.step().act(run, action)
        run.advance()
    return result
