class_name NameKeyboard
extends Control

## Let a player type the name of their captain: with the hand cursor on the
## keys of the alphabet of the game's language, or on the keyboard.
##
## The keyboard fills the whole area it gets, with keys as big as possible, so
## that the players hit them easily with the hand cursor. The keys are
## octagons with gaps between them: a hand between two keys presses neither.
##
## The name starts with a capital letter and goes on in small letters, so the
## players only pick the letters. It has 1 to [member max_length] characters.
##
## The keyboard starts with a default name (e.g., "Liso", or the date and the
## time for a voyage). While the default is untouched, the first letter
## replaces it as a whole, and Delete clears it as a whole.
##
## The keyboard also serves other names, e.g., of the voyage, with digits and
## a space (see [member extra_keys] and [member with_space]).

## The player is done; the name is final.
signal finished(name: String)

## The gap between the keys, relative to the size of a key.
const _GAP := 0.22

## The longest name.
var max_length := CaptainOptions.MAX_NAME_LENGTH

## Keys besides the letters of the alphabet, e.g., digits.
var extra_keys := ""

## Whether to offer a key for the space.
var with_space := false

var _name := ""

## Whether the name is still the untouched default.
var _pristine := false

var _display: HandButton


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE


## Lay out the keys to fill the current size, as big as possible.
func build() -> void:
    for child in get_children():
        child.queue_free()

    var alphabet: String = get_node("/root/Languages").alphabet() + extra_keys
    var letters := alphabet.length()

    # NOTE (mristin):
    # Besides the rows of letters, we need a row for the name on top and a
    # row for Delete and OK at the bottom, each about a key and a half high.
    var best_key := 0.0
    var best_columns := 6
    for columns in range(5, 13):
        var rows := ceili(float(letters) / columns)
        var by_width := size.x / (columns + (columns - 1) * _GAP)
        var by_height := size.y / (rows + (rows - 1) * _GAP + 3.4)
        var key := minf(by_width, by_height)
        if key > best_key:
            best_key = key
            best_columns = columns

    var key_size := Vector2(best_key, best_key)
    var gap := best_key * _GAP

    var layout := VBoxContainer.new()
    layout.set_anchors_preset(Control.PRESET_FULL_RECT)
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", int(gap))
    add_child(layout)

    _display = HandButton.new()
    _display.custom_minimum_size = Vector2(minf(size.x, best_key * 9), best_key * 1.3)
    _display.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _display.title_size = int(best_key * 0.8)
    layout.add_child(_display)

    var grid := GridContainer.new()
    grid.columns = best_columns
    grid.add_theme_constant_override("h_separation", int(gap))
    grid.add_theme_constant_override("v_separation", int(gap))
    grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    layout.add_child(grid)

    for letter in alphabet:
        var key := HandButton.new()
        key.octagon = true
        key.custom_minimum_size = key_size
        key.title = letter
        key.title_size = int(best_key * 0.55)
        key.pressed.connect(_type.bind(letter))
        grid.add_child(key)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", int(gap * 2.0))
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_child(actions)
    var entries := [[tr("Delete"), _delete], [tr("OK"), _finish]]
    if with_space:
        entries.insert(1, [tr("Space"), _type.bind(" ")])
    for entry in entries:
        var button := HandButton.new()
        button.octagon = true
        button.custom_minimum_size = Vector2(best_key * 2.8, best_key * 1.1)
        button.text = entry[0]
        button.text_size = int(best_key * 0.42)
        button.pressed.connect(entry[1])
        actions.add_child(button)

    _show()


## Start typing a new name; the old one stays until the first letter, which
## replaces it.
func start(old_name: String) -> void:
    _name = old_name
    _pristine = old_name != ""
    build()


## The name as typed so far.
func typed_name() -> String:
    return _name


func _unhandled_input(event: InputEvent) -> void:
    if not is_visible_in_tree():
        return
    if not (event is InputEventKey and event.pressed):
        return
    match event.keycode:
        KEY_BACKSPACE:
            _delete()
        KEY_ENTER, KEY_KP_ENTER:
            _finish()
        _:
            if event.unicode <= 0:
                return
            var letter := char(event.unicode)
            var is_letter := letter.to_upper() != letter.to_lower()
            var allowed := is_letter or letter in extra_keys or (with_space and letter == " ")
            if not allowed:
                return
            _type(letter.to_upper())
    get_viewport().set_input_as_handled()


func _type(letter: String) -> void:
    if _pristine:
        _pristine = false
        _name = ""
    if _name.length() >= max_length:
        return
    if letter == " " and (_name == "" or _name.ends_with(" ")):
        return
    _name += letter if _name == "" else letter.to_lower()
    _show()


func _delete() -> void:
    if _pristine:
        _pristine = false
        _name = ""
    _name = _name.substr(0, maxi(0, _name.length() - 1))
    _show()


func _finish() -> void:
    if _name.strip_edges() == "":
        return
    finished.emit(_name.strip_edges())


func _show() -> void:
    if _display != null:
        _display.title = _name if _name != "" else "…"
