class_name DecorationCard
extends HandButton

## A decoration in Master Ivan's shipyard, as a button: a little boat wearing
## it (on top of the captain's other decorations), its name, and its price, or
## "On board" if the captain's boat wears it, or "Bought" if the crew owns it.

## The decoration; null for "none" (e.g., no figurehead).
var decoration: Decoration

## The slot of the card, for "none".
var slot := ""

## The other decorations of the captain's boat, and the captain's initial.
var others := {}
var initial := ""

## "on board", "bought", or "" (to buy).
var state := ""

var _boat: SeaBoat


func _ready() -> void:
    super()
    _boat = SeaBoat.new()
    _boat.position = Vector2(size.x * 0.5, size.y * 0.45)
    _boat.heading = -PI * 0.5 + 0.3
    _boat.sail_angle = 0.3
    _boat.speed_share = 0.8
    _boat.scale = Vector2.ONE * 1.15
    _boat.initial = initial
    var shown := others.duplicate()
    if decoration != null:
        shown[decoration.slot] = decoration
    else:
        shown.erase(slot)
    _boat.decorations = shown
    add_child(_boat)


func _process(delta: float) -> void:
    super(delta)
    if _boat != null:
        _boat.position = Vector2(size.x * 0.5, size.y * 0.42)


func _draw() -> void:
    super()
    var font := ThemeDB.fallback_font
    var name_text := tr(decoration.name) if decoration != null else tr("Nothing")
    draw_string(
        font,
        Vector2(8, size.y - 52),
        name_text,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 16,
        HandButton.fit_size(font, name_text, 26, size.x - 16),
        Paper.INK
    )
    var label := ""
    var color := Paper.INK
    if state == "on board":
        label = tr("On board")
        color = Paper.RED
    elif state == "bought" or decoration == null:
        label = tr("Bought")
    else:
        label = str(decoration.price)
        var coin := Vector2(size.x * 0.5 - 28, size.y - 24)
        draw_circle(coin, 12, Paper.GOLD)
        draw_arc(coin, 12, 0, TAU, 16, Paper.INK, 1.5, true)
        draw_string(
            font, coin + Vector2(18, 10), label, HORIZONTAL_ALIGNMENT_LEFT, 80, 28, Paper.INK
        )
        return
    draw_string(
        font, Vector2(8, size.y - 14), label, HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 26, color
    )
