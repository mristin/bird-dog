class_name Boat
extends Resource

## A boat as the players see it in a harbour, e.g., in a line-up: its sail and
## its hull, and the hallmarks which describe it.

@export var id := ""

## What the boat is, in English, e.g., "a fishing boat".
@export var name := ""

@export var sail_color := Color(0.95, 0.92, 0.82)
@export var hull_color := Color(0.42, 0.26, 0.13)

## Whether the sail has patches.
@export var patched := false

@export var hallmarks: Array[Hallmark] = []
