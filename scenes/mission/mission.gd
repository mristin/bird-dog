extends Node

## Play a mission (see DESIGN.md, section 4 and section 15): sail the chart of
## the Adriatic, steered with the bird dog, and follow the story of the mission
## from port to port.
##
## Every player steers a boat of their own and has a half of the screen (see
## SeaView), as in ergo-chaos; the webcam sits between the halves with a line
## down its middle. The boats sail on their own: the player who enters a port
## sees its scene in their half, while the other sails on. Every boat has its
## own hold (food and water, the hull, ducats, cargo and passengers); when the
## boats meet at sea, the crews can exchange what they carry. Sailing close
## together, both boats sail faster, and the corsairs keep away.
##
## The chart points to the port where the crew has to go. The food and the
## water run out with the days, and every port fills them again.
##
## The mission's steps decide what happens (see MissionStep and MissionRun);
## this screen sails the boats, shows the scenes of the steps in the ports,
## and shows the stars at the end.
##
## Without a camera, A/D (the first boat) and the arrow keys (the second boat)
## steer. Esc goes back to the missions.

## Arriving closer than this to a port enters it, in kilometres.
const ENTER_KM := 5.0

## After leaving a port, a boat has to sail this far away before it can enter
## the port again, in kilometres.
const LEAVE_KM := 9.0

## Sailing this far takes a day of the mission clock, in kilometres.
const KM_PER_DAY := 100.0

## Two boats closer than this sail together, and faster, in kilometres.
const TOGETHER_KM := 8.0
const TOGETHER_BOOST := 1.25

## Two boats closer than this meet and can exchange what they carry; they meet
## again only after they were farther apart than PART_KM.
const MEET_KM := 4.0
const PART_KM := 14.0

## The damage of the hull when a boat runs onto a reef at full speed, and onto
## a cliff (out of 100). The rest of the coast never hurts the hull: it would
## be too frustrating.
const REEF_DAMAGE := 35.0
const CLIFF_DAMAGE := 25.0

## Towing a boat to a port is slower than sailing by this factor, and costs
## this many days on top.
const TOW_SLOWER := 2.0
const TOW_DAYS := 0.5

## The fishermen tow a boat at this share of the best speed of a boat: slowly,
## so that the crew watches (see TowBoat).
const TOW_SHARE := 0.45

## New sails make the boats this much faster.
const NEW_SAILS := 1.2

## The colours of the captains: the pennants, the stripes and the frames.
const COLORS: Array[Color] = [Color(0.7, 0.12, 0.1), Color(0.12, 0.32, 0.65)]

## The mission to play; empty takes the mission the crew chose.
@export var mission_id := ""

## How many players sail; 0 takes the crew's.
@export_range(0, 2) var players := 0

## The scene after the mission; empty to play it again (for the test screens).
@export_file("*.tscn") var next_scene := "res://scenes/mission_select/mission_select.tscn"

## Whether to record the stars in the voyage (the test screens do not).
@export var record_result := true

## The port to start in instead of the mission's own (for the test screens,
## e.g., to sail among the islands right away); empty for the mission's own.
@export var start_port_id := ""

var _run: MissionRun
var _wind: SeaWind
var _mission: Mission
var _helms: Array[Helm] = []
var _views: Array[SeaView] = []
var _cards: Array[StoryCard] = []

## Per player: the port where the boat is (null at sea), the port it left last
## (it may enter it again only after sailing away), whether a scene is open in
## its half, the scene of the port which the merchant's stall interrupted, and
## the step of the open scene.
var _in_port: Array = []
var _left: Array = []
var _busy: Array[bool] = []
var _port_scenes: Array = []
var _scene_steps: Array = []

## Per player: the errand which the local of the port offers.
var _offers: Array = []

## Per player: the boosters on the merchant's stall of the port (a random
## four of all, see [method _draw_stall]).
var _stalls: Array = []

## Per player: the Tow to a port, while fishermen tow the boat, or null.
var _tows: Array = []

## Per player: whether the crew was told that the food runs low on this leg.
var _warned_low: Array[bool] = []

var _entry_headings := {}  # By player: the heading of the boat into its last port.

## Whether everything stops for a screen of both players (the briefing, the
## meeting at sea, the end).
var _all_paused := true

## Whether the boats met and have not parted since (they start together).
var _met := true
var _stars := 0

