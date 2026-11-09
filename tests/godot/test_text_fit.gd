extends SceneTree
## Check that the texts fit their places, in English and in the drafts of every
## translation: the lines and the buttons of every scene of every mission (on
## the whole screen and in a half of it), the clue banner, the names of the
## ports on their plates, the merchant's cards, the decorations, the titles of
## the missions, the labels of the HUD, and the screen at the end of every
## mission, whose text must stay above its button. A text which only fits when it
## shrinks below a readable size, or which needs more lines than its box has,
## fails.
##
## The sizes mirror the layouts of StoryCard, BoosterCard, DecorationCard,
## MissionCard and the HUD panels; change them together.

## The smallest readable font size of a shrunk text (HandButton.fit_size).
const READABLE := 20

var _failures: Array[String] = []
var _font: Font
var _language := ""


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append("%s: %s" % [_language, message])


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    _font = ThemeDB.fallback_font
    # NOTE (mristin):
    # Every form for the addressed captains must fit, so we measure the longest.
    Grammar.longest_crew_forms = true
    for code in _codes():
        _language = code
        var translation := _load_drafts(code)
        TranslationServer.set_locale(code)
        _check_missions()
        _check_world()
        _check_hud()
        await _check_ends()
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


## Every language of the game (translations/languages.json), or only those given
## with --only=<code>[,<code>...].
func _codes() -> Array[String]:
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
## does with --drafts.
func _load_drafts(code: String) -> Translation:
    if code == "en":
        return null
    var lines := PackedStringArray()
    for line in FileAccess.get_file_as_string("res://translations/%s.po" % code).split("\n"):
        if not (line.begins_with("#,") and "fuzzy" in line):
            lines.append(line)
    var path := "user://text_fit_%s.po" % code
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string("\n".join(lines))
    file.close()
    var translation := AddressedTranslation.new(load(path))
    TranslationServer.add_translation(translation)
    return translation


func _width(text: String, size: int) -> float:
    return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## How many lines a wrapped text needs.
func _lines(text: String, size: int, width: float) -> int:
    return (
        _font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size).y
        / (_font.get_height(size))
    )


## A text which shrinks to fit (HandButton.fit_size) must stay readable.
func _shrinks(text: String, size: int, width: float, where: String) -> void:
    var fitted := HandButton.fit_size(_font, text, size, width)
    _check(fitted >= mini(size, READABLE), "%s: '%s' shrinks to %d" % [where, text, fitted])


func _fits(text: String, size: int, width: float, where: String) -> void:
    _check(_width(text, size) <= width, "%s: '%s' is too wide" % [where, text])


# region Missions


## Every scene of every mission, as a good crew meets them, with the generic
## lines of the ports.
func _check_missions() -> void:
    for mission in MissionCatalog.all():
        var layout := MissionCard.title_layout(_font, tr(mission.title), MissionCard.SIZE.x - 20.0)
        _check(
            (
                layout["size"] >= MissionCard.READABLE
                and layout["lines"].size() <= MissionCard.TITLE_LINES
            ),
            "the title of %s on its card (size %d)" % [mission.id, layout["size"]]
        )
        _shrinks(tr(mission.victory_title), 72, 1160, "the end of %s" % mission.id)
        for scene in _scenes(mission):
            _check_scene(scene, mission.id)


## The screen at the end of every mission, with the most text it can have (the
## ducats, the reward and the fun fact): the text must
## end above the button.
func _check_ends() -> void:
    for mission in MissionCatalog.all():
        var complete := MissionComplete.new()
        complete.mission = mission
        complete.run = MissionRun.new(mission, 1)
        complete.stars = 3
        complete.ducats = 120
        root.add_child(complete)
        await process_frame
        await process_frame
        _check(
            complete.content_bottom <= MissionComplete.BUTTON_TOP,
            (
                "the text at the end of %s ends at %d, below the top of the button (%d)"
                % [mission.id, complete.content_bottom, MissionComplete.BUTTON_TOP]
            )
        )
        complete.free()


