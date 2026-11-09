class_name World
extends RefCounted

## The world of the missions: the ports (from `res://data/world/ports/`) and
## the chart of the Adriatic (from `res://data/world/adriatic_map.json`, made
## by dev/maps/make_adriatic_map.py), in kilometres.
##
## The chart and the ports share one projection, so the ports always lie on
## the coast of the chart.

const PORTS_DIR := "res://data/world/ports"
const CHART_PATH := "res://data/world/adriatic_map.json"
const REEFS_DIR := "res://data/world/reefs"
const CLIFFS_DIR := "res://data/world/cliffs"
const DECORATIONS_DIR := "res://data/world/decorations"
const ITEMS_DIR := "res://data/world/items"
const SHIPS_DIR := "res://data/world/ships"
const BOOSTERS_DIR := "res://data/world/boosters"

static var _ports: Array[Port] = []
static var _chart := {}
static var _reefs: Array[ReefField] = []
static var _cliffs: Array[CliffField] = []
static var _decorations: Array[Decoration] = []
static var _ships: Array[Ship] = []
static var _boosters: Array[Booster] = []


## All the ports, sorted by their id.
static func ports() -> Array[Port]:
    if _ports.is_empty():
        for file in ResourceLoader.list_directory(PORTS_DIR):
            if file.ends_with(".tres"):
                var port: Port = load(PORTS_DIR + "/" + file)
                if port != null:
                    _ports.append(port)
        _ports.sort_custom(func(a, b): return a.id < b.id)
    return _ports


## The fields of reefs, sorted by their id.
static func reef_fields() -> Array[ReefField]:
    if _reefs.is_empty():
        for file in ResourceLoader.list_directory(REEFS_DIR):
            if file.ends_with(".tres"):
                var field: ReefField = load(REEFS_DIR + "/" + file)
                if field != null:
                    _reefs.append(field)
        _reefs.sort_custom(func(a, b): return a.id < b.id)
    return _reefs


## The stretches of cliffs, sorted by their id.
static func cliff_fields() -> Array[CliffField]:
    if _cliffs.is_empty():
        for file in ResourceLoader.list_directory(CLIFFS_DIR):
            if file.ends_with(".tres"):
                var field: CliffField = load(CLIFFS_DIR + "/" + file)
                if field != null:
                    _cliffs.append(field)
        _cliffs.sort_custom(func(a, b): return a.id < b.id)
    return _cliffs


## The decorations of Master Ivan's shipyard, in the order of their files.
static func decorations() -> Array[Decoration]:
    if _decorations.is_empty():
        var files: Array = Array(ResourceLoader.list_directory(DECORATIONS_DIR))
        files.sort()
        for file in files:
            if file.ends_with(".tres"):
                var decoration: Decoration = load(DECORATIONS_DIR + "/" + file)
                if decoration != null:
                    _decorations.append(decoration)
    return _decorations


static func decoration(decoration_id: String) -> Decoration:
    for candidate in decorations():
        if candidate.id == decoration_id:
            return candidate
    return null


## The ships of Master Ivan's shipyard, in the order of their files (the
## first is the gajeta, which every captain starts with).
static func ships() -> Array[Ship]:
    if _ships.is_empty():
        for found in _load_all(SHIPS_DIR):
            _ships.append(found)
    return _ships


static func ship(ship_id: String) -> Ship:
    for candidate in ships():
        if candidate.id == ship_id:
            return candidate
    return null


## The ship of a captain: the one they bought and sailed, or the gajeta.
static func captain_ship(captain: Dictionary) -> Ship:
    var found := ship(str(captain.get("ship", "")))
    return found if found != null else ships()[0]


## Every booster which the merchants sell (see DESIGN.md, section 10), in the
## order of their files.
static func boosters() -> Array[Booster]:
    if _boosters.is_empty():
        for found in _load_all(BOOSTERS_DIR):
            _boosters.append(found)
    return _boosters


static func _load_all(directory: String) -> Array[Resource]:
    var result: Array[Resource] = []
    var files: Array = Array(ResourceLoader.list_directory(directory))
    files.sort()
    for file in files:
        if file.ends_with(".tres"):
            var loaded: Resource = load(directory + "/" + file)
            if loaded != null:
                result.append(loaded)
    return result


## The decorations of a captain's boat, by their slot (see Decoration.SLOTS).
static func boat_decorations(captain: Dictionary) -> Dictionary:
    var result := {}
    var boat: Dictionary = captain.get("boat", {})
    for slot in boat:
        var found := decoration(str(boat[slot]))
        if found != null:
            result[slot] = found
    return result


## An item of the world (the bell, the salt, a passenger), by its id.
static func item(item_id: String) -> Item:
    var path := "%s/%s.tres" % [ITEMS_DIR, item_id]
    if not ResourceLoader.exists(path):
        return null
    return load(path)


static func port(port_id: String) -> Port:
    for candidate in ports():
        if candidate.id == port_id:
            return candidate
    return null


## The chart: "projection", "bounds_km" ([x, y, width, height]) and "polygons"
## (each a list of [x, y] in kilometres, x to the east and y to the south).
static func chart() -> Dictionary:
    if _chart.is_empty():
        var json: JSON = load(CHART_PATH)
        _chart = json.data
    return _chart


## Project a latitude and a longitude to kilometres on the chart.
static func to_km(latitude: float, longitude: float) -> Vector2:
    var projection: Dictionary = chart()["projection"]
    return Vector2(
        (longitude - projection["lon0"]) * projection["km_per_degree_lon"],
        -(latitude - projection["lat0"]) * projection["km_per_degree_lat"]
    )


static func port_km(a_port: Port) -> Vector2:
    return to_km(a_port.latitude, a_port.longitude)


## The bounds of the chart in kilometres.
static func bounds_km() -> Rect2:
    var bounds: Array = chart()["bounds_km"]
    return Rect2(bounds[0], bounds[1], bounds[2], bounds[3])