var _chart: ChartView
var _rope: Line2D
var _hazards: SeaHazards
var _wheel: WheelPanel
var _overlay: CanvasLayer
var _shared_card: StoryCard
var _shared_cursor: HandCursor
var _exchange: ExchangeCard
var _sfx: Sfx

var _tips: Tips

## The question whether to leave the mission (Esc), while it is open.
var _leave_dialog: ConfirmDialog
var _paused_before := false
var _full_chart: FullChart

@onready var _session: Node = get_node("/root/Session")
@onready var _crew: Node = get_node("/root/Crew")
@onready var _pose: Node = get_node("/root/Vision").poses


func _ready() -> void:
    var chosen := mission_id if mission_id != "" else str(_session.current_mission)
    _mission = MissionCatalog.by_id(chosen)
    if _mission == null or not _mission.is_playable():
        _mission = MissionCatalog.all()[0]
    _mission = _mission.starting_in(start_port_id)
    if players <= 0:
        players = _crew.players
    _pose.SetPlayerCount(players)

    var seed_value := randi()
    var ships: Array = []
    for i in range(players):
        ships.append(World.captain_ship(_crew.captains[i]) if i < _crew.captains.size() else null)
    _run = MissionRun.new(_mission, seed_value, players, ships)
    _run.bring(_session.ducats)  # All on board; a mission in progress restores its own.
    _wind = SeaWind.new(_mission.sea, seed_value + 1)
    _run.finished.connect(_on_finished)
    _run.rewarded.connect(_on_rewarded)

    for i in range(players):
        _in_port.append(_mission.start_port)
        _left.append(_mission.start_port)
        _busy.append(false)
        _port_scenes.append({})
        _scene_steps.append(null)
        _offers.append({})
        _stalls.append([])
        _tows.append(null)
        _warned_low.append(false)

    var world := _build_world()
    _build_views(world)
    _tips = Tips.new(_session, _views)
    _build_shared()

    _launch(_mission.start_port, -1)
    if record_result and _session.resume_mission and _session.progress_of() == _mission.id:
        _session.resume_mission = false
        if _restore(_session.mission_in_progress):
            _place_boats(true)
            _resume_all()
            return
    _place_boats(true)

    # NOTE (mristin):
    # The briefing is for the whole crew, on the whole screen.
    _run.begin()
    var opening: Variant = _run.step().opening(_run)
    if opening != null:
        _show_shared(opening, _mission.start_port)
    else:
        _resume_all()


# region Building


func _build_world() -> Node2D:
    var world := Node2D.new()
    _chart = ChartView.new()
    world.add_child(_chart)

    _rope = Line2D.new()
    _rope.width = 5.0
    _rope.default_color = Color(Paper.GOLD, 0.8)
    _rope.z_index = 4
    _rope.visible = false
    world.add_child(_rope)

    for i in range(players):
        var boat := SeaBoat.new()
        boat.z_index = 5
        boat.scale = Vector2.ONE * SeaView.BOAT_SCALE
        boat.color = COLORS[i]
        boat.mark = str(i + 1) if players > 1 else ""
        boat.dolphins = true
        boat.ship = _run.hold(i).ship
        if i < _crew.captains.size():
            boat.decorations = World.boat_decorations(_crew.captains[i])
            boat.initial = str(_crew.captains[i].get("name", "")).left(1).to_upper()
        world.add_child(boat)
        _helms.append(Helm.new(i, boat))

    _sfx = Sfx.new()
    add_child(_sfx)
    _hazards = SeaHazards.new()
    _hazards.setup(_mission.sea, _chart, _wind, _run, randi())
    _hazards.said.connect(_say)
    _hazards.sounded.connect(_sfx.play)
    world.add_child(_hazards)
    return world


func _build_views(world: Node2D) -> void:
    for i in range(players):
        var view := SeaView.new()
        add_child(view)
        view.setup(i, players > 1, _run, _wind, world, null if i == 0 else _views[0])
        _views.append(view)

        # NOTE (mristin):
        # The scenes of the ports open in the half of the player who entered,
        # with a cursor which follows only that player's hands.
        var layer := CanvasLayer.new()
        layer.layer = 2
        view.viewport.add_child(layer)
        var card := StoryCard.new()
        card.compact = players > 1
        card.player = i if players > 1 else -1
        card.mirrored = i == 1
        card.size = Vector2(view.size)
        card.visible = false
        card.action_chosen.connect(_on_action.bind(i))
        layer.add_child(card)
        _cards.append(card)
        var cursor := HandCursor.new()
        if players > 1:
            cursor.region = Rect2(i * 0.5, 0, 0.5, 1)
        cursor.visible = false
        layer.add_child(cursor)
        card.set_meta("cursor", cursor)


