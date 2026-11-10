class_name Port
extends Resource

## A port of the Adriatic: where it is, which power holds it, the facts which
## identify it in the clues, its picture and the locals who greet the crew
## (see DESIGN.md, section 15).

@export var id := ""

## The name, in English (translated by the .po files).
@export var name := ""

@export var latitude := 0.0
@export var longitude := 0.0

@export var power: Power

@export var facts: Array[PortFact] = []

## The view of the town, from the prints of the time; may be null.
@export var picture: Texture2D

## The icon on the chart, which shows what the port is known for (see
## PortIcons.NAMES), e.g., "arena" for Pula.
@export var icon := ""

## The locals who greet the crew, in turn.
@export var locals: Array[Person] = []

## The id of a port in the same bay, which the crew reaches from this one with
## a button of the port, since the way between them is too narrow to sail
## (Herceg Novi and Kotor); "" for none.
@export var bay_port_id := ""
