class_name Toast
extends Control

## Short messages in the middle of the screen while sailing, e.g., "+12
## ducats!" or "The corsairs caught you!", which fade after a few seconds.

const SECONDS := 3.5

var _messages: Array[Dictionary] = []


func show_text(text: String) -> void:
    for message in _messages:
        if message["text"] == text:
            message["age"] = 0.0
            return
    _messages.append({"text": text, "age": 0.0})
    if _messages.size() > 3:
        _messages.pop_front()


func _process(delta: float) -> void:
    for message in _messages.duplicate():
        message["age"] += delta
        if message["age"] > SECONDS:
            _messages.erase(message)
    queue_redraw()


## The size of the text of a message: as large as the pop makes it, but
## shrunk to fit the width of the view (e.g., a long sentence in a half).
static func font_size_of(text: String, pop: float, width: float) -> int:
    return HandButton.fit_size(ThemeDB.fallback_font, text, int(44 * pop), width - 80.0)


func _draw() -> void:
    var font := ThemeDB.fallback_font
    var y := 250.0
    for message in _messages:
        var alpha := clampf((SECONDS - message["age"]) / 0.6, 0.0, 1.0)
        var pop := 1.0 + 0.3 * exp(-message["age"] * 8.0)
        var text: String = message["text"]
        var font_size := font_size_of(text, pop, size.x)
        var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 60
        var box := Rect2(size.x * 0.5 - width * 0.5, y, width, font_size + 30)
        draw_rect(box, Color(Paper.PAPER, 0.95 * alpha))
        draw_rect(box, Color(Paper.INK, alpha), false, 3.0)
        draw_string(
            font,
            Vector2(box.position.x, y + font_size + 6),
            text,
            HORIZONTAL_ALIGNMENT_CENTER,
            width,
            font_size,
            Color(Paper.RED, alpha)
        )
        y += box.size.y + 12