func _build_shared() -> void:
    var hud := CanvasLayer.new()
    hud.layer = 1
    add_child(hud)
    if players > 1:
        var divider := ColorRect.new()
        divider.color = Paper.INK
        divider.position = Vector2(957, 0)
        divider.size = Vector2(6, 1080)
        divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
        hud.add_child(divider)

    _wheel = WheelPanel.new()
    var steers: Array[float] = []
    var colors: Array[Color] = []
    for i in range(players):
        steers.append(0.0)
        colors.append(COLORS[i] if players > 1 else Paper.INK)
    _wheel.steers = steers
    _wheel.colors = colors
    var looks: Array[Dictionary] = []
    for i in range(mini(players, _crew.captains.size())):
        looks.append(_crew.captains[i])
    _wheel.looks = looks
    if players > 1:
        _wheel.position = Vector2(760, 780)
        _wheel.size = Vector2(400, 284)
    else:
        _wheel.position = Vector2(24, 690)
        _wheel.size = Vector2(480, 340)
    hud.add_child(_wheel)

    _overlay = CanvasLayer.new()
    _overlay.layer = 3
    add_child(_overlay)
    _shared_card = StoryCard.new()
    _shared_card.visible = false
    _shared_card.action_chosen.connect(_on_shared_action)
    _overlay.add_child(_shared_card)
    _shared_cursor = HandCursor.new()
    _shared_cursor.visible = false
    _overlay.add_child(_shared_cursor)


## Put a boat (or, with -1, all of them) into the sea near the port, heading
## away from it.
func _launch(port: Port, player: int) -> void:
    var center := World.port_km(port)
    var near := center
    for helm in _helms:
        if player >= 0 and helm.player != player:
            continue
        var kept: Variant = ChartView.leaving_heading(port, _entry_headings.get(helm.player))
        var departure := _chart.departure(near, center, kept)
        helm.km = departure["km"]
        helm.heading = departure["heading"]
        helm.speed = 0.0
        near = helm.km


# endregion

# region Saving


## Save the mission in progress into the voyage (in every port, and when the
## crew leaves the mission), so that the crew can continue it later.
func _save_progress() -> void:
    if not record_result or _run.is_done():
        return
    var boats: Array = []
    for helm in _helms:
        boats.append(helm.to_data(_left[helm.player]))
    _session.mission_in_progress = {
        "run": _run.to_data(),
        "boats": boats,
        "visited": _views[0].minimap.visited.keys(),
    }
    _session.save()


## Continue the mission in progress; return whether it worked. A mission of
## two boats never continues with one, and vice versa.
func _restore(data: Dictionary) -> bool:
    if data.get("boats", []).size() != players:
        return false
    if not _run.restore(data.get("run", {})):
        return false
    var boats: Array = data.get("boats", [])
    for i in range(mini(boats.size(), _helms.size())):
        _in_port[i] = null
        _left[i] = _helms[i].restore(boats[i])
    for port_id in data.get("visited", []):
        var port := World.port(str(port_id))
        if port != null:
            for view in _views:
                view.minimap.visited[port.id] = true
    return true


# endregion

# region The story


## Show a scene to the whole crew, on the whole screen (the briefing).
func _show_shared(scene: Dictionary, port: Port) -> void:
    _all_paused = true
    _shared_card.present(scene, _run, port)
    _shared_cursor.visible = true
    for view in _views:
        view.show_hud(false)


func _on_shared_action(action: String) -> void:
    _run.active = 0
    var step := _run.step()
    var next: Variant = step.act(_run, action) if step != null and action != "leave" else null
    if next != null:
        _shared_card.present(next, _run, _mission.start_port)
        return
    _run.advance()
    _shared_card.visible = false
    _shared_cursor.visible = false
    if _run.is_done():
        return
    _resume_all()
    for i in range(players):
        _show_start(i)


