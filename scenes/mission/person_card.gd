class_name PersonCard
extends HandButton

## A person in a line-up, as a button: their portrait from the costume books,
## and under it what one sees of them (their hallmarks), so that the players
## can compare with what they remember. The hallmarks stand in the order of
## their kind (the clothes, the hair, the things), never in the order the
## crew learned them, which would give the answer away.

var person: Person


func _draw() -> void:
    super()
    if person == null:
        return
    var font := ThemeDB.fallback_font
    var lines := person.hallmarks.size()
    var text_height := 40.0 * lines + 20.0
    var area := Rect2(Vector2(20, 20), size - Vector2(40, 40 + text_height))
    if person.portrait != null:
        var portrait_size := person.portrait.get_size()
        var scale := minf(area.size.x / portrait_size.x, area.size.y / portrait_size.y)
        var drawn := portrait_size * scale
        var at := area.position + (area.size - drawn) * 0.5
        draw_texture_rect(person.portrait, Rect2(at, drawn), false)
        draw_rect(Rect2(at, drawn), Paper.INK, false, 2.0)
    var y := size.y - text_height + 16
    var sorted: Array[Hallmark] = person.hallmarks.duplicate()
    sorted.sort_custom(func(a: Hallmark, b: Hallmark) -> bool: return _rank(a) < _rank(b))
    for hallmark in sorted:
        var text := tr(hallmark.phrase)
        var font_size := HandButton.fit_size(font, text, 30, size.x - 30)
        draw_string(
            font,
            Vector2(15, y + 26),
            text,
            HORIZONTAL_ALIGNMENT_CENTER,
            size.x - 30,
            font_size,
            Paper.INK
        )
        y += 40


func _rank(hallmark: Hallmark) -> int:
    var kinds := ["clothes", "hair", "thing", "sail", "hull"]
    return kinds.find(hallmark.kind) * 100 + person.hallmarks.find(hallmark)
