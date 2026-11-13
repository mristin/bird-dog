extends RefCounted
## Check the contracts of the game while the end-to-end tests play it (design
## by contract, in the tests only, so that the game never pays for them):
## what must hold on every screen and on every frame of a mission, whatever
## the players do.
##
## On every menu screen and on every dialogue over a mission (the scenes of
## the ports, the briefing, the meeting at sea, the question whether to leave,
## the end of the mission):
##
## * every button and every label stays inside the screen (or its half), and
##   no two buttons overlap, nor a label and a button;
## * the label of every button fits it at a readable size (see
##   story_layout.gd), and the lines of a button fit its height;
## * the scenes of the ports keep the rules of story_layout.gd: the panels,
##   the buttons and the cards stay inside the card and clear of the webcam,
##   do not overlap, and their texts fit.
##
## In a mission:
##
## * the boats stay on the chart and never on the land;
## * the days never run backwards, the food and the water stay within the
##   hold, the hull's damage within [0, 100], and nobody has fewer than no
##   ducats;
## * a scene shows in the half of a player exactly while the boat of the
##   player is in a port (busy), with its cursor;
## * the HUD of a player hides under the scenes of the ports, the briefing
##   and the meeting at sea, and its panels stay inside the view without
##   overlapping; the toasts fit the view, and the tips their panel;
## * the chart, the minimaps and the arrows point where the step of the
##   mission says;
## * the mission is done exactly when the screen at its end shows, which gives
##   one to three stars, and the text of the end stays above its button.
##
## Each problem is reported once, with its first example and how often it
## happened.
##
## Not a test itself (its name does not start with test_), it is preloaded by
## the tests.

const StoryLayout := preload("res://tests/godot/story_layout.gd")

## The screen, in pixels.
const SCREEN := Rect2(0, 0, 1920, 1080)

## How far an element may stick out or overlap, in pixels (the borders).
const TOLERANCE := 1.0

## The panels of the HUD which draw over the whole view on purpose (the shade
## of the clouds, the arrow to the target, the toasts).
const OVERLAYS := ["CloudShade", "TargetArrow", "Toast"]

## The problems found, by their key, each with its first example and how
## often it happened.
var _found := {}
var _checks := 0

## What the last check of each mission saw, by the id of the mission screen.
var _last := {}

## The scenes of the cards checked already, so that each is checked once.
var _cards_checked := {}


## The problems found, one message for each.
func violations() -> Array[String]:
    var result: Array[String] = []
    for key in _found:
        var found: Dictionary = _found[key]
        result.append("%s (%d times), e.g., %s" % [key, found["count"], found["example"]])
    return result


## How many times the contracts were checked.
func checks() -> int:
    return _checks


func _report(key: String, example: String) -> void:
    if not _found.has(key):
        _found[key] = {"count": 0, "example": example}
        print("CONTRACT ", key, ": ", example)
    _found[key]["count"] += 1


static func _locale() -> String:
    return TranslationServer.get_locale()


## The name of a node for the messages: its class, and its text if any.
static func describe(node: Node) -> String:
    var script := node.get_script() as Script
    var kind := node.get_class()
    if script != null:
        kind = (
            script.get_global_name()
            if script.get_global_name() != ""
            else script.resource_path.get_file().get_basename()
        )
    if node is HandButton:
        var button := node as HandButton
        var said := button.text if button.text != "" else button.title
        if said != "":
            return "%s '%s'" % [kind, said.left(40)]
    if node is Label and (node as Label).text != "":
        return "%s '%s'" % [kind, (node as Label).text.left(40)]
    return kind


## The buttons of the [param root] which a player can press now (visible, not
## quiet behind a dialog), in the viewport of the root.
static func active_buttons(root: Node) -> Array[HandButton]:
    var result: Array[HandButton] = []
    for node in root.find_children("*", "HandButton", true, false):
        var button := node as HandButton
        if button.is_visible_in_tree() and not button.is_blocked():
            if button.get_viewport() == root.get_viewport():
                result.append(button)
    return result


