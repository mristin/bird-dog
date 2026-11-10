class_name MissionRun
extends RefCounted

## The running state of a mission: which step is on, the days used, the cargo,
## the hallmarks the crew learned, the current clue, and the plan which the
## steps drew at the start (see DESIGN.md, "Running a mission").
##
## The resources of the mission never change; everything which changes while
## playing lives here, as plain data, so that it can be saved.
##
## A line of text is a dictionary {"text": English message, "args": {...}}; it
## is translated only when shown (see [method say]).

signal step_started(step: MissionStep)
signal clue_changed
signal finished(stars: int)

## Arriving in a port takes this long, in days.
const PORT_DAYS := 0.2

## With a barrel of salted fish (see Booster), the crews eat this much slower.
const SALTED_FISH := 0.6

var mission: Mission
var step_index := 0
var days := 0.0

## The holds of the boats, one for every player (see BoatHold).
var holds: Array[BoatHold] = []

## The boat whose crew is in a port now: the steps give to and take from its
## hold.
var active := 0

## The cargo of the active boat, for the steps.
var cargo: Array[String]:
    get:
        return holds[active].cargo

## The hallmarks the crew learned, for the line-ups.
var hallmarks: Array[Hallmark] = []

## The boosters the crew holds (they work for every boat).
var bag: BoosterBag

## The errands (side missions) the crew took on: each {"item": id, "port": id,
## "reward": ducats}; the boat which brings the item to the port gets paid.
var errands: Array[Dictionary] = []

## The current clue or objective, as a line.
var clue := {}

## The ducats the crew brought along into the mission (see [method bring]).
var brought := 0

## What the steps drew at the start, by the id of the step.
var plan := {}

var rng := RandomNumberGenerator.new()

var _done := false


## [param ships] are the kinds of the boats (see Ship), one for every player;
## a boat without one is a gajeta (see World.ships).
func _init(the_mission: Mission, seed_value: int, boats := 1, ships: Array = []) -> void:
    mission = the_mission
    rng.seed = seed_value
    for i in range(maxi(1, boats)):
        var ship: Ship = ships[i] if i < ships.size() else null
        holds.append(BoatHold.new(mission.provisions_days, ship))
    bag = BoosterBag.new(self)
    for item in mission.start_cargo:
        holds[0].cargo.append(item.id)
    for step in mission.steps:
        step.plan(self, rng)


## Start the first step.
func begin() -> void:
    _start_step()


func step() -> MissionStep:
    if step_index < mission.steps.size():
        return mission.steps[step_index]
    return null


func is_done() -> bool:
    return _done


## Go on to the next step if the current one is done; finish after the last.
func advance() -> void:
    while step() != null and step().is_done(self):
        step_index += 1
        if step() == null:
            _done = true
            finished.emit(stars())
            return
        _start_step()


## Go back to an earlier step (e.g., the trail, when the target of a line-up
## slipped away); the step keeps its state and does not start again.
func go_back_to(earlier: MissionStep) -> void:
    var index := mission.steps.find(earlier)
    if index >= 0 and index < step_index:
        step_index = index
        step_started.emit(earlier)


func _start_step() -> void:
    var current := step()
    current.start(self)
    step_started.emit(current)


func set_clue(line: Dictionary) -> void:
    clue = line
    clue_changed.emit()


## Let time pass: the clock runs and the crews eat and drink.
func pass_days(spent: float) -> void:
    days += spent
    var eaten := spent * (SALTED_FISH if bag != null and bag.has_effect("food") else 1.0)
    for each in holds:
        each.provisions = maxf(0.0, each.provisions - eaten)


## The hold of a boat; the active one by default.
func hold(index := -1) -> BoatHold:
    return holds[active if index < 0 else index]


## The share of the provisions left in a boat, from 0 to 1.
func provisions_share(index := -1) -> float:
    return hold(index).provisions / maxf(0.01, hold(index).max_provisions)


## How many rations of food a boat has left, as a fraction (e.g., 2.4 is two
## full rations and a part of the third; see ProvisionsPanel).
func rations_left(index := -1) -> float:
    return hold(index).provisions / maxf(0.01, ration_days())


## How many days a ration of food and water lasts in the mission.
func ration_days() -> float:
    return mission.provisions_days / float(Ship.BRACERA_RATIONS)


## Whether any boat of the crew carries the item.
func crew_has(item_id: String) -> bool:
    for each in holds:
        if each.cargo.has(item_id):
            return true
    return false


## The active boat gets ducats (for the news, a delivery, a barrel).
func earn(amount: int) -> void:
    hold().ducats += amount


