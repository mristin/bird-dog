extends Control

## Check the recognition of the bird-dog poses in a real set-up, tune it, and
## record the detections for the tests (see DESIGN.md, "The pose test").
##
## Start with:
##
##   $GODOT --path . scenes/tests/pose_test/pose_test.tscn -- [--record[=DIR]]
##       [--no-thumbnails] [--distance=2.0] [--note=TEXT]
##
## (or pose_test_two_players.tscn for two players). We record only when asked
## to on the command line, since the thumbnails show the players.
##
## Keys: 1 or 2 players, Up/Down move the head line, P starts or stops the
## protocol, S saves the settings, Esc quits.

const _SCREEN := Vector2(1920, 1080)

## The camera picture is 4:3; we center it and keep the sides for the texts.
const _CAMERA_RECT := Rect2(240, 0, 1440, 1080)

const _DEFAULT_RECORD_DIR := "user://pose_recordings"

## The wheel turns this far (in radians) at full steering.
const _WHEEL_ANGLE := 2.2

const _COLOR_RAISED := Color(0.3, 0.95, 0.4)
const _COLOR_DOWN := Color(0.75, 0.75, 0.75, 0.8)
const _COLOR_HEAD := Color(1.0, 0.85, 0.3)
const _COLOR_LINE := Color(1.0, 0.85, 0.3, 0.7)

## The steps of the recording protocol: the label, the instruction and the duration.
const _PROTOCOL := [
    ["rest", "Kneel on all fours and rest.", 10.0],
    ["left_reps", "LEFT arm forward, hold 2 s, rest. Repeat 5 times.", 30.0],
    ["right_reps", "RIGHT arm forward, hold 2 s, rest. Repeat 5 times.", 30.0],
    ["alternate", "Alternate: left, right, left, right, holding each for 2 s.", 30.0],
    [
        "height_left",
        "LEFT arm: raise it slowly from the nose to high above the head, and back.",
        20.0
    ],
    [
        "height_right",
        "RIGHT arm: raise it slowly from the nose to high above the head, and back.",
        20.0
    ],
    ["kneel_up", "Kneel up and wave with both hands.", 15.0],
    ["distance", "Crawl closer to the camera, then farther away.", 20.0],
]

## The number of players at the start (1 or 2); the keys 1 and 2 change it.
@export_range(1, 2) var players := 1
var _wheel_angles := [0.0, 0.0]

## The smoothed center of each player's wheel, so that it glides after the head.
var _wheel_centers: Array = [null, null]
var _wheel_smoothers: Array[PointSmoother] = [PointSmoother.new(), PointSmoother.new()]

var _protocol_step := -1
var _protocol_left := 0.0

var _record_dir := ""
var _metadata := {}

@onready var _vision: Node = get_node("/root/Vision").hands
@onready var _pose: Node = get_node("/root/Vision").poses
@onready var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
    var record := false
    for arg in OS.get_cmdline_user_args():
        if arg == "--record":
            record = true
            _record_dir = _DEFAULT_RECORD_DIR
        elif arg.begins_with("--record="):
            record = true
            _record_dir = arg.get_slice("=", 1)
        elif arg.begins_with("--distance="):
            _metadata["distance_m"] = arg.get_slice("=", 1)
        elif arg.begins_with("--note="):
            _metadata["note"] = arg.get_slice("=", 1)
        elif arg == "--no-thumbnails":
            _pose.ThumbnailSeconds = INF

    _pose.SetPlayerCount(players)

    # NOTE (mristin):
    # We record only when explicitly asked to on the command line, since the
    # thumbnails show the players.
    if record:
        _pose.StartRecording(_record_dir, _metadata)


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return

    match event.keycode:
        KEY_ESCAPE:
            get_tree().quit()
        KEY_1:
            _pose.SetPlayerCount(1)
        KEY_2:
            _pose.SetPlayerCount(2)
        KEY_UP:
            _pose.SetHeadLineAboveTop(_pose.GetHeadLineAboveTop() + 0.05)
        KEY_DOWN:
            _pose.SetHeadLineAboveTop(_pose.GetHeadLineAboveTop() - 0.05)
        KEY_P:
            if _protocol_step < 0:
                _start_protocol_step(0)
            else:
                _stop_protocol()
        KEY_S:
            _pose.SaveConfig()


func _start_protocol_step(step: int) -> void:
    if step >= _PROTOCOL.size():
        _stop_protocol()
        return
    _protocol_step = step
    _protocol_left = _PROTOCOL[step][2]
    _pose.SetLabel(_PROTOCOL[step][0])


func _stop_protocol() -> void:
    _protocol_step = -1
    _pose.SetLabel("")


func _process(delta: float) -> void:
    if _protocol_step >= 0:
        _protocol_left -= delta
        if _protocol_left <= 0.0:
            _start_protocol_step(_protocol_step + 1)

    var players: Array = _pose.GetPlayers()
    for i in range(_wheel_angles.size()):
        if i < players.size() and players[i]["has_head"]:
            var target := _rect_to_screen(players[i]["head"]).get_center()
            if _wheel_centers[i] == null:
                _wheel_centers[i] = target
            else:
                _wheel_centers[i] = _wheel_smoothers[i].update([target] as Array[Vector2], delta)[0]
        var target := 0.0
        if i < players.size():
            target = float(players[i]["steer"]) * _WHEEL_ANGLE
        # NOTE (mristin):
        # The wheel follows the hand quickly, but rolls back to the middle slowly.
        var rate := 16.0 if absf(target) >= absf(_wheel_angles[i]) else 6.0
        _wheel_angles[i] = lerpf(_wheel_angles[i], target, 1.0 - exp(-delta * rate))

    queue_redraw()


