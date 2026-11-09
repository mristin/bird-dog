extends Control

## Show the screen at the end of every mission, in isolation: the left and the
## right arrow keys flip through the missions, the up and the down arrow keys
## change the stars, and the button starts the screen over.

## The number of the mission to show first.
@export var number := 1

## The stars to show.
@export_range(1, 3) var stars := 3

var _complete: MissionComplete


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var cursor := HandCursor.new()
    add_child(cursor)
    _show()


func _show() -> void:
    if _complete != null:
        _complete.free()
    var missions := MissionCatalog.all()
    number = wrapi(number, 1, missions.size() + 1)
    var mission: Mission = missions[number - 1]
    var run := MissionRun.new(mission, 1)
    run.pass_days(mission.clock_days * 0.45)
    _complete = MissionComplete.new()
    _complete.mission = mission
    _complete.run = run
    _complete.stars = stars
    _complete.finished.connect(_show)
    add_child(_complete)
    move_child(_complete, 0)


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed):
        return
    match event.keycode:
        KEY_RIGHT:
            number += 1
            _show()
        KEY_LEFT:
            number -= 1
            _show()
        KEY_UP:
            stars = mini(3, stars + 1)
            _show()
        KEY_DOWN:
            stars = maxi(1, stars - 1)
            _show()
        KEY_ESCAPE:
            get_tree().quit()
