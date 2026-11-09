class_name Mission
extends Resource

## A mission: its header for the mission select, its sea, its clock, and the
## steps which make up its story (see DESIGN.md, section 15). A mission without
## steps is listed, but not playable yet.

## The id, used in the save files; never change it.
@export var id := ""

## The order: 1 is the first; finishing mission n unlocks n + 1.
@export var number := 1

## The title and the summary, in English (translated by the .po files).
@export var title := ""
@export_multiline var summary := ""

@export var start_port: Port

## The mission clock, in days.
@export var clock_days := 6.0

@export var sea: SeaConditions

@export var steps: Array[MissionStep] = []

## The share of the clock which must be left for three stars; any time left
## gives two stars, and finishing at all one star.
@export_range(0.0, 1.0) var three_stars_share := 0.34

## How many days the food and the water on board last; every port fills the
## barrels again (see DESIGN.md, "Provisions"). One load has to last at least
## 1.2 times the widest crossing of the Adriatic (Bari to Dubrovnik, about
## 200 km, which is 2 days), so that the crew can always cross the sea; a
## longer leg forces the crew to stop in a port on the way.
@export var provisions_days := 10.8

## What the crew has on board at the start (e.g., a sack of salt to trade).
@export var start_cargo: Array[Item] = []

## A fun fact about a place of the mission, shown at the end, in English.
@export_multiline var fun_fact := ""

@export_group("Mission complete")

## The headline of the screen at the end, in English, e.g., "The bell rings
## again!".
@export var victory_title := "Mission accomplished!"

## What the crew achieved, in English, one line each.
@export var victory_lines: Array[String] = []

## What the crew gets from now on, in English, or "" for nothing.
@export var reward := ""

## The picture behind the screen (a port of the story); null takes the
## picture of the start port.
@export var victory_picture: Texture2D

## Who smiles on the screen (the happy person of the story).
@export var victory_person: Person

## Whether this mission ends the voyage (the medal of the Bird Dog).
@export var finale := false


func is_playable() -> bool:
    return not steps.is_empty()


## This mission, but starting in the port of [param port_id] (for the test
## screens); the mission itself if the id is empty.
func starting_in(port_id: String) -> Mission:
    if port_id == "":
        return self
    var copy: Mission = duplicate()
    copy.start_port = World.port(port_id)
    return copy
