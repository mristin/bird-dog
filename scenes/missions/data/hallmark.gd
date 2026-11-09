class_name Hallmark
extends Resource

## A mark by which the players recognize a person or a boat in a line-up:
## "a patched red sail", "a grey beard" (see DESIGN.md, section 15, where it is
## called a trait).

@export var id := ""

## The phrase, in English, which fits into "It had {hallmark}.".
@export var phrase := ""

## What the mark is about: "sail", "hull", "clothes", "hair" or "thing".
@export var kind := "sail"
