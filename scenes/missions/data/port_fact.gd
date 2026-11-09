class_name PortFact
extends Resource

## One thing which identifies a port, as a noun phrase which fits into every
## clue template: "the town with the great Roman arena" (see DESIGN.md, "The
## facts of the ports"). Every fact belongs to exactly one port.

## What the fact is about: "landmark", "saint", "goods", "power", "person" or
## "nature".
@export var kind := "landmark"

## The phrase, in English.
@export var phrase := ""

## 1 (easy) to 3 (hard); a mission limits the difficulty of its clues.
@export_range(1, 3) var difficulty := 1
