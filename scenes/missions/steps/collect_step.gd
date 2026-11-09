class_name CollectStep
extends MissionStep

## Fetch items from several ports, in any order (see DESIGN.md, section 15):
## e.g., two loads of salt from any two of Ston, Pag and Trieste, or the
## witnesses of the hearing.

## Where the items can be had.
@export var sources: Array[ItemSource] = []

## How many of the sources the crew needs; 0 for all.
@export var needed := 0

## The objective while sailing, in English, with {count} (how many are still
## missing).
@export var objective := "Fetch {count} more."


func plan(run: MissionRun, _rng: RandomNumberGenerator) -> void:
    run.plan[id] = {"taken": []}


func _needed() -> int:
    return needed if needed > 0 else sources.size()


func _missing(run: MissionRun) -> int:
    return _needed() - run.plan[id]["taken"].size()


## The objective, followed by the ports where the missing items still wait.
func _objective(run: MissionRun) -> Dictionary:
    var names: Array = []
    var taken: Array = run.plan[id]["taken"]
    for i in range(sources.size()):
        if not taken.has(i) and not names.has(sources[i].port.name):
            names.append(sources[i].port.name)
    var go := MissionRun.line("Sail to one of: {ports}", {"ports": names})
    if names.size() == 1:
        go = MissionRun.line("Sail to {port}!", {"port": names[0]})
    return MissionRun.line_then(MissionRun.line(objective, {"count": _missing(run)}), go)


func start(run: MissionRun) -> void:
    run.set_clue(_objective(run))


func arrive(run: MissionRun, port: Port) -> Variant:
    var taken: Array = run.plan[id]["taken"]
    for i in range(sources.size()):
        var source := sources[i]
        if source.port.id != port.id or taken.has(i) or _missing(run) <= 0:
            continue
        taken.append(i)
        run.cargo.append(source.item.id)
        var lines: Array = []
        for text in source.lines:
            lines.append(MissionRun.line(text))
        if _missing(run) > 0:
            var still := _objective(run)
            lines.append(still)
            run.set_clue(still)
        return MissionStep.talk(source.person, lines, MissionRun.line("Thank you!"))
    return null


func target_ports(run: MissionRun) -> Array[Port]:
    var result: Array[Port] = []
    if _missing(run) <= 0:
        return result
    var taken: Array = run.plan[id]["taken"]
    for i in range(sources.size()):
        if not taken.has(i) and not result.has(sources[i].port):
            result.append(sources[i].port)
    return result


func is_done(run: MissionRun) -> bool:
    return _missing(run) <= 0
