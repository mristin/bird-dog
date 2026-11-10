class_name ChartView
extends Node2D

## Draw the chart of the Adriatic at sea, like an old map: the sea in blue
## with engraved wave strokes, pale shallows along the coast, the land as
## paper with an ink coastline, and the ports with their names.
##
## The chart is much larger than the screen (as in Pirates! Gold); the camera
## follows the boat. One kilometre is [constant PX_PER_KM] pixels.

const PX_PER_KM := 11.2

const SEA := Color(0.33, 0.52, 0.66)
const SEA_LINES := Color(0.24, 0.4, 0.55, 0.55)
const SHALLOWS := Color(0.47, 0.66, 0.76)
const LAND := Color(0.9, 0.84, 0.69)
const COAST := Color(0.22, 0.15, 0.09)
const SEA_SHADER := preload("res://scenes/mission/sailing/sea.gdshader")

## A boat closer than this to a reef hits it, in kilometres.
const REEF_KM := 2.5

## The reefs are the same in every mission.
const REEF_SEED := 1600

## The colours of the rings, the same on the sea, on the minimap, on the large
## chart (C) and on the arrow: red where the mission leads, blue where the
## deliveries of the errands go.
const TARGET_COLOR := Color(0.82, 0.13, 0.11)
const ERRAND_COLOR := Color(0.2, 0.45, 0.88)

## The ports where the crew can go now: they get a big red ring and a flag.
var targets: Array[Port] = []:
    set(value):
        targets = value
        if _target_layer != null:
            _target_layer.queue_redraw()

## The ports which the crew's errands go to: they get a blue ring.
var errand_ports: Array[Port] = []:
    set(value):
        errand_ports = value
        if _target_layer != null:
            _target_layer.queue_redraw()

## How far the cameras zoom in among the islands (see ChartZoom).
var zoom_map: ChartZoom

## The ports, their names, the rings of the targets and the ships (see
## SeaHazards) are drawn this much larger, so that they keep their size on the
## screen while the cameras zoom in (the inverse of the zoom).
var marker_scale := 1.0:
    set(value):
        if absf(value - marker_scale) < 0.02:
            return
        marker_scale = value
        if _markers != null:
            _markers.queue_redraw()
        if _target_layer != null:
            _target_layer.queue_redraw()

## The reefs (in Croatian "hridi"): rocks just under the water, off the coasts
## and the islands, in kilometres. They are kept away from the harbours.
var reefs := PackedVector2Array()

## The polygons of the land in kilometres, with their bounding boxes, for
## [method is_land].
var _land: Array[PackedVector2Array] = []
var _boxes: Array[Rect2] = []

var _ports: Array[Port] = []
var _reef_names: Array = []

## The edges of the coast with cliffs: [a, b, inward] in kilometres, the
## inward pointing into the land.
var _cliff_edges: Array = []
var _cliff_names: Array = []
var _hatching := PackedVector2Array()
var _cliffs: Node2D
var _rocks: Node2D
var _markers: Node2D
var _target_layer: Node2D
var _surf: Node2D


func _ready() -> void:
    var bounds := World.bounds_km()
    var sea := Polygon2D.new()
    var rect := Rect2(bounds.position * PX_PER_KM, bounds.size * PX_PER_KM).grow(4000)
    sea.polygon = PackedVector2Array(
        [
            rect.position,
            Vector2(rect.end.x, rect.position.y),
            rect.end,
            Vector2(rect.position.x, rect.end.y)
        ]
    )
    sea.color = SEA
    sea.z_index = -2
    var sea_material := ShaderMaterial.new()
    sea_material.shader = SEA_SHADER
    sea_material.set_shader_parameter("lines_color", SEA_LINES)
    sea.material = sea_material
    add_child(sea)

    for polygon in World.chart()["polygons"]:
        var km := PackedVector2Array()
        var px := PackedVector2Array()
        for point in polygon:
            km.append(Vector2(point[0], point[1]))
            px.append(Vector2(point[0], point[1]) * PX_PER_KM)
        _land.append(km)
        var box := Rect2(km[0], Vector2.ZERO)
        for point in km:
            box = box.expand(point)
        _boxes.append(box)

        var outline := px.duplicate()
        outline.append(px[0])
        var shallows := Line2D.new()
        shallows.points = outline
        shallows.width = 26.0
        shallows.default_color = SHALLOWS
        shallows.joint_mode = Line2D.LINE_JOINT_ROUND
        shallows.z_index = -1
        add_child(shallows)

        var land := Polygon2D.new()
        land.polygon = px
        land.color = LAND
        add_child(land)

        var coast := Line2D.new()
        coast.points = outline
        coast.width = 3.0
        coast.default_color = COAST
        coast.joint_mode = Line2D.LINE_JOINT_ROUND
        add_child(coast)

    zoom_map = ChartZoom.new(_land)
    _ports = World.ports()
    _place_reefs()
    _place_cliffs()
    _cliffs = Node2D.new()
    _cliffs.draw.connect(_draw_cliffs.bind(_cliffs))
    add_child(_cliffs)
    _rocks = Node2D.new()
    _rocks.z_index = 2
    _rocks.draw.connect(_draw_reefs.bind(_rocks))
    add_child(_rocks)

    var markers := Node2D.new()
    markers.z_index = 2
    markers.draw.connect(_draw_ports.bind(markers))
    add_child(markers)
    _markers = markers

    _surf = Node2D.new()
    _surf.draw.connect(_draw_surf.bind(_surf))
    add_child(_surf)
    _target_layer = Node2D.new()
    _target_layer.z_index = 2
    _target_layer.draw.connect(_draw_targets.bind(_target_layer))
    add_child(_target_layer)


