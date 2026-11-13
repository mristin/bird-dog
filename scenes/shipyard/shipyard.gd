extends MenuScreen

## Master Ivan's shipyard in Pula (see DESIGN.md, section 10): every captain
## decorates their own boat, paid from the ducats of the crew, or even buys a
## new ship (see Ship): a nimble gajeta, a fast trabakul, a big galleon, ...
## for very many ducats. What is bought stays bought, and switching between
## the bought ships and decorations is free.
##
## On the left, the captain's boat turns slowly on the water; above it, the
## captains to choose (with two players). On the right, in two rows of tabs, the
## places of the boat
## (the ship itself, the sail, the hull, the pennant, the figurehead, the
## streamers, the lanterns, a friend on board), and a card for every ship or
## decoration of the chosen place. Buying asks first.

## How many decoration cards fit on the right.
const CARDS := 8

## The tabs on the right: the ship, then the places of the decorations.
const TABS: Array[String] = [
    "ship", "sail", "hull", "flag", "figurehead", "streamers", "lanterns", "friend"
]

## The ducats of the crew at the start (for the test screens), or -1.
@export var start_ducats := -1

## The mission select, to go back.
@export_file("*.tscn") var missions_scene := "res://scenes/mission_select/mission_select.tscn"

var _captain := 0
var _slot := "ship"
var _preview: SeaBoat
var _cards: GridContainer
var _slots: Array[HandButton] = []
var _captain_buttons: Array[HandButton] = []

@onready var _session: Node = get_node("/root/Session")
@onready var _crew: Node = get_node("/root/Crew")


func _build() -> void:
    if start_ducats >= 0:
        _session.ducats = start_ducats
    _preview = SeaBoat.new()
    _preview.position = Vector2(400, 560)
    _preview.scale = Vector2.ONE * 2.6
    _preview.speed_share = 0.7
    add_child(_preview)

    if _crew.players > 1:
        for i in range(_crew.players):
            var button := HandButton.new()
            button.position = Vector2(80 + i * 330, 170)
            button.size = Vector2(310, 90)
            button.text = str(_crew.captains[i].get("name", ""))
            button.text_size = 34
            button.pressed.connect(_choose_captain.bind(i))
            add_child(button)
            _captain_buttons.append(button)

    var slot_names := {
        "ship": tr("Ship"),
        "sail": tr("Sail"),
        "hull": tr("Hull"),
        "flag": tr("Pennant"),
        "figurehead": tr("Figurehead"),
        "streamers": tr("Streamers"),
        "lanterns": tr("Lanterns"),
        "friend": tr("Friend"),
    }
    # NOTE (mristin):
    # The tabs stand in two rows of four above the cards, so that the long
    # names of the places (e.g., "Galionsfigur") fit at a readable size.
    var row := GridContainer.new()
    row.columns = 4
    row.add_theme_constant_override("h_separation", 8)
    row.add_theme_constant_override("v_separation", 8)
    row.position = Vector2(800, 160)
    add_child(row)
    for slot in TABS:
        var button := HandButton.new()
        button.custom_minimum_size = Vector2(259, 56)
        button.text = slot_names[slot]
        button.text_size = 26
        button.pressed.connect(_choose_slot.bind(slot))
        row.add_child(button)
        _slots.append(button)

    _cards = GridContainer.new()
    _cards.columns = 4
    _cards.add_theme_constant_override("h_separation", 20)
    _cards.add_theme_constant_override("v_separation", 20)
    _cards.position = Vector2(800, 290)
    add_child(_cards)

    var back := HandButton.new()
    back.position = Vector2(760, 930)
    back.size = Vector2(400, 100)
    back.text = tr("Back to the missions")
    back.text_size = 34
    back.pressed.connect(_back)
    add_child(back)

    _refresh()


func _captain_data() -> Dictionary:
    return _crew.captains[_captain]


func _choose_captain(index: int) -> void:
    _captain = index
    _refresh()


func _choose_slot(slot: String) -> void:
    _slot = slot
    _refresh()


## Rebuild the cards of the chosen place and show the boat as it is.
func _refresh() -> void:
    var captain := _captain_data()
    var others := World.boat_decorations(captain)
    var initial := str(captain.get("name", "")).left(1).to_upper()
    _preview.decorations = others
    _preview.initial = initial
    _preview.ship = World.captain_ship(captain)
    _preview.color = Color(0.7, 0.12, 0.1) if _captain == 0 else Color(0.12, 0.32, 0.65)
    for i in range(_slots.size()):
        _slots[i].selected = TABS[i] == _slot
    for i in range(_captain_buttons.size()):
        _captain_buttons[i].selected = i == _captain

    for child in _cards.get_children():
        child.queue_free()
    if _slot == "ship":
        _refresh_ships(captain, others, initial)
        return
    var choices: Array = [null]
    for decoration in World.decorations():
        if decoration.slot == _slot:
            choices.append(decoration)
    for i in range(mini(choices.size(), CARDS)):
        var decoration: Decoration = choices[i]
        var card := DecorationCard.new()
        card.custom_minimum_size = Vector2(250, 290)
        card.decoration = decoration
        card.slot = _slot
        card.others = others
        card.initial = initial
        var worn: Decoration = others.get(_slot)
        if decoration == worn or (decoration == null and worn == null):
            card.state = "on board"
            card.selected = true
        elif decoration == null or _session.owned.has(decoration.id):
            card.state = "bought"
        card.pressed.connect(_choose_decoration.bind(decoration))
        _cards.add_child(card)


