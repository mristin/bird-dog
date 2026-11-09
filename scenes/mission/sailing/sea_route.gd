class_name SeaRoute
extends RefCounted

## A way over the sea between two points, around the islands and the capes,
## for the fishermen who tow a boat to a port (see TowBoat): the chart around
## the two points is drawn onto a grid of [constant CELL_KM] cells (row by row,
## from the crossings of the coasts, as in tests/godot/test_reachability.gd,
## so that the narrow channels and the bays like that of Kotor stay open), and
## A* finds the shortest way through the cells at sea. The way can also keep
## clear of some places (e.g., the reefs and the storms), which cost more to
## sail through, but never block it: a boat broken on a reef has to get out.

## The size of a cell of the grid, in kilometres.
const CELL_KM := 1.0

## The grid reaches this far beyond the two points, in kilometres, so that the
## way can go around an island; if there is no way, a wider grid, so that it
## can go around a long peninsula, too (e.g., Pelješac to reach Ston).
const MARGINS_KM: Array[float] = [50.0, 140.0]

## The cells this close to the land (in cells) cost more to sail through, so
## that the way keeps some water between the boats and the coast: the cell
## next to the land by the first factor, and so on.
const COAST_COSTS: Array[float] = [6.0, 3.0, 1.6]

## The steps of a way are checked against the land this finely, in kilometres.
const SAMPLE_KM := 0.05

## At most this many times a way is found again around a corner of the land
## which a step of it clipped.
const MAX_FIXES := 40

## At most this many cells near the port are tried as the end of the way.
const MAX_GOALS := 16

## The polygons of the land, in kilometres, with their bounding boxes.
static var _polygons: Array[PackedVector2Array] = []
static var _boxes: Array[Rect2] = []


## The way from [param from] to (near) [param to], as points in kilometres,
## the first at [param from] and the last within [param near_km] of
## [param to]; empty if there is none. [param avoid] lists the places to keep
## clear of: [{"km": Vector2, "radius": float, "cost": float}], where the cost
## is how many times more a cell within the radius costs to sail through.
static func find(
    from: Vector2, to: Vector2, near_km: float, avoid: Array[Dictionary] = []
) -> PackedVector2Array:
    _load()
    for margin in MARGINS_KM:
        var path := _find(from, to, near_km, margin, avoid)
        if not path.is_empty():
            return path
    return PackedVector2Array()


static func _find(
    from: Vector2, to: Vector2, near_km: float, margin: float, avoid: Array[Dictionary]
) -> PackedVector2Array:
    var box := Rect2(from, Vector2.ZERO).expand(to).grow(margin)
    var origin := box.position
    var columns := int(ceil(box.size.x / CELL_KM))
    var rows := int(ceil(box.size.y / CELL_KM))
    var land := _rasterize(origin, columns, rows)

    var grid := AStarGrid2D.new()
    grid.region = Rect2i(0, 0, columns, rows)
    grid.cell_size = Vector2.ONE
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    grid.update()
    grid.fill_solid_region(grid.region, false)
    _keep_off_the_coast(grid, land, columns, rows)
    _keep_clear(grid, origin, avoid)
    var goals: Array[Vector2i] = []
    var start := Vector2i(-1, -1)
    var start_distance := INF
    for row in range(rows):
        for column in range(columns):
            if land[row * columns + column] == 1:
                grid.set_point_solid(Vector2i(column, row), true)
                continue
            var middle := origin + (Vector2(column, row) + Vector2(0.5, 0.5)) * CELL_KM
            if middle.distance_to(to) < near_km:
                goals.append(Vector2i(column, row))
            var to_boat := middle.distance_to(from)
            if to_boat < start_distance:
                start_distance = to_boat
                start = Vector2i(column, row)
    if start.x < 0:
        return PackedVector2Array()

    # NOTE (mristin):
    # The closest cell to the port may lie in a channel which the grid closes
    # (e.g., the narrow channel of Ston); then the next closest.
    goals.sort_custom(
        func(a: Vector2i, b: Vector2i) -> bool:
            return Vector2(a).distance_to(to - origin) < Vector2(b).distance_to(to - origin)
    )
    var cells: Array[Vector2i] = []
    for goal in goals.slice(0, MAX_GOALS):
        cells = _clear_path(grid, origin, start, goal)
        if not cells.is_empty():
            break
    if cells.is_empty():
        return PackedVector2Array()
    var path := PackedVector2Array([from])
    for i in range(1, cells.size()):
        path.append(origin + (Vector2(cells[i]) + Vector2(0.5, 0.5)) * CELL_KM)
    if path.size() < 2:
        # NOTE (mristin):
        # The boat is at the port already: the way is a step to its own cell.
        path.append(origin + (Vector2(cells[0]) + Vector2(0.5, 0.5)) * CELL_KM)
    return path


## The way through the grid from the start to the goal, whose every step
## stays at sea: a step between the middles of two cells at sea may still clip
## a thin tip of the land (the grid knows only the middles of the cells), so
## the cell of the tip is closed and the way found again. Empty if none.
static func _clear_path(
    grid: AStarGrid2D, origin: Vector2, start: Vector2i, goal: Vector2i
) -> Array[Vector2i]:
    for attempt in range(MAX_FIXES):
        var cells := grid.get_id_path(start, goal)
        if cells.is_empty():
            return cells
        var clipped := _clipped_cell(cells, origin)
        if clipped == Vector2i(-1, -1):
            return cells
        if clipped == start or clipped == goal:
            return [] as Array[Vector2i]
        grid.set_point_solid(clipped, true)
    return [] as Array[Vector2i]


