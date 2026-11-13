extends SceneTree
## The base of the end-to-end tests (see playthrough.gd): what they keep
## track of, how they go from screen to screen, and how they click the
## buttons and press the keys as players do.
##
## Not a test itself (its name does not start with test_): the tests extend
## it.

const CaptainBot := preload("res://tests/godot/end2end/captain_bot.gd")
const Contracts := preload("res://tests/godot/end2end/contracts.gd")
const Keys := preload("res://tests/godot/end2end/keys.gd")

const LANGUAGE_SELECT := "res://scenes/language_select/language_select.tscn"

const DEFAULT_SEED := 20261113

## How much faster the game runs than the fixed frame rate gives: one frame
## of 1/60 s plays this many 60ths of a second.
const DEFAULT_TIME_SCALE := 12.0

## How many more steps the boats sail on every frame (see
## [method _play_mission]).
const DEFAULT_SUBSTEPS := 3

## How many missions the players of the new voyage play after the restart.
const DEFAULT_NEW_VOYAGE_MISSIONS := 2

## A mission which takes longer than this, in seconds of the game, is stuck.
const MISSION_SECONDS := 2400.0

## The screens between the missions may take at most this many actions in all.
const MAX_ACTIONS := 4000

## The contracts of a mission are checked on every this many frames.
const CHECK_EVERY := 2

## The chances that the players pick a wrong one in a line-up or give a wrong
## answer to the judge, that they shop and that they take an errand.
const WRONG_CHANCE := 0.12
const SHOP_CHANCE := 0.25
const BUY_CHANCE := 0.5
const ERRAND_CHANCE := 0.25

## The chance that the players leave a mission in the middle (once in each
## phase, surely), and play it again from the start.
const LEAVE_CHANCE := 0.06

## How many captains sail: 1 or 2; the tests set it.
var players := 1

var _failures: Array[String] = []
var _rng := RandomNumberGenerator.new()
var _contracts := Contracts.new()
var _time_scale := DEFAULT_TIME_SCALE
var _substeps := DEFAULT_SUBSTEPS

## The seconds of the game played so far.
var _clock := 0.0

## The phase: "first", the voyage through every mission; then "second", the
## new voyage after the restart; then "back", back to the first voyage.
var _phase := "first"
var _missions_to_play := 0
var _new_voyage_missions := DEFAULT_NEW_VOYAGE_MISSIONS
var _first_voyage := ""
var _second_voyage := ""

## What the players want on the screen of the voyages: "new", "continue", or
## the id of a voyage.
var _voyage_intent := "new"

## The language to choose at the language select next, and the languages in
## the order the voyage goes through them.
var _next_language := ""
var _languages: Array[String] = []
var _languages_seen := {}

## The screens and the detours seen, by the phase.
var _seen := {}

## The missions finished in the first phase, and their stars.
var _finished := {}

## What the players answer when the mission select asks whether to continue
## a mission they left: "" when they did not leave one.
var _resume := ""

## What happened on the current screen: e.g., the detours taken.
var _screen: Node = null
var _here := {}
var _actions := 0
var _missions_played := 0
var _scenes_answered := 0
var _wrong_answers := 0
var _bought := 0
var _errands := 0
var _handed_over := 0

## Whether to print what the boats do now and then (`-- --trace`).
var _tracing := false


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _argument(name: String, default: String) -> String:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--%s=" % name):
            return arg.get_slice("=", 1)
    return default


## Let the frames pass, counting the time of the game.
func _frames(count: int) -> void:
    for i in range(count):
        await process_frame
        _clock += _time_scale / 60.0


func _wait(seconds: float) -> void:
    var until := _clock + seconds
    while _clock < until:
        await _frames(1)


func _session() -> Node:
    return root.get_node("Session")


func _crew() -> Node:
    return root.get_node("Crew")


func _language_node() -> Node:
    return root.get_node("Languages")


## The name of the screen: the file of its script, e.g., "mission_select".
func _name(screen: Variant) -> String:
    if screen == null or not is_instance_valid(screen):
        return "no screen"
    var script := screen.get_script() as Script
    if script == null:
        return screen.get_class()
    return script.resource_path.get_file().get_basename()


## Where the test keeps its voyages and settings.
func _directory() -> String:
    return "user://tests/end2end_%d_players" % players


func _clean(directory: String) -> void:
    if not DirAccess.dir_exists_absolute(directory):
        return
    for sub in DirAccess.get_directories_at(directory):
        _clean(directory.path_join(sub))
    for file in DirAccess.get_files_at(directory):
        DirAccess.remove_absolute(directory.path_join(file))


# region Driving


## The missions of the voyage in their order.
func _missions() -> Array[Mission]:
    return MissionCatalog.all()


