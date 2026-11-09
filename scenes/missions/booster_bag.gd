class_name BoosterBag
extends RefCounted

## The boosters which the crew bought at the merchants in a mission (see
## DESIGN.md, section 10); they work for every boat. The crew in the port pays
## from the chest of the crew and from the ducats on board of its boat.

## The crew can hold at most this many boosters for the next leg.
const MAX_LEG_BOOSTERS := 2

## Fresh bread and water give back this many days.
const BREAD_DAYS := 0.5

## The boosters the crew holds.
var boosters: Array[Booster] = []

## The run which holds the bag; weak, because the run holds the bag, too (a
## cycle of references would never be freed).
var _run_ref: WeakRef


func _init(run: MissionRun) -> void:
    _run_ref = weakref(run)


func _run() -> MissionRun:
    return _run_ref.get_ref()


## The ducats the crew can spend: the chest of the crew and what the mission
## earned, less what it spent.
func purse(chest: int) -> int:
    var hold := _run().hold()
    return chest + hold.ducats - hold.spent


## Why the crew can't buy the booster now ("" if it can): "ducats" (too few),
## "full" (two boosters for the leg already) or "held" (it has one already).
func why_not(booster: Booster, chest: int) -> String:
    if purse(chest) < booster.price:
        return "ducats"
    if booster.lasts != "now" and boosters.has(booster):
        return "held"
    if booster.lasts == "leg" and _count_leg() >= MAX_LEG_BOOSTERS:
        return "full"
    return ""


func _count_leg() -> int:
    var count := 0
    for held in boosters:
        count += 1 if held.lasts == "leg" else 0
    return count


## Buy a booster; return whether it worked.
func buy(booster: Booster, chest: int) -> bool:
    if why_not(booster, chest) != "":
        return false
    _run().hold().spent += booster.price
    if booster.effect == "time":
        _run().days = maxf(0.0, _run().days - BREAD_DAYS)
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
