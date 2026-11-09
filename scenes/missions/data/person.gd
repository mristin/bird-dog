class_name Person
extends Resource

## A person of the story or a local in a port, with a portrait from the
## costume books of the time.

@export var id := ""

## The name, in English (translated by the .po files).
@export var name := ""

## The role, e.g., "fisherman"; shown under the name.
@export var role := ""

## "m" or "f", for the grammatical forms of the lines about them.
@export var gender := "m"

@export var portrait: Texture2D

## How the players recognize the person in a line-up, e.g., "a grey beard".
@export var hallmarks: Array[Hallmark] = []
