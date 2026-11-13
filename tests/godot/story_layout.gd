extends RefCounted
## The rules of the layout of a dialogue screen (StoryCard), shared by the
## test of every scene in every language (test_dialogue_layout.gd) and the
## contracts which the end-to-end tests check while they play (see
## end2end/contracts.gd):
##
## * Every panel (the plate of the port, the frame of the person, the speech,
##   the question), every button and every card stays inside the screen or its
##   half, and no two of them overlap.
## * In a half, nothing covers the webcam in the inner bottom corner.
## * The speech fits into its panel, the label of every button into its button,
##   the question into its panel, and the texts of the cards into their cards
##   (see BoosterCard and PersonCard), at a readable size.
##
## Not a test itself (its name does not start with test_), it is preloaded by
## the tests.

## The smallest readable font size of a shrunk text (HandButton.fit_size).
const READABLE := 20

## The webcam stands between the two halves at the bottom (see the mission
## screen: 400 x 284 pixels at x = 760, y = 780), in the coordinates of the
## left and of the right half.
const WEBCAM_LEFT := Rect2(760, 780, 200, 284)
const WEBCAM_RIGHT := Rect2(0, 780, 200, 284)


## The problems of the layout of the card as it shows the scene now, each a
## message starting with [param where].
static func problems(story: StoryCard, run: MissionRun, where: String) -> Array[String]:
    var found: Array[String] = []
    var font := ThemeDB.fallback_font
    var scene := story.scene()
    var items: Array[Dictionary] = []
    var panels := story.panels()
    for name in panels:
        items.append({"name": "the %s" % name, "rect": panels[name]})
    for control in story.controls():
        var rect := Rect2(control.get_parent().position + control.position, control.size)
        items.append({"name": name_of(control), "rect": rect})

    var bounds := Rect2(Vector2.ZERO, story.size).grow(1.0)
    var webcam := Rect2()
    if story.compact:
        webcam = WEBCAM_RIGHT if story.mirrored else WEBCAM_LEFT
    for i in range(items.size()):
        var rect: Rect2 = items[i]["rect"]
        if not bounds.encloses(rect):
            found.append("%s: %s sticks out of the screen" % [where, items[i]["name"]])
        if story.compact and rect.intersects(webcam):
            found.append("%s: %s covers the webcam" % [where, items[i]["name"]])
        for j in range(i + 1, items.size()):
            if rect.grow(-1.0).intersects(items[j]["rect"].grow(-1.0)):
                found.append("%s: %s overlaps %s" % [where, items[i]["name"], items[j]["name"]])

    if panels.has("speech"):
        found.append_array(_speech(story, scene, panels["speech"], run, where))
    if panels.has("question"):
        var question := run.say(scene["question"])
        var width: float = panels["question"].size.x - 40
        var fitted := HandButton.fit_size(font, question, 42, width)
        if fitted < mini(42, READABLE):
            found.append("%s: the question '%s' shrinks to %d" % [where, question, fitted])
    for control in story.controls():
        if control is PersonCard:
            found.append_array(_person_card(control, where))
        elif control is BoosterCard:
            found.append_array(_booster_card(control, where))
        elif control is HandButton and not control is BoatCard:
            found.append_array(button(control, where))
    return found


## A short name of a control of the card, for the messages.
static func name_of(control: Control) -> String:
    if control is PersonCard:
        return "the card of %s" % control.person.id
    if control is BoosterCard:
        return "the card of %s" % control.booster.id
    if control is BoatCard:
        return "the card of a boat"
    return "the button '%s'" % control.text


## The speech fits into its panel at a readable size (see StoryCard.speech_size).
static func _speech(
    story: StoryCard, scene: Dictionary, panel: Rect2, run: MissionRun, where: String
) -> Array[String]:
    var font := ThemeDB.fallback_font
    var width := panel.size.x - story.speech_margin() * 2.0
    var wanted: int = story._layout["text_size"]
    var size := story.speech_size(scene["lines"], wanted, width, panel.size.y)
    var height := size * 1.7
    for a_line in scene["lines"]:
        var text := run.say(a_line)
        var lines := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size)
        height += size * 1.4 * maxi(1, int(lines.y / font.get_height(size))) + size * 0.6
    if size >= StoryCard.MIN_SPEECH_SIZE and height <= panel.size.y + size:
        return []
    return [
        "%s: the speech does not fit (%d of %d pixels at %d)" % [where, height, panel.size.y, size]
    ]


## The label of a button fits it at a readable size, on one line or two (see
## HandButton.label_lines).
static func button(button: HandButton, where: String) -> Array[String]:
    if button.text == "":
        return []
    var lines := HandButton.label_lines(
        ThemeDB.fallback_font,
        button.text,
        button.text_size,
        button.size.x - 16.0,
        button.size.y - 12.0
    )
    var size: int = lines[-1][1]
    if size >= mini(button.text_size, READABLE):
        return []
    return ["%s: the button '%s' shrinks to %d" % [where, button.text, size]]


## The hallmarks of a person fit their card and leave room for the portrait.
static func _person_card(card: PersonCard, where: String) -> Array[String]:
    var found: Array[String] = []
    var placed := card.layout()
    var name := "%s: the card of %s" % [where, card.person.id]
    for hallmark: Dictionary in placed["hallmarks"]:
        for word in hallmark["text"].split(" "):
            if _width(word, card.text_size) > placed["width"]:
                found.append("%s: the word '%s' is wider than the card" % [name, word])
    var portrait: Rect2 = placed["portrait"]
    if portrait.size.y < card.size.y * PersonCard.MIN_PORTRAIT_SHARE:
        found.append(
            "%s: the hallmarks leave only %d pixels to the portrait" % [name, portrait.size.y]
        )
    return found


## The picture of a booster stands inside its card, its name takes at most
## two lines, and its description ends above the price (see BoosterCard).
static func _booster_card(card: BoosterCard, where: String) -> Array[String]:
    var found: Array[String] = []
    var font := ThemeDB.fallback_font
    var name := "%s: the card of %s" % [where, card.booster.id]
    if card.picture() != null:
        if not Rect2(Vector2.ZERO, card.size).encloses(card.picture_rect()):
            found.append("%s: the picture sticks out of the card" % name)
    var name_lines := _lines(card.tr(card.booster.name), BoosterCard.NAME_SIZE, card.size.x - 20)
    if name_lines > 2:
        found.append("%s: the name needs %d lines" % [name, name_lines])
    var description := font.get_multiline_string_size(
        card.tr(card.booster.description),
        HORIZONTAL_ALIGNMENT_CENTER,
        card.size.x - 40,
        BoosterCard.DESCRIPTION_SIZE
    )
    var top := (
        card.description_top(mini(2, name_lines)) - font.get_ascent(BoosterCard.DESCRIPTION_SIZE)
    )
    if top + description.y > card.size.y - 60:
        found.append(
            (
                "%s: the description ends at %d, below %d"
                % [name, top + description.y, card.size.y - 60]
            )
        )
    return found


static func _width(text: String, size: int) -> float:
    return ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## How many lines a wrapped text needs.
static func _lines(text: String, size: int, width: float) -> int:
    var font := ThemeDB.fallback_font
    return int(
        (
            font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width, size).y
            / font.get_height(size)
        )
    )