## After the briefing, every crew is still in the start port: the merchant and
## the errands are there before it sets sail; then the story goes on.
func _show_start(player: int) -> void:
    var port := _mission.start_port
    _in_port[player] = port
    _stalls[player] = Merchant.draw_stall(port, _session.owned, _run.rng)
    var local: Person = port.locals[0] if not port.locals.is_empty() else null
    var said: Array = [
        MissionRun.line("Fair winds, captain! Do you need anything before you set sail?")
    ]
    var scene := MissionStep.talk(local, said, MissionRun.line("Set sail!"))
    _add_port_buttons(scene, port)
    _port_scenes[player] = scene
    _show(player, scene, port)


func _resume_all() -> void:
    _all_paused = false
    for i in range(players):
        _views[i].show_hud(not _busy[i])
    _update_targets()


## Show a scene in the half of the player.
func _show(player: int, scene: Dictionary, port: Port) -> void:
    _busy[player] = true
    _scene_steps[player] = _run.step()
    _helms[player].speed = 0.0
    _cards[player].present(scene, _run, port)
    _cards[player].get_meta("cursor").visible = true
    _views[player].show_hud(false)


func _show_opening(player: int) -> void:
    _run.active = player
    var step := _run.step()
    if step == null:
        return
    var opening: Variant = step.opening(_run)

    # NOTE (mristin):
    # A step may continue right where the crew is (e.g., the line-up found
    # the doctor in Dubrovnik, and the medicine is in Dubrovnik, too).
    var port: Port = _in_port[player]
    if opening == null and port != null:
        opening = step.arrive(_run, port)
    if opening != null:
        if step is CelebrationStep and step.sound != "":
            _sfx.play(step.sound)
        _show(player, opening, port)
    else:
        _resume(player)


func _resume(player: int) -> void:
    _busy[player] = false
    _in_port[player] = null
    _cards[player].visible = false
    _cards[player].get_meta("cursor").visible = false
    _views[player].show_hud(not _all_paused)
    _update_targets()


func _update_targets() -> void:
    var step := _run.step()
    var targets: Array[Port] = []
    if step != null:
        targets = step.target_ports(_run)
    _chart.targets = targets
    _chart.errand_ports = Errands.ports(_run)
    for view in _views:
        view.minimap.targets = targets
        view.minimap.errand_ports = _chart.errand_ports
        view.arrow.targets = targets


func _on_action(action: String, player: int) -> void:
    _run.active = player
    if _on_shop(action, player):
        return
    var step := _run.step()

    # NOTE (mristin):
    # With two players, the other crew may have moved the story on while this
    # scene was open; its answers then only close it.
    if step != _scene_steps[player]:
        _resume(player)
        return
    var next: Variant = null
    if step != null and action != "leave":
        next = step.act(_run, action)
    if next != null:
        _show(player, next, _in_port[player])
        return
    _run.advance()
    if _run.is_done():
        return
    # NOTE (mristin):
    # The targets change in the port (a task done, the target fled), so that
    # the chart (C) shows them already there, not only at sea.
    _update_targets()
    _show_opening(player)


## The actions of the merchant's stall; return whether it was one of them.
func _on_shop(action: String, player: int) -> bool:
    var port: Port = _in_port[player]
    if action == "shop":
        _show(player, _shop_scene(player, MissionRun.line("What would you like, captain?")), port)
        return true
    if action.begins_with("buy:"):
        var booster: Booster = _stalls[player][int(action.get_slice(":", 1))]
        var bought := false
        if booster.decoration != null and player < _crew.captains.size():
            var captain: Dictionary = _crew.captains[player]
            bought = Merchant.buy_decoration(booster, _run, _session, captain)
            _helms[player].boat.decorations = World.boat_decorations(captain)
        elif booster.decoration == null:
            bought = _run.bag.buy(booster)
        if bought:
            _sfx.play("coins")
        var thanks := MissionRun.line(
            "A fine choice, captain! {booster} is yours.", {"booster": booster.name}
        )
        _show(player, _shop_scene(player, thanks), port)
        return true
    if action == "close_shop":
        _show(player, _port_scenes[player], port)
        return true
    return _on_errand(action, player)