func _to_screen(point: Vector2) -> Vector2:
    return _CAMERA_RECT.position + point * _CAMERA_RECT.size


func _rect_to_screen(rect: Rect2) -> Rect2:
    return Rect2(_to_screen(rect.position), rect.size * _CAMERA_RECT.size)


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, _SCREEN), Color(0.05, 0.12, 0.2))
    _draw_camera()

    var players: Array = _pose.GetPlayers()
    var count: int = _pose.GetPlayerCount()
    if count == 2:
        var x := _CAMERA_RECT.position.x + _CAMERA_RECT.size.x * 0.5
        draw_dashed_line(Vector2(x, 0), Vector2(x, _SCREEN.y), Color(1, 1, 1, 0.6), 4.0, 16.0)

    for player in players:
        _draw_player(player, count)

    _draw_texts(players, count)


func _draw_camera() -> void:
    var texture: Texture2D = _vision.GetCameraTexture()
    if texture == null:
        return
    var size := texture.get_size()
    if size.x <= 0 or size.y <= 0:
        return

    if _vision.Mirror:
        draw_set_transform(Vector2(_SCREEN.x, 0), 0, Vector2(-1, 1))
    draw_texture_rect(
        texture, Rect2(Vector2(_SCREEN.x - _CAMERA_RECT.end.x, 0), _CAMERA_RECT.size), false
    )
    draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_player(player: Dictionary, count: int) -> void:
    var index: int = player["player"]

    for hand in player["hands"]:
        var rect := _rect_to_screen(hand["rect"])
        var color := _COLOR_RAISED if hand["raised"] else _COLOR_DOWN
        draw_rect(rect, color, false, 2.0)
        HandMarker.draw(self, rect.get_center(), hand["raised"])

    if not player["has_head"]:
        return

    var head := _rect_to_screen(player["head"])
    draw_rect(head, _COLOR_HEAD, false, 3.0)

    var line_y := _to_screen(Vector2(0, player["head_line_y"])).y
    var reach := head.size.y * 4.0
    var center := head.get_center()
    draw_dashed_line(
        Vector2(center.x - reach, line_y), Vector2(center.x + reach, line_y), _COLOR_LINE, 3.0, 12.0
    )

    var wheel_center: Vector2 = center if _wheel_centers[index] == null else _wheel_centers[index]
    ShipWheel.draw(self, wheel_center, head.size.y * 1.4, _wheel_angles[index], 0.85)

    var label: String = str(player["pose"]).to_upper()
    var label_x := _CAMERA_RECT.position.x + 20.0
    if count == 2 and index == 1:
        label_x += _CAMERA_RECT.size.x * 0.5
    draw_string(_font, Vector2(label_x, 70), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color.WHITE)


func _draw_texts(players: Array, count: int) -> void:
    var lines: PackedStringArray = []
    lines.append("Vision: %s" % _vision.GetStatusName())
    lines.append(_vision.GetStatusMessage())
    lines.append("")
    lines.append("Players: %d" % count)
    lines.append("Head line: %+.2f h" % _pose.GetHeadLineAboveTop())
    lines.append("")
    for player in players:
        lines.append("Player %d" % (int(player["player"]) + 1))
        lines.append("  pose %s (raw %s)" % [player["pose"], player["raw_pose"]])
        lines.append("  steer %+.2f" % float(player["steer"]))
        lines.append("  distance %s" % player["distance"])
    lines.append("")
    lines.append("1/2  players")
    lines.append("Up/Down  head line")
    lines.append("P  protocol")
    lines.append("S  save settings")
    lines.append("Esc  quit")

    var y := 40.0
    for line in lines:
        draw_string(_font, Vector2(12, y), line, HORIZONTAL_ALIGNMENT_LEFT, 220, 18, Color.WHITE)
        y += 26.0

    if _pose.IsRecording():
        draw_circle(Vector2(_SCREEN.x - 200, 40), 12, Color(0.95, 0.15, 0.15))
        draw_string(_font, Vector2(_SCREEN.x - 180, 50), "REC", HORIZONTAL_ALIGNMENT_LEFT, -1, 28)

    for player in players:
        var hint := ""
        match player["distance"]:
            "too_far":
                hint = "Come closer!"
            "too_close":
                hint = "Move back!"
        if not player["has_head"]:
            hint = "Kneel in front of the camera"
        if hint != "":
            var x := _CAMERA_RECT.position.x + 20.0
            if count == 2 and int(player["player"]) == 1:
                x += _CAMERA_RECT.size.x * 0.5
            draw_string(
                _font, Vector2(x, 140), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, _COLOR_HEAD
            )

    if _protocol_step >= 0:
        var step: Array = _PROTOCOL[_protocol_step]
        var text := (
            "%d/%d  %s  (%d s)"
            % [_protocol_step + 1, _PROTOCOL.size(), step[1], ceili(_protocol_left)]
        )
        draw_rect(
            Rect2(_CAMERA_RECT.position.x, _SCREEN.y - 90, _CAMERA_RECT.size.x, 90),
            Color(0, 0, 0, 0.6)
        )
        draw_string(
            _font,
            Vector2(_CAMERA_RECT.position.x + 20, _SCREEN.y - 30),
            text,
            HORIZONTAL_ALIGNMENT_LEFT,
            _CAMERA_RECT.size.x - 40,
            40,
            Color.WHITE
        )