## Whether a point (in kilometres) lies on the land.
func is_land(km: Vector2) -> bool:
    for i in range(_land.size()):
        if _boxes[i].has_point(km) and Geometry2D.is_point_in_polygon(km, _land[i]):
            return true
    return false


## Whether a boat at the point (in kilometres) hits a reef.
func is_reef(km: Vector2) -> bool:
    for reef in reefs:
        if km.distance_to(reef) < REEF_KM:
            return true
    return false


func _place_reefs() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = REEF_SEED
    for field in World.reef_fields():
        var center := World.to_km(field.latitude, field.longitude)
        var placed := 0
        var field_rocks := PackedVector2Array()
        for attempt in range(field.rocks * 20):
            if placed >= field.rocks:
                break
            var point := (
                center
                + Vector2.RIGHT.rotated(rng.randf() * TAU) * sqrt(rng.randf()) * field.radius_km
            )
            var free := not is_land(point) and not _near_port(point, 10.0)
            for other in reefs:
                free = free and other.distance_to(point) > REEF_KM * 1.6
            if free:
                reefs.append(point)
                field_rocks.append(point)
                placed += 1
        _reef_names.append([field.name, center])
        if not field_rocks.is_empty():
            var patch := ReefPatch.new()
            patch.setup(center, field_rocks, rng.randf() * 50.0)
            patch.z_index = -1
            add_child(patch)


## How far the nearest reef is from the point, in kilometres; INF for none.
func nearest_reef(km: Vector2) -> float:
    var best := INF
    for reef in reefs:
        best = minf(best, reef.distance_to(km))
    return best


## Whether a point (in kilometres) lies near a stretch of cliffs.
func near_cliffs(km: Vector2, distance: float) -> bool:
    for field in World.cliff_fields():
        var center := World.to_km(field.latitude, field.longitude)
        if km.distance_to(center) < field.radius_km + distance:
            return true
    return false


## Whether a point of the land (in kilometres) is part of a cliff, where
## running ashore damages the hull.
func is_cliff(km: Vector2) -> bool:
    for field in World.cliff_fields():
        if km.distance_to(World.to_km(field.latitude, field.longitude)) < field.radius_km + 1.0:
            return true
    return false


## The engraved strokes of a steep face, computed once (they only stay on
## the land), as pairs of points in pixels.
func _add_hatching(a: Vector2, b: Vector2, inward: Vector2) -> void:
    var strokes := int(a.distance_to(b) / 4.0)
    for k in range(strokes + 1):
        var at := a.lerp(b, float(k) / maxf(1.0, strokes))
        var reach := 7.0 + 5.0 * absf(sin(at.x * 0.37 + at.y * 0.21))
        if is_land((at + inward * reach) / PX_PER_KM):
            _hatching.append(at)
            _hatching.append(at + inward * reach)


func _place_cliffs() -> void:
    for field in World.cliff_fields():
        var center := World.to_km(field.latitude, field.longitude)
        for polygon in _land:
            var count := polygon.size()
            for i in range(count):
                var a := polygon[i]
                var b := polygon[(i + 1) % count]
                var middle := a.lerp(b, 0.5)
                if middle.distance_to(center) > field.radius_km or _near_port(middle, 8.0):
                    continue
                if a.distance_to(b) < 0.05:
                    continue
                var inward := (b - a).normalized().orthogonal()
                if not is_land(middle + inward * 0.3):
                    inward = -inward
                _cliff_edges.append([a, b, inward])
                _add_hatching(a * PX_PER_KM, b * PX_PER_KM, inward)
        _cliff_names.append([field.name, center])


