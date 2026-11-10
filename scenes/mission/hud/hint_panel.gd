class_name HintPanel
extends Control

## A tip from Baba Stana, the first time something happens (see DESIGN.md,
## "Hints"): the food runs low, reefs ahead, a storm cloud, corsairs, the
## wind against the boat... It shows for a while on a small sheet of paper in
## the half of the player, then fades. It never stops the game.

## How long a tip shows, in seconds.
const SECONDS := 9.0

var _text := ""
var _age := SECONDS


## The tips, by their id (see Tips.check).
func texts() -> Dictionary:
    return {
        "provisions":
        tr("Food and water run out with the days. Every port gives one ration free; buy more!"),
        "reefs": tr("Reefs ahead! Keep away from the rocks in the white surf."),
        "cliffs": tr("Steep cliffs! Running ashore here damages the hull."),
        "damage": tr("The hull is damaged. Every port repairs it."),
        "cloud": tr("A storm cloud! Inside, the boat sails slowly. Steer out of it."),
        "corsair":
        tr("The black flag of the corsairs! They take 50 ducats. Flee, or sail to a patrol!"),
        "patrol": tr("The star of a Venetian patrol! They want a bribe. The right flag helps."),
        "loot": tr("A floating barrel! Sail over it to pick up the ducats."),
        "into_wind": tr("No boat sails into the wind! Zigzag across it: left, then right."),
        "wind_change": tr("The wind is changing! The wind rose shows which wind comes."),
        "errand": tr("Bring the goods to the port with the blue ring on the chart."),
    }


func show_tip(text: String) -> void:
    _text = text
    _age = 0.0


func _process(delta: float) -> void:
    if _age < SECONDS:
        _age += delta
        queue_redraw()


func _draw() -> void:
    if _age >= SECONDS or _text == "":
        return
    var alpha := clampf(minf(_age / 0.4, (SECONDS - _age) / 0.8), 0.0, 1.0)
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(Vector2(6, 8), size), Color(0, 0, 0, 0.2 * alpha))
    draw_rect(Rect2(Vector2.ZERO, size), Color(Paper.PAPER, 0.97 * alpha))
    draw_rect(Rect2(Vector2.ZERO, size), Color(Paper.GOLD, alpha), false, 4.0)
    draw_string(
        font,
        Vector2(18, 34),
        tr("A tip from Baba Stana"),
        HORIZONTAL_ALIGNMENT_LEFT,
        size.x - 36,
        24,
        Color(Paper.RED, alpha)
    )
    var text_size := 26
    while (
        text_size > 18
        and (
            (
                font
                . get_multiline_string_size(
                    _text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, text_size
                )
                . y
            )
            > size.y - 54
        )
    ):
        text_size -= 1
    draw_multiline_string(
        font,
        Vector2(18, 70),
        _text,
        HORIZONTAL_ALIGNMENT_LEFT,
        size.x - 36,
        text_size,
        -1,
        Color(Paper.INK, alpha)
    )
