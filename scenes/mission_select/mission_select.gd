extends MenuScreen

## Let the crew choose a mission (see DESIGN.md, "The mission select").
##
## Every mission is a card with its stars; the first mission is open, and every
## finished mission opens the next one. Below the missions, the crew can watch
## the instruction again or go back to the voyages.
##
## For now, a mission card opens the mission's placeholder screen, since the
## missions themselves are still to be built. Later, a chart of the Adriatic
## with a pin for each mission replaces the grid of cards.

## The screen of a playable mission.
@export_file("*.tscn") var mission_scene := "res://scenes/mission/mission.tscn"

## The placeholder of a mission which is still being built.
@export_file("*.tscn") var placeholder_scene := "res://scenes/mission/mission_placeholder.tscn"

## The instruction, to watch it again.
@export_file("*.tscn") var instruction_scene := "res://scenes/instruction/instruction.tscn"

## Master Ivan's shipyard (after mission 2).
@export_file("*.tscn") var shipyard_scene := "res://scenes/shipyard/shipyard.tscn"

## The voyages, to switch to another one.
@export_file("*.tscn") var voyages_scene := "res://scenes/session_select/session_select.tscn"

var _busy := false

@onready var _session: Node = get_node("/root/Session")
@onready var _crew: Node = get_node("/root/Crew")


func _build() -> void:
    # NOTE (mristin):
    # Fifteen missions: five columns of three cards.
    var grid := GridContainer.new()
    grid.columns = 5
    grid.add_theme_constant_override("h_separation", 22)
    grid.add_theme_constant_override("v_separation", 22)
    var card_size := MissionCard.SIZE
    grid.position = Vector2((1920 - (5 * card_size.x + 4 * 22)) * 0.5, 195)
    add_child(grid)

    for mission in MissionCatalog.all():
        var card := MissionCard.new()
        card.custom_minimum_size = card_size
        card.number = mission.number
        card.title_text = tr(mission.title)
        card.locked = not _session.is_unlocked(mission)
        card.stars = _session.stars(mission.id)
        card.pressed.connect(_choose.bind(mission, card))
        grid.add_child(card)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 60)
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    actions.position = Vector2(0, 900)
    actions.size = Vector2(1920, 110)
    add_child(actions)
    _add_boats()

    var entries := [[tr("How to steer"), instruction_scene], [tr("Voyages"), voyages_scene]]
    if _session.has_shipyard():
        entries.insert(1, [tr("Ivan's shipyard"), shipyard_scene])
    for entry in entries:
        var button := HandButton.new()
        button.custom_minimum_size = Vector2(380, 100)
        button.text = entry[0]
        button.text_size = 36
        button.pressed.connect(_go.bind(entry[1]))
        actions.add_child(button)


## The crew's boats, wearing their decorations from Master Ivan's shipyard,
## sail next to the chest (see DESIGN.md, section 10).
func _add_boats() -> void:
    var colors: Array[Color] = [Color(0.7, 0.12, 0.1), Color(0.12, 0.32, 0.65)]
    for i in range(_crew.players):
        var boat := SeaBoat.new()
        boat.position = Vector2(1340 + i * 130, 110)
        boat.heading = PI * 0.5
        boat.scale = Vector2.ONE * 0.75
        boat.speed_share = 0.6
        boat.color = colors[i]
        if i < _crew.captains.size():
            boat.decorations = World.boat_decorations(_crew.captains[i])
            boat.initial = str(_crew.captains[i].get("name", "")).left(1).to_upper()
        add_child(boat)


func _choose(mission: Mission, card: MissionCard) -> void:
    if _busy or card.locked:
        return
    _session.current_mission = mission.id
    _session.resume_mission = false
    if _session.progress_of() == mission.id and _session.progress_fits(_crew.players):
        var dialog := ConfirmDialog.ask(
            self,
            tr("Continue the mission where you left off?"),
            tr("Yes, continue"),
            tr("No, start anew")
        )
        dialog.confirmed.connect(_start_mission.bind(true))
        dialog.cancelled.connect(_start_mission.bind(false))
        return
    _go(mission_scene if mission.is_playable() else placeholder_scene)


func _start_mission(resume: bool) -> void:
    _session.resume_mission = resume
    if not resume:
        _session.mission_in_progress = {}
    _go(mission_scene)


func _go(scene: String) -> void:
    if _busy:
        return
    _busy = true
    next_scene = scene
    go_next(0.4)


func _draw_screen() -> void:
    var font := ThemeDB.fallback_font
    draw_string(
        font,
        Vector2(0, 130),
        tr("Choose a mission"),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        60,
        Paper.RED
    )
    var names: Array[String] = []
    for captain in _crew.captains:
        names.append(captain["name"])
    var crew_text := "%s  ·  %s" % [_session.voyage_name, " & ".join(PackedStringArray(names))]
    draw_string(font, Vector2(70, 80), crew_text, HORIZONTAL_ALIGNMENT_LEFT, 900, 28, Paper.INK)
    Chest.draw(self, Vector2(1640, 150), int(_session.ducats))
