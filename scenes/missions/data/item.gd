class_name Item
extends Resource

## A thing which the crew fetches or delivers: the bell, a load of salt, the
## ledger.

@export var id := ""

## The name, in English (translated by the .po files).
@export var name := ""

@export var picture: Texture2D

## How the HUD shows the item (see CargoIcons): "bell", "sack", "bottle",
## "letter", "sealed", "amphora", "sail", "jar", "book", "timber", "oranges",
## "basket", "rope" or "barrel".
@export var icon := ""

## The person, if the "item" is somebody whom the crew carries (a passenger or
## a witness): the HUD shows their portrait.
@export var person: Person