## The actions of the errands of the port; return whether it was one of them.
func _on_errand(action: String, player: int) -> bool:
    var port: Port = _in_port[player]
    if action == "errand":
        var offer := Errands.offer(port, _run.rng)
        _offers[player] = offer
        _show(player, Errands.ask_scene(offer, _port_scenes[player].get("person")), port)
        return true
    if action == "errand_yes":
        var offer: Dictionary = _offers[player]
        _run.hold(player).cargo.append(offer["item"])
        _run.errands.append(offer)
        if _tips.wants("errand"):
            _tips.show_tip(player, "errand")
        var buttons: Array = _port_scenes[player]["buttons"]
        _port_scenes[player]["buttons"] = buttons.filter(
            func(entry: Dictionary) -> bool: return entry["action"] != "errand"
        )
        _update_targets()
        _show(player, _port_scenes[player], port)
        return true
    if action == "bay":
        var bay := World.port(port.bay_port_id)
        _helms[player].heading = (World.port_km(bay) - World.port_km(port)).angle() + PI / 2
        _arrive(player, bay)
        return true
    return false


## The merchant's stall in the port of the player (see Merchant).
func _shop_scene(player: int, said: Dictionary) -> Dictionary:
    var person: Person = _port_scenes[player].get("person")
    _run.active = player
    _stalls[player] = _stalls[player].filter(
        func(booster: Booster) -> bool: return Merchant.offers(booster, _run)
    )
    return Merchant.scene(person, said, _stalls[player], _run, _session)


## The boat of the player enters the port; [param first] are the lines to say
## before the scene of the port (e.g., that the boat was towed there).
func _arrive(player: int, port: Port, first: Array = []) -> void:
    _entry_headings[player] = _helms[player].heading
    _run.active = player
    _in_port[player] = port
    _left[player] = port
    _warned_low[player] = false
    _stalls[player] = Merchant.draw_stall(port, _session.owned, _run.rng)
    _run.pass_days(MissionRun.PORT_DAYS)
    var hold := _run.hold(player)
    var hungry := _run.provisions_share(player) < ProvisionsPanel.LOW
    hold.add_ration(_run.ration_days())
    _run.bag.end_leg()
    var damaged := hold.damage > 0.0
    _run.pass_days(hold.repair())
    var paid := Errands.deliver(_run, port)
    var ducats_before := hold.ducats
    for view in _views:
        view.minimap.visited[port.id] = true
    _launch(port, player)

    var step := _run.step()
    var scene: Variant = step.arrive(_run, port)
    if scene == null:
        var local: Person = port.locals[0] if not port.locals.is_empty() else null
        var said: Array = [MissionRun.line("This is the wrong port, captain!"), _run.clue]
        var wanted := step.wanted_item(_run, port)
        if wanted != null and players > 1:
            said = [
                MissionRun.line(
                    "Your other boat carries {item}. Meet at sea and hand it over!",
                    {"item": wanted.name}
                )
            ]
        scene = MissionStep.talk(local, said, MissionRun.line("Goodbye!"))
    if scene["kind"] == "talk":
        var lines: Array = first.duplicate()
        lines.append_array(paid)
        lines.append_array(scene["lines"])
        if hold.ducats > ducats_before or not paid.is_empty():
            _sfx.play("coins")
        if hold.ducats > ducats_before:
            lines.append(
                MissionRun.line(
                    "You got {ducats} {ducats|ducat|ducats}!",
                    {"ducats": hold.ducats - ducats_before}
                )
            )
        if hungry:
            lines.append(MissionRun.line("Your crew takes on bread and fresh water."))
        if damaged:
            lines.append(MissionRun.line("The shipwrights repair your hull."))
        if _tips.wants("port"):
            lines.append(MissionRun.line("Every port has a merchant and work for the crew."))
        scene["lines"] = lines

        _add_port_buttons(scene, port)
        _port_scenes[player] = scene
    else:
        # NOTE (mristin):
        # A line-up has no room for the thanks, so they show as messages.
        for thanks in paid:
            _say(_run.say(thanks, player), player)
        if not paid.is_empty():
            _sfx.play("coins")
    _update_targets()
    _show(player, scene, port)
    _save_progress()


## Every port has a merchant (see DESIGN.md, section 10) and work for the
## crew (see Errands).
func _add_port_buttons(scene: Dictionary, port: Port) -> void:
    scene["buttons"].append({"label": MissionRun.line("What do you sell?"), "action": "shop"})
    if Errands.can_take(_run):
        scene["buttons"].append({"label": MissionRun.line("Any work for us?"), "action": "errand"})
    if port.bay_port_id != "":
        var bay := World.port(port.bay_port_id)
        var label := MissionRun.line("Sail on to {port}!", {"port": bay.name})
        scene["buttons"].append({"label": label, "action": "bay"})


