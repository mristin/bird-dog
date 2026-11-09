class_name ShipCard
extends HandButton

## A ship in Master Ivan's shipyard (see Ship), as a button: the ship sailing
## with the captain's decorations, its name, how fast it sails, how quickly it
## turns and how many rations of food it stows (as pips), and its price, or
## "On board" if the captain sails it, or "Bought" if the crew owns it.

var ship: Ship

## The decorations of the captain's boat, and the captain's initial.
var decorations := {}
var initial := ""

## "on board", "bought", or "" (to buy).
var state := ""

var _boat: SeaBoat


func _ready() -> void:
    super()
    _boat = SeaBoat.new()
    _boat.heading = -PI * 0.5 + 0.3
    _boat.sail_angle = 0.3
    _boat.speed_share = 0.8
    _boat.scale = Vector2.ONE * 0.85
    _boat.initial = initial
    _boat.ship = ship
    _boat.decorations = decorations
    add_child(_boat)


func _process(delta: float) -> void:
    super(delta)
    if _boat != null:
        _boat.position = Vector2(size.x * 0.5, 74)


## How many pips (1 to 5) a share of the bracera gets; the bracera gets 3.
static func pips(share: float, step: float) -> int:
    return clampi(roundi(3.0 + (share - 1.0) / step), 1, 5)


func _draw() -> void:
    super()
    if ship == null:
        return
    var font := ThemeDB.fallback_font
    var name_text := tr(ship.name)
    draw_string(
        font,
        Vector2(8, 158),
        name_text,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 16,
        HandButton.fit_size(font, name_text, 28, size.x - 16),
        Paper.RED
    )
    var rows := [
        [tr("Speed"), pips(ship.speed, 0.1)],
        [tr("Turning"), pips(ship.turn, 0.2)],
        [tr("Food"), ship.rations],
    ]
    var y := 184.0
    var label_width := size.x * 0.44
    for row in rows:
        draw_string(
            font,
            Vector2(14, y + 7),
            row[0],
            HORIZONTAL_ALIGNMENT_LEFT,
            label_width,
            HandButton.fit_size(font, row[0], 20, label_width - 14),
            Paper.INK
        )
        for k in range(5):
            var at := Vector2(18 + label_width + k * 22, y)
            if k < row[1]:
                draw_circle(at, 8, Paper.GOLD)
            draw_arc(at, 8, 0, TAU, 16, Color(Paper.INK, 0.8 if k < row[1] else 0.3), 1.5, true)
        y += 26
    if state == "on board" or state == "bought":
        var label := tr("On board") if state == "on board" else tr("Bought")
        var color := Paper.RED if state == "on board" else Paper.INK
        draw_string(
            font,
            Vector2(8, size.y - 12),
            label,
            HORIZONTAL_ALIGNMENT_CENTER,
            size.x - 16,
            26,
            color
        )
        return
    var coin := Vector2(size.x * 0.5 - 34, size.y - 22)
    draw_circle(coin, 12, Paper.GOLD)
    draw_arc(coin, 12, 0, TAU, 16, Paper.INK, 1.5, true)
    draw_string(
        font, coin + Vector2(18, 10), str(ship.price), HORIZONTAL_ALIGNMENT_LEFT, 90, 28, Paper.INK
    )
