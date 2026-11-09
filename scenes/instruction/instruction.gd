extends Node3D

## Show the players how to do the bird dog properly and how it steers the boat
## (see DESIGN.md, "The instruction").
##
## Part 1 shows the exercise with a 3D captain on the deck, part 2 how the arms
## turn the wheel and the boat.
##
## The test screens in `scenes/tests/` show the parts on their own (see
## [member first_part] and [member only_one_part]).
##
## Space skips; Esc quits.
##
## We do not skip on a fist, since the hands of a player on all fours are often
## recognized as fists.

const _SCREEN := Vector2(1920, 1080)

## The wheel turns this far (in radians) at full steering.
const _WHEEL_ANGLE := 2.2

## The arm on the left of the screen is the captain's right arm, since the
## camera looks at the captain from the front, like the webcam at the player.
const _SCREEN_LEFT_ARM := "r"
const _SCREEN_RIGHT_ARM := "l"

## Raised this high (in degrees), the hand shows above the head from the front.
const _RAISED := 125.0

const _COLOR_GOOD := Color(0.25, 0.8, 0.35)
const _COLOR_BAD := Color(0.9, 0.2, 0.15)
const _COLOR_INK := Color(0.12, 0.08, 0.05)
const _COLOR_PAPER := Color(0.96, 0.91, 0.78)
const _COLOR_SEA := Color(0.1, 0.36, 0.55)
const _COLOR_HIGHLIGHT := Color(1.0, 0.85, 0.3)

## The part to start with (1 or 2).
@export_range(1, 2) var first_part := 1

## Show only [member first_part], then offer to watch it again (for tests).
@export var only_one_part := false

## The scene to go to after the instruction; empty to offer to watch it again.
@export_file("*.tscn") var next_scene := ""

var _part := 1
var _skipped := false
var _finished := false

var _captain: Captain3D
var _camera: Camera3D
var _camera_pivot: Node3D
var _camera_tween: Tween = null
var _back_board: MeshInstance3D

var _overlay: Control
var _title: Label
var _caption: Label
var _hint: Label

## "good", "bad" or "" for the big tick or cross.
var _mark := ""

## The side of the arm to highlight in part 2 ("l", "r" or "").
var _highlight := ""

var _demo_visible := false
var _demo_steer := 0.0
var _demo_heading := 0.0
var _demo_position := Vector2.ZERO
var _demo_trail: Array[Vector2] = []
var _demo_trail_timer := 0.0
var _demo_wind_visible := false
var _demo_wind_to := PI

@onready var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
    _part = first_part

    _build_world()
    _build_ui()
    _run()


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    # NOTE (mristin):
    # While the question to quit is open, it takes the keys.
    if not get_tree().get_nodes_in_group(ConfirmDialog.GROUP).is_empty():
        return
    match event.keycode:
        KEY_ESCAPE:
            get_viewport().set_input_as_handled()
            ConfirmDialog.ask_to_quit(_overlay)
        KEY_SPACE:
            _on_skip()


func _on_skip() -> void:
    if _finished:
        get_tree().reload_current_scene()
    else:
        _skipped = true


# region The timeline


func _run() -> void:
    if only_one_part:
        match first_part:
            1:
                await _part_1()
            2:
                await _part_2()
        _caption.text = tr("Space: watch it again   Esc: quit")
        _mark = ""
        _finished = true
        return

    if _part <= 1:
        await _part_1()
    if _part <= 2 and not _skipped:
        await _part_2()
    _finish()


## Wait, but stop waiting as soon as the player skips.
func _wait(seconds: float) -> void:
    var elapsed := 0.0
    while elapsed < seconds and not _skipped:
        await get_tree().process_frame
        elapsed += get_process_delta_time()


## Show a caption (already translated) and wait long enough to read it.
func _say(text: String, seconds: float, mark := "") -> void:
    _caption.text = text
    _mark = mark
    await _wait(seconds)


