class_name Captain3D
extends Node3D

## A toy-like 3D captain in a haiduk-sailor outfit, built from simple shapes.
##
## The joints are plain Node3D pivots; the poses (see BirdDogPoses) set their
## rotations around X in degrees, plus the height and the roll of the hips.
## The captain faces -Z, and its right side is +X.

const THIGH := 0.36
const SHIN := 0.34
const UPPER_ARM := 0.2
const FOREARM := 0.19
const TORSO := 0.46
const LOWER_BACK := 0.2
const SHOULDER_HALF_WIDTH := 0.2
const HIP_HALF_WIDTH := 0.09

## The radii of the knees and the hands, and the box of the foot around its ankle,
## for keeping them above the floor.
const _KNEE_RADIUS := 0.066
const _HAND_RADIUS := 0.062
const _FOOT_CENTER := Vector3(0, -0.03, -0.05)
const _FOOT_HALF := Vector3(0.05, 0.0325, 0.11)
const _TOE_CENTER := Vector3(0, -0.01, -0.165)
const _TOE_RADIUS := 0.035

@export var skin := Color(0.93, 0.74, 0.58)
@export var hair := Color(0.13, 0.09, 0.06)
@export var shirt := Color(0.97, 0.95, 0.89)
@export var vest := Color(0.12, 0.22, 0.45)
@export var trim := Color(0.88, 0.68, 0.22)
@export var sash := Color(0.74, 0.1, 0.1)
@export var trousers := Color(0.22, 0.18, 0.15)
@export var shoes := Color(0.47, 0.29, 0.14)
@export var cap := Color(0.78, 0.1, 0.1)

## The hair style and the cap (see CaptainOptions.HAIR_STYLES and CAPS).
@export var hair_style := "short"
@export var cap_style := "lika"
@export var has_moustache := true
@export var has_freckles := false

## Which eye of the captain wears a patch: "none", "left" or "right".
@export var eye_patch := "none"

## The joints by name, e.g., "hips", "spine", "shoulder_r".
var joints := {}

var _materials := {}

# NOTE (mristin):
# We animate the poses ourselves instead of with a Tween, so that we can keep the
# captain above the floor in the very same step. A Tween runs after our
# _process, so the lift would always lag a frame behind, and the feet would dip
# into the floor while kneeling down.
var _from := {}
var _to := {}
var _duration := 0.0
var _elapsed := 0.0
var _transition := Tween.TRANS_SINE
var _easing := Tween.EASE_IN_OUT


func _ready() -> void:
    _build()


## Dress the captain in the looks (see CaptainOptions) and rebuild it, keeping
## its pose.
func apply_looks(looks: Dictionary) -> void:
    skin = CaptainOptions.SKINS[int(looks["skin"])]
    hair = CaptainOptions.HAIR_COLORS[int(looks["hair_color"])]
    vest = CaptainOptions.CLOTHS[int(looks["vest"])]
    sash = CaptainOptions.CLOTHS[int(looks["sash"])]
    hair_style = looks["hair"]
    cap_style = looks["cap"]
    var face: String = looks["face"]
    has_moustache = face in ["moustache", "moustache_freckles"]
    has_freckles = face in ["freckles", "moustache_freckles"]
    eye_patch = looks.get("eye_patch", "none")

    if joints.is_empty():
        return
    var pose := _current_pose()
    for child in get_children():
        child.free()
    joints.clear()
    _build()
    _apply(pose)
    _keep_above_floor()


func _current_pose() -> Dictionary:
    var pose := {}
    for key in BirdDogPoses.standing():
        var target: Variant = _target_of(key)
        if target != null:
            pose[key] = float(target[0].get_indexed(target[1]))
    return pose


func _process(delta: float) -> void:
    if not _to.is_empty():
        _elapsed += delta
        var t := clampf(_elapsed / _duration, 0.0, 1.0)
        var k: float = Tween.interpolate_value(0.0, 1.0, t, 1.0, _transition, _easing)
        var pose := {}
        for key in _to:
            pose[key] = lerpf(_from[key], _to[key], k)
        _apply(pose)
        if t >= 1.0:
            _to = {}

    _keep_above_floor()


## Lift the whole captain just enough that no foot, knee or hand sinks into the
## floor (at y = 0 of the parent).
##
## The poses only set the joints, and in between two poses (e.g., while kneeling
## down) the feet would dip below the floor. We never lower the captain, so that
## the poses which already rest on the floor stay as they are.
func _keep_above_floor() -> void:
    var lowest := INF
    for side in ["l", "r"]:
        lowest = minf(lowest, _height_of(joints["knee_" + side], Vector3.ZERO) - _KNEE_RADIUS)
        var hand := Vector3(0, -FOREARM - 0.035, 0)
        lowest = minf(lowest, _height_of(joints["elbow_" + side], hand) - _HAND_RADIUS)

        var ankle: Node3D = joints["ankle_" + side]
        lowest = minf(lowest, _height_of(ankle, _TOE_CENTER) - _TOE_RADIUS)
        for x in [-1.0, 1.0]:
            for y in [-1.0, 1.0]:
                for z in [-1.0, 1.0]:
                    var corner := _FOOT_CENTER + _FOOT_HALF * Vector3(x, y, z)
                    lowest = minf(lowest, _height_of(ankle, corner))

    position.y = maxf(0.0, -lowest)


