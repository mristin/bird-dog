class_name BirdDogPoses
extends RefCounted

## The poses of the Captain3D for the instruction, as dictionaries of the joint
## rotations around X in degrees (plus "hips_y" and "hips_roll").
##
## The arms are given by their angle in the world: 0 points down, 90 forward
## (level with the back), 135 forward and up. The joints compensate for the
## tilt of the back, so that the angle stays the same however the back bends.

## The height of the hips when kneeling: the thigh plus the radius of the knee.
const KNEEL_HIPS_Y := Captain3D.THIGH + 0.066

## The back rises a little toward the shoulders, so that the straight arms reach the floor.
const BACK_PITCH := -82.0

## When kneeling, the foot slopes from the end of the shin down to the floor,
## its top resting on the floor and the sole facing up.
const KNEEL_ANKLE := -75.0

## The head looks at the floor a little ahead of the hands.
const GOOD_HEAD := -70.0


static func standing() -> Dictionary:
    return {
        "hips_y": Captain3D.THIGH + Captain3D.SHIN + 0.0625,
        "hips_roll": 0.0,
        "spine": 0.0,
        "chest": 0.0,
        "neck": 0.0,
        "head": 0.0,
        "shoulder_l": 4.0,
        "shoulder_r": 4.0,
        "elbow_l": 8.0,
        "elbow_r": 8.0,
        "hip_l": 0.0,
        "hip_r": 0.0,
        "knee_l": 0.0,
        "knee_r": 0.0,
        "ankle_l": 0.0,
        "ankle_r": 0.0,
    }


static func kneeling() -> Dictionary:
    var pose := standing()
    pose["hips_y"] = KNEEL_HIPS_Y
    for side in ["l", "r"]:
        pose["knee_" + side] = -90.0
        pose["ankle_" + side] = KNEEL_ANKLE
    return pose


## Make a pose on all fours.
##
## [param arm_l] and [param arm_r] are the world angles of the arms (0 down,
## 90 forward), [param leg_l] and [param leg_r] how far each leg stretches
## back (0 kneeling, 1 straight back, level with the back), [param head] the
## world pitch of the face (-90 looks straight down, 0 straight ahead),
## [param sag] how much the back sags (0 to 1), [param hip_roll] how much the
## hips roll open, in degrees, and [param leg_high] how far a stretched leg kicks
## up above the back (0 to 1).
static func all_fours(
    arm_l := 0.0,
    arm_r := 0.0,
    leg_l := 0.0,
    leg_r := 0.0,
    head := GOOD_HEAD,
    sag := 0.0,
    hip_roll := 0.0,
    leg_high := 0.0
) -> Dictionary:
    var spine := BACK_PITCH - 30.0 * sag
    var chest := 55.0 * sag
    var back := spine + chest

    var pose := {
        "hips_y": KNEEL_HIPS_Y - 0.02 * sag,
        "hips_roll": hip_roll,
        "spine": spine,
        "chest": chest,
        "neck": 0.0,
        "head": head - back,
        "shoulder_l": arm_l - back,
        "shoulder_r": arm_r - back,
        "elbow_l": 0.0,
        "elbow_r": 0.0,
    }

    for entry in [["l", leg_l], ["r", leg_r]]:
        var side: String = entry[0]
        var stretch: float = entry[1]
        pose["hip_" + side] = lerpf(0.0, -90.0 - 35.0 * leg_high, stretch)
        pose["knee_" + side] = lerpf(-90.0, 0.0, stretch)
        pose["ankle_" + side] = lerpf(KNEEL_ANKLE, -60.0, stretch)

    return pose


## The bird dog: the arm on one side stretches forward and the leg on the
## other side stretches back. [param arm_side] is "r" or "l".
static func bird_dog(arm_side: String, amount := 1.0, arm_angle := 90.0) -> Dictionary:
    var arm := lerpf(0.0, arm_angle, amount)
    if arm_side == "r":
        return all_fours(0.0, arm, amount, 0.0)
    return all_fours(arm, 0.0, 0.0, amount)


static func both_arms_up() -> Dictionary:
    return all_fours(110.0, 110.0)
