extends MenuScreen

## Let the players create their captains (see DESIGN.md, "Creating a captain").
##
## With one player, one wide panel; with two players, two narrow panels, each on
## the half of the screen where that player kneels in the mirrored camera
## picture, so that every player creates their own captain with their own
## hands. When all the players are ready, the crew sets off.

## Start a new crew with this many players (for the test screens); 0 keeps the
## crew of the game.
@export_range(0, 2) var players := 0

var _panels: Array[CaptainPanel] = []
var _waiting := false

@onready var _crew: Node = get_node("/root/Crew")


func _build() -> void:
    if players > 0:
        _crew.start(players)

    var count: int = _crew.players
    for i in range(count):
        var panel := CaptainPanel.new()
        panel.player = i
        panel.looks = _crew.captains[i].duplicate()
        panel.wide = count == 1
        if count == 1:
            panel.position = Vector2(110, 150)
            panel.size = Vector2(1700, 880)
        else:
            panel.position = Vector2(70 + i * 930, 190)
            panel.size = Vector2(850, 850)
        panel.ready_changed.connect(_on_ready_changed)
        add_child(panel)
        _panels.append(panel)


func _all_ready() -> bool:
    for panel in _panels:
        if not panel.is_ready():
            return false
    return true


func _on_ready_changed(_is_ready: bool) -> void:
    if _waiting or not _all_ready():
        return
    _waiting = true
    for panel in _panels:
        panel.lock()
    for i in range(_panels.size()):
        _crew.captains[i] = _panels[i].looks.duplicate()
    get_node("/root/Session").save()
    await get_tree().create_timer(1.2).timeout
    go_next(0.0)


func _draw_screen() -> void:
    var font := ThemeDB.fallback_font
    var title := tr("Create your captain") if _panels.size() == 1 else tr("Create your captains")
    draw_string(font, Vector2(0, 115), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Paper.RED)

    if _panels.size() == 2:
        var x := size.x * 0.5
        draw_dashed_line(Vector2(x, 160), Vector2(x, 1030), Color(Paper.INK, 0.4), 3.0, 14.0)
        for i in range(2):
            var label := tr("Player {number}").format({"number": i + 1})
            draw_string(
                font,
                Vector2(70 + i * 930, 175),
                label,
                HORIZONTAL_ALIGNMENT_LEFT,
                850,
                30,
                Paper.INK
            )