func _part_1() -> void:
    _part = 1
    _title.text = tr("1/2  The bird dog, done right")
    _captain.set_pose(BirdDogPoses.standing())
    _orbit_to(140.0, 1.0, 2.6, 0.0)

    await _say(tr("Ahoy, captain! Let's learn the bird dog."), 3.0)
    _captain.pose_to(BirdDogPoses.kneeling(), 1.2)
    await _wait(1.3)
    _captain.pose_to(BirdDogPoses.all_fours(), 1.2)
    _orbit_to(90.0, 0.8, 2.3, 2.5)
    await _say(tr("Get on all fours: hands under the shoulders, knees under the hips."), 4.5)

    _back_board.visible = true
    await _say(tr("Keep your back flat, like a table."), 3.5, "good")
    _back_board.visible = false
    await _say(tr("Look at the floor, a little ahead of your hands."), 3.5)

    _orbit_to(135.0, 0.8, 2.3, 2.0)
    _captain.pose_to(BirdDogPoses.bird_dog("r"), 1.6)
    await _say(tr("Stretch one arm forward and the opposite leg back."), 4.0)
    await _say(tr("Hold still: belly tight, hips level."), 2.5)
    _captain.pose_to(BirdDogPoses.all_fours(), 1.3)
    await _say(tr("Then slowly back..."), 1.6)

    _orbit_to(45.0, 0.8, 2.3, 2.5)
    _captain.pose_to(BirdDogPoses.bird_dog("l"), 1.6)
    await _say(tr("...and the other arm with the other leg."), 4.0)
    _captain.pose_to(BirdDogPoses.all_fours(), 1.3)
    await _wait(1.5)

    await _mistake(
        BirdDogPoses.all_fours(0.0, 90.0, 1.0, 0.0, BirdDogPoses.GOOD_HEAD, 1.0),
        tr("Don't let your back sag..."),
        tr("...keep it flat."),
        90.0
    )
    await _mistake(
        BirdDogPoses.all_fours(0.0, 90.0, 1.0, 0.0, -5.0),
        tr("Don't throw your head up..."),
        tr("...look at the floor."),
        90.0
    )
    await _mistake(
        BirdDogPoses.all_fours(0.0, 90.0, 1.0, 0.0, BirdDogPoses.GOOD_HEAD, 0.0, 18.0),
        tr("Don't let your hip roll open..."),
        tr("...keep your hips level."),
        0.0
    )
    await _mistake(
        BirdDogPoses.all_fours(0.0, 90.0, 1.0, 0.0, BirdDogPoses.GOOD_HEAD, 0.0, 0.0, 1.0),
        tr("Don't kick your leg up too high..."),
        tr("...level with your back is enough."),
        90.0
    )
    await _jerky_mistake()
    _mark = ""


## Show a mistake with a red cross, then the right way with a green tick.
func _mistake(wrong: Dictionary, wrong_text: String, right_text: String, view: float) -> void:
    if _skipped:
        return
    _orbit_to(view, 0.8, 2.3, 1.2)
    _captain.pose_to(wrong, 1.2)
    await _say(wrong_text, 3.0, "bad")
    _captain.pose_to(BirdDogPoses.bird_dog("r"), 1.2)
    await _say(right_text, 2.6, "good")
    _captain.pose_to(BirdDogPoses.all_fours(), 1.0)
    await _wait(1.0)


func _jerky_mistake() -> void:
    if _skipped:
        return
    _orbit_to(120.0, 0.8, 2.3, 1.2)
    _caption.text = tr("Not fast and jerky...")
    _mark = "bad"
    for i in range(6):
        var side := "r" if i % 2 == 0 else "l"
        _captain.pose_to(BirdDogPoses.bird_dog(side), 0.18, Tween.TRANS_LINEAR)
        await _wait(0.22)
        _captain.pose_to(BirdDogPoses.all_fours(), 0.15, Tween.TRANS_LINEAR)
        await _wait(0.18)
    _caption.text = tr("...but slow and calm.")
    _mark = "good"
    for side in ["r", "l"]:
        _captain.pose_to(BirdDogPoses.bird_dog(side), 1.5)
        await _wait(3.0)
        _captain.pose_to(BirdDogPoses.all_fours(), 1.3)
        await _wait(1.4)


