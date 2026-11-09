extends SceneTree
## Check the building blocks of the menus headless: the keyboard of the names
## (the default name, Delete, the longest name, the typed letters) and the hit
## area of the octagon keys (a hand between two keys presses neither).

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if condition:
        print("PASS ", message)
    else:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _keyboard(default_name: String) -> NameKeyboard:
    var keyboard := NameKeyboard.new()
    keyboard.size = Vector2(1700, 880)
    root.add_child(keyboard)
    keyboard.start(default_name)
    return keyboard


func _run() -> void:
    var keyboard := _keyboard("Liso")
    _check(keyboard.typed_name() == "Liso", "the keyboard starts with the default name")
    keyboard._type("M")
    keyboard._type("A")
    _check(keyboard.typed_name() == "Ma", "the first letter replaces the default name")
    keyboard._delete()
    _check(keyboard.typed_name() == "M", "Delete removes the last letter")

    keyboard.start("2026-11-07 13:41")
    keyboard._delete()
    _check(keyboard.typed_name() == "", "Delete clears an untouched default as a whole")

    keyboard.start("")
    keyboard.max_length = 3
    for letter in ["A", "B", "C", "D"]:
        keyboard._type(letter)
    _check(keyboard.typed_name() == "Abc", "the name keeps to its longest length")

    keyboard.max_length = 24
    keyboard.with_space = true
    keyboard.start("")
    keyboard._type(" ")
    keyboard._type("A")
    keyboard._type(" ")
    keyboard._type(" ")
    keyboard._type("B")
    _check(keyboard.typed_name() == "A b", "the spaces never lead or double")

    var finished := []
    keyboard.finished.connect(func(typed: String): finished.append(typed))
    keyboard.start("")
    keyboard._finish()
    _check(finished.is_empty(), "an empty name does not finish")
    keyboard._type("X")
    keyboard._finish()
    _check(finished == ["X"], "OK finishes with the typed name")
    keyboard.free()

    var key := HandButton.new()
    key.octagon = true
    key.position = Vector2(100, 100)
    key.size = Vector2(100, 100)
    root.add_child(key)
    _check(key.contains(Vector2(150, 150)), "the middle of an octagon key counts")
    _check(not key.contains(Vector2(102, 102)), "the corner of an octagon key does not count")
    _check(not key.contains(Vector2(250, 150)), "a point beside the key does not count")
    key.octagon = false
    _check(key.contains(Vector2(102, 102)), "the corner of a rectangular button counts")

    var dialog := ConfirmDialog.new()
    dialog.question = "Really?"
    dialog.yes_text = "Yes"
    dialog.no_text = "No"
    root.add_child(dialog)
    _check(key.is_blocked(), "an open dialog keeps the buttons behind it quiet")
    var inside: HandButton = null
    for button in dialog.find_children("*", "HandButton", true, false):
        inside = button
    _check(inside != null and not inside.is_blocked(), "the buttons of the dialog work")
    var answers := []
    dialog.cancelled.connect(func(): answers.append("no"))
    dialog._cancel()
    _check(answers == ["no"], "No answers the dialog")
    dialog.free()
    _check(not key.is_blocked(), "without the dialog, the buttons work again")
    key.free()

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)
