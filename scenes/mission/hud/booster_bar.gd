class_name BoosterBar
extends Control

## Show the boosters the crew holds, as round badges with their pictures,
## next to the other panels (see DESIGN.md, section 10).

var run: MissionRun

var _shown := -1


func _process(_delta: float) -> void:
    # NOTE (mristin):
    # Redraw only when the boosters change.
    if run != null and run.bag.boosters.size() != _shown:
        _shown = run.bag.boosters.size()
        queue_redraw()


func _draw() -> void:
    if run == null:
        return
    for i in range(run.bag.boosters.size()):
        var center := Vector2(40 + i * 86, size.y * 0.5)
        draw_circle(center + Vector2(4, 5), 36, Color(0, 0, 0, 0.2))
        draw_circle(center, 36, Paper.PAPER)
        draw_arc(center, 36, 0, TAU, 32, Paper.GOLD, 4.0, true)
        BoosterIcons.draw(self, run.bag.boosters[i].effect, center, 26)
