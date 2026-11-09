class_name ItemSource
extends Resource

## Where the crew can get an item in a CollectStep: the port, the person who
## gives it, and what they say.

@export var item: Item
@export var port: Port
@export var person: Person

## What the person says when giving the item, in English.
@export var lines: Array[String] = []
