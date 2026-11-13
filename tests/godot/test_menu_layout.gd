extends SceneTree
## Check the layout of the menu screens in English and in the drafts of every
## translation, with the contracts of the end-to-end tests (see
## end2end/contracts.gd): no button or label sticks out of the screen, no two
## buttons overlap, and every label of a button fits it at a readable size.
##
## The end-to-end tests see every screen, but only in some languages and with
## some choices; here, every screen shows in every language: the captains with
## every choice of every row, one and two of them, and the shipyard with
## every tab, for one and two captains.

const Contracts := preload("res://tests/godot/end2end/contracts.gd")
const Samples := preload("res://tests/godot/samples.gd")

const SCREENS := [
    "res://scenes/language_select/language_select.tscn",
    "res://scenes/session_select/session_select.tscn",
    "res://scenes/session_name/session_name.tscn",
    "res://scenes/player_count/player_count.tscn",
    "res://scenes/mission_select/mission_select.tscn",
]
const CAPTAINS := "res://scenes/captain_creator/captain_creator.tscn"
const SHIPYARD := "res://scenes/shipyard/shipyard.tscn"

## The rows of the captain's choices (see CaptainPanel).
const CHOICES := ["skin", "hair", "hair_color", "cap", "vest", "sash", "face", "eye_patch"]

var _contracts := Contracts.new()
var _directory := "user://tests/menu_layout"


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var session: Node = root.get_node("Session")
    session.saves_dir = _directory.path_join("saves")
    session.settings_path = _directory.path_join("settings.cfg")
    root.get_node("Languages").settings_path = _directory.path_join("settings.cfg")
    # NOTE (mristin):
    # A voyage with the shipyard open, so that every screen shows it all.
    session.start("Test")
    for mission in MissionCatalog.all().slice(0, 2):
        session.complete(mission.id, 3)
    session.ducats = 100
    for code in Samples.codes():
        var translation := Samples.load_drafts(code, "menu_layout")
        TranslationServer.set_locale(code)
        for players in [1, 2]:
            root.get_node("Crew").start(players)
            for path in SCREENS:
                await _check(path, "%s, %d captain(s)" % [path.get_file(), players])
            await _check_captains(players)
            await _check_shipyard(players)
        if translation != null:
            TranslationServer.remove_translation(translation)
    session.delete_voyage(session.id)

    var violations := _contracts.violations()
    for violation in violations:
        print("FAIL ", violation)
    if violations.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % violations.size())
        quit(1)


func _open(path: String) -> Node:
    var screen: Node = (load(path) as PackedScene).instantiate()
    screen.set("next_scene", "")
    root.add_child(screen)
    return screen


func _settle() -> void:
    await process_frame
    await process_frame


func _check(path: String, tag: String) -> void:
    var screen := _open(path)
    await _settle()
    _contracts.check_screen(screen, tag)
    screen.free()


## Every choice of every row, in every panel.
func _check_captains(players: int) -> void:
    var screen := _open(CAPTAINS)
    await _settle()
    for panel: CaptainPanel in screen._panels:
        for gender in ["hajduk", "hajducica"]:
            panel._set_gender(gender)
            for key in CHOICES:
                for i in range(panel._choices(key).size()):
                    panel._step(key, 1)
                    await process_frame
                    _contracts.check_screen(
                        screen, "the captains (%d), %s, %s" % [players, gender, key]
                    )
    screen.free()


## Every tab of the shipyard, for every captain.
func _check_shipyard(players: int) -> void:
    var screen := _open(SHIPYARD)
    await _settle()
    for captain in range(players):
        screen._choose_captain(captain)
        for slot in screen.TABS:
            screen._choose_slot(slot)
            await _settle()
            _contracts.check_screen(screen, "the shipyard (%d), %s" % [players, slot])
    screen.free()
