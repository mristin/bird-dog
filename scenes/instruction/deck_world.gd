class_name DeckWorld
extends RefCounted

## Build the scenery of the instruction: a warm evening sky with a little haze,
## the sun, the sea (a small water shader), the deck of the boat with the Bird
## Dog flag on its mast, and Pula with the Roman Arena in the distance.

const WATER_SHADER := """
shader_type spatial;

uniform vec4 deep : source_color = vec4(0.04, 0.22, 0.38, 1.0);
uniform vec4 shallow : source_color = vec4(0.1, 0.42, 0.58, 1.0);

void fragment() {
    vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float a = world.x * 0.55 + TIME * 0.7;
    float b = world.z * 0.7 - TIME * 0.5;
    float c = (world.x + world.z) * 0.3 + TIME * 0.35;

    // NOTE (mristin):
    // The ripples fade with the distance, so that they do not flicker on the horizon.
    float near = 1.0 / (1.0 + length(world - CAMERA_POSITION_WORLD) * 0.12);
    float waves = 0.5 + near * (0.2 * sin(a) + 0.2 * sin(b) + 0.1 * sin(c));
    ALBEDO = mix(deep.rgb, shallow.rgb, waves);
    float bump = 0.07 * near;
    vec3 normal = normalize(vec3((cos(a) + 0.5 * cos(c)) * bump, 1.0, cos(b) * bump));
    NORMAL = normalize((VIEW_MATRIX * vec4(normal, 0.0)).xyz);
    ROUGHNESS = 0.12;
    SPECULAR = 0.7;
}
"""


## Add the whole scenery to the parent.
static func build(parent: Node3D) -> void:
    var environment := Environment.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.22, 0.42, 0.72)
    sky_material.sky_horizon_color = Color(0.98, 0.78, 0.56)
    sky_material.ground_horizon_color = Color(0.98, 0.78, 0.56)
    sky_material.ground_bottom_color = Color(0.05, 0.15, 0.25)
    sky_material.sun_angle_max = 20.0
    var sky := Sky.new()
    sky.sky_material = sky_material
    environment.background_mode = Environment.BG_SKY
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.8
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.93, 0.8, 0.66)
    environment.fog_density = 0.006
    environment.fog_sky_affect = 0.0
    var world_environment := WorldEnvironment.new()
    world_environment.environment = environment
    parent.add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-38, -50, 0)
    sun.light_color = Color(1.0, 0.9, 0.76)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    parent.add_child(sun)

    _build_sea(parent)
    _build_boat(parent)
    _build_pula(parent)


static func _box(
    parent: Node3D, size: Vector3, color: Color, at_position: Vector3
) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material
    instance.position = at_position
    parent.add_child(instance)
    return instance


static func _build_sea(parent: Node3D) -> void:
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(400, 400)
    var material := ShaderMaterial.new()
    var shader := Shader.new()
    shader.code = WATER_SHADER
    material.shader = shader
    var sea := MeshInstance3D.new()
    sea.mesh = mesh
    sea.material_override = material
    sea.position = Vector3(0, -0.45, 0)
    parent.add_child(sea)


static func _build_boat(parent: Node3D) -> void:
    var planks := 14
    for i in range(planks):
        var x := -1.4 + (i + 0.5) * 2.8 / planks
        var tone := Color(0.62, 0.42, 0.24) if i % 2 == 0 else Color(0.56, 0.37, 0.2)
        _box(parent, Vector3(2.8 / planks - 0.012, 0.06, 5.2), tone, Vector3(x, -0.03, 0.4))

    var hull := Color(0.32, 0.19, 0.1)
    for x in [-1.5, 1.5]:
        _box(parent, Vector3(0.12, 0.85, 5.4), hull, Vector3(x, -0.12, 0.4))
        _box(parent, Vector3(0.2, 0.06, 5.5), Color(0.5, 0.3, 0.15), Vector3(x, 0.32, 0.4))
    _box(parent, Vector3(3.1, 0.85, 0.12), hull, Vector3(0, -0.12, 3.05))
    _box(parent, Vector3(3.1, 0.85, 0.12), hull, Vector3(0, -0.12, -2.25))

    # The mast with the Bird Dog flag.
    var mast_mesh := CylinderMesh.new()
    mast_mesh.top_radius = 0.05
    mast_mesh.bottom_radius = 0.08
    mast_mesh.height = 4.5
    var mast := MeshInstance3D.new()
    mast.mesh = mast_mesh
    var mast_material := StandardMaterial3D.new()
    mast_material.albedo_color = Color(0.42, 0.26, 0.12)
    mast.material_override = mast_material
    mast.position = Vector3(-1.0, 2.25, 2.2)
    parent.add_child(mast)

    var flag_mesh := QuadMesh.new()
    flag_mesh.size = Vector2(1.1, 0.8)
    var flag_material := StandardMaterial3D.new()
    flag_material.albedo_texture = load("res://assets/images/flag.svg")
    flag_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    flag_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
    var flag := MeshInstance3D.new()
    flag.mesh = flag_mesh
    flag.material_override = flag_material
    flag.position = Vector3(-1.0 + 0.58, 4.05, 2.2)
    parent.add_child(flag)


## Pula in the distance: the hills, the shore and the Roman Arena.
static func _build_pula(parent: Node3D) -> void:
    var town := Node3D.new()
    town.position = Vector3(-22, -0.45, -30)
    town.rotation_degrees.y = 25.0
    parent.add_child(town)

    _box(town, Vector3(60, 0.8, 18), Color(0.72, 0.68, 0.55), Vector3(0, 0.2, -4))
    var hill := Color(0.36, 0.45, 0.3)
    for entry in [
        [Vector3(-14, 0, -14), 9.0], [Vector3(6, 0, -16), 12.0], [Vector3(22, 0, -12), 8.0]
    ]:
        var mesh := SphereMesh.new()
        mesh.radius = entry[1]
        mesh.height = entry[1] * 1.0
        var material := StandardMaterial3D.new()
        material.albedo_color = hill
        var instance := MeshInstance3D.new()
        instance.mesh = mesh
        instance.material_override = material
        instance.position = entry[0]
        town.add_child(instance)

    # The Arena: an ellipse of piers in two tiers, with arches between them.
    var stone := Color(0.9, 0.85, 0.74)
    var count := 32
    for i in range(count):
        var angle := i * TAU / count
        var at_position := Vector3(cos(angle) * 6.5, 0, sin(angle) * 4.8 - 4.0)
        var pier := _box(town, Vector3(0.6, 3.2, 0.7), stone, at_position + Vector3(0, 2.2, 0))
        pier.rotation.y = -angle
        var upper := _box(town, Vector3(0.6, 2.2, 0.7), stone, at_position + Vector3(0, 5.2, 0))
        upper.rotation.y = -angle
        var beam := _box(town, Vector3(1.3, 0.35, 0.72), stone, at_position + Vector3(0, 3.9, 0))
        beam.rotation.y = -angle + PI / 2
        var top := _box(town, Vector3(1.3, 0.35, 0.72), stone, at_position + Vector3(0, 6.4, 0))
        top.rotation.y = -angle + PI / 2
