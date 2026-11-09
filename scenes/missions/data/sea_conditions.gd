class_name SeaConditions
extends Resource

## The sea of a mission: its winds and how often they change, the clouds, the
## corsairs and the patrols, the barrels, and how fast the boats sail (see
## DESIGN.md, section 15).

@export var winds: Array[WindChance] = []

## The wind changes every so many seconds: (the shortest, the longest).
@export var change_seconds := Vector2(40, 90)

## How many storm clouds are out at once: (the fewest, the most).
@export var clouds := Vector2i(0, 0)

@export var corsairs := true
@export var patrols := true

## How many corsairs and patrols are out at once, at most.
@export var corsair_count := 3
@export var patrol_count := 2

## How many barrels with ducats float in the sea.
@export var barrels := 6

## The speed of the boats, so that a leg takes a minute or a minute and a half.
@export var speed_scale := 1.0

## Whether some of the clouds are storms (on the open sea): bigger, darker,
## slower, with stronger gusts and more lightning.
@export var storms := false
