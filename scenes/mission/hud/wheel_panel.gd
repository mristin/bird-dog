class_name WheelPanel
extends Control

## Show the players how the game sees them while sailing (see DESIGN.md, "The
## view at sea"): the mirrored camera picture, every player's ship's wheel
## pinned to their head and turned by their steering, the head lines at the
## noses, and the hands. Behind the wheel, every face wears the cap, the eye
## patch, the moustache and the freckles of its captain, fitted to the
## landmarks of the face (see FaceOverlay). They are composed in a layer of
## their own, which is faded as a whole, so that the wheel stands out.
##
## With two players, as in ergo-chaos, the panel shows one picture with a line
## down the middle: the player on the left of the mirrored picture steers the
## first boat, the player on the right the second. The panel stands at the
## bottom between the two halves of the screen.

## How opaque the whole dress of the faces is, behind the wheel.
const OVERLAY_ALPHA := 0.45

## How opaque the moustache and the freckles are within the dress.
const FACE_ALPHA := 0.85

## How opaque the caps and the eye patches are within the dress; they hide the
## forehead and the hair on top.
const CAP_ALPHA := 1.0

## The steering of every player, from -1 to 1.
var steers: Array[float] = [0.0]

## The colours of the captains, for the wheels' rims and the frame.
var colors: Array[Color] = [Paper.INK]

## The looks of the captains (see CaptainOptions), to dress the faces; a player
## without looks shows the bare face.
var looks: Array[Dictionary] = []

var _angles: Array[float] = []
var _centers: Array = []
var _radii: Array[float] = []
var _center_smoothers: Array[PointSmoother] = []
var _hand_smoothers: Array[PointSmoother] = []
var _hands: Array = []
var _head_sizes: Array[Vector2] = []
var _face_alphas: Array[float] = []
var _face_points: Array[PackedVector2Array] = []

var _picture: Control
var _faces: CanvasGroup
var _face_layer: Control
var _wheel_layer: Control

@onready var _vision: Node = get_node("/root/Vision").hands
@onready var _pose: Node = get_node("/root/Vision").poses


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    # NOTE (mristin):
    # The panel draws the camera picture itself; on top come the faces, faded
    # as one (a CanvasGroup, so that the parts of a cap do not show through
    # each other), and the wheels on top of everything. The picture clips them,
    # so that a tall cap does not reach out of the panel.
    _picture = Control.new()
    _picture.clip_contents = true
    _picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_picture)
    _faces = CanvasGroup.new()
    _faces.self_modulate = Color(1, 1, 1, OVERLAY_ALPHA)
    _picture.add_child(_faces)
    _face_layer = Control.new()
    _face_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _face_layer.draw.connect(_draw_faces)
    _faces.add_child(_face_layer)
    _wheel_layer = Control.new()
    _wheel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _wheel_layer.draw.connect(_draw_wheels)
    _picture.add_child(_wheel_layer)
    for i in range(steers.size()):
        _angles.append(0.0)
        _centers.append(null)
        _radii.append(60.0)
        _center_smoothers.append(PointSmoother.new())
        _hand_smoothers.append(PointSmoother.new())
        _hands.append([])
        _head_sizes.append(Vector2.ZERO)
        _face_alphas.append(0.0)
        _face_points.append(PackedVector2Array())


