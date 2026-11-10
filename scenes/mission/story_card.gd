class_name StoryCard
extends Control

## Show a scene of a mission (see MissionStep): a person talks, the crew picks
## a boat or a person in a line-up, or the merchant shows the stall. The
## picture of the port fills the card; the person stands framed on the left
## with their lines beside them, and the answers are big HandButtons.
##
## The card fills the screen (one player, the briefing) or the half of the
## player whose boat entered the port ([member compact], two players): the
## other player sails on meanwhile.

## The players chose an answer.
signal action_chosen(action: String)

## Where everything stands: on the whole screen, and on a half of it.
const FULL := {
    "title": Rect2(60, 40, 520, 100),
    "title_size": 60,
    "frame": Rect2(70, 190, 470, 760),
    "speech": Rect2(600, 150, 1200, 540),
    "speech_alone": Rect2(300, 150, 1320, 540),
    "speech_shop": Rect2(600, 150, 1200, 170),
    "text_size": 34,
    "buttons": Rect2(560, 720, 1240, 140),
    "button": Vector2(420, 130),
    "button_text": 44,
    "row": Rect2(0, 290, 1920, 520),
    "card": Vector2(500, 520),
    "question": Rect2(260, 170, 1400, 100),
    "shop": Rect2(600, 336, 1200, 430),
    "offer": Vector2(300, 430),
}
## The half keeps clear of its inner bottom corner, where the webcam stands
## between the two halves (see the mission screen); the right half mirrors it.
const HALF := {
    "title": Rect2(20, 16, 560, 90),
    "title_size": 44,
    "frame": Rect2(20, 120, 300, 420),
    "speech": Rect2(340, 110, 560, 540),
    "speech_alone": Rect2(60, 110, 840, 540),
    "speech_shop": Rect2(20, 120, 920, 190),
    "text_size": 26,
    "buttons": Rect2(60, 680, 660, 140),
    "button": Vector2(236, 130),
    "button_text": 30,
    "row": Rect2(0, 230, 960, 520),
    "card": Vector2(220, 480),
    "question": Rect2(20, 120, 920, 90),
    "shop": Rect2(20, 334, 920, 430),
    "offer": Vector2(220, 430),
}

## Speech shrinks to fit its box, but not below this size.
const MIN_SPEECH_SIZE := 20

## Whether the card is a half of the screen.
var compact := false

## The player whose captain the card addresses alone (the half of their boat),
## or -1 for the whole crew.
var player := -1

## Whether the card is the right half (its layout is mirrored).
var mirrored := false

var _scene := {}
var _run: MissionRun
var _picture: Texture2D
var _title := ""
var _icon := ""
var _controls: Array[Control] = []
var _layout := FULL


func _ready() -> void:
    if size == Vector2.ZERO:
        set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


## The scene which the card shows.
func scene() -> Dictionary:
    return _scene


## Show the scene in the port (whose picture and name frame it).
func present(new_scene: Dictionary, run: MissionRun, port: Port) -> void:
    _scene = new_scene
    _run = run
    _layout = HALF if compact else FULL
    if compact and mirrored:
        _layout = _mirror(HALF)
    _picture = port.picture if port != null and port.picture != null else null
    _title = tr(port.name) if port != null else ""
    _icon = port.icon if port != null else ""
    for control in _controls:
        control.queue_free()
    _controls.clear()

    if _scene["kind"] == "lineup":
        _build_lineup()
    else:
        _build_talk()
    if _scene["kind"] == "shop":
        _build_shop()
    visible = true
    queue_redraw()


## The layout of the right half: every area mirrored around the middle.
static func _mirror(layout: Dictionary) -> Dictionary:
    var result := layout.duplicate()
    for key in result:
        var value: Variant = result[key]
        if value is Rect2:
            var area: Rect2 = value
            result[key] = Rect2(960 - area.end.x, area.position.y, area.size.x, area.size.y)
    return result


func _row(area: Rect2, separation: int) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", separation)
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.position = area.position
    row.size = area.size
    add_child(row)
    _controls.append(row)
    return row


