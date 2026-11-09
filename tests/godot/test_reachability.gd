extends SceneTree
## Check that the boats can reach every port: the land of the chart is drawn
## onto a grid of 1 km cells (row by row, from the crossings of the coasts),
## the sea is flooded from the middle of the Adriatic, and every port must
## have flooded sea within the distance at which a boat enters it. So no port
## lies in a bay or behind an island which the chart closes off, and no boat
## starts trapped.

## The size of a cell of the grid, in kilometres.
const CELL := 1.0

## A boat closer than this enters a port (see the mission screen), less a cell
## for the coarseness of the grid.
const ENTER_KM := 5.0 - CELL

var _failures: Array[String] = []
var _origin := Vector2.ZERO
var _columns := 0
var _rows := 0


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var bounds := World.bounds_km()
    _origin = bounds.position
    _columns = int(ceil(bounds.size.x / CELL))
    _rows = int(ceil(bounds.size.y / CELL))
    var land := _rasterize()
    var sea := _flood(land, World.to_km(42.5, 16.5))
    print("The sea floods %d of %d cells." % [_count(sea), sea.size()])

    for port in World.ports():
        _check(_reachable(sea, World.port_km(port)), "the boats can reach %s" % port.id)
    for mission in MissionCatalog.all():
        _check(
            _reachable(sea, World.port_km(mission.start_port)),
            "the boats of %s start in the open sea" % mission.id
        )

    if _failures.is_empty():
        print("RESULT: OK")
        quit(0)
    else:
        print("RESULT: FAILED (%d)" % _failures.size())
        quit(1)


func _index(column: int, row: int) -> int:
    return row * _columns + column


## Draw the land onto the grid: for every row, the crossings of the row's
## middle with the edges of every polygon, paired up, are stretches of land.
func _rasterize() -> PackedByteArray:
    var land := PackedByteArray()
    land.resize(_columns * _rows)
    var polygons: Array = World.chart()["polygons"]
    for row in range(_rows):
        var y := _origin.y + (row + 0.5) * CELL
        for polygon in polygons:
            var crossings: Array[float] = []
            var count: int = polygon.size()
            for i in range(count):
                var a: Array = polygon[i]
                var b: Array = polygon[(i + 1) % count]
                if (a[1] > y) != (b[1] > y):
                    crossings.append(a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
            crossings.sort()
            for k in range(0, crossings.size() - 1, 2):
                var first := maxi(0, int(ceil((crossings[k] - _origin.x) / CELL - 0.5)))
                var last := mini(
                    _columns - 1, int(floor((crossings[k + 1] - _origin.x) / CELL - 0.5))
                )
                for column in range(first, last + 1):
                    land[_index(column, row)] = 1
    return land


## Flood the sea from a point: every sea cell connected to it.
func _flood(land: PackedByteArray, start_km: Vector2) -> PackedByteArray:
    var sea := PackedByteArray()
    sea.resize(land.size())
    var start := Vector2i(((start_km - _origin) / CELL).floor())
    var queue: Array[int] = [_index(start.x, start.y)]
    sea[queue[0]] = 1
    var head := 0
    while head < queue.size():
        var at := queue[head]
        head += 1
        var column := at % _columns
        var row := at / _columns
        for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var next := Vector2i(column, row) + step
            if next.x < 0 or next.y < 0 or next.x >= _columns or next.y >= _rows:
                continue
            var index := _index(next.x, next.y)
            if land[index] == 0 and sea[index] == 0:
                sea[index] = 1
                queue.append(index)
    return sea


## Whether flooded sea lies within the distance of entering the port.
func _reachable(sea: PackedByteArray, port_km: Vector2) -> bool:
    var reach := int(ceil(ENTER_KM / CELL))
    var center := Vector2i(((port_km - _origin) / CELL).floor())
    for dy in range(-reach, reach + 1):
        for dx in range(-reach, reach + 1):
            var cell := center + Vector2i(dx, dy)
            if cell.x < 0 or cell.y < 0 or cell.x >= _columns or cell.y >= _rows:
                continue
            var middle := _origin + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL
            if middle.distance_to(port_km) <= ENTER_KM and sea[_index(cell.x, cell.y)] == 1:
                return true
    return false


func _count(cells: PackedByteArray) -> int:
    var total := 0
    for cell in cells:
        total += cell
    return total