func _part_2() -> void:
    _part = 2
    _title.text = tr("2/2  How you steer the boat")
    _captain.set_pose(BirdDogPoses.all_fours())
    _orbit_to(180.0, 0.9, 2.6, 0.0)
    _camera.h_offset = 0.6
    _demo_visible = true
    _demo_heading = 0.0
    _demo_trail.clear()

    await _say(tr("Look: this is you, as the camera sees you."), 3.0)

    _highlight = _SCREEN_LEFT_ARM
    _captain.pose_to(BirdDogPoses.bird_dog(_SCREEN_LEFT_ARM, 1.0, _RAISED), 1.4)
    _steer_to(0.8, 1.4)
    await _say(tr("The arm on the left lifts the wheel on the left: the boat turns right."), 4.5)
    _captain.pose_to(BirdDogPoses.all_fours(), 1.2)
    _steer_to(0.0, 1.0)
    await _wait(1.3)

    _highlight = _SCREEN_RIGHT_ARM
    _captain.pose_to(BirdDogPoses.bird_dog(_SCREEN_RIGHT_ARM, 1.0, _RAISED), 1.4)
    _steer_to(-0.8, 1.4)
    await _say(tr("The arm on the right lifts the wheel on the right: the boat turns left."), 4.5)
    _captain.pose_to(BirdDogPoses.all_fours(), 1.2)
    _steer_to(0.0, 1.0)
    await _wait(1.3)

    _highlight = _SCREEN_LEFT_ARM
    _caption.text = tr("The higher the arm, the harder the turn.")
    _captain.pose_to(BirdDogPoses.bird_dog(_SCREEN_LEFT_ARM, 1.0, 100.0), 1.2)
    await _wait(1.3)
    if not _skipped:
        var sweep := create_tween()
        sweep.tween_method(_raise_left_arm, 100.0, 150.0, 3.5).set_trans(Tween.TRANS_SINE)
        await _wait(4.0)
        sweep.kill()

    _highlight = ""
    _captain.pose_to(BirdDogPoses.all_fours(), 1.2)
    _steer_to(0.0, 1.2)
    await _say(tr("Hands down, and the boat keeps its course."), 3.5)

    _demo_wind_visible = true
    _demo_wind_to = _demo_heading + PI
    await _say(tr("The wind moves the boat. Against the wind, it is slow..."), 4.0)
    _caption.text = tr("...so zig-zag: left, right, left, right!")
    for i in range(4):
        var side := _SCREEN_LEFT_ARM if i % 2 == 0 else _SCREEN_RIGHT_ARM
        _highlight = side
        _captain.pose_to(BirdDogPoses.bird_dog(side, 1.0, _RAISED), 1.0)
        _steer_to(0.9 if side == _SCREEN_LEFT_ARM else -0.9, 0.8)
        await _wait(1.25 if i == 0 else 2.5)
        _captain.pose_to(BirdDogPoses.all_fours(), 0.8)
        _steer_to(0.0, 0.6)
        await _wait(0.8)

    _highlight = ""
    _captain.pose_to(BirdDogPoses.both_arms_up(), 1.2)
    await _say(tr("Both arms up at once does nothing."), 3.0, "bad")
    _captain.pose_to(BirdDogPoses.all_fours(), 1.0)
    await _say(tr("One arm at a time!"), 2.5, "good")
    _mark = ""


func _raise_left_arm(angle: float) -> void:
    _captain.set_pose(BirdDogPoses.bird_dog(_SCREEN_LEFT_ARM, 1.0, angle))
    _demo_steer = clampf((angle - 95.0) / 55.0, 0.0, 1.0)


func _steer_to(value: float, seconds: float) -> void:
    create_tween().tween_property(self, "_demo_steer", value, seconds).set_trans(Tween.TRANS_SINE)


## Go on to the next scene, or offer to watch the instruction again.
func _finish() -> void:
    if next_scene != "":
        get_tree().change_scene_to_file(next_scene)
        return
    _caption.text = tr("Space: watch it again   Esc: quit")
    _mark = ""
    _finished = true


# endregion

# region The world


func _process(delta: float) -> void:
    _camera.look_at(_camera_pivot.global_position)

    if _demo_visible:
        _update_demo(delta)

    _overlay.queue_redraw()


func _orbit_to(angle: float, height: float, radius: float, seconds: float) -> void:
    if _camera_tween != null and _camera_tween.is_valid():
        _camera_tween.kill()
    var target := Vector3(0, height, radius)
    if seconds <= 0.0:
        _camera_pivot.rotation_degrees.y = angle
        _camera.position = target
        return
    _camera_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
    _camera_tween.tween_property(_camera_pivot, "rotation_degrees:y", angle, seconds)
    _camera_tween.tween_property(_camera, "position", target, seconds)


