class_name Chapter
extends Resource

## A chapter of the voyage: a villain of its own, a coast of its own and a
## finale before a judge (see DESIGN.md, "The chapters"). The missions name
## their chapter by its number (Mission.chapter).

## The number: 1 is the first.
@export var number := 1

## The title and the summary, in English (translated by the .po files).
@export var title := ""
@export_multiline var summary := ""
