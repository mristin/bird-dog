class_name StormCloud
extends Node2D

## A storm cloud over the sea, as in Pirates! (see DESIGN.md, section 9),
## drawn by a shader (storm_cloud.gdshader): billowing, slowly churning, lit
## from the top left, with its shadow on the sea, the rain below it (a veil
## which drifts in sheets with the wind, streaks of falling drops, and their
## rings on the sea), and a soft flash of lightning inside now and then. It
## drifts with the wind, lives for a while, then rains itself out. A boat
## inside sails at half speed and is pushed off course by the gusts.

## Lightning flashed in the cloud (it rumbles, see SeaHazards).
signal flashed

const SHADER := preload("res://scenes/mission/sailing/storm_cloud.gdshader")

## The cloud is drawn this much bigger than its radius, because its edges fade.
const DRAWN := 1.35

## Whether the cloud is a storm (see SeaConditions.storms).
var storm := false

## Where the cloud is and how big, in kilometres.
var km := Vector2.ZERO
var radius_km := 10.0

## How long the cloud lives, and how long it has lived, in seconds.
var life := 120.0
var age := 0.0

var _flash := 0.0
var _next_flash := 6.0
var _rng := RandomNumberGenerator.new()
var _cloud: ColorRect
var _shadow: ColorRect
var _rain: ColorRect


func setup(seed_value: int) -> void:
    _rng.seed = seed_value
    _next_flash = _rng.randf_range(4.0, 10.0)
    var seed_uniform := _rng.randf() * 100.0
    _shadow = _layer(seed_uniform, 1, Vector2(70, 110))
    _rain = _layer(seed_uniform, 2, Vector2.ZERO)
    _cloud = _layer(seed_uniform, 0, Vector2.ZERO)


## A layer of the shader: 0 the cloud, 1 its shadow, 2 the rain.
func _layer(seed_uniform: float, layer: int, offset: Vector2) -> ColorRect:
    var half := radius_km * ChartView.PX_PER_KM * DRAWN
    var rect := ColorRect.new()
    rect.size = Vector2(half, half) * 2.0
    rect.position = -Vector2(half, half) + offset
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var material := ShaderMaterial.new()
    material.shader = SHADER
    material.set_shader_parameter("seed", seed_uniform)
    material.set_shader_parameter("layer", layer)
    material.set_shader_parameter("storm", storm)
    material.set_shader_parameter("size_px", rect.size)
    rect.material = material
    add_child(rect)
    return rect


## How much of the cloud is there, from 0 to 1: it grows and fades.
func strength() -> float:
    return clampf(minf(age / 8.0, (life - age) / 12.0), 0.0, 1.0)


func is_gone() -> bool:
    return age >= life


func contains(point_km: Vector2) -> bool:
    return strength() > 0.4 and point_km.distance_to(km) < radius_km


func drift(delta: float, wind: SeaWind) -> void:
    age += delta
    km += wind.blows_to() * (0.12 + 0.08 * wind.intensity) * delta
    position = km * ChartView.PX_PER_KM
    _flash = maxf(0.0, _flash - delta * 2.5)
    _next_flash -= delta
    if _next_flash <= 0.0:
        _flash = 1.0
        _next_flash = _rng.randf_range(3.0, 6.0) if storm else _rng.randf_range(5.0, 12.0)
        flashed.emit()
    for layer in [_cloud, _shadow, _rain]:
        var material: ShaderMaterial = layer.material
        material.set_shader_parameter("strength", strength())
        material.set_shader_parameter("flash", _flash)
        material.set_shader_parameter("wind", wind.blows_to() * (0.6 + 0.4 * wind.intensity))