## Check a menu screen, or a dialogue over a mission ([param root]), whose
## elements must stay inside [param bounds] (the screen, or a half of it).
func check_screen(root: Node, tag: String, bounds := SCREEN) -> void:
    _checks += 1
    var where := "%s (%s)" % [tag, _locale()]
    var buttons := active_buttons(root)
    var labels: Array[Label] = []
    for node in root.find_children("*", "Label", true, false):
        var label := node as Label
        if label.is_visible_in_tree() and label.text.strip_edges() != "":
            labels.append(label)
    var inside := bounds.grow(TOLERANCE)
    for button in buttons:
        var rect := button.get_global_rect()
        if not inside.encloses(rect):
            _report(
                "%s: %s sticks out of the screen" % [tag, describe(button)],
                "%s: %s, the screen %s" % [where, rect, bounds]
            )
        for problem in button_problems(button, where):
            _report("%s: %s does not fit" % [tag, describe(button)], problem)
    for label in labels:
        var rect := label.get_global_rect()
        if not inside.encloses(rect):
            _report(
                "%s: %s sticks out of the screen" % [tag, describe(label)],
                "%s: %s, the screen %s" % [where, rect, bounds]
            )
        for button in buttons:
            if _overlap(rect, button.get_global_rect()):
                _report(
                    "%s: %s overlaps %s" % [tag, describe(label), describe(button)],
                    "%s: %s and %s" % [where, rect, button.get_global_rect()]
                )
    for i in range(buttons.size()):
        for j in range(i + 1, buttons.size()):
            var a := buttons[i].get_global_rect()
            var b := buttons[j].get_global_rect()
            if _overlap(a, b):
                var names := [describe(buttons[i]), describe(buttons[j])]
                names.sort()
                _report(
                    "%s: %s overlaps %s" % [tag, names[0], names[1]],
                    "%s: %s and %s" % [where, a, b]
                )


static func _overlap(a: Rect2, b: Rect2) -> bool:
    return a.grow(-TOLERANCE).intersects(b.grow(-TOLERANCE))


## The problems of the lines of a plain button (as [method HandButton._draw]
## lays them out): every line at a readable size, and all of them within the
## height of the button. The cards (e.g., of the missions or the boosters)
## lay out their own texts; their tests check them.
static func button_problems(button: HandButton, where: String) -> Array[String]:
    var found: Array[String] = []
    if button.get_script() != HandButton or button.arrow != 0 or button.swatch.a > 0.0:
        return found
    var font := ThemeDB.fallback_font
    var top := 24.0 + button.icon_size.y if button.icon != null else 0.0
    var lines := []
    if button.title != "":
        var fitted := HandButton.fit_size(font, button.title, button.title_size, button.size.x - 16)
        lines.append([button.title, fitted, button.title_size])
    if button.text != "":
        var room := (
            button.size.y - top - 12.0 - (button.title_size * 1.15 if button.title != "" else 0.0)
        )
        for line in HandButton.label_lines(
            font, button.text, button.text_size, button.size.x - 16.0, room
        ):
            lines.append([line[0], line[1], button.text_size])
    var total := top
    for line in lines:
        total += line[1] * 1.15
        if line[1] < mini(line[2], StoryLayout.READABLE):
            found.append("%s: '%s' shrinks to %d" % [where, line[0], line[1]])
    if total > button.size.y + TOLERANCE:
        found.append(
            "%s: the lines need %d pixels, the button is %d high" % [where, total, button.size.y]
        )
    return found


## Check a card of a port, of a half or of the whole screen, once per scene it
## shows (the rows of its buttons lay out in the frame after it was shown, so
## the card is checked on the second look).
func check_card(card: StoryCard, run: MissionRun, tag: String) -> void:
    var scene := card.scene()
    var key := shown_key(card)
    var seen: int = _cards_checked.get(key, 0)
    _cards_checked[key] = seen + 1
    if seen != 1:
        return
    _checks += 1
    var said := ""
    if scene["kind"] == "lineup":
        said = "the line-up"
    elif not scene["lines"].is_empty():
        said = "'%s'" % run.say(scene["lines"][0]).left(40)
    var where := "%s, %s (%s)" % [tag, said, _locale()]
    for problem in StoryLayout.problems(card, run, where):
        # NOTE (mristin):
        # The key leaves out what is said, so that a problem is reported once
        # for all the scenes.
        _report("%s: %s" % [tag, problem.trim_prefix(where + ": ")], problem)


