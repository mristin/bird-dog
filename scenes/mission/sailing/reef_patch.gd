class_name ReefPatch
extends ColorRect

## A field of reefs on the chart, drawn by a shader (reef.gdshader): pale
## shallow water with rippling light, dark rocks breaking the surface, and
## foam breaking around them. The rocks of the shader are the rocks which the
## boats hit (see ChartView.is_reef).

const SHADER := preload("res://scenes/mission/sailing/reef.gdshader")

## The most rocks a patch can show (the size of the shader's array).
const MAX_ROCKS := 12


## Show the rocks (in kilometres) around the middle (in kilometres).
func setup(center_km: Vector2, rocks_km: PackedVector2Array, seed_value: float) -> void:
    var px := ChartView.PX_PER_KM
    var reach := 0.0
    for rock in rocks_km:
        reach = maxf(reach, rock.distance_to(center_km))
    var half := (reach + ChartView.REEF_KM * 7.0) * px
    size = Vector2(half, half) * 2.0
    position = center_km * px - Vector2(half, half)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    var offsets := PackedVector2Array()
    for i in range(mini(rocks_km.size(), MAX_ROCKS)):
        offsets.append((rocks_km[i] - center_km) * px)
    while offsets.size() < MAX_ROCKS:
        offsets.append(Vector2(1e5, 1e5))

    var shader_material := ShaderMaterial.new()
    shader_material.shader = SHADER
    shader_material.set_shader_parameter("rocks", offsets)
    shader_material.set_shader_parameter("count", mini(rocks_km.size(), MAX_ROCKS))
    shader_material.set_shader_parameter("radius", ChartView.REEF_KM * px)
    shader_material.set_shader_parameter("half_size", half)
    shader_material.set_shader_parameter("seed", seed_value)
    shader_material.set_shader_parameter("sea_color", ChartView.SEA)
    material = shader_material
