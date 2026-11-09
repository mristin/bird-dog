class_name CargoPanel
extends Control

## Show what a boat carries (see BoatHold.cargo) on a panel like the others:
## four slots, empty ones as dashed rings, which fill with the items (as
## pictures) and the passengers (as small portraits, see CargoIcons), each with
## its name under it, and, for the goods of an errand, where they go. So the
## players always see which boat carries what, and whom.

## How many slots the panel shows.
const SLOTS := 4

var run: MissionRun

## The player whose boat the panel shows.
var player := 0

var _shown := ""


func _process(_delta: float) -> void:
    # NOTE (mristin):
    # Redraw only when the cargo or the errands change.
    if run == null:
        return
    var now := ",".join(PackedStringArray(run.hold(player).cargo)) + str(run.errands.size())
    if now != _shown:
        _shown = now
        queue_redraw()


func _draw() -> void:
    if run == null:
        return
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(Vector2(6, 8), size), Color(0, 0, 0, 0.2))
    draw_rect(Rect2(Vector2.ZERO, size), Color(Paper.PAPER, 0.95))
    draw_rect(Rect2(Vector2.ZERO, size), Paper.INK, false, 3.0)
    draw_string(font, Vector2(14, 28), tr("On board"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Paper.INK)

    var cargo := run.hold(player).cargo
    var step := (size.x - 20.0) / SLOTS
    for i in range(SLOTS):
        var center := Vector2(10 + step * (i + 0.5), 66)
        if i >= cargo.size():
            _draw_empty(center)
            continue
        var item := World.item(cargo[i])
        if item == null:
            _draw_empty(center)
            continue
        if i == SLOTS - 1 and cargo.size() > SLOTS:
            var more := "+%d" % (cargo.size() - SLOTS + 1)
            draw_circle(center, 28, Paper.CARD)
            draw_arc(center, 28, 0, TAU, 28, Paper.INK, 2.5, true)
            draw_string(
                font,
                center + Vector2(-40, 12),
                more,
                HORIZONTAL_ALIGNMENT_CENTER,
                80,
                32,
                Paper.INK
            )
            continue
        draw_circle(center, 28, Paper.CARD)
        draw_arc(center, 28, 0, TAU, 28, Paper.INK, 2.5, true)
        CargoIcons.draw(self, item, center, 24)
        _draw_label(font, tr(item.name), Vector2(center.x - step * 0.5, 112), step, Paper.INK)

        # NOTE (mristin):
        # The goods of an errand tell where they go, on a line of their own.
        for errand in run.errands:
            if errand["item"] == item.id:
                var to := "→ " + Grammar.format(tr("to {port}"), {"port": errand["port_name"]})
                _draw_label(font, to, Vector2(center.x - step * 0.5, 132), step, Paper.RED)
                break


## An empty slot: a faint dashed ring.
func _draw_empty(center: Vector2) -> void:
    var dashes := 16
    for k in range(dashes):
        var start := TAU * k / dashes
        draw_arc(
            center, 28, start, start + TAU / dashes * 0.55, 4, Color(Paper.INK, 0.35), 2.0, true
        )


func _draw_label(font: Font, text: String, at: Vector2, width: float, color: Color) -> void:
    draw_string(
        font,
        at,
        text,
        HORIZONTAL_ALIGNMENT_CENTER,
        width,
        HandButton.fit_size(font, text, 18, width - 4),
        color
    )