## What tells the scenes of the card apart: every scene shown builds the
## rows of its buttons anew.
static func shown_key(card: StoryCard) -> String:
    var row: int = card._controls[0].get_instance_id() if not card._controls.is_empty() else 0
    return "%d %d" % [card.get_instance_id(), row]


## Check the mission on this frame.
func check_mission(mission: Node, tag: String) -> void:
    _checks += 1
    var run: MissionRun = mission._run
    var where := "%s on day %.2f (%s)" % [tag, run.days, _locale()]
    var last: Dictionary = _last.get(mission.get_instance_id(), {})
    var chart: ChartView = mission._chart
    var bounds := World.bounds_km()

    # NOTE (mristin):
    # The boats and their holds.
    for helm: Helm in mission._helms:
        var who := "%s, the boat %d" % [where, helm.player + 1]
        if not bounds.has_point(helm.km):
            _report("%s: a boat leaves the chart" % tag, "%s at %s" % [who, helm.km])
        elif chart.is_land(helm.km):
            _report("%s: a boat sails on the land" % tag, "%s at %s" % [who, helm.km])
        var hold := run.hold(helm.player)
        if hold.provisions < -0.001 or hold.provisions > hold.max_provisions + 0.001:
            _report(
                "%s: the food and water are out of the hold" % tag,
                "%s: %f of %f" % [who, hold.provisions, hold.max_provisions]
            )
        if hold.damage < 0.0 or hold.damage > 100.0:
            _report(
                "%s: the damage of the hull is out of [0, 100]" % tag, "%s: %f" % [who, hold.damage]
            )
        if hold.on_board() < 0:
            _report("%s: a boat has fewer than no ducats" % tag, "%s: %d" % [who, hold.on_board()])
    if run.days < float(last.get("days", 0.0)) - 0.0001:
        _report(
            "%s: the days run backwards" % tag, "%s: %f, then %f" % [where, last["days"], run.days]
        )
    last["days"] = run.days

    # NOTE (mristin):
    # The scenes in the halves of the players, and the HUD.
    var done := run.is_done()
    for i in range(mission.players):
        var card: StoryCard = mission._cards[i]
        var view: SeaView = mission._views[i]
        var who := "%s, the player %d" % [where, i + 1]
        if not done and card.visible != mission._busy[i]:
            _report(
                "%s: a scene shows while the boat sails, or the other way" % tag,
                "%s: busy %s, the scene shown %s" % [who, mission._busy[i], card.visible]
            )
        if card.visible and not card.get_meta("cursor").visible:
            _report("%s: a scene shows without its cursor" % tag, who)
        if card.visible:
            check_card(card, run, "%s, the half of the player %d" % [tag, i + 1])
        var hud: CanvasLayer = view._hud
        # NOTE (mristin):
        # The chart and the question whether to leave stand over the HUD, but
        # the scenes of the ports, the briefing and the meeting at sea hide it.
        var covered: bool = (
            mission._busy[i] or mission._shared_card.visible or mission._exchange != null
        )
        if hud.visible and covered:
            _report("%s: the HUD shows under a scene" % tag, who)
        if hud.visible:
            _check_hud(view, tag, who)
            _check_texts(view, tag, who)
    if mission._shared_card.visible:
        check_card(mission._shared_card, run, "%s, the whole screen" % tag)

    # NOTE (mristin):
    # Where the chart points.
    var step := run.step()
    if step != null and not done and not mission._all_paused:
        var targets := step.target_ports(run)
        var shown: Array = chart.targets
        if not _same_ports(targets, shown):
            # NOTE (mristin):
            # The chart follows on the next frame at the latest.
            if last.get("targets", false):
                _report(
                    "%s: the chart does not point where the step says" % tag,
                    (
                        "%s: the step %s points to %s, the chart to %s"
                        % [where, step.id, _ids(targets), _ids(shown)]
                    )
                )
            last["targets"] = true
        else:
            last["targets"] = false
        for view: SeaView in mission._views:
            if (
                not _same_ports(view.minimap.targets, shown)
                or not _same_ports(view.arrow.targets, shown)
            ):
                _report("%s: the minimap or the arrow points elsewhere than the chart" % tag, where)

    # NOTE (mristin):
    # The end of the mission.
    var complete := end_screen(mission)
    if done != (complete != null):
        _report(
            "%s: the mission is done, but its end does not show, or the other way" % tag,
            "%s: done %s, the end shown %s" % [where, done, complete != null]
        )
    if complete != null:
        if complete.stars < 1 or complete.stars > 3:
            _report("%s: the mission gives %d stars" % [tag, complete.stars], where)
        if complete.content_bottom > MissionComplete.BUTTON_TOP + TOLERANCE:
            _report(
                "%s: the text of the end runs into its button" % tag,
                (
                    "%s: down to %d, the button at %d"
                    % [where, complete.content_bottom, MissionComplete.BUTTON_TOP]
                )
            )
    _last[mission.get_instance_id()] = last