## Out of food and water, or with a broken hull: a fishing boat comes and
## tows the boat to the nearest port, slowly, around the islands, while the
## crew watches (see Tow); it costs time (see DESIGN.md, "Provisions").
## [param started] is told at once, [param reason] in the port.
func _tow(player: int, started: Dictionary, reason: Dictionary) -> void:
    var helm := _helms[player]
    var found := Tow.nearest_by_sea(helm.km, ENTER_KM - 0.5, Tow.avoid(_chart, _hazards))
    var nearest: Port = found["port"]
    var path: PackedVector2Array = found["path"]
    reason["args"] = {"port": nearest.name}
    started["args"] = {"port": nearest.name}
    _run.pass_days(TOW_DAYS)
    if path.size() < 2:
        # NOTE (mristin):
        # No way at sea (it should not happen): the boat is in the port at once.
        _run.pass_days(World.port_km(nearest).distance_to(helm.km) * TOW_SLOWER / KM_PER_DAY)
        _arrive(player, nearest, [reason])
        return
    helm.towed = true
    helm.speed = 0.0
    helm.steer = 0.0
    _tows[player] = Tow.new(path, nearest, reason, _chart.get_parent())
    _say(_run.say(started, player), player)


## The fishermen pull the boat a bit; at the end of the way, it enters the
## port. Return how far it went, in kilometres.
func _tow_step(helm: Helm, delta: float) -> float:
    var tow: Tow = _tows[helm.player]
    tow.look_out(delta, _chart, _hazards, ENTER_KM - 0.5)
    var speed := Helm.BASE_KM_PER_SECOND * _mission.sea.speed_scale * TOW_SHARE
    var moved := tow.pull(helm, delta, speed)
    if tow.is_done():
        _tows[helm.player] = null
        helm.towed = false
        tow.finish()
        _arrive(helm.player, tow.port, [tow.reason])
    return moved


func _on_rewarded(ducats: int) -> void:
    _sfx.play("coins")
    var text := tr("+{ducats} {ducats|ducat|ducats} for the task done!")
    _say(Grammar.format(text, {"ducats": ducats}), _run.active)


func _on_finished(stars: int) -> void:
    _stars = stars
    # The yataks give what they collected, once (see Session.yatak_gift).
    var gift: int = _session.yatak_gift(_mission.id) if record_result else 0
    _run.holds[0].ducats += gift
    _all_paused = true
    for i in range(players):
        _cards[i].visible = false
        _cards[i].get_meta("cursor").visible = false
    var complete := MissionComplete.new()
    complete.mission = _mission
    complete.run = _run
    complete.stars = stars
    complete.ducats = _run.ducats_total() - _run.brought - gift
    complete.gift = gift
    complete.finished.connect(_leave)
    _overlay.add_child(complete)
    _overlay.move_child(_shared_cursor, -1)
    _shared_cursor.visible = true


func _leave() -> void:
    if record_result:
        _session.complete(_mission.id, _stars, _run.ducats_total())
    if next_scene == "":
        get_tree().reload_current_scene()
    else:
        get_tree().change_scene_to_file(next_scene)


# endregion

# region Meeting at sea


func _check_meeting() -> void:
    if players < 2 or _busy[0] or _busy[1]:
        return
    var distance := _helms[0].km.distance_to(_helms[1].km)
    if distance > PART_KM:
        _met = false
    if _met or distance > MEET_KM:
        return
    _met = true
    _all_paused = true
    for view in _views:
        view.show_hud(false)
    _exchange = ExchangeCard.new()
    _exchange.run = _run
    var names: Array[String] = []
    for i in range(players):
        var name := str(_crew.captains[i].get("name", "")) if i < _crew.captains.size() else ""
        names.append(name if name != "" else tr("Player {number}").format({"number": i + 1}))
    _exchange.names = names
    _exchange.action_chosen.connect(_on_exchange)
    _overlay.add_child(_exchange)
    _exchange.refresh()
    _overlay.move_child(_shared_cursor, -1)
    _shared_cursor.visible = true


func _on_exchange(action: String) -> void:
    if action == "close":
        _exchange.queue_free()
        _exchange = null
        _shared_cursor.visible = false
        _resume_all()
        return
    ExchangeCard.hand_over(_run, action)
    _exchange.refresh()