func _build_talk() -> void:
    var area: Rect2 = _layout["buttons"]
    var row := _row(area, 20 if compact else 40)
    var count: int = _scene["buttons"].size()
    var wanted: Vector2 = _layout["button"]
    var width := minf(wanted.x, (area.size.x - 20.0 * (count - 1)) / count)
    for entry in _scene["buttons"]:
        var button := HandButton.new()
        button.custom_minimum_size = Vector2(width, wanted.y)
        button.text = _run.say(entry["label"], player)
        button.text_size = _layout["button_text"]
        button.pressed.connect(_choose.bind(entry["action"]))
        row.add_child(button)


## The merchant's stall: a card for every booster on offer (see BoosterCard),
## under the merchant's words.
func _build_shop() -> void:
    var area: Rect2 = _layout["shop"]
    var row := _row(area, 16)
    var offers: Array = _scene["offers"]
    var wanted: Vector2 = _layout["offer"]
    var width := minf(wanted.x, (area.size.x - 16.0 * (offers.size() - 1)) / offers.size())
    for i in range(offers.size()):
        var card := BoosterCard.new()
        card.booster = offers[i]
        card.reason = _scene["reasons"][i]
        card.custom_minimum_size = Vector2(width, wanted.y)
        if card.reason == "":
            card.pressed.connect(_choose.bind("buy:%d" % i))
        row.add_child(card)


func _build_lineup() -> void:
    var area: Rect2 = _layout["row"]
    var row := _row(area, 20 if compact else 50)
    var candidates: Array = _scene["candidates"]
    var wanted: Vector2 = _layout["card"]
    var width := minf(
        wanted.x, (area.size.x - 40.0 - 20.0 * (candidates.size() - 1)) / candidates.size()
    )
    for i in range(candidates.size()):
        var card: HandButton
        if candidates[i] is Person:
            var person_card := PersonCard.new()
            person_card.person = candidates[i]
            card = person_card
        else:
            var boat_card := BoatCard.new()
            boat_card.boat = candidates[i]
            card = boat_card
        card.custom_minimum_size = Vector2(width, wanted.y)
        card.pressed.connect(_choose.bind("pick:%d" % i))
        row.add_child(card)


func _choose(action: String) -> void:
    visible = false
    action_chosen.emit(action)


func _draw() -> void:
    if _scene.is_empty():
        return
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(Vector2.ZERO, size), Paper.PAPER_DARK)
    if _picture != null:
        var picture_size := _picture.get_size()
        var scale := maxf(size.x / picture_size.x, size.y / picture_size.y)
        var drawn := picture_size * scale
        draw_texture_rect(_picture, Rect2((size - drawn) * 0.5, drawn), false)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.18))

    if _title != "":
        var title: Rect2 = _layout["title"]
        draw_rect(title, Color(Paper.PAPER, 0.95))
        draw_rect(title, Paper.INK, false, 3.0)
        var text_left := title.size.y * 0.9
        draw_string(
            font,
            title.position + Vector2(text_left, title.size.y * 0.72),
            _title,
            HORIZONTAL_ALIGNMENT_CENTER,
            title.size.x - text_left - 10,
            _layout["title_size"],
            Paper.RED
        )
        PortIcons.draw(
            self,
            _icon,
            title.position + Vector2(text_left * 0.6, title.size.y * 0.82),
            title.size.y / 135.0
        )

    if _scene["kind"] == "lineup":
        _draw_lineup(font)
    else:
        _draw_talk(font)


