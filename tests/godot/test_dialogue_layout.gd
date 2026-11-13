extends SceneTree
## Check the layout of every dialogue screen (StoryCard), in English and in the
## drafts of every translation: every scene of every mission in its port (with
## the buttons of the port), the merchant's stall with every booster, and the
## line-ups, on the whole screen and in both halves of it (two players). The
## rules are in story_layout.gd, which the end-to-end tests check while they
## play, too.

const Samples := preload("res://tests/godot/samples.gd")
const StoryLayout := preload("res://tests/godot/story_layout.gd")

## The layouts of the card: the whole screen, and the left and the right half.
const LAYOUTS: Array[Dictionary] = [
    {"name": "", "compact": false, "mirrored": false},
    {"name": " in the left half", "compact": true, "mirrored": false},
    {"name": " in the right half", "compact": true, "mirrored": true},
]

var _failures: Array[String] = []
var _language := ""


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append("%s: %s" % [_language, message])


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    # NOTE (mristin):
    # Every form for the addressed captains must fit, so we measure the longest.
    Grammar.longest_crew_forms = true
    var samples: Array[Dictionary] = []
    for mission in MissionCatalog.all():
        for sample in Samples.scenes(mission):
            sample["where"] = mission.id
            samples.append(sample)
    samples.append_array(_stalls())
    var run := MissionRun.new(MissionCatalog.all()[0], 1)

    for code in Samples.codes():
        _language = code
        var translation := Samples.load_drafts(code, "dialogue_layout")
        TranslationServer.set_locale(code)
        for sample in samples:
            for layout in LAYOUTS:
                await _check_screen(sample, layout, run)
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


## The merchant's stall in Kotor, with every booster of the world, four at a
## time.
func _stalls() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var port := World.port("kotor")
    var run := MissionRun.new(MissionCatalog.all()[0], 1)
    var boosters := World.boosters()
    for start in range(0, boosters.size(), Merchant.STALL_SIZE):
        var stall := boosters.slice(start, start + Merchant.STALL_SIZE)
        var scene := MissionStep.talk(
            port.locals[0],
            [MissionRun.line("What would you like, captain?")],
            MissionRun.line("Goodbye!"),
            "close_shop"
        )
        scene["kind"] = "shop"
        scene["offers"] = stall
        var reasons: Array = []
        for booster in stall:
            reasons.append("")
        scene["reasons"] = reasons
        scene["lines"].append(
            MissionRun.line("You have {ducats} {ducats|ducat|ducats}.", {"ducats": run.bag.purse()})
        )
        result.append({"scene": scene, "port": port, "where": "the stall %d" % start})
    return result


func _check_screen(sample: Dictionary, layout: Dictionary, run: MissionRun) -> void:
    var story := StoryCard.new()
    story.compact = layout["compact"]
    story.mirrored = layout["mirrored"]
    story.size = Vector2(960, 1080) if story.compact else Vector2(1920, 1080)
    root.add_child(story)
    story.present(sample["scene"], run, sample["port"])
    # NOTE (mristin):
    # The rows of the buttons and the cards lay out their children in a frame.
    await process_frame

    var where := "%s, %s%s" % [sample["where"], _describe(sample["scene"], run), layout["name"]]
    for problem in StoryLayout.problems(story, run, where):
        _check(false, problem)
    story.free()


## A short description of the scene for the messages: what is said first.
func _describe(scene: Dictionary, run: MissionRun) -> String:
    if scene["kind"] == "lineup":
        return "the line-up"
    var said: String = run.say(scene["lines"][0]) if not scene["lines"].is_empty() else ""
    return "'%s'" % said.left(40)
