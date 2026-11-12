extends SceneTree
## Check that the texts fit their places, in English and in the drafts of every
## translation: the clue banner, the names of the ports on their plates, the
## merchant's cards, the decorations, the titles of the missions, the labels
## of the HUD, and the screen at the end of every mission, whose text must
## stay above its button. The scenes of the missions are checked in
## test_dialogue_layout.gd. A text which only fits when it
## shrinks below a readable size, or which needs more lines than its box has,
## fails.
##
## The sizes mirror the layouts of StoryCard, BoosterCard, DecorationCard,
## MissionCard and the HUD panels; change them together.

## The smallest readable font size of a shrunk text (HandButton.fit_size).
const READABLE := 20

const Samples := preload("res://tests/godot/samples.gd")

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
    for code in Samples.codes():
        _language = code
        var translation := Samples.load_drafts(code, "text_fit")
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


# endregion

# region The world


func _check_world() -> void:
    for port in World.ports():
        var name := tr(port.name)
        # NOTE (mristin):
        # A name may shrink a little to fit on its plate (see StoryCard).
        _fits(name, ceili(60 * StoryCard.MIN_TITLE_SHARE), 420, "the plate of %s" % port.id)
        _fits(
            name, ceili(44 * StoryCard.MIN_TITLE_SHARE), 430, "the plate of %s in a half" % port.id
        )
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
