extends MenuScreen

## Let the players choose the language of the game: the very first screen.
##
## Each language is a card (a HandButton) with its name in itself, so that
## everybody finds their own without reading the others. The cards come from
## the list of the languages (see the Languages autoload), so a new language
## needs no change here: up to four cards fit in a row, and more languages
## make more rows. "Choose your language" cycles through all the languages
## above the cards, and shows the language of the card pointed at.
##
## Point at a card with an open hand and hold a fist to choose it (or use the
## mouse, the arrow keys and Enter, or the number keys: 1 to 9 for the first
## nine cards and 0 for the tenth, as on a phone). The choice is remembered for
## the next start.

## The area of the cards, and the largest card.
const _CARDS_AREA := Rect2(140, 570, 1640, 330)
const _MAX_CARD := Vector2(470, 210)
const _CARD_GAP := 50.0
const _MAX_COLUMNS := 4

## Show each translation of "Choose your language" this long, in seconds.
const _PROMPT_SECONDS := 2.2

var _cards: Array[HandButton] = []
var _highlight := 0
var _chosen := -1
var _time := 0.0

@onready var _languages: Node = get_node("/root/Languages")
@onready var _flag: Texture2D = load("res://assets/images/flag.svg")


func _build() -> void:
    for i in range(_count()):
        var language := _language(i)
        var card := HandButton.new()
        var rect := _card_rect(i)
        card.position = rect.position
        card.size = rect.size
        var scale := rect.size.y / _MAX_CARD.y
        card.title = language["name"]
        card.title_size = int(64 * scale)
        card.text = language["subtitle"]
        card.text_size = int(34 * scale)
        card.pressed.connect(_choose.bind(i))
        add_child(card)
        _cards.append(card)
        if language["code"] == _languages.current():
            _highlight = i
    _show_highlight()


func _count() -> int:
    return _languages.languages.size()


func _language(index: int) -> Dictionary:
    return _languages.languages[index]


func _unhandled_input(event: InputEvent) -> void:
    super(event)
    if _chosen >= 0 or not (event is InputEventKey and event.pressed and not event.echo):
        return
    var columns := _columns()
    match event.keycode:
        KEY_LEFT:
            _highlight = posmod(_highlight - 1, _count())
        KEY_RIGHT:
            _highlight = posmod(_highlight + 1, _count())
        KEY_UP:
            _highlight = posmod(_highlight - columns, _count())
        KEY_DOWN:
            _highlight = posmod(_highlight + columns, _count())
        KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
            _choose(_highlight)
        _:
            if event.keycode >= KEY_1 and event.keycode <= KEY_9:
                _choose(event.keycode - KEY_1)
            elif event.keycode == KEY_0:
                _choose(9)
    _show_highlight()


## Mark the card of the keyboard (at first, the language of the last game).
func _show_highlight() -> void:
    for i in range(_cards.size()):
        _cards[i].selected = i == _highlight or i == _chosen


## Lay the cards out in as few rows as possible, at most four in a row, and
## spread them evenly over the rows (e.g., seven make rows of four and three).
func _columns() -> int:
    var rows := ceili(float(_count()) / _MAX_COLUMNS)
    return ceili(float(_count()) / rows)


func _card_size() -> Vector2:
    var columns := _columns()
    var rows := ceili(float(_count()) / columns)
    var width := minf(_MAX_CARD.x, (_CARDS_AREA.size.x - (columns - 1) * _CARD_GAP) / columns)
    var height := minf(_MAX_CARD.y, (_CARDS_AREA.size.y - (rows - 1) * _CARD_GAP) / rows)
    return Vector2(width, height)


func _card_rect(index: int) -> Rect2:
    var columns := _columns()
    var rows := ceili(float(_count()) / columns)
    var card := _card_size()
    var row := index / columns
    var in_row := mini(columns, _count() - row * columns)

    # NOTE (mristin):
    # A shorter last row is centered, too.
    var row_width := in_row * card.x + (in_row - 1) * _CARD_GAP
    var left := _CARDS_AREA.position.x + (_CARDS_AREA.size.x - row_width) * 0.5
    var total_height := rows * card.y + (rows - 1) * _CARD_GAP
    var top := _CARDS_AREA.position.y + (_CARDS_AREA.size.y - total_height) * 0.5
    var column := index % columns
    return Rect2(
        Vector2(left + column * (card.x + _CARD_GAP), top + row * (card.y + _CARD_GAP)), card
    )


