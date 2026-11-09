class_name ConfirmDialog
extends Control

## Ask the players a yes-or-no question before something which can not be
## undone, e.g., deleting a voyage.
##
## The dialog dims the screen and shows the question with two big buttons.
## While it is open, it is modal: the HandButtons behind it do not react, so
## that a hand which rests somewhere else presses nothing. Esc answers "no",
## Enter "yes".

## The players answered "yes".
signal confirmed

## The players answered "no" (or pressed Esc).
signal cancelled

## The group of the open dialogs; the HandButtons outside of them stay quiet.
const GROUP := "modal_dialog"

var question := ""
var yes_text := ""
var no_text := ""

var _answered := false


## Create a dialog on the menu screen and show it on top, under the cursor.
static func ask(
    screen: MenuScreen, question_text: String, yes: String, no: String
) -> ConfirmDialog:
    var dialog := ConfirmDialog.new()
    dialog.question = question_text
    dialog.yes_text = yes
    dialog.no_text = no
    screen.add_child(dialog)
    screen.move_child(screen.cursor, screen.get_child_count() - 1)
    return dialog


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_to_group(GROUP)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 80)
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    actions.position = Vector2(0, 600)
    actions.size = Vector2(1920, 140)
    add_child(actions)

    for entry in [[yes_text, _confirm], [no_text, _cancel]]:
        var button := HandButton.new()
        button.custom_minimum_size = Vector2(440, 130)
        button.text = entry[0]
        button.text_size = 44
        button.pressed.connect(entry[1])
        actions.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    if event.keycode == KEY_ESCAPE:
        get_viewport().set_input_as_handled()
        _cancel()
    elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
        get_viewport().set_input_as_handled()
        _confirm()


## Ask whether to quit the game, so that Esc never quits it by accident; quit
## on "yes". On a screen without a hand cursor (e.g., the instruction), the
## dialog brings its own, so that the hands and the mouse can answer.
static func ask_to_quit(parent: Node) -> ConfirmDialog:
    var dialog := ConfirmDialog.new()
    dialog.question = parent.tr("Do you really want to quit the game?")
    dialog.yes_text = parent.tr("Yes, quit")
    dialog.no_text = parent.tr("No, stay")
    dialog.confirmed.connect(parent.get_tree().quit)
    # NOTE (mristin):
    # The own cursor enters the tree before the buttons of the dialog, so that
    # they find it, and then moves on top of them.
    var cursor: HandCursor = null
    if not parent is MenuScreen:
        cursor = HandCursor.new()
        dialog.add_child(cursor)
    parent.add_child(dialog)
    if cursor != null:
        dialog.move_child(cursor, -1)
    else:
        parent.move_child((parent as MenuScreen).cursor, -1)
    return dialog


func _confirm() -> void:
    if _answered:
        return
    _answered = true
    confirmed.emit()
    queue_free()


func _cancel() -> void:
    if _answered:
        return
    _answered = true
    cancelled.emit()
    queue_free()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
    var panel := Rect2(260, 260, 1400, 560)
    draw_rect(Rect2(panel.position + Vector2(10, 12), panel.size), Color(0, 0, 0, 0.25))
    draw_rect(panel, Paper.PAPER)
    draw_rect(panel, Paper.INK, false, 4.0)
    draw_rect(panel.grow(-14), Color(Paper.INK, 0.4), false, 2.0)
    draw_multiline_string(
        ThemeDB.fallback_font,
        Vector2(panel.position.x + 60, 400),
        question,
        HORIZONTAL_ALIGNMENT_CENTER,
        panel.size.x - 120,
        52,
        -1,
        Paper.INK
    )
