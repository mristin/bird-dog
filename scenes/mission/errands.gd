class_name Errands
extends RefCounted

## The errands of the ports (see DESIGN.md, "Errands"): while one boat follows
## the story, the other can earn ducats by carrying goods from port to port.
## A local offers to pay for bringing a barrel of wine, a basket of figs, a
## bolt of cloth, lace or a letter to another port; the further, the more
## ducats. The goods ride in the boat which took them; the boats can hand
## them over at sea, and whoever brings them gets paid.

## The goods which the locals send.
const GOODS: Array[String] = [
    "goods_wine", "goods_figs", "goods_cloth", "goods_lace", "goods_letter"
]

## The destination of an errand lies this far from the port, in kilometres.
const DISTANCE_KM := Vector2(60.0, 220.0)


## Whether the boat of the crew in the port may take on another errand: every
## ship carries a few goods at most (see Ship.errands).
static func can_take(run: MissionRun) -> bool:
    var carried := 0
    for errand in run.errands:
        carried += 1 if run.hold().cargo.has(errand["item"]) else 0
    return carried < run.hold().ship.errands


## Draw an errand from the port: {"item", "port", "reward"}, or {} if no port
## lies at the right distance.
static func offer(from: Port, rng: RandomNumberGenerator) -> Dictionary:
    var candidates: Array[Port] = []
    var at := World.port_km(from)
    for port in World.ports():
        var distance := World.port_km(port).distance_to(at)
        if distance >= DISTANCE_KM.x and distance <= DISTANCE_KM.y:
            candidates.append(port)
    if candidates.is_empty():
        return {}
    var to: Port = candidates[rng.randi_range(0, candidates.size() - 1)]
    var distance := World.port_km(to).distance_to(at)
    return {
        "item": GOODS[rng.randi_range(0, GOODS.size() - 1)],
        "port": to.id,
        "port_name": to.name,
        "reward": 10 + int(round(distance / 20.0)) * 5,
    }


## What the local of the port says about the errand (the actions
## "errand_yes" and "close_shop"); with no errand, that there is no work.
static func ask_scene(offer: Dictionary, local: Person) -> Dictionary:
    if offer.is_empty():
        return MissionStep.talk(
            local,
            [MissionRun.line("No work today, captain.")],
            MissionRun.line("Goodbye!"),
            "close_shop"
        )
    var args := {
        "item": World.item(offer["item"]).name,
        "port": World.port(offer["port"]).name,
        "reward": offer["reward"],
    }
    var said := MissionRun.line(
        "Could you bring {item} to {port}? They will pay you {reward} {reward|ducat|ducats} there.",
        args
    )
    var ask := MissionStep.talk(local, [said], MissionRun.line("We'll do it!"), "errand_yes")
    ask["buttons"].append({"label": MissionRun.line("Not now"), "action": "close_shop"})
    return ask


## Deliver all the errands to the port which the boat carries goods for;
## return a line of thanks for every one, with the icon of its goods (the boat
## gets the ducats).
static func deliver(run: MissionRun, port: Port) -> Array:
    var lines: Array = []
    var hold := run.hold()
    for errand in run.errands.duplicate():
        if errand["port"] != port.id or not hold.cargo.has(errand["item"]):
            continue
        hold.cargo.erase(errand["item"])
        hold.ducats += errand["reward"]
        run.errands.erase(errand)
        var item := World.item(errand["item"])
        var thanks := MissionRun.line(
            "Thank you for {item}! Here are {reward} {reward|ducat|ducats}.",
            {"item": item.name, "reward": errand["reward"]}
        )
        # NOTE (mristin):
        # The card shows the goods beside the thanks (see StoryCard).
        thanks["icon"] = errand["item"]
        lines.append(thanks)
    return lines


## The ports which the errands of the crew go to.
static func ports(run: MissionRun) -> Array[Port]:
    var result: Array[Port] = []
    for errand in run.errands:
        var port := World.port(errand["port"])
        if port != null and not result.has(port):
            result.append(port)
    return result
