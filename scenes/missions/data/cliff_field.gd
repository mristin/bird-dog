class_name CliffField
extends Resource

## A stretch of steep coast with cliffs, e.g., the cliffs of Telašćica or of the
## Gargano (see DESIGN.md, "Reefs and cliffs"). Here, and only here, running
## ashore damages the hull; everywhere else the coast is harmless.

@export var id := ""

## The name on the chart, in English (translated by the .po files).
@export var name := ""

## The middle of the stretch.
@export var latitude := 0.0
@export var longitude := 0.0

## How far the cliffs reach from the middle, in kilometres.
@export var radius_km := 6.0
