class_name FaceOverlay
extends RefCounted

## Dress the face of a player in the camera picture like their captain: the
## chosen cap (or none), the eye patch, the moustache and the freckles, if any
## (see CaptainOptions).
##
## Everything is fitted to five landmarks of the face (the eyes, the tip of
## the nose and the corners of the mouth, see YuNetFaceLandmarker), so it
## follows the head as it tilts. We measure in "eyes": the distance between the
## eyes, which is about 6.3 cm on a real face. Without the landmarks, we guess
## them from the head box (see [method points_from_head]).
##
## The cap is opaque and pulled down to the eyebrows, so that it hides the
## forehead and the hair on top; the moustache and the freckles are a bit
## transparent, so that the face still shows through.

## The indices of the landmarks in the points.
const EYE_LEFT := 0
const EYE_RIGHT := 1
const NOSE := 2
const MOUTH_LEFT := 3
const MOUTH_RIGHT := 4

## The brim of the cap, just above the eyebrows, in eyes above the eye line.
const _BRIM := 0.55

## Half of the width of the cap at the brim, in eyes; a real head is about
## 2.4 eyes wide, and the cap must cover the hair at the temples.
const _HALF_WIDTH := 1.32

## How much of the top of a cylinder we see, as the camera looks down a bit.
const _LID := 0.2

const _BLACK := Color(0.07, 0.06, 0.06)
const _RED := Color(0.7, 0.07, 0.08)
const _GOLD := Color(0.86, 0.66, 0.24)
const _FUR := Color(0.2, 0.13, 0.08)
const _LINEN := Color(0.95, 0.92, 0.84)
const _FEATHER := Color(0.97, 0.96, 0.92)
const _LEATHER := Color(0.1, 0.08, 0.07)


## The coordinates of the face: x to the right along the eye line and y up,
## both in eyes, from the middle between the eyes.
class Face:
    var origin: Vector2
    var right: Vector2
    var up: Vector2
    var eyes: float

    func _init(eye_left: Vector2, eye_right: Vector2) -> void:
        origin = (eye_left + eye_right) * 0.5
        eyes = eye_left.distance_to(eye_right)
        right = (eye_right - eye_left) / maxf(eyes, 1e-3)
        up = Vector2(right.y, -right.x)

    ## Map a point of the face to the canvas.
    func at(x: float, y: float) -> Vector2:
        return origin + (right * x + up * y) * eyes

    ## How far a point of the canvas is above the eye line, in eyes.
    func up_of(point: Vector2) -> float:
        return (point - origin).dot(up) / eyes

    ## How far a point of the canvas is right of the middle, in eyes.
    func right_of(point: Vector2) -> float:
        return (point - origin).dot(right) / eyes

    ## Convert a length in eyes to pixels.
    func px(value: float) -> float:
        return value * eyes


## Guess the landmarks of a face which looks at the camera from its head box,
## by the proportions of a real face.
static func points_from_head(head: Rect2) -> PackedVector2Array:
    var center_x := head.get_center().x
    var eye_y := head.position.y + head.size.y * 0.52
    var eyes := head.size.x * 0.36
    return PackedVector2Array(
        [
            Vector2(center_x - eyes * 0.5, eye_y),
            Vector2(center_x + eyes * 0.5, eye_y),
            Vector2(center_x, eye_y + eyes * 0.5),
            Vector2(center_x - eyes * 0.42, eye_y + eyes * 0.88),
            Vector2(center_x + eyes * 0.42, eye_y + eyes * 0.88),
        ]
    )


## Get the landmarks of the face of a player of PoseService.GetPlayers() on a
## canvas of [param size].
static func points_from_face(face: Dictionary, size: Vector2) -> PackedVector2Array:
    var eyes: Array = face["eyes"]
    var mouth: Array = face["mouth"]
    var nose: Vector2 = face["nose"]
    return PackedVector2Array(
        [eyes[0] * size, eyes[1] * size, nose * size, mouth[0] * size, mouth[1] * size]
    )