## The first mission which the voyage did not complete yet, or null.
func _next_mission() -> Mission:
    for mission in _missions().slice(0, _missions_to_play):
        if not _session().is_completed(mission.id):
            return mission
    return null


func _completed_count() -> int:
    var count := 0
    for mission in _missions():
        count += 1 if _session().is_completed(mission.id) else 0
    return count


## Whether the first voyage completed its missions, and its players look at
## the mission select.
func _first_done() -> bool:
    return _name(current_scene) == "mission_select" and _next_mission() == null


## Whether the players of the new voyage completed their missions, and look
## at the mission select.
func _second_done() -> bool:
    var id: String = _session().id
    if _name(current_scene) != "mission_select" or id == "" or id == _first_voyage:
        return false
    return _completed_count() >= _new_voyage_missions


## Play on from screen to screen until [param done].
func _drive(done: Callable) -> void:
    while not done.call():
        var screen := current_scene
        if screen == null or screen.is_queued_for_deletion():
            await _frames(1)
            continue
        if screen != _screen:
            _screen = screen
            _here = {}
            _seen["%s %s" % [_phase, _name(screen)]] = true
            await _frames(2)
            if screen != current_scene:
                continue
        if _name(screen) == "mission":
            await _play_mission(screen)
            continue
        _actions += 1
        if _actions > MAX_ACTIONS:
            _check(false, "%s: the screens took more than %d actions" % [_phase, MAX_ACTIONS])
            return
        _contracts.check_screen(screen, "%s %s" % [_phase, _name(screen)])
        await _act(screen)
        await _frames(2)


## Wait until the screen gives way to the next one; return whether it did.
func _leaves(screen: Variant, what: String, seconds := 4.0) -> bool:
    var name := _name(screen) if is_instance_valid(screen) else "a screen"
    var until := _clock + seconds
    while is_instance_valid(screen) and current_scene == screen and _clock < until:
        await _frames(1)
    var left: bool = not is_instance_valid(screen) or current_scene != screen
    _check(left, "%s: %s leads on from %s" % [_phase, what, name])
    return left


# endregion

# region Clicking


## Click the button as a player does, with the mouse in its middle, which
## checks that nothing else catches the click there; [param view] is where
## the viewport of the button stands on the screen (the half of a player).
func _click(button: HandButton, what: String, view := Vector2.ZERO) -> void:
    if button == null or not is_instance_valid(button):
        _check(false, "%s: the button %s is missing" % [_phase, what])
        return
    _check(
        button.is_visible_in_tree() and not button.is_blocked(),
        "%s: the button %s shows and can be pressed" % [_phase, what]
    )
    var pressed := [0]
    var on_press := func() -> void: pressed[0] += 1
    button.pressed.connect(on_press)
    var at := view + button.get_global_rect().get_center()
    var motion := InputEventMouseMotion.new()
    motion.position = at
    motion.global_position = at
    root.push_input(motion, true)
    for down in [true, false]:
        var event := InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = down
        event.position = at
        event.global_position = at
        root.push_input(event, true)
    if is_instance_valid(button) and button.pressed.is_connected(on_press):
        button.pressed.disconnect(on_press)
    _check(
        pressed[0] == 1,
        (
            "%s: the mouse clicks %s once in its middle, on %s (%d times)"
            % [_phase, what, _name(current_scene), pressed[0]]
        )
    )
    if pressed[0] == 0 and is_instance_valid(button):
        button.pressed.emit()
    await _frames(1)


## Press the key and let it go.
func _key(key: Key) -> void:
    Keys.tap(key)
    await _frames(1)


## The active button of the root with the text (or the title), or null.
func _button(screen: Node, text: String) -> HandButton:
    for button in Contracts.active_buttons(screen):
        if button.text == text or button.title == text:
            return button
    return null


func _pick(buttons: Array) -> Variant:
    return buttons[_rng.randi_range(0, buttons.size() - 1)]


## Whether to take a detour of this name now: by chance, and surely the
## first time in the phase it can, so that every detour is taken.
func _detour(name: String, chance: float) -> bool:
    var key := "%s detour %s" % [_phase, name]
    if _here.has(name):
        return false
    if not _seen.has(key) or _rng.randf() < chance:
        _here[name] = true
        _seen[key] = true
        return true
    return false


# endregion

# region To be done by the tests


## Play the game (see playthrough.gd).
func _run() -> void:
    pass


## Do one thing on the menu screen (see menus.gd).
func _act(_screen: Node) -> void:
    pass


## Play the mission until it is left (see playthrough.gd).
func _play_mission(_mission: Node) -> void:
    pass

# endregion
