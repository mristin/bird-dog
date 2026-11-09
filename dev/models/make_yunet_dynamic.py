"""Make the input of YuNet dynamic, so that we can run it on small head crops.

The original model of the OpenCV Zoo has a fixed input of 640x640, but the graph
only reshapes to ``[1, -1, k]``, so it runs on any input which is a multiple of
32. We only rename the height and the width of the input (and of the outputs)
to symbolic dimensions; the weights stay unchanged.

Usage:

    pip install onnx==1.23.2
    curl -L -o face_detection_yunet_2023mar.onnx \\
        https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx
    python dev/models/make_yunet_dynamic.py face_detection_yunet_2023mar.onnx \\
        scenes/hand_tracker/yunet/model/face_detection_yunet_2023mar_dynamic.onnx
"""

import argparse
import sys

import onnx


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", help="the original ONNX model")
    parser.add_argument("target", help="where to write the model with the dynamic input")
    args = parser.parse_args()

    model = onnx.load(args.source)

    dims = model.graph.input[0].type.tensor_type.shape.dim
    dims[2].ClearField("dim_value")
    dims[2].dim_param = "H"
    dims[3].ClearField("dim_value")
    dims[3].dim_param = "W"

    for output in model.graph.output:
        output_dims = output.type.tensor_type.shape.dim
        output_dims[1].ClearField("dim_value")
        output_dims[1].dim_param = f"anchors_{output.name.split('_')[-1]}"

    del model.graph.value_info[:]
    onnx.checker.check_model(model)
    onnx.save(model, args.target)
    print(f"Wrote {args.target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