func _scenes(mission: Mission) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var run := MissionRun.new(mission, 5)
    run.begin()
    var port := mission.start_port
    for turn in range(100):
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
            port = targets[0]
            result.append(
                MissionStep.talk(
                    null,
                    [MissionRun.line("This is the wrong port, captain!"), run.clue],
                    MissionRun.line("Goodbye!")
                )
            )
            scene = step.arrive(run, port)
        for count in range(20):
            if scene == null:
                break
            result.append(scene)
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


func _check_scene(scene: Dictionary, where: String) -> void:
    var run := MissionRun.new(MissionCatalog.all()[0], 1)
    if scene["kind"] == "lineup":
        _shrinks(run.say(scene["question"]), 42, 880, "%s: the question" % where)
        return

    # NOTE (mristin):
    # The speech in the whole screen and in a half (with the portrait).
    var card := StoryCard.new()
    card._run = run
    for layout in [[1180.0, 40, 590.0], [552.0, 30, 620.0]]:
        var size := card.speech_size(scene["lines"], layout[1], layout[0], layout[2])
        var height := size * 1.7
        for a_line in scene["lines"]:
            var text := run.say(a_line)
            height += size * 1.4 * maxi(1, _lines(text, size, layout[0])) + size * 0.6
        _check(
            height <= layout[2] + size,
            "%s: the speech does not fit at %d pixels (%d of %d)" % [where, size, height, layout[2]]
        )
    card.free()

    var buttons: Array = scene["buttons"].duplicate()
    buttons.append({"label": MissionRun.line("What do you sell?")})
    buttons.append({"label": MissionRun.line("Any work for us?")})
    for entry in buttons:
        var label := run.say(entry["label"])
        _shrinks(label, 44, 404, "%s: a button" % where)
        _shrinks(label, 30, 220, "%s: a button in a half" % where)


# endregion

# region The world


func _check_world() -> void:
    for port in World.ports():
        var name := tr(port.name)
        _fits(name, 60, 420, "the plate of %s" % port.id)
        _fits(name, 44, 430, "the plate of %s in a half" % port.id)
        var sail := Grammar.format(tr("Sail to {port}!"), {"port": port.name})
        _fits(sail, 40, 860, "the banner of %s in a half" % port.id)
    for booster_id in ["new_sails", "fisherman", "pilot", "right_flag", "figs", "bread_water"]:
        var booster: Booster = load("res://data/world/boosters/%s.tres" % booster_id)
        _check(
            _lines(tr(booster.name), BoosterCard.NAME_SIZE, 200) <= 2,
            "the booster %s: its name needs more than 2 lines" % booster_id
        )
        _check(
            _lines(tr(booster.description), BoosterCard.DESCRIPTION_SIZE, 180) <= 5,
            "the booster %s: its description needs more than 5 lines" % booster_id
        )
    for decoration in World.decorations():
        _shrinks(tr(decoration.name), 26, 234, "the decoration %s" % decoration.id)


# endregion

# region The HUD


func _check_hud() -> void:
    _shrinks(tr("Food"), 24, 84, "the rations")
    for text in [tr("Hull"), tr("Careful! Reefs!")]:
        _shrinks(text, 26, 248, "the hull panel in a half")
    _fits(tr("On board"), 24, 360, "the cargo panel")
    _fits(Grammar.format(tr("Days left: {days}"), {"days": 22}), 30, 348, "the days")
    for text in ["What do you sell?", "Any work for us?", "Set sail!", "Goodbye!", "Sail on!"]:
        _shrinks(tr(text), 30, 220, "the button '%s' in a half" % text)
    for text in [tr("Give half the food and water") + " →", tr("The boats meet at sea!")]:
        _shrinks(text, 30, 680, "the meeting")
    _shrinks(tr("Back to the missions"), 34, 380, "the shipyard")

# endregion
