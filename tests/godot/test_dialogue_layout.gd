extends SceneTree
## Check the layout of every dialogue screen (StoryCard), in English and in the
## drafts of every translation: every scene of every mission in its port (with
## the buttons of the port), the merchant's stall with every booster, and the
## line-ups, on the whole screen and in both halves of it (two players).
##
## * Every panel (the plate of the port, the frame of the person, the speech,
##   the question), every button and every card stays inside the screen or its
##   half, and no two of them overlap.
## * In a half, nothing covers the webcam in the inner bottom corner.
## * The speech fits into its panel, the label of every button into its button,
##   the question into its panel, and the texts of the cards into their cards
##   (see BoosterCard and PersonCard), at a readable size.

const Samples := preload("res://tests/godot/samples.gd")

## The smallest readable font size of a shrunk text (HandButton.fit_size).
const READABLE := 20

## The webcam stands between the two halves at the bottom (see the mission
## screen: 400 x 284 pixels at x = 760, y = 780), in the coordinates of the
## left and of the right half.
const WEBCAM_LEFT := Rect2(760, 780, 200, 284)
const WEBCAM_RIGHT := Rect2(0, 780, 200, 284)

## The layouts of the card: the whole screen, and the left and the right half.
const LAYOUTS: Array[Dictionary] = [
    {"name": "", "compact": false, "mirrored": false},
    {"name": " in the left half", "compact": true, "mirrored": false},
    {"name": " in the right half", "compact": true, "mirrored": true},
]

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

    var scene: Dictionary = sample["scene"]
    var where := "%s, %s%s" % [sample["where"], _describe(scene, run), layout["name"]]
    var items: Array[Dictionary] = []
    var panels := story.panels()
    for name in panels:
        items.append({"name": "the %s" % name, "rect": panels[name]})
    for control in story.controls():
        var rect := Rect2(control.get_parent().position + control.position, control.size)
        items.append({"name": _name_of(control), "rect": rect})

    var bounds := Rect2(Vector2.ZERO, story.size).grow(1.0)
    var webcam := Rect2()
    if story.compact:
        webcam = WEBCAM_RIGHT if story.mirrored else WEBCAM_LEFT
    for i in range(items.size()):
        var rect: Rect2 = items[i]["rect"]
        _check(bounds.encloses(rect), "%s: %s sticks out of the screen" % [where, items[i]["name"]])
        _check(
            not story.compact or not rect.intersects(webcam),
            "%s: %s covers the webcam" % [where, items[i]["name"]]
        )
        for j in range(i + 1, items.size()):
            _check(
                not rect.grow(-1.0).intersects(items[j]["rect"].grow(-1.0)),
                "%s: %s overlaps %s" % [where, items[i]["name"], items[j]["name"]]
            )

    if panels.has("speech"):
        _check_speech(story, scene, panels["speech"], run, where)
    if panels.has("question"):
        var question := run.say(scene["question"])
        _shrinks(question, 42, panels["question"].size.x - 40, "%s: the question" % where)
    for control in story.controls():
        if control is PersonCard:
            _check_person_card(control, where)
        elif control is BoosterCard:
            _check_booster_card(control, where)
        elif control is HandButton and not control is BoatCard:
            _check_button(control, where)
    story.free()


## A short description of the scene for the messages: what is said first.
func _describe(scene: Dictionary, run: MissionRun) -> String:
    if scene["kind"] == "lineup":
        return "the line-up"
    var said: String = run.say(scene["lines"][0]) if not scene["lines"].is_empty() else ""
    return "'%s'" % said.left(40)


func _name_of(control: Control) -> String:
    if control is PersonCard:
        return "the card of %s" % control.person.id
    if control is BoosterCard:
        return "the card of %s" % control.booster.id
    if control is BoatCard:
        return "the card of a boat"
    return "the button '%s'" % control.text


## The speech fits into its panel at a readable size (see StoryCard.speech_size).
func _check_speech(
    story: StoryCard, scene: Dictionary, panel: Rect2, run: MissionRun, where: String
) -> void:
    var width := panel.size.x - story.speech_margin() * 2.0
    var wanted: int = story._layout["text_size"]
    story._run = run
    var size := story.speech_size(scene["lines"], wanted, width, panel.size.y)
    var height := size * 1.7
    for a_line in scene["lines"]:
        var text := run.say(a_line)
        var lines := _font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size)
        height += size * 1.4 * maxi(1, int(lines.y / _font.get_height(size))) + size * 0.6
    _check(
        size >= StoryCard.MIN_SPEECH_SIZE and height <= panel.size.y + size,
        "%s: the speech does not fit (%d of %d pixels at %d)" % [where, height, panel.size.y, size]
    )


## The label of a button fits it at a readable size, on one line or two (see
## HandButton.label_lines).
func _check_button(button: HandButton, where: String) -> void:
    var lines := HandButton.label_lines(
        _font, button.text, button.text_size, button.size.x - 16.0, button.size.y - 12.0
    )
    var size: int = lines[-1][1]
    _check(
        size >= mini(button.text_size, READABLE),
        "%s: the button '%s' shrinks to %d" % [where, button.text, size]
    )


## The hallmarks of a person fit their card and leave room for the portrait.
func _check_person_card(card: PersonCard, where: String) -> void:
    var placed := card.layout()
    var name := "%s: the card of %s" % [where, card.person.id]
    for hallmark: Dictionary in placed["hallmarks"]:
        for word in hallmark["text"].split(" "):
            _check(
                _width(word, card.text_size) <= placed["width"],
                "%s: the word '%s' is wider than the card" % [name, word]
            )
    var portrait: Rect2 = placed["portrait"]
    _check(
        portrait.size.y >= card.size.y * PersonCard.MIN_PORTRAIT_SHARE,
        "%s: the hallmarks leave only %d pixels to the portrait" % [name, portrait.size.y]
    )


## The picture of a booster stands inside its card, its name takes at most
## two lines, and its description ends above the price (see BoosterCard).
func _check_booster_card(card: BoosterCard, where: String) -> void:
    var name := "%s: the card of %s" % [where, card.booster.id]
    if card.picture() != null:
        _check(
            Rect2(Vector2.ZERO, card.size).encloses(card.picture_rect()),
            "%s: the picture sticks out of the card" % name
        )
    var name_lines := _lines(tr(card.booster.name), BoosterCard.NAME_SIZE, card.size.x - 20)
    _check(name_lines <= 2, "%s: the name needs %d lines" % [name, name_lines])
    var description := _font.get_multiline_string_size(
        tr(card.booster.description),
        HORIZONTAL_ALIGNMENT_CENTER,
        card.size.x - 40,
        BoosterCard.DESCRIPTION_SIZE
    )
    var top := (
        card.description_top(mini(2, name_lines)) - _font.get_ascent(BoosterCard.DESCRIPTION_SIZE)
    )
    _check(
        top + description.y <= card.size.y - 60,
        "%s: the description ends at %d, below %d" % [name, top + description.y, card.size.y - 60]
    )


func _width(text: String, size: int) -> float:
    return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## How many lines a wrapped text needs.
func _lines(text: String, size: int, width: float) -> int:
    return int(
        (
            _font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width, size).y
            / _font.get_height(size)
        )
    )


## A text which shrinks to fit (HandButton.fit_size) must stay readable.
func _shrinks(text: String, size: int, width: float, where: String) -> void:
    var fitted := HandButton.fit_size(_font, text, size, width)
    _check(fitted >= mini(size, READABLE), "%s: '%s' shrinks to %d" % [where, text, fitted])
