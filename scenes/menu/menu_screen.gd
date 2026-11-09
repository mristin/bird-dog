class_name MenuScreen
extends Control

## The base of every menu screen (the dialogues): the paper, the hand cursor on
## top of everything, Esc to quit, and going on to the next screen.
##
## A screen extends this class and overrides:
##
## * [method _build] to add its HandButtons and other controls,
## * [method _draw_screen] to draw its titles and pictures on the paper.
##
## When the screen is done, it calls [method go_next]. If [member next_scene]
## is empty (as in the test screens of `scenes/tests/`), the screen starts over
## instead, so that it can be tried again and again in isolation.

## The scene to go to when this screen is done; empty to start over (for tests).
@export_file("*.tscn") var next_scene := ""

## The hand cursor of the screen, which the HandButtons find by its group.
var cursor: HandCursor

var _leaving := false


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    cursor = HandCursor.new()
    add_child(cursor)
    _build()

    # NOTE (mristin):
    # The cursor draws over everything which the screen added.
    move_child(cursor, get_child_count() - 1)


## Add the controls of the screen; called once from _ready.
func _build() -> void:
    pass


## Draw the titles and the pictures of the screen on the paper.
func _draw_screen() -> void:
    pass


func _draw() -> void:
    Paper.draw(self, size)
    _draw_screen()


func _process(_delta: float) -> void:
    queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        # NOTE (mristin):
        # An open dialog takes Esc as "no" instead; otherwise Esc asks before
        # it quits the game.
        if get_tree().get_nodes_in_group(ConfirmDialog.GROUP).is_empty():
            get_viewport().set_input_as_handled()
            ConfirmDialog.ask_to_quit(self)


## Go on to the next screen after a short pause (so that the players see their
## click), or start over if there is no next screen.
func go_next(pause := 0.6) -> void:
    if _leaving:
        return
    _leaving = true
    await get_tree().create_timer(pause).timeout
    if next_scene == "":
        get_tree().reload_current_scene()
    else:
        get_tree().change_scene_to_file(next_scene)
