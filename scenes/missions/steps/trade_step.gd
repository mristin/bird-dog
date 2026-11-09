class_name TradeStep
extends MissionStep

## A chain of trades (see DESIGN.md, section 15): the first link wants an item
## which the second link gives, but only for an item which the third gives,
## and so on. The crew learns the chain link by link ("Bring me a sail!"),
## then trades its way back. The step is done when the first link got what
## they wanted.

@export var links: Array[TradeLink] = []

## The objective while the crew learns the chain, in English, with {person}
## and {port}.
@export var ask_objective := "Talk to {person} in {port}."

## The objective while the crew brings an item, in English, with {item},
## {person} and {port}.
@export var bring_objective := "Bring {item} to {person} in {port}."


func plan(run: MissionRun, _rng: RandomNumberGenerator) -> void:
    # NOTE (mristin):
    # "asked": how many links the crew has heard; "done": the traded links.
    run.plan[id] = {"asked": 0, "done": []}


## The link which the crew can do now: the deepest heard link whose wish one
## of the crew's boats can fulfil, or the next link to hear; -1 if none.
func _next(run: MissionRun) -> int:
    var state: Dictionary = run.plan[id]
    for i in range(state["asked"] - 1, -1, -1):
        if state["done"].has(i):
            continue
        var link := links[i]
        if link.wants == null or run.crew_has(link.wants.id):
            return i
    if state["asked"] < links.size():
        return state["asked"]
    return -1


func _update_clue(run: MissionRun) -> void:
    var i := _next(run)
    if i < 0:
        return
    var link := links[i]
    var args := {"person": link.person.name, "port": link.port.name}
    if i < run.plan[id]["asked"] and link.wants != null:
        args["item"] = link.wants.name
        run.set_clue(MissionRun.line(bring_objective, args))
    else:
        run.set_clue(MissionRun.line(ask_objective, args))


func start(run: MissionRun) -> void:
    _update_clue(run)


func arrive(run: MissionRun, port: Port) -> Variant:
    var i := _next(run)
    if i < 0 or links[i].port.id != port.id:
        return null
    var state: Dictionary = run.plan[id]
    var link := links[i]
    var lines: Array = []

    # NOTE (mristin):
    # The person already asked, and the other boat carries what they want:
    # the port tells the crew to hand it over (see wanted_item).
    var heard: bool = i < state["asked"]
    if heard and link.wants != null and not run.cargo.has(link.wants.id):
        return null
    if link.wants == null or run.cargo.has(link.wants.id):
        if link.wants != null:
            run.cargo.erase(link.wants.id)
        if link.gives != null:
            run.cargo.append(link.gives.id)
        state["done"].append(i)
        state["asked"] = maxi(state["asked"], i + 1)
        for text in link.thanks_lines:
            lines.append(MissionRun.line(text))
        _update_clue(run)
        return MissionStep.talk(link.person, lines, MissionRun.line("Thank you!"))

    state["asked"] = maxi(state["asked"], i + 1)
    for text in link.ask_lines:
        lines.append(MissionRun.line(text))
    _update_clue(run)
    return MissionStep.talk(link.person, lines, MissionRun.line("We will!"))


func wanted_item(run: MissionRun, port: Port) -> Item:
    var i := _next(run)
    if i < 0 or links[i].port.id != port.id:
        return null
    var wanted := links[i].wants
    if i < run.plan[id]["asked"] and wanted != null and not run.cargo.has(wanted.id):
        return wanted
    return null


func target_ports(run: MissionRun) -> Array[Port]:
    var i := _next(run)
    if i < 0:
        return []
    return [links[i].port]


func is_done(run: MissionRun) -> bool:
    return run.plan[id]["done"].has(0)