## Get the height of a point given in the frame of a joint, as if the captain
## stood at y = 0, i.e., without our own lift.
func _height_of(joint: Node3D, point: Vector3) -> float:
    return (global_transform.affine_inverse() * (joint.global_transform * point)).y


## Move all the joints smoothly to the pose (see BirdDogPoses) in the given time.
func pose_to(
    pose: Dictionary, duration: float, transition := Tween.TRANS_SINE, easing := Tween.EASE_IN_OUT
) -> void:
    if duration <= 0.0:
        set_pose(pose)
        return

    _from = {}
    for key in pose:
        var target: Variant = _target_of(key)
        if target != null:
            _from[key] = float(target[0].get_indexed(target[1]))
    _to = {}
    for key in _from:
        _to[key] = float(pose[key])
    _duration = duration
    _elapsed = 0.0
    _transition = transition
    _easing = easing


## Set the pose at once.
func set_pose(pose: Dictionary) -> void:
    stop()
    _apply(pose)
    _keep_above_floor()


## Stop the current movement where it is.
func stop() -> void:
    _to = {}


func _apply(pose: Dictionary) -> void:
    for key in pose:
        var target: Variant = _target_of(key)
        if target != null:
            target[0].set_indexed(target[1], float(pose[key]))


## Map a key of a pose to the node and the property which it animates.
func _target_of(key: String) -> Variant:
    match key:
        "hips_y":
            return [joints["hips"], "position:y"]
        "hips_roll":
            return [joints["hips"], "rotation_degrees:z"]
    if joints.has(key):
        return [joints[key], "rotation_degrees:x"]
    push_warning("Captain3D: unknown pose key %s" % key)
    return null


func _material(color: Color) -> StandardMaterial3D:
    if not _materials.has(color):
        var material := StandardMaterial3D.new()
        material.albedo_color = color
        material.roughness = 0.75
        _materials[color] = material
    return _materials[color]


func _joint(joint_name: String, parent: Node3D, offset: Vector3) -> Node3D:
    var joint := Node3D.new()
    joint.name = joint_name
    joint.position = offset
    parent.add_child(joint)
    joints[joint_name] = joint
    return joint


func _part(
    parent: Node3D,
    mesh: Mesh,
    color: Color,
    offset: Vector3,
    stretch := Vector3.ONE,
    tilt := Vector3.ZERO
) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.mesh = mesh
    part.material_override = _material(color)
    part.position = offset
    part.scale = stretch
    part.rotation_degrees = tilt
    parent.add_child(part)
    return part


static func _capsule(radius: float, height: float) -> CapsuleMesh:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = maxf(height, radius * 2.0)
    return mesh


static func _sphere(radius: float) -> SphereMesh:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    return mesh


static func _box(size: Vector3) -> BoxMesh:
    var mesh := BoxMesh.new()
    mesh.size = size
    return mesh


static func _cylinder(radius: float, height: float) -> CylinderMesh:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    return mesh


func _build() -> void:
    var hips := _joint("hips", self, Vector3(0, THIGH + SHIN + 0.06, 0))

    # The seat and the sash.
    _part(hips, _sphere(0.13), trousers, Vector3(0, 0.0, 0.01), Vector3(1.25, 0.8, 0.9))

    var spine := _joint("spine", hips, Vector3.ZERO)
    _build_torso(spine)

    for side in ["l", "r"]:
        var side_sign := 1.0 if side == "r" else -1.0
        _build_leg(hips, side, side_sign)


