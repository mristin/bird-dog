class_name MissionCard
extends HandButton

## A card of the mission select: the number and the title of the mission, its
## stars (up to three), or a padlock while the mission is locked. The title
## wraps onto at most [constant TITLE_LINES] lines, and shrinks if it must.

## The size of the card, so that fifteen of them fit the screen (5 x 3) below
## the tabs of the chapters.
const SIZE := Vector2(330, 190)

const TITLE_SIZE := 30
const TITLE_LINES := 2

## The smallest readable size of a title (the tests check it).
const READABLE := 22

var number := 1
var stars := 0
var locked := false

## The title of the mission (translated).
var title_text := ""


## Lay the title out on at most [constant TITLE_LINES] lines of the width:
## {"size": font size, "lines": [line, ...]}.
static func title_layout(font: Font, text: String, width: float) -> Dictionary:
    var font_size := TITLE_SIZE
    while true:
        var lines := _wrap(font, text, font_size, width)
        if font_size <= 12 or lines.size() <= TITLE_LINES:
            return {"size": font_size, "lines": lines}
        font_size -= 1
    return {}


## Wrap the words greedily; a line which is too long even alone counts as too
## many lines, so that the text shrinks.
static func _wrap(font: Font, text: String, font_size: int, width: float) -> Array[String]:
    var lines: Array[String] = []
    var current := ""
    for word in text.split(" ", false):
        var candidate := word if current == "" else current + " " + word
        if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
            current = candidate
            continue
        if current != "":
            lines.append(current)
        current = word
        if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
            lines.append_array(["", "", ""])
    if current != "":
        lines.append(current)
    return lines


func _draw() -> void:
    super()
    var font := ThemeDB.fallback_font
    var center_x := size.x * 0.5

    var badge := Vector2(center_x, 40)
    draw_circle(badge, 26, Paper.RED if not locked else Color(Paper.INK, 0.35))
    draw_string(
        font, badge + Vector2(-40, 11), str(number), HORIZONTAL_ALIGNMENT_CENTER, 80, 32, Paper.CARD
    )

    var layout := title_layout(font, title_text, size.x - 20.0)
    var line_height: float = layout["size"] * 1.15
    var y: float = 104.0 - line_height * layout["lines"].size() * 0.5 + layout["size"] * 0.9
    for line in layout["lines"]:
        draw_string(
            font,
            Vector2(0, y),
            line,
            HORIZONTAL_ALIGNMENT_CENTER,
            size.x,
            layout["size"],
            Paper.INK
        )
        y += line_height

    if locked:
        _draw_padlock(Vector2(center_x, size.y - 28))
        draw_rect(Rect2(Vector2.ZERO, size), Color(Paper.PAPER_DARK, 0.45))
        return

    for i in range(3):
        _draw_star(Vector2(center_x + (i - 1) * 44, size.y - 27), 17.0, i < stars)


func _draw_star(center: Vector2, radius: float, filled: bool) -> void:
    var points := PackedVector2Array()
    for i in range(10):
        var r := radius if i % 2 == 0 else radius * 0.45
        points.append(center + Vector2.UP.rotated(i * PI / 5) * r)
    if filled:
        draw_colored_polygon(points, Paper.GOLD)
    var outline := points.duplicate()
    outline.append(points[0])
    draw_polyline(outline, Paper.INK if filled else Color(Paper.INK, 0.45), 3.0, true)


func _draw_padlock(center: Vector2) -> void:
    var ink := Color(Paper.INK, 0.8)
    draw_arc(center + Vector2(0, -10), 12, PI, TAU, 16, ink, 5.0, true)
    draw_line(center + Vector2(-12, -10), center + Vector2(-12, 0), ink, 5.0, true)
    draw_line(center + Vector2(12, -10), center + Vector2(12, 0), ink, 5.0, true)
    draw_rect(Rect2(center + Vector2(-18, -2), Vector2(36, 27)), ink)
    draw_circle(center + Vector2(0, 11), 4, Paper.CARD)
