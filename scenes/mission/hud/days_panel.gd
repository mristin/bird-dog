class_name DaysPanel
extends Control

## Show the mission clock: a sun for every day of the mission, the used days
## faded, and how many days are left.

var run: MissionRun


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    if run == null:
        return
    draw_rect(Rect2(Vector2.ZERO, size), Color(Paper.PAPER, 0.92))
    draw_rect(Rect2(Vector2.ZERO, size), Paper.INK, false, 3.0)
    var total := int(ceil(run.mission.clock_days))
    var used := run.days
    # NOTE (mristin):
    # A long mission has many days; the suns shrink to fit the panel.
    var spacing := minf(46.0, (size.x - 40.0) / maxf(1.0, total))
    var scale := spacing / 46.0
    for i in range(total):
        var at := Vector2(20 + spacing * 0.5 + i * spacing, 40)
        var share := clampf(1.0 - (used - i), 0.0, 1.0)
        var color := Paper.GOLD.lerp(Color(Paper.INK, 0.15), 1.0 - share)
        for k in range(8):
            var ray := Vector2.UP.rotated(k * TAU / 8)
            draw_line(at + ray * 15 * scale, at + ray * 21 * scale, color, 3.0 * scale, true)
        draw_circle(at, 12 * scale, color)
    var left := Grammar.format(tr("Days left: {days}"), {"days": int(ceil(run.days_left()))})
    draw_string(
        ThemeDB.fallback_font,
        Vector2(16, 98),
        left,
        HORIZONTAL_ALIGNMENT_LEFT,
        size.x - 32,
        30,
        Paper.INK
    )