func _build_torso(spine: Node3D) -> void:
    # NOTE (mristin):
    # The lower back and the chest are separate, so that a sagging back can bend.
    _part(
        spine,
        _capsule(0.14, LOWER_BACK + 0.12),
        vest,
        Vector3(0, LOWER_BACK * 0.5, 0),
        Vector3(1.25, 1, 0.85)
    )
    _part(spine, _cylinder(0.165, 0.1), sash, Vector3(0, 0.06, 0), Vector3(1.22, 1, 0.88))

    var chest := _joint("chest", spine, Vector3(0, LOWER_BACK, 0))
    var upper := TORSO - LOWER_BACK
    _part(
        chest, _capsule(0.16, upper + 0.14), vest, Vector3(0, upper * 0.5, 0), Vector3(1.3, 1, 0.85)
    )

    # The shirt shows in the open front of the vest, framed by the golden trim.
    _part(chest, _box(Vector3(0.09, upper + 0.02, 0.02)), shirt, Vector3(0, upper * 0.55, -0.132))
    for x in [-0.055, 0.055]:
        _part(
            chest, _box(Vector3(0.018, upper + 0.02, 0.02)), trim, Vector3(x, upper * 0.55, -0.13)
        )

    var neck := _joint("neck", chest, Vector3(0, upper + 0.02, 0))
    _part(neck, _capsule(0.055, 0.12), skin, Vector3(0, 0.03, 0))
    _build_head(_joint("head", neck, Vector3(0, 0.06, 0)))

    for side in ["l", "r"]:
        var side_sign := 1.0 if side == "r" else -1.0
        _build_arm(chest, side, side_sign, upper)


func _build_head(head: Node3D) -> void:
    var center := Vector3(0, 0.13, 0)
    _part(head, _sphere(0.15), skin, center)

    # The hair covers the back and the sides; the face looks to -Z.
    _part(head, _sphere(0.155), hair, center + Vector3(0, 0.02, 0.035), Vector3(1.0, 0.95, 0.92))
    _build_hair(head, center)

    _part(head, _sphere(0.03), skin.darkened(0.08), center + Vector3(0, -0.01, -0.15))
    # NOTE (mristin):
    # The eyes are painted on, like those of a toy figure: flat black ovals
    # which lie on the face, each with a tiny flat highlight. Round eyes which
    # stick out look spooky.
    for x in [-0.052, 0.052]:
        var on_face := Vector3(x, 0.03, -sqrt(0.15 * 0.15 - x * x - 0.03 * 0.03))
        var tilt := Vector3(rad_to_deg(asin(0.03 / 0.15)), rad_to_deg(-asin(x / 0.15)), 0)
        _part(
            head,
            _sphere(0.02),
            Color(0.08, 0.06, 0.05),
            center + on_face * 0.995,
            Vector3(0.8, 1.15, 0.12),
            tilt
        )
        _part(
            head,
            _sphere(0.0055),
            Color.WHITE,
            center + on_face * 1.003 + Vector3(0.005, 0.009, 0),
            Vector3(1.0, 1.0, 0.2),
            tilt
        )

    if has_moustache:
        for x in [-1.0, 1.0]:
            _part(
                head,
                _capsule(0.016, 0.1),
                hair,
                center + Vector3(x * 0.04, -0.045, -0.142),
                Vector3.ONE,
                Vector3(0, 0, x * 70.0)
            )

    if has_freckles:
        var freckle := skin.darkened(0.35)
        for offset in [
            Vector3(-0.075, -0.005, -0.125),
            Vector3(-0.055, -0.02, -0.135),
            Vector3(-0.09, -0.025, -0.11),
            Vector3(0.075, -0.005, -0.125),
            Vector3(0.055, -0.02, -0.135),
            Vector3(0.09, -0.025, -0.11),
        ]:
            _part(head, _sphere(0.007), freckle, center + offset)

    _build_eye_patch(head, center)
    _build_cap(head, center)


## Add the eye patch: a black leather patch over the eye, and its strap around
## the head, tilted so that it runs through the eye.
func _build_eye_patch(head: Node3D, center: Vector3) -> void:
    if eye_patch not in ["left", "right"]:
        return
    var leather := Color(0.1, 0.08, 0.07)

    # NOTE (mristin):
    # The captain faces -Z, and its right side is +X, so its left eye is at -X.
    var x := 0.052 if eye_patch == "right" else -0.052
    var on_face := Vector3(x, 0.03, -sqrt(0.15 * 0.15 - x * x - 0.03 * 0.03))
    var tilt := Vector3(rad_to_deg(asin(0.03 / 0.15)), rad_to_deg(-asin(x / 0.15)), 0)
    _part(head, _sphere(0.034), leather, center + on_face * 1.0, Vector3(1.0, 0.85, 0.3), tilt)

    var strap := TorusMesh.new()
    strap.inner_radius = 0.151
    strap.outer_radius = 0.159
    strap.rings = 32
    _part(head, strap, leather, center, Vector3.ONE, Vector3(0, 0, rad_to_deg(atan2(0.03, x))))


