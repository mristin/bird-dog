class_name HearingQuestion
extends Resource

## A question in a HearingStep (or a riddle): the question, the answers to
## choose from, and which one is right.

@export var question := ""
@export var answers: Array[String] = []
@export var correct := 0
