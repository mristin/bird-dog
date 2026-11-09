class_name WindChance
extends Resource

## A wind of the Adriatic and how often it blows in a sea (see DESIGN.md, "The
## view at sea").

## The name: "bura", "jugo", "maestral", "tramontana", "levant", "lebic",
## "ostro" or "pulenat".
@export var name := "maestral"

## Where the wind blows FROM, in degrees: 0 is north, 90 east.
@export var from_degrees := 315.0

## The weights of the intensities: light, fresh and strong.
@export var intensities := Vector3(1, 1, 0)

## How often this wind blows, relative to the others of the sea.
@export var weight := 1.0
