class_name ExchangeCard
extends Control

## The two boats met at sea (see DESIGN.md, "Two players"): the crews can hand
## over to each other half of their food and water, ten ducats, or anything
## and anybody they carry (the bell, the salt, Master Ivan...). Each side of
## the card shows a boat's hold and its "Give" buttons; "Sail on!" in the
## middle closes the card.

## The crews chose: "food:<from>", "ducats:<from>", "item:<from>:<id>" or "close".
signal action_chosen(action: String)

## How many ducats one press gives.
const DUCATS_STEP := 10

## The colours of the captains.
const COLORS: Array[Color] = [Color(0.7, 0.12, 0.1), Color(0.12, 0.32, 0.65)]

var run: MissionRun

## The names of the captains.
var names: Array[String] = ["", ""]

var _controls: Array[Control] = []


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


## Build the buttons for what the boats carry now.
func refresh() -> void:
    for control in _controls:
        control.queue_free()
    _controls.clear()
    for side in range(2):
        var hold := run.hold(side)
        var column := VBoxContainer.new()
        column.add_theme_constant_override("separation", 16)
        column.position = Vector2(110 + side * 1000, 430)
        column.size = Vector2(700, 460)
        add_child(column)
        _controls.append(column)
        var arrow := "→" if side == 0 else "←"
        var entries: Array = []
        if hold.provisions > 0.2:
            entries.append([tr("Give half the food and water") + " " + arrow, "food:%d" % side])
        if hold.on_board() > 0:
            entries.append(
                [
                    (
                        Grammar.format(
                            tr("Give {ducats} {ducats|ducat|ducats}"),
                            {"ducats": mini(DUCATS_STEP, hold.on_board())}
                        )
                        + " "
                        + arrow
                    ),
                    "ducats:%d" % side
                ]
            )
        for item_id in hold.cargo:
            var item := World.item(item_id)
            entries.append(
                [
                    (
                        Grammar.format(
                            tr("Give: {item}"), {"item": item.name if item != null else item_id}
                        )
                        + " "
                        + arrow
                    ),
                    "item:%d:%s" % [side, item_id]
                ]
            )
        for entry in entries.slice(0, 5):
            var button := HandButton.new()
            button.custom_minimum_size = Vector2(700, 80)
            button.text = entry[0]
            button.text_size = 30
            button.pressed.connect(_choose.bind(entry[1]))
            column.add_child(button)

    var close := HandButton.new()
    close.position = Vector2(810, 940)
    close.size = Vector2(300, 110)
    close.text = tr("Sail on!")
    close.text_size = 40
    close.pressed.connect(_choose.bind("close"))
    add_child(close)
    _controls.append(close)
    queue_redraw()


## Hand over what the action says ("food:<giver>", "ducats:<giver>" or
## "item:<giver>:<item id>") from the boat of the giver to the other boat.
static func hand_over(the_run: MissionRun, action: String) -> void:
    var parts := action.split(":")
    var giver := the_run.hold(int(parts[1]))
    var taker := the_run.hold(1 - int(parts[1]))
    match parts[0]:
        "food":
            giver.give_provisions(taker)
        "ducats":
            giver.give_ducats(taker, DUCATS_STEP)
        "item":
            giver.give_item(taker, parts[2])


func _choose(action: String) -> void:
    action_chosen.emit(action)


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    if run == null:
        return
    Paper.draw(self, size)
    var font := ThemeDB.fallback_font
    draw_string(
        font,
        Vector2(0, 100),
        tr("The boats meet at sea!"),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        60,
        Paper.RED
    )
    draw_string(
        font,
        Vector2(0, 160),
        tr("What do you want to give to each other?"),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        34,
        Paper.INK
    )
    for side in range(2):
        var hold := run.hold(side)
        var left := 110.0 + side * 1000.0
        draw_rect(Rect2(left - 20, 200, 740, 210), Color(COLORS[side], 0.12))
        draw_rect(Rect2(left - 20, 200, 740, 210), COLORS[side], false, 4.0)
        draw_string(
            font, Vector2(left, 250), names[side], HORIZONTAL_ALIGNMENT_LEFT, 700, 40, COLORS[side]
        )
        var share := run.provisions_share(side)
        draw_string(
            font,
            Vector2(left, 300),
            tr("Food and water"),
            HORIZONTAL_ALIGNMENT_LEFT,
            300,
            28,
            Paper.INK
        )
        draw_rect(Rect2(left + 260, 280, 300, 24), Color(Paper.INK, 0.15))
        draw_rect(Rect2(left + 260, 280, 300 * share, 24), Color(0.3, 0.6, 0.25))
        draw_rect(Rect2(left + 260, 280, 300, 24), Paper.INK, false, 2.0)
        draw_string(
            font,
            Vector2(left, 345),
            Grammar.format(tr("{ducats} {ducats|ducat|ducats}"), {"ducats": hold.on_board()}),
            HORIZONTAL_ALIGNMENT_LEFT,
            300,
            28,
            Paper.INK
        )
        for i in range(hold.cargo.size()):
            var item := World.item(hold.cargo[i])
            if item != null:
                CargoIcons.draw(self, item, Vector2(left + 300 + i * 80, 360), 30)
