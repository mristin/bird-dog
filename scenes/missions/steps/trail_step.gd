class_name TrailStep
extends MissionStep

## Follow somebody or something from port to port (see DESIGN.md, section 15):
## in the right port, a local tells where the trail goes on, and maybe a
## hallmark of the target. A wrong port has nothing to tell.

## A leg of a random route is at most this long, in kilometres, if the pool
## has a port so close; so the trail wanders along a coast instead of zig-
## zagging across the whole sea.
const MAX_LEG_KM := 230.0

## A leg of a random route is at least this long, in kilometres (if it can be).
const MIN_LEG_KM := 40.0

## The ports of the trail: with a fixed route, in this order; otherwise a pool
## from which the plan draws [member length] ports, a new route every time the
## mission starts (see [method plan]). The pool also gives the ports where the
## target flees to after a wrong pick in the line-up (see [method flee]).
@export var ports: Array[Port] = []

@export var length := 2
@export var fixed_route := true

## A random route is at most this long, from the start of the mission through
## all its ports, in kilometres, so that the mission clock fits every route;
## 0 for no limit. The plan draws routes until one fits (or takes the shortest
## of those it drew).
@export var max_route_km := 0.0

## The port where the trail always starts, also with a random route; null for
## any. It need not be in [member ports].
@export var starts_at: Port

## The hardest facts which the clues may use.
@export_range(1, 3) var max_difficulty := 1

## The destination clues, in English, each with {fact}.
@export var clue_templates: Array[String] = []

## The hallmarks to reveal, one per right port, in this order.
@export var reveal: Array[Hallmark] = []

## How a local tells a hallmark, in English, with {hallmark}.
@export var hallmark_template := "Their boat had {hallmark}."

## What the crew asks in the ports, in English.
@export var question := "Have you seen them?"

## Whether a rival (e.g., the Aga's recruiter) follows the same trail: if he
## reaches the last port first, the target flees once more, and the trail
## gets one port longer (see DESIGN.md, mission 2).
@export var rival := false

## How fast the rival sails, as a share of the best speed of the crew's boats.
@export var rival_share := 0.55

## What the crew hears when the rival was first, in English, with {port}.
@export var rival_line := "The rival reached {port} first! The trail goes on."

## What the local in the last port says, in English.
@export var found_line := "They are here!"


func plan(run: MissionRun, rng: RandomNumberGenerator) -> void:
    var route: Array[Port] = []
    if fixed_route:
        route = ports.duplicate()
    else:
        var best := INF
        for attempt in range(40):
            var drawn := _walk(run, rng)
            var km := _route_km(run, drawn)
            if km < best:
                best = km
                route = drawn
            if max_route_km <= 0.0 or km <= max_route_km:
                route = drawn
                break

    var facts: Array[int] = []
    var templates: Array[int] = []
    for port in route:
        facts.append(_draw_fact(port, rng))
        templates.append(rng.randi_range(0, maxi(0, clue_templates.size() - 1)))

    var ids: Array[String] = []
    for port in route:
        ids.append(port.id)
    run.plan[id] = {"route": ids, "facts": facts, "templates": templates, "index": 0}


## A random route: a random walk through the pool, every port at a sailable
## distance from the one before (or from the start of the mission).
func _walk(run: MissionRun, rng: RandomNumberGenerator) -> Array[Port]:
    var route: Array[Port] = []
    if starts_at != null:
        route.append(starts_at)
    var at: Port = starts_at if starts_at != null else run.mission.start_port
    while route.size() < length:
        var next := _next_port(at, route, rng)
        if next == null:
            break
        route.append(next)
        at = next
    return route


## How long a route is, from the start of the mission, in kilometres.
static func _route_km(run: MissionRun, route: Array[Port]) -> float:
    var km := 0.0
    var at := World.port_km(run.mission.start_port)
    for port in route:
        km += at.distance_to(World.port_km(port))
        at = World.port_km(port)
    return km