## Draw the looks of the captain on the face with the landmarks [param points]
## (see [constant EYE_LEFT] and the others) in the [param head] box, both in the
## coordinates of the [param canvas]. The cap and the eye patch are drawn with
## [param cap_alpha], the moustache and the freckles with [param face_alpha].
## In a [param mirrored] picture, the left eye of the player is on the left of
## the screen.
static func draw(
    canvas: CanvasItem,
    head: Rect2,
    points: PackedVector2Array,
    looks: Dictionary,
    face_alpha: float,
    cap_alpha: float,
    mirrored := true
) -> void:
    if points.size() != 5:
        return
    var face := Face.new(points[EYE_LEFT], points[EYE_RIGHT])
    if face.eyes < 2.0:
        return

    var kind: String = looks.get("face", "plain")
    var skin: Color = CaptainOptions.SKINS[int(looks.get("skin", 0))]
    var hair: Color = CaptainOptions.HAIR_COLORS[int(looks.get("hair_color", 0))]

    if face_alpha > 0.0 and kind in ["freckles", "moustache_freckles"]:
        _draw_freckles(canvas, face, points, skin, face_alpha)
    if face_alpha > 0.0 and kind in ["moustache", "moustache_freckles"]:
        _draw_moustache(canvas, face, points, hair, face_alpha)

    var patch: String = looks.get("eye_patch", "none")
    if cap_alpha > 0.0 and patch in ["left", "right"]:
        var on_left_of_screen := (patch == "left") == mirrored
        _draw_eye_patch(
            canvas, face, points[EYE_LEFT if on_left_of_screen else EYE_RIGHT], cap_alpha
        )

    if cap_alpha > 0.0:
        # NOTE (mristin):
        # The cap must reach above the hair, so we take the top of the head box
        # if it is higher than a usual head (1.9 eyes above the eye line).
        var top_of_head := head.position + Vector2(head.size.x * 0.5, 0)
        var crown := clampf(face.up_of(top_of_head) + 0.1, 1.9, 2.6)
        var half := clampf(head.size.x * 0.5 / face.eyes * 1.05, _HALF_WIDTH, 1.6)
        _draw_cap(canvas, face, looks.get("cap", "none"), crown, half, cap_alpha)


static func _draw_freckles(
    canvas: CanvasItem, face: Face, points: PackedVector2Array, skin: Color, alpha: float
) -> void:
    var nose_y := face.up_of(points[NOSE])
    var color := Color(skin.darkened(0.5).lerp(Color(0.55, 0.28, 0.12), 0.5), alpha * 0.7)

    # NOTE (mristin):
    # The freckles scatter over the cheeks and across the bridge of the nose; we
    # place them by a fixed pattern (x, the share of the way down to the nose,
    # and the radius, in eyes), so that they do not dance.
    var pattern := [
        Vector3(0.52, 0.55, 0.035),
        Vector3(0.64, 0.45, 0.03),
        Vector3(0.6, 0.66, 0.028),
        Vector3(0.74, 0.58, 0.033),
        Vector3(0.47, 0.75, 0.025),
        Vector3(0.7, 0.78, 0.028),
        Vector3(0.82, 0.7, 0.024),
        Vector3(0.56, 0.86, 0.022),
        Vector3(0.14, 0.3, 0.022),
        Vector3(0.2, 0.42, 0.02),
    ]
    for freckle in pattern:
        for side in [-1.0, 1.0]:
            var at := face.at(side * freckle.x, nose_y * freckle.y)
            canvas.draw_circle(at, maxf(1.0, face.px(freckle.z)), color, true, -1.0, true)


