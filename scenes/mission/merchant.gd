class_name Merchant
extends RefCounted

## The merchant's stall of a port (see DESIGN.md, section 10): four boosters of
## all (see World.boosters), drawn anew at every visit, one of them a
## speciality of the power of the port (Venice sells flags, the Ottoman ports
## figs, ...). A decoration among them (see Booster.decoration) is the
## captain's for good: it is paid at once, and the boat wears it at once.

## How many boosters a merchant shows.
const STALL_SIZE := 4


## Draw the stall of the port; the decorations which the crew owns already are
## left out.
static func draw_stall(port: Port, owned: Array, rng: RandomNumberGenerator) -> Array:
    var pool: Array = []
    for booster in World.boosters():
        if booster.decoration == null or not owned.has(booster.decoration.id):
            pool.append(booster)
    var stall: Array = []
    if port != null and port.power != null and not port.power.offers.is_empty():
        var specials: Array = port.power.offers
        stall.append(specials[rng.randi_range(0, specials.size() - 1)])
    while stall.size() < STALL_SIZE and stall.size() < pool.size():
        var booster: Booster = pool[rng.randi_range(0, pool.size() - 1)]
        if not stall.has(booster):
            stall.append(booster)
    return stall


## Why the crew can't buy the booster now, as BoosterBag.why_not; a decoration
## only needs the ducats (it is the captain's for good).
static func why_not(booster: Booster, run: MissionRun, session: Node) -> String:
    if booster.decoration == null:
        return run.bag.why_not(booster, session.ducats)
    if session.owned.has(booster.decoration.id):
        return "held"
    if run.bag.purse(session.ducats) < booster.price:
        return "ducats"
    return ""


## Buy a decoration for the captain of the active boat: it is paid from the
## ducats on board first and then from the chest of the crew, at once, since it
## stays the captain's for good (as in the shipyard); return whether it worked.
static func buy_decoration(
    booster: Booster, run: MissionRun, session: Node, captain: Dictionary
) -> bool:
    if why_not(booster, run, session) != "":
        return false
    var hold := run.hold()
    var from_hold := mini(booster.price, hold.on_board())
    hold.spent += from_hold
    session.ducats -= booster.price - from_hold
    var decoration := booster.decoration
    session.owned.append(decoration.id)
    var boat: Dictionary = captain.get("boat", {})
    boat[decoration.slot] = decoration.id
    captain["boat"] = boat
    session.save()
    return true


## The scene of the stall: what the merchant says, the purse, and the cards.
static func scene(
    person: Person, said: Dictionary, stall: Array, run: MissionRun, session: Node
) -> Dictionary:
    var reasons: Array = []
    for booster in stall:
        reasons.append(why_not(booster, run, session))
    var purse := MissionRun.line(
        "You have {ducats} {ducats|ducat|ducats}.", {"ducats": run.bag.purse(session.ducats)}
    )
    var result := MissionStep.talk(person, [said, purse], MissionRun.line("Goodbye!"), "close_shop")
    result["kind"] = "shop"
    result["offers"] = stall
    result["reasons"] = reasons
    return result
