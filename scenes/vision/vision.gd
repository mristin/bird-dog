extends Node

## Keep the camera and the vision running for the whole game, across all the
## scenes, so that the camera starts only once (which takes a few seconds).
##
## The scenes use `Vision.hands` (the HandVisionService: the camera picture, the
## aims of the hands and the fists) and `Vision.poses` (the PoseService: the
## bird-dog poses and the steering).
##
## Start with `-- --no-camera` to run without the camera, e.g., to render the
## scenes without showing the webcam.

@onready var hands: Node = $HandVisionService
@onready var poses: Node = $PoseService


func _enter_tree() -> void:
    # NOTE (mristin):
    # The vision starts the camera in its _ready, which runs before ours.
    if "--no-camera" in OS.get_cmdline_user_args():
        $HandVisionService.UseCamera = false