## The crew brings its ducats along into the mission (see Session.ducats):
## they are on board, split between the boats (the first boat gets the odd
## ducat).
func bring(amount: int) -> void:
    amount = maxi(0, amount)
    brought += amount
    var each := amount / holds.size()
    for i in range(holds.size()):
        holds[i].ducats += each + (amount - each * holds.size() if i == 0 else 0)


## All the ducats on board of the boats of the crew.
func ducats_total() -> int:
    var total := 0
    for each in holds:
        total += each.on_board()
    return total


func days_left() -> float:
    return maxf(0.0, mission.clock_days - days)


## The stars of the mission so far: three with enough time left, two with any
## time left, one otherwise.
func stars() -> int:
    var left := days_left()
    if left >= mission.clock_days * mission.three_stars_share:
        return 3
    if left > 0.0:
        return 2
    return 1


## Make a line of text.
static func line(text: String, args := {}) -> Dictionary:
    return {"text": text, "args": args}


## Make a line of text followed by another one (e.g., a riddle and then the
## port where it leads), translated each on its own.
static func line_then(first: Dictionary, then: Dictionary) -> Dictionary:
    var result := first.duplicate(true)
    result["then"] = then
    return result


## Translate a line: the text and every argument which is a message (the names
## and the facts are messages, too), in the grammatical forms which the
## translation asks for (see Grammar), and the line which follows it, if any.
## The line addresses the captain of [param player] alone, or the whole crew
## (-1).
func say(a_line: Dictionary, player := -1) -> String:
    var before := Grammar.addressed
    Grammar.addressed = player
    var text := Grammar.format(tr(a_line.get("text", "")), a_line.get("args", {}))
    if a_line.has("then"):
        text += " " + say(a_line["then"], player)
    Grammar.addressed = before
    return text


## The state of the run as plain data, for the save of the voyage (see
## DESIGN.md, "Saving a mission in progress"): the plan which the steps drew,
## the step, the clock, what the crew learned and carries, and the errands.
func to_data() -> Dictionary:
    var holds_data: Array = []
    for each in holds:
        (
            holds_data
            . append(
                {
                    "provisions": each.provisions,
                    "damage": each.damage,
                    "ducats": each.ducats,
                    "spent": each.spent,
                    "cargo": each.cargo.duplicate(),
                }
            )
        )
    var hallmark_ids: Array = []
    for hallmark in hallmarks:
        hallmark_ids.append(hallmark.id)
    var booster_ids: Array = []
    for booster in bag.boosters:
        booster_ids.append(booster.id)
    return {
        "mission": mission.id,
        "step": step_index,
        "days": days,
        "plan": plan.duplicate(true),
        "clue": clue.duplicate(true),
        "hallmarks": hallmark_ids,
        "boosters": booster_ids,
        "errands": errands.duplicate(true),
        "holds": holds_data,
        "brought": brought,
    }


## Restore the state of [method to_data] (the run was made for the same
## mission); return whether it worked.
func restore(data: Dictionary) -> bool:
    if str(data.get("mission", "")) != mission.id:
        return false
    step_index = clampi(int(data.get("step", 0)), 0, mission.steps.size() - 1)
    days = float(data.get("days", 0.0))
    var saved_plan: Dictionary = _whole(data.get("plan", {}))
    for key in saved_plan:
        plan[key] = saved_plan[key]
    clue = data.get("clue", {})
    hallmarks.clear()
    for hallmark_id in data.get("hallmarks", []):
        var hallmark: Hallmark = load("res://data/world/hallmarks/%s.tres" % hallmark_id)
        if hallmark != null:
            hallmarks.append(hallmark)
    bag.boosters.clear()
    for booster_id in data.get("boosters", []):
        var booster: Booster = load("res://data/world/boosters/%s.tres" % booster_id)
        if booster != null:
            bag.boosters.append(booster)
    errands.clear()
    for errand in data.get("errands", []):
        errands.append(_whole(errand))
    brought = int(data.get("brought", 0))
    var saved_holds: Array = data.get("holds", [])
    for i in range(mini(saved_holds.size(), holds.size())):
        var saved: Dictionary = saved_holds[i]
        holds[i].provisions = float(saved.get("provisions", holds[i].max_provisions))
        holds[i].damage = float(saved.get("damage", 0.0))
        holds[i].ducats = int(saved.get("ducats", 0))
        holds[i].spent = int(saved.get("spent", 0))
        holds[i].cargo.clear()
        for item_id in saved.get("cargo", []):
            holds[i].cargo.append(str(item_id))
    return true


## JSON makes every number a float; the plan uses whole numbers as indices.
static func _whole(value: Variant) -> Variant:
    if value is float and value == floorf(value):
        return int(value)
    if value is Array:
        var result := []
        for element in value:
            result.append(_whole(element))
        return result
    if value is Dictionary:
        var result := {}
        for key in value:
            result[key] = _whole(value[key])
        return result
    return value
