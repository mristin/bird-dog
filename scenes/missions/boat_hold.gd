class_name BoatHold
extends RefCounted

## What a boat of the crew carries in a mission: its food and water, the
## damage of its hull, its ducats, and its cargo (see DESIGN.md, "Two
## players"). With two players, every boat has its own hold, and the boats
## can exchange what they carry when they meet.

## The kind of ship (see Ship): how many rations it stows, how many goods.
var ship: Ship

## How many days the food and the water still last, and at most (all the
## rations of the ship full).
var provisions := 0.0
var max_provisions := 0.0

## The damage of the hull from the reefs and the cliffs, from 0 to 100; at 100,
## the boat has to be towed to a port.
var damage := 0.0

## The ducats this boat carries (what the crew brought along into the
## mission and what it earned in it), and what it spent of them at the
## merchants. There is no chest at home: all the ducats are on board, and the
## corsairs and the patrols can take them.
var ducats := 0
var spent := 0

## The ids of the items on board.
var cargo: Array[String] = []


## [param provisions_days] is how long the food of a bracera lasts in the
## mission (three rations); other ships stow more or fewer rations.
func _init(provisions_days: float, the_ship: Ship = null) -> void:
    ship = the_ship if the_ship != null else World.ships()[0]
    max_provisions = provisions_days * ship.rations / float(Ship.BRACERA_RATIONS)
    provisions = max_provisions


## The ducats on board: what the boat earned, less what it spent.
func on_board() -> int:
    return maxi(0, ducats - spent)


## The corsairs or the Venetian patrols take [param amount] ducats, or all
## on board if there are fewer (see SeaHazards); return how many.
func steal(amount: int) -> int:
    var stolen := mini(amount, on_board())
    ducats -= stolen
    return stolen


## Put one more ration of food and water ([param ration_days] long) into the
## barrels, as much as fits. A port gives one for free; the other rations of a
## bigger ship have to be bought (see BoosterBag.buy).
func add_ration(ration_days: float) -> void:
    provisions = minf(max_provisions, provisions + ration_days)


## Whether a whole ration of food and water still fits into the barrels
## (otherwise, the merchants don't offer one).
func has_room_for(ration_days: float) -> bool:
    return provisions + ration_days <= max_provisions + 0.001


func add_damage(amount: float) -> void:
    damage = clampf(damage + amount, 0.0, 100.0)


func is_wrecked() -> bool:
    return damage >= 100.0


func is_out_of_provisions() -> bool:
    return provisions <= 0.0


## The shipwrights of a port repair the hull; return the days it takes (more
## for a bigger damage).
func repair() -> float:
    var spent_days := damage / 100.0 * 0.5
    damage = 0.0
    return spent_days


## Give half of the food and the water to the other boat.
func give_provisions(other: BoatHold) -> void:
    var half := provisions * 0.5
    provisions -= half
    other.provisions += half


## Give some ducats on board to the other boat; return how many were given.
func give_ducats(other: BoatHold, amount: int) -> int:
    var given := mini(amount, on_board())
    ducats -= given
    other.ducats += given
    return given


func give_item(other: BoatHold, item_id: String) -> void:
    if cargo.has(item_id):
        cargo.erase(item_id)
        other.cargo.append(item_id)