func _choose(index: int) -> void:
    if _chosen >= 0 or index < 0 or index >= _count():
        return
    _chosen = index
    _show_highlight()
    _languages.choose(_language(index)["code"])
    go_next(0.8)


func _process(delta: float) -> void:
    super(delta)
    _time += delta


func _draw_screen() -> void:
    var font := ThemeDB.fallback_font
    var flag_size := Vector2(330, 240)
    draw_texture_rect(_flag, Rect2(Vector2((size.x - flag_size.x) * 0.5, 60), flag_size), false)
    draw_string(
        font, Vector2(0, 400), "Bird Dog", HORIZONTAL_ALIGNMENT_CENTER, size.x, 96, Paper.RED
    )
    _draw_prompt(Vector2(0, 500))
    _draw_how_to_choose(Vector2(size.x * 0.5, 975))


## Cycle "Choose your language" through all the languages, fading from one to
## the next; while a card is pointed at, show it in that card's language.
func _draw_prompt(at: Vector2) -> void:
    var index := _chosen
    if index < 0:
        for i in range(_cards.size()):
            if _cards[i].is_hovered():
                index = i
    var alpha := 1.0
    if index < 0:
        var phase := _time / _PROMPT_SECONDS
        index = int(phase) % _count()
        var t := fmod(phase, 1.0)
        alpha = clampf(minf(t, 1.0 - t) * 6.0, 0.0, 1.0)
    var prompt: String = _language(index)["prompt"]
    draw_string(
        ThemeDB.fallback_font,
        at,
        prompt,
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x,
        46,
        Color(Paper.INK, alpha)
    )


## Show without words how to choose: point with an open hand, then hold a fist
## until the golden ring is full.
func _draw_how_to_choose(center: Vector2) -> void:
    _draw_open_hand(center + Vector2(-110, 0))
    draw_line(center + Vector2(-50, 0), center + Vector2(30, 0), Paper.INK, 5.0, true)
    draw_colored_polygon(
        PackedVector2Array(
            [center + Vector2(46, 0), center + Vector2(26, -14), center + Vector2(26, 14)]
        ),
        Paper.INK
    )
    var fist_at := center + Vector2(110, 0)
    var progress := fmod(Time.get_ticks_msec() / 1500.0, 1.0)
    draw_arc(fist_at, 46, 0, TAU, 48, Color(Paper.INK, 0.25), 7.0, true)
    draw_arc(fist_at, 46, -PI / 2, -PI / 2 + TAU * progress, 48, Paper.GOLD, 7.0, true)
    _draw_fist(fist_at)


## An open hand, the palm toward the viewer: a palm and five fingers.
func _draw_open_hand(at: Vector2) -> void:
    draw_rect(Rect2(at + Vector2(-18, -8), Vector2(36, 34)), Paper.INK)
    var fingers := [
        [-15.0, 22.0, -0.18], [-5.0, 30.0, -0.06], [5.0, 31.0, 0.04], [15.0, 26.0, 0.14]
    ]
    for finger in fingers:
        var base: Vector2 = at + Vector2(finger[0], -6)
        var tip: Vector2 = base + Vector2(0, -finger[1]).rotated(finger[2])
        draw_line(base, tip, Paper.INK, 8.0, true)
        draw_circle(tip, 4.0, Paper.INK)
    draw_line(at + Vector2(-16, 14), at + Vector2(-32, -2), Paper.INK, 9.0, true)
    draw_circle(at + Vector2(-32, -2), 4.5, Paper.INK)


## A fist seen from the front: a rounded block with four knuckles and the thumb.
func _draw_fist(at: Vector2) -> void:
    draw_rect(Rect2(at + Vector2(-22, -14), Vector2(44, 36)), Paper.INK)
    for i in range(4):
        draw_circle(at + Vector2(-16.5 + i * 11, -14), 6.0, Paper.INK)
    for i in range(3):
        var x := -11.0 + i * 11.0
        draw_line(at + Vector2(x, -18), at + Vector2(x, -4), Paper.CARD, 2.5, true)
    draw_line(at + Vector2(-18, 6), at + Vector2(8, 6), Paper.CARD, 3.0, true)
