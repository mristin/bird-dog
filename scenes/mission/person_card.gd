class_name PersonCard
extends HandButton

## A person in a line-up, as a button: their portrait from the costume books,
## and under it what one sees of them (their hallmarks), so that the players
## can compare with what they remember. The hallmarks stand in the order of
## their kind (the clothes, the hair, the things), never in the order the
## crew learned them, which would give the answer away.

## The size of the hallmarks on the whole screen and on a half of it; a long
## hallmark wraps onto more lines, and the portrait gives way to it.
const TEXT_SIZE := 28
const HALF_TEXT_SIZE := 20

## The hallmarks leave at least this share of the height of the card to the
## portrait: the hallmarks are what the crew compares, the portrait only shows
## the person (see tests/godot/test_dialogue_layout.gd).
const MIN_PORTRAIT_SHARE := 0.3

## The margin of the portrait and of the hallmarks to the edges of the card.
const MARGIN := 16.0

var person: Person


func _draw() -> void:
    super()
    if person == null:
        return
    var font := ThemeDB.fallback_font
    var placed := layout()
    var area: Rect2 = placed["portrait"]
    if person.portrait != null and area.size.y > 0.0:
        var portrait_size := person.portrait.get_size()
        var scale := minf(area.size.x / portrait_size.x, area.size.y / portrait_size.y)
        var drawn := portrait_size * scale
        var at := area.position + (area.size - drawn) * 0.5
        draw_texture_rect(person.portrait, Rect2(at, drawn), false)
        draw_rect(Rect2(at, drawn), Paper.INK, false, 2.0)
    for hallmark: Dictionary in placed["hallmarks"]:
        draw_multiline_string(
            font,
            Vector2(MARGIN, hallmark["top"] + font.get_ascent(text_size)),
            hallmark["text"],
            HORIZONTAL_ALIGNMENT_CENTER,
            placed["width"],
            text_size,
            -1,
            Paper.INK
        )


## Where everything stands on the card: the hallmarks ({"text", "top"}, in the
## order of their kind, wrapped to "width") at the bottom, and the area of the
## portrait above them.
func layout() -> Dictionary:
    var font := ThemeDB.fallback_font
    var width := size.x - MARGIN * 2.0
    var gap := font.get_height(text_size) * 0.25
    var sorted: Array[Hallmark] = person.hallmarks.duplicate()
    sorted.sort_custom(func(a: Hallmark, b: Hallmark) -> bool: return _rank(a) < _rank(b))
    var heights: Array[float] = []
    var text_height := 0.0
    for hallmark in sorted:
        var height := (
            font
            . get_multiline_string_size(
                tr(hallmark.phrase), HORIZONTAL_ALIGNMENT_CENTER, width, text_size
            )
            . y
        )
        heights.append(height)
        text_height += height + gap
    var top := size.y - MARGIN - text_height
    var hallmarks: Array[Dictionary] = []
    for i in range(sorted.size()):
        hallmarks.append({"text": tr(sorted[i].phrase), "top": top})
        top += heights[i] + gap
    return {
        "hallmarks": hallmarks,
        "width": width,
        "portrait":
        Rect2(Vector2(MARGIN, MARGIN), Vector2(width, size.y - MARGIN * 3.0 - text_height)),
    }


func _rank(hallmark: Hallmark) -> int:
    var kinds := ["clothes", "hair", "thing", "sail", "hull"]
    return kinds.find(hallmark.kind) * 100 + person.hallmarks.find(hallmark)
