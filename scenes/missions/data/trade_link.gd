class_name TradeLink
extends Resource

## A link of a chain of trades (see TradeStep): the person in the port wants
## an item and gives another one for it.

@export var port: Port
@export var person: Person

## What the person wants; null for nothing (they give freely).
@export var wants: Item

## What the person gives; null for nothing (the end of the chain gives the
## story's prize through the next step).
@export var gives: Item

## What the person says while the crew does not have what they want, in
## English: this tells the crew where to go next.
@export var ask_lines: Array[String] = []

## What the person says when the trade is done, in English.
@export var thanks_lines: Array[String] = []