## A port of the pool, not on the route yet, at a sailable distance from
## [param at]; null if the pool is used up.
func _next_port(at: Port, route: Array, rng: RandomNumberGenerator) -> Port:
    var unused: Array[Port] = []
    for port in ports:
        if not route.has(port) and port != at:
            unused.append(port)
    if unused.is_empty():
        return null
    var from := World.port_km(at) if at != null else Vector2.ZERO
    var near: Array[Port] = []
    for port in unused:
        var distance := World.port_km(port).distance_to(from)
        if at == null or (distance >= MIN_LEG_KM and distance <= MAX_LEG_KM):
            near.append(port)
    if near.is_empty():
        # NOTE (mristin):
        # Nothing at a good distance: the closest unused port.
        unused.sort_custom(
            func(a: Port, b: Port) -> bool:
                return World.port_km(a).distance_to(from) < World.port_km(b).distance_to(from)
        )
        return unused[0]
    return near[rng.randi_range(0, near.size() - 1)]


## A fact of the port, easy enough for the clues.
func _draw_fact(port: Port, rng: RandomNumberGenerator) -> int:
    var easy: Array[int] = []
    for i in range(port.facts.size()):
        if port.facts[i].difficulty <= max_difficulty:
            easy.append(i)
    return easy[rng.randi_range(0, easy.size() - 1)] if not easy.is_empty() else 0


func _route_port(run: MissionRun, index: int) -> Port:
    return World.port(run.plan[id]["route"][index])


## The clue which points to the port with the given index of the route,
## followed by the name of the port, so that the kids need not solve the
## riddle to know where to sail.
func clue_line(run: MissionRun, index: int) -> Dictionary:
    var port := _route_port(run, index)
    var fact: PortFact = port.facts[run.plan[id]["facts"][index]]
    var template: String = clue_templates[run.plan[id]["templates"][index]]
    return MissionRun.line_then(
        MissionRun.line(template, {"fact": fact.phrase}),
        MissionRun.line("Sail to {port}!", {"port": port.name})
    )


func start(run: MissionRun) -> void:
    var state: Dictionary = run.plan[id]
    run.set_clue(clue_line(run, mini(state["index"], state["route"].size() - 1)))


func arrive(run: MissionRun, port: Port) -> Variant:
    var state: Dictionary = run.plan[id]
    var index: int = state["index"]
    var route: Array = state["route"]
    if index >= route.size() or port.id != route[index]:
        return null

    var lines: Array = [MissionRun.line(question)]
    if index < reveal.size():
        run.hallmarks.append(reveal[index])
        lines.append(MissionRun.line(hallmark_template, {"hallmark": reveal[index].phrase}))

    state["index"] = index + 1
    var local: Person = port.locals[0] if not port.locals.is_empty() else null
    if index + 1 < route.size():
        var next := clue_line(run, index + 1)
        lines.append(next)
        run.set_clue(next)
        return MissionStep.talk(local, lines, MissionRun.line("Thank you!"))

    lines.append(MissionRun.line(found_line))
    return MissionStep.talk(local, lines, MissionRun.line("Let's look!"))


## The ports of the route, in order.
func route_ports(run: MissionRun) -> Array[Port]:
    var result: Array[Port] = []
    for index in range(run.plan[id]["route"].size()):
        result.append(_route_port(run, index))
    return result


## The target flees once more: add a port of the pool to the end of the route
## (with its fact and clue), at a sailable distance from the last one; return
## it, or null if the pool is used up.
func extend(run: MissionRun) -> Port:
    var state: Dictionary = run.plan[id]
    var route := route_ports(run)
    var last: Port = route[-1] if not route.is_empty() else run.mission.start_port
    var port := _next_port(last, route, run.rng)
    if port == null:
        # NOTE (mristin):
        # The pool is used up: the target flees back to an earlier port of
        # the route (never the one where the crew is).
        for earlier in route:
            if earlier != last:
                port = earlier
        if port == null:
            return null
    state["route"].append(port.id)
    state["facts"].append(_draw_fact(port, run.rng))
    state["templates"].append(run.rng.randi_range(0, maxi(0, clue_templates.size() - 1)))
    return port


## A wrong pick in the line-up: the target slips away to another port, the
## trail goes on there, and the clue points to it; return the clue, or {} if
## the target can't flee.
func flee(run: MissionRun) -> Dictionary:
    if extend(run) == null:
        return {}
    var state: Dictionary = run.plan[id]
    state["index"] = state["route"].size() - 1
    var next := clue_line(run, state["index"])
    run.set_clue(next)
    return next


func target_ports(run: MissionRun) -> Array[Port]:
    var index: int = run.plan[id]["index"]
    if index < run.plan[id]["route"].size():
        return [_route_port(run, index)]
    return []


func is_done(run: MissionRun) -> bool:
    return run.plan[id]["index"] >= run.plan[id]["route"].size()
