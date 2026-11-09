class_name Rival
extends RefCounted

## A rival who follows the same trail as the crew (see TrailStep.rival), e.g.,
## the Aga's recruiter in mission 2. He sails from port to port of the route
## (shown on the minimap only: he takes his own ways between the islands),
## rests a little in every port, and if he reaches the last port of the route
## before the crew is done with the trail, the target flees once more. He does
## that only once; then he gives up.
##
## His state lives in the plan of the trail (run.plan[trail.id]["rival"]), so
## that a saved mission continues with him where he was.

## He rests this long in every port, in seconds.
const REST_SECONDS := 8.0


## Move the rival; return the port where he was first (the trail got longer
## then), or null.
static func update(run: MissionRun, trail: TrailStep, delta: float, speed: float) -> Port:
    var state: Dictionary = run.plan[trail.id]
    if not state.has("rival"):
        var start := World.port_km(run.mission.start_port)
        state["rival"] = {"x": start.x, "y": start.y, "leg": 0, "rest": REST_SECONDS, "done": false}
    var rival: Dictionary = state["rival"]
    if rival["done"]:
        return null
    rival["rest"] = maxf(0.0, rival["rest"] - delta)
    if rival["rest"] > 0.0:
        return null

    var route := trail.route_ports(run)
    var leg: int = rival["leg"]
    if leg >= route.size():
        rival["done"] = true
        return null
    var at := Vector2(rival["x"], rival["y"])
    var goal := World.port_km(route[leg])
    var step := speed * trail.rival_share * delta
    if at.distance_to(goal) > step:
        at += (goal - at).normalized() * step
        rival["x"] = at.x
        rival["y"] = at.y
        return null

    rival["x"] = goal.x
    rival["y"] = goal.y
    rival["leg"] = leg + 1
    rival["rest"] = REST_SECONDS
    var last := leg == route.size() - 1
    if last and state["index"] < route.size():
        rival["done"] = true
        if trail.extend(run) != null:
            return route[leg]
    return null


## Where the rival is, in kilometres, or null if there is none (yet).
static func position(run: MissionRun, trail: TrailStep) -> Variant:
    var state: Dictionary = run.plan.get(trail.id, {})
    if not state.has("rival") or state["rival"]["done"]:
        return null
    return Vector2(state["rival"]["x"], state["rival"]["y"])