# endregion

# region Sailing


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_C or (event.keycode == KEY_ESCAPE and _full_chart != null):
        get_viewport().set_input_as_handled()
        _toggle_chart()
    elif event.keycode == KEY_ESCAPE and _leave_dialog == null:
        get_viewport().set_input_as_handled()
        _ask_to_leave()


## C shows the chart of the whole Adriatic, so that the crew gets its
## bearings (see FullChart); the game waits meanwhile.
func _toggle_chart() -> void:
    if _full_chart != null:
        _all_paused = _full_chart.close()
        _full_chart = null
    elif _leave_dialog == null:
        _full_chart = FullChart.open(_overlay, _views[0].minimap, _all_paused)
        _all_paused = true


## Esc asks first, so that a child does not leave the mission by accident; the
## game waits meanwhile.
func _ask_to_leave() -> void:
    _paused_before = _all_paused
    _all_paused = true
    _leave_dialog = ConfirmDialog.new()
    _leave_dialog.question = tr("Leave the mission? It is saved, and you can continue later.")
    _leave_dialog.yes_text = tr("Yes, leave")
    _leave_dialog.no_text = tr("No, sail on")
    _leave_dialog.confirmed.connect(_leave_now)
    _leave_dialog.cancelled.connect(_stay)
    _overlay.add_child(_leave_dialog)
    _overlay.move_child(_shared_cursor, -1)
    _shared_cursor.visible = true


func _stay() -> void:
    _leave_dialog = null
    _all_paused = _paused_before
    _shared_cursor.visible = _shared_card.visible or _exchange != null


func _leave_now() -> void:
    _save_progress()
    if next_scene == "":
        get_tree().quit()
    else:
        get_tree().change_scene_to_file(next_scene)


## The steering of a player (the soak test wanders instead, see Helm.read_steer).
func _steer_of(player: int, poses: Array) -> float:
    return Helm.read_steer(player, poses)


## Show a message to the player (or, with -1, to everybody).
func _say(text: String, player: int) -> void:
    for view in _views:
        if player < 0 or view.player == player or players == 1:
            view.toast.show_text(text)


func _process(delta: float) -> void:
    var poses: Array = _pose.GetPlayers()
    for helm in _helms:
        helm.steer = 0.0 if helm.towed else _steer_of(helm.player, poses)
        _wheel.steers[helm.player] = helm.steer
    # NOTE (mristin):
    # The webcam steps aside while nobody sails (a scene fills the screen).
    _wheel.visible = not _all_paused and _busy.has(false)
    if _all_paused:
        return

    var sailing: Array[Helm] = []
    var towed: Array[Helm] = []
    for helm in _helms:
        if _busy[helm.player]:
            continue
        if helm.towed:
            towed.append(helm)
        else:
            sailing.append(helm)
    if sailing.is_empty() and towed.is_empty():
        return

    _wind.update(delta)
    if not sailing.is_empty():
        _hazards.update(delta, sailing, _chart.targets)
    var together := players > 1 and _helms[0].km.distance_to(_helms[1].km) < TOGETHER_KM
    var boost := TOGETHER_BOOST if together else 1.0
    if _run.bag.has_effect("speed"):
        boost *= NEW_SAILS
    _wind.warning_seconds = (
        SeaWind.FISHERMAN_SECONDS if _run.bag.has_effect("weather") else SeaWind.WARNING_SECONDS
    )

    for helm in _helms:
        helm.fit(_run.hold(helm.player).ship, _run.bag)

    var sailed := 0.0
    var tow_km := 0.0
    for helm in towed:
        tow_km = maxf(tow_km, _tow_step(helm, delta))
    for helm in sailing:
        var factor := _hazards.speed_factor(helm.km)
        _views[helm.player].shade.amount = 1.0 if factor < 1.0 else 0.0
        helm.heading += _hazards.gust(helm.km, delta)
        sailed = maxf(
            sailed, helm.sail(delta, _wind, _chart, _mission.sea.speed_scale, boost * factor)
        )
        _check_damage(helm, delta)

    # NOTE (mristin):
    # The clock runs while a boat is at sea, as fast as the boat which sails
    # the farthest; a towed boat is slower, and its days run slower, too.
    _run.pass_days(maxf(sailed / KM_PER_DAY, tow_km * TOW_SLOWER / KM_PER_DAY))
    for helm in sailing:
        _tips.check(helm, delta, _run, _chart, _hazards, _wind)
    var marks := _hazards.marks()
    _update_rival(delta, marks)
    for view in _views:
        view.minimap.marks = marks
    _rope.visible = together
    if together:
        _rope.points = PackedVector2Array([_helms[0].boat.position, _helms[1].boat.position])
    _place_boats(false, delta)

    for helm in sailing:
        if _busy[helm.player] or helm.towed:
            continue
        var hold := _run.hold(helm.player)
        if hold.is_out_of_provisions():
            _tow(
                helm.player,
                MissionRun.line("Out of food and water! Fishermen tow you to {port}."),
                MissionRun.line("Out of food and water! A fishing boat towed you to {port}.")
            )
        elif hold.is_wrecked():
            _tow(
                helm.player,
                MissionRun.line("The hull is broken! Fishermen tow you to {port}."),
                MissionRun.line("The hull is broken! A fishing boat towed you to {port}.")
            )
        else:
            _warn_low(helm.player)
            _check_ports(helm)
    if towed.is_empty():
        _check_meeting()


