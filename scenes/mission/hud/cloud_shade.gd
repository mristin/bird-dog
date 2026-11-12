class_name CloudShade
extends Control

## Darken the edges of the view while a boat is inside a storm cloud (see
## DESIGN.md, section 9): the crew sees less around the boat. The shade is a
## smooth vignette, clear around the boat and darkest in the corners.

## The colour of the shade at its darkest.
const DARK := Color(0.15, 0.17, 0.22, 0.6)

## How much of the shade to show, from 0 to 1.
var amount := 0.0

var _shown := 0.0
var _vignette: GradientTexture2D


func _ready() -> void:
    var gradient := Gradient.new()
    gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
    gradient.colors = PackedColorArray([Color(DARK, 0.0), Color(DARK, 0.0), DARK])
    _vignette = GradientTexture2D.new()
    _vignette.gradient = gradient
    _vignette.fill = GradientTexture2D.FILL_RADIAL
    _vignette.fill_from = Vector2(0.5, 0.5)
    # NOTE (mristin):
    # The corners lie beyond the radius of the fill; they keep the last colour.
    _vignette.fill_to = Vector2(1.0, 0.5)
    _vignette.width = 256
    _vignette.height = 256


func _process(delta: float) -> void:
    var before := _shown
    _shown = lerpf(_shown, amount, 1.0 - exp(-delta * 3.0))
    if absf(_shown - before) > 0.001:
        queue_redraw()


func _draw() -> void:
    if _shown < 0.01:
        return
    draw_texture_rect(_vignette, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, _shown))
