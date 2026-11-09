class_name BoosterCard
extends HandButton

## A booster on the merchant's stall, as a button: its picture (a decoration
## shows on a little boat), its name, what it does, and its price. A booster
## the crew can't buy now is greyed, with the reason: too few ducats, two
## boosters for the leg already, or the crew has one already.

## The sizes of the name and of the description.
const NAME_SIZE := 25
const DESCRIPTION_SIZE := 22

var booster: Booster

## Why the crew can't buy it ("" if it can; see MissionRun.why_not).
var reason := ""

var _boat: SeaBoat


func _ready() -> void:
    super()
    if booster == null or booster.decoration == null:
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
    _boat.position = Vector2(size.x * 0.5, 82)
    add_child(_boat)


func _process(delta: float) -> void:
    super(delta)
    if _boat != null:
        _boat.position = Vector2(size.x * 0.5, 82)


func _draw() -> void:
    super()
    if booster == null:
        return
    var font := ThemeDB.fallback_font
    var faded := reason != ""
    if booster.decoration == null:
        BoosterIcons.draw(self, booster.effect, Vector2(size.x * 0.5, 80), 52)
    # NOTE (mristin):
    # The name may take two lines, so that a long name (in any language)
    # stays readable; the description follows below it.
    var name_text := tr(booster.name)
    var name_lines := mini(2, _lines(font, name_text, NAME_SIZE, size.x - 20))
    draw_multiline_string(
        font,
        Vector2(10, 172),
        name_text,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 20,
        NAME_SIZE,
        2,
        Paper.RED
    )
    draw_multiline_string(
        font,
        Vector2(20, 180 + name_lines * NAME_SIZE * 1.2),
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


static func _lines(font: Font, text: String, size: int, width: float) -> int:
    return int(
        (
            font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size).y
            / font.get_height(size)
        )
    )
