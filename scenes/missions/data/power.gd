class_name Power
extends Resource

## A power of the Adriatic around 1600: Venice, Ragusa, the Ottomans, the
## Habsburgs, the Papal States or Naples (see DESIGN.md, section 2).

@export var id := ""

## The name, in English (translated by the .po files).
@export var name := ""

## Whether its patrols stop "suspected uskoks" (from mission 3 on).
@export var patrols := false

## What the merchants in its ports sell (see DESIGN.md, section 10): Venice
## sells flags, the Ottoman ports figs for the corsairs, and so on.
@export var offers: Array[Booster] = []
