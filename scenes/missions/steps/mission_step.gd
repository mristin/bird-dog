class_name MissionStep
extends Resource

## A step of a mission (see DESIGN.md, section 15). The subclasses hold exactly
## the data which their part of the story needs, and their rules as methods.
## The resources never change while playing; the state lives in the MissionRun.
##
## What a step shows in a port is a "scene", a dictionary:
##
## * {"kind": "talk", "person": Person, "lines": [line, ...],
##   "buttons": [{"label": line, "action": String}, ...]}, or
## * {"kind": "lineup", "question": line, "boats": [Boat, ...]}, whose answers
##   are the actions "pick:<index>".
##
## The action "leave" closes the scene.

@export var id := ""


## Draw what is random about the step (e.g., the clues), into run.plan[id].
func plan(_run: MissionRun, _rng: RandomNumberGenerator) -> void:
    pass


## The step begins: set the clue or the objective.
func start(_run: MissionRun) -> void:
    pass


## The scene to show as soon as the step starts (e.g., a briefing or a
## line-up), or null.
func opening(_run: MissionRun) -> Variant:
    return null


## The scene in the port, or null if the step has nothing to say there.
func arrive(_run: MissionRun, _port: Port) -> Variant:
    return null


## React to an answer in the scene; return the next scene, or null to close it.
func act(_run: MissionRun, _action: String) -> Variant:
    return null


func is_done(_run: MissionRun) -> bool:
    return true


## The ports where the crew can go now, which the chart points to (the kids
## need not remember the clues); empty for none.
func target_ports(_run: MissionRun) -> Array[Port]:
    return []


## The item (or passenger) which the crew needs in the port but does not
## carry on the boat which came, or null: with two boats, the other boat may
## carry it, and the port says so.
func wanted_item(_run: MissionRun, _port: Port) -> Item:
    return null


## The action which solves a scene of the step (for the tests, which play
## every mission headless), or "" if any answer goes on.
func solution(_run: MissionRun) -> String:
    return ""


## A scene in which a person talks and the crew answers with one button.
static func talk(person: Person, lines: Array, label: Dictionary, action := "leave") -> Dictionary:
    return {
        "kind": "talk",
        "person": person,
        "lines": lines,
        "buttons": [{"label": label, "action": action}],
    }
