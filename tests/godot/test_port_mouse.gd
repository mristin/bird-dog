extends SceneTree
## Click the buttons of the start port with the mouse, with one and with two
## players: the cards of the ports live in the SubViewport of each player, so
## the mouse has to reach them through the SeaView, and the cursor (with the
## camera picture behind it) has to fill the view.

const MISSION := preload("res://scenes/mission/mission.tscn")

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _frames(count: int) -> void:
    for i in range(count):
        await process_frame


func _click(at: Vector2) -> void:
    var motion := InputEventMouseMotion.new()
    motion.position = at
    motion.global_position = at
    root.push_input(motion, true)
    var press := InputEventMouseButton.new()
    press.button_index = MOUSE_BUTTON_LEFT
    press.pressed = true
    press.position = at
    press.global_position = at
    root.push_input(press, true)
    var release := press.duplicate()
    release.pressed = false
    root.push_input(release, true)


func _find_button(node: Node, text: String) -> HandButton:
    if node is HandButton and node.text == text:
        return node
    for child in node.get_children():
        var found := _find_button(child, text)
        if found != null:
            return found
    return null


func _play(players: int) -> void:
    var scene: Node = MISSION.instantiate()
    scene.mission_id = "bell_of_grebastica"
    scene.next_scene = ""
    scene.record_result = false
    scene.players = players
    root.add_child(scene)
    await _frames(2)
    scene._on_shared_action("done")
    await _frames(3)
    for i in range(players):
        _check(scene._busy[i], "%d players: crew %d is in the start port" % [players, i])
        var card: StoryCard = scene._cards[i]
        var cursor: HandCursor = card.get_meta("cursor")
        _check(
            cursor.size == scene._views[i].size,
            "%d players: the cursor %d (and the camera behind it) fills the view" % [players, i]
        )
        var button := _find_button(card, tr("Set sail!"))
        _check(button != null, "%d players: the card %d has Set sail!" % [players, i])
        if button == null:
            continue
        # The button's rectangle is in the viewport of the player; the screen
        # adds the position of the view.
        var at: Vector2 = scene._views[i].position + button.get_global_rect().get_center()
        _click(at)
        await _frames(3)
        _check(not scene._busy[i], "%d players: the mouse sets crew %d sailing" % [players, i])
    scene.queue_free()
    await _frames(2)


func _run() -> void:
    await _play(1)
    await _play(2)
    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)
