class_name HandCursor
extends Control

## Point with an open hand and click with a fist, in the menus and the ports.
##
## Every hand in front of the camera gets a cursor: a seagull in a ring. To
## click, the player closes an open hand into a fist and holds the fist for
## [constant FIST_HOLD_SECONDS]; a golden ring fills around the cursor meanwhile.
##
## We are strict, so that a calm hand never clicks by itself:
##
## * a hold starts only when the vision sees an open hand close into a fist
##   (its ShotFired signal); a hand which merely looks like a fist for a while
##   never starts one,
## * the fist must stay clear (its probability at least
##   [constant FIST_PROBABILITY]) for the whole hold; otherwise the ring empties,
## * and a fist clicks only once; the hand has to open and close again.
##
## The cursor of a hand is calm and sticky, since the hands of children are
## hard to hold still and the detections jitter: it smooths strongly and
## ignores small shakes (see PointSmoother.dead_zone), a cursor on a button
## sticks to it (it is drawn towards the middle and leaves only when the hand
## moves clearly beyond the edge), and it stands still while the fist is held,
## so that closing the hand does not move it off the button.
##
## The mouse clicks at once, for testing; it shows as a seagull, too, instead
## of the pointer of the system.
##
## Behind the cursors, the players see themselves dimly, mirrored, so that each
## hand in the picture lies right under its cursor (as in Splash 'n' Splat).
##
## The menus ask for [method get_pointers] to highlight what is pointed at, and
## listen to [signal clicked].

## A hand or the mouse clicked at this position (in the coordinates of the screen).
signal clicked(at_position: Vector2)

## The group of the hand cursor, so that the buttons find it.
const GROUP := "hand_cursor"

## The radius of the hand symbol (the ring with the seagull), in pixels. The
## hand markers while steering (see HandMarker) have the same size.
const RADIUS := 51.0

## Hold the fist this long, in seconds, to click.
const FIST_HOLD_SECONDS := 1.5

## The fist must be at least this probable during the whole hold.
const FIST_PROBABILITY := 0.75

## A hold survives this long without a clear fist (the classifier flickers).
const _FIST_GRACE_SECONDS := 0.25

## The mouse counts as a pointer this long after it moved, in seconds.
const _MOUSE_SECONDS := 3.0

## A cursor on a button leaves it only when the hand is this far beyond its
## edge, in pixels, but at most [constant STICKY_MARGIN_SHARE] of the smaller
## side of the button (so that the neighbouring keys of the name keyboard
## stay easy to reach).
const STICKY_MARGIN := 70.0
const STICKY_MARGIN_SHARE := 0.35

## On a button, the cursor moves only this share of the way of the hand from
## the middle of the button, so that it stays well inside.
const STICKY_SHARE := 0.35

## The time constant of the cursor moving onto, along and off a button, in
## seconds, so that it glides instead of jumping.
const _GLIDE_SECONDS := 0.08

const _RING := Color(1, 1, 1, 0.9)
const _BACKING := Color(0.1, 0.12, 0.2, 0.7)
const _FIST := Color(1.0, 0.85, 0.3)

## How strongly the camera picture shows through.
@export_range(0.0, 1.0) var camera_opacity := 0.22

## The part of the picture (as the players see it, from 0 to 1) whose hands
## this cursor follows: all of it, or the half of one player when two players
## have a half of the screen each. The part fills the cursor's control.
var region := Rect2(0, 0, 1, 1)

var _mouse_at := Vector2.ZERO
var _mouse_moved := -INF
var _flashes: Array = []

## The fists being held, by the id of the hand: how long ("held") and how long
## without a clear fist since ("away"). A hold exists only from the moment an
## open hand closed into a fist until the click or until the fist is gone.
var _holds := {}

## Smooth the cursors, so that they stand calm while the hand holds still.
var _smoother := _make_smoother()

## The smoothed position of every hand on the screen, by the id of the hand.
var _smoothed := {}

## Where the cursor of every hand is shown (on a button, drawn to it), by the
## id of the hand.
var _positions := {}

## The button which the cursor of a hand sticks to, by the id of the hand.
var _stuck := {}

# NOTE (mristin):
# We reach the autoloads by their paths, so that the scripts also type-check on
# their own, without the project's autoloads.
@onready var _hands: Node = get_node("/root/Vision").hands


func _ready() -> void:
    # NOTE (mristin):
    # Set the offsets, too, so that the cursor (and the camera picture behind
    # it) fills a CanvasLayer as well, not only a full-screen parent control.
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_to_group(GROUP)
    # NOTE (mristin):
    # The cursor draws the mouse as a seagull, too, so the pointer of the
    # system would only be in the way.
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
    _hands.connect("ShotFired", _on_hand_closed)


func _exit_tree() -> void:
    if _hands.is_connected("ShotFired", _on_hand_closed):
        _hands.disconnect("ShotFired", _on_hand_closed)


## An open hand just closed into a fist: start its hold.
func _on_hand_closed(hand_id: int) -> void:
    _holds[hand_id] = {"held": 0.0, "away": 0.0}


