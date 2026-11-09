class_name ReefField
extends Resource

## A field of reefs (in Croatian "hridi"): rocks just under the water at a
## special place of the Adriatic, e.g., the reefs of the Kornati or the rocks
## of Palagruža (see DESIGN.md, "Reefs"). A boat which runs onto a rock damages
## its hull; the coasts themselves never do.

@export var id := ""

## The name on the chart, in English (translated by the .po files).
@export var name := ""

## The middle of the field.
@export var latitude := 0.0
@export var longitude := 0.0

## How far the rocks lie from the middle, in kilometres.
@export var radius_km := 6.0

## How many rocks there are.
@export var rocks := 6
