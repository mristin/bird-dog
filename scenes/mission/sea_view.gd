class_name SeaView
extends SubViewportContainer

## What one player sees at sea (see DESIGN.md, "Two players"): a SubViewport
## on the shared chart with a camera which follows the player's boat, and the
## player's own HUD: the clue, the days, the hull of their boat with its cargo
## and passengers, the rations of food and water (a column of tokens), the boosters, the wind, the
## minimap, the arrow to the target, the toasts and the shade of the storm
## clouds.
##
## With one player, the view fills the screen; with two, every player has a
## half of it (960 x 1080), as in ergo-chaos, and the panels stand mirrored so
## that the webcam fits between the two halves at the bottom.

## The boats are this large on the chart at the zoom of 1; they keep this
## (small) size on the screen whatever the zoom of the camera (see ChartZoom),
## so that they fit into the channels.
const BOAT_SCALE := 1.0

## The camera measures how far to zoom in this often, in seconds.
const ZOOM_MEASURE_SECONDS := 0.2

## The camera eases in to a larger zoom over about this long, in seconds...
const ZOOM_IN_SECONDS := 1.0

## ...and out again more slowly, so that it does not pump among the islands.
const ZOOM_OUT_SECONDS := 2.0

## When zoomed in fully, the camera looks ahead of the boat by this share of
## the half of the view, so that the crew sees the channel ahead.
const LOOK_AHEAD := 0.35

## The player (0 or 1) whose boat the view follows.
var player := 0

## Whether the view is a half of the screen (two players).
var half := false

## How far the camera zooms in now (see ChartZoom), and where it goes.
var zoom := 1.0
var target_zoom := 1.0

var viewport: SubViewport
var camera: Camera2D
var minimap: Minimap
var arrow: TargetArrow
var toast: Toast
var shade: CloudShade
var hint: HintPanel
var rose: WindRose

var _hud: CanvasLayer
var _zoom_timer := 0.0


## Build the view; [param world] is the world to show: the first view holds
## the world, the second shares its World2D.
func setup(
    the_player: int, is_half: bool, run: MissionRun, wind: SeaWind, world: Node2D, shared: SeaView
) -> void:
    player = the_player
    half = is_half
    var width := 960 if half else 1920
    position = Vector2(player * 960 if half else 0, 0)
    size = Vector2(width, 1080)
    # NOTE (mristin):
    # A SubViewportContainer forwards the mouse to its viewport only if it does
    # not ignore the mouse; the cards of the ports and their cursors live in the
    # viewport, and the mouse clicks there for testing.
    mouse_filter = Control.MOUSE_FILTER_PASS

    viewport = SubViewport.new()
    viewport.size = Vector2i(width, 1080)
    viewport.handle_input_locally = false
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(viewport)
    if shared == null:
        viewport.add_child(world)
    else:
        viewport.world_2d = shared.viewport.world_2d

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 4.0
    viewport.add_child(camera)
    camera.make_current()

    _hud = CanvasLayer.new()
    viewport.add_child(_hud)
    _build_hud(run, wind, width)


## Place a panel: the positions are for the left half (or the whole screen);
## in the right half, they are mirrored.
func _place(control: Control, at: Vector2, extent: Vector2) -> void:
    var x := at.x
    if half and player == 1:
        x = 960 - at.x - extent.x
    control.position = Vector2(x, at.y)
    control.size = extent
    _hud.add_child(control)


func _build_hud(run: MissionRun, wind: SeaWind, width: int) -> void:
    shade = CloudShade.new()
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _place(shade, Vector2.ZERO, Vector2(width, 1080))

    var banner := ClueBanner.new()
    banner.run = run
    var days := DaysPanel.new()
    days.run = run
    var provisions := ProvisionsPanel.new()
    provisions.run = run
    provisions.player = player
    var hull := HullPanel.new()
    hull.run = run
    hull.player = player
    var bar := BoosterBar.new()
    bar.run = run
    rose = WindRose.new()
    rose.wind = wind
    var cargo := CargoPanel.new()
    cargo.run = run
    cargo.player = player
    minimap = Minimap.new()

    if half:
        _place(banner, Vector2(20, 16), Vector2(920, 130))
        _place(days, Vector2(20, 160), Vector2(380, 110))
        _place(hull, Vector2(20, 282), Vector2(380, 90))
        _place(bar, Vector2(20, 384), Vector2(380, 80))
        _place(cargo, Vector2(20, 476), Vector2(380, 144))
        _place(provisions, Vector2(412, 282), Vector2(96, 338))
        _place(rose, Vector2(600, 150), Vector2(340, 360))
        _place(minimap, Vector2(20, 764), Vector2(290, 296))
    else:
        _place(days, Vector2(30, 24), Vector2(420, 120))
        _place(hull, Vector2(30, 160), Vector2(420, 90))
        _place(bar, Vector2(30, 264), Vector2(420, 90))
        _place(cargo, Vector2(30, 364), Vector2(420, 144))
        _place(provisions, Vector2(464, 190), Vector2(104, 318))
        _place(banner, Vector2(490, 24), Vector2(1000, 150))
        _place(rose, Vector2(1560, 0), Vector2(340, 360))
        _place(minimap, Vector2(1500, 640), Vector2(390, 410))

    # NOTE (mristin):
    # The arrow and the toasts draw over the panels.
    arrow = TargetArrow.new()
    arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _place(arrow, Vector2.ZERO, Vector2(width, 1080))
    toast = Toast.new()
    toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _place(toast, Vector2.ZERO, Vector2(width, 1080))

    # NOTE (mristin):
    # The tips stand at the bottom, clear of the panels and the webcam.
    hint = HintPanel.new()
    hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if half:
        _place(hint, Vector2(330, 790), Vector2(410, 260))
    else:
        _place(hint, Vector2(560, 860), Vector2(800, 190))


## Show or hide the HUD (it hides while a scene of a port is open).
func show_hud(shown: bool) -> void:
    _hud.visible = shown


## Follow the boat of the helm with the camera, zooming in among the islands
## (see ChartZoom) and looking ahead of the boat when zoomed in. The boat keeps
## its size on the screen.
func follow(helm: Helm, chart: ChartView, snap := false, delta := 0.0) -> void:
    _zoom_timer -= delta
    if snap or _zoom_timer <= 0.0:
        _zoom_timer = ZOOM_MEASURE_SECONDS
        target_zoom = chart.zoom_map.zoom(helm.km)
    var boat := helm.boat
    if snap:
        zoom = target_zoom
    else:
        var seconds := ZOOM_IN_SECONDS if target_zoom > zoom else ZOOM_OUT_SECONDS
        zoom = lerpf(zoom, target_zoom, 1.0 - exp(-delta * 3.0 / seconds))
    camera.zoom = Vector2.ONE * zoom
    boat.scale = Vector2.ONE * BOAT_SCALE / zoom

    var zoomed_in := clampf((zoom - 1.0) / (ChartZoom.MAX_CROWDED - 1.0), 0.0, 1.0)
    var half := minf(size.x, size.y) * 0.5 / zoom
    var ahead := Vector2.UP.rotated(boat.heading) * half * LOOK_AHEAD * zoomed_in
    camera.position = boat.position + ahead
    if snap:
        camera.reset_smoothing()