## Add the hair style on top of the hair which covers the back of the head.
func _build_hair(head: Node3D, center: Vector3) -> void:
    match hair_style:
        "curly":
            for offset in [
                Vector3(0, 0.13, 0.03),
                Vector3(-0.09, 0.1, 0.05),
                Vector3(0.09, 0.1, 0.05),
                Vector3(-0.12, 0.02, 0.07),
                Vector3(0.12, 0.02, 0.07),
                Vector3(0, 0.07, 0.12),
                Vector3(-0.07, -0.03, 0.12),
                Vector3(0.07, -0.03, 0.12),
            ]:
                _part(head, _sphere(0.055), hair, center + offset)
        "ponytail":
            _part(head, _sphere(0.035), hair, center + Vector3(0, 0.02, 0.16))
            _part(
                head,
                _capsule(0.035, 0.2),
                hair,
                center + Vector3(0, -0.08, 0.18),
                Vector3.ONE,
                Vector3(-15, 0, 0)
            )
        "long":
            _part(
                head,
                _capsule(0.13, 0.36),
                hair,
                center + Vector3(0, -0.06, 0.07),
                Vector3(1.05, 1.0, 0.6)
            )
        "braid":
            for i in range(5):
                var y := 0.0 - i * 0.065
                var z := 0.15 + i * 0.012
                _part(head, _sphere(0.042 - i * 0.003), hair, center + Vector3(0, y, z))
            _part(head, _sphere(0.02), sash, center + Vector3(0, -0.33, 0.21))
        "bun":
            _part(head, _sphere(0.075), hair, center + Vector3(0, 0.12, 0.12))


## Add the cap: the red Lika cap, the tall fur kalpak, a headscarf, a cap
## with a feather, or none.
func _build_cap(head: Node3D, center: Vector3) -> void:
    var black := Color(0.08, 0.06, 0.05)
    match cap_style:
        "lika":
            _part(head, _cylinder(0.125, 0.08), cap, center + Vector3(0, 0.14, 0.01))
            _part(head, _cylinder(0.128, 0.025), black, center + Vector3(0, 0.105, 0.01))
        "kalpak":
            var fur := Color(0.2, 0.13, 0.08)
            _part(head, _cylinder(0.14, 0.2), fur, center + Vector3(0, 0.17, 0.01))
            _part(head, _cylinder(0.11, 0.02), cap, center + Vector3(0, 0.275, 0.01))
        "headscarf":
            var scarf := Color(0.93, 0.9, 0.82)
            _part(
                head,
                _sphere(0.165),
                scarf,
                center + Vector3(0, 0.035, 0.03),
                Vector3(1.0, 0.95, 0.95)
            )
            _part(head, _cylinder(0.168, 0.025), cap, center + Vector3(0, 0.06, 0.03))
            _part(head, _sphere(0.04), scarf, center + Vector3(0, -0.06, 0.17))
        "feather":
            _part(head, _cylinder(0.125, 0.08), cap, center + Vector3(0, 0.14, 0.01))
            _part(head, _cylinder(0.128, 0.025), black, center + Vector3(0, 0.105, 0.01))
            _part(
                head,
                _capsule(0.018, 0.26),
                Color(0.97, 0.96, 0.92),
                center + Vector3(0.1, 0.24, 0.06),
                Vector3(2.2, 1.0, 0.45),
                Vector3(-20, 0, -25)
            )


func _build_arm(chest: Node3D, side: String, side_sign: float, upper: float) -> void:
    var shoulder := _joint(
        "shoulder_" + side, chest, Vector3(side_sign * SHOULDER_HALF_WIDTH, upper - 0.03, 0)
    )
    _part(shoulder, _sphere(0.075), shirt, Vector3.ZERO)
    _part(shoulder, _capsule(0.068, UPPER_ARM + 0.1), shirt, Vector3(0, -UPPER_ARM * 0.5, 0))

    var elbow := _joint("elbow_" + side, shoulder, Vector3(0, -UPPER_ARM, 0))
    _part(elbow, _capsule(0.062, FOREARM + 0.06), shirt, Vector3(0, -FOREARM * 0.5, 0))
    _part(elbow, _sphere(0.058), skin, Vector3(0, -FOREARM - 0.035, 0), Vector3(0.9, 1.1, 0.7))


func _build_leg(hips: Node3D, side: String, side_sign: float) -> void:
    var hip := _joint("hip_" + side, hips, Vector3(side_sign * HIP_HALF_WIDTH, 0, 0))
    _part(hip, _capsule(0.082, THIGH + 0.12), trousers, Vector3(0, -THIGH * 0.5, 0))

    var knee := _joint("knee_" + side, hip, Vector3(0, -THIGH, 0))
    _part(knee, _capsule(0.066, SHIN + 0.08), trousers, Vector3(0, -SHIN * 0.5, 0))

    # The opanci: leather shoes with the tips turned up.
    var ankle := _joint("ankle_" + side, knee, Vector3(0, -SHIN, 0))
    _part(ankle, _box(_FOOT_HALF * 2.0), shoes, _FOOT_CENTER)
    _part(ankle, _sphere(_TOE_RADIUS), shoes, _TOE_CENTER)
