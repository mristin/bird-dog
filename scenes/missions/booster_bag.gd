class_name BoosterBag
extends RefCounted

## The boosters which the crew bought at the merchants in a mission (see
## DESIGN.md, section 10); they work for every boat. The crew in the port pays
## from the ducats on board of its boat.

## The crew can hold at most this many boosters for the next leg.
const MAX_LEG_BOOSTERS := 2

## The boosters the crew holds.
var boosters: Array[Booster] = []

## The run which holds the bag; weak, because the run holds the bag, too (a
## cycle of references would never be freed).
var _run_ref: WeakRef


func _init(run: MissionRun) -> void:
    _run_ref = weakref(run)


func _run() -> MissionRun:
    return _run_ref.get_ref()


## The ducats the crew in the port can spend: those on board of its boat.
func purse() -> int:
    return _run().hold().on_board()


## Why the crew can't buy the booster now ("" if it can): "ducats" (too few),
## "full" (two boosters for the leg already, or no room in the barrels for
## another ration of food) or "held" (it has one already).
func why_not(booster: Booster) -> String:
    if purse() < booster.price:
        return "ducats"
    if booster.lasts != "now" and boosters.has(booster):
        return "held"
    if booster.lasts == "leg" and _count_leg() >= MAX_LEG_BOOSTERS:
        return "full"
    if booster.effect == "ration" and not _run().hold().has_room_for(_run().ration_days()):
        return "full"
    return ""


func _count_leg() -> int:
    var count := 0
    for held in boosters:
        count += 1 if held.lasts == "leg" else 0
    return count


## Buy a booster; return whether it worked.
func buy(booster: Booster) -> bool:
    if why_not(booster) != "":
        return false
    _run().hold().spent += booster.price
    if booster.effect == "ration":
        _run().hold().add_ration(_run().ration_days())
    else:
        boosters.append(booster)
    return true


func has_effect(effect: String) -> bool:
    for held in boosters:
        if held.effect == effect:
            return true
    return false


## Use up a booster which lasts until it is used (e.g., the figs); return
## whether the crew had one.
func use_effect(effect: String) -> bool:
    for held in boosters:
        if held.effect == effect:
            boosters.erase(held)
            return true
    return false


## A leg ends in a port: the boosters for the leg are spent.
func end_leg() -> void:
    for held in boosters.duplicate():
        if held.lasts == "leg":
            boosters.erase(held)
