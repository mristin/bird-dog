class_name MissionComplete
extends Control

## The screen at the end of a mission: every mission has its own (see
## Mission, "Mission complete"). The picture of a port of the story fills the
## background, the happy person of the story smiles in their frame, and a big
## sheet of paper tells what the crew achieved, what it gets from now on, the
## stars (which pop in one after the other), the days, and a fun fact.
##
## The last mission of the voyage shows the medal of the Bird Dog instead of a
## person.

signal finished

const FLAG := preload("res://assets/images/flag.svg")

## Each star pops in after this many seconds.
const STAR_SECONDS := 0.6

## The sheet with the story, the stars and the button.
const _SHEET := Rect2(620, 40, 1260, 1000)

## The top of the button; the text on the sheet must end above it.
const BUTTON_TOP := 910.0

## The fun fact shrinks at most to this size to stay above the button.
const MIN_FACT_SIZE := 20

var mission: Mission
var run: MissionRun
var stars := 0

## The ducats which the mission earned (what the boats found and earned with
## errands, less what they spent and what the corsairs and the patrols took);
## negative if it cost more than it earned.
var ducats := 0

## The ducats which the yataks collected for the crew (see
## Session.yatak_gift); 0 for none.
var gift := 0

## Where the text on the sheet ends (drawn), so that the tests can check it
## stays above the button.
var content_bottom := 0.0

var _time := 0.0


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var button := HandButton.new()
    button.text = tr("Back to the missions")
    if mission.finale:
        var last := mission.chapter >= MissionCatalog.chapters().size()
        button.text = tr("The end of the voyage") if last else tr("On to the next chapter!")
    button.text_size = 40
    # NOTE (mristin):
    # The button stands centred on the sheet (see _SHEET), inside its frame.
    button.size = Vector2(600, 100)
    button.position = Vector2(_SHEET.get_center().x - button.size.x * 0.5, BUTTON_TOP)
    button.pressed.connect(func() -> void: finished.emit())
    add_child(button)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    var font := ThemeDB.fallback_font
    _draw_background()

    var sheet := _SHEET
    if mission.finale:
        _draw_medal(Vector2(310, 470))
    else:
        _draw_person(Rect2(60, 120, 500, 800))

    draw_rect(Rect2(sheet.position + Vector2(10, 12), sheet.size), Color(0, 0, 0, 0.3))
    draw_rect(sheet, Color(Paper.PAPER, 0.97))
    draw_rect(sheet.grow(-10), Paper.GOLD, false, 3.0)
    draw_rect(sheet, Paper.INK, false, 4.0)

    var x := sheet.position.x + 50
    var width := sheet.size.x - 100
    var label := Grammar.format(
        tr("Mission {number}: {title}"), {"number": mission.number, "title": tr(mission.title)}
    )
    draw_string(
        font,
        Vector2(x, 110),
        label,
        HORIZONTAL_ALIGNMENT_CENTER,
        width,
        HandButton.fit_size(font, label, 34, width),
        Paper.INK
    )
    var title := tr(mission.victory_title)
    draw_string(
        font,
        Vector2(x, 200),
        title,
        HORIZONTAL_ALIGNMENT_CENTER,
        width,
        HandButton.fit_size(font, title, 72, width),
        Paper.RED
    )

    var y := 270.0
    for text in mission.victory_lines:
        y = _draw_lines(font, tr(text), Vector2(x, y), width, 36, Paper.INK)

    _draw_stars(Vector2(sheet.get_center().x, y + 70))
    y += 160
    var days := Grammar.format(
        tr("Days at sea: {used} of {clock}"),
        {"used": snappedf(run.days, 0.1), "clock": int(mission.clock_days)}
    )
    draw_string(font, Vector2(x, y), days, HORIZONTAL_ALIGNMENT_CENTER, width, 30, Paper.INK)
    y += 30
    var earned := Grammar.format(
        tr("+{ducats} {ducats|ducat|ducats} earned in this mission"), {"ducats": ducats}
    )
    if ducats < 0:
        earned = Grammar.format(
            tr("{ducats} {ducats|ducat|ducats} spent in this mission"), {"ducats": -ducats}
        )
    # NOTE (mristin):
    # The coin and the line stand centred together, the coin before the line.
    var line_width := font.get_string_size(earned, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
    var left := sheet.get_center().x - (line_width + 40) * 0.5
    draw_circle(Vector2(left + 14, y + 19), 14, Paper.GOLD)
    draw_arc(Vector2(left + 14, y + 19), 14, 0, TAU, 20, Paper.INK, 2.0, true)
    draw_string(
        font, Vector2(left + 40, y + 30), earned, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Paper.INK
    )
    y += 42
    if gift > 0:
        var yataks := Grammar.format(
            tr("The yataks, the haiduks' friends, collected {gift} {gift|ducat|ducats} for you."),
            {"gift": gift}
        )
        y = _draw_lines(font, yataks, Vector2(x, y + 4), width, 28, Paper.INK) + 6

    if mission.reward != "":
        var reward := tr(mission.reward)
        var count := ceili(
            font.get_string_size(reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x / (width - 60)
        )
        var box := Rect2(x, y, width, maxi(1, count) * 32 * 1.3 + 30)
        draw_rect(box, Color(Paper.GOLD, 0.25))
        draw_rect(box, Paper.GOLD, false, 4.0)
        _draw_lines(font, reward, Vector2(x + 30, y + 10), width - 60, 32, Paper.INK)
        y += box.size.y + 10

    content_bottom = y
    if mission.fun_fact != "":
        draw_string(
            font,
            Vector2(x, y + 34),
            tr("Did you know?"),
            HORIZONTAL_ALIGNMENT_LEFT,
            width,
            34,
            Paper.RED
        )
        # NOTE (mristin):
        # The fun fact shrinks a little if it would run into the button (e.g.,
        # under the gift of the yataks).
        var fact := tr(mission.fun_fact)
        var fact_size := 28
        while (
            fact_size > MIN_FACT_SIZE
            and _lines_bottom(font, fact, y + 44, width, fact_size) > BUTTON_TOP
        ):
            fact_size -= 1
        content_bottom = _draw_lines(font, fact, Vector2(x, y + 44), width, fact_size, Paper.INK)


func _draw_background() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Paper.PAPER_DARK)
    var picture := mission.victory_picture
    if picture == null and mission.start_port != null:
        picture = mission.start_port.picture
    if picture != null:
        var picture_size := picture.get_size()
        var scale := maxf(size.x / picture_size.x, size.y / picture_size.y)
        var drawn := picture_size * scale
        draw_texture_rect(picture, Rect2((size - drawn) * 0.5, drawn), false)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.2))