## The cards of the ships, with the price or whether the crew has it.
func _refresh_ships(captain: Dictionary, others: Dictionary, initial: String) -> void:
    var sailed := World.captain_ship(captain)
    for ship in World.ships():
        var card := ShipCard.new()
        card.custom_minimum_size = Vector2(250, 290)
        card.ship = ship
        card.decorations = others
        card.initial = initial
        if ship == sailed:
            card.state = "on board"
            card.selected = true
        elif ship.price == 0 or _session.owned.has(ship.id):
            card.state = "bought"
        card.pressed.connect(_choose_ship.bind(ship))
        _cards.add_child(card)


func _choose_ship(ship: Ship) -> void:
    if ship.price == 0 or _session.owned.has(ship.id):
        _sail(ship)
        return
    if _session.ducats < ship.price:
        ConfirmDialog.ask(
            self,
            Grammar.format(
                tr("{name} costs {price} {price|ducat|ducats}, but you have only {ducats}."),
                {"name": ship.name, "price": ship.price, "ducats": _session.ducats}
            ),
            tr("Alright"),
            tr("Back")
        )
        return
    var dialog := ConfirmDialog.ask(
        self,
        (
            Grammar.format(
                tr("Buy {name} for {price} {price|ducat|ducats}?"),
                {"name": ship.name, "price": ship.price}
            )
            + " "
            + tr(ship.description)
        ),
        tr("Yes, buy it"),
        tr("No, thanks")
    )
    dialog.confirmed.connect(_buy_ship.bind(ship))


func _buy_ship(ship: Ship) -> void:
    if _session.buy_ship(ship):
        _sail(ship)


## The captain sails the ship from now on.
func _sail(ship: Ship) -> void:
    _captain_data()["ship"] = ship.id
    _session.save()
    _refresh()


func _choose_decoration(decoration: Decoration) -> void:
    if decoration == null or _session.owned.has(decoration.id):
        _wear(decoration)
        return
    if _session.ducats < decoration.price:
        ConfirmDialog.ask(
            self,
            Grammar.format(
                tr("{name} costs {price} {price|ducat|ducats}, but you have only {ducats}."),
                {"name": decoration.name, "price": decoration.price, "ducats": _session.ducats}
            ),
            tr("Alright"),
            tr("Back")
        )
        return
    var dialog := ConfirmDialog.ask(
        self,
        Grammar.format(
            tr("Buy {name} for {price} {price|ducat|ducats}?"),
            {"name": decoration.name, "price": decoration.price}
        ),
        tr("Yes, buy it"),
        tr("No, thanks")
    )
    dialog.confirmed.connect(_buy.bind(decoration))


func _buy(decoration: Decoration) -> void:
    if _session.buy_decoration(decoration):
        _wear(decoration)


## Put the decoration on the captain's boat (null takes the place's one off).
func _wear(decoration: Decoration) -> void:
    var captain := _captain_data()
    var boat: Dictionary = captain.get("boat", {})
    if decoration == null:
        boat.erase(_slot)
    else:
        boat[_slot] = decoration.id
    captain["boat"] = boat
    _session.save()
    _refresh()


func _back() -> void:
    next_scene = missions_scene
    go_next(0.3)


func _process(delta: float) -> void:
    super(delta)
    _preview.heading = sin(Time.get_ticks_msec() / 2500.0) * 0.6 - PI * 0.5
    _preview.sail_angle = sin(Time.get_ticks_msec() / 1800.0) * 0.4


func _draw_screen() -> void:
    var font := ThemeDB.fallback_font
    draw_string(
        font,
        Vector2(0, 110),
        tr("Master Ivan's shipyard"),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        60,
        Paper.RED
    )
    var water := Rect2(60, 290, 680, 600)
    draw_rect(water, ChartView.SEA)
    for y in range(int(water.position.y) + 30, int(water.end.y), 60):
        for x in range(int(water.position.x) + 40, int(water.end.x) - 30, 110):
            draw_arc(Vector2(x, y), 14, PI * 1.1, PI * 1.9, 6, ChartView.SEA_LINES, 2.0)
    draw_rect(water, Paper.INK, false, 4.0)
    var name_text := str(_captain_data().get("name", ""))
    draw_string(font, Vector2(60, 280), name_text, HORIZONTAL_ALIGNMENT_CENTER, 680, 36, Paper.INK)
    Purse.draw(self, Vector2(1560, 140), int(_session.ducats))
