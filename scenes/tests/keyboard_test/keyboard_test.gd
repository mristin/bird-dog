extends MenuScreen

## Try the keyboard of the captain's name on its own, with the hand cursor.
##
## The keyboard fills the area of a single player (or, with [member narrow],
## the half of the screen of a player in a game with two players). OK shows the
## typed name above the keyboard and starts over; Esc quits.

## Lay the keyboard out for a player of a game with two players.
@export var narrow := false

var _keyboard: NameKeyboard
var _last_name := ""


func _build() -> void:
    _keyboard = NameKeyboard.new()
    if narrow:
        _keyboard.position = Vector2(70, 190)
        _keyboard.size = Vector2(850, 850)
    else:
        _keyboard.position = Vector2(110, 150)
        _keyboard.size = Vector2(1700, 880)
    _keyboard.finished.connect(_on_finished)
    add_child(_keyboard)
    _keyboard.start("")


func _on_finished(typed_name: String) -> void:
    _last_name = typed_name
    print("Typed: ", typed_name)
    _keyboard.start("")


func _draw_screen() -> void:
    var text := "Keyboard test   (Esc: quit)"
    if _last_name != "":
        text = "Typed: %s   (Esc: quit)" % _last_name
    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, 110),
        text,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        40,
        Paper.INK
    )
