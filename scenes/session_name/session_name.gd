extends MenuScreen

## Name a new voyage. The name starts as the date and the time, so "OK" is
## enough; the players may type their own name instead.

var _keyboard: NameKeyboard

@onready var _session: Node = get_node("/root/Session")


func _build() -> void:
    _keyboard = NameKeyboard.new()
    _keyboard.position = Vector2(110, 170)
    _keyboard.size = Vector2(1700, 860)
    _keyboard.max_length = _session.MAX_NAME_LENGTH
    _keyboard.extra_keys = "0123456789-:"
    _keyboard.with_space = true
    _keyboard.finished.connect(_on_finished)
    add_child(_keyboard)
    _keyboard.start(_session.default_name())


func _on_finished(voyage_name: String) -> void:
    _session.start(voyage_name)
    go_next(0.3)


func _draw_screen() -> void:
    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, 130),
        tr("Name your voyage"),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        60,
        Paper.RED
    )
