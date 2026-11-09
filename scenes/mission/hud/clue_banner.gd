class_name ClueBanner
extends Control

## Show the current clue (or objective) on a strip of paper at the top, and,
## big and red, the port where the crew has to go (the chart points to it, too).

var run: MissionRun


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    if run == null or run.clue.is_empty():
        return
    var font := ThemeDB.fallback_font
    # NOTE (mristin):
    # The port of the clue stands big and red below, so the clue goes without
    # its "Sail to ..." (see MissionRun.line_then).
    var clue := run.clue.duplicate()
    clue.erase("then")
    var text := run.say(clue)
    draw_rect(Rect2(Vector2(6, 8), size), Color(0, 0, 0, 0.2))
    draw_rect(Rect2(Vector2.ZERO, size), Color(Paper.PAPER, 0.96))
    draw_rect(Rect2(Vector2.ZERO, size), Paper.INK, false, 3.0)
    var font_size := HandButton.fit_size(font, text, 30, (size.x - 60) * 2.0)
    draw_multiline_string(
        font,
        Vector2(30, 44),
        text,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 60,
        font_size,
        2,
        Paper.INK
    )
    var step := run.step()
    var targets: Array[Port] = []
    if step != null:
        targets = step.target_ports(run)
    if not targets.is_empty():
        var go := Grammar.format(tr("Sail to {port}!"), {"port": targets[0].name})
        if targets.size() > 1:
            var names: Array[String] = []
            for target in targets:
                names.append(tr(target.name))
            go = Grammar.format(
                tr("Sail to one of: {ports}"), {"ports": ", ".join(PackedStringArray(names))}
            )
        draw_string(
            font,
            Vector2(30, size.y - 18),
            go,
            HORIZONTAL_ALIGNMENT_CENTER,
            size.x - 60,
            40,
            Paper.RED
        )
