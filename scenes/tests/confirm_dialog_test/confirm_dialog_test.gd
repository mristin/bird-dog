extends MenuScreen

## Try the dialog which asks before something can not be undone. "Ask" opens it;
## while it is open, the "Behind" button must not react. The last answer shows
## at the top; Esc answers "no" in the dialog, and quits otherwise.

var _answer := "-"
var _behind_presses := 0


func _build() -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 80)
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.position = Vector2(0, 760)
    row.size = Vector2(1920, 150)
    add_child(row)

    var ask := HandButton.new()
    ask.custom_minimum_size = Vector2(400, 140)
    ask.text = "Ask"
    ask.text_size = 44
    ask.pressed.connect(_ask)
    row.add_child(ask)

    var behind := HandButton.new()
    behind.custom_minimum_size = Vector2(400, 140)
    behind.text = "Behind"
    behind.text_size = 44
    behind.pressed.connect(func(): _behind_presses += 1)
    row.add_child(behind)


func _ask() -> void:
    var dialog := ConfirmDialog.ask(
        self, 'Delete the voyage "Test"? This can not be undone.', "Yes, delete", "No, keep it"
    )
    dialog.confirmed.connect(func(): _answer = "yes")
    dialog.cancelled.connect(func(): _answer = "no")


func _draw_screen() -> void:
    var text := (
        "Dialog test   answer: %s   presses behind: %d   (Esc: quit)" % [_answer, _behind_presses]
    )
    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, 110),
        text,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        40,
        Paper.INK
    )