## Draw a full moustache just below the nose: thick in the middle, parted under
## the nose, and with the tips curling down past the corners of the mouth.
static func _draw_moustache(
    canvas: CanvasItem, face: Face, points: PackedVector2Array, hair: Color, alpha: float
) -> void:
    var nose_y := face.up_of(points[NOSE])
    var mouth_y := (face.up_of(points[MOUTH_LEFT]) + face.up_of(points[MOUTH_RIGHT])) * 0.5
    var mouth_left := face.right_of(points[MOUTH_LEFT])
    var mouth_right := face.right_of(points[MOUTH_RIGHT])
    var middle_x := (face.right_of(points[NOSE]) + (mouth_left + mouth_right) * 0.5) * 0.5

    # The upper edge sits just below the tip of the nose, the lower edge on the
    # upper lip.
    var gap := nose_y - mouth_y
    var top := nose_y - gap * 0.22
    var bottom := nose_y - gap * 0.72
    var half := maxf((mouth_right - mouth_left) * 0.5, 0.3) * 1.35

    var dark := hair.darkened(0.25)
    var light := hair.lightened(0.18)
    var steps := 10
    for side in [-1.0, 1.0]:
        var outline := PackedVector2Array()
        var colors := PackedColorArray()

        # The upper edge from the parting to the tip, then the lower edge back.
        for i in range(steps + 1):
            var t := float(i) / steps
            var y := top - t * t * (top - bottom) * 0.9 - t * gap * 0.15
            outline.append(face.at(middle_x + side * (0.03 + t * half), y))
            colors.append(Color(light.lerp(dark, t * 0.6), alpha))
        outline.append(face.at(middle_x + side * (half + 0.08), bottom - gap * 0.45))
        colors.append(Color(dark, alpha))
        for i in range(steps, -1, -1):
            var t := float(i) / steps
            var y := bottom - t * t * gap * 0.3
            outline.append(face.at(middle_x + side * (0.03 + t * half * 0.92), y))
            colors.append(Color(hair.lerp(dark, 0.5), alpha))
        canvas.draw_polygon(outline, colors)

        # The hairs comb out from the parting.
        var strand := Color(dark, alpha * 0.8)
        for i in range(7):
            var t := (i + 0.5) / 7.0
            var x: float = middle_x + side * (0.05 + t * half * 0.9)
            var upper := top - t * t * (top - bottom) * 0.9 - t * gap * 0.15
            var lower := bottom - t * t * gap * 0.3
            canvas.draw_line(
                face.at(x - side * 0.04, lerpf(upper, lower, 0.15)),
                face.at(x + side * 0.03, lerpf(upper, lower, 0.85)),
                strand,
                maxf(1.0, face.px(0.018)),
                true
            )


## Draw a leather eye patch over the [param eye], tied with a strap which runs
## up across the forehead on one side and over the ear on the other; the cap
## covers the strap on top.
static func _draw_eye_patch(canvas: CanvasItem, face: Face, eye: Vector2, alpha: float) -> void:
    var x := face.right_of(eye)
    var y := face.up_of(eye)
    var side := signf(x) if x != 0.0 else 1.0
    var strap := Color(_LEATHER.lightened(0.08), alpha)
    var width := maxf(1.5, face.px(0.06))

    # The strap: from the inner edge of the patch up across the forehead, and
    # from the outer edge back over the ear.
    canvas.draw_line(
        face.at(x - side * 0.2, y + 0.1), face.at(-side * 0.9, y + 1.6), strap, width, true
    )
    canvas.draw_line(
        face.at(x + side * 0.22, y + 0.06), face.at(side * 1.3, y + 0.3), strap, width, true
    )

    # The patch, rounded and a bit wider than high, darker at its lower edge.
    var outline := PackedVector2Array()
    var colors := PackedColorArray()
    for i in range(28):
        var angle := TAU * i / 28.0
        var dx := cos(angle) * 0.3
        var dy := sin(angle) * 0.24 - 0.02
        outline.append(face.at(x + dx, y + dy))
        var light := 0.5 + 0.5 * (sin(angle) * 0.8 - cos(angle) * 0.4)
        colors.append(Color(_LEATHER.lightened(0.18 * light), alpha))
    canvas.draw_polygon(outline, colors)

    # The stitches around the rim and a glint on the leather.
    var stitch := Color(0.45, 0.38, 0.3, alpha)
    for i in range(14):
        var angle := TAU * i / 14.0
        var at := face.at(x + cos(angle) * 0.25, y + sin(angle) * 0.19 - 0.02)
        canvas.draw_circle(at, maxf(0.75, face.px(0.016)), stitch, true, -1.0, true)
    var glint := face.at(x - 0.08, y + 0.08)
    canvas.draw_circle(glint, face.px(0.05), Color(1, 1, 1, alpha * 0.18), true, -1.0, true)