func _process(delta: float) -> void:
    var players: Array = _pose.GetPlayers()
    for i in range(steers.size()):
        _angles[i] = lerpf(_angles[i], steers[i] * 2.2, 1.0 - exp(-delta * 16.0))
        var targets: Array[Vector2] = []
        var raised: Array[bool] = []
        var has_head: bool = i < players.size() and players[i]["has_head"]
        _face_alphas[i] = move_toward(_face_alphas[i], 1.0 if has_head else 0.0, delta * 4.0)
        if has_head:
            var head: Rect2 = players[i]["head"]
            var center := head.get_center() * size
            if _head_sizes[i] == Vector2.ZERO:
                _head_sizes[i] = head.size * size
            else:
                _head_sizes[i] = _head_sizes[i].lerp(head.size * size, 1.0 - exp(-delta * 6.0))
            _update_face(i, players[i], Rect2(head.position * size, head.size * size), delta)
            var radius := minf(head.size.y * size.y * 1.4, size.y * 0.42)
            if _centers[i] == null:
                _centers[i] = center
            else:
                _centers[i] = _center_smoothers[i].update([center] as Array[Vector2], delta)[0]
            _radii[i] = lerpf(_radii[i], radius, 1.0 - exp(-delta * 3.0))
            for hand in players[i]["hands"]:
                var rect: Rect2 = hand["rect"]
                targets.append(rect.get_center() * size)
                raised.append(hand["raised"])
        var smoothed := _hand_smoothers[i].update(targets, delta)
        var hands := []
        for k in range(smoothed.size()):
            hands.append([smoothed[k], raised[k]])
        _hands[i] = hands

    _picture.size = size
    _face_layer.size = size
    _wheel_layer.size = size
    queue_redraw()
    _face_layer.queue_redraw()
    _wheel_layer.queue_redraw()


## Ease the landmarks of the face toward the latest ones, or toward those
## guessed from the head box if the face was not found.
func _update_face(i: int, player: Dictionary, head: Rect2, delta: float) -> void:
    var targets: PackedVector2Array
    if player.has("face"):
        targets = FaceOverlay.points_from_face(player["face"], size)
    else:
        targets = FaceOverlay.points_from_head(head)

    if _face_points[i].size() != targets.size():
        _face_points[i] = targets
        return

    var follow := 1.0 - exp(-delta * 14.0)
    var points := _face_points[i]
    for k in range(points.size()):
        points[k] = points[k].lerp(targets[k], follow)
    _face_points[i] = points


func _draw() -> void:
    draw_rect(Rect2(Vector2(6, 8), size), Color(0, 0, 0, 0.25))
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.1, 0.14))
    var texture: Texture2D = _vision.GetCameraTexture()
    if texture != null and texture.get_size().x > 0:
        if _vision.Mirror:
            draw_set_transform(Vector2(size.x, 0), 0, Vector2(-1, 1))
        draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.85))
        draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

    var count := steers.size()
    if count > 1:
        draw_dashed_line(
            Vector2(size.x * 0.5, 6),
            Vector2(size.x * 0.5, size.y - 6),
            Color(1, 1, 1, 0.8),
            4.0,
            14.0
        )


func _draw_faces() -> void:
    for i in range(steers.size()):
        if i < looks.size() and _centers[i] != null:
            var head := Rect2(_centers[i] - _head_sizes[i] * 0.5, _head_sizes[i])
            FaceOverlay.draw(
                _face_layer,
                head,
                _face_points[i],
                looks[i],
                FACE_ALPHA * _face_alphas[i],
                CAP_ALPHA * _face_alphas[i],
                _vision.Mirror
            )


func _draw_wheels() -> void:
    var canvas := _wheel_layer
    var count := steers.size()
    var players: Array = _pose.GetPlayers()
    for i in range(count):
        var fallback := Vector2(size.x * (i + 0.5) / count, size.y * 0.5)
        var center: Vector2 = _centers[i] if _centers[i] != null else fallback
        ShipWheel.draw(canvas, center, _radii[i], _angles[i], 0.95)
        if count > 1:
            canvas.draw_arc(center, _radii[i] * 1.08, 0, TAU, 40, colors[i], 5.0, true)
        if i < players.size() and players[i]["has_head"]:
            var y := float(players[i]["head_line_y"]) * size.y
            var left := size.x * i / count
            canvas.draw_dashed_line(
                Vector2(left + 10, y), Vector2(left + size.x / count - 10, y), Paper.GOLD, 4.0, 14.0
            )
        for hand in _hands[i]:
            HandMarker.draw(canvas, hand[0], hand[1], 22.0)

    canvas.draw_rect(Rect2(Vector2.ZERO, size), Paper.INK, false, 4.0)
    if count > 1:
        for i in range(count):
            canvas.draw_rect(Rect2(size.x * i / count, 0, size.x / count, 6), colors[i])