func _build_world() -> void:
    DeckWorld.build(self)

    _camera_pivot = Node3D.new()
    _camera_pivot.position = Vector3(0, 0.45, 0)
    add_child(_camera_pivot)
    _camera = Camera3D.new()
    _camera.fov = 50.0
    _camera_pivot.add_child(_camera)
    _camera.make_current()
    _orbit_to(140.0, 1.0, 2.6, 0.0)

    # NOTE (mristin):
    # The instruction shows the captain of the first player, in their looks.
    _captain = Captain3D.new()
    _captain.apply_looks(get_node("/root/Crew").captains[0])
    add_child(_captain)

    # A see-through board on the back shows how flat it should be. It hangs on
    # the spine, whose +Y runs along the back and +Z points up on all fours.
    var board_mesh := BoxMesh.new()
    board_mesh.size = Vector3(0.5, 0.62, 0.02)
    var board_material := StandardMaterial3D.new()
    board_material.albedo_color = Color(_COLOR_GOOD, 0.45)
    board_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _back_board = MeshInstance3D.new()
    _back_board.mesh = board_mesh
    _back_board.material_override = board_material
    _back_board.position = Vector3(0, 0.26, 0.19)
    _back_board.visible = false
    _captain.joints["spine"].add_child(_back_board)


# endregion

# region The overlay


func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    _overlay = Control.new()
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.draw.connect(_draw_overlay)
    layer.add_child(_overlay)

    _title = _label(30, Vector2(30, 24), Vector2(900, 50), HORIZONTAL_ALIGNMENT_LEFT)
    _caption = _label(46, Vector2(60, 900), Vector2(1800, 140), HORIZONTAL_ALIGNMENT_CENTER)
    _caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _hint = _label(24, Vector2(1400, 1030), Vector2(500, 40), HORIZONTAL_ALIGNMENT_RIGHT)
    _hint.text = tr("Space: skip   Esc: quit")
    for label in [_title, _caption, _hint]:
        layer.add_child(label)


func _label(size: int, at_position: Vector2, extent: Vector2, alignment: int) -> Label:
    var label := Label.new()
    label.position = at_position
    label.size = extent
    label.horizontal_alignment = alignment
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color.WHITE)
    label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    label.add_theme_constant_override("outline_size", maxi(6, int(size / 5.0)))
    return label


func _draw_overlay() -> void:
    if _demo_visible:
        _draw_demo(Rect2(1000, 110, 880, 760))

    if _highlight != "" and _part == 2:
        var elbow: Node3D = _captain.joints["elbow_" + _highlight]
        var hand := elbow.global_transform * Vector3(0, -Captain3D.FOREARM - 0.035, 0)
        if not _camera.is_position_behind(hand):
            var at := _camera.unproject_position(hand)
            var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() / 150.0)
            _overlay.draw_arc(at, 42.0 * pulse, 0, TAU, 48, _COLOR_HIGHLIGHT, 6.0, true)

    if _caption.text != "":
        _overlay.draw_rect(Rect2(0, 890, _SCREEN.x, 160), Color(0, 0, 0, 0.35))

    if _mark != "":
        _draw_mark(Vector2(1780 if not _demo_visible else 900, 140), 70.0, _mark == "good")


func _draw_mark(center: Vector2, radius: float, good: bool) -> void:
    var color := _COLOR_GOOD if good else _COLOR_BAD
    _overlay.draw_circle(center, radius, Color.WHITE)
    _overlay.draw_arc(center, radius, 0, TAU, 64, color, 8.0, true)
    var width := radius * 0.2
    if good:
        (
            _overlay
            . draw_polyline(
                PackedVector2Array(
                    [
                        center + Vector2(-0.45, 0.02) * radius,
                        center + Vector2(-0.12, 0.35) * radius,
                        center + Vector2(0.48, -0.35) * radius,
                    ]
                ),
                color,
                width,
                true
            )
        )
    else:
        var d := radius * 0.4
        _overlay.draw_line(center + Vector2(-d, -d), center + Vector2(d, d), color, width, true)
        _overlay.draw_line(center + Vector2(d, -d), center + Vector2(-d, d), color, width, true)


## The speed of a boat by the angle off the wind, as in DESIGN.md.
static func _speed_factor(heading: float, wind_to: float) -> float:
    var off := absf(wrapf(heading - (wind_to + PI), -PI, PI))
    if off < deg_to_rad(35.0):
        return 0.15
    if off < deg_to_rad(70.0):
        return 0.5
    if off < deg_to_rad(110.0):
        return 0.8
    if off < deg_to_rad(150.0):
        return 1.0
    return 0.85