static func _draw_cap(
    canvas: CanvasItem, face: Face, cap: String, crown: float, half: float, alpha: float
) -> void:
    match cap:
        "lika":
            _draw_lika(canvas, face, crown, half, alpha)
        "feather":
            _draw_lika(canvas, face, crown, half, alpha)
            _draw_feather(canvas, face, crown, half, alpha)
            _draw_brooch(canvas, face, half, alpha)
        "kalpak":
            _draw_kalpak(canvas, face, crown, half, alpha)
        "headscarf":
            _draw_headscarf(canvas, face, crown, half, alpha)
        _:
            pass


## The Lika cap: a red cap with a black band embroidered at the brim, and the
## black silk tassels hanging on the side.
static func _draw_lika(
    canvas: CanvasItem, face: Face, crown: float, half: float, alpha: float
) -> void:
    var top := crown + 0.12
    var top_half := half * 0.93
    _draw_tassels(canvas, face, top, half, alpha)
    _draw_side(canvas, face, _BRIM, top, half, top_half, _RED, alpha)
    var band := _BRIM + 0.42
    var band_half := lerpf(half, top_half, 0.42 / (top - _BRIM))
    _draw_side(canvas, face, _BRIM, band, half, band_half, _BLACK, alpha)

    # The embroidery of the band: a row of small golden and red stitches.
    var stitch := maxf(1.0, face.px(0.03))
    for i in range(15):
        var t := (i + 0.5) / 15.0 * 2.0 - 1.0
        var color := _GOLD if i % 2 == 0 else Color(0.85, 0.18, 0.12)
        var at := face.at(t * half * 0.97, _BRIM + 0.21 + _bend(t, half))
        canvas.draw_circle(at, stitch, _shade(color, t, alpha), true, -1.0, true)

    _draw_lid(canvas, face, top, top_half, _RED.lightened(0.08), alpha)


static func _draw_tassels(
    canvas: CanvasItem, face: Face, top: float, half: float, alpha: float
) -> void:
    # The tassels hang from the top on the left side, over the ear.
    var root := Vector2(-half * 0.9, top - 0.15)
    for i in range(9):
        var t := i / 8.0
        var end := Vector2(-half * (1.02 + 0.12 * t), _BRIM - 0.35 - 0.25 * sin(t * PI))
        canvas.draw_line(
            face.at(root.x + 0.03 * i, root.y),
            face.at(end.x, end.y),
            Color(_BLACK.lightened(0.12 * (i % 3)), alpha),
            maxf(1.0, face.px(0.04)),
            true
        )


## The kalpak: a tall cap of dark lamb fur with a red cloth top.
static func _draw_kalpak(
    canvas: CanvasItem, face: Face, crown: float, half: float, alpha: float
) -> void:
    var top := crown + 0.55
    var top_half := half * 0.9
    _draw_side(canvas, face, _BRIM, top, half, top_half, _FUR, alpha)
    _draw_lid(canvas, face, top, top_half, _RED, alpha)

    # The curls of the fur, by a fixed pattern, lighter toward the light.
    var rows := 9
    var columns := 11
    var width := maxf(1.0, face.px(0.045))
    var angle := face.right.angle()
    for row in range(rows):
        var v := (row + 0.5) / rows
        var y_base := lerpf(_BRIM, top, v)
        var row_half := lerpf(half, top_half, v)
        for column in range(columns):
            var t := ((column + 0.5 + 0.5 * (row % 2)) / columns) * 2.0 - 1.0
            if absf(t) > 0.97:
                continue
            var y := y_base + _bend(t, row_half) * (1.0 - v) + 0.04 * sin(column * 2.7 + row)
            var radius := face.px(0.075 + 0.02 * sin(column * 1.3 + row * 2.1))
            canvas.draw_arc(
                face.at(t * row_half, y),
                radius,
                angle + PI * 0.9,
                angle + TAU * 0.95,
                8,
                _shade(_FUR.lightened(0.28), t, alpha * 0.9),
                width,
                true
            )

    # The fur is shaggy at the edges.
    for i in range(16):
        var v := (i + 0.5) / 16.0
        var y := lerpf(_BRIM, top, v)
        var edge := lerpf(half, top_half, v)
        for side in [-1.0, 1.0]:
            canvas.draw_circle(
                face.at(side * edge, y), face.px(0.07), _shade(_FUR, side, alpha), true, -1.0, true
            )


