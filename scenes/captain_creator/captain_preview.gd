class_name CaptainPreview
extends SubViewportContainer

## Show a captain in 3D, standing on a piece of deck and turning slowly from
## side to side, so that the players see their captain from all around.

var _captain: Captain3D
var _time := 0.0


func _ready() -> void:
    stretch = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    var viewport := SubViewport.new()
    viewport.own_world_3d = true
    viewport.msaa_3d = Viewport.MSAA_4X
    add_child(viewport)

    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Paper.PAPER_DARK.lerp(Paper.PAPER, 0.5)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(1.0, 0.95, 0.88)
    environment.ambient_light_energy = 0.55
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    var world_environment := WorldEnvironment.new()
    world_environment.environment = environment
    viewport.add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-40, 150, 0)
    sun.light_color = Color(1.0, 0.92, 0.8)
    sun.light_energy = 1.1
    sun.shadow_enabled = true
    viewport.add_child(sun)

    for i in range(7):
        var plank := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.24, 0.05, 1.6)
        plank.mesh = mesh
        var material := StandardMaterial3D.new()
        material.albedo_color = (Color(0.62, 0.42, 0.24) if i % 2 == 0 else Color(0.56, 0.37, 0.2))
        plank.material_override = material
        plank.position = Vector3(-0.75 + i * 0.25, -0.025, 0)
        viewport.add_child(plank)

    _captain = Captain3D.new()
    viewport.add_child(_captain)
    _captain.set_pose(BirdDogPoses.standing())

    var camera := Camera3D.new()
    camera.fov = 34.0
    camera.position = Vector3(0, 1.25, -3.8)
    viewport.add_child(camera)
    camera.look_at(Vector3(0, 0.88, 0))


func set_looks(looks: Dictionary) -> void:
    _captain.apply_looks(looks)


func _process(delta: float) -> void:
    _time += delta
    _captain.rotation.y = sin(_time * 0.6) * 0.6
