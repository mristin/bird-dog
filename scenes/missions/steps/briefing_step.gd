class_name BriefingStep
extends MissionStep

## Somebody tells the crew what happened and gives the first clue (see
## DESIGN.md, section 15): Baba Stana in Pula, or her letter by pigeon.

@export var speaker: Person

## The lines, in English.
@export var lines: Array[String] = []

## Whether the speaker is far away and sends a letter by carrier pigeon.
@export var by_pigeon := false

## The label of the button which starts the mission, in English.
@export var go_label := "Set sail!"


func plan(run: MissionRun, _rng: RandomNumberGenerator) -> void:
    run.plan[id] = {"done": false}


func opening(run: MissionRun) -> Variant:
    var said: Array = []
    if by_pigeon:
        said.append(MissionRun.line("A carrier pigeon lands on the boat with a letter:"))
    for text in lines:
        said.append(MissionRun.line(text))

    # NOTE (mristin):
    # The briefing ends with the first clue of the trail which follows it.
    var next_index := run.mission.steps.find(self) + 1
    if next_index < run.mission.steps.size():
        var next_step := run.mission.steps[next_index]
        if next_step is TrailStep:
            said.append((next_step as TrailStep).clue_line(run, 0))
    return MissionStep.talk(speaker, said, MissionRun.line(go_label), "done")


func act(run: MissionRun, action: String) -> Variant:
    if action == "done":
        run.plan[id]["done"] = true
    return null


func is_done(run: MissionRun) -> bool:
    return run.plan[id]["done"]
