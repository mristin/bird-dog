class_name LineupStep
extends MissionStep

## Pick the right one out of several by the hallmarks the crew learned (see
## DESIGN.md, section 15): a Boat or a Person. The decoys share some of the
## hallmarks, never all. The crew has to remember the hallmarks: the line-up
## never repeats them. After a wrong pick, the target slips away to another
## port, and the trail before the line-up goes on there (see TrailStep.flee);
## without a trail, a wrong pick costs time.

## The one to find: a Boat or a Person.
@export var target: Resource

## The others in the line-up, of the same kind as the target.
@export var decoys: Array[Resource] = []

## The question, in English.
@export var question := "Which boat is it?"

## What happens on a wrong pick and on the right one, in English.
@export var wrong_line := "No, not this one!"
@export var right_line := "That's the one!"

## The item which the crew gets with the right pick; may be null.
@export var gives: Item

## A wrong pick costs this many days, if there is no trail to go on.
@export var wrong_days := 0.5

## What the crew hears when the target slipped away, in English.
@export var fled_line := "Oh no! While you looked at the wrong one, they slipped away!"


func plan(run: MissionRun, rng: RandomNumberGenerator) -> void:
    run.plan[id] = {"order": _shuffled(rng), "done": false, "wrong": false}


func _shuffled(rng: RandomNumberGenerator) -> Array[int]:
    var order: Array[int] = []
    for i in range(decoys.size() + 1):
        order.append(i)
    for i in range(order.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var swap := order[i]
        order[i] = order[j]
        order[j] = swap
    return order


func _candidates(run: MissionRun) -> Array[Resource]:
    var all: Array[Resource] = [target]
    all.append_array(decoys)
    var result: Array[Resource] = []
    for i in run.plan[id]["order"]:
        result.append(all[i])
    return result


func start(run: MissionRun) -> void:
    run.set_clue(MissionRun.line(question))


func opening(run: MissionRun) -> Variant:
    var said := question
    if run.plan[id]["wrong"]:
        said = wrong_line
    return {"kind": "lineup", "question": MissionRun.line(said), "candidates": _candidates(run)}


func act(run: MissionRun, action: String) -> Variant:
    if not action.begins_with("pick:"):
        return null
    var picked := _candidates(run)[int(action.get_slice(":", 1))]
    if picked != target:
        return _wrong(run)
    run.plan[id]["done"] = true
    if gives != null:
        run.cargo.append(gives.id)
    return MissionStep.talk(null, [MissionRun.line(right_line)], MissionRun.line("Hooray!"))


## A wrong pick: the target flees to another port, and the crew follows the
## trail there; the line-up comes again, in a new order.
func _wrong(run: MissionRun) -> Variant:
    run.plan[id]["order"] = _shuffled(run.rng)
    var trail := _trail(run)
    var next: Dictionary = trail.flee(run) if trail != null else {}
    if next.is_empty():
        run.days += wrong_days
        run.plan[id]["wrong"] = true
        return opening(run)
    run.go_back_to(trail)
    var lines: Array = [MissionRun.line(wrong_line), MissionRun.line(fled_line), next]
    return MissionStep.talk(null, lines, MissionRun.line("After them!"))


## The trail right before the line-up, or null.
func _trail(run: MissionRun) -> TrailStep:
    var index := run.mission.steps.find(self)
    for i in range(index - 1, -1, -1):
        if run.mission.steps[i] is TrailStep:
            return run.mission.steps[i]
    return null


func is_done(run: MissionRun) -> bool:
    return run.plan[id]["done"]


func solution(run: MissionRun) -> String:
    return "pick:%d" % _candidates(run).find(target)
