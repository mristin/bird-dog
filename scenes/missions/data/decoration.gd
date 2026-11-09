class_name Decoration
extends Resource

## A decoration of a boat from Master Ivan's shipyard (see DESIGN.md, section
## 10): a sail, a hull paint, a pennant, a figurehead, streamers, lanterns or a
## friend on board. Decorations are only for looks and never change the speed.

## The places on a boat, in the order of the shipyard; a boat has at most one
## decoration in every place.
const SLOTS: Array[String] = [
    "sail", "hull", "flag", "figurehead", "streamers", "lanterns", "friend"
]

@export var id := ""

## The name, in English (translated by the .po files).
@export var name := ""

## Where it goes: one of [constant SLOTS].
@export var slot := "sail"

## The price in ducats.
@export var price := 30

## The colours, e.g., of a sail and of its pattern.
@export var color := Color.WHITE
@export var color_2 := Color.WHITE

## What it shows: for a sail "plain", "stripes", "sun", "star", "gull" or
## "initial"; for a hull "plain" or "band"; for a figurehead "dolphin",
## "lion", "gull", "mermaid" or "goat"; for a friend "cat", "parrot", "dog" or
## "goat".
@export var pattern := "plain"
