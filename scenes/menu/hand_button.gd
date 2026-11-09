class_name HandButton
extends Control

## A button of the menus which the players press with the hand cursor (point
## with an open hand, then close it into a fist and hold it, see HandCursor),
## or with the mouse.
##
## It shows a title (big) and a text (smaller), or a swatch of colour. It
## highlights while a hand points at it, fills with gold from the bottom while
## a fist is held on it, and flashes when it is pressed. A selected button (e.g.,
## the chosen gender) stays golden.
##
## The scene needs a HandCursor; the button finds it by its group.

signal pressed

## The big line, e.g., "1".
var title := ""

## The normal line, e.g., "One captain".
var text := ""

## A colour to show instead of the text; transparent for none.
var swatch := Color(0, 0, 0, 0)

## An arrow to draw instead of the text: -1 points left, 1 right, 0 none.
var arrow := 0

## Draw the button as an octagon, and count only the points inside the octagon,
## so that a hand between two neighbouring keys presses neither.
var octagon := false

## A picture to show above the lines (e.g., the flag), and how many times in a row.
var icon: Texture2D = null
var icon_count := 1
var icon_size := Vector2(110, 80)

## A small symbol to draw left of the first line: "" for none, or "trash".
var symbol := ""

var selected := false
var title_size := 72
var text_size := 30

var _hover := 0.0
var _flash := 0.0
var _charge := 0.0
var _cursor: HandCursor = null


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    # NOTE (mristin):
    # With two players, every half of the screen has its own cursor, in its
    # own viewport.
    for candidate in get_tree().get_nodes_in_group(HandCursor.GROUP):
        if candidate.get_viewport() == get_viewport():
            _cursor = candidate
            break
    if _cursor != null:
        _cursor.clicked.connect(_on_clicked)


func _exit_tree() -> void:
    if _cursor != null and _cursor.clicked.is_connected(_on_clicked):
        _cursor.clicked.disconnect(_on_clicked)


## Whether a hand (or the mouse) points at the button.
func is_hovered() -> bool:
    return _hover > 0.5


## Whether the point (in global coordinates) lies on the button.
func contains(global_point: Vector2) -> bool:
    if not get_global_rect().has_point(global_point):
        return false
    if not octagon:
        return true
    return Geometry2D.is_point_in_polygon(global_point - global_position, _octagon())


func _octagon() -> PackedVector2Array:
    var w := size.x
    var h := size.y
    var c := minf(w, h) * 0.29
    return PackedVector2Array(
        [
            Vector2(c, 0),
            Vector2(w - c, 0),
            Vector2(w, c),
            Vector2(w, h - c),
            Vector2(w - c, h),
            Vector2(c, h),
            Vector2(0, h - c),
            Vector2(0, c),
        ]
    )


## Whether an open dialog (see ConfirmDialog) keeps the button quiet: every
## button outside of the dialog stays quiet while it is open.
func is_blocked() -> bool:
    for dialog in get_tree().get_nodes_in_group(ConfirmDialog.GROUP):
        if not dialog.is_ancestor_of(self):
            return true
    return false


func _on_clicked(at_position: Vector2) -> void:
    if is_visible_in_tree() and not is_blocked() and contains(at_position):
        _flash = 1.0
        pressed.emit()


func _process(delta: float) -> void:
    var hovered := false
    _charge = 0.0
    if _cursor != null and is_visible_in_tree() and not is_blocked():
        for pointer in _cursor.get_pointers():
            hovered = hovered or contains(pointer)
        for charge in _cursor.get_charges():
            if contains(charge["position"]):
                _charge = maxf(_charge, charge["progress"])
    _hover = lerpf(_hover, 1.0 if hovered else 0.0, 1.0 - exp(-delta * 14.0))
    _flash = maxf(0.0, _flash - delta * 3.0)
    queue_redraw()


func _draw_octagon(fill: Color, border: Color, border_width: float) -> void:
    var shape := _octagon()
    var shadow := PackedVector2Array()
    for point in shape:
        shadow.append(point + Vector2(5, 7))
    draw_colored_polygon(shadow, Color(0, 0, 0, 0.16))
    draw_colored_polygon(shape, fill)
    if _charge > 0.0:
        var height := size.y * _charge
        var level := PackedVector2Array(
            [
                Vector2(0, size.y - height),
                Vector2(size.x, size.y - height),
                Vector2(size.x, size.y),
                Vector2(0, size.y),
            ]
        )
        for part in Geometry2D.intersect_polygons(shape, level):
            draw_colored_polygon(part, Color(Paper.GOLD, 0.45))
    var outline := shape.duplicate()
    outline.append(shape[0])
    draw_polyline(outline, border, border_width, true)


## The largest font size up to [param wanted] at which the text fits the width.
static func fit_size(font: Font, line: String, wanted: int, width: float) -> int:
    var font_size := wanted
    while (
        font_size > 10
        and font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width
    ):
        font_size -= 1
    return font_size