## The screen at the end of the mission, if it shows.
static func end_screen(mission: Node) -> MissionComplete:
    for child in mission._overlay.get_children():
        if child is MissionComplete and not child.is_queued_for_deletion():
            return child
    return null


## The panels of the HUD stay inside the view and do not overlap each other.
func _check_hud(view: SeaView, tag: String, who: String) -> void:
    var panels: Array[Control] = []
    for child in view._hud.get_children():
        var control := child as Control
        if control == null or not control.visible:
            continue
        if describe(control) in OVERLAYS:
            continue
        if control is HintPanel and not _hint_shown(control):
            continue
        panels.append(control)
    var inside := Rect2(Vector2.ZERO, view.size).grow(TOLERANCE)
    for i in range(panels.size()):
        var a := panels[i].get_rect()
        if not inside.encloses(a):
            _report(
                "%s: %s of the HUD sticks out of the view" % [tag, describe(panels[i])],
                "%s: %s in %s" % [who, a, view.size]
            )
        for j in range(i + 1, panels.size()):
            var b := panels[j].get_rect()
            if _overlap(a, b):
                var names := [describe(panels[i]), describe(panels[j])]
                names.sort()
                _report(
                    "%s: %s overlaps %s in the HUD" % [tag, names[0], names[1]],
                    "%s: %s and %s" % [who, a, b]
                )


## Whether the panel of the tips shows a tip now.
static func _hint_shown(hint: HintPanel) -> bool:
    return hint._age < HintPanel.SECONDS and hint._text != ""


## The messages of the toasts fit the width of the view (as Toast draws them,
## at their size after the pop), and a tip fits its panel at its smallest size
## (as HintPanel draws it).
func _check_texts(view: SeaView, tag: String, who: String) -> void:
    var font := ThemeDB.fallback_font
    for message in view.toast._messages:
        var text: String = message["text"]
        var size := Toast.font_size_of(text, 1.0, view.size.x)
        var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 60
        if width > view.size.x + TOLERANCE or size < StoryLayout.READABLE:
            _report(
                "%s: a toast does not fit the view" % tag,
                "%s: '%s' needs %d of %d pixels at %d" % [who, text, width, view.size.x, size]
            )
    var hint := view.hint
    if _hint_shown(hint):
        var height := (
            font
            . get_multiline_string_size(hint._text, HORIZONTAL_ALIGNMENT_LEFT, hint.size.x - 36, 18)
            . y
        )
        if height > hint.size.y - 54 + TOLERANCE:
            _report(
                "%s: a tip does not fit its panel" % tag,
                "%s: '%s' needs %d of %d pixels" % [who, hint._text, height, hint.size.y - 54]
            )


static func _same_ports(a: Array, b: Array) -> bool:
    if a.size() != b.size():
        return false
    for port in a:
        var found := false
        for other in b:
            found = found or World.port_km(port).distance_to(World.port_km(other)) < 0.01
        if not found:
            return false
    return true


static func _ids(ports: Array) -> String:
    var ids: Array[String] = []
    for port in ports:
        ids.append(port.id)
    return ", ".join(ids)


## Forget the mission, e.g., when it is left.
func forget(mission_id: int) -> void:
    _last.erase(mission_id)
    _cards_checked.clear()
