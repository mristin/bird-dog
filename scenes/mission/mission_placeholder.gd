extends MenuScreen

## Stand in for a mission until the missions are built: show its title and its
## summary, and let the crew go back, or (for testing) finish the mission with
## three stars, which unlocks the next one.

var _done := false

@onready var _session: Node = get_node("/root/Session")
@onready var _mission: Mission = MissionCatalog.by_id(get_node("/root/Session").current_mission)


func _build() -> void:
    if _mission == null:
        _mission = MissionCatalog.all()[0]
        _session.current_mission = _mission.id

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 60)
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    actions.position = Vector2(0, 760)
    actions.size = Vector2(1920, 120)
    add_child(actions)

    var back := HandButton.new()
    back.custom_minimum_size = Vector2(360, 110)
    back.text = tr("Back")
    back.text_size = 40
    back.pressed.connect(_back)
    actions.add_child(back)

    var finish := HandButton.new()
    finish.custom_minimum_size = Vector2(520, 110)
    finish.text = tr("Finish the mission (test)")
    finish.text_size = 34
    finish.pressed.connect(_finish)
    actions.add_child(finish)


func _back() -> void:
    if _done:
        return
    _done = true
    go_next(0.3)


func _finish() -> void:
    if _done:
        return
    _done = true
    _session.complete(_mission.id, 3)
    go_next(0.6)


func _draw_screen() -> void:
    var font := ThemeDB.fallback_font
    var title := "%d. %s" % [_mission.number, tr(_mission.title)]
    draw_string(font, Vector2(0, 220), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, 64, Paper.RED)
    draw_multiline_string(
        font,
        Vector2(260, 340),
        tr(_mission.summary),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 520,
        40,
        -1,
        Paper.INK
    )
    draw_string(
        font,
        Vector2(0, 620),
        tr("This mission is still being built."),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        34,
        Color(Paper.INK, 0.7)
    )