func _update_demo(delta: float) -> void:
    _demo_heading += _demo_steer * deg_to_rad(40.0) * delta
    var speed := 70.0
    if _demo_wind_visible:
        speed *= _speed_factor(_demo_heading, _demo_wind_to)
    _demo_position += Vector2.UP.rotated(_demo_heading) * speed * delta

    _demo_trail_timer += delta
    if _demo_trail_timer >= 0.1:
        _demo_trail_timer = 0.0
        _demo_trail.append(_demo_position)
        if _demo_trail.size() > 300:
            _demo_trail.pop_front()


func _draw_demo(rect: Rect2) -> void:
    _overlay.draw_rect(rect.grow(10), Color(0.35, 0.22, 0.1))
    _overlay.draw_rect(rect, _COLOR_SEA)

    var center := rect.get_center()

    # The waves stay in place on the sea, so they show how the boat moves.
    var spacing := 90.0
    var offset := Vector2(fposmod(-_demo_position.x, spacing), fposmod(-_demo_position.y, spacing))
    var y := rect.position.y + offset.y - spacing
    while y < rect.end.y:
        var x := rect.position.x + offset.x - spacing
        while x < rect.end.x:
            var at := Vector2(x, y)
            if rect.grow(-20).has_point(at):
                _overlay.draw_arc(at, 14.0, PI * 1.15, PI * 1.85, 8, Color(1, 1, 1, 0.25), 3.0)
            x += spacing
        y += spacing

    var trail := PackedVector2Array()
    for point in _demo_trail:
        var at := center + point - _demo_position
        if rect.has_point(at):
            trail.append(at)
    if trail.size() >= 2:
        _overlay.draw_polyline(trail, Color(1, 1, 1, 0.55), 5.0, true)

    _draw_boat(center, _demo_heading)

    ShipWheel.draw(
        _overlay, rect.position + Vector2(130, rect.size.y - 130), 80.0, _demo_steer * _WHEEL_ANGLE
    )

    if _demo_wind_visible:
        _draw_wind(rect.position + Vector2(rect.size.x - 100, 100), _demo_wind_to)


func _draw_boat(center: Vector2, heading: float) -> void:
    var hull := PackedVector2Array(
        [
            Vector2(0, -55),
            Vector2(18, -28),
            Vector2(21, 18),
            Vector2(13, 46),
            Vector2(-13, 46),
            Vector2(-21, 18),
            Vector2(-18, -28),
        ]
    )
    var deck := PackedVector2Array()
    var outline := PackedVector2Array()
    for point in hull:
        outline.append(center + point.rotated(heading))
        deck.append(center + (point * 0.8 + Vector2(0, 2)).rotated(heading))
    _overlay.draw_colored_polygon(outline, Color(0.35, 0.2, 0.1))
    _overlay.draw_colored_polygon(deck, Color(0.66, 0.46, 0.26))

    var sail_a := center + Vector2(-30, -4).rotated(heading)
    var sail_b := center + Vector2(30, -4).rotated(heading)
    _overlay.draw_line(sail_a, sail_b, _COLOR_PAPER, 9.0, true)
    _overlay.draw_circle(center + Vector2(0, -4).rotated(heading), 6.0, Color(0.62, 0.11, 0.11))


func _draw_wind(center: Vector2, wind_to: float) -> void:
    _overlay.draw_circle(center, 70.0, Color(_COLOR_PAPER, 0.92))
    _overlay.draw_arc(center, 70.0, 0, TAU, 48, _COLOR_INK, 3.0, true)
    var direction := Vector2.UP.rotated(wind_to)
    var tip := center + direction * 52.0
    _overlay.draw_line(center - direction * 50.0, tip - direction * 10.0, _COLOR_INK, 10.0, true)
    (
        _overlay
        . draw_colored_polygon(
            PackedVector2Array(
                [
                    tip,
                    tip - direction * 26.0 + direction.orthogonal() * 18.0,
                    tip - direction * 26.0 - direction.orthogonal() * 18.0,
                ]
            ),
            _COLOR_INK
        )
    )
    _overlay.draw_string(
        _font,
        center + Vector2(-60, 100),
        tr("Wind"),
        HORIZONTAL_ALIGNMENT_CENTER,
        120,
        28,
        Color.WHITE
    )

# endregion
