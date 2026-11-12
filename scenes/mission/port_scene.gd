class_name PortScene
extends RefCounted

## The scene of a port when a boat enters it (see the mission screen): what
## the step of the mission says there, or else the "wrong port" talk of a
## local, with the news of the visit (the errands paid, the ducats, the food,
## the repair) and the buttons which every port has (the merchant, the work,
## the other port of the bay).


## The scene of the step in the port, or the "wrong port" talk of a local if
## the step has nothing to do there.
static func of(run: MissionRun, port: Port, players: int) -> Dictionary:
    var step := run.step()
    var scene: Variant = step.arrive(run, port)
    if scene != null:
        return scene
    var local: Person = port.locals[0] if not port.locals.is_empty() else null
    var said: Array = [MissionRun.line("This is the wrong port, captain!"), run.clue]
    var wanted := step.wanted_item(run, port)
    if wanted != null and players > 1:
        said = [
            MissionRun.line(
                "Your other boat carries {item}. Meet at sea and hand it over!",
                {"item": wanted.name}
            )
        ]
    return MissionStep.talk(local, said, MissionRun.line("Goodbye!"))


## The lines of a talk in the port: [param first] (e.g., that the boat was
## towed there), the thanks for the errands [param paid], what the scene says,
## and the news of the visit: the ducats [param gained], the food for a
## [param hungry] crew, the repair of a [param damaged] hull, and the tip about
## the ports, if [param tip].
static func lines(
    scene: Dictionary,
    first: Array,
    paid: Array,
    gained: int,
    hungry: bool,
    damaged: bool,
    tip: bool
) -> Array:
    var result: Array = first.duplicate()
    result.append_array(paid)
    result.append_array(scene["lines"])
    if gained > 0:
        result.append(
            MissionRun.line("You got {ducats} {ducats|ducat|ducats}!", {"ducats": gained})
        )
    if hungry:
        result.append(MissionRun.line("Your crew takes on bread and fresh water."))
    if damaged:
        result.append(MissionRun.line("The shipwrights repair your hull."))
    if tip:
        result.append(MissionRun.line("Every port has a merchant and work for the crew."))
    return result


## Every port has a merchant (see DESIGN.md, section 10) and work for the
## crew (see Errands); the ports of a bay lead to each other.
static func add_buttons(scene: Dictionary, port: Port, run: MissionRun) -> void:
    scene["buttons"].append({"label": MissionRun.line("What do you sell?"), "action": "shop"})
    if Errands.can_take(run):
        scene["buttons"].append({"label": MissionRun.line("Any work for us?"), "action": "errand"})
    if port.bay_port_id != "":
        var bay := World.port(port.bay_port_id)
        var label := MissionRun.line("Sail on to {port}!", {"port": bay.name})
        scene["buttons"].append({"label": label, "action": "bay"})
