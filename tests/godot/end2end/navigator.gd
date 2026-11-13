extends RefCounted
## Find the way over the sea for the captains of the end-to-end tests (see
## captain_bot.gd), and follow it: where to head now, a few kilometres ahead
## along the way.
##
## The whole chart is drawn once onto a grid of [constant CELL_KM] cells, as
## the fishermen who tow a boat draw a part of it (see SeaRoute): the cells
## near the coast and the reefs cost more, so that the way keeps clear of
## them. Then [AStarGrid2D] finds every way on the same grid, in a moment.
##
## Not a test itself (its name does not start with test_), it is preloaded by
## the tests.

## The size of a cell of the grid, in kilometres.
const CELL_KM := 1.0

## The way keeps this far clear of the reefs, in kilometres, and a cell of
## the sea there costs this many times more.
const REEF_KM := 2.0
const REEF_COST := 40.0

## The way keeps this far clear of the ports, in kilometres (a boat enters a
## port at 5), and a cell there costs this many times more.
const PORT_KM := 6.5
const PORT_COST := 60.0

## The captain heads for the point of the way this far ahead, in kilometres,
## if the water between is free: farther than the boat turns around (about
## three kilometres), so that it does not circle around the way.
const LOOK_AHEAD_KM := 7.0

## A boat farther than this from its way finds a new one, in kilometres.
const OFF_WAY_KM := 5.0

## At most this many cells near the goal are tried as the end of the way.
const MAX_GOALS := 24

## The grid of the whole chart, shared by all the navigators, and where it
## starts, in kilometres.
static var _grid: AStarGrid2D = null
static var _origin := Vector2.ZERO

## The way, from the boat to near the goal, in kilometres.
var path := PackedVector2Array()

## Where the way leads.
var goal := Vector2.INF

var _next := 1


func _init(chart: ChartView) -> void:
    if _grid == null:
        _build(chart)


static func _build(chart: ChartView) -> void:
    SeaRoute._load()
    var bounds := World.bounds_km()
    _origin = bounds.position
    var columns := int(ceil(bounds.size.x / CELL_KM))
    var rows := int(ceil(bounds.size.y / CELL_KM))
    var land := SeaRoute._rasterize(_origin, columns, rows, CELL_KM)
    _grid = AStarGrid2D.new()
    _grid.region = Rect2i(0, 0, columns, rows)
    _grid.cell_size = Vector2.ONE
    _grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    _grid.update()
    for row in range(rows):
        for column in range(columns):
            if land[row * columns + column] == 1:
                _grid.set_point_solid(Vector2i(column, row), true)
    SeaRoute._keep_off_the_coast(_grid, land, columns, rows)
    var avoid: Array[Dictionary] = []
    for rock in chart.reefs:
        avoid.append({"km": rock, "radius": ChartView.REEF_KM + REEF_KM, "cost": REEF_COST})
    # NOTE (mristin):
    # A boat which passes a port enters it, which costs time; the way keeps
    # clear of the ports, unless it leads into one (it ends in the costly
    # cells, which only make the end of the way a bit longer).
    for port in World.ports():
        avoid.append({"km": World.port_km(port), "radius": PORT_KM, "cost": PORT_COST})
    SeaRoute._keep_clear(_grid, _origin, avoid, CELL_KM)


static func _cell(km: Vector2) -> Vector2i:
    return Vector2i(((km - _origin) / CELL_KM).floor())


static func _middle(cell: Vector2i) -> Vector2:
    return _origin + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_KM


## The cells at sea within [param radius] kilometres of the point, the
## closest first.
static func _sea_cells(km: Vector2, radius: float) -> Array[Vector2i]:
    var center := _cell(km)
    var reach := ceili(radius / CELL_KM)
    var result: Array[Vector2i] = []
    for dy in range(-reach, reach + 1):
        for dx in range(-reach, reach + 1):
            var cell := center + Vector2i(dx, dy)
            if not _grid.is_in_boundsv(cell) or _grid.is_point_solid(cell):
                continue
            if _middle(cell).distance_to(km) <= radius:
                result.append(cell)
    result.sort_custom(
        func(a: Vector2i, b: Vector2i) -> bool:
            return _middle(a).distance_to(km) < _middle(b).distance_to(km)
    )
    return result


## Find the way from [param from] to within [param near] kilometres of
## [param to]; return whether there is one.
func plan(from: Vector2, to: Vector2, near: float) -> bool:
    goal = to
    _next = 1
    path = PackedVector2Array()
    var starts := _sea_cells(from, 3.0)
    var goals := _sea_cells(to, near)
    if starts.is_empty() or goals.is_empty():
        return false
    for end in goals.slice(0, MAX_GOALS):
        var cells := _grid.get_id_path(starts[0], end)
        if cells.is_empty():
            continue
        path.append(from)
        for i in range(1, cells.size()):
            path.append(_middle(cells[i]))
        if path.size() < 2:
            path.append(_middle(end))
        return true
    return false


## Forget the way, e.g., when the boat enters a port.
func forget() -> void:
    path = PackedVector2Array()
    goal = Vector2.INF


## Whether the boat at [param at] still follows a way to [param to].
func follows(at: Vector2, to: Vector2) -> bool:
    if path.size() < 2 or goal.distance_to(to) > 0.5:
        return false
    var best := INF
    var first := maxi(0, _next - 1)
    for i in range(first, mini(path.size() - 1, first + 10)):
        var closest := Geometry2D.get_closest_point_to_segment(at, path[i], path[i + 1])
        best = minf(best, at.distance_to(closest))
    return best < OFF_WAY_KM


## The point to head for from [param at] (pure pursuit): the point of the
## way [constant LOOK_AHEAD_KM] further along it than the point of the way
## closest to the boat, or closer, if the land stands between.
func aim(at: Vector2) -> Vector2:
    if path.size() < 2:
        return goal
    # NOTE (mristin):
    # The closest point of the way is searched a bit ahead only, so that a way
    # which comes back close to itself does not let the boat skip a loop.
    var best := INF
    var segment := _next - 1
    var along := 0.0
    for i in range(maxi(0, _next - 1), mini(path.size() - 1, _next + 20)):
        var closest := Geometry2D.get_closest_point_to_segment(at, path[i], path[i + 1])
        var distance := at.distance_to(closest)
        if distance < best - 0.01:
            best = distance
            segment = i
            along = path[i].distance_to(closest)
    _next = segment + 1
    for reach in [LOOK_AHEAD_KM, LOOK_AHEAD_KM * 0.5, LOOK_AHEAD_KM * 0.25]:
        var point := _ahead(segment, along + reach)
        if clear(at, point):
            return point
    return path[mini(_next, path.size() - 1)]


## The point of the way [param distance] kilometres after the start of the
## segment.
func _ahead(segment: int, distance: float) -> Vector2:
    var i := segment
    while i < path.size() - 1:
        var length := path[i].distance_to(path[i + 1])
        if distance <= length:
            return path[i].lerp(path[i + 1], distance / maxf(length, 0.001))
        distance -= length
        i += 1
    return path[-1]


## Whether the point lies at sea, by the grid (a coast cuts its cell).
static func is_sea(km: Vector2) -> bool:
    var cell := _cell(km)
    return _grid.is_in_boundsv(cell) and not _grid.is_point_solid(cell)


## Whether the straight line between the two points stays at sea, by the grid.
static func clear(a: Vector2, b: Vector2) -> bool:
    var steps := maxi(1, ceili(a.distance_to(b) / (CELL_KM * 0.5)))
    for k in range(1, steps + 1):
        if not is_sea(a.lerp(b, float(k) / steps)):
            return false
    return true
