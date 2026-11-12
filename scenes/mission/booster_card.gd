class_name BoosterCard
extends HandButton

## A booster on the merchant's stall, as a button: its picture (a decoration
## shows on a little boat, a friend for the deck and a figurehead as
## themselves), its name, what it
## does, and its price. A booster the crew can't buy now is greyed, with the
## reason: too few ducats, two boosters for the leg already, or the crew has
## one already.

## The sizes of the name and of the description.
const NAME_SIZE := 25
const DESCRIPTION_SIZE := 22

var booster: Booster

## Whether the card is in a half of the screen: its picture and its texts move
## up, so that a long description fits.
var compact := false

## Why the crew can't buy it ("" if it can; see MissionRun.why_not).
var reason := ""

var _boat: SeaBoat


## A friend for the deck and a figurehead show themselves, seen from above as
## on the boat (see SeaBoat.FRIEND_PICTURES and SeaBoat.FIGUREHEAD_PICTURES),
## instead of a little boat; null for any other booster.
func picture() -> Texture2D:
    var decoration := booster.decoration if booster != null else null
    if decoration == null:
        return null
    if decoration.slot == "friend":
        return SeaBoat.FRIEND_PICTURES.get(decoration.pattern)
    if decoration.slot == "figurehead":
        return SeaBoat.FIGUREHEAD_PICTURES.get(decoration.pattern)
    return null


## Where the picture stands: as large as it fits between the top of the card
## and the name, keeping its shape, centred.
func picture_rect() -> Rect2:
    var texture := picture()
    var top := 10.0
    var bottom := 172.0 - _lift() - NAME_SIZE - 6.0
    var height := bottom - top
    var width := minf(size.x - 20.0, height * texture.get_width() / texture.get_height())
    height = width * texture.get_height() / texture.get_width()
    return Rect2(Vector2((size.x - width) * 0.5, bottom - height), Vector2(width, height))


func _ready() -> void:
    super()
    if booster == null or booster.decoration == null or picture() != null:
        return
    # NOTE (mristin):
    # A decoration shows on a little boat, sailing to the right.
    _boat = SeaBoat.new()
    _boat.heading = PI * 0.5
    _boat.sail_angle = 0.2
    _boat.speed_share = 0.8
    _boat.wind_to = PI * 1.3
    _boat.scale = Vector2.ONE * 0.9
    _boat.decorations = {booster.decoration.slot: booster.decoration}
    _boat.position = Vector2(size.x * 0.5, 82 - _lift())
    add_child(_boat)


func _process(delta: float) -> void:
    super(delta)
    if _boat != null:
        _boat.position = Vector2(size.x * 0.5, 82 - _lift())


func _draw() -> void:
    super()
    if booster == null:
        return
    var font := ThemeDB.fallback_font
    var faded := reason != ""
    if booster.decoration == null:
        BoosterIcons.draw(self, booster.effect, Vector2(size.x * 0.5, 80 - _lift()), 52)
    if picture() != null:
        draw_texture_rect(picture(), picture_rect(), false)
    # NOTE (mristin):
    # The name may take two lines, so that a long name (in any language)
    # stays readable; the description follows below it.
    var name_text := tr(booster.name)
    var name_lines := mini(2, _lines(font, name_text, NAME_SIZE, size.x - 20))
    draw_multiline_string(
        font,
        Vector2(10, 172 - _lift()),
        name_text,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 20,
        NAME_SIZE,
        2,
        Paper.RED
    )
    draw_multiline_string(
        font,
        Vector2(20, description_top(name_lines)),
        tr(booster.description),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 40,
        DESCRIPTION_SIZE,
        5,
        Paper.INK
    )
    var price := Vector2(size.x * 0.5 - 40, size.y - 40)
    draw_circle(price, 16, Paper.GOLD)
    draw_arc(price, 16, 0, TAU, 20, Paper.INK, 2.0, true)
    draw_string(
        font,
        price + Vector2(24, 12),
        str(booster.price),
        HORIZONTAL_ALIGNMENT_LEFT,
        80,
        36,
        Paper.INK
    )
    if faded:
        # NOTE (mristin):
        # A booster which the crew can't buy is clearly greyed, and the reason
        # stands on a band of its own, away from the description.
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.4, 0.37, 0.72))
        var why := tr("Not enough ducats")
        if reason == "full":
            why = tr("Two boosters already")
        elif reason == "held":
            why = tr("You have it already")
        var band := Rect2(0, size.y - 120, size.x, 56)
        draw_rect(band, Paper.PAPER)
        draw_rect(band, Paper.RED, false, 3.0)
        draw_string(
            font,
            band.position + Vector2(8, 38),
            why,
            HORIZONTAL_ALIGNMENT_CENTER,
            size.x - 16,
            HandButton.fit_size(font, why, 28, size.x - 16),
            Paper.RED
        )


## Where the first line of the description stands (its baseline), under a
## name of [param name_lines] lines.
func description_top(name_lines: int) -> float:
    return 180 - _lift() + name_lines * NAME_SIZE * 1.2


func _lift() -> float:
    return 30.0 if compact else 0.0


static func _lines(font: Font, text: String, size: int, width: float) -> int:
    return int(
        (
            font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size).y
            / font.get_height(size)
        )
    )
