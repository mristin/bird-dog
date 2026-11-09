class_name HearingStep
extends MissionStep

## Somebody asks the crew questions, right where the crew is (see DESIGN.md,
## section 15): the kadı's hearing, or the riddle of the Pope's envoy. A wrong
## answer only makes them ask again.

@export var speaker: Person

## What the speaker says before the first question, in English.
@export var intro: Array[String] = []

@export var questions: Array[HearingQuestion] = []

## What the speaker says after a wrong answer, in English.
@export var wrong_line := "Hmm, no. Think again!"

## What the speaker says when all is answered, in English.
@export var right_lines: Array[String] = []


func plan(run: MissionRun, _rng: RandomNumberGenerator) -> void:
    run.plan[id] = {"index": 0, "wrong": false, "done": false}


func _question(run: MissionRun) -> Dictionary:
    var state: Dictionary = run.plan[id]
    var question := questions[state["index"]]
    var lines: Array = []
    if state["index"] == 0 and not state["wrong"]:
        for text in intro:
            lines.append(MissionRun.line(text))
    if state["wrong"]:
        lines.append(MissionRun.line(wrong_line))
    lines.append(MissionRun.line(question.question))
    var scene := MissionStep.talk(speaker, lines, MissionRun.line(""))
    var buttons: Array = []
    for i in range(question.answers.size()):
        buttons.append({"label": MissionRun.line(question.answers[i]), "action": "answer:%d" % i})
    scene["buttons"] = buttons
    return scene


func start(run: MissionRun) -> void:
    run.set_clue(MissionRun.line(questions[0].question))


func opening(run: MissionRun) -> Variant:
    return _question(run)


func act(run: MissionRun, action: String) -> Variant:
    var state: Dictionary = run.plan[id]
    if action == "done":
        state["done"] = true
        return null
    if not action.begins_with("answer:"):
        return null
    if int(action.get_slice(":", 1)) != questions[state["index"]].correct:
        state["wrong"] = true
        return _question(run)
    state["wrong"] = false
    state["index"] += 1
    if state["index"] < questions.size():
        return _question(run)
    var lines: Array = []
    for text in right_lines:
        lines.append(MissionRun.line(text))
    return MissionStep.talk(speaker, lines, MissionRun.line("Thank you!"), "done")


func solution(run: MissionRun) -> String:
    var state: Dictionary = run.plan[id]
    if state["index"] >= questions.size():
        return "done"
    return "answer:%d" % questions[state["index"]].correct


func is_done(run: MissionRun) -> bool:
    return run.plan[id]["done"]