## The headscarf (marama): white linen over the head and down the sides of the
## face, with a red embroidered band over the forehead.
static func _draw_headscarf(
    canvas: CanvasItem, face: Face, crown: float, half: float, alpha: float
) -> void:
    var top := crown + 0.1
    var outer := half * 1.05
    var inner := half * 0.78
    var chin := 1.25
    var steps := 24

    # The scarf goes around the head and frames the face: up the outer edge,
    # over the top and down, then back up along the face and over the forehead.
    var outline := PackedVector2Array()
    var colors := PackedColorArray()
    for i in range(steps + 1):
        var angle := PI * float(i) / steps
        var t := -cos(angle)
        var y := -chin if i == 0 or i == steps else _BRIM + sin(angle) * (top - _BRIM)
        outline.append(face.at(t * outer, y))
        colors.append(_shade(_LINEN, t, alpha))
    outline.append(face.at(inner, -chin))
    colors.append(_shade(_LINEN, 1.0, alpha))
    for i in range(steps + 1):
        var angle := PI * float(i) / steps
        var t := cos(angle)
        outline.append(face.at(t * inner, _BRIM + sin(angle) * 0.12))
        colors.append(_shade(_LINEN, t, alpha))
    outline.append(face.at(-inner, -chin))
    colors.append(_shade(_LINEN, -1.0, alpha))
    canvas.draw_polygon(outline, colors)

    # The folds of the linen fall from the crown.
    var fold := Color(_LINEN.darkened(0.25), alpha * 0.8)
    for i in range(6):
        var t := (i + 0.5) / 6.0 * 2.0 - 1.0
        var points := PackedVector2Array()
        for k in range(8):
            var v := k / 7.0
            var x := t * lerpf(outer * 0.35, outer * 0.95, v)
            var y := lerpf(top - 0.25, _BRIM + 0.3, v) - absf(t) * v * 0.6
            points.append(face.at(x, y))
        canvas.draw_polyline(points, fold, maxf(1.0, face.px(0.03)), true)

    # The embroidered band over the forehead.
    var band := PackedVector2Array()
    var band_colors := PackedColorArray()
    for i in range(steps + 1):
        var t := float(i) / steps * 2.0 - 1.0
        band.append(face.at(t * inner * 1.04, _BRIM + 0.12 * sqrt(1.0 - t * t) + 0.24))
        band_colors.append(_shade(_RED, t, alpha))
    for i in range(steps, -1, -1):
        var t := float(i) / steps * 2.0 - 1.0
        band.append(face.at(t * inner * 1.04, _BRIM + 0.12 * sqrt(1.0 - t * t) - 0.02))
        band_colors.append(_shade(_RED.darkened(0.2), t, alpha))
    canvas.draw_polygon(band, band_colors)
    for i in range(11):
        var t := (i + 0.5) / 11.0 * 2.0 - 1.0
        var at := face.at(t * inner, _BRIM + 0.12 * sqrt(1.0 - t * t) + 0.11)
        canvas.draw_circle(at, maxf(1.0, face.px(0.035)), _shade(_GOLD, t, alpha), true, -1.0, true)