## Tell the crew once per leg when the food runs low (the panel blinks, too).
func _warn_low(player: int) -> void:
    if _warned_low[player] or _run.provisions_share(player) >= ProvisionsPanel.LOW:
        return
    _warned_low[player] = true
    _say(tr("Running low! Stop in a port!"), player)


## The rival of a trail (e.g., the recruiter of mission 2) sails, shows on the
## minimap, and may make the trail longer.
func _update_rival(delta: float, marks: Array[Dictionary]) -> void:
    var trail := _run.step() as TrailStep
    if trail == null or not trail.rival:
        return
    var speed := Helm.BASE_KM_PER_SECOND * _mission.sea.speed_scale
    var first := Rival.update(_run, trail, delta, speed)
    if first != null:
        _say(Grammar.format(tr(trail.rival_line), {"port": first.name}), -1)
        _update_targets()
    var at: Variant = Rival.position(_run, trail)
    if at != null:
        marks.append({"km": at, "kind": "rival", "radius": 0.0})


## The reefs and the cliffs damage the hull (see DESIGN.md, "Reefs and
## cliffs"); the rest of the coast never does.
func _check_damage(helm: Helm, delta: float) -> void:
    helm.bump_cooldown = maxf(0.0, helm.bump_cooldown - delta)
    if helm.bump_cooldown > 0.0 or _run.bag.has_effect("pilot"):
        return
    var hold := _run.hold(helm.player)
    if _chart.is_reef(helm.km):
        var share := clampf(helm.speed / Helm.BASE_KM_PER_SECOND, 0.4, 1.0)
        hold.add_damage(REEF_DAMAGE * share)
        helm.speed *= 0.3
        helm.bump_cooldown = 2.5
        _say(tr("Crash! A reef! The hull is damaged."), helm.player)
        _sfx.play("crash")
    elif helm.hit_land != Vector2.INF and _chart.is_cliff(helm.hit_land):
        hold.add_damage(CLIFF_DAMAGE)
        helm.bump_cooldown = 2.0
        _say(tr("Crash! The cliffs! The hull is damaged."), helm.player)
        _sfx.play("crash")


func _place_boats(snap: bool, delta := 0.0) -> void:
    var boats: Array[Dictionary] = []
    for helm in _helms:
        helm.place(_wind)
        boats.append({"km": helm.km, "heading": helm.heading, "color": COLORS[helm.player]})
    for view in _views:
        view.minimap.boats = boats
        view.rose.heading = _helms[view.player].heading
        view.follow(_helms[view.player], _chart, snap, delta)
    for helm in _helms:
        if _tows[helm.player] != null:
            _tows[helm.player].place(helm)
    # NOTE (mristin):
    # The shared chart keeps its size in the view which zoomed in the most.
    _chart.marker_scale = 1.0 / _views.map(func(view): return view.zoom).max()


func _check_ports(helm: Helm) -> void:
    var left: Port = _left[helm.player]
    if left != null and helm.km.distance_to(World.port_km(left)) > LEAVE_KM:
        _left[helm.player] = null
    for port in World.ports():
        if port == _left[helm.player]:
            continue
        if helm.km.distance_to(World.port_km(port)) < ENTER_KM:
            _arrive(helm.player, port)
            return

# endregion
