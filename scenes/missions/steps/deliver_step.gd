class_name DeliverStep
extends MissionStep

## Bring an item (or a person, or just the crew) to somebody in a port (see
## DESIGN.md, section 15); this is also the step to sail home ("Return").

## The item to bring; null to only sail there.
@export var item: Item
@export var port: Port
@export var recipient: Person

## The objective while sailing, in English, with {port}.
@export var objective := "Bring it to {port}."

## What the recipient says, in English.
@export var thanks: Array[String] = []

## What the recipient gives in return (e.g., a sealed answer); may be null.
@export var gives: Item


func plan(run: MissionRun, _rng: RandomNumberGenerator) -> void:
    run.plan[id] = {"done": false}


func start(run: MissionRun) -> void:
    run.set_clue(MissionRun.line(objective, {"port": port.name}))


func arrive(run: MissionRun, arrived: Port) -> Variant:
    if arrived.id != port.id or (item != null and not run.cargo.has(item.id)):
        return null
    if item != null:
        run.cargo.erase(item.id)
    if gives != null:
        run.cargo.append(gives.id)
    run.plan[id]["done"] = true
    var lines: Array = []
    for text in thanks:
        lines.append(MissionRun.line(text))
    return MissionStep.talk(recipient, lines, MissionRun.line("You're welcome!"))


func wanted_item(run: MissionRun, arrived: Port) -> Item:
    if arrived.id == port.id and item != null and not run.cargo.has(item.id):
        return item
    return null


func target_ports(_run: MissionRun) -> Array[Port]:
    return [port]


func is_done(run: MissionRun) -> bool:
    return run.plan[id]["done"]