## The first cell where a step of the way runs over the land, or (-1, -1).
static func _clipped_cell(cells: Array[Vector2i], origin: Vector2) -> Vector2i:
    for i in range(1, cells.size()):
        var a := origin + (Vector2(cells[i - 1]) + Vector2(0.5, 0.5)) * CELL_KM
        var b := origin + (Vector2(cells[i]) + Vector2(0.5, 0.5)) * CELL_KM
        var on_land := _land_on(a, b)
        if on_land != Vector2.INF:
            return Vector2i(((on_land - origin) / CELL_KM).floor())
    return Vector2i(-1, -1)


## A point of the land which the step from a to b crosses (even a thin tip
## of an island; sampled every [constant SAMPLE_KM], with the same test as
## ChartView.is_land), or INF if it stays at sea.
static func _land_on(a: Vector2, b: Vector2) -> Vector2:
    var step := Rect2(a, Vector2.ZERO).expand(b).grow(0.01)
    var near: Array[int] = []
    for i in range(_polygons.size()):
        if _boxes[i].intersects(step):
            near.append(i)
    if near.is_empty():
        return Vector2.INF
    var count := maxi(2, ceili(a.distance_to(b) / SAMPLE_KM))
    for k in range(count + 1):
        var point := a.lerp(b, float(k) / count)
        for i in near:
            if Geometry2D.is_point_in_polygon(point, _polygons[i]):
                return point
    return Vector2.INF


## Make the cells near the land cost more (see COAST_COSTS): a breadth-first
## walk from every land cell, as far as the costs reach.
static func _keep_off_the_coast(
    grid: AStarGrid2D, land: PackedByteArray, columns: int, rows: int
) -> void:
    var distance := PackedInt32Array()
    distance.resize(columns * rows)
    distance.fill(-1)
    var front: Array[int] = []
    for i in range(land.size()):
        if land[i] == 1:
            distance[i] = 0
            front.append(i)
    for step in range(1, COAST_COSTS.size() + 1):
        var next: Array[int] = []
        for at in front:
            var column := at % columns
            var row := at / columns
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    var c: int = column + dx
                    var r: int = row + dy
                    if c < 0 or r < 0 or c >= columns or r >= rows:
                        continue
                    var index := r * columns + c
                    if distance[index] >= 0:
                        continue
                    distance[index] = step
                    grid.set_point_weight_scale(Vector2i(c, r), COAST_COSTS[step - 1])
                    next.append(index)
        front = next


## Make the cells within the places to avoid cost more (see [method find]).
static func _keep_clear(grid: AStarGrid2D, origin: Vector2, avoid: Array[Dictionary]) -> void:
    for place in avoid:
        var center: Vector2 = (place["km"] - origin) / CELL_KM
        var radius: float = place["radius"] / CELL_KM
        var area := (
            Rect2i(
                Vector2i((center - Vector2.ONE * radius).floor()),
                Vector2i.ONE * (ceili(radius) * 2 + 2)
            )
            . intersection(grid.region)
        )
        for row in range(area.position.y, area.end.y):
            for column in range(area.position.x, area.end.x):
                var cell := Vector2i(column, row)
                if (Vector2(cell) + Vector2(0.5, 0.5)).distance_to(center) > radius:
                    continue
                grid.set_point_weight_scale(
                    cell, maxf(grid.get_point_weight_scale(cell), place["cost"])
                )


## How many kilometres of the way run through the places to avoid (see
## [method find]), sampled every kilometre.
static func km_through(path: PackedVector2Array, avoid: Array[Dictionary]) -> float:
    var result := 0.0
    for i in range(1, path.size()):
        var count := maxi(1, ceili(path[i - 1].distance_to(path[i]) / CELL_KM))
        var piece := path[i - 1].distance_to(path[i]) / count
        for k in range(count):
            var point := path[i - 1].lerp(path[i], (k + 0.5) / count)
            for place in avoid:
                if point.distance_to(place["km"]) < place["radius"]:
                    result += piece
                    break
    return result


static func _load() -> void:
    if not _polygons.is_empty():
        return
    for polygon in World.chart()["polygons"]:
        var points := PackedVector2Array()
        for point in polygon:
            points.append(Vector2(point[0], point[1]))
        var box := Rect2(points[0], Vector2.ZERO)
        for point in points:
            box = box.expand(point)
        _polygons.append(points)
        _boxes.append(box)


## Draw the land onto the grid: for every row, the crossings of the row's
## middle with the edges of every polygon, paired up, are stretches of land.
static func _rasterize(origin: Vector2, columns: int, rows: int) -> PackedByteArray:
    var land := PackedByteArray()
    land.resize(columns * rows)
    var area := Rect2(origin, Vector2(columns, rows) * CELL_KM)
    var near: Array[int] = []
    for i in range(_polygons.size()):
        if _boxes[i].intersects(area):
            near.append(i)
    for row in range(rows):
        var y := origin.y + (row + 0.5) * CELL_KM
        for i in near:
            if y < _boxes[i].position.y or y > _boxes[i].end.y:
                continue
            var polygon := _polygons[i]
            var crossings: Array[float] = []
            var count := polygon.size()
            for k in range(count):
                var a := polygon[k]
                var b := polygon[(k + 1) % count]
                if (a.y > y) != (b.y > y):
                    crossings.append(a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y))
            crossings.sort()
            for k in range(0, crossings.size() - 1, 2):
                var first := maxi(0, int(ceil((crossings[k] - origin.x) / CELL_KM - 0.5)))
                var last := mini(
                    columns - 1, int(floor((crossings[k + 1] - origin.x) / CELL_KM - 0.5))
                )
                for column in range(first, last + 1):
                    land[row * columns + column] = 1
    return land
