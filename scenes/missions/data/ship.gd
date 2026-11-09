class_name Ship
extends Resource

## A kind of ship from Master Ivan's shipyard (see DESIGN.md, section 10): every
## captain starts with the smallest, a gajeta, and may buy a bigger or a faster
## one, for very many ducats. Unlike the decorations, a ship changes how the
## boat sails: how fast, how quickly it turns, how much food it stows (the
## rations, see ProvisionsPanel), and how many goods of errands it carries.

## The rations of the bracera, which the mission's provisions are made for.
const BRACERA_RATIONS := 3

@export var id := ""

## The name and what it is good at, in English (translated by the .po files).
@export var name := ""
@export var description := ""

## The price in ducats; 0 for the ship every captain starts with.
@export var price := 0

## How many masts with sails it has (1 to 3), and how long it is drawn, as a
## share of the bracera.
@export_range(1, 3) var masts := 2
@export var length := 1.0

## Oars: the crew rows, so that the ship is not so slow into the wind.
@export var oars := false

## How fast it sails and how quickly it turns, as shares of the bracera.
@export var speed := 1.0
@export var turn := 1.0

## How many rations of food and water it stows; a ration lasts a third of the
## mission's provisions (see Mission.provisions_days).
@export_range(1, 5) var rations := 3

## How many goods of errands it carries at once (see Errands).
@export var errands := 2