## The cliffs: a band of grey rock along the coast with the engraved hatching
## of a steep face, the surf breaking at its foot, and their name.
func _draw_cliffs(canvas: Node2D) -> void:
    if not _hatching.is_empty():
        canvas.draw_multiline(_hatching, Color(0.24, 0.19, 0.15), 1.8)
    for edge in _cliff_edges:
        var a: Vector2 = edge[0] * PX_PER_KM
        var b: Vector2 = edge[1] * PX_PER_KM
        var inward: Vector2 = edge[2]
        canvas.draw_line(a + inward * 4.0, b + inward * 4.0, Color(0.58, 0.54, 0.49), 9.0)
    for edge in _cliff_edges:
        var a: Vector2 = edge[0] * PX_PER_KM
        var b: Vector2 = edge[1] * PX_PER_KM
        var inward: Vector2 = edge[2]
        canvas.draw_line(a, b, Color(0.15, 0.11, 0.08), 4.0)
    var font := ThemeDB.fallback_font
    for entry in _cliff_names:
        var label := tr(entry[0])
        var at: Vector2 = entry[1] * PX_PER_KM + Vector2(-200, 70)
        canvas.draw_string_outline(
            font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 400, 24, 6, Color(SEA, 0.9)
        )
        canvas.draw_string(
            font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 400, 24, Color(1, 1, 1, 0.9)
        )


func _near_port(km: Vector2, distance: float) -> bool:
    for port in _ports:
        if World.port_km(port).distance_to(km) < distance:
            return true
    return false


## The names of the fields of reefs (the reefs themselves are ReefPatches).
func _draw_reefs(canvas: Node2D) -> void:
    var font := ThemeDB.fallback_font
    for entry in _reef_names:
        var label := tr(entry[0])
        var at: Vector2 = entry[1] * PX_PER_KM + Vector2(-200, REEF_KM * PX_PER_KM * 7.0)
        canvas.draw_string_outline(
            font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 400, 24, 6, Color(SEA, 0.9)
        )
        canvas.draw_string(
            font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 400, 24, Color(1, 1, 1, 0.9)
        )


func _process(_delta: float) -> void:
    # NOTE (mristin):
    # Only the moving parts redraw: the surf of the cliffs and the rings of
    # the targets. The coasts, the icons and the hatching are drawn once.
    _surf.queue_redraw()
    if not targets.is_empty() or not errand_ports.is_empty():
        _target_layer.queue_redraw()


## The surf breaking at the foot of the cliffs (the only part of the cliffs
## which moves, so the only one drawn again every frame).
func _draw_surf(canvas: Node2D) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    for edge in _cliff_edges:
        var a: Vector2 = edge[0] * PX_PER_KM
        var b: Vector2 = edge[1] * PX_PER_KM
        var inward: Vector2 = edge[2]
        var surf := 0.5 + 0.5 * sin(t * 2.0 + a.x * 0.05 + a.y * 0.03)
        canvas.draw_line(a - inward * 5.0, b - inward * 5.0, Color(1, 1, 1, 0.4 + 0.45 * surf), 3.0)


func _draw_targets(canvas: Node2D) -> void:
    for port in targets:
        canvas.draw_set_transform(World.port_km(port) * PX_PER_KM, 0.0, Vector2.ONE * marker_scale)
        _draw_target(canvas, Vector2.ZERO)
    for port in errand_ports:
        canvas.draw_set_transform(World.port_km(port) * PX_PER_KM, 0.0, Vector2.ONE * marker_scale)
        var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() / 300.0)
        canvas.draw_arc(
            Vector2.ZERO, 80.0 * pulse, 0, TAU, 48, Color(ERRAND_COLOR, 0.85), 5.0, true
        )
    canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ports(canvas: Node2D) -> void:
    var font := ThemeDB.fallback_font
    for port in _ports:
        var at := World.port_km(port) * PX_PER_KM
        PortIcons.draw(canvas, port.icon, at, marker_scale)
        canvas.draw_set_transform(at, 0.0, Vector2.ONE * marker_scale)
        at = Vector2.ZERO
        var label: String = tr(port.name)
        var at_label := at + Vector2(-150, 42)
        canvas.draw_string_outline(
            font, at_label, label, HORIZONTAL_ALIGNMENT_CENTER, 300, 30, 8, Color(LAND, 0.95)
        )
        canvas.draw_string(font, at_label, label, HORIZONTAL_ALIGNMENT_CENTER, 300, 30, COAST)
    canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The target: a pulsing red ring around the port and a big pennant. The
## ring stays outside the blue ring of an errand to the same port, so that a
## port can be both.
func _draw_target(canvas: Node2D, at: Vector2) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    var pulse := 1.0 + 0.12 * sin(t * 4.0)
    canvas.draw_arc(at, 130.0 * pulse, 0, TAU, 64, Color(TARGET_COLOR, 0.35), 26.0, true)
    canvas.draw_arc(at, 130.0 * pulse, 0, TAU, 64, TARGET_COLOR, 6.0, true)
    var top := at + Vector2(40, -120)
    canvas.draw_line(top + Vector2(0, 70), top, COAST, 5.0, true)
    var wave := sin(t * 6.0) * 6.0
    canvas.draw_colored_polygon(
        PackedVector2Array([top, top + Vector2(56, 12 + wave), top + Vector2(0, 30)]), TARGET_COLOR
    )
    canvas.draw_polyline(
        PackedVector2Array([top, top + Vector2(56, 12 + wave), top + Vector2(0, 30)]),
        COAST,
        2.0,
        true
    )