func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _mouse_at = event.position
        _mouse_moved = _now()
    elif (
        event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
    ):
        _mouse_at = event.position
        _mouse_moved = _now()
        _click(event.position)


static func _make_smoother() -> PointSmoother:
    var smoother := PointSmoother.new()
    smoother.calm_seconds = 0.35
    smoother.fast_seconds = 0.06
    smoother.fast_speed = 1500.0
    smoother.dead_zone = 10.0
    return smoother


func _process(delta: float) -> void:
    var targets := {}
    for aim in _aims():
        targets[aim["hand_id"]] = _to_screen(aim["position"])
    _smoothed = _smoother.update_keyed(targets, delta)
    _place_cursors(delta)

    _update_holds(delta)
    for flash in _flashes:
        flash["time"] += delta
    _flashes = _flashes.filter(func(flash): return flash["time"] < 0.4)
    queue_redraw()


func _now() -> float:
    return Time.get_ticks_msec() / 1000.0


## Get where the hands (and, if it moved recently, the mouse) point, in the
## coordinates of the screen.
func get_pointers() -> Array[Vector2]:
    var pointers: Array[Vector2] = []
    for aim in _aims():
        pointers.append(_position_of(aim))
    if _now() - _mouse_moved < _MOUSE_SECONDS:
        pointers.append(_mouse_at)
    return pointers


## Get the fists being held: each a dictionary with "position" (in the
## coordinates of the screen) and "progress" toward the click, in (0, 1].
func get_charges() -> Array[Dictionary]:
    var charges: Array[Dictionary] = []
    for aim in _aims():
        var progress := _hold_progress(aim["hand_id"])
        if progress > 0.0:
            charges.append({"position": _position_of(aim), "progress": progress})
    return charges


func _to_screen(normalized: Vector2) -> Vector2:
    return (normalized - region.position) / region.size * size


## The aims of the hands in the region of the cursor.
func _aims() -> Array:
    var aims: Array = []
    for aim in _hands.GetAims():
        if region.has_point(aim["position"]):
            aims.append(aim)
    return aims


## Where the hand of the aim points on the screen, smoothed.
func _position_of(aim: Dictionary) -> Vector2:
    return _positions.get(aim["hand_id"], _to_screen(aim["position"]))


func _update_holds(delta: float) -> void:
    var seen := {}
    for aim in _aims():
        var hand_id: int = aim["hand_id"]
        seen[hand_id] = true
        if not _holds.has(hand_id):
            continue
        var hold: Dictionary = _holds[hand_id]

        var clear_fist: bool = (
            aim["gesture"] == "fist" and float(aim["fist_probability"]) >= FIST_PROBABILITY
        )
        if clear_fist:
            hold["away"] = 0.0
            hold["held"] += delta
            if hold["held"] >= FIST_HOLD_SECONDS:
                _holds.erase(hand_id)
                _click(_position_of(aim))
        else:
            hold["away"] += delta
            if hold["away"] > _FIST_GRACE_SECONDS:
                _holds.erase(hand_id)

    for hand_id in _holds.keys():
        if not seen.has(hand_id):
            _holds.erase(hand_id)


## Place the cursor of every hand: where the hand points, but stuck to the
## button it is on, and still while its fist is held.
func _place_cursors(delta: float) -> void:
    var buttons: Array = []
    for button in get_tree().get_nodes_in_group(HandButton.GROUP):
        if button.is_active_for(self):
            buttons.append(button)
    var glide := 1.0 - exp(-delta / _GLIDE_SECONDS)
    var placed := {}
    for hand_id in _smoothed:
        var at: Vector2 = _smoothed[hand_id]
        var previous: Vector2 = _positions.get(hand_id, at)
        if _holds.has(hand_id):
            placed[hand_id] = previous
            continue
        # NOTE (mristin):
        # A button may be gone (a new screen); check it before typing it.
        var stuck: Variant = _stuck.get(hand_id)
        var button: HandButton = null
        if (
            is_instance_valid(stuck)
            and buttons.has(stuck)
            and stuck.get_global_rect().grow(_margin_of(stuck)).has_point(at)
        ):
            button = stuck
        if button == null:
            button = _button_at(buttons, at)
        if button == null:
            _stuck.erase(hand_id)
            placed[hand_id] = previous.lerp(at, glide)
            continue
        _stuck[hand_id] = button
        var middle := button.get_global_rect().get_center()
        var wanted := middle + (at - middle) * STICKY_SHARE
        if not button.contains(wanted):
            wanted = middle
        placed[hand_id] = previous.lerp(wanted, glide)
    for hand_id in _stuck.keys():
        if not placed.has(hand_id):
            _stuck.erase(hand_id)
    _positions = placed


func _margin_of(button: HandButton) -> float:
    return minf(STICKY_MARGIN, minf(button.size.x, button.size.y) * STICKY_MARGIN_SHARE)