## Where a text which wraps from [param top] ends, as [method _draw_lines]
## draws it.
static func _lines_bottom(
    font: Font, text: String, top: float, width: float, font_size: int
) -> float:
    var count := ceili(
        font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / width
    )
    return top + maxi(1, count) * font_size * 1.3 + 10


## Draw a text which wraps; return the y below it.
func _draw_lines(
    font: Font, text: String, at: Vector2, width: float, font_size: int, color: Color
) -> float:
    draw_multiline_string(
        font,
        at + Vector2(0, font_size),
        text,
        HORIZONTAL_ALIGNMENT_CENTER,
        width,
        font_size,
        -1,
        color
    )
    return _lines_bottom(font, text, at.y, width, font_size)


func _draw_person(frame: Rect2) -> void:
    var person := mission.victory_person
    if person == null:
        return
    var font := ThemeDB.fallback_font
    var tilt := sin(_time * 1.5) * 0.015
    draw_set_transform(frame.get_center(), tilt, Vector2.ONE)
    var local := Rect2(-frame.size * 0.5, frame.size)
    draw_rect(Rect2(local.position + Vector2(8, 10), local.size), Color(0, 0, 0, 0.3))
    draw_rect(local, Paper.PAPER)
    if person.portrait != null:
        var portrait_size := person.portrait.get_size()
        var area := Rect2(local.position + Vector2(20, 20), local.size - Vector2(40, 120))
        var scale := minf(area.size.x / portrait_size.x, area.size.y / portrait_size.y)
        var drawn := portrait_size * scale
        draw_texture_rect(
            person.portrait, Rect2(area.position + (area.size - drawn) * 0.5, drawn), false
        )
    draw_rect(local, Paper.GOLD, false, 6.0)
    draw_string(
        font,
        local.position + Vector2(0, local.size.y - 40),
        tr(person.name),
        HORIZONTAL_ALIGNMENT_CENTER,
        local.size.x,
        44,
        Paper.RED
    )
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The medal of the Bird Dog on its ribbon, slowly swinging.
func _draw_medal(center: Vector2) -> void:
    var swing := sin(_time * 1.2) * 0.05
    draw_set_transform(center + Vector2(0, -260), swing, Vector2.ONE)
    var ribbon := PackedVector2Array(
        [Vector2(-90, 0), Vector2(90, 0), Vector2(40, 200), Vector2(-40, 200)]
    )
    draw_colored_polygon(ribbon, Paper.RED)
    draw_line(Vector2(-12, 0), Vector2(-12, 200), Color(1, 1, 1, 0.8), 10.0)
    draw_line(Vector2(12, 0), Vector2(12, 200), Color(1, 1, 1, 0.8), 10.0)
    var disc := Vector2(0, 360)
    var shine := 0.5 + 0.5 * sin(_time * 3.0)
    for k in range(16):
        var ray := Vector2.UP.rotated(k * TAU / 16 + _time * 0.3)
        draw_line(disc + ray * 175, disc + ray * 215, Color(Paper.GOLD, 0.4 + 0.4 * shine), 6.0)
    draw_circle(disc, 170, Paper.GOLD)
    draw_circle(disc, 150, Paper.GOLD.lightened(0.25))
    draw_arc(disc, 170, 0, TAU, 64, Paper.INK, 4.0, true)
    draw_arc(disc, 150, 0, TAU, 64, Paper.INK, 2.0, true)
    var flag_size := Vector2(200, 145)
    draw_texture_rect(FLAG, Rect2(disc - flag_size * 0.5, flag_size), false)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The stars, popping in one after the other.
func _draw_stars(center: Vector2) -> void:
    for i in range(3):
        var at := center + Vector2((i - 1) * 150, 0)
        var age := _time - (i + 1) * STAR_SECONDS
        var earned := i < stars and age > 0.0
        var pop := 1.0
        if earned:
            pop = 1.0 + 0.5 * exp(-age * 6.0) * cos(age * 18.0)
        var points := PackedVector2Array()
        for k in range(10):
            var radius := (60.0 if k % 2 == 0 else 26.0) * pop
            points.append(at + Vector2.UP.rotated(k * PI / 5) * radius)
        if earned:
            draw_colored_polygon(points, Paper.GOLD)
        else:
            draw_colored_polygon(points, Color(Paper.INK, 0.08))
        var outline := points.duplicate()
        outline.append(points[0])
        draw_polyline(outline, Paper.INK, 4.0, true)
