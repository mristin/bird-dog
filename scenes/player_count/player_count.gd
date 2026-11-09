extends MenuScreen

## Ask how many captains play: one, or two side by side (see DESIGN.md, "The
## split screen with two players"). Then the players create their captains.

const _CARD_SIZE := Vector2(520, 380)

var _chosen := false

@onready var _crew: Node = get_node("/root/Crew")
@onready var _flag: Texture2D = load("res://assets/images/flag.svg")


func _build() -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 120)
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.position = Vector2(0, 380)
    row.size = Vector2(1920, _CARD_SIZE.y)
    add_child(row)

    for count in [1, 2]:
        var button := HandButton.new()
        button.custom_minimum_size = _CARD_SIZE
        button.title = str(count)
        button.title_size = 150
        button.text = tr("One captain") if count == 1 else tr("Two captains")
        button.text_size = 44
        button.icon = _flag
        button.icon_count = count
        button.pressed.connect(_choose.bind(count))
        row.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
    super(event)
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    match event.keycode:
        KEY_1:
            _choose(1)
        KEY_2:
            _choose(2)


func _choose(count: int) -> void:
    if _chosen:
        return
    _chosen = true
    _crew.start(count)
    go_next(0.5)


func _draw_screen() -> void:
    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, 250),
        tr("How many captains sail?"),
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        64,
        Paper.RED
    )