## The smallest button under the point, or null.
func _button_at(buttons: Array, at: Vector2) -> HandButton:
    var best: HandButton = null
    for button in buttons:
        if button.contains(at):
            var area: float = button.size.x * button.size.y
            if best == null or area < best.size.x * best.size.y:
                best = button
    return best


## How far the fist of the hand is toward a click, in [0, 1].
func _hold_progress(hand_id: int) -> float:
    if not _holds.has(hand_id):
        return 0.0
    return clampf(_holds[hand_id]["held"] / FIST_HOLD_SECONDS, 0.0, 1.0)


func _click(at_position: Vector2) -> void:
    _flashes.append({"at": at_position, "time": 0.0})
    clicked.emit(at_position)


func _draw() -> void:
    _draw_camera()

    for aim in _aims():
        _draw_cursor(_position_of(aim), _hold_progress(aim["hand_id"]))
    if _now() - _mouse_moved < _MOUSE_SECONDS:
        _draw_cursor(_mouse_at, 0.0)

    for flash in _flashes:
        var t: float = flash["time"] / 0.4
        var flash_radius := RADIUS * (1.2 + 1.5 * t)
        draw_arc(flash["at"], flash_radius, 0, TAU, 40, Color(_FIST, 1.0 - t), 8.0, true)


## Show exactly the region of the camera which the vision maps to the screen.
func _draw_camera() -> void:
    var texture: Texture2D = _hands.GetCameraTexture()
    if texture == null or camera_opacity <= 0.0:
        return
    var texture_size := texture.get_size()
    if texture_size.x <= 0 or texture_size.y <= 0:
        return

    var aim_region: Rect2 = _hands.GetAimRegion()

    # NOTE (mristin):
    # The region of the cursor is in the picture as the players see it, which
    # is mirrored: its left is the right of the texture.
    var left := region.position.x
    if _hands.Mirror:
        left = 1.0 - region.end.x
    var source := Rect2(
        (aim_region.position + Vector2(left, region.position.y) * aim_region.size) * texture_size,
        region.size * aim_region.size * texture_size
    )
    if _hands.Mirror:
        draw_set_transform(Vector2(size.x, 0), 0, Vector2(-1, 1))
    draw_texture_rect_region(
        texture, Rect2(Vector2.ZERO, size), source, Color(1, 1, 1, camera_opacity)
    )
    draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Draw a seagull in a ring. While the fist is held, its power accumulates: a
## golden glow swells, sparks stream into the fist, the ring fills and thickens,
## and the cursor pulses faster and faster until it clicks.
func _draw_cursor(at: Vector2, progress: float) -> void:
    var radius := RADIUS
    if progress > 0.0:
        var pulse := 1.0 + 0.08 * progress * sin(_now() * (6.0 + 18.0 * progress))
        radius *= 1.0 + 0.25 * progress * pulse

        # The glow grows brighter and wider with the power.
        for i in range(5):
            var glow := radius + 6.0 + i * 9.0 * (0.4 + progress)
            draw_circle(at, glow, Color(_FIST, 0.05 * progress * (5 - i)))

        _draw_sparks(at, radius, progress)
        draw_circle(at, radius, Color(_FIST, 0.15 + 0.45 * progress))

    draw_arc(at, radius, 0, TAU, 40, _BACKING, 9.0, true)
    draw_arc(at, radius, 0, TAU, 40, _RING, 5.0, true)
    if progress > 0.0:
        var outer := radius + 12.0
        var width := 6.0 + 8.0 * progress
        draw_arc(at, outer, 0, TAU, 48, _BACKING, width + 4.0, true)
        draw_arc(at, outer, -PI / 2, -PI / 2 + TAU * progress, 48, _FIST, width, true)

    draw_gull(self, at + Vector2(0, -3), 2.4, Color.WHITE, _BACKING)


## Draw sparks which stream from all around into the fist; the more power,
## the more sparks and the faster they come.
func _draw_sparks(at: Vector2, radius: float, progress: float) -> void:
    var count := 6 + int(10 * progress)
    var speed := 0.8 + 1.6 * progress
    for i in range(count):
        var phase := fmod(_now() * speed + float(i) / count, 1.0)
        var angle := i * 2.39996 + _now() * 0.7
        var distance := lerpf(radius + 135.0, radius + 6.0, phase)
        var spark := at + Vector2.from_angle(angle) * distance
        draw_circle(spark, 3.5 + 5.0 * phase, Color(_FIST, (0.3 + 0.7 * phase) * progress))


## Draw a seagull as two soft wings, like a child draws it from afar.
static func draw_gull(
    canvas: CanvasItem, at: Vector2, scale: float, color: Color, outline: Color
) -> void:
    for side in [-1.0, 1.0]:
        var center := at + Vector2(side * 9.0, 4.0) * scale
        if outline.a > 0.0:
            canvas.draw_arc(
                center, 9.0 * scale, PI * 1.05, PI * 1.95, 16, outline, 7.5 * scale, true
            )
        canvas.draw_arc(center, 9.0 * scale, PI * 1.05, PI * 1.95, 16, color, 4.0 * scale, true)
