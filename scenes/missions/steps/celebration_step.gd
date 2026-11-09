class_name CelebrationStep
extends MissionStep

## The happy end of a mission (see DESIGN.md, section 15).

@export var speaker: Person
@export var lines: Array[String] = []

## A sound of the celebration (see Sfx), e.g., "bell"; "" for none.
@export var sound := ""


func plan(run: MissionRun, _rng: RandomNumberGenerator) -> void:
    run.plan[id] = {"done": false}


func opening(_run: MissionRun) -> Variant:
    var said: Array = []
    for text in lines:
        said.append(MissionRun.line(text))
    return MissionStep.talk(speaker, said, MissionRun.line("Hooray!"), "done")


func act(run: MissionRun, action: String) -> Variant:
    if action == "done":
        run.plan[id]["done"] = true
    return null


func is_done(run: MissionRun) -> bool:
    return run.plan[id]["done"]