func _draw_person(font: Font, person: Person) -> void:
    var frame: Rect2 = _layout["frame"]
    draw_rect(Rect2(frame.position + Vector2(8, 10), frame.size), Color(0, 0, 0, 0.3))
    draw_rect(frame, Paper.PAPER)
    var footer := frame.size.y * 0.2
    if person.portrait != null:
        var portrait_size := person.portrait.get_size()
        var area := Rect2(frame.position + Vector2(16, 16), frame.size - Vector2(32, footer + 16))
        var scale := minf(area.size.x / portrait_size.x, area.size.y / portrait_size.y)
        var drawn := portrait_size * scale
        draw_texture_rect(
            person.portrait, Rect2(area.position + (area.size - drawn) * 0.5, drawn), false
        )
    draw_rect(frame, Paper.INK, false, 4.0)
    var name_text := tr(person.name)
    draw_string(
        font,
        frame.position + Vector2(8, frame.size.y - footer * 0.45),
        name_text,
        HORIZONTAL_ALIGNMENT_CENTER,
        frame.size.x - 16,
        HandButton.fit_size(font, name_text, 44, frame.size.x - 16),
        Paper.RED
    )
    var role := tr(person.role)
    draw_string(
        font,
        frame.position + Vector2(8, frame.size.y - footer * 0.12),
        role,
        HORIZONTAL_ALIGNMENT_CENTER,
        frame.size.x - 16,
        HandButton.fit_size(font, role, 28, frame.size.x - 16),
        Paper.INK
    )


func _draw_talk(font: Font) -> void:
    var person: Person = _scene.get("person")
    var speech: Rect2 = _layout["speech"]
    if _scene["kind"] == "shop":
        speech = _layout["speech_shop"]

    # NOTE (mristin):
    # In a half of the screen, the merchant's stall needs the whole width.
    var shop_in_half: bool = compact and _scene["kind"] == "shop"
    if person != null and not shop_in_half:
        _draw_person(font, person)
    elif not shop_in_half:
        speech = _layout["speech_alone"]

    draw_rect(Rect2(speech.position + Vector2(8, 10), speech.size), Color(0, 0, 0, 0.3))
    draw_rect(speech, Color(Paper.PAPER, 0.97))
    draw_rect(speech, Paper.INK, false, 4.0)
    var margin := 24.0 if compact else 40.0
    var width := speech.size.x - margin * 2.0
    var text_size := speech_size(_scene["lines"], _layout["text_size"], width, speech.size.y)
    var y := speech.position.y + text_size * 1.7
    for a_line in _scene["lines"]:
        var text := _run.say(a_line, player)
        var indent := _indent(a_line, text_size)
        if indent > 0.0:
            # NOTE (mristin):
            # The goods of a delivered errand stand beside its thanks.
            CargoIcons.draw(
                self,
                World.item(a_line["icon"]),
                Vector2(speech.position.x + margin + indent * 0.4, y - text_size * 0.3),
                text_size * 0.8
            )
        draw_multiline_string(
            font,
            Vector2(speech.position.x + margin + indent, y),
            text,
            HORIZONTAL_ALIGNMENT_LEFT,
            width - indent,
            text_size,
            -1,
            Paper.INK
        )
        var lines_used := ceili(
            (
                font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
                / (width - indent)
            )
        )
        y += text_size * 1.4 * maxi(1, lines_used) + text_size * 0.6


## How far the text of a line stands in, to make room for its icon (if any).
static func _indent(a_line: Dictionary, text_size: int) -> float:
    if a_line.has("icon") and World.item(a_line["icon"]) != null:
        return text_size * 2.2
    return 0.0


## The size of the speech: the size of the layout, or smaller, down to a
## readable size, when a scene has a lot to say (see tests/godot/test_text_fit.gd).
func speech_size(lines: Array, wanted: int, width: float, height: float) -> int:
    var font := ThemeDB.fallback_font
    var size := wanted
    while size > MIN_SPEECH_SIZE:
        var needed := size * 1.7
        for a_line in lines:
            var text := _run.say(a_line, player)
            var line_width := width - _indent(a_line, size)
            var used := (
                font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, line_width, size).y
            )
            needed += size * 1.4 * maxi(1, int(used / font.get_height(size))) + size * 0.6
        if needed <= height + size:
            break
        size -= 2
    return size


func _draw_lineup(font: Font) -> void:
    var question := _run.say(_scene["question"], player)
    var area: Rect2 = _layout["question"]
    draw_rect(area, Color(Paper.PAPER, 0.97))
    draw_rect(area, Paper.INK, false, 4.0)
    draw_string(
        font,
        area.position + Vector2(0, area.size.y * 0.66),
        question,
        HORIZONTAL_ALIGNMENT_CENTER,
        area.size.x,
        HandButton.fit_size(font, question, 42, area.size.x - 40),
        Paper.INK
    )
