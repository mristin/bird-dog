class_name Tips
extends RefCounted

## The tips of the things which the crew meets for the first time (see
## HintPanel): every tip shows once per voyage, in the half of the player who
## met the thing (or in both halves, e.g., for a change of the wind).

var _session: Node
var _views: Array[SeaView] = []

## Per player: how long the boat has been sailing into the wind, in seconds.
var _into_wind := [0.0, 0.0]


func _init(session: Node, views: Array[SeaView]) -> void:
    _session = session
    _views = views


## Whether to show the tip: every tip shows once per voyage.
func wants(hint_id: String) -> bool:
    if _session.hints_seen.has(hint_id):
        return false
    _session.hints_seen.append(hint_id)
    return true


## Show the tip to the player (or, with -1, to everybody).
func show_tip(player: int, hint_id: String) -> void:
    var text: String = _views[0].hint.texts()[hint_id]
    for view in _views:
        if player < 0 or _views.size() == 1 or view.player == player:
            view.hint.show_tip(text)


## Show the tip of the first thing which the boat of the helm meets now.
func check(
    helm: Helm, delta: float, run: MissionRun, chart: ChartView, hazards: SeaHazards, wind: SeaWind
) -> void:
    var player := helm.player
    var into := wind.is_into_wind(helm.heading) and helm.speed < Helm.BASE_KM_PER_SECOND * 0.4
    _into_wind[player] = _into_wind[player] + delta if into else 0.0
    var seen := {
        "provisions": run.provisions_share(player) < 0.5,
        "reefs": chart.nearest_reef(helm.km) < 25.0,
        "cliffs": chart.near_cliffs(helm.km, 12.0),
        "damage": run.hold(player).damage > 0.0,
        "cloud": hazards.speed_factor(helm.km) < 1.0,
        "corsair": hazards.nearest("corsair", helm.km) < 35.0,
        "patrol": hazards.nearest("patrol", helm.km) < 35.0,
        "loot": hazards.nearest("loot", helm.km) < 20.0,
        "into_wind": _into_wind[player] > 2.0,
        "wind_change": wind.is_changing(),
    }
    for hint_id in seen:
        if seen[hint_id] and wants(hint_id):
            show_tip(-1 if hint_id == "wind_change" else player, hint_id)
            return
