class_name Booster
extends Resource

## Something the merchant of a port sells (see DESIGN.md, section 10): new
## sails, a weather-wise fisherman, a local pilot, the right flag, figs for
## the corsairs, fresh bread and water, lots of cannons, a skilled helmsman,
## a barrel of salted fish, strong rowers, or a decoration for the boat (a
## figurehead, a flag, ...), which stays for good.
##
## The effect is a word which the mission screen understands; a booster lasts
## the next leg (until the next port), until it is used, or acts at once. Every
## merchant shows four boosters of all, drawn anew at every visit.

@export var id := ""

## The name and what it does, in English (translated by the .po files).
@export var name := ""
@export var description := ""

## The price in ducats.
@export var price := 20

## "speed", "weather", "pilot", "flag", "figs", "time", "cannons", "nimble"
## (turn quicker), "food" (eat slower), "oars" (row into the wind) or
## "decoration".
@export var effect := ""

## "leg" (until the next port), "use" (until it is used) or "now" (at once).
@export var lasts := "leg"

## The decoration which the booster puts on the boat of the captain for good
## (the effect "decoration"), or null.
@export var decoration: Decoration
