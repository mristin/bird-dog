class_name ChartZoom
extends RefCounted

## How far the camera zooms in at sea (see DESIGN.md, "Zooming in among the
## islands"), so that the crew sees the way through the archipelagos, e.g.,
## around Zadar and Šibenik. Only the camera zooms: the boat sails as fast as
## ever.
##
## Two measures, of which the larger zoom wins:
##
## * **crowded:** how much coast lies near the boat (many islands),
## * **narrow:** how wide the water is around the boat, i.e., the shortest way
##   from land to land through the boat (a channel, e.g., the Pašman channel).
##
## The edges of the coast are kept in a grid, so that a measure looks only at
## the coast near the boat.

## The zoom among many islands.
const MAX_CROWDED := 2.5

## The zoom in a narrow channel.
const MAX_NARROW := 4.0

## The coast within this radius counts as near, in kilometres.
const CROWD_RADIUS_KM := 15.0

## With this much coast near the boat (in kilometres), the camera starts to
## zoom in, and it zooms in fully with [constant CROWD_FULL_KM]. Measured on
## the chart: a straight coast (Bari, Ancona) has about 35 km of coast near
## it, Šibenik 80 km, Zadar 140 km and Pag 200 km.
const CROWD_START_KM := 50.0
const CROWD_FULL_KM := 150.0

## The water narrower than this (in kilometres) starts to zoom the camera in,
## and the water as narrow as [constant NARROW_FULL_KM] zooms it in fully.
## Measured on the chart: the Pašman channel is about 3 km wide, the way into
## Zadar 6 km, the Split channel 12 km, and the open sea more than 25 km.
const NARROW_START_KM := 14.0
const NARROW_FULL_KM := 3.0

## The rays look this far for the land, in kilometres.
const RAY_KM := 16.0

## The number of directions (each in both ways) to measure the width in.
const RAYS := 12

const _CELL_KM := 8.0

## Longer edges close the polygons along the border of the chart; they are no
## coast.
const _LONGEST_EDGE_KM := 50.0

## The edges of the coast: [a, b] in kilometres.
var _edges: Array[PackedVector2Array] = []

## The indices of the edges in every cell of the grid, by the cell.
var _cells := {}


func _init(polygons: Array[PackedVector2Array]) -> void:
    for polygon in polygons:
        for i in range(polygon.size()):
            var a := polygon[i]
            var b := polygon[(i + 1) % polygon.size()]
            if a.distance_to(b) > _LONGEST_EDGE_KM:
                continue
            var index := _edges.size()
            _edges.append(PackedVector2Array([a, b]))
            var low := _cell(a.min(b))
            var high := _cell(a.max(b))
            for x in range(low.x, high.x + 1):
                for y in range(low.y, high.y + 1):
                    var key := Vector2i(x, y)
                    if not _cells.has(key):
                        _cells[key] = PackedInt32Array()
                    _cells[key].append(index)


func _cell(km: Vector2) -> Vector2i:
    return Vector2i(floori(km.x / _CELL_KM), floori(km.y / _CELL_KM))


## The edges of the coast within [param reach] kilometres of the point (and a
## few more), each once.
func _edges_near(km: Vector2, reach: float) -> Array[PackedVector2Array]:
    var low := _cell(km - Vector2(reach, reach))
    var high := _cell(km + Vector2(reach, reach))
    var seen := {}
    var result: Array[PackedVector2Array] = []
    for x in range(low.x, high.x + 1):
        for y in range(low.y, high.y + 1):
            var key := Vector2i(x, y)
            if not _cells.has(key):
                continue
            for index in _cells[key]:
                if not seen.has(index):
                    seen[index] = true
                    result.append(_edges[index])
    return result


## Measure the sea around the point (in kilometres): "coast_km" is how much
## coast lies within [constant CROWD_RADIUS_KM], and "width_km" how wide the
## water is (at most twice [constant RAY_KM]).
func measure(km: Vector2) -> Dictionary:
    var edges := _edges_near(km, maxf(CROWD_RADIUS_KM, RAY_KM))

    var coast := 0.0
    for edge in edges:
        var middle := (edge[0] + edge[1]) * 0.5
        if middle.distance_to(km) < CROWD_RADIUS_KM:
            coast += edge[0].distance_to(edge[1])

    var width := RAY_KM * 2.0
    for i in range(RAYS):
        var direction := Vector2.RIGHT.rotated(PI * i / RAYS)
        width = minf(width, _ray(km, direction, edges) + _ray(km, -direction, edges))

    return {"coast_km": coast, "width_km": width}


## How far the land is in the direction, at most [constant RAY_KM].
func _ray(km: Vector2, direction: Vector2, edges: Array[PackedVector2Array]) -> float:
    var end := km + direction * RAY_KM
    var nearest := RAY_KM
    for edge in edges:
        var hit: Variant = Geometry2D.segment_intersects_segment(km, end, edge[0], edge[1])
        if hit != null:
            nearest = minf(nearest, km.distance_to(hit))
    return nearest


## The zoom of the camera for a boat at the point (in kilometres): 1 at the
## open sea, up to [constant MAX_NARROW] in a narrow channel.
func zoom(km: Vector2) -> float:
    return zoom_for(measure(km))


## The zoom for a measure (see [method measure]).
static func zoom_for(measured: Dictionary) -> float:
    var crowded := smoothstep(CROWD_START_KM, CROWD_FULL_KM, measured["coast_km"])
    var narrow := 1.0 - smoothstep(NARROW_FULL_KM, NARROW_START_KM, measured["width_km"])
    return maxf(1.0 + (MAX_CROWDED - 1.0) * crowded, 1.0 + (MAX_NARROW - 1.0) * narrow)