func _draw() -> void:
    var font := ThemeDB.fallback_font
    var rect := Rect2(Vector2.ZERO, size)

    var fill := Paper.CARD
    if selected:
        fill = Paper.CARD.lerp(Paper.GOLD, 0.45)
    fill = fill.lerp(Paper.GOLD, 0.5 * _flash)
    var border := Paper.INK.lerp(Paper.GOLD, maxf(_hover, 1.0 if selected else 0.0))
    var border_width := 3.0 + 4.0 * _hover

    if octagon:
        _draw_octagon(fill, border, border_width)
    else:
        draw_rect(Rect2(Vector2(5, 7), size), Color(0, 0, 0, 0.16))
        draw_rect(rect, fill)
        if _charge > 0.0:
            var height := size.y * _charge
            draw_rect(Rect2(0, size.y - height, size.x, height), Color(Paper.GOLD, 0.4))
            draw_line(
                Vector2(0, size.y - height), Vector2(size.x, size.y - height), Paper.GOLD, 4.0
            )
        draw_rect(rect, border, false, border_width)

    if arrow != 0:
        var center := size * 0.5
        var half := minf(size.x, size.y) * 0.26
        var tip := center + Vector2(arrow * half, 0)
        var back := center - Vector2(arrow * half * 0.8, 0)
        draw_colored_polygon(
            PackedVector2Array([tip, back + Vector2(0, -half), back + Vector2(0, half)]), Paper.INK
        )
        return

    if swatch.a > 0.0:
        var radius := minf(size.x, size.y) * 0.32
        draw_circle(size * 0.5, radius, swatch)
        draw_arc(size * 0.5, radius, 0, TAU, 40, Paper.INK, 3.0, true)
        return

    var top := 0.0
    if icon != null:
        var gap := 30.0
        var total_width := icon_count * icon_size.x + (icon_count - 1) * gap
        for i in range(icon_count):
            var at := Vector2((size.x - total_width) * 0.5 + i * (icon_size.x + gap), 24)
            draw_texture_rect(icon, Rect2(at, icon_size), false)
        top = 24 + icon_size.y

    # NOTE (mristin):
    # A text which is too long for the button (e.g., in another language)
    # shrinks until it fits.
    var lines := []
    if title != "":
        lines.append([title, fit_size(font, title, title_size, size.x - 16.0)])
    if text != "":
        lines.append([text, fit_size(font, text, text_size, size.x - 16.0)])
    var total := 0.0
    for line in lines:
        total += line[1] * 1.15
    var y := top + (size.y - top - total) * 0.5

    # NOTE (mristin):
    # The symbol stands left of the first line, and the two are centered
    # together.
    var shift := 0.0
    if symbol != "" and not lines.is_empty():
        var height: float = lines[0][1]
        var width := font.get_string_size(lines[0][0], HORIZONTAL_ALIGNMENT_LEFT, -1, height).x
        shift = height * 0.55
        var at := Vector2(size.x * 0.5 - width * 0.5 - shift, y + height * 0.62)
        _draw_symbol(at, height * 0.9)

    var first := true
    for line in lines:
        y += line[1] * 0.95
        var offset := shift if first else 0.0
        draw_string(
            font,
            Vector2(offset, y),
            line[0],
            HORIZONTAL_ALIGNMENT_CENTER,
            size.x,
            line[1],
            Paper.INK
        )
        y += line[1] * 0.2
        first = false


## Draw the symbol centered at the point, about as high as the given height.
func _draw_symbol(center: Vector2, height: float) -> void:
    if symbol != "trash":
        return

    # NOTE (mristin):
    # A bin: the lid with its handle, and the can, narrower at the bottom,
    # with three grooves.
    var h := height
    var width := maxf(2.0, h * 0.08)
    var lid_y := center.y - h * 0.36
    draw_line(
        center + Vector2(-h * 0.36, lid_y - center.y),
        center + Vector2(h * 0.36, lid_y - center.y),
        Paper.INK,
        width,
        true
    )
    draw_rect(
        Rect2(center + Vector2(-h * 0.1, lid_y - center.y - h * 0.1), Vector2(h * 0.2, h * 0.1)),
        Paper.INK,
        false,
        width * 0.8
    )
    var can := PackedVector2Array(
        [
            center + Vector2(-h * 0.3, -h * 0.28),
            center + Vector2(h * 0.3, -h * 0.28),
            center + Vector2(h * 0.24, h * 0.42),
            center + Vector2(-h * 0.24, h * 0.42),
            center + Vector2(-h * 0.3, -h * 0.28),
        ]
    )
    draw_polyline(can, Paper.INK, width, true)
    for x in [-0.1, 0.0, 0.1]:
        draw_line(
            center + Vector2(h * x, -h * 0.18),
            center + Vector2(h * x * 0.85, h * 0.32),
            Paper.INK,
            width * 0.7,
            true
        )