## A white heron feather which stands up from the right side of the cap.
static func _draw_feather(
    canvas: CanvasItem, face: Face, crown: float, half: float, alpha: float
) -> void:
    var root := Vector2(half * 0.75, _BRIM + 0.4)
    var tip := Vector2(half * 1.25, crown + 1.3)
    var axis := tip - root
    var side := Vector2(-axis.y, axis.x).normalized()

    var vane := PackedVector2Array()
    var colors := PackedColorArray()
    for i in range(13):
        var t := 0.15 + 0.85 * i / 12.0
        var at := root + axis * t + side * 0.16 * sin(PI * pow(t, 0.8))
        vane.append(face.at(at.x, at.y))
        colors.append(Color(_FEATHER.darkened(0.15 * t), alpha))
    for i in range(12, -1, -1):
        var t := 0.15 + 0.85 * i / 12.0
        var at := root + axis * t - side * 0.12 * sin(PI * pow(t, 0.8))
        vane.append(face.at(at.x, at.y))
        colors.append(Color(_FEATHER.darkened(0.08), alpha))
    canvas.draw_polygon(vane, colors)

    # The barbs and the shaft.
    var barb := Color(_FEATHER.darkened(0.3), alpha * 0.7)
    for i in range(14):
        var t := 0.2 + 0.75 * i / 13.0
        var at := root + axis * t
        var w := 0.14 * sin(PI * pow(t, 0.8))
        for s in [-1.0, 1.0]:
            var end: Vector2 = at + side * w * s + axis * 0.04
            canvas.draw_line(face.at(at.x, at.y), face.at(end.x, end.y), barb, 1.0, true)
    canvas.draw_line(
        face.at(root.x, root.y),
        face.at(tip.x, tip.y),
        Color(_FEATHER.darkened(0.35), alpha),
        maxf(1.0, face.px(0.025)),
        true
    )


## The brass brooch which pins the feather to the cap.
static func _draw_brooch(canvas: CanvasItem, face: Face, half: float, alpha: float) -> void:
    var at := face.at(half * 0.75, _BRIM + 0.45)
    canvas.draw_circle(at, face.px(0.14), Color(_GOLD.darkened(0.35), alpha), true, -1.0, true)
    canvas.draw_circle(at, face.px(0.11), Color(_GOLD, alpha), true, -1.0, true)
    var glint := at + (face.up - face.right) * face.px(0.04)
    canvas.draw_circle(glint, face.px(0.04), Color(1, 0.95, 0.75, alpha), true, -1.0, true)


## Draw the side of an upright cylinder (narrowing from [param bottom_half] to
## [param top_half]), lit from the upper left; its edges bend down at the
## front, as the camera looks down on it.
static func _draw_side(
    canvas: CanvasItem,
    face: Face,
    bottom: float,
    top: float,
    bottom_half: float,
    top_half: float,
    color: Color,
    alpha: float
) -> void:
    var columns := 24
    for i in range(columns):
        var t0 := float(i) / columns * 2.0 - 1.0
        var t1 := float(i + 1) / columns * 2.0 - 1.0
        var quad := PackedVector2Array(
            [
                face.at(t0 * top_half, top + _bend(t0, top_half)),
                face.at(t1 * top_half, top + _bend(t1, top_half)),
                face.at(t1 * bottom_half, bottom + _bend(t1, bottom_half)),
                face.at(t0 * bottom_half, bottom + _bend(t0, bottom_half)),
            ]
        )
        var colors := PackedColorArray(
            [
                _shade(color, t0, alpha),
                _shade(color, t1, alpha),
                _shade(color.darkened(0.12), t1, alpha),
                _shade(color.darkened(0.12), t0, alpha),
            ]
        )
        canvas.draw_polygon(quad, colors)


## Draw the top of a cylinder as an ellipse, lighter toward the light.
static func _draw_lid(
    canvas: CanvasItem, face: Face, top: float, half: float, color: Color, alpha: float
) -> void:
    var outline := PackedVector2Array()
    var colors := PackedColorArray()
    for i in range(32):
        var angle := TAU * i / 32.0
        outline.append(face.at(cos(angle) * half, top + sin(angle) * half * _LID))
        colors.append(_shade(color.lightened(0.1), cos(angle) * 0.6 - sin(angle) * 0.4, alpha))
    canvas.draw_polygon(outline, colors)


## How much lower the front of a cylinder is than its sides, seen a bit from
## above; [param t] runs from -1 (left) to 1 (right).
static func _bend(t: float, half: float) -> float:
    return -half * _LID * sqrt(maxf(0.0, 1.0 - t * t))


## Shade a colour on a round surface whose normal points to [param t] (from
## -1, left, to 1, right), lit from the upper left.
static func _shade(color: Color, t: float, alpha: float) -> Color:
    var light := clampf(0.62 - 0.55 * clampf(t, -1.0, 1.0), 0.0, 1.0)
    var shaded := (
        color.darkened(0.5 * (0.75 - light))
        if light < 0.75
        else color.lightened(0.6 * (light - 0.75))
    )
    return Color(shaded, alpha)
